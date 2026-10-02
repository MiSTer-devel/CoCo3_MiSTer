#pragma once
//============================================================================
//  RS-232 Pak (glb6551) line model for the CoCo3 sim.
//
//  Works on the pins, not on the registers: TXD is decoded as the far end of
//  the cable would see it, and RXD is driven bit by bit. So a byte is only
//  logged as transmitted if the 6551 really shifted it out, at the baud rate
//  it was really programmed for.
//
//  Clocked once per clk_sys (57.272727 MHz). Bit timing follows
//  rtl/UART_6551/uart_6551.v: a 1.8475 MHz enable (clk_sys / 31) feeds the
//  divider; the 6551 samples at 16x the bit rate.
//
//  Optional pty bridge: the slave side (/dev/ttysNNN) can be opened by a
//  DriveWire server or FujiNet-PC, or by socat to reach a TCP one. Note the sim
//  runs ~50x slower than real time, so the far end sees ~400 baud of real
//  throughput whatever the programmed rate is.
//============================================================================

#include <cstdint>
#include <cstdio>
#include <deque>
#include <string>
#include <vector>

struct SerialPort {
	// --- configuration -------------------------------------------------
	bool  print_bytes = true;           // SERIAL TX/RX lines on stdout
	FILE* log_file    = nullptr;        // --serial-log: one line per byte
	// Rate the far end sends at, in clk_sys cycles per bit. 0 = the rate the
	// 6551 transmits at, i.e. a peer configured to match. RXD is driven at this
	// rate whatever the 6551's RECEIVER is clocked at, so a receiver-clock
	// mismatch shows up as garbage, as it would on the cable.
	long  line_bit_clks = 0;
	long  line_clks() const { return line_bit_clks ? line_bit_clks : bit_clks(ctl); }

	// --- state visible to the UI ----------------------------------------
	std::string pty_name;
	long tx_count = 0, rx_count = 0;
	long tx_framing_errors = 0;
	std::vector<uint8_t> tx_hist, rx_hist;   // capped, for the Serial window
	uint8_t ctl = 0, cmd = 0;                // last seen 6551 registers

	// Bits per word and clk_sys cycles per bit for a control/command value.
	static int  data_bits(uint8_t ctl) { return 8 - ((ctl >> 5) & 3); }
	static long bit_clks(uint8_t ctl);       // transmitter / internal generator
	static long rx_bit_clks(uint8_t ctl);    // receiver (CTL bit 4 picks the source)
	static double baud(long clks);

	bool open_pty();
	void queue_rx(const uint8_t* p, size_t n);

	// One clk_sys cycle. Returns the level to drive on RXD.
	uint8_t clock(uint8_t txd, uint8_t ctl, uint8_t cmd, int frame);

	// Flush the per-frame byte lines.
	void end_frame(int frame);

private:
	// TX decoder
	int      tx_phase = 0;                   // 0 idle, 1 start, 2 data, 3 parity, 4 stop
	long     tx_timer = 0;
	int      tx_bitn = 0;
	uint16_t tx_shift = 0;
	uint8_t  tx_last = 1;
	// RX driver
	std::deque<uint8_t> rx_queue;
	uint16_t rx_frame = 0;                   // bits to send, LSB first
	int      rx_bits_left = 0;
	long     rx_timer = 0;
	uint8_t  rx_level = 1;
	// pty
	int      pty_fd = -1, pty_slave_fd = -1;
	long     poll_timer = 0;
	// per-frame print buffers
	std::vector<uint8_t> tx_line, rx_line;

	void got_tx_byte(uint8_t b, bool framing_ok, int frame);
	void poll_pty();
	void print_line(const char* dir, std::vector<uint8_t>& v, int frame);
};
