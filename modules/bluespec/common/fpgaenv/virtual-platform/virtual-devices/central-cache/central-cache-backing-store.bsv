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


interface CENTRAL_CACHE_BACKING_CONNECTION;
    interface CENTRAL_CACHE_BACKING_PORT backingPort;
    interface RL_SA_CACHE_SOURCE_DATA#(CENTRAL_CACHE_LINE_ADDR,
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
    FIFO#(CENTRAL_CACHE_BACKING_READ_REQ) readReqQ <- mkFIFO();
    FIFOF#(Bool) writeAckQ <- mkBypassFIFOF();

    // FIFO1 to save space.  Throughput isn't terribly important here
    // since the call will go through RRR.
    FIFOF#(CENTRAL_CACHE_BACKING_WRITE_REQ) writeCtrlQ <- mkFIFOF1();
    FIFO#(CENTRAL_CACHE_LINE) writeDataQ <- mkFIFO1();
    Reg#(Bit#(TLog#(CENTRAL_CACHE_WORDS_PER_LINE))) writeWordIdx <- mkReg(0);

    // Read response logic.  Combine pipelined read response (words) into a single
    // line-sized register.
    Reg#(Vector#(CENTRAL_CACHE_WORDS_PER_LINE, CENTRAL_CACHE_WORD)) readData <- mkRegU();
    Reg#(Bit#(TLog#(CENTRAL_CACHE_WORDS_PER_LINE))) readWordIdx <- mkReg(0);
    Reg#(Bool) readDataReady <- mkReg(False);

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
        // Provide read data in response to getReadReq.  This method is called
        // multiple times for each getReadReq.
        //
        method Action sendReadResp(CENTRAL_CACHE_WORD val) if (! readDataReady);
            readData[readWordIdx] <= val;

            debugLog.record($format("port %0d: BACKING sendReadResp idx=%0d, val=0x%x", port, readWordIdx, val));

            if (readWordIdx == maxBound)
            begin
                readDataReady <= True;
            end
    
            readWordIdx <= readWordIdx + 1;
        endmethod

    
        //
        // Poll for request from cache to write to backing storage.
        //
        method ActionValue#(CENTRAL_CACHE_BACKING_WRITE_REQ) getWriteReq();
            let w = writeCtrlQ.first();
            writeCtrlQ.deq();

            debugLog.record($format("port %0d: BACKING getWriteReq addr=0x%x, wMask=0x%x, refInfo=0x%x, ack=%d", port, w.addr, w.wordValidMask, w.refInfo, w.sendAck));
    
            return w;
        endmethod

        //
        // Poll for write data following a getWriteReq().
        //
        method ActionValue#(CENTRAL_CACHE_WORD) getWriteData() if (! writeCtrlQ.notEmpty());
            debugLog.record($format("port %0d: BACKING getWriteData idx=%0d", port, writeWordIdx));

            Vector#(CENTRAL_CACHE_WORDS_PER_LINE, CENTRAL_CACHE_WORD) v = unpack(pack(writeDataQ.first()));
            if (writeWordIdx == maxBound)
            begin
                // Sent entire line
                writeDataQ.deq();
            end

            let r = v[writeWordIdx];
            writeWordIdx <= writeWordIdx + 1;

            return r;
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
    interface RL_SA_CACHE_SOURCE_DATA cacheSourceData;
        method Action readReq(CENTRAL_CACHE_LINE_ADDR addr, CENTRAL_CACHE_REF_INFO refInfo);
            readReqQ.enq(CENTRAL_CACHE_BACKING_READ_REQ { addr: addr, refInfo: refInfo });
            debugLog.record($format("port %0d: BACKING readReq addr=0x%x, refInfo=0x%x", port, addr, refInfo));
        endmethod

        method ActionValue#(CENTRAL_CACHE_LINE) readResp() if (readDataReady);
            CENTRAL_CACHE_LINE v = unpack(pack(readData));
            readDataReady <= False;

            debugLog.record($format("port %0d: BACKING readResp val=0x%x", port, v));
    
            return v;
        endmethod

    
        // Asynchronous write (no response)
        method Action write(CENTRAL_CACHE_LINE_ADDR addr,
                            Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) wordValidMask,
                            CENTRAL_CACHE_LINE val,
                            CENTRAL_CACHE_REF_INFO refInfo);

            CENTRAL_CACHE_BACKING_WRITE_REQ w;
            w.addr = addr;
            w.wordValidMask = wordValidMask;
            w.refInfo = refInfo;
            w.sendAck = False;

            writeCtrlQ.enq(w);
            writeDataQ.enq(val);
            debugLog.record($format("port %0d: BACKING write addr=0x%x, wMask=0x%x, refInfo=0x%x, ack=%d, val=0x%x", port, w.addr, w.wordValidMask, w.refInfo, w.sendAck, val));
        endmethod
    
        // Synchronous write.  writeSyncWait() blocks until the response arrives.
        method Action writeSyncReq(CENTRAL_CACHE_LINE_ADDR addr,
                                   Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) wordValidMask,
                                   CENTRAL_CACHE_LINE val,
                                   CENTRAL_CACHE_REF_INFO refInfo);

            CENTRAL_CACHE_BACKING_WRITE_REQ w;
            w.addr = addr;
            w.wordValidMask = wordValidMask;
            w.refInfo = refInfo;
            w.sendAck = True;

            writeCtrlQ.enq(w);
            writeDataQ.enq(val);
            debugLog.record($format("port %0d: BACKING write addr=0x%x, wMask=0x%x, refInfo=0x%x, ack=%d, val=0x%x", port, w.addr, w.wordValidMask, w.refInfo, w.sendAck, val));
        endmethod

        method Action writeSyncWait() if (writeAckQ.notEmpty());
            writeAckQ.deq();
            debugLog.record($format("port %0d: BACKING writeSyncWait fired", port));
        endmethod
    endinterface

endmodule
