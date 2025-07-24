`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2025 04:48:49 PM
// Design Name: 
// Module Name: process
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module processa #(
  parameter [31:0] WORD_WIDTH      = 32'd8
)  (
  input                  clk,
  input                  rst,
  input [WORD_WIDTH-1:0] din,
  input                  empty,
  input  [8:0]           fifo_data_count, // FIFO内データ数
  output                 re,         // FIFOからのリードイネーブル
  output [7:0]           data        // 受け取ったデータ
);


  logic [7:0] data_reg;
  state_t state, next_state;
  logic [15:0] speed; // deg/s 回転速度
  logic [15:0] start_angle;
  logic [15:0] end_angle;
  logic [15:0] time_stamp;
  logic [7:0] crc;
  logic [7:0] bulk_buffer [0:44]; // 45バイト分のデータ格納用
  polar_point polar_data_array [0:11]; // 極座標データ

  // type definition
  typedef enum logic [2:0] {
    STATE_WAIT      = 3'h0,
    STATE_READ      = 3'h1,
    STATE_DATA      = 3'h2,
    STATE_DATA2     = 3'h3,
    STATE_BULK_READ = 3'h4
  } state_t;

  typedef struct packed{
    logic [15:0] radius;
    logic [15:0] angle;
    logic [7:0] intensity;
  } polar_point;

  logic [5:0] bulk_count; // 0〜45までカウント
	logic [15:0] interval;

  assign data = data_reg;
  assign re = (state == STATE_READ || state == STATE_DATA || state == STATE_BULK_READ); // バルク読み込み時もリードイネーブル

  // 状態遷移
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= STATE_WAIT;
      data_reg <= 8'd0;
      bulk_count <= 6'd0;
    end else begin
      state <= next_state;
      case (state)
        STATE_READ:  data_reg <= din; // 1バイト目受信
        STATE_DATA:  data_reg <= din; // 2バイト目受信
        STATE_BULK_READ: begin
          data_reg <= din; // バルクデータ受信
          if (bulk_count < 6'd45) begin
            bulk_buffer[bulk_count] <= din; // 配列に格納
            bulk_count <= bulk_count + 1'b1;
          end else begin
            bulk_buffer[bulk_count] <= din; // 最後の1バイト
            bulk_count <= 6'd0;
            // データの割り当て
            speed <= {bulk_buffer[1] << 8 | bulk_buffer[0]};
            start_angle <= {bulk_buffer[3] << 8 | bulk_buffer[2]};
            end_angle <= {bulk_buffer[41] << 8 | bulk_buffer[40]};
            time_stamp <= {bulk_buffer[43] << 8 | bulk_buffer[42]};

            // interval計算（整数型）
            if (start_angle > end_angle) begin
              interval = (360 - start_angle + end_angle) / 11;
            end else begin
              interval = (end_angle - start_angle) / 11;
            end

            for (int i = 0; i < 12; i = i + 1) begin
              polar_data_array[i].radius <= {bulk_buffer[5 + i*3], bulk_buffer[4 + i*3]};
							polar_data_array[i].angle <= start_angle + interval * i;
              polar_data_array[i].intensity <= bulk_buffer[6 + i*3];
            end
          end
        end
        default: bulk_count <= 6'd0;
      endcase
    end
  end

  always_comb begin
    case (state)
      STATE_WAIT:
        // fifo_data_countが47を超えるまで待機
        next_state = (fifo_data_count > 47) ? (empty ? STATE_WAIT : STATE_READ) : STATE_WAIT;
      STATE_READ:
        // ヘッダー0x54を検出したらデータ読み取り状態へ
        next_state = (din == 8'h54) ? STATE_DATA : STATE_WAIT;
      STATE_DATA:
        // 2バイト目を受信するためSTATE_DATA2へ
        next_state = empty ? STATE_DATA : STATE_DATA2;
      STATE_DATA2:
        // 2バイト目が0x2cならバルク読み込みへ、違えば待機に戻す
        next_state = (din == 8'h2c) ? STATE_BULK_READ : STATE_WAIT;
      STATE_BULK_READ:
        // 45バイト読み終わったら待機に戻す
        next_state = (bulk_count == 6'd45) ? STATE_WAIT : STATE_BULK_READ;
      default:
        next_state = STATE_WAIT;
    endcase
  end

endmodule
