import rrr::*;
import toplevel_wires::*;

interface FrontPanel;
    method Bit#(4)  readSwitches();
    method Bit#(5)  readButtons();
    method Action   writeLEDs(Bit#(4) data);
endinterface

module mkFrontPanel#(RPCClient rpcClient, TopLevelWiresDriver wires) (FrontPanel);
    // maintain input and output caches
    Reg#(Bit#(32))  inputCache  <- mkReg(0);
    Reg#(Bit#(32))  outputCache <- mkReg(0);

    // ugly: constantly keep sending RPC requests to sync up
    // state of both inputs and outputs
    rule sendRPCRequest (True);
        Bit#(32) serviceID = 0;
        Bit#(32) param0    = outputCache;
        Bit#(32) param1    = 0;
        Bit#(32) param2    = 0;
        rpcClient.sendReq(serviceID, param0, param1, param2);
    endrule

    // read RPC response and update input cache... note that
    // we do not need any internal state machine to determine
    // when we can perform a valid read
    rule readRPCResponse (True);
        Bit#(32) data <- rpcClient.getResp();
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
