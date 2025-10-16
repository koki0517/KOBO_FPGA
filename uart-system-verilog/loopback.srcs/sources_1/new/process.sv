module processa (
  input clk,
  input rst,
  input [7:0] din,
  input empty,
  output re,
  output [7:0] dout,
  output wr_en
);

  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_WAIT_2C,
    STATE_WRITE
  } state_t;

  state_t state, next_state;
  logic read_enable;
  logic write_enable;

  assign re = read_enable;
  assign wr_en = write_enable;
  assign dout = 8'h08;

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= STATE_IDLE;
    end else begin
      state <= next_state;
    end
  end

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
            next_state = STATE_WRITE;
          end else if (din == 8'h54) begin
            // Keep waiting if we see another 0x54
            next_state = STATE_WAIT_2C;
          end else begin
            next_state = STATE_IDLE;
          end
        end
      end

      STATE_WRITE: begin
        write_enable = 1'b1;
        next_state = STATE_IDLE;
      end

      default: begin
        next_state = STATE_IDLE;
      end
    endcase
  end

endmodule