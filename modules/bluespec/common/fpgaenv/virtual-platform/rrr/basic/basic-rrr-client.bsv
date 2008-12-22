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

    for (Integer i = 0; i < `NUM_SERVICES; i = i+1)
    begin
        requestQueues[i]  <- mkFIFOF();
        responseQueues[i] <- mkFIFOF();

        // create a new request port and link it to the FIFO
        req_ports[i] = interface CLIENT_REQUEST_PORT
                           method Action write(UMF_PACKET data);
        
                               requestQueues[i].enq(data);
                           
                           endmethod
                       endinterface;

        // create a new response port and link it to the FIFO
        resp_ports[i] = interface CLIENT_RESPONSE_PORT
                            method ActionValue#(UMF_PACKET) read();

                                UMF_PACKET val = responseQueues[i].first();
                                responseQueues[i].deq();
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
    
    // arbitrate
    Bit#(`NUM_SERVICES) request = '0;
    for (Integer i = 0; i < `NUM_SERVICES; i = i + 1)
    begin
        request[i] = pack((requestChunksRemaining == 0) && (requestQueues[i].notEmpty()));
    end

    // start writing new message
    rule write_request_newmsg (requestChunksRemaining == 0 &&&
                               arbiter.arbitrate(request) matches tagged Valid .i);

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
        requestActiveQueue <= zeroExtend(pack(i));

    endrule
    
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
