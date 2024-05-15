////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 5.x.x
// File Name:		Cassette_Write.sv
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
//	Cassette_Write by Stan Hodge 03/18/24
////////////////////////////////////////////////////////////////////////////////


module Cassette_Write(
	input				RESET_N,
	input				CLK,
	input				CLK_1_78,

	input				CASS_REWIND_RECORD,
	input				MOTOR_ON,
	input		[5:0]	DTOA_CODE,

// 	SD block level interface

	input 				img_mounted, 	// signaling that new image has been mounted
	input				img_readonly, 	// mounted as read only. valid only for active bit in img_mounted
	input 		[63:0] 	img_size,    	// size of image in bytes.

	output		[31:0] 	sd_lba,
	output		[5:0]	sd_blk_cnt,		// number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!
	output reg			sd_rd,
	output reg  		sd_wr,
	input       		sd_ack,

// 	SD byte level access. Signals for 2-PORT altsyncram.
	input  		[8:0]	sd_buff_addr,
	input  		[7:0] 	sd_buff_dout,
	output 		[7:0] 	sd_buff_din,
	input        		sd_buff_wr

);


//	Create 16x sample clock for the 2400 Baud rate...
//	~26us based on 1.78Mhz [562 ns]- divide by 46....
// Generate 1.78 Mhz [enable] GP clk
reg clk_sample;
reg [5:0] clk_sample_ctr;

localparam	Divide_Rate	=	6'd45;

always @ (negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		clk_sample <= 1'b0;
		clk_sample_ctr <= 6'b000000;
	end
	else
	begin
		clk_sample <= 1'b0;
		if (CLK_1_78)
		begin
			clk_sample_ctr <= clk_sample_ctr + 1'b1;
			if (clk_sample_ctr == Divide_Rate)
			begin
				clk_sample <= 1'b1;
				clk_sample_ctr <= 6'b000000;
			end
		end
	end
end

//	Mounted SD Image [for the cass]
//	This is not used and only here for completeness

//reg				drive_wp;
//reg		[31:0]	drive_size;

//always @(negedge img_mounted)
//begin
//	drive_wp <= img_readonly;
//	drive_size <= img_size[31:0];  //Size / 256  on [31:8]
//end

//	Set to 1 512 byte block per r/w
assign sd_blk_cnt = 6'd0;


//	Byte Receiver

reg 	[15:0]	incomming_reg;

reg 	[5:0]	bit_time;
reg		[2:0]	bit_count;
reg				wave_negative;

localparam		time_out		=	6'h3f;
localparam		wave_zero_level	=	6'd32;
localparam		bit_time_1		=	6'd22;
localparam		sync			=	15'b0111_1000_1010_101;	// Pre shift $553C [L -> R]
localparam		sync_proper		=	8'h3C;
localparam		leader			=	8'h55;
localparam		pre_rollover	=	9'h1FF;
localparam		rollover		=	9'h000;

reg				byte_clk;
reg				look_for_sync;
reg				flush_end, flush_end_que;
reg				sd_hold;
reg				pre_roll;
reg		[7:0]	blk_type;
reg 	[7:0]	protocol_data_count;
reg				gap;

//	Buffer interface
wire 	[8:0]	buf_address;
wire	[7:0]	buf_data_in;
wire	[7:0]	buf_data_out;
wire			buf_write;

//	State Mach states
localparam 		st_beg0 = 			4'd0;
localparam 		st_start = 			4'd1;
localparam 		st_st1 = 			4'd2;
localparam 		st_st2 = 			4'd3;
localparam 		st_wr = 			4'd4;
localparam 		st_wr1 = 			4'd5;

reg		[3:0]	st_state;
reg		[3:0]	state_stack;

localparam 		p_sync =			3'd0;
localparam 		p_blk_type =		3'd1;
localparam 		p_len =				3'd2;
localparam 		p_dta =				3'd3;
localparam 		p_cksum =			3'd4;

reg		[2:0]	p_state;

localparam 		sd_wr_st =			2'd0;
localparam 		sd_wr_st1 =			2'd1;
localparam 		sd_wr_st2 =			2'd2;

reg		[1:0]	sd_wr_state;


always @ (negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		buf_address <= 9'b000000000;
		byte_clk <= 1'b0;
		bit_count <= 3'b000;
		incomming_reg <= 16'h0000;
		bit_time <= 6'b000000;
		wave_negative <= 1'b0;
		look_for_sync <= 1'b1;

		buf_write <= 1'b0;
		st_state <= st_beg0;
		p_state <= p_sync;
		flush_end <= 1'b0;
		flush_end_que <= 1'b0;
		
		sd_lba <= 32'd0;
		sd_wr <= 1'b0;
		sd_rd <= 1'b0;

		sd_wr_state <= sd_wr_st;
		sd_hold <= 1'b0;
		pre_roll <= 1'b0;
		gap <= 1'b0;
	end
	else
	begin
//		Synchronus Clears
		if (!MOTOR_ON)
		begin
//			Receiver Resets
			byte_clk <= 1'b0;
			bit_count <= 3'b000;
			incomming_reg <= 16'h0000;
			bit_time <= 6'b000000;
			wave_negative <= 1'b0;
			look_for_sync <= 1'b1;
		end

		if (!CASS_REWIND_RECORD)
		begin
//			Eject Tape
			byte_clk <= 1'b0;
			bit_count <= 3'b000;
			incomming_reg <= 16'h0000;
			bit_time <= 6'b000000;
			wave_negative <= 1'b0;
			look_for_sync <= 1'b1;

			st_state <= st_beg0;
			p_state <= p_sync;
			buf_write <= 1'b0;
			flush_end <= 1'b0;
			flush_end_que <= 1'b0;

			sd_lba <= 32'd0;
			sd_wr <= 1'b0;
			sd_rd <= 1'b0;

			sd_wr_state <= sd_wr_st;
			sd_hold <= 1'b0;
			pre_roll <= 1'b0;
			gap <= 1'b0;
		end

		byte_clk <= 1'b0;

//		2400/1200 baud receiver
		if (clk_sample)
		begin
			if (DTOA_CODE < wave_zero_level)
				wave_negative <= 1'b1;
			else
				wave_negative <= 1'b0;
			bit_time <=  bit_time + 1'b1;

//			Zero crossing detect
			if ((DTOA_CODE >= wave_zero_level) && wave_negative)
			begin
//				Initially we are not collecting the leader bytes just collecting them and
//				waiting for the sync $3C55.  The write to file stage will automatically
//				write the 128 leader bytes befor we start transfering data.
				if (!look_for_sync)
				begin
					bit_count <= bit_count + 1'b1;
					if (bit_count == 3'b111)
						byte_clk <= 1'b1;
				end
//				Shift
				incomming_reg[14:0] <= incomming_reg[15:1];
				if (bit_time <  bit_time_1)
					incomming_reg[15] <= 1'b1;
				else
				begin
					incomming_reg[15] <= 1'b0;
					if (incomming_reg[15:1] == sync)
					begin
						look_for_sync <= 1'b0;
						byte_clk <= 1'b1;
					end
				end
				bit_time <= 6'b000000;
			end
		end

//		Normal clocking starts here
		case(st_state)

			st_beg0:
			begin
//				When we start we write 128 bytes of leader to the buffer
//				before we start with the protocol stuff
				if (MOTOR_ON)
				begin
					buf_address <= 9'b000000000;
					buf_data_in <= leader;
					protocol_data_count <= 8'h80;	// We will use this to count the 128 bytes

					st_state <= st_start;
				end
			end

			st_start:
			begin
				state_stack <= st_start;			// We come back here
				st_state <= st_wr;					// Write a byte
				protocol_data_count <= protocol_data_count - 1'b1;
				if (protocol_data_count == 8'h00)	// 128 bytes
				begin
					st_state <= st_st1;				// No, don't write any more - were done
				end
			end

			st_st1:
			begin
				if (byte_clk)
				begin
					case(p_state)

						p_sync:
						begin
							if (incomming_reg[15:8] == sync_proper)
							begin
								buf_data_in <= incomming_reg[15:8];
								state_stack <= st_st1;				// We come back here
								st_state <= st_wr;					// Write a byte
								p_state <= p_blk_type;
							end
						end

						p_blk_type:
						begin
							buf_data_in <= incomming_reg[15:8];
							blk_type <= incomming_reg[15:8];
							state_stack <= st_st1;				// We come back here
							st_state <= st_wr;					// Write a byte
							p_state <= p_len;
						end

						p_len:
						begin
							buf_data_in <= incomming_reg[15:8];
							protocol_data_count <= incomming_reg[15:8];
							state_stack <= st_st1;				// We come back here
							st_state <= st_wr;						// Write a byte
							if (incomming_reg[15:8] == 8'h00)
								p_state <= p_cksum;
							else
								p_state <= p_dta;
						end

						p_dta:
						begin
							buf_data_in <= incomming_reg[15:8];
							protocol_data_count <= protocol_data_count - 1'b1;
							state_stack <= st_st1;				// We come back here
							st_state <= st_wr;						// Write a byte
							p_state <= p_dta;
							if ((blk_type == 8'h00) & (protocol_data_count == 8'h05) & (incomming_reg[15:8] == 8'hff))
								gap <= 1'b1;
							if (protocol_data_count == 8'h01)
								p_state <= p_cksum;
						end

						p_cksum:
						begin
							buf_data_in <= incomming_reg[15:8];
							look_for_sync <= 1'b1;
							if (blk_type == 8'hff)
							begin
								flush_end_que <= 1'b1;
								state_stack <= st_st1;			// We come back here [close it]
							end
							else
								state_stack <= st_st2;			// We come back here [next block]
							st_state <= st_wr;					// Write a byte
							p_state <= p_sync;
						end

						default:;
					endcase
				end
			end

			st_st2:
			begin
				buf_data_in <= leader;
				if ((blk_type == 8'h00) || gap)
					protocol_data_count <= 8'h80;	// We will use this to count the 128 bytes
				else
					protocol_data_count <= 8'h02;	// We will use this to count the 2 bytes
				st_state <= st_start;				// No, don't write any more - were done
			end

//			Perform the byte writes to the buffer
//			This acts like a sub routine....
			st_wr:
			begin
				if (!sd_hold)
				begin
					buf_write <= 1'b1;
					st_state <= st_wr1;
				end
			end

			st_wr1:
			begin
				buf_address <= buf_address + 1'b1;
				buf_write <= 1'b0;
				flush_end  <= flush_end_que;
				flush_end_que <= 1'b0;
				st_state <= state_stack;
			end

			default:;
		endcase

//		Handle SD buf clear
		case(sd_wr_state)

			sd_wr_st:
			begin
				if (buf_address == pre_rollover)
					pre_roll <= 1'b1;						// Stop writing to buffer
				if ((buf_address == rollover) & pre_roll)	// If buffer full - write it to SD
				begin
					pre_roll <= 1'b0;

					sd_wr <= 1'b1;
					sd_wr_state <= sd_wr_st1;

					sd_hold <= 1'b1; 						// Hold writes
				end
				if (flush_end)								// Write remainder of the buffer at th end...
				begin
					sd_wr <= 1'b1;
					flush_end <= 1'b0;
					sd_hold <= 1'b1;
					sd_wr_state <= sd_wr_st1;
				end
			end

			sd_wr_st1:
			begin
				if (sd_ack)
				begin
					sd_wr <= 1'b0;
					sd_wr_state <= sd_wr_st2;
				end
			end

			sd_wr_st2:
			begin
				if (!sd_ack)
				begin
					sd_hold <= 1'b0;
					sd_lba <= sd_lba + 1'b1;
					sd_wr_state <= sd_wr_st;
				end
			end

			default:;
		endcase
			
	end
end


cass_dpram cas_wr_buff
(
	.clock(CLK),
	.address_a(sd_buff_addr),
	.data_a(sd_buff_dout),
	.wren_a(sd_buff_wr),
	.q_a(sd_buff_din),
	
	.address_b(buf_address),
	.data_b(buf_data_in),
	.wren_b(buf_write),
	.q_b(buf_data_out)
);


endmodule


module cass_dpram
(
	input	    	 	clock,

	input		[8:0]	address_a,
	input		[7:0]	data_a,
	input	      		wren_a,
	output reg 	[7:0]	q_a,

	input	    [8:0]	address_b,
	input	    [7:0]	data_b,
	input	            wren_b,
	output reg	[7:0]	q_b
);

logic [7:0] ram[0:511];

always_ff@(posedge clock) begin
	if(wren_a) begin
		ram[address_a] <= data_a;
		q_a <= data_a;
	end else begin
		q_a <= ram[address_a];
	end
end

always_ff@(posedge clock) begin
	if(wren_b) begin
		ram[address_b] <= data_b;
		q_b <= data_b;
	end else begin
		q_b <= ram[address_b];
	end
end

endmodule
