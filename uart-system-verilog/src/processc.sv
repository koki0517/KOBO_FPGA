`timescale 1ns / 1ps

module processc (
	input  logic        clk,
	input  logic        rst,
	// processb の最終計算結果
	input  logic        result_valid,
	input  logic signed [31:0] result_x [0:11],
	input  logic signed [31:0] result_y [0:11],
	// 受け取った結果を保持して出力（3パケット分）
	output logic        out_valid,
	output logic signed [31:0] out_x [0:2][0:11],
	output logic signed [31:0] out_y [0:2][0:11],
	// 特徴点出力
	output logic        feature_valid,
	output logic [5:0]  feature_count,
	output logic signed [31:0] feature_x [0:35],
	output logic signed [31:0] feature_y [0:35],
	// UART 出力 FIFO への書き込み
	input  logic        fifo_full,
	output logic [7:0]  fifo_dout,
	output logic        fifo_wr_en
);
	localparam int NUM_POINTS = 12;
	localparam int BUF_DEPTH = 3;
	localparam int TOTAL_POINTS = NUM_POINTS * BUF_DEPTH;
	localparam int M_POINTS = 12;
	localparam logic [31:0] COS2_THRESH_Q32_32 = 32'd386547057; // 0.09 in Q32.32

	integer i;
	integer j;
	integer k;
	logic [1:0] stored_count;
	logic [1:0] wr_idx;
	logic signed [31:0] mem_x [0:BUF_DEPTH-1][0:NUM_POINTS-1];
	logic signed [31:0] mem_y [0:BUF_DEPTH-1][0:NUM_POINTS-1];

	// UART送信用の内部状態
	logic        send_active;
	logic [5:0]  send_feat_idx;
	logic [3:0]  send_byte_idx;
	logic [7:0]  send_byte;
	logic [5:0]  latched_count;
	logic signed [31:0] latched_x [0:35];
	logic signed [31:0] latched_y [0:35];

	function automatic logic signed [31:0] get_point_x(
		input logic [1:0] next_wr,
		input logic [1:0] write_slot,
		input int pkt_idx,
		input int pt_idx
	);
		logic [1:0] mem_idx;
		begin
			mem_idx = (next_wr + pkt_idx[1:0]) % BUF_DEPTH;
			if (mem_idx == write_slot) begin
				get_point_x = result_x[pt_idx];
			end else begin
				get_point_x = mem_x[mem_idx][pt_idx];
			end
		end
	endfunction

	function automatic logic signed [31:0] get_point_y(
		input logic [1:0] next_wr,
		input logic [1:0] write_slot,
		input int pkt_idx,
		input int pt_idx
	);
		logic [1:0] mem_idx;
		begin
			mem_idx = (next_wr + pkt_idx[1:0]) % BUF_DEPTH;
			if (mem_idx == write_slot) begin
				get_point_y = result_y[pt_idx];
			end else begin
				get_point_y = mem_y[mem_idx][pt_idx];
			end
		end
	endfunction
	always_ff @(posedge clk) begin
		if (rst) begin
			out_valid <= 1'b0;
			feature_valid <= 1'b0;
			feature_count <= 6'd0;
			stored_count <= 2'd0;
			wr_idx <= 2'd0;
			send_active <= 1'b0;
			send_feat_idx <= 6'd0;
			send_byte_idx <= 4'd0;
			latched_count <= 6'd0;
			fifo_wr_en <= 1'b0;
			fifo_dout <= 8'h00;
			for (j = 0; j < BUF_DEPTH; j = j + 1) begin
				for (i = 0; i < NUM_POINTS; i = i + 1) begin
					mem_x[j][i] <= 32'sd0;
					mem_y[j][i] <= 32'sd0;
					out_x[j][i] <= 32'sd0;
					out_y[j][i] <= 32'sd0;
				end
			end
			for (i = 0; i < TOTAL_POINTS; i = i + 1) begin
				feature_x[i] <= 32'sd0;
				feature_y[i] <= 32'sd0;
				latched_x[i] <= 32'sd0;
				latched_y[i] <= 32'sd0;
			end
		end else begin
			logic [1:0] next_wr;
			logic [1:0] next_count;
			logic [1:0] write_slot;
			logic [1:0] map_wr;
			logic [5:0] feat_cnt;
			logic signed [31:0] p_x;
			logic signed [31:0] p_y;
			logic signed [31:0] gmx;
			logic signed [31:0] gmy;
			logic signed [31:0] gpx;
			logic signed [31:0] gpy;
			logic signed [31:0] v1x;
			logic signed [31:0] v1y;
			logic signed [31:0] v2x;
			logic signed [31:0] v2y;
			logic signed [63:0] dot;
			logic signed [63:0] mag1;
			logic signed [63:0] mag2;
			logic signed [127:0] dot2;
			logic signed [127:0] mag12;
			int before_cnt;
			int after_cnt;
			int idx;
			int pkt_idx;
			int pt_idx;

			fifo_wr_en <= 1'b0;
			feature_valid <= 1'b0;

			// バッファ保持の更新
			if (result_valid) begin
				for (i = 0; i < NUM_POINTS; i = i + 1) begin
					mem_x[wr_idx][i] <= result_x[i];
					mem_y[wr_idx][i] <= result_y[i];
				end
				next_wr = (wr_idx == BUF_DEPTH-1) ? 2'd0 : wr_idx + 2'd1;
				write_slot = wr_idx;
				wr_idx <= next_wr;
				if (stored_count < BUF_DEPTH[1:0]) begin
					next_count = stored_count + 2'd1;
					stored_count <= next_count;
				end else begin
					next_count = stored_count;
				end

				// 3パケット揃ったら特徴点検出
				if (next_count == BUF_DEPTH[1:0]) begin
					feat_cnt = 6'd0;
					for (idx = 0; idx < TOTAL_POINTS; idx = idx + 1) begin
						pkt_idx = idx / NUM_POINTS;
						pt_idx = idx % NUM_POINTS;
						p_x = get_point_x(next_wr, write_slot, pkt_idx, pt_idx);
						p_y = get_point_y(next_wr, write_slot, pkt_idx, pt_idx);

						before_cnt = (idx < M_POINTS) ? idx : M_POINTS;
						after_cnt  = ((TOTAL_POINTS - 1 - idx) < M_POINTS) ? (TOTAL_POINTS - 1 - idx) : M_POINTS;
						if ((before_cnt > 0) && (after_cnt > 0)) begin
							gmx = 32'sd0;
							gmy = 32'sd0;
							gpx = 32'sd0;
							gpy = 32'sd0;
							for (k = 1; k <= before_cnt; k = k + 1) begin
								pkt_idx = (idx - k) / NUM_POINTS;
								pt_idx = (idx - k) % NUM_POINTS;
								gmx += get_point_x(next_wr, write_slot, pkt_idx, pt_idx);
								gmy += get_point_y(next_wr, write_slot, pkt_idx, pt_idx);
							end
							for (k = 1; k <= after_cnt; k = k + 1) begin
								pkt_idx = (idx + k) / NUM_POINTS;
								pt_idx = (idx + k) % NUM_POINTS;
								gpx += get_point_x(next_wr, write_slot, pkt_idx, pt_idx);
								gpy += get_point_y(next_wr, write_slot, pkt_idx, pt_idx);
							end
							gmx = gmx / before_cnt;
							gmy = gmy / before_cnt;
							gpx = gpx / after_cnt;
							gpy = gpy / after_cnt;

							v1x = gmx - p_x;
							v1y = gmy - p_y;
							v2x = gpx - p_x;
							v2y = gpy - p_y;

							dot = $signed(v1x) * $signed(v2x) + $signed(v1y) * $signed(v2y);
							mag1 = $signed(v1x) * $signed(v1x) + $signed(v1y) * $signed(v1y);
							mag2 = $signed(v2x) * $signed(v2x) + $signed(v2y) * $signed(v2y);
							dot2 = $signed(dot) * $signed(dot);
							mag12 = $signed(mag1) * $signed(mag2);

							if ((mag1 != 0) && (mag2 != 0) && (dot2 < (mag12 * COS2_THRESH_Q32_32 >>> 32))) begin
								feature_x[feat_cnt] <= p_x;
								feature_y[feat_cnt] <= p_y;
								latched_x[feat_cnt] <= p_x;
								latched_y[feat_cnt] <= p_y;
								$display("FEATURE %0d: x=%0.3f mm y=%0.3f mm",
								         feat_cnt,
								         $itor(p_x) / 65536.0,
								         $itor(p_y) / 65536.0);
								feat_cnt = feat_cnt + 6'd1;
							end
						end
					end

					feature_count <= feat_cnt;
					feature_valid <= 1'b1;
					latched_count <= feat_cnt;
					send_active <= 1'b1;
					send_feat_idx <= 6'd0;
					send_byte_idx <= 4'd0;
				end
			end

			// out_x/out_y を時系列順に並べ替え（最古→最新）
			map_wr = wr_idx;
			if (result_valid) begin
				map_wr = (wr_idx == BUF_DEPTH-1) ? 2'd0 : wr_idx + 2'd1;
			end
			for (j = 0; j < BUF_DEPTH; j = j + 1) begin
				for (i = 0; i < NUM_POINTS; i = i + 1) begin
					logic [1:0] idx_map;
					idx_map = (map_wr + j[1:0]) % BUF_DEPTH;
					out_x[j][i] <= mem_x[idx_map][i];
					out_y[j][i] <= mem_y[idx_map][i];
				end
			end

			out_valid <= (stored_count != 2'd0) || result_valid;

			// UART送信FSM
			if (send_active && !fifo_full) begin
				case (send_byte_idx)
					4'd0: send_byte = 8'hF0;
					4'd1: send_byte = latched_count;
					default: begin
						logic [31:0] cur_x;
						logic [31:0] cur_y;
						cur_x = latched_x[send_feat_idx];
						cur_y = latched_y[send_feat_idx];
						case (send_byte_idx)
							4'd2: send_byte = cur_x[7:0];
							4'd3: send_byte = cur_x[15:8];
							4'd4: send_byte = cur_x[23:16];
							4'd5: send_byte = cur_x[31:24];
							4'd6: send_byte = cur_y[7:0];
							4'd7: send_byte = cur_y[15:8];
							4'd8: send_byte = cur_y[23:16];
							4'd9: send_byte = cur_y[31:24];
							default: send_byte = 8'h00;
						endcase
					end
				endcase

				fifo_dout <= send_byte;
				fifo_wr_en <= 1'b1;

				if (send_byte_idx == 4'd9) begin
					send_byte_idx <= 4'd2;
					if (send_feat_idx + 6'd1 >= latched_count) begin
						send_active <= 1'b0;
					end else begin
						send_feat_idx <= send_feat_idx + 6'd1;
					end
				end else begin
					send_byte_idx <= send_byte_idx + 4'd1;
				end
			end
		end
	end
endmodule
