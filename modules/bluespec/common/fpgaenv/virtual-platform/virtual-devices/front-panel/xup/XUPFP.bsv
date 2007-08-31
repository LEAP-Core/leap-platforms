import low_level_platform_interface::*;
import toplevel_wires::*;

interface FrontPanel;
    method Bit#(4)  readSwitches();
    method Bit#(5)  readButtons();
    method Action   writeLEDs(Bit#(4) data);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface llpi) (FrontPanel);

    method Bit#(4) readSwitches();
        // read from toplevel wires
        return (llpi.topLevelWires.getSwitches());
    endmethod

    method Bit#(5) readButtons();
        // read from toplevel wires
        Bit#(5) all_inputs;

        all_inputs[0]   = llpi.topLevelWires.getButtonUp();
        all_inputs[1]   = llpi.topLevelWires.getButtonLeft();
        all_inputs[2]   = llpi.topLevelWires.getButtonCenter();
        all_inputs[3]   = llpi.topLevelWires.getButtonRight();
        all_inputs[4]   = llpi.topLevelWires.getButtonDown();

        return all_inputs;
    endmethod

    method Action writeLEDs(Bit#(4) data);
        // write to toplevel wires
        llpi.topLevelWires.setLEDs(data);
    endmethod

endmodule
