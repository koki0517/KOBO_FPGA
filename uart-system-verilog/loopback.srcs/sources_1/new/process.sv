`timescale 1ns / 1ps

module processa #(
  parameter [31:0] CLOCK_FREQUENCY = 32'd33_000_000
) (
  input clk,
  input rst,
  input [7:0] din,
  input empty,
  output re,
  output [7:0] dout,
  output wr_en,
  output led_enable  // LED点滅制御信号
);

  // State definition
  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_WAIT_2C,
    STATE_SEND
  } state_t;

  // Internal signals
  state_t state, next_state;
  logic read_enable;
  logic write_enable;
  logic [7:0] dout_reg;

  // Timeout counter for 2 seconds
  // 2秒 = CLOCK_FREQUENCY * 2
  localparam [31:0] TIMEOUT_MAX = CLOCK_FREQUENCY * 2 - 1;
  logic [31:0] timeout_counter;
  logic led_enable_reg;

  // Port assignments
  assign re = read_enable;
  assign wr_en = write_enable;
  assign dout = dout_reg;
  assign led_enable = led_enable_reg;

  // State register
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= STATE_IDLE;
    end else begin
      state <= next_state;
    end
  end

  // Timeout counter and LED enable logic
  always_ff @(posedge clk) begin
    if (rst) begin
      timeout_counter <= 32'd0;
      led_enable_reg <= 1'b0;
    end else begin
      // 0x54を検出したらカウンタをリセットし、LED点滅を有効化
      if (state == STATE_IDLE && read_enable && din == 8'h54) begin
        timeout_counter <= 32'd0;
        led_enable_reg <= 1'b1;
      end 
      // タイムアウトカウンタをインクリメント
      else if (timeout_counter < TIMEOUT_MAX) begin
        timeout_counter <= timeout_counter + 1;
      end 
      // 2秒経過したらLED点滅を無効化
      else begin
        led_enable_reg <= 1'b0;
      end
    end
  end

  // Combinational logic for state transitions and outputs
  always_comb begin
    next_state = state;
    read_enable = 1'b0;
    write_enable = 1'b0;
    dout_reg = 8'h00;

    case (state)
      STATE_IDLE: begin
        if (~empty) begin
          read_enable = 1'b1;
          if (din == 8'h54) begin
            next_state = STATE_WAIT_2C;
          end
        end
      end

      STATE_WAIT_2C: begin
        if (~empty) begin
          read_enable = 1'b1;
          if (din == 8'h2c) begin
            next_state = STATE_SEND;
          end else if (din != 8'h54) begin
            next_state = STATE_IDLE;
          end
        end
      end

      STATE_SEND: begin
        write_enable = 1'b1;
        dout_reg = 8'h08;
        next_state = STATE_IDLE;
      end

      default: begin
        next_state = STATE_IDLE;
      end
    endcase
  end

endmodule
