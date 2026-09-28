#include "serial.h"

#include <algorithm>
#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>

static const double CLK_SYS_HZ = 57272727.0;
static const int    XTAL_DIV   = 31;          // coco3fpga.sv CLK_6551_EN
static const size_t HIST_MAX   = 4096;

// uart_6551.v: TX_CLK_DIV wraps after this many enables for CTL[3:0]; the
// baud clock toggles on each wrap and pulses on every second one.
static const int wrap_enables[16] = {
	0, 1152, 768, 524, 428, 384, 192, 96, 48, 32, 24, 16, 12, 8, 6, 3
};

long SerialPort::bit_clks(uint8_t ctl) {
	int sel = ctl & 0x0F;
	// CTL[3:0] == 0: "16x external clock", which in this core is the
	// 1.8475 MHz enable itself -- 115,469 baud.
	long enables_per_16x = sel ? 2L * wrap_enables[sel] : 1L;
	return XTAL_DIV * enables_per_16x * 16;
}

long SerialPort::rx_bit_clks(uint8_t ctl) {
	// uart_6551.v: RX_CLK = TX_CLK, i.e. the receiver always runs off the baud
	// generator. (It used to take the "external" 1.8475 MHz clock when CTL bit 4
	// was 0, which made CTL=$0F transmit at 19,200 but receive at 115,200.)
	return bit_clks(ctl);
}

double SerialPort::baud(long clks) { return CLK_SYS_HZ / (double)clks; }

bool SerialPort::open_pty() {
	pty_fd = posix_openpt(O_RDWR | O_NOCTTY);
	if (pty_fd < 0 || grantpt(pty_fd) < 0 || unlockpt(pty_fd) < 0) {
		perror("serial: posix_openpt");
		return false;
	}
	const char* name = ptsname(pty_fd);
	if (!name) { perror("serial: ptsname"); return false; }
	pty_name = name;
	// Hold the slave open ourselves: otherwise reads on the master return EIO
	// until something connects, and again whenever the far end reconnects.
	pty_slave_fd = open(name, O_RDWR | O_NOCTTY);
	if (pty_slave_fd >= 0) {
		struct termios t;
		if (tcgetattr(pty_slave_fd, &t) == 0) {
			cfmakeraw(&t);
			tcsetattr(pty_slave_fd, TCSANOW, &t);
		}
	}
	fcntl(pty_fd, F_SETFL, fcntl(pty_fd, F_GETFL) | O_NONBLOCK);
	printf("Serial: RS-232 Pak on pty %s\n", name);
	fflush(stdout);
	return true;
}

void SerialPort::queue_rx(const uint8_t* p, size_t n) {
	rx_queue.insert(rx_queue.end(), p, p + n);
}

void SerialPort::poll_pty() {
	if (pty_fd < 0) return;
	uint8_t buf[256];
	ssize_t n = read(pty_fd, buf, sizeof(buf));
	if (n > 0) queue_rx(buf, (size_t)n);
}

void SerialPort::got_tx_byte(uint8_t b, bool framing_ok, int frame) {
	tx_count++;
	if (!framing_ok) tx_framing_errors++;
	tx_hist.push_back(b);
	if (tx_hist.size() > HIST_MAX) tx_hist.erase(tx_hist.begin());
	tx_line.push_back(b);
	if (log_file)
		fprintf(log_file, "%6d TX %02X%s\n", frame, b, framing_ok ? "" : "  framing error");
	if (pty_fd >= 0) {
		ssize_t w = write(pty_fd, &b, 1);
		(void)w;
	}
}

uint8_t SerialPort::clock(uint8_t txd, uint8_t ctl_now, uint8_t cmd_now, int frame) {
	ctl = ctl_now;
	cmd = cmd_now;

	// ---- TX: decode what the 6551 puts on the pin ---------------------
	const long bclk = bit_clks(ctl);
	switch (tx_phase) {
	case 0:
		if (tx_last && !txd) { tx_phase = 1; tx_timer = bclk / 2; }
		break;
	case 1:                                   // middle of the start bit
		if (--tx_timer <= 0) {
			if (txd) tx_phase = 0;                // glitch, not a start bit
			else { tx_phase = 2; tx_timer = bclk; tx_bitn = 0; tx_shift = 0; }
		}
		break;
	case 2:                                   // data bits, LSB first
		if (--tx_timer <= 0) {
			tx_shift |= (uint16_t)(txd & 1) << tx_bitn;
			tx_timer = bclk;
			if (++tx_bitn == data_bits(ctl)) tx_phase = (cmd & 0x20) ? 3 : 4;
		}
		break;
	case 3:                                   // parity (not checked)
		if (--tx_timer <= 0) { tx_phase = 4; tx_timer = bclk; }
		break;
	case 4:                                   // stop bit
		if (--tx_timer <= 0) {
			got_tx_byte((uint8_t)tx_shift, txd != 0, frame);
			tx_phase = 0;
		}
		break;
	}
	tx_last = txd;

	// ---- RX: drive the pin, 8N1 at the far end's rate -------------------
	if (++poll_timer >= 4096) { poll_timer = 0; poll_pty(); }
	if (rx_timer > 0) rx_timer--;
	if (rx_timer == 0) {
		if (rx_bits_left == 0 && !rx_queue.empty()) {
			uint8_t b = rx_queue.front();
			rx_queue.pop_front();
			rx_count++;
			rx_hist.push_back(b);
			if (rx_hist.size() > HIST_MAX) rx_hist.erase(rx_hist.begin());
			rx_line.push_back(b);
			if (log_file) fprintf(log_file, "%6d RX %02X\n", frame, b);
			rx_frame = (uint16_t)(1u << 9) | ((uint16_t)b << 1);   // start 0, data, stop 1
			rx_bits_left = 10;
		}
		if (rx_bits_left > 0) {
			// Each bit, the stop bit included, is held for a full bit time.
			rx_level = rx_frame & 1;
			rx_frame >>= 1;
			rx_bits_left--;
			rx_timer = line_clks();
		} else {
			rx_level = 1;
		}
	}
	return rx_level;
}

void SerialPort::print_line(const char* dir, std::vector<uint8_t>& v, int frame) {
	if (v.empty()) return;
	if (print_bytes) {
		for (size_t i = 0; i < v.size(); i += 16) {
			char hex[16 * 3 + 1] = {0}, asc[17] = {0};
			size_t n = std::min<size_t>(16, v.size() - i);
			for (size_t j = 0; j < n; j++) {
				uint8_t c = v[i + j];
				snprintf(hex + j * 3, 4, "%02X ", c);
				asc[j] = (c >= 0x20 && c < 0x7f) ? (char)c : '.';
			}
			printf("SERIAL %s %6d  %-48s |%s|\n", dir, frame, hex, asc);
		}
		fflush(stdout);
	}
	v.clear();
}

void SerialPort::end_frame(int frame) {
	print_line("TX", tx_line, frame);
	print_line("RX", rx_line, frame);
}
