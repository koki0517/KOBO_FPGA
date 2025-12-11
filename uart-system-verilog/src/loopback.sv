`timescale 1ns / 1ps

module loopback #(
  parameter CLOCK_FREQUENCY = 32'd50_000_000,
  parameter BAUD_RATE = 32'd115200
) (
  input clk,
  input rst,
  input rx,
  output tx,
  output [15:0] led
);

  // レシーバ -> 入力 FIFO の信号
  logic [7:0] received_data;
  logic data_valid;

  // 入力 FIFO -> 処理モジュール の信号
  logic [7:0] fifo_in_dout;
  logic fifo_in_empty;
  logic process_re; // 処理モジュールが制御する読み出しイネーブル

  // 処理モジュール -> 出力 FIFO の信号
  logic [7:0] process_dout;
  logic process_wr_en;
  logic process_led_enable;

  // 出力 FIFO -> 送信機 の信号
  logic [7:0] fifo_out_dout;
  logic fifo_out_empty;
  logic tx_re; // 送信機が制御する読み出しイネーブル

  // レシーバのインスタンス化
  receiver #(
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
    .BAUD_RATE(BAUD_RATE)
  ) i_receiver (
    .clk(clk),
    .rst(rst),
    .din(rx),
    .dout(received_data),
    .full(1'b0), // 今のところレシーバにバックプレッシャは不要と仮定
    .we(data_valid)
  );

  // INPUT FIFO バッファのインスタンス化
  fifo_buffer i_fifo_in (
    .clk(clk),
    .srst(rst),
    .din(received_data),
    .wr_en(data_valid),
    .rd_en(process_re),
    .dout(fifo_in_dout),
    .full(),
    .empty(fifo_in_empty)
  );

  // 処理モジュールのインスタンス化
  processa #(
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY)
  ) i_process (
    .clk(clk),
    .rst(rst),
    .din(fifo_in_dout),
    .empty(fifo_in_empty),
    .re(process_re),
    .dout(process_dout),
    .wr_en(process_wr_en),
    .led_enable(process_led_enable)
  );

  // OUTPUT FIFO バッファ（同じ fifo_buffer IP を使用）のインスタンス化
  fifo_buffer i_fifo_out (
    .clk(clk),
    .srst(rst),
    .din(process_dout),
    .wr_en(process_wr_en),
    .rd_en(tx_re),
    .dout(fifo_out_dout),
    .full(),
    .empty(fifo_out_empty)
  );

  // 送信機のインスタンス化
  transmitter #(
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
    .BAUD_RATE(BAUD_RATE)
  ) i_transmitter (
    .clk(clk),
    .rst(rst),
    .din(fifo_out_dout),
    .empty(fifo_out_empty),
    .re(tx_re),
    .dout(tx)
  );

  // LED ブリンカー - led[0] は常時点灯, led[1] は処理モジュールで制御
  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : led_gen
      led_blinker #(.CLOCK_FREQUENCY(CLOCK_FREQUENCY)) blinker (
        .clk(clk),
        .rst(rst),
        .enable(i == 0 ? 1'b1 : (i == 1 ? process_led_enable : 1'b0)),
        .led(led[i])
      );
    end
  endgenerate

endmodule
