import channelio::*;

typedef Bit#(32) RRR_ServiceID;
typedef Bit#(32) RRR_Param;
typedef Bit#(32) RRR_Response;

typedef struct
{
    RRR_ServiceID   serviceID;
    RRR_Param       param0;
    RRR_Param       param1;
    RRR_Param       param2;
    Bool            needResponse;
} RRR_Request   deriving (Eq, Bits);

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

    method Action makeRequest(RRR_Request request) if (state == 0);
        // send command down channel, buffer params locally
        channel.write(request.serviceID);
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
