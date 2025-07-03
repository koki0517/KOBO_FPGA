module sound(input CLK, input RESET, input [4:0] BTN, output SPEAKER0, output SPEAKER1);
   reg [15:0] count;
   reg 	      s;
   reg [15:0] count_to_turn = 56817; // 25MHz/440Hz = 56817
   reg [7:0] step = 0;
   reg [31:0] total_count = 0;

   reg [15:0] C  = 95555; // ド
   reg [15:0] Cp = 90194; // ド#
   reg [15:0] D  = 85132; // レ
   reg [15:0] Dp = 80352; // レ#
   reg [15:0] E  = 75843; // ミ
   reg [15:0] F  = 71586; // ファ
   reg [15:0] Fp = 67569; // ファ#
   reg [15:0] G  = 63776; // ソ
   reg [15:0] Gp = 60197; // ソ#
   reg [15:0] A  = 56818; // ラ
   reg [15:0] Ap = 53630; // ラ#
   reg [15:0] B  = 50620; // シ
   reg [15:0] C_low  = 47778; // ド

   always @(posedge CLK) begin
      if(RESET==1) begin
         count <= 0;
         s     <= 0;
         step <= 0;
         total_count <= 0;
         count_to_turn <= C; // Initialize to the first note (C)
      end else begin
         // Sound generation logic
         if(count == count_to_turn -1) begin // count_to_turn is a period, so compare with period-1
            count <= 0;
            s     <= ~s;
         end else begin
            count <= count + 1;
         end

         // Note change logic (every 1 second for 25MHz clock)
         if(total_count == 25000000 - 1) begin // 25,000,000 cycles = 1 second at 25MHz
            total_count <= 0;
            step <= step + 1;
            if (step > 11) begin // After B (11), loop back to C (0)
               step <= 0;
            end
            case (step)
               0: count_to_turn <= C;    // ド
               1: count_to_turn <= Cp;   // ド#
               2: count_to_turn <= D;    // レ
               3: count_to_turn <= Dp;   // レ#
               4: count_to_turn <= E;    // ミ
               5: count_to_turn <= F;    // ファ
               6: count_to_turn <= Fp;   // ファ#
               7: count_to_turn <= G;    // ソ
               8: count_to_turn <= Gp;   // ソ#
               9: count_to_turn <= A;    // ラ
               10: count_to_turn <= Ap;  // ラ#
               11: count_to_turn <= B;   // シ
               default: count_to_turn <= C;
            endcase
         end else begin
            total_count <= total_count + 1;
         end
      end
   end

   assign SPEAKER0 = s;
   assign SPEAKER1 = ~SPEAKER0;
endmodule // sound


module clock_25MHz(output reg clk_25MHz);
   initial clk_25MHz = 0;
   always  #20 clk_25MHz = ~clk_25MHz; // 1/(25x10^6)=40nsec 
endmodule

module soundSim;
   wire CLK25M,speaker0,speaker1;
   reg [4:0] btn;
   reg       reset;
   clock_25MHz clock_25MHz(CLK25M);
   sound sound(CLK25M,reset,btn,speaker0,speaker1);
   initial begin
      $display("reset  speaker0 time(ns)");
      $monitor(" %b        %b   ",reset,speaker0,$stime);
      btn = 4'b0000;
      @(posedge CLK25M) reset = 1;
      @(posedge CLK25M) reset = 0;
      #20000000;
      $finish;
   end
endmodule // soundSim

