`timescale 1ns / 1ps

// ========================================================================
//
// CLK_PLL -- Configurable multiple of base clock, taking three parameters:
//
//     1.  Incoming clock period (in ns)
//     2.  Multiplier to apply to incoming clock (integer 1-32)
//     3.  Divisor to apply to incoming clock (integer 2-32)
//
//   The outgoing clock is (M / D) * incoming clock frequency
//
// ========================================================================

module clk_pll(CLKIN1_IN, 
              RST_IN, 
              CLKOUT0_OUT, 
              LOCKED_OUT);

   parameter PLL_CLKIN_PERIOD = 20;
   parameter PLL_CLKOUT_MULTIPLY = 2;
   parameter PLL_CLKOUT_DIVIDE = 1;

    input CLKIN1_IN;
    input RST_IN;
   output CLKOUT0_OUT;
   output LOCKED_OUT;
   
   wire   CLKFBOUT;
   wire   CLKFBIN;
   
   wire CLKOUT0_BUF;
   wire GND_BIT;
   wire [4:0] GND_BUS_5;
   wire [15:0] GND_BUS_16;
   wire VCC_BIT;
   
   assign GND_BIT = 0;
   assign GND_BUS_5 = 5'b00000;
   assign GND_BUS_16 = 16'b0000000000000000;
   assign VCC_BIT = 1;
   BUFG CLKOUT0_BUFG_INST (.I(CLKOUT0_BUF), 
                           .O(CLKOUT0_OUT));
   BUFG CLKFB_BUFG_INST (.I(CLKFBOUT),
                         .O(CLKFBIN));

   PLL_ADV PLL_ADV_INST (
                         .CLKFBIN(CLKFBIN),
                         .CLKINSEL(VCC_BIT), 
                         .CLKIN1(CLKIN1_IN), 
                         .CLKIN2(GND_BIT), 
                         .DADDR(GND_BUS_5[4:0]), 
                         .DCLK(GND_BIT), 
                         .DEN(GND_BIT), 
                         .DI(GND_BUS_16[15:0]), 
                         .DWE(GND_BIT), 
                         .REL(GND_BIT), 
                         .RST(RST_IN), 
                         .CLKFBDCM(), 
                         .CLKFBOUT(CLKFBOUT), 
                         .CLKOUTDCM0(), 
                         .CLKOUTDCM1(), 
                         .CLKOUTDCM2(), 
                         .CLKOUTDCM3(), 
                         .CLKOUTDCM4(), 
                         .CLKOUTDCM5(), 
                         .CLKOUT0(CLKOUT0_BUF), 
                         .CLKOUT1(),
                         .CLKOUT2(), 
                         .CLKOUT3(), 
                         .CLKOUT4(), 
                         .CLKOUT5(), 
                         .DO(), 
                         .DRDY(), 
                         .LOCKED(LOCKED_OUT));
   defparam PLL_ADV_INST.BANDWIDTH = "OPTIMIZED";
   defparam PLL_ADV_INST.CLKIN1_PERIOD = PLL_CLKIN_PERIOD;
   defparam PLL_ADV_INST.CLKIN2_PERIOD =  5.000;
   defparam PLL_ADV_INST.CLKOUT0_DIVIDE = PLL_CLKOUT_DIVIDE;
   defparam PLL_ADV_INST.CLKOUT0_PHASE = 0.000;
   defparam PLL_ADV_INST.CLKOUT0_DUTY_CYCLE = 0.500;
   defparam PLL_ADV_INST.COMPENSATION = "SYSTEM_SYNCHRONOUS";
   defparam PLL_ADV_INST.DIVCLK_DIVIDE = 1;
   defparam PLL_ADV_INST.CLKFBOUT_MULT = PLL_CLKOUT_MULTIPLY;
   defparam PLL_ADV_INST.CLKFBOUT_PHASE = 0.0;
   defparam PLL_ADV_INST.REF_JITTER = 0.005000;
endmodule

//
// Bluespec interface
//
module mkUserClock_Ratio_PLL(CLK, RST_N, CLK_OUT, RST_N_OUT);

   parameter CR_CLKIN_PERIOD = 20;
   parameter CR_CLKOUT_MULTIPLY = 4;
   parameter CR_CLKOUT_DIVIDE = 1;

   input CLK;
   input RST_N;
   output CLK_OUT;
   output RST_N_OUT;
   
   wire   RST;
   
   assign RST = !RST_N;

   clk_pll#(CR_CLKIN_PERIOD,
            CR_CLKOUT_MULTIPLY,
            CR_CLKOUT_DIVIDE)
      x (.CLKIN1_IN(CLK),
         .RST_IN(RST),
         .CLKOUT0_OUT(CLK_OUT),
         .LOCKED_OUT(RST_N_OUT));

endmodule
