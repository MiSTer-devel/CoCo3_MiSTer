//============================================================================
//  Verilog conversions of the CoCo3 ROM entities in rtl/rom/*.vhd.
//
//  Line-for-line translations: same entity names, same ports, same clocking.
//  The three loadable ROMs are single-clock RAMs filled over ioctl; while a
//  write is in progress the read register holds its previous value, exactly as
//  the VHDL `if WRITE = '1' ... else DATA <= ...` does.
//============================================================================

// rtl/rom/coco_rom_32K.vhd -- CoCo3 system ROM (boot0.rom, ioctl index 0)
module COCO_ROM_32K
(
	input      [14:0] ADDR,
	output reg  [7:0] DATA,
	input             CLK,
	input      [14:0] WR_ADDR,
	input       [7:0] WR_DATA,
	input             WRITE
);
reg [7:0] ROM [0:32767];
always @(posedge CLK) begin
	if (WRITE) ROM[WR_ADDR] <= WR_DATA;
	else       DATA <= ROM[ADDR];
end
endmodule

// rtl/rom/coco_rom_8K.vhd -- Disk BASIC ROM (boot1.rom, ioctl index 64)
module COCO_ROM_8K
(
	input      [12:0] ADDR,
	output reg  [7:0] DATA,
	input             CLK,
	input      [12:0] WR_ADDR,
	input       [7:0] WR_DATA,
	input             WRITE
);
reg [7:0] ROM [0:8191];
always @(posedge CLK) begin
	if (WRITE) ROM[WR_ADDR] <= WR_DATA;
	else       DATA <= ROM[ADDR];
end
endmodule

// rtl/rom/coco_rom_cart.vhd -- Program Pak, up to 128K (ioctl index 1)
module COCO_ROM_CART
(
	input      [16:0] ADDR,
	output reg  [7:0] DATA,
	input             CLK,
	input      [16:0] WR_ADDR,
	input       [7:0] WR_DATA,
	input             WRITE
);
reg [7:0] ROM [0:131071];
always @(posedge CLK) begin
	if (WRITE) ROM[WR_ADDR] <= WR_DATA;
	else       DATA <= ROM[ADDR];
end
endmodule

// rtl/rom/coco_rom_16.vhd -- the AMW (automatic memory write) script: three
// {valid, a24..a0, data} records followed by a terminator. Asynchronous.
module COCO_ROM_16
(
	input       [3:0] ADDR,
	output reg  [7:0] DATA
);
always @(*) begin
	case (ADDR)
		// Clear $71 [Warm Start Flag]
		4'd0:  DATA = 8'h80;  4'd1:  DATA = 8'h07;  4'd2:  DATA = 8'h00;
		4'd3:  DATA = 8'h71;  4'd4:  DATA = 8'h00;
		// Set $C000 <- $55 [Clear D in DK identifier in rom]
		4'd5:  DATA = 8'h80;  4'd6:  DATA = 8'h07;  4'd7:  DATA = 8'hC0;
		4'd8:  DATA = 8'h00;  4'd9:  DATA = 8'h55;
		// Clear $72 [Warm Start Jump]
		4'd10: DATA = 8'h80;  4'd11: DATA = 8'h07;  4'd12: DATA = 8'h00;
		4'd13: DATA = 8'h72;  4'd14: DATA = 8'h00;
		// terminator
		default: DATA = 8'h00;
	endcase
end
endmodule

// rtl/rom/coco3_char_rom.vhd -- 4K font RAM, preloaded with the CoCo3 font
// (verilator/rtl/coco3_char_rom.mem, extracted from the VHDL by gen_mem.py).
// Separate write and registered-read clocks, as in the VHDL.
module coco3_Char_ROM
(
	input             RD_CLK,
	input      [11:0] ADDR_R,
	output reg  [7:0] DATA_R,
	input             WR_CLK,
	input             WE,
	input      [11:0] ADDR_W,
	input       [7:0] DATA_W
);
reg [7:0] RAM [0:4095];
initial $readmemh("rtl/coco3_char_rom.mem", RAM);
always @(posedge WR_CLK) if (WE) RAM[ADDR_W] <= DATA_W;
always @(posedge RD_CLK) DATA_R <= RAM[ADDR_R];
endmodule
