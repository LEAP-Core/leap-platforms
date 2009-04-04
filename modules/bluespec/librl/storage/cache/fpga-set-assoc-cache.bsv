//
// Copyright (C) 2008 Intel Corporation
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
// Author: Michael Adler
//
// A generic cache class (n-way set associative) for caching data in BRAM.
// Classes building a cache must provide an interface class to the source
// data of type HASIM_CACHE_SOURCE_DATA (defined below).  The cache
// takes a number of parameters: the address and data types, the number of
// sets and the number of ways within each set.
//
// The cache may either be write-back (the default) or write-through.  For
// write through caches it is the callers responsibility to do the write
// to backing storage.  This cache class merely skips setting of the dirty
// bit on writes in write-through mode.
//

// Library imports.

import FIFO::*;
import FIFOF::*;
import Vector::*;
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
    // Not all returned words are guaranteed, so they are protected by Maybe#().
    // The requested word is guaranteed valid.
    Vector#(nWordsPerLine, Maybe#(t_CACHE_WORD)) words;
    t_CACHE_ADDR addr;
    t_CACHE_REF_INFO refInfo;
}
HASIM_CACHE_LOAD_RESP#(type t_CACHE_ADDR,
                       type t_CACHE_WORD,
                       numeric type nWordsPerLine,
                       type t_CACHE_REF_INFO)
    deriving (Eq, Bits);


//
// HAsim cache interface.  nTagExtraLowBits is used just for debugging.
// This specified number of low bits are prepanded to cache tags so
// addresses match those seen in other modules.
//
// t_CACHE_REF_INFO is metadata associated with a reference.  Metadata is
// passed to the backing store for fills.  The metadata is not stored in
// the cache.
//
interface HASIM_CACHE#(type t_CACHE_ADDR,
                       type t_CACHE_LINE,
                       type t_CACHE_WORD,
                       numeric type nWordsPerLine,
                       type t_CACHE_REF_INFO,
                       numeric type nSets,
                       numeric type nWays,
                       numeric type nTagExtraLowBits);

    // Read up to a full line.  Read from backing store if not already cached.
    // The read response is guaranteed to return at least the requested
    // word in the line.  If more of the line is already available it will
    // be returned as well.
    method Action readReq(t_CACHE_ADDR addr,
                          Bit#(TLog#(nWordsPerLine)) wordIdx,
                          t_CACHE_REF_INFO refInfo);

    method ActionValue#(HASIM_CACHE_LOAD_RESP#(t_CACHE_ADDR, t_CACHE_WORD, nWordsPerLine, t_CACHE_REF_INFO)) readResp();

    // Predicate to test whether a read response is ready this cycle.
    method Bool readRespReady();
    

    // Write a word to a cache line.  Word index 0 corresponds to the
    // low bits of a cache line.
    method Action write(t_CACHE_ADDR addr,
                        t_CACHE_WORD val,
                        Bit#(TLog#(nWordsPerLine)) wordIdx,
                        t_CACHE_REF_INFO refInfo);
    
    // Invalidate & flush requests.  Both write dirty lines back.  Invalidate drops
    // the line from the cache.  Flush keeps the line in the cache.  A response
    // is returned for invalOrFlushWait iff sendAck is true.
    method Action invalReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
    method Action flushReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo);
    method Action invalOrFlushWait();

    // Invalidate entire cache.
    method Action invalAllReq(t_CACHE_REF_INFO refInfo);
    method Action invalAllWait();
    
    // Write back or write through cache?  Default is write back.
    // NOTE:  Turning off writeback does NOT cause the cache to write through
    //        as stores arrive.  All it does is keep the dirty bit from being
    //        set on writes.  If a caller turns off write back it becomes the
    //        responsibility of the caller to write data to the storage device
    //        outside of this interface.
    method Action setModeWriteBack(Bool isWriteBack);

endinterface: HASIM_CACHE


//
// The caller must provide an instance of the HASIM_CACHE_SOURCE_DATA interface
// so the cache can read and write data from the next level in the hierarchy.
//
// See HASIM_CACHE interface for description of refInfo.
//
interface HASIM_CACHE_SOURCE_DATA#(type t_CACHE_ADDR,
                                   type t_CACHE_LINE,
                                   numeric type nWordsPerLine,
                                   type t_CACHE_REF_INFO);

    // Read request and response with data
    method Action readReq(t_CACHE_ADDR addr, t_CACHE_REF_INFO refInfo);
    method ActionValue#(t_CACHE_LINE) readResp();
    
    // Asynchronous write (no response)
    method Action write(t_CACHE_ADDR addr,
                        Vector#(nWordsPerLine, Bool) wordValidMask,
                        t_CACHE_LINE val,
                        t_CACHE_REF_INFO refInfo);
    
    // Synchronous write.  writeSyncWait() blocks until the response arrives.
    method Action writeSyncReq(t_CACHE_ADDR addr,
                               Vector#(nWordsPerLine, Bool) wordValidMask,
                               t_CACHE_LINE val,
                               t_CACHE_REF_INFO refInfo);
    method Action writeSyncWait();

endinterface: HASIM_CACHE_SOURCE_DATA


//
// The caller must provide an instance of the HASIM_CACHE_STATS interface to
// the cache code.  This allows each instance of the cache to have its own
// statistics.  mkNullHAsimCacheStats is provided in this package for callers
// not interested in statistics.
//
interface HASIM_CACHE_STATS;
    method Action readHit();
    method Action readMiss();
    method Action writeHit();
    method Action writeMiss();
    method Action invalLine();             // Invalidate due to capacity
    method Action dirtyLineFlush();
    method Action forceInvalLine();        // Invalidate forced by external request
endinterface: HASIM_CACHE_STATS


// ===================================================================
//
// PRIVATE DATA STRUCTURES
//
// ===================================================================

//
// States in the cache manager FSM
//
typedef enum
{
    HCST_NORMAL,

    // Invalidating all sets
    HCST_INVAL_ALL,
    HCST_INVAL_ALL_DONE
}
HASIM_CACHE_STATE
    deriving (Eq, Bits);

//
// Data to be written to the cache.
//
typedef struct
{
    t_CACHE_WORD val;
}
HASIM_CACHE_WRITE_INFO#(type t_CACHE_WORD, type t_CACHE_WRITE_WORD_IDX)
    deriving (Eq, Bits);

//
// Bit size of the write data heap index.  To save space, write data is passed
// through the cache pipelines as a pointer.  The heap size limits the number
// of writes in flight.  Writes never wait for a fill, so the heap doesn't
// have to be especially large.
//
typedef 3 WRITE_DATA_HEAP_IDX_SZ;

//
// Meta-data associated with a write request.
//
typedef struct
{
    Bit#(WRITE_DATA_HEAP_IDX_SZ) dataIdx;
    Bit#(TLog#(nWordsPerLine)) wordIdx;
}
HASIM_CACHE_WRITE_REQ#(numeric type nWordsPerLine)
    deriving (Eq, Bits);


typedef UInt#(TLog#(nSets)) HASIM_CACHE_SET_IDX#(numeric type nSets);
typedef UInt#(TLog#(nWays)) HASIM_CACHE_WAY_IDX#(numeric type nWays);


//
// Cache metadata (tag and a dirty bit). It is the responsibility of the
// package using this cache to drop insignificant low bits from the address
// size before addresses reach here.
//
typedef struct
{
    t_CACHE_TAG tag;
    Bool dirty;
    Vector#(nWordsPerLine, Bool) wordValid;
}
HASIM_CACHE_METADATA#(type t_CACHE_TAG, numeric type nWordsPerLine)
    deriving(Bits, Eq);

//
// The cache data is indexed by the set and the way within the set.
// Declaring the cache data as multiply indexed vectors results in a large
// amount of extra LUT usage to control the BRAMs.  Instead, we allocate a
// single large cache data BRAM and index it with a packed version of this
// structure:
//
typedef struct
{
    t_CACHE_SET_IDX set;
    HASIM_CACHE_WAY_IDX#(nWays) way;
}
HASIM_CACHE_DATA_IDX#(numeric type nWays, type t_CACHE_SET_IDX)
    deriving(Bits, Eq);


//
// Responses to flush and invalidate requests are returned in order to
// guarantee consistent state.  The number of entries in the scoreboard
// limits the number of requests in flight.
//
typedef 16 HASIM_CACHE_MAX_INVAL;
typedef Bit#(TLog#(HASIM_CACHE_MAX_INVAL)) HASIM_CACHE_INVAL_IDX;

//
// Cache reads may be returned either in order or out of order depending
// on the permitOOOReadResp argument to mkCachesetAssoc.  When response
// must be ordered the size of the read response FIFO limits the number
// of requests in flight.  Data can be large, so there is more of a space
// tradeoff for reads than flush requests.
//
typedef 4 HASIM_CACHE_MAX_READ;
typedef Bit#(TLog#(HASIM_CACHE_MAX_READ)) HASIM_CACHE_READ_FIFO_IDX;

//
// Meta-data associated with a read request.
//
typedef struct
{
    Bit#(TLog#(nWordsPerLine)) wordIdx;
    HASIM_CACHE_READ_FIFO_IDX readFifoIdx;
}
HASIM_CACHE_READ_REQ#(numeric type nWordsPerLine)
    deriving (Eq, Bits);


//
// Basic request information constructed when a new request arrives.
//
// This declaration would be much cleaner if typedef could be inside a module
// after the types are known.
//
typedef struct
{
    t_CACHE_TAG     tag;
    t_CACHE_SET_IDX set;
    t_CACHE_WAY_IDX way;

    // Meta-data associated with the reference.  Meta-data has meaning only to the
    // caller.
    t_CACHE_REF_INFO refInfo;
}
HASIM_CACHE_REQ_BASE#(type t_CACHE_TAG,
                      type t_CACHE_SET_IDX,
                      type t_CACHE_WAY_IDX,
                      type t_CACHE_REF_INFO)
    deriving(Bits, Eq);

typedef union tagged
{
    // Reads have no extra data (beyond HASIM_CACHE_REQ_BASE above)
    HASIM_CACHE_READ_REQ#(nWordsPerLine) HCOP_READ;

    // Writes have pointer to data to be written
    HASIM_CACHE_WRITE_REQ#(nWordsPerLine) HCOP_WRITE;

    // Inval and flush have a bool indicating whether an ACK is needed
    Maybe#(HASIM_CACHE_INVAL_IDX) HCOP_INVAL;
    Maybe#(HASIM_CACHE_INVAL_IDX) HCOP_FLUSH_DIRTY;
}
HASIM_CACHE_REQ#(numeric type nWordsPerLine)
    deriving(Bits, Eq);



// ========================================================================
//
// mkCacheSetAssoc --
//     Set associative cache.
//
//    NOTE: mkCacheSetAssoc may return read responses out of order relative
//          to the request order!  For in-order responses the caller
//          must add a tag to the t_CACHE_REF_INFO type and use the
//          tag to sort the responses.  A SCOREBOARD_FIFO would do the job.
//
// ========================================================================

module mkCacheSetAssoc#(HASIM_CACHE_SOURCE_DATA#(Bit#(t_CACHE_ADDR_SZ), t_CACHE_LINE, nWordsPerLine, t_CACHE_REF_INFO) sourceData,
                        HASIM_CACHE_STATS stats,
                        Bool permitOOOReadResp,
                        DEBUG_FILE debugLog)
    // interface:
        (HASIM_CACHE#(Bit#(t_CACHE_ADDR_SZ), t_CACHE_LINE, t_CACHE_WORD, nWordsPerLine, t_CACHE_REF_INFO, nSets, nWays, nTagExtraLowBits))
    provisos (Bits#(t_CACHE_LINE, t_CACHE_LINE_SZ),
              Bits#(t_CACHE_REF_INFO, t_CACHE_REF_INFO_SZ),
              Bits#(t_CACHE_WORD, t_CACHE_WORD_SZ),

              // The interface allows for numbers of sets and ways that aren't
              // powers of 2, but the implementation currently does not.  Enforce
              // powers of 2 here.
              Add#(nSets, 0, TExp#(TLog#(nSets))),
              Add#(nWays, 0, TExp#(TLog#(nWays))),

              // Write word size must tile into cache line
              Bits#(Vector#(nWordsPerLine, t_CACHE_WORD), t_CACHE_LINE_SZ),

              // Cache address size must be no larger than 64 bits
              Add#(t_CACHE_ADDR_SZ, a__, 64),

              // Set index and tag.  Set index size + tag size == address size.
              Alias#(HASIM_CACHE_SET_IDX#(nSets), t_CACHE_SET_IDX),
              Bits#(t_CACHE_SET_IDX, t_CACHE_SET_IDX_SZ),
              Add#(t_CACHE_TAG_SZ, t_CACHE_SET_IDX_SZ, t_CACHE_ADDR_SZ),
              Alias#(Bit#(t_CACHE_TAG_SZ), t_CACHE_TAG),

              // Set size must be no longer than 32 bits (for set filter)
              Add#(t_CACHE_SET_IDX_SZ, b__, 32),

              Alias#(Bit#(t_CACHE_ADDR_SZ), t_CACHE_ADDR),
              Alias#(HASIM_CACHE_WAY_IDX#(nWays), t_CACHE_WAY_IDX),
              Alias#(Vector#(nWays, HASIM_CACHE_WAY_IDX#(nWays)), t_LRU_LIST),
              Alias#(HASIM_CACHE_DATA_IDX#(nWays, t_CACHE_SET_IDX), t_CACHE_DATA_IDX),
              Alias#(HASIM_CACHE_METADATA#(t_CACHE_TAG, nWordsPerLine), t_METADATA),
              Alias#(HASIM_CACHE_LOAD_RESP#(t_CACHE_ADDR, t_CACHE_WORD, nWordsPerLine, t_CACHE_REF_INFO), t_CACHE_LOAD_RESP),
              Alias#(Vector#(nWays, Maybe#(HASIM_CACHE_METADATA#(t_CACHE_TAG, nWordsPerLine))), t_METADATA_VECTOR),
              Alias#(HASIM_CACHE_REQ_BASE#(t_CACHE_TAG, t_CACHE_SET_IDX, t_CACHE_WAY_IDX, t_CACHE_REF_INFO), t_CACHE_REQ_BASE),
              Alias#(HASIM_CACHE_REQ#(nWordsPerLine), t_CACHE_REQ),
              Alias#(Bit#(TLog#(nWordsPerLine)), t_CACHE_WRITE_WORD_IDX),
              Alias#(HASIM_CACHE_WRITE_INFO#(t_CACHE_WORD, t_CACHE_WRITE_WORD_IDX), t_CACHE_WRITE_INFO),
              Alias#(Vector#(nWordsPerLine, Bool), t_CACHE_WORD_VALID_MASK),
       
              Bits#(t_CACHE_REQ, t_CACHE_REQ_SZ),

              // Unbelievably ugly tautologies required by the compiler:
              Add#(t_CACHE_ADDR_SZ, nTagExtraLowBits, TAdd#(t_CACHE_ADDR_SZ, nTagExtraLowBits)),
              Log#(nWays, TLog#(nWays)),
              Add#(TLog#(TExp#(TLog#(nSets))), 0, TLog#(nSets)),
              Add#(TLog#(TDiv#(TExp#(TLog#(nSets)), 2)), x__, TLog#(nSets)));


    // ***** Cache data *****

    // Tags & dirty bits
    BRAM#(t_CACHE_SET_IDX, t_METADATA_VECTOR) cacheMeta <- mkBRAMInitialized(Vector::replicate(tagged Invalid));

    // Values
    Vector#(nWordsPerLine, BRAM_MULTI_READ#(4, t_CACHE_DATA_IDX, t_CACHE_WORD)) cacheData <- replicateM(mkBRAMPseudoMultiRead());

    // LRU hint
    BRAM#(t_CACHE_SET_IDX, t_LRU_LIST) cacheLRU <- mkBRAMInitialized(Vector::genWith(fromInteger));

    // ***** Internal state *****

    Reg#(HASIM_CACHE_STATE) curState <- mkReg(HCST_NORMAL);

    Reg#(Bool) cacheIsEmpty <- mkReg(True);

    // Write data is kept in a heap to avoid passing it around through FIFOs.
    // The heap size limits the number of writes in flight.
    MEMORY_HEAP_IMM#(Bit#(WRITE_DATA_HEAP_IDX_SZ), t_CACHE_WRITE_INFO) reqInfo_writeData <- mkMemoryHeapUnionLUTRAM();

    // Is the cache write back?  If not, never set a dirty bit.  It is then the
    // responsibility of the caller to write values to backing storage.
    Reg#(Bool) writeBackCache <- mkReg(True);

    // Filter for allowing one live operation per cache set.
    COUNTING_FILTER#(t_CACHE_SET_IDX) setFilter <- mkCountingFilter(debugLog);
    COUNTER#(t_CACHE_SET_IDX_SZ) nBusySets <- mkLCounter(0);

    Reg#(Bool) invalidateAllReq <- mkReg(False);

    // ***** Queues between internal pipeline stages *****

    // Incoming requests
    FIFO#(Tuple2#(t_CACHE_REQ_BASE, t_CACHE_REQ)) newReqQ <- mkFIFO();

    // First stage coming out of handleIncomingReq
    FIFO#(Tuple2#(t_CACHE_REQ_BASE, t_CACHE_REQ)) processReqQ0 <- mkFIFO();

    // Hit path for operations that read the cache (read and flush)
    FIFO#(Tuple3#(t_CACHE_REQ_BASE, t_CACHE_REQ, t_CACHE_WORD_VALID_MASK)) readHitQ <- mkFIFO();
    // Side paths, also for read and flush hit.
    FIFO#(t_CACHE_DATA_IDX) cacheReadForHitQ <- mkFIFO();
    FIFO#(t_CACHE_DATA_IDX) cacheReadForFlushReqQ <- mkFIFO();

    // Queues on miss path
    FIFO#(Tuple4#(t_CACHE_REQ_BASE, t_CACHE_REQ, t_LRU_LIST, t_METADATA_VECTOR)) lineMissQ <- mkFIFO();
    FIFO#(Tuple3#(t_CACHE_REQ_BASE, t_CACHE_REQ, t_CACHE_WORD_VALID_MASK)) wordMissQ <- mkFIFO();
    FIFO#(t_CACHE_DATA_IDX) cacheReadForEvictDirtyQ <- mkFIFO();
    FIFO#(Tuple3#(t_CACHE_REQ_BASE, t_CACHE_REQ, t_METADATA)) evictDirtyForFillQ <- mkFIFO1();

    // Fill for read path
    FIFO#(Tuple2#(t_CACHE_REQ_BASE, t_CACHE_REQ)) fillLineRequestQ <- mkFIFO();
    FIFO#(Tuple3#(t_CACHE_REQ_BASE, t_CACHE_REQ, t_CACHE_WORD_VALID_MASK)) fillLineQ <- mkSizedFIFO(16);

    // Write data to an allocated queue entry
    FIFO#(Tuple2#(t_CACHE_REQ_BASE, HASIM_CACHE_WRITE_REQ#(nWordsPerLine))) writeDataQ <- mkFIFO();

    // Wait for ACK from backing store that flush was received
    FIFO#(Tuple2#(t_CACHE_SET_IDX, Maybe#(HASIM_CACHE_INVAL_IDX))) flushAckQ <- mkFIFO();

    // Exit from all paths
    FIFO#(t_CACHE_SET_IDX) doneQ <- mkFIFO();

    // Read responses may be returned either OOO or in request order, depending
    // on the value of permitOOOReadResp.  Define both queues but only one will
    // actually be used.
    FIFOF#(Tuple3#(t_CACHE_REQ_BASE, t_CACHE_LINE, t_CACHE_WORD_VALID_MASK)) readRespToClientQ_OOO <- mkBypassFIFOF();
    SCOREBOARD_FIFO#(HASIM_CACHE_MAX_READ, Tuple3#(t_CACHE_REQ_BASE, t_CACHE_LINE, t_CACHE_WORD_VALID_MASK)) readRespToClientQ_InOrder <- mkScoreboardFIFO();

    // Invalidate and flush requests are always returned in the order they
    // were requested.
    SCOREBOARD_FIFO#(HASIM_CACHE_MAX_INVAL, Bool) invalReqDoneQ <- mkScoreboardFIFO();

    // ***** Indexing functions *****

    //
    // getDataIdx --
    //     Index in the cache data BRAM given a set and way.
    //
    function t_CACHE_DATA_IDX getDataIdx (t_CACHE_SET_IDX set, t_CACHE_WAY_IDX way);
        t_CACHE_DATA_IDX idx;
        idx.set = set;
        idx.way = way;
        return idx;
    endfunction

    //
    // Functions for converting from address to tag and set or vice versa.
    //
    function Tuple2#(t_CACHE_TAG, t_CACHE_SET_IDX) cacheTagAndSet(t_CACHE_ADDR addr);
        return unpack(hashBits(addr));
    endfunction

    function t_CACHE_ADDR cacheAddr(t_CACHE_TAG tag, t_CACHE_SET_IDX set);
        t_CACHE_ADDR hashed_addr = { tag, pack(set) };
        return hashBits_inv(hashed_addr);
    endfunction

    //
    // debugAddr --
    //     Pretty printer for converting cache addresses to system addresses.
    //     Adds trailing 0's that were dropped from cache addresses because they
    //     are inside a cache line.
    //
    function Bit#(TAdd#(t_CACHE_ADDR_SZ, nTagExtraLowBits)) debugAddr(t_CACHE_ADDR addr);
        Bit#(nTagExtraLowBits) zero = 0;
        return { addr, zero };
    endfunction

    function Bit#(TAdd#(t_CACHE_ADDR_SZ, nTagExtraLowBits)) debugAddrFromTag(t_CACHE_TAG tag, t_CACHE_SET_IDX set);
        Bit#(nTagExtraLowBits) zero = 0;
        return { cacheAddr(tag, set), zero };
    endfunction


    // ***** Cache data read requests *****

    //
    // Cache lines may be separated into multiple BRAM words.  These functions
    // access all words in a line.
    //

    function Action cacheDataReadReq(Integer port, t_CACHE_DATA_IDX idx);
    action
        for (Integer b = 0; b < valueOf(nWordsPerLine); b = b + 1)
        begin
            cacheData[b].readPorts[port].readReq(idx);
        end
    endaction
    endfunction

    function ActionValue#(t_CACHE_LINE) cacheDataReadRsp(Integer port);
    actionvalue
        Vector#(nWordsPerLine, t_CACHE_WORD) lineVal;
        for (Integer b = 0; b < valueOf(nWordsPerLine); b = b + 1)
        begin
            let v <- cacheData[b].readPorts[port].readRsp();
            lineVal[b] = v;
        end

        return unpack(pack(lineVal));
    endactionvalue
    endfunction

    function Action cacheDataWrite(t_CACHE_DATA_IDX idx, t_CACHE_LINE v);
    action
        Vector#(nWordsPerLine, t_CACHE_WORD) lineVal = unpack(pack(v));

        for (Integer b = 0; b < valueOf(nWordsPerLine); b = b + 1)
        begin
            cacheData[b].write(idx, lineVal[b]);
        end
    endaction
    endfunction


    // ***** Meta data searches *****

    function t_METADATA metaData(t_CACHE_TAG tag,
                                 Bool dirty,
                                 t_CACHE_WORD_VALID_MASK wordValid);
        t_METADATA meta;
        meta.tag = tag;
        meta.dirty = dirty;
        meta.wordValid = wordValid;
    
        return meta;
    endfunction


    function Maybe#(Tuple2#(t_CACHE_WAY_IDX, t_METADATA)) findWayMatch(t_CACHE_TAG tag, t_METADATA_VECTOR meta);
        Vector#(nWays, Bool) way_match = replicate(False);

        for (Integer w = 0; w < valueOf(nWays); w = w + 1)
        begin
            way_match[w] = case (meta[w]) matches
                               tagged Valid .m: (m.tag == tag);
                               default: False;
                           endcase;
        end

        let way = findElem(True, way_match);
        if (way matches tagged Valid .w)
            return tagged Valid tuple2(w, validValue(meta[w]));
        else
            return tagged Invalid;
    endfunction


    function Bool isInvalid(Maybe#(t) m) = ! isValid(m);


    function Maybe#(t_CACHE_WAY_IDX) findFirstInvalid(t_METADATA_VECTOR meta);
        return findIndex(isInvalid, meta);
    endfunction


    // ***** LRU Management ***** //

    //
    // getLRU --
    //   Least recently used way in a set.
    //
    function t_CACHE_WAY_IDX getLRU(t_LRU_LIST list);
        return list[valueOf(nWays) - 1];
    endfunction


    //
    // getMRU --
    //   Most recently used way in a set.
    //

    function t_CACHE_WAY_IDX getMRU(t_LRU_LIST list);
        return list[0];
    endfunction


    //
    // pushMRU --
    //   Update MRU list, moving a way to the head of the list.
    //
    function t_LRU_LIST pushMRU(t_LRU_LIST curLRU, t_CACHE_WAY_IDX mru);
        t_LRU_LIST new_list = curLRU;
    
        //
        // Find the new MRU value in the current list
        //
        if (findElem(mru, curLRU) matches tagged Valid .mru_pos)
        begin
            //
            // Shift older references out of the MRU slot
            //
            for (t_CACHE_WAY_IDX w = 0; w < mru_pos; w = w + 1)
            begin
                new_list[w + 1] = curLRU[w];
            end

            // MRU is slot 0
            new_list[0] = mru;
        end

        return new_list;
    endfunction



    function Action cacheLRUUpdate(t_CACHE_SET_IDX set,
                                   t_CACHE_WAY_IDX way,
                                   t_LRU_LIST cur_lru);
    action
        let new_lru = pushMRU(cur_lru, way);
        cacheLRU.write(set, new_lru);

        if ((getMRU(cur_lru) != way) || (cur_lru != new_lru))
        begin
            debugLog.record($format("    Update LRU (set=0x%x): %b -> %b", set, cur_lru, new_lru));
        end
        if (getMRU(new_lru) != way)
        begin
            debugLog.record($format("    ***ERROR*** expected MRU to be 0x%x but it is 0x%x", way, getMRU(new_lru)));
        end
    endaction
    endfunction


    // ***** Rules ***** //

    // ====================================================================
    //
    // All incoming requests start here with handleIncomingReq
    //
    // ====================================================================

    //
    // handleIncomingReq --
    //     Only one request may be active per set.  The set filter monitors
    //     active requests to also non-conflicting requests to proceed.
    //
    (* conservative_implicit_conditions *)
    rule handleIncomingReq (curState == HCST_NORMAL && ! invalidateAllReq);
        match {.req_base, .req} = newReqQ.first();

        let success <- setFilter.insert(req_base.set);

        if (success)
        begin
            nBusySets.up();
            newReqQ.deq();

            // Read meta data and LRU hints
            cacheMeta.readReq(req_base.set);
            cacheLRU.readReq(req_base.set);
            
            processReqQ0.enq(tuple2(req_base, req));
        end
    endrule


    // ====================================================================
    //
    // Three stage path for invalidate or flush requests.  First stage
    // looks up the address in the cache.  If the line is present and dirty,
    // the second stage flushes it to the backing storage.  The third
    // stage responds with an ACK that storage is consistent, if requested.
    //
    // ====================================================================

    function Bool reqIsInvalOrFlush(t_CACHE_REQ req);
        if (req matches tagged HCOP_INVAL .needAck)
            return True;
        else if (req matches tagged HCOP_FLUSH_DIRTY .needAck)
            return True;
        else
            return False;
    endfunction

    //
    // handleInvalOrFlush --
    //     Invalidate and flush requests have similar handling.  Both write
    //     back a dirty matching line.  Flush preserves the now clean line
    //     in the cache.
    //
    (* conservative_implicit_conditions *)
    rule handleInvalOrFlush (curState == HCST_NORMAL &&
                             reqIsInvalOrFlush(tpl_2(processReqQ0.first())));

        match {.req_base_in, .req} = processReqQ0.first();
        processReqQ0.deq();

        let meta <- cacheMeta.readRsp();
        let cur_lru <- cacheLRU.readRsp();

        let tag = req_base_in.tag;
        let set = req_base_in.set;

        Maybe#(HASIM_CACHE_INVAL_IDX) need_ack = ?;
        Bool is_inval = ?;

        case (req) matches
        tagged HCOP_INVAL .needACK:
        begin
            need_ack = needACK;
            is_inval = True;
            debugLog.record($format("  Process request: INVAL addr=0x%x, set=0x%x", debugAddrFromTag(tag, set), set));
        end
        tagged HCOP_FLUSH_DIRTY .needACK:
        begin
            need_ack = needACK;
            is_inval = False;
            debugLog.record($format("  Process request: FLUSH addr=0x%x, set=0x%x", debugAddrFromTag(tag, set), set));
        end
        endcase

        Bool found_dirty_line = False;
        let req_base_out = req_base_in;

        if (findWayMatch(tag, meta) matches tagged Valid {.way, .way_meta})
        begin
            if (way_meta.dirty)
            begin
                // Found dirty line.  Prepare for write back.
                req_base_out.way = way;
                cacheReadForFlushReqQ.enq(getDataIdx(set, way));
                readHitQ.enq(tuple3(req_base_out, req, way_meta.wordValid));
                found_dirty_line = True;

                if (! is_inval)
                begin
                    // FLUSH:  Line no longer dirty.  Update meta data.
                    let new_meta = way_meta;
                    new_meta.dirty = False;
                    meta[way] = tagged Valid new_meta;
                end
            end

            if (is_inval)
            begin
                // Invalidate line
                meta[way] = tagged Invalid;
                stats.forceInvalLine();
            end

            cacheMeta.write(set, meta);

            debugLog.record($format("  FLUSH/INVAL HIT %s: addr=0x%x, set=0x%x, way=%0d", (found_dirty_line ? "dirty" : "clean"), debugAddrFromTag(tag, set), set, way));
        end
        
        if (! found_dirty_line)
        begin
            // Line is not dirty.  Done with this request.
            doneQ.enq(set);
            if (need_ack matches tagged Valid .inval_idx)
                invalReqDoneQ.setValue(inval_idx, ?);
        end
    endrule


    //
    // readCacheDataForFlushReq --
    //     There isn't enough time to request the cache data read during way
    //     hit detection in handleInvalOrFlush.  The cache read is requested
    //     here for use in flushDirtyLine.
    //    
    rule readCacheDataForFlushReq (curState == HCST_NORMAL);
        let idx = cacheReadForFlushReqQ.first();
        cacheReadForFlushReqQ.deq();

        cacheDataReadReq(0, idx);
    endrule


    //
    // flushDirtyLine --
    //   Flush a dirty line and continue on to fill, if appropriate.
    //
    rule flushDirtyLine (curState == HCST_NORMAL &&
                         reqIsInvalOrFlush(tpl_2(readHitQ.first())));

        match {.req_base, .req, .word_valid_mask} = readHitQ.first();
        readHitQ.deq();

        let flushData <- cacheDataReadRsp(0);

        let tag = req_base.tag;
        let set = req_base.set;
        let way = req_base.way;

        Maybe#(HASIM_CACHE_INVAL_IDX) need_ack =
            case (req) matches
                tagged HCOP_INVAL .needAck: needAck;
                tagged HCOP_FLUSH_DIRTY .needAck: needAck;
            endcase;

        stats.dirtyLineFlush();
        debugLog.record($format("  Write back DIRTY: addr=0x%x, set=0x%x, mask=0x%x, data=0x%x", debugAddrFromTag(tag, set), set, word_valid_mask, flushData));

        // Flush for invalidate request.  Use sync method to know the
        // data arrived.
        sourceData.writeSyncReq(cacheAddr(tag, set), word_valid_mask, flushData, req_base.refInfo);
        flushAckQ.enq(tuple2(set, need_ack));
    endrule


    //
    // handleFlushACK --
    //   Wait for the response to a flush from back storage for synchronous
    //   flushes.
    //
    rule handleFlushACK (True);
        sourceData.writeSyncWait();

        match { .set, .need_ack } = flushAckQ.first();
        flushAckQ.deq();

        // Done with this flush request.
        doneQ.enq(set);

        if (need_ack matches tagged Valid .inval_idx)
        begin
            invalReqDoneQ.setValue(inval_idx, ?);
            debugLog.record($format("  FLUSH or INVAL done, set=0x%x, invalIdx=%0d", set, inval_idx));
        end
        else
        begin
            debugLog.record($format("  FLUSH or INVAL done, set=0x%x", set));
        end
    endrule


    // ====================================================================
    //
    // Read and Write data path.
    //
    // ====================================================================

    //
    // handleRead --
    //     First unique stage of cache READ path.
    //
    (* conservative_implicit_conditions *)
    rule handleRead (curState == HCST_NORMAL &&&
                     tpl_2(processReqQ0.first()) matches tagged HCOP_READ .rReq);

        match {.req_base_in, .req} = processReqQ0.first();
        processReqQ0.deq();

        let meta <- cacheMeta.readRsp();
        let cur_lru <- cacheLRU.readRsp();

        let tag = req_base_in.tag;
        let set = req_base_in.set;

        debugLog.record($format("  Process request: READ addr=0x%x, set=0x%x", debugAddrFromTag(tag, set), set));

        let req_base_out = req_base_in;

        if (findWayMatch(tag, meta) matches tagged Valid {.way, .way_meta})
        begin
            //
            // Line hit!
            //
            req_base_out.way = way;

            // Update LRU
            cacheLRUUpdate(set, way, cur_lru);

            if (way_meta.wordValid[rReq.wordIdx])
            begin
                // Word hit!
                cacheReadForHitQ.enq(getDataIdx(set, way));
                readHitQ.enq(tuple3(req_base_out, req, way_meta.wordValid));
            end
            else
            begin
                // Line valid but word in line is not.  Fill.
                wordMissQ.enq(tuple3(req_base_out, req, way_meta.wordValid));

                // Mark all words valid in the line.  They will be after
                // the fill completes.
                let meta_upd = meta;
                meta_upd[way] = tagged Valid metaData(tag, way_meta.dirty, replicate(True));
                cacheMeta.write(set, meta_upd);
            end
        end
        else
        begin
            // Miss.
            lineMissQ.enq(tuple4(req_base_out, req, cur_lru, meta));
        end
    endrule


    //
    // handleWrite --
    //     First unique stage of cache WRITE path.
    //
    (* conservative_implicit_conditions *)
    rule handleWrite (curState == HCST_NORMAL &&&
                      tpl_2(processReqQ0.first()) matches tagged HCOP_WRITE .wReq);

        match {.req_base_in, .req} = processReqQ0.first();
        processReqQ0.deq();

        let meta <- cacheMeta.readRsp();
        let cur_lru <- cacheLRU.readRsp();

        let tag = req_base_in.tag;
        let set = req_base_in.set;

        debugLog.record($format("  Process request: WRITE addr=0x%x, set=0x%x", debugAddrFromTag(tag, set), set));

        cacheIsEmpty <= False;
        let req_base_out = req_base_in;

        if (findWayMatch(tag, meta) matches tagged Valid {.way, .way_meta})
        begin
            //
            // Line hit!
            //
            req_base_out.way = way;

            // Update LRU
            cacheLRUUpdate(set, way, cur_lru);

            stats.writeHit();

            // Mark line dirty and word valid
            let new_word_valid = way_meta.wordValid;
            new_word_valid[wReq.wordIdx] = True;

            let meta_upd = meta;
            meta_upd[way] = tagged Valid metaData(tag, writeBackCache, new_word_valid);
            cacheMeta.write(set, meta_upd);

            // Request write to cache
            writeDataQ.enq(tuple2(req_base_out, wReq));
            debugLog.record($format("  Write HIT: addr=0x%x, set=0x%x, way=%0d, mask=0x%x", debugAddrFromTag(tag, set), set, way, new_word_valid));
        end
        else
        begin
            // Miss.
            lineMissQ.enq(tuple4(req_base_out, req, cur_lru, meta));
        end
    endrule



    // ====================================================================
    //
    // Read or write hits end here.
    //
    // ====================================================================

    //
    // readCacheDataForReadHit --
    //     There isn't enough time to request the cache data read during way
    //     hit detection in handleRead.  The cache read is requested here
    //     for use in handleReadCacheHit.
    //    
    rule readCacheDataForReadHit (curState == HCST_NORMAL);
        let idx = cacheReadForHitQ.first();
        cacheReadForHitQ.deq();

        stats.readHit();
        cacheDataReadReq(1, idx);
    endrule


    //
    // handleReadCacheHit --
    //   Forward data coming from cache BRAM from handleRead to back to the requester.
    //
    rule handleReadCacheHit (curState == HCST_NORMAL &&&
                             tpl_2(readHitQ.first()) matches tagged HCOP_READ .rReq);

        match {.req_base, .req, .word_valid_mask} = readHitQ.first();
        readHitQ.deq();

        let v <- cacheDataReadRsp(1);

        let tag = req_base.tag;
        let set = req_base.set;
        let way = req_base.way;

        if (permitOOOReadResp)
            readRespToClientQ_OOO.enq(tuple3(req_base, v, word_valid_mask));
        else
            readRespToClientQ_InOrder.setValue(rReq.readFifoIdx, tuple3(req_base, v, word_valid_mask));

        // Done with this read request
        doneQ.enq(set);

        debugLog.record($format("  Read HIT: addr=0x%x, set=0x%x, way=%0d, mask=0x%x, data=0x%x", debugAddrFromTag(tag, set), set, way, word_valid_mask, v));
    endrule


    //
    // writeCacheData --
    //   All cache writes terminate here, including the line miss path.
    //
    rule writeCacheData (curState == HCST_NORMAL);
        match {.req_base, .w_req} = writeDataQ.first();
        writeDataQ.deq();

        let w_data = reqInfo_writeData.sub(w_req.dataIdx);

        let tag = req_base.tag;
        let set = req_base.set;
        let way = req_base.way;

        cacheData[w_req.wordIdx].write(getDataIdx(set, way), w_data.val);

        debugLog.record($format("  WRITE Word: addr=0x%x, set=0x%x, way=%0d, word=%0d, data=0x%x", debugAddrFromTag(tag, set), set, way, w_req.wordIdx, w_data.val));

        reqInfo_writeData.free(w_req.dataIdx);
        doneQ.enq(set);
    endrule


    // ====================================================================
    //
    // Miss handlers.
    //
    // ====================================================================

    //
    // handleWordMissForRead --
    //     Line is present in the cache but incomplete.  Request the full line
    //     from backing storage and merge it into the line.
    //
    rule handleWordMissForRead (curState == HCST_NORMAL &&&
                                tpl_2(wordMissQ.first()) matches tagged HCOP_READ .rReq);

        match {.req_base, .req, .word_valid_mask} = wordMissQ.first();
        wordMissQ.deq();

        let tag = req_base.tag;
        let set = req_base.set;

        //
        // Miss.  Pick a victim.
        //

        stats.readMiss();

        let addr = cacheAddr(tag, set);
        sourceData.readReq(addr, req_base.refInfo);
        fillLineQ.enq(tuple3(req_base, req, word_valid_mask));

        debugLog.record($format("  READ WORD MISS (FILL): addr=0x%x, set=0x%x, way=%0d", debugAddr(addr), set, req_base.way));
    endrule


    //
    // handleMissForRead --
    //     Pick a victim and prepare to fill a way from backing storage.
    //
    (* conservative_implicit_conditions *)
    rule handleMissForRead (curState == HCST_NORMAL &&&
                            tpl_2(lineMissQ.first()) matches tagged HCOP_READ .rReq);

        match {.req_base_in, .req, .cur_lru, .meta} = lineMissQ.first();
        lineMissQ.deq();

        let tag = req_base_in.tag;
        let set = req_base_in.set;

        stats.readMiss();

        //
        // Pick a fill victim:  either the first invalid or the LRU entry.
        // 
        t_CACHE_WAY_IDX fill_way = getLRU(cur_lru);
        if (findFirstInvalid(meta) matches tagged Valid .inval_way)
        begin
            fill_way = inval_way;
        end

        let req_base_out = req_base_in;
        req_base_out.way = fill_way;

        // Update LRU
        cacheLRUUpdate(set, fill_way, cur_lru);

        //
        // Update metadata here for the filled line since we have the details.
        //
        let meta_upd = meta;
        meta_upd[fill_way] = tagged Valid metaData(tag, False, replicate(True));
        cacheMeta.write(set, meta_upd);

        //
        // Now must figure out the next state...
        //

        // Is victim dirty?
        Bool flushed_dirty = False;
        if (meta[fill_way] matches tagged Valid .m)
        begin
            stats.invalLine();
            if (m.dirty)
            begin
                // Victim is dirty.  Flush data.
                flushed_dirty = True;
                cacheReadForEvictDirtyQ.enq(getDataIdx(set, fill_way));
                evictDirtyForFillQ.enq(tuple3(req_base_out, req, m));

                debugLog.record($format("  READ MISS (FLUSH): addr=0x%x, set=0x%x, way=%0d", debugAddrFromTag(m.tag, set), set, fill_way));
            end
        end

        if (! flushed_dirty)
        begin
            let addr = cacheAddr(tag, set);
            sourceData.readReq(addr, req_base_out.refInfo);
            fillLineQ.enq(tuple3(req_base_out, req, replicate(False)));

            debugLog.record($format("  READ MISS (FILL): addr=0x%x, set=0x%x, way=%0d", debugAddr(addr), set, req_base_out.way));
        end
    endrule


    //
    // handleMissForWrite --
    //     Pick a victim and write back the dirty data, if needed.
    //
    (* conservative_implicit_conditions *)
    rule handleMissForWrite (curState == HCST_NORMAL &&&
                             tpl_2(lineMissQ.first()) matches tagged HCOP_WRITE .wReq);

        match {.req_base_in, .req, .cur_lru, .meta} = lineMissQ.first();
        lineMissQ.deq();

        let tag = req_base_in.tag;
        let set = req_base_in.set;

        stats.writeMiss();

        //
        // Pick a fill victim:  either the first invalid or the LRU entry.
        // 
        t_CACHE_WAY_IDX fill_way = getLRU(cur_lru);
        if (findFirstInvalid(meta) matches tagged Valid .inval_way)
        begin
            fill_way = inval_way;
        end

        let req_base_out = req_base_in;
        req_base_out.way = fill_way;

        // Update LRU
        cacheLRUUpdate(set, fill_way, cur_lru);

        //
        // Update metadata here for the filled line since we have the details.
        //
        
        // The full line will not be filled from memory for a write.  Only
        // mark the word being written valid.
        t_CACHE_WORD_VALID_MASK word_valid_mask = replicate(False);
        word_valid_mask[wReq.wordIdx] = True;

        // Update tag and write metadata
        let meta_upd = meta;
        meta_upd[fill_way] = tagged Valid metaData(tag, writeBackCache, word_valid_mask);
        cacheMeta.write(set, meta_upd);

        //
        // Now must figure out the next state...
        //

        // Is victim dirty?
        Bool flushed_dirty = False;
        if (meta[fill_way] matches tagged Valid .m)
        begin
            stats.invalLine();
            if (m.dirty)
            begin
                // Victim is dirty.  Flush data.
                flushed_dirty = True;
                cacheReadForEvictDirtyQ.enq(getDataIdx(set, fill_way));
                evictDirtyForFillQ.enq(tuple3(req_base_out, req, m));

                debugLog.record($format("  WRITE MISS (FLUSH): addr=0x%x, set=0x%x, way=%0d", debugAddrFromTag(m.tag, set), set, fill_way));
            end
        end

        if (! flushed_dirty)
        begin
            // Writing does not require a fill.  Ready now.
            writeDataQ.enq(tuple2(req_base_out, wReq));
            debugLog.record($format("  Write to INVAL: addr=0x%x, set=0x%x, way=%0d", debugAddr(cacheAddr(tag, set)), set, fill_way));
        end
    endrule


    //
    // readCacheDataForEvict --
    //     There isn't enough time to request the cache data read during way
    //     victim selection in flushDirtyForRead and flushDirtyForWrite.  The
    //     cache read is requested here for use in flushDirtyForFill.
    //    
    rule readCacheDataForEvict (curState == HCST_NORMAL);
        let idx = cacheReadForEvictDirtyQ.first();
        cacheReadForEvictDirtyQ.deq();

        cacheDataReadReq(2, idx);
    endrule


    //
    // evictDirtyForFill --
    //   Flush a dirty line and continue on to fill, if appropriate.
    //
    rule evictDirtyForFill (curState == HCST_NORMAL);
        match {.req_base, .req, .flush_meta} = evictDirtyForFillQ.first();
        evictDirtyForFillQ.deq();

        let flush_data <- cacheDataReadRsp(2);

        let set = req_base.set;
        let way = req_base.way;

        stats.dirtyLineFlush();
        debugLog.record($format("  Write back DIRTY: addr=0x%x, set=0x%x, way=%0d, mask=0x%x, data=0x%x", debugAddrFromTag(flush_meta.tag, set), set, way, flush_meta.wordValid, flush_data));

        // Normal flush before a fill
        sourceData.write(cacheAddr(flush_meta.tag, set), flush_meta.wordValid, flush_data, req_base.refInfo);

        if (req matches tagged HCOP_WRITE .wReq)
        begin
            // WRITE: Line is empty and ready to receive write data.
            writeDataQ.enq(tuple2(req_base, wReq));
        end
        else
        begin
            // READ: Pass the request on to the fill stage.
            fillLineRequestQ.enq(tuple2(req_base, req));
        end
    endrule


    rule sendFillRequest (curState == HCST_NORMAL);
        match {.req_base, .req} = fillLineRequestQ.first();
        fillLineRequestQ.deq();

        let tag = req_base.tag;
        let set = req_base.set;
        let way = req_base.way;

        let addr = cacheAddr(tag, set);
        sourceData.readReq(addr, req_base.refInfo);
        fillLineQ.enq(tuple3(req_base, req, replicate(False)));
    endrule


    //
    // handleFillForRead --
    //    Update the cache with requested data coming back from memory.
    //
    rule handleFillForRead (curState == HCST_NORMAL &&&
                            tpl_2(fillLineQ.first()) matches tagged HCOP_READ .rReq);

        match {.req_base, .req, .cur_word_valid_mask} = fillLineQ.first();
        fillLineQ.deq();

        let v <- sourceData.readResp();

        let tag = req_base.tag;
        let set = req_base.set;
        let way = req_base.way;

        // Cache the new values.  Don't overwrite entries that are currently
        // valid, since they may be dirty.
        t_CACHE_WORD_VALID_MASK ret_valid_words;
        Vector#(nWordsPerLine, t_CACHE_WORD) lineWords = unpack(pack(v));
        for (Integer w = 0; w < valueOf(nWordsPerLine); w = w + 1)
        begin
            if (! cur_word_valid_mask[w])
            begin
                cacheData[w].write(getDataIdx(set, way), lineWords[w]);
            end
            
            // On return only claim that the newly filled lines are valid.
            // We could retrieve the entire line but that would take another
            // stage and more wires to read the dirty data from the cache.
            ret_valid_words[w] = ! cur_word_valid_mask[w];
        end

        if (permitOOOReadResp)
        begin
            readRespToClientQ_OOO.enq(tuple3(req_base, v, ret_valid_words));
            debugLog.record($format("  Read FILL: addr=0x%x, set=0x%x, way=%0d, mask=0x%x, data=0x%x", debugAddrFromTag(tag, set), set, way, ret_valid_words, v));
        end
        else
        begin
            readRespToClientQ_InOrder.setValue(rReq.readFifoIdx, tuple3(req_base, v, ret_valid_words));
            debugLog.record($format("  Read FILL: addr=0x%x, set=0x%x, way=%0d, mask=0x%x, idx=%d, data=0x%x", debugAddrFromTag(tag, set), set, way, ret_valid_words, rReq.readFifoIdx, v));
        end

        doneQ.enq(set);
    endrule


    // ====================================================================
    //
    //   End of reference.
    //
    // ====================================================================

    //
    // doneWithRef --
    //     All access paths terminate here.
    //
    rule doneWithRef (curState == HCST_NORMAL);
        let set = doneQ.first();
        doneQ.deq();

        nBusySets.down();
        setFilter.remove(set);
    endrule


    // ====================================================================
    //
    //   Invalidate ALL support (clear entire cache).
    //
    // ====================================================================

    FIFO#(Tuple3#(t_CACHE_SET_IDX, t_METADATA_VECTOR, Bool)) invalAllFlushSetQ <- mkFIFO();
    FIFO#(Tuple3#(t_CACHE_TAG, t_CACHE_SET_IDX, t_CACHE_WORD_VALID_MASK)) invalAllFlushLineQ <- mkFIFO();

    // State for invalidate all
    Reg#(Bool)             invalidatingAllLastSet  <- mkReg(False);
    Reg#(t_CACHE_SET_IDX)  invalidateAllSet <- mkReg(0);
    Reg#(t_CACHE_WAY_IDX)  invalidateFlushWay <- mkReg(0);

    Reg#(t_CACHE_REF_INFO) invalidateAll_refInfo <- mkRegU();

    //
    // invalAllWait --
    //     Wait for cache to be idle before starting an invalidate all.
    //
    rule handleInvalAllReq (invalidateAllReq &&
                            curState == HCST_NORMAL &&
                            (nBusySets.value() == 0));

        debugLog.record($format("  Start INVAL ALL"));

        invalidateAllReq <= False;
        invalidatingAllLastSet <= False;

        if (cacheIsEmpty)
        begin
            curState <= HCST_INVAL_ALL_DONE;
        end
        else
        begin
            curState <= HCST_INVAL_ALL;
            cacheMeta.readReq(0);
            cacheIsEmpty <= True;
        end
    endrule


    //
    // handleInvalidateAll --
    //     Memory system may request invalidation of the entire cache if it
    //     doesn't know which lines may need to be flushed.
    //
    rule handleInvalidateAll ((curState == HCST_INVAL_ALL) && ! invalidatingAllLastSet);
        cacheLRU.write(invalidateAllSet, Vector::genWith(fromInteger));
        cacheMeta.write(invalidateAllSet, Vector::replicate(tagged Invalid));

        // Flush dirty lines
        let meta <- cacheMeta.readRsp();
        let done = (invalidateAllSet == maxBound);
        invalAllFlushSetQ.enq(tuple3(invalidateAllSet, meta, done));

        if (done)
        begin
            invalidatingAllLastSet <= True;
        end
        else
        begin
            cacheMeta.readReq(invalidateAllSet);
        end

        invalidateAllSet <= invalidateAllSet + 1;
    endrule


    // Not required for correctness: get rid of warning messages...
    (* descending_urgency = "writeCacheData, handleFlushACK, flushDirtyLine, handleFillForRead, evictDirtyForFill, handleWordMissForRead, handleMissForRead, handleMissForWrite, handleReadCacheHit, readCacheDataForEvict, readCacheDataForReadHit, readCacheDataForFlushReq, handleRead, handleWrite, handleInvalOrFlush, handleIncomingReq, flushDirtyLineForInvalAll, invalSetForInvalAll, handleInvalidateAll, handleInvalAllReq" *)


    //
    // invalSetForInvalAll --
    //   Invalidate an entire set (requested by handleInvalidateAll).
    //
    (* conservative_implicit_conditions *)
    rule invalSetForInvalAll (curState == HCST_INVAL_ALL);
        match {.set, .meta, .last_set} = invalAllFlushSetQ.first();
        
        if (meta[invalidateFlushWay] matches tagged Valid .m &&& m.dirty)
        begin
            invalAllFlushLineQ.enq(tuple3(m.tag, set, m.wordValid));
            cacheDataReadReq(3, getDataIdx(set, invalidateFlushWay));
        end

        // Done with the set?
        if (invalidateFlushWay == maxBound)
        begin
            // Done.  Pass the request on to the fill stage, if appropriate.
            invalAllFlushSetQ.deq();
            
            // Done with invalidateingAll?
            if (last_set)
            begin
                curState <= HCST_INVAL_ALL_DONE;
                debugLog.record($format("  Request done: INVAL ALL"));
            end
        end

        invalidateFlushWay <= invalidateFlushWay + 1;
    endrule


    //
    // flushDirtyLineForInvalAll --
    //     Flush one dirty line, requested by invalSetForInvalAll.
    //
    rule flushDirtyLineForInvalAll (True);
        match { .tag, .set, .word_valid_mask } = invalAllFlushLineQ.first();
        invalAllFlushLineQ.deq();

        let flush_data <- cacheDataReadRsp(3);
        sourceData.write(cacheAddr(tag, set), word_valid_mask, flush_data, invalidateAll_refInfo);

        stats.dirtyLineFlush();
        debugLog.record($format("  Write back DIRTY: addr=0x%x, set=0x%x, mask=0x%x, data=0x%x", debugAddrFromTag(tag, set), set, word_valid_mask, flush_data));
    endrule


    // ====================================================================
    //
    //   Incoming cache requests (methods)
    //
    // ====================================================================

    //
    // genRequest --
    //     This function is used by most of the request methods to generate
    //     the internal data structure for managing a request.  It also starts
    //     the first step:  reading metadata from BRAM.
    //
    function ActionValue#(t_CACHE_SET_IDX) genRequest(t_CACHE_REQ req,
                                                      t_CACHE_ADDR addr,
                                                      t_CACHE_REF_INFO refInfo);
    actionvalue
        match {.tag, .set} = cacheTagAndSet(addr);

        t_CACHE_REQ_BASE req_base;
        req_base.tag = tag;
        req_base.set = set;
        req_base.way = ?;  // Way won't be known until the set meta data is read
        req_base.refInfo = refInfo;
        
        newReqQ.enq(tuple2(req_base, req));

        return set;
    endactionvalue
    endfunction


    //
    // readReq -- Read a full line.  Fetch from backing store if not in the cache.
    //
    method Action readReq(t_CACHE_ADDR addr,
                          Bit#(TLog#(nWordsPerLine)) wordIdx,
                          t_CACHE_REF_INFO refInfo) if (curState == HCST_NORMAL);
        //
        // If resonses are supposed to be returned in order than allocate a slot
        // in the response queue.
        //
        HASIM_CACHE_READ_FIFO_IDX readIdx = ?;
        if (! permitOOOReadResp)
        begin
            readIdx <- readRespToClientQ_InOrder.enq();
        end

        HASIM_CACHE_READ_REQ#(nWordsPerLine) req;
        req.wordIdx = wordIdx;
        req.readFifoIdx = readIdx;
    
        let set <- genRequest(tagged HCOP_READ req, addr, refInfo);
        if (permitOOOReadResp)
            debugLog.record($format("  New request: READ addr=0x%x, set=0x%x, word=%0d", debugAddr(addr), set, wordIdx));
        else
            debugLog.record($format("  New request: READ addr=0x%x, set=0x%x, word=%0d, readIdx=%0d", debugAddr(addr), set, wordIdx, readIdx));
    endmethod

    method ActionValue#(t_CACHE_LOAD_RESP) readResp();
        //
        // Only one read response queue is actually used, depending on the
        // value of permitOOOReadResp.
        //
        t_CACHE_REQ_BASE req_base;
        Vector#(nWordsPerLine, t_CACHE_WORD) value;
        t_CACHE_WORD_VALID_MASK valid_words;    

        if (permitOOOReadResp)
        begin
            match {.rb, .v, .word_mask} = readRespToClientQ_OOO.first();
            readRespToClientQ_OOO.deq();
            req_base = rb;
            value = unpack(pack(v));
            valid_words = word_mask;
        end
        else
        begin
            match {.rb, .v, .word_mask} = readRespToClientQ_InOrder.first();
            readRespToClientQ_InOrder.deq();
            req_base = rb;
            value = unpack(pack(v));
            valid_words = word_mask;
        end

        t_CACHE_LOAD_RESP rsp;
        for (Integer w = 0; w < valueOf(nWordsPerLine); w = w + 1)
            rsp.words[w] = valid_words[w] ? tagged Valid value[w] : tagged Invalid;
        rsp.addr = cacheAddr(req_base.tag, req_base.set);
        rsp.refInfo = req_base.refInfo;

        return rsp;
    endmethod

    method Bool readRespReady();
        if (permitOOOReadResp)
            return readRespToClientQ_OOO.notEmpty();
        else
            return readRespToClientQ_InOrder.notEmpty();
    endmethod

    //
    // write -- Write a word to a line.
    //
    method Action write(t_CACHE_ADDR addr, t_CACHE_WORD val, t_CACHE_WRITE_WORD_IDX wordIdx, t_CACHE_REF_INFO refInfo) if (curState == HCST_NORMAL);
        t_CACHE_WRITE_INFO w_info;
        w_info.val = val;

        let h <- reqInfo_writeData.malloc();
        reqInfo_writeData.upd(h, w_info);

        HASIM_CACHE_WRITE_REQ#(nWordsPerLine) w_req;
        w_req.wordIdx = wordIdx;    
        w_req.dataIdx = h;

        let set <- genRequest(tagged HCOP_WRITE w_req, addr, refInfo);

        debugLog.record($format("  New request: WRITE addr=0x%x, set=0x%x, data=0x%x, word=%0d, wData heap=%0d", debugAddr(addr), set, val, wordIdx, h));
    endmethod


    //
    // invalReq -- Invalidate (remove) a line from the cache
    //
    method Action invalReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo) if (curState == HCST_NORMAL);
        if (sendAck)
        begin
            let idx <- invalReqDoneQ.enq();
            let set <- genRequest(tagged HCOP_INVAL tagged Valid idx, addr, refInfo);

            debugLog.record($format("  New request: INVAL addr=0x%x, set=0x%x, invalIdx=%d", debugAddr(addr), set, idx));
        end
        else
        begin
            let set <- genRequest(tagged HCOP_INVAL tagged Invalid, addr, refInfo);

            debugLog.record($format("  New request: INVAL addr=0x%x, set=0x%x", debugAddr(addr), set));
        end
    endmethod
    

    //
    // flushReq --
    //     Flush (write back) a line from the cache but keep the line cached.
    //
    method Action flushReq(t_CACHE_ADDR addr, Bool sendAck, t_CACHE_REF_INFO refInfo) if (curState == HCST_NORMAL);
        if (sendAck)
        begin
            let idx <- invalReqDoneQ.enq();
            let set <- genRequest(tagged HCOP_FLUSH_DIRTY tagged Valid idx, addr, refInfo);

            debugLog.record($format("  New request: FLUSH addr=0x%x, set=0x%x, invalIdx=%d", debugAddr(addr), set, idx));
        end
        else
        begin
            let set <- genRequest(tagged HCOP_FLUSH_DIRTY tagged Invalid, addr, refInfo);

            debugLog.record($format("  New request: FLUSH addr=0x%x, set=0x%x", debugAddr(addr), set));
        end
    endmethod


    //
    // invalOrFlushWait -- Block until an inval or flush request completes.
    //
    method Action invalOrFlushWait();
        invalReqDoneQ.deq();
    endmethod


    //
    // invalAllReq -- Invalidate entire cache.  Write back dirty lines.
    //
    method Action invalAllReq(t_CACHE_REF_INFO refInfo) if (! invalidateAllReq);
        debugLog.record($format("  New request: INVAL ALL"));
        invalidateAll_refInfo <= refInfo;
        invalidateAllReq <= True;
    endmethod

    method Action invalAllWait() if (curState == HCST_INVAL_ALL_DONE);
        curState <= HCST_NORMAL;
    endmethod

    //
    // setModeWriteBack -- Write back or write through cache config.
    //
    method Action setModeWriteBack(Bool isWriteBack);
        if (writeBackCache != isWriteBack)
            debugLog.record($format("Cache mode: WRITE %s", (isWriteBack ? "BACK" : "THROUGH")));

        writeBackCache <= isWriteBack;
    endmethod

endmodule


// ===================================================================
//
// Null version of HASIM_CACHE_STATS interface for clients not interested in
// statistics.
//
// ===================================================================

module mkNullHAsimCacheStats
    // interface:
        (HASIM_CACHE_STATS);
    
    method Action readHit();
    endmethod

    method Action readMiss();
    endmethod

    method Action writeHit();
    endmethod

    method Action writeMiss();
    endmethod

    method Action invalLine();
    endmethod

    method Action dirtyLineFlush();
    endmethod

    method Action forceInvalLine();
    endmethod

endmodule
