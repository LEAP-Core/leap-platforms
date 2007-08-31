import toplevel_wires::*;
import low_level_platform_interface::*;

interface FrontPanel;
    method Bit#(4)  readSwitches();
    method Bit#(5)  readButtons();
    method Action   writeLEDs(Bit#(4) data);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface pint) (FrontPanel);

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
