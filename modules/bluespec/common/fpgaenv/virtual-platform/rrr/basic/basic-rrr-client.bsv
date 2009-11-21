/*****************************************************************************
 * basic-rrr-client.bsv
 *
 * Copyright (C) 2008 Intel Corporation
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

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

    for (Integer s = 0; s < `NUM_SERVICES; s = s + 1)
    begin
        requestQueues[s]  <- mkFIFOF();
        responseQueues[s] <- mkFIFOF();

        // create a new request port and link it to the FIFO
        req_ports[s] = interface CLIENT_REQUEST_PORT
                           method Action write(UMF_PACKET data);
        
                               requestQueues[s].enq(data);
                           
                           endmethod
                       endinterface;

        // create a new response port and link it to the FIFO
        resp_ports[s] = interface CLIENT_RESPONSE_PORT
                            method ActionValue#(UMF_PACKET) read();

                                UMF_PACKET val = responseQueues[s].first();
                                responseQueues[s].deq();
                                return val;
                            
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
    
    //
    // Start writing new message.  The write_request_newmsg rule is broken
    // into two parts in order to help Bluespec generate a significantly simpler
    // schedule than if the rules are combined.  Separating the rules breaks
    // the connection between arbiter input vector state and the test for
    // whether a requestQueue has data.
    //

    Wire#(Maybe#(UInt#(TLog#(`NUM_SERVICES)))) newMsgQIdx <- mkDWire(tagged Invalid);

    //
    // First half -- pick an incoming requestQueue
    //
    rule write_request_newmsg1 (requestChunksRemaining == 0);

        // arbitrate
        Bit#(`NUM_SERVICES) request = '0;
        for (Integer s = 0; s < `NUM_SERVICES; s = s + 1)
        begin
            request[s] = pack(requestQueues[s].notEmpty());
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
        rule write_request_newmsg2 (newMsgQIdx matches tagged Valid .idx &&&
                                    fromInteger(s) == idx &&&
                                    requestChunksRemaining == 0);

            // get header packet
            UMF_PACKET packet = requestQueues[s].first();
            requestQueues[s].deq();

            // add my virtual channelID to header
            UMF_PACKET newpacket = tagged UMF_PACKET_header UMF_PACKET_HEADER
                                       {
                                        filler: ?,
                                        phyChannelPvt: ?,
                                        channelID: `CLIENT_CHANNEL_ID,
                                        serviceID: packet.UMF_PACKET_header.serviceID,
                                        methodID : packet.UMF_PACKET_header.methodID,
                                        numChunks: packet.UMF_PACKET_header.numChunks
                                       };

            // send the header packet to channelio
            channel.writePorts[`CLIENT_CHANNEL_ID].write(newpacket);

            // setup remaining chunks
            requestChunksRemaining <= newpacket.UMF_PACKET_header.numChunks;
            requestActiveQueue <= fromInteger(s);
        endrule

    end
    
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
