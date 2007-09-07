import low_level_platform_interface::*;
import rrr::*;

`define FP_SERVICE_ID   0

interface FrontPanel;
    method Bit#(4)  readSwitches();
    method Bit#(5)  readButtons();
    method Action   writeLEDs(Bit#(4) data);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface llpint) (FrontPanel);
    // maintain input and output caches
    Reg#(Bit#(32))  inputCache  <- mkReg(0);
    Reg#(Bit#(32))  outputCache <- mkReg(0);

    // ugly: constantly keep sending RRR requests to sync up
    // state of both inputs and outputs
    rule sendRRRRequest (True);
        Bit#(32) serviceID = `FP_SERVICE_ID;
        Bit#(32) param0    = outputCache;
        Bit#(32) param1    = 0;
        Bit#(32) param2    = 0;
        llpint.rrrClient.sendReq(serviceID, param0, param1, param2);
    endrule

    // read RRR response and update input cache... note that
    // we do not need any internal state machine to determine
    // when we can perform a valid read
    rule readRRRResponse (llpint.rrrClient.isRespAvailable(`FP_SERVICE_ID));
        Bit#(32) data <- llpint.rrrClient.getResp();
        inputCache <= data;
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
        // simply update local cached state
        Bit#(32) ext = zeroExtend(data);
        outputCache <= ext;
    endmethod

endmodule
