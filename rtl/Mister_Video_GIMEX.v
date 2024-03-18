////////////////////////////////////////////////////////////////////////////////
// Project Name: CoCo3FPGA Version 4.0
// File Name:  coco3fpga.v
//
// CoCo3 in an FPGA
//
// Revision: 4.0 07/10/16
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent
// The FDC co-processor copyrighted Daniel Wallner.
// SDRAM Controller copyrighted by XESS Corp.
//
////////////////////////////////////////////////////////////////////////////////
//
// Only supports 320 bytes per line x 1 line and 640 bytes per line x 2 lines
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 4.0
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
// The latest version of this file can be found at:
//      http://groups.yahoo.com/group/CoCo3FPGA
//
// File history :
//
//  1.0   Full Release
//  2.0   Partial Release
//  3.0   Full Release
//  3.0.0.1  Update to fix DoD interrupt issue
// 3.0.1.0  Update to fix 32/40 CoCO3 Text issue and add 2 Meg max memory
// 4.0.X.X  Full Release
////////////////////////////////////////////////////////////////////////////////
// Gary Becker
// gary_L_becker@yahoo.com
////////////////////////////////////////////////////////////////////////////////
`define	MiSTer_CoCo3

module COCO3VIDEO_GIMEX(
PIX_CLK,      // 14.31818MHz
RESET_N,
COLOR,
HSYNC_N,
VSYNC_N,
BUFF_ADD_F,
RAM_DATA,
RAM_ADD,
COCO1,
V,
BP,
VERT,
VID_CONT,
CSS,
LPF,
VERT_FIN_SCRL,
HLPR,
LPR,
HRES,
CRES,
HVEN,
SCRN_START_HSB,
SCRN_START_MSB,
SCRN_START_LSB,
`ifdef MiSTer_CoCo3
SWITCH,
`endif
BLINK,
ARTI,
PHASE,
HBORDER,
`ifdef MiSTer_CoCo3
VBORDER,
`endif
HBORDER_INT,
VBORDER_INT,
DOUBLE,
BUFF_BANK,
TURBO,
SDRate,
ROM_ADDRESS,
ROM_DATA1
//ROM_DATA2
);

input           PIX_CLK;
input           RESET_N;
output  [9:0]   COLOR;
reg     [9:0]   COLOR;
output          HSYNC_N;
reg             HSYNC_N;
output          VSYNC_N;
reg             VSYNC_FLAG;
output  [9:0]   BUFF_ADD_F;
reg     [9:0]   BUFF_ADD_F;
output  [24:0]  RAM_ADD;
input   [15:0]  RAM_DATA;
input           COCO1;
input   [2:0]   V;
input           BP;
input   [6:0]   VERT;
input   [3:0]   VID_CONT;
input           CSS;
input   [1:0]   LPF;
input           HLPR;
input   [2:0]   LPR;
input   [3:0]   VERT_FIN_SCRL;
input   [3:0]   HRES;
input   [1:0]   CRES;
input           HVEN;
input   [5:0]   SCRN_START_HSB;  // 6 extra bits for 32MB screen start highest always 0 as no way to set it
input   [7:0]   SCRN_START_MSB;
input   [7:0]   SCRN_START_LSB;
`ifdef MiSTer_CoCo3
input			SWITCH;
`endif
input           BLINK;
input   [1:0]   ARTI;
input           PHASE;
output          DOUBLE;
reg             DOUBLE;
output          BUFF_BANK;
reg             BUFF_BANK;
input           TURBO;
input           SDRate;
output          HBORDER;
reg             HBORDER;
output          HBORDER_INT;
reg             HBORDER_INT;
output          VBORDER_INT;
reg             VBORDER_INT;
output  [10:0]  ROM_ADDRESS;
reg     [10:0]  ROM_ADDRESS;
input   [7:0]   ROM_DATA1;
//input       [7:0]   ROM_DATA2;
`ifdef MiSTer_CoCo3
output			VBORDER;
reg				VBORDER;
`else
reg             VBORDER;
`endif
reg     [8:0]   LINE;
reg     [3:0]   VLPR;
reg     [10:0]  PIXEL_COUNT;
reg     [15:0]  CHAR_LATCH_0;
reg     [15:0]  CHAR_LATCH_1;
reg     [15:0]  CHAR_LATCH_2;
reg     [15:0]  CHAR_LATCH_3;
reg     [15:0]  CHAR_LATCH_4;
reg     [15:0]  CHAR_LATCH_5;
reg     [15:0]  CHAR_LATCH_6;
reg     [15:0]  CHAR_LATCH_7;
wire    [3:0]   PIXEL_ORDER;
reg             HBLANKING;
reg             VBLANKING;
reg     [7:0]   CHARACTER0;
reg     [7:0]   CHARACTER1;
reg     [7:0]   CHARACTER2;
wire    [7:0]   CHARACTER3;
wire    [7:0]   CHARACTER4;
reg             UNDERLINE;
wire            MODE_256;
wire    [8:0]   BUF_ADD;

wire    [3:0]   LINES_ROW;
wire            SIX;
wire    [1:0]   SG6;
wire    [7:0]   PIXEL0;
wire    [7:0]   PIXEL1;
wire    [7:0]   PIXEL2;
wire    [7:0]   PIXEL3;
wire    [7:0]   PIXEL4;
wire    [7:0]   PIXEL5;
wire    [7:0]   PIXEL6;
wire    [7:0]   PIXEL7;
wire    [7:0]   PIXEL8;
wire    [7:0]   PIXEL9;
wire    [7:0]   PIXELA;
wire    [7:0]   PIXELB;
wire    [7:0]   PIXELC;
wire    [7:0]   PIXELD;
wire    [7:0]   PIXELE;
wire    [7:0]   PIXELF;
reg     [15:0]  COLOR0;
reg     [15:0]  COLOR1;
reg     [15:0]  COLOR2;
reg     [15:0]  COLOR3;
reg     [15:0]  COLOR4;
reg     [15:0]  COLOR5;
reg     [15:0]  COLOR6;
reg     [15:0]  COLOR7;
reg     [16:0]  ROW_ADD;    // Max ROW_ADD / SCREEN_OFF is 225 * 256
wire    [16:0]  OFFSET;
wire    [9:0]   BORDER;
wire    [9:0]   CCOLOR;
reg     [2:0]   INC;
reg     [6:0]   SYNC_COUNT;
wire            VSYNC_CLK;
reg     [139:0] VSYNC_DELAY;
reg     [24:0]  SCREEN_START_ADD;
reg             FIRST;
wire    [3:0]   SG_VLPR;
wire            SG6_ENABLE;
reg     [1:0]   HISTORY;
reg     [1:0]   FUTURE;
reg             RD_BUFF_BANK;
reg             LAST;
reg             VBLANKING_FLAG;

/*
// Character generator
COCO3GEN coco3gen(
.address(ROM_ADDRESS[10:0]),
.clock(PIX_CLK),
.q(ROM_DATA1)
);
COCO3GEN2 coco3gen2(
.address(ROM_ADDRESS[10:0]),
.clock(PIX_CLK),
.q(ROM_DATA2)
);
*/
/*****************************************************************************
SCREEN_START_ADD is set only on the start of HBorder on the last line that VBlanking on
ROW_ADD is chaned at the start of the verticle border
Row_OFFSET calculates the next ROW_ADD
******************************************************************************/
assign RAM_ADD = SCREEN_START_ADD + ROW_ADD;
/*
CR 64  = 16
GR 128 = 16
CR 128 = 32
GR 256 = 32
*/
assign OFFSET =
// CoCo1 low res graphics
({HVEN,COCO1,VID_CONT[3],V[0]} == 4'b0111)     ? ROW_ADD + 11'd16:  // WHEN V[0]=1 16 BYTES V[0]=0 32 BYTES
//HR Text
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}==6'b0000000) ? ROW_ADD + 11'd32:  // XTEXT
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}==6'b0000001) ? ROW_ADD + 11'd40:  // XTEXT
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}==6'b0000010) ? ROW_ADD + 11'd64:
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}==6'b0000011) ? ROW_ADD + 11'd80:
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}==6'b0000100) ? ROW_ADD + 11'd64:  // XTEXT
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}==6'b0000101) ? ROW_ADD + 11'd80:  // XTEXT
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}==6'b0000110) ? ROW_ADD + 11'd128:
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}==6'b0000111) ? ROW_ADD + 11'd160:
//HR Graphics
      ({HVEN,COCO1,BP,HRES}==7'b0010000)  ? ROW_ADD + 11'd16:
      ({HVEN,COCO1,BP,HRES}==7'b0010001)  ? ROW_ADD + 11'd20:
      ({HVEN,COCO1,BP,HRES}==7'b0010010)  ? ROW_ADD + 11'd32:
      ({HVEN,COCO1,BP,HRES}==7'b0010011)  ? ROW_ADD + 11'd40:
      ({HVEN,COCO1,BP,HRES}==7'b0010100)  ? ROW_ADD + 11'd64:
      ({HVEN,COCO1,BP,HRES}==7'b0010101)  ? ROW_ADD + 11'd80:
      ({HVEN,COCO1,BP,HRES}==7'b0010110)  ? ROW_ADD + 11'd128:
      ({HVEN,COCO1,BP,HRES}==7'b0010111)  ? ROW_ADD + 11'd160:
//Graphics greater than 160 bytes / row
      ({HVEN,COCO1,BP,HRES}==7'b0011000) ? ROW_ADD + 11'd256:
      ({HVEN,COCO1,BP,HRES}==7'b0011001) ? ROW_ADD + 11'd320:
      ({HVEN,COCO1,BP,HRES}==7'b0011010) ? ROW_ADD + 11'd512:
      ({HVEN,COCO1,BP,HRES}==7'b0011011) ? ROW_ADD + 11'd640:
// HVEN is Horizontal virtual enable, so each line is 256 bytes eventhough we real only 160 and display only 80
      ({HVEN, HRES[3]}==2'b10)    ?  ROW_ADD + 11'd256:
// 256 / 320 modes use 1024
      ({HVEN, HRES[3]}==2'b11)    ?  ROW_ADD + 11'd1024:
// CoCo1 Text
                   ROW_ADD + 11'd32;
/*****************************************************************************
* Read RAM
******************************************************************************/
assign BUF_ADD =                       //7 bits of two byte reads = 256 max bytes
// CoCo1 low res graphics (64 pixels / 2 bytes)
({COCO1,V[0]} == 2'b11)       ? {4'b0000, PIXEL_COUNT[10:6]}:   //16 bytes / line  Read 2 bytes every 64 pixels
// HR Text
({COCO1,BP,HRES[2],CRES[0]}==4'b0001)  ? {2'b00,  PIXEL_COUNT[10:4]}:   //32 / 40 characters / line  Read 2 bytes every 16 pixels
({COCO1,BP,HRES[2],CRES[0]}==4'b0010)  ? {2'b00,  PIXEL_COUNT[10:4]}:   //64 / 80 characters / line  Read 2 bytes every 16 pixels XTEXT
({COCO1,BP,HRES[2],CRES[0]}==4'b0011)  ? {2'b00,  PIXEL_COUNT[9:4], 1'b0}: //128/160 characters / line  Read 2 bytes every 8 pixels
// HR Graphics
({COCO1,BP,HRES}==6'b010000)     ? {4'b0000, PIXEL_COUNT[10:6]}:   //16 bytes / line (Graphics only)
({COCO1,BP,HRES}==6'b010001)     ? {4'b0000, PIXEL_COUNT[10:6]}:   //20 bytes / line (Graphics only)
({COCO1,BP,HRES}==6'b010100)     ? {2'b00,  PIXEL_COUNT[10:4]}:   //64 bytes / line
({COCO1,BP,HRES}==6'b010101)     ? {2'b00,  PIXEL_COUNT[10:4]}:   //80 bytes / line
({COCO1,BP,HRES}==6'b010110)     ? {2'b00,  PIXEL_COUNT[9:4], 1'b0}: //128 bytes / line
({COCO1,BP,HRES}==6'b010111)     ? {2'b00,  PIXEL_COUNT[9:4], 1'b0}: //160 bytes / line
({COCO1,BP,HRES}==6'b011000)     ? {1'b0,    PIXEL_COUNT[9:2]}:   //256 bytes / line
({COCO1,BP,HRES}==6'b011001)     ? {1'b0,      PIXEL_COUNT[9:2]}:   //320 bytes / line
({COCO1,BP,HRES}==6'b011010)     ? {        PIXEL_COUNT[9:1]}:   //512 bytes / line
({COCO1,BP,HRES}==6'b011011)     ? {        PIXEL_COUNT[9:1]}:   //640 bytes / line
// CoCo1 Text and SEMIGRAPHICS
               {3'b000,  PIXEL_COUNT[10:5]};   //32/40 bytes / line

// 16 pixel wide cell
// Minimum 1 read = 2 bytes
// Lores 16 mode = 1/2 character = 1/2 bytes = 1/4 read
// CoCo1 32 mode = 1 character  = 1 byte  = 1/2 read
// CoCo3 40 mode = 1 characters = 2 bytes  = 1 read
// CoCo3 80 mode = 2 characters = 4 bytes  = 2 reads
always @ (negedge PIX_CLK)
begin
  case (PIXEL_COUNT[3:0])
  4'b0000:
  begin
   BUFF_ADD_F <= {RD_BUFF_BANK, BUF_ADD};      // This will change the buffer half
//   CHAR_LATCH_7 <= RAM_DATA[15:0];
  end
  4'b0010:
  begin
   BUFF_ADD_F <= BUFF_ADD_F + 1'b1;
// 16-20 bytes / line = 1 read every 4 loops
   if(({PIXEL_COUNT[5:4]} !=2'b00)                  // First of 4 loops (2 bytes gives 64 pixels)
   &(({COCO1,V[0]}==2'b11)                     // CoCo1 16 byte/line mode
         |({COCO1,BP,HRES[3],HRES[2],HRES[1]}==5'b01000)))            // CoCo3 16/20 bytes/line mode
   begin
    CHAR_LATCH_0 <= {CHAR_LATCH_0[11:8],4'h0,CHAR_LATCH_0[3:0],CHAR_LATCH_0[15:12]}; // Rotate into position on 16/20 bytes/line
   end
   else
   begin
// 32-40 bytes / line = 1 read every 2 loops
    if(PIXEL_COUNT[4]                      // Every other loop (2 bytes gives 32 pixels)
    &((COCO1)                        // All other CoCo1 modes
    |({COCO1,BP,HRES[3],HRES[2],CRES[0]}==5'b00000)            // CoCo3 32/40 XText
    |({COCO1,BP,HRES[3],HRES[2],HRES[1]}==5'b01001)))           // CoCo3 32/40 bytes/line
    begin
     CHAR_LATCH_0 <= {8'h00,CHAR_LATCH_0[15:8]};
     HISTORY <= CHAR_LATCH_0[1:0];
     FUTURE <= CHAR_LATCH_1[7:6];
    end
    else
    begin
// 64-160 bytes / line = 1-2 reads / loop or when others need to read
     CHAR_LATCH_0 <= RAM_DATA[15:0];
     FUTURE <= RAM_DATA[15:14];
     if (HBLANKING)
      HISTORY <= {VID_CONT[3],VID_CONT[3]};
     else
      HISTORY <= CHAR_LATCH_0[1:0];
    end
   end
  end
  4'b0011:
  begin
   if(!COCO1)
    ROM_ADDRESS <= {CHAR_LATCH_0[6:0],VLPR};
   else
   begin
    if({VID_CONT[0],CHAR_LATCH_0[6:5]} == 3'b100)
     ROM_ADDRESS <= {2'b11, CHAR_LATCH_0[4:0], VLPR};       // COCO1 Text 1 with LC
    else
     ROM_ADDRESS <= {~CHAR_LATCH_0[5], CHAR_LATCH_0[5:0], VLPR};   // COCO1 Text 1 w/o LC
   end
  end
  4'b0100:
  begin
   CHAR_LATCH_1 <= RAM_DATA[15:0];                  // Only needed by 2 reads / loop
   BUFF_ADD_F <= BUFF_ADD_F + 1'b1;
  end
  4'b0110:
  begin
   CHAR_LATCH_2 <= RAM_DATA[15:0];                  // Only needed by 2 reads / loop
   BUFF_ADD_F <= BUFF_ADD_F + 1'b1;
// Underline
   if({COCO1,CRES[0],CHAR_LATCH_0[14],UNDERLINE} == 4'b0111)
    CHARACTER0 <= 8'hFF;
// Not Underline
   else
//    if(COCO1)
//     CHARACTER0 <= ROM_DATA2;
//    else
     CHARACTER0 <= ROM_DATA1;
   ROM_ADDRESS <= {CHAR_LATCH_0[14:8],VLPR};
  end
  4'b1000:
  begin
   CHAR_LATCH_3 <= RAM_DATA[15:0];                // Only needed by 2 reads / loop
   BUFF_ADD_F <= BUFF_ADD_F + 1'b1;
  end
  4'b1010:
  begin
   CHAR_LATCH_4 <= RAM_DATA[15:0];                // Only needed by 2 reads / loop
   BUFF_ADD_F <= BUFF_ADD_F + 1'b1;
   CHARACTER1 <= ROM_DATA1;                  //XTEXT only, so no underline
   ROM_ADDRESS <= {CHAR_LATCH_1[6:0],VLPR};
  end
  4'b1100:
  begin
   CHAR_LATCH_5 <= RAM_DATA[15:0];                // Only needed by 2 reads / loop
   BUFF_ADD_F <= BUFF_ADD_F + 1'b1;
  end
  4'b1101:
  begin
   CHAR_LATCH_6 <= RAM_DATA[15:0];                // Only needed by 2 reads / loop
   BUFF_ADD_F <= BUFF_ADD_F + 1'b1;
  end
  4'b1110:
  begin
// Underline
   if({COCO1,BP,CRES[0],CHAR_LATCH_1[14],UNDERLINE} == 5'b00111)
    CHARACTER2 <= 8'hFF;
   else
// Not Underline
    CHARACTER2 <= ROM_DATA1;
   CHAR_LATCH_7 <= RAM_DATA[15:0];                // Only needed by 2 reads / loop
//   BUFF_ADD_F <= BUFF_ADD_F + 1'b1;
  end
  endcase
end

assign CHARACTER3 = ({COCO1,BP,CRES[0],CHAR_LATCH_0[15],BLINK} == 5'b00111) ? 8'h00:    // Hires Text blink
       ({COCO1, VID_CONT[1:0], CHAR_LATCH_0[6:5]} == 5'b10000) ? ~CHARACTER0:  // Lowres  0-31 Normal UC only (Inverse)
       ({COCO1, VID_CONT[1:0], CHAR_LATCH_0[6:5]} == 5'b10001) ? ~CHARACTER0:  // Lowres 32-64 Normal UC only (Inverse)
       ({COCO1, VID_CONT[1:0], CHAR_LATCH_0[6:5]} == 5'b10101) ? ~CHARACTER0:  // Lowres 32-64 LC but UC part (Inverse)
       ({COCO1, VID_CONT[1:0], CHAR_LATCH_0[6:5]} == 5'b11010) ? ~CHARACTER0:  // Lowres 64-95 Inverse
       ({COCO1, VID_CONT[1:0], CHAR_LATCH_0[6:5]} == 5'b11011) ? ~CHARACTER0:  // Lowres 96-128 Inverse
       ({COCO1, VID_CONT[1:0], CHAR_LATCH_0[6:5]} == 5'b11100) ? ~CHARACTER0:  // Lowres  0-31 Inverse
       ({COCO1, VID_CONT[1:0], CHAR_LATCH_0[6:5]} == 5'b11110) ? ~CHARACTER0:  // Lowres 64-95 Inverse
       ({COCO1, VID_CONT[1:0], CHAR_LATCH_0[6:5]} == 5'b11111) ? ~CHARACTER0:  // Lowres 96-128 Inverse
                            CHARACTER0;  // Normal Video

assign CHARACTER4 = ({COCO1,BP,CRES[0],CHAR_LATCH_1[15],BLINK} == 5'b00111) ? 8'h00:    // Hires Text blink 80 only
                           CHARACTER2;  // Normal Video

function [3:0] messArtifactPalette(
 input [5:0] VGAPixel6_delay6,
 input       hcount_VGA,
 input       sw_artifact_swap);

 reg [3:0] color;
 reg [3:0] a0 = 4'h0;
 reg [3:0] a1;
 reg [3:0] a2;
 reg [3:0] a3;
 reg [3:0] a4;
 reg [3:0] a5;
 reg [3:0] a6;
 reg [3:0] a7;
 reg [3:0] a8;
 reg [3:0] a9;
 reg [3:0] a10;
 reg [3:0] a11;
 reg [3:0] a12;
 reg [3:0] a13;
 reg [3:0] a14;
 reg [3:0] a15 = 4'hF;

 if(!sw_artifact_swap) begin
  a1 = 4'h2;
  a2 = 4'h1;
  a3 = 4'h4;
  a4 = 4'h3;
  a5 = 4'h6;
  a6 = 4'h5;
  a7 = 4'h8;
  a8 = 4'h7;
  a9 = 4'hA;
  a10 = 4'h9;
  a11 = 4'hC;
  a12 = 4'hB;
  a13 = 4'hE;
  a14 = 4'hD;
 end else begin
  a1 = 4'h1;
  a2 = 4'h2;
  a3 = 4'h3;
  a4 = 4'h4;
  a5 = 4'h5;
  a6 = 4'h6;
  a7 = 4'h7;
  a8 = 4'h8;
  a9 = 4'h9;
  a10 = 4'hA;
  a11 = 4'hB;
  a12 = 4'hC;
  a13 = 4'hD;
  a14 = 4'hE;
 end
  
 casex({VGAPixel6_delay6[5:0], hcount_VGA})
  {6'b00000x, 1'bx}: color = a0;  // 0, 1
  
  {6'b000010, 1'b0}: color = a0;  // 2
  {6'b000010, 1'b1}: color = a6;

  {6'b000011, 1'b0}: color = a0;  // 3
  {6'b000011, 1'b1}: color = a2; 
  
  {6'b00010x, 1'b0}: color = a5;  // 4, 5
  {6'b00010x, 1'b1}: color = a7;
  
  {6'b000110, 1'b0}: color = a1;  // 6
  {6'b000110, 1'b1}: color = a3;

  {6'b000111, 1'b0}: color = a1;  // 7
  {6'b000111, 1'b1}: color = a11; 
  
  {6'b001000, 1'b0}: color = a8;  // 8
  {6'b001000, 1'b1}: color = a6;

  {6'b001001, 1'b0}: color = a8;  // 9  
  {6'b001001, 1'b1}: color = a14; 

  {6'b00101x, 1'b0}: color = a8;  // 10, 11
  {6'b00101x, 1'b1}: color = a9;

  {6'b001100, 1'bx}: color = a4;  // 12

  {6'b001101, 1'b0}: color = a4;  // 13
  {6'b001101, 1'b1}: color = a15;

  {6'b001110, 1'bx}: color = a12; // 14

  {6'b001111, 1'b0}: color = a12; // 15
  {6'b001111, 1'b1}: color = a15;
  
  
  
  {6'b01000x, 1'b0}: color = a5;  // 16, 17
  {6'b01000x, 1'b1}: color = a13;
  
  {6'b010010, 1'b0}: color = a13; // 18
  {6'b010010, 1'b1}: color = a0;
  
  {6'b010011, 1'b0}: color = a13; // 19
  {6'b010011, 1'b1}: color = a2;
  
  {6'b01010x, 1'bx}: color = a10; // 20, 21

  {6'b010110, 1'b0}: color = a10; // 22
  {6'b010110, 1'b1}: color = a15;
  
  {6'b010111, 1'b0}: color = a10; // 23
  {6'b010111, 1'b1}: color = a11;
  
  {6'b01100x, 1'b0}: color = a3;  // 24, 25
  {6'b01100x, 1'b1}: color = a1;

  {6'b01101x, 1'b0}: color = a15; // 26, 27
  {6'b01101x, 1'b1}: color = a9;
  
  {6'b01110x, 1'bx}: color = a11; // 28, 29
  
  {6'b01111x, 1'bx}: color = a15; // 30, 31
  

  
  {6'b10000x, 1'b0}: color = a14; // 32, 33
  {6'b10000x, 1'b1}: color = a0;
  
  {6'b100010, 1'b0}: color = a14; // 34
  {6'b100010, 1'b1}: color = a6;
  
  {6'b100011, 1'b0}: color = a14; // 35
  {6'b100011, 1'b1}: color = a2;

  {6'b10010x, 1'b0}: color = a0;  // 36, 37
  {6'b10010x, 1'b1}: color = a7;
  
  {6'b100110, 1'b0}: color = a1;  // 38
  {6'b100110, 1'b1}: color = a3;

  {6'b100111, 1'b0}: color = a1;  // 39
  {6'b100111, 1'b1}: color = a11;

  {6'b101000, 1'b0}: color = a9;  // 40
  {6'b101000, 1'b1}: color = a6;
  
  {6'b101001, 1'b0}: color = a9;  // 41
  {6'b101001, 1'b1}: color = a14;
  
  {6'b10101x, 1'bx}: color = a9;  // 42, 43

  {6'b101100, 1'b0}: color = a15; // 44
  {6'b101100, 1'b1}: color = a4;
  
  {6'b101101, 1'bx}: color = a15; // 45
  
  {6'b101110, 1'bx}: color = a12; // 46
  
  {6'b101111, 1'b0}: color = a12; // 47
  {6'b101111, 1'b1}: color = a15;

  
  
  {6'b11000x, 1'b0}: color = a2;  // 48, 49
  {6'b11000x, 1'b1}: color = a13;
  
  {6'b110010, 1'b0}: color = a2;  // 50
  {6'b110010, 1'b1}: color = a0;
  
  {6'b110011, 1'bx}: color = a2;  // 51
  
  {6'b11010x, 1'bx}: color = a10; // 52, 53

  {6'b110110, 1'b0}: color = a10; // 54
  {6'b110110, 1'b1}: color = a15;
  
  {6'b110111, 1'b0}: color = a10; // 55
  {6'b110111, 1'b1}: color = a11;
  
  {6'b11100x, 1'b0}: color = a12; // 56, 57
  {6'b11100x, 1'b1}: color = a1;

  {6'b11101x, 1'b0}: color = a12; // 58, 59
  {6'b11101x, 1'b1}: color = a9;
  
  {6'b11110x, 1'b0}: color = a15; // 60, 61
  {6'b11110x, 1'b1}: color = a11;
  
  {6'b11111x, 1'bx}: color = a15; // 62, 63
 endcase
 
 messArtifactPalette = color;
endfunction

`ifdef MiSTer_CoCo3
assign SG6_ENABLE = SWITCH & VID_CONT[0];
`else
assign SG6_ENABLE = ARTI[0] & VID_CONT[0];
`endif

assign PIXEL0 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[7]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[7]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[7]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[7]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[7]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[7]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER0[7]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[7]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 0
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({HISTORY[1:0],CHAR_LATCH_0[7:4]},1'b0,!PHASE)}:
// CoCo3 Graphics
//2 color 128/160 = 160/8 = 20
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[7]}:
//2 color 256/320 = 320/8 = 40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[7]}:
//2 color 512/640 = 640/8 = 80
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[7]}:

//4 Color 64/80 = 80/4 = 20
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 128/160 = 160/4 = 40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 256/320 = 320/4 = 80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 512/640 = 640/4 = 160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_0[7:6]}:

//16 Color 32/40 = 40/2 = 20
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80 = 80/2 = 40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 128/160 = 160/2 = 80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 256/320 = 320/2 = 160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} ==                   8'b01100100)       ? {4'h0,CHAR_LATCH_0[7:4]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_0[7:4]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_0[7:4]}:

// 256 color 32/40 = 40/1 = 40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80 = 80/1 = 80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[7:0]:
// 256 color 128/160 = 160/1 = 160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_0[7:0]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_0[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_0[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_0[7:0]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_0[7:0]:
// Default
                                 8'b00000000;
assign PIXEL1 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[7]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[7]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[7]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[6]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[6]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[7]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER0[6]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[7]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 1
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({HISTORY[1:0],CHAR_LATCH_0[7:4]},1'b0,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[7]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[7]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[6]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_0[3:0]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_0[3:0]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_0[3:0]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[7:0]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_0[7:0]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_0[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_0[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_0[7:0]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_0[15:8]:
// Default
                                 8'b00000000;
assign PIXEL2 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[6]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[6]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[6]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[5]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[5]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//32/40
   ({COCO1,BP,HRES[2],CRES[0]} ==4'b0001)                 ? {4'b0000,CHARACTER3[6],CHAR_LATCH_0[10:8]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0]} ==4'b0011)                 ? {4'b0000,CHARACTER3[5],CHAR_LATCH_0[10:8]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[6]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER0[5]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[6]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 2
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({HISTORY[1:0],CHAR_LATCH_0[7:4]},1'b1,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[7]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[6]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[5]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_0[3:2]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_0[15:12]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_0[15:12]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_0[15:12]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[7:0]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_0[7:0]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_0[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_0[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_0[15:8]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_1[7:0]:
// Default
                                 8'b00000000;
assign PIXEL3 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[6]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[6]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[6]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[4]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[4]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[6]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER0[4]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[7]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[6]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[7:6],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[7:6],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 3
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({HISTORY[1:0],CHAR_LATCH_0[7:4]},1'b1,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[7]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[6]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[4]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_0[1:0]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_0[11:8]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_0[11:8]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_0[11:8]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                 ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[7:0]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_0[7:0]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_0[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_0[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_0[15:8]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_1[15:8]:
// Default
                                 8'b00000000;
assign PIXEL4 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[5]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[5]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[5]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[3]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[3]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[5]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER0[3]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[5]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 4
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[7:2]},1'b0,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[6]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[5]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[3]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[3:2]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_0[15:14]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_0[15:12]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_1[7:4]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_1[7:4]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_1[7:4]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                 ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[7:0]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_0[15:8]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_1[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_1[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_1[7:0]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_2[7:0]:
// Default
                                 8'b00000000;
assign PIXEL5 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[5]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[5]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[5]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[2]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[2]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[5]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER0[2]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[5]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 5
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[7:2]},1'b0,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[6]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[5]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[2]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[3:2]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_0[13:12]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_0[15:12]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_1[3:0]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_1[3:0]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_1[3:0]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                 ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[7:0]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_0[15:8]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_1[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_1[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_1[7:0]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_2[15:8]:
// Default
                                 8'b00000000;
assign PIXEL6 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[4]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
//   ({COCO1,VID_CONT[3],MODE6,SG6,CHAR_LATCH_0[1]} == 6'b101100)         ? PALETTE8:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
//   ({COCO1,VID_CONT[3],MODE6,SG6,CHAR_LATCH_0[3]} == 6'b101010)         ? PALETTE8:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
//   ({COCO1,VID_CONT[3],MODE6,SG6,CHAR_LATCH_0[5]} == 6'b101000)         ? PALETTE8:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[4]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[4]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[1]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[1]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[4]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER0[1]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[4]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 6
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[7:2]},1'b1,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[6]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[4]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[1]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[1:0]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_0[11:10]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_0[11:8]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_1[15:12]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_1[15:12]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_1[15:12]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 7'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[7:0]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_0[15:8]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_1[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_1[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_1[15:8]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_3[7:0]:
// Default
                                 8'b00000000;
assign PIXEL7 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[4]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
//   ({COCO1,VID_CONT[3],MODE6,SG6,CHAR_LATCH_0[1]} == 6'b101100)         ? PALETTE8:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
//   ({COCO1,VID_CONT[3],MODE6,SG6,CHAR_LATCH_0[3]} == 6'b101010)         ? PALETTE8:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
//   ({COCO1,VID_CONT[3],MODE6,SG6,CHAR_LATCH_0[5]} == 6'b101000)         ? PALETTE8:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[4]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[4]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[0]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[0]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[4]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER0[0]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[7:6]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[6]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[4]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[5:4],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[5:4],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 7
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[7:2]},1'b1,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[6]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[4]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[0]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[7:6]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[1:0]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_0[9:8]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_0[11:8]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_1[11:8]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_1[11:8]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_1[11:8]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[7:0]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_0[15:8]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_1[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_1[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_1[15:8]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_3[15:8]:
// Default
                                 8'b00000000;
assign PIXEL8 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[3]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[3]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[3]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[7]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_1[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[7]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_1[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[3]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER1[7]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[3]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 8
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[5:0]},1'b0,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[5]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[3]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[15]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[3:2]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[15:14]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_1[7:6]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[15:12]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_1[7:4]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_2[7:4]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_2[7:4]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_2[7:4]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[15:8]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_1[7:0]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_2[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_2[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_2[7:0]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_4[7:0]:
// Default
                                 8'b00000000;
assign PIXEL9 =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[3]}:
//   ({COCO1,VID_CONT[3],CSS,CHAR_LATCH_0[7]} == 4'b1010)            ? {7'b0000111,~CHARACTER3[3]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100110)  ? 8'b00001100:
//   ({COCO1,VID_CONT[3],MODE6,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 6'b100101)    ? {5'b00000,CHAR_LATCH_0[6:4]}:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100100)  ? 8'b00001100:
//   ({COCO1,VID_CONT[3],MODE6,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 6'b100111)    ? {5'b00000,CHAR_LATCH_0[6:4]}:
//SG6
//Lines 0-3
//   ({COCO1,VID_CONT[3],MODE6,SG6,CHAR_LATCH_0[1]} == 6'b101100)         ? PALETTE8:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
//   ({COCO1,VID_CONT[3],MODE6,SG6,CHAR_LATCH_0[3]} == 6'b101010)         ? PALETTE8:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
//   ({COCO1,VID_CONT[3],MODE6,SG6,CHAR_LATCH_0[5]} == 6'b101000)         ? PALETTE8:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[3]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[3]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[6]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_1[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[6]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_1[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[3]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER1[6]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[3]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel 9
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[5:0]},1'b0,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[5]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[3]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[14]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[3:2]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[15:14]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_1[5:4]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[15:12]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_1[7:4]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_2[3:0]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_2[3:0]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_2[3:0]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[15:8]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_1[7:0]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_2[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_2[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_2[7:0]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_4[15:8]:
// Default
                                 8'b00000000;
assign PIXELA =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[2]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[2]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[2]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[5]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_1[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[5]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_1[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[2]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER1[5]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[2]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel A
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[5:0]},1'b1,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[5]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[2]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[13]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[3:2]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[13:12]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_1[3:2]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[15:12]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_1[3:0]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_2[15:12]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_2[15:12]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_2[15:12]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[15:8]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_1[7:0]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_2[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_2[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_2[15:8]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_5[7:0]:
// Default
                                 8'b00000000;
assign PIXELB =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[2]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[2]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[2]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[4]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_1[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[4]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_1[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[2]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER1[4]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[5]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[3:2]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[2]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[3:2],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[3:2],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel B
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[5:0]},1'b1,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[5]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[2]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                 ? {7'h00,CHAR_LATCH_0[12]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[3:2]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[13:12]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_1[1:0]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[15:12]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_1[3:0]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_2[11:8]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_2[11:8]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_2[11:8]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                 ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[15:8]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_1[7:0]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_2[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_2[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_2[15:8]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_5[15:8]:
// Default
                                 8'b00000000;
assign PIXELC =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[1]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[1]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[1]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[3]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_1[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[3]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_1[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[1]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER1[3]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[1]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel C
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[3:0],FUTURE[1:0]},1'b0,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[4]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[1]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                 ? {7'h00,CHAR_LATCH_0[11]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[1:0]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[11:10]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_1[15:14]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[11:8]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_1[15:12]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_3[7:4]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_3[7:4]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b011001010001)      ? {4'h0,CHAR_LATCH_3[7:4]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[15:8]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_1[15:8]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_3[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_3[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_3[7:0]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_6[7:0]:
// Default
                                 8'b00000000;
assign PIXELD =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[1]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[1]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[1]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[2]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_1[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[2]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_1[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[1]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER1[2]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[1]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel D
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[3:0],FUTURE[1:0]},1'b0,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[4]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[1]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                 ? {7'h00,CHAR_LATCH_0[10]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[1:0]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[11:10]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_1[13:12]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[11:8]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_1[15:12]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_3[3:0]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_3[3:0]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_3[3:0]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                 ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[15:8]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_1[15:8]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_3[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_3[7:0]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_3[7:0]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_6[15:8]:
// Default
                                 8'b00000000;
assign PIXELE =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[0]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[0]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[0]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[1]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_1[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[1]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_1[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[0]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER1[1]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[0]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel E
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[3:0],FUTURE[1:0]},1'b1,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[4]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[0]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                 ? {7'h00,CHAR_LATCH_0[9]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[1:0]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[9:8]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_1[11:10]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[11:8]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_1[11:8]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_3[15:12]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_3[15:12]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_3[15:12]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[15:8]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_1[15:8]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_3[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_3[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_3[15:8]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_7[7:0]:
// Default
                                 8'b00000000;
assign PIXELF =
//CoCo1 Text
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 4'b1000)         ? {6'b000011,CSS,~CHARACTER3[0]}:
//SG4, SG8, SG12, SG24
//Lines 0-5
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100111)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 6'b100110)  ? 8'b00001100:
//Lines 6-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100101)  ? {5'b00000,CHAR_LATCH_0[6:4]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 6'b100100)  ? 8'b00001100:
//SG6
//Lines 0-3
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101101)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 6'b101100)       ? 8'b00001100:
//Lines 4-7
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101011)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 6'b101010)       ? 8'b00001100:
//Lines 8-11
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101001)       ? {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
   ({COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 6'b101000)       ? 8'b00001100:
//HR Text
//32/40
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[0]} ==5'b00010)            ? {5'b00000,CHAR_LATCH_0[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER3[0]} ==5'b00011)            ? {5'b00001,CHAR_LATCH_0[13:11]}:
//64/80
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[0]} ==5'b00110)            ? {5'b00000,CHAR_LATCH_1[10:8]}:
   ({COCO1,BP,HRES[2],CRES[0],CHARACTER4[0]} ==5'b00111)            ? {5'b00001,CHAR_LATCH_1[13:11]}:
//XTEXT
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0000)                 ? {7'b0000000,CHARACTER0[0]}:
   ({COCO1,BP,HRES[2],CRES[0]}==4'b0010)                 ? {7'b0000000,CHARACTER1[0]}:
//CoCo1 graphics
//4 color 64
   ({COCO1,VID_CONT[3:0]} == 5'b11000)                  ? {5'h00,CSS,CHAR_LATCH_0[5:4]}:
//2 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11001)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11011)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11101)                  ? {6'h02,CSS,CHAR_LATCH_0[4]}:
//4 color 128
   ({COCO1,VID_CONT[3:0]} == 5'b11010)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11100)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
   ({COCO1,VID_CONT[3:0]} == 5'b11110)                  ? {5'h00,CSS,CHAR_LATCH_0[1:0]}:
//2 color 256
   ({COCO1,VID_CONT[3:0],ARTI} == 7'b1111100)               ? {6'h02,CSS,CHAR_LATCH_0[0]}:   // Black/Green and Black/White
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0]} == 9'b111111000)        ? {8'h10}:  // No pixels means black
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0],CSS} == 10'b1111110110)      ? {8'h0F}:  // 2 Pixels means Green
({COCO1,VID_CONT[3:0],ARTI,CHAR_LATCH_0[1:0],CSS} == 10'b1111110111)      ? {8'h1F}:  // 2 Pixels means White

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101011)   ? 8'h19:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100011)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101101)   ? 8'h1A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100101)   ? 8'h19:

({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101010)   ? 8'h09:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100010)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111101100)   ? 8'h0A:
({COCO1,VID_CONT[3:0],ARTI,PHASE,CHAR_LATCH_0[1:0],CSS} == 11'b11111100100)   ? 8'h09:
//Pixel F
({COCO1,VID_CONT[3:0],ARTI} == 7'b1111101)              ? {3'h0,CSS,messArtifactPalette({CHAR_LATCH_0[3:0],FUTURE[1:0]},1'b1,!PHASE)}:

// CoCo3 Graphics
//2 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100000)                ? {7'h00,CHAR_LATCH_0[4]}:
//2 color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100100)                ? {7'h00,CHAR_LATCH_0[0]}:
//2 color 512/640
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010100)                ? {7'h00,CHAR_LATCH_0[8]}:
//4 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100001)                ? {6'h00,CHAR_LATCH_0[5:4]}:
//4 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100101)                ? {6'h00,CHAR_LATCH_0[1:0]}:
//4 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101001)                ? {6'h00,CHAR_LATCH_0[9:8]}:
//4 Color 512/640
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101101)                ? {6'h00,CHAR_LATCH_1[9:8]}:
//16 Color 32/40
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100010)                ? {4'h0,CHAR_LATCH_0[7:4]}:
//16 Color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0100110)                ? {4'h0,CHAR_LATCH_0[3:0]}:
//16 Color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101010)                ? {4'h0,CHAR_LATCH_0[11:8]}:
//16 Color 256/320
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101110)                ? {4'h0,CHAR_LATCH_1[11:8]}:
//16 Color 512/640 = 640/2 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100100)             ? {4'h0,CHAR_LATCH_3[11:8]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100000)      ? {4'h0,CHAR_LATCH_3[11:8]}:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110010100011)      ? {4'h0,CHAR_LATCH_3[11:8]}:
// 256 color 32/40
   ({COCO1,BP,HRES[3:2],CRES} == 6'b010011)                ? CHAR_LATCH_0[7:0]:
// 256 color 64/80
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101011)                ? CHAR_LATCH_0[15:8]:
// 256 color 128/160
   ({COCO1,BP,HRES[3:1],CRES} == 7'b0101111)                ? CHAR_LATCH_1[15:8]:
// 256 color 256/320 = 320/1 = 320
   ({COCO1,BP,HRES[3:1],CRES,TURBO} == 8'b01100110)             ? CHAR_LATCH_3[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100000)      ? CHAR_LATCH_3[15:8]:
   ({COCO1,BP,HRES[3:1],CRES,TURBO,LINES_ROW,SDRate} == 13'b0110011100011)      ? CHAR_LATCH_3[15:8]:
// 256 color 512/640 = 640/1 = 640
   ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,SDRate} == 12'b011011100010)        ? CHAR_LATCH_7[15:8]:
// Default
                                 8'b00000000;
/*****************************************************************************
* Generate RGB
******************************************************************************/
always @ (negedge PIX_CLK)
begin
 if(PIXEL_COUNT[3:0] == 4'b1111)
 begin
   COLOR7[15:0] <= {PIXELF[7],PIXELE[7],PIXELD[7],PIXELC[7],PIXELB[7],PIXELA[7],PIXEL9[7],PIXEL8[7],
          PIXEL7[7],PIXEL6[7],PIXEL5[7],PIXEL4[7],PIXEL3[7],PIXEL2[7],PIXEL1[7],PIXEL0[7]};
   COLOR6[15:0] <= {PIXELF[6],PIXELE[6],PIXELD[6],PIXELC[6],PIXELB[6],PIXELA[6],PIXEL9[6],PIXEL8[6],
          PIXEL7[6],PIXEL6[6],PIXEL5[6],PIXEL4[6],PIXEL3[6],PIXEL2[6],PIXEL1[6],PIXEL0[6]};
   COLOR5[15:0] <= {PIXELF[5],PIXELE[5],PIXELD[5],PIXELC[5],PIXELB[5],PIXELA[5],PIXEL9[5],PIXEL8[5],
          PIXEL7[5],PIXEL6[5],PIXEL5[5],PIXEL4[5],PIXEL3[5],PIXEL2[5],PIXEL1[5],PIXEL0[5]};
   COLOR4[15:0] <= {PIXELF[4],PIXELE[4],PIXELD[4],PIXELC[4],PIXELB[4],PIXELA[4],PIXEL9[4],PIXEL8[4],
          PIXEL7[4],PIXEL6[4],PIXEL5[4],PIXEL4[4],PIXEL3[4],PIXEL2[4],PIXEL1[4],PIXEL0[4]};
   COLOR3[15:0] <= {PIXELF[3],PIXELE[3],PIXELD[3],PIXELC[3],PIXELB[3],PIXELA[3],PIXEL9[3],PIXEL8[3],
          PIXEL7[3],PIXEL6[3],PIXEL5[3],PIXEL4[3],PIXEL3[3],PIXEL2[3],PIXEL1[3],PIXEL0[3]};
   COLOR2[15:0] <= {PIXELF[2],PIXELE[2],PIXELD[2],PIXELC[2],PIXELB[2],PIXELA[2],PIXEL9[2],PIXEL8[2],
          PIXEL7[2],PIXEL6[2],PIXEL5[2],PIXEL4[2],PIXEL3[2],PIXEL2[2],PIXEL1[2],PIXEL0[2]};
   COLOR1[15:0] <= {PIXELF[1],PIXELE[1],PIXELD[1],PIXELC[1],PIXELB[1],PIXELA[1],PIXEL9[1],PIXEL8[1],
          PIXEL7[1],PIXEL6[1],PIXEL5[1],PIXEL4[1],PIXEL3[1],PIXEL2[1],PIXEL1[1],PIXEL0[1]};
   COLOR0[15:0] <= {PIXELF[0],PIXELE[0],PIXELD[0],PIXELC[0],PIXELB[0],PIXELA[0],PIXEL9[0],PIXEL8[0],
          PIXEL7[0],PIXEL6[0],PIXEL5[0],PIXEL4[0],PIXEL3[0],PIXEL2[0],PIXEL1[0],PIXEL0[0]};
 end
end
// ******************Check to see how bit 8 can be set see line 1785 *** maybe line 1773 should be 10'h100
assign BORDER =
// Real Borders
  ({COCO1,VID_CONT[3],CSS} == 3'b110)      ? 10'h281:     // Green
  ({COCO1,VID_CONT[3],CSS} == 3'b111)      ? 10'h282:     // White
  ({COCO1,VID_CONT[3]} == 2'b10)       ? 10'h280:     // Black
                    10'h010;     // BDR_PAL

always @ (negedge PIX_CLK)
begin
 COLOR <= CCOLOR;
end
// CCOLOR[9]  == 1  for hard coded colors
// CCOLOR[9:8] == 01  for 256 color palette
// CCOLOR[9:8] == 00  for normal palette registers

assign CCOLOR[9] = ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)   ? BORDER[9]:         // Border
       ({VBLANKING,HBLANKING,COCO1} == 3'b000)       ?  1'b0:           // CoCo3 (no artifacting)
       ({VBLANKING,HBLANKING,COCO1,ARTI} == 5'b00100)     ? 1'b0:           // CoCo1 No Artifacts
       ({VBLANKING,HBLANKING,COCO1,ARTI} == 5'b00111)     ? 1'b0:           // CoCo1 No Artifacts
       ({VBLANKING,HBLANKING,COCO1,ARTI} == 5'b00101)     ? (VID_CONT == 4'b1111):     // normal screen area Depends if artifact mode
       ({VBLANKING,HBLANKING,COCO1,ARTI} == 5'b00110)     ? (VID_CONT == 4'b1111):     // normal screen area Depends if artifact mode
                            1'b1;           // Retrace / Artifacting mode

assign CCOLOR[8] = ({VBLANKING,HBLANKING,COCO1} == 3'b000)       ? ({BP,CRES} == 3'b111):     //normal screen area in CoCo3 mode
//       ({VBLANKING,HBLANKING,COCO1} == 3'b001)       ? ({VID_CONT[3:0],ARTI} == 6'b111101): //normal screen area in CoCo1 MESS Artifacting mode
       ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)   ? BORDER[8]:         // Border
                            1'b0;           // Retrace / Artifacting

assign CCOLOR[7] = ({VBLANKING,HBLANKING} == 2'b00)   ? COLOR7[PIXEL_COUNT[3:0]]:    // Normal screeen area
  ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11) ? BORDER[7]:         // Border
                     1'b1;           // Retrace (80 = Black)

assign CCOLOR[6] = ({VBLANKING,HBLANKING} == 2'b00)   ? COLOR6[PIXEL_COUNT[3:0]]:    // Normal screeen area
  ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11) ? BORDER[6]:         // Border
                     1'b0;           // Retrace

assign CCOLOR[5] = ({VBLANKING,HBLANKING} == 2'b00)   ? COLOR5[PIXEL_COUNT[3:0]]:    // Normal screeen area
  ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11) ? BORDER[5]:         // Border
                     1'b0;           // Retrace

assign CCOLOR[4] = ({VBLANKING,HBLANKING} == 2'b00)   ? COLOR4[PIXEL_COUNT[3:0]]:    // Normal screeen area
  ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11) ? BORDER[4]:         // Border
                     1'b0;           // Retrace

assign CCOLOR[3] = ({VBLANKING,HBLANKING} == 2'b00)   ? COLOR3[PIXEL_COUNT[3:0]]:    // Normal screeen area
  ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11) ? BORDER[3]:         // Border
                     1'b0;           // Retrace

assign CCOLOR[2] = ({VBLANKING,HBLANKING} == 2'b00)   ? COLOR2[PIXEL_COUNT[3:0]]:    // Normal screeen area
  ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11) ? BORDER[2]:         // Border
                     1'b0;           // Retrace

assign CCOLOR[1] = ({VBLANKING,HBLANKING} == 2'b00)   ? COLOR1[PIXEL_COUNT[3:0]]:    // Normal screeen area
  ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11) ? BORDER[1]:         // Border
                     1'b0;           // Retrace

assign CCOLOR[0] = ({VBLANKING,HBLANKING} == 2'b00)   ? COLOR0[PIXEL_COUNT[3:0]]:    // Normal screeen area
  ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11) ? BORDER[0]:         // Border
                     1'b0;           // Retrace

/*****************************************************************************
* Count pixels across each line
* 32 and 40 character modes use double wide pixels
* There are 912 Pixels across the screen, with 640 the max shown
* HS = 80
* FP = 64 
* Border = 44
*  Additional Border = 64
* 80*8 = 640 or 32*16 = 512
* Additional Border = 64 
* Border = 44
* BP = 40
* Total = 912
******************************************************************************
HBORDER has to be 1 to display a border
HBlanking is 0 for main display
******************************************************************************/
always @ (negedge PIX_CLK)
begin
    case(PIXEL_COUNT)
    11'd015:            // Turn off horizontal blanking so first character can be displayed
    begin
        HBLANKING <= 1'b0;       // Turn off blanking which starts video
        PIXEL_COUNT  <= 11'd016;     // During 16, video is output
        HBORDER_INT <= 1'b0;                   // Every line
    end

    11'd527:            // 512 + 16 -1
    begin
        if(MODE_256)         // 512 mode
        begin
            HBLANKING <= 1'b1;      // Turn on blanking, which turns off video
            PIXEL_COUNT  <= 11'd592;    // 528 + 64 = 592
        end
        else            // 640 mode
        begin
            PIXEL_COUNT  <= 11'd528;    // Continue to display video
        end
    end

    11'd646:
    begin
        HBORDER_INT <= 1'b1;                        // 1 1.78 MHz CPU cycle before the end of Video
        PIXEL_COUNT  <= 11'd647;
    end

    11'd655:            // 640 + 16 - 1
    begin
        HBLANKING <= 1'b1;       // Blanking on which turns off video
        PIXEL_COUNT  <= 11'd656;
        if(({COCO1,BP,HRES[3:1],CRES,LINES_ROW,LINE[0]}==   12'b011011100010)  // 640 256 Color mode and LINE0 = 0
        || ({COCO1,BP,HRES[3:1],LINES_ROW,LINE[0],SDRate}== 11'b01100000101))  // 320 256/16 Color mode and LINE0 = 0, SDRate
        //|| ({COCO1,BP,HRES[3:1],CRES,LINES_ROW,LINE[0],SDRate}==13'b0110010000101)) // 640  16 Color mode and LINE0 = 0, SDRate
            DOUBLE <= 1'b1;                   // Double tells the RAM reader to continue reading during the !border and HSync
        else
            DOUBLE <= 1'b0;
        if(VBLANKING == 1'b1)                  // During the Verticle blanking, reset the video write buffer bank to 0
        begin
            if({COCO1,BP,HRES[3:1],TURBO,LAST,SDRate}==8'b01100110)      // 320 bytes / line mode and TURBO mode alternate banks (Double is set to 0 above)
        //    if({COCO1,BP,HRES[3:1],TURBO,LAST}==7'b0110011)         // 320 bytes / line mode and TURBO mode alternate banks (Double is set to 0 above)
                BUFF_BANK <= !BUFF_BANK;
            else
                BUFF_BANK <= 1'b0;
        end
        else
        begin
            if(({COCO1,BP,HRES[3:1],CRES,LINES_ROW,LINE[0]}== 12'b011011100011)     // 640 256 Color mode and LINE0 = 1 alternate banks (Double is set to 0 above)
            ||({COCO1,BP,HRES[3:1],TURBO,SDRate}== 7'b0110010)          // 320 All Color modes alternate banks
            ||({COCO1,BP,HRES[3:1],LINES_ROW,LINE[0],SDRate}== 11'b01100000111))    // 320 All Color mode and LINE0 = 1 SDRate alternate banks (Double is set to 0 above)
                BUFF_BANK <= !BUFF_BANK;

            //if({COCO1,BP,HRES[3:1],TURBO}==6'b011001)             // 320 bytes / line mode and TURBO mode alternate banks (Double is set to 0 above)
            // BUFF_BANK <= !BUFF_BANK;
        end

        if (VBLANKING == 1'b1)                  // During the Verticle blanking, reset the video read buffer bank to 0
            RD_BUFF_BANK <= 1'b0;
        else
        begin
            if(({COCO1,BP,HRES[3:1],CRES,LINES_ROW,LINE[0]}==12'b011011100010)    // 640 256 Color mode and LINE0 = 0 alternate banks (Reading is a 1 line later than writing
            ||({COCO1,BP,HRES[3:1],TURBO,SDRate}== 7'b0110010)          // 320 256 Color mode
            ||({COCO1,BP,HRES[3:1],LINES_ROW,LINE[0],SDRate}==11'b01100000101))    // 640  16 Color mode and LINE0 = 0, SDRate
                RD_BUFF_BANK <= !RD_BUFF_BANK;
            //if({COCO1,BP,HRES[3:1],TURBO}==6'b011001)           // 320 bytes / line mode and TURBO mode alternate banks (Double is set to 0 above)
                // RD_BUFF_BANK <= !RD_BUFF_BANK;
        end
    end

    11'd724:            // End of right border 720 + 44 - 1 (+ 64) start of back porch
    begin
        HBORDER <= 1'b0;        // 736 - 28
        PIXEL_COUNT <= 11'd725;
    end
/**************************************************************************************
// Adjust HSYNC here
**************************************************************************************/
// Width from 87 GIME 5.08 uS = 73 clocks
  11'd751:            // 824 - 751 = 73 (approx 5.09 uS)
  begin
   HSYNC_N <= 1'b0;        // Turn on Sync
   PIXEL_COUNT <= 11'd752;
  end
  11'd810:            // End of SYNC start of front porch 804 + 80 - 1, End of Sync to Video = 167 816 + 167 = 
  begin
   HSYNC_N <= 1'b1;        // SYNC OFF
   PIXEL_COUNT <= 11'd811;
  end
/**************************************************************************************
* End of HSYNC adjustment
**************************************************************************************/
    11'd873:            // Start of Border 824 + 64
    begin
        HBORDER <= 1'b1;        // Start border
//        VBORDER_INT <= VBLANKING_FLAG;                       // Interrupt at HBORDER Start on first line after video
        if(MODE_256)
            PIXEL_COUNT <= 11'd874;
        else
            PIXEL_COUNT <= 11'd938;    // Skip 64 extra border of 512 mode
    end
    11'd975:           // 912 + 64 or 948 + 44 - 16 - 1
    begin
        PIXEL_COUNT <= 11'd0;
    end
    default:
    begin
        PIXEL_COUNT <= PIXEL_COUNT + 1'b1;
    end
    endcase
end

/*****************************************************************************
* Switches to set different video modes
******************************************************************************/
assign MODE_256 = (COCO1 == 1'b1)     ? 1'b1:
      ({COCO1, HRES[0]}== 2'b00)  ? 1'b1:
                 1'b0;

/*
00x=one line per row
010=two lines per row
011=eight lines per row
100=nine lines per row
101=ten lines per row
110=eleven lines per row
111=*infinite lines per row
*/
assign LINES_ROW =  
                    // CoCo3
                    ({COCO1,LPR[2:1]}== 3'b000)                 ?   4'b0000:            //  1
                    ({COCO1,LPR}==      4'b0010)                ?   4'b0001:            //  2
                    ({COCO1,LPR}==      4'b0011)                ?   4'b0111:            //  8
                    ({COCO1,LPR}==      4'b0100)                ?   4'b1000:            //  9
                    ({COCO1,LPR}==      4'b0101)                ?   4'b1001:            //  10
                    ({COCO1,LPR}==      4'b0110)                ?   4'b1010:            //  11
                    ({COCO1,LPR}==      4'b0111)                ?   4'b1111:            //  Infinite

            // CoCo1
            ({COCO1,VID_CONT[3],V}==    5'b11000)               ?   4'b0010:            //  3    UNK x64
            ({COCO1,VID_CONT[3],V}==    5'b11001)               ?   4'b0010:            //  3    x64
            ({COCO1,VID_CONT[3],V}==    5'b11010)               ?   4'b0010:            //  3    x64

            ({COCO1,VID_CONT[3],V}==    5'b11011)               ?   4'b0001:            //  2    x96
            ({COCO1,VID_CONT[3],V}==    5'b11100)               ?   4'b0001:            //  2    x96

            ({COCO1,VID_CONT[3],V}==    5'b11101)               ?   4'b0000:            //  1    x192
            ({COCO1,VID_CONT[3],V}==    5'b11110)               ?   4'b0000:            //  1    x192
            ({COCO1,VID_CONT[3],V}==    5'b11111)               ? 4'b0000:            //  1    UNK x192

//          ({COCO1,VID_CONT[3],V}==    5'b10010)               ?   4'b0010:            //  3    SG8
//          ({COCO1,VID_CONT[3],V}==    5'b10100)               ?   4'b0001:            //  2    SG12
//          ({COCO1,VID_CONT[3],V}==    5'b10010)               ?   4'b0000:            //  1    SG24

                                                                    4'b1011;            // 12

assign SG_VLPR = VLPR + 1'b1;
assign SIX = //(V!=3'b000)      ? SIX_R:  //SG8, SG12, SG24
     (SG_VLPR[3:2] == 2'b00)  ? 1'b0:   //0-3 SG4
     (SG_VLPR[3:1] == 3'b010)  ? 1'b0:   //4-5 SG4
               1'b1;   //6-11

assign SG6 = SG_VLPR[3:2];  // 0000 - 0011 = 00
           // 0100 - 0111 = 01
           // 1000 - 1011 = 10
           // 1100 - 1111 = Not used

/************************************
* Generate clock for VSYNC_N by
* Delaying VSYNC_FLAG by 137
*************************************/
assign VSYNC_N = VSYNC_DELAY[137];
//assign VSYNC_N = VSYNC_FLAG;
always @ (negedge PIX_CLK)
begin
 VSYNC_DELAY <= {VSYNC_DELAY[138:0], VSYNC_FLAG};
end

/*****************************************************************************
* Keeps track of how many lines are in each row.
* Cannot sync to HSYNC (Checking this)
* Maybe can sync posedge HSYNC_N
******************************************************************************/
always @ (posedge HBORDER)
begin
 if(VBLANKING)
 begin
  UNDERLINE <= 1'b0;
  FIRST <= 1'b1;
  ROW_ADD <= 17'h00000;
  if(~COCO1)
  begin
   //25 bits =          6 bits     +   8 bits    +    8 bits    +    3 bits
   SCREEN_START_ADD <= {SCRN_START_HSB,SCRN_START_MSB,SCRN_START_LSB,3'h0};
  end
  else
  begin
   //25 bits            6 bits          3 bits               7 bits   6 bits               3 bits
   //                   24-19           18-16                15-9     8-3                  2-0
   SCREEN_START_ADD <= {SCRN_START_HSB, SCRN_START_MSB[7:5], VERT,    SCRN_START_LSB[5:0], 3'h0};
  end
  if(!COCO1 & BP)      // Vertical Fine Scroll not in HR graphics modes
   VLPR <= 4'h0;
  else
   VLPR <= VERT_FIN_SCRL;
 end
 else
 begin
  if(FIRST)      // Skip the first line since Blanking goes away before the HORDER signal
  begin
   FIRST <= 1'b0;
   if({COCO1,BP,HRES[3:1],TURBO}==6'b011001)    // 320 256 Color mode and Turbo mode
    ROW_ADD <= OFFSET;
  end
  else
  begin
   if(!COCO1)
   begin
    case (VLPR)
    4'h0:                    // Pixel row 1
    begin
     if((LINES_ROW == 4'b0000))            // 1 line
      ROW_ADD <= OFFSET;
     else
      if(({COCO1,BP,HRES[3:1],CRES,LPR[2:0],LINE[0]}==11'b01101110100)    // 640 256 Color mode and LINE0 = 0
      || ({COCO1,BP,HRES[3:1],CRES,LPR[2:0],LINE[0],SDRate}==12'b011001101001) // 320 256 Color mode and LINE0 = 0. SDRate
      || ({COCO1,BP,HRES[3:1],CRES,LPR[2:0],LINE[0],SDRate}==12'b011001001001)) // 640  16 Color mode and LINE0 = 0. SDRate
       ROW_ADD <= OFFSET;


     if(LINES_ROW == 4'b0001)            // 2 lines per row
      UNDERLINE <= 1'b1;             // Set underline
     else
      UNDERLINE <= 1'b0;

     if((LINES_ROW == 4'b0000) || ({BP, LINES_ROW} == 5'b11111)) // 1 or infinite graphics mode
      VLPR <= 4'h0;
     else
      if(({COCO1,BP,HRES[3:1],CRES,LPR[2:0],LINE[0]}==11'b01101110100)    // 640 256 Color mode and LINE0 = 0
      || ({COCO1,BP,HRES[3:1],CRES,LPR[2:0],LINE[0],SDRate}==12'b011001101001) // 320 256 Color mode and LINE0 = 0, SDRate
      || ({COCO1,BP,HRES[3:1],CRES,LPR[2:0],LINE[0],SDRate}==12'b011001101001)) // 640 256 Color mode and LINE0 = 0, SDRate
       VLPR <= 4'h0;
      else
       VLPR <= 4'h1;

    end
    4'h1:                    // Pixel row 2
    begin
     UNDERLINE <= 1'b0;
     if(LINES_ROW == 4'b0001)
     begin
      ROW_ADD <= OFFSET;
      VLPR <= 4'h0;
     end
     else
      VLPR <= 4'h2;
    end
    4'h6:                    // Pixel row 7
    begin
     VLPR <= 4'h7;
     if(LINES_ROW == 4'b0111)            // 8 lines per row
      UNDERLINE <= 1'b1;             // Set underline
     else
      UNDERLINE <= 1'b0;
    end
    4'h7:                    // Pixel Row 8
    begin
     if(LINES_ROW == 4'b0111)
     begin
      ROW_ADD <= OFFSET;
      VLPR <= 4'h0;
     end
     else
      VLPR <= 4'h8;

     if(LINES_ROW == 4'b1000)
      UNDERLINE <= 1'b1;     // Set underline
     else
      UNDERLINE <= 1'b0;

    end
    4'h8:         // Pixel Row 9
    begin
     if(LINES_ROW == 4'b1000)   // 9
     begin
      ROW_ADD <= OFFSET;
      VLPR <= 4'h0;
     end
     else
      VLPR <= 4'h9;

     if(LINES_ROW == 4'b1001)  // 10
      UNDERLINE <= 1'b1;     // Set underline
     else
      UNDERLINE <= 1'b0;

    end
    4'h9:         // Pixel Row 10
    begin
     if(LINES_ROW == 4'b1001)   // 10
     begin
      ROW_ADD <= OFFSET;
      VLPR <= 4'h0;
     end
     else
     begin
      VLPR <= 4'hA;
      UNDERLINE <= 1'b1;
     end
    end
    4'hA:         // Pixel Row 11
    begin
     if(LINES_ROW == 4'b1010)   // 11
     begin
      ROW_ADD <= OFFSET;
      VLPR <= 4'h0;
     end

     UNDERLINE <= 1'b0;
    end
    4'hB,         // Pixel Row 12
    4'hC,
    4'hD,
    4'hE,
    4'hF:
    begin
     if(LINES_ROW != 4'b1111)   // Infinite
     begin
      ROW_ADD <= OFFSET;
      VLPR <= 4'h0;
      UNDERLINE <= 1'b0;
     end

     UNDERLINE <= 1'b0;
    end
    default:
    begin
     VLPR <= VLPR + 1'b1;
    end
    endcase
   end
   else
   begin
/*
Alpha       12 / 1 = 12
SemiGraphics 4   12 / 1 = 12
SemiGraphics 6   12 / 1 = 12
SemiGraphbics 8  12 / 4 = 3 (A, 1, 4, 7)
SemiGraphics 12  12 / 6 = 2 (A, 0, 2, 4, 6, 8)
SemiGraphics 24  12 / 12 = 1
*/
// This gets triggered towards the end of the row
    case (VLPR)
// Line 1
    4'hF:                      // Start at F for the character generator
    begin
     if(LINES_ROW == 4'b0000)
     begin
      VLPR <= VERT_FIN_SCRL;
     end
     else
     begin
      VLPR <= 4'h0;
     end
     if ((LINES_ROW == 4'b0000)             // 1 line
      |({VID_CONT[3], V} == 4'b0110))          // SG24
     begin
      ROW_ADD <= OFFSET;
     end
    end
// Line 2
    4'h0:
    begin
     if(LINES_ROW == 4'b0001)
     begin
      VLPR <= VERT_FIN_SCRL;
     end
     else
     begin
      VLPR <= 4'h1;
     end
     if ((LINES_ROW == 4'b0001)             // 2 Lines
      |({VID_CONT[3], V} == 4'b0100)          // SG12
      |({VID_CONT[3], V} == 4'b0110))          // SG24
     begin
      ROW_ADD <= OFFSET;
     end
    end
// Line 3
    4'h1:
    begin
     if(LINES_ROW == 4'b0010)
     begin
      VLPR <= VERT_FIN_SCRL;
     end
     else
     begin
      VLPR <= 4'h2;
     end
     if ((LINES_ROW == 4'b0010)             // 3 Lines
      |({VID_CONT[3], V} == 4'b0010)          // SG8
      |({VID_CONT[3], V} == 4'b0110))          // SG24
     begin
      ROW_ADD <= OFFSET;
     end
    end
// Line 4
    4'h2:
    begin
     if(LINES_ROW == 4'b0010)
     begin
      VLPR <= VERT_FIN_SCRL;
     end
     else
     begin
      VLPR <= 4'h3;
     end
     if ((LINES_ROW == 4'b0010)             // 3 line
      |({VID_CONT[3], V} == 4'b0100)          // SG12
      |({VID_CONT[3], V} == 4'b0110))          // SG24
     begin
      ROW_ADD <= OFFSET;
     end
    end
// Line 6
    4'h4:
    begin
     VLPR <= 4'h5;
     if (({VID_CONT[3], V} == 4'b0010)           // SG8
      |({VID_CONT[3], V} == 4'b0100)           // SG12
      |({VID_CONT[3], V} == 4'b0110))           // SG24
     begin
      ROW_ADD <= OFFSET;
     end
    end
// Line 8
    4'h6:
    begin
     VLPR <= 4'h7;
     if (({VID_CONT[3], V} == 4'b0100)           // SG12
      |({VID_CONT[3], V} == 4'b0110))           // SG24
     begin
      ROW_ADD <= OFFSET;
     end
    end
// Line 9
    4'h7:
    begin
     VLPR <= 4'h8;
     if (({VID_CONT[3], V} == 4'b0010)           // SG8
      |({VID_CONT[3], V} == 4'b0110))           // SG24
     begin
      ROW_ADD <= OFFSET;
     end
    end
// Line 10
    4'h8:
    begin
     VLPR <= 4'h9;
     if (({VID_CONT[3], V} == 4'b0100)           // SG12
      |({VID_CONT[3], V} == 4'b0110))           // SG24
     begin
      ROW_ADD <= OFFSET;
     end
    end
// Line 12
    4'hA:                                                                           //  ll Line 11 + (F) = 12
    begin
     VLPR <= VERT_FIN_SCRL;
     ROW_ADD <= OFFSET;
    end
    4'hB:
     VLPR <= VLPR + 1'b1;
    4'hC:
     VLPR <= VLPR + 1'b1;
    4'hD:
     VLPR <= VLPR + 1'b1;
    4'hE:
    begin
     VLPR <= VERT_FIN_SCRL;
     ROW_ADD <= OFFSET;
    end
    default:
    begin
     VLPR <= VLPR + 1'b1;
     if({VID_CONT[3], V} == 4'b0110)            //SG24
     begin
      ROW_ADD <= OFFSET;
     end
    end
    endcase
   end
  end
 end
end
/*****************************************************************************
* Keeps track of the real line number, and controls VSYNC and VBlanking.
* Does not keep track of the lines per row
*
* LPR    Lines
*
* 00 or COCO =1 192
* 01     200
* 10     210
* 11     225 (25*9)
*
*  4  VSYNC
*  3  Upper porch
*  36  Border
*  192  video
* 26  Border (26)
* 2  Lower porch
*  
* 263
*
* In 80 mode, border starts 3 lines after end of sync
* VSync is 4 HSync wide
* VSync changes state 5.8 uS after fall of HSync = 143
* 5.8 uS = 80 clocks
* In 32 Column mode
* VSync changes state 10.1 uS after fall of HSync = 143 - from scope
* 10.1 uS = 144 clocks
******************************************************************************
* 80 column 225 mode text starts 22 lines after end of vsync
* 80 column 192 mode text starts 38 lines after end of vsync
* 225-192 = 33 /2 = 16
*  38- 22 = 15
*
*
*
******************************************************************************/
/*
always @ (negedge HSYNC_N or negedge RESET_N)   // Start of HSYNC
begin
 if(~RESET_N)
 begin
  VBLANKING_INT_N <= 1'b1;
 end
 else
 begin
  case (LINE)
  9'd232: // 192
  begin
   if((LPF == 2'b00)|(COCO1))
    VBLANKING_INT_N <= 1'b0;
  end
  9'd238: // 200
  begin
   if(LPF == 2'b01)
    VBLANKING_INT_N <= 1'b0;
  end
  9'd242: // 210
  begin
   if(LPF == 2'b10)
    VBLANKING_INT_N <= 1'b0;
  end
  9'd249: // 225
  begin
            if(LPF == 2'b11)
    VBLANKING_INT_N <= 1'b0;
  end
        default:
        begin
    VBLANKING_INT_N <= 1'b1;
        end
        endcase
    end
end
*/
always @ (negedge HSYNC_N or negedge RESET_N)   // Start of HSYNC
begin
    if(~RESET_N)
    begin
        LINE <= 9'd00;
        VBLANKING <= 1'b1;
        VBORDER <= 1'b0;
        VSYNC_FLAG <= 1'b1;
        LAST <= 1'b0;
    end
    else
    begin
        case (LINE)
        9'd0:
        begin
            VSYNC_FLAG <= 1'b0;
            LINE <= 9'd1;
        end
        9'd4:
        begin
            VSYNC_FLAG <= 1'b1;
            LINE <= 9'd5;
        end
        9'd7:
        begin
            VBORDER <= 1'b1;
            LINE <= 9'd8;
        end
        9'd25: // 225
        begin
            if((LPF == 2'b11)&(!COCO1))
                LAST <= 1'b1;
            LINE <= 9'd26;
        end
        9'd26: // 225
        begin
            if((LPF == 2'b11)&(!COCO1))
                VBLANKING <= 1'b0;
            LAST <= 1'b0;
            LINE <= 9'd27;
        end
        9'd33: // 210
        begin
            if((LPF == 2'b10)&(!COCO1))
                LAST <= 1'b1;
            LINE <= 9'd34;
        end
        9'd34: // 210
        begin
            if((LPF == 2'b10)&(!COCO1))
                VBLANKING <= 1'b0;
            LAST <= 1'b0;
            LINE <= 9'd35;
        end
        9'd39: // 200
        begin
            if((LPF == 2'b01)&(!COCO1))
                LAST <= 1'b1;
            LINE <= 9'd40;
        end
        9'd40: // 200
        begin
            if((LPF == 2'b01)&(!COCO1))
                VBLANKING <= 1'b0;
            LAST <= 1'b0;
            LINE <= 9'd41;
        end
        9'd41: // 192
        begin
            if((LPF == 2'b00)&(!COCO1))
                LAST <= 1'b1;
            LINE <= 9'd42;
        end
        9'd42: // 192
        begin
            VBLANKING <= 1'b0;
            LAST <= 1'b0;
            LINE <= 9'd43;
        end
        9'd233: // 192
        begin
            if((LPF == 2'b00)|(COCO1))
            begin
                VBORDER_INT <= 1'b1;
            end
            LINE <= 9'd234;
        end
        9'd234: // 192
        begin
            if((LPF == 2'b00)|(COCO1))
            begin
                VBLANKING <= 1'b1;
                VBORDER_INT <= 1'b1;
            end
            LINE <= 9'd235;
        end
        9'd238: // 200
        begin
            if(LPF == 2'b01)
            begin
                VBORDER_INT <= 1'b1;
            end
            LINE <= 9'd239;
        end
        9'd239: // 200
        begin
            if(LPF == 2'b01)
            begin
                VBLANKING <= 1'b1;
                VBORDER_INT <= 1'b1;
            end
            LINE <= 9'd240;
        end
        9'd243: // 210
        begin
            if(LPF == 2'b10)
            begin
                VBORDER_INT <= 1'b1;
            end
            LINE <= 9'd244;
        end
        9'd244: // 210
        begin
            if(LPF == 2'b10)
            begin
                VBLANKING <= 1'b1;
                VBORDER_INT <= 1'b1;
            end
            LINE <= 9'd245;
        end
        9'd250: // 225
        begin
            VBORDER_INT <= 1'b1;
            LINE <= 9'd251;
        end
        9'd251: // 225
        begin
            VBLANKING <= 1'b1;
            LINE <= 9'd252;
        end
        9'd261:
        begin
            VBORDER <= 1'b0;
            LINE <= 9'd262;
        end
        9'd262:
        begin
            LINE <= 9'd0;
            VBORDER_INT <= 1'b0;
        end
        default:
        begin
            LINE <= LINE + 1'b1;
        end
        endcase
    end
end
endmodule
