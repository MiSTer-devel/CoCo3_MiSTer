////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 5.x.x
// File Name:		coco3fpga.sv
//
// CoCo3 in an FPGA
//
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent or Greg Miller dependant on selection
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 5.x
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
// MISTer Conversion by Stan Hodge and Alan Steremberg (& Gary Becker)
// stan.pda@gmail.com
// 
////////////////////////////////////////////////////////////////////////////////



module coco3fpga(
// Input Clocks
//	CLOCKS

input				CLK_50M,
input				CLK_114,
input				CLK_57,
input				CLK_28,
input				CLK_14,

input 				COCO_RESET_N,

// Video

output	reg	[7:0]	RED,
output	reg	[7:0]	GREEN,
output	reg	[7:0]	BLUE,

output	reg			H_SYNC,
output	reg			V_SYNC,
//output	reg			VGA_SYNC_N,
output				PIX_CLK,
output				HBLANK,
output				VBLANK,

// PS/2
input				ps2_clk,
input				ps2_data,

//Mouse

input		[24:0]	ps2_mouse,

// RS-232
output				UART_TXD,
input 				UART_RXD,
output 				UART_RTS,
input 				UART_CTS,
output				UART_DTR,
input 				UART_DSR,


//output [5:0] 		SOUND_OUT,
output [15:0] 		SOUND_LEFT,
output [15:0] 		SOUND_RIGHT,

// CoCo Joystick
// Needs removal.... ???
//input	[3:0]		PADDLE_CLK,
input	[3:0]		P_SWITCH,
// joystick input
// digital for buttons
input [15:0]		joy1,  
input [15:0]		joy2,
// analog for position
input [15:0]		joya1,
input [15:0]		joya2,
input 				joy_use_dpad,
input				SWAP_M_J,

//	Config Static switches
input	[9:0]  		SWITCH,			

// roms, cartridges, etc
input	[7:0] 		ioctl_data,
input	[24:0]		ioctl_addr,
input				ioctl_download,
input				ioctl_wr,
input 	[15:0]		ioctl_index,

//	SDRAM Info
input	[15:0]		sdram_sz,

// SD block level interface
input   [6:0]  		img_mounted, // signaling that new image has been mounted
input				img_readonly, // mounted as read only. valid only for active bit in img_mounted
input 	[63:0] 		img_size,    // size of image in bytes. 1MB MAX!

output	[31:0] 		sd_lba[7],
output  [5:0] 		sd_blk_cnt[7], // number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!

output 	reg  [6:0]	sd_rd,
output 	reg  [6:0]	sd_wr,
input        [6:0]	sd_ack,

// SD byte level access. Signals for 2-PORT altsyncram.
input  	[8:0] 		sd_buff_addr,
input  	[7:0] 		sd_buff_dout,
output 	[7:0] 		sd_buff_din[7],
input        		sd_buff_wr,

//	GPIO
inout	[7:0]		GPIO,

//  Misc
input				EE_N,
input				PHASE,
output	[31:0]		PROBE,

//  Cassette Input linkage
output				clk_Q_out,
output				cas_relay,
input				casdout,

//	SDRAM

output	[24:0]		sdram_cpu_addr,
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

input  				AMW_Trigger,
output 				AMW_ACK,

input	[64:0]		RTC,

input				F_Turbo,
input	[2:0]		turbo_speed,
output	[2:0]		assigned_turbo_speed,
input	[2:0]		Mem_Size,
input	[1:0]		AUTO_MODE,

input	[71:0]		Config_Data

);



assign clk_Q_out = PH_2;
assign cas_relay = CAS_MTR;


//Version 5 bits Major and 4 bits Minor
parameter Version_Hi = 8'h51;


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

//	Define Config features

reg		[7:0]	i_val;
`include "../rtl/config.sv"


reg		[15:0]	RAM0_DATA_I;

wire			RAM_CS;						// DATA_IN Mux select

 
wire	[21:0]	FLASH_ADDRESS;

wire	[7:0]	FLASH_DATA;

// Extra Buttons and Switches

//	SRH	MISTer
//	Static Buttons
wire   	[3:0]	 BUTTON_N;
									
reg				CLK3_57MHZ;

wire			EF;
wire			PH_2;
`ifndef CoCo3_CYC_ACC_6809
reg 			PH_2_RAW;
`endif
reg				RESET_N;
reg		[6:0]	CPU_RESET_SM;
reg				CPU_RESET;
wire			RESET_INS;
reg				MUGS = 0;
wire			RESET;
wire			RESET_P;
wire	[15:0]	ADDRESS;
wire	[11:0]	BLOCK_ADDRESS;		// 5:0 for 512kb
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
reg		[1:0]	TMR_ENABLE;
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
wire			ENA_DISK2;
wire			ENA_PAK;

wire			HDD_EN;
wire			HDD_EN_DATA;

reg		[1:0]	MPI_SCS;				// IO select
reg		[1:0]	MPI_CTS;				// ROM select
reg				SBS;
reg		[11:0]	SAM00;	// 8MB    5:0 for 512kb   
reg		[11:0]	SAM01;
reg		[11:0]	SAM02;
reg		[11:0]	SAM03;
reg		[11:0]	SAM04;
reg		[11:0]	SAM05;
reg		[11:0]	SAM06;
reg		[11:0]	SAM07;
reg		[11:0]	SAM10;
reg		[11:0]	SAM11;
reg		[11:0]	SAM12;
reg		[11:0]	SAM13;
reg		[11:0]	SAM14;
reg		[11:0]	SAM15;
reg		[11:0]	SAM16;
reg		[11:0]	SAM17;
reg		[3:0]	SAM_EXT; // 2 bits for 8 MB, 4 bits for 32 MB + 21 bits (2 MB blocks)
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
wire			CART_SEL;
reg		[5:0]	DTOA_CODE;
reg		[5:0]	SOUND_DTOA;

//assign SOUND_OUT = SOUND_DTOA; // AJS - hook up sound directly

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
reg				DACLRCLK;
reg		[5:0]	DAC_STATE;
wire 			H_FLAG;

reg		[3:0]	SWITCH_L;

wire			RST_FF00_N;
wire			RST_FF02_N;
//reg			RST_FF20_N;
wire			RST_FF22_N;
wire			RST_FF92_N;
wire			RST_FF93_N;
wire			CPU_IRQ_N;
wire			CPU_FIRQ_N;
reg		[2:0]	DIV_7;
reg				DIV_14;
reg		[12:0]	TIMER;
wire			TMR_CLK;
reg				TMR_CLK_D;
wire			SER_IRQ;
reg				COM3_CLOCK;
reg		[2:0]	COM3_CLK;
wire	[7:0]	DATA_HDD;
wire			RS232_EN;
wire			RX_CLK2;
wire	[7:0]	DATA_RS232;
reg		[2:0]	ROM_BANK;
wire			SLOT3_HW;
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
reg				JSTICK;
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
reg		[7:0]	GART_BUF;
reg		[7:0]	BI_TIMER;
reg				DBUF_BI_TO;
reg				DBUF_BI_TO1;
reg				BI_TO;
wire			BI_TO_RST;
reg				ANALOG;
wire			VDAC_EN;
wire	[15:0]	VDAC_OUT;

wire			CART_INT_N;
reg				CART_INT_N_D;
wire			VSYNC_INT_N;
reg				VSYNC_INT_N_D;
wire			HSYNC_INT_N;
reg				HSYNC_INT_N_D;
wire            TMR_RESET_N;
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
wire			clk_sys;

reg 			hold;
`ifndef CoCo3_CYC_ACC_6809
reg 			cpu_ena;
`endif

wire	[4:0]	CENT; // BIN Values
wire	[6:0]	YEAR;
wire	[3:0]	MNTH;
wire	[4:0]	DMTH;
wire	[2:0]	DWK;
wire	[4:0]	HOUR;
wire	[5:0]	MIN;
wire	[5:0]	SEC;

//	This is a Real Time Clock.  It is initialized by RTC which is provided by MISTER.
//	RTC is provided only once after reset to initialize the clock.  RTC is in BCD
//	format.  The output here is in BIN values.  Note while CENT will roll in the clock
//	it is NOT initialized from MiSTer.  As such - it is a static value set to 5'd20.
//	BASIC does not use this.  OS9 does not by default, however it is designed to be
//	compatiable with CoCo3FPGA's RTC at the register level.

rtc #(50000000) CC3_rtc(
.clk(CLK_50M),
.RTC(RTC),
.O_CENT(CENT),
.O_YEAR(YEAR),
.O_MNTH(MNTH),
.O_DMTH(DMTH),
.O_DWK(DWK),
.O_HOUR(HOUR),
.O_MIN(MIN),
.O_SEC(SEC)
);


// Probe's defined
//assign PROBE[6:0] = {CART1_POL, CART1_BUF_RESET_N, CART1_FIRQ_STAT_N, CART1_CLK_N, CART1_FIRQ_N, RESET_N, PH_2};
//assign PROBE[7:0] = {1'b0, CART1_POL, CART1_FIRQ_N, CART1_FIRQ_BUF[0], CART1_CLK_N_D, CART1_FIRQ_RESET_N, CART1_CLK_N, PH_2};
assign PROBE[7:0] = {1'b0, TMR_CLK, DATA_IN[5], RST_FF93_N_SFT[0], RST_FF93_N, !TIMER3_FIRQ_N, VSYNC_INT_N, TIMER_INT_N};
assign PROBE[15:8] = 8'h00;
assign PROBE[23:16] = 8'h00;
//assign PROBE[31:24] = {3'b000, DATA_OUT[3], MOTOR, DRIVE_SEL_EXT[0], HDD_EN, ADDRESS[0]};
assign PROBE[31:24] = {8'h00};

assign clk_sys = CLK_57;

assign BUTTON_N[3:0] = {COCO_RESET_N, 2'b1,EE_N};


/*****************************************************************************
* RAM signals
******************************************************************************/


assign BLOCK_ADDRESS =  ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b10000)       ?   SAM00:  //  10 000X XXXX 0000-1FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b10001)       ?   SAM01:  //  10 001X XXXX 2000-3FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b10010)       ?   SAM02:  //  10 010X XXXX 4000-5FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b10011)       ?   SAM03:  //  10 011X XXXX 6000-7FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b10100)       ?   SAM04:  //  10 100X XXXX 8000-9FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b10101)       ?   SAM05:  //  10 101X XXXX A000-BFFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b10110)       ?   SAM06:  //  10 110X XXXX C000-DFFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:12]}               ==  6'b101110)      ?   SAM07:  //  10 1110      E000-EFFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:11]}               ==  7'b1011110)     ?   SAM07:  //  10 1111 0XXX F000-F7FF
                        ({MMU_EN, MMU_TR, ADDRESS[15:10]}               ==  8'b10111110)    ?   SAM07:  //  10 1111 10XX F800-FBFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:9]}                ==  9'b101111110)   ?   SAM07:  //  10 1111 110X FC00-FDFF
           ({VEC_PAG_RAM, MMU_EN, MMU_TR, ADDRESS[15:8]}                ==11'b01011111110)  ?   SAM07:  // 010 1111 1110 FE00-FEFF RAM Vector page
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b11000)       ?   SAM10:  //  11 000X XXXX 0000-1FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b11001)       ?   SAM11:  //  11 001X XXXX 2000-3FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b11010)       ?   SAM12:  //  11 010X XXXX 4000-5FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b11011)       ?   SAM13:  //  11 011X XXXX 6000-7FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b11100)       ?   SAM14:  //  11 100X XXXX 8000-9FFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b11101)       ?   SAM15:  //  11 101X XXXX A000-BFFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:13]}               ==  5'b11110)       ?   SAM16:  //  11 110X XXXX C000-DFFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:12]}               ==  6'b111110)      ?   SAM17:  //  11 1110 XXXX E000-EFFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:11]}               ==  7'b1111110)     ?   SAM17:  //  11 1111 0XXX F000-F7FF
                        ({MMU_EN, MMU_TR, ADDRESS[15:10]}               ==  8'b11111110)    ?   SAM17:  //  11 1111 10XX F800-FBFF
                        ({MMU_EN, MMU_TR, ADDRESS[15:9]}                ==  9'b111111110)   ?   SAM17:  //  11 1111 110X FC00-FDFF
           ({VEC_PAG_RAM, MMU_EN, MMU_TR, ADDRESS[15:8]}                ==11'b01111111110)  ?   SAM17:  // 011 1111 1110 FE00-FEFF RAM Vector page
                                                                                               {9'h007, ADDRESS[15:13]};

assign RAM_CS = (ADDRESS[15:0]== 16'hFFE8)         					?   1'b1:       // GART 1
                (ADDRESS[15:0]== 16'hFFE9)         					?   1'b1:       // GART 2
				({ADDRESS[15:8]}== 8'hFF)           				?   1'b0:       // Hardware (FF00-FFFF) always Excluded
                ({VEC_PAG_RAM, ADDRESS[15:8]} ==  9'b111111110)     ?   1'b1:  		// If VEC_PAG_RAM then include FEXX Secondary Vectors
                 ROM_SEL                            				?   1'b0:       // Internal ROMs
                 CART_SEL                            				?   1'b0:       // External Cart
																		1'b1;



/*****************************************************************************
* ROM signals
******************************************************************************/
// ROM_SEL is 1 when the system is accessing the internal "ROM"
// CART_SEL is 1 when the system is accessing any cartridge "ROM" meaning the
// 4 slots of the MPI, this is:
//		Slot 1 	Not Used 
//		Slot 2	Disk Controller ROM
//		Slot 3	Cart slot
//		Slot 4	Disk Controller ROM

assign  ROM_SEL =    (ADDRESS[15:4]                                     == 12'b111111111111)   	?   1'b1:   // Enable for Vectors
                     (ADDRESS[15:9]                                     ==  7'b1111111)      	?   1'b0:   // Disabled for FE00 - FFFF
//					 (CART_SEL											==	1'b1)				?	1'b0:
                    ({ROM[1], RAM, BLOCK_ADDRESS[11:1]}    				== 13'b0000000011110)  	?   1'b1:   // Enabled Read, 16K Int, Page 7, x1    $78000-$7BFFF
//                    ({ROM[1], RAM, BLOCK_ADDRESS[11:2], ADDRESS[14]}  == 13'b0000000011110)  	?   1'b1:   // Enabled Read, 16K Int, Page 7, x1    $78000-$7BFFF
                    ({ROM,    RAM, BLOCK_ADDRESS[11:2]}                 == 13'b1000000001111)  	?   1'b1:   // Enabled 32K int, Page 7, x           $78000-$7FFFF
                                                                                                    1'b0;

assign  CART_SEL =  (ADDRESS[15:8]                                      ==  8'b11111111)        ?   1'b0:   // Disabled for FF00 - FFFF
//                    ({ROM[1], RAM, BLOCK_ADDRESS[11:2], ADDRESS[14]} 	== 13'b0000000011111)  	?   1'b1:   // Enabled Read, 16K Cart, Page 7, x1 $7C000-$7FEFF
                    ({ROM[1], RAM, BLOCK_ADDRESS[11:1]}    				== 13'b0000000011111)  	?   1'b1:   // Enabled Read, 16K Cart, Page 7, x1 $7C000-$7FEFF
                    ({ROM,    RAM, BLOCK_ADDRESS[11:2]}                 == 13'b1100000001111)  	?   1'b1:   // Enabled 32K Cart, Page 7, x1       $78000-$7FEFF
																									1'b0;

//ROM
//00		16 Internal + 16 External
//01		16 Internal + 16 External
//10		32 Internal
//11		32 External


assign  FLASH_ADDRESS = 	ENA_DSK             			?   {9'b000000100, ADDRESS[12:0]}:  //8K Disk BASIC 8K Slot 4
							ENA_DISK2           			?   {9'b000000100, ADDRESS[12:0]}:  //[maps to same disk rom]
							({ENA_PAK, ROM[1]} == 2'b10)	?	{5'b00000,ROM_BANK,	ADDRESS[13:0]}:	//16K External R CART ROM
							({ENA_PAK, ROM} == 3'b111)		?	{4'b0000,ROM_BANK,	~ADDRESS[14], ADDRESS[13:0]}:	//32K External R CART ROM
																{7'b0000000,ADDRESS[14:0]};							//32K Internal COCO3 ROM


//ROM
//00		16 Internal + 16 External
//01		16 Internal + 16 External
//10		32 Internal
//11		32 External

assign FLASH_CE_S = ROM_SEL     ?   1'b1:
                    ENA_DISK2   ?   1'b1:
                    ENA_PAK     ?   1'b1:
                    ENA_DSK     ?   1'b1:
                                    1'b0;

wire	[7:0]	COCO3_ROM_DATA;
wire	[7:0]	COCO3_DISK_ROM_DATA;

localparam 	[1:0]	BOOT0 = 2'd0;
localparam 	[1:0]	BOOT1 = 2'd1;
localparam 	[1:0]	BOOT2 = 2'd2;

localparam	[5:0]	BOOT  = 6'd0;


wire			COCO3_ROM_WRITE = (ioctl_index[7:0] == {BOOT0, BOOT})  & ioctl_wr;
wire			COCO3_DISKROM_WRITE = (ioctl_index[7:0] == {BOOT1, BOOT}) & ioctl_wr;
wire			COCO3_CART_WRITE = (ioctl_index[5:0] == 6'd1) & ioctl_wr & !cart_lock;


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


assign FLASH_DATA =	ENA_PAK	?									CART_DATA:
					(FLASH_ADDRESS[15] == 1'b0)				?	COCO3_ROM_DATA:
					(FLASH_ADDRESS[15:13] == 3'b100)		?	COCO3_DISK_ROM_DATA:
																8'b00000000;


COCO_ROM_CART CC3_ROM_CART(
.ADDR(FLASH_ADDRESS[16:0]),
.DATA(CART_DATA),
.CLK(~clk_sys),
.WR_ADDR(ioctl_addr[16:0]),
.WR_DATA(ioctl_data[7:0]),
.WRITE(COCO3_CART_WRITE)
);

wire	SDC_EN_CS;

assign	ENA_DISK2 =	({CART_SEL, MPI_CTS} == 3'b101)									?	1'b1:		// Alternative Disk controller ROM up to 32K
																						1'b0;

assign	ENA_PAK =	({CART_SEL, MPI_CTS} == 3'b110)									?	1'b1:		// ROM SLOT 3
																						1'b0;

assign	ENA_DSK =	({CART_SEL, MPI_CTS} == 3'b111)									?	1'b1:		// Disk C000-DFFF Slot 4
																						1'b0;
`ifdef CoCo3_sdc_fix_os9_driver
assign	HDD_EN = 	({ext_response, MPI_SCS, ADDRESS[15:5]} == 15'b01111111111010)	?	1'b1:		// FF40-FF5F with MPI switch = 4
																						1'b0;

assign	SDC_EN_CS = (({MPI_SCS, ADDRESS[15:5]} == 13'b0111111111010) | 
					((ADDRESS[15:5] == 11'b11111111010) & ext_response))			?	1'b1:		// FF40-FF5F with MPI switch = 2
																						1'b0;
`else
assign	HDD_EN = 	({MPI_SCS, ADDRESS[15:5]} == 13'b1111111111010)					?	1'b1:		// FF40-FF5F with MPI switch = 4
																						1'b0;
assign	SDC_EN_CS = ({MPI_SCS, ADDRESS[15:5]} == 13'b0111111111010)					?	1'b1:		// FF40-FF5F with MPI switch = 2
																						1'b0;
`endif

assign	RS232_EN = ({MPI_SCS, ADDRESS[15:2]} == 16'b0011111111011010)				?	1'b1:		//FF68-FF6B - Now in slot 1
																						1'b0;

assign	SLOT3_HW = ({SWITCH[2:1], ADDRESS[15:5]} == 13'b1011111111010)				?	1'b1:		// FF40-FF5F  Ensure this only appears in slot 3 PHYSICALLY
																						1'b0;

assign	VDAC_EN = ({RW_N,ADDRESS[15:0]} == 17'H0FF7E)								?	1'b1:		// FF7E
																						1'b0;

/*
$FF40 - This is the bank latch. The same latch that is used by the Super Program Paks to bank 16K of the Pak ROM
at a time. This latch is set to $00 on reset or power up (same as the super program paks).
*/

always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		ROM_BANK <= 3'b000;
	end
	else
	begin
		if({PH_2, SLOT3_HW, RW_N} == 3'b110)
			case (ADDRESS[4:0])
			5'h00:
			begin
				ROM_BANK <= DATA_OUT[2:0];
			end
			endcase
	end
end


wire [3:0]	Config_FLAG = `Config_Debug_FLAG;
wire [7:0]	Build_Info;
reg	 [3:0]	Build_Info_Count;
reg			Build_Info_Read, Build_Info_Read_Delay;

reg	[3:0]	i_count;

always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		i_count <= 4'b0000;
		i_val <= 8'h00;
	end
	else
	begin
		if ( !(i_count == 4'b1000))
			i_count <= i_count + 1'b1;
		case(i_count)
		4'b0001:
		begin
			`ifdef Feat_1
				i_val <= i_val + FEATURE_1;
			`endif
		end
		4'b0010:
		begin
			`ifdef Feat_2
				i_val <= i_val + FEATURE_2;
			`endif
		end
		4'b0011:
		begin
			`ifdef Feat_3
				i_val <= i_val + FEATURE_3;
			`endif
		end
		4'b0100:
		begin
			`ifdef Feat_4
				i_val <= i_val + FEATURE_4;
			`endif
		end
		4'b0101:
		begin
			`ifdef Feat_5
				i_val <= i_val + FEATURE_5;
			`endif
		end
		4'b0110:
		begin
			`ifdef Feat_6
				i_val <= i_val + FEATURE_6;
			`endif
		end
		4'b0111:
		begin
			`ifdef Feat_7
				i_val <= i_val + FEATURE_7;
			`endif
		end
		default:;
		endcase
	end
end

always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		Build_Info_Count <= 4'b0000;
		Build_Info <= 8'h00;
		Build_Info_Read <= 1'b0;
		Build_Info_Read_Delay <= 1'b0;
	end
	else
	begin
        Build_Info_Read <= 1'b0;
		Build_Info_Read_Delay <= Build_Info_Read;
		if (Build_Info_Read_Delay)
			Build_Info_Count <= Build_Info_Count + 1'b1;

		case (Build_Info_Count)
		4'd0:
			Build_Info <= Config_Data[71:64];		// Year MSB
		4'd1:
			Build_Info <= Config_Data[63:56];		// Year LSB
		4'd2:
			Build_Info <= Config_Data[55:48];		// Month MSB
		4'd3:
			Build_Info <= Config_Data[47:40];		// Month LSB
		4'd4:
			Build_Info <= Config_Data[39:32];		// Day MSB
		4'd5:
			Build_Info <= Config_Data[31:24];		// Day LSB
		4'd6:
			Build_Info <= Config_Data[23:16];		// Daily Build ID
		4'd7:
			Build_Info <= Config_Data[15:8];		// Daily Build ID
		4'd8:
			Build_Info <= Config_Data[7:0];			// Daily Build ID
		4'd9:
			`ifdef Config_Debug
				Build_Info <= {4'b1111, Config_FLAG};
			`else
				Build_Info <= {4'b0000, Config_FLAG};
			`endif
		4'd10:
			Build_Info <= i_val;
		4'd11:
			Build_Info <= {Config_FLAG, sdram_sz[15], 1'b0, sdram_sz[1:0]};
		4'd12:
			Build_Info <= Version_Hi;
		4'd13:
			Build_Info <= (Version_Lo + BOARD_TYPE);

        default:
			Build_Info <= 8'h00;
        endcase

        if(PH_2)
        begin
            case ({RW_N,ADDRESS})
            17'h1FFEF:
            begin
                Build_Info_Read <= 1'b1;
            end
            default:;
            endcase
        end
	end
end


assign	DATA_IN =
														(sdram_BE_0)	?	hold_data_L[7:0]:
														(sdram_BE_1)	?	hold_data_L[15:8]:
														FLASH_CE_S		?	FLASH_DATA:
														SDC_EN_CS		?	DATA_SDC:	// needs priority due to nitros9 llcocosdc ddriver bug
														HDD_EN			?	DATA_HDD:
														RS232_EN		?	DATA_RS232:
														SLOT3_HW		?	{5'b00000, ROM_BANK}:
// FF00, FF04, FF08, FF0C, FF10, FF14, FF18, FF1C
({ADDRESS[15:5], ADDRESS[1:0]} == 13'b11111111000_00)	?	DATA_REG1:
// FF01, FF05, FF09, FF0D, FF11, FF15, FF19, FF1D
({ADDRESS[15:5], ADDRESS[1:0]} == 13'b11111111000_01)	?	{!HSYNC1_IRQ_BUF[1], 3'b011, SEL[0], DDR1, HSYNC1_POL, HSYNC1_IRQ_INT}:
// FF02, FF06, FF0A, FF0E, FF12, FF16, FF1A, FF1E
({ADDRESS[15:5], ADDRESS[1:0]} == 13'b11111111000_10)	?	DATA_REG2:
// FF03, FF07, FF0B, FF0F, FF13, FF17, FF1B, FF1F
({ADDRESS[15:5], ADDRESS[1:0]} == 13'b11111111000_11)	?	{!VSYNC1_IRQ_BUF[1], 3'b011, SEL[1], DDR2, VSYNC1_POL, VSYNC1_IRQ_INT}:
// FF20, FF24, FF28, FF2C
({ADDRESS[15:4], ADDRESS[1:0]} == 14'b111111110010_00)	?	DATA_REG3:
// FF21, FF25, FF29, FF2D
({ADDRESS[15:4], ADDRESS[1:0]} == 14'b111111110010_01)	?	{4'b0011, CAS_MTR, DDR3, 2'b00}:	// CD_POL, CD_INT}:
// FF22, FF26, FF2A, FF2E
({ADDRESS[15:4], ADDRESS[1:0]} == 14'b111111110010_10)	?	DATA_REG4:
// FF23, FF27, FF2B, FF2F
({ADDRESS[15:4], ADDRESS[1:0]} == 14'b111111110010_11)	?	{!CART1_FIRQ_BUF[1], 3'b011, SOUND_EN, DDR4, CART1_POL, CART1_FIRQ_INT}:

									(ADDRESS == 16'hFF70)		?	{1'b0, GART_WRITE[22:16]}:		// 2MB
									(ADDRESS == 16'hFF71)		?	{       GART_WRITE[15:8]}:
									(ADDRESS == 16'hFF72)		?	{       GART_WRITE[7:0]}:
									(ADDRESS == 16'hFF74)		?	{1'b0, GART_READ[22:16]}:
									(ADDRESS == 16'hFF75)		?	{       GART_READ[15:8]}:
									(ADDRESS == 16'hFF76)		?	{       GART_READ[7:0]}:

									(ADDRESS == 16'hFF7F)		?	{2'b11, MPI_CTS, 2'b00, MPI_SCS}:

									(ADDRESS == 16'hFF8E)		?	GPIO_DIR:
									(ADDRESS == 16'hFF8F)		?	GPIO:

									(ADDRESS == 16'hFF90)		?	{COCO1, MMU_EN, GIME_IRQ, GIME_FIRQ, VEC_PAG_RAM, ST_SCS, ROM}:
									(ADDRESS == 16'hFF91)		?	{2'b00, TIMER_INS, 4'b0000, MMU_TR}:
									(ADDRESS == 16'hFF92)		?	{2'b00, !TIMER3_IRQ_N,  !HSYNC3_IRQ_N,  !VSYNC3_IRQ_N,  1'b0, !KEY3_IRQ_N,  !CART3_IRQ_N}:
									(ADDRESS == 16'hFF93)		?	{2'b00, !TIMER3_FIRQ_N, !HSYNC3_FIRQ_N, !VSYNC3_FIRQ_N, 1'b0, !KEY3_FIRQ_N, !CART3_FIRQ_N}:
									(ADDRESS == 16'hFF94)		?	{4'h0,TMR_MSB}:
									(ADDRESS == 16'hFF95)		?	TMR_LSB:
									(ADDRESS == 16'hFF98)		?	{GRMODE, HRES[3], 3'b000, LPR}:
									(ADDRESS == 16'hFF99)		?	{HLPR, LPF, HRES[2:0], CRES}:
									(ADDRESS == 16'hFF9A)		?	{2'b00, PALETTE[16][5:0]}:
									(ADDRESS == 16'hFF9B)		?	{SAM_EXT[2], SCRN_START_HSB[4],SAM_EXT[1:0],SCRN_START_HSB[3:0]}:	// 4 extra bits for 8MB. Real hardware can't read back!!
									(ADDRESS == 16'hFF9C)		?	{4'h0,VERT_FIN_SCRL}:
									(ADDRESS == 16'hFF9D)		?	SCRN_START_MSB:
									(ADDRESS == 16'hFF9E)		?	SCRN_START_LSB:
									(ADDRESS == 16'hFF9F)		?	{HVEN,HOR_OFFSET}:
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
									(ADDRESS == 16'hFFC0)		?	{3'b000, CENT}:
									(ADDRESS == 16'hFFC1)		?	{1'b0, YEAR}:
									(ADDRESS == 16'hFFC2)		?	{4'h0, MNTH}:
									(ADDRESS == 16'hFFC3)		?	{3'b000, DMTH}:
									(ADDRESS == 16'hFFC4)		?	{5'b00000, DWK}:
									(ADDRESS == 16'hFFC5)		?	{3'b000, HOUR}:
									(ADDRESS == 16'hFFC6)		?	{2'b00, MIN}:
									(ADDRESS == 16'hFFC7)		?	{2'b00, SEC}:

									(ADDRESS == 16'hFFD9)       ?   {5'h00, RATE_PGM}:

									(ADDRESS == 16'hFFEF)		?	Build_Info:
																	8'hAA;

assign	DATA_REG1	= !DDR1	?	DD_REG1:
											KEYBOARD_IN;

assign	DATA_REG2	= !DDR2	?	DD_REG2:
											KEY_COLUMN;

assign	DATA_REG3	= !DDR3	?	DD_REG3:
											{DTOA_CODE, 1'b1, casdout};

// A 0 in the DDR makes that pin an input
assign	BIT3 			= !DD_REG4[3]	?	1'b0:
											CSS;
assign	DATA_REG4		= !DDR4	?			DD_REG4:
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

wire	[24:0]	AMW_Adrs;
wire	[7:0]	AMW_Data;
wire			AMW_EN;
wire			AMW_Ready;
wire			AMW_End;

assign AMW_ACK = AMW_End;

AMW coco_AMW (
	.CLK(clk_sys),
	.RESET_N(RESET_N),
	.Trigger(AMW_Trigger),
	.Restart(1'b0),
	.Cycle_Run(AMW_WR),
	.AMW_Adrs(AMW_Adrs),
	.AMW_Data(AMW_Data),
	.AMW_EN(AMW_EN),
	.AMW_Ready(AMW_Ready),
	.AMW_End(AMW_End)
);


reg				end_hold;
reg		[15:0]	hold_data, hold_data_L;
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

localparam Sz_512K = 			3'b000;
localparam Sz_1M = 				3'b001;
localparam Sz_2M = 				3'b010;

assign sdram_cpu_addr = 	(Mem_Size == Sz_512K)	?	{6'h00, sdram_cpu_addr_i[18:0]}:
							(Mem_Size == Sz_1M)		?	{5'b00000, sdram_cpu_addr_i[19:0]}:
							(Mem_Size == Sz_2M)		?	{4'h0, sdram_cpu_addr_i[20:0]}:
														sdram_cpu_addr_i[24:0];				// 32MB space but we only have MMU addressing for 16MB

assign sdram_cpu_addr_i = 	(AMW_WR)		?	AMW_Adrs:
							(GART_RD)		?	{2'b00, GART_READ}:
							(GART_WR)		?	{2'b00, GART_WRITE}:
												{BLOCK_ADDRESS[11:0], ADDRESS[12:1], ADDRESS[0]};

assign sdram_cpu_din = 		(AMW_WR)		?	AMW_Data:
												DATA_OUT;

reg		[24:0]	sdram_cpu_addr_i;
reg		[24:0]	sdram_cpu_addr_L;
reg				last_write;
reg				sdram_BE_0, sdram_BE_1;
reg				GART_RD, GART_WR;
reg				AMW_WR;

reg		[2:0]	RATE_PGM;

assign	assigned_turbo_speed = (!(turbo_speed == 3'b000))	?	turbo_speed:
																RATE_PGM;

wire	cache_hit  /* synthesis preserve */;
assign	cache_hit = (sdram_cpu_addr[24:1] == sdram_cpu_addr_L[24:1]);


//	Master timing loop

// This sig is only used for the cycle accurate 09
reg cpu_cycle_ena;



always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		CLK <= 6'h00;
		SWITCH_L <= 3'b000;
`ifndef CoCo3_CYC_ACC_6809
		PH_2_RAW <= 1'b0;
		cpu_ena <= 1'b0;
`endif
		hold <= 1'b0;
		end_hold <= 1'b0;
		RAM0_BE0_L <= 1'b0;
		RAM0_BE1_L <= 1'b0;
		clear_data_ready <= 1'b1;
		sdram_cpu_req <= 1'b0;
		sdram_cpu_rnw <= 1'b1;
		sdram_cpu_addr_L <= 24'h000000;
		last_write <= 1'b1;
		sdram_BE_0 <= 1'b0;
		sdram_BE_1 <= 1'b0;
		GART_WR <= 1'b0;
		GART_RD <= 1'b0;
		AMW_WR <= 1'b0;
		cpu_cycle_ena <= 1'b0;
	end
	else
	begin
		clear_data_ready <= 1'b0;
		sdram_BE_0 <= 1'b0;
		sdram_BE_1 <= 1'b0;
		cpu_cycle_ena <= 1'b0;  // This is only a single clock per cpu cycle

//		If we are in hold were done @ data_ready.
		if (hold)
		begin
			if (data_ready)
			begin
//				Hold states are done - kill hold and set end hold to drive data
				hold <= 1'b0;
				end_hold <= 1'b1;
				cpu_cycle_ena <= 1'b1; // Cycle at the end of a memory transaction
				clear_data_ready <= 1'b1;
				hold_data_L <= hold_data;
				sdram_BE_0 <= RAM0_BE0_L;
				sdram_BE_1 <= RAM0_BE1_L;
			end
		end

		if (end_hold)
		begin
//			kill end hold and cpu_ena for the read memory hold 
			end_hold <= 1'b0;
`ifndef CoCo3_CYC_ACC_6809
			cpu_ena <= 1'b0;
`endif
		end

		if (sdram_cpu_ack)
		begin
			sdram_cpu_req <= 1'b0;
			GART_WR <= 1'b0; // GART address has already been used in the sdram controller so - de-select it
			GART_RD <= 1'b0;
			AMW_WR <= 1'b0;
		end
			
		case (CLK)
		6'h00:
		begin
			SWITCH_L <= {assigned_turbo_speed, (RATE | F_Turbo)};				// Normal speed
			CLK <= 6'h01;
`ifndef CoCo3_CYC_ACC_6809
			PH_2_RAW <= 1'b1;
`endif
			if (~(hold | end_hold))	// Make sure we are not in a cycle before starting one....
									// If we are still in one - we skip this cpu_enable cycle
			begin
`ifndef CoCo3_CYC_ACC_6809
				cpu_ena <= 1'b1;
`endif
				cpu_cycle_ena <= 1'b1;  // Default cycle

				if (AMW_EN)			// Automated Memory Write ?
				begin
					AMW_WR <= 1'b1;
`ifndef CoCo3_CYC_ACC_6809
					cpu_ena <= 1'b0; // Kill cpu enable
`endif
					cpu_cycle_ena <= 1'b0;  // Kill (defer) cycle based on memory transaction


//					Start AMW cycle
					RAM0_BE0_L <=  !AMW_Adrs[0];
					RAM0_BE1_L <=  AMW_Adrs[0];
					last_write <= 1'b1; // Kill cache hit
					hold <= 1'b1;
					sdram_cpu_req <= 1'b1;
					sdram_cpu_rnw <= 1'b0;
				end
				else if (VMA & RAM_CS) // FFE8 / FFE9 is now in RAM_CS
				begin
//					sdram memory cycle
					`ifdef CoCo3_disable_GART_in_GIMEX
					if (0);
					`else
					if ((ADDRESS[15:0] == 16'hFFE8) | (ADDRESS[15:0] == 16'hFFE9)) // GART
					begin
						if (~RW_N)
						begin // Gart Write
							RAM0_BE0_L <=  !GART_WRITE[0];
							RAM0_BE1_L <=  GART_WRITE[0];
							GART_WR <= 1'b1;
						end
						else
						begin // Gart Read
							RAM0_BE0_L <=  !GART_READ[0];
							RAM0_BE1_L <=  GART_READ[0];
							GART_RD <= 1'b1;
						end
						hold <= 1'b1;
						cpu_cycle_ena <= 1'b0;  // Kill (defer) cycle based on memory transaction
						sdram_cpu_req <= 1'b1;
						sdram_cpu_rnw <= RW_N;
						last_write <= 1'b1; // Kill cache hit on any access after GART
					end
					`endif
					else  // Normal CPU cycle
					begin
//						get which byte
						RAM0_BE0_L <=  !ADDRESS[0];
						RAM0_BE1_L <=  ADDRESS[0];

						if (RW_N & cache_hit & ~last_write)		// Read cache hit on stored on 16 hold_data value?
						begin
							end_hold <= 1'b1;					// If so then end the cpu_ena cycle with the updated byte enable
							sdram_BE_0 <= !ADDRESS[0];
							sdram_BE_1 <= ADDRESS[0];
																// Allow cpu_cycke_ena previously set based upon cache tansaction
						end
						else
						begin
							sdram_cpu_addr_L <= sdram_cpu_addr;	// Else set hold and start a sdram cycle
							hold <= 1'b1;
							cpu_cycle_ena <= 1'b0;  // Kill (defer) cycle based on memory transaction
							sdram_cpu_req <= 1'b1;
							sdram_cpu_rnw <= RW_N;
							last_write <= ~RW_N;
						end
					end
				end
			end
		end
		6'h01:
		begin
`ifndef CoCo3_CYC_ACC_6809
			PH_2_RAW <= 1'b0;
`endif
//			if we are not in a memory read [hold] then terminate cpu_ena - just like PH_2
`ifndef CoCo3_CYC_ACC_6809
			if (!hold)
				cpu_ena <= 1'b0;
`endif
			CLK <= 6'h02;
		end
		6'h05:								//	64/6 = 9.55
		begin
			if(SWITCH_L == 4'b1101)			//Rate = 9.55
				CLK <= 6'h00;
			else
				CLK <= 6'h06;
		end
		6'h07:								//	64/8 = 7.16
		begin
			if(SWITCH_L == 4'b1011)			//Rate = 7.16
				CLK <= 6'h00;
			else
				CLK <= 6'h08;
		end
		6'h0F:								//	64/16 = 3.58
		begin
			if(SWITCH_L == 4'b1001)			//Rate = 3.58
				CLK <= 6'h00;
			else
				CLK <= 6'h10;
		end
		6'h13:								//	64/19 = 2.86
		begin
			if(SWITCH_L == 4'b0111)			//Rate = 2.86
				CLK <= 6'h00;
			else
				CLK <= 6'h14;
		end
		6'h1F:								//	64/32 = 1.7857
		begin
			if(SWITCH_L == 4'b0101)			//Rate = 1.78?
				CLK <= 6'h00;
			else
				CLK <= 6'h20;
		end
		6'h3F:								// Just in case
		begin
			CLK <= 6'h00;
		end
		default:
		begin
			CLK <= CLK + 1'b1;
		end
		endcase
	end
end


//
//	This is the reset in which includes the MiSTer button, system reset, cold boot reset [frm EE_cold_bt].
//	Here we add the keyboard reset and turn it positive.
//
assign RESET_P =	!BUTTON_N[3]					// Button
					| RESET; 						// CTRL-ALT-DEL or CTRL-ALT-INS from Keyboard


always @ (posedge clk_sys)
begin
	if (RESET)
		MUGS <= RESET_INS;	   	//This is holding a <ctrl><alt><ins> across a reset to activate the Easter Egg
end

always @ (posedge clk_sys or posedge RESET_P)
begin
	reg	[24:0]	RESET_SM;

	if(RESET_P)
	begin
		RESET_SM <= 25'd0;
		CPU_RESET <= 1'b1;
		RESET_N <= 1'b0;
	end
	else
	begin
		case (RESET_SM)
		25'h0800000:									// time = 143 mS
														// Take away RESET_N
														// Leave CPU_RESET Asserted
		begin
			RESET_N <= 1'b1;
			CPU_RESET <= 1'b1;
			RESET_SM <= RESET_SM + 1'b1;
		end
		25'h1000000:									// time = 286 mS
														// Take away RESET_N & CPU_RESET
														// Stop RESET_SM count
		begin
			RESET_N <= 1'b1;
			CPU_RESET <= 1'b0;
		end
		default:
			RESET_SM <= RESET_SM + 1'b1;
		endcase
	end
end

////////////////////////////////////////////////////////////////////
//
//		CPU Selection
//
////////////////////////////////////////////////////////////////////

`ifdef CoCo3_CYC_ACC_6809

//	Create VMA out of AVMA
wire AVMA;

always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		VMA <= 1'b0;
	end
	else
	begin
		if (cpu_cycle_ena)
		begin
			VMA <= AVMA;
		end
	end
end

// Cycle Accurate CPU section copyrighted by Greg Miller

mc6809x GLBCPU09(
	.D(DATA_IN),
	.DOut(DATA_OUT),
	.ADDR(ADDRESS),
	.RnW(RW_N),
	.MASTER(clk_sys),
	.E(cpu_cycle_ena),
	.Q(cpu_cycle_ena),
	.nIRQ(CPU_IRQ_N),
	.nFIRQ(CPU_FIRQ_N),
	.nNMI(!NMI_09),
	.AVMA(AVMA),
	.nHALT(~HALT),
	.nRESET(~CPU_RESET),
	.nDMABREQ(1'b1)
);

assign PH_2 = cpu_cycle_ena;

`else

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

assign PH_2 = PH_2_RAW;

`endif

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
	.HRES(HRES),
	.CT_320_160(1'b1)
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
wire	FF40_ENA, sdc_FF40_ENA;
wire	wd1793_data_read, sdc_wd1793_data_read;
wire	wd1793_read, sdc_wd1793_read;
wire	wd1793_write, sdc_wd1793_write;
wire	[7:0]	DATA_SDC;

wire	HALT_sdc, HALT_fdc;
wire 	NMI_09_sdc, NMI_09_fdc;

wire	SDC_REG_W_ENA, SDC_REG_READ;
wire	ext_response;

assign	FF40_ENA =				({cpu_cycle_ena, RW_N, HDD_EN, ADDRESS[3:0]} == 7'B1010000)		?	1'b1:
																									1'b0;

assign	wd1793_data_read =		(RW_N && HDD_EN && ADDRESS[3]);

assign	wd1793_read =			(RW_N && HDD_EN && ADDRESS[3]);
assign	wd1793_write =			(cpu_cycle_ena && ~RW_N && HDD_EN && ADDRESS[3]);

assign	sdc_FF40_ENA =			({cpu_cycle_ena, RW_N, SDC_EN_CS, ADDRESS[3:0]} == 7'B1010000)	?	1'b1:
																									1'b0;


assign	sdc_wd1793_data_read =	(RW_N && SDC_EN_CS && ADDRESS[3]);

assign	sdc_wd1793_read =		(RW_N && SDC_EN_CS && ADDRESS[3]);
assign	sdc_wd1793_write =		(~RW_N && SDC_EN_CS && ADDRESS[3]);

assign	SDC_REG_W_ENA =			({RW_N, SDC_EN_CS} == 2'B01)									?	1'b1:	// This is for the FF40/5F SDC detect
																									1'b0;
assign	SDC_REG_READ =			SDC_EN_CS & RW_N;															// This is for the FF40/5F SDC detect

assign	HALT = 					HALT_fdc | HALT_sdc;
assign	NMI_09 =				NMI_09_fdc | NMI_09_sdc;

// Slot 4 fdc

fdc coco_fdc(
	.CLK(clk_sys),     					// clock
	.RESET_N(RESET_N),		  			// async reset
	.ADDRESS(ADDRESS[3:0]),	       		// i/o port addr for wd1793 & FF48+
	.CLK_EN(PH_2),
	.DATA_IN(DATA_OUT),        			// data in
	.DATA_HDD(DATA_HDD),      			// data out
	.HALT(HALT_fdc),       				// DMA request
	.NMI_09(NMI_09_fdc),

//	FDC host r/w handling
	.FF40_CLK(clk_sys),
	.FF40_ENA(FF40_ENA),

	.HDD_EN(HDD_EN),
	.WD1793_RD(wd1793_data_read),
	
	.WD1793_WR_CTRL(wd1793_write),
	.WD1793_RD_CTRL(wd1793_read),

// 	SD block level interface
	.img_mounted(img_mounted[5:2]), 	// signaling that new image has been mounted
	.img_readonly(img_readonly), 		// mounted as read only. valid only for active bit in img_mounted
	.img_size(img_size),    			// size of image in bytes. 

	.sd_lba(sd_lba[2:5]),
	.sd_blk_cnt(sd_blk_cnt[2:5]), 		// number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!
	.sd_rd(sd_rd[5:2]),
	.sd_wr(sd_wr[5:2]),
	.sd_ack(sd_ack[5:2]),

// 	SD byte level access. Signals for 2-PORT altsyncram.
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din[2:5]),
	.sd_buff_wr(sd_buff_wr)
);

// Slot 2 sdc

sdc_top coco_sdc_top(
	.CLK(clk_sys),     					// clock
	.RESET_N(RESET_N),	   				// async reset
	.ADDRESS(ADDRESS[3:0]),	       		// i/o port addr for wd1793 & FF48+
`ifdef CoCo3_CYC_ACC_6809
	.CLK_EN(cpu_cycle_ena),
`else
	.CLK_EN(PH_2),
`endif
	.DATA_IN(DATA_OUT),        			// data in
	.DATA_HDD(DATA_SDC),	 			// data out
	.HALT(HALT_sdc),       				// DMA request
	.NMI_09(NMI_09_sdc),

//	FDC host r/w handling
	.FF40_CLK(clk_sys),
	.FF40_ENA(sdc_FF40_ENA),

	.SDC_EN_CS(SDC_EN_CS),
	.WD1793_RD(sdc_wd1793_data_read),
	
	.WD1793_WR_CTRL(sdc_wd1793_write),
	.WD1793_RD_CTRL(sdc_wd1793_read),

//	SDC I/O
	.SDC_REG_W_ENA(SDC_REG_W_ENA),
	.SDC_REG_READ(SDC_REG_READ),

	.ext_response(ext_response),

// 	SD block level interface
	.img_mounted(img_mounted[1:0]), 	// signaling that new image has been mounted
	.img_readonly(img_readonly), 		// mounted as read only. valid only for active bit in img_mounted
	.img_size(img_size),    		// size of image in bytes. 

	.sd_lba(sd_lba[0:1]),
	.sd_blk_cnt(sd_blk_cnt[0:1]), 		// number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!
	.sd_rd(sd_rd[1:0]),
	.sd_wr(sd_wr[1:0]),
	.sd_ack(sd_ack[1:0]),

// 	SD byte level access. Signals for 2-PORT altsyncram.
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din[0:1]),
	.sd_buff_wr(sd_buff_wr)
);


reg cart_firq_enable;

reg	firq_trig;
reg	cart_lock;

always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		firq_trig <= 1'b0;
		cart_firq_enable <= 1'b1;
		cart_lock <= 1'b0;
	end
	else
	begin
		if ((ioctl_index[5:0] == 6'd1) & ioctl_download)
			firq_trig <= 1'b1;

		if (firq_trig)
			if (!ioctl_download)
			begin
				cart_firq_enable <= 1'b0;
				cart_lock <= 1'b1;
			end
	end
end


//***********************************************************************
// Interrupt Sources
//***********************************************************************
// Org FPGA code
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
				CART_INT_IN_N <= (SER_IRQ);
			2'b01:
				CART_INT_IN_N <= (SER_IRQ);
			2'b10:
				CART_INT_IN_N <= (!CART_INT_IN_N | cart_firq_enable);
			2'b11:
				CART_INT_IN_N <= (SER_IRQ);
			endcase
	end
end

assign CART_INT_N = CART_INT_IN_N;
`ifdef CoCo3_Horz_INT_FIX
	wire	HBORDER_INT;
	assign 	HSYNC_INT_N = !HBORDER_INT;
`else
	assign 	HSYNC_INT_N = H_SYNC_N;
`endif

`ifdef CoCo3_Vert_INT_FIX
	wire	VBORDER_INT;
	assign 	VSYNC_INT_N = VBORDER_INT;
`else
	assign 	VSYNC_INT_N = V_SYNC_N;
`endif

assign KEY_INT_N = (KEYBOARD_IN == 8'hFF);

//***********************************************************************
// Interrupt Latch RESETs
// This code delays the asynchronus clears by 3 clocks to prevent race 
// condition of reading and clearing at the same time.
//***********************************************************************
reg	[2:0]	RST_FF00_N_SFT, RST_FF02_N_SFT, RST_FF22_N_SFT, RST_FF92_N_SFT, RST_FF93_N_SFT;

assign RST_FF00_N = RST_FF00_N_SFT[2];
assign RST_FF02_N = RST_FF02_N_SFT[2];
assign RST_FF22_N = RST_FF22_N_SFT[2];
assign RST_FF92_N = RST_FF92_N_SFT[2];
assign RST_FF93_N = RST_FF93_N_SFT[2];

wire	[7:0]	FF93_Value;
assign	FF93_Value = {2'b00, !TIMER3_FIRQ_N, !HSYNC3_FIRQ_N, !VSYNC3_FIRQ_N, 1'b0, !KEY3_FIRQ_N, !CART3_FIRQ_N};


always @(negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		RST_FF00_N_SFT <= 3'b111;
		RST_FF02_N_SFT <= 3'b111;
		RST_FF22_N_SFT <= 3'b111;
		RST_FF92_N_SFT <= 3'b111;
		RST_FF93_N_SFT <= 3'b111;
	end
	else
	begin
		RST_FF00_N_SFT[0] <= 1'b1;
		RST_FF02_N_SFT[0] <= 1'b1;
		RST_FF22_N_SFT[0] <= 1'b1;
		RST_FF92_N_SFT[0] <= 1'b1;
		RST_FF93_N_SFT[0] <= 1'b1;

		RST_FF00_N_SFT[2:1] <= RST_FF00_N_SFT[1:0];
		RST_FF02_N_SFT[2:1] <= RST_FF02_N_SFT[1:0];
		RST_FF22_N_SFT[2:1] <= RST_FF22_N_SFT[1:0];
		RST_FF92_N_SFT[2:1] <= RST_FF92_N_SFT[1:0];
		RST_FF93_N_SFT[2:1] <= RST_FF93_N_SFT[1:0];

		if (PH_2)
		begin

			case({RW_N,ADDRESS})
			17'h1FF00,
			17'h1FF04,
			17'h1FF08,
			17'h1FF0C,
			17'h1FF10,
			17'h1FF14,
			17'h1FF18,
			17'h1FF1C:
				RST_FF00_N_SFT[0] <= 1'b0;

			17'h1FF02,
			17'h1FF06,
			17'h1FF0A,
			17'h1FF0E,
			17'h1FF12,
			17'h1FF16,
			17'h1FF1A,
			17'h1FF1E:
				RST_FF02_N_SFT[0] <= 1'b0;

			17'h1FF22,
			17'h1FF26,
			17'h1FF2A,
			17'h1FF2E,
			17'h0FF22,
			17'h0FF26,
			17'h0FF2A,
			17'h0FF2E:
				RST_FF22_N_SFT[0] <= 1'b0;

			17'h1FF92:
				RST_FF92_N_SFT[0] <= 1'b0;

			17'h1FF93:
				begin
					if (!(FF93_Value == 8'h00))
						RST_FF93_N_SFT[0] <= 1'b0;
				end
				
			default:;

			endcase
		end
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


//assign CPU_IRQ_N =  ( GIME_IRQ  | (HSYNC1_IRQ_N		&	VSYNC1_IRQ_N))
//						& (!GIME_IRQ  | (TIMER3_IRQ_N		&	HSYNC3_IRQ_N	&	VSYNC3_IRQ_N	&	KEY3_IRQ_N	&	CART3_IRQ_N));
//assign CPU_FIRQ_N = ( GIME_FIRQ | (CART1_FIRQ_N))
//						& (!GIME_FIRQ | (TIMER3_FIRQ_N	&	HSYNC3_FIRQ_N	&	VSYNC3_FIRQ_N	&	KEY3_FIRQ_N	&	CART3_FIRQ_N));

assign CPU_IRQ_N =  HSYNC1_IRQ_N & VSYNC1_IRQ_N
                & (!GIME_IRQ  | (TIMER3_IRQ_N  & HSYNC3_IRQ_N  & VSYNC3_IRQ_N  & CART3_IRQ_N));

assign CPU_FIRQ_N = CART1_FIRQ_N
                & (!GIME_FIRQ | (TIMER3_FIRQ_N & HSYNC3_FIRQ_N & VSYNC3_FIRQ_N & CART3_FIRQ_N));



// Timer
assign TMR_CLK = !TIMER_INS	?		HSYNC_INT_N:
									CLK3_57MHZ;					// 14.32Mhz... /4

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

assign TMR_RESET_N = TMR_ENABLE[1];             // Already == 0 when RESET_N is 0

always @ (negedge clk_sys or negedge RESET_N)
begin
    if(!RESET_N)
    begin
        TMR_ENABLE <= 2'b00;
    end
    else
    begin
        if(PH_2)
        begin
            case ({RW_N,ADDRESS})
            17'h0FF94:
            begin
                TMR_ENABLE <= 2'b01;
            end
            default:
            begin
                TMR_ENABLE <= {TMR_ENABLE[0],TMR_ENABLE[0]};	//	This is a write
            end
            endcase
        end
    end
end

reg		TIMER_LOAD;

always @(negedge clk_sys or negedge TMR_RESET_N)
begin
    if(!TMR_RESET_N)
    begin
        TIMER_INT_N <= 1'b1;
        BLINK <= 1'b0;
        TIMER <= 13'h1FFF;
		TIMER_LOAD <= 1'b1;
    end
    else
    begin
// This turns out being TIMER + 1 as in Sockmaster's GIME Reference 1987 GIME
// 0 to TMR_MSB,TMR_LSB (0 to TMR_MSB,TMR_LSB is really counts + 1)

		if (TIMER_LOAD)
		begin
			TIMER <= {1'b0,TMR_MSB,TMR_LSB};
			TIMER_LOAD <= 1'b0;
		end

        if (TMR_CLK == 1'b0 && TMR_CLK_D == 1'b1)
        begin
            case (TIMER)
            13'h0000:
            begin
                if(({TMR_MSB,TMR_LSB} == 12'h000))
                begin
                    TIMER_INT_N <= 1'b0;
                    TIMER <= 13'h0000;
                    BLINK <= 1'b0;
                end
                else
                begin
                    TIMER_INT_N <= 1'b1;
                    TIMER <= {1'b0,TMR_MSB,TMR_LSB};
                    BLINK <= !BLINK;
                end
            end
            13'h0001:
            begin
                TIMER_INT_N <= 1'b0;
                TIMER <= 13'h0000;
            end
            default:
            begin
                if(TIMER[12])
                    TIMER <= {1'b0,TMR_MSB,TMR_LSB};
                else
                    TIMER <= TIMER - 1'b1;
            end
            endcase
        end
    end
end



//reg		TIMER_LOAD;

//always @(negedge clk_sys or negedge TMR_RESET_N)
//begin
//	if(!TMR_RESET_N)
//	begin
//		TIMER_INT_N <= 1'b1;
//		BLINK <= 1'b0;
//		TIMER <= 13'h1FFF;
//		TIMER_LOAD <= 1'b1;
//	end
//	else
//	begin

// This turns out being TIMER + 2 as in Sockmaster's GIME Reference 1986 GIME
// 0 to TIMER-1 (0 to TIMER is really TIMER counts + 1)
// This timer goes from 0 directly to 1FFF where it loads the timer count and decrements from there
// So 1FFF to TIMER to 0 is TIMER + 2 counts

//		if (TIMER_LOAD)
//		begin
//			TIMER <= {1'b0,TMR_MSB,TMR_LSB};
//			TIMER_LOAD <= 1'b0;
//		end

//		if (!TIMER_INT_N)
//		begin
//			TIMER_INT_N <= 1'b1;
//          TIMER <= {1'b0,TMR_MSB,TMR_LSB};
//        end
		
//		if (TMR_CLK == 1'b0 && TMR_CLK_D == 1'b1)
//		begin

//			case (TIMER)
//            13'h0000:
//            begin
//                if(({TMR_MSB,TMR_LSB} == 12'h000))
//                begin
//                    TIMER_INT_N <= 1'b0;
//                    TIMER <= 13'h0000;
//                    BLINK <= 1'b0;
//                end
//                else
//                begin
//					TIMER_INT_N <= 1'b0;
//                    BLINK <= !BLINK;
//				end
//            end
//            default:
//            begin
//                TIMER <= TIMER - 1'b1;
//            end
//			endcase
//		end
//	end
//end

reg	sync_rst1;

// Most of the latches for settings
always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		sync_rst1 <= 1'b1;		// Eliminating Latches

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
// FF7A
		ORCH_LEFT <= 8'b10000000;
// FF7B
		ORCH_RIGHT <= 8'b10000000;
// FF7F
//		MPI_SCS <= SWITCH[2:1];
//		MPI_CTS <= SWITCH[2:1];
// FF8E-FF8F
		GPIO_DIR <= 8'h00;
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
		SAM_EXT <= 4'b0000;				// extra 4 bits for 32MB SAMs
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
		SAM00 <= 12'h000;	
// FFA1
		SAM01 <= 12'h000;
// FFA2
		SAM02 <= 12'h000;
// FFA3
		SAM03 <= 12'h000;
// FFA4
		SAM04 <= 12'h000;
// FFA5
		SAM05 <= 12'h000;
// FFA6
		SAM06 <= 12'h000;
// FFA7
		SAM07 <= 12'h000;
// FFA8
		SAM10 <= 12'h000;
// FFA9
		SAM11 <= 12'h000;
// FFAA
		SAM12 <= 12'h000;
// FFAB
		SAM13 <= 12'h000;
// FFAC
		SAM14 <= 12'h000;
// FFAD
		SAM15 <= 12'h000;
// FFAE
		SAM16 <= 12'h000;
// FFAF
		SAM17 <= 12'h000;
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
		RATE_PGM <= 3'b010;
		RATE <= 1'b0;
// FFDE / FFDF
		RAM <= 1'b0;
// FFE1-FFE3
		GART_WRITE <= 23'h000000;
// FFE4-FFE6
		GART_READ <= 23'h000000;
// FFE7
		GART_INC <= 2'b00;
	end
	else
	begin
		if (sync_rst1)
		begin
			sync_rst1 <= 1'b0;		// Eliminating Latches
			MPI_SCS <= SWITCH[2:1];
			MPI_CTS <= SWITCH[2:1];
		end

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

				16'hFF00,
				16'hFF04,
				16'hFF08,
				16'hFF0C,
				16'hFF10,
				16'hFF14,
				16'hFF18,
				16'hFF1C:
				begin
					if(!DDR1)
						DD_REG1 <= DATA_OUT;
				end

				16'hFF01,
				16'hFF05,
				16'hFF09,
				16'hFF0D,
				16'hFF11,
				16'hFF15,
				16'hFF19,
				16'hFF1D:
				begin
					HSYNC1_IRQ_INT <= DATA_OUT[0];
					HSYNC1_POL <= DATA_OUT[1];
					DDR1 <= DATA_OUT[2];
					SEL[0] <= DATA_OUT[3];
				end

				16'hFF02,
				16'hFF06,
				16'hFF0A,
				16'hFF0E,
				16'hFF12,
				16'hFF16,
				16'hFF1A,
				16'hFF1E:
				begin
					if(!DDR2)
						DD_REG2 <= DATA_OUT;
					else
						KEY_COLUMN <= DATA_OUT;
				end

				16'hFF03,
				16'hFF07,
				16'hFF0B,
				16'hFF0F,
				16'hFF13,
				16'hFF17,
				16'hFF1B,
				16'hFF1F:
				begin
					VSYNC1_IRQ_INT <= DATA_OUT[0];
					VSYNC1_POL <= DATA_OUT[1];
					DDR2 <= DATA_OUT[2];
					SEL[1] <= DATA_OUT[3];
				end


				16'hFF20,
				16'hFF24,
				16'hFF28,
				16'hFF2C:
				begin
					if(!DDR3)
						DD_REG3 <= DATA_OUT;
					else
					begin
						DTOA_CODE <= DATA_OUT[7:2];
					end
				end

				16'hFF21,
				16'hFF25,
				16'hFF29,
				16'hFF2D:
				begin
//					CD_INT <= DATA_OUT[0];
//					CD_POL <= DATA_OUT[1];
					DDR3 <= DATA_OUT[2];
					CAS_MTR <= DATA_OUT[3];
				end

				16'hFF22,
				16'hFF26,
				16'hFF2A,
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

				16'hFF23,
				16'hFF27,
				16'hFF2B,
				16'hFF2F:
				begin
					CART1_FIRQ_INT <= DATA_OUT[0];
					CART1_POL <= DATA_OUT[1];
					DDR4 <= DATA_OUT[2];
					SOUND_EN <= DATA_OUT[3];
				end


				16'hFF7A:
				begin
					ORCH_LEFT <= DATA_OUT;
				end
				16'hFF7B:
				begin
					ORCH_RIGHT <= DATA_OUT;
				end
				16'hFF7F:
				begin
					MPI_SCS <= DATA_OUT[1:0];
					MPI_CTS <= DATA_OUT[5:4];
				end
				16'hFF8E:
					GPIO_DIR <= DATA_OUT;
				16'hFF8F:
				begin
					GPIO_OUT <= DATA_OUT;
				end
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
				end
				16'hFF95:
				begin
					TMR_LSB <= DATA_OUT;
				end
				16'hFF98:
				begin
					GRMODE <= DATA_OUT[7];
					if (SWITCH[5])				// On in Extended CoCo3 mode
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
					SAM_EXT <= {1'b0,DATA_OUT[7],DATA_OUT[5:4]};
//					SCRN_START_HSB <= DATA_OUT[3:0];	// extra 4 bits for 8MB screen start [V5]
//					SAM_EXT <= DATA_OUT[5:4];	// [V5]
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
					RATE_PGM <= 3'b010;
				end
				16'hFFD9:
				begin
					RATE <= 1'b1;
					RATE_PGM <= 3'b010;	// Normal Turbo
					if (RATE && (DATA_OUT==8'hA5))
						RATE_PGM <= 3'b011; // 2.68 Mhz
					else if (RATE && (DATA_OUT==8'h45))
						RATE_PGM <= 3'b101; // 7.16 Mhz
					else if (RATE && (DATA_OUT==8'h05))
						RATE_PGM <= 3'b110; // 9.54 Mhz
					else
						RATE_PGM <= 3'b010;	// Normal Turbo
						
				end
				16'hFFDE:
				begin
					RAM <= 1'b0;
				end
				16'hFFDF:
				begin
					RAM <= 1'b1;
				end
                16'hFFE1:
                begin
                    GART_WRITE[22:16]<= DATA_OUT[6:0];
                end
                16'hFFE2:
                begin
                    GART_WRITE[15:8]<= DATA_OUT;
                end
                16'hFFE3:
                begin
                    GART_WRITE[7:0]<= DATA_OUT;
                end
                16'hFFE4:
                begin
                    GART_READ[22:16] <= DATA_OUT[6:0];
                end
                16'hFFE5:
                begin
                    GART_READ[15:8] <= DATA_OUT;
                end
                16'hFFE6:
                begin
                    GART_READ[7:0] <= DATA_OUT;
                end
                16'hFFE7:
                begin
                    GART_INC <= DATA_OUT[1:0];
                end
                16'hFFE8:
                begin
                    if(GART_INC[0])
                        GART_WRITE <= GART_WRITE + 1'b1;
                end
                16'hFFE9:
                begin
                    if(GART_INC[0])
                        GART_WRITE <= GART_WRITE + 1'b1;
                end

				endcase
			end
			else
			begin
                if(ADDRESS == 16'hFFE8)
                begin
                    if(GART_INC[1])
                        GART_READ <= GART_READ + 1'b1;
                end
                else
                begin
                    if(ADDRESS == 16'hFFE9)
                    begin
                        if(GART_INC[1])
                            GART_READ <= GART_READ + 1'b1;
                    end
                end
			end
		end
	end
end

// The code for the internal and Orchestra sound

// Internal Sound generation
//assign SOUND		=	{SBS, 7'b0000000} + {SOUND_DTOA, SOUND_DTOA[5:4]};
assign SOUND		=	{SBS, SOUND_DTOA, SOUND_DTOA[5]};

assign SOUND_LEFT = {ORCH_LEFT,  ORCH_LEFT}	+ {SOUND, SOUND};
assign SOUND_RIGHT = {ORCH_RIGHT, ORCH_RIGHT}	+ {SOUND, SOUND};


// the DAC isn't really a DAC but represents the DAC chip on the schematic. 
// All the signals have been digitized before it gets here.

reg [15:0] dac_joya1;
reg [15:0] dac_joya2;

always @ (negedge clk_sys) 
begin

	if (joy_use_dpad)
	begin
		dac_joya1[15:8] <= 8'd128;
		dac_joya1[7:0]  <= 8'd128;
		
		dac_joya2[15:8] <= 8'd128;
		dac_joya2[7:0]  <= 8'd128;
		
		if (joy1[0])	// right
			dac_joya1[15:8] <= 8'd255;

		if (joy1[1])	// left
			dac_joya1[15:8] <= 8'd0;
		
		if (joy1[2])	// down
			dac_joya1[7:0] <= 8'd255;

		if (joy1[3])	// up
			dac_joya1[7:0] <= 8'd0;
		
		if (joy2[0])	// right
			dac_joya2[15:8] <= 8'd255;

		if (joy2[1])	// left
			dac_joya2[15:8] <= 8'd0;
		
		if (joy2[2])	// down
			dac_joya2[7:0] <= 8'd255;

		if (joy2[3])	// upimg_mounted
			dac_joya2[7:0] <= 8'd0;
	end
	else
	begin
		if (SWAP_M_J)
			dac_joya2 <= mouse_xy_pos;
		else
			dac_joya2 <= joya2;
		dac_joya1 <= joya1;
	end
end


always @(negedge clk_sys)
begin
	case (SEL)
	2'b00:
		if (dac_joya2[15:10] >= DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
	2'b01:
  		if (dac_joya2[7:2] >= DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
	2'b10:
		if (dac_joya1[15:10] >= DTOA_CODE)
			JSTICK<=1;
		else
			JSTICK<=0;
	2'b11:
  		if (dac_joya1[7:2] >= DTOA_CODE)
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
assign KEYBOARD_IN[0] =  			!((!KEY_COLUMN[0] & KEY[0])				// @
								 | (!KEY_COLUMN[1] & KEY[1])				// A
								 | (!KEY_COLUMN[2] & KEY[2])				// B
								 | (!KEY_COLUMN[3] & KEY[3])				// C
								 | (!KEY_COLUMN[4] & KEY[4])				// D
								 | (!KEY_COLUMN[5] & KEY[5])				// E
								 | (!KEY_COLUMN[6] & KEY[6])				// F
								 | (!KEY_COLUMN[7] & KEY[7])				// G
								 | !(P_SWITCH[3] & (ps2_button | !SWAP_M_J)));			// Right Joystick Switch 1

assign KEYBOARD_IN[1] =	 			!((!KEY_COLUMN[0] & KEY[8])				// H
								 | (!KEY_COLUMN[1] & KEY[9])				// I
								 | (!KEY_COLUMN[2] & KEY[10])				// J
								 | (!KEY_COLUMN[3] & KEY[11])				// K
								 | (!KEY_COLUMN[4] & KEY[12])				// L
								 | (!KEY_COLUMN[5] & KEY[13])				// M
								 | (!KEY_COLUMN[6] & KEY[14])				// N
								 | (!KEY_COLUMN[7] & KEY[15])				// O
								 | !P_SWITCH[0]);							// Left Joystick Switch 1

assign KEYBOARD_IN[2] =	 		!((!KEY_COLUMN[0] & KEY[16])				// P
								 | (!KEY_COLUMN[1] & KEY[17])				// Q
								 | (!KEY_COLUMN[2] & KEY[18])				// R
								 | (!KEY_COLUMN[3] & KEY[19])				// S
								 | (!KEY_COLUMN[4] & KEY[20])				// T
								 | (!KEY_COLUMN[5] & KEY[21])				// U
								 | (!KEY_COLUMN[6] & KEY[22])				// V
								 | (!KEY_COLUMN[7] & KEY[23])				// W
								 | !P_SWITCH[2]);							// Left Joystick Switch 2

assign KEYBOARD_IN[3] =	 		!((!KEY_COLUMN[0] & KEY[24])				// X
								 | (!KEY_COLUMN[1] & KEY[25])				// Y
								 | (!KEY_COLUMN[2] & KEY[26])				// Z
								 | (!KEY_COLUMN[3] & KEY[27])				// up
								 | (!KEY_COLUMN[4] & KEY[28])				// down
								 | (!KEY_COLUMN[5] & KEY[29])				// Backspace & left
								 | (!KEY_COLUMN[6] & KEY[30])				// right
								 | (!KEY_COLUMN[7] & KEY[31])				// space
								 | !P_SWITCH[1]);							// Right Joystick Switch 2

assign KEYBOARD_IN[4] =	 		!((!KEY_COLUMN[0] & KEY[32])				// 0
								 | (!KEY_COLUMN[1] & KEY[33])				// 1
								 | (!KEY_COLUMN[2] & KEY[34])				// 2
								 | (!KEY_COLUMN[3] & KEY[35])				// 3
								 | (!KEY_COLUMN[4] & KEY[36])				// 4
								 | (!KEY_COLUMN[5] & KEY[37])				// 5
								 | (!KEY_COLUMN[6] & KEY[38])				// 6
								 | (!KEY_COLUMN[7] & KEY[39]));				// 7

assign KEYBOARD_IN[5] =	 		!((!KEY_COLUMN[0] & KEY[40])				// 8
								 | (!KEY_COLUMN[1] & KEY[41])				// 9
								 | (!KEY_COLUMN[2] & KEY[42])				// :
								 | (!KEY_COLUMN[3] & KEY[43])				// ;
								 | (!KEY_COLUMN[4] & KEY[44])				// ,
								 | (!KEY_COLUMN[5] & KEY[45])				// -
								 | (!KEY_COLUMN[6] & KEY[46])				// .
								 | (!KEY_COLUMN[7] & KEY[47]));				// /

assign KEYBOARD_IN[6] =	 		!((!KEY_COLUMN[0] & KEY[48])				// CR
								 | (!KEY_COLUMN[1] & KEY[49])				// TAB
								 | (!KEY_COLUMN[2] & KEY[50])				// ESC
								 | (!KEY_COLUMN[3] & KEY[51])				// ALT
								 | (!KEY_COLUMN[3] & (!BUTTON_N[0] | MUGS))	// ALT (Easter Egg)
								 | (!KEY_COLUMN[4] & KEY[52])				// CTRL
								 | (!KEY_COLUMN[4] & (!BUTTON_N[0] | MUGS))	// CTRL (Easter Egg)
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
		.PS2_CLK(ps2_clk),
		.PS2_DATA(ps2_data),
		.KEY(KEY_RCVD),
		.SHIFT(SHIFT),
		.SHIFT_OVERRIDE(SHIFT_OVERRIDE),
		.RESET(RESET),
		.RESET_INS(RESET_INS)
);

wire	[72:0]	KEY_RCVD;

Auto_Run CoCo3_Auto_Run(
		.RESET_N(RESET_N),
		.CLK(clk_sys),
		.CLK_1_78(clk_1_78),
		.MPI_SCS(SWITCH[2:1]),
		.MODE(AUTO_MODE),
		.AMW_ACK(AMW_ACK),
		.KEY_IN(KEY_RCVD),
		.KEY_OUT(KEY)
);

// Generate 1.78 Mhz [enable] GP clk
reg clk_1_78;
reg [4:0] clk_178_ctr;

always @ (negedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		clk_1_78 <= 1'b0;
		clk_178_ctr <= 5'b00000;
	end
	else
	begin
		clk_1_78 <= 1'b0;
		clk_178_ctr <= clk_178_ctr + 1'b1;
		if (clk_178_ctr == 5'd27)
		begin
			clk_1_78 <= 1'b1;
		end
	end
end

// PS2 Mouse [MiSTer]
// Borrowed from MAC PLUS

wire	ps2_x1, ps2_y1, ps2_x2, ps2_y2;
wire	ps2_button;

ps2_mouse coco_ps2_mouse(
		.clk(clk_sys),
		.ce(PH_2),
		.reset(~RESET_N),

		.ps2_mouse(ps2_mouse),
		
		.x1(ps2_x1),
		.y1(ps2_y1),
		.x2(ps2_x2),
		.y2(ps2_y2),
		.button(ps2_button)
);

//	This code creates a virtual joystick based on mouse movements.
//	The result is mouse_xy_pos
//	[note check of boundry before inc / dev]

reg		[7:0]	mouse_x_pos, mouse_y_pos;
wire	[15:0]	mouse_xy_pos = {mouse_x_pos, mouse_y_pos};
reg		[1:0]	old_x, old_y;
wire	[1:0]	x_mouse	= {ps2_x1, ps2_x2};
wire	[1:0]	y_mouse	= {ps2_y1, ps2_y2};

always @ (posedge clk_sys or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		mouse_x_pos <= 8'h80;
		mouse_y_pos <= 8'h80;
		old_x <= 2'b00;
		old_y <= 2'b00;
	end
	else
	begin
		if (PH_2)
		begin
			old_x <= x_mouse;
			old_y <= y_mouse;
			if ( !(old_x == x_mouse))				//if a x change
			begin
				if (^x_mouse)						// xor of x bits show + move ; else neg
				begin
					if (!(mouse_x_pos == 8'hff))
						mouse_x_pos <= mouse_x_pos + 1'b1;
				end
				else
				begin
					if (!(mouse_x_pos == 8'h00))
						mouse_x_pos <= mouse_x_pos - 1'b1;
				end
			end

			if ( !(old_y == y_mouse))				//if a y change
			begin
				if (^y_mouse)						// xor of x bits show + move ; else neg
				begin
					if (!(mouse_y_pos == 8'h00))
						mouse_y_pos <= mouse_y_pos - 1'b1;
				end
				else
				begin
					if (!(mouse_y_pos == 8'hff))
						mouse_y_pos <= mouse_y_pos + 1'b1;
				end
			end
		end
	end
end



/*****************************************************************************
* Video
******************************************************************************/

assign PIX_CLK = CLK_14;

wire PIX_CLK_D;


// Note HBALNK and VBLANK from the Mister_Video module are unused.
// This moves the HBLANK just off a H_SYNC color change + inversion.
// The VBOARDER is used as a VBLANK as is [inverted]
reg		[3:0]    MISTER_HBLANK_D;

assign 	HBLANK = MISTER_HBLANK_D[1];  // This is 2 clock delay on the ~HBORDER...
assign	VBLANK = ~VBORDER;

assign	RED[3:0] = RED[7:4];
assign	GREEN[3:0] = GREEN[7:4];
assign	BLUE[3:0] = BLUE[7:4];

// Video DAC
always @ (negedge clk_sys)
begin
	PIX_CLK_D <= PIX_CLK;
	if (PIX_CLK == 1'b1 & PIX_CLK_D == 1'b0)
	begin
		COLOR_BUF <= COLOR;						// Delay COLOR by 1 clock cycle to align with 256 Color SRAM
		H_SYNC <= !H_SYNC_N;					// Delay H_SYNC by 1 clock cycle
		V_SYNC <= !V_SYNC_N;					// Delay V_SYNC by 1 clock cycle
//		RED[3:0] <= 4'B0000;
//		GREEN[3:0] <= 4'B0000;
//		BLUE[3:0] <= 4'B0000;
//		VGA_SYNC_N <= 1'b1;
		
		MISTER_HBLANK_D[3] <= ~HBORDER;
        MISTER_HBLANK_D[2:0] <= MISTER_HBLANK_D[3:1];


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
		RED[4] = RED[6];
		GREEN[4] = GREEN[6];
		BLUE[5] = BLUE[7];
		BLUE[4] = BLUE[6];
	end
end


VDAC	VDAC_inst (
	.data ( {4'h0,PALETTE[0][11:0]} ),
	.rdaddress ( COLOR[7:0] ),
	.rdclock ( PIX_CLK ),
	.wraddress ( DATA_OUT ),
	.wrclock ( clk_sys ),
	.wren ( VDAC_EN & PH_2 ),
	.q ( VDAC_OUT )
	);

wire	[10:0]	font_adrs;
wire	[7:0]	font_data;

wire HBORDER;
wire VBORDER;
wire VBLANK_1;
wire HBLANK_1;
wire double, buff_bank;

`ifndef CoCo3_Select_GIMEX_RAST
// Video timing and modes
COCO3VIDEO MISTER_COCOVID(
// Clocks / RESET
	.MASTER_CLK(clk_sys),
	.PIX_CLK(PIX_CLK),			//14.32 MHz = 69.3 nS
	.RESET_N(RESET_N),

// Video Out
	.COLOR(COLOR),
	.HSYNC_N(H_SYNC_N),
	.VSYNC_N(V_SYNC_N),
	.HBLANKING(HBLANK_1),
	.VBLANKING(VBLANK_1),

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
	.HLPR(HLPR),
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

//	Interrupts
`ifdef CoCo3_Horz_INT_FIX
	.HBORDER_INT(HBORDER_INT),
`endif

`ifdef CoCo3_Vert_INT_FIX
	.VBORDER_INT(VBORDER_INT),
`endif

	.HBORDER(HBORDER),
	.VBORDER(VBORDER),
	
	.art(SWITCH[7:6])
);

`else

wire	[9:0]	BUFF_ADD_temp;
assign			BUFF_ADD = BUFF_ADD_temp[8:0];

COCO3VIDEO_GIMEX MISTER_COCOVID(
// Clocks / RESET
	.PIX_CLK(PIX_CLK),			//14.32 MHz = 69.3 nS
	.RESET_N(RESET_N),

	.COLOR(COLOR),
	.HSYNC_N(H_SYNC_N),
	.VSYNC_N(V_SYNC_N),

// RAM / Buffer
	.BUFF_ADD_F(BUFF_ADD_temp),
	.RAM_ADD(VIDEO_ADDRESS),
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
	.HLPR(HLPR),
	.LPR(LPR),
	.HRES(HRES),
	.CRES(CRES),
	.HVEN(HVEN),

// Starting location
	.SCRN_START_HSB(SCRN_START_HSB),		// 2 extra bits for 2MB screen start
	.SCRN_START_MSB(SCRN_START_MSB),
	.SCRN_START_LSB(SCRN_START_LSB),

	.SWITCH(SWITCH[5]),

	.BLINK(BLINK),

	.ARTI(SWITCH[7:6]),
	.PHASE(PHASE),
	.HBORDER(HBORDER),
	.VBORDER(VBORDER),

//	Interrupts
`ifdef CoCo3_Horz_INT_FIX
	.HBORDER_INT(HBORDER_INT),
`endif

`ifdef CoCo3_Vert_INT_FIX
	.VBORDER_INT(VBORDER_INT),
`endif


//	.DOUBLE(double),
//	.BUFF_BANK(buff_bank),
	.TURBO(1'b0),
	.SDRate(1'b0),

	.ROM_ADDRESS(font_adrs),
	.ROM_DATA1(font_data)
);
`endif

parameter SHDOW_FONT_LOCK_REG = 16'hfff0;
parameter SHDOW_FONT_DATA_REG = 16'hfff1;
parameter SHDOW_FONT_ADRS_REG = 16'hfff2;

parameter SHDOW_FONT_UNLOCK_UPPER_VAL = 8'hA5;
parameter SHDOW_FONT_UNLOCK_LOWER_VAL = 8'h5A;

parameter SHDOW_FONT_USE_ALT = 8'hC3;

reg		[7:0]	Font_Lock_Register;
reg		[7:0]	Font_Data_Register;
reg		[7:0]	Font_ADRS_Register;
reg				Font_Data_Write_Strobe;
reg				Font_Adrs_Write_Strobe;
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
		Font_Adrs_Write_Strobe <= 1'b0;
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
//				SHDOW_FONT_ADRS_REG = 16'hfff2;
				SHDOW_FONT_ADRS_REG:
				begin
					Font_ADRS_Register <= DATA_OUT[7:0];
					Font_Adrs_Write_Strobe <= 1'b1;
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
		if (Font_Adrs_Write_Strobe)
			Font_ROM_CPU_W <= {Font_ADRS_Register[6:0], 4'b0000};
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
	.WR_CLK(clk_sys),
	.WE(((ioctl_index[5:0] == 6'd3) & ioctl_wr) | Font_ROM_Mach_WE), // Can be just Font_ROM_Mach_WE if no MISTer
	.ADDR_W(Font_ROM_Adrs_Buf),
    .DATA_W(Font_ROM_Data_Buf),
	.RD_CLK(PIX_CLK),
	.ADDR_R({(COCO1 ^ Font_ROM_Upper_Select), font_adrs}),
    .DATA_R(font_data)
);


reg     [4:0]           CLK_6551;
// Targeting 1.8432 Mhz.
// 57.272727 Mhz / 31 = 1.8475 Mhz
reg						CLK_6551_EN;

always @(negedge clk_sys or negedge RESET_N)
begin
    if(!RESET_N)
	begin
        CLK_6551 <= 5'd0;
		CLK_6551_EN <= 1'b0;
	end
    else
	begin
		CLK_6551_EN <= 1'b0;
        case(CLK_6551)
        5'd30:
		begin
			CLK_6551_EN <= 1'b1;
            CLK_6551 <= 5'd0;
		end
        default:
            CLK_6551 <= CLK_6551 + 1'b1;
        endcase
	end
end


// RS232PAK UART
glb6551 RS232(
.RESET_N(RESET_N),
.CLK(clk_sys),
.RX_CLK(RX_CLK2), 				// This is a output [nc]
.RX_CLK_IN(CLK_6551_EN),		// These are now enables
.XTAL_CLK_IN(CLK_6551_EN),
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

Cassette_Write CoCo3_Cassette_Write(
		.RESET_N(RESET_N),
		.CLK(clk_sys),
		.CLK_1_78(clk_1_78),

		.CASS_REWIND_RECORD(SWITCH[3]),
		.MOTOR_ON(CAS_MTR),
		.DTOA_CODE(DTOA_CODE),
		
// 		SD block level interface
		.img_mounted(img_mounted[6]), 	// signaling that new image has been mounted
		.img_readonly(img_readonly),	// mounted as read only. valid only for active bit in img_mounted
		.img_size(img_size),    		// size of image in bytes. 

		.sd_lba(sd_lba[6]),
		.sd_blk_cnt(sd_blk_cnt[6]), 	// number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!
		.sd_rd(sd_rd[6]),
		.sd_wr(sd_wr[6]),
		.sd_ack(sd_ack[6]),

// 		SD byte level access. Signals for 2-PORT altsyncram.
		.sd_buff_addr(sd_buff_addr),
		.sd_buff_dout(sd_buff_dout),
		.sd_buff_din(sd_buff_din[6]),
		.sd_buff_wr(sd_buff_wr)
);


endmodule
