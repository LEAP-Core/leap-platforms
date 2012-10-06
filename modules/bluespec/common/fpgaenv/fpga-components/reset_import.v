
module reset_import(RST_N,
                    CLK,
                    CLK_GATE,
                    reset_in,
		    reset_out);
   
  
   input RST_N;
   input CLK;
   input CLK_GATE;
   input reset_in;
   output reset_out;

   assign reset_out = reset_in;
   
endmodule