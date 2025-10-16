module processa (
  input clk,
  input rst,
  input [7:0] din,
  input empty,
  output re,
  output [7:0] dout,
  output wr_en
);

  // State definition
  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_WAIT_2C,
    STATE_READ_PAYLOAD,
    STATE_WRITE_OUTPUT
  } state_t;

  // Internal signals
  state_t state, next_state;
  logic read_enable;
  logic write_enable;
  logic [5:0] byte_counter; // Counter for 45 bytes (0 to 44)
  logic [7:0] data_memory [44:0]; // Memory for 45 bytes

  // Port assignments
  assign re = read_enable;
  assign wr_en = write_enable;
  assign dout = 8'h09; // Output is always 0x09 when writing

  // State register
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= STATE_IDLE;
    end else begin
      state <= next_state;
    end
  end

  // Counter and Memory logic
  always_ff @(posedge clk) begin
    if (rst) begin
      byte_counter <= 6'd0;
    end else if (next_state == STATE_READ_PAYLOAD && state == STATE_WAIT_2C) begin
      byte_counter <= 6'd0; // Reset counter when starting payload read
    end else if (state == STATE_READ_PAYLOAD && read_enable && ~empty) begin
      byte_counter <= byte_counter + 1;
      data_memory[byte_counter] <= din;
    end
  end

  // Combinational logic for state transitions
  always_comb begin
    next_state = state;
    read_enable = 1'b0;
    write_enable = 1'b0;

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
            next_state = STATE_READ_PAYLOAD;
          end else if (din != 8'h54) begin
            next_state = STATE_IDLE;
          end
        end
      end

      STATE_READ_PAYLOAD: begin
        if (~empty) begin
          read_enable = 1'b1;
          if (byte_counter == 6'd44) begin
            next_state = STATE_WRITE_OUTPUT;
          end
        end
      end

      STATE_WRITE_OUTPUT: begin
        write_enable = 1'b1;
        next_state = STATE_IDLE;
      end

      default: begin
        next_state = STATE_IDLE;
      end
    endcase
  end

endmodule
