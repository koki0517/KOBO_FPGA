`timescale 1ns / 1ps

module processb #(
  parameter int MEASURING_POINTS = 12
) (
  input  logic        clk,
  input  logic        rst,

  // from processa
  input  logic [15:0] start_angle10_in,
  input  logic [15:0] end_angle10_in,
  input  logic signed [31:0] points_x_q16_16 [0:MEASURING_POINTS-1],
  input  logic signed [31:0] points_y_q16_16 [0:MEASURING_POINTS-1],
  input  logic        points_valid,
  output logic        points_ready,

  // to output FIFO
  output logic [7:0]  dout,
  output logic        wr_en,
  input  logic        fifo_out_full
);

  // Latch inputs on handshake
  logic [15:0] start_angle10_l;
  logic [15:0] end_angle10_l;
  logic signed [31:0] x_l [0:MEASURING_POINTS-1];
  logic signed [31:0] y_l [0:MEASURING_POINTS-1];

  logic busy;
  logic [$clog2(MEASURING_POINTS)-1:0] point_idx;
  logic [2:0] byte_offset;

  integer i;

  // combinational byte selection
  logic [31:0] word32;
  logic [1:0] byte_idx_in_word;
  logic [2:0] byte_offset_tmp;

  always_comb begin
    word32 = 32'd0;
    byte_idx_in_word = 2'd0;
    byte_offset_tmp = 3'd0;

    if (busy) begin
      if (byte_offset < 3'd4) begin
        word32 = x_l[point_idx];
        byte_idx_in_word = byte_offset[1:0];
      end else begin
        word32 = y_l[point_idx];
        byte_offset_tmp = byte_offset - 3'd4;
        byte_idx_in_word = byte_offset_tmp[1:0];
      end
    end

    // MSB -> LSB
    dout = word32[31 - (byte_idx_in_word * 8) -: 8];
  end

  assign wr_en = busy && (~fifo_out_full);
  assign points_ready = ~busy;

  always_ff @(posedge clk) begin
    if (rst) begin
      busy <= 1'b0;
      point_idx <= '0;
      byte_offset <= 3'd0;
      start_angle10_l <= 16'd0;
      end_angle10_l <= 16'd0;
      for (i = 0; i < MEASURING_POINTS; i = i + 1) begin
        x_l[i] <= 32'sd0;
        y_l[i] <= 32'sd0;
      end
    end else begin
      // accept a new frame when idle
      if (~busy) begin
        if (points_valid) begin
          busy <= 1'b1;
          point_idx <= '0;
          byte_offset <= 3'd0;
          start_angle10_l <= start_angle10_in;
          end_angle10_l <= end_angle10_in;
          for (i = 0; i < MEASURING_POINTS; i = i + 1) begin
            x_l[i] <= points_x_q16_16[i];
            y_l[i] <= points_y_q16_16[i];
          end
        end
      end else begin
        // stream out bytes with backpressure from fifo_out_full
        if (~fifo_out_full) begin
          if ((point_idx == (MEASURING_POINTS - 1)) && (byte_offset == 3'd7)) begin
            busy <= 1'b0;
          end else begin
            if (byte_offset == 3'd7) begin
              byte_offset <= 3'd0;
              point_idx <= point_idx + 1'b1;
            end else begin
              byte_offset <= byte_offset + 3'd1;
            end
          end
        end
      end
    end
  end

endmodule
