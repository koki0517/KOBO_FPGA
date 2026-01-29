`timescale 1ns / 1ps

module processb (
  input  logic        clk,
  input  logic        rst,
  input  logic [15:0] start_angle10_in,   // 0.1度単位 (例: 180度 -> 1800)
  input  logic [15:0] end_angle10_in,     // 0.1度単位
  // points_x_q16_16 は距離 r を Q16.16 として受け取る想定
  input  logic signed [31:0] points_x_q16_16 [0:11],
  // points_y_q16_16 は未使用 (強度など) として受け取る想定
  input  logic signed [31:0] points_y_q16_16 [0:11],
  input  logic        points_valid,
  output logic        points_ready,
  // 出力 FIFO 用 (未使用のため 0 固定)
  output logic [7:0]  dout,
  output logic        wr_en,
  // デバッグ用出力
  output logic        debug_busy,
  output logic        debug_phase_valid,
  output logic [15:0] debug_phase_tdata,
  output logic signed [31:0] debug_bram_x [0:11],
  output logic signed [31:0] debug_bram_y [0:11]
);

  localparam int NUM_POINTS = 12;
  localparam int ANGLE_MAX_10 = 3600; // 0.1度単位で360度

  // CORDIC (Sin/Cos) の位相フォーマット: Scaled Radians (pi radians)
  // 角度(0.1度) -> scaled radians: angle10 / 1800
  // 16bit Q3.13 に変換する
  localparam int PHASE_Q_FRAC = 13;
  localparam int PHASE_SCALE_DEN = 1800 * (1 << 16); // angle10_q16_16 の分母

  // BRAM (推論) - 計算した x,y を保存
  (* ram_style = "block" *) logic signed [31:0] bram_x_q16_16 [0:NUM_POINTS-1];
  (* ram_style = "block" *) logic signed [31:0] bram_y_q16_16 [0:NUM_POINTS-1];

  // 内部レジスタ
  logic [15:0] start_angle10_reg;
  logic [15:0] end_angle10_reg;
  logic signed [31:0] r_points [0:NUM_POINTS-1];

  logic signed [31:0] interval10_q16_16;
  logic signed [31:0] angle10_q16_16;

  logic [3:0] send_index;
  logic [3:0] recv_index;
  logic       busy;

  // CORDIC I/F
  logic        phase_valid;
  logic [15:0] phase_tdata;
  logic        cordic_valid;
  logic [31:0] cordic_tdata;

  // CORDIC インスタンス
  cordic_0 i_cordic (
    .aclk(clk),
    .s_axis_phase_tvalid(phase_valid),
    .s_axis_phase_tdata(phase_tdata),
    .m_axis_dout_tvalid(cordic_valid),
    .m_axis_dout_tdata(cordic_tdata)
  );

  // 出力 FIFO は未使用
  assign dout = 8'h00;
  assign wr_en = 1'b0;

  // デバッグ出力
  assign debug_busy = busy;
  assign debug_phase_valid = phase_valid;
  assign debug_phase_tdata = phase_tdata;

  genvar gi;
  generate
    for (gi = 0; gi < NUM_POINTS; gi = gi + 1) begin : debug_bram_copy
      assign debug_bram_x[gi] = bram_x_q16_16[gi];
      assign debug_bram_y[gi] = bram_y_q16_16[gi];
    end
  endgenerate

  // points_ready: idle のとき受け入れ可能
  assign points_ready = ~busy;

  // 角度(0.1度, Q16.16) -> CORDIC Phase (Q3.13, scaled radians)
  function automatic logic [15:0] angle10_q16_16_to_phase(
    input logic signed [31:0] angle10_q16_16_in
  );
    logic signed [63:0] num;
    logic signed [63:0] tmp;
    begin
      // scaled = angle10 / 1800
      // Q3.13 = scaled * 2^13
      num = angle10_q16_16_in * (1 << PHASE_Q_FRAC);
      tmp = num / PHASE_SCALE_DEN;
      angle10_q16_16_to_phase = tmp[15:0];
    end
  endfunction

  // interval 계산
  function automatic logic signed [31:0] calc_interval_q16_16(
    input logic [15:0] start_angle10,
    input logic [15:0] end_angle10
  );
    logic signed [31:0] delta10;
    begin
      if (start_angle10 > end_angle10) begin
        delta10 = (ANGLE_MAX_10 - start_angle10 + end_angle10);
      end else begin
        delta10 = (end_angle10 - start_angle10);
      end
      calc_interval_q16_16 = (delta10 <<< 16) / 11;
    end
  endfunction

  // 受信完了時に入力をラッチ
  integer i;
  always_ff @(posedge clk) begin
    if (rst) begin
      start_angle10_reg <= 16'd0;
      end_angle10_reg <= 16'd0;
      interval10_q16_16 <= 32'sd0;
      send_index <= 4'd0;
      recv_index <= 4'd0;
      busy <= 1'b0;
      for (i = 0; i < NUM_POINTS; i = i + 1) begin
        r_points[i] <= 32'sd0;
        bram_x_q16_16[i] <= 32'sd0;
        bram_y_q16_16[i] <= 32'sd0;
      end
    end else begin
      if (points_valid && points_ready) begin
        start_angle10_reg <= start_angle10_in;
        end_angle10_reg <= end_angle10_in;
        interval10_q16_16 <= calc_interval_q16_16(start_angle10_in, end_angle10_in);
        for (i = 0; i < NUM_POINTS; i = i + 1) begin
          r_points[i] <= points_x_q16_16[i];
        end
        send_index <= 4'd0;
        recv_index <= 4'd0;
        busy <= 1'b1;
      end

      // CORDIC 出力を受け取ったら x,y を計算して BRAM に格納
      if (cordic_valid && busy) begin
        logic signed [31:0] cos_q2_14;
        logic signed [31:0] sin_q2_14;
        logic signed [63:0] x_mult;
        logic signed [63:0] y_mult;

        cos_q2_14 = {{16{cordic_tdata[31]}}, cordic_tdata[31:16]};
        sin_q2_14 = {{16{cordic_tdata[15]}}, cordic_tdata[15:0]};

        x_mult = r_points[recv_index] * cos_q2_14;
        y_mult = r_points[recv_index] * sin_q2_14;

        // Q16.16 (r) * Q2.14 (sin/cos) -> Q18.30
        // Q16.16 に戻すため >> 14
        bram_x_q16_16[recv_index] <= x_mult >>> 14;
        bram_y_q16_16[recv_index] <= y_mult >>> 14;

        if (recv_index == NUM_POINTS - 1) begin
          busy <= 1'b0;
        end else begin
          recv_index <= recv_index + 4'd1;
        end
      end

      // CORDIC へ位相を送るたびにインデックスを進める
      if (busy && phase_valid) begin
        if (send_index < NUM_POINTS - 1) begin
          send_index <= send_index + 4'd1;
        end
      end

      if (!busy) begin
        send_index <= 4'd0;
      end
    end
  end

  // 送信する角度を生成して CORDIC に入力
  always_comb begin
    phase_valid = 1'b0;
    phase_tdata = 16'sd0;
    angle10_q16_16 = 32'sd0;

    if (busy && send_index < NUM_POINTS) begin
      // angle10_q16_16 = start + interval * i
      angle10_q16_16 = ({{16{1'b0}}, start_angle10_reg} <<< 16)
                       + (interval10_q16_16 * send_index);

      // wrap (0 .. 3600)
      if (angle10_q16_16 >= (ANGLE_MAX_10 <<< 16)) begin
        angle10_q16_16 = angle10_q16_16 - (ANGLE_MAX_10 <<< 16);
      end

      phase_tdata = angle10_q16_16_to_phase(angle10_q16_16);
      phase_valid = 1'b1;
    end
  end

endmodule
