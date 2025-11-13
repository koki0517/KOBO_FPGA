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

  // Signals for Receiver -> Input FIFO
  logic [7:0] received_data;
  logic data_valid;

  // Signals for Input FIFO -> Process
  logic [7:0] fifo_in_dout;
  logic fifo_in_empty;
  logic process_re; // Read enable controlled by process module

  // Signals for Process -> Output FIFO
  logic [7:0] process_dout;
  logic process_wr_en;
  logic process_led_enable;

  // Signals for Output FIFO -> Transmitter
  logic [7:0] fifo_out_dout;
  logic fifo_out_empty;
  logic tx_re; // Read enable controlled by transmitter

  // Instantiate the receiver
  receiver #(
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
    .BAUD_RATE(BAUD_RATE)
  ) i_receiver (
    .clk(clk),
    .rst(rst),
    .din(rx),
    .dout(received_data),
    .full(1'b0), // Assuming the receiver doesn't need backpressure for now
    .we(data_valid)
  );

  // Instantiate the INPUT FIFO buffer
  fifo_buffer i_fifo_in (
    .clk(clk),
    .srst(rst),
    .din(received_data),
    .wr_en(data_valid),
    .rd_en(~fifo_in_empty), // Directly connect to fifo_in_empty to drain it
    .dout(fifo_in_dout),
    .full(),
    .empty(fifo_in_empty)
  );

  /* --- DEBUG: Bypassing process module with Corrected Pipelining--- */
  logic [7:0] data_to_write;
  logic       write_now;
  logic       read_now;

  // Connect control/data signals to the pipeline logic
  assign process_re = read_now;
  assign process_dout = data_to_write;
  assign process_wr_en = write_now;
  assign process_led_enable = 1'b0; // Turn off process-controlled LED

  // This single block correctly pipelines the data transfer over two clock cycles
  always_ff @(posedge clk) begin
    if (rst) begin
      read_now <= 1'b0;
      write_now <= 1'b0;
      data_to_write <= 8'h00;
    end else begin
      // By default, de-assert signals
      read_now <= 1'b0;
      write_now <= 1'b0;

      // STAGE 1: If the input FIFO has data, start a read operation.
      if (~fifo_in_empty) begin
        read_now <= 1'b1;
      end

      // STAGE 2: If we were reading last cycle, the data is now valid.
      // Latch the data and start the write operation to the output FIFO.
      if (read_now) begin
        write_now <= 1'b1;
        data_to_write <= fifo_in_dout;
      end
    end
  end

  // Instantiate the OUTPUT FIFO buffer (using the same fifo_buffer IP)
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

  // Instantiate the transmitter
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

  // LED Blinker - led[0] is always on, led[1] is controlled by process module
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
