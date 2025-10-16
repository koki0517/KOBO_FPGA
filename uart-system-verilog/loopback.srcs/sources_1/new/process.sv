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
  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_WAIT_2C,
    STATE_READ_PAYLOAD,
    STATE_WRITE_START_LSB,
    STATE_WRITE_START_MSB,
    STATE_WRITE_END_LSB,
    STATE_WRITE_END_MSB
  } state_t;

  // Internal signals
  state_t state, next_state;
  logic read_enable;
  logic write_enable;
  logic [5:0] byte_counter; // Counter for 45 bytes (0 to 44)
  logic [7:0] temp_lsb; // Temporary storage for LSB of an angle
  logic [15:0] stored_start_angle;
  logic [15:0] stored_end_angle;
  logic [7:0] dout_reg;

  // Port assignments
  assign re = read_enable;
  assign wr_en = write_enable;
  assign dout = dout_reg;

  // State register
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= STATE_IDLE;
    end else begin
      state <= next_state;
    end
  end

  // Logic to store angles during reception
  always_ff @(posedge clk) begin
    if (rst) begin
      stored_start_angle <= 16'd0;
      stored_end_angle <= 16'd0;
      temp_lsb <= 8'd0;
    end else if (state == STATE_READ_PAYLOAD && read_enable && ~empty) begin
      case (byte_counter)
        6'd2: temp_lsb <= din; // Capture Start Angle LSB
        6'd3: stored_start_angle <= {din, temp_lsb}; // Capture MSB and form 16-bit word
        6'd40: temp_lsb <= din; // Capture End Angle LSB
        6'd41: stored_end_angle <= {din, temp_lsb}; // Capture MSB and form 16-bit word
        default: ; // Do nothing for other bytes
      endcase
    end
  end

  // Counter logic
  always_ff @(posedge clk) begin
    if (rst) begin
      byte_counter <= 6'd0;
    end else if (next_state == STATE_READ_PAYLOAD && state == STATE_WAIT_2C) begin
      byte_counter <= 6'd0; // Reset counter when starting payload read
    end else if (state == STATE_READ_PAYLOAD && read_enable && ~empty) begin
      byte_counter <= byte_counter + 1;
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
            next_state = STATE_WRITE_START_LSB;
          end
        end
      end

      STATE_WRITE_START_LSB: begin
        write_enable = 1'b1;
        dout_reg = stored_start_angle[7:0]; // LSB
        next_state = STATE_WRITE_START_MSB;
      end

      STATE_WRITE_START_MSB: begin
        write_enable = 1'b1;
        dout_reg = stored_start_angle[15:8]; // MSB
        next_state = STATE_WRITE_END_LSB;
      end

      STATE_WRITE_END_LSB: begin
        write_enable = 1'b1;
        dout_reg = stored_end_angle[7:0]; // LSB
        next_state = STATE_WRITE_END_MSB;
      end

      STATE_WRITE_END_MSB: begin
        write_enable = 1'b1;
        dout_reg = stored_end_angle[15:8]; // MSB
        next_state = STATE_IDLE;
      end

      default: begin
        next_state = STATE_IDLE;
      end
    endcase
  end

endmodule
