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

  receiver rx (
    .clk(clk),
    .rst(rst),
    .din(rxd),
    .dout(received_word),
    .full(full),
    .we(we)
  );

  fifo_buffer fb (
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

  processa proc (
    .clk(clk),
    .rst(rst),
    .din(word_to_transmit),
    .empty(empty),
    .fifo_data_count(fifo_data_count),
    .re(re),
    .data(processed_word)
  );

  transmitter tx (
    .clk(clk),
    .rst(rst),
    .din(processed_word),
    .empty(empty),
    .re(re),
    .dout(txd)
  );
endmodule
