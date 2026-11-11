////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 5.0
// File Name:		UIM.v
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
// UART Injection Module by Stan Hodge 11/8/26
//
// This module uses the AMW_END chain to cause a $FF to be written to the 6551 
// uart, then delay until that transmission has been made, then pass on the AMW_END.
// This only occurs in slot 1.  In other slots, AMW_END_OUT = AMW_END_IN.
//
////////////////////////////////////////////////////////////////////////////////


module UIM(
input				CLK,
input				RESET_N,

input		[1:0]	MPI_SCS,
input				PH_2,

input				AMW_END_IN,
input				ENABLE_IN,
input				RW_N_IN,

input		[1:0]	ADDRESS_IN,
input		[7:0]	DATA_IN,


output				AMW_END_OUT,
output				ENABLE_OUT,
output				RW_N_OUT,

output		[1:0]	ADDRESS_OUT,
output		[7:0]	DATA_OUT

);

////////////////////////////////////////////////////////////


localparam UIM_START = 			3'd0;
localparam UIM_F1 = 			3'd1;
localparam UIM_F2 = 			3'd2;
localparam UIM_F3 = 			3'd3;
localparam UIM_F4 = 			3'd4;
localparam UIM_F5 = 			3'd5;
localparam UIM_F6 = 			3'd6;
localparam UIM_ST_END = 		3'd7;

reg	[2:0]	state;
reg			mux,rw,ena,timer_ena, AMW_END_OUT_ST;
reg	[13:0]	timer;

assign	ADDRESS_OUT = (mux == 1'b0)			?	ADDRESS_IN:
												2'b00;

assign	DATA_OUT = (mux == 1'b0)			?	DATA_IN:
												8'b11111111;

assign	RW_N_OUT = (mux == 1'b0)			?	RW_N_IN:
												rw;

assign	ENABLE_OUT = (mux == 1'b0)			?	ENABLE_IN:
												ena;

assign	AMW_END_OUT = (MPI_SCS == 2'b00)	?	AMW_END_OUT_ST:
												AMW_END_IN;

always @(negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		state <= 	UIM_START;
		mux <=		1'b0;
		rw <=		1'b1;
		ena <=		1'b0;
		timer <=	14'b00000000000000;
		timer_ena <=1'b0;
		AMW_END_OUT_ST <= 1'b0;
	end
	else
	begin

		if (timer_ena == 1'b1)
			timer <= timer + 1'b1;

		case(state)
	
			UIM_START:
			begin
				if ((MPI_SCS == 2'b00) && (AMW_END_IN == 1'b1))
					state <= UIM_F1;
			end

			UIM_F1:
			begin
				mux <=	1'b1;
				state <= UIM_F2;
			end

			UIM_F2:
			begin
				ena <= 1'b1;
				state <= UIM_F3;
			end

			UIM_F3:
			begin
				rw <= 1'b0;
				state <= UIM_F4;
			end

			UIM_F4:
			begin
				if (PH_2)
				begin
					rw <= 1'b1;
					state <= UIM_F5;
				end
			end

			UIM_F5:
			begin
				ena <= 1'b0;
				state <= UIM_F6;
			end

			UIM_F6:
			begin
				mux <= 1'b0;
				timer_ena <= 1'b1;
				state <= UIM_ST_END;
			end

			UIM_ST_END:
			begin
				if (timer[13] == 1'b1)
				begin
					AMW_END_OUT_ST <= 1'b1;
					timer_ena <= 1'b0;
				end
			end

			default:;
		endcase
	end
end

endmodule
