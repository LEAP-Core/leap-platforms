import Vector::*;
import FIFOF::*;

`include "channelio.bsh"
`include "rrr.bsh"
`include "asim/rrr/service_ids.bsh"
`include "umf.bsh"

// RRR Server: my job is to scan channelio for incoming requests and queue
// them in service-private internal buffers. Services will periodically probe
// me to inquire if there are any outstanding requests for them

`define SERVER_CHANNEL_ID  1

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

//    method ActionValue#(UMF_PACKET) read(UMF_SERVICE_ID i);

// server
module mkRRRServer#(CHANNEL_IO channel) (RRR_SERVER);

    // ==============================================================
    //                        Ports and Queues
    // ==============================================================

    // create request/response buffers and link them to ports
    FIFOF#(UMF_PACKET)                    requestQueues[`NUM_SERVICES];
    Vector#(`NUM_SERVICES, SERVER_REQUEST_PORT)  req_ports = newVector();

    FIFOF#(UMF_PACKET)                    responseQueues[`NUM_SERVICES];
    Vector#(`NUM_SERVICES, SERVER_RESPONSE_PORT) resp_ports = newVector();

    for (Integer i = 0; i < `NUM_SERVICES; i = i+1)
    begin
        requestQueues[i]  <- mkFIFOF();
        responseQueues[i] <- mkFIFOF();

        // create a new request port and link it to the FIFO
        req_ports[i] = interface SERVER_REQUEST_PORT
                           method ActionValue#(UMF_PACKET) read();

                               UMF_PACKET val = requestQueues[i].first();
                               requestQueues[i].deq();
                               return val;

                           endmethod
                       endinterface;

        // create a new response port and link it to the FIFO
        resp_ports[i] = interface SERVER_RESPONSE_PORT
                            method Action write(UMF_PACKET data);

                                responseQueues[i].enq(data);

                            endmethod
                        endinterface;
    end

    // === arbiters ===
    
    ARBITER#(`NUM_SERVICES) arbiter <- mkRoundRobinArbiter();
    
    // === other state ===

    Reg#(UMF_MSG_LENGTH) requestChunksRemaining  <- mkReg(0);
    Reg#(UMF_MSG_LENGTH) responseChunksRemaining <- mkReg(0);

    Reg#(UMF_SERVICE_ID) requestActiveQueue  <- mkReg(0);
    Reg#(UMF_SERVICE_ID) responseActiveQueue <- mkReg(0);

    // ==============================================================
    //                          Request Rules
    // ==============================================================

    // scan channel for incoming request headers
    rule scan_requests (requestChunksRemaining == 0);

        UMF_PACKET packet <- channel.readPorts[`SERVER_CHANNEL_ID].read();

        // enqueue header in service's queue
        requestQueues[packet.UMF_PACKET_header.serviceID].enq(packet);

        // set up remaining chunks
        requestChunksRemaining <= packet.UMF_PACKET_header.numChunks;
        requestActiveQueue     <= packet.UMF_PACKET_header.serviceID;

    endrule

    // scan channel for request message chunks
    rule scan_params (requestChunksRemaining != 0);

        // grab a chunk from channelio and place it into the active request queue
        UMF_PACKET packet <- channel.readPorts[`SERVER_CHANNEL_ID].read();
        requestQueues[requestActiveQueue].enq(packet);

        // one chunk processed
        requestChunksRemaining <= requestChunksRemaining - 1;

    endrule

    // ==============================================================
    //                          Response Rules
    // ==============================================================
    
    // start writing new message
    rule write_response_newmsg (responseChunksRemaining == 0);

        // arbitrate
        Bit#(`NUM_SERVICES) request = '0;
        for (Integer i = 0; i < `NUM_SERVICES; i = i + 1)
        begin
            request[i] = pack((responseChunksRemaining == 0) && (responseQueues[i].notEmpty()));
        end

        if (arbiter.arbitrate(request) matches tagged Valid .i)
        begin
            // get header packet
            UMF_PACKET packet = responseQueues[i].first();
            responseQueues[i].deq();

            // add my virtual channelID to header
            UMF_PACKET newpacket = tagged UMF_PACKET_header
                                       {
                                        channelID: `SERVER_CHANNEL_ID,
                                        serviceID: packet.UMF_PACKET_header.serviceID,
                                        methodID : packet.UMF_PACKET_header.methodID,
                                        numChunks: packet.UMF_PACKET_header.numChunks
                                       };

            // send the header packet to channelio
            channel.writePorts[`SERVER_CHANNEL_ID].write(newpacket);

            // setup remaining chunks
            responseChunksRemaining <= newpacket.UMF_PACKET_header.numChunks;
            responseActiveQueue <= zeroExtend(pack(i));
        end

    endrule
    
    // continue writing message
    rule write_response_continue (responseChunksRemaining != 0);

        // get the next packet from the active response queue
        UMF_PACKET packet = responseQueues[responseActiveQueue].first();
        responseQueues[responseActiveQueue].deq();

        // send the packet to channelio
        channel.writePorts[`SERVER_CHANNEL_ID].write(packet);

        // one more chunk processed
        responseChunksRemaining <= responseChunksRemaining - 1;

    endrule

    // ==============================================================
    //                        Set Interfaces
    // ==============================================================

    interface requestPorts  = req_ports;
    interface responsePorts = resp_ports;

endmodule
