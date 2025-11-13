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
    // 1. Reset
    rst = 1;
    #200ns;
    rst = 0;
    #1us;

    // 2. Send 'T' (0x54)
    $display("Testbench: Sending 'T' (0x54)...");
    send_byte(8'h54);

    #10us; // Wait a bit between bytes

    // 3. Send ',' (0x2c)
    $display("Testbench: Sending ',' (0x2c)...");
    send_byte(8'h2c);

    // 4. Wait long enough for the response (0x08)
    #200us;

    $display("Testbench: Simulation finished. Check tx for 0x08.");
    $finish;
  end

endmodule