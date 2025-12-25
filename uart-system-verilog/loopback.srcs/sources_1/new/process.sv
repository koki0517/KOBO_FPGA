`timescale 1ns / 1ps

module processa #(
  parameter [31:0] CLOCK_FREQUENCY = 32'd50_000_000
) (
  input  logic        clk,
  input  logic        rst,
  input  logic [7:0]  din,      // FIFO の出力（読み出したバイト）
  input  logic        empty,    // FIFO が空かどうかのフラグ
  output logic        re,       // FIFO 読み出しイネーブル（次のバイトを読み出すための1サイクルパルス）
  // processb へ渡す計算結果
  output logic [15:0] start_angle10_out,
  output logic [15:0] end_angle10_out,
  output logic signed [31:0] points_x_q16_16 [0:11],
  output logic signed [31:0] points_y_q16_16 [0:11],
  output logic        points_valid,
  input  logic        points_ready,
  output logic        led_enable
);

  // パケット / タイムアウトの定義
  localparam int PAYLOAD_LEN = 45; // ペイロード長（バイト数）
  localparam int MEASURING_POINTS = 12; // 測定点の数（固定）
  localparam [31:0] TIMEOUT_MAX = (CLOCK_FREQUENCY * 2) - 1; // 2秒

  // FSM（状態機械）の状態
  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_CHECK1,        // ヘッダ1バイト目を検出（値は din に入っている）
    STATE_CHECK2,        // ヘッダ2バイト目を検出（値は din に入っている）
    STATE_RECEIVE_PAYLOAD,
    STATE_OUTPUT_READY,
    STATE_CORDIC_SEND,
    STATE_CORDIC_WAIT
  } state_t;

  state_t state, next_state;

  // 内部レジスタ
  logic read_req;
  // 読み出し要求をクロック同期で保持（FIFO の出力が 1 クロック遅れるため）
  logic read_req_reg;
  logic [5:0] byte_counter; // 45バイト分をカウントできる幅
  // ペイロードバッファ（受信したペイロードを一時保存）
  logic [7:0] payload [0:PAYLOAD_LEN-1];
  // CORDIC関連
  logic [3:0] cordic_idx; // 0..11
  logic s_axis_phase_tvalid_reg;
  logic [15:0] s_axis_phase_tdata_reg;
  wire m_axis_dout_tvalid_wire;
  wire [31:0] m_axis_dout_tdata_wire;
  // 結果保存（raw 16bit each）
  logic signed [15:0] cordic_cos [0:MEASURING_POINTS-1];
  logic signed [15:0] cordic_sin [0:MEASURING_POINTS-1];
  // 各点の距離(mm) と X/Y 結果 (Q16.16, signed 32bit)
  logic [15:0] distance_mm [0:MEASURING_POINTS-1];
  logic [31:0] timeout_cnt;
  logic led_en_reg;
  // start/end angle (raw, units = degrees * 10: e.g., 180deg -> 1800)
  logic [15:0] start_angle10;
  logic [15:0] end_angle10;
  // start in Q8.8 (degrees * 2^8)
  logic signed [31:0] start_q8_8;
  // interval in Q8.8 fixed-point representing degrees
  localparam int INTERVAL_FRAC = 8;
  logic [15:0] interval_q8_8;
  // temporary for delta computation (in tenths of degree)
  logic [31:0] delta_tenths;
  // temporaries used across states (declare at module scope to be XSV compatible)
  logic [15:0] d16_temp;
  logic signed [47:0] mult_x_temp;
  logic signed [47:0] mult_y_temp;
  // CORDIC angle temporaries
  logic signed [31:0] angle_q8_8;
  logic signed [31:0] angle_wrapped_q8_8;
  logic signed [31:0] angle_signed_q8_8;
  logic signed [31:0] tmp_phase;
  logic signed [31:0] phase_int;

  // Angle scaling: packet uses 0.01 degree units (centi-degrees)
  localparam int ANGLE_SCALE = 100;
  localparam int ANGLE_FULL  = 360 * ANGLE_SCALE; // 36000
  localparam int ANGLE_POINTS_MINUS1 = (MEASURING_POINTS - 1); // 11
  localparam int INTERVAL_DENOM = ANGLE_SCALE * ANGLE_POINTS_MINUS1; // 1100

  // CORDIC IP (`cordic_0`) is treated as fixed configuration:
  // - Phase format: Scaled_Radians with pi => 0x2000 (8192)
  // - Output format: signed Q2.14 (e.g. cos(0)=0x4000)
  // - Output packing: upper16=sin, lower16=cos
  localparam int CORDIC_TRIG_FRAC = 14;
  localparam int XY_FRAC          = 16;
  localparam int CORDIC_TO_XY_SHIFT = (XY_FRAC - CORDIC_TRIG_FRAC); // 2
  localparam int CORDIC_PHASE_PI  = 8192;  // 0x2000
  localparam int CORDIC_PHASE_MAX = (CORDIC_PHASE_PI - 1); // 8191
  localparam int CORDIC_PHASE_MIN = (-CORDIC_PHASE_PI);    // -8192
  // With INTERVAL_FRAC=8 (Q8.8 deg), this becomes 8192 / 256 = 32.
  localparam int CORDIC_PHASE_MULT = (CORDIC_PHASE_PI >> INTERVAL_FRAC);

  integer reset_i;

  assign re = read_req;
  assign led_enable = led_en_reg;
  // CORDIC IP 接続
  wire s_axis_phase_tvalid;
  wire [15:0] s_axis_phase_tdata;
  assign s_axis_phase_tvalid = s_axis_phase_tvalid_reg;
  assign s_axis_phase_tdata = s_axis_phase_tdata_reg;

  // Cordic IP instance
  cordic_0 cordic_inst (
    .aclk(clk),
    .s_axis_phase_tvalid(s_axis_phase_tvalid),
    .s_axis_phase_tdata(s_axis_phase_tdata),
    .m_axis_dout_tvalid(m_axis_dout_tvalid_wire),
    .m_axis_dout_tdata(m_axis_dout_tdata_wire)
  );

  // 順序回路：状態、カウンタ、タイムアウトの更新
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= STATE_IDLE;
      byte_counter <= 6'd0;
      timeout_cnt <= TIMEOUT_MAX; // タイムアウト済み -> 初期状態は LED オフ
      led_en_reg <= 1'b0;

      start_angle10_out <= 16'd0;
      end_angle10_out <= 16'd0;
      points_valid <= 1'b0;

      read_req_reg <= 1'b0;
      start_angle10 <= 16'd0;
      end_angle10 <= 16'd0;
      start_q8_8 <= 32'sd0;
      delta_tenths <= 32'd0;
      interval_q8_8 <= 16'd0;

      cordic_idx <= 4'd0;

      for (reset_i = 0; reset_i < MEASURING_POINTS; reset_i = reset_i + 1) begin
        cordic_cos[reset_i] <= 16'sd0;
        cordic_sin[reset_i] <= 16'sd0;
        distance_mm[reset_i] <= 16'd0;
        points_x_q16_16[reset_i] <= 32'sd0;
        points_y_q16_16[reset_i] <= 32'sd0;
      end
    end else begin
      state <= next_state;

      // タイムアウト: CHECK1 で 0x54 を観測したらリセット
      if (state == STATE_CHECK1 && din == 8'h54) begin
        timeout_cnt <= 32'd0;
        led_en_reg <= 1'b1;
      end else if (timeout_cnt < TIMEOUT_MAX) begin
        timeout_cnt <= timeout_cnt + 32'd1;
      end else begin
        timeout_cnt <= TIMEOUT_MAX;
        led_en_reg <= 1'b0;
      end

      // ペイロードのバイトを取り込み（FIFO を消費）
      // read_req_reg を用いて、実際に FIFO からデータが出てきたタイミングで
      // din を読み込む（FIFO の re -> dout が 1 クロック遅延する想定）
      if (read_req_reg && state == STATE_RECEIVE_PAYLOAD) begin
        // 読み出したバイトをバッファに保存し、カウントを進める
        payload[byte_counter] <= din;
        byte_counter <= byte_counter + 6'd1;
      end

      // IDLE へ戻るときにバイトカウンタをリセット
      if (next_state == STATE_IDLE) begin
        byte_counter <= 6'd0;
      end

      // 計算完了(OUTPUT_READYへ遷移)で valid を立てる
      if (state != STATE_OUTPUT_READY && next_state == STATE_OUTPUT_READY) begin
        points_valid <= 1'b1;
      end
      // processb が受理したら valid を落とす
      if (points_valid && points_ready) begin
        points_valid <= 1'b0;
      end

      // CORDIC_SEND へ入るサイクルは start/end 取り出しと interval を計算
      if (state != STATE_CORDIC_SEND && next_state == STATE_CORDIC_SEND) begin
        // ここで payload から start/end を取り出して interval を計算する
        // payload の構成 (byte index):
        // [0..1]=Speed, [2..3]=StartAngle(LSB,MSB), [4..39]=Data, [40..41]=EndAngle(LSB,MSB), [42..43]=Timestamp, [44]=CRC
        start_angle10 <= {payload[3], payload[2]};
        end_angle10   <= {payload[41], payload[40]};

        start_angle10_out <= {payload[3], payload[2]};
        end_angle10_out   <= {payload[41], payload[40]};

        // start_q8_8 = start_angle(centi-deg) * 256 / 100
        // NOTE: use payload directly to avoid NBA dependency on start_angle10
        start_q8_8 <= ( ({payload[3], payload[2]} * 32'd256) + (ANGLE_SCALE/2) ) / ANGLE_SCALE;

        // delta (in centi-degrees) with wrap-around handling
        if ({payload[41], payload[40]} >= {payload[3], payload[2]}) begin
          delta_tenths <= {payload[41], payload[40]} - {payload[3], payload[2]};
        end else begin
          delta_tenths <= {payload[41], payload[40]} + ANGLE_FULL - {payload[3], payload[2]};
        end

        // interval (degrees) = delta_centi / (100*11)
        // interval_q8_8 = (delta_centi * 2^FRAC) / (100*11)
        // NOTE: compute from payload directly to avoid NBA dependency on delta_tenths
        interval_q8_8 <= (
          (
            (
              (
                ({payload[41], payload[40]} >= {payload[3], payload[2]}) ?
                  ({payload[41], payload[40]} - {payload[3], payload[2]}) :
                  ({payload[41], payload[40]} + ANGLE_FULL - {payload[3], payload[2]})
              )
              * (1 << INTERVAL_FRAC)
            )
            + (INTERVAL_DENOM/2)
          )
          / INTERVAL_DENOM
        );
      end

      // STATE_CORDIC_SEND へ入るサイクルは cordic_idx を初期化
      if (state != STATE_CORDIC_SEND && next_state == STATE_CORDIC_SEND) begin
        cordic_idx <= 4'd0;
      end

      // read_req_reg を更新して次サイクルに capture を行えるようにする
      read_req_reg <= read_req;

      // CORDIC 出力を受け取り、配列に保存
      if (state == STATE_CORDIC_WAIT && m_axis_dout_tvalid_wire) begin
        // m_axis_dout_tdata_wire: upper 16 bits = sin, lower 16 bits = cos
        // CORDIC output is signed fixed-point Q2.14 in this configuration.
        cordic_sin[cordic_idx] <= $signed(m_axis_dout_tdata_wire[31:16]);
        cordic_cos[cordic_idx] <= $signed(m_axis_dout_tdata_wire[15:0]);
        // 距離を payload から取り出す
        d16_temp = {payload[4 + cordic_idx*3 + 1], payload[4 + cordic_idx*3]};
        distance_mm[cordic_idx] <= d16_temp;
        // multiply distance * cos/sin -> result is Q16.14 (since trig is Q2.14)
        // shift left by 2 to convert to Q16.16
        // use wider intermediate to avoid overflow
        mult_x_temp = $signed({16'd0, d16_temp}) * $signed(m_axis_dout_tdata_wire[15:0]);  // cos
        mult_y_temp = $signed({16'd0, d16_temp}) * $signed(m_axis_dout_tdata_wire[31:16]);  // sin
        mult_x_temp = mult_x_temp <<< CORDIC_TO_XY_SHIFT;
        mult_y_temp = mult_y_temp <<< CORDIC_TO_XY_SHIFT;
        // clamp to 32-bit signed
        if (mult_x_temp > 48'sd2147483647) points_x_q16_16[cordic_idx] <= 32'sd2147483647;
        else if (mult_x_temp < -48'sd2147483648) points_x_q16_16[cordic_idx] <= -32'sd2147483648;
        else points_x_q16_16[cordic_idx] <= mult_x_temp[31:0];
        if (mult_y_temp > 48'sd2147483647) points_y_q16_16[cordic_idx] <= 32'sd2147483647;
        else if (mult_y_temp < -48'sd2147483648) points_y_q16_16[cordic_idx] <= -32'sd2147483648;
        else points_y_q16_16[cordic_idx] <= mult_y_temp[31:0];

        cordic_idx <= cordic_idx + 4'd1;
      end
    end
  end

  // 組合せ回路：次状態と読み書き制御
  always_comb begin
    // デフォルト値
    next_state = state;
    read_req = 1'b0;
    // CORDIC defaults
    s_axis_phase_tvalid_reg = 1'b0;
    s_axis_phase_tdata_reg = 16'h0000;

    case (state)
      STATE_IDLE: begin
        // 走査を開始：FIFO が空でなければ読み出し要求を出す
        if (~empty) begin
          read_req = 1'b1;
          next_state = STATE_CHECK1; // 次サイクルで din にバイトが入る
        end
      end

      STATE_CHECK1: begin
        // 'din' は前サイクルに読み出したバイト
        if (din == 8'h54) begin
          // ヘッダの1バイト目が一致したので、2バイト目が来ていれば読み出し要求
          if (~empty) begin
            read_req = 1'b1;
            next_state = STATE_CHECK2;
          end else begin
            next_state = STATE_CHECK1; // 2バイト目が来るのを待つ
          end
        end else begin
          next_state = STATE_IDLE; // ヘッダでない場合は走査を再開
        end
      end

      STATE_CHECK2: begin
        // 'din' は 2 バイト目の値
        if (din == 8'h2c) begin
          // ヘッダ一致：次サイクルからペイロード受信状態へ移行
          // （読み出し要求は RECEIVE_PAYLOAD 側で出す。ここで出すと
          //  2nd header（VerLen）が payload として誤って取り込まれる可能性がある）
          next_state = STATE_RECEIVE_PAYLOAD;
        end else begin
          next_state = STATE_IDLE; // 2 バイト目が不正
        end
      end

      STATE_RECEIVE_PAYLOAD: begin
        // ペイロードのバイトを読み出してカウントする。
        // 最後のバイトを読み出す直前に読み出し要求を出し、SEND_ACK に遷移して
        // 読み出し後に ACK を送信できるようにする。
        if (byte_counter == (PAYLOAD_LEN - 1)) begin
          // 最後のバイトを読み出すための最終読み出しが必要
          if (~empty) begin
            read_req = 1'b1;
            // CRC まで受信完了したら、CORDIC を使って12点分の sin/cos->x,y を計算する
            next_state = STATE_CORDIC_SEND;
          end else begin
            next_state = STATE_RECEIVE_PAYLOAD; // 最後のバイトが来るのを待つ
          end
        end else begin
          // まだ終了していない - 次のバイトがあれば読み出す
          if (~empty) begin
            read_req = 1'b1;
            next_state = STATE_RECEIVE_PAYLOAD;
          end else begin
            next_state = STATE_RECEIVE_PAYLOAD; // 待機
          end
        end
      end

      STATE_OUTPUT_READY: begin
        // 点群 + start/end angle は順序回路で保持済み。
        // processb が受理するまでここで待つ。
        if (points_valid && points_ready) begin
          next_state = STATE_IDLE;
        end else begin
          next_state = STATE_OUTPUT_READY;
        end
      end

      STATE_CORDIC_SEND: begin
        // Compute phase for cordic based on start_q8_8 and interval_q8_8
        // angle_q8_8 = start_q8_8 + cordic_idx * interval_q8_8
        // wrap in [0,360)
        angle_q8_8 = start_q8_8 + $signed(interval_q8_8) * $signed({28'd0, cordic_idx});
        angle_wrapped_q8_8 = 32'sd0;
        angle_signed_q8_8 = 32'sd0;
        tmp_phase = 32'sd0;
        // modular reduce by 360 degrees
        if (angle_q8_8 >= (32'sd360 << INTERVAL_FRAC)) begin
          angle_wrapped_q8_8 = angle_q8_8 - (32'sd360 << INTERVAL_FRAC);
        end else begin
          angle_wrapped_q8_8 = angle_q8_8;
        end
        // map to signed -180..180 range
        if (angle_wrapped_q8_8 > (32'sd180 << INTERVAL_FRAC)) begin
          angle_signed_q8_8 = angle_wrapped_q8_8 - (32'sd360 << INTERVAL_FRAC);
        end else begin
          angle_signed_q8_8 = angle_wrapped_q8_8;
        end
        // Phase format (Scaled_Radians) for this core maps pi -> 0x2000 (8192).
        // angle_signed_q8_8 is degrees in Q8.8. Convert:
        // phase = round(angle_deg * CORDIC_PHASE_PI / 180)
        //       = round(angle_q8_8 * (CORDIC_PHASE_PI/2^INTERVAL_FRAC) / 180)
        //       = round(angle_q8_8 * CORDIC_PHASE_MULT / 180)
        if (angle_signed_q8_8 >= 0) begin
          tmp_phase = (angle_signed_q8_8 * CORDIC_PHASE_MULT + 90) / 180;
        end else begin
          tmp_phase = (angle_signed_q8_8 * CORDIC_PHASE_MULT - 90) / 180;
        end
        // Clamp to [CORDIC_PHASE_MIN, CORDIC_PHASE_MAX] which corresponds to [-pi, pi)
        if (tmp_phase > $signed(CORDIC_PHASE_MAX)) begin
          phase_int = $signed(CORDIC_PHASE_MAX);
        end else if (tmp_phase < $signed(CORDIC_PHASE_MIN)) begin
          phase_int = $signed(CORDIC_PHASE_MIN);
        end else begin
          phase_int = tmp_phase;
        end
        s_axis_phase_tvalid_reg = 1'b1;
        s_axis_phase_tdata_reg = phase_int[15:0];
        next_state = STATE_CORDIC_WAIT;
      end

      STATE_CORDIC_WAIT: begin
        // wait for cordic result
        s_axis_phase_tvalid_reg = 1'b0;
        s_axis_phase_tdata_reg = 16'h0000;
        if (m_axis_dout_tvalid_wire) begin
          // capture in sequential block
          if (cordic_idx == (MEASURING_POINTS - 1)) begin
            next_state = STATE_OUTPUT_READY;
          end else begin
            next_state = STATE_CORDIC_SEND;
          end
        end else begin
          next_state = STATE_CORDIC_WAIT;
        end
      end

      default: next_state = STATE_IDLE;
    endcase
  end

endmodule