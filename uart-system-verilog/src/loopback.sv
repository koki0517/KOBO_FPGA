module loopback (
  input clk,
  input rst,
  input rxd,
  output txd
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

  receiver rx (
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

  processa proc (
    .clk(clk),
    .rst(rst),
    .din(word_to_transmit),
    .empty(empty),
    .re(re),
    .dout(processed_word),
    .wr_en(proc_wr_en)
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

  transmitter tx (
    .clk(clk),
    .rst(rst),
    .din(tx_fifo_out),
    .empty(tx_fifo_empty),
    .re(tx_fifo_re),
    .dout(txd)
  );
endmodule
