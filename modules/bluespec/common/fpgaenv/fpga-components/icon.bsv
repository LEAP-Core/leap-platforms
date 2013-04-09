
interface ICON;
     (* always_ready, always_enabled *)
     interface Inout#(Bit#(36)) control;
endinterface

import "BVI" icon_wrapper =
module mkICON(ICON);
  
    parameter GENERATION = `XILINX_GENERATION; 
   
    default_clock clk(CLK);
    no_reset;
    ifc_inout   control(CONTROL0);

endmodule