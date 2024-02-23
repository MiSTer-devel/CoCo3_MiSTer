////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 5.x.x
// File Name:		Music_Speech.sv
//
// CoCo3 in an FPGA
//
////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
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
//
////////////////////////////////////////////////////////////////////////////////
// Stan Hodge
//
//	Music_Speech.sv by Stan Hodge 02/16/24
////////////////////////////////////////////////////////////////////////////////

module Music_Speech(
input				RESET_N,
input				CLK,
input				CLK_EN,
input				CLK_1_78,

input		[1:0]	MPI_SCS,			// slot id
input		[15:0]	ADDRESS,			// from 09
input		[7:0]	WRITE_DATA,			// from 09

output		[7:0]	READ_DATA,			// to 09
input				RW_N,				// from 09
output		[7:0]	AUDIO				// 8 bit audio output mixed from both Speech and Music chips
);

///////////////////////////////////////////////////////
// Host Interface

localparam	Soft_Reset_Adrs	=	15'hff7d;
localparam	Data_Write_Adrs	=	15'hff7e;

localparam	SLOT_1		=	2'b00;	// Nothing [RS-232)
localparam	SLOT_2		=	2'b01;	// SDC
localparam	SLOT_3		=	2'b10;	// Cartridge System
localparam	SLOT_4		=	2'b11;	// FDC

localparam	S_M_SLOT	=	SLOT_2;

reg			Soft_Reset;
wire		System_Reset;

//	Soft Reset Bit
always @ (negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		Soft_Reset <= 1'b0;
	end
	else
	begin
		if (CLK_EN && !RW_N && (MPI_SCS == S_M_SLOT) && (ADDRESS == Soft_Reset_Adrs))
		begin
			if (WRITE_DATA[0])
				Soft_Reset <= !Soft_Reset;
			else
				Soft_Reset <= 1'b0;
		end
	end
end

assign	System_Reset = RESET_N ^ Soft_Reset;

// New data and INT
reg			INT3_N;
reg	[7:0]	SOC_WR_DATA;

always @ (negedge CLK or negedge Port_C[7])
begin
	if(!Port_C[7])
	begin
		INT3_N <= 1'b1;
	end
	else
	begin
		if (CLK_EN && !RW_N && (MPI_SCS == S_M_SLOT) && (ADDRESS == Data_Write_Adrs))
		begin
			SOC_WR_DATA <= WRITE_DATA;
			INT3_N <= 1'b0;
		end
	end
end


//////////////////////////////////////////////////////////////////////////////
// Read Data

wire			Speech_Status;
wire			Music_Status;

assign			READ_DATA = {INT3_N, Speech_Status, Music_Status, 5'b00000};


/////////////////////////////////////////////////////////////////////////////
// SOC

wire			INT1_N;
wire	[7:0]	Port_A, Port_B, Port_C, Port_D_IN, Port_D_OUT;

Music_Speech_SOC CoCo3_Music_Speech_SOC(
		.RESET_N(RESET_N),
		.CLKIN(CLK),
		.CLK_1_78(CLK_1_78),

		.INT1_N(INT1_N),
		.INT3_N(INT3_N),
		.PORT_A(Port_A),
		.PORT_B(Port_B),
		.PORT_C(Port_C),
		.PORT_D_OUT(Port_D_OUT),
		.PORT_D_IN(Port_D_IN)
);

/////////////////////////////////////////////////////////////////////////////
// SRAM Chip

COCO_SRAM_6116 CoCo3_SRAM_6116(
		.CLK(CLK),
		.ADDR({Port_C[2:0], Port_B}),		// Check
		.R_N(Port_C[4]),					// Check
		.DATA_O(Port_D_IN),
		.DATA_I(Port_D_OUT)
);

/////////////////////////////////////////////////////////////////////////////
// Speech Chip

sp0256 CoCo3_sp0256(
	.clock(),
	.ce(),
	.reset(),
	.input_rdy(),
	.allophone(),
	.trig_allophone(),
	.audio_out()
);


/////////////////////////////////////////////////////////////////////////////
// Music Chip

ym2149_audio CoCo3_ym2149_audio(
	.clk_i(CLK),
	.en_clk_psg_i(CLK_1_78),
	.sel_n_i(1'b1),		// No divide by 2
	.reset_n_i(RESET_N),
	.bc_i(),
	.bdir_i(),
	.data_i(),
	.data_r_o(),

//	.ch_a_o(),
//	.ch_b_o(),
//	.ch_c_o()

	.mix_audio_o(),		//[13:0]
//	.pcm14s_o()
);

endmodule
