`timescale 1ns / 1ps

module loopback_tb;

  // Parameters
  localparam CLOCK_FREQUENCY = 50_000_000;
  localparam BAUD_RATE = 115200;
  localparam CLK_PERIOD = 20; // ns

  // Signals
  logic clk = 0;
  logic rst;
  logic rx = 1; // UART idle state is High
  wire  tx;

  // Instantiate the Device Under Test (DUT)
  loopback #(
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
    .BAUD_RATE(BAUD_RATE)
  ) dut (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .tx(tx)
  );

  // Clock generation block
  always #(CLK_PERIOD / 2.0 * 1ns) clk = ~clk;

  // Task to send one byte
  task send_byte(input [7:0] data);
    localparam BIT_PERIOD_NS = 8680; // ~1/115200 bps
    // Start Bit
    rx = 1'b0;
    #(BIT_PERIOD_NS * 1ns);
    // Data Bits
    for (int i = 0; i < 8; i++) begin
      rx = data[i];
      #(BIT_PERIOD_NS * 1ns);
    end
    // Stop Bit
    rx = 1'b1;
    #(BIT_PERIOD_NS * 1ns);
  endtask

  // Main test sequence
  initial begin
    // Define the array of bytes to send
    logic [7:0] data_queue[$] = '{
      8'h54, 8'h2c, 8'h14, 8'h0e, 8'h53, 8'h49, 8'hc5, 8'h00, 8'hf3, 8'hbd, 
      8'h00, 8'hf0, 8'hb9, 8'h00, 8'hf4, 8'hae, 8'h00, 8'hf4, 8'ha9, 8'h00, 
      8'hf4, 8'ha6, 8'h00, 8'hf5, 8'ha5, 8'h00, 8'hf2, 8'h9c, 8'h00, 8'hf5, 
      8'h97, 8'h00, 8'hf1, 8'h95, 8'h00, 8'hf4, 8'h94, 8'h00, 8'hf4, 8'h93, 
      8'h00, 8'hf5, 8'hbf, 8'h4c, 8'hca, 8'h70, 8'h88
    };

    // 1. Apply reset
    rst = 1;
    #200ns;
    rst = 0;
    #1us;

    // 2. Send all bytes in the queue
    $display("Testbench: Starting to send byte sequence...");
    foreach (data_queue[i]) begin
      send_byte(data_queue[i]);
      #10us; // Wait a bit between bytes
    end

    // 3. Wait long enough for all data to be processed
    #5ms;

    // 4. Finish the simulation
    $display("Testbench: Simulation finished. Check the waveforms.");
    $finish;
  end

endmodule