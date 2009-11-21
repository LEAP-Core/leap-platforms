//
// Copyright (C) 2009 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

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

    for (Integer s = 0; s < `NUM_SERVICES; s = s + 1)
    begin
        requestQueues[s]  <- mkFIFOF();
        responseQueues[s] <- mkFIFOF();

        // create a new request port and link it to the FIFO
        req_ports[s] = interface SERVER_REQUEST_PORT
                           method ActionValue#(UMF_PACKET) read();

                               UMF_PACKET val = requestQueues[s].first();
                               requestQueues[s].deq();
                               return val;

                           endmethod
                       endinterface;

        // create a new response port and link it to the FIFO
        resp_ports[s] = interface SERVER_RESPONSE_PORT
                            method Action write(UMF_PACKET data);

                                responseQueues[s].enq(data);

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
    
    //
    // Start writing new message.  The write_response_newmsg rule is broken
    // into two parts in order to help Bluespec generate a significantly simpler
    // schedule than if the rules are combined.  Separating the rules breaks
    // the connection between arbiter input vector state and the test for
    // whether a responseQueue has data.
    //

    Wire#(Maybe#(UInt#(TLog#(`NUM_SERVICES)))) newMsgQIdx <- mkDWire(tagged Invalid);

    //
    // First half -- pick an incoming responseQueue
    //
    rule write_response_newmsg1 (responseChunksRemaining == 0);

        // arbitrate
        Bit#(`NUM_SERVICES) request = '0;
        for (Integer s = 0; s < `NUM_SERVICES; s = s + 1)
        begin
            request[s] = pack(responseQueues[s].notEmpty());
        end

        newMsgQIdx <= arbiter.arbitrate(request);

    endrule
    
    //
    // Second half -- consume a value from the chosen responseQueue.  If the
    // rule fails to fire because the channel write port is full it will fire
    // again later after being reselected by the first half.
    //
    for (Integer s = 0; s < `NUM_SERVICES; s = s + 1)
    begin
        rule write_response_newmsg2 (newMsgQIdx matches tagged Valid .idx &&&
                                     fromInteger(s) == idx &&&
                                     responseChunksRemaining == 0);

            // get header packet
            UMF_PACKET packet = responseQueues[s].first();
            responseQueues[s].deq();

            // add my virtual channelID to header
            UMF_PACKET newpacket = tagged UMF_PACKET_header UMF_PACKET_HEADER
                                       {
                                         filler: ?,
                                         phyChannelPvt: ?,
                                         channelID: `SERVER_CHANNEL_ID,
                                         serviceID: packet.UMF_PACKET_header.serviceID,
                                         methodID : packet.UMF_PACKET_header.methodID,
                                         numChunks: packet.UMF_PACKET_header.numChunks
                                        };

            // send the header packet to channelio
            channel.writePorts[`SERVER_CHANNEL_ID].write(newpacket);

            // setup remaining chunks
            responseChunksRemaining <= newpacket.UMF_PACKET_header.numChunks;
            responseActiveQueue <= fromInteger(s);

        endrule
    end
    
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
