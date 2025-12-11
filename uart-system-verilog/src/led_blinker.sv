module led_blinker #(
  parameter [31:0] CLOCK_FREQUENCY = 32'd33_000_000,
  parameter [31:0] BLINK_FREQUENCY = 32'd2  // 点滅周波数 (Hz)
) (
  input clk,
  input rst,
  input enable,  // 点滅を有効にする信号
  output reg led
);

  // 2Hzの点滅 = 0.5秒周期でトグル
  // カウンタの最大値 = CLOCK_FREQUENCY / (BLINK_FREQUENCY * 2)
  localparam [31:0] COUNT_MAX = CLOCK_FREQUENCY / (BLINK_FREQUENCY * 2) - 1;
  
  reg [31:0] counter;

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= 32'd0;
      led <= 1'b0;
    end else if (enable) begin
      if (counter >= COUNT_MAX) begin
        counter <= 32'd0;
        led <= ~led;  // LEDをトグル
      end else begin
        counter <= counter + 1;
      end
    end else begin
      counter <= 32'd0;
      led <= 1'b0;  // enableがオフの時はLEDを消灯
    end
  end

endmodule
