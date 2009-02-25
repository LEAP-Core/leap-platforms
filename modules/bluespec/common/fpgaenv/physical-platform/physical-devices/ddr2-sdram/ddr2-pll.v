`timescale 1ns / 1ps

module ddr2_pll(CLKIN1_IN, 
                RST_IN, 
                CLKOUT0_OUT, 
                CLKOUT1_OUT, 
                LOCKED_OUT);

    input CLKIN1_IN;
    input RST_IN;
   output CLKOUT0_OUT;
   output CLKOUT1_OUT;
   output LOCKED_OUT;
   
   //wire CLKFBOUT_CLKFBIN;
   wire   CLKFBOUT;
   wire   CLKFBIN;
   
   //wire CLKIN1_IBUFG;
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
   //IBUFG CLKIN1_IBUFG_INST (.I(CLKIN1_IN), 
   //                         .O(CLKIN1_IBUFG));
   BUFG CLKOUT0_BUFG_INST (.I(CLKOUT0_BUF), 
                           .O(CLKOUT0_OUT));
   BUFG CLKOUT1_BUFG_INST (.I(CLKOUT1_BUF), 
                           .O(CLKOUT1_OUT));
   BUFG CLKFB_BUFG_INST (.I(CLKFBOUT),
                         .O(CLKFBIN));

   PLL_ADV PLL_ADV_INST (//.CLKFBIN(CLKFBOUT_CLKFBIN),
                         .CLKFBIN(CLKFBIN),
                         .CLKINSEL(VCC_BIT), 
                         //.CLKIN1(CLKIN1_IBUFG), 
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
                         //.CLKFBOUT(CLKFBOUT_CLKFBIN), 
                         .CLKFBOUT(CLKFBOUT), 
                         .CLKOUTDCM0(), 
                         .CLKOUTDCM1(), 
                         .CLKOUTDCM2(), 
                         .CLKOUTDCM3(), 
                         .CLKOUTDCM4(), 
                         .CLKOUTDCM5(), 
                         .CLKOUT0(CLKOUT0_BUF), 
                         //.CLKOUT0(CLKOUT0_OUT), 
                         .CLKOUT1(CLKOUT1_BUF), 
                         //.CLKOUT1(CLKOUT1_OUT), 
                         .CLKOUT2(), 
                         .CLKOUT3(), 
                         .CLKOUT4(), 
                         .CLKOUT5(), 
                         .DO(), 
                         .DRDY(), 
                         .LOCKED(LOCKED_OUT));
   defparam PLL_ADV_INST.BANDWIDTH = "OPTIMIZED";
   defparam PLL_ADV_INST.CLKIN1_PERIOD = 20.000;
   defparam PLL_ADV_INST.CLKIN2_PERIOD = 10.000;
   defparam PLL_ADV_INST.CLKOUT0_DIVIDE = 4;
   defparam PLL_ADV_INST.CLKOUT1_DIVIDE = 3;
   defparam PLL_ADV_INST.CLKOUT0_PHASE = 0.000;
   defparam PLL_ADV_INST.CLKOUT1_PHASE = 0.000;
   defparam PLL_ADV_INST.CLKOUT0_DUTY_CYCLE = 0.500;
   defparam PLL_ADV_INST.CLKOUT1_DUTY_CYCLE = 0.500;
   defparam PLL_ADV_INST.COMPENSATION = "SYSTEM_SYNCHRONOUS";
   defparam PLL_ADV_INST.DIVCLK_DIVIDE = 1;
   defparam PLL_ADV_INST.CLKFBOUT_MULT = 12;
   defparam PLL_ADV_INST.CLKFBOUT_PHASE = 0.0;
   defparam PLL_ADV_INST.REF_JITTER = 0.005000;
endmodule

//
// Bluespec interface
//
module mkDDR2PLL(CLK,
                 RST_N,
                 CLK_150_OUT,
                 CLK_200_OUT,
                 RST_N_OUT);

   input CLK;
   input RST_N;

   output CLK_150_OUT;
   output CLK_200_OUT;
   output RST_N_OUT;
   
   wire   RST;
   
   assign RST = !RST_N;

   ddr2_pll x (.CLKIN1_IN(CLK),
         .RST_IN(RST),
         .CLKOUT0_OUT(CLK_150_OUT),
         .CLKOUT1_OUT(CLK_200_OUT),
         .LOCKED_OUT(RST_N_OUT));

endmodule
