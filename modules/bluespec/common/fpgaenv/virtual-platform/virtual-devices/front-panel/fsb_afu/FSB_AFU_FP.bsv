import toplevel_wires::*;

interface FrontPanel;
  method Action makeResponse(Bit#(256) data);
  method ActionValue#(Bit#(256)) getRequest();
endinterface

module mkFrontPanel#(TopLevelWiresDriver wires) (FrontPanel);

  method Action makeResponse(Bit#(256) data);
    wires.makeResponse(data);
  endmethod
  
  method ActionValue#(Bit#(256)) getRequest();
    let r <- wires.getRequest();
    return r;
  endmethod
  
endmodule
