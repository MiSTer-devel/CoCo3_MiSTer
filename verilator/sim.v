//============================================================================
//  CoCo3 Verilator simulation wrapper
//
//  Stands in for CoCo3.sv (the MiSTer top level) without the sys/ framework:
//  no hps_io, no PLL, no video_mixer. sim_main.cpp drives the clocks and the
//  ioctl/block-device/keyboard ports; everything between those and the core
//  is wired the way CoCo3.sv wires it, with the OSD `status` word decoded
//  here by the same expressions.
//
//  Deliberate differences from CoCo3.sv:
//    - CLK_114/57/28/14 come straight from sim_main instead of the PLL. The PLL
//      makes them 114.545454 / 57.272727 / 28.636363 / 14.318181 MHz, all
//      phase 0, i.e. exact /2 /4 /8 divisions of one clock, which is what
//      sim_main produces -- all four change in the same eval, so there is no
//      derived-clock race between domains. CLK_50M (rtc.sv, the UART) is
//      approximated by sim_main with a phase accumulator.
//    - rtl/sdram/sdram2.sv is replaced by verilator/rtl/sdram2.sv: the same
//      controller with an SDR chip model hung off it instead of SDRAM_* pins.
//    - hps_io's keyboard path is reproduced from its parts: ps2_key events are
//      turned into scan-code bytes and pushed into MiSTer's own ps2_device
//      (sys/hps_io.sv) clocked exactly as hps_io clocks it with PS2DIV(2400),
//      so cocokey.v sees the same PS/2 serial stream as on hardware.
//    - The VHDL entities are replaced by their Verilog conversions in this
//      directory: rtl/coco_rom.v, rtl/coco_sram.v. VDAC.v's altsyncram becomes an
//      equivalent registered dual-port RAM.
//============================================================================

`timescale 1ns / 1ps

module emu
(
	input         CLK_114,
	input         CLK_57,           // clk_sys
	input         CLK_28,
	input         CLK_14,
	input         CLK_50M,
	input         RESET,

	// The OSD status word, bit-for-bit as hps_io would present it.
	input  [63:0] status,
	input   [1:0] buttons,

	// [7:0] scancode, [8] extended, [9] pressed, [10] toggles per event
	input  [10:0] ps2_key,
	input  [24:0] ps2_mouse,

	input  [31:0] joy1,
	input  [31:0] joy2,
	input  [15:0] joya1,
	input  [15:0] joya2,

	input  [64:0] RTC,

	// HPS ioctl download
	input         ioctl_download,
	input         ioctl_wr,
	input  [24:0] ioctl_addr,
	input   [7:0] ioctl_dout,
	input   [7:0] ioctl_index,
	output        ioctl_wait,

	// MiSTer block device (VDNUM 7): 0-1 SDC, 2-5 floppy, 6 cassette write.
	// Widths match SimBlockDevice's member types.
	input  [15:0] img_mounted,
	input         img_readonly,
	input  [63:0] img_size,
	output [31:0] sd_lba [7],
	output [15:0] sd_rd,
	output [15:0] sd_wr,
	input  [15:0] sd_ack,
	input   [8:0] sd_buff_addr,
	input   [7:0] sd_buff_dout,
	output  [7:0] sd_buff_din [7],
	input         sd_buff_wr,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_HB,
	output        VGA_VB,
	output        CE_PIXEL,         // coco3fpga PIX_CLK: a clk_sys enable; sample RGB/syncs on a clk_sys rising edge when high

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,

	// RS-232 Pak (glb6551 at $FF68-$FF6B). On MiSTer these are the UART_* pins
	// of the sys framework (the FujiNet daemon's /dev/ttyS1); here sim_main
	// decodes TXD and drives RXD. Idle is 1.
	output        uart_txd,
	input         uart_rxd,
	output        uart_rts,
	output        uart_dtr,

	// ---- debug taps ----------------------------------------------------
	// Hierarchical reads into the core; nothing here drives it.
	output [15:0] dbg_pc,
	output  [7:0] dbg_a, dbg_b, dbg_cc, dbg_dp,
	output [15:0] dbg_x, dbg_y, dbg_u, dbg_s,
	output        dbg_lic,          // last instruction cycle
	output [15:0] dbg_addr,
	output  [7:0] dbg_din,          // data into the CPU
	output  [7:0] dbg_dout,         // data out of the CPU
	output        dbg_rw,           // 1 = read
	output        dbg_ena,          // cpu_cycle_ena: the CPU advances on this
	output        dbg_irqn,
	output        dbg_firqn,
	output        dbg_reset,        // CPU_RESET
	output  [7:0] dbg_gime_init0,   // $FF90
	output  [2:0] dbg_speed,        // assigned_turbo_speed

	// ACIA / Multi-Pak state, for the serial trace
	output        dbg_rs232_en,     // $FF68-$FF6B decoded to the 6551 this cycle
	output  [1:0] dbg_mpi_scs,      // $FF7F SCS (I/O slot, 0 = slot 1)
	output  [1:0] dbg_mpi_cts,      // $FF7F CTS (ROM slot)
	output  [7:0] dbg_acia_ctl,     // 6551 control register (baud in [3:0])
	output  [7:0] dbg_acia_cmd      // 6551 command register
);

// The OSD word as the core sees it. hps_io hands `status` over as a register;
// registering it here too keeps it off the top-level input path. Verilator
// re-evaluates everything combinational on a top-level input at EVERY eval,
// and status feeds the video pixel mux (artifact/colour-set options), so as a
// raw input it cost ~20% of the run time.
reg [63:0] status_q = 64'd0;
always @(posedge CLK_14) status_q <= status;

//////////////////////////////////////////////////////////////////
// status decode -- copied from CoCo3.sv
//////////////////////////////////////////////////////////////////

wire clk_sys = CLK_57;

wire [2:0] turbo_speed = status_q[34:32];
wire [2:0] assigned_turbo_speed;
wire [1:0] art = status_q[38:37];
wire [1:0] Auto_Mode = status_q[41:40];

wire AMW_ACK;

wire [1:0] mpi = status_q[13:12] + 1'b1;
wire CASS_REW_RECORD = status_q[14];
wire rs_swap = status_q[16];
wire cartint = status_q[19];
wire sg4v6 = status_q[21];

wire PHASE = status_q[18];

wire coldboot = status_q[22];

wire F_Turbo = status_q[24];
wire [2:0] Mem_Size = status_q[27:25];
wire SWAP_M_J = status_q[28];
wire display_debug = status_q[29];
wire UART_INPUT = status_q[30];

wire digitalJoy = status_q[23];
wire easter_egg = status_q[10];

reg  [2:0] mpi_d = 2'b00;
reg first_mpi_chg = 1'b0;
reg mpi_reset = 1'b0;

always @(negedge CLK_14) begin
	mpi_d <= mpi;
	mpi_reset <= 1'b0;
	if (~(mpi == mpi_d))
		if (~first_mpi_chg)
			first_mpi_chg <= 1'b1;
		else
			mpi_reset <= 1'b1;
end

reg  [2:0] Mem_Size_d = 3'b000;
reg first_mem_chg = 1'b0;
reg mem_reset = 1'b0;

always @(negedge CLK_14) begin
	Mem_Size_d <= Mem_Size;
	mem_reset <= 1'b0;
	if (~(Mem_Size == Mem_Size_d))
		if (~first_mem_chg)
			first_mem_chg <= 1'b1;
		else
			mem_reset <= 1'b1;
end

//	Set bit 9 to swap serial ports...
wire [9:0] switch = { cartint,UART_INPUT,art,sg4v6,rs_swap,CASS_REW_RECORD,mpi,1'b0};

wire reset = RESET | status_q[0] | buttons[1];

//////////////////////////////////////////////////////////////////
// Joysticks -- copied from CoCo3.sv
//////////////////////////////////////////////////////////////////

wire [9:0] center_joystick_y1 = 8'd128 + joya1[15:8];
wire [9:0] center_joystick_x1 = 8'd128 + joya1[7:0];
wire [9:0] center_joystick_y2 = 8'd128 + joya2[15:8];
wire [9:0] center_joystick_x2 = 8'd128 + joya2[7:0];

wire [31:0] coco_joy1 = status_q[6] ? joy2 : joy1;
wire [31:0] coco_joy2 = status_q[6] ? joy1 : joy2;

wire [15:0] coco_ajoy1 = status_q[6] ? {center_joystick_x2[7:0],center_joystick_y2[7:0]} : {center_joystick_x1[7:0],center_joystick_y1[7:0]};
wire [15:0] coco_ajoy2 = status_q[6] ? {center_joystick_x1[7:0],center_joystick_y1[7:0]} : {center_joystick_x2[7:0],center_joystick_y2[7:0]};

//////////////////////////////////////////////////////////////////
// Keyboard: ps2_key -> PS/2 serial, the way hps_io produces it
//////////////////////////////////////////////////////////////////

reg clk_ps2 = 1'b0;
reg [11:0] ps2_div = 12'd0;
always @(posedge clk_sys) begin
	ps2_div <= ps2_div + 1'd1;
	if (ps2_div == 12'd2400) begin      // hps_io PS2DIV
		clk_ps2 <= ~clk_ps2;
		ps2_div <= 12'd0;
	end
end

// One ps2_key event becomes [E0] [F0] code. Main_MiSTer hands hps_io the same
// bytes one at a time; here they go into ps2_device's FIFO on consecutive
// clk_sys cycles.
reg        old_ps2_stb = 1'b0;
reg  [1:0] kbd_seq = 2'd0;
reg        kbd_ext, kbd_rel;
reg  [7:0] kbd_code;
reg  [7:0] kbd_data;
reg        kbd_we = 1'b0;

always @(posedge clk_sys) begin
	kbd_we <= 1'b0;
	old_ps2_stb <= ps2_key[10];
	if (kbd_seq == 2'd0 && old_ps2_stb != ps2_key[10]) begin
		kbd_ext  <= ps2_key[8];
		kbd_rel  <= ~ps2_key[9];
		kbd_code <= ps2_key[7:0];
		kbd_seq  <= 2'd1;
	end
	else if (kbd_seq == 2'd1) begin
		kbd_seq <= 2'd2;
		if (kbd_ext) begin kbd_data <= 8'hE0; kbd_we <= 1'b1; end
	end
	else if (kbd_seq == 2'd2) begin
		kbd_seq <= 2'd3;
		if (kbd_rel) begin kbd_data <= 8'hF0; kbd_we <= 1'b1; end
	end
	else if (kbd_seq == 2'd3) begin
		kbd_seq <= 2'd0;
		kbd_data <= kbd_code;
		kbd_we <= 1'b1;
	end
end

wire ps2_kbd_clk;
wire ps2_kbd_data;

ps2_device keyboard
(
	.clk_sys(clk_sys),
	.wdata(kbd_data),
	.we(kbd_we),
	.ps2_clk(clk_ps2),
	.ps2_clk_out(ps2_kbd_clk),
	.ps2_dat_out(ps2_kbd_data),
	.tx_empty(),
	.ps2_clk_in(1'b1),                  // PS2WE=0: host never talks back
	.ps2_dat_in(1'b1),
	.rdata(),
	.rd(1'b0)
);

//////////////////////////////////////////////////////////////////
// Core
//////////////////////////////////////////////////////////////////

wire	Programmed_RESET_N;
wire	Programmed_EE;

EE_Cold_Bt COCO3_EE_Cold_Bt (
	.CLK(CLK_14),
	.RESET(1'b0),
	.Display_EE(easter_egg),
	.Cold_Boot(AMW_ACK),
	.RESET_to_COCO_N(Programmed_RESET_N),
	.EE_to_COCO(Programmed_EE)
);

wire [15:0] audio_left;
wire [15:0] audio_right;
assign AUDIO_L = { audio_left[15:14], audio_left[13] ^ (status_q[17] ? casdout : 1'b0), audio_left[12:0]};
assign AUDIO_R = audio_right;

wire [7:0] r, g, b;
wire hblank, vblank, hs, vs, pix_clk;
wire [6:0] probe_o;

wire [71:0] Config_Data = {"SIMULATE", 8'h00};

wire [24:0] sdram_cpu_addr;
wire [15:0] sdram_dout;
wire  [7:0] sdram_cpu_din;
wire        sdram_cpu_req, sdram_cpu_rnw;
wire        sdram_cpu_ack, sdram_vid_ack;
wire        sdram_cpu_ready;
wire [24:0] sdram_vid_addr;
wire        sdram_vid_req;
wire        sdram_vid_ready;
wire        sdram_busy;

wire  [6:0] sd_rd_c, sd_wr_c;
wire  [5:0] sd_blk_cnt [7];
assign sd_rd = {9'd0, sd_rd_c};
assign sd_wr = {9'd0, sd_wr_c};

wire clk_Q_out;
wire casdout;
wire cas_relay;

wire UART_TXD, UART_RTS, UART_DTR;

coco3fpga coco3 (
	.CLK_50M(CLK_50M),
	.CLK_114(CLK_114),
	.CLK_57(CLK_57),
	.CLK_28(CLK_28),
	.CLK_14(CLK_14),

	.COCO_RESET_N((~reset & Programmed_RESET_N)),

	.RED_O(r),
	.GREEN_O(g),
	.BLUE_O(b),

	.EE_N(Programmed_EE),
	.PHASE(PHASE),

	.H_SYNC(hs),
	.V_SYNC(vs),
	.HBLANK(hblank),
	.VBLANK(vblank),
	.PIX_CLK(pix_clk),

	.ps2_clk(ps2_kbd_clk),
	.ps2_data(ps2_kbd_data),
	.ps2_mouse(ps2_mouse),

	.joy_use_dpad(digitalJoy),
	.joy1(coco_joy1[15:0]),
	.joy2(coco_joy2[15:0]),
	.joya1(coco_ajoy1),
	.joya2(coco_ajoy2),
	.SWAP_M_J(SWAP_M_J),

	// R1, L2, R2, L1
	.P_SWITCH(~{coco_joy2[4],coco_joy1[5],coco_joy2[5],coco_joy1[4]}),
	.SWITCH(switch),
	.SOUND_LEFT(audio_left),
	.SOUND_RIGHT(audio_right),

	.ioctl_addr(ioctl_addr),
	.ioctl_data(ioctl_dout),
	.ioctl_download(ioctl_download),
	.ioctl_index({8'd0, ioctl_index}),
	.ioctl_wr(ioctl_wr),

	.sdram_sz(16'h8001),                 // SDRAM present, 32 MB

	.img_mounted(img_mounted[6:0]),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.sd_lba(sd_lba),
	.sd_blk_cnt(sd_blk_cnt),
	.sd_rd(sd_rd_c),
	.sd_wr(sd_wr_c),
	.sd_ack(sd_ack[6:0]),

	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),

	.GPIO(),

	.PROBE_O(probe_o),
	.PROBE_I(7'h7F),                     // SNAC (USER_IN) pins idle high
	.clk_Q_out(clk_Q_out),
	.casdout(casdout),
	.cas_relay(cas_relay),

	.sdram_cpu_addr(sdram_cpu_addr),
	.sdram_dout(sdram_dout),
	.sdram_cpu_din(sdram_cpu_din),
	.sdram_cpu_req(sdram_cpu_req),
	.sdram_cpu_rnw(sdram_cpu_rnw),
	.sdram_cpu_ack(sdram_cpu_ack),
	.sdram_cpu_ready(sdram_cpu_ready),

	.sdram_vid_addr(sdram_vid_addr),
	.sdram_vid_req(sdram_vid_req),
	.sdram_vid_ack(sdram_vid_ack),
	.sdram_vid_ready(sdram_vid_ready),

	.sdram_busy(sdram_busy),

	.turbo_speed(turbo_speed),
	.assigned_turbo_speed(assigned_turbo_speed),

	.RTC(RTC),

	.AMW_Trigger(coldboot | mpi_reset | mem_reset),
	.AMW_ACK(AMW_ACK),

	.F_Turbo(F_Turbo),
	.Mem_Size(Mem_Size),
	.AUTO_MODE(Auto_Mode),
	.Config_Data(Config_Data),
	.Display_Debug(display_debug),

	.UART_TXD(UART_TXD),
	.UART_RXD(uart_rxd),
	.UART_RTS(UART_RTS),
	.UART_CTS(1'b0),                    // active low: always clear to send
	.UART_DTR(UART_DTR),
	.UART_DSR(1'b0)
);

sdram_32r8w coco3_sdram
(
	.init(reset),
	.clk(CLK_114),
	.sdram_cpu_addr(sdram_cpu_addr),
	.sdram_dout(sdram_dout),
	.sdram_cpu_din(sdram_cpu_din),
	.sdram_cpu_req(sdram_cpu_req),
	.sdram_cpu_rnw(sdram_cpu_rnw),
	.sdram_cpu_ack(sdram_cpu_ack),
	.sdram_cpu_ready(sdram_cpu_ready),
	.sdram_vid_addr(sdram_vid_addr),
	.sdram_vid_req(sdram_vid_req),
	.sdram_vid_ack(sdram_vid_ack),
	.sdram_vid_ready(sdram_vid_ready),
	.sdram_busy(sdram_busy)
);

//////////////////////////////////////////////////////////////////
// Cassette -- copied from CoCo3.sv
//////////////////////////////////////////////////////////////////

wire load_tape = ioctl_index == 2;

wire [15:0] ram_addr;
wire  [7:0] ram_data_o;
reg         ram_wr;
reg  [15:0] ram_ad_buf;

always @(posedge clk_sys) begin
	ram_wr <= ~(ioctl_wr & load_tape);
	if (ioctl_download)
		ram_ad_buf <= ioctl_addr[15:0];
	else
		ram_ad_buf <= ram_addr;
end

COCO_SRAM CC3_CAS1(
	.CLK(clk_sys),
	.ADDR(ram_ad_buf),
	.R_W(ram_wr),
	.DATA_I(ioctl_dout),
	.DATA_O(ram_data_o)
);

cassette cassette(
	.clk(clk_sys),
	.Q(clk_Q_out),
	.rewind(status_q[15]|~ram_wr),
	.en(cas_relay),
	.sdram_addr(ram_addr),
	.sdram_data(ram_data_o),
	.data(casdout)
);

assign ioctl_wait = 1'b0;

//////////////////////////////////////////////////////////////////
// Video out
//////////////////////////////////////////////////////////////////

assign VGA_R    = r;
assign VGA_G    = g;
assign VGA_B    = b;
assign VGA_HS   = hs;
assign VGA_VS   = vs;
assign VGA_HB   = hblank;
assign VGA_VB   = vblank;
assign CE_PIXEL = pix_clk;

//////////////////////////////////////////////////////////////////
// Debug taps
//////////////////////////////////////////////////////////////////

assign dbg_pc    = coco3.GLBCPU09.pc;
assign dbg_a     = coco3.GLBCPU09.a;
assign dbg_b     = coco3.GLBCPU09.b;
assign dbg_x     = coco3.GLBCPU09.x;
assign dbg_y     = coco3.GLBCPU09.y;
assign dbg_u     = coco3.GLBCPU09.u;
assign dbg_s     = coco3.GLBCPU09.s;
assign dbg_cc    = coco3.GLBCPU09.cc;
assign dbg_dp    = coco3.GLBCPU09.dp;
assign dbg_lic   = coco3.GLBCPU09.LIC;
assign dbg_addr  = coco3.ADDRESS;
assign dbg_din   = coco3.DATA_IN;
assign dbg_dout  = coco3.DATA_OUT;
assign dbg_rw    = coco3.RW_N;
assign dbg_ena   = coco3.cpu_cycle_ena;
assign dbg_irqn  = coco3.CPU_IRQ_N;
assign dbg_firqn = coco3.CPU_FIRQ_N;
assign dbg_reset = coco3.CPU_RESET;
assign dbg_gime_init0 = {coco3.COCO1, coco3.MMU_EN, coco3.GIME_IRQ, coco3.GIME_FIRQ,
                         coco3.VEC_PAG_RAM, coco3.ST_SCS, coco3.ROM};
assign dbg_speed = assigned_turbo_speed;

assign uart_txd     = UART_TXD;
assign uart_rts     = UART_RTS;
assign uart_dtr     = UART_DTR;
assign dbg_rs232_en = coco3.RS232_EN;
assign dbg_mpi_scs  = coco3.MPI_SCS;
assign dbg_mpi_cts  = coco3.MPI_CTS;
assign dbg_acia_ctl = coco3.RS232.CTL_REG;
assign dbg_acia_cmd = coco3.RS232.CMD_REG;

//////////////////////////////////////////////////////////////////
// FPGA power-up state
//
// Every register starts at 0 in this sim. Quartus does the same, EXCEPT for a
// register with an asynchronous set: it implements the set with NOT-gate
// push-back, so the register powers up at 1. Where that matters it is
// reproduced here.
//
// mc6809x NMILatched: active low (0 = NMI pending), in an
// `always @(negedge NMISample2 or posedge wNMIClear)` block whose async branch
// sets it. At 0 the CPU takes a phantom NMI on its first instruction -- the
// ORCC at the reset entry -- and vectors through $FFFC into uninitialised RAM.
//////////////////////////////////////////////////////////////////

initial coco3.GLBCPU09.NMILatched = 1'b1;

//////////////////////////////////////////////////////////////////
// +acia_any_slot (--acia-any-slot)
//
// coco3fpga.sv used to decode the RS-232 Pak at $FF68-$FF6B only when the
// Multi-Pak I/O select was slot 1 (MPI_SCS == 0), which the OSD cannot select,
// so a cart in slot 3 driving the 6551 -- HDB-DOS SY6551 for FujiNet -- talked
// to an empty bus. The RTL now decodes it in any slot, which makes this a no-op;
// it is kept for testing RTL from before that fix.
//////////////////////////////////////////////////////////////////

// The right-hand side of a procedural force is taken once, when the
// force executes (Verilator 5.044), so it is re-issued whenever the decode it follows
// changes. The net must also be `forceable` (sim.vlt) or the force is lost.
wire acia_any_slot_en = (coco3.ADDRESS[15:2] == 14'b11111111011010);
reg  acia_any_slot = 1'b0;
initial acia_any_slot = $test$plusargs("acia_any_slot");
always @(acia_any_slot_en or acia_any_slot)
	if (acia_any_slot) force coco3.RS232_EN = acia_any_slot_en;

endmodule
