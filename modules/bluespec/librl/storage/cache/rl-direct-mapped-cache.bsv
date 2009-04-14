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
// Direct mapped cache.
//

// Library imports.

import FIFO::*;
import SpecialFIFOs::*;

// Project foundation imports.

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/librl_bsv_storage.bsh"
`include "asim/provides/fpga_components.bsh"


// ===================================================================
//
// PUBLIC DATA STRUCTURES
//
// ===================================================================

//
// Load response
//
typedef struct
{
    t_CACHE_WORD val;
    t_CACHE_REF_INFO refInfo;
}
RL_DM_CACHE_LOAD_RESP#(type t_CACHE_WORD,
                       type t_CACHE_REF_INFO)
    deriving (Eq, Bits);


//
// Direct mapped cache interface.  nTagExtraLowBits is used just for
// debugging.  This specified number of low bits are prepanded to cache
// tags so addresses match those seen in other modules.
//
// t_CACHE_REF_INFO is metadata associated with a reference.  Metadata is
// passed to the backing store for fills.  The metadata is not stored in
// the cache.
//
interface RL_DM_CACHE#(type t_CACHE_ADDR,
                       type t_CACHE_WORD,
                       type t_CACHE_REF_INFO,
                       numeric type nTagExtraLowBits);

    // Read a word.  Read from backing store if not already cached.
    // *** Read responses are NOT guaranteed to be in the order of requests. ***
    method Action readReq(t_CACHE_ADDR addr, t_CACHE_REF_INFO refInfo);

    method ActionValue#(RL_DM_CACHE_LOAD_RESP#(t_CACHE_WORD, t_CACHE_REF_INFO)) readResp();
    

    // Write a word to a cache line.  Word index 0 corresponds to the
    // low bits of a cache line.
    method Action write(t_CACHE_ADDR addr, t_CACHE_WORD val, t_CACHE_REF_INFO refInfo);
    
    // Invalidate & flush requests.  Both write dirty lines back.  Invalidate drops
    // the line from the cache.  Flush keeps the line in the cache.  A response
    // is returned for invalOrFlushWait iff sendAck is true.
    method Action invalReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
    method Action flushReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
    method Action invalOrFlushWait();
    
    //
    // Set cache mode.  Mostly useful for debugging.
    //
//    method Action setCacheMode(RL_SA_CACHE_MODE mode);

endinterface: RL_DM_CACHE


//
// Source data fill response
//
typedef struct
{
    t_CACHE_ADDR addr;
    t_CACHE_WORD val;
    t_CACHE_REF_INFO refInfo;
}
RL_DM_CACHE_FILL_RESP#(type t_CACHE_ADDR,
                       type t_CACHE_WORD,
                       type t_CACHE_REF_INFO)
    deriving (Eq, Bits);

//
// The caller must provide an instance of the RL_DM_CACHE_SOURCE_DATA interface
// so the cache can read and write data from the next level in the hierarchy.
//
// See RL_DM_CACHE interface for description of refInfo.
//
interface RL_DM_CACHE_SOURCE_DATA#(type t_CACHE_ADDR,
                                   type t_CACHE_WORD,
                                   type t_CACHE_REF_INFO);

    // Fill request and response with data.  The source server may choose to
    // respond with more than one response message per fill request.  Extra
    // fill responses will be treated as prefetches, though the cache is
    // free to drop them.
    method Action readReq(t_CACHE_ADDR addr, t_CACHE_REF_INFO refInfo);
    method ActionValue#(RL_DM_CACHE_FILL_RESP#(t_CACHE_ADDR,
                                               t_CACHE_WORD,
                                               t_CACHE_REF_INFO)) readResp();
    
    // Asynchronous write (no response)
    method Action write(t_CACHE_ADDR addr,
                        t_CACHE_WORD val,
                        t_CACHE_REF_INFO refInfo);
    
    // Synchronous write.  writeSyncWait() blocks until the response arrives.
    method Action writeSyncReq(t_CACHE_ADDR addr,
                               t_CACHE_WORD val,
                               t_CACHE_REF_INFO refInfo);
    method Action writeSyncWait();

endinterface: RL_DM_CACHE_SOURCE_DATA



// ===================================================================
//
// Internal types
//
// ===================================================================

typedef struct
{
    t_CACHE_ADDR addr;
    t_CACHE_REF_INFO refInfo;
}
RL_DM_CACHE_READ_REQ#(type t_CACHE_ADDR,
                      type t_CACHE_REF_INFO)
    deriving (Eq, Bits);

typedef struct
{
    t_CACHE_ADDR addr;
    t_CACHE_WORD val;
    t_CACHE_REF_INFO refInfo;
}
RL_DM_CACHE_WRITE_REQ#(type t_CACHE_ADDR,
                       type t_CACHE_WORD,
                       type t_CACHE_REF_INFO)
    deriving (Eq, Bits);

typedef struct
{
    t_CACHE_ADDR addr;
    t_CACHE_REF_INFO refInfo;
    Bool inval;
    Bool sendAck;
}
RL_DM_CACHE_FLUSH_REQ#(type t_CACHE_ADDR,
                       type t_CACHE_REF_INFO)
    deriving (Eq, Bits);

typedef enum
{
    DM_CACHE_READ,
    DM_CACHE_WRITE,
    DM_CACHE_FLUSH
}
RL_DM_CACHE_REQ
    deriving (Eq, Bits);

// ===================================================================
//
// Cache implementation
//
// ===================================================================

module mkCacheDirectMapped#(RL_DM_CACHE_SOURCE_DATA#(Bit#(t_CACHE_ADDR_SZ), t_CACHE_WORD, t_CACHE_REF_INFO) sourceData,
                            DEBUG_FILE debugLog)
    // interface:
    (RL_DM_CACHE#(Bit#(t_CACHE_ADDR_SZ), t_CACHE_WORD, t_CACHE_REF_INFO, nTagExtraLowBits))
    provisos (Alias#(Bit#(t_CACHE_ADDR_SZ), t_CACHE_ADDR),
              Alias#(RL_DM_CACHE_LOAD_RESP#(t_CACHE_WORD, t_CACHE_REF_INFO), t_CACHE_LOAD_RESP),
              Alias#(RL_DM_CACHE_READ_REQ#(t_CACHE_ADDR, t_CACHE_REF_INFO), t_CACHE_READ_REQ),
              Alias#(RL_DM_CACHE_WRITE_REQ#(t_CACHE_ADDR, t_CACHE_WORD, t_CACHE_REF_INFO), t_CACHE_WRITE_REQ),
              Alias#(RL_DM_CACHE_FLUSH_REQ#(t_CACHE_ADDR, t_CACHE_REF_INFO), t_CACHE_FLUSH_REQ),
       
              // Required by the compiler:
              Bits#(t_CACHE_LOAD_RESP, t_CACHE_LOAD_RESP_SZ),
              Bits#(t_CACHE_READ_REQ, t_CACHE_READ_REQ_SZ),
              Bits#(t_CACHE_WRITE_REQ, t_CACHE_WRITE_REQ_SZ),
              Bits#(t_CACHE_FLUSH_REQ, t_CACHE_FLUSH_REQ_SZ));
    
    // Incoming data.  Merge FIFO controls the order.
    MERGE_FIFOF#(3, RL_DM_CACHE_REQ) reqQ <- mkMergeBypassFIFOF();
    FIFO#(t_CACHE_READ_REQ) readReqQ <- mkBypassFIFO();
    FIFO#(t_CACHE_WRITE_REQ) writeReqQ <- mkBypassFIFO();
    FIFO#(t_CACHE_FLUSH_REQ) flushReqQ <- mkBypassFIFO();

    FIFO#(t_CACHE_LOAD_RESP) readRespQ <- mkFIFO();

    Reg#(Bool) awaitingResp <- mkReg(False);

    rule processIncomingReq (! awaitingResp);
        let r = reqQ.first();
        case (r) matches
            DM_CACHE_READ:
            begin
                let read_req = readReqQ.first();
                readReqQ.deq();

                sourceData.readReq(read_req.addr, read_req.refInfo);
                awaitingResp <= True;
            end

            DM_CACHE_WRITE:
            begin
                let write_req = writeReqQ.first();
                writeReqQ.deq();

                sourceData.write(write_req.addr, write_req.val, write_req.refInfo);
                reqQ.deq();
            end

            DM_CACHE_FLUSH:
            begin
                let flush_req = flushReqQ.first();
                flushReqQ.deq();

                reqQ.deq();
            end
        endcase
    endrule

    rule forwardReadResp (awaitingResp);
        let r <- sourceData.readResp();
        reqQ.deq();
        awaitingResp <= False;
        
        t_CACHE_LOAD_RESP resp;
        resp.val = r.val;
        resp.refInfo = r.refInfo;
        
        readRespQ.enq(resp);
    endrule


    method Action readReq(t_CACHE_ADDR addr, t_CACHE_REF_INFO refInfo);
        readReqQ.enq(RL_DM_CACHE_READ_REQ { addr: addr, refInfo: refInfo });
        reqQ.ports[1].enq(DM_CACHE_READ);
    endmethod

    method ActionValue#(RL_DM_CACHE_LOAD_RESP#(t_CACHE_WORD, t_CACHE_REF_INFO)) readResp();
        let r = readRespQ.first();
        readRespQ.deq();

        return r;
    endmethod


    method Action write(t_CACHE_ADDR addr, t_CACHE_WORD val, t_CACHE_REF_INFO refInfo);
        writeReqQ.enq(RL_DM_CACHE_WRITE_REQ { addr: addr, val: val, refInfo: refInfo });
        reqQ.ports[2].enq(DM_CACHE_WRITE);
    endmethod
    

    method Action invalReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
        flushReqQ.enq(RL_DM_CACHE_FLUSH_REQ { addr: addr,
                                              refInfo: refInfo,
                                              inval: True,
                                              sendAck: sendAck });
        reqQ.ports[0].enq(DM_CACHE_FLUSH);
    endmethod

    method Action flushReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
        flushReqQ.enq(RL_DM_CACHE_FLUSH_REQ { addr: addr,
                                              refInfo: refInfo,
                                              inval: False,
                                              sendAck: sendAck });
        reqQ.ports[0].enq(DM_CACHE_FLUSH);
    endmethod

    method Action invalOrFlushWait();
    endmethod

endmodule
