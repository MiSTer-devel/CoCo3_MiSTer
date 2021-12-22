//============================================================================
//  CoCo3 port to MiSTer
//  Copyright (c) 2019 Alan Steremberg - alanswx
//
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);


//`define SOUND_DBG
//assign CE_PIXEL=1;

//assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
//assign USER_OUT = '1;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign ADC_BUS  = 'Z;
//assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign BUTTONS = 0;


assign VGA_F1    = 0;
//assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

wire [1:0] ar = status[9:8];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;



`include "build_id.v"
localparam  CONF_STR = {
        "COCO3;UART19200:9600:4800:2400:1200:300;",
        "-;",
        "OCD,Multi-Pak Slot,Orch 90,ECB / Cart,Disk;",
        "-;",
        "H2S0,DSK,Load Disk Drive 0;",
        "H2S1,DSK,Load Disk Drive 1;",
        "H2S2,DSK,Load Disk Drive 2;",
        "H2S3,DSK,Load Disk Drive 3;",
        "H1F1,CCC,Load Cartridge;",
        "-;",

        "F2,CAS,Load Cassette;",
        "TF,Stop & Rewind;",
        "OH,Monitor Tape Sound,No,Yes;",
		  
        "-;",
        "P1,Video Settings;",
        "P1-;",
        "P1-, -= Video Settings =-;",
        "P1-;",
        "P1O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
        "P1O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;", 
		  "P1OL,Artifact Color,Off - SG4,On - SG6;",
		  "P1OI,Artifact Color Set,0,1;",
        "-;",
        "P2,Debug Menu;",
        "P2-;",
        "P2-, -= Debug Menu =-;",
        "P2-;",
        "P2F3,BIN,Load COCO Font;", 
		  "P2OG,Cart Interrupt Disabled,OFF,ON;",
        //P2O?,Force Disk 0 DS,Off,On;"
        //P2O?,Force Disk 1 DS,Off,On;"
        "-;",

		  
		  
		  "O6,Swap Joysticks,Off,On;",
		  "RA,Easter Egg;",
		  "-;",
		  "OJK,Turbo Speed:,1.78 Mhz,3.58 Mhz,7.16 Mhz, NA;",
		  
		  
		  
        "-;",
        "RM,Cold Boot;",
        "R0,Reset;",
        "J,Button1,Button2;",
        "jn,A,B;",
        "V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

//wire clk_sys,clk_ram, clk_vid,clk_sys_2;
wire clk_sys;

assign clk_sys=CLK_57;
//assign clk_sys=clk_vid; (SRH)

wire pll_locked, pll2_locked;
wire CLK_114, CLK_57, CLK_28, CLK_14;



pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(CLK_114),
	.outclk_1(CLK_57),
	.outclk_2(CLK_28),
	.outclk_3(CLK_14),
	.locked(pll2_locked)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_data;

wire [10:0] ps2_key;

wire [31:0] joy1, joy2;

wire [15:0] joya1, joya2;

wire [21:0] gamma_bus;

assign CLK_VIDEO = clk_sys;


// SD - 4 drives 512 size blocks [the wd1793 translates to a 256 byte sector size]	
hps_io #(.CONF_STR(CONF_STR),.PS2DIV(1000), .VDNUM(4), .BLKSZ(2)) hps_io
(
      .clk_sys(clk_sys),
//		.clk_sys(CLK_50M), (SRH)
      .HPS_BUS(HPS_BUS),


      .buttons(buttons),
      .status(status),
      .status_menumask({ (mpi != 2'b11), (mpi != 2'b10),direct_video}),
      .forced_scandoubler(forced_scandoubler),
      .gamma_bus(gamma_bus),
      .direct_video(direct_video),

      .ioctl_download(ioctl_download),
      .ioctl_wr(ioctl_wr),
      .ioctl_addr(ioctl_addr),
      .ioctl_dout(ioctl_data),
      .ioctl_index(ioctl_index),

      // 	SD block level interface

      .img_mounted(img_mounted), 		// signaling that new image has been mounted
      .img_readonly(img_readonly), 	// mounted as read only. valid only for active bit in img_mounted
      .img_size(img_size),			// size of image in bytes. 1MB MAX!

      .sd_lba(sd_lba),
      .sd_blk_cnt(sd_blk_cnt), 		// number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!

      .sd_rd(sd_rd),
      .sd_wr(sd_wr),
      .sd_ack(sd_ack),

      // 	SD byte level access. Signals for 2-PORT altsyncram.
      .sd_buff_addr(sd_buff_addr),
      .sd_buff_dout(sd_buff_dout),
      .sd_buff_din(sd_buff_din),
      .sd_buff_wr(sd_buff_wr),
	  
      .joystick_0(joy1),
      .joystick_1(joy2),

      .joystick_analog_0(joya1),
      .joystick_analog_1(joya2),
		  
      .ps2_key(ps2_key),


      .ps2_kbd_clk_out    ( ps2_kbd_clk    ),
      .ps2_kbd_data_out   ( ps2_kbd_data   )
);

// SD block level interface
wire	[3:0]  		img_mounted;
wire				   img_readonly;
wire	[19:0] 		img_size;

wire	[31:0] 		sd_lba[4];
wire	[5:0] 		sd_blk_cnt[4];

wire	[3:0]		   sd_rd;
wire	[3:0]		   sd_wr;
wire	[3:0]		   sd_ack;

// SD byte level access. Signals for 2-PORT altsyncram.
wire  	[8:0]    sd_buff_addr;
wire  	[7:0]    sd_buff_dout;
wire 	[7:0]       sd_buff_din[4];
wire        		sd_buff_wr;


wire [9:0] center_joystick_y1   =  8'd128 + joya1[15:8];
wire [9:0] center_joystick_x1   =  8'd128 + joya1[7:0];
wire [9:0] center_joystick_y2   =  8'd128 + joya2[15:8];
wire [9:0] center_joystick_x2   =  8'd128 + joya2[7:0];
wire vclk;

wire [31:0] coco_joy1 = status[6] ? joy2 : joy1;
wire [31:0] coco_joy2 = status[6] ? joy1 : joy2;

wire [15:0] coco_ajoy1 = status[6] ? {center_joystick_x2[7:0],center_joystick_y2[7:0]} : {center_joystick_x1[7:0],center_joystick_y1[7:0]};
wire [15:0] coco_ajoy2 = status[6] ? {center_joystick_x1[7:0],center_joystick_y1[7:0]} : {center_joystick_x2[7:0],center_joystick_y2[7:0]};



wire ps2_kbd_clk;
wire ps2_kbd_data;


wire hblank, vblank;
wire hs, vs;

wire pix_clk;


wire [2:0] scale = status[5:3];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
wire       scandoubler = (scale || forced_scandoubler);
assign VGA_SL = sl[1:0];

wire freeze_sync;


video_mixer #(.GAMMA(1)) video_mixer
(
   .*,

   .CLK_VIDEO(clk_sys),
   .ce_pix(pix_clk),

	.hq2x(scale==1),


   .R(r),
   .G(g),
   .B(b),

   // Positive pulses.
   .HSync(hs),
   .VSync(vs),
   .HBlank(hblank),
   .VBlank(vblank)
);
//
//

wire	Programmed_RESET_N;
wire	Programmed_EE;

EE_Cold_Bt COCO3_EE_Cold_Bt (
	.CLK(CLK_14),

	.Display_EE(easter_egg),				// from MISTer subsystem
	.Cold_Boot(coldboot | mpi_reset),		// from MISTer subsystem or mpi change

	.RESET_to_COCO_N(Programmed_RESET_N),	// RESET_N to the coco3 [logically AND'ed to top reset]
	.EE_to_COCO(Programmed_EE)				// Easter Egg to the coco3
);


wire [15:0] audio_left;
assign AUDIO_L = { audio_left[15:6], audio_left[5] ^ (status[17] ?  casdout : 1'b0),audio_left[4:0]};
//assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

wire [7:0] r;
wire [7:0] g;
wire [7:0] b;

wire easter_egg = ~status[10];
wire	[31:0]	probe;

assign USER_OUT[6:0] = probe[6:0];

coco3fpga coco3 (
  //	CLOCKS

  .CLK_114(CLK_114),
  .CLK_57(CLK_57),
  .CLK_28(CLK_28),
  .CLK_14(CLK_14),

  .CLK50MHZ(CLK_50M),

  // Reset
  .COCO_RESET_N((~reset & Programmed_RESET_N)),

  .RED(r),
  .GREEN(g),
  .BLUE(b),

  .EE_N(Programmed_EE),
  .PHASE(PHASE),

  .H_SYNC(hs),
  .V_SYNC(vs),
  .HBLANK(hblank),
  .VBLANK(vblank),
  .PIX_CLK(pix_clk),
  // PS/2
  .ps2_clk(ps2_kbd_clk),
  .ps2_data(ps2_kbd_data),


//  .joy1(coco_joy1),
//  .joy2(coco_joy2),

  .joya1(coco_ajoy1),
  .joya2(coco_ajoy2),

  // R1, L2, R2, L1
  .P_SWITCH(~{coco_joy2[4],coco_joy1[5],coco_joy2[5],coco_joy1[4]}),
  .SWITCH(switch),
  .SOUND_OUT(cocosound),
  .SOUND_LEFT(audio_left),
  .SOUND_RIGHT(AUDIO_R),
//.OPTTXD(USER_OUT[5]),
//.OPTRXD(USER_IN[6]),

  //	Removed offset addition
  .ioctl_addr(ioctl_addr),
  .ioctl_data(ioctl_data),
  .ioctl_download(ioctl_download),
  .ioctl_index(ioctl_index),
  .ioctl_wr(ioctl_wr),

// SD block level interface

  .img_mounted(img_mounted), 	// signaling that new image has been mounted
  .img_readonly(img_readonly), 	// mounted as read only. valid only for active bit in img_mounted
  .img_size(img_size),			// size of image in bytes. 1MB MAX!

  .sd_lba(sd_lba),
  .sd_blk_cnt(sd_blk_cnt), 		// number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!

  .sd_rd(sd_rd),
  .sd_wr(sd_wr),
  .sd_ack(sd_ack),

// 	SD byte level access. Signals for 2-PORT altsyncram.
  .sd_buff_addr(sd_buff_addr),
  .sd_buff_dout(sd_buff_dout),
  .sd_buff_din(sd_buff_din),
  .sd_buff_wr(sd_buff_wr),

  .PROBE(probe[31:0]),
  .clk_Q_out(clk_Q_out),
  .casdout( casdout),
  .cas_relay(cas_relay),

//	SDRAM

  .sdram_cpu_addr(sdram_cpu_addr),
//  .sdram_ldout(sdram_ldout),
  .sdram_dout(sdram_dout),
  .sdram_cpu_din(sdram_cpu_din),
  .sdram_cpu_req(sdram_cpu_req),
  .sdram_cpu_rnw(sdram_cpu_rnw),
  .sdram_cpu_ack(sdram_cpu_ack),
  .sdram_cpu_ready(sdram_cpu_ready),

  .sdram_vid_addr(sdram_vid_addr[24:0]),
  .sdram_vid_req(sdram_vid_req),
  .sdram_vid_ack(sdram_vid_ack),
  .sdram_vid_ready(sdram_vid_ready),
  
  .sdram_busy(sdram_busy),
  
  .turbo_speed(turbo_speed),

	.UART_TXD(UART_TXD),
	.UART_RXD(UART_RXD),
	.UART_RTS(UART_RTS),
	.UART_CTS(UART_CTS),
	.UART_DTR(UART_DTR),
	.UART_DSR(UART_DSR)
  

);

wire [5:0] cocosound;

wire [1:0] turbo_speed = status[20:19];

wire cpu_speed = status[11];
wire [1:0] mpi = (status[13:12]==2'b00)  ? 2'b00  : status[13:12]==2'b01 ? 2'b10 : status[13:12]==2'b10 ? 2'b11 : 2'b00;		
wire video=status[14];
wire cartint=status[16];
//wire cartint = 1'b0;
wire sg4v6 = status[21];

wire PHASE = status[18];

wire coldboot = status[22];

reg	[2:0] mpi_d	= 2'b00;
reg first_mpi_chg = 1'b0;
reg mpi_reset = 1'b0;

always @ (negedge CLK_14)
begin
	mpi_d <= mpi;
	mpi_reset <= 1'b0;
	
	if (~(mpi == mpi_d))
		if (~first_mpi_chg)
			first_mpi_chg <= 1'b1;
		else
			mpi_reset <= 1'b1;
	
end

//	Set bit 9 to swap serial ports...
wire [9:0] switch = { 4'b1000,sg4v6,cartint,video,mpi,cpu_speed} ;


wire reset = RESET | status[0] | buttons[1];
//wire reset = buttons[1];

wire clk_Q_out;

wire [24:0] sdram_cpu_addr;
//wire [31:0]	sdram_ldout;
wire [15:0]	sdram_dout;
wire [7:0] sdram_cpu_din;
wire sdram_cpu_req, sdram_cpu_rnw;
wire sdram_cpu_ack, sdram_vid_ack;
wire sdram_cpu_ready;

wire [24:0] sdram_vid_addr;
wire sdram_vid_req;
wire sdram_vid_ready;
wire sdram_busy;

sdram_32r8w coco3_sdram
(
	.*,
	.init(reset),
	.clk(CLK_114),
	.sdram_cpu_addr(sdram_cpu_addr[24:0]),
//	.sdram_ldout(sdram_ldout),
	.sdram_dout(sdram_dout),
	.sdram_cpu_din(sdram_cpu_din),
	.sdram_cpu_req(sdram_cpu_req),
	.sdram_cpu_rnw(sdram_cpu_rnw),
	.sdram_cpu_ack(sdram_cpu_ack),
	.sdram_cpu_ready(sdram_cpu_ready),
	
	.sdram_vid_addr(sdram_vid_addr[24:0]),
	.sdram_vid_req(sdram_vid_req),
	.sdram_vid_ack(sdram_vid_ack),
	.sdram_vid_ready(sdram_vid_ready),
	.sdram_busy(sdram_busy)
);

wire casdout;
wire cas_relay;
wire load_tape = ioctl_index == 2;

wire	[15:0]	ram_addr;
wire	[7:0]	ram_data_o;
wire	ram_rd;
wire	ram_wr;
wire	[15:0]	ram_ad_buf;

always @(posedge clk_sys)
begin
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
.DATA_I(ioctl_data),
.DATA_O(ram_data_o)
);


cassette cassette(
  .clk(clk_sys),
  .Q(clk_Q_out),

  .rewind(status[15]),
  .en(cas_relay),

  .sdram_addr(ram_addr),
  .sdram_data(ram_data_o),
  .sdram_rd(ram_rd), // Not connected for sram

  .data(casdout)
);
endmodule
