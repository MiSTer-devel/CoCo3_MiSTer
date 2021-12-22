////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 4.0
// File Name:		EE_Cold_Bt.v
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
//	EE_Cold_Bt by Stan Hodge 11/30/21
////////////////////////////////////////////////////////////////////////////////


module EE_Cold_Bt(
input				CLK,

input				Display_EE,			// from MISTer subsystem
input				Cold_Boot,			// from MISTer subsystem

output				RESET_to_COCO_N,	// RESET_N to the coco3 [logically AND'ed to top reset]
output				EE_to_COCO			// Easter Egg to the coco3

);

////////////////////////////////////////////////////////////
reg 			Display_EE_D = 1'b0;
reg				Cold_Boot_D = 1'b0;
wire			Start_Display_EE, Start_Cold_Boot;
wire	[3:0]	inst;
reg				EE = 1'b1;
reg				N_RESET = 1'b1;

assign			EE_to_COCO = EE;
assign			RESET_to_COCO_N = N_RESET;

reg		[47:0]	prog = 48'h000000000000;
assign			inst = prog[3:0];

reg				next_instruction = 1'b0;

reg		[23:0]	timer = 24'h000000;

localparam	SHORT_TIME	=	24'h0aecdf;	//	.05 sec @ 14.32 Mhz
localparam	LONG_TIME	=	24'h418D40;	// .3 sec @ 14.32 Mhz

localparam	EE_PROG =			{20'h00000, inst_EE_INACTIVE, inst_LONG_TIMER, inst_RESET_INACTIVE, inst_SHORT_TIMER, inst_RESET_ACTIVE,
								inst_EE_ACTIVE, inst_START};
localparam	Cold_Boot_PROG =	{1'h0, inst_RESET_INACTIVE, inst_SHORT_TIMER, inst_RESET_ACTIVE, inst_SHORT_TIMER, inst_EE_INACTIVE, 
								inst_LONG_TIMER, inst_RESET_INACTIVE, inst_SHORT_TIMER, inst_RESET_ACTIVE, inst_EE_ACTIVE, inst_START};

localparam inst_NULL = 			4'd0;
localparam inst_EE_ACTIVE = 	4'd1;
localparam inst_EE_INACTIVE = 	4'd2;
localparam inst_RESET_ACTIVE = 	4'd3;
localparam inst_RESET_INACTIVE =4'd4;
localparam inst_SHORT_TIMER = 	4'd5;
localparam inst_LONG_TIMER = 	4'd6;
localparam inst_START = 		4'd8;

assign		Start_Display_EE = ((Display_EE == 1'b1) & (Display_EE_D == 1'b0));
assign		Start_Cold_Boot = ((Cold_Boot == 1'b1) & (Cold_Boot_D == 1'b0));


always @(posedge CLK)
begin

	Display_EE_D <= Display_EE;
	Cold_Boot_D <= Cold_Boot;

	next_instruction <= 1'b0;

	if (Start_Display_EE)
	begin
		prog <= EE_PROG;
	end

	if (Start_Cold_Boot)
	begin
		prog <= Cold_Boot_PROG;
	end

	if (next_instruction)
		prog[43:0] <= prog[47:4];

	case(inst)
	
	inst_NULL:;
	
	inst_START:
	begin
		if (!next_instruction)
		begin
			timer <= 24'h000000;		// clear timer
			next_instruction <= 1'b1;
		end
	end

	inst_EE_ACTIVE:
	begin
		if (!next_instruction)
		begin
			EE <= 1'b0;
			next_instruction <= 1'b1;
		end
	end
	
	inst_EE_INACTIVE:
	begin
		if (!next_instruction)
		begin
			EE <= 1'b1;
			next_instruction <= 1'b1;
		end
	end

	inst_RESET_ACTIVE:
	begin
		if (!next_instruction)
		begin
			N_RESET <= 1'b0;
			next_instruction <= 1'b1;
		end
	end
	
	inst_RESET_INACTIVE:
	begin
		if (!next_instruction)
		begin
			N_RESET <= 1'b1;
			next_instruction <= 1'b1;
		end
	end
	
	inst_SHORT_TIMER:
	begin
		if (!next_instruction)
		begin
			timer <= timer + 1'b1;
			if (timer==SHORT_TIME)
			begin
				next_instruction <= 1'b1;
				timer <= 24'h000000;		// clear timer
			end
		end
	end

	inst_LONG_TIMER:
	begin
		if (!next_instruction)
		begin
			timer <= timer + 1'b1;
			if (timer==LONG_TIME)
			begin
				next_instruction <= 1'b1;
				timer <= 24'h000000;		// clear timer
			end
		end
	end

	default:;

	endcase
end

endmodule
