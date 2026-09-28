//============================================================================
//  CoCo3 Verilator simulation
//
//  Two modes, one binary:
//    windowed  - ImGui/SDL front end: the video output, a CPU/GIME inspector,
//                the OSD options, disk/cart/tape mounting and a console.
//    headless  - no SDL at all (--headless). Runs to a frame, types at the
//                machine on a frame schedule, writes PNGs, prints the text
//                screen, logs per-frame hashes. This is what run_tests.sh uses.
//
//  Schedules are in *frames*, not cycles, so they survive clocking changes.
//
//  Clocking. The PLL in CoCo3.sv makes 114.545 / 57.27 / 28.64 / 14.32 MHz, all
//  phase 0 -- exact /2 /4 /8 divisions. sim_main steps a half-period of CLK_114
//  per eval and derives the other three from the same counter, so every rising
//  edge that coincides on hardware coincides here, inside one eval.
//============================================================================

#include <verilated.h>
#include "Vemu.h"
#if __has_include("Vemu___024root.h")
#include "Vemu___024root.h"
#endif
#if VM_TRACE_VCD
#include <verilated_vcd_c.h>
#endif

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <ctime>
#include <string>
#include <vector>
#include <map>
#include <set>
#include <algorithm>

#include "sim_console.h"
#include "sim_bus.h"
#include "sim_video.h"
#include "sim_input.h"
#include "sim_audio.h"
#include "sim_blkdevice.h"
#include "dis6809.h"
#include "serial.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#ifndef _MSC_VER
#include <SDL.h>
#include <SDL_opengl.h>
#include "ImGuiFileDialog.h"
#endif

//----------------------------------------------------------------------------
// Machine constants
//----------------------------------------------------------------------------

// Active area as the core blanks it (Mister_Video.v), measured with the sim's
// own "active WxH" report: 763 pixel clocks by 254 lines, border included.
static const int VIDEO_WIDTH  = 763;
static const int VIDEO_HEIGHT = 254;

static const double CLK_114_HZ = 114545454.0;
static const long   CLK_SYS_HZ = 57272727;

// Block-device slots, from CoCo3.sv's hps_io VDNUM(7) / CONF_STR:
//   S0/S1 = SDC drives 0/1, S2..S5 = floppy drives 0..3, S6 = cassette save.
static const int BLK_SDC0 = 0, BLK_FDC0 = 2;

// ioctl indices. Main_MiSTer uploads boot<N>.rom with index N<<6.
static const int IDX_BOOT0 = 0x00;   // CoCo3 system ROM, 32K
static const int IDX_BOOT1 = 0x40;   // Disk BASIC ROM, 8K
static const int IDX_CART  = 1;      // "F1,CCC"
static const int IDX_CAS   = 2;      // "F2,CAS"
static const int IDX_FONT  = 3;      // "P2F3,BIN"

//----------------------------------------------------------------------------
// Globals
//----------------------------------------------------------------------------

static Vemu*      top = nullptr;
static vluint64_t main_time = 0;       // half-periods of CLK_114
double sc_time_stamp() { return (double)main_time; }

#if VM_TRACE_VCD
static VerilatedVcdC* tfp = nullptr;
#endif
static std::string vcd_path;

static DebugConsole   console;
static SimBus         bus(console);
static SimVideo       video(VIDEO_WIDTH, VIDEO_HEIGHT, 0);
static SimInput       input(0, console);
static SimAudio       audio(CLK_SYS_HZ, false);
static SimBlockDevice blk(console);
static SerialPort     serial;

// Referenced as extern by sim_video.cpp / sim_input.cpp to skip SDL/GL work.
bool headless = false;

static bool run_enable    = true;
static int  stop_at_frame = -1;
static int  reset_at_frame = -1;

// OSD status word, decoded by sim.v exactly as CoCo3.sv decodes it.
static uint64_t status = 0;
static int      status_pulse[64];      // eval-steps left on a momentary bit

static int      reset_hold = 0;        // clk_sys cycles of RESET at start

// ROMs and media
static std::string rom_path      = "roms/boot0.rom";
static std::string diskrom_path  = "roms/boot1.rom";
static std::string cart_path, cas_path, font_path;
// --cart-frame: deliver the cart after boot, as Main_MiSTer does when the cart
// is picked from the OSD or an MGL. -1 = with the ROMs, before reset ends.
static int cart_frame = -1;
static std::string fdc_path[4], sdc_path[2];

// Screenshots / logging
static std::vector<int> screenshot_frames;
static std::set<int>    screenshots_taken;
static std::string      screenshot_prefix = "screenshot";
static bool             frame_log = false;
static std::vector<int> ascii_frames;
static bool             ascii_at_end = false;

// CPU trace
static bool  trace_cpu   = false;
static bool  trace_bus   = false;
static int   trace_from  = 0;
static int   trace_until = -1;
static long  trace_max   = 2000000;
static long  trace_lines = 0;
static FILE* trace_file  = nullptr;

// Serial (RS-232 Pak, glb6551 at $FF68-$FF6B)
static bool  trace_acia = false;
static bool  serial_pty = false;
static long  acia_accesses = 0, acia_undecoded = 0;
static int   acia_undecoded_scs = -1;
struct SerialSend { int frame; std::vector<uint8_t> bytes; };
static std::vector<SerialSend> serial_sends;

// Stats
static long  instr_count = 0;
static long  instr_count_frame = 0;
static long  irq_edges = 0;
static long  ena_frame = 0;

//----------------------------------------------------------------------------
// Bus shadow: every byte the CPU has read or written, by logical address.
// Feeds the disassembler and the text-screen dump.
//----------------------------------------------------------------------------

static uint8_t shadow[65536];
static uint8_t shadow_known[65536];
static int rd_shadow(uint16_t a) { return shadow_known[a] ? shadow[a] : -1; }

//----------------------------------------------------------------------------
// Keyboard scheduling (US PC layout -- rtl/cocokey.v maps from that)
//----------------------------------------------------------------------------

struct KeyMap { uint8_t code; bool extended; bool shift; };

static bool ascii_to_ps2(char c, KeyMap& out) {
	static const uint8_t letters[26] = {
		0x1c,0x32,0x21,0x23,0x24,0x2b,0x34,0x33,0x43,0x3b,0x42,0x4b,0x3a,
		0x31,0x44,0x4d,0x15,0x2d,0x1b,0x2c,0x3c,0x2a,0x1d,0x22,0x35,0x1a
	};
	static const uint8_t digits[10] = {
		0x45,0x16,0x1e,0x26,0x25,0x2e,0x36,0x3d,0x3e,0x46
	};
	out.extended = false;
	out.shift    = false;
	// The CoCo has no lower case on the keyboard matrix without SHIFT-0, and
	// BASIC wants capitals, so letters are sent unshifted either way.
	if (c >= 'a' && c <= 'z') { out.code = letters[c - 'a']; return true; }
	if (c >= 'A' && c <= 'Z') { out.code = letters[c - 'A']; return true; }
	if (c >= '0' && c <= '9') { out.code = digits[c - '0']; return true; }
	switch (c) {
		case ' ':  out.code = 0x29; return true;
		case '\n': case '\r': out.code = 0x5a; return true;
		case '\b': out.code = 0x66; return true;
		case '-':  out.code = 0x4e; return true;
		case '=':  out.code = 0x55; return true;
		case ',':  out.code = 0x41; return true;
		case '.':  out.code = 0x49; return true;
		case ';':  out.code = 0x4c; return true;
		case '/':  out.code = 0x4a; return true;
		case '\'': out.code = 0x52; return true;
		case '[':  out.code = 0x54; return true;
		case ']':  out.code = 0x5b; return true;
		case '\\': out.code = 0x5d; return true;
		case '!':  out.code = 0x16; out.shift = true; return true;
		case '@':  out.code = 0x1e; out.shift = true; return true;
		case '#':  out.code = 0x26; out.shift = true; return true;
		case '$':  out.code = 0x25; out.shift = true; return true;
		case '%':  out.code = 0x2e; out.shift = true; return true;
		case '^':  out.code = 0x36; out.shift = true; return true;
		case '&':  out.code = 0x3d; out.shift = true; return true;
		case '*':  out.code = 0x3e; out.shift = true; return true;
		case '(':  out.code = 0x46; out.shift = true; return true;
		case ')':  out.code = 0x45; out.shift = true; return true;
		case '_':  out.code = 0x4e; out.shift = true; return true;
		case '+':  out.code = 0x55; out.shift = true; return true;
		case '<':  out.code = 0x41; out.shift = true; return true;
		case '>':  out.code = 0x49; out.shift = true; return true;
		case ':':  out.code = 0x4c; out.shift = true; return true;
		case '?':  out.code = 0x4a; out.shift = true; return true;
		case '"':  out.code = 0x52; out.shift = true; return true;
		default: return false;
	}
}

static bool name_to_ps2(std::string n, KeyMap& out) {
	static const std::map<std::string, KeyMap> names = {
		{"RETURN",{0x5a,false,false}}, {"ENTER",{0x5a,false,false}},
		{"SPACE",{0x29,false,false}},  {"BS",{0x66,false,false}},
		{"ESC",{0x76,false,false}},    {"BREAK",{0x76,false,false}},
		{"CLEAR",{0x6c,true,false}},   {"HOME",{0x6c,true,false}},
		{"UP",{0x75,true,false}},      {"DOWN",{0x72,true,false}},
		{"LEFT",{0x6b,true,false}},    {"RIGHT",{0x74,true,false}},
		{"SHIFT",{0x12,false,false}},  {"CTRL",{0x14,false,false}},
		{"ALT",{0x11,false,false}},
		{"F1",{0x05,false,false}},     {"F2",{0x06,false,false}},
	};
	std::transform(n.begin(), n.end(), n.begin(), ::toupper);
	auto it = names.find(n);
	if (it == names.end()) return false;
	out = it->second;
	return true;
}

struct KeyEvent { int frame; uint8_t code; bool extended; bool pressed; };
static std::vector<KeyEvent> key_events;   // sorted by frame when consumed
static size_t key_event_pos = 0;
static int    key_hold_frames = 2;         // frames a key stays down
static int    key_gap_frames  = 2;         // frames between keys
// After RETURN, BASIC is busy running the line (clearing the screen, changing
// mode, drawing) and does not scan the keyboard; the CoCo has no type-ahead,
// so keys pressed in that window are simply lost, as on the real machine.
static int    return_gap_frames = 30;

// Queue text starting at `frame`. "@NAME" inside {} sends a named key, e.g.
// "PRINT 2+2{RETURN}". Returns the frame after the last release.
static int schedule_text(int frame, const std::string& text) {
	int f = frame;
	for (size_t i = 0; i < text.size(); i++) {
		KeyMap k;
		if (text[i] == '{') {
			size_t e = text.find('}', i);
			if (e == std::string::npos || !name_to_ps2(text.substr(i + 1, e - i - 1), k)) {
				fprintf(stderr, "Unknown key name in \"%s\"\n", text.c_str());
				return f;
			}
			i = e;
		} else if (!ascii_to_ps2(text[i], k)) {
			fprintf(stderr, "No PS/2 mapping for '%c'\n", text[i]);
			continue;
		}
		if (k.shift) key_events.push_back({ f, 0x12, false, true });
		key_events.push_back({ f, k.code, k.extended, true });
		key_events.push_back({ f + key_hold_frames, k.code, k.extended, false });
		if (k.shift) key_events.push_back({ f + key_hold_frames, 0x12, false, false });
		f += key_hold_frames + key_gap_frames;
		if (k.code == 0x5a && !k.extended) f += return_gap_frames;
	}
	return f;
}

static void apply_key_events(int frame) {
	while (key_event_pos < key_events.size() && key_events[key_event_pos].frame <= frame) {
		const KeyEvent& e = key_events[key_event_pos++];
		input.keyEvents.push(SimInput_PS2KeyEvent(0, e.pressed, e.extended, e.code));
	}
}

//----------------------------------------------------------------------------
// Output helpers
//----------------------------------------------------------------------------

static void save_screenshot(int frame) {
	if (!output_ptr) return;
	char filename[512];
	snprintf(filename, sizeof(filename), "%s_frame_%04d.png", screenshot_prefix.c_str(), frame);
	const int w = video.output_width, h = video.output_height;
	std::vector<uint8_t> rgb((size_t)w * h * 3);
	for (int i = 0; i < w * h; i++) {
		uint32_t px = output_ptr[i];            // 0xFF | B<<16 | G<<8 | R
		rgb[i * 3 + 0] = px & 0xFF;
		rgb[i * 3 + 1] = (px >> 8) & 0xFF;
		rgb[i * 3 + 2] = (px >> 16) & 0xFF;
	}
	int ok = stbi_write_png(filename, w, h, 3, rgb.data(), w * 3);
	printf(ok ? "Screenshot saved: %s\n" : "Error: could not write %s\n", filename);
	fflush(stdout);
}

static uint64_t frame_hash() {
	uint64_t h = 1469598103934665603ULL;
	for (int i = 0; i < video.output_width * video.output_height; i++) {
		h ^= output_ptr[i];
		h *= 1099511628211ULL;
	}
	return h;
}

// The 32x16 VDG text screen at logical $0400, as the CPU last wrote it.
// VDG codes: $00-$3F inverse '@'..'?', $40-$7F normal, $80+ semigraphics.
static void print_text_screen(int frame) {
	printf("---- text screen $0400, frame %d ----\n", frame);
	for (int row = 0; row < 16; row++) {
		char line[33];
		for (int col = 0; col < 32; col++) {
			uint16_t a = 0x0400 + row * 32 + col;
			uint8_t c = shadow[a];
			char ch;
			if (!shadow_known[a])  ch = ' ';
			else if (c >= 0x80)    ch = '#';
			else {
				uint8_t b = c & 0x3F;
				ch = (b < 0x20) ? (char)('@' + b) : (char)b;
				if (c < 0x40) ch = (char)tolower(ch);   // inverse shows lower case
			}
			line[col] = ch;
		}
		line[32] = 0;
		printf("|%s|\n", line);
	}
	printf("-----------------------------------\n");
	fflush(stdout);
}

//----------------------------------------------------------------------------
// Media
//----------------------------------------------------------------------------

static bool file_exists(const std::string& p) {
	FILE* f = fopen(p.c_str(), "rb");
	if (f) fclose(f);
	return f != nullptr;
}

static void queue_rom(const std::string& path, int index, const char* what) {
	if (path.empty()) return;
	if (!file_exists(path)) {
		fprintf(stderr, "Warning: %s not found: %s\n", what, path.c_str());
		return;
	}
	printf("Loading %s over ioctl index 0x%02x: %s\n", what, index, path.c_str());
	bus.QueueDownload(path, index, true);
}

static void mount(int slot, const std::string& path) {
	if (path.empty()) return;
	printf("Mounting block device %d: %s\n", slot, path.c_str());
	blk.MountDisk(path, slot);
}

// MiSTer RTC: BCD {weekday, year, month, date, hour, min, sec}, bit 64 toggles
// on every update.
static void set_rtc() {
	time_t t = time(nullptr);
	struct tm* tm = localtime(&t);
	auto bcd = [](int v) { return (uint64_t)(((v / 10) << 4) | (v % 10)); };
	uint64_t v = bcd(tm->tm_sec) | bcd(tm->tm_min) << 8 | bcd(tm->tm_hour) << 16 |
	             bcd(tm->tm_mday) << 24 | bcd(tm->tm_mon + 1) << 32 |
	             bcd(tm->tm_year % 100) << 40 | bcd(tm->tm_wday + 1) << 48;
	top->RTC[0] = (uint32_t)v;
	top->RTC[1] = (uint32_t)(v >> 32);
	top->RTC[2] ^= 1;
}

//----------------------------------------------------------------------------
// OSD options (status bits, see CONF_STR in CoCo3.sv)
//----------------------------------------------------------------------------

static void set_status_field(int lo, int width, uint64_t v) {
	uint64_t mask = ((1ULL << width) - 1) << lo;
	status = (status & ~mask) | ((v << lo) & mask);
}
static uint64_t get_status_field(int lo, int width) {
	return (status >> lo) & ((1ULL << width) - 1);
}
static void pulse_status(int bit) {
	status_pulse[bit] = 64;                   // ~1 us of clk_sys
}

//----------------------------------------------------------------------------
// One half-period of CLK_114
//----------------------------------------------------------------------------

// --fast-clocks: step per half-period of clk_sys and run the CLK_114 domain
// (SDRAM controller, data_ready latch, video line fetcher) at 57 MHz. Half the
// evals, but memory accesses take twice as long in real time. See README.
static bool fast_clocks = false;

static int  clk50_acc = 0;                    // picoseconds
static bool clk50 = false;

// Bus-cycle bookkeeping for the trace/shadow (sampled before a clk_sys edge).
static bool     fetch_next = true;
static uint16_t cur_pc = 0, prev_pc = 0;
static bool     have_prev = false;
static uint8_t  old_irqn = 1;

static bool in_trace_window() {
	if (video.count_frame < trace_from) return false;
	if (trace_until >= 0 && video.count_frame > trace_until) return false;
	return trace_lines < trace_max;
}

static void emit_trace(uint16_t pc) {
	char instr[64], cc[9];
	dis6809(pc, rd_shadow, instr, sizeof(instr));
	cc6809_string(top->dbg_cc, cc);
	FILE* o = trace_file ? trace_file : stdout;
	fprintf(o, "%6d %04X  %-24s A=%02X B=%02X X=%04X Y=%04X U=%04X S=%04X DP=%02X CC=%s\n",
	        video.count_frame, pc, instr, top->dbg_a, top->dbg_b, top->dbg_x, top->dbg_y,
	        top->dbg_u, top->dbg_s, top->dbg_dp, cc);
	trace_lines++;
}

static void sim_step() {
	// k counts half-periods of CLK_114; fast mode visits only the even ones.
	const uint64_t k = fast_clocks ? (main_time << 1) : main_time;
	const bool c57  = !((k >> 1) & 1);
	const bool c114 = fast_clocks ? c57 : !(k & 1);
	const bool c28  = !((k >> 2) & 1);
	const bool c14  = !((k >> 3) & 1);
	const bool sys_rise = c57 && !top->CLK_57;
	const bool pix_rise = c14 && !top->CLK_14;

	// 50 MHz, free-running and asynchronous to the rest, as on the board.
	clk50_acc += fast_clocks ? 8730 : 4365;   // step length in ps
	if (clk50_acc >= 10000) { clk50_acc -= 10000; clk50 = !clk50; }

	// Sample the CPU bus as it stands before this clk_sys edge: mc6809x latches
	// on MASTER (clk_sys) while cpu_cycle_ena is high, so these are the address
	// and data of the bus cycle this edge completes.
	bool     b_ena = false, b_rw = false, b_lic = false, b_rs232 = false;
	uint16_t b_addr = 0;
	uint8_t  b_din = 0, b_dout = 0;
	if (sys_rise) {
		b_ena  = top->dbg_ena && !top->dbg_reset;
		ena_frame += top->dbg_ena;
		b_rw   = top->dbg_rw;
		b_lic  = top->dbg_lic;
		b_addr = top->dbg_addr;
		b_din  = top->dbg_din;
		b_dout = top->dbg_dout;
		b_rs232 = top->dbg_rs232_en;

		bus.BeforeEval();
		blk.BeforeEval(main_time);
		input.BeforeEval();

		for (int i = 0; i < 64; i++) {
			if (status_pulse[i] > 0) {
				status |= (1ULL << i);
				if (--status_pulse[i] == 0) status &= ~(1ULL << i);
			}
		}
		top->status = status;
		top->RESET = reset_hold > 0;
		if (reset_hold > 0) reset_hold--;
	}

	top->CLK_114 = c114;
	top->CLK_57  = c57;
	top->CLK_28  = c28;
	top->CLK_14  = c14;
	top->CLK_50M = clk50;
	top->eval();
#if VM_TRACE_VCD
	if (tfp && video.count_frame >= trace_from &&
	    (trace_until < 0 || video.count_frame <= trace_until))
		tfp->dump(main_time);
#endif

	if (sys_rise) {
		bus.AfterEval();
		blk.AfterEval();
		audio.Clock((int16_t)top->AUDIO_L, (int16_t)top->AUDIO_R);
		top->uart_rxd = serial.clock(top->uart_txd, top->dbg_acia_ctl, top->dbg_acia_cmd,
		                             video.count_frame);

		if (b_ena) {
			if (trace_bus && in_trace_window()) {
				FILE* o = trace_file ? trace_file : stdout;
				fprintf(o, "%6d bus %c %04X %s %02X%s\n", video.count_frame, b_rw ? 'R' : 'W',
				        b_addr, b_rw ? "->" : "<-", b_rw ? b_din : b_dout, b_lic ? "  LIC" : "");
				trace_lines++;
			}
			shadow[b_addr] = b_rw ? b_din : b_dout;
			shadow_known[b_addr] = 1;
			if ((b_addr & 0xFFFC) == 0xFF68) {
				// $FF68-$FF6B only reach the 6551 when the Multi-Pak I/O select
				// (SCS, $FF7F bits 1:0) is slot 1. Count the ones that do not.
				acia_accesses++;
				if (!b_rs232) { acia_undecoded++; acia_undecoded_scs = top->dbg_mpi_scs; }
				if (trace_acia) {
					static const char* regs[4] = { "DATA", "STATUS", "CMD", "CTRL" };
					FILE* o = trace_file ? trace_file : stdout;
					fprintf(o, "%6d ACIA %c $%04X %-6s %s $%02X%s  SCS=%d CTL=$%02X CMD=$%02X pc=$%04X\n",
					        video.count_frame, b_rw ? 'R' : 'W', b_addr, regs[b_addr & 3],
					        b_rw ? "->" : "<-", b_rw ? b_din : b_dout,
					        b_rs232 ? "" : "  NOT DECODED", top->dbg_mpi_scs,
					        top->dbg_acia_ctl, top->dbg_acia_cmd, cur_pc);
				}
			}
			if (fetch_next) {
				// First cycle after the last cycle of an instruction: the
				// opcode fetch of the next one. The previous instruction's
				// bytes are all in the shadow by now.
				prev_pc = cur_pc;
				cur_pc = b_addr;
				if (have_prev && trace_cpu && in_trace_window()) emit_trace(prev_pc);
				have_prev = true;
				instr_count++;
				instr_count_frame++;
				fetch_next = false;
			}
			if (b_lic) fetch_next = true;
		}
		if (old_irqn && !top->dbg_irqn) irq_edges++;
		old_irqn = top->dbg_irqn;
	}

	if (pix_rise) {
		uint32_t colour = 0xFF000000 | (top->VGA_B << 16) | (top->VGA_G << 8) | top->VGA_R;
		video.Clock(top->VGA_HB, top->VGA_VB, top->VGA_HS, top->VGA_VS, colour);
	}

	main_time++;
}

//----------------------------------------------------------------------------
// Per-frame work
//----------------------------------------------------------------------------

static int last_frame_seen = -1;

static void on_frame(int frame) {
	apply_key_events(frame);
	serial.end_frame(frame);
	for (const SerialSend& ss : serial_sends)
		if (ss.frame == frame) serial.queue_rx(ss.bytes.data(), ss.bytes.size());
	if (frame_log)
		printf("FRAME %d hash=%016llx instr=%ld cycles=%ld\n", frame,
		       (unsigned long long)frame_hash(), instr_count_frame, ena_frame);
	instr_count_frame = 0;
	ena_frame = 0;
	for (int f : screenshot_frames)
		if (f == frame && !screenshots_taken.count(f)) {
			screenshots_taken.insert(f);
			save_screenshot(f);
		}
	for (int f : ascii_frames)
		if (f == frame) print_text_screen(f);
	if (frame == reset_at_frame) {
		printf("Reset at frame %d\n", frame);
		pulse_status(0);
	}
	if ((frame % 60) == 0) set_rtc();
	if (frame == cart_frame && !cart_path.empty()) {
		printf("Loading cartridge at frame %d: %s\n", frame, cart_path.c_str());
		bus.QueueDownload(cart_path, IDX_CART, true);
	}
}

// Edge counts over the last run_until_next_frame(), for the "no frame" report.
static long diag_hb, diag_vb, diag_hs, diag_vs, diag_ena, diag_reset;

static void run_until_next_frame() {
	int start = video.count_frame;
	// Long enough to cover the core's own power-on sequence (coco3fpga.sv holds
	// RESET_N for 143 ms and CPU_RESET for 286 ms) with margin: ~436 ms.
	long guard = 100L * 1000 * 1000;
	diag_hb = diag_vb = diag_hs = diag_vs = diag_ena = diag_reset = 0;
	while (video.count_frame == start && guard-- > 0) {
		uint8_t hb = top->VGA_HB, vb = top->VGA_VB, hs = top->VGA_HS, vs = top->VGA_VS;
		sim_step();
		diag_hb += hb != top->VGA_HB;
		diag_vb += vb != top->VGA_VB;
		diag_hs += hs != top->VGA_HS;
		diag_vs += vs != top->VGA_VS;
		diag_ena += top->dbg_ena;
		diag_reset += top->dbg_reset;
	}
	if (video.count_frame != last_frame_seen) {
		last_frame_seen = video.count_frame;
		on_frame(video.count_frame);
	}
}

//----------------------------------------------------------------------------
// Arguments
//----------------------------------------------------------------------------

static void print_usage(const char* argv0) {
	printf(
"Usage: %s [options]\n"
"\n"
"Mode\n"
"  --headless                 no window; run to --stop-at-frame\n"
"  --stop-at-frame N          exit after frame N\n"
"\n"
"ROMs (ioctl, as Main_MiSTer uploads them)\n"
"  --rom FILE                 CoCo3 ROM, 32K, index 0     (default roms/boot0.rom)\n"
"  --disk-rom FILE            Disk BASIC ROM, 8K, index 64 (default roms/boot1.rom)\n"
"  --font FILE                font override, index 3\n"
"\n"
"Media\n"
"  --cart FILE                Program Pak (.ccc), index 1; selects MPI slot 3\n"
"  --cart-frame N             load the cart at frame N, after boot (as the OSD/MGL do)\n"
"  --cas FILE                 cassette image (.cas), index 2\n"
"  --disk FILE  / --disk0..3  floppy drive 0..3 (.dsk); selects MPI slot 4\n"
"  --sdc FILE   / --sdc1      CoCoSDC drive 0/1 (.dsk/.vhd); selects MPI slot 2\n"
"  --disk-writable            let the sim write back to images\n"
"\n"
"Options (OSD)\n"
"  --mpi N                    Multi-Pak slot 2|3|4\n"
"  --mem N                    0=512K 1=1M 2=2M 3=16M\n"
"  --turbo N                  status turbo speed 0..6 (0 = CoCo controlled)\n"
"  --force-turbo              force the turbo setting\n"
"  --artifact N               0=MESS 1=simple 2=none\n"
"  --status HEX               set the whole status word\n"
"\n"
"Input\n"
"  --type F:TEXT              type TEXT starting at frame F; {RETURN}, {BREAK},\n"
"                             {CLEAR}, {UP}... send named keys\n"
"  --key-hold N               frames a typed key is held (default 2)\n"
"  --key-gap N                frames between typed keys (default 2)\n"
"  --return-gap N             extra frames after each RETURN (default 30)\n"
"  --reset-at-frame N         pulse the OSD reset at frame N\n"
"\n"
"Output\n"
"  --screenshot N             PNG at frame N (repeatable)\n"
"  --screenshot-prefix P      file prefix (default \"screenshot\")\n"
"  --ascii N                  print the 32x16 text screen at frame N (repeatable)\n"
"  --ascii-end                print it at exit\n"
"  --frame-log                per-frame framebuffer hash and instruction count\n"
"\n"
"Serial (RS-232 Pak: 6551 at $FF68-$FF6B)\n"
"  --serial-pty               bridge TXD/RXD to a pty (name printed at start)\n"
"  --serial-send F:HEX...     feed bytes into RXD at frame F, e.g. 300:23 00 01\n"
"  --serial-log FILE          one line per byte, with frame\n"
"  --serial-baud N            rate the far end sends RXD at (default: the 6551's TX rate)\n"
"  --serial-quiet             no SERIAL TX/RX lines on stdout\n"
"  --trace-acia               log every CPU access to $FF68-$FF6B\n"
"  --acia-any-slot            force $FF68-$FF6B to the 6551 in every MPI slot; only\n"
"                             matters on RTL from before the RS232_EN fix\n"
"\n"
"Speed\n"
"  --fast-clocks              run the 114 MHz memory domain at 57 MHz: ~2x faster;\n"
"                             CPU timing unchanged at normal speed (see README)\n"
"\n"
"Debug\n"
"  --trace-cpu [FILE]         disassembly trace, one line per instruction\n"
"  --trace-bus                one line per CPU bus cycle (to the same place)\n"
"  --trace-from N / --trace-until N / --trace-max N\n"
"  --vcd FILE                 waveform over the trace window (make TRACE=1)\n",
	argv0);
}

static int parse_args(int argc, char** argv) {
	int cart_or_disk_mpi = -1;
	int explicit_mpi = -1;
	for (int i = 1; i < argc; i++) {
		std::string a = argv[i];
		auto next = [&]() -> const char* {
			if (i + 1 >= argc) { fprintf(stderr, "%s needs an argument\n", a.c_str()); exit(1); }
			return argv[++i];
		};
		if (a == "-h" || a == "--help") { print_usage(argv[0]); return 1; }
		else if (a == "--headless")        headless = true;
		else if (a == "--stop-at-frame")   stop_at_frame = atoi(next());
		else if (a == "--rom")             rom_path = next();
		else if (a == "--disk-rom")        diskrom_path = next();
		else if (a == "--font")            font_path = next();
		else if (a == "--cart")          { cart_path = next(); cart_or_disk_mpi = 1; }
		else if (a == "--cas")             cas_path = next();
		else if (a == "--cart-frame")      cart_frame = atoi(next());
		else if (a == "--disk" || a == "--disk0") { fdc_path[0] = next(); cart_or_disk_mpi = 2; }
		else if (a == "--disk1")           fdc_path[1] = next();
		else if (a == "--disk2")           fdc_path[2] = next();
		else if (a == "--disk3")           fdc_path[3] = next();
		else if (a == "--sdc" || a == "--sdc0") { sdc_path[0] = next(); cart_or_disk_mpi = 0; }
		else if (a == "--sdc1")            sdc_path[1] = next();
		else if (a == "--disk-writable")   disk_persist_writes = true;
		else if (a == "--mpi")             explicit_mpi = atoi(next()) - 2;
		else if (a == "--mem")             set_status_field(25, 3, atoi(next()) & 3);
		else if (a == "--turbo")           set_status_field(32, 3, atoi(next()) & 7);
		else if (a == "--force-turbo")     set_status_field(24, 1, 1);
		else if (a == "--artifact")        set_status_field(37, 2, atoi(next()) & 3);
		else if (a == "--status")          status = strtoull(next(), nullptr, 16);
		else if (a == "--type") {
			const char* v = next();
			const char* colon = strchr(v, ':');
			if (!colon) { fprintf(stderr, "--type wants FRAME:TEXT\n"); exit(1); }
			// Accept literal "\n" in the text as RETURN.
			std::string t(colon + 1), u;
			for (size_t j = 0; j < t.size(); j++) {
				if (t[j] == '\\' && j + 1 < t.size() && t[j + 1] == 'n') { u += '\n'; j++; }
				else u += t[j];
			}
			schedule_text(atoi(v), u);
		}
		else if (a == "--key-hold")        key_hold_frames = atoi(next());
		else if (a == "--key-gap")         key_gap_frames = atoi(next());
		else if (a == "--return-gap")      return_gap_frames = atoi(next());
		else if (a == "--reset-at-frame")  reset_at_frame = atoi(next());
		else if (a == "--screenshot")      screenshot_frames.push_back(atoi(next()));
		else if (a == "--screenshot-prefix") screenshot_prefix = next();
		else if (a == "--ascii")           ascii_frames.push_back(atoi(next()));
		else if (a == "--ascii-end")       ascii_at_end = true;
		else if (a == "--frame-log")       frame_log = true;
		else if (a == "--trace-cpu") {
			trace_cpu = true;
			if (i + 1 < argc && argv[i + 1][0] != '-') {
				trace_file = fopen(argv[++i], "w");
				if (!trace_file) { perror(argv[i]); exit(1); }
			}
		}
		else if (a == "--trace-bus")       trace_bus = true;
		else if (a == "--trace-from")      trace_from = atoi(next());
		else if (a == "--trace-until")     trace_until = atoi(next());
		else if (a == "--trace-max")       trace_max = atol(next());
		else if (a == "--vcd")             vcd_path = next();
		else if (a == "--serial-pty")      serial_pty = true;
		else if (a == "--fast-clocks")     fast_clocks = true;
		else if (a == "--acia-any-slot") {
			// sim.v picks this up with $test$plusargs at time 0.
			const char* plus[] = { "+acia_any_slot" };
			Verilated::commandArgsAdd(1, plus);
		}
		else if (a == "--serial-quiet")    serial.print_bytes = false;
		else if (a == "--serial-baud")     serial.line_bit_clks = (long)(57272727.0 / atof(next()) + 0.5);
		else if (a == "--trace-acia")      trace_acia = true;
		else if (a == "--serial-log") {
			serial.log_file = fopen(next(), "w");
			if (!serial.log_file) { perror(argv[i]); exit(1); }
		}
		else if (a == "--serial-send") {
			const char* v = next();
			const char* colon = strchr(v, ':');
			if (!colon) { fprintf(stderr, "--serial-send wants FRAME:HEX...\n"); exit(1); }
			SerialSend ss;
			ss.frame = atoi(v);
			for (const char* q = colon + 1; *q; ) {
				while (*q == ' ' || *q == ',') q++;
				if (!*q) break;
				char* end;
				long b = strtol(q, &end, 16);
				if (end == q) { fprintf(stderr, "--serial-send: bad hex at \"%s\"\n", q); exit(1); }
				ss.bytes.push_back((uint8_t)b);
				q = end;
			}
			serial_sends.push_back(ss);
		}
		else { fprintf(stderr, "Unknown option %s (try --help)\n", a.c_str()); exit(1); }
	}
	// MPI slot: status[13:12] + 1 is the slot index 1..3 (= slots 2..4).
	int mpi = explicit_mpi >= 0 ? explicit_mpi : cart_or_disk_mpi;
	if (mpi >= 0) set_status_field(12, 2, mpi);
	std::stable_sort(key_events.begin(), key_events.end(),
	                 [](const KeyEvent& x, const KeyEvent& y) { return x.frame < y.frame; });
	return 0;
}

static void print_serial_summary() {
	long clks = SerialPort::bit_clks(serial.ctl);
	printf("Serial: TX %ld bytes, RX %ld bytes; 6551 CTL=$%02X CMD=$%02X (%.0f baud); "
	       "CPU accesses to $FF68-$FF6B: %ld",
	       serial.tx_count, serial.rx_count, serial.ctl, serial.cmd,
	       SerialPort::baud(clks), acia_accesses);
	if (serial.tx_framing_errors) printf(", %ld TX framing errors", serial.tx_framing_errors);
	printf("\n");
	long rx = SerialPort::rx_bit_clks(serial.ctl), line = serial.line_clks();
	if (serial.ctl && (rx * 100 < line * 97 || rx * 100 > line * 103))
		printf("Serial: WARNING the 6551 receiver is clocked at %.0f baud but the line "
		       "runs at %.0f (--serial-baud) -- received bytes will be garbage\n",
		       SerialPort::baud(rx), SerialPort::baud(line));
	if (acia_undecoded)
		printf("Serial: %ld of those were NOT decoded to the 6551 (Multi-Pak SCS was %d, slot %d)\n",
		       acia_undecoded, acia_undecoded_scs, acia_undecoded_scs + 1);
}

//----------------------------------------------------------------------------
// Windowed UI
//----------------------------------------------------------------------------

#ifndef _MSC_VER
static int ui_frames_to_run = 0;

static void draw_video_window() {
	ImGui::Begin("CoCo3");
	ImGui::Text("frame %d   %.1f fps   active %dx%d", video.count_frame, video.stats_fps,
	            video.stats_xMax, video.stats_yMax);
	float w = ImGui::GetContentRegionAvail().x;
	if (w < VIDEO_WIDTH) w = VIDEO_WIDTH;
	ImGui::Image(video.texture_id, ImVec2(w, w * (VIDEO_HEIGHT * 2.0f) / VIDEO_WIDTH));
	ImGui::End();
}

static void draw_cpu_window() {
	ImGui::Begin("CPU / GIME");
	char cc[9];
	cc6809_string(top->dbg_cc, cc);
	ImGui::Text("PC %04X   A %02X  B %02X  DP %02X  CC %s", cur_pc, top->dbg_a, top->dbg_b, top->dbg_dp, cc);
	ImGui::Text("X %04X  Y %04X  U %04X  S %04X", top->dbg_x, top->dbg_y, top->dbg_u, top->dbg_s);
	ImGui::Text("IRQ %s  FIRQ %s  reset %d", top->dbg_irqn ? "-" : "LOW", top->dbg_firqn ? "-" : "LOW",
	            top->dbg_reset);
	ImGui::Text("$FF90 %02X   CPU speed %d", top->dbg_gime_init0, top->dbg_speed);
	ImGui::Text("instructions %ld   IRQs %ld", instr_count, irq_edges);
	ImGui::Separator();
	// Disassembly from the current PC through the bus shadow.
	uint16_t pc = cur_pc;
	for (int n = 0; n < 12; n++) {
		char line[64];
		int len = dis6809(pc, rd_shadow, line, sizeof(line));
		ImGui::Text("%s%04X  %s", n == 0 ? ">" : " ", pc, line);
		pc += len > 0 ? len : 1;
	}
	ImGui::End();
}

static void draw_hex(const char* label, const std::vector<uint8_t>& v) {
	ImGui::Text("%s (last %zu)", label, v.size() < 256 ? v.size() : (size_t)256);
	ImGui::BeginChild(label, ImVec2(0, 120), true);
	size_t start = v.size() > 256 ? v.size() - 256 : 0;
	for (size_t i = start; i < v.size(); i += 16) {
		char hex[16 * 3 + 1] = {0}, asc[17] = {0};
		for (size_t j = 0; j < 16 && i + j < v.size(); j++) {
			snprintf(hex + j * 3, 4, "%02X ", v[i + j]);
			asc[j] = (v[i + j] >= 0x20 && v[i + j] < 0x7f) ? (char)v[i + j] : '.';
		}
		ImGui::Text("%-48s %s", hex, asc);
	}
	ImGui::SetScrollHereY(1.0f);
	ImGui::EndChild();
}

static void draw_serial_window() {
	ImGui::Begin("Serial (RS-232 Pak)");
	long clks = SerialPort::bit_clks(serial.ctl);
	ImGui::Text("pty: %s", serial.pty_name.empty() ? "(none; --serial-pty)" : serial.pty_name.c_str());
	ImGui::Text("CTL $%02X  CMD $%02X  %.0f baud  RTS %d DTR %d  MPI SCS %d",
	            serial.ctl, serial.cmd, SerialPort::baud(clks), top->uart_rts, top->uart_dtr,
	            top->dbg_mpi_scs);
	ImGui::Text("TX %ld  RX %ld  $FF68 accesses %ld (%ld not decoded)",
	            serial.tx_count, serial.rx_count, acia_accesses, acia_undecoded);
	ImGui::Checkbox("Log ACIA accesses to stdout", &trace_acia);
	draw_hex("TX", serial.tx_hist);
	draw_hex("RX", serial.rx_hist);
	ImGui::End();
}

static void draw_control_window() {
	ImGui::Begin("Control");
	if (ImGui::Button(run_enable ? "Pause" : "Run")) run_enable = !run_enable;
	ImGui::SameLine();
	if (ImGui::Button("Step frame")) ui_frames_to_run = 1;
	ImGui::SameLine();
	if (ImGui::Button("Reset")) pulse_status(0);
	ImGui::SameLine();
	if (ImGui::Button("Cold boot")) pulse_status(22);
	ImGui::SameLine();
	if (ImGui::Button("Screenshot")) save_screenshot(video.count_frame);

	ImGui::Separator();
	int mpi = (int)get_status_field(12, 2);
	const char* mpi_items[] = { "Slot 2: CoCoSDC", "Slot 3: ECB / Cart", "Slot 4: Disk" };
	if (ImGui::Combo("Multi-Pak", &mpi, mpi_items, 3)) set_status_field(12, 2, mpi);
	int mem = (int)get_status_field(25, 3);
	const char* mem_items[] = { "512K", "1M", "2M", "16M" };
	if (ImGui::Combo("Memory", &mem, mem_items, 4)) set_status_field(25, 3, mem);
	int turbo = (int)get_status_field(32, 3);
	const char* turbo_items[] = { "CoCo Ctrl", "0.89 MHz", "1.78 MHz", "2.86 MHz", "3.58 MHz", "7.16 MHz", "9.54 MHz" };
	if (ImGui::Combo("Turbo speed", &turbo, turbo_items, 7)) set_status_field(32, 3, turbo);
	bool force = get_status_field(24, 1);
	if (ImGui::Checkbox("Force turbo", &force)) set_status_field(24, 1, force);
	int art = (int)get_status_field(37, 2);
	const char* art_items[] = { "MESS", "Simple", "None" };
	if (ImGui::Combo("Artifacts", &art, art_items, 3)) set_status_field(37, 2, art);
	bool artset = get_status_field(18, 1);
	if (ImGui::Checkbox("Artifact colour set 1", &artset)) set_status_field(18, 1, artset);

	ImGui::Separator();
	if (ImGui::Button("Load cart...")) ImGuiFileDialog::Instance()->OpenDialog("cart", "Program Pak", ".ccc,.rom,.bin", ".");
	ImGui::SameLine();
	if (ImGui::Button("Load cassette...")) ImGuiFileDialog::Instance()->OpenDialog("cas", "Cassette", ".cas,.wav", ".");
	for (int d = 0; d < 4; d++) {
		char label[32];
		snprintf(label, sizeof(label), "Drive %d...", d);
		if (d) ImGui::SameLine();
		if (ImGui::Button(label)) {
			char key[16];
			snprintf(key, sizeof(key), "fdc%d", d);
			ImGuiFileDialog::Instance()->OpenDialog(key, "Floppy image", ".dsk", ".");
		}
	}
	if (ImGui::Button("SDC 0...")) ImGuiFileDialog::Instance()->OpenDialog("sdc0", "SDC image", ".dsk,.vhd", ".");
	ImGui::SameLine();
	if (ImGui::Button("SDC 1...")) ImGuiFileDialog::Instance()->OpenDialog("sdc1", "SDC image", ".dsk,.vhd", ".");

	auto dialog = [](const char* key, auto on_ok) {
		if (ImGuiFileDialog::Instance()->Display(key)) {
			if (ImGuiFileDialog::Instance()->IsOk()) on_ok(ImGuiFileDialog::Instance()->GetFilePathName());
			ImGuiFileDialog::Instance()->Close();
		}
	};
	dialog("cart", [](std::string p) { cart_path = p; bus.QueueDownload(p, IDX_CART, true); });
	dialog("cas",  [](std::string p) { cas_path = p; bus.QueueDownload(p, IDX_CAS, true); });
	dialog("fdc0", [](std::string p) { mount(BLK_FDC0 + 0, p); });
	dialog("fdc1", [](std::string p) { mount(BLK_FDC0 + 1, p); });
	dialog("fdc2", [](std::string p) { mount(BLK_FDC0 + 2, p); });
	dialog("fdc3", [](std::string p) { mount(BLK_FDC0 + 3, p); });
	dialog("sdc0", [](std::string p) { mount(BLK_SDC0 + 0, p); });
	dialog("sdc1", [](std::string p) { mount(BLK_SDC0 + 1, p); });

	ImGui::Separator();
	ImGui::Checkbox("CPU trace to stdout", &trace_cpu);
	ImGui::End();
}
#endif

//----------------------------------------------------------------------------
// main
//----------------------------------------------------------------------------

int main(int argc, char** argv, char** env) {
	Verilated::commandArgs(argc, argv);
	// Default Multi-Pak slot 4 (Disk), 512K. A fresh MiSTer config is slot 2
	// (CoCoSDC); slot 4 boots Disk BASIC from boot1.rom with no SDC image.
	set_status_field(12, 2, 2);
	if (parse_args(argc, argv)) return 0;

	top = new Vemu();

#if VM_TRACE_VCD
	if (!vcd_path.empty()) {
		Verilated::traceEverOn(true);
		tfp = new VerilatedVcdC;
		top->trace(tfp, 99);
		tfp->open(vcd_path.c_str());
	}
#else
	if (!vcd_path.empty())
		fprintf(stderr, "--vcd needs a TRACE=1 build: make clean && make TRACE=1\n");
#endif

	bus.ioctl_addr     = &top->ioctl_addr;
	bus.ioctl_index    = &top->ioctl_index;
	bus.ioctl_wait     = &top->ioctl_wait;
	bus.ioctl_download = &top->ioctl_download;
	bus.ioctl_wr       = &top->ioctl_wr;
	bus.ioctl_dout     = &top->ioctl_dout;
	input.ps2_key      = &top->ps2_key;
	// One ps2_key event becomes up to three serial bytes at ~12 kHz, about
	// 70k clk_sys cycles each. Space events so the FIFO never races ahead.
	input.keyEventWait = 250000;

	for (int i = 0; i < 7; i++) {
		blk.sd_lba[i]      = &top->sd_lba[i];
		blk.sd_buff_din[i] = &top->sd_buff_din[i];
	}
	blk.sd_rd        = &top->sd_rd;
	blk.sd_wr        = &top->sd_wr;
	blk.sd_ack       = &top->sd_ack;
	blk.sd_buff_addr = &top->sd_buff_addr;
	blk.sd_buff_dout = &top->sd_buff_dout;
	blk.sd_buff_wr   = &top->sd_buff_wr;
	blk.img_mounted  = &top->img_mounted;
	blk.img_readonly = &top->img_readonly;
	blk.img_size     = &top->img_size;

	// Main_MiSTer loads boot0.rom and boot1.rom when the core starts, before
	// any user media. The ROMs load while the CPU is already running (as on
	// hardware); the download is short enough that the reset below outlasts it.
	queue_rom(rom_path,     IDX_BOOT0, "CoCo3 ROM");
	queue_rom(diskrom_path, IDX_BOOT1, "Disk BASIC ROM");
	queue_rom(font_path,    IDX_FONT,  "font");
	if (cart_frame < 0) queue_rom(cart_path, IDX_CART, "cartridge");
	queue_rom(cas_path,     IDX_CAS,   "cassette");
	for (int d = 0; d < 4; d++) mount(BLK_FDC0 + d, fdc_path[d]);
	for (int d = 0; d < 2; d++) mount(BLK_SDC0 + d, sdc_path[d]);

	// Hold reset across the ROM download: 32K + 8K bytes at two clk_sys
	// cycles each, plus margin.
	reset_hold = 200000;
	set_rtc();
	top->uart_rxd = 1;
	if (serial_pty && !serial.open_pty()) return 1;

	if (headless) {
		output_ptr = (uint32_t*)calloc((size_t)VIDEO_WIDTH * VIDEO_HEIGHT, sizeof(uint32_t));
		if (stop_at_frame < 0) stop_at_frame = 300;
		time_t t0 = time(nullptr);
		while (video.count_frame <= stop_at_frame) {
			int before = video.count_frame;
			run_until_next_frame();
			if (video.count_frame == before) {
				fprintf(stderr, "No video frame produced -- the raster is not running.\n"
				        "  edges: HBLANK %ld VBLANK %ld HSYNC %ld VSYNC %ld;"
				        " steps with cpu_cycle_ena %ld, with CPU_RESET %ld\n",
				        diag_hb, diag_vb, diag_hs, diag_vs, diag_ena, diag_reset);
				break;
			}
			if ((video.count_frame % 50) == 0) {
				printf("frame %d (%lds)\n", video.count_frame, (long)(time(nullptr) - t0));
				fflush(stdout);
			}
		}
		if (ascii_at_end) print_text_screen(video.count_frame);
		print_serial_summary();
		printf("Finished at frame %d: %ld instructions, %ld IRQs, %lds, active %dx%d\n",
		       video.count_frame, instr_count, irq_edges, (long)(time(nullptr) - t0),
		       video.stats_xMax, video.stats_yMax);
		for (int f : screenshot_frames)
			if (!screenshots_taken.count(f))
				printf("Warning: never reached frame %d for screenshot\n", f);
		if (trace_file) fclose(trace_file);
#if VM_TRACE_VCD
		if (tfp) tfp->close();
#endif
		top->final();
		return 0;
	}

#ifndef _MSC_VER
	if (video.Initialise("CoCo3") == 1) return 1;
	audio.Initialise();

	bool done = false;
	while (!done) {
		SDL_Event event;
		while (SDL_PollEvent(&event)) {
			ImGui_ImplSDL2_ProcessEvent(&event);
			if (event.type == SDL_QUIT) done = true;
		}
		// Keys go to the CoCo only while the video window has focus, so typing
		// in a dialog does not also type at BASIC.
		if (!ImGui::GetIO().WantTextInput) input.Read();

		video.StartFrame();
		ImGui::NewFrame();

		if (run_enable || ui_frames_to_run > 0) {
			run_until_next_frame();
			if (ui_frames_to_run > 0) ui_frames_to_run--;
		}
		if (stop_at_frame >= 0 && video.count_frame > stop_at_frame) done = true;

		draw_video_window();
		draw_cpu_window();
		draw_control_window();
		draw_serial_window();
		console.Draw("Console", nullptr, ImVec2(600, 250));

		video.UpdateTexture();
	}

	audio.CleanUp();
	video.CleanUp();
#endif

	if (trace_file) fclose(trace_file);
#if VM_TRACE_VCD
	if (tfp) { tfp->close(); delete tfp; }
#endif
	top->final();
	delete top;
	return 0;
}
