
// UART module for Basys3 board
// Baud rate: 115200
// Clock: 25MHz

module uart(
    input CLK,
    input RESET,
    input RX,
    output TX,
    output [7:0] rx_data,
    output rx_valid,
    input [7:0] tx_data,
    input tx_start,
    output tx_busy
);

    // Internal signals
    wire [7:0] rx_data_internal;
    wire rx_valid_internal;
    wire tx_busy_internal;

    // UART Receiver
    uart_rx #(
        .CLKS_PER_BIT(217) // 25,000,000 / 115200
    ) uart_rx_inst (
        .i_Clock(CLK),
        .i_Rx_Serial(RX),
        .o_Rx_DV(rx_valid_internal),
        .o_Rx_Byte(rx_data_internal)
    );

    // UART Transmitter
    uart_tx #(
        .CLKS_PER_BIT(217) // 25,000,000 / 115200
    ) uart_tx_inst (
        .i_Clock(CLK),
        .i_Tx_DV(tx_start),
        .i_Tx_Byte(tx_data),
        .o_Tx_Serial(TX),
        .o_Tx_Busy(tx_busy_internal)
    );

    assign rx_data = rx_data_internal;
    assign rx_valid = rx_valid_internal;
    assign tx_busy = tx_busy_internal;

endmodule

// UART Receiver
module uart_rx #(
    parameter CLKS_PER_BIT = 217
) (
    input i_Clock,
    input i_Rx_Serial,
    output reg o_Rx_DV,
    output reg [7:0] o_Rx_Byte
);

    localparam s_IDLE = 0;
    localparam s_RX_START_BIT = 1;
    localparam s_RX_DATA_BITS = 2;
    localparam s_RX_STOP_BIT = 3;
    localparam s_CLEANUP = 4;

    reg [2:0] r_State = s_IDLE;
    reg [11:0] r_Clock_Count = 0;
    reg [2:0] r_Bit_Index = 0;
    reg [7:0] r_Rx_Byte = 0;

    always @(posedge i_Clock) begin
        case (r_State)
            s_IDLE: begin
                o_Rx_DV <= 1'b0;
                if (i_Rx_Serial == 1'b0) begin
                    r_Clock_Count <= 0;
                    r_State <= s_RX_START_BIT;
                end
            end

            s_RX_START_BIT: begin
                if (r_Clock_Count == (CLKS_PER_BIT / 2)) begin
                    if (i_Rx_Serial == 1'b0) begin
                        r_Clock_Count <= 0;
                        r_Bit_Index <= 0;
                        r_State <= s_RX_DATA_BITS;
                    end else begin
                        r_State <= s_IDLE;
                    end
                end else begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end
            end

            s_RX_DATA_BITS: begin
                if (r_Clock_Count < CLKS_PER_BIT) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_Clock_Count <= 0;
                    r_Rx_Byte[r_Bit_Index] <= i_Rx_Serial;
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                    end else begin
                        r_State <= s_RX_STOP_BIT;
                    end
                end
            end

            s_RX_STOP_BIT: begin
                if (r_Clock_Count < CLKS_PER_BIT) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    o_Rx_DV <= 1'b1;
                    o_Rx_Byte <= r_Rx_Byte;
                    r_State <= s_CLEANUP;
                end
            end
            
            s_CLEANUP: begin
                r_State <= s_IDLE;
                o_Rx_DV <= 1'b0;
            end

            default:
                r_State <= s_IDLE;
        endcase
    end
endmodule

// UART Transmitter
module uart_tx #(
    parameter CLKS_PER_BIT = 217
) (
    input i_Clock,
    input i_Tx_DV,
    input [7:0] i_Tx_Byte,
    output reg o_Tx_Serial,
    output reg o_Tx_Busy
);

    localparam s_IDLE = 0;
    localparam s_TX_START_BIT = 1;
    localparam s_TX_DATA_BITS = 2;
    localparam s_TX_STOP_BIT = 3;

    reg [2:0] r_State = s_IDLE;
    reg [11:0] r_Clock_Count = 0;
    reg [2:0] r_Bit_Index = 0;
    reg [7:0] r_Tx_Byte = 0;

    always @(posedge i_Clock) begin
        case (r_State)
            s_IDLE: begin
                o_Tx_Serial <= 1'b1;
                o_Tx_Busy <= 1'b0;
                if (i_Tx_DV) begin
                    r_Tx_Byte <= i_Tx_Byte;
                    r_Clock_Count <= 0;
                    r_State <= s_TX_START_BIT;
                end
            end

            s_TX_START_BIT: begin
                o_Tx_Serial <= 1'b0;
                o_Tx_Busy <= 1'b1;
                if (r_Clock_Count < CLKS_PER_BIT) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_Clock_Count <= 0;
                    r_Bit_Index <= 0;
                    r_State <= s_TX_DATA_BITS;
                end
            end

            s_TX_DATA_BITS: begin
                o_Tx_Serial <= r_Tx_Byte[r_Bit_Index];
                if (r_Clock_Count < CLKS_PER_BIT) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_Clock_Count <= 0;
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                    end else begin
                        r_State <= s_TX_STOP_BIT;
                    end
                end
            end

            s_TX_STOP_BIT: begin
                o_Tx_Serial <= 1'b1;
                if (r_Clock_Count < CLKS_PER_BIT) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                end else begin
                    r_State <= s_IDLE;
                end
            end

            default:
                r_State <= s_IDLE;
        endcase
    end
endmodule
