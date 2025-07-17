`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2025 
// Design Name: 
// Module Name: uartTop_tb
// Project Name: UART Test Bench
// Target Devices: 
// Tool Versions: 
// Description: Test bench for uartTop module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uartTop_tb();

    // Test bench signals
    reg CLK100M;
    reg rx;
    reg [15:0] SW;
    wire [15:0] LED;
    wire tx;
    wire PS2Clk;
    wire PS2Data;
    
    // UART parameters
    parameter CLKS_PER_BIT = 10417;
    parameter BIT_PERIOD = CLKS_PER_BIT * 10; // 10ns per clock cycle
    
    // Instantiate the Unit Under Test (UUT)
    uartTop uut (
        .CLK100M(CLK100M),
        .rx(rx),
        .SW(SW),
        .LED(LED),
        .tx(tx),
        .PS2Clk(PS2Clk),
        .PS2Data(PS2Data)
    );
    
    // Clock generation (100MHz = 10ns period)
    initial begin
        CLK100M = 0;
        forever #5 CLK100M = ~CLK100M;
    end
    
    // Task to send a UART byte
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            $display("Time %t: Sending UART byte: 0x%02X (%c)", $time, data, data);
            
            // Start bit
            rx = 0;
            #BIT_PERIOD;
            
            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #BIT_PERIOD;
            end
            
            // Stop bit
            rx = 1;
            #BIT_PERIOD;
            
            $display("Time %t: UART byte transmission completed", $time);
        end
    endtask
    
    // Task to wait for TX transmission and verify
    task wait_for_tx_byte;
        output [7:0] received_data;
        integer i;
        begin
            // Wait for start bit on tx
            wait (tx == 0);
            $display("Time %t: TX start bit detected", $time);
            #(BIT_PERIOD/2); // Sample at middle of bit
            
            // Skip start bit and sample data bits
            #BIT_PERIOD;
            for (i = 0; i < 8; i = i + 1) begin
                received_data[i] = tx;
                #BIT_PERIOD;
            end
            
            // Check stop bit
            if (tx !== 1) begin
                $error("Time %t: TX stop bit error! Expected 1, got %b", $time, tx);
            end else begin
                $display("Time %t: TX byte received: 0x%02X (%c)", $time, received_data, received_data);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize signals
        rx = 1;  // UART idle state
        SW = 16'h0000;
        
        // Wait for reset
        #1000;
        
        $display("=== UART Loopback Test Starting ===");
        $display("Time %t: Test bench initialized", $time);
        
        // Test Case 1: Send 'A' (0x41)
        $display("\n--- Test Case 1: Sending 'A' (0x41) ---");
        fork
            send_uart_byte(8'h41);  // Send 'A'
            begin
                reg [7:0] rx_data;
                wait_for_tx_byte(rx_data);  // Wait for loopback
                if (rx_data == 8'h41) begin
                    $display("✓ Test Case 1 PASSED: Received correct data");
                end else begin
                    $error("✗ Test Case 1 FAILED: Expected 0x41, got 0x%02X", rx_data);
                end
            end
        join
        
        // Wait between tests
        #(BIT_PERIOD * 5);
        
        // Test Case 2: Send 'B' (0x42)
        $display("\n--- Test Case 2: Sending 'B' (0x42) ---");
        fork
            send_uart_byte(8'h42);  // Send 'B'
            begin
                reg [7:0] rx_data;
                wait_for_tx_byte(rx_data);  // Wait for loopback
                if (rx_data == 8'h42) begin
                    $display("✓ Test Case 2 PASSED: Received correct data");
                end else begin
                    $error("✗ Test Case 2 FAILED: Expected 0x42, got 0x%02X", rx_data);
                end
            end
        join
        
        // Wait between tests
        #(BIT_PERIOD * 5);
        
        // Test Case 3: Send sequence "HI"
        $display("\n--- Test Case 3: Sending sequence 'HI' ---");
        fork
            begin
                send_uart_byte(8'h48);  // Send 'H'
                #(BIT_PERIOD * 2);      // Small gap between bytes
                send_uart_byte(8'h49);  // Send 'I'
            end
            begin
                reg [7:0] rx_data1, rx_data2;
                wait_for_tx_byte(rx_data1);  // Wait for 'H'
                wait_for_tx_byte(rx_data2);  // Wait for 'I'
                if (rx_data1 == 8'h48 && rx_data2 == 8'h49) begin
                    $display("✓ Test Case 3 PASSED: Received correct sequence");
                end else begin
                    $error("✗ Test Case 3 FAILED: Expected H(0x48), I(0x49), got 0x%02X, 0x%02X", rx_data1, rx_data2);
                end
            end
        join
        
        // Test Case 4: Check LED outputs
        $display("\n--- Test Case 4: Checking LED outputs ---");
        send_uart_byte(8'hAA);  // Send 0xAA
        #(BIT_PERIOD * 15);     // Wait for processing
        
        $display("LED[7:0] (rx_byte): 0x%02X", LED[7:0]);
        $display("LED[8] (rx_dv): %b", LED[8]);
        $display("LED[9] (tx_done): %b", LED[9]);
        $display("LED[10] (tx_busy): %b", LED[10]);
        $display("LED[11] (tx_start): %b", LED[11]);
        
        if (LED[7:0] == 8'hAA) begin
            $display("✓ Test Case 4 PASSED: LED shows correct received data");
        end else begin
            $error("✗ Test Case 4 FAILED: Expected LED[7:0] = 0xAA, got 0x%02X", LED[7:0]);
        end
        
        // Final wait
        #(BIT_PERIOD * 10);
        
        $display("\n=== UART Loopback Test Completed ===");
        $finish;
    end
    
    // Monitor signals for debugging
    initial begin
        $monitor("Time %t: CLK=%b rx=%b tx=%b rx_dv=%b tx_done=%b tx_busy=%b tx_start=%b LED[7:0]=0x%02X", 
                 $time, CLK100M, rx, tx, LED[8], LED[9], LED[10], LED[11], LED[7:0]);
    end
    
    // Timeout watchdog
    initial begin
        #50000000;  // 50ms timeout
        $error("Test bench timeout!");
        $finish;
    end

endmodule
