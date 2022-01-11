//============================================================================
//  CoCo RTC
//  by Stan Hodge - stan.pda@gmail.com
//
//	Based on:
//  RTC DS1307
//  Copyright (C) 2021 Alexey Melnikov
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module rtc #(parameter CLOCK_RATE)
(
	input        clk,

	input [64:0] RTC,

	output[4:0]	 O_CENT,
	output[6:0]	 O_YEAR,
	output[3:0]	 O_MNTH,
	output[4:0]	 O_DMTH,
	output[2:0]	 O_DWK,
	output[4:0]	 O_HOUR,
	output[5:0]	 O_MIN,
	output[5:0]	 O_SEC
);

localparam SEC  = 0;
localparam MIN  = 1;
localparam HR   = 2;
localparam DAY  = 3;
localparam DATE = 4;
localparam MON  = 5;
localparam YEAR = 6;
localparam CTL  = 7;

reg  [7:0] data[8];
reg        flg = 0;
reg [31:0] seccnt = 1;


assign O_CENT = 5'd20;
assign O_YEAR = (4'd10 * data[YEAR][7:4]) + data[YEAR][3:0];
assign O_MNTH = (4'd10 * data[MON][6:4]) + data[MON][3:0];
assign O_DMTH = (4'd10 * data[DATE][6:4]) + data[DATE][3:0];
assign O_DWK  = data[DAY][2:0];
assign O_HOUR = (4'd10 * data[HR][6:4]) + data[HR][3:0];
assign O_MIN  = (4'd10 * data[MIN][6:4]) + data[MIN][3:0];
assign O_SEC  = (4'd10 * data[SEC][6:4]) + data[SEC][3:0];



always @(posedge clk) 
begin

	seccnt <= seccnt + 1;
	if(seccnt >= CLOCK_RATE)
	begin
		seccnt <= 1;
		if(!data[SEC][7])
		begin
			if (data[SEC][3:0] != 9)
				data[SEC][3:0] <= data[SEC][3:0] + 1'd1;
			else
			begin
				data[SEC][3:0] <= 0;
				if (data[SEC][6:4] != 5)
					data[SEC][6:4] <= data[SEC][6:4] + 1'd1;
				else
				begin
					data[SEC][6:4] <= 0;
					if (data[MIN][3:0] != 9)
						data[MIN][3:0] <= data[MIN][3:0] + 1'd1;
					else
					begin
						data[MIN][3:0] <= 0;
						if (data[MIN][6:4] != 5) 
							data[MIN][6:4] <= data[MIN][6:4] + 1'd1;
						else
						begin
							data[MIN][6:4] <= 0;
							if (data[HR][3:0] == 9)
							begin
								data[HR][3:0] <= 0;
								data[HR][5:4] <= data[HR][5:4] + 1'd1;
							end
							else
								data[HR][3:0] <= data[HR][3:0] + 1'd1;
							if (data[HR][6:0] == {3'd2,4'd3})
							begin
								data[HR][3:0] <= 4'd0;
								data[HR][6:4] <= 3'd0;

								data[DAY] <= &data[DAY][2:0] ? 8'd1 : (data[DAY][2:0] + 1'd1);

								if (({data[MON], data[DATE]} == (({data[YEAR][4],1'b0} + data[YEAR][1:0]) ? 16'h0228 : 16'h0229)) ||
									 ({data[MON], data[DATE]} == 16'h0430) ||
									 ({data[MON], data[DATE]} == 16'h0630) ||
									 ({data[MON], data[DATE]} == 16'h0930) ||
									 ({data[MON], data[DATE]} == 16'h1130) ||
									 (data[DATE] == 8'h31)) 
								begin
									data[DATE][5:0] <= 1;
									if (data[MON][3:0] == 9)
										data[MON][4:0] <= 'h10;
									else if (data[MON][4:0] != 5'h12)
										data[MON][3:0] <= data[MON][3:0] + 1'd1;
									else
									begin 
										data[MON][4:0] <= 5'h1;
										if (data[YEAR][3:0] != 9) 
											data[YEAR][3:0] <= data[YEAR][3:0] + 1'd1;
										else
										begin
											data[YEAR][3:0] <= 0;
											if (data[YEAR][7:4] != 9)
												data[YEAR][7:4] <= data[YEAR][7:4] + 1'd1;
											else
												data[YEAR][7:4] <= 0;
										end
									end
								end
								else if (data[DATE][3:0] != 9)
									data[DATE][3:0] <= data[DATE][3:0] + 1'd1;
								else 
								begin
									data[DATE][3:0] <= 0;
									data[DATE][5:4] <= data[DATE][5:4] + 1'd1;
								end
							end
						end
					end
				end
			end
		end
	end

	flg <= RTC[64];
	if (flg != RTC[64])
	begin
		data[SEC]  <= RTC[6:0];
		data[MIN]  <= RTC[15:8];
		data[HR]   <= RTC[21:16];
		data[DAY]  <= RTC[55:48] + 1'b1;
		data[DATE] <= RTC[31:24];
		data[MON]  <= RTC[39:32];
		data[YEAR] <= RTC[47:40];
		data[CTL]  <= 0;
		seccnt     <= 1;
	end  
end

endmodule
