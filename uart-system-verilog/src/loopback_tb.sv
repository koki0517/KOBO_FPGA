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

  // Main test sequence with INLINED byte sending logic
  initial begin
    logic [7:0] data_to_send;
    // Bit period for 115200 bps is ~8680 ns. Hardcoding to be safe.
    localparam BIT_PERIOD_NS = 8680; 

    // 1. Apply reset
    rst = 1;
    #200ns;
    rst = 0;
    #1us;

    // 2. Send 'A' (0x41) directly inside the initial block
    $display("Testbench: Sending 'A' (0x41) with inlined logic...");
    data_to_send = 8'h41;

    // --- Start of byte transmission ---
    // Start Bit
    rx = 1'b0;
    #(BIT_PERIOD_NS * 1ns);

    // Data Bits (LSB first)
    for (int i = 0; i < 8; i++) begin
      rx = data_to_send[i];
      #(BIT_PERIOD_NS * 1ns);
    end

    // Stop Bit
    rx = 1'b1;
    #(BIT_PERIOD_NS * 1ns);
    // --- End of byte transmission ---

    // 3. Wait long enough for the byte to be received and sent back
    #200us;

    // 4. Finish the simulation
    $display("Testbench: Simulation finished. Check the waveforms.");
    $finish;
  end

endmodule
