//
// Based on Bluespec RegFile.v -- a dual port (one read and one write)
// implementation of a register file.
//

`define BSV_WARN_REGFILE_ADDR_RANGE 0

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif


// Dual-ported LUT-based storage
module LUTRAMUDualPort(CLK,
                       RST_N,
                       CLK_GATE,
                       INIT,
                       ADDR_IN, D_IN, WE,
                       ADDR_1, D_OUT_1
                       );
   // synopsys template
   parameter                   addr_width = 1;
   parameter                   data_width = 1;
   parameter                   lo = 0;
   parameter                   hi = 1;

   input                       CLK;
   input                       RST_N, CLK_GATE;
   input [addr_width - 1 : 0]  ADDR_IN;
   input [data_width - 1 : 0]  D_IN;
   input                       WE;

   input [addr_width - 1 : 0]  ADDR_1;
   output [data_width - 1 : 0] D_OUT_1;

   output                      INIT;

   // synthesis attribute ram_style of arr is distributed
   reg [data_width - 1 : 0]    arr[lo:hi];


`ifdef BSV_NO_INITIAL_BLOCKS
`else // not BSV_NO_INITIAL_BLOCKS
   // synopsys translate_off
   initial
     begin : init_block
        integer                     i; 		// temporary for generate reset value
        for (i = lo; i <= hi; i = i + 1) begin
           arr[i] = {((data_width + 1)/2){2'b10}} ;
        end
     end // initial begin
   // synopsys translate_on
`endif // BSV_NO_INITIAL_BLOCKS


   always@(posedge CLK)
     begin
        if (WE)
          arr[ADDR_IN] <= `BSV_ASSIGNMENT_DELAY D_IN;
     end // always@ (posedge CLK)

   assign D_OUT_1 = arr[ADDR_1];

   assign INIT = 1;

   // synopsys translate_off
   always@(posedge CLK)
     begin : runtime_check
        reg enable_check;
        enable_check = `BSV_WARN_REGFILE_ADDR_RANGE ;
        if ( enable_check )
           begin
              if (( ADDR_1 < lo ) || (ADDR_1 > hi) )
                $display( "Warning: RegFile: %m -- Address port 1 is out of bounds: %h", ADDR_1 ) ;
              if ( WE && ( ADDR_IN < lo ) || (ADDR_IN > hi) )
                $display( "Warning: RegFile: %m -- Write Address port is out of bounds: %h", ADDR_IN ) ;
           end
     end
   // synopsys translate_on

endmodule
