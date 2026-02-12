`timescale 1ns / 1ps

module cordic_sincos (
  input  logic        aclk,
  input  logic        s_axis_phase_tvalid,
  input  logic [15:0] s_axis_phase_tdata,
  output logic        m_axis_dout_tvalid,
  output logic [31:0] m_axis_dout_tdata
);
  localparam int ITER = 16;

  // atan(2^-i) scaled to Scaled Radians (2^15 = pi)
  localparam logic signed [31:0] ATAN_TABLE [0:ITER-1] = '{
    32'sd8192, 32'sd4836, 32'sd2555, 32'sd1297,
    32'sd651,  32'sd326,  32'sd163,  32'sd81,
    32'sd41,   32'sd20,   32'sd10,   32'sd5,
    32'sd3,    32'sd1,    32'sd1,    32'sd0
  };

  // K (gain compensation) for 16 iterations in Q4.28
  localparam logic signed [31:0] K_Q4_28 = 32'sd163008219;

  function automatic logic signed [15:0] sat16(input logic signed [31:0] v);
    if (v > 32'sd32767) begin
      sat16 = 16'sh7fff;
    end else if (v < -32'sd32768) begin
      sat16 = 16'sh8000;
    end else begin
      sat16 = v[15:0];
    end
  endfunction

  function automatic logic [31:0] cordic_eval(input logic signed [15:0] phase_in);
    logic signed [31:0] x;
    logic signed [31:0] y;
    logic signed [31:0] z;
    logic signed [31:0] x_new;
    logic signed [31:0] y_new;
    logic signed [31:0] z_new;
    logic signed [31:0] cos_q2_14;
    logic signed [31:0] sin_q2_14;
    logic signed [15:0] cos16;
    logic signed [15:0] sin16;
    logic signed [31:0] z_in;
    logic signed [31:0] cos_adj;
    logic signed [31:0] sin_adj;
    logic [1:0] quadrant;
    int i;
    begin
      x = K_Q4_28;
      y = 32'sd0;
      z_in = {{16{phase_in[15]}}, phase_in};
      quadrant = 2'd0;

      // Range reduction to [-pi/2, +pi/2]
      if (z_in > 32'sd16384) begin
        // +90..+180
        z = z_in - 32'sd16384;
        quadrant = 2'd1;
      end else if (z_in < -32'sd16384) begin
        // -180..-90
        z = z_in + 32'sd16384;
        quadrant = 2'd2;
      end else begin
        z = z_in;
      end

      for (i = 0; i < ITER; i = i + 1) begin
        if (z >= 0) begin
          x_new = x - (y >>> i);
          y_new = y + (x >>> i);
          z_new = z - ATAN_TABLE[i];
        end else begin
          x_new = x + (y >>> i);
          y_new = y - (x >>> i);
          z_new = z + ATAN_TABLE[i];
        end
        x = x_new;
        y = y_new;
        z = z_new;
      end

      // Q4.28 -> Q2.14
      cos_q2_14 = x >>> 14;
      sin_q2_14 = y >>> 14;

      // Quadrant correction
      case (quadrant)
        2'd1: begin // +90..+180: cos=-sin', sin=cos'
          cos_adj = -sin_q2_14;
          sin_adj =  cos_q2_14;
        end
        2'd2: begin // -180..-90: cos=sin', sin=-cos'
          cos_adj =  sin_q2_14;
          sin_adj = -cos_q2_14;
        end
        default: begin
          cos_adj = cos_q2_14;
          sin_adj = sin_q2_14;
        end
      endcase

      cos16 = sat16(cos_adj);
      sin16 = sat16(sin_adj);
      cordic_eval = {cos16, sin16}; // [31:16]=cos, [15:0]=sin
    end
  endfunction

  always_ff @(posedge aclk) begin
    m_axis_dout_tvalid <= s_axis_phase_tvalid;
    if (s_axis_phase_tvalid) begin
      m_axis_dout_tdata <= cordic_eval($signed(s_axis_phase_tdata));
    end
  end
endmodule
