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
// Direct mapped cache.  This cache is intended to be relatively simple and
// light weight, with fast hit times.
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
// Cache mode can set the write policy or completely disable hits in the cache.
// This is mostly useful for debugging.
//
typedef enum
{
    RL_DM_MODE_WRITE_BACK,
    RL_DM_MODE_WRITE_THROUGH,
    RL_DM_MODE_DISABLED
}
RL_DM_CACHE_MODE
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
                       numeric type nTagExtraLowBits,
                       numeric type nEntries);

    // Read a word.  Read from backing store if not already cached.
    // *** Read responses are NOT guaranteed to be in the order of requests. ***
    method Action readReq(t_CACHE_ADDR addr, t_CACHE_REF_INFO refInfo);

    method ActionValue#(RL_DM_CACHE_LOAD_RESP#(t_CACHE_WORD, t_CACHE_REF_INFO)) readResp();
    

    // Write a word to a cache line.  Word index 0 corresponds to the
    // low bits of a cache line.
    method Action write(t_CACHE_ADDR addr, t_CACHE_WORD val, t_CACHE_REF_INFO refInfo);
    
    // Invalidate & flush requests.  Both write dirty lines back.  Invalidate drops
    // the line from the cache.  Flush keeps the line in the cache.
    // invalOrFlushWait is used iff sendAck is true.
    method Action invalReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
    method Action flushReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
    method Action invalOrFlushWait();
    
    //
    // Set cache mode.  Mostly useful for debugging.  This may not be changed
    // in the middle of a run!
    //
    method Action setCacheMode(RL_DM_CACHE_MODE mode);

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

    // Fill request and response with data.  The source server must respond
    // in order.
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

    // Wait for writeSyncReq to complete.
    method Action writeSyncWait();

    // Pass invalidate and flush requests down the hierarchy.  The semantics
    // are the same as the methods on the cache.
    method Action invalReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
    method Action flushReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
    method Action invalOrFlushWait();

endinterface: RL_DM_CACHE_SOURCE_DATA



// ===================================================================
//
// Internal types
//
// ===================================================================

typedef enum
{
    DM_CACHE_READ,
    DM_CACHE_WRITE,
    DM_CACHE_FLUSH,
    DM_CACHE_INVAL
}
RL_DM_CACHE_ACTION
    deriving (Eq, Bits);


//
// Index of the write data heap index.  To save space, write data is passed
// through the cache pipelines as a pointer.  The heap size limits the number
// of writes in flight.  Writes never wait for a fill, so the heap doesn't
// have to be especially large.
//
typedef Bit#(2) RL_DM_WRITE_DATA_HEAP_IDX;


//
// Basic cache request.  A tagged union would be a good idea here but the
// compiler gets funny about Bits#() of a tagged union and seems to force
// ugly provisos up the call chain.
//
typedef struct
{
   RL_DM_CACHE_ACTION act;
   t_CACHE_ADDR addr;
   t_CACHE_REF_INFO refInfo;
 
   // Write data index
   RL_DM_WRITE_DATA_HEAP_IDX writeDataIdx;
 
   // Flush / inval info
   Bool sendAck;
}
RL_DM_CACHE_REQ#(type t_CACHE_ADDR, type t_CACHE_REF_INFO)
    deriving (Eq, Bits);


// Cache index
typedef UInt#(TLog#(nEntries)) RL_DM_CACHE_IDX#(numeric type nEntries);


typedef struct
{
    Bool dirty;
    t_CACHE_TAG tag;
    t_CACHE_WORD val;
}
RL_DM_CACHE_ENTRY#(type t_CACHE_WORD, type t_CACHE_TAG)
    deriving (Eq, Bits);


// ===================================================================
//
// Cache implementation
//
// ===================================================================

module mkCacheDirectMapped#(RL_DM_CACHE_SOURCE_DATA#(Bit#(t_CACHE_ADDR_SZ), t_CACHE_WORD, t_CACHE_REF_INFO) sourceData,
                            DEBUG_FILE debugLog)
    // interface:
    (RL_DM_CACHE#(Bit#(t_CACHE_ADDR_SZ), t_CACHE_WORD, t_CACHE_REF_INFO, nTagExtraLowBits, nEntries))
    provisos (Bits#(t_CACHE_REF_INFO, t_CACHE_REF_INFO_SZ),
              Bits#(t_CACHE_WORD, t_CACHE_WORD_SZ),
              Alias#(Bit#(t_CACHE_ADDR_SZ), t_CACHE_ADDR),

              // Entries must be a power of 2 and smaller than the address.
              Add#(nEntries, 0, TExp#(TLog#(nEntries))),
              Alias#(RL_DM_CACHE_IDX#(nEntries), t_CACHE_IDX),
              Bits#(t_CACHE_IDX, t_CACHE_IDX_SZ),

              // Tag is the address bits other than the entry index
              Alias#(Bit#(TSub#(t_CACHE_ADDR_SZ, t_CACHE_IDX_SZ)), t_CACHE_TAG),
              Alias#(Maybe#(RL_DM_CACHE_ENTRY#(t_CACHE_WORD, t_CACHE_TAG)), t_CACHE_ENTRY),

              Alias#(RL_DM_CACHE_REQ#(t_CACHE_ADDR, t_CACHE_REF_INFO), t_CACHE_REQ),
              Alias#(RL_DM_CACHE_LOAD_RESP#(t_CACHE_WORD, t_CACHE_REF_INFO), t_CACHE_LOAD_RESP),
       
              // Required by the compiler:
              Bits#(t_CACHE_LOAD_RESP, t_CACHE_LOAD_RESP_SZ),
              Bits#(t_CACHE_TAG, t_CACHE_TAG_SZ),
              Add#(TLog#(TExp#(TLog#(nEntries))), 0, TLog#(nEntries)),
              Add#(TLog#(TDiv#(TExp#(TLog#(nEntries)), 2)), x__, TLog#(nEntries)));
    
    Reg#(RL_DM_CACHE_MODE) cacheMode <- mkReg(RL_DM_MODE_WRITE_BACK);

    // Cache data and tag
    BRAM#(t_CACHE_IDX, t_CACHE_ENTRY) cache <- mkBRAMInitialized(tagged Invalid);

    // Track busy entries
    COUNTING_FILTER#(t_CACHE_IDX) entryFilter <- mkCountingFilter(False, debugLog);

    // Write data is kept in a heap to avoid passing it around through FIFOs.
    // The heap size limits the number of writes in flight.
    MEMORY_HEAP_IMM#(RL_DM_WRITE_DATA_HEAP_IDX, t_CACHE_WORD) reqInfo_writeData <- mkMemoryHeapUnionLUTRAM();

    // Incoming data.  Merge FIFO controls the order.
    MERGE_FIFOF#(3, t_CACHE_REQ) newReqQ <- mkMergeBypassFIFOF();

    // Pipelines
    FIFO#(t_CACHE_REQ) cacheLookupQ <- mkFIFO();
    FIFO#(t_CACHE_REQ) fillReqQ <- mkFIFO();
    FIFO#(Tuple2#(t_CACHE_REQ, Bool)) invalQ <- mkFIFO();

    FIFO#(t_CACHE_LOAD_RESP) readRespQ <- mkBypassFIFO();


    //
    // debugAddr --
    //     Pretty printer for converting cache addresses to system addresses.
    //     Adds trailing 0's that were dropped from cache addresses because they
    //     are inside a cache line.
    //
    function Bit#(TAdd#(t_CACHE_ADDR_SZ, nTagExtraLowBits)) debugAddr(t_CACHE_ADDR addr);
        Bit#(nTagExtraLowBits) zero = 0;
        return zeroExtendNP({ addr, zero });
    endfunction


    //
    // Convert address to cache index and tag
    //

    function Tuple2#(t_CACHE_TAG, t_CACHE_IDX) cacheEntryFromAddr(t_CACHE_ADDR addr);
        return unpack(truncateNP(addr));
    endfunction

    function t_CACHE_ADDR cacheAddrFromEntry(t_CACHE_TAG tag, t_CACHE_IDX idx);
        return zeroExtendNP({tag, pack(idx)});
    endfunction


    // ====================================================================
    //
    // All incoming requests start here.
    //
    // ====================================================================

    rule startNewReq (True);
        let r = newReqQ.first();
        match {.tag, .entryIdx} = cacheEntryFromAddr(r.addr);

        // Is the entry busy?
        let success <- entryFilter.insert(entryIdx);
        if (success)
        begin
            debugLog.record($format("    startNewReq: addr=0x%x, entry=0x%x", debugAddr(r.addr), entryIdx));

            // Read the entry either to return the value (READ) or to see whether
            // the entry is dirty and flush it.
            cache.readReq(entryIdx);

            cacheLookupQ.enq(r);
            newReqQ.deq();
        end
    endrule


    // ====================================================================
    //
    // Read path
    //
    // ====================================================================

    (* conservative_implicit_conditions *)
    rule lookupRead (cacheLookupQ.first().act == DM_CACHE_READ);
        let r = cacheLookupQ.first();
        cacheLookupQ.deq();

        let cur_entry <- cache.readRsp();

        match {.r_tag, .entryIdx} = cacheEntryFromAddr(r.addr);

        Bool needFill = True;

        if (cacheMode != RL_DM_MODE_DISABLED &&& cur_entry matches tagged Valid .e)
        begin
            if (e.tag == r_tag)
            begin
                // Hit!
                debugLog.record($format("    lookupRead: HIT addr=0x%x, entry=0x%x, val=0x%x", debugAddr(r.addr), entryIdx, e.val));

                t_CACHE_LOAD_RESP resp;
                resp.val = e.val;
                resp.refInfo = r.refInfo;
                readRespQ.enq(resp);

                entryFilter.remove(entryIdx);
                needFill = False;
            end
            else if (e.dirty)
            begin
                // Miss.  Need to flush old data?
                let old_addr = cacheAddrFromEntry(e.tag, entryIdx);
                debugLog.record($format("    doWrite: FLUSH addr=0x%x, entry=0x%x, val=0x%x", debugAddr(old_addr), entryIdx, e.val));

                sourceData.write(old_addr, e.val, r.refInfo);
            end
        end

        // Request fill of new value
        if (needFill)
            fillReqQ.enq(r);
    endrule


    //
    // fillReq --
    //     Request fill from backing storage.
    //
    rule fillReq (True);
        let r = fillReqQ.first();
        fillReqQ.deq();

        debugLog.record($format("    fillReq: addr=0x%x", debugAddr(r.addr)));

        sourceData.readReq(r.addr, r.refInfo);
    endrule
    

    //
    // fillResp --
    //     Fill response.  Fills must return in order.
    //
    rule fillResp (True);
        let f <- sourceData.readResp();
        
        match {.tag, .entryIdx} = cacheEntryFromAddr(f.addr);

        debugLog.record($format("    fillResp: FILL addr=0x%x, entry=0x%x, val=0x%x", debugAddr(f.addr), entryIdx, f.val));

        t_CACHE_LOAD_RESP resp;
        resp.val = f.val;
        resp.refInfo = f.refInfo;
        readRespQ.enq(resp);
        
        // Save value in cache
        cache.write(entryIdx, tagged Valid RL_DM_CACHE_ENTRY { dirty: False,
                                                               tag: tag,
                                                               val: f.val });

        entryFilter.remove(entryIdx);
    endrule


    // ====================================================================
    //
    // Write path
    //
    // ====================================================================

    (* conservative_implicit_conditions *)
    rule doWrite (cacheLookupQ.first().act == DM_CACHE_WRITE);
        let r = cacheLookupQ.first();
        cacheLookupQ.deq();

        let cur_entry <- cache.readRsp();

        match {.r_tag, .entryIdx} = cacheEntryFromAddr(r.addr);

        // New data to write
        let w_data = reqInfo_writeData.sub(r.writeDataIdx);
        reqInfo_writeData.free(r.writeDataIdx);

        if (cacheMode != RL_DM_MODE_WRITE_BACK)
        begin
            // Caching writes is disabled.  Write through.
            debugLog.record($format("    doWrite: WRITE THROUGH addr=0x%x, entry=0x%x, val=0x%x", debugAddr(r.addr), entryIdx, w_data));
            sourceData.write(r.addr, w_data, r.refInfo);
        end
        else if (cur_entry matches tagged Valid .e &&&
                 e.dirty &&&
                 e.tag != r_tag)
        begin
            // Dirty data must be flushed
            let old_addr = cacheAddrFromEntry(e.tag, entryIdx);
            debugLog.record($format("    doWrite: FLUSH addr=0x%x, entry=0x%x, val=0x%x", debugAddr(old_addr), entryIdx, e.val));

            sourceData.write(old_addr, e.val, r.refInfo);
        end

        // Now do the write.
        debugLog.record($format("    doWrite: WRITE addr=0x%x, entry=0x%x, val=0x%x", debugAddr(r.addr), entryIdx, w_data));

        cache.write(entryIdx, tagged Valid RL_DM_CACHE_ENTRY { dirty: (cacheMode == RL_DM_MODE_WRITE_BACK),
                                                               tag: r_tag,
                                                               val: w_data });

        entryFilter.remove(entryIdx);
    endrule


    // ====================================================================
    //
    // Inval / flush path
    //
    // ====================================================================

    (* conservative_implicit_conditions *)
    rule evictForInval ((cacheLookupQ.first().act == DM_CACHE_INVAL) ||
                        (cacheLookupQ.first().act == DM_CACHE_FLUSH));
        let r = cacheLookupQ.first();
        cacheLookupQ.deq();

        let cur_entry <- cache.readRsp();

        match {.r_tag, .entryIdx} = cacheEntryFromAddr(r.addr);

        Bool was_dirty = False;
        if (cur_entry matches tagged Valid .e &&& (e.tag == r_tag))
        begin
            if (e.dirty)
            begin
                // Dirty data must be flushed
                let old_addr = cacheAddrFromEntry(e.tag, entryIdx);
                debugLog.record($format("    evictForInval: FLUSH addr=0x%x, entry=0x%x, sync=%0d, val=0x%x", debugAddr(old_addr), entryIdx, r.sendAck, e.val));

                was_dirty = True;

                if (r.sendAck)
                    sourceData.writeSyncReq(old_addr, e.val, r.refInfo);
                else
                    sourceData.write(old_addr, e.val, r.refInfo);
            end

            // Clear the entry if invalidating
            if (r.act == DM_CACHE_INVAL)
            begin
                debugLog.record($format("    evictForInval: INVAL addr=0x%x, entry=0x%x", debugAddr(r.addr), entryIdx));
                cache.write(entryIdx, tagged Invalid);
            end
        end

        invalQ.enq(tuple2(r, was_dirty));
    endrule


    (* descending_urgency = "fillResp, fillReq, lookupRead, doWrite, finishInval, evictForInval" *)
    rule finishInval (True);
        match {.r, .was_dirty} = invalQ.first();
        invalQ.deq();

        // Wait for an ACK that the value reached the next level down, if required.
        if (was_dirty && r.sendAck)
        begin
            sourceData.writeSyncWait();
        end

        match {.r_tag, .entryIdx} = cacheEntryFromAddr(r.addr);

        //
        // Pass the message down the hierarchy.  There might be another cache
        // below this one.
        //
        if (r.act == DM_CACHE_INVAL)
            sourceData.invalReq(r.addr, r.sendAck, r.refInfo);
        else
            sourceData.flushReq(r.addr, r.sendAck, r.refInfo);

        entryFilter.remove(entryIdx);
    endrule


    // ====================================================================
    //
    // Methods
    //
    // ====================================================================

    method Action readReq(t_CACHE_ADDR addr, t_CACHE_REF_INFO refInfo);
        debugLog.record($format("  New request: READ addr=0x%x", debugAddr(addr)));

        t_CACHE_REQ r = ?;
        r.act = DM_CACHE_READ;
        r.addr = addr;
        r.refInfo = refInfo;
        newReqQ.ports[1].enq(r);
    endmethod

    method ActionValue#(RL_DM_CACHE_LOAD_RESP#(t_CACHE_WORD, t_CACHE_REF_INFO)) readResp();
        let r = readRespQ.first();
        readRespQ.deq();

        return r;
    endmethod


    method Action write(t_CACHE_ADDR addr, t_CACHE_WORD val, t_CACHE_REF_INFO refInfo);
        // Store the write data on a heap
        let data_idx <- reqInfo_writeData.malloc();
        reqInfo_writeData.upd(data_idx, val);

        t_CACHE_REQ r = ?;
        r.act = DM_CACHE_WRITE;
        r.addr = addr;
        r.refInfo = refInfo;
        r.writeDataIdx = data_idx;
        newReqQ.ports[2].enq(r);

        debugLog.record($format("  New request: WRITE addr=0x%x, wData heap=%0d, val=0x%x", debugAddr(addr), data_idx, val));
    endmethod
    

    method Action invalReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
        debugLog.record($format("  New request: INVAL addr=0x%x, ack=%d", debugAddr(addr), sendAck));

        t_CACHE_REQ r = ?;
        r.act = DM_CACHE_INVAL;
        r.addr = addr;
        r.refInfo = refInfo;
        r.sendAck = sendAck;
        newReqQ.ports[0].enq(r);
    endmethod

    method Action flushReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
        debugLog.record($format("  New request: FLUSH addr=0x%x, ack=%d", debugAddr(addr), sendAck));

        t_CACHE_REQ r = ?;
        r.act = DM_CACHE_FLUSH;
        r.addr = addr;
        r.refInfo = refInfo;
        r.sendAck = sendAck;
        newReqQ.ports[0].enq(r);
    endmethod

    method Action invalOrFlushWait();
        debugLog.record($format("    INVAL/FLUSH complete"));

        sourceData.invalOrFlushWait();
    endmethod


    method Action setCacheMode(RL_DM_CACHE_MODE mode);
        cacheMode <= mode;
    endmethod
endmodule
