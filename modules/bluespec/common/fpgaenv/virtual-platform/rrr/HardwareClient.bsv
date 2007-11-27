`include "channelio.bsh"
`include "rrr_common.bsh"

`define CLIENT_CHANNEL_ID 0

interface RRRClient;
    method Action                       makeRequest(RRR_Request request);
    method ActionValue#(RRR_Response)   getResponse();
endinterface

// state encodings
// ---------------
// 00   : accepting requests
// 01/09: RRR request sent, sending param0
// 02/10: sending param1
// 03/11: sending param2
// 04   : waiting for response
// 05   : response ready, waiting to be read

module mkRRRClient#(ChannelIO channel) (RRRClient);

    Reg#(Bit#(4))   state           <- mkReg(0);
    Reg#(Bit#(32))  param0Buffer    <- mkReg(0);
    Reg#(Bit#(32))  param1Buffer    <- mkReg(0);
    Reg#(Bit#(32))  param2Buffer    <- mkReg(0);
    Reg#(Bit#(32))  responseBuffer  <- mkReg(0);

    rule sendParam0(state == 1 || state == 9);
        channel.writePorts[`CLIENT_CHANNEL_ID].write(param0Buffer);
        state <= state + 1;
    endrule

    rule sendParam1(state == 2 || state == 10);
        channel.writePorts[`CLIENT_CHANNEL_ID].write(param1Buffer);
        state <= state + 1;
    endrule

    rule sendParam2(state == 3 || state == 11);
        Bit#(4) s = state;
        channel.writePorts[`CLIENT_CHANNEL_ID].write(param2Buffer);
        if (s == 3)
            state <= 4;
        else
            state <= 0;
    endrule

    rule waitForResponse(state == 4);
        CIO_Chunk response <- channel.readPorts[`CLIENT_CHANNEL_ID].read();
        responseBuffer <= pack(response);
        state <= 5;
    endrule

    method Action makeRequest(RRR_Request request) if (state == 0);
        // send command down channel, buffer params locally
        channel.writePorts[`CLIENT_CHANNEL_ID].write(zeroExtend(request.serviceID));
        param0Buffer <= request.param0;
        param1Buffer <= request.param1;
        param2Buffer <= request.param2;
        if (request.needResponse == True)
            state <= 1;
        else
            state <= 9;
    endmethod

    method ActionValue#(RRR_Response) getResponse() if (state == 5);
        state <= 0;
        return responseBuffer;
    endmethod

endmodule
