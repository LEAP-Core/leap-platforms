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

//
// The cache expects an interface to backing storage.  Clients of the central
// cache must provide backing storage.  The cache interface and the client
// interface are, necessarily, different since the cache storage interface
// is method based and the client interface is message based, often over
// a soft connection.
//
// This module bridges the gap between the interfaces by providing two interfaces:
// one for the base cache backing storage and one for the central cache virtual
// device communication with clients.  The module implements the connection
// between the two interfaces.
//


import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/librl_bsv_cache.bsh"
`include "asim/provides/virtual_devices.bsh"


interface CENTRAL_CACHE_BACKING_CONNECTION;
    interface CENTRAL_CACHE_BACKING_PORT backingPort;
    interface HASIM_CACHE_SOURCE_DATA#(CENTRAL_CACHE_ADDR,
                                       CENTRAL_CACHE_LINE,
                                       CENTRAL_CACHE_WORDS_PER_LINE,
                                       CENTRAL_CACHE_REF_INFO) cacheSourceData;
endinterface: CENTRAL_CACHE_BACKING_CONNECTION

//
// mkCentralCacheBackingConnection --
//     The backing store connection is essentially an interface mapper between
//     the backing store interface required by the standard cache interface
//     and the backing store interface required by a central cache client.
//
//     The port and debugLog arguments are provided solely for debugging
//     messages.
//
module mkCentralCacheBackingConnection#(Integer port, DEBUG_FILE debugLog)
    // interface:
    (CENTRAL_CACHE_BACKING_CONNECTION);
    
    // Internal communication
    FIFO#(CENTRAL_CACHE_BACKING_READ_REQ) readReqQ <- mkBypassFIFO();
    FIFO#(CENTRAL_CACHE_LINE) readRespQ <- mkBypassFIFO();
    FIFO#(CENTRAL_CACHE_BACKING_WRITE_REQ) writeQ <- mkBypassFIFO();
    FIFOF#(Bool) writeAckQ <- mkBypassFIFOF();

    //
    // Central cache interface.
    //
    interface CENTRAL_CACHE_BACKING_PORT backingPort;
        //
        // Central cache client polls getReadReq.
        //
        method ActionValue#(CENTRAL_CACHE_BACKING_READ_REQ) getReadReq();
            let r = readReqQ.first();
            readReqQ.deq();
    
            debugLog.record($format("port %0d: BACKING getReadReq addr=0x%x, refInfo=0x%x", port, r.addr, r.refInfo));

            return r;
        endmethod


        //
        // Provide read data in response to getReadReq.
        //
        method Action sendReadResp(CENTRAL_CACHE_LINE val);
            readRespQ.enq(val);
            debugLog.record($format("port %0d: BACKING sendReadResp val=0x%x", port, val));
        endmethod

    
        //
        // Poll for request from cache to write to backing storage.
        //
        method ActionValue#(CENTRAL_CACHE_BACKING_WRITE_REQ) getWriteReq();
            let w = writeQ.first();
            writeQ.deq();

            debugLog.record($format("port %0d: BACKING write addr=0x%x, wMask=0x%x, refInfo=0x%x, ack=%d, val=0x%x", port, w.addr, w.wordValidMask, w.refInfo, w.sendAck, w.val));
    
            return w;
        endmethod

        //
        // Client ack that write to backing storage is complete.
        //
        method Action sendWriteAck();
            writeAckQ.enq(?);
            debugLog.record($format("port %0d: BACKING sendWriteAck", port));
        endmethod
    endinterface

    
    //
    // Cache backing storage interface.
    //
    interface HASIM_CACHE_SOURCE_DATA cacheSourceData;
        method Action readReq(CENTRAL_CACHE_ADDR addr, CENTRAL_CACHE_REF_INFO refInfo);
            readReqQ.enq(CENTRAL_CACHE_BACKING_READ_REQ { addr: addr, refInfo: refInfo });
            debugLog.record($format("port %0d: BACKING readReq addr=0x%x, refInfo=0x%x", port, addr, refInfo));
        endmethod

        method ActionValue#(CENTRAL_CACHE_LINE) readResp();
            let v = readRespQ.first();
            readRespQ.deq();

            debugLog.record($format("port %0d: BACKING readResp val=0x%x", port, v));
    
            return v;
        endmethod

    
        // Asynchronous write (no response)
        method Action write(CENTRAL_CACHE_ADDR addr,
                            Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) wordValidMask,
                            CENTRAL_CACHE_LINE val,
                            CENTRAL_CACHE_REF_INFO refInfo);

            CENTRAL_CACHE_BACKING_WRITE_REQ w;
            w.addr = addr;
            w.wordValidMask = wordValidMask;
            w.val = val;
            w.refInfo = refInfo;
            w.sendAck = False;

            writeQ.enq(w);
            debugLog.record($format("port %0d: BACKING write addr=0x%x, wMask=0x%x, refInfo=0x%x, ack=%d, val=0x%x", port, w.addr, w.wordValidMask, w.refInfo, w.sendAck, w.val));
        endmethod
    
        // Synchronous write.  writeSyncWait() blocks until the response arrives.
        method Action writeSyncReq(CENTRAL_CACHE_ADDR addr,
                                   Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) wordValidMask,
                                   CENTRAL_CACHE_LINE val,
                                   CENTRAL_CACHE_REF_INFO refInfo);

            CENTRAL_CACHE_BACKING_WRITE_REQ w;
            w.addr = addr;
            w.wordValidMask = wordValidMask;
            w.val = val;
            w.refInfo = refInfo;
            w.sendAck = True;

            writeQ.enq(w);
            debugLog.record($format("port %0d: BACKING write addr=0x%x, wMask=0x%x, refInfo=0x%x, ack=%d, val=0x%x", port, w.addr, w.wordValidMask, w.refInfo, w.sendAck, w.val));
        endmethod

        method Action writeSyncWait() if (writeAckQ.notEmpty());
            writeAckQ.deq();
            debugLog.record($format("port %0d: BACKING writeSyncWait fired", port));
        endmethod
    endinterface

endmodule
