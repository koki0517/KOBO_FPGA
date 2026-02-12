`timescale 1ns / 1ps

module loopback_tb;

  // Parameters
  localparam CLOCK_FREQUENCY = 50_000_000;
  localparam BAUD_RATE = 230400;
  localparam CLK_PERIOD = 20; // ns

  // Signals
  logic clk = 0;
  logic rst;
  logic rx = 1; // UART idle state is High
  wire  tx;
  wire [15:0] led;
  wire        result_valid;
  wire signed [31:0] result_x [0:11];
  wire signed [31:0] result_y [0:11];
  wire        result3_valid;
  wire signed [31:0] result3_x [0:2][0:11];
  wire signed [31:0] result3_y [0:2][0:11];
  wire        feature_valid;
  wire [5:0]  feature_count;
  wire signed [31:0] feature_x [0:35];
  wire signed [31:0] feature_y [0:35];
  int processed_count;

  // Instantiate the Device Under Test (DUT)
  loopback #(
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
    .BAUD_RATE(BAUD_RATE)
  ) dut (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .tx(tx),
    .led(led),
    .result_valid(result_valid),
    .result_x(result_x),
    .result_y(result_y),
    .result3_valid(result3_valid),
    .result3_x(result3_x),
    .result3_y(result3_y),
    .feature_valid(feature_valid),
    .feature_count(feature_count),
    .feature_x(feature_x),
    .feature_y(feature_y)
  );

  // Standalone CORDIC instance for phase-format calibration
  logic        cal_tvalid;
  logic [15:0] cal_tdata;
  wire         cal_out_valid;
  wire  [31:0] cal_out_data;

  cordic_sincos cordic_cal (
    .aclk              (clk),
    .s_axis_phase_tvalid(cal_tvalid),
    .s_axis_phase_tdata (cal_tdata),
    .m_axis_dout_tvalid (cal_out_valid),
    .m_axis_dout_tdata  (cal_out_data)
  );

  // Clock generation block
  always #(CLK_PERIOD / 2.0 * 1ns) clk = ~clk;

  // Count packets processed by processb
  always @(posedge clk) begin
    if (rst) begin
      processed_count <= 0;
    end else if (result_valid) begin
      processed_count <= processed_count + 1;
    end
  end

  task automatic cordic_cal_send(input logic [15:0] phase_word, input string label);
    int cyc;
    int valid_count;
    logic [31:0] captured_dout;
    logic captured;
    begin
      // Clear any pending output
      captured = 0;
      
      // Drive continuous valid signal for multiple cycles
      cal_tdata  = phase_word;
      cal_tvalid = 1'b1;
      
      // Keep valid high and wait for output
      for (cyc = 0; cyc < 100; cyc++) begin
        @(posedge clk);
        if (cal_out_valid && !captured) begin
          captured_dout = cal_out_data;
          captured = 1;
          valid_count = cyc;
        end
      end
      
      cal_tvalid = 1'b0;
      
      if (captured) begin
        $display("CAL %s: phase=0x%04h signed=%0d dout=0x%08h cos=%0d sin=%0d latency=%0d",
           label,
           phase_word,
           $signed(phase_word),
           captured_dout,
           $signed(captured_dout[31:16]), // upper = cos
           $signed(captured_dout[15:0]),  // lower = sin
           valid_count);
      end else begin
        $display("CAL %s: TIMEOUT - no valid output", label);
      end
      
      // Wait for pipeline to clear
      repeat(50) @(posedge clk);
    end
  endtask

  // Task to send one byte
  task send_byte(input [7:0] data);
    localparam BIT_PERIOD_NS = 4340; // ~1/230400 bps
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

  // Stimulus packet bytes (1 line = 1 packet)
  localparam int PACKET_LEN  = 47;
  localparam int NUM_PACKETS = 38;
  localparam int DEFAULT_SIM_PACKETS = NUM_PACKETS;
  logic [7:0] data_packets[NUM_PACKETS][PACKET_LEN] = '{
    '{8'h54, 8'h2c, 8'h17, 8'h0e, 8'he4, 8'h7b, 8'hd9, 8'h00, 8'hf3, 8'hd9, 8'h00, 8'hf4, 8'hd9, 8'h00, 8'hf2, 8'hd9, 8'h00, 8'hf1, 8'hd9, 8'h00, 8'hf2, 8'hd9, 8'h00, 8'hf2, 8'hd9, 8'h00, 8'hf0, 8'hd2, 8'h00, 8'hf2, 8'hd6, 8'h00, 8'hf1, 8'hd8, 8'h00, 8'hf2, 8'hd9, 8'h00, 8'hf0, 8'hd9, 8'h00, 8'hf1, 8'h51, 8'h7f, 8'h1d, 8'h72, 8'h98},
    '{8'h54, 8'h2c, 8'h17, 8'h0e, 8'h9d, 8'h7f, 8'hd9, 8'h00, 8'hf2, 8'hd9, 8'h00, 8'hf3, 8'hd9, 8'h00, 8'hf2, 8'hd2, 8'h00, 8'hf3, 8'hd6, 8'h00, 8'hf4, 8'hd8, 8'h00, 8'hf2, 8'hd9, 8'h00, 8'hf3, 8'hd9, 8'h00, 8'hf2, 8'hd2, 8'h00, 8'hf1, 8'hd6, 8'h00, 8'hf3, 8'hd8, 8'h00, 8'hf2, 8'hd9, 8'h00, 8'hf3, 8'h09, 8'h83, 8'h1f, 8'h72, 8'hd0},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h83, 8'h83, 8'hd9, 8'h00, 8'hf2, 8'hd9, 8'h00, 8'hf1, 8'hd9, 8'h00, 8'hf2, 8'hd2, 8'h00, 8'hf2, 8'hdd, 8'h00, 8'hf2, 8'hdb, 8'h00, 8'hf3, 8'he2, 8'h00, 8'hf4, 8'he5, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf5, 8'he8, 8'h00, 8'hf4, 8'he9, 8'h86, 8'h22, 8'h72, 8'h40},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h35, 8'h87, 8'he8, 8'h00, 8'hf3, 8'he8, 8'h00, 8'hf5, 8'he8, 8'h00, 8'hf3, 8'he8, 8'h00, 8'hf3, 8'he8, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf2, 8'he8, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf2, 8'he8, 8'h00, 8'hf1, 8'he8, 8'h00, 8'hf1, 8'he8, 8'h00, 8'hf3, 8'h5b, 8'h8a, 8'h25, 8'h72, 8'h6d},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hae, 8'h8a, 8'hef, 8'h00, 8'hf4, 8'hec, 8'h00, 8'hf3, 8'hf1, 8'h00, 8'hf1, 8'hed, 8'h00, 8'hf1, 8'hf2, 8'h00, 8'hf1, 8'hf4, 8'h00, 8'hf1, 8'hf5, 8'h00, 8'hf1, 8'hf6, 8'h00, 8'hf3, 8'hfd, 8'h00, 8'hf4, 8'h01, 8'h01, 8'hf3, 8'h03, 8'h01, 8'hf0, 8'h04, 8'h01, 8'hf1, 8'h7c, 8'h01, 8'h27, 8'h72, 8'h34},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hc7, 8'h01, 8'h04, 8'h01, 8'hf2, 8'he9, 8'h00, 8'hec, 8'hf0, 8'h00, 8'heb, 8'hec, 8'h00, 8'hed, 8'hf1, 8'h00, 8'hf4, 8'hf4, 8'h00, 8'hf4, 8'hf5, 8'h00, 8'hf3, 8'hf6, 8'h00, 8'hf5, 8'hf6, 8'h00, 8'hf3, 8'hf6, 8'h00, 8'hf2, 8'hf6, 8'h00, 8'hf4, 8'hf6, 8'h00, 8'hf2, 8'h57, 8'h05, 8'h2a, 8'h72, 8'hf2},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'haa, 8'h05, 8'hef, 8'h00, 8'hf4, 8'hec, 8'h00, 8'hf3, 8'hea, 8'h00, 8'hf4, 8'he9, 8'h00, 8'hf3, 8'he9, 8'h00, 8'hf4, 8'he9, 8'h00, 8'hf5, 8'he9, 8'h00, 8'hf4, 8'he9, 8'h00, 8'hf3, 8'he9, 8'h00, 8'hf5, 8'he9, 8'h00, 8'hf3, 8'he9, 8'h00, 8'hf4, 8'he1, 8'h00, 8'hf6, 8'hf1, 8'h08, 8'h2c, 8'h72, 8'h13},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h3d, 8'h09, 8'hdd, 8'h00, 8'hf4, 8'hdb, 8'h00, 8'hf3, 8'hda, 8'h00, 8'hf1, 8'hd3, 8'h00, 8'hf4, 8'hd6, 8'h00, 8'hf3, 8'hd8, 8'h00, 8'hf3, 8'hd2, 8'h00, 8'hf4, 8'hcf, 8'h00, 8'hf3, 8'hcd, 8'h00, 8'hf2, 8'hcc, 8'h00, 8'hf3, 8'hcc, 8'h00, 8'hf4, 8'hcc, 8'h00, 8'hf2, 8'hab, 8'h0c, 8'h2f, 8'h72, 8'h04},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hf6, 8'h0c, 8'hcc, 8'h00, 8'hf1, 8'hcc, 8'h00, 8'hf5, 8'hcc, 8'h00, 8'hf4, 8'hcc, 8'h00, 8'hf4, 8'hcc, 8'h00, 8'hf5, 8'hcc, 8'h00, 8'hf6, 8'hcc, 8'h00, 8'hf2, 8'hcc, 8'h00, 8'hf4, 8'hcc, 8'h00, 8'hf5, 8'hc5, 8'h00, 8'hf5, 8'hc8, 8'h00, 8'hf6, 8'hca, 8'h00, 8'hf5, 8'h49, 8'h10, 8'h32, 8'h72, 8'h9a},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h9c, 8'h10, 8'hcb, 8'h00, 8'hf5, 8'hcb, 8'h00, 8'hf5, 8'hcb, 8'h00, 8'hf5, 8'hcb, 8'h00, 8'hf6, 8'hcb, 8'h00, 8'hf5, 8'hc4, 8'h00, 8'hf5, 8'hc1, 8'h00, 8'hf4, 8'hbf, 8'h00, 8'hf4, 8'hbe, 8'h00, 8'hf5, 8'hc5, 8'h00, 8'hf4, 8'hc8, 8'h00, 8'hf4, 8'hc3, 8'h00, 8'hf5, 8'h2b, 8'h14, 8'h34, 8'h72, 8'ha3},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h7e, 8'h14, 8'hc0, 8'h00, 8'hf6, 8'hbf, 8'h00, 8'hf4, 8'hbe, 8'h00, 8'hf5, 8'hbe, 8'h00, 8'hf5, 8'hbe, 8'h00, 8'hf5, 8'hbe, 8'h00, 8'hf6, 8'hbe, 8'h00, 8'hf4, 8'hbe, 8'h00, 8'hf4, 8'hbe, 8'h00, 8'hf4, 8'hc5, 8'h00, 8'hf4, 8'hc1, 8'h00, 8'hf5, 8'hbf, 8'h00, 8'hf4, 8'he8, 8'h17, 8'h37, 8'h72, 8'h74},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h34, 8'h18, 8'hbe, 8'h00, 8'hf4, 8'hbe, 8'h00, 8'hf5, 8'hbe, 8'h00, 8'hf5, 8'hbe, 8'h00, 8'hf5, 8'hbe, 8'h00, 8'hf5, 8'hbe, 8'h00, 8'hf5, 8'hc5, 8'h00, 8'hf6, 8'hc1, 8'h00, 8'hf5, 8'hc6, 8'h00, 8'hf7, 8'hc9, 8'h00, 8'hf6, 8'hca, 8'h00, 8'hf4, 8'hcb, 8'h00, 8'hf5, 8'h89, 8'h1b, 8'h3a, 8'h72, 8'h1e},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hdc, 8'h1b, 8'hcb, 8'h00, 8'hf6, 8'hcb, 8'h00, 8'hf5, 8'hcb, 8'h00, 8'hf6, 8'hcb, 8'h00, 8'hf4, 8'hcb, 8'h00, 8'hf6, 8'hcb, 8'h00, 8'hf2, 8'hcb, 8'h00, 8'hf5, 8'hcb, 8'h00, 8'hf2, 8'hcb, 8'h00, 8'hf3, 8'hcb, 8'h00, 8'hf4, 8'hcb, 8'h00, 8'hf4, 8'hcb, 8'h00, 8'hf3, 8'h46, 8'h1f, 8'h3c, 8'h72, 8'hc4},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h95, 8'h1f, 8'hcb, 8'h00, 8'hf7, 8'hcb, 8'h00, 8'hf1, 8'hcb, 8'h00, 8'hf1, 8'hcb, 8'h00, 8'hf4, 8'hd2, 8'h00, 8'hf1, 8'hc8, 8'h00, 8'hf3, 8'hca, 8'h00, 8'hf1, 8'hcb, 8'h00, 8'hf3, 8'hd2, 8'h00, 8'hf4, 8'hd6, 8'h00, 8'hf5, 8'hd8, 8'h00, 8'hf6, 8'he0, 8'h00, 8'hf6, 8'hfa, 8'h22, 8'h3f, 8'h72, 8'h8f},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h49, 8'h23, 8'he4, 8'h00, 8'hf3, 8'he6, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf2, 8'he7, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf2, 8'he7, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf1, 8'hef, 8'h00, 8'hf2, 8'hf3, 8'h00, 8'hf3, 8'hf4, 8'h00, 8'hf4, 8'had, 8'h26, 8'h42, 8'h72, 8'h1f},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hfd, 8'h26, 8'hf5, 8'h00, 8'hf4, 8'hfd, 8'h00, 8'hf3, 8'h01, 8'h01, 8'hf1, 8'h03, 8'h01, 8'hf4, 8'h04, 8'h01, 8'hf2, 8'h04, 8'h01, 8'hf4, 8'h04, 8'h01, 8'hf4, 8'h0b, 8'h01, 8'hec, 8'hda, 8'h00, 8'he6, 8'he1, 8'h00, 8'hea, 8'hea, 8'h00, 8'hf3, 8'hf0, 8'h00, 8'hf2, 8'h66, 8'h2a, 8'h44, 8'h72, 8'h51},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hb2, 8'h2a, 8'hfa, 8'h00, 8'hf4, 8'hff, 8'h00, 8'hf4, 8'h02, 8'h01, 8'hf2, 8'he8, 8'h00, 8'hf1, 8'he8, 8'h00, 8'hf3, 8'he8, 8'h00, 8'hf1, 8'hef, 8'h00, 8'hf5, 8'hf2, 8'h00, 8'hf3, 8'hf4, 8'h00, 8'hf2, 8'hf5, 8'h00, 8'hf1, 8'hf5, 8'h00, 8'hf4, 8'hee, 8'h00, 8'hf4, 8'h16, 8'h2e, 8'h47, 8'h72, 8'h4f},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h6a, 8'h2e, 8'hf2, 8'h00, 8'hf4, 8'hf4, 8'h00, 8'hf4, 8'hf5, 8'h00, 8'hf5, 8'hee, 8'h00, 8'hf2, 8'heb, 8'h00, 8'hf1, 8'he9, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf3, 8'he1, 8'h00, 8'hf3, 8'he4, 8'h00, 8'hf3, 8'he6, 8'h00, 8'hf2, 8'he7, 8'h00, 8'hf4, 8'hf2, 8'h31, 8'h49, 8'h72, 8'hc8},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h3e, 8'h32, 8'he7, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf5, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf3, 8'he0, 8'h00, 8'hf2, 8'he4, 8'h00, 8'hf2, 8'he6, 8'h00, 8'hf1, 8'ha4, 8'h35, 8'h4c, 8'h72, 8'hbf},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hf7, 8'h35, 8'he0, 8'h00, 8'hf3, 8'he4, 8'h00, 8'hf2, 8'he6, 8'h00, 8'hf2, 8'he7, 8'h00, 8'hf3, 8'he0, 8'h00, 8'hf2, 8'he4, 8'h00, 8'hf2, 8'hdf, 8'h00, 8'hf2, 8'he3, 8'h00, 8'hf2, 8'hd7, 8'h00, 8'hf3, 8'hd8, 8'h00, 8'hf1, 8'hd9, 8'h00, 8'hf3, 8'he0, 8'h00, 8'hf3, 8'h49, 8'h39, 8'h4f, 8'h72, 8'hd7},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h98, 8'h39, 8'hd6, 8'h00, 8'hf3, 8'hd8, 8'h00, 8'hf3, 8'hd9, 8'h00, 8'hf2, 8'he0, 8'h00, 8'hf3, 8'hdd, 8'h00, 8'hf2, 8'he2, 8'h00, 8'hf4, 8'hde, 8'h00, 8'hf2, 8'he3, 8'h00, 8'hf3, 8'he5, 8'h00, 8'hf5, 8'he6, 8'h00, 8'hf5, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf2, 8'h06, 8'h3d, 8'h51, 8'h72, 8'h83},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h50, 8'h3d, 8'he7, 8'h00, 8'hf5, 8'he7, 8'h00, 8'hf2, 8'he7, 8'h00, 8'hf5, 8'he7, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf5, 8'he7, 8'h00, 8'hf4, 8'he7, 8'h00, 8'hf3, 8'hb6, 8'h40, 8'h54, 8'h72, 8'h0f},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h09, 8'h41, 8'he7, 8'h00, 8'hf4, 8'hee, 8'h00, 8'hf4, 8'heb, 8'h00, 8'hf3, 8'hf0, 8'h00, 8'hf2, 8'hec, 8'h00, 8'hf2, 8'hf1, 8'h00, 8'hef, 8'hf3, 8'h00, 8'hf3, 8'hed, 8'h00, 8'hf2, 8'hf1, 8'h00, 8'hf3, 8'hf3, 8'h00, 8'hf2, 8'hf4, 8'h00, 8'hf3, 8'hf5, 8'h00, 8'hf3, 8'h6d, 8'h44, 8'h57, 8'h72, 8'hae},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hbc, 8'h44, 8'hf5, 8'h00, 8'hf3, 8'hf5, 8'h00, 8'hf3, 8'hfd, 8'h00, 8'hf2, 8'h01, 8'h01, 8'hf2, 8'h03, 8'h01, 8'hf0, 8'h04, 8'h01, 8'hf1, 8'h04, 8'h01, 8'hf2, 8'h04, 8'h01, 8'hf1, 8'h04, 8'h01, 8'hf1, 8'he8, 8'h00, 8'hed, 8'he8, 8'h00, 8'hec, 8'he8, 8'h00, 8'hee, 8'h26, 8'h48, 8'h59, 8'h72, 8'he7},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h75, 8'h48, 8'hef, 8'h00, 8'hf4, 8'hfa, 8'h00, 8'hf4, 8'hff, 8'h00, 8'hf5, 8'h02, 8'h01, 8'hf3, 8'hf6, 8'h00, 8'hf3, 8'hf6, 8'h00, 8'hf4, 8'hf6, 8'h00, 8'hf5, 8'hf6, 8'h00, 8'hf5, 8'hf6, 8'h00, 8'hf3, 8'hf6, 8'h00, 8'hf4, 8'hef, 8'h00, 8'hf3, 8'heb, 8'h00, 8'hf4, 8'hdd, 8'h4b, 8'h5c, 8'h72, 8'h94},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h29, 8'h4c, 8'he9, 8'h00, 8'hf5, 8'he8, 8'h00, 8'hf5, 8'he8, 8'h00, 8'hf6, 8'he8, 8'h00, 8'hf5, 8'he8, 8'h00, 8'hf6, 8'he8, 8'h00, 8'hf3, 8'he1, 8'h00, 8'hf5, 8'hdd, 8'h00, 8'hf2, 8'hd4, 8'h00, 8'hf3, 8'hd7, 8'h00, 8'hf3, 8'hd8, 8'h00, 8'hf2, 8'hd9, 8'h00, 8'hf0, 8'h6d, 8'h4f, 8'h5f, 8'h72, 8'hb3},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hc0, 8'h4f, 8'hd2, 8'h00, 8'hf1, 8'hcf, 8'h00, 8'hf1, 8'hcd, 8'h00, 8'hf0, 8'hcc, 8'h00, 8'hf3, 8'hcc, 8'h00, 8'hf0, 8'hcc, 8'h00, 8'hf1, 8'hcc, 8'h00, 8'hf0, 8'hcc, 8'h00, 8'hf2, 8'hcc, 8'h00, 8'hf1, 8'hcc, 8'h00, 8'hf1, 8'hcc, 8'h00, 8'hf1, 8'hcc, 8'h00, 8'hf1, 8'h29, 8'h53, 8'h61, 8'h72, 8'h2c},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h79, 8'h53, 8'hcc, 8'h00, 8'hf3, 8'hcc, 8'h00, 8'hf4, 8'hcc, 8'h00, 8'hf3, 8'hc5, 8'h00, 8'hf4, 8'hc8, 8'h00, 8'hf4, 8'hca, 8'h00, 8'hf2, 8'hc4, 8'h00, 8'hf5, 8'hc1, 8'h00, 8'hf5, 8'hbf, 8'h00, 8'hf5, 8'hc5, 8'h00, 8'hf5, 8'hc1, 8'h00, 8'hf5, 8'hbf, 8'h00, 8'hf6, 8'hfe, 8'h56, 8'h64, 8'h72, 8'h1c},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h49, 8'h57, 8'hbe, 8'h00, 8'hf7, 8'hbe, 8'h00, 8'hf6, 8'hbe, 8'h00, 8'hf6, 8'hbe, 8'h00, 8'hf5, 8'hb7, 8'h00, 8'hf6, 8'hba, 8'h00, 8'hf7, 8'hbc, 8'h00, 8'hf6, 8'hbd, 8'h00, 8'hf6, 8'hb6, 8'h00, 8'hf5, 8'hba, 8'h00, 8'hf4, 8'hbc, 8'h00, 8'hf2, 8'hbd, 8'h00, 8'hf4, 8'hb8, 8'h5a, 8'h67, 8'h72, 8'h00},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h0c, 8'h5b, 8'hbd, 8'h00, 8'hf2, 8'hbd, 8'h00, 8'hf2, 8'hbd, 8'h00, 8'hf1, 8'hb6, 8'h00, 8'hf3, 8'hba, 8'h00, 8'hf3, 8'hbc, 8'h00, 8'hf3, 8'hbd, 8'h00, 8'hf4, 8'hbd, 8'h00, 8'hf4, 8'hbd, 8'h00, 8'hf5, 8'hbd, 8'h00, 8'hf4, 8'hbd, 8'h00, 8'hf3, 8'hbd, 8'h00, 8'hf4, 8'h75, 8'h5e, 8'h69, 8'h72, 8'hc7},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hc5, 8'h5e, 8'hbd, 8'h00, 8'hf5, 8'hbd, 8'h00, 8'hf5, 8'hbd, 8'h00, 8'hf2, 8'hbd, 8'h00, 8'hf6, 8'hbd, 8'h00, 8'hf5, 8'hbd, 8'h00, 8'hf5, 8'hbd, 8'h00, 8'hf6, 8'hc4, 8'h00, 8'hf5, 8'hc1, 8'h00, 8'hf6, 8'hbf, 8'h00, 8'hf5, 8'hbe, 8'h00, 8'hf6, 8'hbe, 8'h00, 8'hf5, 8'h2c, 8'h62, 8'h6c, 8'h72, 8'hc5},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h78, 8'h62, 8'hc5, 8'h00, 8'hf4, 8'hc8, 8'h00, 8'hf5, 8'hca, 8'h00, 8'hf5, 8'hc4, 8'h00, 8'hf6, 8'hc8, 8'h00, 8'hf5, 8'hca, 8'h00, 8'hf4, 8'hcb, 8'h00, 8'hf5, 8'hcb, 8'h00, 8'hf5, 8'hcb, 8'h00, 8'hf6, 8'hcb, 8'h00, 8'hf5, 8'hcb, 8'h00, 8'hf4, 8'hcb, 8'h00, 8'hf7, 8'he2, 8'h65, 8'h6e, 8'h72, 8'hcf},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h30, 8'h66, 8'hcb, 8'h00, 8'hf6, 8'hcb, 8'h00, 8'hf4, 8'hcb, 8'h00, 8'hf4, 8'hcb, 8'h00, 8'hf3, 8'hd2, 8'h00, 8'hf2, 8'hcf, 8'h00, 8'hf4, 8'hcd, 8'h00, 8'hf4, 8'hd3, 8'h00, 8'hf3, 8'hcf, 8'h00, 8'hf4, 8'hd4, 8'h00, 8'hf5, 8'hd7, 8'h00, 8'hf4, 8'hd8, 8'h00, 8'hf4, 8'h8b, 8'h69, 8'h71, 8'h72, 8'h74},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hda, 8'h69, 8'hd9, 8'h00, 8'hf3, 8'he0, 8'h00, 8'hf5, 8'he4, 8'h00, 8'hf2, 8'he6, 8'h00, 8'hf2, 8'he7, 8'h00, 8'hf5, 8'he7, 8'h00, 8'hf2, 8'he7, 8'h00, 8'hf3, 8'he7, 8'h00, 8'hf5, 8'hef, 8'h00, 8'hf3, 8'hf3, 8'h00, 8'hf2, 8'hf5, 8'h00, 8'hf5, 8'hf6, 8'h00, 8'hf4, 8'h50, 8'h6d, 8'h74, 8'h72, 8'hd0},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h9c, 8'h6d, 8'hf6, 8'h00, 8'hf5, 8'hf6, 8'h00, 8'hf3, 8'hfd, 8'h00, 8'hf3, 8'h01, 8'h01, 8'hf4, 8'h03, 8'h01, 8'hf3, 8'h04, 8'h01, 8'hf3, 8'he8, 8'h00, 8'hea, 8'hda, 8'h00, 8'he9, 8'he4, 8'h00, 8'hf1, 8'hec, 8'h00, 8'hf4, 8'hf2, 8'h00, 8'hf2, 8'hf4, 8'h00, 8'hf2, 8'h06, 8'h71, 8'h76, 8'h72, 8'hca},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h55, 8'h71, 8'hf5, 8'h00, 8'hf2, 8'hf6, 8'h00, 8'hf2, 8'hf6, 8'h00, 8'hf1, 8'hf6, 8'h00, 8'hf2, 8'hf6, 8'h00, 8'hf3, 8'hf6, 8'h00, 8'hf2, 8'hf6, 8'h00, 8'hf2, 8'hf6, 8'h00, 8'hf3, 8'hf6, 8'h00, 8'hf4, 8'hef, 8'h00, 8'hf2, 8'heb, 8'h00, 8'hf2, 8'he9, 8'h00, 8'hf2, 8'hb6, 8'h74, 8'h79, 8'h72, 8'hbb},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'h09, 8'h75, 8'he8, 8'h00, 8'hf1, 8'he8, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf2, 8'he8, 8'h00, 8'hf2, 8'he8, 8'h00, 8'hf3, 8'he8, 8'h00, 8'hf3, 8'he8, 8'h00, 8'hf2, 8'he8, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf4, 8'he8, 8'h00, 8'hf2, 8'he8, 8'h00, 8'hf0, 8'he8, 8'h00, 8'hf3, 8'h8a, 8'h78, 8'h7c, 8'h72, 8'h6d},
    '{8'h54, 8'h2c, 8'h1a, 8'h0e, 8'hd9, 8'h78, 8'he8, 8'h00, 8'hf3, 8'he8, 8'h00, 8'hf3, 8'he8, 8'h00, 8'hf3, 8'he1, 8'h00, 8'hf2, 8'he4, 8'h00, 8'hf4, 8'hdf, 8'h00, 8'hf1, 8'he3, 8'h00, 8'hf3, 8'he5, 8'h00, 8'hf3, 8'hdf, 8'h00, 8'hf5, 8'hdc, 8'h00, 8'hf3, 8'hdb, 8'h00, 8'hf4, 8'hda, 8'h00, 8'hf4, 8'h3f, 8'h7c, 8'h7e, 8'h72, 8'he7}
  };

  // Variables for analysis (declared at module scope for XSim compatibility)
  localparam int EXPECT_POINTS = 12;
  // Allow small fixed-point/CORDIC quantization error in Q16.16
  localparam int TOL_Q16_16 = 5000;
  localparam time OUT_TIMEOUT = 30ms;
  localparam int MAX_WAIT_CYCLES = 1_500_000; // 30ms / 20ns
  localparam int ANGLE_SCALE = 100;
  localparam int ANGLE_FULL  = 360 * ANGLE_SCALE; // 36000
  time t_start;
  int errors;
  int start10;
  int end10;
  int delta10;
  real interval_deg;

  int p;
  int signed_x;
  int signed_y;
  int d_idx;
  int dist_mm;
  real angle_deg;
  real angle_rad;
  real expect_x;
  real expect_y;
  int expect_x_q;
  int expect_y_q;
  int diffx;
  int diffy;
  bit seen_points_valid;
  bit busy_cleared;

  // Capture phase words sent into the CORDIC (for diagnosing phase scaling)
  logic [15:0] phase_log [0:31];
  int phase_count;
  bit busy_seen;
  bit phase_seen;
  always @(posedge clk) begin
    if (rst) begin
      phase_count <= 0;
      busy_seen <= 1'b0;
      phase_seen <= 1'b0;
    end else begin
      if (dut.debug_phase_valid && (phase_count < 32)) begin
        phase_log[phase_count] <= dut.debug_phase_tdata;
        phase_count <= phase_count + 1;
      end
      if (dut.debug_busy) begin
        busy_seen <= 1'b1;
      end
      if (dut.debug_phase_valid) begin
        phase_seen <= 1'b1;
      end
    end
  end

  // Main test sequence
  initial begin
    int sim_packets;
    int last_pkt_idx;
    int check_pkt_idx;
    bit do_compare;
    // 1. Apply reset
    rst = 1;
    cal_tvalid = 1'b0;
    cal_tdata  = '0;
    #200ns;
    rst = 0;
    #1us;

    // 1.5 Optional: Calibrate CORDIC phase mapping (enable with +CORDIC_CAL)
    if ($test$plusargs("CORDIC_CAL")) begin
      cordic_cal_send(16'h0000, "0x0000");
      cordic_cal_send(16'h2000, "0x2000");
      cordic_cal_send(16'h4000, "0x4000");
      cordic_cal_send(16'h6000, "0x6000");
      cordic_cal_send(16'h7fff, "0x7fff");
      cordic_cal_send(16'h8000, "0x8000");
      cordic_cal_send(16'ha000, "0xa000");
      cordic_cal_send(16'hc000, "0xc000");
      cordic_cal_send(16'he000, "0xe000");
    end

    // 2. Send all packets (1 packet per line, 1ms interval)
    if (!$value$plusargs("NUM_PKTS=%d", sim_packets)) begin
      sim_packets = DEFAULT_SIM_PACKETS;
    end
    if (sim_packets > NUM_PACKETS) sim_packets = NUM_PACKETS;
    if (sim_packets < 1) sim_packets = 1;
    last_pkt_idx = 0;
    check_pkt_idx = -1;
    do_compare = 1'b1;
    $display("Testbench: Starting to send packet sequence...");
    for (int pkt = 0; pkt < sim_packets; pkt++) begin
      for (int b = 0; b < PACKET_LEN; b++) begin
        send_byte(data_packets[pkt][b]);
      end
      if (pkt != sim_packets - 1) #1ms; // 1ms between packets
    end

    // 3. Wait for processb to start (debug_busy rising)
    // processb finishes quickly; capture cases where it already ran before we start waiting
    seen_points_valid = busy_seen || phase_seen || (phase_count > 0) || dut.debug_busy;
    for (int k = 0; k < MAX_WAIT_CYCLES; k++) begin
      @(posedge clk);
      if (busy_seen || phase_seen || dut.debug_busy || (phase_count > 0)) begin
        seen_points_valid = 1'b1;
        break;
      end
    end
    if (!seen_points_valid) begin
      $display("ERROR: processb did not start (debug_busy never asserted)");
      $finish;
    end

    // Wait until processb busy deasserts (all 12 points computed)
    busy_cleared = (!dut.debug_busy && (busy_seen || phase_seen || (phase_count > 0)));
    for (int k2 = 0; k2 < MAX_WAIT_CYCLES; k2++) begin
      @(posedge clk);
      if (!dut.debug_busy) begin
        busy_cleared = 1'b1;
        break;
      end
    end
    if (!busy_cleared) begin
      $display("ERROR: processb busy did not deassert within timeout");
      $finish;
    end

    // Wait for the last processed packet (based on result_valid pulses)
    for (int k3 = 0; k3 < MAX_WAIT_CYCLES; k3++) begin
      @(posedge clk);
      if (processed_count >= sim_packets) begin
        break;
      end
    end
    if (processed_count == 0) begin
      $display("ERROR: No result_valid pulses observed");
      $finish;
    end
    last_pkt_idx = (processed_count > 0) ? (processed_count - 1) : 0;

    if ($value$plusargs("CHECK_PKT=%d", check_pkt_idx)) begin
      if (check_pkt_idx < 0) check_pkt_idx = 0;
      if (check_pkt_idx >= sim_packets) check_pkt_idx = sim_packets - 1;
    end else if (sim_packets > 1) begin
      do_compare = 1'b0;
      $display("NOTE: Multiple packets sent. Skipping compare. Use +CHECK_PKT=N to enable.");
    end

    $display("Testbench: CORDIC computation complete. Comparing theoretical vs DUT...");

    // Quick sanity: payload bytes in processa
    $display("DUT payload[2..5]=%02h %02h %02h %02h (StartAngle LSB/MSB)",
             dut.i_process.payload[2], dut.i_process.payload[3], dut.i_process.payload[4], dut.i_process.payload[5]);
    $display("DUT payload[40..41]=%02h %02h (EndAngle LSB/MSB)", dut.i_process.payload[40], dut.i_process.payload[41]);
    $display("DUT phase_count=%0d phase[0]=0x%04h (signed %0d)", phase_count, phase_log[0], $signed(phase_log[0]));

    // reconstruct and verify
    if (!do_compare) begin
      $display("Testbench: Done.");
      $finish;
    end
    errors = 0;
    // extract start/end from selected packet
    // packet: [0..1]=header, [2..3]=speed, [4..5]=start angle (centi-deg)
    //         [6..41]=12 points (3 bytes each), [42..43]=end angle (centi-deg)
    if (check_pkt_idx >= 0) begin
      start10 = {data_packets[check_pkt_idx][5], data_packets[check_pkt_idx][4]};
      end10   = {data_packets[check_pkt_idx][43], data_packets[check_pkt_idx][42]};
    end else begin
      start10 = {data_packets[last_pkt_idx][5], data_packets[last_pkt_idx][4]};
      end10   = {data_packets[last_pkt_idx][43], data_packets[last_pkt_idx][42]};
    end
    if (end10 >= start10) delta10 = end10 - start10;
    else delta10 = end10 + ANGLE_FULL - start10;
    interval_deg = delta10 / (ANGLE_SCALE * 11.0); // degrees

    for (p = 0; p < 12; p++) begin
      // DUT outputs from processb BRAM (Q16.16)
      signed_x = dut.debug_bram_x[p];
      signed_y = dut.debug_bram_y[p];

      // distance
      d_idx = 6 + p*3;
      if (check_pkt_idx >= 0) begin
        dist_mm = {data_packets[check_pkt_idx][d_idx+1], data_packets[check_pkt_idx][d_idx]};
      end else begin
        dist_mm = {data_packets[last_pkt_idx][d_idx+1], data_packets[last_pkt_idx][d_idx]};
      end

      angle_deg = (start10 / (1.0*ANGLE_SCALE)) + p * interval_deg;
      angle_rad = angle_deg * 3.14159265358979323846 / 180.0;
      expect_x = dist_mm * $cos(angle_rad);
      expect_y = dist_mm * $sin(angle_rad);
      expect_x_q = $rtoi(expect_x * 65536.0 + (expect_x >= 0 ? 0.5 : -0.5));
      expect_y_q = $rtoi(expect_y * 65536.0 + (expect_y >= 0 ? 0.5 : -0.5));

      diffx = signed_x - expect_x_q;
      diffy = signed_y - expect_y_q;
      $display("Point %0d: theta=%0.3f deg r=%0d | DUT X=0x%08h Y=0x%08h | EXP X=0x%08h Y=0x%08h | dX=%0d dY=%0d",
               p, angle_deg, dist_mm, signed_x, signed_y, expect_x_q, expect_y_q, diffx, diffy);
      if ( (diffx > TOL_Q16_16) || (diffx < -TOL_Q16_16) || (diffy > TOL_Q16_16) || (diffy < -TOL_Q16_16) ) begin
        errors++;
      end
    end

    if (errors == 0) $display("All points match expected values.");
    else $display("%0d mismatches found.", errors);
    $display("Testbench: Done.");
    $finish;
  end

endmodule