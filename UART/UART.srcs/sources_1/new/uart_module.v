/*
Author: Shubhayu Das
Email: shubhayu.das@iitkgp.ac.in
*/


/*
This module receives a byte of data over UART. 
The baud rate is set to 9600.
The system clock is 100 MHz.

Number of ticks per bit = 100 * 10^6 / 9600 = 10417 (approx)

The FSM has three states:
    - IDLE: Waits for the start bit (a logic low)
    - RX_START_BIT: Waits for half a bit time to sample the start bit
    - RX_DATA_BITS: Samples the 8 data bits
    - RX_STOP_BIT: Waits for the stop bit (a logic high)
    - CLEANUP: Sets the output valid signal high for one clock cycle
*/

module uart_rx(
    input i_clk,
    input i_rx_serial,
    output o_rx_dv,
    output [7:0] o_rx_byte
);

    // Parameters
    parameter p_CLKS_PER_BIT = 10417;

    // FSM states
    localparam IDLE = 0;
    localparam RX_START_BIT = 1;
    localparam RX_DATA_BITS = 2;
    localparam RX_STOP_BIT = 3;
    localparam CLEANUP = 4;

    // Internal registers
    reg [2:0] r_SM_Main = IDLE;
    reg [13:0] r_Clk_Count = 0;
    reg [2:0] r_Bit_Index = 0;
    reg [7:0] r_RX_Byte = 0;
    reg r_RX_DV = 0;


    // Output assignments
    assign o_rx_dv = r_RX_DV;
    assign o_rx_byte = r_RX_Byte;


    // Main FSM
    always @(posedge i_clk) begin
        case (r_SM_Main)
            IDLE: begin
                r_RX_DV <= 0;
                r_Clk_Count <= 0;
                r_Bit_Index <= 0;
                r_RX_Byte <= 0;

                if (i_rx_serial == 0) begin
                    r_SM_Main <= RX_START_BIT;
                end
            end

            RX_START_BIT: begin
                if (r_Clk_Count == (p_CLKS_PER_BIT / 2) - 1) begin
                    if (i_rx_serial == 0) begin
                        r_Clk_Count <= 0;
                        r_SM_Main <= RX_DATA_BITS;
                    end else begin
                        r_SM_Main <= IDLE;
                    end
                end else begin
                    r_Clk_Count <= r_Clk_Count + 1;
                end
            end

            RX_DATA_BITS: begin
                if (r_Clk_Count < p_CLKS_PER_BIT - 1) begin
                    r_Clk_Count <= r_Clk_Count + 1;
                end else begin
                    r_Clk_Count <= 0;
                    r_RX_Byte[r_Bit_Index] <= i_rx_serial;

                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                    end else begin
                        r_SM_Main <= RX_STOP_BIT;
                    end
                end
            end

            RX_STOP_BIT: begin
                if (r_Clk_Count < p_CLKS_PER_BIT - 1) begin
                    r_Clk_Count <= r_Clk_Count + 1;
                end else begin
                    if (i_rx_serial == 1) begin
                        r_SM_Main <= CLEANUP;
                    end else begin
                        r_SM_Main <= IDLE;
                    end
                end
            end

            CLEANUP: begin
                r_RX_DV <= 1;
                r_SM_Main <= IDLE;
            end

            default: begin
                r_SM_Main <= IDLE;
            end
        endcase
    end

endmodule

/*
This is the UART TX module.
It takes in a byte, and transmits it over the tx line
A FSM is used to keep track of the states.
A counter is used to count the number of clock cycles for each bit.
*/
`timescale 1ns / 1ps
module uart_tx(
    // We need a clock and a reset
    input clk,
    input reset,
    // We need a signal to start the transmission
    input tx_start,
    // We need the data to be transmitted
    input [7:0] data_in,
    // We need a signal to indicate that the transmission is done
    output reg tx_done,
    // We need the tx line
    output reg tx
    );

    // We need a state machine to keep track of the transmission
    // The states are:
    // 0: Idle
    // 1: Start bit
    // 2: Data bits
    // 3: Stop bit
    reg [1:0] state;
    // We need a counter to count the number of clock cycles for each bit
    reg [15:0] counter;
    // We need a variable to store the data to be transmitted
    reg [7:0] data;
    // We need a variable to keep track of the number of bits transmitted
    reg [2:0] bit_count;

    // We need to set the baud rate
    // The baud rate is 9600
    // The clock frequency is 100MHz
    // The number of clock cycles per bit is 100MHz / 9600 = 10417
    parameter BAUD_RATE = 10417;

    // We need to initialize the state machine
    initial begin
        state = 0;
        counter = 0;
        data = 0;
        bit_count = 0;
        tx_done = 0;
        tx = 1;
    end

    // We need to implement the state machine
    always @(posedge clk) begin
        if (reset) begin
            state <= 0;
            counter <= 0;
            data <= 0;
            bit_count <= 0;
            tx_done <= 0;
            tx <= 1;
        end else begin
            case (state)
                0: begin
                    // In the idle state, we wait for the tx_start signal
                    if (tx_start) begin
                        // When we receive the tx_start signal, we load the data
                        data <= data_in;
                        // We go to the start bit state
                        state <= 1;
                        // We reset the counter
                        counter <= 0;
                        // We set the tx line to 0
                        tx <= 0;
                        // We reset the tx_done signal
                        tx_done <= 0;
                    end
                end
                1: begin
                    // In the start bit state, we wait for the counter to reach the baud rate
                    if (counter == BAUD_RATE) begin
                        // When the counter reaches the baud rate, we go to the data bits state
                        state <= 2;
                        // We reset the counter
                        counter <= 0;
                        // We set the tx line to the first bit of the data
                        tx <= data[0];
                        // We reset the bit count
                        bit_count <= 0;
                    end else begin
                        // We increment the counter
                        counter <= counter + 1;
                    end
                end
                2: begin
                    // In the data bits state, we wait for the counter to reach the baud rate
                    if (counter == BAUD_RATE) begin
                        // When the counter reaches the baud rate, we check if we have transmitted all the bits
                        if (bit_count == 7) begin
                            // If we have transmitted all the bits, we go to the stop bit state
                            state <= 3;
                            // We reset the counter
                            counter <= 0;
                            // We set the tx line to 1
                            tx <= 1;
                        end else begin
                            // If we have not transmitted all the bits, we increment the bit count
                            bit_count <= bit_count + 1;
                            // We set the tx line to the next bit of the data
                            tx <= data[bit_count + 1];
                            // We reset the counter
                            counter <= 0;
                        end
                    end else begin
                        // We increment the counter
                        counter <= counter + 1;
                    end
                end
                3: begin
                    // In the stop bit state, we wait for the counter to reach the baud rate
                    if (counter == BAUD_RATE) begin
                        // When the counter reaches the baud rate, we go to the idle state
                        state <= 0;
                        // We set the tx_done signal
                        tx_done <= 1;
                    end else begin
                        // We increment the counter
                        counter <= counter + 1;
                    end
                end
            endcase
        end
    end

endmodule