`timescale 1ns / 1ps

module processb #(
  parameter int MEASURING_POINTS = 12,
  // Angle unit coming from processa is assumed to be centi-degrees (0.01 deg): 0..35999.
  parameter int ANGLE_SCALE = 100,
  parameter int ANGLE_BINS  = 360
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

  localparam int ANGLE_FULL = ANGLE_BINS * ANGLE_SCALE;
  localparam int POINTS_MINUS1 = (MEASURING_POINTS - 1);

  // Latch inputs on handshake
  logic [15:0] start_angle10_l;
  logic [15:0] end_angle10_l;
  logic [31:0] interval_centi_l;
  logic signed [31:0] x_l [0:MEASURING_POINTS-1];
  logic signed [31:0] y_l [0:MEASURING_POINTS-1];

  // 360-degree map (one slot per integer degree)
  logic signed [31:0] map_x_q16_16 [0:ANGLE_BINS-1];
  logic signed [31:0] map_y_q16_16 [0:ANGLE_BINS-1];
  logic              map_valid    [0:ANGLE_BINS-1];

  typedef enum logic [1:0] {
    ST_IDLE,
    ST_UPDATE,
    ST_STREAM
  } st_t;

  st_t st;

  logic [$clog2(MEASURING_POINTS)-1:0] update_idx;
  logic [$clog2(MEASURING_POINTS)-1:0] point_idx;
  logic [2:0] byte_offset;

  integer i;
  integer j;

  logic [31:0] delta_centi;
  logic [31:0] angle_centi;
  logic [31:0] angle_centi_wrapped;
  logic [$clog2(ANGLE_BINS)-1:0] angle_bin;

  // combinational byte selection
  logic [31:0] word32;
  logic [1:0] byte_idx_in_word;
  logic [2:0] byte_offset_tmp;

  always_comb begin
    word32 = 32'd0;
    byte_idx_in_word = 2'd0;
    byte_offset_tmp = 3'd0;

    if (st == ST_STREAM) begin
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

  assign wr_en = (st == ST_STREAM) && (~fifo_out_full);
  assign points_ready = (st == ST_IDLE);

  always_ff @(posedge clk) begin
    if (rst) begin
      st <= ST_IDLE;
      update_idx <= '0;
      point_idx <= '0;
      byte_offset <= 3'd0;
      start_angle10_l <= 16'd0;
      end_angle10_l <= 16'd0;
      interval_centi_l <= 32'd0;
      for (i = 0; i < MEASURING_POINTS; i = i + 1) begin
        x_l[i] <= 32'sd0;
        y_l[i] <= 32'sd0;
      end
      for (j = 0; j < ANGLE_BINS; j = j + 1) begin
        map_x_q16_16[j] <= 32'sd0;
        map_y_q16_16[j] <= 32'sd0;
        map_valid[j] <= 1'b0;
      end
    end else begin
      case (st)
        ST_IDLE: begin
          if (points_valid) begin
            start_angle10_l <= start_angle10_in;
            end_angle10_l <= end_angle10_in;

            // delta in centi-degrees with wrap-around
            if (end_angle10_in >= start_angle10_in) begin
              delta_centi = end_angle10_in - start_angle10_in;
            end else begin
              delta_centi = end_angle10_in + ANGLE_FULL - start_angle10_in;
            end
            // interval in centi-degrees across 12 points (11 intervals), with rounding
            interval_centi_l <= (delta_centi + (POINTS_MINUS1/2)) / POINTS_MINUS1;

            for (i = 0; i < MEASURING_POINTS; i = i + 1) begin
              x_l[i] <= points_x_q16_16[i];
              y_l[i] <= points_y_q16_16[i];
            end

            update_idx <= '0;
            st <= ST_UPDATE;
          end
        end

        ST_UPDATE: begin
          // angle for this point: start + idx * interval (centi-deg)
          angle_centi = $unsigned(start_angle10_l) + ($unsigned(update_idx) * interval_centi_l);
          if (angle_centi >= ANGLE_FULL) begin
            angle_centi_wrapped = angle_centi - ANGLE_FULL;
          end else begin
            angle_centi_wrapped = angle_centi;
          end
          angle_bin = angle_centi_wrapped / ANGLE_SCALE;

          map_x_q16_16[angle_bin] <= x_l[update_idx];
          map_y_q16_16[angle_bin] <= y_l[update_idx];
          map_valid[angle_bin] <= 1'b1;

          if (update_idx == (MEASURING_POINTS - 1)) begin
            point_idx <= '0;
            byte_offset <= 3'd0;
            st <= ST_STREAM;
          end else begin
            update_idx <= update_idx + 1'b1;
          end
        end

        ST_STREAM: begin
          // stream out bytes with backpressure from fifo_out_full
          if (~fifo_out_full) begin
            if ((point_idx == (MEASURING_POINTS - 1)) && (byte_offset == 3'd7)) begin
              st <= ST_IDLE;
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

        default: st <= ST_IDLE;
      endcase
    end
  end

endmodule
