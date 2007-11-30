import channelio::*;

typedef Bit#(32) RRR_ServiceID;
typedef Bit#(32) RRR_Param;
typedef Bit#(32) RRR_Response;
typedef Bit#(32) RRR_Chunk;

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

module mkRRRClient#(ChannelIO channel) (RRRClient);

    method Action makeRequest(RRR_Request request);
        noAction;
    endmethod

    method ActionValue#(RRR_Response) getResponse();
        noAction;
        return 0;
    endmethod

endmodule

interface RRRServer;
    method ActionValue#(RRR_Chunk) getNextChunk(RRR_ServiceID i);
endinterface

module mkRRRServer#(ChannelIO channel) (RRRServer);

    method ActionValue#(RRR_Chunk) getNextChunk(RRR_ServiceID i);
        noAction;
        return 0;
    endmethod

endmodule
