
module clock_import(RST_N,
                    CLK,
                    CLK_GATE,
                    clk_in,
		    clk_out);
   input RST_N;
   input CLK;
   input CLK_GATE;
   input clk_in;
   output clk_out;

   assign clk_out = clk_in;
   
endmodule