////////////////////////////////////////////////////////////////////////////////
// Project Name:	COCO3 Targeting MISTer 
// File Name:		sdc_top.sv
//
// CoCo SDC TOP Controller for MISTer
//
////////////////////////////////////////////////////////////////////////////////
//
//
// CoCo SDC TOP Controller (sdc_top.sv) by Stan Hodge (stan.pda@gmail.com)
// Copyright (c) 2022 by Stan Hodge (stan.pda@gmail.com)
//
// All rights reserved

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
//	This is a full FDC controller for 2 floppy drives.  It also has a 2 drive
//	cocosdc imbedded.  When booting with a superfloppy, the floppy portion
//	of this controller will be shutdown and the normal 4 drive fdc will take
//	over dfc on a different mpi slot.
//
//  Ver 2.00 Implemented with single 1793 ...
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



module sdc_top(
	input        		CLK,     		// clock
	input        		RESET_N,	   	// async reset
	input  		[3:0]	ADDRESS,       	// i/o port addr [extended for coco]
	input				CLK_EN,
	input  		[7:0]	DATA_IN,        // data in
	output 		[7:0] 	DATA_HDD,      	// data out
	output       		HALT,         	// DMA request
	output       		NMI_09,

//	FDC host r/w handling

	input				FF40_CLK,		// FDC Write support
	input				FF40_ENA,

	input				SDC_EN_CS,			// FDC Read Data support
	input				WD1793_RD,

	input				WD1793_WR_CTRL,	// 1793 RD & WR control signal generation
	input				WD1793_RD_CTRL,

//	SDC I/O
	input				SDC_REG_W_ENA,
	input				SDC_REG_READ,

	output				ext_response,
	
// 	SD block level interface

	input 		[1:0]	img_mounted, 	// signaling that new image has been mounted
	input				img_readonly, 	// mounted as read only. valid only for active bit in img_mounted
	input 		[63:0] 	img_size,    	// size of image in bytes.

	output		[31:0] 	sd_lba[2],
	output		[5:0]	sd_blk_cnt[2],	// number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!
	output reg	[1:0]	sd_rd,
	output reg  [1:0]	sd_wr,
	input       [1:0]	sd_ack,

// 	SD byte level access. Signals for 2-PORT altsyncram.
	input  		[8:0]	sd_buff_addr,
	input  		[7:0] 	sd_buff_dout,
	output 		[7:0] 	sd_buff_din[2],
	input        		sd_buff_wr
);

wire	[7:0]	DRIVE_SEL_EXT;
wire			MOTOR;
wire			WRT_PREC;
wire			DENSITY;
wire			HALT_EN;

// Diagnostics only
//assign probe = {2'd0, HALT_EN_RST, sd_buff_wr, WR[0], RD[0], HALT_EN, HALT};

// Generate a 8.333 Mhz enable for the fdc... and control writes
wire ena_8Mhz;
wire [5:0]	div_8mhz;

assign ena_8Mhz = (div_8mhz == 6'd5) ? 1'b1: 1'b0;

always@(negedge CLK or negedge RESET_N)
begin
	if (~RESET_N)	div_8mhz <= 6'd0;
	else
		begin
			if (ena_8Mhz)
				div_8mhz <= 6'd0;
			else
				div_8mhz <= div_8mhz + 6'd1;
		end
end

localparam SDC_MAGIC_CMD = 			8'h43;
wire	sdc_always;

wire	[7:0]	FF40_READ_VALUE = 	{HALT_EN, DRIVE_SEL_EXT[3], DENSITY, WRT_PREC, MOTOR,	DRIVE_SEL_EXT[2:0]};
wire	  		SDC_EN = 			((FF40_READ_VALUE == SDC_MAGIC_CMD) | sdc_always);
wire	[7:0]	SDC_READ_DATA;
wire			FF40_RD =			({SDC_EN_CS, ADDRESS[3:0]} == 5'b10000);

//FDC read data path.  =$ff40 or wd1793(s)

assign	DATA_HDD =
						(FF40_RD)												?	FF40_READ_VALUE:
						(SDC_EN | ext_response)									?	SDC_READ_DATA:
						(SDC_EN_CS & (ADDRESS[3:1] == 3'b001))					?	SDC_READ_DATA:	// FF42 & FF43
						(WD1793_RD)												?	DATA_1793: //(1793[s])
																					8'h00;

wire		[31:0] 	sdc_sd_lba[2];
wire		[31:0] 	fdc_sd_lba[2];
wire		[31:0] 	wd1793_sd_lba;
wire 		[1:0]	sdc_sd_rd;
wire				wd1793_sd_rd;
wire 		[1:0]	fdc_sd_rd;
wire 		[1:0]	sdc_sd_wr;
wire 		[1:0]	fdc_sd_wr;
wire				wd1793_sd_wr;
wire 		[7:0] 	sdc_sd_buff_din[2];
wire 		[7:0] 	fdc_sd_buff_din[2];
wire 		[7:0] 	wd1793_sd_buff_din;
wire				wd1793_sd_ack;
wire				sdc_HALT;

assign		sd_lba[0:1]			=	SDC_EN					?	sdc_sd_lba[0:1]:
																fdc_sd_lba[0:1];

assign		fdc_sd_lba[0]		=	wd1793_sd_lba;
assign		fdc_sd_lba[1]		=	wd1793_sd_lba;

assign		sd_rd[1:0]			=	SDC_EN					?	sdc_sd_rd[1:0]:
																fdc_sd_rd[1:0];

assign		fdc_sd_rd[0]		=	(drive_index == 3'd1)	?	wd1793_sd_rd:
																1'b0;
																
assign		fdc_sd_rd[1]		=	(drive_index == 3'd2)	?	wd1793_sd_rd:
																1'b0;
											
assign		sd_wr[1:0]			=	SDC_EN					?	sdc_sd_wr[1:0]:
																fdc_sd_wr[1:0];

assign		fdc_sd_wr[0]		=	(drive_index == 3'd1)	?	wd1793_sd_wr:
																1'b0;
																
assign		fdc_sd_wr[1]		=	(drive_index == 3'd2)	?	wd1793_sd_wr:
																1'b0;

assign		sd_buff_din[0:1]	=	SDC_EN					?	sdc_sd_buff_din[0:1]:
																fdc_sd_buff_din[0:1];

assign		fdc_sd_buff_din[0]	=	wd1793_sd_buff_din;
assign		fdc_sd_buff_din[1]	=	wd1793_sd_buff_din;


assign		wd1793_sd_ack		=	(drive_index == 3'd1)	?	sd_ack[0]:
									(drive_index == 3'd2)	?	sd_ack[1]:
																sd_ack[0];		// default is drive 1


sdc coco_sdc(
	.CLK(CLK),     					// clock
	.RESET_N(RESET_N),	   			// async reset
	.ADDRESS(ADDRESS),     			// i/o port addr [extended for coco]
	.SDC_DATA_IN(DATA_IN),  		// data in
	.SDC_READ_DATA(SDC_READ_DATA),  // data out

	.SDC_EN(SDC_EN),				// SDC is active  [input to sdc]
	.CLK_EN(CLK_EN),
	.SDC_WR(SDC_REG_W_ENA),
	.SDC_RD(SDC_REG_READ),

	.sdc_HALT(sdc_HALT),

	.ext_response(ext_response),
	.sdc_always(sdc_always),

// 	SD block level interface

	.sd_lba(sdc_sd_lba[0:1]),
	.sd_rd(sdc_sd_rd[1:0]),
	.sd_wr(sdc_sd_wr[1:0]),
	.sd_ack(sd_ack[1:0]),

//	Drive descripters

	.drive_wp(drive_wp),
	.drive_ready(drive_ready),
	.drive_size(drive_size[0:1]),

// 	SD byte level access. Signals for 2-PORT altsyncram.
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sdc_sd_buff_din[0:1]),
	.sd_buff_wr(sd_buff_wr)
);



// $ff40 control register [part 1]

wire	[3:0]	DRIVE_SEL_EXT_PRE = {DATA_IN[6]			// Side Select
									, DATA_IN[2:0]};	// ONLY 2 drives (DS)

reg		[2:0]	drive_index;

// SD blk system is a array of 4 systems - one for each drive.  
// 'drive_index' identifies which controller is addressd.
// drive 1-2 for the sdc is denoted as 1 , 2 [0 is no drive selected]

always @(negedge FF40_CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		DRIVE_SEL_EXT <= 8'h00;
		MOTOR <= 1'b0;
		WRT_PREC <= 1'b0;
		DENSITY <= 1'b0;
		drive_index <= 3'd0; 
	end
	else
	begin
		if (FF40_ENA)
		begin
			DRIVE_SEL_EXT <= {4'b0000, DRIVE_SEL_EXT_PRE};
			MOTOR <= DATA_IN[3];				// Turn on motor, not used here just checked, 0=MotorOff 1=MotorOn
			WRT_PREC <= DATA_IN[4];				// Write Precompensation, not used here
			DENSITY <= DATA_IN[5];				// Density, not used here just checked
			case(DRIVE_SEL_EXT_PRE)
			4'b0010:
				drive_index <= 3'd2;
			
			4'b0001:
				drive_index <= 3'd1;
			
			4'b1010:
				drive_index <= 3'd2;
			
			4'b1001:
				drive_index <= 3'd1;

			4'b1011:							//	This is what the Magic Number $43 does so we select a non-active drive
				drive_index <= 3'd0;
			4'b1000:							//	This is no drive with DS = illegal drive
				drive_index <= 3'd0;
			4'b0000:							//	This is no drive (maybe 0 in ff40) = illegal drive
				drive_index <= 3'd0;
			default:
				drive_index <= 3'd0;
			endcase
		end
	end
end

// $ff40 control register [part 2]
always @(negedge FF40_CLK or negedge HALT_EN_RST)
begin
	if(!HALT_EN_RST)
	begin
		HALT_EN <= 1'b0;
	end
	else
	begin
		if (FF40_ENA)
		begin
			HALT_EN <= DATA_IN[7];					// Normal Halt enable, 0=Disabled 1=Enabled
			if (sdc_always)
				HALT_EN <= 1'b0;
		end
	end
end


// Control signals for the wd1793

wire			selected_DRQ;
wire			selected_INTRQ;

wire			WR;
wire			RD;
wire			RD_E;
wire			HALT_EN_RST;
wire	[7:0]	DATA_1793;
reg				read;
reg				write;
reg 			read_d;
reg				write_d;
reg		[7:0]	DATA_IN_L;
reg				r_w_active;
reg				clk_8Mhz_enable_found;
reg				read1;
reg				write1;
reg		[1:0]	ADDRESS_L;

assign RD = (read || RD_E); 															// Even with no drive selected allow read to the controller

// The idea here is to "stretch" the CPU read and write signals to ensure we catch a 8 mhz enable.
// For writes we will buffer the data out to ensure it does not go away.
// For reads it is expected that data is available asynchronusly at the cpu rate and the only reason to catch a 
// 8Mhz edge is to update pointer and misc flags. 

// This is very nasty code and will likely only work with the present CPU timing.
// It is heavily dependant on address and write data being available just after
// the previous cycle.

wire	wd1793_r_w_sync_rst = RESET_N;

always @(negedge CLK or negedge wd1793_r_w_sync_rst)
begin
	if(!wd1793_r_w_sync_rst)
	begin
		read_d <= 1'b0;
		write_d <= 1'b0;
		r_w_active <= 1'b0;
		clk_8Mhz_enable_found <= 1'b0;
		WR <= 1'b0;
		RD_E <= 1'b0;
		read1 <= 1'b0;
		write1 <= 1'b0;
		read <= 1'b0;
		write <= 1'b0;
	end
	else
	begin

//		synchronizers
		read1 <= WD1793_RD_CTRL  & ~SDC_EN;
		read <= read1;
		
		write1 <= WD1793_WR_CTRL & ~SDC_EN;
		write <= write1;

//		delays for edge detection
		read_d <= read;
		write_d <= write;

		if ((read1 & ~read) | (write1 & ~write))
		begin
//			Latch Address & Data
			ADDRESS_L <= ADDRESS[1:0];
			DATA_IN_L <= DATA_IN;
		end
		
//		Synchronus rising edge of write
		if ((write == 1'b1) && (write_d == 1'b0))
		begin
//			Set Write
			r_w_active <= 1'b1;
			WR <= 1'b1;
		end

//		Synchronus rising edge of read
		if ((read == 1'b1) && (read_d == 1'b0))
		begin
			r_w_active <= 1'b1;
			RD_E <= 1'b1;
		end

//		Clears
		if (ena_8Mhz && r_w_active)
			clk_8Mhz_enable_found <= 1'b1;

//		1 50Mhz clock later...
		if (clk_8Mhz_enable_found)
		begin
			clk_8Mhz_enable_found <= 1'b0;
			r_w_active <= 1'b0;
			WR <= 1'b0;
			RD_E <= 1'b0;
		end
	end
end


//	NMI from disk controller

assign	NMI_09	=	~SDC_EN & DENSITY & selected_INTRQ;		// Send NMI if Double Density (Halt Mode)

//	HALT from disk controller

assign	HALT	=	(~SDC_EN & HALT_EN & ~selected_DRQ) | sdc_HALT;

assign	HALT_EN_RST = RESET_N & ~selected_INTRQ; // From controller schematic


// The SD_BLK interface and thus the wd1793 will allways transfer 1 blk. This is blk qty - 1 per spec.
assign sd_blk_cnt[1] = 6'd0;
assign sd_blk_cnt[0] = 6'd0;

reg       drive_wp[2];
reg       [1:0] drive_ready  = 2'b00;
reg       [1:0] double_sided = 2'b00;
reg		  [31:0] drive_size[2];
wire	  [31:0] selected_drive_size;
wire			 selected_drive_ready, selected_drive_wp, selected_double_sided;

// As drives are mounted in MISTer this logic saves the write protect and generates ready for
// changing drives to the wd1793.
// This can also get the disk size to properly handle DS drives - TBD

// Reset of drive wp to a default of 1 removed because of persistance.

// Drive 0

always @(negedge img_mounted[0])
begin
	drive_wp[0] <= img_readonly;
	drive_ready[0] <= 1'b1;
	drive_size[0] <= img_size[31:0];  //Size / 256  on [31:8]
	double_sided[0]<= (img_size > 64'd368600) & (img_size < 64'd740000);//20'd368640;
end

// Drive 1

always @(negedge img_mounted[1])
begin
	drive_wp[1] <= img_readonly;
	drive_ready[1] <= 1'b1;
	drive_size[1] <= img_size[31:0];  //Size / 256  on [31:8]
	double_sided[1]<= (img_size > 64'd368600) & (img_size < 64'd740000);//20'd368640;
end

assign		selected_drive_size	=	(drive_index == 3'd1)	?	drive_size[0]:
									(drive_index == 3'd2)	?	drive_size[1]:
																drive_size[0];		// default is drive 1

assign		selected_drive_wp	=	(drive_index == 3'd1)	?	drive_wp[0]:
									(drive_index == 3'd2)	?	drive_wp[1]:
																drive_wp[0];		// default is drive 1

assign		selected_double_sided=	(drive_index == 3'd1)	?	double_sided[0]:
									(drive_index == 3'd2)	?	double_sided[1]:
																double_sided[0];	// default is drive 1

assign		selected_drive_ready =	(drive_index == 3'd1)	?	drive_ready[0]:
									(drive_index == 3'd2)	?	drive_ready[1]:
																drive_ready[0];		// default is drive 1

wd1793 #(1,0) coco_wd1793_sdc
(
	.clk_sys(~CLK),
	.ce(ena_8Mhz),
	.reset(~RESET_N),
	.io_en(1'b1),
	.rd(RD),
	.wr(WR),
	.addr(ADDRESS_L[1:0]),
	.din(DATA_IN_L),
	.dout(DATA_1793),
	.drq(selected_DRQ),
	.intrq(selected_INTRQ),

	.img_mounted(1'b0),						// Not used when using _override
	.img_mounted_overide(1'b1),				// Load img_size and layout on each clock
	.img_size(selected_drive_size[19:0]),

	.sd_lba(wd1793_sd_lba),
	.sd_rd(wd1793_sd_rd),
	.sd_wr(wd1793_sd_wr), 
	.sd_ack(wd1793_sd_ack),

	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(wd1793_sd_buff_din), 
	.sd_buff_wr(sd_buff_wr),

	.wp(selected_drive_wp),

	.size_code(3'd5),						// 5 is 18 sector x 256 bits COCO standard
	.layout(~selected_double_sided),		// 0 = Track-Side-Sector, 1 - Side-Track-Sector
	.side(selected_double_sided  & DRIVE_SEL_EXT[3]),
	.ready(selected_drive_ready),

	.input_active(0),						// Section not used
	.input_addr(0),
	.input_data(0),
	.input_wr(0),
	.buff_din(0)
);


endmodule
