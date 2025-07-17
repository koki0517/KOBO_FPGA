`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/10/2025 05:09:18 PM
// Design Name: 
// Module Name: uartTop
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


`include "uart_module.v"

module uartTop(
        input CLK100M,     // 100MHz clock input
        input rx,         // UART RX
        input [15:0] SW,    // Switch (SW3,SW2,SW1,SW0)
        output [15:0] LED,   // LED    (LD3,LD2,LD1,LD0)
        output tx,         // UART TX
        inout PS2Clk,      // PS/2 Clock
        inout PS2Data      // PS/2 Data
        );
    
    wire [7:0] rx_byte;
    wire rx_dv;
    wire tx_done;
    
    // 送信制御用の信号
    reg tx_start;
    reg [7:0] tx_data;
    reg tx_busy;

    // assign LED = SW; // ←複数ドライバエラー回避のため削除

    // 受信データを送信用にラッチするロジック
    always @(posedge CLK100M) begin
        if (rx_dv && !tx_busy) begin
            // 新しいデータを受信し、送信が空いている場合
            tx_data <= rx_byte;
            tx_start <= 1;
            tx_busy <= 1;
        end else if (tx_done) begin
            // 送信完了時
            tx_start <= 0;
            tx_busy <= 0;
        end else begin
            // その他の場合はtx_startをクリア
            tx_start <= 0;
        end
    end

    uart_rx #(
        .p_CLKS_PER_BIT(10417)
    ) uart_rx_inst (
        .i_clk(CLK100M),
        .i_rx_serial(rx),
        .o_rx_dv(rx_dv),
        .o_rx_byte(rx_byte)
    );

    uart_tx #(
        .BAUD_RATE(10417)
    ) uart_tx_inst (
        .clk(CLK100M),
        .reset(0), // Assuming no reset for now
        .tx_start(tx_start),
        .data_in(tx_data),
        .tx_done(tx_done),
        .tx(tx)
    );

    assign LED[7:0] = rx_byte;
    assign LED[8] = rx_dv;
    assign LED[9] = tx_done;
    assign LED[10] = tx_busy;
    assign LED[11] = tx_start;
    assign LED[15:12] = 0;


    assign PS2Clk = 1'bz; // 仮の三態（必要に応じて修正）
    assign PS2Data = 1'bz; // 仮の三態（必要に応じて修正）
endmodule
