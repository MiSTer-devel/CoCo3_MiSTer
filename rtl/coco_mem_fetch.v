////////////////////////////////////////////////////////////////////////////////
// Project Name:	COCO3 Targeting MISTer 
// File Name:		coco_mem_fetch.v
//
// Video Memory Fetch Controller for MISTer
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2021 by Stan Hodge (stan.pda@gmail.com)
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
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



module coco_mem_fetch(
	input        		fast_clk,  		// clock
	input        		RESET_N,	   	// async reset

//	Memory Controller I/O
	output				SDRAM_VID_REQ,
	output	[24:0]		SDRAM_VID_ADDR,
	input				SDRAM_VID_ACK,
	input				SDRAM_VID_READY,
	input	[15:0]		SDRAM_DOUT,

// RAM / Buffer
	output	[8:0]		BUFF_ADD,		// 512x16 ram buffer
	output	[15:0]		BUFF_DATA_O,
	output				BUFFER_WRITE,

//	Video Controller Inputs
	input	[24:0]		RAM_ADDRESS,	// real ram

	input				HBORDER,
	input	[6:0]		HOR_OFFSET,
	input				COCO1,
	input	[3:0]		HRES


);

localparam WORD_END_COUNT = 9'd160 - 1'd1;


wire	[24:0]	PHY_VID_ADD;
wire	[2:0]	BUF_HBORDER;
reg		[8:0]	VID_READ_OFFSET;
reg		[8:0]	read_count;
reg		[4:0]	state;
reg				second_write;
reg				init_offset_a0;
reg		[4:0]	a0_delay;

localparam state_pre_start = 	4'd0;
localparam state_start = 		4'd1;
localparam state_wait_accept = 	4'd2;

localparam state_done = 		4'd10;

assign BUF_HBORDER[0] = HBORDER;
assign a0_delay[0] = init_offset_a0;

assign	PHY_VID_ADD = 	({COCO1, HRES[3]} == 2'b01)           ?	RAM_ADDRESS + {         VID_READ_OFFSET[8:0],   1'b0}:  // 1K  bytes
//                      ({COCO1, HRES[3:1]} == 4'b0100)       ?	RAM_ADDRESS + {1'b0,    VID_READ_OFFSET[7:0],   1'b0}:  // 512 bytes
																RAM_ADDRESS + {2'b00,   VID_READ_OFFSET[6:0],   1'b0};  // 256 Bytes

assign SDRAM_VID_ADDR = PHY_VID_ADD;

// Also if we start a line on a odd word, we will have to throw out the associated even word of the first fetch as it is before our start
// From that point we will be correct using 2 16 bit words.
// We will need SDRAM_VID_READY specific to each port of the memory controller
// Assume SDRAM_VID_READY is specific to this port

always @(posedge fast_clk or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		BUF_HBORDER[2:1] <= 2'b00;
		read_count <= 9'h000;
		SDRAM_VID_REQ <= 1'b0;
		state <= state_pre_start;
		second_write <= 1'b0;
		init_offset_a0 <= 1'b0;
		BUFF_ADD <= 9'h000;
	end
	else
	begin
//		delay 2 clocks [may need to be more because we are running fast]
		BUF_HBORDER[2:1] <= BUF_HBORDER[1:0];

//		delay the a0 component 4 clocks to line up with the read data
		a0_delay[4:1] <= a0_delay[3:0];
		
		BUFF_DATA_O <= SDRAM_DOUT; // 1 clock delay so we can affect the write flag

//		Second write will only be active for 1 clock during a 2 clock write.
		second_write <= SDRAM_VID_READY;
		if (second_write == 1'b1)
			second_write <= 1'b0;
		
//		Eliminate second_write on the first odd write
		BUFFER_WRITE <= SDRAM_VID_READY && !(second_write & a0_delay[4]);

		if (BUFFER_WRITE)
			BUFF_ADD <= BUFF_ADD + 1'b1;


//		State Mach
		case(state)
			state_pre_start:
				if (!BUF_HBORDER[2])
				begin
					VID_READ_OFFSET <= HOR_OFFSET;
					BUFF_ADD <= 9'h000;
				end
				else
					state <= state_start;
				
			state_start:
			begin
				if (!SDRAM_VID_ACK)
				begin
					SDRAM_VID_REQ <= 1'b1;
					state <= state_wait_accept;
					init_offset_a0 <= PHY_VID_ADD[1];
				end
			end

			state_wait_accept:
			begin
				if (SDRAM_VID_ACK)
				begin
					SDRAM_VID_REQ <= 1'b0;

					if (read_count >= WORD_END_COUNT)
					begin
						read_count <= 9'h000;
						state <= state_done;
					end
					else
					begin
//						If odd address we only store 1 else 2
						if (init_offset_a0)
						begin
							read_count <= read_count + 1'b1;
							VID_READ_OFFSET <= VID_READ_OFFSET + 1'b1;
						end
						else
						begin
							VID_READ_OFFSET <= VID_READ_OFFSET + 2'b10;
							read_count <= read_count + 2'b10;
						end

						state <= state_start;
					end
				end
			end

			state_done:
			begin
				if (!BUF_HBORDER[2])
					state <= state_pre_start;
			end

			default:
				state <= state_done;
		endcase

	end
end


endmodule

