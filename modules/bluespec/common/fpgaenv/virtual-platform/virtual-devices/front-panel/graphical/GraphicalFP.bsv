import low_level_platform_interface::*;
import channelio::*;

interface FrontPanel;
    method Bit#(4)  readSwitches();
    method Bit#(5)  readButtons();
    method Action   writeLEDs(Bit#(4) data);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface llpi) (FrontPanel);
    // maintain input and output caches
    Reg#(Bit#(32))  inputCache  <- mkReg(0);
    Reg#(Bit#(32))  outputCache <- mkReg(0);

    // we want readSwitches() to be a pure value method (to provide
    // the illusion of a wire coming from a physical switch.
    // Therefore we cannot probe the channel and update our
    // internal cache in this method; we do this in a separate
    // rule
    rule updateInputCache (True);
        Maybe#(Bit#(32)) data <- llpi.channelIO.read();
        inputCache <= fromMaybe(inputCache, data);
    endrule

    // check if our UNIX channel was forcibly closed, and if so,
    // terminate simulation
    rule detectTermination (True);
        Bool wire_out <- llpi.channelIO.isDestroyed();
        if (wire_out == True)
            $finish(0);
    endrule

    // return switch state from input cache
    method Bit#(4) readSwitches();
        return inputCache[3:0];
    endmethod

    // return switch state from input cache
    method Bit#(5) readButtons();
        return inputCache[8:4];
    endmethod

    // write to output cache
    method Action writeLEDs(Bit#(4) data);
        // write to channel only if state has changed
        Bit#(32) ext = zeroExtend(data);
        if (ext != outputCache)
        begin
            outputCache <= ext;
            llpi.channelIO.write(ext);
        end
    endmethod

endmodule
