import toplevel_wires::*;

interface FrontPanel;
  method Action putData(Bit#(256) data, Bool begin_xfer, Bool end_xfer);
  method ActionValue#(Tuple3#(Bit#(256), Bool, Bool)) getData();
  method Action putCmd(Bit#(75) cmd);
  method ActionValue#(Bit#(75)) getCmd();
endinterface

module mkFrontPanel#(TopLevelWiresDriver wires) (FrontPanel);

  method Action putData(Bit#(256) data, Bool begin_xfer, Bool end_xfer);
    wires.putData(data, begin_xfer, end_xfer);
  endmethod
  
  method Action putCmd(Bit#(75) cmd);
    wires.putCmd(cmd);
  endmethod
  
  method ActionValue#(Tuple3#(Bit#(256), Bool, Bool)) getData();
    let r <- wires.getData();
    return r;
  endmethod
  
  method ActionValue#(Bit#(75)) getCmd();
    let r <- wires.getCmd();
    return r;
  endmethod
  
endmodule
