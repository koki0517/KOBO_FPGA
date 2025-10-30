module loopback (
  input clk,
  input rst,
  input rxd,
  output txd,
  output [15:0] led
);
  logic [7:0] received_word;
  logic       full;
  logic       we;
  logic [7:0] word_to_transmit;
  logic       empty;
  logic       re;
  logic [8:0] fifo_data_count;
  logic [7:0] processed_word;
  logic [7:0] tx_fifo_out;
  logic       tx_fifo_empty;
  logic       tx_fifo_re;
  logic [8:0] tx_fifo_data_count;

  receiver #(
    .CLOCK_FREQUENCY(33_000_000),
    .BAUD_RATE(230400),
    .WORD_WIDTH(8)
  ) rx (
    .clk(clk),
    .rst(rst),
    .din(rxd),
    .dout(received_word),
    .full(full),
    .we(we)
  );

  fifo_buffer fb_in (
    .clk(clk),
    .srst(rst),
    .din(received_word),
    .full(full),
    .wr_en(we),
    .dout(word_to_transmit),
    .empty(empty),
    .rd_en(re),
    .data_count(fifo_data_count)
  );

  logic proc_wr_en;
  logic proc_led_enable;

  processa #(
    .CLOCK_FREQUENCY(33_000_000)
  ) proc (
    .clk(clk),
    .rst(rst),
    .din(word_to_transmit),
    .empty(empty),
    .re(re),
    .dout(processed_word),
    .wr_en(proc_wr_en),
    .led_enable(proc_led_enable)
  );

  fifo_buffer fb_out (
    .clk(clk),
    .srst(rst),
    .din(processed_word),
    .full(), // 未使用
    .wr_en(proc_wr_en),
    .dout(tx_fifo_out),
    .empty(tx_fifo_empty),
    .rd_en(tx_fifo_re),
    .data_count(tx_fifo_data_count)
  );

  transmitter #(
    .CLOCK_FREQUENCY(33_000_000),
    .BAUD_RATE(115200),
    .WORD_WIDTH(8)
  ) tx (
    .clk(clk),
    .rst(rst),
    .din(tx_fifo_out),
    .empty(tx_fifo_empty),
    .re(tx_fifo_re),
    .dout(txd)
  );

  // LED Blinker - led[0]は常時有効、led[1]はプロセス制御
  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : led_gen
      led_blinker #(
        .CLOCK_FREQUENCY(33_000_000),
        .BLINK_FREQUENCY(2)
      ) blinker (
        .clk(clk),
        .rst(rst),
        .enable(i == 0 ? 1'b1 : (i == 1 ? proc_led_enable : 1'b0)),
        .led(led[i])
      );
    end
  endgenerate

endmodule
