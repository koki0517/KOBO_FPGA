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

  // Standalone CORDIC instance for phase-format calibration
  logic        cal_tvalid;
  logic [15:0] cal_tdata;
  wire         cal_out_valid;
  wire  [31:0] cal_out_data;

  cordic_0 cordic_cal (
    .aclk              (clk),
    .s_axis_phase_tvalid(cal_tvalid),
    .s_axis_phase_tdata (cal_tdata),
    .m_axis_dout_tvalid (cal_out_valid),
    .m_axis_dout_tdata  (cal_out_data)
  );

  // Clock generation block
  always #(CLK_PERIOD / 2.0 * 1ns) clk = ~clk;

  task automatic cordic_cal_send(input logic [15:0] phase_word, input string label);
    int cyc;
    begin
      begin : cal_wait_block
      // Drive a single-beat transfer (no TREADY on this IP instance)
      cal_tdata  = phase_word;
      cal_tvalid = 1'b1;
      @(posedge clk);
      cal_tvalid = 1'b0;

      // Wait for the next valid pulse from the pipelined core
      for (cyc = 0; cyc < 200; cyc++) begin
        @(posedge clk);
        if (cal_out_valid) begin
          $display("CAL %s: phase=0x%04h signed=%0d unsigned=%0d dout=0x%08h hi=%0d lo=%0d valid=%0b",
                   label,
                   phase_word,
                   $signed(phase_word),
                   phase_word,
                   cal_out_data,
                   $signed(cal_out_data[31:16]),
                   $signed(cal_out_data[15:0]),
                   cal_out_valid);
          disable cal_wait_block;
        end
      end

      $display("CAL %s: TIMEOUT waiting for cal_out_valid", label);
      end
    end
  endtask

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

  // Stimulus packet bytes (queue)
  logic [7:0] data_queue[$] = '{
    8'h54, 8'h2c, 8'h14, 8'h0e, 8'h53, 8'h49, 8'hc5, 8'h00, 8'hf3, 8'hbd,
    8'h00, 8'hf0, 8'hb9, 8'h00, 8'hf4, 8'hae, 8'h00, 8'hf4, 8'ha9, 8'h00,
    8'hf4, 8'ha6, 8'h00, 8'hf5, 8'ha5, 8'h00, 8'hf2, 8'h9c, 8'h00, 8'hf5,
    8'h97, 8'h00, 8'hf1, 8'h95, 8'h00, 8'hf4, 8'h94, 8'h00, 8'hf4, 8'h93,
    8'h00, 8'hf5, 8'hbf, 8'h4c, 8'hca, 8'h70, 8'h88
  };

  // Capture bytes output from fifo via transmitter (use DUT hierarchical signals)
  byte out_bytes[$];
  logic tx_re_d;
  always @(posedge clk) begin
    if (rst) begin
      tx_re_d <= 1'b0;
    end else begin
      tx_re_d <= dut.tx_re;
    end

    // fifo_buffer has 1-cycle read latency; capture data one cycle after rd_en.
    if (tx_re_d) begin
      out_bytes.push_back(dut.fifo_out_dout);
    end
  end

  // Variables for analysis (declared at module scope for XSim compatibility)
  localparam int EXPECT_BYTES = 12*8;
  // Allow small fixed-point/CORDIC quantization error in Q16.16
  localparam int TOL_Q16_16 = 5000;
  localparam time OUT_TIMEOUT = 30ms;
  localparam int ANGLE_SCALE = 100;
  localparam int ANGLE_FULL  = 360 * ANGLE_SCALE; // 36000
  time t_start;
  int out_count;
  int errors;
  int start10;
  int end10;
  int delta10;
  real interval_deg;

  int p;
  int base;
  int unsigned u32x;
  int unsigned u32y;
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

  // Capture phase words sent into the CORDIC (for diagnosing phase scaling)
  logic [15:0] phase_log [0:31];
  int phase_count;
  always @(posedge clk) begin
    if (rst) begin
      phase_count <= 0;
    end else begin
      if (dut.i_process.s_axis_phase_tvalid && (phase_count < 32)) begin
        phase_log[phase_count] <= dut.i_process.s_axis_phase_tdata;
        phase_count <= phase_count + 1;
      end
    end
  end

  // Main test sequence
  initial begin
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

    // 2. Send all bytes in the queue
    $display("Testbench: Starting to send byte sequence...");
    foreach (data_queue[i]) begin
      send_byte(data_queue[i]);
      #10us; // Wait a bit between bytes
    end

    // 3. Wait long enough for all data to be processed + transmitted.
    // 115200bps => ~86.8us per byte (10 bits). 96 bytes needs ~8.3ms plus processing.
    // Wait until all expected bytes are captured (or timeout).
    t_start = $time;
    while ((out_bytes.size() < EXPECT_BYTES) && (($time - t_start) < OUT_TIMEOUT)) begin
      #100us;
    end

    // 4. Finish the simulation
    $display("Testbench: Simulation finished. Checking outputs...");

    // Analyze captured output bytes
    out_count = out_bytes.size();
    $display("Captured %0d bytes from output FIFO", out_count);

    // Expect 12 points * 8 bytes each = 96 bytes
    if (out_count != EXPECT_BYTES) begin
      $display("ERROR: unexpected output byte count (expected %0d)", EXPECT_BYTES);
      $display("Hint: if this is smaller, increase OUT_TIMEOUT or baud assumptions.");
      $finish;
    end

    // Quick sanity: confirm DUT payload alignment (first bytes should be Speed/StartAngle)
    $display("DUT payload[0..5]=%02h %02h %02h %02h %02h %02h",
             dut.i_process.payload[0], dut.i_process.payload[1], dut.i_process.payload[2],
             dut.i_process.payload[3], dut.i_process.payload[4], dut.i_process.payload[5]);
    $display("DUT payload[40..41]=%02h %02h (EndAngle LSB/MSB)", dut.i_process.payload[40], dut.i_process.payload[41]);
    $display("DUT start_q8_8=%0d interval_q8_8=%0d", dut.i_process.start_q8_8, dut.i_process.interval_q8_8);
    $display("DUT cordic[0] cos=%0d (0x%04h) sin=%0d (0x%04h)",
         $signed(dut.i_process.cordic_cos[0]), dut.i_process.cordic_cos[0],
         $signed(dut.i_process.cordic_sin[0]), dut.i_process.cordic_sin[0]);
    $display("DUT phase_count=%0d phase[0]=0x%04h (signed %0d)", phase_count, phase_log[0], $signed(phase_log[0]));

    // reconstruct and verify
    errors = 0;
    // extract start/end from original data_queue
    // packet: [0..1]=header, [2..3]=speed, [4..5]=start angle (centi-deg)
    //         [6..41]=12 points (3 bytes each), [42..43]=end angle (centi-deg)
    start10 = {data_queue[5], data_queue[4]};
    end10   = {data_queue[43], data_queue[42]};
    if (end10 >= start10) delta10 = end10 - start10;
    else delta10 = end10 + ANGLE_FULL - start10;
    interval_deg = delta10 / (ANGLE_SCALE * 11.0); // degrees

    for (p = 0; p < 12; p++) begin
      // reconstruct X
      base = p*8;
      u32x = {out_bytes[base], out_bytes[base+1], out_bytes[base+2], out_bytes[base+3]};
      u32y = {out_bytes[base+4], out_bytes[base+5], out_bytes[base+6], out_bytes[base+7]};
      signed_x = $signed(u32x);
      signed_y = $signed(u32y);

      // distance
      d_idx = 6 + p*3;
      dist_mm = {data_queue[d_idx+1], data_queue[d_idx]};

      angle_deg = (start10 / (1.0*ANGLE_SCALE)) + p * interval_deg;
      angle_rad = angle_deg * 3.14159265358979323846 / 180.0;
      expect_x = dist_mm * $cos(angle_rad);
      expect_y = dist_mm * $sin(angle_rad);
      expect_x_q = $rtoi(expect_x * 65536.0 + (expect_x >= 0 ? 0.5 : -0.5));
      expect_y_q = $rtoi(expect_y * 65536.0 + (expect_y >= 0 ? 0.5 : -0.5));

      diffx = signed_x - expect_x_q;
      diffy = signed_y - expect_y_q;
      if ( (diffx > TOL_Q16_16) || (diffx < -TOL_Q16_16) || (diffy > TOL_Q16_16) || (diffy < -TOL_Q16_16) ) begin
        $display("Point %0d mismatch: got X=0x%08h Y=0x%08h expected X=0x%08h Y=0x%08h diffX=%0d diffY=%0d", p, signed_x, signed_y, expect_x_q, expect_y_q, diffx, diffy);
        errors++;
      end else begin
        $display("Point %0d OK: X=0x%08h Y=0x%08h diffX=%0d diffY=%0d", p, signed_x, signed_y, diffx, diffy);
      end
    end

    if (errors == 0) $display("All points match expected values.");
    else $display("%0d mismatches found.", errors);
    $display("Testbench: Done.");
    $finish;
  end

endmodule