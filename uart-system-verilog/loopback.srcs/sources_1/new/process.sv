`timescale 1ns / 1ps

module processa #(
  parameter [31:0] CLOCK_FREQUENCY = 32'd50_000_000
) (
  input clk,
  input rst,
  input [7:0] din,
  input empty,
  output re,
  output [7:0] dout,
  output wr_en,
  output led_enable
);

  // State definition for a multi-cycle state machine
  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_FETCH_1,
    STATE_WAIT_2C,
    STATE_FETCH_2C,
    STATE_SEND
  } state_t;

  // Internal signals
  state_t state, next_state;
  logic read_enable;
  logic write_enable;
  logic [7:0] dout_reg;
  logic led_enable_reg;

  // Timeout counter for 2 seconds
  localparam [31:0] TIMEOUT_MAX = CLOCK_FREQUENCY * 2 - 1;
  logic [31:0] timeout_counter;

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
    end else if (state == STATE_FETCH_1 && din == 8'h54) begin
      // 'T' received, start the 2-second timer for the LED
      timeout_counter <= 32'd0;
      led_enable_reg <= 1'b1;
    end else if (timeout_counter < TIMEOUT_MAX) begin
      timeout_counter <= timeout_counter + 1;
    end else begin
      // Timer expired, turn off LED
      led_enable_reg <= 1'b0;
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
        // If input FIFO has data, assert read enable and go to fetch state
        if (~empty) begin
          read_enable = 1'b1;
          next_state = STATE_FETCH_1;
        end
      end

      STATE_FETCH_1: begin
        // In this state, `din` has the data read from the previous cycle.
        // Check if it's 'T' (0x54).
        if (din == 8'h54) begin
          next_state = STATE_WAIT_2C;
        end else begin
          next_state = STATE_IDLE;
        end
      end

      STATE_WAIT_2C: begin
        // Wait for the next byte. If available, fetch it.
        if (~empty) begin
          read_enable = 1'b1;
          next_state = STATE_FETCH_2C;
        end
      end

      STATE_FETCH_2C: begin
        // In this state, `din` has the second byte.
        // Check if it's ',' (0x2c).
        if (din == 8'h2c) begin
          next_state = STATE_SEND;
        end else begin
          next_state = STATE_IDLE;
        end
      end

      STATE_SEND: begin
        // Send the response byte (0x08)
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