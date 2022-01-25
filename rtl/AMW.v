////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 5.0
// File Name:		AMW.v
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
// Automated Memory Write by Stan Hodge 1/20/22
////////////////////////////////////////////////////////////////////////////////


module AMW(
input				CLK,
input				RESET_N,

input				Trigger,
input				Restart,
input				Cycle_Run,	// AMW_WR shows cycle in process

output	reg	[24:0]	AMW_Adrs,
output	reg	[7:0]	AMW_Data,
output	reg			AMW_EN,
output	reg			AMW_Ready,
output	reg			AMW_End
);

////////////////////////////////////////////////////////////

COCO_ROM_16 COCO3_ROM_Instructions (
	.ADDR(pgm_address),
	.DATA(DOUT)
);

wire	[7:0]	DOUT;

//	Instructions are 5 bytes

// valid, nc, nc, nc, nc, nc, nc, a24
// a23, a22, a21, a20, a19, a18, a17, a16
// a15, a14, a13, a12, a11, a10, a09, a08
// a07, a06, a05, a04, a03, a02, a01, a00
// d07, d06, d05, d04, d03, d02, d01, d00

////////////////////////////////////////////////////////////

localparam AMW_START = 			4'd0;
localparam AMW_F1 = 			4'd1;
localparam AMW_F2 = 			4'd2;
localparam AMW_F3 = 			4'd3;
localparam AMW_F4 = 			4'd4;
localparam AMW_F5 = 			4'd5;
localparam AMW_WAIT = 			4'd6;
localparam AMW_W1 = 			4'd7;
localparam AMW_W2 = 			4'd8;
localparam AMW_ST_END = 		4'd9;

reg	[3:0]	state;
reg	[3:0]	pgm_address;
reg			valid;
reg			Trigger_D;
reg			run;

always @(negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		state <= AMW_START;
		pgm_address <= 4'b0000;
		AMW_Ready <= 1'b0;
		valid <= 1'b0;
		AMW_End <= 1'b0;
		AMW_EN <= 1'b0;
		run <= 1'b0;
	end
	else
	begin

		Trigger_D <= Trigger;

		case(state)
	
			AMW_START:
			begin
				pgm_address <= 4'b0000;
				AMW_Ready <= 1'b0;
				AMW_EN <= 1'b0;
				state <= AMW_F1;
				run <= 1'b0;
			end

			AMW_F1:
			begin
				AMW_Ready <= 1'b0;
				valid <= DOUT[7];
				AMW_Adrs[24] <= DOUT[0];
				pgm_address <= pgm_address + 1'b1;
				state <= AMW_F2;
			end

			AMW_F2:
			begin
				if (~valid)
					state <= AMW_ST_END;
				else
				begin
					AMW_Adrs[23:16] <= DOUT[7:0];
					pgm_address <= pgm_address + 1'b1;
					state <= AMW_F3;
				end
			end

			AMW_F3:
			begin
				AMW_Adrs[15:8] <= DOUT[7:0];
				pgm_address <= pgm_address + 1'b1;
				state <= AMW_F4;
			end

			AMW_F4:
			begin
				AMW_Adrs[7:0] <= DOUT[7:0];
				pgm_address <= pgm_address + 1'b1;
				state <= AMW_F5;
			end

			AMW_F5:
			begin
				AMW_Data <= DOUT[7:0];
				pgm_address <= pgm_address + 1'b1;
				AMW_Ready <= 1'b1;
				state <= AMW_WAIT;
			end

			AMW_WAIT:
			begin
				if (run | (Trigger == 1'b1 && Trigger_D == 1'b0))
				begin
					run <= 1'b1;
					AMW_EN <= 1'b1;
					AMW_Ready <= 1'b0;
					state <= AMW_W1;
				end
			end

			AMW_W1:
			begin
				if (Cycle_Run)	// Processing
				begin
					AMW_EN <= 1'b0;
					state <= AMW_W2;
				end
			end

			AMW_W2:
			begin
				if (~Cycle_Run)	// Write Done
				begin
					state <= AMW_F1;	// Get next inst
				end
			end

			AMW_ST_END:
			begin
				AMW_End <= 1'b1;
				if (Restart)
				begin
					AMW_End <= 1'b0;
					state <= AMW_START;
				end
			end

			default:;
		endcase
	end
end

endmodule
