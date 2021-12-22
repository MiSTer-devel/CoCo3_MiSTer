//
// sdram
// Copyright (c) 2015-2019 Sorgelig
// 
// Simplified version, for circular frame reading, without refresh.
//
// Modified by Stan Hodge Oct 2021.
// Refresh added back in.  8 Bit write and 32 bit reads.  Optionally 
// you may take the data from the 16 bit read port in 2 clock cycles.
//
// MISTer sdram Alliance AS4C32M16SB-7TIN (x2)
// https://www.mouser.com/datasheet/2/12/512M%20SDRAM_%20B%20die_AS4C32M16SB-7TCN-7TIN-6TIN_Rev%201-1265391.pdf
//
// Some parts of SDRAM code used from project:
// http://hamsterworks.co.nz/mediawiki/index.php/Simple_SDRAM_Controller
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version. 
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

module sdram_32r8w
(
	input             init,        // reset to initialize RAM
	input             clk,         // clock ~100MHz

	inout  reg [15:0] SDRAM_DQ,    // 16 bit bidirectional data bus
	output reg [12:0] SDRAM_A,     // 13 bit multiplexed address bus
	output            SDRAM_DQML,  // two byte masks
	output            SDRAM_DQMH,  // 
	output reg  [1:0] SDRAM_BA,    // two banks
	output            SDRAM_nCS,   // a single chip select
	output            SDRAM_nWE,   // write enable
	output            SDRAM_nRAS,  // row address select
	output            SDRAM_nCAS,  // columns address select
	output            SDRAM_CKE,   // clock enable
	output            SDRAM_CLK,   // clock for chip

//	CPU R/W port
	input      [24:0] sdram_cpu_addr,  // 25 bit address for 8bit mode. 
//	output reg [31:0] sdram_ldout,     // data output to cpu
	output reg [15:0] sdram_dout,      // data output to cpu [for both ports]
	input      [7:0]  sdram_cpu_din,   // data input from cpu
	input             sdram_cpu_req,   // request
	input             sdram_cpu_rnw,   // 1 - read, 0 - write
	output reg		  sdram_cpu_ack,   // 1 = ack
	output reg        sdram_cpu_ready, // dout is valid. Ready to accept new read/write.

//	Video R port
	input      [24:0] sdram_vid_addr,  // 25 bit A0=0. 
	input             sdram_vid_req,   // request
	output reg		  sdram_vid_ack,   // 1 = ack
	output reg        sdram_vid_ready, // dout is valid. Ready to accept new read/write.

	output reg		  sdram_busy		// doing something...

);

assign SDRAM_nCS  = 0; // It would appear from the schematics that this is a toggle if you want more than 64MB ram (full 128MB)
assign SDRAM_nRAS = command[2];
assign SDRAM_nCAS = command[1];
assign SDRAM_nWE  = command[0];
assign SDRAM_CKE  = 1;
assign {SDRAM_DQMH,SDRAM_DQML} = SDRAM_A[12:11]; // This works because A12 & A11 are unused.  This makes it convenient to assert only during CAS
assign sdram_dout = dq_reg;

// Burst length = 4
localparam BURST_LENGTH        = 2;
localparam BURST_CODE          = (BURST_LENGTH == 8) ? 3'b011 : (BURST_LENGTH == 4) ? 3'b010 : (BURST_LENGTH == 2) ? 3'b001 : 3'b000;  // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE         = 1'b0;     // 0=sequential, 1=interleaved
localparam CAS_LATENCY         = 3'd3;     // 2 for < 100MHz, 3 for >100MHz
localparam OP_MODE             = 2'b00;    // only 00 (standard operation) allowed
localparam NO_WRITE_BURST      = 1'b1;     // 0= write burst enabled, 1=only single access write
localparam MODE                = {3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_CODE};

localparam sdram_startup_cycles= 14'd12100;// 100us, plus a little more, @ 100MHz
localparam startup_refresh_max = 14'b11111111111111;
//localparam cycles_per_refresh  = 14'd780;  // (64000*100)/8192-1 Calc'd as (64ms @ 100MHz)/8192 rose
localparam cycles_per_refresh  = 14'd890;  // (64000*100)/8192-1 Calc'd as (64ms @ 114.560MHz)/8192 rose (act 895)

// SDRAM commands
wire [2:0] CMD_NOP             = 3'b111;
wire [2:0] CMD_ACTIVE          = 3'b011;
wire [2:0] CMD_READ            = 3'b101;
wire [2:0] CMD_WRITE           = 3'b100;
wire [2:0] CMD_PRECHARGE       = 3'b010;
wire [2:0] CMD_AUTO_REFRESH    = 3'b001;
wire [2:0] CMD_LOAD_MODE       = 3'b000;

reg [13:0] refresh_count = startup_refresh_max - sdram_startup_cycles;
reg  [2:0] command;

localparam STATE_STARTUP = 0;
localparam STATE_WAIT    = 1;
localparam STATE_WAIT1   = 2;
localparam STATE_RW1     = 3;
localparam STATE_IDLE    = 4;
localparam STATE_DLY1    = 5;
localparam STATE_DLY2    = 6;
localparam STATE_IDLE_7  = 17;
localparam STATE_IDLE_6  = 16;
localparam STATE_IDLE_5  = 15;
localparam STATE_IDLE_4  = 14;
localparam STATE_IDLE_3  = 13;
localparam STATE_IDLE_2  = 12;
localparam STATE_IDLE_1  = 11;

reg [15:0] dq_reg;

always @(posedge clk) begin
	reg [CAS_LATENCY+BURST_LENGTH:0] data_cpu_ready_delay;
	reg [CAS_LATENCY+BURST_LENGTH:0] data_vid_ready_delay;

	reg        saved_wr;
	reg        saved_vid;
	reg [12:0] cas_addr;
	reg [31:0] saved_data;
	reg  [4:0] state = STATE_STARTUP;

	refresh_count <= refresh_count + 1'b1;

	data_vid_ready_delay[CAS_LATENCY+BURST_LENGTH] <= 0;

	data_cpu_ready_delay[CAS_LATENCY+BURST_LENGTH] <= 0;

	data_cpu_ready_delay <= data_cpu_ready_delay>>1;
	data_vid_ready_delay <= data_vid_ready_delay>>1;

	dq_reg <= SDRAM_DQ;

//	if(data_ready_delay[1]) sdram_ldout[15:00] <= dq_reg;
//	if(data_ready_delay[0]) sdram_ldout[31:16] <= dq_reg;

	sdram_cpu_ready <= 1'b0;
	sdram_vid_ready <= 1'b0;
	
	if (data_cpu_ready_delay[2]) sdram_cpu_ready <= 1'b1; // Data valid for the first 16 bits
	if (data_cpu_ready_delay[1]) sdram_busy <= 1'b0; 

	if (data_vid_ready_delay[2]) sdram_vid_ready <= 1'b1; // Data valid for the first 16 bits
	if (data_vid_ready_delay[1]) sdram_vid_ready <= 1'b1; // Data valid for the second 16 bits

	if (data_vid_ready_delay[0]) sdram_busy <= 1'b0;


	SDRAM_DQ <= 16'bZ;

	command <= CMD_NOP;

	if (!sdram_cpu_req)
		sdram_cpu_ack <= 1'b0;

	if (!sdram_vid_req)
		sdram_vid_ack <= 1'b0;

	case (state)
		STATE_STARTUP: begin
			SDRAM_A    <= 0;
			SDRAM_BA   <= 0;
			sdram_cpu_ready <= 0; //not ready
			sdram_vid_ready <= 0; //not ready
			sdram_busy <= 1'b1;

			// All the commands during the startup are NOPS, except these
			if (refresh_count == startup_refresh_max-31) begin
				// ensure all rows are closed
				command     <= CMD_PRECHARGE;
				SDRAM_A[10] <= 1;  // all banks
				SDRAM_BA    <= 2'b00;
			end
			if (refresh_count == startup_refresh_max-23) begin
				// these refreshes need to be at least tREF (66ns) apart
				command     <= CMD_AUTO_REFRESH;
			end
			if (refresh_count == startup_refresh_max-15) begin
				command     <= CMD_AUTO_REFRESH;
			end
			if (refresh_count == startup_refresh_max-7) begin
				// Now load the mode register
				command     <= CMD_LOAD_MODE;
				SDRAM_A     <= MODE;
			end

			if (!refresh_count) begin
				state   <= STATE_IDLE;
				sdram_busy <= 1'b0;
				refresh_count <= 0;
			end
		end

		STATE_IDLE_7: state <= STATE_IDLE_6;
		STATE_IDLE_6: state <= STATE_IDLE_5;
		STATE_IDLE_5: state <= STATE_IDLE_4;
		STATE_IDLE_4: state <= STATE_IDLE_3;
		STATE_IDLE_3: state <= STATE_IDLE_2;
		STATE_IDLE_2: state <= STATE_IDLE_1;
		STATE_IDLE_1: begin
			state      <= STATE_IDLE;
			sdram_busy <= 1'b0;
			// mask possible refresh to reduce colliding.
			if(refresh_count > cycles_per_refresh) begin
				state    <= STATE_IDLE_7;
				command  <= CMD_AUTO_REFRESH;
				refresh_count <= 0;
				sdram_busy <= 1'b1;
			end
		end

		STATE_IDLE: begin
			saved_vid <= 1'b0;
			if(refresh_count > (cycles_per_refresh<<1)) 
			begin
				state <= STATE_IDLE_1;
				sdram_busy <= 1'b1;
			end
			else
			begin
				if(sdram_cpu_req & !sdram_cpu_ack) // request has to go away after ready=0
				begin
//					fix byte writes [no new command until data is actually written]
					if (~sdram_cpu_rnw)
						{cas_addr[12:9],SDRAM_BA,SDRAM_A,cas_addr[8:0]} <= {~sdram_cpu_addr[0], sdram_cpu_addr[0], 2'b10, sdram_cpu_addr[24:1]}; // Bytes by A0 for writes
					else
						{cas_addr[12:9],SDRAM_BA,SDRAM_A,cas_addr[8:0]} <= {2'b00, 2'b10, sdram_cpu_addr[24:1]}; // No bytes for reads...

					saved_data 	<= {sdram_cpu_din, sdram_cpu_din};
					saved_wr   	<= ~sdram_cpu_rnw;
					command    	<= CMD_ACTIVE;
					state      	<= STATE_WAIT;
					sdram_busy <= 1'b1;
				end
				else
				begin
					if (sdram_vid_req)
					begin
						{cas_addr[12:9],SDRAM_BA,SDRAM_A,cas_addr[8:0]} <= {2'b00, 2'b10, sdram_vid_addr[24:1]}; // No bytes for reads...
						command    	<= CMD_ACTIVE;
						saved_vid <= 1'b1;
						saved_wr <= 1'b0;
						sdram_busy <= 1'b1;
						state	<= STATE_WAIT;
					end
				end
			end
		end

		STATE_WAIT:  state <= STATE_WAIT1;
		STATE_WAIT1: begin
			if (saved_wr)
			begin
				if ((data_vid_ready_delay[5:1] == 5'b00000) && (data_cpu_ready_delay[5:1] == 5'b00000))
					state <= STATE_RW1; // added for clk > 100Mhz
			end	
			else
				state <= STATE_RW1; // added for clk > 100Mhz
		end
		
		STATE_RW1: begin
			SDRAM_A <= cas_addr;
			if (saved_vid)
				sdram_vid_ack <= 1'b1;
			else
				sdram_cpu_ack <= 1'b1;

			if(saved_wr) begin
				command  <= CMD_WRITE;
				SDRAM_DQ <= saved_data[15:0];
//				state <= STATE_IDLE;
				state   <= STATE_DLY1;
				sdram_cpu_ready <= 1'b1; // write done
				sdram_busy	<= 1'b0;
			end
			else begin
				command <= CMD_READ;
				state   <= STATE_IDLE;
				if (saved_vid)
				begin
					data_vid_ready_delay[CAS_LATENCY+BURST_LENGTH] <= 1;
					state   <= STATE_DLY1;
				end
				else
					data_cpu_ready_delay[CAS_LATENCY+BURST_LENGTH] <= 1;
					state   <= STATE_DLY1;
			end
		end
		STATE_DLY1:
			state   <= STATE_DLY2;
		STATE_DLY2:
			state   <= STATE_IDLE;
	endcase

	if (init) begin
		sdram_cpu_ack <= 1'b0;
		sdram_vid_ack <= 1'b0;
		state <= STATE_STARTUP;
		refresh_count <= startup_refresh_max - sdram_startup_cycles;
	end
end

altddio_out
#(
	.extend_oe_disable("OFF"),
	.intended_device_family("Cyclone V"),
	.invert_output("OFF"),
	.lpm_hint("UNUSED"),
	.lpm_type("altddio_out"),
	.oe_reg("UNREGISTERED"),
	.power_up_high("OFF"),
	.width(1)
)
sdramclk_ddr
(
	.datain_h(1'b0),
	.datain_l(1'b1),
	.outclock(clk),
	.dataout(SDRAM_CLK),
	.aclr(1'b0),
	.aset(1'b0),
	.oe(1'b1),
	.outclocken(1'b1),
	.sclr(1'b0),
	.sset(1'b0)
);

endmodule
