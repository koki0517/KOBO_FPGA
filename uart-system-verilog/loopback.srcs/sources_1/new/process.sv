`timescale 1ns / 1ps

module processa #(
  parameter [31:0] CLOCK_FREQUENCY = 32'd50_000_000
) (
  input  logic        clk,
  input  logic        rst,
  input  logic [7:0]  din,      // FIFO の出力（読み出したバイト）
  input  logic        empty,    // FIFO が空かどうかのフラグ
  output logic        re,       // FIFO 読み出しイネーブル（次のバイトを読み出すための1サイクルパルス）
  output logic [7:0]  dout,     // 出力バイト（TX 側 FIFO に書き込む）
  output logic        wr_en,    // 出力 FIFO 書き込みパルス（1サイクル）
  output logic        led_enable
);

  // パケット / タイムアウトの定義
  localparam int PAYLOAD_LEN = 45; // ペイロード長（バイト数）
  localparam [31:0] TIMEOUT_MAX = (CLOCK_FREQUENCY * 2) - 1; // 2秒

  // FSM（状態機械）の状態
  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_CHECK1,        // ヘッダ1バイト目を検出（値は din に入っている）
    STATE_CHECK2,        // ヘッダ2バイト目を検出（値は din に入っている）
    STATE_RECEIVE_PAYLOAD,
    STATE_SEND_ACK
  } state_t;

  state_t state, next_state;

  // 内部レジスタ
  logic read_req;
  logic [5:0] byte_counter; // 45バイト分をカウントできる幅
  logic [31:0] timeout_cnt;
  logic led_en_reg;
  logic [7:0] dout_reg;
  logic wr_en_reg;

  // 出力
  assign re = read_req;
  assign dout = dout_reg;
  assign wr_en = wr_en_reg;
  assign led_enable = led_en_reg;

  // 順序回路：状態、カウンタ、タイムアウトの更新
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= STATE_IDLE;
      byte_counter <= 6'd0;
      timeout_cnt <= TIMEOUT_MAX; // タイムアウト済み -> 初期状態は LED オフ
      led_en_reg <= 1'b0;
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
      if (read_req && state == STATE_RECEIVE_PAYLOAD) begin
        // ここではペイロード自体は保存せず、終了検出のためにカウントのみ行う
        byte_counter <= byte_counter + 6'd1;
      end

      // IDLE へ戻るときにバイトカウンタをリセット
      if (next_state == STATE_IDLE) begin
        byte_counter <= 6'd0;
      end
    end
  end

  // 組合せ回路：次状態と読み書き制御
  always_comb begin
    // デフォルト値
    next_state = state;
    read_req = 1'b0;
    dout_reg = 8'h00;
    wr_en_reg = 1'b0;

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
          // ヘッダ一致：ペイロード受信を開始
          if (~empty) begin
            read_req = 1'b1; // 最初のペイロードバイトを読み出す
            next_state = STATE_RECEIVE_PAYLOAD;
          end else begin
            next_state = STATE_RECEIVE_PAYLOAD; // ペイロードが利用可能になるまでここで待つ
          end
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
            next_state = STATE_SEND_ACK;
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

      STATE_SEND_ACK: begin
        // 1サイクルだけ出力 FIFO に 0x08 を書き込む
        wr_en_reg = 1'b1;
        dout_reg = 8'h08;
        next_state = STATE_IDLE;
      end

      default: next_state = STATE_IDLE;
    endcase
  end

endmodule