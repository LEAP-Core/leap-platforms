//
// Bluespec interface
//
module mkUserClock_Ratio_MMCM(CLK, RST_N, CLK_OUT, RST_N_OUT);

//   parameter CR_CLKIN_PERIOD = 20;
//   parameter CR_CLKFX_MULTIPLY = 4;
//   parameter CR_CLKFX_DIVIDE = 1;

   input CLK;
   input RST_N;
   output CLK_OUT;
   output RST_N_OUT;
   
   wire   RST;
   
   assign RST = !RST_N;

   clock_gen x (.CLK_IN1(CLK),
		.RESET(RST),
		.CLK_OUT1(CLK_OUT),
		.LOCKED(RST_N_OUT));

endmodule
