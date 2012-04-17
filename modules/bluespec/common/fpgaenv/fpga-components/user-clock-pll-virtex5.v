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
              CLKOUT1_OUT, 
              LOCKED_OUT);

   parameter PLL_CLKIN_PERIOD = 20;
   parameter PLL_DIVCLK_DIVIDE = 1;
   parameter PLL_CLKFBOUT_MULT = 2;
   parameter PLL_CLKOUT0_DIVIDE = 1;
   parameter PLL_CLKOUT1_PHASE = 0.000;

    input CLKIN1_IN;
    input RST_IN;
   output CLKOUT0_OUT;
   output CLKOUT1_OUT;
   output LOCKED_OUT;
   
   wire   CLKFBOUT;
   wire   CLKFBIN;
   
   wire CLKOUT0_BUF;
   wire CLKOUT1_BUF;
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
   BUFG CLKOUT1_BUFG_INST (.I(CLKOUT1_BUF), 
                           .O(CLKOUT1_OUT));
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
                         .CLKOUT1(CLKOUT1_BUF), 
                         .CLKOUT2(), 
                         .CLKOUT3(), 
                         .CLKOUT4(), 
                         .CLKOUT5(), 
                         .DO(), 
                         .DRDY(), 
                         .LOCKED(LOCKED_OUT));
   defparam PLL_ADV_INST.BANDWIDTH = "OPTIMIZED";
   defparam PLL_ADV_INST.CLKIN1_PERIOD = PLL_CLKIN_PERIOD;
   defparam PLL_ADV_INST.CLKIN2_PERIOD =  PLL_CLKIN_PERIOD;

   defparam PLL_ADV_INST.CLKOUT0_DIVIDE = PLL_CLKOUT0_DIVIDE;
   defparam PLL_ADV_INST.CLKOUT0_PHASE = 0.000;
   defparam PLL_ADV_INST.CLKOUT0_DUTY_CYCLE = 0.500;

   defparam PLL_ADV_INST.CLKOUT1_DIVIDE = PLL_CLKOUT0_DIVIDE;
   defparam PLL_ADV_INST.CLKOUT1_PHASE = PLL_CLKOUT1_PHASE;
   defparam PLL_ADV_INST.CLKOUT1_DUTY_CYCLE = 0.500;

   defparam PLL_ADV_INST.COMPENSATION = "SYSTEM_SYNCHRONOUS";
   defparam PLL_ADV_INST.DIVCLK_DIVIDE = PLL_DIVCLK_DIVIDE;
   defparam PLL_ADV_INST.CLKFBOUT_MULT = PLL_CLKFBOUT_MULT;
   defparam PLL_ADV_INST.CLKFBOUT_PHASE = 0.0;
   defparam PLL_ADV_INST.REF_JITTER = 0.005000;
endmodule

