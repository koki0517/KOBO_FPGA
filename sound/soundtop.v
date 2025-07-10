module soundtop(
		input CLK100M,     // 100MHz clock input
		input [4:0] BTN,   // Button (BTN4=BTNC,BTN3=BTND,BTN2=BTNR,BTN1=BTNL,BTN0=BTNU)
		input [3:0] SW,    // Switch (SW3,SW2,SW1,SW0)
		output [3:0] LED,  // LED    (LD3,LD2,LD1,LD0)
		// output SPEAKER0, output SPEAKER1, // Speaker
		input UART_RXD, output UART_TXD
		);	    
   // make 25MHz clock from 100MHz clock
   reg [1:0] 	       count=0;
   wire 	       CLK25M;
   always @(posedge CLK100M) begin
      count <= count + 1;
   end
   assign CLK25M = count[1];
	
   // LED
   assign LED = SW;

   // generate sound
//    sound sound(CLK25M, SW[0], BTN, SPEAKER0, SPEAKER1);

   // UART
   reg [7:0] tx_data_reg = 8'h00;
   reg tx_start_reg = 0;
   wire tx_busy_wire;

   reg [31:0] timer = 0;
   reg [3:0] state = 0;

   always @(posedge CLK25M) begin
       if (SW[0]) begin
           timer <= 0;
           state <= 0;
           tx_start_reg <= 0;
       end else begin
           timer <= timer + 1;
           if (timer == 25000000) begin // 1 second delay
               timer <= 0;
               state <= state + 1;
               if (state == 5) begin
                   state <= 0;
               end
           end

           case (state)
               0: tx_data_reg <= "h";
               1: tx_data_reg <= "e";
               2: tx_data_reg <= "l";
               3: tx_data_reg <= "l";
               4: tx_data_reg <= "o";
               default: tx_data_reg <= 8'h00;
           endcase

           if (timer == 1) begin
               tx_start_reg <= 1;
           end else begin
               tx_start_reg <= 0;
           end
       end
   end

   uart uart(
       .CLK(CLK25M),
       .RESET(SW[0]),
       .RX(UART_RXD),
       .TX(UART_TXD),
       .rx_data(),
       .rx_valid(),
       .tx_data(tx_data_reg),
       .tx_start(tx_start_reg),
       .tx_busy(tx_busy_wire)
   );

endmodule
