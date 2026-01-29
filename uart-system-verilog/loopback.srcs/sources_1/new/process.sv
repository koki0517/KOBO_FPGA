`timescale 1ns / 1ps

module processa #(
  parameter [31:0] CLOCK_FREQUENCY = 32'd50_000_000
) (
  input  logic        clk,
  input  logic        rst,
  input  logic [7:0]  din,            // FIFO の出力（読み出したバイト）
  input  logic        empty,          // FIFO が空かどうかのフラグ
  output logic        re,             // FIFO 読み出しイネーブル（次のバイトを読み出すための1サイクルパルス）
  output logic [15:0] start_angle10_out, // 0.1度単位
  output logic [15:0] end_angle10_out,   // 0.1度単位
  output logic signed [31:0] points_x_q16_16 [0:11], // 距離 r を Q16.16 で出力
  output logic signed [31:0] points_y_q16_16 [0:11], // 強度など (未使用時は0)
  output logic        points_valid,
  input  logic        points_ready,
  output logic        led_enable
);

  // パケット / タイムアウトの定義
  localparam int PAYLOAD_LEN = 45; // ペイロード長（バイト数）
  localparam int MEASURING_POINTS = 12; // 測定点の数（固定）
  localparam [31:0] TIMEOUT_MAX = (CLOCK_FREQUENCY * 2) - 1; // 2秒

  // payload index definitions
  localparam int START_ANGLE_LSB = 2;
  localparam int START_ANGLE_MSB = 3;
  localparam int POINTS_START    = 4;  // distance LSB
  localparam int END_ANGLE_LSB   = 40;
  localparam int END_ANGLE_MSB   = 41;

  // FSM states
  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_CHECK1,        // ヘッダ1バイト目を検出（値は din に入っている）
    STATE_CHECK2,        // ヘッダ2バイト目を検出（値は din に入っている）
    STATE_RECEIVE_PAYLOAD,
    STATE_WAIT_READY
  } state_t;

  state_t state, next_state;

  // internal regs
  logic read_req;
  logic read_req_reg;
  logic [5:0] byte_counter; // enough for 45 bytes
  logic [31:0] timeout_cnt;
  logic led_en_reg;

  // payload buffer
  logic [7:0] payload [0:PAYLOAD_LEN-1];
  // ループ内で使用する一時変数（ツール互換のため事前宣言）
  logic [15:0] dist_mm;
  logic [7:0] intensity_val;

  // outputs
  assign re = read_req;
  assign led_enable = led_en_reg;

  // Sequential: state, counters and timeout updates
  integer i;
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= STATE_IDLE;
      byte_counter <= 6'd0;
      timeout_cnt <= TIMEOUT_MAX; // タイムアウト済み -> 初期状態は LED オフ
      led_en_reg <= 1'b0;
      points_valid <= 1'b0;
      start_angle10_out <= 16'd0;
      end_angle10_out <= 16'd0;
      for (i = 0; i < MEASURING_POINTS; i = i + 1) begin
        points_x_q16_16[i] <= 32'sd0;
        points_y_q16_16[i] <= 32'sd0;
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
      // 最終バイトは WAIT_READY へ遷移した次サイクルで出てくるため、両方を許可
      if (read_req_reg && (state == STATE_RECEIVE_PAYLOAD || state == STATE_WAIT_READY)) begin
        payload[byte_counter] <= din;
        byte_counter <= byte_counter + 6'd1;
      end

      // IDLE へ戻るときにバイトカウンタをリセット
      if (next_state == STATE_IDLE) begin
        byte_counter <= 6'd0;
      end

      // read_req_reg を更新して次サイクルに capture を行えるようにする
      read_req_reg <= read_req;

      // 最終バイト受信時にパースして出力
      if (read_req_reg && (state == STATE_RECEIVE_PAYLOAD || state == STATE_WAIT_READY) && byte_counter == (PAYLOAD_LEN - 1)) begin
        start_angle10_out <= {payload[START_ANGLE_MSB], payload[START_ANGLE_LSB]};
        end_angle10_out <= {payload[END_ANGLE_MSB], payload[END_ANGLE_LSB]};
        for (i = 0; i < MEASURING_POINTS; i = i + 1) begin
          dist_mm = {payload[POINTS_START + (i*3) + 1], payload[POINTS_START + (i*3)]};
          intensity_val = payload[POINTS_START + (i*3) + 2];
          points_x_q16_16[i] <= {dist_mm, 16'b0};
          points_y_q16_16[i] <= {8'b0, intensity_val, 16'b0};
        end
        points_valid <= 1'b1;
      end

      // 受信完了の受け渡し完了で points_valid をクリア
      if (points_valid && points_ready) begin
        points_valid <= 1'b0;
      end
    end
  end

  // Combinational: next state and read control
  always_comb begin
    // defaults
    next_state = state;
    read_req = 1'b0;

    case (state)
      STATE_IDLE: begin
        // points_valid が残っている間は次のパケットを読まない
        if (!points_valid && ~empty) begin
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
          next_state = STATE_RECEIVE_PAYLOAD; // ペイロード受信開始
        end else begin
          next_state = STATE_IDLE; // 2 バイト目が不正
        end
      end

      STATE_RECEIVE_PAYLOAD: begin
        if (byte_counter == (PAYLOAD_LEN - 1)) begin
          if (~empty) begin
            read_req = 1'b1; // 最終バイト読み出し
            next_state = STATE_WAIT_READY;
          end else begin
            next_state = STATE_RECEIVE_PAYLOAD; // 最後のバイト待ち
          end
        end else begin
          if (~empty) begin
            read_req = 1'b1;
            next_state = STATE_RECEIVE_PAYLOAD;
          end else begin
            next_state = STATE_RECEIVE_PAYLOAD; // 待機
          end
        end
      end

      STATE_WAIT_READY: begin
        if (points_ready && points_valid) begin
          next_state = STATE_IDLE;
        end else begin
          next_state = STATE_WAIT_READY;
        end
      end

      default: next_state = STATE_IDLE;
    endcase
  end

endmodule