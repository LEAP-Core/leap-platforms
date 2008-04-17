import Vector::*;
import FIFOF::*;

`include "channelio.bsh"
`include "rrr.bsh"
`include "asim/rrr/service_ids.bsh"
`include "umf.bsh"

// RRR Client

`define CLIENT_CHANNEL_ID  0

// request/response port interfaces
interface CLIENT_REQUEST_PORT;
    method Action write(UMF_PACKET data);
endinterface

interface CLIENT_RESPONSE_PORT;
    method ActionValue#(UMF_PACKET) read();
endinterface

// client interface
interface RRR_CLIENT;
    interface Vector#(`NUM_SERVICES, CLIENT_REQUEST_PORT)  requestPorts;
    interface Vector#(`NUM_SERVICES, CLIENT_RESPONSE_PORT) responsePorts;
endinterface

// client
module mkRRRClient#(CHANNEL_IO channel) (RRR_CLIENT);

    // ==============================================================
    //                        Ports and Queues
    // ==============================================================

    // create request/response buffers and link them to ports
    FIFOF#(UMF_PACKET)                     requestQueues[`NUM_SERVICES];
    Vector#(`NUM_SERVICES, CLIENT_REQUEST_PORT) req_ports = newVector();

    FIFOF#(UMF_PACKET)                      responseQueues[`NUM_SERVICES];
    Vector#(`NUM_SERVICES, CLIENT_RESPONSE_PORT) resp_ports = newVector();

    for (Integer i = 0; i < `NUM_SERVICES; i = i+1)
    begin
        requestQueues[i]  <- mkFIFOF();
        responseQueues[i] <- mkFIFOF();

        // create a new request port and link it to the FIFO
        req_ports[i] = interface CLIENT_REQUEST_PORT
                           method Action write(UMF_PACKET data);
        
                               responseQueues[i].enq(data);
                           
                           endmethod
                       endinterface;

        // create a new response port and link it to the FIFO
        resp_ports[i] = interface CLIENT_RESPONSE_PORT
                            method ActionValue#(UMF_PACKET) read();

                                UMF_PACKET val = requestQueues[i].first();
                                requestQueues[i].deq();
                                return val;
                            
                            endmethod
                        endinterface;
    end

    // === other state ===

    Reg#(UMF_MSG_LENGTH) requestChunksRemaining  <- mkReg(0);
    Reg#(UMF_MSG_LENGTH) responseChunksRemaining <- mkReg(0);

    Reg#(UMF_SERVICE_ID) requestActiveQueue  <- mkReg(0);
    Reg#(UMF_SERVICE_ID) responseActiveQueue <- mkReg(0);

    // ==============================================================
    //                          Response Rules
    // ==============================================================

    // scan channel for incoming response headers
    rule scan_responses (responseChunksRemaining == 0);

        UMF_PACKET packet <- channel.readPorts[`CLIENT_CHANNEL_ID].read();

        // enqueue header in service's queue
        responseQueues[packet.UMF_PACKET_header.serviceID].enq(packet);

        // set up remaining chunks
        responseChunksRemaining <= packet.UMF_PACKET_header.numChunks;
        responseActiveQueue     <= packet.UMF_PACKET_header.serviceID;

    endrule

    // scan channel for response message chunks
    rule scan_params (responseChunksRemaining != 0);

        // grab a chunk from channelio and place it into the active response queue
        UMF_PACKET packet <- channel.readPorts[`CLIENT_CHANNEL_ID].read();
        responseQueues[responseActiveQueue].enq(packet);

        // one chunk processed
        responseChunksRemaining <= responseChunksRemaining - 1;

    endrule

    // ==============================================================
    //                          Request Rules
    // ==============================================================
    
    // start generating explicit priority arbiter
    Bool p_request[`NUM_SERVICES];
    Bool higher_priority_request[`NUM_SERVICES];
    Bool p_grant[`NUM_SERVICES];

    // static loop for all request queues
    for (Integer i = 0; i < `NUM_SERVICES; i = i + 1)
    begin

        // compute priority for this queue (static request/grant)
        // current algorithm involves a chain OR, which is fine for
        // a small number of request queues

        p_request[i] = (requestChunksRemaining == 0) &&
                       (requestQueues[i].notEmpty());

        if (i == 0)
        begin
            p_grant[i] = p_request[i];
            higher_priority_request[i] = p_request[i];
        end
        else
        begin
            p_grant[i] = (!higher_priority_request[i-1]) && p_request[i];
            higher_priority_request[i] = higher_priority_request[i-1] || p_request[i];
        end

        // start writing new message
        rule write_request_newmsg (p_grant[i]);

            // get header packet
            UMF_PACKET packet = requestQueues[i].first();
            requestQueues[i].deq();

            // add my virtual channelID to header
            UMF_PACKET newpacket = tagged UMF_PACKET_header
                                   {
                                       channelID: `CLIENT_CHANNEL_ID,
                                       serviceID: packet.UMF_PACKET_header.serviceID,
                                       methodID : packet.UMF_PACKET_header.methodID,
                                       numChunks: packet.UMF_PACKET_header.numChunks
                                   };

            // send the header packet to channelio
            channel.writePorts[`CLIENT_CHANNEL_ID].write(newpacket);

            // setup remaining chunks
            requestChunksRemaining <= newpacket.UMF_PACKET_header.numChunks;
            requestActiveQueue <= fromInteger(i);

        endrule

    end // for
    
    // continue writing message
    rule write_request_continue (requestChunksRemaining != 0);

        // get the next packet from the active request queue
        UMF_PACKET packet = requestQueues[requestActiveQueue].first();
        requestQueues[requestActiveQueue].deq();

        // send the packet to channelio
        channel.writePorts[`CLIENT_CHANNEL_ID].write(packet);

        // one more chunk processed
        requestChunksRemaining <= requestChunksRemaining - 1;

    endrule

    // ==============================================================
    //                        Set Interfaces
    // ==============================================================

    interface requestPorts  = req_ports;
    interface responsePorts = resp_ports;

endmodule
