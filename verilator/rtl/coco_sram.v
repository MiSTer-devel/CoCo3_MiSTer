//============================================================================
//  Verilog conversions of rtl/sram/*.vhd: synchronous write, asynchronous
//  read, matching the VHDL (`DATA_O <= SRAM(ADDR)` outside the process).
//============================================================================

// rtl/sram/coco_ram.vhd -- 64K cassette buffer (R_W low = write)
module COCO_SRAM
(
	input             CLK,
	input      [15:0] ADDR,
	input             R_W,
	input       [7:0] DATA_I,
	output      [7:0] DATA_O
);
reg [7:0] SRAM [0:65535];
always @(posedge CLK) if (!R_W) SRAM[ADDR] <= DATA_I;
assign DATA_O = SRAM[ADDR];
endmodule

// rtl/sram/coco_vid_ram_buf.vhd -- 512 x 16 video line buffer
module COCO_VID_RAM_BUF
(
	input             CLK,
	input       [8:0] ADDR_I,
	input       [8:0] ADDR_O,
	input             WE,
	input      [15:0] DATA_I,
	output     [15:0] DATA_O
);
reg [15:0] SRAM [0:511];
always @(posedge CLK) if (WE) SRAM[ADDR_I] <= DATA_I;
assign DATA_O = SRAM[ADDR_O];
endmodule
