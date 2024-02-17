////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 5.x.x
// File Name:		Auto_Run.sv
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
//	Auto_Run by Stan Hodge 02/16/24
////////////////////////////////////////////////////////////////////////////////


module Auto_Run(
input				RESET_N,
input				CLK,
input				CLK_1_78,

input		[1:0]	MPI_SCS,			// slot id
input		[1:0]	MODE,				// from MISTer subsystem 00=NONE, 01=DOS<RET>, 10=RUN"AUTO<RET>
input				AMW_ACK,			// from AMW subsystem - Cold Boot setup finished

input		[72:0]	KEY_IN,				// Keystroke array
output		[72:0]	KEY_OUT				// Modified Keystroke array
);


// Programs
// MODE = 01
//											 D   O   S  <CR>
wire		[7:0]	DOS_KEYFILE[0:3]	=	'{8'd4, 8'd15, 8'd19, 8'd48};

// MODE = 10
//											 R   U   N  <S>  2   A  U   T   O  <CR>
wire		[7:0]	RUN_KEYFILE[0:9]	=	'{8'd18, 8'd21, 8'd14, 8'd55, 8'd34, 8'd1, 8'd21, 8'd20, 8'd15, 8'd48};

localparam	PRESS_KEY	=	1'b1;
localparam	RELEASE_KEY	=	1'b0;

reg		[3:0]	index;
reg				shift;
reg		[7:0]	char;
reg				run;					// 1=running
reg				key_up_down;
reg				timer_19_d;

//	300ms [600ms is aprox 1024000]
reg		[19:0]	timer;
//	timer[19] changes state every 524288 counts, ~ 0.294 seconds.

reg				timer_enable;	// 1=run, 0=stop and clear

localparam st_beg0 = 			4'd0;
localparam st_beg1 = 			4'd1;
localparam st_beg2 = 			4'd2;
localparam st_start = 			4'd3;
localparam st_1 = 				4'd4;
localparam st_2 = 				4'd5;
localparam st_3 = 				4'd6;

reg		[3:0]	state;

reg				first_time	=	1'b1;

/////////////////////////////////////////////////////////////
//	Timer

always @ (negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		timer <= 20'b00000000000000000000;
	end
	else
	begin
		if (CLK_1_78)
		begin
			if (timer_enable)
				timer <= timer + 1'b1;
			else
				timer <= 20'b00000000000000000000;
		end
	end
end

/////////////////////////////////////////////////////////////
//	Output

always @(*)
begin
	
	KEY_OUT <= KEY_IN;

	if (run)
	begin
		if (shift)
		begin
			KEY_OUT[55] 	<= 	key_up_down;
			KEY_OUT[char]	<=	key_up_down;
		end
		else
		begin
			KEY_OUT[char]	<=	key_up_down;
		end
	end
end


/////////////////////////////////////////////////////////////
//	Main State Mach

always @ (negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		state <= st_beg0;
		shift <= 1'b0;
		index <= 4'd0;
		run <= 1'b0;
		timer_enable <= 1'b0;
		key_up_down <= RELEASE_KEY;
		timer_19_d <= 1'b0;
	end
	else
	begin

		if (AMW_ACK)
			first_time <= 1'b1;

		timer_19_d <= timer[19];

		case(state)

			st_beg0:
			begin
				timer_enable <= 1'b1;
				if (!timer[19] && timer_19_d)
					state <= st_beg1;
			end

			st_beg1:
			begin
				if (!timer[19] && timer_19_d)
					state <= st_beg2;
			end

			st_beg2:
			begin
				if (!timer[19] && timer_19_d)
				begin
					state <= st_start;
					timer_enable <= 1'b0;
				end
			end

			st_start:
			begin
				if (first_time  && (MPI_SCS == 2'b01))
				begin
					if (MODE == 2'b01)	//DOS
					begin
						if (DOS_KEYFILE[index] == 8'd55)
							shift <= 1'b1;
						char <= DOS_KEYFILE[index];
						run <= 1'b1;
						state <= st_1;
					end
					else if (MODE == 2'b10)	//RUN"AUTO
					begin
						if (RUN_KEYFILE[index] == 8'd55)
							shift <= 1'b1;
						char <= RUN_KEYFILE[index];
						run <= 1'b1;
						state <= st_1;
					end
				end
			end
	
			st_1:
			begin
				index <= index + 1'b1;
				if (shift && (char == 8'd55)) // read next char
					state <= st_start;
				else
				begin
					timer_enable <= 1'b1;
					key_up_down <= PRESS_KEY;
					state <= st_2;
				end
			end

			st_2:
			begin
				if (timer[18] == 1'b1)	// 300ms time passed
				begin
					key_up_down <= RELEASE_KEY;
					state <= st_3;
				end
			end

			st_3:
			begin
				if (timer[18] == 1'b0)	// 300ms time passed
				begin
					shift <= 1'b0;
					timer_enable <= 1'b0;
					if (char == 7'd48) // we are done
					begin
						first_time <= 1'b0;
						run <= 1'b0;
					end
					state <= st_start;
				end
			end

			default:;
		endcase
	end
end


endmodule
