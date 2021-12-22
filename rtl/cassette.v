
module cassette(

  input clk,
  input Q,
  input rewind,
  input en,

  output reg [24:0] sdram_addr,
  input [7:0] sdram_data,
  output reg sdram_rd,

  output data,
  output [2:0] status

);

assign status = state;

reg old_en;
reg ffrewind;

reg [23:0] seq;
reg [7:0] ibyte;
reg [2:0] state;
reg sq_start;
reg [1:0] eof;
reg name;
wire done;
reg [18:0] hold;

parameter
  IDLE      = 3'h0,
  NEXT      = 3'h2,
  READ1     = 3'h3,
  READ2     = 3'h4,
  READ3     = 3'h5,
  READ4     = 3'h6,
  WAIT      = 3'h7;

reg q_r;

always @(posedge clk) begin
  if (Q==1 && q_r ==0) begin

    old_en <= en;
    if (old_en ^ en) begin
      state <= state == IDLE ? WAIT : IDLE;
      hold <= 19'd445000;
      seq <= 24'd0;
    end

    ffrewind <= rewind;

    case (state)
    WAIT: begin
      ibyte <= 8'd0;
      hold <= hold - 19'd1;
      state <= hold == 0 ? NEXT : WAIT;
    end
    NEXT: begin
      state <= READ1;
      sdram_rd <= 1'b0;
      if (seq == 24'h553c00) name <= 1'd1;
      if (seq == 24'h555555 && name) begin
        name <= 1'd0;
        state <= WAIT;
        hold <= 19'd445000; // 0.5s
        sdram_addr <= sdram_addr - 25'd3;
      end
      if (seq == 24'h553cff) eof <= 2'd1;
      if (seq == 24'h00ff55 && eof == 2'd1) eof <= 2'd2;
      if (~en) state <= IDLE;
    end
    READ1: begin
      sdram_rd <= 1'b1;
      state <= READ2;
    end
    READ2: begin
      ibyte <= sdram_data;
      sdram_rd <= 1'b0;
      state <= READ3;
      sq_start <= 1'b1;
    end
    READ3: begin
      sq_start <= 1'b0;
      state <= done ? READ4 : READ3;
    end
    READ4: begin
      seq <= { seq[15:0], sdram_data };
      sdram_addr <= sdram_addr + 25'd1;
      state <= eof == 2'd2 ? IDLE : NEXT;
    end
    endcase

    if (ffrewind ^ rewind) begin
      seq <= 24'd0;
      sdram_addr <= 25'd0;
      state <= IDLE;
      eof <= 2'd0;
    end

  end
  q_r <= Q;
end

square_gen sq(
  .clk(clk),
  .Q(Q),
  .start(sq_start),
  .din(ibyte),
  .done(done),
  .dout(data)
);


endmodule
