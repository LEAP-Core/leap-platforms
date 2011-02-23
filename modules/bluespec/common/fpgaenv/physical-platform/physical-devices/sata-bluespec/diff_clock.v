`timescale 1ns / 1ps
`define DLY #1

module diff_clock 
( 
  CLK_N_IN,
  CLK_P_IN,
  RST_IN,
  CLK_OUT,
  RST_OUT
);
   input  CLK_N_IN;
   input  CLK_P_IN;
   input  RST_IN;
   output CLK_OUT;
   output RST_OUT;

   wire   clk_in_i;

   //----- Reference clock using normal clock resources (CLK)  -----------
    // In designs that can tolerate higher jitter, CLK reference clock inputs to the GTPs can
    // be used. In this example, we use an IBUFDS to bring a reference clock on chip through the
    // regular IOs    
        
    IBUFDS clk_in_ibufds
    (
        .O                              (clk_in_i), 
        .I                              (CLK_P_IN),
        .IB                             (CLK_N_IN)
    );

    // The tools automatically turn on CLK reference clocking when the CLKIN port of the GTP is 
    // driven by a BUFG. Here we connect the grefclk from the IBUFDS to a BUFG, which we will use to 
    // drive the GTPs in the design that were selected to use CLK.
       
    BUFG clk_in_bufg
    (
        .I                              (clk_in_i),
        .O                              (CLK_OUT)
    );

   assign RST_OUT = RST_IN;

endmodule // diff_clock

