import toplevel_wires::*;

interface FrontPanel;
    method Bit#(4)  readSwitches();
    method Bit#(5)  readButtons();
    method Action   writeLEDs(Bit#(4) data);
endinterface

module mkFrontPanel#(TopLevelWiresDriver wires) (FrontPanel);

    method Bit#(4) readSwitches();
        return 0;
    endmethod

    method Bit#(5) readButtons();
        return 0;
    endmethod

    method Action writeLEDs(Bit#(4) data);
        noAction;
    endmethod

endmodule
