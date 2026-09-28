//============================================================================
//  Simulation stand-in for rtl/VDAC.v (an altsyncram megafunction).
//
//  Same ports and the configuration the megafunction declares: DUAL_PORT,
//  256 x 16, write on wrclock, address AND output registered on rdclock
//  (address_reg_b = outdata_reg_b = CLOCK1), so q lags rdaddress by two
//  rdclock edges. Preloaded from rtl/VDAC.mif via verilator/rtl/vdac.mem.
//============================================================================
module VDAC
(
	input      [15:0] data,
	input       [7:0] rdaddress,
	input             rdclock,
	input       [7:0] wraddress,
	input             wrclock,
	input             wren,
	output reg [15:0] q
);
reg [15:0] mem [0:255];
reg  [7:0] rd_a;
initial $readmemh("rtl/vdac.mem", mem);
always @(posedge wrclock) if (wren) mem[wraddress] <= data;
always @(posedge rdclock) begin
	rd_a <= rdaddress;
	q    <= mem[rd_a];
end
endmodule
