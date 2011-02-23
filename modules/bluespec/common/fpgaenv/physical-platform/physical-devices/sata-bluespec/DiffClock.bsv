import Clocks::*;

interface DiffClockWithReset;
   (* always_enabled, always_ready *)
   method Action clk_n_in(Bit#(1) clk);
   (* always_enabled, always_ready *)
   method Action clk_p_in(Bit#(1) clk);      
   (* always_enabled, always_ready *)
   method Action rst_in(Bit#(1) rst);      
   interface Clock clk_out;
   interface Reset rst_out;
endinterface

import "BVI" diff_clock =   
module mkDiffClockWithReset_Internal (DiffClockWithReset);

   default_clock no_clock;
   default_reset no_reset;
   
   output_clock clk_out(CLK_OUT);
   output_reset rst_out(RST_OUT) clocked_by(clk_out);
   
   method clk_n_in(CLK_N_IN) enable((*inhigh*)clk_n_in_en) reset_by(no_reset) clocked_by(no_clock);
   method clk_p_in(CLK_P_IN) enable((*inhigh*)clk_p_in_en) reset_by(no_reset) clocked_by(no_clock);
   method rst_in(RST_IN)     enable((*inhigh*)rst_in_en)   reset_by(no_reset) clocked_by(no_clock);
      
   schedule (clk_n_in, clk_p_in, rst_in) CF 
            (clk_n_in, clk_p_in, rst_in);
      
endmodule

(* no_default_clock, no_default_reset *)
module mkDiffClockWithReset (DiffClockWithReset);
   
   let diff_clock <- mkDiffClockWithReset_Internal();
   let clk = diff_clock.clk_out;
   let rst = diff_clock.rst_out;
   let rst_n <- mkResetInverter(rst, clocked_by clk);
   let rst_n_out <- mkAsyncReset(10, rst_n, clk, clocked_by clk);
   
   method clk_n_in = diff_clock.clk_n_in;
   method clk_p_in = diff_clock.clk_p_in;
   method rst_in   = diff_clock.rst_in;
   interface Clock clk_out = clk;
   interface Reset rst_out = rst_n_out;
endmodule
   
      
