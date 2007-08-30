import toplevel_wires::*;

interface FrontPanel;
    method Bit#(4)  readSwitches();
    method Bit#(5)  readButtons();
    method Action   writeLEDs(Bit#(4) data);
endinterface

module mkFrontPanel#(TopLevelWiresDriver wires) (FrontPanel);

    method Bit#(4) readSwitches();
        // read from toplevel wires
        return (wires.getSwitches());
    endmethod

    method Bit#(5) readButtons();
        // read from toplevel wires
        Bit#(5) all_inputs;

        all_inputs[0]   = wires.getButtonUp();
        all_inputs[1]   = wires.getButtonLeft();
        all_inputs[2]   = wires.getButtonCenter();
        all_inputs[3]   = wires.getButtonRight();
        all_inputs[4]   = wires.getButtonDown();

        return all_inputs;
    endmethod

    method Action writeLEDs(Bit#(4) data);
        // write to toplevel wires
        wires.setLEDs(data);
    endmethod

endmodule
