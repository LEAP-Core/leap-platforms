import channelio::*;
import toplevel_wires::*;

interface RPCClient;
    method Action                   sendReq(Bit#(32) serviceID, Bit#(32) param0, Bit#(32) param1, Bit#(32) param2);
    method ActionValue#(Bit#(32))   getResp();
    method Action                   sendVoidReq(Bit#(32) serviceID, Bit#(32) param0, Bit#(32) param1, Bit#(32) param2);
endinterface

// state encodings
// ---------------
// 00   : accepting requests
// 01/09: RPC request sent, sending param0
// 02/10: sending param1
// 03/11: sending param2
// 04   : waiting for response
// 05   : response ready, waiting to be read

module mkRPCClient(RPCClient);

    ChannelIO       channel         <- mkChannelIO();
    Reg#(Bit#(4))   state           <- mkReg(0);
    Reg#(Bit#(32))  param0Buffer    <- mkReg(0);
    Reg#(Bit#(32))  param1Buffer    <- mkReg(0);
    Reg#(Bit#(32))  param2Buffer    <- mkReg(0);
    Reg#(Bit#(32))  responseBuffer  <- mkReg(0);

    rule sendParam0(state == 1 || state == 9);
        channel.write(param0Buffer);
        state <= state + 1;
    endrule

    rule sendParam1(state == 2 || state == 10);
        channel.write(param1Buffer);
        state <= state + 1;
    endrule

    rule sendParam2(state == 3 || state == 11);
        Bit#(4) s = state;
        channel.write(param2Buffer);
        if (s == 3)
            state <= 4;
        else
            state <= 0;
    endrule

    rule waitForResponse(state == 4);
        Maybe#(Bit#(32)) data <- channel.read();
        if (isValid(data))
        begin
            responseBuffer <= fromMaybe(0, data);
            state <= 5;
        end
    endrule

    // ----- WE NEED TO MOVE THIS SOMEWHERE ELSE -----
    // check if our UNIX channel was forcibly closed, and if so,
    // terminate simulation
    rule detectTermination (True);
        Bool wire_out <- channel.isDestroyed();
        if (wire_out == True)
            $finish(0);
    endrule
    // -----------------------------------------------

    method Action sendReq(Bit#(32) serviceID, Bit#(32) param0, Bit#(32) param1, Bit#(32) param2) if (state == 0);
        // send command down channel, buffer params locally
        channel.write(serviceID);
        param0Buffer <= param0;
        param1Buffer <= param1;
        param2Buffer <= param2;
        state <= 1;
    endmethod

    method ActionValue#(Bit#(32)) getResp() if (state == 5);
        state <= 0;
        return responseBuffer;
    endmethod

    method Action sendVoidReq(Bit#(32) serviceID, Bit#(32) param0, Bit#(32) param1, Bit#(32) param2) if (state == 0);
        // send command down channel, buffer params locally
        channel.write(serviceID);
        param0Buffer <= param0;
        param1Buffer <= param1;
        param2Buffer <= param2;
        state <= 9;
    endmethod

endmodule
