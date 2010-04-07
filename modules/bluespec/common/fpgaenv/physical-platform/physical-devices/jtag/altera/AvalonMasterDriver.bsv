`include "asim/provides/avalon.bsh"

import "BVI" avalon_jtag = 
module mkAvalonMasterDriver 
   
   // master driver has masterInverse wires interface
   (AvalonMasterInverseWires#(32,32));
   
   default_clock clk(clk_0, (*unused*) clk_gate);
   default_reset rst(reset_n) clocked_by(clk);

   // inputs 
   method read(masterInverseWires_read_to_the_mkAvalonWrapperInstance_0) enable((*inhigh*) read_en) clocked_by(clk) reset_by(rst);
   method write(masterInverseWires_write_to_the_mkAvalonWrapperInstance_0) enable((*inhigh*) write_en) clocked_by(clk) reset_by(rst);
   method address(masterInverseWires_address_to_the_mkAvalonWrapperInstance_0) enable((*inhigh*) address_en) clocked_by(clk) reset_by(rst);
   method writedata(masterInverseWires_writedata_to_the_mkAvalonWrapperInstance_0) enable((*inhigh*) writedata_en) clocked_by(clk) reset_by(rst);
   
   // outputs
   method masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0 readdata() clocked_by(clk) reset_by(rst);
   method masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0 waitrequest() clocked_by(clk) reset_by(rst);
   method masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0 readdatavalid() clocked_by(clk) reset_by(rst);
      
   schedule (read,
             write,
             address,
             writedata,
             readdata,
             waitrequest,
             readdatavalid) CF
            (read,
             write,
             address,
             writedata,
             readdata,
             waitrequest,
             readdatavalid);
      
endmodule