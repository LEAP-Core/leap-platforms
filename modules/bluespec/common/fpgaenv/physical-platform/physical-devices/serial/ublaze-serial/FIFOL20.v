// Copyright 2000--2008 Bluespec, Inc.  All rights reserved.

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif


// Depth 2 FIFO  Data width 0, loopy
module FIFOL20(CLK, 
               RST_N, 
               ENQ, 
               FULL_N, 
               DEQ, 
               EMPTY_N, 
               CLR
               );
   input  RST_N;
   input  CLK;
   input  ENQ;
   input  CLR;
   input  DEQ;

   output FULL_N;
   output EMPTY_N;

   reg    empty_reg;
   reg    full_reg;

   assign FULL_N  = full_reg || DEQ;
   assign EMPTY_N = empty_reg ;
   
`ifdef BSV_NO_INITIAL_BLOCKS
`else // not BSV_NO_INITIAL_BLOCKS
   // synopsys translate_off
   initial 
     begin
        empty_reg = 1'b0 ;
        full_reg  = 1'b1 ;
     end // initial begin
   // synopsys translate_on  
`endif // BSV_NO_INITIAL_BLOCKS

   always@(posedge CLK /* or negedge RST_N */) 
     begin
        if (!RST_N) 
          begin
             empty_reg <= `BSV_ASSIGNMENT_DELAY 1'b0;
             full_reg  <= `BSV_ASSIGNMENT_DELAY 1'b1;
          end // if (RST_N == 0)
        else
           begin
              if (CLR) 
                begin
                   empty_reg <= `BSV_ASSIGNMENT_DELAY 1'b0;
                   full_reg  <= `BSV_ASSIGNMENT_DELAY 1'b1;
                end 
              else if (ENQ && !DEQ) 
                begin
                   empty_reg <= `BSV_ASSIGNMENT_DELAY 1'b1;
                   full_reg  <= `BSV_ASSIGNMENT_DELAY ! empty_reg;
                end 
              else if (!ENQ && DEQ) 
                begin
                   full_reg  <= `BSV_ASSIGNMENT_DELAY 1'b1;
                   empty_reg <= `BSV_ASSIGNMENT_DELAY ! full_reg;
                end // if (!ENQ && DEQ)
           end // else: !if(RST_N == 0)
     end // always@ (posedge CLK or negedge RST_N)

   // synopsys translate_off
   always@(posedge CLK)
     begin: error_checks
        reg deqerror, enqerror ;
        
        deqerror =  0;
        enqerror = 0;
        if ( RST_N )
          begin
             if ( ! empty_reg && DEQ )
               begin
                  deqerror = 1 ;             
                  $display( "Warning: FIFO20: %m -- Dequeuing from empty fifo" ) ;
               end
             if ( ! full_reg && ENQ && !DEQ )
               begin
                  enqerror =  1 ;             
                  $display( "Warning: FIFO20: %m -- Enqueuing to a full fifo" ) ;
               end
          end // if ( RST_N )        
     end
   // synopsys translate_on
   
endmodule
