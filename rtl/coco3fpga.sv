////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 4.1.2
// File Name:		coco3fpga.v
//
// CoCo3 in an FPGA
//
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 4.1.2
//
// Copyright (c) 2008 Gary Becker (gary_l_becker@yahoo.com)
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
// The latest version of this file can be found at:
//      http://groups.yahoo.com/group/CoCo3FPGA
//
// File history :
//
//  1.0			Full Release
//  2.0			Partial Release
//  3.0			Full Release
//  3.0.0.1		Update to fix DoD interrupt issue
//	3.0.1.0		Update to fix 32/40 CoCO3 Text issue and add 2 Meg max memory
//	4.1.2.X		Fixed 6502 code for drivewire, removed timer, fixed 6551 baud 
//				rate (& DE2-115 compiler symbol)
//	5.x			15Khz video updated from GIME-X, clocking changes, SDRAM intigration
////////////////////////////////////////////////////////////////////////////////
// Gary Becker
// gary_L_becker@yahoo.com
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// MISTer Conversion by Stan Hodge and Alan Steremberg
// stan.pda@gmail.com
// 
// This code is a fork of the DE2-115 conversion.
////////////////////////////////////////////////////////////////////////////////



module coco3fpga(
// Input Clocks
//	CLOCKS

input				CLK_114,
input				CLK_57,
input				CLK_28,
input				CLK_14,

input				CLK50MHZ,

input 				COCO_RESET_N,

// Video

output	reg	[7:0]	RED,
output	reg	[7:0]	GREEN,
output	reg	[7:0]	BLUE,

output	reg			H_SYNC,
output	reg			V_SYNC,
output	reg			VGA_SYNC_N,
output	reg			VGA_BLANK_N,
output				PIX_CLK,
output				HBLANK,
output				VBLANK,

// PS/2
input				ps2_clk,
input				ps2_data,

// RS-232
output	UART_TXD,
input 	UART_RXD,
output 	UART_RTS,
input 	UART_CTS,
output	UART_DTR,
input 	UART_DSR,



output				DE1TXD,
input				DE1RXD,
output				OPTTXD,
input				OPTRXD,


output [5:0] SOUND_OUT,
output [15:0] SOUND_LEFT,
output [15:0] SOUND_RIGHT,

// CoCo Joystick
// Needs removal.... ???
input	[3:0]		PADDLE_CLK,
input	[3:0]		P_SWITCH,
input [15:0] joya1,
input [15:0] joya2,

//	Config Static switches
input	[9:0]  		SWITCH,			

// roms, cartridges, etc
input	[7:0]		ioctl_data,
input	[24:0]		ioctl_addr,
input				ioctl_download,
input				ioctl_wr,
input 	[15:0]		ioctl_index,

// SD block level interface
input   [3:0]  		img_mounted, // signaling that new image has been mounted
input				img_readonly, // mounted as read only. valid only for active bit in img_mounted
input 	[19:0] 		img_size,    // size of image in bytes. 1MB MAX!

output	[31:0] 		sd_lba[4],
output  [5:0] 		sd_blk_cnt[4], // number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!

output 	reg  [3:0]	sd_rd,
output 	reg  [3:0]	sd_wr,
input        [3:0]	sd_ack,

// SD byte level access. Signals for 2-PORT altsyncram.
input  	[8:0] 		sd_buff_addr,
input  	[7:0] 		sd_buff_dout,
output 	[7:0] 		sd_buff_din[4],
input        		sd_buff_wr,

//	GPIO
inout	[7:0]		GPIO,

//  Misc
input				EE_N,
input				PHASE,
output	[31:0]		PROBE,

//  Cassette
output				clk_Q_out,
output				cas_relay,
input				casdout,

//	SDRAM

output	[24:0]		sdram_cpu_addr,
//input	[31:0]		sdram_ldout,
input	[15:0]		sdram_dout,
output	[7:0]		sdram_cpu_din,
output				sdram_cpu_req,
output				sdram_cpu_rnw,
input				sdram_cpu_ack,
input				sdram_cpu_ready,

output	[24:0]		sdram_vid_addr,
output				sdram_vid_req,
input				sdram_vid_ack,
input				sdram_vid_ready,

input				sdram_busy,

input	[1:0]		turbo_speed

 
);



assign clk_Q_out = PH_2;
assign cas_relay = CAS_MTR;


//Version 5 bits Major and 4 bits Minor
parameter Version_Hi = 8'h50;


parameter Version_Lo = 8'h20;	// MiSTer
// High nibble = DE1 		= '0000'
// High nibble = DE2-115 	= '0001'
// High nibble = MISTer 	= '0010'

parameter BOARD_TYPE = 8'h01;	// No Riser - 2M
// Low nibble is minor version
// Analog Board
// High bit of lower nibble is Riser Type 0=Gary (or none) 1=Ed
// Next three bits is Memory size 000=128K, 001=One Meg or 512K or 2M (DE2-115) 101=5 Meg

////////////////////////////////////////////////////////////////////////////////

//	SRH	MISTer
// Use 128KB Internal SRAM
reg 	[19:0]	RAM0_ADDRESS;		// OUT 2MB SRAM.  Bit 19 unconnected on DE1, gives 1MB
//reg	 [19:0]	RAM0_ADDRESS;
reg				RAM0_RW_N;		// OUT
//reg				RAM0_RW_N;

// SRAM	paths to be delt with later in code  - convert to RAM0_DATA_I and RAM0_DATA_O
//inout		[15:0]	RAM0_DATA;	//OUT
//reg		[15:0]	RAM0_DATA;

reg		[15:0]	RAM0_DATA_O;
//reg			[15:0]	RAM0_DATA_O;

reg		[15:0]	RAM0_DATA_I;

wire			RAM_CS;						// DATA_IN Mux select
reg				RAM0_BE0_N;	// OUT
//reg					RAM0_BE0_N;
reg				RAM0_BE1_N;	// OUT
//reg					RAM0_BE1_N;

wire			RAM0_BE0;
wire			RAM0_BE1;

 
//Flash ROM
// SRH
wire	[22:0]	FLASH_ADDRESS;

//	SRH	MISTer
wire	[7:0]	FLASH_DATA;

// LEDs
// SRH DE2-115 has one extra Green LED
wire	[8:0]	LEDG;
//output	[9:0]		LEDR;
// SRH DE2-115 has 10 extra Red LED
wire	[17:0]	LEDR;

// Extra Buttons and Switches

//	SRH	MISTer
//	Static Buttons
wire   	[3:0]	 BUTTON_N;
											//  3 RESET
											//  2 SD Card Inserted (0=Inserted) wired to switche on the SD card
											//  1 SD Write Protect (1=Protected) wired to switche on the SD card
											//  0 Easter Egg
									
reg				CLK3_57MHZ;

//WiFi
wire 			WF_RXD;
wire 			WF_TXD;

wire			WF_RTS;
wire			EF;
wire			PH_2;
reg 			PH_2_RAW;
reg				RESET_N;
reg		[13:0]	RESET_SM;
reg		[6:0]	CPU_RESET_SM;
reg				CPU_RESET;
wire			RESET_INS;
reg				MUGS;
wire			RESET;
wire			RESET_P;
wire	[15:0]	ADDRESS;
wire	[9:0]	BLOCK_ADDRESS;		// 5:0 for 512kb
wire			RW_N;
wire	[7:0]	DATA_IN;
wire	[7:0]	DATA_OUT;
wire			VMAX;
wire			VMA;
reg		[5:0]	CLK;

// Gime Regs
reg		[1:0]	ROM;
reg				RAM;
reg				ST_SCS;
reg				VEC_PAG_RAM;
reg				GIME_FIRQ;
reg				GIME_IRQ;
reg				MMU_EN;
reg				COCO1;
reg		[2:0]	V;
reg		[6:0]	VERT;
reg				RATE;
reg				TIMER_INS;
reg				MMU_TR;
reg		[3:0]	TMR_MSB;
reg		[7:0]	TMR_LSB;
wire			TMR_RST;
reg				TMR_ENABLE;
reg		[15:0]	VIDEO_BUFFER;
reg				GRMODE;
reg				BLINK;
reg				HLPR;
reg		[2:0]	LPR;
reg		[1:0]	LPF;
reg		[3:0]	HRES;
reg		[1:0]	CRES;
reg		[3:0]	VERT_FIN_SCRL;
reg		[5:0]	SCRN_START_HSB;	// 4 extra bits for 4MB
reg		[7:0]	SCRN_START_MSB;
reg		[7:0]	SCRN_START_LSB;
reg		[6:0]	HOR_OFFSET;
reg				HVEN;
reg		[11:0]	PALETTE [16:0];
wire	[9:0]	COLOR;
reg		[9:0]	COLOR_BUF;
wire			H_SYNC_N;
wire			V_SYNC_N;
reg		[1:0]	SEL;
reg		[7:0]	KEY_COLUMN;
reg		[3:0]	VDG_CONTROL;
reg				CSS;
wire			BIT3;
reg				CAS_MTR;
reg				SOUND_EN;
wire	[24:0]	VIDEO_ADDRESS;		// 8MB   17:0 for 512kb
wire			FLASH_CE_S;

wire			ENA_DSK;
wire			ENA_ORCC;
wire			ENA_DISK2;
wire			ENA_PAK;

wire			HDD_EN;
wire			HDD_EN_DATA;

reg		[1:0]	MPI_SCS;				// IO select
reg		[1:0]	MPI_CTS;				// ROM select
reg		[1:0]	W_PROT;
reg				SBS;
reg		[9:0]	SAM00;	// 8MB    5:0 for 512kb   
reg		[9:0]	SAM01;
reg		[9:0]	SAM02;
reg		[9:0]	SAM03;
reg		[9:0]	SAM04;
reg		[9:0]	SAM05;
reg		[9:0]	SAM06;
reg		[9:0]	SAM07;
reg		[9:0]	SAM10;
reg		[9:0]	SAM11;
reg		[9:0]	SAM12;
reg		[9:0]	SAM13;
reg		[9:0]	SAM14;
reg		[9:0]	SAM15;
reg		[9:0]	SAM16;
reg		[9:0]	SAM17;
reg		[1:0]	SAM_EXT;
wire	[72:0]	KEY;
wire			SHIFT_OVERRIDE;
wire			SHIFT;
wire	[7:0]	KEYBOARD_IN;
reg				DDR1;
reg				DDR2;
reg				DDR3;
reg				DDR4;
wire	[7:0]	DATA_REG1;
wire	[7:0]	DATA_REG2;
wire	[7:0]	DATA_REG3;
wire	[7:0]	DATA_REG4;
reg		[7:0]	DD_REG1;
reg		[7:0]	DD_REG2;
reg		[7:0]	DD_REG3;
reg		[7:0]	DD_REG4;
wire			ROM_SEL;
reg		[5:0]	DTOA_CODE;
reg		[5:0]	SOUND_DTOA;

assign SOUND_OUT = SOUND_DTOA; // AJS - hook up sound directly

wire	[7:0]	SOUND;
wire	[18:0]	DAC_LEFT;
wire	[18:0]	DAC_RIGHT;
wire	[7:0]	VU;
wire	[7:0]	VUM;
reg		[18:0]	LEFT;
reg		[18:0]	RIGHT;
reg		[18:0]	LEFT_BUF;
reg		[18:0]	RIGHT_BUF;
reg		[18:0]	LEFT_BUF2;
reg		[18:0]	RIGHT_BUF2;
reg		[7:0]	ORCH_LEFT;
reg		[7:0]	ORCH_RIGHT;
reg		[7:0]	ORCH_LEFT_EXT;
reg		[7:0]	ORCH_RIGHT_EXT;
reg		[7:0]	ORCH_LEFT_EXT_BUF;
reg		[7:0]	ORCH_RIGHT_EXT_BUF;
reg				DACLRCLK;
reg		[5:0]	DAC_STATE;
wire 			H_FLAG;

reg		[2:0]	SWITCH_L;

wire			CPU_IRQ_N;
wire			CPU_FIRQ_N;
reg		[2:0]	DIV_7;
reg				DIV_14;
reg		[12:0]	TIMER;
wire			TMR_CLK;
reg				TMR_CLK_D;
wire			SER_IRQ;
reg		[4:0]	COM1_STATE;
reg				COM1_CLOCK_X;
reg				COM1_CLOCK_X_D;
//reg				COM1_CLOCK;
reg		[2:0]	COM1_CLK;
reg		[2:0]	COM2_STATE;
reg				COM3_CLOCK;
reg		[2:0]	COM3_CLK;
wire	[7:0]	DATA_HDD;
wire			RS232_EN;
wire			RX_CLK2;
wire	[7:0]	DATA_RS232;
reg		[2:0]	ROM_BANK;
wire			SLOT3_HW;
wire			UART51_TXD;
wire			UART51_RXD;
wire			UART51_RTS;
wire			UART51_DTR;
wire			UART50_RXD;
wire			UART50_RTS;
reg		[9:0]	SEC;
reg				TICK0;
reg				TICK1;
reg				TICK2;
// Joystick
reg		[12:0]	JOY_CLK0;
reg		[12:0]	JOY_CLK1;
reg		[12:0]	JOY_CLK2;
reg		[12:0]	JOY_CLK3;
reg		[9:0]	PADDLE_ZERO_0;
reg		[9:0]	PADDLE_ZERO_1;
reg		[9:0]	PADDLE_ZERO_2;
reg		[9:0]	PADDLE_ZERO_3;
reg		[11:0]	PADDLE_VAL_0;
reg		[11:0]	PADDLE_VAL_1;
reg		[11:0]	PADDLE_VAL_2;
reg		[11:0]	PADDLE_VAL_3;
reg		[1:0]	PADDLE_STATE_0;
reg		[1:0]	PADDLE_STATE_1;
reg		[1:0]	PADDLE_STATE_2;
reg		[1:0]	PADDLE_STATE_3;
reg		[5:0]	JOY1_COUNT;
reg		[5:0]	JOY2_COUNT;
reg		[5:0]	JOY3_COUNT;
reg		[5:0]	JOY4_COUNT;
reg				JOY_TRIGGER0;
reg				JOY_TRIGGER1;
reg				JOY_TRIGGER2;
reg				JOY_TRIGGER3;
reg			JSTICK;
wire			JOY1;
wire			JOY2;
wire			JOY3;
wire			JOY4;
reg				JCASE0;
reg				JCASE1;
reg				JCASE2;
reg				JCASE3;
reg				WRT_PREC;
reg				DENSITY;
reg				HALT_EN;
reg		[7:0]	COMMAND;
reg		[7:0]	SECTOR;
reg		[7:0]	DATA_EXT;
reg		[7:0]	STATUS;
reg				IRQ_02_N;
reg				IRQ_02_BUF0_N;
reg				IRQ_02_BUF1_N;
wire			IRQ_02_UART;
wire			IRQ_02_UART_2;
wire			NMI_09;
reg				HALT_BUF0;
reg				HALT_BUF1;
reg				HALT_BUF2;
reg				HALT_SIG_BUF0;
reg				HALT_SIG_BUF1;
reg		[6:0]	HALT_STATE;
wire			PH2_02;
wire	[15:0]	ADDRESS_02;
wire	[7:0]	CPU_BANK;
wire	[7:0]	DATA_OUT_02;
wire	[7:0]	DATA_IN_02;
wire	[7:0]	DATA_COM1;
//reg		[8:0]	BUFF_ADD;
reg				ADDR_RESET_N;
reg				IMM_HALT_09;
wire			COM1_EN;
reg		[7:0]	TRACK_REG_R;
reg		[7:0]	TRACK_REG_W;
reg		[7:0]	TRACK_EXT_R;
reg		[7:0]	TRACK_EXT_W;
reg				NMI_09_EN;
reg				IRQ_RESET;
reg				BUSY0;
reg				BUSY1;
wire	[3:0]	HEXX;
wire			HALT;
reg				FORCE_NMI_09_BUF0;
reg				FORCE_NMI_09_BUF1;
reg				ADDR_RST_BUFF0_N;
reg				ADDR_RST_BUFF1_N;
reg		[7:0]	TRACE;
reg				HALT_100_09;
reg				IRQ_09_EN;
reg				ADDR_100_BUF0;
reg				ADDR_100_BUF1;
reg				IRQ_09_BUF0;
reg				IRQ_09_BUF1;
reg				IRQ_09_BUF2;
reg				CMD_RST;
reg				WAIT_HALT;
reg				CMD_RST_BUF0;
reg				CMD_RST_BUF1;
wire			CPU_RESET_N;
wire			RW_02_N;
wire			DISKBUF_02;
wire	[7:0]	DISK_BUF_Q;
reg		[7:0]	DATA_REG;
wire			HALT_CODE;
wire			RAM02_00_EN;
wire			RAM02_02_EN;
wire			RAM02_03_EN;
wire	[7:0]	DATAO2_00_HDD;
wire	[7:0]	DATAO2_02_HDD;
wire	[7:0]	DATAO2_03_HDD;
wire	[7:0]	DATAO_09_HDD;
reg		[7:0]	TRACK1;
reg		[7:0]	TRACK2;
reg		[7:0]	HEADS;
wire			RDFIFO_RDREQ;
wire			RDFIFO_WRREQ;
wire			WRFIFO_RDREQ;
wire			WRFIFO_WRREQ;
wire	[7:0]	RDFIFO_DATA;
wire	[7:0]	WRFIFO_DATA;
wire			RDFIFO_RDEMPTY;
wire			RDFIFO_WRFULL;
wire			WRFIFO_RDEMPTY;
wire			WRFIFO_WRFULL;
reg				BI_IRQ_EN;
reg 	[19:0]	MCLOCK;
reg 	[19:0]	MCLOCK_DELAY;
wire			I2C_SCL_EN;
wire			I2C_DAT_EN;
reg		[7:0]	I2C_DEVICE;
reg		[7:0]	I2C_REG;
wire	[7:0]	I2C_DATA_IN;
reg		[7:0]	I2C_DATA_OUT;
wire	[5:0]	I2C_STATE;
wire			I2C_DONE;
reg		[1:0]	I2C_DONE_BUF;
wire			I2C_FAIL;
reg				I2C_START;

wire			VDA;
wire			MF;
wire			VPA;
wire			ML_N;
wire			XF;
wire			SYNC;
wire			VP_N;
reg				ODD_LINE;
wire			SPI_HALT;
reg		[22:0]	GART_WRITE;		// 8MB   18:0 for 512kb
reg		[22:0]	GART_READ;
reg		[1:0]	GART_INC;
reg		[16:0]	GART_CNT;
reg		[7:0]	GART_BUF;
reg		[7:0]	BI_TIMER;
reg				DBUF_BI_TO;
reg				DBUF_BI_TO1;
reg				BI_TO;
wire			BI_TO_RST;
reg				ANALOG;
wire			VDAC_EN;
wire	[15:0]	VDAC_OUT;
reg		[5:0]	COM2_CLK;
wire			COM2_EN;
wire			WF_WRFIFO_RDREQ;
wire			WF_RDFIFO_WRREQ;
wire			WF_RDFIFO_WRFULL;
wire			WF_WRFIFO_WRREQ;
wire	[7:0]	WF_WRFIFO_DATA;
wire			WF_WRFIFO_RDEMPTY;
wire	[7:0]	DATA_COM2;

//reg				SDRAM_READ;
//wire	[15:0]	HDOUT;
//reg		[15:0]	SDRAM_DIN;
//reg		[15:0]	SDRAM_DOUT;
//reg		[21:0]	SDRAM_ADDR;
//reg		[2:0]	SDRAM_STATE;
//reg				SDRAM_START;
//reg		[1:0]	SDRAM_START_BUF;
//reg				SDRAM_RD;
//reg				SDRAM_WR;
//wire			SDRAM_NEXT;
//reg		[1:0]	SDRAM_NEXT_BUF;
//wire			SDRAM_EOB;
//wire			SDRAM_OB;
//wire			SDRAM_RDP;
//wire			SDRAM_DONE;
//wire			SDRAM_RDD;
//wire			SDRAM_STATUS;
//wire	[15:0]	SDRAM_DATA_BUF;
//wire			SDRAM_DATA_BUF_EN;
//reg		[1:0]	SDRAM_READY_BUF;

reg				RST_FF00_N;
reg				RST_FF02_N;
//reg			RST_FF20_N;
reg				RST_FF22_N;
reg				RST_FF92_N;
reg				RST_FF93_N;
reg				TMR_RST_N;
wire			CART_INT_N;
reg				CART_INT_N_D;
wire			VSYNC_INT_N;
reg				VSYNC_INT_N_D;
wire			HSYNC_INT_N;
reg				HSYNC_INT_N_D;
reg				TIMER_INT_N;
reg				TIMER_INT_N_D;
wire			KEY_INT_N;
reg				KEY_INT_N_D;
reg				TIMER3_IRQ_N;
reg				HSYNC3_IRQ_N;
reg				VSYNC3_IRQ_N;
reg				KEY3_IRQ_N;
reg				CART3_IRQ_N;
reg				TIMER3_FIRQ_N;
reg				HSYNC3_FIRQ_N;
reg				VSYNC3_FIRQ_N;
reg				KEY3_FIRQ_N;
reg				CART3_FIRQ_N;
reg				CART_INT_IN_N;
reg				HSYNC1_POL;
reg		[1:0]	HSYNC1_IRQ_BUF;
reg				HSYNC1_IRQ_N;
reg				HSYNC1_IRQ_STAT_N;
reg				HSYNC1_IRQ_INT;
reg				VSYNC1_POL;
reg		[1:0]	VSYNC1_IRQ_BUF;
reg				VSYNC1_IRQ_N;
reg				VSYNC1_IRQ_STAT_N;
reg				VSYNC1_IRQ_INT;
wire			HSYNC1_CLK_N;
reg				HSYNC1_CLK_N_D;
wire			VSYNC1_CLK_N;
reg				VSYNC1_CLK_N_D;
wire			CART1_CLK_N;
reg				CART1_CLK_N_D;
reg				CART1_POL;
wire			CART1_BUF_RESET_N;
wire			CART1_FIRQ_RESET_N;
reg		[1:0]	CART_POL_BUF;
reg		[1:0]	CART1_FIRQ_BUF;
reg				CART1_FIRQ_N;
reg				CART1_FIRQ_STAT_N;
reg				CART1_FIRQ_INT;
reg		[1:0]	HSYNC3_FIRQ_BUF;
reg				HSYNC3_FIRQ_STAT_N;
reg				HSYNC3_FIRQ_INT;
reg		[1:0]	VSYNC3_FIRQ_BUF;
reg				VSYNC3_FIRQ_STAT_N;
reg				VSYNC3_FIRQ_INT;
reg		[1:0]	CART3_FIRQ_BUF;
reg				CART3_FIRQ_STAT_N;
reg				CART3_FIRQ_INT;
reg		[1:0]	KEY3_FIRQ_BUF;
reg				KEY3_FIRQ_STAT_N;
reg				KEY3_FIRQ_INT;
reg		[1:0]	TIMER3_FIRQ_BUF;
reg				TIMER3_FIRQ_STAT_N;
reg				TIMER3_FIRQ_INT;
reg		[1:0]	HSYNC3_IRQ_BUF;
reg				HSYNC3_IRQ_STAT_N;
reg				HSYNC3_IRQ_INT;
reg		[1:0]	VSYNC3_IRQ_BUF;
reg				VSYNC3_IRQ_STAT_N;
reg				VSYNC3_IRQ_INT;
reg		[1:0]	CART3_IRQ_BUF;
reg				CART3_IRQ_STAT_N;
reg				CART3_IRQ_INT;
reg		[1:0]	KEY3_IRQ_BUF;
reg				KEY3_IRQ_STAT_N;
reg				KEY3_IRQ_INT;
reg		[1:0]	TIMER3_IRQ_BUF;
reg				TIMER3_IRQ_STAT_N;
reg				TIMER3_IRQ_INT;
reg		[7:0]	GPIO_OUT;
reg		[7:0]	GPIO_DIR;
wire	[7:0]	ROM_DATA;
wire	[7:0]	CART_DATA;
wire	[7:0]	fdc_probe;
wire			clk_sys;

reg 			hold;
reg 			cpu_ena;

// Probe's defined
//assign PROBE[6:0] = {CART1_POL, CART1_BUF_RESET_N, CART1_FIRQ_STAT_N, CART1_CLK_N, CART1_FIRQ_N, RESET_N, PH_2};
//assign PROBE[7:0] = {1'b0, CART1_POL, CART1_FIRQ_N, CART1_FIRQ_BUF[0], CART1_CLK_N_D, CART1_FIRQ_RESET_N, CART1_CLK_N, PH_2};
assign PROBE[7:0] = {2'b00, cache_hit, COCO3_ROM_WRITE, ioctl_wr, ioctl_download, ioctl_index[7], ioctl_index[6]};
assign PROBE[15:8] = LEDR[7:0];
assign PROBE[23:16] = LEDG[7:0];
//assign PROBE[31:24] = {3'b000, DATA_OUT[3], MOTOR, DRIVE_SEL_EXT[0], HDD_EN, ADDRESS[0]};
assign PROBE[31:24] = {2'b00, fdc_probe[5:0]};

assign ROM_BANK = 3'b000;

assign clk_sys = CLK_57;

// SRH MISTer
//
//	Assign switches & buttons
//	instanciate rom

											//  9 UART / DriveWire
											//		Off - DE1 Port is DriveWire and Analog Board is RS232 PAK
											//		on  - DE1 Port is RS232 PAK and Analog Board is DriveWire
											//  8 Serial Port Speed[1]
											//  7 Serial Port Speed[0]
											//    [1] [0]
											//		OFF OFF - 115200	// Swap UART / DriveWire
											//		OFF ON  - 230400
											//		ON  OFF - 460800	// Fastest for the DE1 Port
											//		ON  ON  - 921600
											//  6 SD Card Presence / Write Protect
											//		Off - Use card signals
											//		On  - Ignore Signals
											//  5 SG4 / SG6 mode select
											//		Off - SG4
											//		On  - SG6
											//  4 Cartridge Interrupt disabled except Disk
											//  3 Video Odd line black
											//		Off - Normal video
											//		On  - Odd lines black
											//  2 MPI [1]
											//  1 MPI [0]
											//    [1] [0]
											//		OFF OFF - Slot 1
											//		OFF ON  - Slot 2
											//		ON  OFF - Slot 3
											//		ON  ON  - Slot 4
											//  0 CPU Turbo Speed
											//		Off - Normal 1.78 MHz
											//		On  - 25 MHz


//assign SWITCH[9:0] = 10'b0000010000; /* synthesis preserve */ // This is ECB
//assign SWITCH[9:0] = 10'b0000010110; // This is EDB
//assign SWITCH[9:0] = 10'b0000000000; // This is Orch 80 in ROM

assign BUTTON_N[3:0] = {COCO_RESET_N, 2'b1,EE_N};


//assign LEDG = TRACE;														// Floppy Trace

assign LEDG[0] =  RAM0_BE0 | RAM0_BE1;
assign LEDG[1] =  1'b0;
assign LEDG[2] =  1'b0;
assign LEDG[3] =  FLASH_CE_S;
assign LEDG[4] = (ADDRESS == 16'hFF84);								// SDRAM
assign LEDG[5] =  1'b0;
assign LEDG[6] = 1'b0;												// SD Card activity
assign LEDG[7] = !UART50_RXD;
// SRH DE2-115 Extra Green LED is unused and off
assign LEDG[8] = 1'b0;

assign LEDR[0] =  1'b0;
assign LEDR[1] =  1'b0;
assign LEDR[2] =  1'b0;
assign LEDR[3] =  1'b0;

assign LEDR[4] = 1'b0; 
assign LEDR[5] = SWITCH[6];					// SD Card inserted
assign LEDR[6] =  RESET_N;
assign LEDR[7] =  KEY[55];													// Shift Lock
// SRH DE2-115 Extra Red LEDs are unused and off
assign LEDR[17:8] = 10'b0000000000;

//Master clock divider chain
//	MCLOCK[0] = 50/2		= 25 MHz
//	MCLOCK[1] = 50/4		= 12.5 MHz
//	MCLOCK[2] = 50/8		= 6.25 MHz
//	MCLOCK[3] = 50/16		= 3.125 MHz
//	MCLOCK[4] = 50/32		= 1.5625 MHz
//	MCLOCK[5] = 50/64		= 781.25 KHz
//	MCLOCK[6] = 50/128		= 390.625 KHz
//	MCLOCK[7] = 50/256		= 195.125 KHz
//	MCLOCK[8] = 50/512		= 97.65625 KHz
//	MCLOCK[9] = 50/1024		= 48.828125 KHz
//	MCLOCK[10] = 50/2048	= 24.4140625 KHz
//	MCLOCK[11] = 50/4096	= 12.20703125 KHz

always @ (negedge clk_sys)				//50 MHz
begin
	MCLOCK <= MCLOCK + 1'b1;
	MCLOCK_DELAY <= MCLOCK;
end


//SRH DE2-115 extra digits - blank

/*****************************************************************************
* RAM signals
******************************************************************************/

assign	RAM0_BE0 =			((ADDRESS == 16'hFF73)&&  RW_N && ({GART_READ[22:21], GART_READ[0]}  == 3'b000))		?	1'b1:
							((ADDRESS == 16'hFF73)&& !RW_N && ({GART_WRITE[22:21],GART_WRITE[0]} == 3'b000))		?	1'b1:
							( !VMA && !GART_CNT[0] 			 && ({GART_READ[22:21], GART_READ[0]}  == 3'b000))		?	1'b1:
							( !VMA &&  GART_CNT[0]			 && ({GART_WRITE[22:21],GART_WRITE[0]} == 3'b000))		?	1'b1:
							(  VMA &&  RAM_CS					 && ({BLOCK_ADDRESS[9:8],ADDRESS[0]}  ==  3'b000))	?	1'b1:
																														1'b0;

assign	RAM0_BE1 =			((ADDRESS == 16'hFF73)&&  RW_N && ({GART_READ[22:21], GART_READ[0]}  == 3'b001))		?	1'b1:
							((ADDRESS == 16'hFF73)&& !RW_N && ({GART_WRITE[22:21],GART_WRITE[0]} == 3'b001))		?	1'b1:
							( !VMA && !GART_CNT[0] 			 && ({GART_READ[22:21], GART_READ[0]}  == 3'b001))		?	1'b1:
							( !VMA &&  GART_CNT[0]			 && ({GART_WRITE[22:21],GART_WRITE[0]} == 3'b001))		?	1'b1:
							(  VMA &&  RAM_CS					 && ({BLOCK_ADDRESS[9:8],ADDRESS[0]}  ==  3'b001))	?	1'b1:
																														1'b0;


assign	BLOCK_ADDRESS =	({MMU_EN, MMU_TR, ADDRESS[15:13]} ==  5'b10000)					?	SAM00:		// 10 000X	0000-1FFF
									({MMU_EN, MMU_TR, ADDRESS[15:13]} ==  5'b10001)					?	SAM01:		// 10 001X	2000-3FFF
									({MMU_EN, MMU_TR, ADDRESS[15:13]} ==  5'b10010)					?	SAM02:		// 10 010X	4000-5FFF
									({MMU_EN, MMU_TR, ADDRESS[15:13]} ==  5'b10011)					?	SAM03:		// 10 011X	6000-7FFF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:13]} == 6'b010100)		?	SAM04:		//010 100X	8000-9FFF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:13]} == 6'b010101)		?	SAM05:		//010 101X	A000-BFFF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:13]} == 6'b010110)		?	SAM06:		//010 110X	C000-DFFF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:12]} == 7'b0101110)	?	SAM07:		//010 1110 X		E000-EFFF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:11]} == 8'b01011110)	?	SAM07:		//010 1111 0X		F000-F7FF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:10]} == 9'b010111110)	?	SAM07:		//010 1111 10X		F800-FBFF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:9]} == 10'b0101111110)?	SAM07:		//010 1111 110X	FC00-FDFF
							({VEC_PAG_RAM, MMU_EN, MMU_TR, ADDRESS[15:8]} == 11'b01011111110)	?	SAM07:		//010 1111 1110 X	FE00-FEFF Vector page as RAM
									({MMU_EN, MMU_TR, ADDRESS[15:13]} ==  5'b11000)					?	SAM10:		// 11 000X
									({MMU_EN, MMU_TR, ADDRESS[15:13]} ==  5'b11001)					?	SAM11:		// 11 001X
									({MMU_EN, MMU_TR, ADDRESS[15:13]} ==  5'b11010)					?	SAM12:		// 11 010X
									({MMU_EN, MMU_TR, ADDRESS[15:13]} ==  5'b11011)					?	SAM13:		//011 011X
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:13]} == 6'b011100)		?	SAM14:		//011 100X
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:13]} == 6'b011101)		?	SAM15:		//011 101X
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:13]} == 6'b011110)		?	SAM16:		//011 110X
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:12]} == 7'b0111110)	?	SAM17:		//011 1110 X		E000-EFFF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:11]} == 8'b01111110)	?	SAM17:		//011 1111 0X		F000-F7FF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:10]} == 9'b011111110)	?	SAM17:		//011 1111 10X		F800-FBFF
									({ROM_SEL, MMU_EN, MMU_TR, ADDRESS[15:9]} == 10'b0111111110)?	SAM17:		//011 1111 110X	FC00-FDFF
							({VEC_PAG_RAM, MMU_EN, MMU_TR, ADDRESS[15:8]} == 11'b01111111110)	?	SAM17:		//011 1111 1110 X	FE00-FEFF Vector page as RAM
																														{7'b0000111,ADDRESS[15:13]};

assign RAM_CS =					(ROM_SEL)										?	1'b0:		// Any slot
								({RAM, ADDRESS[15:14]} == 3'b010)				?	1'b0:		// ROM (8000-BFFF)
								({RAM, ADDRESS[15:13]} == 4'b0110)				?	1'b0:		// ROM (C000-DFFF)
								({RAM, ADDRESS[15:12]} == 5'b01110)				?	1'b0:		// ROM (E000-EFFF)
								({RAM, ADDRESS[15:11]} == 6'b011110)			?	1'b0:		// ROM (F000-F8FF)
								({RAM, ADDRESS[15:10]} == 7'b0111110)			?	1'b0:		// ROM (F800-FBFF)
								({RAM, ADDRESS[15:9]}  == 8'b01111110)			?	1'b0:		// ROM (FC00-FDFF)
//								({BLOCK_ADDRESS[9:8]} != 2'b10)					?	1'b0:		// 0 - 4M
								(ADDRESS[15:0]== 18'h2FF73)						?	1'b1:		// GART
//								(!VMA & (GART_CNT != 17'h00000))				?	1'b1:		// Chip Select is not needed for the memcopy
								({ADDRESS[15:8]}== 8'hFF)						?	1'b0:		// Hardware (FF00-FFFF)
																					1'b1;

/*****************************************************************************
* ROM signals
******************************************************************************/
// ROM_SEL is 1 when the system is accessing any cartridge "ROM" meaning the
// 4 slots of the MPI, this is:
//		Slot 1 	Orchestra-90C
//		Slot 2	Alternate Disk Controller ROM
//		Slot 3	Cart slot
//		Slot 4	Disk Controller ROM
assign	ROM_SEL =		( RAM								== 1'b1)	?	1'b0:	// All RAM Mode excluded
						( ROM 								== 2'b10)	?	1'b0:	// All Internal excluded
						({ROM[1], ADDRESS[15:14]}			== 3'b010)	?	1'b0:   // 16K 8000-BFFF excluded
						(			 ADDRESS[15]			== 1'b0)	?	1'b0:	// Lower 32K RAM space excluded
						(			 ADDRESS[15:8]			== 8'hFE)	?	1'b0:	// Vector space excluded
						(			 ADDRESS[15:8]			== 8'hFF)	?	1'b0:	// Hardware space excluded
																			1'b1;	// Everything else included

//ROM
//00		16 Internal + 16 External
//01		16 Internal + 16 External
//10		32 Internal
//11		32 External

// SRH
// For DE2-115 concanenate 1'b0 as MSB
// The two ENA_PAK terms do not function correctly.  They both occur at once meaning the first has priority...  This needs addressed. SRH 8/25

assign	FLASH_ADDRESS =	ENA_DSK		?			{1'b0,9'b000000100, ADDRESS[12:0]}:	//8K Disk BASIC 8K Slot 4
						ENA_DISK2	?			{1'b0,7'b1111111,   ADDRESS[14:0]}:	//ROM Anternative Disk Controller
						ENA_ORCC	?			{1'b0,9'b000000101, ADDRESS[12:0]}:	//8K Orchestra 8K 90CC Slot 1
//						ENA_PAK		?			{1'b0,7'b0000000, 	ADDRESS[14:0]}:	//Internal R/W CART ROM
//	(ENA_PAK & (ROM == 2'b11))		?			{1'b0,6'b000000, ~ADDRESS[14],	ADDRESS[13:0]}:	//Internal R/W CART ROM
//						ENA_PAK		?			{1'b0,5'b00000,ROM_BANK,	ADDRESS[13:0]}:	//Internal R/W CART ROM
						ENA_PAK		?			{1'b0,4'b0000,ROM_BANK,	ADDRESS[14:0]}:	//Internal R/W CART ROM
// Slot 3 ROMPak
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b100000)	?	{1'b0,BANK0,     ADDRESS[14:0]}:	//32K
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b110000)	?	{1'b0,BANK0,     ADDRESS[14:0]}:	//32K
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b101000)	?	{1'b0,BANK0,1'b0,ADDRESS[13:0]}:	//16K Lower half
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b111000)	?	{1'b0,BANK0,1'b1,ADDRESS[13:0]}:	//16K Higher half
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b100001)	?	{1'b0,BANK1,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b110001)	?	{1'b0,BANK1,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b101001)	?	{1'b0,BANK1,1'b0,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b111001)	?	{1'b0,BANK1,1'b1,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b100010)	?	{1'b0,BANK2,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b110010)	?	{1'b0,BANK2,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b101010)	?	{1'b0,BANK2,1'b0,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b111010)	?	{1'b0,BANK2,1'b1,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b100011)	?	{1'b0,BANK3,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b110011)	?	{1'b0,BANK3,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b101011)	?	{1'b0,BANK3,1'b0,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b111011)	?	{1'b0,BANK3,1'b1,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b100100)	?	{1'b0,BANK4,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b110100)	?	{1'b0,BANK4,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b101100)	?	{1'b0,BANK4,1'b0,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b111100)	?	{1'b0,BANK4,1'b1,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b100101)	?	{1'b0,BANK5,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b110101)	?	{1'b0,BANK5,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b101101)	?	{1'b0,BANK5,1'b0,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b111101)	?	{1'b0,BANK5,1'b1,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b100110)	?	{1'b0,BANK6,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b110110)	?	{1'b0,BANK6,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b101110)	?	{1'b0,BANK6,1'b0,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b111110)	?	{1'b0,BANK6,1'b1,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b100111)	?	{1'b0,BANK7,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b110111)	?	{1'b0,BANK7,     ADDRESS[14:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b101111)	?	{1'b0,BANK7,1'b0,ADDRESS[13:0]}:
//({ENA_PAK,BANK_SIZE,ROM_BANK}== 6'b111111)	?	{1'b0,BANK7,1'b1,ADDRESS[13:0]}:
												{1'b0,7'b0000000, ADDRESS[14:0]};

//ROM
//00		16 Internal + 16 External
//01		16 Internal + 16 External
//10		32 Internal
//11		32 External
assign FLASH_CE_S =	({RAM, ROM[1], ADDRESS[15:14]} ==  4'b0010)						?	1'b1:		// Internal 16K ROM 8000-BFFF
							({RAM, ROM,    ADDRESS[15:14]} ==  5'b01010)			?	1'b1:		// Internal 32K ROM 8000-BFFF
							({RAM, ROM,    ADDRESS[15:13]} ==  6'b010110)			?	1'b1:		// Internal 32K ROM C000-DFFF
							({RAM, ROM,    ADDRESS[15:12]} ==  7'b0101110)			?	1'b1:		// Internal 32K ROM E000-EFFF
							({RAM, ROM,    ADDRESS[15:11]} ==  8'b01011110)			?	1'b1:		// Internal 32K ROM F000-F7FF
							({RAM, ROM,    ADDRESS[15:10]} ==  9'b010111110)		?	1'b1:		// Internal 32K ROM F800-FBFF
							({RAM, ROM,    ADDRESS[15:9]}  == 10'b0101111110)		?	1'b1:		// Internal 32K ROM FC00-FDFF
							ENA_DSK													?	1'b1:
							ENA_PAK													?	1'b1:
							ENA_DISK2												?	1'b1:
							ENA_ORCC												?	1'b1:
																						1'b0;


wire	[7:0]	COCO3_ROM_DATA;
wire	[7:0]	COCO3_DISK_ROM_DATA;
wire	[7:0]	ORCH90_ROM_DATA;

localparam 	[1:0]	BOOT0 = 2'd0;
localparam 	[1:0]	BOOT1 = 2'd1;
localparam 	[1:0]	BOOT2 = 2'd2;

localparam	[5:0]	BOOT  = 6'd0;


wire			COCO3_ROM_WRITE = (ioctl_index[7:0] == {BOOT0, BOOT})  & ioctl_wr;
wire			COCO3_DISKROM_WRITE = (ioctl_index[7:0] == {BOOT1, BOOT}) & ioctl_wr;
wire			COCO3_ORCH90_ROM_WRITE = (ioctl_index[7:0] == {BOOT2, BOOT}) & ioctl_wr;


//COCO_ROM CC3_ROM(
//.ADDR(FLASH_ADDRESS[15:0]),
//.DATA(ROM_DATA),
//.CLK(~clk_sys),
//.WR_ADDR(ioctl_addr[15:0]),
//.WR_DATA(ioctl_data[7:0]),
//.WRITE((ioctl_index[5:0] == 6'd0) & ioctl_wr)
//);


COCO_ROM_32K CC3_ROM(
.ADDR(FLASH_ADDRESS[14:0]),
.DATA(COCO3_ROM_DATA),
.CLK(~clk_sys),
.WR_ADDR(ioctl_addr[14:0]),
.WR_DATA(ioctl_data[7:0]),
.WRITE(COCO3_ROM_WRITE)
);

COCO_ROM_8K CC3_DISK_ROM(
.ADDR(FLASH_ADDRESS[12:0]),
.DATA(COCO3_DISK_ROM_DATA),
.CLK(~clk_sys),
.WR_ADDR(ioctl_addr[12:0]),
.WR_DATA(ioctl_data[7:0]),
.WRITE(COCO3_DISKROM_WRITE)
);

COCO_ROM_8K CC3_ORCH90_ROM(
.ADDR(FLASH_ADDRESS[12:0]),
.DATA(ORCH90_ROM_DATA),
.CLK(~clk_sys),
.WR_ADDR(ioctl_addr[12:0]),
.WR_DATA(ioctl_data[7:0]),
.WRITE(COCO3_ORCH90_ROM_WRITE)
);

 

assign FLASH_DATA =	ENA_PAK	?								CART_DATA:
					(FLASH_ADDRESS[15] == 1'b0)			?	COCO3_ROM_DATA:
					(FLASH_ADDRESS[15:13] == 3'b100)	?	COCO3_DISK_ROM_DATA:
					(FLASH_ADDRESS[15:13] == 3'b101)	?	ORCH90_ROM_DATA:
															8'b00000000;


COCO_ROM_CART CC3_ROM_CART(
.ADDR({FLASH_ADDRESS[15], (FLASH_ADDRESS[14] ^ inv_a14), FLASH_ADDRESS[13:0]}),
.DATA(CART_DATA),
.CLK(~clk_sys),
.WR_ADDR(ioctl_addr[15:0]),
.WR_DATA(ioctl_data[7:0]),
.WRITE((ioctl_index[5:0] == 6'd1) & ioctl_wr)
);

wire write_to_cart_0;
wire inv_a14;
reg	adrs_monitor;

assign write_to_cart_0 = (ioctl_addr[15:0] == 16'b0000000000000000) ?	1'b1:
																		1'b0;


always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		inv_a14 <= 1'b0;
		adrs_monitor <= 1'b0;
	end
	else
	begin
		if (adrs_monitor == 1'b0)
			inv_a14 <= 1'b1;
		else
			inv_a14 <= 1'b0;
			
		if (write_to_cart_0)
			adrs_monitor <= 1'b0;
		if ((ioctl_index[5:0] == 6'd1) & ioctl_wr)
			adrs_monitor <= adrs_monitor | ioctl_addr[14];
	end
end


// Removal of sram [V5]
//COCO_SRAM CC3_SRAM0(
//.CLK(~clk_sys),
//.ADDR(RAM0_ADDRESS[15:0]),
//.R_W(RAM0_RW_N | RAM0_BE0_N),
//.DATA_I(RAM0_DATA_I[7:0]),
//.DATA_O(RAM0_DATA_O[7:0])
//);

//COCO_SRAM CC3_SRAM1(
//.CLK(~clk_sys),
//.ADDR(RAM0_ADDRESS[15:0]),
//.R_W(RAM0_RW_N | RAM0_BE1_N),
//.DATA_I(RAM0_DATA_I[15:8]),
//.DATA_O(RAM0_DATA_O[15:8])
//);

assign	ENA_ORCC =	({ROM_SEL, MPI_CTS} == 3'b100)						?	1'b1:		// Orchestra-90CC C000-DFFF Slot 1
																								1'b0;
assign	ENA_DISK2 =	({ROM_SEL, MPI_CTS} == 3'b101)						?	1'b1:		// Alternative Disk controller ROM up to 32K
																								1'b0;
assign	ENA_PAK =	({ROM_SEL, MPI_CTS} == 3'b110)						?	1'b1:		// ROM SLOT 3
																								1'b0;
assign	ENA_DSK =	({ROM_SEL, MPI_CTS} == 3'b111)						?	1'b1:		// Disk C000-DFFF Slot 4
																								1'b0;
assign	HDD_EN = ({MPI_SCS[0], ADDRESS[15:4]} == 13'b1111111110100)	?	1'b1:		// FF40-FF4F with MPI switch = 2 or 4
																								1'b0;
assign	RS232_EN = (ADDRESS[15:2] == 14'b11111111011010)				?	1'b1:		//FF68-FF6B
																								1'b0;
//assign	SPI_EN = (ADDRESS[15:1]  == 15'b111111110110010)				?	1'b1:		// SPI FF64-FF65
//																								1'b0;
assign	SLOT3_HW = ({MPI_SCS, ADDRESS[15:5]} == 13'b1011111111010)	?	1'b1:		// FF40-FF5F
																								1'b0;
assign	VDAC_EN = ({RW_N,ADDRESS[15:0]} == 17'H0FF7E)					?	1'b1:		// FF7E
																								1'b0;

/*
$FF40 - This is the bank latch. The same latch that is used by the Super Program Paks to bank 16K of the Pak ROM
at a time. The initial design simply used 32K banks - this would allow the Super Program Paks to function, but
wastes 16K per Bank. This was done so the banks could house any of the 32K CoCo 3 Program PAKs as well. This latch
is set to $00 on reset or power up (same as the super program paks).

$FF41 - the CTS* WRITE data latch. This was incorporated because the CTS* line is read only. I could have just
derived a new CTS* that is active on both reads and writes, however, some PAKs utilize a copy protection scheme
whereas they write to the PAK area. As long as the PAK was in ROM, nothing happened, but if trying to run from a
R/W* RAMPAK, or from disk (wheras the CoCo is placed in the allram mode and the PAK transferred there and executed),
then the PAK code would be corrupted and a crash would occur. This behavior could be patched out of the PAK but I
wanted to be able to execute the PAK code verbatim. Thus this latch at $FF41. A byte of data is written to $FF41.
It is latched and a flip-flop is triggered (this flip-flop starts up un-triggered - either at power on or reset).
Once the flip-flop is triggered, it indicates a valid byte has been stored at $FF41 and then any READ of the CTS*
area will WRITE the byte from $FF41 into the SRAM at the memory location that was READ, the flip-flop is also
reset by this action. This allows writing to the CTS* area while still providing the Read Only protection offered
by the CTS* signal.
$FF42 - BANK 0 latch - this was incorporated because Aaron wanted to be able to start up with his operating code in
bank $00, however, the super program PAKs must start at bank $00. So, whatever is written into this latch will
be the bank that is accessed as BANK 0. This is reset to $00 only at power on (Not reset). So, whatever is written
here will be the bank accessed as bank 00 from that point forward, until it is changed again. Reset will not change it.
$FF43 - Bank Size latch. Only two bits used.:
             Bit 0 = 0 = 32K BANK SIZE, =1=16K Banks Size
             Bit 1 = 0 = Use lower 16K of each 32K bank
             Bit 1 = 1 = Use upper 16K of each 32K bank
Bit 1 is only effective if bank size is set to 16K by bit 0. This register is set to $00 at power on or reset,
and was added to reduce wasted memory. Under proper program control this allows two 16K or less program paks to
exist in each 32K bank.

$FF44-$FF4A = bank 1 through bank 7 latches. The largest super program pak that I am aware of was RoboCop,
consuming 8 banks of 16K for 128K total. These work just like the latch at $FF42 EXCEPT they affect banks 1-7.
They are also set to $01-$07 (respectively) on power up (but not reset). This allows a Super Program Pak to reside
in any banks in any order, by simply writing the proper data into these latches.
*/

// If W_PROT[1] = 1 then ROM_RW is 0, else ROM_RW = !RW_N


assign	DATA_IN =
														(RAM0_BE0_L & end_hold)		?	hold_data[7:0]:
														(RAM0_BE1_L & end_hold)		?	hold_data[15:8]:
//														RAM0_BE0		?	RAM0_DATA_O[7:0]: Removal of sram data out [V5]
//														RAM0_BE1		?	RAM0_DATA_O[15:8]:
//														RAM1_BE0		?	RAM1_DATA[7:0]:
//														RAM1_BE1		?	RAM1_DATA[15:8]:
//														RAM1_BE2		?	RAM1_DATA[7:0]:
//														RAM1_BE3		?	RAM1_DATA[15:8]:
														FLASH_CE_S		?	FLASH_DATA:
														HDD_EN			?	DATA_HDD:
														RS232_EN		?	DATA_RS232:
														SLOT3_HW		?	{5'b00000, ROM_BANK}:
//														WF_RDFIFO_RDREQ	?	WF_RDFIFO_DATA:
//														SPI_EN			?	SPI_DATA:
// FF00, FF04, FF08, FF0C, FF10, FF14, FF18, FF1C
({ADDRESS[15:5], ADDRESS[1:0]} == 13'b1111111100000)	?	DATA_REG1:
// FF01, FF05, FF09, FF0D, FF11, FF15, FF19, FF1D
({ADDRESS[15:5], ADDRESS[1:0]} == 13'b1111111100001)	?	{!HSYNC1_IRQ_BUF[1], 3'b011, SEL[0], DDR1, HSYNC1_POL, HSYNC1_IRQ_INT}:
// FF02, FF06, FF0A, FF0E, FF12, FF16, FF1A, FF1E
({ADDRESS[15:5], ADDRESS[1:0]} == 13'b1111111100010)	?	DATA_REG2:
// FF03, FF07, FF0B, FF0F, FF13, FF17, FF1B, FF1F
({ADDRESS[15:5], ADDRESS[1:0]} == 16'b1111111100011)	?	{!VSYNC1_IRQ_BUF[1], 3'b011, SEL[1], DDR2, VSYNC1_POL, VSYNC1_IRQ_INT}:
// FF20, FF24, FF28, FF2C, FF30, FF34, FF38, FF3C
({ADDRESS[15:5], ADDRESS[1:0]} == 16'b1111111100100)	?	DATA_REG3:
// FF21, FF25, FF29, FF2D, FF31, FF35, FF39, FF3D
({ADDRESS[15:5], ADDRESS[1:0]} == 16'b1111111100101)	?	{4'b0011, CAS_MTR, DDR3, 2'b00}:	// CD_POL, CD_INT}:
// FF22, FF26, FF2A, FF2E, FF32, FF36, FF3A, FF3E
({ADDRESS[15:5], ADDRESS[1:0]} == 16'b1111111100110)	?	DATA_REG4:
// FF23, FF27, FF2B, FF2F, FF33, FF37, FF3B, FF3F
({ADDRESS[15:5], ADDRESS[1:0]} == 16'b1111111100111)	?	{!CART1_FIRQ_BUF[1], 3'b011, SOUND_EN, DDR4, CART1_POL, CART1_FIRQ_INT}:
// HiRes Joystick
//								({PDL,ADDRESS} == 17'h0FF60)	?	PADDLE_LATCH_0[11:4]:
//								({PDL,ADDRESS} == 17'h0FF61)	?	{PADDLE_LATCH_0[3:0],4'b0000}:
//								({PDL,ADDRESS} == 17'h0FF62)	?	PADDLE_LATCH_1[11:4]:
//								({PDL,ADDRESS} == 17'h0FF63)	?	{PADDLE_LATCH_1[3:0],4'b0000}:
//								({PDL,ADDRESS} == 17'h1FF60)	?	PADDLE_LATCH_2[11:4]:
//								({PDL,ADDRESS} == 17'h1FF61)	?	{PADDLE_LATCH_2[3:0],4'b0000}:
//								({PDL,ADDRESS} == 17'h1FF62)	?	PADDLE_LATCH_3[11:4]:
//								({PDL,ADDRESS} == 17'h1FF63)	?	{PADDLE_LATCH_3[3:0],4'b0000}:
//									  (ADDRESS  == 16'hFF6C)	?	{(!WF_RDFIFO_RDEMPTY & WF_IRQ_EN),
//																			5'b00000,
//																			!WF_RDFIFO_RDEMPTY,							// 1 = data available
//																			WF_WRFIFO_WRFULL}:							// 1 = Write FIFO Full

									(ADDRESS == 16'hFF70)		?	{1'b0, GART_WRITE[22:16]}:		// 2MB
									(ADDRESS == 16'hFF71)		?	{       GART_WRITE[15:8]}:
									(ADDRESS == 16'hFF72)		?	{       GART_WRITE[7:0]}:
									(ADDRESS == 16'hFF74)		?	{1'b0, GART_READ[22:16]}:
									(ADDRESS == 16'hFF75)		?	{       GART_READ[15:8]}:
									(ADDRESS == 16'hFF76)		?	{       GART_READ[7:0]}:
									(ADDRESS == 16'hFF77)		?	{(GART_CNT == 17'h00000),5'b00000, GART_INC[1:0]}:
									(ADDRESS == 16'hFF7F)		?	{2'b11, MPI_CTS, W_PROT, MPI_SCS}:
//									(ADDRESS == 16'hFF80)		?	{CK_DONE_BUF[1],
//																						CK_FAIL,
//																						CK_STATE}:
//									(ADDRESS == 16'hFF81)		?	CK_DATA_IN:

//									(ADDRESS == 16'hFF84)		?	{SDRAM_READY_BUF[1], 3'b000, SDRAM_STATE, SDRAM_READ}:
//									(ADDRESS == 16'hFF85)		?	SDRAM_DOUT[7:0]:
//									(ADDRESS == 16'hFF86)		?	SDRAM_DOUT[15:8]:
//									(ADDRESS == 16'hFF87)		?	{1'b0, SDRAM_ADDR[21:15]}:
//									(ADDRESS == 16'hFF88)		?	SDRAM_ADDR[14:7]:
//									(ADDRESS == 16'hFF87)		?	BUFF_DATA[15:8]:
//									(ADDRESS == 16'hFF88)		?	BUFF_DATA[7:0]:

									(ADDRESS == 16'hFF8E)		?	GPIO_DIR:
									(ADDRESS == 16'hFF8F)		?	GPIO:

									(ADDRESS == 16'hFF90)		?	{COCO1, MMU_EN, GIME_IRQ, GIME_FIRQ, VEC_PAG_RAM, ST_SCS, ROM}:
									(ADDRESS == 16'hFF91)		?	{2'b00, TIMER_INS, 4'b0000, MMU_TR}:
									(ADDRESS == 16'hFF92)		?	{2'b00, !TIMER3_IRQ_N,  !HSYNC3_IRQ_N,  !VSYNC3_IRQ_N,  1'b0, !KEY3_IRQ_N,  !CART3_IRQ_N}:
									(ADDRESS == 16'hFF93)		?	{2'b00, !TIMER3_FIRQ_N, !HSYNC3_FIRQ_N, !VSYNC3_FIRQ_N, 1'b0, !KEY3_FIRQ_N, !CART3_FIRQ_N}:
									(ADDRESS == 16'hFF94)		?	{4'h0,TMR_MSB}:
									(ADDRESS == 16'hFF95)		?	TMR_LSB:
//									(ADDRESS == 16'hFF98)		?	{GRMODE, HRES[3], DESCEN, MONO, 1'b0, LPR}:
//									(ADDRESS == 16'hFF99)		?	{HLPR, LPF, HRES[2:0], CRES}:
//									(ADDRESS == 16'hFF9A)		?	{2'b00, PALETTE[16][5:0]}:
//									(ADDRESS == 16'hFF9B)		?	{2'b00, SAM_EXT, SCRN_START_HSB}:	// 4 extra bits for 8MB. Real hardware can't read back!!
//									(ADDRESS == 16'hFF9C)		?	{4'h0,VERT_FIN_SCRL}:
//									(ADDRESS == 16'hFF9D)		?	SCRN_START_MSB:
//									(ADDRESS == 16'hFF9E)		?	SCRN_START_LSB:
//									(ADDRESS == 16'hFF9F)		?	{HVEN,HOR_OFFSET}:
									(ADDRESS == 16'hFFA0)		?	SAM00[7:0]:
									(ADDRESS == 16'hFFA1)		?	SAM01[7:0]:
									(ADDRESS == 16'hFFA2)		?	SAM02[7:0]:
									(ADDRESS == 16'hFFA3)		?	SAM03[7:0]:
									(ADDRESS == 16'hFFA4)		?	SAM04[7:0]:
									(ADDRESS == 16'hFFA5)		?	SAM05[7:0]:
									(ADDRESS == 16'hFFA6)		?	SAM06[7:0]:
									(ADDRESS == 16'hFFA7)		?	SAM07[7:0]:
									(ADDRESS == 16'hFFA8)		?	SAM10[7:0]:
									(ADDRESS == 16'hFFA9)		?	SAM11[7:0]:
									(ADDRESS == 16'hFFAA)		?	SAM12[7:0]:
									(ADDRESS == 16'hFFAB)		?	SAM13[7:0]:
									(ADDRESS == 16'hFFAC)		?	SAM14[7:0]:
									(ADDRESS == 16'hFFAD)		?	SAM15[7:0]:
									(ADDRESS == 16'hFFAE)		?	SAM16[7:0]:
									(ADDRESS == 16'hFFAF)		?	SAM17[7:0]:
									(ADDRESS == 16'hFFB0)		?	{2'b00, PALETTE[0][5:0]}:
									(ADDRESS == 16'hFFB1)		?	{2'b00, PALETTE[1][5:0]}:
									(ADDRESS == 16'hFFB2)		?	{2'b00, PALETTE[2][5:0]}:
									(ADDRESS == 16'hFFB3)		?	{2'b00, PALETTE[3][5:0]}:
									(ADDRESS == 16'hFFB4)		?	{2'b00, PALETTE[4][5:0]}:
									(ADDRESS == 16'hFFB5)		?	{2'b00, PALETTE[5][5:0]}:
									(ADDRESS == 16'hFFB6)		?	{2'b00, PALETTE[6][5:0]}:
									(ADDRESS == 16'hFFB7)		?	{2'b00, PALETTE[7][5:0]}:
									(ADDRESS == 16'hFFB8)		?	{2'b00, PALETTE[8][5:0]}:
									(ADDRESS == 16'hFFB9)		?	{2'b00, PALETTE[9][5:0]}:
									(ADDRESS == 16'hFFBA)		?	{2'b00, PALETTE[10][5:0]}:
									(ADDRESS == 16'hFFBB)		?	{2'b00, PALETTE[11][5:0]}:
									(ADDRESS == 16'hFFBC)		?	{2'b00, PALETTE[12][5:0]}:
									(ADDRESS == 16'hFFBD)		?	{2'b00, PALETTE[13][5:0]}:
									(ADDRESS == 16'hFFBE)		?	{2'b00, PALETTE[14][5:0]}:
									(ADDRESS == 16'hFFBF)		?	{2'b00, PALETTE[15][5:0]}:
//									(ADDRESS == 16'hFFC0)		?	{3'b000, CENT}:
//									(ADDRESS == 16'hFFC1)		?	{1'b0, YEAR}:
//									(ADDRESS == 16'hFFC2)		?	{4'h0, MNTH}:
//									(ADDRESS == 16'hFFC3)		?	{3'b000, DMTH}:
//									(ADDRESS == 16'hFFC4)		?	{5'b00000, DWK}:
//									(ADDRESS == 16'hFFC5)		?	{3'b000, HOUR}:
//									(ADDRESS == 16'hFFC6)		?	{2'b00, MIN}:
//									(ADDRESS == 16'hFFC7)		?	{2'b00, SEC}:

									(ADDRESS == 16'hFFCC)		?	{KEY[51],KEY[52],KEY[72],KEY[71],
																			 KEY[28],KEY[27],KEY[30],KEY[29]}:
									(ADDRESS == 16'hFFCD)		?	{KEY[70],KEY[69],KEY[65],KEY[66],
																			 KEY[67],KEY[68],2'b00}:
									(ADDRESS == 16'hFFCE)		?	{KEY[61],KEY[60],KEY[59],KEY[58],
																			 KEY[57],KEY[56],KEY[54],KEY[53]}:
									(ADDRESS == 16'hFFCF)		?	{V_SYNC,VBLANK,H_SYNC,HBLANK,
																			 KEY[0],KEY[64],KEY[63],KEY[62]}:

									(ADDRESS == 16'hFFF0)		?	Version_Hi:
									(ADDRESS == 16'hFFF1)		?	(Version_Lo + BOARD_TYPE):
									(ADDRESS == 16'hFFF2)		?	8'hFE:
									(ADDRESS == 16'hFFF3)		?	8'hEE:
									(ADDRESS == 16'hFFF4)		?	8'hFE:
									(ADDRESS == 16'hFFF5)		?	8'hF1:
									(ADDRESS == 16'hFFF6)		?	8'hFE:
									(ADDRESS == 16'hFFF7)		?	8'hF4:
									(ADDRESS == 16'hFFF8)		?	8'hFE:
									(ADDRESS == 16'hFFF9)		?	8'hF7:
									(ADDRESS == 16'hFFFA)		?	8'hFE:
									(ADDRESS == 16'hFFFB)		?	8'hFA:
									(ADDRESS == 16'hFFFC)		?	8'hFE:
									(ADDRESS == 16'hFFFD)		?	8'hFD:
									(ADDRESS == 16'hFFFE)		?	8'h8C:
									(ADDRESS == 16'hFFFF)		?	8'h1B:
																			8'h55;

assign	DATA_REG1	= !DDR1	?	DD_REG1:
											KEYBOARD_IN;

assign	DATA_REG2	= !DDR2	?	DD_REG2:
											KEY_COLUMN;

assign	DATA_REG3	= !DDR3	?	DD_REG3:
											{DTOA_CODE, 1'b1, casdout};

// A 0 in the DDR makes that pin an input
assign	BIT3 			= !DD_REG4[3]	?	1'b0:
													CSS;
assign	DATA_REG4	= !DDR4	?	DD_REG4:
											{VDG_CONTROL, BIT3, KEY_COLUMN[6], SBS, 1'b1};
/********************************************************************************
*	GPIO
*********************************************************************************/
assign	GPIO[0] = GPIO_DIR[0]	?	GPIO_OUT[0]:
												1'bZ;
assign	GPIO[1] = GPIO_DIR[1]	?	GPIO_OUT[1]:
												1'bZ;
assign	GPIO[2] = GPIO_DIR[2]	?	GPIO_OUT[2]:
												1'bZ;
assign	GPIO[3] = GPIO_DIR[3]	?	GPIO_OUT[3]:
												1'bZ;
assign	GPIO[4] = GPIO_DIR[4]	?	GPIO_OUT[4]:
												1'bZ;
assign	GPIO[5] = GPIO_DIR[5]	?	GPIO_OUT[5]:
												1'bZ;
assign	GPIO[6] = GPIO_DIR[6]	?	GPIO_OUT[6]:
												1'bZ;
assign	GPIO[7] = GPIO_DIR[7]	?	GPIO_OUT[7]:
												1'bZ;


// Clock for Drivewire UART on the slave processor(6850)
// 8 cycles in 50 MHz / 27 = 8*50/27 = 14.815 MHz
//				111	1111 1111 0000 0000	0000 0000
//				A98 7654 3210 fedc ba98	7654 3210
// 27 bit.....  011 0010 0110 0100 1001 1001 0010
// 
always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		COM1_STATE <= 5'h00;
		COM1_CLOCK_X <= 1'b0;
	end
	else
	begin
		COM1_CLOCK_X_D <= COM1_CLOCK_X;
		case (COM1_STATE)
		5'h00:
		begin
			COM1_STATE <= 5'h01;
			COM1_CLOCK_X <= 1'b0;
		end
		5'h01:
		begin
			COM1_STATE <= 5'h02;
			COM1_CLOCK_X <= 1'b1;
		end
		5'h02:
		begin
			COM1_STATE <= 5'h03;
			COM1_CLOCK_X <= 1'b0;
		end
		5'h04:
		begin
			COM1_STATE <= 5'h05;
			COM1_CLOCK_X <= 1'b1;
		end
		5'h05:
		begin
			COM1_STATE <= 5'h06;
			COM1_CLOCK_X <= 1'b0;
		end
		5'h07:
		begin
			COM1_STATE <= 5'h08;
			COM1_CLOCK_X <= 1'b1;
		end
		5'h09:
		begin
			COM1_STATE <= 5'h0A;
			COM1_CLOCK_X <= 1'b0;
		end
		5'h0B:
		begin
			COM1_STATE <= 5'h0C;
			COM1_CLOCK_X <= 1'b1;
		end
		5'h0C:
		begin
			COM1_STATE <= 5'h0D;
			COM1_CLOCK_X <= 1'b0;
		end
		5'h0E:
		begin
			COM1_STATE <= 5'h0F;
			COM1_CLOCK_X <= 1'b1;
		end
		5'h0F:
		begin
			COM1_STATE <= 5'h10;
			COM1_CLOCK_X <= 1'b0;
		end
		5'h11:
		begin
			COM1_STATE <= 5'h12;
			COM1_CLOCK_X <= 1'b1;
		end
		5'h13:
		begin
			COM1_STATE <= 5'h14;
			COM1_CLOCK_X <= 1'b0;
		end
		5'h15:
		begin
			COM1_STATE <= 5'h16;
			COM1_CLOCK_X <= 1'b1;
		end
		5'h16:
		begin
			COM1_STATE <= 5'h17;
			COM1_CLOCK_X <= 1'b0;
		end
		5'h18:
		begin
			COM1_STATE <= 5'h19;
			COM1_CLOCK_X <= 1'b1;
		end
		5'h1A:
		begin
			COM1_STATE <= 5'h00;
			COM1_CLOCK_X <= 1'b0;
		end
		5'h1F:
		begin
			COM1_STATE <= 5'h00;
			COM1_CLOCK_X <= 1'b0;
		end
		default:
		begin
			COM1_STATE <= COM1_STATE + 1'b1;
		end
		endcase
	end
end

//Switch selectable baud rate
always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		COM1_CLK <= 3'b000;
//		COM1_CLOCK <= 1'b0;
	end
	else
	begin
		if (COM1_CLOCK_X == 1'b0 && COM1_CLOCK_X_D == 1'b1)
		begin
			case (COM1_CLK)
			3'b000:
			begin
//				COM1_CLOCK <= 1'b1;
				COM1_CLK <= 3'b001;
			end
			3'b001:
			begin
//				COM1_CLOCK <= 1'b0;
				if(SWITCH[8:7]==2'b10)				// divide by 2 460800 = 14.814814815 / 2 / 16 = 462962.963 = 0.469393%
					COM1_CLK <= 3'b000;
				else
					COM1_CLK <= 3'b010;
			end
			3'b011:
			begin
//				COM1_CLOCK <= 1'b0;
				if(SWITCH[8:7]==2'b01)				// divide by 4 230400
					COM1_CLK <= 3'b000;
				else
					COM1_CLK <= 3'b100;
			end
			3'b111:										// divide by 8 115200
			begin
				COM1_CLK <= 3'b000;
			end
			default:
			begin
				COM1_CLK <= COM1_CLK + 1'b1;
			end
			endcase
		end
	end
end


// Combinatorial clocks :(
//assign UART1_CLK = (SWITCH[8:7] == 2'b11)	?	COM1_CLOCK_X:	// 921600
//															COM1_CLOCK;
//assign WF_CLOCK  = (WF_BAUD == 2'b11)		?	COM1_CLOCK_X:	// 921600
//															COM3_CLOCK;

// Clock for RS232 PAK (6551)
// 24 MHz / 13 = 1.846 MHz
/*always @(negedge CLK24MHZ or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		COM2_STATE <= 13'b0000000000001;
	end
	else
	begin
		COM2_STATE <= {COM2_STATE[11:0],COM2_STATE[12]};
	end
end
*/
// 14.814814815 MHz / 8 = 1.851851852 MHz / 16 = 115740.741 = 115200 + 0.469393%
// CLK_57
always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		COM2_STATE <= 3'b000;
	end
	else
	begin
		if (COM1_CLOCK_X == 1'b0 && COM1_CLOCK_X_D == 1'b1)
			COM2_STATE <= COM2_STATE + 1'b1;
	end
end

reg				end_hold;
reg		[15:0]	hold_data;
reg				RAM0_BE0_L, RAM0_BE1_L;
reg				clear_data_ready, data_ready;

always @(posedge CLK_114 or posedge clear_data_ready)
begin
	if (clear_data_ready)
		data_ready <= 1'b0;
	else
	begin
		if (sdram_cpu_ready)
		begin
			hold_data <= sdram_dout;
			data_ready <= 1'b1;
		end	
	end
end

assign sdram_cpu_addr = {4'b0000, BLOCK_ADDRESS[7:0], ADDRESS[12:1], ADDRESS[0]};
assign sdram_cpu_din = DATA_OUT;
reg		[24:0]	sdram_cpu_addr_L;
reg				last_write;

wire	cache_hit  /* synthesis preserve */;
assign	cache_hit = (sdram_cpu_addr[24:1] == sdram_cpu_addr_L[24:1]);
//assign	cache_hit = 1'b0;

//BANKS
// CPU clock / SRAM Signals for old SRAM
always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		CLK <= 6'h00;
		SWITCH_L <= 3'b000;
		PH_2_RAW <= 1'b0;
		RAM0_RW_N <= 1'b1;
		RAM0_BE0_N <=  1'b1;
		RAM0_BE1_N <= 1'b1;
		hold <= 1'b0;
		cpu_ena <= 1'b0;
		end_hold <= 1'b0;
		RAM0_BE0_L <= 1'b0;
		RAM0_BE1_L <= 1'b0;
		clear_data_ready <= 1'b1;
		sdram_cpu_req <= 1'b0;
		sdram_cpu_rnw <= 1'b1;
		sdram_cpu_addr_L <= 24'h000000;
		last_write <= 1'b1;
	end
	else
	begin
		clear_data_ready <= 1'b0;

//		If we are in hold were done @ data_ready.
		if (hold)
		begin
			if (data_ready)
			begin
//				Hold states are done - kill hold and set end hold to drive data
				hold <= 1'b0;
				end_hold <= 1'b1;
				clear_data_ready <= 1'b1;
//				hold_cnt <= 1'b00;
			end
		end

		if (end_hold)
		begin
//			kill end hold and cpu_ena for the read memory hold 
			end_hold <= 1'b0;
			cpu_ena <= 1'b0;
		end

		if (sdram_cpu_ack)
			sdram_cpu_req <= 1'b0;

		case (CLK)
		6'h00:
		begin
			SWITCH_L <= {turbo_speed, RATE};				// Normal speed
			CLK <= 6'h01;
			PH_2_RAW <= 1'b1;
			RAM0_BE0_N <=  !RAM0_BE0;						// Delete?
			RAM0_BE1_N <=  !RAM0_BE1;

			if (~(hold | end_hold))	// Make sure we are not in a cycle before starting one....
									// If we are still in one - we skip this cpu_enable cycle
			begin
				cpu_ena <= 1'b1;

				if (VMA & RAM_CS)
				begin
//					sdram memory cycle
//					get which byte
					RAM0_BE0_L <=  !ADDRESS[0];
					RAM0_BE1_L <=  ADDRESS[0];

					if (RW_N & cache_hit & ~last_write)		// Read cache hit on stored on 16 hold_data value?
					begin
						end_hold <= 1'b1;					// If so then end the cpu_ena cycle with the updated byte enable
					end
					else
					begin
						sdram_cpu_addr_L <= sdram_cpu_addr;	// Else set hold and start a sdram cycle
						hold <= 1'b1;
						sdram_cpu_req <= 1'b1;
						sdram_cpu_rnw <= RW_N;
						last_write <= ~RW_N;
					end
				end
			end
			

//***************************************
// Gart
//***************************************
//	This needs a total rework
			if(ADDRESS[15:0]==16'hFF73)
			begin
				RAM0_RW_N <= RW_N;
				if(!RW_N)
				begin
					RAM0_ADDRESS <= GART_WRITE[20:1];
				end
				else
				begin
					RAM0_ADDRESS <= GART_READ[20:1];
				end
				if (!RW_N)
				begin
					RAM0_DATA_I[15:0] <= {DATA_OUT, DATA_OUT};
				end
			end
			else
			begin
				if(!VMA & (GART_CNT != 17'h00000))
				begin
					if(GART_CNT[0])
					begin
						RAM0_RW_N <= 1'b0;
						RAM0_ADDRESS <= GART_WRITE[20:1];
						RAM0_DATA_I[15:0] <= {GART_BUF, GART_BUF};
					end
					else
					begin
						RAM0_RW_N <= 1'b1;
						RAM0_ADDRESS <= GART_READ[20:1];
					end
				end
				else
				begin
					RAM0_RW_N <= RW_N;
					RAM0_ADDRESS <= {BLOCK_ADDRESS[7:0], ADDRESS[12:1]};
					if (!RW_N)
					begin
						RAM0_DATA_I[15:0] <= {DATA_OUT, DATA_OUT};
					end
				end
			end
		end
		6'h01:
		begin
			if(!VMA & !GART_CNT[0])
			begin
				GART_BUF <= DATA_IN;
			end
			PH_2_RAW <= 1'b0;

//			if we are not in a memory read [hold] then terminate cpu_ena - just like PH_2
			if (!hold)
				cpu_ena <= 1'b0;

//			Grab sram data to supply after the read hold delay
//			hold_data <= RAM0_DATA_O;
				
			CLK <= 6'h02;
		end
		6'h07:								//	64/8 = 7.16
		begin
			if(SWITCH_L == 3'b101)				//Rate = 7.16?
				CLK <= 6'h00;
			else
				CLK <= 6'h08;
		end
		6'h0F:								//	64/16 = 3.58
		begin
			if(SWITCH_L == 3'b011)				//Rate = 3.58?
				CLK <= 6'h00;
			else
				CLK <= 6'h10;
		end
		6'h1F:								//	64/32 = 1.7857
		begin
			if(SWITCH_L == 3'b001)				//Rate = 1.78?
				CLK <= 6'h00;
			else
				CLK <= 6'h20;
		end
//		6'h1B:								//	50/28 = 1.7857
//		6'h17:								//	50/24 = 2.0833
//		begin
//			RAM0_ADDRESS <= VIDEO_ADDRESS[19:0];

//			RAM0_BE0_N <= !(!VIDEO_ADDRESS[21] & !VIDEO_ADDRESS[20]);
//			RAM0_BE1_N <= !(!VIDEO_ADDRESS[21] & !VIDEO_ADDRESS[20]);
//			VIDEO_BUFFER <= RAM0_DATA_O;
//			if(SWITCH_L[0])				//Rate = 1?
//				CLK <= 6'h00;
//			else
//				CLK <= 6'h20;
//		end
//		6'h37:								// 50/56 = 0.89286
//		begin
//			RAM0_ADDRESS <= VIDEO_ADDRESS[19:0];
//			RAM0_BE0_N <= !(!VIDEO_ADDRESS[21] & !VIDEO_ADDRESS[20]);
//			RAM0_BE1_N <= !(!VIDEO_ADDRESS[21] & !VIDEO_ADDRESS[20]);
//			VIDEO_BUFFER <= RAM0_DATA_O;
//			CLK <= 6'h00;
//		end
		6'h3F:								// Just in case
		begin
			CLK <= 6'h00;
		end
		default:
		begin
			CLK <= CLK + 1'b1;
//			RAM0_ADDRESS <= VIDEO_ADDRESS[19:0];
//			RAM0_BE0_N <= !(!VIDEO_ADDRESS[21] & !VIDEO_ADDRESS[20]);
//			RAM0_BE1_N <= !(!VIDEO_ADDRESS[21] & !VIDEO_ADDRESS[20]);
//			VIDEO_BUFFER <= RAM0_DATA_O;
		end
		endcase
	end
end

assign PH_2 = PH_2_RAW;



assign RESET_P =	!BUTTON_N[3]					// Button
					| RESET; 						// CTRL-ALT-DEL or CTRL-ALT-INS

// Make sure all resets are enabled for a long enough time to allow voltages to settle
always @ (negedge clk_sys or posedge RESET_P)		// 50 MHz / 64
begin
	if(RESET_P)
	begin
		RESET_SM <= 14'h0000;
		CPU_RESET <= 1'b1;
		RESET_N <= 1'b0;
		MUGS <= RESET_INS;	   //This is holding a <ctrl><alt><ins> across a reset to activate the Easter Egg
	end
	else
	begin
		if (MCLOCK[9] == 1'b0 && MCLOCK_DELAY[9] == 1'b1)
			case (RESET_SM)
			14'h1FFF:									// time = 1.28 uS * 14336 = 18350.08 uS
			begin
				RESET_N <= 1'b1;
				CPU_RESET <= 1'b1;
				RESET_SM <= 14'h3800;
			end
			14'h3FFF:									// time = 1.28 uS * 16383 = 20970.24 uS
			begin
				RESET_N <= 1'b1;
				CPU_RESET <= 1'b0;
				RESET_SM <= 14'h3FFF;
			end
			default:
				RESET_SM <= RESET_SM + 1'b1;
			endcase
	end
end

// CPU section copyrighted by John Kent
cpu09 GLBCPU09(
	.clk(clk_sys),
//	.ce(cpu_ena),
	.rst(CPU_RESET),
	.vma(VMA),
	.addr(ADDRESS),
	.rw(RW_N),
	.data_in(DATA_IN),
	.data_out(DATA_OUT),
	.halt(HALT),
	.hold(hold | ~cpu_ena),
	.irq(!CPU_IRQ_N),
	.firq(!CPU_FIRQ_N),
	.nmi(NMI_09)
);

wire	[8:0]		BUFF_ADD_W;		
wire	[8:0]		BUFF_ADD;
wire	[15:0]		BUFF_DATA_O;
wire	[15:0]		BUFF_DATA;
wire				BUFFER_WRITE;


coco_mem_fetch video_fetch(
	.fast_clk(CLK_114),
	.RESET_N(RESET_N),

//	Memory Controller I/O
	.SDRAM_VID_REQ(sdram_vid_req),
	.SDRAM_VID_ADDR(sdram_vid_addr),
	.SDRAM_VID_ACK(sdram_vid_ack),
	.SDRAM_VID_READY(sdram_vid_ready),
	.SDRAM_DOUT(sdram_dout),
	
// RAM / Buffer
	.BUFF_ADD(BUFF_ADD_W), 		// 512x16 ram buffer
	.BUFF_DATA_O(BUFF_DATA_O),
	.BUFFER_WRITE(BUFFER_WRITE),
	
//	Video Controller Inputs for physical address computation
	.RAM_ADDRESS(VIDEO_ADDRESS),
	.HBORDER(HBORDER),
	.HOR_OFFSET(HOR_OFFSET),
	.COCO1(COCO1),
	.HRES(HRES)
);



COCO_VID_RAM_BUF VIDEO_BUFF (
	.CLK(CLK_114),
	.ADDR_I(BUFF_ADD_W),
	.ADDR_O(BUFF_ADD),
	.WE(BUFFER_WRITE),
	.DATA_I(BUFF_DATA_O),
	.DATA_O(BUFF_DATA)
);

//		Disk I/O
//=====================================================================================
wire	FF40_ENA;
wire	FF40_read;
wire	wd1793_data_read;
wire	wd1793_read;
wire	wd1793_write;

assign	FF40_ENA =			({PH_2, RW_N, HDD_EN, ADDRESS[3:0]} == 7'B1010000)	?	1'b1:
																					1'b0;

assign	FF40_read =			({HDD_EN, ADDRESS[3:0]} == 5'h10);
assign	wd1793_data_read =	(HDD_EN && ADDRESS[3]);

assign	wd1793_read =		(RW_N && HDD_EN && ADDRESS[3]);
assign	wd1793_write =		(~RW_N && HDD_EN && ADDRESS[3]);

fdc coco_fdc(
	.CLK(clk_sys),     					// clock
	.RESET_N(RESET_N),	   				// async reset
	.ADDRESS(ADDRESS[1:0]),	       		// i/o port addr for wd1793 & FF48+
	.DATA_IN(DATA_OUT),        			// data in
	.DATA_HDD(DATA_HDD),      			// data out
	.HALT(HALT),         				// DMA request
	.NMI_09(NMI_09),
	.DS_ENABLE(GPIO_DIR[0]),			// DS support - '1 to enable drives 0-2

//	FDC host r/w handling
	.FF40_CLK(clk_sys),
	.FF40_ENA(FF40_ENA),

	.FF40_RD(FF40_read),
	.WD1793_RD(wd1793_data_read),
	
	.WD1793_WR_CTRL(wd1793_write),
	.WD1793_RD_CTRL(wd1793_read),
	
// 	SD block level interface
	.img_mounted(img_mounted), 			// signaling that new image has been mounted
	.img_readonly(img_readonly), 		// mounted as read only. valid only for active bit in img_mounted
	.img_size(img_size),    			// size of image in bytes. 1MB MAX!

	.sd_lba(sd_lba),
	.sd_blk_cnt(sd_blk_cnt), 			// number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),

// 	SD byte level access. Signals for 2-PORT altsyncram.
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),

	.probe(fdc_probe)
);

reg cart_firq_enable;

reg	firq_trig;
reg	[15:0]	firq_tmr;

always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		firq_trig <= 1'b0;
		firq_tmr <= 16'h0000;
		cart_firq_enable <= 1'b1;
	end
	else
	begin
		if (firq_trig)
			if (~(firq_tmr == 16'hffff))
				firq_tmr = firq_tmr + 1'b1;
			else
				cart_firq_enable <= SWITCH[4];

		if ((ioctl_index[5:0] == 6'd1) & ioctl_wr)
		begin
			firq_trig <= 1'b1;
			firq_tmr <= 16'h0000;
		end
	end
end

//***********************************************************************
// Interrupt Sources
//***********************************************************************
// Interrupt source for CART signal
always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		CART_INT_IN_N <= 1'b1;
	end
	else
	begin
		if (PH_2)
			case (MPI_SCS)
			2'b00:
				CART_INT_IN_N <=  (!CART_INT_IN_N )
										&(SER_IRQ);
//				CART_INT_IN_N <=  (!CART_INT_IN_N | SWITCH[4])
//										&(SER_IRQ);
			2'b01:
				CART_INT_IN_N <= (SER_IRQ);
			2'b10:
				CART_INT_IN_N <= (!CART_INT_IN_N | cart_firq_enable)
										&(SER_IRQ);
//				CART_INT_IN_N <=  (!CART_INT_IN_N | SWITCH[4])
//										&(SER_IRQ);
			2'b11:
				CART_INT_IN_N <= (SER_IRQ);
			endcase
	end
end

assign CART_INT_N = CART_INT_IN_N;
assign VSYNC_INT_N = V_SYNC_N;
//assign HSYNC_INT_N = (H_SYNC_N | !H_FLAG);
assign HSYNC_INT_N = H_SYNC_N;
//assign TIMER_INT_N = ;
assign KEY_INT_N = (KEYBOARD_IN == 8'hFF);

//***********************************************************************
// Interrupt Latch RESETs
//***********************************************************************
always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		RST_FF00_N <= 1'b1;
		RST_FF02_N <= 1'b1;
//		RST_FF20_N <= 1'b1;
		RST_FF22_N <= 1'b1;
		RST_FF92_N <= 1'b1;
		RST_FF93_N <= 1'b1;
		TMR_RST_N <= 1'b1;
	end
	else
	begin
		if (PH_2)
			case({RW_N,ADDRESS})
			17'h1FF00:
				RST_FF00_N <= 1'b0;
			17'h1FF04:
				RST_FF00_N <= 1'b0;
			17'h1FF08:
				RST_FF00_N <= 1'b0;
			17'h1FF0C:
				RST_FF00_N <= 1'b0;
			17'h1FF10:
				RST_FF00_N <= 1'b0;
			17'h1FF14:
				RST_FF00_N <= 1'b0;
			17'h1FF18:
				RST_FF00_N <= 1'b0;
			17'h1FF1C:
				RST_FF00_N <= 1'b0;
			17'h1FF02:
				RST_FF02_N <= 1'b0;
			17'h1FF06:
				RST_FF02_N <= 1'b0;
			17'h1FF0A:
				RST_FF02_N <= 1'b0;
			17'h1FF0E:
				RST_FF02_N <= 1'b0;
			17'h1FF12:
				RST_FF02_N <= 1'b0;
			17'h1FF16:
				RST_FF02_N <= 1'b0;
			17'h1FF1A:
				RST_FF02_N <= 1'b0;
			17'h1FF1E:
				RST_FF02_N <= 1'b0;
/*			17'h1FF20:
				RST_FF20_N <= 1'b0;
			17'h1FF24:
				RST_FF20_N <= 1'b0;
			17'h1FF28:
				RST_FF20_N <= 1'b0;
			17'h1FF2C:
				RST_FF20_N <= 1'b0;
			17'h1FF30:
				RST_FF20_N <= 1'b0;
			17'h1FF34:
				RST_FF20_N <= 1'b0;
			17'h1FF38:
				RST_FF20_N <= 1'b0;
			17'h1FF3C:
				RST_FF20_N <= 1'b0;	*/
			17'h1FF22:
				RST_FF22_N <= 1'b0;
			17'h1FF26:
				RST_FF22_N <= 1'b0;
			17'h1FF2A:
				RST_FF22_N <= 1'b0;
			17'h1FF2E:
				RST_FF22_N <= 1'b0;
			17'h1FF32:
				RST_FF22_N <= 1'b0;
			17'h1FF36:
				RST_FF22_N <= 1'b0;
			17'h1FF3A:
				RST_FF22_N <= 1'b0;
			17'h1FF3E:
				RST_FF22_N <= 1'b0;
			17'h0FF22:
				RST_FF22_N <= 1'b0;
			17'h0FF26:
				RST_FF22_N <= 1'b0;
			17'h0FF2A:
				RST_FF22_N <= 1'b0;
			17'h0FF2E:
				RST_FF22_N <= 1'b0;
			17'h0FF32:
				RST_FF22_N <= 1'b0;
			17'h0FF36:
				RST_FF22_N <= 1'b0;
			17'h0FF3A:
				RST_FF22_N <= 1'b0;
			17'h0FF3E:
				RST_FF22_N <= 1'b0;
			17'h1FF92:
				RST_FF92_N <= 1'b0;
			17'h1FF93:
				RST_FF93_N <= 1'b0;
			17'h0FF94:
				TMR_RST_N <= 1'b0;
			17'h0FF95:
				TMR_RST_N <= 1'b0;
			default:
			begin
				RST_FF00_N <= 1'b1;
				RST_FF02_N <= 1'b1;
//				RST_FF20_N <= 1'b1;
				RST_FF22_N <= 1'b1;
				RST_FF92_N <= 1'b1;
				RST_FF93_N <= 1'b1;
				TMR_RST_N <= 1'b1;
			end
			endcase
	end
end

//***********************************************************************
// CoCo1 IRQ Latches
//***********************************************************************
// H_SYNC int for COCO1
// Output	HSYNC1_IRQ_N
// Status	HSYNC1_IRQ_STAT_N
// Buffer	HSYNC1_IRQ_BUF
// State		HSYNC1_IRQ_SM
// Input		HSYNC_INT_N
// Switch	HSYNC1_IRQ_INT @ FF01
// Polarity	HSYNC1_POL
// Clear		FF00
assign HSYNC1_CLK_N = HSYNC_INT_N ^ HSYNC1_POL;
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		HSYNC1_IRQ_BUF <= 2'b11;
		HSYNC1_IRQ_N <= 1'b1;
		HSYNC1_CLK_N_D <= 1'b1;			// no int
	end
	else
	begin
		HSYNC1_CLK_N_D <= HSYNC1_CLK_N;
		if (PH_2)
		begin
			HSYNC1_IRQ_BUF <= {HSYNC1_IRQ_BUF[0], HSYNC1_IRQ_STAT_N};
			HSYNC1_IRQ_N <= HSYNC1_IRQ_BUF[1] | !HSYNC1_IRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF00_N)
begin
	if(!RST_FF00_N)
	begin
		HSYNC1_IRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (HSYNC1_CLK_N_D == 1'b1 && HSYNC1_CLK_N == 1'b0)
			HSYNC1_IRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

// V_SYNC int for COCO1
// Output	VSYNC1_IRQ_N
// Status	VSYNC1_IRQ_STAT_N
// Buffer	VSYNC1_IRQ_BUF
// State		VSYNC1_IRQ_SM
// Input		VSYNC_INT_N
// Switch	VSYNC1_IRQ_INT @ FF01
// Polarity	VSYNC1_POL
// Clear		FF02
assign VSYNC1_CLK_N = VSYNC_INT_N ^ VSYNC1_POL;
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		VSYNC1_IRQ_BUF <= 2'b11;
		VSYNC1_IRQ_N <= 1'b1;
		VSYNC1_CLK_N_D <= 1'b1;
	end
	else
	begin
		VSYNC1_CLK_N_D <= VSYNC1_CLK_N;
		if (PH_2)
		begin
			VSYNC1_IRQ_BUF <= {VSYNC1_IRQ_BUF[0], VSYNC1_IRQ_STAT_N};
			VSYNC1_IRQ_N <= VSYNC1_IRQ_BUF[1] | !VSYNC1_IRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF02_N)
begin
	if(!RST_FF02_N)
	begin
		VSYNC1_IRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (VSYNC1_CLK_N_D == 1'b1 && VSYNC1_CLK_N == 1'b0)
			VSYNC1_IRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

//***********************************************************************
// CoCo1 FIRQ Latches
//***********************************************************************
// CART int for COCO1
// Output	CART1_FIRQ_N
// Status	CART1_FIRQ_STAT_N
// Buffer	CART1_FIRQ_BUF
// State		CART1_FIRQ_SM
// Input		CART_INT_N
// Switch	CART1_FIRQ_INT @ FF01
// Polarity	CART1_FIRQ_POL
// Clear		FF22
assign CART1_BUF_RESET_N =		  RESET_N
									&	!(CART_POL_BUF[0] ^ CART1_POL)
									&	!(CART_POL_BUF[1] ^ CART_POL_BUF[0]);
assign CART1_FIRQ_RESET_N =	CART1_BUF_RESET_N & RST_FF22_N;
assign CART1_CLK_N = CART_INT_N ^ CART1_POL;

always @ (negedge clk_sys)
begin
	if (PH_2)
		CART_POL_BUF <= {CART_POL_BUF[0],CART1_POL}; 
end

always @ (negedge clk_sys or negedge CART1_BUF_RESET_N)
begin
	if(!CART1_BUF_RESET_N)
	begin
		CART1_FIRQ_BUF <= 2'b11;
		CART1_FIRQ_N <= 1'b1;
//		CART1_CLK_N_D <= 1'b1;
	end
	else
	begin
		if (PH_2)
		begin
			CART1_FIRQ_BUF <= {CART1_FIRQ_BUF[0], CART1_FIRQ_STAT_N};
			CART1_FIRQ_N <= CART1_FIRQ_BUF[1] | !CART1_FIRQ_INT;
		end
	end
end

always @ (negedge clk_sys)
	CART1_CLK_N_D <= CART1_CLK_N;


always @ (negedge clk_sys or negedge CART1_FIRQ_RESET_N)
begin
	if(!CART1_FIRQ_RESET_N)
	begin
		CART1_FIRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (CART1_CLK_N_D == 1'b1 && CART1_CLK_N == 1'b0)
			CART1_FIRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

//Bit banger Serial port interrupt not implemented

//***********************************************************************
// CoCo3 FIRQ Latches
//***********************************************************************
// H_SYNC int for COCO3
// Output	HSYNC3_FIRQ_N
// Status	HSYNC3_FIRQ_STAT_N
// Buffer	HSYNC3_FIRQ_BUF
// State		HSYNC3_FIRQ_SM
// Input		HSYNC_INT_N
// Switch	HSYNC3_FIRQ_INT
// Clear		FF93


always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		HSYNC3_FIRQ_BUF <= 2'b11;
		HSYNC3_FIRQ_N <= 1'b1;
		HSYNC_INT_N_D <= 1'b1;
	end
	else
	begin
		HSYNC_INT_N_D <= HSYNC_INT_N;
		if (PH_2)
		begin
			HSYNC3_FIRQ_BUF <= {HSYNC3_FIRQ_BUF[0], HSYNC3_FIRQ_STAT_N};
			HSYNC3_FIRQ_N <= HSYNC3_FIRQ_BUF[1] | !HSYNC3_FIRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF93_N)
begin
	if(!RST_FF93_N)
	begin
		HSYNC3_FIRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (HSYNC_INT_N == 1'b0	&& HSYNC_INT_N_D == 1'b1)
			HSYNC3_FIRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

// V_SYNC int for COCO3
// Output	VSYNC3_FIRQ_N
// Status	VSYNC3_FIRQ_STAT_N
// Buffer	VSYNC3_FIRQ_BUF
// State		VSYNC3_FIRQ_SM
// Input		VSYNC_FIRQ_INT_N
// Switch	VSYNC3_INT
// Clear		FF93
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		VSYNC3_FIRQ_BUF <= 2'b11;
		VSYNC3_FIRQ_N <= 1'b1;
		VSYNC_INT_N_D <= 1'b1;
	end
	else
	begin
		VSYNC_INT_N_D <= VSYNC_INT_N;
		if (PH_2)
		begin
			VSYNC3_FIRQ_BUF <= {VSYNC3_FIRQ_BUF[0], VSYNC3_FIRQ_STAT_N};
			VSYNC3_FIRQ_N <= VSYNC3_FIRQ_BUF[1] | !VSYNC3_FIRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF93_N)
begin
	if(!RST_FF93_N)
	begin
		VSYNC3_FIRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (VSYNC_INT_N_D == 1'b1 && VSYNC_INT_N == 1'b0)
			VSYNC3_FIRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

// CART int for COCO3
// Output	CART3_FIRQ_N
// Status	CART3_FIRQ_STAT_N
// Buffer	CART3_FIRQ_BUF
// State		CART3_FIRQ_SM
// Input		CART_INT_N
// Switch	CART3_FIRQ_INT
// Clear		FF93
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		CART3_FIRQ_BUF <= 2'b11;
		CART3_FIRQ_N <= 1'b1;
		CART_INT_N_D <= 1'b1;
	end
	else
	begin
		CART_INT_N_D <= CART_INT_N;
		if (PH_2)
		begin
			CART3_FIRQ_BUF <= {CART3_FIRQ_BUF[0], CART3_FIRQ_STAT_N};
			CART3_FIRQ_N <= CART3_FIRQ_BUF[1] | !CART3_FIRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF93_N)
begin
	if(!RST_FF93_N)
	begin
		CART3_FIRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (CART_INT_N == 1'b0 && CART_INT_N_D == 1'b1)
			CART3_FIRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

// Keyboard int for COCO3
// Output	KEY3_FIRQ_N
// Status	KEY3_FIRQ_STAT_N
// Buffer	KEY3_FIRQ_BUF
// State		KEY3_FIRQ_SM
// Input		KEY_INT_N
// Switch	KEY3_FIRQ_INT
// Clear		FF93
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		KEY3_FIRQ_BUF <= 2'b11;
		KEY3_FIRQ_N <= 1'b1;
		KEY_INT_N_D <= 1'b1;
	end
	else
	begin
		KEY_INT_N_D <= KEY_INT_N;
		if (PH_2)
		begin
			KEY3_FIRQ_BUF <= {KEY3_FIRQ_BUF[0], KEY3_FIRQ_STAT_N};
			KEY3_FIRQ_N <= KEY3_FIRQ_BUF[1] | !KEY3_FIRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF93_N)
begin
	if(!RST_FF93_N)
	begin
		KEY3_FIRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (KEY_INT_N == 1'b0 && KEY_INT_N_D == 1'b1)
			KEY3_FIRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

// Timer int for COCO3
// Output	TIMER3_FIRQ_N
// Status	TIMER3_FIRQ_STAT_N
// Buffer	TIMER3_FIRQ_BUF
// State		TIMER3_FIRQ_SM
// Input		TIMER_INT_N
// Switch	TIMER3_FIRQ_INT
// Clear		FF93
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		TIMER3_FIRQ_BUF <= 2'b11;
		TIMER3_FIRQ_N <= 1'b1;
		TIMER_INT_N_D <= 1'b1;
	end
	else
	begin
		TIMER_INT_N_D <= TIMER_INT_N;
		if (PH_2)
		begin
			TIMER3_FIRQ_BUF <= {TIMER3_FIRQ_BUF[0], TIMER3_FIRQ_STAT_N};
			TIMER3_FIRQ_N <= TIMER3_FIRQ_BUF[1] | !TIMER3_FIRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF93_N)
begin
	if(!RST_FF93_N)
	begin
		TIMER3_FIRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (TIMER_INT_N == 1'b0 && TIMER_INT_N_D == 1'b1)
			TIMER3_FIRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

//***********************************************************************
// CoCo3 IRQ Latches
//***********************************************************************
// H_SYNC int for COCO3
// Output	HSYNC3_IRQ_N
// Status	HSYNC3_IRQ_STAT_N
// Buffer	HSYNC3_IRQ_BUF
// State		HSYNC3_IRQ_SM
// Input		HSYNC_INT_N
// Switch	HSYNC3_IRQ_INT
// Clear		FF92
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		HSYNC3_IRQ_BUF <= 2'b11;
		HSYNC3_IRQ_N <= 1'b1;
	end
	else
	begin
		if (PH_2)
		begin
			HSYNC3_IRQ_BUF <= {HSYNC3_IRQ_BUF[0], HSYNC3_IRQ_STAT_N};
			HSYNC3_IRQ_N <= HSYNC3_IRQ_BUF[1] | !HSYNC3_IRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF92_N)
begin
	if(!RST_FF92_N)
	begin
		HSYNC3_IRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (HSYNC_INT_N == 1'b0	&& HSYNC_INT_N_D == 1'b1)
			HSYNC3_IRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

// V_SYNC int for COCO3
// Output	VSYNC3_IRQ_N
// Status	VSYNC3_IRQ_STAT_N
// Buffer	VSYNC3_IRQ_BUF
// State		VSYNC3_IRQ_SM
// Input		VSYNC_IRQ_INT_N
// Switch	VSYNC3_IRQ_INT
// Clear		FF92
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		VSYNC3_IRQ_BUF <= 2'b11;
		VSYNC3_IRQ_N <= 1'b1;
	end
	else
	begin
		if (PH_2)
		begin
			VSYNC3_IRQ_BUF <= {VSYNC3_IRQ_BUF[0], VSYNC3_IRQ_STAT_N};
			VSYNC3_IRQ_N <= VSYNC3_IRQ_BUF[1] | !VSYNC3_IRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF92_N)
begin
	if(!RST_FF92_N)
	begin
		VSYNC3_IRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (VSYNC_INT_N_D == 1'b1 && VSYNC_INT_N == 1'b0)
			VSYNC3_IRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

// CART int for COCO3
// Output	CART3_IRQ_N
// Status	CART3_IRQ_STAT_N
// Buffer	CART3_IRQ_BUF
// State		CART3_IRQ_SM
// Input		CART_INT_N
// Switch	CART3_IRQ_INT
// Clear		FF92
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		CART3_IRQ_BUF <= 2'b11;
		CART3_IRQ_N <= 1'b1;
	end
	else
	begin
		if (PH_2)
		begin
			CART3_IRQ_BUF <= {CART3_IRQ_BUF[0], CART3_IRQ_STAT_N};
			CART3_IRQ_N <= CART3_IRQ_BUF[1] | !CART3_IRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF92_N)
begin
	if(!RST_FF92_N)
	begin
		CART3_IRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (CART_INT_N == 1'b0 && CART_INT_N_D == 1'b1)
			CART3_IRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

// Keyboard int for COCO3
// Output	KEY3_IRQ_N
// Status	KEY3_IRQ_STAT_N
// Buffer	KEY3_IRQ_BUF
// State		KEY3_IRQ_SM
// Input		KEY_INT_N
// Switch	KEY3_IRQ_INT
// Clear		FF92
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		KEY3_IRQ_BUF <= 2'b11;
		KEY3_IRQ_N <= 1'b1;
	end
	else
	begin
		if (PH_2)
		begin
			KEY3_IRQ_BUF <= {KEY3_IRQ_BUF[0], KEY3_IRQ_STAT_N};
			KEY3_IRQ_N <= KEY3_IRQ_BUF[1] | !KEY3_IRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF92_N)
begin
	if(!RST_FF92_N)
	begin
		KEY3_IRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (KEY_INT_N == 1'b0 && KEY_INT_N_D == 1'b1)
			KEY3_IRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

// Timer int for COCO3
// Output	TIMER3_IRQ_N
// Status	TIMER3_IRQ_STAT_N
// Buffer	TIMER3_IRQ_BUF
// State		TIMER3_IRQ_SM
// Input		TIMER_INT_N
// Switch	TIMER3_IRQ_INT
// Clear		FF92
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		TIMER3_IRQ_BUF <= 2'b11;
		TIMER3_IRQ_N <= 1'b1;
	end
	else
	begin
		if (PH_2)
		begin
			TIMER3_IRQ_BUF <= {TIMER3_IRQ_BUF[0], TIMER3_IRQ_STAT_N};
			TIMER3_IRQ_N <= TIMER3_IRQ_BUF[1] | !TIMER3_IRQ_INT;
		end
	end
end

always @ (negedge clk_sys or negedge RST_FF92_N)
begin
	if(!RST_FF92_N)
	begin
		TIMER3_IRQ_STAT_N <= 1'b1;			// no int
	end
	else
	begin
		if (TIMER_INT_N == 1'b0 && TIMER_INT_N_D == 1'b1)
			TIMER3_IRQ_STAT_N <= 1'b0;				// Interrupt
	end
end

assign CPU_IRQ_N =  ( GIME_IRQ  | (HSYNC1_IRQ_N		&	VSYNC1_IRQ_N))
						& (!GIME_IRQ  | (TIMER3_IRQ_N		&	HSYNC3_IRQ_N	&	VSYNC3_IRQ_N	&	KEY3_IRQ_N	&	CART3_IRQ_N));
assign CPU_FIRQ_N = ( GIME_FIRQ | (CART1_FIRQ_N))
						& (!GIME_FIRQ | (TIMER3_FIRQ_N	&	HSYNC3_FIRQ_N	&	VSYNC3_FIRQ_N	&	KEY3_FIRQ_N	&	CART3_FIRQ_N));

//Swap the DW and RS232 ports on connectors
assign UART51_RXD =	(!SWITCH[9])	?	OPTRXD:						// Switch 9 off
													DE1RXD;						// Switch 9 on
assign UART50_RXD =	(!SWITCH[9])	?	DE1RXD:						// Switch 9 off
													OPTRXD;						// Switch 9 on
assign DE1TXD =		UART51_TXD;					
assign OPTTXD =		1'b0;

// Timer
//assign TMR_CLK = !TIMER_INS	?	(!H_SYNC_N | !H_FLAG):
//											CLK3_57MHZ;					// 50 MHz / 14 = 3.57 MHz
assign TMR_CLK = !TIMER_INS	?		!H_SYNC_N:
									CLK3_57MHZ;					// 14.32Mhz... /4
//assign CLK3_57MHZ = DIV_14;

reg 	[1:0]	DIV_4;
reg				CLK_14_D;


always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		DIV_4 <= 2'b00;
		CLK_14_D <= 1'b0;
		CLK3_57MHZ <= 1'b0;
		TMR_CLK_D <= 1'b0;
	end
	else
	begin
		CLK_14_D <= CLK_14;
		TMR_CLK_D <= TMR_CLK;
		CLK3_57MHZ <= 1'b0;
		
		if ((CLK_14 == 1'b1) & (CLK_14_D == 1'b0))
		begin
			DIV_4 <= DIV_4 + 1'b1;
			if (DIV_4 == 2'b11)
				CLK3_57MHZ <= 1'b1;
		end		
	end
end



//always @ (negedge clk_sys or negedge RESET_N)
//begin
//	if(!RESET_N)
//	begin
//		DIV_7 <= 3'b000;
//		TMR_CLK_D <= 1'b0;
//	end
//	else
//	begin
//		TMR_CLK_D <= TMR_CLK;
//		case (DIV_7)
//		3'b110:
//		begin
//			DIV_7 <= 3'b000;
//			DIV_14 <= !DIV_14;
//		end
//		default:
//			DIV_7 <= DIV_7 + 1'b1;
//		endcase
//	end
//end

always @(negedge clk_sys or negedge TMR_RST_N)
begin
	if(!TMR_RST_N)
	begin
		TIMER_INT_N <= 1'b1;
		BLINK <= 1'b1;
		TIMER <= 13'h1FFF;
	end
	else
	begin
		if (TMR_CLK == 1'b0 && TMR_CLK_D == 1'b1)
		begin
			if(!TMR_ENABLE)
			begin
				TIMER_INT_N <= 1'b1;
				BLINK <= 1'b1;
				TIMER <= 13'h1FFF;
			end
			else
			begin
				case (TIMER)
				13'h0000:
				begin
					TIMER_INT_N <= 1'b0;
					BLINK <= !BLINK;
					TIMER <= 13'h1FFF;
				end
				13'h1FFF: 												//Maybe this should be 1XXX
				begin
// This turns out being TIMER + 2 as in Sockmaster's GIME Reference 1986 GIME
// 0 to TIMER-1 (0 to TIMER is really TIMER counts + 1)
// This timer goes from 0 directly to 1FFF where it loads the timer count and decrements from there
// So 1FFF to TIMER to 0 is TIMER + 2 counts
					TIMER_INT_N <= 1'b1;
					if({TMR_MSB,TMR_LSB} != 12'h000)
						TIMER <= {1'b0,TMR_MSB,TMR_LSB};
				end
				default:
					TIMER <= TIMER - 1'b1;
				endcase
			end
		end
	end
end

// Most of the latches for settings
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
// FF00
		DD_REG1 <= 8'h00;
// FF01
		HSYNC1_IRQ_INT <= 1'b0;
		HSYNC1_POL <= 1'b0;
		DDR1 <= 1'b0;
		SEL[0] <= 1'b0;
// FF02
		DD_REG2 <= 8'h00;
		KEY_COLUMN <= 8'h00;
// FF03
		VSYNC1_IRQ_INT <= 1'b0;
		VSYNC1_POL <= 1'b0;
		DDR2 <= 1'b0;
		SEL[1] <= 1'b0;
// FF20
		DD_REG3 <= 8'h00;
		DTOA_CODE <= 6'b000000;
		SOUND_DTOA <= 6'b000000;
//		BBTXD <= 1'b0;
// FF21
//		CD_INT <= 1'b0;
//		CD_POL <= 1'b0;
		DDR3 <= 1'b0;
		CAS_MTR <= 1'b0;
// FF22
		DD_REG4 <= 8'h00;
		SBS <= 1'b0;
		CSS <= 1'b0;
		VDG_CONTROL <= 4'b0000;
// FF23
		CART1_FIRQ_INT <= 1'b0;
		CART1_POL <= 1'b0;
		DDR4 <= 1'b0;
		SOUND_EN <= 1'b0;
// FF70-FF72
		GART_WRITE <= 23'h000000;			// 19' for 512kb
// FF74-FF76
		GART_READ <= 23'h000000;			// 19' for 512kb
// FF77
		GART_INC <= 2'b00;
//	FF78-FF79
		GART_CNT <= 17'h00000;
// FF7A
		ORCH_LEFT <= 8'b10000000;
// FF7B
		ORCH_RIGHT <= 8'b10000000;
// FF7C
		ORCH_LEFT_EXT <= 8'b10000000;
		ORCH_LEFT_EXT_BUF <= 8'b10000000;
// FF7D
		ORCH_RIGHT_EXT <= 8'b10000000;
		ORCH_RIGHT_EXT_BUF <= 8'b10000000;
// FF7F
		W_PROT <= 2'b11;
		MPI_SCS <= SWITCH[2:1];
		MPI_CTS <= SWITCH[2:1];
// FF80
//		CK_START <= 1'b0;
// FF81
//		CK_DATA_OUT <= 8'h00;
// FF82
//		CK_DEVICE <= 8'h00;
// FF83
//		CK_REG <= 8'h00;
// FF84
//		SDRAM_READ <= 1'b0;
// FF85-FF86
//		SDRAM_DIN <= 16'h0000;
// FF87-FF88
//		SDRAM_ADDR[21:7] <= 15'h0000;
// FF8E-FF8F
		GPIO_DIR <= 8'd0;
		GPIO_OUT <= 8'h00;
// FF90
		ROM <= 2'b00;
		ST_SCS <= 1'b0;
		VEC_PAG_RAM <= 1'b0;
		GIME_FIRQ <= 1'b0;
		GIME_IRQ <= 1'b0;
		MMU_EN <= 1'b0;
		COCO1 <= 1'b0;
// FF91
		TIMER_INS <= 1'b0;
		MMU_TR <= 1'b0;
// FF92
		TIMER3_IRQ_INT <= 1'b0;
		HSYNC3_IRQ_INT <= 1'b0;
		VSYNC3_IRQ_INT <= 1'b0;
		KEY3_IRQ_INT <= 1'b0;
		CART3_IRQ_INT <= 1'b0;
// FF93
		TIMER3_FIRQ_INT <= 1'b0;
		HSYNC3_FIRQ_INT <= 1'b0;
		VSYNC3_FIRQ_INT <= 1'b0;
		KEY3_FIRQ_INT <= 1'b0;
		CART3_FIRQ_INT <= 1'b0;
// FF94
		TMR_MSB <= 4'h0;
		TMR_ENABLE <= 1'b0;
// FF95
		TMR_LSB <= 8'h00;
// FF98
		GRMODE <= 1'b0;
		LPR <= 3'b000;
// FF99
		HLPR <= 1'b0;
		LPF <= 2'b00;
		HRES <= 4'b0000;
		CRES <= 2'b00;
// FF9A
//		BDR_PAL <= 12'h000;
// FF9B
		SCRN_START_HSB <= 6'b000000;		// extra 4 bits for 2MB screen start
		SAM_EXT <= 2'b00;				// extra 2 bits for 8MB SAMs
// FF9C
		VERT_FIN_SCRL <= 4'h0;
// FF9D
		SCRN_START_MSB <= 8'h00;
// FF9E
		SCRN_START_LSB <= 8'h00;
// FF9F
		HVEN <= 1'b0;
		HOR_OFFSET <= 7'h00;
// FFA0
		SAM00 <= 10'h000;	// 2MB   6'00 for 512kb
// FFA1
		SAM01 <= 10'h000;
// FFA2
		SAM02 <= 10'h000;
// FFA3
		SAM03 <= 10'h000;
// FFA4
		SAM04 <= 10'h000;
// FFA5
		SAM05 <= 10'h000;
// FFA6
		SAM06 <= 10'h000;
// FFA7
		SAM07 <= 10'h000;
// FFA8
		SAM10 <= 10'h000;
// FFA9
		SAM11 <= 10'h000;
// FFAA
		SAM12 <= 10'h000;
// FFAB
		SAM13 <= 10'h000;
// FFAC
		SAM14 <= 10'h000;
// FFAD
		SAM15 <= 10'h000;
// FFAE
		SAM16 <= 10'h000;
// FFAF
		SAM17 <= 10'h000;
// FFB0
		PALETTE[0] <= 12'h0000;
// FFB1
		PALETTE[1] <= 12'h0000;
// FFB2
		PALETTE[2] <= 12'h000;
// FFB3
		PALETTE[3] <= 12'h000;
// FFB4
		PALETTE[4] <= 12'h000;
// FFB5
		PALETTE[5] <= 12'h000;
// FFB6
		PALETTE[6] <= 12'h000;
// FFB7
		PALETTE[7] <= 12'h000;
// FFB8
		PALETTE[8] <= 12'h000;
// FFB9
		PALETTE[9] <= 12'h000;
// FFBA
		PALETTE[10] <= 12'h000;
// FFBB
		PALETTE[11] <= 12'h000;
// FFBC
		PALETTE[12] <= 12'h000;
// FFBD
		PALETTE[13] <= 12'h000;
// FFBE
		PALETTE[14] <= 12'h000;
// FFBF
		PALETTE[15] <= 12'h000;
// FFC0 / FFC1
		V[0] <= 1'b0;
// FFC2 / FFC3
		V[1] <= 1'b0;
// FFC4 / FFC5
		V[2] <= 1'b0;
// FFC6 / FFC7
		VERT[0] <= 1'b0;
// FFC8 / FFC9
		VERT[1] <= 1'b0;
// FFCA / FFCB
		VERT[2] <= 1'b0;
// FFCC / FFCD
		VERT[3] <= 1'b0;
// FFCE / FFCF
		VERT[4] <= 1'b0;
// FFD0 / FFD1
		VERT[5] <= 1'b0;
// FFD2 / FFD3
		VERT[6] <= 1'b0;
// FFD8 / FFD9
		RATE <= 1'b0;
// FFDE / FFDF
		RAM <= 1'b0;
	end
	else
	begin
// Sound Mux
		if (PH_2)
		begin

			case ({SOUND_EN,SEL})
			3'b100:
				SOUND_DTOA <= DTOA_CODE;
			3'b111:
				SOUND_DTOA <= 6'b000000;
			endcase

			if(!RW_N)
			begin
				case (ADDRESS)
				16'hFF00:
				begin
					if(!DDR1)
						DD_REG1 <= DATA_OUT;
				end
				16'hFF01:
				begin
					HSYNC1_IRQ_INT <= DATA_OUT[0];
					HSYNC1_POL <= DATA_OUT[1];
					DDR1 <= DATA_OUT[2];
					SEL[0] <= DATA_OUT[3];
				end
				16'hFF02:
				begin
					if(!DDR2)
						DD_REG2 <= DATA_OUT;
					else
						KEY_COLUMN <= DATA_OUT;
				end
				16'hFF03:
				begin
					VSYNC1_IRQ_INT <= DATA_OUT[0];
					VSYNC1_POL <= DATA_OUT[1];
					DDR2 <= DATA_OUT[2];
					SEL[1] <= DATA_OUT[3];
				end
				16'hFF04:
				begin
					if(!DDR1)
						DD_REG1 <= DATA_OUT;
				end
				16'hFF05:
				begin
					HSYNC1_IRQ_INT <= DATA_OUT[0];
					HSYNC1_POL <= DATA_OUT[1];
					DDR1 <= DATA_OUT[2];
					SEL[0] <= DATA_OUT[3];
				end
				16'hFF06:
				begin
					if(!DDR2)
						DD_REG2 <= DATA_OUT;
					else
						KEY_COLUMN <= DATA_OUT;
				end
				16'hFF07:
				begin
					VSYNC1_IRQ_INT <= DATA_OUT[0];
					VSYNC1_POL <= DATA_OUT[1];
					DDR2 <= DATA_OUT[2];
					SEL[1] <= DATA_OUT[3];
				end
				16'hFF08:
				begin
					if(!DDR1)
						DD_REG1 <= DATA_OUT;
				end
				16'hFF09:
				begin
					HSYNC1_IRQ_INT <= DATA_OUT[0];
					HSYNC1_POL <= DATA_OUT[1];
					DDR1 <= DATA_OUT[2];
					SEL[0] <= DATA_OUT[3];
				end
				16'hFF0A:
				begin
					if(!DDR2)
						DD_REG2 <= DATA_OUT;
					else
						KEY_COLUMN <= DATA_OUT;
				end
				16'hFF0B:
				begin
					VSYNC1_IRQ_INT <= DATA_OUT[0];
					VSYNC1_POL <= DATA_OUT[1];
					DDR2 <= DATA_OUT[2];
					SEL[1] <= DATA_OUT[3];
				end
				16'hFF0C:
				begin
					if(!DDR1)
						DD_REG1 <= DATA_OUT;
				end
				16'hFF0D:
				begin
					HSYNC1_IRQ_INT <= DATA_OUT[0];
					HSYNC1_POL <= DATA_OUT[1];
					DDR1 <= DATA_OUT[2];
					SEL[0] <= DATA_OUT[3];
				end
				16'hFF0E:
				begin
					if(!DDR2)
						DD_REG2 <= DATA_OUT;
					else
						KEY_COLUMN <= DATA_OUT;
				end
				16'hFF0F:
				begin
					VSYNC1_IRQ_INT <= DATA_OUT[0];
					VSYNC1_POL <= DATA_OUT[1];
					DDR2 <= DATA_OUT[2];
					SEL[1] <= DATA_OUT[3];
				end
				16'hFF10:
				begin
					if(!DDR1)
						DD_REG1 <= DATA_OUT;
				end
				16'hFF11:
				begin
					HSYNC1_IRQ_INT <= DATA_OUT[0];
					HSYNC1_POL <= DATA_OUT[1];
					DDR1 <= DATA_OUT[2];
					SEL[0] <= DATA_OUT[3];
				end
				16'hFF12:
				begin
					if(!DDR2)
						DD_REG2 <= DATA_OUT;
					else
						KEY_COLUMN <= DATA_OUT;
				end
				16'hFF13:
				begin
					VSYNC1_IRQ_INT <= DATA_OUT[0];
					VSYNC1_POL <= DATA_OUT[1];
					DDR2 <= DATA_OUT[2];
					SEL[1] <= DATA_OUT[3];
				end
				16'hFF14:
				begin
					if(!DDR1)
						DD_REG1 <= DATA_OUT;
				end
				16'hFF15:
				begin
					HSYNC1_IRQ_INT <= DATA_OUT[0];
					HSYNC1_POL <= DATA_OUT[1];
					DDR1 <= DATA_OUT[2];
					SEL[0] <= DATA_OUT[3];
				end
				16'hFF16:
				begin
					if(!DDR2)
						DD_REG2 <= DATA_OUT;
					else
						KEY_COLUMN <= DATA_OUT;
				end
				16'hFF17:
				begin
					VSYNC1_IRQ_INT <= DATA_OUT[0];
					VSYNC1_POL <= DATA_OUT[1];
					DDR2 <= DATA_OUT[2];
					SEL[1] <= DATA_OUT[3];
				end
				16'hFF18:
				begin
					if(!DDR1)
						DD_REG1 <= DATA_OUT;
				end
				16'hFF19:
				begin
					HSYNC1_IRQ_INT <= DATA_OUT[0];
					HSYNC1_POL <= DATA_OUT[1];
					DDR1 <= DATA_OUT[2];
					SEL[0] <= DATA_OUT[3];
				end
				16'hFF1A:
				begin
					if(!DDR2)
						DD_REG2 <= DATA_OUT;
					else
						KEY_COLUMN <= DATA_OUT;
				end
				16'hFF1B:
				begin
					VSYNC1_IRQ_INT <= DATA_OUT[0];
					VSYNC1_POL <= DATA_OUT[1];
					DDR2 <= DATA_OUT[2];
					SEL[1] <= DATA_OUT[3];
				end
				16'hFF1C:
				begin
					if(!DDR1)
						DD_REG1 <= DATA_OUT;
				end
				16'hFF1D:
				begin
					HSYNC1_IRQ_INT <= DATA_OUT[0];
					HSYNC1_POL <= DATA_OUT[1];
					DDR1 <= DATA_OUT[2];
					SEL[0] <= DATA_OUT[3];
				end
				16'hFF1E:
				begin
					if(!DDR2)
						DD_REG2 <= DATA_OUT;
					else
						KEY_COLUMN <= DATA_OUT;
				end
				16'hFF1F:
				begin
					VSYNC1_IRQ_INT <= DATA_OUT[0];
					VSYNC1_POL <= DATA_OUT[1];
					DDR2 <= DATA_OUT[2];
					SEL[1] <= DATA_OUT[3];
				end
				16'hFF20:
				begin
					if(!DDR3)
						DD_REG3 <= DATA_OUT;
					else
					begin
						DTOA_CODE <= DATA_OUT[7:2];
//						if({SOUND_EN,SEL} == 3'b100)
//							SOUND_DTOA <= DATA_OUT[7:2];
					end
				end
				16'hFF21:
				begin
//					CD_INT <= DATA_OUT[0];
//					CD_POL <= DATA_OUT[1];
					DDR3 <= DATA_OUT[2];
					CAS_MTR <= DATA_OUT[3];
				end
				16'hFF22:
				begin
					if(!DDR4)
						DD_REG4 <= DATA_OUT;
					else
					begin
						SBS <= DATA_OUT[1];
						CSS <= DATA_OUT[3];
						VDG_CONTROL <= DATA_OUT[7:4];
					end
				end
				16'hFF23:
				begin
					CART1_FIRQ_INT <= DATA_OUT[0];
					CART1_POL <= DATA_OUT[1];
					DDR4 <= DATA_OUT[2];
					SOUND_EN <= DATA_OUT[3];
				end
				16'hFF24:
				begin
					if(!DDR3)
						DD_REG3 <= DATA_OUT;
					else
					begin
						DTOA_CODE <= DATA_OUT[7:2];
//						if({SOUND_EN,SEL} == 3'b100)
//							SOUND_DTOA <= DATA_OUT[7:2];
					end
				end
				16'hFF25:
				begin
//					CD_INT <= DATA_OUT[0];
//					CD_POL <= DATA_OUT[1];
					DDR3 <= DATA_OUT[2];
					CAS_MTR <= DATA_OUT[3];
				end
				16'hFF26:
				begin
					if(!DDR4)
						DD_REG4 <= DATA_OUT;
					else
					begin
						SBS <= DATA_OUT[1];
						CSS <= DATA_OUT[3];
						VDG_CONTROL <= DATA_OUT[7:4];
					end
				end
				16'hFF27:
				begin
					CART1_FIRQ_INT <= DATA_OUT[0];
					CART1_POL <= DATA_OUT[1];
					DDR4 <= DATA_OUT[2];
					SOUND_EN <= DATA_OUT[3];
				end
				16'hFF28:
				begin
					if(!DDR3)
						DD_REG3 <= DATA_OUT;
					else
					begin
						DTOA_CODE <= DATA_OUT[7:2];
//						if({SOUND_EN,SEL} == 3'b100)
//							SOUND_DTOA <= DATA_OUT[7:2];
					end
				end
				16'hFF29:
				begin
//					CD_INT <= DATA_OUT[0];
//					CD_POL <= DATA_OUT[1];
					DDR3 <= DATA_OUT[2];
					CAS_MTR <= DATA_OUT[3];
				end
				16'hFF2A:
				begin
					if(!DDR4)
						DD_REG4 <= DATA_OUT;
					else
					begin
						SBS <= DATA_OUT[1];
						CSS <= DATA_OUT[3];
						VDG_CONTROL <= DATA_OUT[7:4];
					end
				end
				16'hFF2B:
				begin
					CART1_FIRQ_INT <= DATA_OUT[0];
					CART1_POL <= DATA_OUT[1];
					DDR4 <= DATA_OUT[2];
					SOUND_EN <= DATA_OUT[3];
				end
				16'hFF2C:
				begin
					if(!DDR3)
						DD_REG3 <= DATA_OUT;
					else
					begin
						DTOA_CODE <= DATA_OUT[7:2];
//						if({SOUND_EN,SEL} == 3'b100)
//							SOUND_DTOA <= DATA_OUT[7:2];
					end
				end
				16'hFF2D:
				begin
//					CD_INT <= DATA_OUT[0];
//					CD_POL <= DATA_OUT[1];
					DDR3 <= DATA_OUT[2];
					CAS_MTR <= DATA_OUT[3];
				end
				16'hFF2E:
				begin
					if(!DDR4)
						DD_REG4 <= DATA_OUT;
					else
					begin
						SBS <= DATA_OUT[1];
						CSS <= DATA_OUT[3];
						VDG_CONTROL <= DATA_OUT[7:4];
					end
				end
				16'hFF2F:
				begin
					CART1_FIRQ_INT <= DATA_OUT[0];
					CART1_POL <= DATA_OUT[1];
					DDR4 <= DATA_OUT[2];
					SOUND_EN <= DATA_OUT[3];
				end
				16'hFF30:
				begin
					if(!DDR3)
						DD_REG3 <= DATA_OUT;
					else
					begin
						DTOA_CODE <= DATA_OUT[7:2];
//						if({SOUND_EN,SEL} == 3'b100)
//							SOUND_DTOA <= DATA_OUT[7:2];
					end
				end
				16'hFF31:
				begin
//					CD_INT <= DATA_OUT[0];
//					CD_POL <= DATA_OUT[1];
					DDR3 <= DATA_OUT[2];
					CAS_MTR <= DATA_OUT[3];
				end
				16'hFF32:
				begin
					if(!DDR4)
						DD_REG4 <= DATA_OUT;
					else
					begin
						SBS <= DATA_OUT[1];
						CSS <= DATA_OUT[3];
						VDG_CONTROL <= DATA_OUT[7:4];
					end
				end
				16'hFF33:
				begin
					CART1_FIRQ_INT <= DATA_OUT[0];
					CART1_POL <= DATA_OUT[1];
					DDR4 <= DATA_OUT[2];
					SOUND_EN <= DATA_OUT[3];
				end
				16'hFF34:
				begin
					if(!DDR3)
						DD_REG3 <= DATA_OUT;
					else
					begin
						DTOA_CODE <= DATA_OUT[7:2];
//						if({SOUND_EN,SEL} == 3'b100)
//							SOUND_DTOA <= DATA_OUT[7:2];
					end
				end
				16'hFF35:
				begin
//					CD_INT <= DATA_OUT[0];
//					CD_POL <= DATA_OUT[1];
					DDR3 <= DATA_OUT[2];
					CAS_MTR <= DATA_OUT[3];
				end
				16'hFF36:
				begin
					if(!DDR4)
						DD_REG4 <= DATA_OUT;
					else
					begin
						SBS <= DATA_OUT[1];
						CSS <= DATA_OUT[3];
						VDG_CONTROL <= DATA_OUT[7:4];
					end
				end
				16'hFF37:
				begin
					CART1_FIRQ_INT <= DATA_OUT[0];
					CART1_POL <= DATA_OUT[1];
					DDR4 <= DATA_OUT[2];
					SOUND_EN <= DATA_OUT[3];
				end
				16'hFF38:
				begin
					if(!DDR3)
						DD_REG3 <= DATA_OUT;
					else
					begin
						DTOA_CODE <= DATA_OUT[7:2];
//						if({SOUND_EN,SEL} == 3'b100)
//							SOUND_DTOA <= DATA_OUT[7:2];
					end
				end
				16'hFF39:
				begin
//					CD_INT <= DATA_OUT[0];
//					CD_POL <= DATA_OUT[1];
					DDR3 <= DATA_OUT[2];
					CAS_MTR <= DATA_OUT[3];
				end
				16'hFF3A:
				begin
					if(!DDR4)
						DD_REG4 <= DATA_OUT;
					else
					begin
						SBS <= DATA_OUT[1];
						CSS <= DATA_OUT[3];
						VDG_CONTROL <= DATA_OUT[7:4];
					end
				end
				16'hFF3B:
				begin
					CART1_FIRQ_INT <= DATA_OUT[0];
					CART1_POL <= DATA_OUT[1];
					DDR4 <= DATA_OUT[2];
					SOUND_EN <= DATA_OUT[3];
				end
				16'hFF3C:
				begin
					if(!DDR3)
						DD_REG3 <= DATA_OUT;
					else
					begin
						DTOA_CODE <= DATA_OUT[7:2];
//						if({SOUND_EN,SEL} == 3'b100)
//							SOUND_DTOA <= DATA_OUT[7:2];
					end
				end
				16'hFF3D:
				begin
//					CD_INT <= DATA_OUT[0];
//					CD_POL <= DATA_OUT[1];
					DDR3 <= DATA_OUT[2];
					CAS_MTR <= DATA_OUT[3];
				end
				16'hFF3E:
				begin
					if(!DDR4)
						DD_REG4 <= DATA_OUT;
					else
					begin
						SBS <= DATA_OUT[1];
						CSS <= DATA_OUT[3];
						VDG_CONTROL <= DATA_OUT[7:4];
					end
				end
				16'hFF3F:
				begin
					CART1_FIRQ_INT <= DATA_OUT[0];
					CART1_POL <= DATA_OUT[1];
					DDR4 <= DATA_OUT[2];
					SOUND_EN <= DATA_OUT[3];
				end
				16'hFF70:
				begin
					GART_WRITE[22:16] <= DATA_OUT[6:0];	//2MB    512Kb: GART_WRITE[18:16] <= DATA_OUT[2:0];
				end
				16'hFF71:
				begin
					GART_WRITE[15:8] <= DATA_OUT;
				end
				16'hFF72:
				begin
					GART_WRITE[7:0] <= DATA_OUT;
				end
				16'hFF73:
				begin
					if(GART_INC[0])
						GART_WRITE <= GART_WRITE + 1'b1;
				end
				16'hFF74:
				begin
					GART_READ[22:16] <= DATA_OUT[6:0];	//2MB     512:GART_READ[18:16] <= DATA_OUT[2:0];
				end
				16'hFF75:
				begin
					GART_READ[15:8] <= DATA_OUT;
				end
				16'hFF76:
				begin
					GART_READ[7:0] <= DATA_OUT;
				end
				16'hFF77:
				begin
					GART_INC <= DATA_OUT[1:0];
				end
				16'hFF78:
				begin
					GART_CNT[16:9] <= DATA_OUT;
				end
				16'hFF79:
				begin
					GART_CNT[8:0] <= {DATA_OUT,1'b0};
				end
				16'hFF7A:
				begin
					ORCH_LEFT <= DATA_OUT;
					ORCH_LEFT_EXT <= ORCH_LEFT_EXT_BUF;
				end
				16'hFF7B:
				begin
					ORCH_RIGHT <= DATA_OUT;
					ORCH_RIGHT_EXT <= ORCH_RIGHT_EXT_BUF;
				end
				16'hFF7C:
					ORCH_LEFT_EXT_BUF <= DATA_OUT;
				16'hFF7D:
					ORCH_RIGHT_EXT_BUF <= DATA_OUT;
				16'hFF7F:
				begin
					W_PROT[0] <=  DATA_OUT[2] | !DATA_OUT[3];
					W_PROT[1] <= !DATA_OUT[2] |  DATA_OUT[3] | W_PROT[0];
					MPI_SCS <= DATA_OUT[1:0];
					MPI_CTS <= DATA_OUT[5:4];
				end
//				16'hFF80:
//				begin
//					CK_START <= DATA_OUT[0];
//				end
//				16'hFF81:
//				begin
//					CK_DATA_OUT <= DATA_OUT;
//				end
//				16'hFF82:
//				begin
//					CK_DEVICE <= DATA_OUT;
//				end
//				16'hFF83:
//				begin
//					CK_REG <= DATA_OUT;
//				end
//SRH Removal
//				16'hFF84:
//				begin
//					SDRAM_READ <= DATA_OUT[0];
//				end
//				16'hFF85:
//				begin
//					SDRAM_DIN[7:0] <= DATA_OUT;
//				end
//				16'hFF86:
//				begin
//					SDRAM_DIN[15:8] <= DATA_OUT;
//				end
//				16'hFF87:
//				begin
//					SDRAM_ADDR[21:15] <= DATA_OUT[6:0];
//				end
//				16'hFF88:
//				begin
//					SDRAM_ADDR[14:7] <= DATA_OUT;
//				end
				16'hFF8E:
					GPIO_DIR <= DATA_OUT;
				16'hFF8F:
					GPIO_OUT <= DATA_OUT;
				16'hFF90:
				begin
					ROM <= DATA_OUT[1:0];
					ST_SCS <= DATA_OUT[2];
					VEC_PAG_RAM <= DATA_OUT[3];
					GIME_FIRQ <= DATA_OUT[4];
					GIME_IRQ <= DATA_OUT[5];
					MMU_EN <= DATA_OUT[6];
					COCO1 <= DATA_OUT[7];
				end
				16'hFF91:
				begin
					TIMER_INS <= DATA_OUT[5];
					MMU_TR <= DATA_OUT[0];
				end
				16'hFF92:
				begin
					TIMER3_IRQ_INT <= DATA_OUT[5];
					HSYNC3_IRQ_INT <= DATA_OUT[4];
					VSYNC3_IRQ_INT <= DATA_OUT[3];
					KEY3_IRQ_INT <= DATA_OUT[1];
					CART3_IRQ_INT <= DATA_OUT[0];
				end
				16'hFF93:
				begin
					TIMER3_FIRQ_INT <= DATA_OUT[5];
					HSYNC3_FIRQ_INT <= DATA_OUT[4];
					VSYNC3_FIRQ_INT <= DATA_OUT[3];
					KEY3_FIRQ_INT <= DATA_OUT[1];
					CART3_FIRQ_INT <= DATA_OUT[0];
				end
				16'hFF94:
				begin
					TMR_MSB <= DATA_OUT[3:0];
					TMR_ENABLE <= 1'b1;
				end
				16'hFF95:
				begin
					TMR_LSB <= DATA_OUT;
				end
				16'hFF98:
				begin
					GRMODE <= DATA_OUT[7];
					HRES[3] <= DATA_OUT[6];	// Extended resolutions
					LPR <= DATA_OUT[2:0];
				end
				16'hFF99:
				begin
					HLPR <= DATA_OUT[7];
					LPF <= DATA_OUT[6:5];
					HRES[2:0] <= DATA_OUT[4:2];
					CRES <= DATA_OUT[1:0];
				end
				16'hFF9A:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[16][5:0] <= DATA_OUT[5:0];
						PALETTE[16][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[16][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFF9B:
				begin
//					GIME-X code
					SCRN_START_HSB <= {1'b0,DATA_OUT[6],DATA_OUT[3:0]}; // extra 6 bits for 32MB screen start (Highest always 0, no way to set it
//					To do - expand memory management for 32M.
//					SAM_EXT <= {CPU_DATA[7],CPU_DATA[5:4]};
//					SCRN_START_HSB <= DATA_OUT[3:0];	// extra 4 bits for 8MB screen start [V5]
					SAM_EXT <= DATA_OUT[5:4];	// [V5]
				end
				16'hFF9C:
				begin
					VERT_FIN_SCRL <= DATA_OUT[3:0];
				end
				16'hFF9D:
				begin
					SCRN_START_MSB <= DATA_OUT;
				end
				16'hFF9E:
				begin
					SCRN_START_LSB <= DATA_OUT;
				end
				16'hFF9F:
				begin
					HVEN <= DATA_OUT[7];
					HOR_OFFSET <= DATA_OUT[6:0];
				end
				16'hFFA0:
				begin
					SAM00 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFA1:
				begin
					SAM01 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFA2:
				begin
					SAM02 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFA3:
				begin
					SAM03 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFA4:
				begin
					SAM04 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFA5:
				begin
					SAM05 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFA6:
				begin
					SAM06 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFA7:
				begin
					SAM07 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFA8:
				begin
					SAM10 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFA9:
				begin
					SAM11 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFAA:
				begin
					SAM12 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFAB:
				begin
					SAM13 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFAC:
				begin
					SAM14 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFAD:
				begin
					SAM15 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFAE:
				begin
					SAM16 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFAF:
				begin
					SAM17 <= {SAM_EXT,DATA_OUT[7:0]};
				end
				16'hFFB0:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[0][5:0] <= DATA_OUT[5:0];
						PALETTE[0][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[0][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFB1:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[1][5:0] <= DATA_OUT[5:0];
						PALETTE[1][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[1][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFB2:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[2][5:0] <= DATA_OUT[5:0];
						PALETTE[2][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[2][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFB3:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[3][5:0] <= DATA_OUT[5:0];
						PALETTE[3][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[3][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFB4:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[4][5:0] <= DATA_OUT[5:0];
						PALETTE[4][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[4][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFB5:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[5][5:0] <= DATA_OUT[5:0];
						PALETTE[5][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[5][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFB6:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[6][5:0] <= DATA_OUT[5:0];
						PALETTE[6][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[6][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFB7:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[7][5:0] <= DATA_OUT[5:0];
						PALETTE[7][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[7][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFB8:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[8][5:0] <= DATA_OUT[5:0];
						PALETTE[8][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[8][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFB9:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[9][5:0] <= DATA_OUT[5:0];
						PALETTE[9][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[9][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFBA:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[10][5:0] <= DATA_OUT[5:0];
						PALETTE[10][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[10][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFBB:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[11][5:0] <= DATA_OUT[5:0];
						PALETTE[11][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[11][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFBC:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[12][5:0] <= DATA_OUT[5:0];
						PALETTE[12][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[12][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFBD:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[13][5:0] <= DATA_OUT[5:0];
						PALETTE[13][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[13][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFBE:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[14][5:0] <= DATA_OUT[5:0];
						PALETTE[14][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[14][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFBF:
				begin
					if(!DATA_OUT[7])
					begin
						PALETTE[15][5:0] <= DATA_OUT[5:0];
						PALETTE[15][11:6] <= DATA_OUT[5:0];
					end
					else
					begin
						PALETTE[15][5:0] <= DATA_OUT[5:0];
					end
				end
				16'hFFC0:
				begin
					V[0] <= 1'b0;
				end
				16'hFFC1:
				begin
					V[0] <= 1'b1;
				end
				16'hFFC2:
				begin
					V[1] <= 1'b0;
				end
				16'hFFC3:
				begin
					V[1] <= 1'b1;
				end
				16'hFFC4:
				begin
					V[2] <= 1'b0;
				end
				16'hFFC5:
				begin
					V[2] <= 1'b1;
				end
				16'hFFC6:
				begin
					VERT[0] <= 1'b0;
				end
				16'hFFC7:
				begin
					VERT[0] <= 1'b1;
				end
				16'hFFC8:
				begin
					VERT[1] <= 1'b0;
				end
				16'hFFC9:
				begin
					VERT[1] <= 1'b1;
				end
				16'hFFCA:
				begin
					VERT[2] <= 1'b0;
				end
				16'hFFCB:
				begin
					VERT[2] <= 1'b1;
				end
				16'hFFCC:
				begin
					VERT[3] <= 1'b0;
				end
				16'hFFCD:
				begin
					VERT[3] <= 1'b1;
				end
				16'hFFCE:
				begin
					VERT[4] <= 1'b0;
				end
				16'hFFCF:
				begin
					VERT[4] <= 1'b1;
				end
				16'hFFD0:
				begin
					VERT[5] <= 1'b0;
				end
				16'hFFD1:
				begin
					VERT[5] <= 1'b1;
				end
				16'hFFD2:
				begin
					VERT[6] <= 1'b0;
				end
				16'hFFD3:
				begin
					VERT[6] <= 1'b1;
				end
				16'hFFD8:
				begin
					RATE <= 1'b0;
				end
				16'hFFD9:
				begin
					RATE <= 1'b1;
				end
				16'hFFDE:
				begin
					RAM <= 1'b0;
				end
				16'hFFDF:
				begin
					RAM <= 1'b1;
				end
				endcase
			end
			else
			begin
				if(ADDRESS == 16'hFF73)
				begin
					if(GART_INC[1])
						GART_READ <= GART_READ + 1'b1;
				end
				else
				begin
					if(!VMA & (GART_CNT != 17'h00000))
					begin
						GART_CNT <= GART_CNT - 1'b1;
						if(GART_CNT[0] & GART_INC[0])
							GART_WRITE <= GART_WRITE + 1'b1;
						else
							if(!GART_CNT[0] & GART_INC[1])
								GART_READ <= GART_READ + 1'b1;
					end
				end
			end
		end
	end
end

// The code for the internal and Orchestra sound

// Internal Sound generation
assign SOUND		=	{1'b0, SBS, SOUND_DTOA};

assign SOUND_LEFT = {ORCH_LEFT,  ORCH_LEFT_EXT}	+ {SOUND, 8'h00};
assign SOUND_RIGHT = {ORCH_RIGHT, ORCH_RIGHT_EXT}	+ {SOUND, 8'h00};


// The code for the paddles
//`include "..\CoCo3FPGA_Common\paddles.v"

/*
  Joystick direction code
  buttons are handled below in the keyboard routines 
*/

always @(posedge clk_sys) begin
  case (SEL)
  2'b00:
		if (joya2[15:10] > DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
  2'b01:
  		if (joya2[7:2] > DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
2'b10:
		if (joya1[15:10] > DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
  2'b11:
  		if (joya1[7:2] > DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
	endcase
end



/*****************************************************************************
* Convert PS/2 keyboard to CoCo keyboard
* Buttons
* 0 left 1
* 1 left 2
* 2 right 2
* 3 right 1
******************************************************************************/
assign KEYBOARD_IN[0] =  !((!KEY_COLUMN[0] & KEY[0])				// @
								 | (!KEY_COLUMN[1] & KEY[1])				// A
								 | (!KEY_COLUMN[2] & KEY[2])				// B
								 | (!KEY_COLUMN[3] & KEY[3])				// C
								 | (!KEY_COLUMN[4] & KEY[4])				// D
								 | (!KEY_COLUMN[5] & KEY[5])				// E
								 | (!KEY_COLUMN[6] & KEY[6])				// F
								 | (!KEY_COLUMN[7] & KEY[7])				// G
								 | !P_SWITCH[3]);								// Right Joystick Switch 1

assign KEYBOARD_IN[1] =	 !((!KEY_COLUMN[0] & KEY[8])				// H
								 | (!KEY_COLUMN[1] & KEY[9])				// I
								 | (!KEY_COLUMN[2] & KEY[10])				// J
								 | (!KEY_COLUMN[3] & KEY[11])				// K
								 | (!KEY_COLUMN[4] & KEY[12])				// L
								 | (!KEY_COLUMN[5] & KEY[13])				// M
								 | (!KEY_COLUMN[6] & KEY[14])				// N
								 | (!KEY_COLUMN[7] & KEY[15])				// O
								 | !P_SWITCH[0]);								// Left Joystick Switch 1

assign KEYBOARD_IN[2] =	 !((!KEY_COLUMN[0] & KEY[16])				// P
								 | (!KEY_COLUMN[1] & KEY[17])				// Q
								 | (!KEY_COLUMN[2] & KEY[18])				// R
								 | (!KEY_COLUMN[3] & KEY[19])				// S
								 | (!KEY_COLUMN[4] & KEY[20])				// T
								 | (!KEY_COLUMN[5] & KEY[21])				// U
								 | (!KEY_COLUMN[6] & KEY[22])				// V
								 | (!KEY_COLUMN[7] & KEY[23])				// W
								 | !P_SWITCH[2]);								// Left Joystick Switch 2

assign KEYBOARD_IN[3] =	 !((!KEY_COLUMN[0] & KEY[24])				// X
								 | (!KEY_COLUMN[1] & KEY[25])				// Y
								 | (!KEY_COLUMN[2] & KEY[26])				// Z
								 | (!KEY_COLUMN[3] & KEY[27])				// up
								 | (!KEY_COLUMN[4] & KEY[28])				// down
								 | (!KEY_COLUMN[5] & KEY[29])				// Backspace & left
								 | (!KEY_COLUMN[6] & KEY[30])				// right
								 | (!KEY_COLUMN[7] & KEY[31])				// space
								 | !P_SWITCH[1]);								// Right Joystick Switch 2

assign KEYBOARD_IN[4] =	 !((!KEY_COLUMN[0] & KEY[32])				// 0
								 | (!KEY_COLUMN[1] & KEY[33])				// 1
								 | (!KEY_COLUMN[2] & KEY[34])				// 2
								 | (!KEY_COLUMN[3] & KEY[35])				// 3
								 | (!KEY_COLUMN[4] & KEY[36])				// 4
								 | (!KEY_COLUMN[5] & KEY[37])				// 5
								 | (!KEY_COLUMN[6] & KEY[38])				// 6
								 | (!KEY_COLUMN[7] & KEY[39]));			// 7

assign KEYBOARD_IN[5] =	 !((!KEY_COLUMN[0] & KEY[40])				// 8
								 | (!KEY_COLUMN[1] & KEY[41])				// 9
								 | (!KEY_COLUMN[2] & KEY[42])				// :
								 | (!KEY_COLUMN[3] & KEY[43])				// ;
								 | (!KEY_COLUMN[4] & KEY[44])				// ,
								 | (!KEY_COLUMN[5] & KEY[45])				// -
								 | (!KEY_COLUMN[6] & KEY[46])				// .
								 | (!KEY_COLUMN[7] & KEY[47]));			// /

assign KEYBOARD_IN[6] =	 !((!KEY_COLUMN[0] & KEY[48])				// CR
								 | (!KEY_COLUMN[1] & KEY[49])				// TAB
								 | (!KEY_COLUMN[2] & KEY[50])				// ESC
								 | (!KEY_COLUMN[3] & KEY[51])				// ALT
								 | (!KEY_COLUMN[3] & (!BUTTON_N[0] | MUGS))		// ALT (Easter Egg)
								 | (!KEY_COLUMN[4] & KEY[52])				// CTRL
								 | (!KEY_COLUMN[4] & (!BUTTON_N[0] | MUGS))		// CTRL (Easter Egg)
								 | (!KEY_COLUMN[5] & KEY[53])				// F1
								 | (!KEY_COLUMN[6] & KEY[54])				// F2
								 | (!KEY_COLUMN[7] & KEY[55] & !SHIFT_OVERRIDE)	// shift
								 |	(!KEY_COLUMN[7] & SHIFT));				// Forced Shift

assign KEYBOARD_IN[7] =	 JSTICK;											// Joystick input

// PS2 Keyboard interface
COCOKEY coco_keyboard(
		.RESET_N(RESET_N),
		.CLK50MHZ(clk_sys),
		.SLO_CLK(V_SYNC_N),
//		.SLO_CLK(MCLOCK[19]),
		.PS2_CLK(ps2_clk),
		.PS2_DATA(ps2_data),
		.KEY(KEY),
		.SHIFT(SHIFT),
		.SHIFT_OVERRIDE(SHIFT_OVERRIDE),
		.RESET(RESET),
		.RESET_INS(RESET_INS)
);
/*****************************************************************************
* Video
******************************************************************************/

// SRH DE2-115 DAC lower video bits = '0000' amd transfomation RGB[7:4] ,= RGB[3:0]
assign PIX_CLK = CLK_14;

wire PIX_CLK_D;

// Video DAC
always @ (negedge clk_sys)
begin
	PIX_CLK_D <= PIX_CLK;
	if (PIX_CLK == 1'b1 & PIX_CLK_D == 1'b0)
	begin
		COLOR_BUF <= COLOR;						// Delay COLOR by 1 clock cycle to align with 256 Color SRAM
		H_SYNC <= !H_SYNC_N;					// Delay H_SYNC by 1 clock cycle
		V_SYNC <= !V_SYNC_N;					// Delay V_SYNC by 1 clock cycle
		RED[3:0] <= 4'B0000;
		GREEN[3:0] <= 4'B0000;
		BLUE[3:0] <= 4'B0000;
		VGA_SYNC_N <= 1'b1;

//  	Retrace Black
//		if(COLOR_BUF[9])
//		begin
//			RED[7:4] <=	4'B0000;
//			GREEN[7:4] <= 4'B0000;
//			BLUE[7:4] <= 4'B0000;
//		end
//  Retrace Black
        if(COLOR_BUF[9])
        begin
            case(COLOR_BUF[7:0])
            //  8'h80:   // Black
            //  begin
            //   {RED3, GREEN3, BLUE3, RED2, GREEN2, BLUE2, RED1, GREEN1, BLUE1, RED0, GREEN0, BLUE0} <= 12'h000;   // Black
            //  end
            8'h81:   // Green
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h492;  // GREEN
            end
            8'h82:   // White
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'hFFF;  // WHITE
            end
            8'h00:   // Dark Green
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h080;
            end
            8'h01:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h010;
            end
            8'h02:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h010;
            end
            8'h03:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h480;
            end
            8'h04:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h490;
            end
            8'h05:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h010;
            end
            8'h06:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h010;
            end
            8'h07:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h400;
            end
            8'h08:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h410;
            end
            8'h09:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h480;
            end
            8'h0A:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h400;
            end
            8'h0B:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h490;
            end
            8'h0C:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h490;
            end
            8'h0D:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h010;
            end
            8'h0E:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h010;
            end
            8'h0F:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h492;
            end
            //  8'h10:   // Black
            //  begin
            //    {RED3, GREEN3, BLUE3, RED2, GREEN2, BLUE2, RED1, GREEN1, BLUE1, RED0, GREEN0, BLUE0} <= 12'h000;
            //  end
            8'h11:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h028;
            end
            8'h12:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h082;
            end
            8'h13:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'hFE8;
            end
            8'h14:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'hFD0;
            end
            8'h15:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h218;
            end
            8'h16:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h130;
            end
            8'h17:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h768;
            end
            8'h18:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'hDE0;
            end
            8'h19:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h9E0;
            end
            8'h1A:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h648;
            end
            8'h1B:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'hFD8;
            end
            8'h1C:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'hDF8;
            end
            8'h1D:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h008;
            end
            8'h1E:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h020;
            end
            8'h1F:
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'hFFF;
            end
            default:   // Black
            begin
                {RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= 12'h000; // Black
            end
            endcase
		end
		else
// 		Request for every other line to be black
// 		Looks more like the original video
// 		Not for 15KHz Video
		begin
			begin
				if(COLOR_BUF[8])
				begin
					{RED[7], GREEN[7], BLUE[7], RED[6], GREEN[6], BLUE[6], RED[5], GREEN[5], BLUE[5], RED[4], GREEN[4], BLUE[4]} <= VDAC_OUT[11:0];
				end
				else
				begin
					RED[7] <= PALETTE[COLOR_BUF[4:0]][11];
					RED[6] <= PALETTE[COLOR_BUF[4:0]][8];
					RED[5] <= PALETTE[COLOR_BUF[4:0]][5];
					RED[4] <= PALETTE[COLOR_BUF[4:0]][2];
					GREEN[7] <= PALETTE[COLOR_BUF[4:0]][10];
					GREEN[6] <= PALETTE[COLOR_BUF[4:0]][7];
					GREEN[5] <= PALETTE[COLOR_BUF[4:0]][4];
					GREEN[4] <= PALETTE[COLOR_BUF[4:0]][1];
					BLUE[7] <=	PALETTE[COLOR_BUF[4:0]][9];
					BLUE[6] <=	PALETTE[COLOR_BUF[4:0]][6];
					BLUE[5] <=	PALETTE[COLOR_BUF[4:0]][3];
					BLUE[4] <=	PALETTE[COLOR_BUF[4:0]][0];
				end
			end
		end
	end
end


VDAC	VDAC_inst (
	.data ( {4'h0,PALETTE[0][11:0]} ),
	.rdaddress ( COLOR[7:0] ),
	.rdclock ( PIX_CLK ),
	.wraddress ( DATA_OUT ),
	.wrclock ( PH_2 ),
	.wren ( VDAC_EN ),
	.q ( VDAC_OUT )
	);

wire	[10:0]	font_adrs;
wire	[7:0]	font_data;

wire HBORDER;

// Video timing and modes
COCO3VIDEO MISTER_COCOVID(
// Clocks / RESET
	.MASTER_CLK(clk_sys),		// Should this be inverted?
	.PIX_CLK(PIX_CLK),			//14.32 MHz = 69.3 nS
	.RESET_N(RESET_N),

// Video Out
	.COLOR(COLOR),
	.HSYNC_N(H_SYNC_N),
	.SYNC_FLAG(H_FLAG),			//Have to figure out this one...
	.VSYNC_N(V_SYNC_N),
	.HBLANKING(HBLANK),
	.VBLANKING(VBLANK),

// RAM / Buffer
	.RAM_ADDRESS(VIDEO_ADDRESS),
	.BUFF_ADD(BUFF_ADD),
	.RAM_DATA(BUFF_DATA),

// Mode Selection
	.COCO1(COCO1),
	.V(V),
	.BP(GRMODE),
	.VERT(VERT),
	.VID_CONT(VDG_CONTROL),
 	.CSS(CSS),
	.LPF(LPF),
	.VERT_FIN_SCRL(VERT_FIN_SCRL),
	.HLPR(HLPR & !SWITCH[3]),
	.LPR(LPR),
	.HRES(HRES),
	.CRES(CRES),
	.HVEN(HVEN),

// Starting location
	.SCRN_START_HSB(SCRN_START_HSB),		// 2 extra bits for 2MB screen start
	.SCRN_START_MSB(SCRN_START_MSB),
	.SCRN_START_LSB(SCRN_START_LSB),


// Attributes
	.SWITCH(SWITCH[5]),
	.BLINK(BLINK),

	.PHASE(PHASE),

	.ROM_ADDRESS(font_adrs),
	.ROM_DATA1(font_data),

	.HBORDER(HBORDER)

//HBORDER_INT,
//VBORDER_INT

);



parameter SHDOW_FONT_LOCK_REG = 16'hfff0;
parameter SHDOW_FONT_DATA_REG = 16'hfff1;

parameter SHDOW_FONT_UNLOCK_UPPER_VAL = 8'hA5;
parameter SHDOW_FONT_UNLOCK_LOWER_VAL = 8'h5A;

parameter SHDOW_FONT_USE_ALT = 8'hC3;

reg		[7:0]	Font_Lock_Register;
reg		[7:0]	Font_Data_Register;
reg				Font_Data_Write_Strobe;
wire	[1:0]	Font_ROM_Unlocks;
wire			Font_ROM_Unlocked;
wire			Font_ROM_Upper_Select;
reg		[10:0]	Font_ROM_CPU_W;
reg		[3:0]	Font_ROM_Mach_Shft;
wire			Font_ROM_Mach_WE;
wire	[11:0]	Font_ROM_Adrs_Buf;
wire	[7:0]	Font_ROM_Data_Buf;

always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		Font_Data_Write_Strobe <= 1'b0;
//		SHDOW_FONT_LOCK_REG = 16'hfff0;
		Font_Lock_Register <= 8'H00;
//		SHDOW_FONT_DATA_REG = 16'hfff1;
		Font_Data_Register <= 8'H00;
	end
	else
	begin
		Font_Data_Write_Strobe <= 1'b0;
		if (PH_2)
		begin
			if(!RW_N)
			begin
				case (ADDRESS[15:0])
//				SHDOW_FONT_LOCK_REG = 16'hfff0;
				SHDOW_FONT_LOCK_REG:
					Font_Lock_Register <= DATA_OUT[7:0];
		
//				SHDOW_FONT_DATA_REG = 16'hfff1;
				SHDOW_FONT_DATA_REG:
				begin
					Font_Data_Register <= DATA_OUT[7:0];
					Font_Data_Write_Strobe <= 1'b1;
				end
				endcase;
			end
		end
	end
end

assign 	Font_ROM_Unlocks = 	(Font_Lock_Register == SHDOW_FONT_UNLOCK_UPPER_VAL) ?	2'b10:
							(Font_Lock_Register == SHDOW_FONT_UNLOCK_LOWER_VAL) ?	2'b01:
																					2'b00;

assign	Font_ROM_Unlocked =	 Font_ROM_Unlocks[1] | Font_ROM_Unlocks[0];

assign	Font_ROM_Upper_Select = (Font_Lock_Register == SHDOW_FONT_USE_ALT)?			1'b1:
																					1'b0;

assign Font_ROM_Mach_Shft[0] = Font_Data_Write_Strobe;
assign Font_ROM_Mach_WE = Font_ROM_Mach_Shft[1];

always @ (negedge clk_sys or negedge Font_ROM_Unlocked)
begin
	if(!Font_ROM_Unlocked)
	begin
		Font_ROM_CPU_W <= 11'b00000000000;
		Font_ROM_Mach_Shft[3:1] <= 3'b000;
	end
	else
	begin
		Font_ROM_Mach_Shft[3:1] <= Font_ROM_Mach_Shft[2:0];
		if (Font_ROM_Mach_Shft[3])
			Font_ROM_CPU_W <= Font_ROM_CPU_W + 1'b1;
	end
end

//	A little MISTer glue

// The address write can be just Font_ROM_Unlocks[1], Font_ROM_CPU_W} if no MISTer
// The data_w can be Font_Data_Register if no MISTer

assign Font_ROM_Adrs_Buf = (Font_ROM_Unlocked) ?	{Font_ROM_Unlocks[1], Font_ROM_CPU_W}:
													ioctl_addr[11:0];

assign Font_ROM_Data_Buf = (Font_ROM_Unlocked) ?	Font_Data_Register:
													ioctl_data[7:0];
// COCO3 Character rom

coco3_Char_ROM coco3_Char_ROM(
	.CLK(clk_sys),
	.ADDR_R({Font_ROM_Upper_Select, font_adrs}),
	.ADDR_W(Font_ROM_Adrs_Buf),
	.WE(((ioctl_index[5:0] == 6'd3) & ioctl_wr) | Font_ROM_Mach_WE), // Can be just Font_ROM_Mach_WE if no MISTer
    .DATA_R(font_data),
    .DATA_W(Font_ROM_Data_Buf)
);


reg     [4:0]           CLK_6551;
// 14.31818
// 50 MHz / 27 = 1.852 MHz
always @(negedge CLK50MHZ or negedge RESET_N)
begin
        if(!RESET_N)
                CLK_6551 <= 5'd0;
        else
                case(CLK_6551)
                5'd26:
                        CLK_6551 <= 5'd0;
                default:
                        CLK_6551 <= CLK_6551 + 1'b1;
                endcase
end


// RS232PAK UART
glb6551 RS232(
.RESET_N(RESET_N),
.RX_CLK(RX_CLK2),
.RX_CLK_IN(CLK_6551[4]),
.XTAL_CLK_IN(CLK_6551[4]),
//.RX_CLK_IN(COM2_STATE[2]),
//.XTAL_CLK_IN(COM2_STATE[2]),
.PH_2(PH_2),
.DI(DATA_OUT),
.DO(DATA_RS232),
.IRQ(SER_IRQ),
.CS({1'b0, RS232_EN}),
.RW_N(RW_N),
.RS(ADDRESS[1:0]),
.TXDATA_OUT(UART_TXD),
.RXDATA_IN(UART_RXD),
.RTS(UART_RTS),
.CTS(UART_CTS),
.DCD(1'b1),
.DTR(UART_DTR),
.DSR(UART_DSR)
);




endmodule
