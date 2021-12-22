module COCO3VIDEO(
// Clocks / RESET
MASTER_CLK,
PIX_CLK,
RESET_N,
// Video Out
COLOR,
HSYNC_N,
SYNC_FLAG,
VSYNC_N,
HBLANKING,
VBLANKING,

// RAM / Buffer
RAM_ADDRESS,
BUFF_ADD,
RAM_DATA,

// Mode Selection
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

// Starting location
SCRN_START_HSB,     // 6 extra bits
SCRN_START_MSB,
SCRN_START_LSB,

// Attributes
SWITCH,
BLINK,
PHASE,
ROM_ADDRESS,
ROM_DATA1,
HBORDER,
HBORDER_INT,
VBORDER_INT
);

input               MASTER_CLK;
input               PIX_CLK;
input               RESET_N;

output      [9:0]   COLOR;
reg         [9:0]   COLOR;
output              HSYNC_N;
reg                 HSYNC_N;
output				SYNC_FLAG;
reg					SYNC_FLAG;
output              VSYNC_N;
output				HBLANKING;
reg					HBLANKING;
output				VBLANKING;
reg					VBLANKING;

output      [24:0]  RAM_ADDRESS;
output      [8:0]   BUFF_ADD;
reg         [8:0]   BUFF_ADD;
input       [15:0]  RAM_DATA;

input               COCO1;
input       [2:0]   V;
input               BP;
input       [6:0]   VERT;
input       [3:0]   VID_CONT;
input               CSS;
input       [1:0]   LPF;
input               HLPR;
input       [2:0]   LPR;
input       [3:0]   VERT_FIN_SCRL;
input       [3:0]   HRES;
input       [1:0]   CRES;
input               HVEN;

input       [5:0]   SCRN_START_HSB; // extra 6
input       [7:0]   SCRN_START_MSB;
input       [7:0]   SCRN_START_LSB;

input               BLINK;
input               PHASE;
input               SWITCH;

output      [10:0]  ROM_ADDRESS;
input       [7:0]  ROM_DATA1;
output              HBORDER;
output              HBORDER_INT;
reg                 HBORDER_INT;
output              VBORDER_INT;
reg                 VBORDER_INT;

//reg                 HBLANKING;
reg     [9:0]       LINE;
reg     [3:0]       VLPR;
reg     [3:0]       COCO_VLPR;
reg     [10:0]      PIXEL_COUNT;
reg     [15:0]      CHAR_LATCH_0_TMP;
reg     [15:0]      CHAR_LATCH_1_TMP;
reg     [15:0]      CHAR_LATCH_2_TMP;
reg     [15:0]      CHAR_LATCH_3_TMP;
reg     [15:0]      CHAR_LATCH_4_TMP;
reg     [15:0]      CHAR_LATCH_5_TMP;
reg     [15:0]      CHAR_LATCH_6_TMP;
reg     [15:0]      CHAR_LATCH_7_TMP;
reg     [15:0]      CHAR_LATCH_0;
reg     [15:0]      CHAR_LATCH_1;
reg     [15:0]      CHAR_LATCH_2;
reg     [15:0]      CHAR_LATCH_3;
reg     [15:0]      CHAR_LATCH_4;
reg     [15:0]      CHAR_LATCH_5;
reg     [15:0]      CHAR_LATCH_6;
reg     [15:0]      CHAR_LATCH_7;
reg     [7:0]       CHARACTER0_TMP;
reg     [7:0]       CHARACTER1_TMP;
reg     [7:0]       CHARACTER2_TMP;
reg     [7:0]       CHARACTER0;
reg     [7:0]       CHARACTER1;
reg     [7:0]       CHARACTER2;
wire    [7:0]       CHARACTER3;
wire    [7:0]       CHARACTER4;

wire    [3:0]       PIXEL_ORDER;
reg                 UNDERLINE;
wire                MODE_256;
reg     [10:0]      ROM_ADDRESS;
wire    [3:0]       LINES_ROW;
//reg     [3:0]       NUM_ROW;
wire                SIX;
reg                 SIX_R;
wire    [1:0]       SG6;
reg     [2:0]       SG_LINES;
wire    [7:0]       PIXEL_X;

reg     [24:0]      ROW_ADD;
wire    [24:0]      OFFSET;
reg                 HBORDER;
wire    [9:0]       BORDER;
wire    [9:0]       CCOLOR;
wire                MODE6;
wire                SG6_ENABLE;
reg     [1:0]       HISTORY;
reg     [1:0]       FUTURE;
wire    [8:0]       BUF_ADD_BASE;
//reg   [353:0]       VSYNC_DELAY;
//reg                 VBLANKING;
wire    [3:0]       SG_VLPR;
reg     [139:0]     VSYNC_DELAY;
reg                 VBORDER;
reg                 VSYNC_FLAG;
reg                 HBORDER_DELAY;
reg     [24:0]      SCREEN_START_ADD;
reg                 HSYNC_N_DELAY;
reg                 PIX_CLK_DELAY;
reg                 FIRST;

parameter PALETTE0 = 4'h0;
parameter PALETTE1 = 4'h1;
parameter PALETTE2 = 4'h2;
parameter PALETTE3 = 4'h3;
parameter PALETTE4 = 4'h4;
parameter PALETTE5 = 4'h5;
parameter PALETTE6 = 4'h6;
parameter PALETTE7 = 4'h7;
parameter PALETTE8 = 4'h8;
parameter PALETTE9 = 4'h9;
parameter PALETTEA = 4'hA;
parameter PALETTEB = 4'hB;
parameter PALETTEC = 4'hC;
parameter PALETTED = 4'hD;
parameter PALETTEE = 4'hE;
parameter PALETTEF = 4'hF;

/*****************************************************************************
* SCREEN_START_ADD is set only on the start of HBorder on the last line that
* VBlanking on ROW_ADD is changed at the start of the verticle border
******************************************************************************/
assign RAM_ADDRESS = SCREEN_START_ADD + ROW_ADD;
/*****************************************************************************
* Calculates the offset for the start of the row
******************************************************************************/
assign OFFSET =
// CoCo1 low res graphics
({HVEN,COCO1,VID_CONT[3],V[0]}                   ==  4'b0111)        ?   ROW_ADD + 11'd16:   // WHEN V[0]=1 16 BYTES V[0]=0 32 BYTES

// HR Text
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}       ==  6'b0000001)     ?   ROW_ADD + 11'd40:   // HR TEXT with no Attributes
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}       ==  6'b0000010)     ?   ROW_ADD + 11'd64:
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}       ==  6'b0000011)     ?   ROW_ADD + 11'd80:
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}       ==  6'b0000100)     ?   ROW_ADD + 11'd64:
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}       ==  6'b0000101)     ?   ROW_ADD + 11'd80:
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}       ==  6'b0000110)     ?   ROW_ADD + 11'd128:
({HVEN,COCO1,BP,HRES[3:2],CRES[0],HRES[0]}       ==  6'b0000111)     ?   ROW_ADD + 11'd160:

// HR Graphics
({HVEN,COCO1,BP,HRES}                            ==  7'b0010000)     ?   ROW_ADD + 11'd16:
({HVEN,COCO1,BP,HRES}                            ==  7'b0010001)     ?   ROW_ADD + 11'd20:
({HVEN,COCO1,BP,HRES}                            ==  7'b0010011)     ?   ROW_ADD + 11'd40:
({HVEN,COCO1,BP,HRES}                            ==  7'b0010100)     ?   ROW_ADD + 11'd64:
({HVEN,COCO1,BP,HRES}                            ==  7'b0010101)     ?   ROW_ADD + 11'd80:
({HVEN,COCO1,BP,HRES}                            ==  7'b0010110)     ?   ROW_ADD + 11'd128:
({HVEN,COCO1,BP,HRES}                            ==  7'b0010111)     ?   ROW_ADD + 11'd160:

// Graphics greater than 160 bytes / row
({HVEN,COCO1,BP,HRES}                            ==  7'b0011000)     ?   ROW_ADD + 11'd256:
({HVEN,COCO1,BP,HRES}                            ==  7'b0011001)     ?   ROW_ADD + 11'd320:
//({HVEN,COCO1,BP,HRES}                            ==  7'b0011010)     ?   ROW_ADD + 11'd512:
//({HVEN,COCO1,BP,HRES}                            ==  7'b0011011)     ?   ROW_ADD + 11'd640:

// HVEN is Horizontal virtual enable, so each line is 256 bytes eventhough we real only 160 and display only 80
({HVEN,COCO1}                                    ==  2'b11)          ?   ROW_ADD + 11'd256:
({HVEN,COCO1, HRES[3]}                           ==  3'b100)         ?   ROW_ADD + 11'd256:

// 256 / 320 / 512 / 640 modes use 1024
({HVEN,COCO1, HRES[3]}                           ==  3'b101)         ?   ROW_ADD + 11'd1024:

// Everything else is 32 bytes
                                                                        ROW_ADD + 11'd32;

/*****************************************************************************
* Read RAM
******************************************************************************/
assign BUF_ADD_BASE =
// CoCo1 low res graphics (64 pixels / 2 bytes)
({COCO1,VID_CONT[3],V[0]} == 3'b111)     ?   {5'b00000, PIXEL_COUNT[9:6]}        :   //16 bytes / line  Uses 2 bytes every 64 pixels

//  HR Text
({COCO1,BP,HRES[2],CRES[0]}==4'b0001)    ?   {3'b000,   PIXEL_COUNT[9:4]}        :   //64 / 80 characters / line  Uses` 2 bytes every 16 pixels
({COCO1,BP,HRES[2],CRES[0]}==4'b0010)    ?   {3'b000,   PIXEL_COUNT[9:4]}        :   //64 / 80 characters / line  Uses 2 bytes every 16 pixels
({COCO1,BP,HRES[2],CRES[0]}==4'b0011)    ?   {2'b00,    PIXEL_COUNT[9:4], 1'b0}  :   //128/160 characters / line  Uses 2 bytes every 8 pixels

//  HR Graphics
({COCO1,BP,HRES}==6'b010000)             ?   {5'b00000, PIXEL_COUNT[9:6]}        :   //16 bytes / line
({COCO1,BP,HRES}==6'b010001)             ?   {5'b00000, PIXEL_COUNT[9:6]}        :   //20 bytes / line
({COCO1,BP,HRES}==6'b010100)             ?   {3'b000,   PIXEL_COUNT[9:4]}        :   //64 bytes / line
({COCO1,BP,HRES}==6'b010101)             ?   {3'b000,   PIXEL_COUNT[9:4]}        :   //80 bytes / line
({COCO1,BP,HRES}==6'b010110)             ?   {2'b00,    PIXEL_COUNT[9:4], 1'b0}  :   //128 bytes / line
({COCO1,BP,HRES}==6'b010111)             ?   {2'b00,    PIXEL_COUNT[9:4], 1'b0}  :   //160 bytes / line
({COCO1,BP,HRES}==6'b011000)             ?   {1'b0,     PIXEL_COUNT[9:4], 2'b00} :   //256 bytes / line
({COCO1,BP,HRES}==6'b011001)             ?   {1'b0,     PIXEL_COUNT[9:4], 2'b00} :   //320 bytes / line
({COCO1,BP,HRES}==6'b011010)             ?   {          PIXEL_COUNT[9:4], 3'b000}:   //512 bytes / line
({COCO1,BP,HRES}==6'b011011)             ?   {          PIXEL_COUNT[9:4], 3'b000}:   //640 bytes / line

// CoCo1 Text and SEMIGRAPHICS
                                            {4'b0000,  PIXEL_COUNT[9:5]};   //32 characters / line
// SRH fix for 80 col mode...
wire [3:0]	COCO3_VLPR;
//assign COCO3_VLPR = VLPR + 2'b11;
assign COCO3_VLPR = VLPR;

always @ (negedge MASTER_CLK)
    PIX_CLK_DELAY <= PIX_CLK;

always @ (negedge MASTER_CLK)
    if(PIX_CLK == 1'b0 && PIX_CLK_DELAY == 1'b1)
    begin
        case (PIXEL_COUNT[3:0])
        4'b0100:
        begin
            BUFF_ADD <= BUF_ADD_BASE;
        end
        4'b0101:
        begin
            BUFF_ADD <= BUFF_ADD + 1'b1;
            if  (({PIXEL_COUNT[5:4]} !=2'b00)
            &(({COCO1,VID_CONT[3],V[0]}==3'b111)                                                  // CoCo1 16 byte / line mode
            | ({COCO1,BP,HRES[3],HRES[2],HRES[1]}==5'b01000)))                                    // CoCo3 16/20 bytes/line
            begin
                CHAR_LATCH_0_TMP <= {CHAR_LATCH_0_TMP[11:8],
                                    4'h0,
                                    CHAR_LATCH_0_TMP[3:0],
                                    CHAR_LATCH_0_TMP[15:12]};                                      // Rotate into position on 16/20 bytes/line
            end
            else
            begin
                if  (PIXEL_COUNT[4]
                &((COCO1)                                                                          // All other CoCo1 modes
                |({COCO1,BP,HRES[3],HRES[2],CRES[0]}==5'b00000)                                    // CoCo3 32/40 XText
                |({COCO1,BP,HRES[3],HRES[2],HRES[1]}==5'b01001)))                                  //CoCo3 32/40 bytes/line
                begin
                    CHAR_LATCH_0_TMP <= {8'h00,CHAR_LATCH_0_TMP[15:8]};
                    HISTORY <= CHAR_LATCH_0_TMP[1:0];
                    FUTURE <= CHAR_LATCH_1_TMP[7:6];
                end
                else
                begin
                    CHAR_LATCH_0_TMP <= RAM_DATA[15:0];                                             // Everything else
                    FUTURE <= RAM_DATA[15:14];
                    if (HBLANKING)
                        HISTORY <= {VID_CONT[3],VID_CONT[3]};                                       // First history after hblanking depends on the border
                    else
                        HISTORY <= CHAR_LATCH_0_TMP[1:0];                                           // After that, it is the last two pixels
                end
            end
        end
        4'b0110:
        begin
            if(!COCO1)
                ROM_ADDRESS <=  {CHAR_LATCH_0_TMP[6:0],COCO3_VLPR[3:0]};                                  // COCO3 Text 1 (40 and 80)
            else
            begin
                if({COCO1,VID_CONT[0],CHAR_LATCH_0_TMP[6:5]} == 4'b1100)
                    ROM_ADDRESS <=  {2'b11, CHAR_LATCH_0_TMP[4:0], VLPR};                           // COCO1 Text 1 with LC
                else
                    ROM_ADDRESS <=  {~CHAR_LATCH_0_TMP[5],  CHAR_LATCH_0_TMP[5:0], VLPR};           // COCO1 Text 1 w/o LC
            end
        end
        4'b0111:
        begin
            BUFF_ADD <= BUFF_ADD + 1'b1;
            CHAR_LATCH_1_TMP <= RAM_DATA[15:0];
        end
        4'b1000:
        begin
            BUFF_ADD <= BUFF_ADD + 1'b1;
            CHAR_LATCH_2_TMP <= RAM_DATA[15:0];
            ROM_ADDRESS <=  {CHAR_LATCH_0_TMP[14:8],COCO3_VLPR[3:0]};                                     // COCO3 Text 1 (40 and 80)
            CHARACTER0_TMP <=   ROM_DATA1;
        end
        4'b1001:
        begin
//            BUFF_ADD <= BUFF_ADD + 1'b1;
            CHAR_LATCH_3_TMP <= RAM_DATA[15:0];
        end
        4'b1010:
        begin
//            BUFF_ADD <= BUFF_ADD + 1'b1;
//            CHAR_LATCH_4_TMP <= RAM_DATA[15:0];
    //Attribute less TEXT only
            CHARACTER1_TMP <=   ROM_DATA1;
            ROM_ADDRESS <=  {CHAR_LATCH_1_TMP[6:0],COCO3_VLPR[3:0]};                                      // COCO3 Text 1 (40 and 80)
        end
//        4'b1011:
//        begin
//            BUFF_ADD <= BUFF_ADD + 1'b1;
//            CHAR_LATCH_5_TMP <= RAM_DATA[15:0];                                                         // last read from the previous series
//        end
        4'b1100:
        begin
//            BUFF_ADD <= BUFF_ADD + 1'b1;
//            CHAR_LATCH_6_TMP <= RAM_DATA[15:0];                                                         // First read of this series
              CHARACTER2_TMP <=   ROM_DATA1;
        end
//        4'b1101:
//        begin
//            CHAR_LATCH_7_TMP <= RAM_DATA[15:0];
//        end
        4'b1111:
        begin
            CHAR_LATCH_0    <=   CHAR_LATCH_0_TMP;
            CHAR_LATCH_1    <=   CHAR_LATCH_1_TMP;
            CHAR_LATCH_2    <=   CHAR_LATCH_2_TMP;
            CHAR_LATCH_3    <=   CHAR_LATCH_3_TMP;
//            CHAR_LATCH_4    <=  CHAR_LATCH_4_TMP;
//            CHAR_LATCH_5    <=  CHAR_LATCH_5_TMP;
//            CHAR_LATCH_6    <=  CHAR_LATCH_6_TMP;
//            CHAR_LATCH_7    <=  CHAR_LATCH_7_TMP;
            CHARACTER0      <=   CHARACTER3;
            CHARACTER1      <=   CHARACTER1_TMP;
            CHARACTER2      <=   CHARACTER4;
        end
        endcase
        
    end

/*****************************************************************************
* Add attributes to the Character for both CoCo3 and CoCo1
* CHARACTER3 is for both 32/40 and the first 64/80 character
* CHARACTER4 is the second 64/80 character
******************************************************************************/
assign CHARACTER3 = ({COCO1,BP,CRES[0],CHAR_LATCH_0_TMP[15],BLINK}      == 5'b00111)    ?    8'h00:             // Hires Text blink
                    ({COCO1,BP,CRES[0],CHAR_LATCH_0_TMP[14],UNDERLINE}  == 5'b00111)    ?    8'h7E:             // Underline
                    ({COCO1, VID_CONT[1:0], CHAR_LATCH_0_TMP[6:5]}      == 5'b10000)    ?   ~CHARACTER0_TMP:    // Lowres  0-31 Normal UC only (Inverse)
                    ({COCO1, VID_CONT[1:0], CHAR_LATCH_0_TMP[6:5]}      == 5'b10001)    ?   ~CHARACTER0_TMP:    // Lowres 32-64 Normal UC only (Inverse)
                    ({COCO1, VID_CONT[1:0], CHAR_LATCH_0_TMP[6:5]}      == 5'b10101)    ?   ~CHARACTER0_TMP:    // Lowres 32-64 LC but UC part (Inverse)
                    ({COCO1, VID_CONT[1:0], CHAR_LATCH_0_TMP[6:5]}      == 5'b11010)    ?   ~CHARACTER0_TMP:    // Lowres 64-95 Inverse
                    ({COCO1, VID_CONT[1:0], CHAR_LATCH_0_TMP[6:5]}      == 5'b11011)    ?   ~CHARACTER0_TMP:    // Lowres 96-128 Inverse
                    ({COCO1, VID_CONT[1:0], CHAR_LATCH_0_TMP[6:5]}      == 5'b11100)    ?   ~CHARACTER0_TMP:    // Lowres  0-31 Inverse
                    ({COCO1, VID_CONT[1:0], CHAR_LATCH_0_TMP[6:5]}      == 5'b11110)    ?   ~CHARACTER0_TMP:    // Lowres 64-95 Inverse
                    ({COCO1, VID_CONT[1:0], CHAR_LATCH_0_TMP[6:5]}      == 5'b11111)    ?   ~CHARACTER0_TMP:    // Lowres 96-128 Inverse
                                                                                             CHARACTER0_TMP;    // Normal Video

assign CHARACTER4 = ({COCO1,BP,CRES[0],CHAR_LATCH_1_TMP[15],BLINK}      == 5'b00111)    ?    8'h00:             // Hires Text blink
                    ({COCO1,BP,CRES[0],CHAR_LATCH_1_TMP[14],UNDERLINE}  == 5'b00111)    ?    8'h7E:             // Underline
                                                                                             CHARACTER2_TMP;    // Normal Video

assign SG6_ENABLE = SWITCH & VID_CONT[0];

assign PIXEL_X =
// CoCo1 Text
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b00001000)                         ?   {6'b000011,CSS,~CHARACTER0[7]}:        // 12, 13, 14, 15
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b00011000)                         ?   {6'b000011,CSS,~CHARACTER0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b00101000)                         ?   {6'b000011,CSS,~CHARACTER0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b00111000)                         ?   {6'b000011,CSS,~CHARACTER0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b01001000)                         ?   {6'b000011,CSS,~CHARACTER0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b01011000)                         ?   {6'b000011,CSS,~CHARACTER0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b01101000)                         ?   {6'b000011,CSS,~CHARACTER0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b01111000)                         ?   {6'b000011,CSS,~CHARACTER0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b10001000)                         ?   {6'b000011,CSS,~CHARACTER0[3]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b10011000)                         ?   {6'b000011,CSS,~CHARACTER0[3]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b10101000)                         ?   {6'b000011,CSS,~CHARACTER0[2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b10111000)                         ?   {6'b000011,CSS,~CHARACTER0[2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b11001000)                         ?   {6'b000011,CSS,~CHARACTER0[1]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b11011000)                         ?   {6'b000011,CSS,~CHARACTER0[1]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b11101000)                         ?   {6'b000011,CSS,~CHARACTER0[0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7]} == 8'b11111000)                         ?   {6'b000011,CSS,~CHARACTER0[0]}:

// SG4, SG8, SG12, SG24
// Lines 0-5
// Pixel Set
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0000100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0001100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0010100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0011100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0100100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0101100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0110100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0111100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1000100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1001100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1010100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1011100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1100100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1101100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1110100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1111100111)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
// Pixel Clear, default background palette
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0000100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0001100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0010100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0011100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0100100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0101100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0110100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[1]} == 10'b0111100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1000100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1001100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1010100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1011100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1100100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1101100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1110100110)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[0]} == 10'b1111100110)  ?   8'b00001100:
// Lines 6-11
// Pixel Set
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0000100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0001100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0010100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0011100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0100100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0101100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0110100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0111100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1000100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1001100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1010100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1011100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1100100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1101100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1110100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1111100101)  ?   {5'b00000,CHAR_LATCH_0[6:4]}:
// Pixel Clear
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0000100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0001100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0010100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0011100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0100100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0101100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0110100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[3]} == 10'b0111100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1000100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1001100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1010100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1011100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1100100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1101100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1110100100)  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,CHAR_LATCH_0[7],SIX,CHAR_LATCH_0[2]} == 10'b1111100100)  ?   8'b00001100:

// SG6
// Lines 0-3
// Pixel Set
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0000101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0001101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0010101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0011101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0100101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0101101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0110101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0111101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1000101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1001101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1010101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1011101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1100101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1101101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1110101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1111101101)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
// Pixel Clear
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0000101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0001101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0010101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0011101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0100101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0101101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0110101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[1]} == 10'b0111101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1000101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1001101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1010101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1011101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1100101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1101101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1110101100)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[0]} == 10'b1111101100)                  ?   8'b00001100:
// Lines 4-7
// Pixel Set
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0000101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0001101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0010101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0011101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0100101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0101101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0110101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0111101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1000101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1001101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1010101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1011101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1100101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1101101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1110101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1111101011)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
// Pixel Clear
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0000101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0001101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0010101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0011101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0100101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0101101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0110101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[3]} == 10'b0111101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1000101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1001101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1010101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1011101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1100101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1101101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1110101010)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[2]} == 10'b1111101010)                  ?   8'b00001100:
// Lines 8-11
// Pixel Set
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0000101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0001101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0010101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0011101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0100101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0101101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0110101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0111101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1000101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1001101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1010101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1011101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1100101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1101101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1110101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1111101001)                  ?   {5'b00000,CSS,CHAR_LATCH_0[7:6]}:
// Pixel Clear
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0000101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0001101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0010101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0011101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0100101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0101101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0110101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[5]} == 10'b0111101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1000101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1001101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1010101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1011101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1100101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1101101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1110101000)                  ?   8'b00001100:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3],SG6_ENABLE,SG6,CHAR_LATCH_0[4]} == 10'b1111101000)                  ?   8'b00001100:

// CoCo3 HR Text
// 32/40
// Pixel Set
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[7]} ==9'b000000011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[7]} ==9'b000100011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[6]} ==9'b001000011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[6]} ==9'b001100011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[5]} ==9'b010000011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[5]} ==9'b010100011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[4]} ==9'b011000011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[4]} ==9'b011100011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[3]} ==9'b100000011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[3]} ==9'b100100011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[2]} ==9'b101000011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[2]} ==9'b101100011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[1]} ==9'b110000011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[1]} ==9'b110100011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[0]} ==9'b111000011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[0]} ==9'b111100011)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
// Pixel Clear
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[7]} ==9'b000000010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[7]} ==9'b000100010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[6]} ==9'b001000010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[6]} ==9'b001100010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[5]} ==9'b010000010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[5]} ==9'b010100010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[4]} ==9'b011000010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[4]} ==9'b011100010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[3]} ==9'b100000010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[3]} ==9'b100100010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[2]} ==9'b101000010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[2]} ==9'b101100010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[1]} ==9'b110000010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[1]} ==9'b110100010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[0]} ==9'b111000010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[0]} ==9'b111100010)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
// 64/80
// Pixel Set
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[7]} ==9'b000000111)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[6]} ==9'b000100111)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[5]} ==9'b001000111)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[4]} ==9'b001100111)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[3]} ==9'b010000111)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[2]} ==9'b010100111)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[1]} ==9'b011000111)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[0]} ==9'b011100111)                               ?   {5'b00001,CHAR_LATCH_0[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[7]} ==9'b100000111)                               ?   {5'b00001,CHAR_LATCH_1[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[6]} ==9'b100100111)                               ?   {5'b00001,CHAR_LATCH_1[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[5]} ==9'b101000111)                               ?   {5'b00001,CHAR_LATCH_1[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[4]} ==9'b101100111)                               ?   {5'b00001,CHAR_LATCH_1[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[3]} ==9'b110000111)                               ?   {5'b00001,CHAR_LATCH_1[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[2]} ==9'b110100111)                               ?   {5'b00001,CHAR_LATCH_1[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[1]} ==9'b111000111)                               ?   {5'b00001,CHAR_LATCH_1[13:11]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[0]} ==9'b111100111)                               ?   {5'b00001,CHAR_LATCH_1[13:11]}:
// Pixel Clear
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[7]} ==9'b000000110)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[6]} ==9'b000100110)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[5]} ==9'b001000110)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[4]} ==9'b001100110)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[3]} ==9'b010000110)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[2]} ==9'b010100110)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[1]} ==9'b011000110)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER0[0]} ==9'b011100110)                               ?   {5'b00000,CHAR_LATCH_0[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[7]} ==9'b100000110)                               ?   {5'b00000,CHAR_LATCH_1[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[6]} ==9'b100100110)                               ?   {5'b00000,CHAR_LATCH_1[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[5]} ==9'b101000110)                               ?   {5'b00000,CHAR_LATCH_1[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[4]} ==9'b101100110)                               ?   {5'b00000,CHAR_LATCH_1[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[3]} ==9'b110000110)                               ?   {5'b00000,CHAR_LATCH_1[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[2]} ==9'b110100110)                               ?   {5'b00000,CHAR_LATCH_1[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[1]} ==9'b111000110)                               ?   {5'b00000,CHAR_LATCH_1[10:8]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0],CHARACTER2[0]} ==9'b111100110)                               ?   {5'b00000,CHAR_LATCH_1[10:8]}:

// Attribute less HR Text
// 32/40
// Pixel Set / Clear
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b00000000 )                                              ?   {7'b0000000,CHARACTER0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b00010000 )                                              ?   {7'b0000000,CHARACTER0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b00100000 )                                              ?   {7'b0000000,CHARACTER0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b00110000 )                                              ?   {7'b0000000,CHARACTER0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b01000000 )                                              ?   {7'b0000000,CHARACTER0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b01010000 )                                              ?   {7'b0000000,CHARACTER0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b01100000 )                                              ?   {7'b0000000,CHARACTER0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b01110000 )                                              ?   {7'b0000000,CHARACTER0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b10000000 )                                              ?   {7'b0000000,CHARACTER0[3]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b10010000 )                                              ?   {7'b0000000,CHARACTER0[3]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b10100000 )                                              ?   {7'b0000000,CHARACTER0[2]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b10110000 )                                              ?   {7'b0000000,CHARACTER0[2]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b11000000 )                                              ?   {7'b0000000,CHARACTER0[1]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b11010000 )                                              ?   {7'b0000000,CHARACTER0[1]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b11100000 )                                              ?   {7'b0000000,CHARACTER0[0]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b11110000 )                                              ?   {7'b0000000,CHARACTER0[0]}:
// 64/80
// Pixel Set / Clear
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b00000010 )                                              ?   {7'b0000000,CHARACTER0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b00010010 )                                              ?   {7'b0000000,CHARACTER0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b00100010 )                                              ?   {7'b0000000,CHARACTER0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b00110010 )                                              ?   {7'b0000000,CHARACTER0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b01000010 )                                              ?   {7'b0000000,CHARACTER0[3]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b01010010 )                                              ?   {7'b0000000,CHARACTER0[2]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b01100010 )                                              ?   {7'b0000000,CHARACTER0[1]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b01110010 )                                              ?   {7'b0000000,CHARACTER0[0]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b10000010 )                                              ?   {7'b0000000,CHARACTER1[7]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b10010010 )                                              ?   {7'b0000000,CHARACTER1[6]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b10100010 )                                              ?   {7'b0000000,CHARACTER1[5]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b10110010 )                                              ?   {7'b0000000,CHARACTER1[4]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b11000010 )                                              ?   {7'b0000000,CHARACTER1[3]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b11010010 )                                              ?   {7'b0000000,CHARACTER1[2]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b11100010 )                                              ?   {7'b0000000,CHARACTER1[1]}:
    ({PIXEL_COUNT[3:0],COCO1,BP,HRES[2],CRES[0]}==8'b11110010 )                                              ?   {7'b0000000,CHARACTER1[0]}:

// CoCo1 graphics
// 4 color 64
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000011000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000111000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001011000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001111000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010011000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010111000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011011000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011111000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100011000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100111000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101011000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101111000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110011000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110111000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111011000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111111000)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:

// 2 color 128
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000011001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000111001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001011001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001111001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010011001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010111001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011011001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011111001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100011001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100111001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101011001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101111001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110011001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110111001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111011001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111111001)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:

    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000011011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000111011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001011011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001111011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010011011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010111011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011011011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011111011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100011011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100111011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101011011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101111011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110011011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110111011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111011011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111111011)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:

    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000011101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000111101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001011101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001111101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010011101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010111101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011011101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011111101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100011101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100111101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101011101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101111101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110011101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110111101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111011101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111111101)                                                 ?   {6'h02,CSS,CHAR_LATCH_0[4]}:

// 4 color 128
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000011010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000111010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001011010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001111010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010011010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010111010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011011010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011111010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100011010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100111010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101011010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101111010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110011010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110111010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111011010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111111010)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:

    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000011100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000111100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001011100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001111100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010011100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010111100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011011100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011111100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100011100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100111100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101011100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101111100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110011100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110111100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111011100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111111100)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:

    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000011110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b000111110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001011110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b001111110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[7:6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010011110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b010111110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011011110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b011111110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[5:4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100011110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b100111110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101011110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b101111110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[3:2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110011110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b110111110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111011110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0]} == 9'b111111110)                                                 ?   {5'h00,CSS,CHAR_LATCH_0[1:0]}:

// 2 color 256
// No Artifacts
// Black/Green and Black/White
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b0000111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b0001111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[7]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b0010111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b0011111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[6]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b0100111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b0101111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[5]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b0110111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b0111111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[4]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b1000111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[3]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b1001111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[3]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b1010111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b1011111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[2]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b1100111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[1]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b1101111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[1]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b1110111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[0]}:
    ({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH} == 10'b1111111110)                                        ?   {6'h02,CSS,CHAR_LATCH_0[0]}:

// Simple Artifacts
// CSS = 1 Artifacting black, orange, blue, and white
// CSS = 0 Artifacting black, orangeish, greenish, and green
// Both Bits Clear
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[7:6]} == 12'b000011111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[7:6]} == 12'b000111111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[7:6]} == 12'b001011111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[7:6]} == 12'b001111111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[5:4]} == 12'b010011111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[5:4]} == 12'b010111111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[5:4]} == 12'b011011111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[5:4]} == 12'b011111111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[3:2]} == 12'b100011111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[3:2]} == 12'b100111111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[3:2]} == 12'b101011111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[3:2]} == 12'b101111111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[1:0]} == 12'b110011111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[1:0]} == 12'b110111111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[1:0]} == 12'b111011111100)                        ?   {8'h10}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[1:0]} == 12'b111111111100)                        ?   {8'h10}:

// Both Bits Set
// 2 Pixels means Green/White
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[7:6]} == 12'b000011111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[7:6]} == 12'b000111111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[7:6]} == 12'b001011111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[7:6]} == 12'b001111111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[5:4]} == 12'b010011111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[5:4]} == 12'b010111111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[5:4]} == 12'b011011111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[5:4]} == 12'b011111111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[3:2]} == 12'b100011111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[3:2]} == 12'b100111111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[3:2]} == 12'b101011111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[3:2]} == 12'b101111111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[1:0]} == 12'b110011111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[1:0]} == 12'b110111111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[1:0]} == 12'b111011111111)                        ?   {3'h0, CSS, 4'hF}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,CHAR_LATCH_0[1:0]} == 12'b111111111111)                        ?   {3'h0, CSS, 4'hF}:

// Phase 1 Bits 01
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0000111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0001111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0010111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0011111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0100111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0101111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0110111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0111111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1000111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1001111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1010111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1011111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1100111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1101111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1110111111101)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1111111111101)                 ?   {3'h0, CSS, 4'h9}:

// Phase 0 Bits 01
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0000111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0001111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0010111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0011111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0100111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0101111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0110111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0111111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1000111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1001111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1010111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1011111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1100111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1101111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1110111111001)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1111111111001)                 ?   {3'h0, CSS, 4'hA}:

// Phase 1 Bits 10
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0000111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0001111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0010111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0011111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0100111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0101111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0110111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0111111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1000111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1001111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1010111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1011111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1100111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1101111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1110111111110)                 ?   {3'h0, CSS, 4'hA}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1111111111110)                 ?   {3'h0, CSS, 4'hA}:

// Phase 0 Bits 10
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0000111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0001111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0010111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[7:6]} == 13'b0011111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0100111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0101111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0110111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[5:4]} == 13'b0111111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1000111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1001111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1010111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[3:2]} == 13'b1011111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1100111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1101111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1110111111010)                 ?   {3'h0, CSS, 4'h9}:
({PIXEL_COUNT[3:0],COCO1,VID_CONT[3:0],SWITCH,PHASE,CHAR_LATCH_0[1:0]} == 13'b1111111111010)                 ?   {3'h0, CSS, 4'h9}:

// CoCo3 Graphics
// 2 color 128/160 = 160/8 = 20
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000100000)                                              ?   {7'h00,CHAR_LATCH_0[7]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010100000)                                              ?   {7'h00,CHAR_LATCH_0[7]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100100000)                                              ?   {7'h00,CHAR_LATCH_0[7]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110100000)                                              ?   {7'h00,CHAR_LATCH_0[7]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000100000)                                              ?   {7'h00,CHAR_LATCH_0[6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010100000)                                              ?   {7'h00,CHAR_LATCH_0[6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100100000)                                              ?   {7'h00,CHAR_LATCH_0[6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110100000)                                              ?   {7'h00,CHAR_LATCH_0[6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000100000)                                              ?   {7'h00,CHAR_LATCH_0[5]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010100000)                                              ?   {7'h00,CHAR_LATCH_0[5]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100100000)                                              ?   {7'h00,CHAR_LATCH_0[5]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110100000)                                              ?   {7'h00,CHAR_LATCH_0[5]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000100000)                                              ?   {7'h00,CHAR_LATCH_0[4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010100000)                                              ?   {7'h00,CHAR_LATCH_0[4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100100000)                                              ?   {7'h00,CHAR_LATCH_0[4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110100000)                                              ?   {7'h00,CHAR_LATCH_0[4]}:

//2 color 256/320 = 320/8 = 40
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000100100)                                              ?   {7'h00,CHAR_LATCH_0[7]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010100100)                                              ?   {7'h00,CHAR_LATCH_0[7]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100100100)                                              ?   {7'h00,CHAR_LATCH_0[6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110100100)                                              ?   {7'h00,CHAR_LATCH_0[6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000100100)                                              ?   {7'h00,CHAR_LATCH_0[5]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010100100)                                              ?   {7'h00,CHAR_LATCH_0[5]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100100100)                                              ?   {7'h00,CHAR_LATCH_0[4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110100100)                                              ?   {7'h00,CHAR_LATCH_0[4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000100100)                                              ?   {7'h00,CHAR_LATCH_0[3]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010100100)                                              ?   {7'h00,CHAR_LATCH_0[3]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100100100)                                              ?   {7'h00,CHAR_LATCH_0[2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110100100)                                              ?   {7'h00,CHAR_LATCH_0[2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000100100)                                              ?   {7'h00,CHAR_LATCH_0[1]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010100100)                                              ?   {7'h00,CHAR_LATCH_0[1]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100100100)                                              ?   {7'h00,CHAR_LATCH_0[0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110100100)                                              ?   {7'h00,CHAR_LATCH_0[0]}:

//2 color 512/640 = 640/8 = 80
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0000010100)                                               ?   {7'h00,CHAR_LATCH_0[7]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0001010100)                                               ?   {7'h00,CHAR_LATCH_0[6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0010010100)                                               ?   {7'h00,CHAR_LATCH_0[5]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0011010100)                                               ?   {7'h00,CHAR_LATCH_0[4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0100010100)                                               ?   {7'h00,CHAR_LATCH_0[3]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0101010100)                                               ?   {7'h00,CHAR_LATCH_0[2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0110010100)                                               ?   {7'h00,CHAR_LATCH_0[1]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0111010100)                                               ?   {7'h00,CHAR_LATCH_0[0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1000010100)                                               ?   {7'h00,CHAR_LATCH_0[15]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1001010100)                                               ?   {7'h00,CHAR_LATCH_0[14]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1010010100)                                               ?   {7'h00,CHAR_LATCH_0[13]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1011010100)                                               ?   {7'h00,CHAR_LATCH_0[12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1100010100)                                               ?   {7'h00,CHAR_LATCH_0[11]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1101010100)                                               ?   {7'h00,CHAR_LATCH_0[10]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1110010100)                                               ?   {7'h00,CHAR_LATCH_0[9]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1111010100)                                               ?   {7'h00,CHAR_LATCH_0[8]}:

//4 Color 64/80 = 80/4 = 20
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000100001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010100001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100100001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110100001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000100001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010100001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100100001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110100001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000100001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010100001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100100001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110100001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000100001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010100001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100100001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110100001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:

//4 Color 128/160 = 160/4 = 40
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000100101)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010100101)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100100101)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110100101)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000100101)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010100101)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100100101)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110100101)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000100101)                                              ?   {6'h00,CHAR_LATCH_0[3:2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010100101)                                              ?   {6'h00,CHAR_LATCH_0[3:2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100100101)                                              ?   {6'h00,CHAR_LATCH_0[3:2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110100101)                                              ?   {6'h00,CHAR_LATCH_0[3:2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000100101)                                              ?   {6'h00,CHAR_LATCH_0[1:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010100101)                                              ?   {6'h00,CHAR_LATCH_0[1:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100100101)                                              ?   {6'h00,CHAR_LATCH_0[1:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110100101)                                              ?   {6'h00,CHAR_LATCH_0[1:0]}:
//4 Color 256/320 = 320/4 = 80
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000101001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010101001)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100101001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110101001)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000101001)                                              ?   {6'h00,CHAR_LATCH_0[3:2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010101001)                                              ?   {6'h00,CHAR_LATCH_0[3:2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100101001)                                              ?   {6'h00,CHAR_LATCH_0[1:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110101001)                                              ?   {6'h00,CHAR_LATCH_0[1:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000101001)                                              ?   {6'h00,CHAR_LATCH_0[15:14]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010101001)                                              ?   {6'h00,CHAR_LATCH_0[15:14]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100101001)                                              ?   {6'h00,CHAR_LATCH_0[13:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110101001)                                              ?   {6'h00,CHAR_LATCH_0[13:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000101001)                                              ?   {6'h00,CHAR_LATCH_0[11:10]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010101001)                                              ?   {6'h00,CHAR_LATCH_0[11:10]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100101001)                                              ?   {6'h00,CHAR_LATCH_0[9:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110101001)                                              ?   {6'h00,CHAR_LATCH_0[9:8]}:

//4 Color 512/640 = 640/4 = 160
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000101101)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010101101)                                              ?   {6'h00,CHAR_LATCH_0[7:6]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100101101)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110101101)                                              ?   {6'h00,CHAR_LATCH_0[5:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000101101)                                              ?   {6'h00,CHAR_LATCH_0[3:2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010101101)                                              ?   {6'h00,CHAR_LATCH_0[3:2]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100101101)                                              ?   {6'h00,CHAR_LATCH_0[1:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110101101)                                              ?   {6'h00,CHAR_LATCH_0[1:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000101101)                                              ?   {6'h00,CHAR_LATCH_0[15:14]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010101101)                                              ?   {6'h00,CHAR_LATCH_0[15:14]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100101101)                                              ?   {6'h00,CHAR_LATCH_0[13:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110101101)                                              ?   {6'h00,CHAR_LATCH_0[13:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000101101)                                              ?   {6'h00,CHAR_LATCH_0[11:10]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010101101)                                              ?   {6'h00,CHAR_LATCH_0[11:10]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100101101)                                              ?   {6'h00,CHAR_LATCH_0[9:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110101101)                                              ?   {6'h00,CHAR_LATCH_1[9:8]}:

//16 Color 32/40 = 40/2 = 20
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110100010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:

//16 Color 64/80 = 80/2 = 40
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000100110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010100110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100100110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110100110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000100110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010100110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100100110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110100110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000100110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010100110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100100110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110100110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000100110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010100110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100100110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110100110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:

//16 Color 128/160 = 160/2 = 80
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000101010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010101010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100101010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110101010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000101010)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010101010)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100101010)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110101010)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000101010)                                              ?   {4'h0,CHAR_LATCH_0[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010101010)                                              ?   {4'h0,CHAR_LATCH_0[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100101010)                                              ?   {4'h0,CHAR_LATCH_0[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110101010)                                              ?   {4'h0,CHAR_LATCH_0[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000101010)                                              ?   {4'h0,CHAR_LATCH_0[11:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010101010)                                              ?   {4'h0,CHAR_LATCH_0[11:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100101010)                                              ?   {4'h0,CHAR_LATCH_0[11:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110101010)                                              ?   {4'h0,CHAR_LATCH_0[11:8]}:

//16 Color 256/320 = 320/2 = 160
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000101110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010101110)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100101110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110101110)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000101110)                                              ?   {4'h0,CHAR_LATCH_0[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010101110)                                              ?   {4'h0,CHAR_LATCH_0[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100101110)                                              ?   {4'h0,CHAR_LATCH_0[11:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110101110)                                              ?   {4'h0,CHAR_LATCH_0[11:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000101110)                                              ?   {4'h0,CHAR_LATCH_1[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010101110)                                              ?   {4'h0,CHAR_LATCH_1[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100101110)                                              ?   {4'h0,CHAR_LATCH_1[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110101110)                                              ?   {4'h0,CHAR_LATCH_1[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000101110)                                              ?   {4'h0,CHAR_LATCH_1[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010101110)                                              ?   {4'h0,CHAR_LATCH_1[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100101110)                                              ?   {4'h0,CHAR_LATCH_1[11:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110101110)                                              ?   {4'h0,CHAR_LATCH_1[11:8]}:

//16 Color 512/640 = 640/2 = 320
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000110010)                                              ?   {4'h0,CHAR_LATCH_0[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010110010)                                              ?   {4'h0,CHAR_LATCH_0[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100110010)                                              ?   {4'h0,CHAR_LATCH_0[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110110010)                                              ?   {4'h0,CHAR_LATCH_0[11:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000110010)                                              ?   {4'h0,CHAR_LATCH_1[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010110010)                                              ?   {4'h0,CHAR_LATCH_1[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100110010)                                              ?   {4'h0,CHAR_LATCH_1[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110110010)                                              ?   {4'h0,CHAR_LATCH_1[11:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000110010)                                              ?   {4'h0,CHAR_LATCH_2[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010110010)                                              ?   {4'h0,CHAR_LATCH_2[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100110010)                                              ?   {4'h0,CHAR_LATCH_2[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110110010)                                              ?   {4'h0,CHAR_LATCH_2[11:8]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000110010)                                              ?   {4'h0,CHAR_LATCH_3[7:4]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010110010)                                              ?   {4'h0,CHAR_LATCH_3[3:0]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100110010)                                              ?   {4'h0,CHAR_LATCH_3[15:12]}:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110110010)                                              ?   {4'h0,CHAR_LATCH_3[11:8]}:

// 256 color 32/40 = 40/1 = 40
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0000010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0001010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0010010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0011010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0100010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0101010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0110010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b0111010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1000010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1001010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1010010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1011010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1100010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1101010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1110010011)                                               ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:2],CRES} == 10'b1111010011)                                               ?   CHAR_LATCH_0[7:0]:

// 256 color 64/80 = 80/1 = 80
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000101011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010101011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100101011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110101011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000101011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010101011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100101011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110101011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000101011)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010101011)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100101011)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110101011)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000101011)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010101011)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100101011)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110101011)                                              ?   CHAR_LATCH_0[15:8]:

// 256 color 128/160 = 160/1 = 160
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000101111)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010101111)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100101111)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110101111)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000101111)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010101111)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100101111)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110101111)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000101111)                                              ?   CHAR_LATCH_1[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010101111)                                              ?   CHAR_LATCH_1[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100101111)                                              ?   CHAR_LATCH_1[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110101111)                                              ?   CHAR_LATCH_1[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000101111)                                              ?   CHAR_LATCH_1[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010101111)                                              ?   CHAR_LATCH_1[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100101111)                                              ?   CHAR_LATCH_1[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110101111)                                              ?   CHAR_LATCH_1[15:8]:

// 256 color 256/320 = 320/1 = 320
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00000110011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00010110011)                                              ?   CHAR_LATCH_0[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00100110011)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b00110110011)                                              ?   CHAR_LATCH_0[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01000110011)                                              ?   CHAR_LATCH_1[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01010110011)                                              ?   CHAR_LATCH_1[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01100110011)                                              ?   CHAR_LATCH_1[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b01110110011)                                              ?   CHAR_LATCH_1[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10000110011)                                              ?   CHAR_LATCH_2[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10010110011)                                              ?   CHAR_LATCH_2[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10100110011)                                              ?   CHAR_LATCH_2[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b10110110011)                                              ?   CHAR_LATCH_2[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11000110011)                                              ?   CHAR_LATCH_3[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11010110011)                                              ?   CHAR_LATCH_3[7:0]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11100110011)                                              ?   CHAR_LATCH_3[15:8]:
({PIXEL_COUNT[3:0],COCO1,BP,HRES[3:1],CRES} == 11'b11110110011)                                              ?   CHAR_LATCH_3[15:8]:

// Default, modes not implemented
                                                                                                                8'h00;

/*****************************************************************************
* Generate RGB
******************************************************************************/
// Border depends on mode
assign BORDER =
// Real Borders
                ({COCO1,VID_CONT[3],CSS} == 3'b110)                             ?   10'h281:                // Green
                ({COCO1,VID_CONT[3],CSS} == 3'b111)                             ?   10'h282:                // White
                ({COCO1,VID_CONT[3]} == 2'b10)                                  ?   10'h280:                // Black
                                                                                    10'h010;                // BDR_PAL

// Clock in Color
always @ (negedge MASTER_CLK)
    if(PIX_CLK == 1'b0 && PIX_CLK_DELAY == 1'b1)
        COLOR <= CCOLOR;

assign CCOLOR[9] =  ({VBLANKING,HBLANKING,COCO1} == 3'b000)                     ?   1'b0:                   // CoCo3 No Artifacts
                    ({VBLANKING,HBLANKING,COCO1,SWITCH} == 4'b0010)             ?   1'b0:                   // CoCo1 No Artifacts
                    ({VBLANKING,HBLANKING,COCO1,SWITCH} == 4'b0011)             ?   (VID_CONT == 4'b1111):  // CoCo1 with simple artifacts depends on mode
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[9]:              // Border
                                                                                    1'b1;                   // Retrace / Artifacting mode

assign CCOLOR[8] =  ({VBLANKING,HBLANKING,COCO1} == 3'b000)                     ?   ({BP,CRES} == 3'b111):  // CoCo3 normal screen depends on 256 color mode
//                    ({VBLANKING,HBLANKING,COCO1} == 3'b001)                     ?   ({VID_CONT[3:0],ARTI} == 6'b111101): //normal screen area in CoCo1 MESS Artifacting mode
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[8]:              // Border
                                                                                    1'b0;

assign CCOLOR[7] =  ({VBLANKING,HBLANKING} == 2'b00)                            ?   PIXEL_X[7]:             // Normal screeen area
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[7]:              // Border
                                                                                    1'b0;                   // Retrace

assign CCOLOR[6] =  ({VBLANKING,HBLANKING} == 2'b00)                            ?   PIXEL_X[6]:             // Normal screeen area
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[6]:              // Border
                                                                                    1'b0;                   // Retrace

assign CCOLOR[5] =  ({VBLANKING,HBLANKING} == 2'b00)                            ?   PIXEL_X[5]:             // Normal screeen area
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[5]:              // Border
                                                                                    1'b0;                   // Retrace

assign CCOLOR[4] =  ({VBLANKING,HBLANKING} == 2'b00)                            ?   PIXEL_X[4]:             // Normal screeen area
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[4]:              // Border
                                                                                    1'b0;                   // Retrace

assign CCOLOR[3] =  ({VBLANKING,HBLANKING} == 2'b00)                            ?   PIXEL_X[3]:             // Normal screeen area
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[3]:              // Border
                                                                                    1'b0;                   // Retrace

assign CCOLOR[2] =  ({VBLANKING,HBLANKING} == 2'b00)                            ?   PIXEL_X[2]:             // Normal screeen area
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[2]:              // Border
                                                                                    1'b0;                   // Retrace

assign CCOLOR[1] =  ({VBLANKING,HBLANKING} == 2'b00)                            ?   PIXEL_X[1]:             // Normal screeen area
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[1]:              // Border
                                                                                    1'b0;                   // Retrace

assign CCOLOR[0] =  ({VBLANKING,HBLANKING} == 2'b00)                            ?   PIXEL_X[0]:             // Normal screeen area
                    ({(VBORDER&HBORDER),(VBLANKING|HBLANKING)} == 2'b11)        ?   BORDER[0]:              // Border
                                                                                    1'b0;                   // Retrace

/*****************************************************************************
* Count pixels across each line
* There are 912 Pixels across the screen
* HS = 80
* FP = 64 
* Border = 44
*  Additional Border = 64 = (640 - 512) / 2
* 80*8 = 640 or 32*16 = 512
* Additional Border = 64  = (640 - 512) / 2
* Border = 44
* BP = 40
* Total = 912
******************************************************************************
HBORDER   has to be 0 for retrace
HBlanking has to be 0 for retrace
HBORDER   has to be 1 for border
HBlanking has to be 1 for border
HBORDER   has to be 1 for main display
HBlanking has to be 0 for main display
******************************************************************************/
always @ (negedge MASTER_CLK)
    if(PIX_CLK == 1'b0 && PIX_CLK_DELAY == 1'b1)
    begin
        case(PIXEL_COUNT)
        11'd015:                            // Turn off horizontal blanking so first character can be displayed
        begin
            HBLANKING <= 1'b0;              // Turn off blanking which starts video
            PIXEL_COUNT  <= 11'd016;        // During 16, video is output
            HBORDER_INT <= 1'b0;            // Every line
        end
        11'd527:                            // 512 + 16 -1
        begin
            if(MODE_256)                    // 512 mode
            begin
                HBLANKING <= 1'b1;          // Turn on blanking, which turns off video
                PIXEL_COUNT  <= 11'd592;    // 528 + 64 = 592
            end
            else                            // 640 mode
            begin
                PIXEL_COUNT  <= 11'd528;    // Continue to display video
            end
        end
        11'd646:
        begin
            HBORDER_INT <= 1'b1;            // 1 1.78 MHz CPU cycle before the end of Video
            PIXEL_COUNT  <= 11'd647;
        end
        11'd655:                            // 640 + 16 - 1
        begin
            HBLANKING <= 1'b1;              // Blanking on which turns off video
            PIXEL_COUNT  <= 11'd656;
        end
        11'd724:                            // End of right border 720 + 44 - 1 (+ 64) start of back porch
        begin
			SYNC_FLAG <= !LINE[0];					// Every other line with the first visable line has sync [addrd SH]
            HBORDER <= 1'b0;                // 736 - 28
            PIXEL_COUNT <= 11'd725;
        end

/**************************************************************************************
// Adjust HSYNC here
**************************************************************************************/
// Width from 87 GIME 5.08 uS = 73 clocks
        11'd751:                            // 824 - 751 = 73 (approx 5.09 uS)
        begin
            HSYNC_N <= 1'b0;                // Turn on Sync
            PIXEL_COUNT <= 11'd752;
        end
        11'd810:                            // End of SYNC start of front porch 804 + 80 - 1, End of Sync to Video = 167 816 + 167 = 
        begin
            HSYNC_N <= 1'b1;                // SYNC OFF
            PIXEL_COUNT <= 11'd811;
        end
/**************************************************************************************
* End of HSYNC adjustment
**************************************************************************************/
        11'd873:                            // Start of Border 824 + 64
        begin
            HBORDER <= 1'b1;                // Start border
            VBORDER_INT <= VBLANKING;       // Interrupt at HBORDER Start on first line after video
            if(MODE_256)
                PIXEL_COUNT <= 11'd874;
            else
                PIXEL_COUNT <= 11'd938;     // Skip 64 extra border of 512 mode
        end
        11'd975:                            // 912 + 64 or 948 + 44 - 16 - 1
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
* MODE_256 = 1 means 512 displayed pixels across the screen
* MODE_256 = 0 means 640 displayed pixels across the screen
******************************************************************************/
assign MODE_256 =    (COCO1 == 1'b1)            ?   1'b1:
                    ({COCO1, HRES[0]}== 2'b00)  ?   1'b1:
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
                    ({COCO1,LPR[2:1]}== 3'b000)     ?   4'b0000:    //  1
                    ({COCO1,LPR}==      4'b0010)    ?   4'b0001:    //  2
                    ({COCO1,LPR}==      4'b0011)    ?   4'b0111:    //  8
                    ({COCO1,LPR}==      4'b0100)    ?   4'b1000:    //  9
                    ({COCO1,LPR}==      4'b0101)    ?   4'b1001:    // 10
                    ({COCO1,LPR}==      4'b0110)    ?   4'b1010:    // 11
                    ({COCO1,LPR}==      4'b0111)    ?   4'b1111:    // Infinite

            // CoCo1
            ({COCO1,VID_CONT[3],V}==    5'b11000)   ?   4'b0010:    //  3    UNK x64
            ({COCO1,VID_CONT[3],V}==    5'b11001)   ?   4'b0010:    //  3    x64
            ({COCO1,VID_CONT[3],V}==    5'b11010)   ?   4'b0010:    //  3    x64

            ({COCO1,VID_CONT[3],V}==    5'b11011)   ?   4'b0001:    //  2    x96
            ({COCO1,VID_CONT[3],V}==    5'b11100)   ?   4'b0001:    //  2    x96

            ({COCO1,VID_CONT[3],V}==    5'b11101)   ?   4'b0000:    //  1    x192
            ({COCO1,VID_CONT[3],V}==    5'b11110)   ?   4'b0000:    //  1    x192
            ({COCO1,VID_CONT[3],V}==    5'b11111)   ?   4'b0000:    //  1    UNK x192

                                                        4'b1011;    // 12

assign SG_VLPR = VLPR + 1'b1;
assign SIX =    (SG_VLPR[3:2] == 2'b00)     ?   1'b0:   //0-3 SG4
                (SG_VLPR[3:1] == 3'b010)    ?   1'b0:   //4-5 SG4
                                                1'b1;   //6-11

assign SG6 = SG_VLPR[3:2];

/************************************
* Generate clock for VSYNC_N by
* Delaying VSYNC_FLAG by 137 pixels
*************************************/
assign VSYNC_N = VSYNC_DELAY[137];
always @ (negedge MASTER_CLK)
    if(PIX_CLK == 1'b0 && PIX_CLK_DELAY == 1'b1)
    begin
        VSYNC_DELAY <= {VSYNC_DELAY[138:0], VSYNC_FLAG};
    end

/*****************************************************************************
* Keeps track of how many lines are in each row.
* Cannot sync to HSYNC (Checking this)
* Maybe can sync posedge HSYNC_N
******************************************************************************/
always @ (negedge MASTER_CLK)
    HBORDER_DELAY <= HBORDER;

always @ (negedge MASTER_CLK)
begin
    // Falling edge of horizontal border
    if((HBORDER == 1'b1) && (HBORDER_DELAY == 1'b0))
    begin
        if(VBLANKING)
        begin
            FIRST <= 1'b1;
            UNDERLINE <= 1'b0;
            ROW_ADD <= 25'h0000000;
            if(COCO1 == 1'b0)
            begin
                //25 bits =          6 bits     +    8 bits    +     8 bits    +     3 bits
                //                   24-19      +    18-11     +     10-3      +     2-0
                SCREEN_START_ADD <= {SCRN_START_HSB, SCRN_START_MSB, SCRN_START_LSB, 3'h0};
                //SCREEN_START_ADD <= 25'h0000000;
            end
            else
            begin
                //25 bits            6 bits     +    3 bits               7 bits + 6 bits               3 bits
                //                   24-19      +    18-16      +         15-9   + 8-3                  2-0
                SCREEN_START_ADD <= {SCRN_START_HSB, SCRN_START_MSB[7:5], VERT,    SCRN_START_LSB[5:0], 3'h0};
            end
            if((COCO1 == 1'b0) && (BP == 1'b1))      // Vertical Fine Scroll not in HR graphics modes
                VLPR <= 4'h0;
            else
                VLPR <= VERT_FIN_SCRL;
        end
        else
        begin
            if(FIRST)						// Skip the first line since Blanking goes away before the HORDER signal
            begin
                FIRST <= 1'b0;
            end
            else
            begin
                if(!COCO1)
                begin
                    case (VLPR)
                    4'h0:                                           // Pixel row 1
                    begin
                        if((LINES_ROW == 4'b0000))                  // 1 line
                            ROW_ADD <= OFFSET;
                        if(LINES_ROW == 4'b0001)                    // 2 lines per row
                            UNDERLINE <= 1'b1;                      // Set underline
                        else
                            UNDERLINE <= 1'b0;
                        if((LINES_ROW == 4'b0000) || ({BP, LINES_ROW} == 5'b11111)) // 1 or infinite graphics mode
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
                        UNDERLINE <= 1'b0;
                        if(LINES_ROW != 4'b1111)   // Infinite
                        begin
                            ROW_ADD <= OFFSET;
                            VLPR <= 4'h0;
                        end
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
end

always @ (negedge MASTER_CLK)
    HSYNC_N_DELAY <= HSYNC_N;

always @ (negedge MASTER_CLK or negedge RESET_N)   // Start of HSYNC
begin
    if(~RESET_N)
    begin
        LINE <= 9'd00;
        VBLANKING <= 1'b1;
        VBORDER <= 1'b0;
        VSYNC_FLAG <= 1'b1;
    end
    else
    begin
        if(HSYNC_N == 1'b0 && HSYNC_N_DELAY == 1'b1)
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
            9'd26: // 225
            begin
                if((LPF == 2'b11)&(!COCO1))
                    VBLANKING <= 1'b0;
                LINE <= 9'd27;
            end
            9'd34: // 210
            begin
                if((LPF == 2'b10)&(!COCO1))
                    VBLANKING <= 1'b0;
                LINE <= 9'd35;
            end
            9'd40: // 200
            begin
                if((LPF == 2'b01)&(!COCO1))
                    VBLANKING <= 1'b0;
                LINE <= 9'd41;
            end
            9'd42: // 192
            begin
                VBLANKING <= 1'b0;
                LINE <= 9'd43;
            end
            9'd234: // 192
            begin
                if((LPF == 2'b00)|(COCO1))
                    VBLANKING <= 1'b1;
                LINE <= 9'd235;
            end
            9'd240: // 200
            begin
                if(LPF == 2'b01)
                    VBLANKING <= 1'b1;
                LINE <= 9'd241;
            end
            9'd244: // 210
            begin
                if(LPF == 2'b10)
                    VBLANKING <= 1'b1;
                LINE <= 9'd245;
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
            end
            default:
            begin
                LINE <= LINE + 1'b1;
            end
            endcase
        end
    end
end
endmodule
