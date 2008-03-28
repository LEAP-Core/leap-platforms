import Vector::*;


`include "channelio.bsh"

`include "asim/rrr/rrr_service_ids.bsh"
`include "umf.bsh"

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

// request/response port interfaces
interface REQUEST_PORT;
    method ActionValue#(UMF_PACKET) acceptRequest();
endinterface

interface RESPONSE_PORT;
    method Action sendResponse(UMF_PACKET data);
endinterface

interface RRR_SERVER;
    interface Vector#(`NUM_SERVICES, REQUEST_PORT)  requestPorts;
    interface Vector#(`NUM_SERVICES, RESPONSE_PORT) responsePorts;
endinterface


module mkRRRServer#(ChannelIO channel) (RRR_SERVER);

    Vector#(`NUM_SERVICES, REQUEST_PORT)  reqPorts = newVector();
    Vector#(`NUM_SERVICES, RESPONSE_PORT) rspPorts = newVector();
    
    
    interface requestPorts = reqPorts;
    interface responsePorts = rspPorts;

endmodule
