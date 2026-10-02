// Verilog translation of rtl/OVO.vhd (the debug / "NO ROM" text overlay) for the
// simulation, since the simulator cannot read VHDL. Same ports, generics and timing: two
// cycles of video delay, probes latched at Hcount = Vcount = 0, 8x8 font.
//
// VHDL bit order: vin0/vin1 are (0 TO COLS*5-1), so character 0 is the
// leftmost 5 bits of in0/in1, i.e. the first entry of the concatenation in
// coco3fpga.sv; a font row's bit 0 is the leftmost pixel.

module ovo #(
	parameter COLS     = 32,
	parameter LINES    = 2,
	parameter RGB      = 24'hFFFFFF,
	parameter H_OFFSET = 4,
	parameter V_OFFSET = 45
) (
	input      [7:0]  i_r,
	input      [7:0]  i_g,
	input      [7:0]  i_b,
	input             i_clk,

	input      [10:0] i_Hcount,
	input      [9:0]  i_VCount,

	output reg [7:0]  o_r,
	output reg [7:0]  o_g,
	output reg [7:0]  o_b,

	input             ena,

	input  [COLS*5-1:0] in0,
	input  [COLS*5-1:0] in1
);

localparam N = COLS*5;

reg [7:0] chars [0:255];
initial begin
	{chars[  0],chars[  1],chars[  2],chars[  3],chars[  4],chars[  5],chars[  6],chars[  7]} = 64'h3E63737B6F673E00;	// 0
	{chars[  8],chars[  9],chars[ 10],chars[ 11],chars[ 12],chars[ 13],chars[ 14],chars[ 15]} = 64'h0C0E0C0C0C0C3F00;	// 1
	{chars[ 16],chars[ 17],chars[ 18],chars[ 19],chars[ 20],chars[ 21],chars[ 22],chars[ 23]} = 64'h1E33301C06333F00;	// 2
	{chars[ 24],chars[ 25],chars[ 26],chars[ 27],chars[ 28],chars[ 29],chars[ 30],chars[ 31]} = 64'h1E33301C30331E00;	// 3
	{chars[ 32],chars[ 33],chars[ 34],chars[ 35],chars[ 36],chars[ 37],chars[ 38],chars[ 39]} = 64'h383C36337F307800;	// 4
	{chars[ 40],chars[ 41],chars[ 42],chars[ 43],chars[ 44],chars[ 45],chars[ 46],chars[ 47]} = 64'h3F031F3030331E00;	// 5
	{chars[ 48],chars[ 49],chars[ 50],chars[ 51],chars[ 52],chars[ 53],chars[ 54],chars[ 55]} = 64'h1C06031F33331E00;	// 6
	{chars[ 56],chars[ 57],chars[ 58],chars[ 59],chars[ 60],chars[ 61],chars[ 62],chars[ 63]} = 64'h3F3330180C0C0C00;	// 7
	{chars[ 64],chars[ 65],chars[ 66],chars[ 67],chars[ 68],chars[ 69],chars[ 70],chars[ 71]} = 64'h1E33331E33331E00;	// 8
	{chars[ 72],chars[ 73],chars[ 74],chars[ 75],chars[ 76],chars[ 77],chars[ 78],chars[ 79]} = 64'h1E33333E30180E00;	// 9
	{chars[ 80],chars[ 81],chars[ 82],chars[ 83],chars[ 84],chars[ 85],chars[ 86],chars[ 87]} = 64'h0C1E33333F333300;	// A
	{chars[ 88],chars[ 89],chars[ 90],chars[ 91],chars[ 92],chars[ 93],chars[ 94],chars[ 95]} = 64'h3F66663E66663F00;	// B
	{chars[ 96],chars[ 97],chars[ 98],chars[ 99],chars[100],chars[101],chars[102],chars[103]} = 64'h3C66030303663C00;	// C
	{chars[104],chars[105],chars[106],chars[107],chars[108],chars[109],chars[110],chars[111]} = 64'h1F36666666361F00;	// D
	{chars[112],chars[113],chars[114],chars[115],chars[116],chars[117],chars[118],chars[119]} = 64'h7F46161E16467F00;	// E
	{chars[120],chars[121],chars[122],chars[123],chars[124],chars[125],chars[126],chars[127]} = 64'h7F46161E16060F00;	// F
	{chars[128],chars[129],chars[130],chars[131],chars[132],chars[133],chars[134],chars[135]} = 64'h0000000000000000;	// ' ' 10
	{chars[136],chars[137],chars[138],chars[139],chars[140],chars[141],chars[142],chars[143]} = 64'h00003F00003F0000;	// =  11
	{chars[144],chars[145],chars[146],chars[147],chars[148],chars[149],chars[150],chars[151]} = 64'h000C0C3F0C0C0000;	// +  12
	{chars[152],chars[153],chars[154],chars[155],chars[156],chars[157],chars[158],chars[159]} = 64'h0000003F00000000;	// -  13
	{chars[160],chars[161],chars[162],chars[163],chars[164],chars[165],chars[166],chars[167]} = 64'h180C0603060C1800;	// <  14
	{chars[168],chars[169],chars[170],chars[171],chars[172],chars[173],chars[174],chars[175]} = 64'h060C1830180C0600;	// >  15
	{chars[176],chars[177],chars[178],chars[179],chars[180],chars[181],chars[182],chars[183]} = 64'h081C366341000000;	// ^  16
	{chars[184],chars[185],chars[186],chars[187],chars[188],chars[189],chars[190],chars[191]} = 64'h081C366341000000;	// v  17
	{chars[192],chars[193],chars[194],chars[195],chars[196],chars[197],chars[198],chars[199]} = 64'h180C0606060C1800;	// (  18
	{chars[200],chars[201],chars[202],chars[203],chars[204],chars[205],chars[206],chars[207]} = 64'h060C1818180C0600;	// )  19
	{chars[208],chars[209],chars[210],chars[211],chars[212],chars[213],chars[214],chars[215]} = 64'h000C0C00000C0C00;	// :  1A
	{chars[216],chars[217],chars[218],chars[219],chars[220],chars[221],chars[222],chars[223]} = 64'h4143454951614100;	// N  1B
	{chars[224],chars[225],chars[226],chars[227],chars[228],chars[229],chars[230],chars[231]} = 64'h3E41414141413E00;	// O  1C
	{chars[232],chars[233],chars[234],chars[235],chars[236],chars[237],chars[238],chars[239]} = 64'h3F41413F11214100;	// R  1D
	{chars[240],chars[241],chars[242],chars[243],chars[244],chars[245],chars[246],chars[247]} = 64'h4163554941414100;	// M  1E
	{chars[248],chars[249],chars[250],chars[251],chars[252],chars[253],chars[254],chars[255]} = 64'h36367F367F363600;	// #  1F
end

reg [N-1:0] in0s, in1s, vin0, vin1;
reg [7:0]   t_r, t_g, t_b;
reg [11:0]  hcpt, hcpt2, vcpt;
reg [7:0]   col;

wire [N-1:0] vin_v  = vcpt[3] ? vin1 : vin0;			// (vcpt/8) mod 2
wire [11:0]  cidx   = hcpt >> 3;
wire [4:0]   char_v = (hcpt < COLS*8 && vcpt < LINES*8) ? vin_v[N-1-cidx*5 -: 5] : 5'b10000;

always @(posedge i_clk) begin
	in0s <= in0;
	in1s <= in1;

	t_r <= i_r;
	t_g <= i_g;
	t_b <= i_b;

	if (i_Hcount == 0 && i_VCount == 0) begin
		vin0 <= in0s;
		vin1 <= in1s;
	end

	hcpt  <= (i_Hcount < H_OFFSET) ? COLS*8 : {1'b0, i_Hcount} - H_OFFSET;
	vcpt  <= (i_VCount < V_OFFSET) ? 12'd512 : {2'b0, i_VCount} - V_OFFSET;
	hcpt2 <= hcpt;

	col <= chars[{char_v, vcpt[2:0]}];

	if (ena && col[hcpt2[2:0]]) begin
		o_r <= RGB[23:16];
		o_g <= RGB[15:8];
		o_b <= RGB[7:0];
	end else begin
		o_r <= t_r;
		o_g <= t_g;
		o_b <= t_b;
	end
end

endmodule
