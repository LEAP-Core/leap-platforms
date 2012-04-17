`timescale 1ns / 1ps

//
// Bluespec interface
//
module mkUserClock_Ratio_PLL(CLK, RST_N, CLK0_OUT, CLK1_OUT, RST_N_OUT);

   parameter CR_CLKIN_PERIOD = 20;
   parameter CR_DIVCLK_DIVIDE = 1;
   parameter CR_CLKFBOUT_MULT = 2;
   parameter CR_CLKOUT0_DIVIDE = 1;
   parameter CR_CLKOUT1_PHASE = 0.000;

   input CLK;
   input RST_N;
   output CLK0_OUT;
   output CLK1_OUT;
   output RST_N_OUT;
   
   wire   RST;
   
   assign RST = !RST_N;

   clk_pll#(CR_CLKIN_PERIOD,
            CR_DIVCLK_DIVIDE,
            CR_CLKFBOUT_MULT,
            CR_CLKOUT0_DIVIDE,
            CR_CLKOUT1_PHASE)
      x (.CLKIN1_IN(CLK),
         .RST_IN(RST),
         .CLKOUT0_OUT(CLK0_OUT),
         .CLKOUT1_OUT(CLK1_OUT),
         .LOCKED_OUT(RST_N_OUT));

endmodule
