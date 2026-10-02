//============================================================================
//  Simulation replacement for rtl/sdram/sdram2.sv (module sdram_32r8w).
//
//  The controller below is rtl/sdram/sdram2.sv copied verbatim -- the same
//  state machine, refresh schedule, CAS/burst delays and ack/ready timing the
//  core is written against. Only the pins changed:
//
//    - SDRAM_DQ is not a tristate. The controller's drive is SDRAM_DQ (a reg
//      that it sets to 16'bZ when idle, harmless here) and what it samples is
//      chip_dq, driven by the chip model at the bottom of this file.
//    - The block-local registers of the main always block are declared at
//      module scope instead; see the note there.
//    - The altddio_out that forwards the (inverted) clock to the chip is gone;
//      the chip model samples the controller's registered command one clk
//      later, which is where the inverted SDRAM_CLK edge lands.
//
//  Chip model: one 32 MB x16 SDR SDRAM, CAS latency 3, sequential burst 2,
//  single-word writes, DQM byte masks on A[12:11] -- the mode sdram2.sv
//  programs. A READ registered at clk edge k (command <= CMD_READ) makes word 0
//  land in dq_reg at edge k+4 and word 1 at k+5, which is exactly when the
//  controller's data_*_ready_delay taps say the data is there.
//============================================================================
module sdram_32r8w
(
	input             init,        // reset to initialize RAM
	input             clk,         // clock ~100MHz

//	CPU R/W port
	input      [24:0] sdram_cpu_addr,  // 25 bit address for 8bit mode.
	output     [15:0] sdram_dout,      // data output to cpu [for both ports]
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

reg [15:0] SDRAM_DQ;
reg [12:0] SDRAM_A;
reg  [1:0] SDRAM_BA;
reg [15:0] chip_dq;


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

// In the original these are declared inside the always block below, with
// `state` initialised there. Verilator (5.044) re-applies a block-local
// initialiser every time the block runs, so `state` was forced back to
// STATE_STARTUP on every clock and no request was ever served. At module scope
// the initialiser runs once, as Quartus treats it.
reg [CAS_LATENCY+BURST_LENGTH:0] data_cpu_ready_delay;
reg [CAS_LATENCY+BURST_LENGTH:0] data_vid_ready_delay;

reg        saved_wr;
reg        saved_vid;
reg [12:0] cas_addr;
reg [31:0] saved_data;
reg  [4:0] state = STATE_STARTUP;

always @(posedge clk) begin

	refresh_count <= refresh_count + 1'b1;

	data_vid_ready_delay[CAS_LATENCY+BURST_LENGTH] <= 0;

	data_cpu_ready_delay[CAS_LATENCY+BURST_LENGTH] <= 0;

	data_cpu_ready_delay <= data_cpu_ready_delay>>1;
	data_vid_ready_delay <= data_vid_ready_delay>>1;

	dq_reg <= chip_dq;

//	if(data_ready_delay[1]) sdram_ldout[15:00] <= dq_reg;
//	if(data_ready_delay[0]) sdram_ldout[31:16] <= dq_reg;

	sdram_cpu_ready <= 1'b0;
	sdram_vid_ready <= 1'b0;
	
	if (data_cpu_ready_delay[2]) sdram_cpu_ready <= 1'b1; // Data valid for the first 16 bits
	if (data_cpu_ready_delay[1]) sdram_busy <= 1'b0; 

	if (data_vid_ready_delay[2]) sdram_vid_ready <= 1'b1; // Data valid for the first 16 bits
	if (data_vid_ready_delay[1]) sdram_vid_ready <= 1'b1; // Data valid for the second 16 bits

	if (data_vid_ready_delay[0]) sdram_busy <= 1'b0;


	SDRAM_DQ <= 16'h0000;   // was 16'bZ: the bus is not tristated here

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

//----------------------------------------------------------------------------
// SDR SDRAM chip model
//----------------------------------------------------------------------------
reg [15:0] chip_mem [0:(1<<24)-1];
reg [12:0] chip_row [0:3];

reg        rd_p1, rd_p2, rd_w1;
reg [23:0] rd_a1, rd_a2, rd_aw;

wire [23:0] cmd_addr = {SDRAM_BA, chip_row[SDRAM_BA], SDRAM_A[8:0]};

always @(posedge clk) begin
	case (command)
		3'b011: chip_row[SDRAM_BA] <= SDRAM_A;              // ACTIVE
		3'b100: begin                                       // WRITE
			if (!SDRAM_A[11]) chip_mem[cmd_addr][7:0]  <= SDRAM_DQ[7:0];
			if (!SDRAM_A[12]) chip_mem[cmd_addr][15:8] <= SDRAM_DQ[15:8];
		end
		default: ;
	endcase

	// READ: two pipeline stages, then word 0 and word 1 on consecutive edges.
	rd_p1 <= (command == 3'b101);
	rd_a1 <= cmd_addr;
	rd_p2 <= rd_p1;
	rd_a2 <= rd_a1;
	rd_w1 <= rd_p2;
	rd_aw <= {rd_a2[23:1], ~rd_a2[0]};                      // burst 2, sequential

	if (rd_p2)      chip_dq <= chip_mem[rd_a2];
	else if (rd_w1) chip_dq <= chip_mem[rd_aw];
	else            chip_dq <= 16'h0000;
end

endmodule
