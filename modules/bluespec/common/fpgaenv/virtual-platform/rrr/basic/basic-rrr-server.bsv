import Vector::*;
import FIFO::*;

`include "channelio.bsh"
`include "basic-rrr.bsh"
`include "rrr_service_ids.bsh"

// RRR Server: my job is to scan channelio for incoming requests and queue
// them in service-private internal buffers. Services will periodically probe
// me to inquire if there are any outstanding requests for them

`define SERVER_CHANNEL_ID  1

interface RRRServer;
    method ActionValue#(UMF_PACKET) read(UMF_SERVICE_ID i);
endinterface

// server
module mkRRRServer#(ChannelIO channel) (RRRServer);

    // === state ===

    Reg#(UMF_MSG_LENGTH)    chunksRemaining     <-  mkReg(0);
    Reg#(UMF_SERVICE_ID)    activeQueueIndex    <-  mkReg(0);

    FIFO#(UMF_PACKET)    serviceQueues[`NUM_SERVICES];
    for (Integer i = 0; i < `NUM_SERVICES; i=i+1)
        serviceQueues[i] <- mkFIFO();

    // === rules ===

    // scan channel for incoming request headers
    rule scan_requests (chunksRemaining == 0);

        UMF_PACKET packet <- channel.readPorts[`SERVER_CHANNEL_ID].read();

        // enqueue header in service's queue
        serviceQueues[packet.UMF_PACKET_header.serviceID].enq(packet);

        // set up remaining chunks
        chunksRemaining <= packet.UMF_PACKET_header.numChunks;
        activeQueueIndex <= packet.UMF_PACKET_header.serviceID;

    endrule

    // scan channel for message chunks
    rule scan_params (chunksRemaining != 0);

        // grab a chunk from channelio and place it into the active request queue
        UMF_PACKET packet <- channel.readPorts[`SERVER_CHANNEL_ID].read();
        serviceQueues[activeQueueIndex].enq(packet);

        // one chunk processed
        chunksRemaining <= chunksRemaining - 1;

    endrule

    // === methods ===

    // get the next available chunk in a particular service's queue
    method ActionValue#(UMF_PACKET) read(UMF_SERVICE_ID i);

        UMF_PACKET packet = serviceQueues[i].first();
        serviceQueues[i].deq();
        return packet;

    endmethod

endmodule


// RRR parameter de-marshaller

typedef enum
{
    DEM_STATE_idle,
    DEM_STATE_active
}
DEM_STATE
    deriving (Bits, Eq);

// outbits *has* to be a multiple of inbits
interface DeMarshaller#(numeric type inbits, numeric type outbits);
    method Action                       start(UMF_MSG_LENGTH nchunks);
    method Action                       enq(Bit#(inbits) chunk);
    method ActionValue#(Bit#(outbits))  deq();
endinterface

module mkDeMarshaller(DeMarshaller#(inbits, outbits));

    // compute degree
    Integer in     = valueof(inbits);
    Integer out    = valueof(outbits);
    Integer degree = (out % in) == 0 ? (out / in) : (out / in) + 1;

    // instantiate output register
    Reg#(Bit#(inbits))  outreg[degree];
    for (Integer i = 0; i < degree; i=i+1)
        outreg[i] <- mkReg(0);

    // output release register
    Reg#(UMF_MSG_LENGTH) outchunks <- mkReg(0);

    // current index
    Reg#(UMF_MSG_LENGTH) index <- mkReg(0);

    // state
    Reg#(DEM_STATE) state <- mkReg(DEM_STATE_idle);

    // set up de-marshalling wires that generate the output
    Bit#(outbits) outval = 0;
    for (Integer i = 0; i < degree; i=i+1)
        outval[ (i+1)*in - 1 : i*in ] = outreg[i];

    // methods
    method Action start(UMF_MSG_LENGTH nchunks) if (state == DEM_STATE_idle);
        index <= 0;
        outchunks <= nchunks;
        state <= DEM_STATE_active;
    endmethod

    method Action enq(Bit#(inbits) chunk) if (state == DEM_STATE_active &&
                                              index != outchunks);
        outreg[index] <= chunk;
        index <= index + 1;
    endmethod

    method ActionValue#(Bit#(outbits)) deq() if (state == DEM_STATE_active &&
                                                 index == outchunks);
        state <= DEM_STATE_idle;
        return outval;
    endmethod

endmodule
