import Vector::*;


`include "channelio.bsh"
`include "umf.bsh"

`define NUM_SERVICES 0


typedef Bit#(8)  UINT8;
typedef Bit#(16) UINT16;
typedef Bit#(32) UINT32;
typedef Bit#(64) UINT64;


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

// request/response port interfaces
interface CLIENT_REQUEST_PORT;
    method Action write(UMF_PACKET data);
endinterface

interface CLIENT_RESPONSE_PORT;
    method ActionValue#(UMF_PACKET) read();
endinterface


interface RRR_CLIENT;
    interface Vector#(`NUM_SERVICES, CLIENT_REQUEST_PORT)  requestPorts;
    interface Vector#(`NUM_SERVICES, CLIENT_RESPONSE_PORT) responsePorts;
endinterface


// request/response port interfaces
interface SERVER_REQUEST_PORT;
    method ActionValue#(UMF_PACKET) read();
endinterface

interface SERVER_RESPONSE_PORT;
    method Action write(UMF_PACKET data);
endinterface

// channelio interface
interface RRR_SERVER;
    interface Vector#(`NUM_SERVICES, SERVER_REQUEST_PORT)  requestPorts;
    interface Vector#(`NUM_SERVICES, SERVER_RESPONSE_PORT) responsePorts;
endinterface

module mkRRRClient#(CHANNEL_IO channel) (RRR_CLIENT);

    Vector#(`NUM_SERVICES, CLIENT_REQUEST_PORT)  reqPorts = newVector();
    Vector#(`NUM_SERVICES, CLIENT_RESPONSE_PORT) rspPorts = newVector();    
    
    interface requestPorts = reqPorts;
    interface responsePorts = rspPorts;


endmodule


module mkRRRServer#(CHANNEL_IO channel) (RRR_SERVER);

    Vector#(`NUM_SERVICES, SERVER_REQUEST_PORT)  reqPorts = newVector();
    Vector#(`NUM_SERVICES, SERVER_RESPONSE_PORT) rspPorts = newVector();
    
    interface requestPorts = reqPorts;
    interface responsePorts = rspPorts;

endmodule


