import Vector::*;
import FIFO::*;

`include "channelio.bsh"
`include "rrr_common.bsh"
`include "rrr_service_ids.bsh"

/* RRR Server: my job is to scan channelio for incoming requests and queue
 * them in service-private internal buffers. Services will periodically probe
 * me to inquire if there are any outstanding requests for them */

`define SERVER_CHANNEL_ID  1

`define DECODE_LENGTH(chunk)    chunk[15:0]
`define DECODE_CID(chunk)       chunk[19:16]
`define DECODE_SID(chunk)       chunk[23:16]
`define DECODE_MID(chunk)       chunk[19:16]

interface RRRServer;
    method ActionValue#(RRR_Chunk) getNextChunk(RRR_ServiceID i);
endinterface

// server
module mkRRRServer#(ChannelIO channel) (RRRServer);

    /* --- state --- */

    Reg#(Bit#(32))  chunksRemaining     <-  mkReg(0);
    Reg#(Bit#(32))  activeQueueIndex    <-  mkReg(0);

    FIFO#(RRR_Chunk)    serviceQueues[`NUM_SERVICES];
    for (Integer i = 0; i < `NUM_SERVICES; i=i+1)
        serviceQueues[i] <- mkFIFO();

    /* --- rules --- */

    // scan channel for incoming requests
    rule scan_requests (chunksRemaining == 0);

        CIO_Chunk data <- channel.readPorts[`SERVER_CHANNEL_ID].read();
        $display("hardware server: impossible! request arrived from channelio!");
        $finish(0);

        // new request is available, decode serviceID
        RRR_Chunk chunk = unpack(data);
        RRR_ServiceID   sid = `DECODE_SID(chunk);

        // find out number of chunks in parameter list
        Bit#(32) chunkLength = zeroExtend(`DECODE_LENGTH(chunk));
        Bit#(32) totalchunks = chunkLength >> `LOG_RRR_CHUNK_SIZE;
        if ((chunkLength & (`RRR_CHUNK_SIZE - 1)) != 0)
            chunksRemaining <= totalchunks;
        else
            chunksRemaining <= totalchunks - 1;

        activeQueueIndex <= zeroExtend(sid);

        // place chunk into service queue too, so that service
        // can read method ID
        serviceQueues[sid].enq(chunk);

    endrule

    // scan channel for incoming param chunks
    rule scan_params (chunksRemaining > 0);

        // grab a chunk from channelio (we know that this is a param
        // chunk) and place it into the active request queue
        CIO_Chunk data <- channel.readPorts[`SERVER_CHANNEL_ID].read();
        RRR_Chunk chunk = unpack(data);
        serviceQueues[activeQueueIndex].enq(chunk);

        // one chunk processed
        chunksRemaining <= chunksRemaining - 1;

    endrule

    /* --- methods --- */

    // get the next available chunk in a particular service's queue
    method ActionValue#(RRR_Chunk) getNextChunk(RRR_ServiceID i);

        $display("this method must not fire");
        $finish(0);

        RRR_Chunk chunk = serviceQueues[i].first();
        serviceQueues[i].deq();
        return chunk;

    endmethod

endmodule


/* RRR parameter de-marshaller. To keep this module simple,
   we instantiate it with a given inbits, outbits and
   marshalling factor such that inbits * factor = outbits */

interface DeMarshaller#(numeric type inbits, numeric type outbits, numeric type factor);
    method Action                       enq(Bit#(inbits) in);
    method ActionValue#(Bit#(outbits))  deq();
endinterface

module mkDeMarshaller(DeMarshaller#(inbits, outbits, factor));

    Reg#(Bit#(inbits))  outreg[valueOf(factor)];
    for (Integer i = 0; i < valueOf(factor); i=i+1)
        outreg[i] <- mkReg(0);

    Reg#(Bit#(8)) index <- mkReg(0);

    method Action enq(Bit#(inbits) in) if (index != fromInteger(valueOf(factor)));
        outreg[index] <= in;
        index <= index + 1;
    endmethod

    method ActionValue#(Bit#(outbits)) deq() if (index == fromInteger(valueOf(factor)));
        Bit#(outbits) outval = 0;
        for (Integer i = 0; i < valueOf(factor); i=i+1)
            outval[ (i+1)*valueOf(inbits)-1 : i*valueOf(inbits) ] = outreg[i];
        index <= 0;
        return outval;
    endmethod

endmodule
