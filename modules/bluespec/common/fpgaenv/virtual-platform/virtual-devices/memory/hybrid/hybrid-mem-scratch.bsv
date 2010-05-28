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
// Scratchpad memory using the hosts's memory as the backing storage.
//

import FIFO::*;
import FIFOF::*;
import Vector::*;

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/local_mem.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/central_cache.bsh"
`include "asim/provides/fpga_components.bsh"
`include "asim/provides/librl_bsv_storage.bsh"
`include "asim/provides/scratchpad_memory_common.bsh"

`include "asim/rrr/service_ids.bsh"
`include "asim/rrr/client_stub_SCRATCHPAD_MEMORY.bsh"
`include "asim/rrr/server_stub_SCRATCHPAD_MEMORY.bsh"
`include "asim/dict/VDEV_CACHE.bsh"


//
// Scratchpad memory address and value.  Value size and words per line must
// match local memory and the central cache.
//
typedef Bit#(`SCRATCHPAD_MEMORY_ADDR_BITS) SCRATCHPAD_MEM_ADDRESS;

typedef LOCAL_MEM_WORD SCRATCHPAD_MEM_VALUE;
typedef LOCAL_MEM_WORD_SZ SCRATCHPAD_MEM_VALUE_SZ;
typedef LOCAL_MEM_WORD_MASK SCRATCHPAD_MEM_MASK;

// Number of scratchpad words in a line.  The line is the basic I/O size
// for RRR messages and caching of scratchpad values.
typedef LOCAL_MEM_WORDS_PER_LINE SCRATCHPAD_WORDS_PER_LINE;
typedef LOCAL_MEM_WORD_IDX SCRATCHPAD_WORD_IDX;


// Host scratchpad addresses are 64 bits
typedef Bit#(64) HOST_SCRATCHPAD_ADDR;

typedef SCRATCHPAD_MEMORY_VIRTUAL_DEVICE#(SCRATCHPAD_MEM_ADDRESS,
                                          SCRATCHPAD_MEM_VALUE,
                                          SCRATCHPAD_MEM_MASK) SCRATCHPAD_MEMORY_VDEV;


//
// Internal types
//

typedef struct
{
    SCRATCHPAD_MEM_ADDRESS addr;
    SCRATCHPAD_MEM_MASK byteMask;
    SCRATCHPAD_REF_INFO refInfo;
}
SCRATCHPAD_HYBRID_READ_REQ
    deriving (Eq, Bits);

typedef struct
{
    SCRATCHPAD_MEM_ADDRESS addr;
    SCRATCHPAD_MEM_VALUE val;
    SCRATCHPAD_MEM_MASK byteMask;
    SCRATCHPAD_PORT_NUM port;
}
SCRATCHPAD_HYBRID_WRITE_REQ
    deriving (Eq, Bits);

typedef union tagged
{
    SCRATCHPAD_HYBRID_READ_REQ  SCRATCHPAD_HYBRID_READ;
    SCRATCHPAD_HYBRID_WRITE_REQ SCRATCHPAD_HYBRID_WRITE;
}
SCRATCHPAD_HYBRID_REQ
    deriving (Eq, Bits);

typedef struct
{
    Bool fromCentralCache;

    // For streaming, uncached reads:  this request is from the same line
    // as the previous read.  Use the last line buffer instead of consuming
    // a read response from the host.
    Bool mergedWithLastLineReq;

    SCRATCHPAD_WORD_IDX wordIdx;
    SCRATCHPAD_MEM_ADDRESS addr;
    SCRATCHPAD_REF_INFO refInfo;
}
SCRATCHPAD_HYBRID_READ_INFO
    deriving (Eq, Bits);

//
// mkMemoryVirtualDevice --
//     Build a device interface with the requested number of ports.
//
module mkMemoryVirtualDevice#(LowLevelPlatformInterface llpi,
                              CENTRAL_CACHE_IFC centralCache)
    // interface:
    (SCRATCHPAD_MEMORY_VDEV)
    provisos (Bits#(SCRATCHPAD_MEM_ADDRESS, t_SCRATCHPAD_MEM_ADDRESS_SZ),
              Bits#(SCRATCHPAD_MEM_MASK, t_SCRATCHPAD_MEM_MASK_SZ),
              Log#(SCRATCHPAD_WORDS_PER_LINE, t_WORD_IDX_SZ),
              Add#(t_WORD_IDX_SZ, t_LINE_ADDR_SZ, `SCRATCHPAD_MEMORY_ADDR_BITS),

              Alias#(Bit#(t_LINE_ADDR_SZ), t_LINE_ADDR),
              Alias#(Bit#(t_WORD_IDX_SZ), t_WORD_IDX),

              Alias#(Vector#(SCRATCHPAD_WORDS_PER_LINE, SCRATCHPAD_MEM_VALUE), t_SCRATCHPAD_LINE),
              Alias#(Vector#(SCRATCHPAD_WORDS_PER_LINE, SCRATCHPAD_MEM_MASK), t_SCRATCHPAD_LINE_MASK));

    DEBUG_FILE debugLog <- (`SCRATCHPAD_MEMORY_DEBUG_ENABLE == 1)?
                           mkDebugFile("memory_scratchpad.out"):
                           mkDebugFileNull("memory_scratchpad.out");  

    ClientStub_SCRATCHPAD_MEMORY scratchpad_rrr <- mkClientStub_SCRATCHPAD_MEMORY(llpi.rrrClient);

    //
    // Port state
    //

    // Scratchpads may delcare that they don't use the central cache
    Reg#(Vector#(SCRATCHPAD_N_CLIENTS, Bool)) portUsesCentralCache <- mkRegU();

    //
    // Scratchpad's central cache port
    //
    let centralCachePort = centralCache.clientPorts[`VDEV_CACHE_SCRATCH - `VDEV_CACHE__BASE];

    // Meta-data for outstanding reads from the host
    NumTypeParam#(1024) reqInfoEntries = ?;
    FIFO#(SCRATCHPAD_HYBRID_READ_INFO) readReqInfoQ <- mkSizedBRAMFIFO(reqInfoEntries);

    FIFOF#(Tuple3#(SCRATCHPAD_MEM_ADDRESS,
                   SCRATCHPAD_MEM_VALUE,
                   SCRATCHPAD_REF_INFO)) uncachedReadRspQ <- mkLFIFOF();

    // ====================================================================
    //
    // Address manipulation functions.
    //
    // ====================================================================

    //
    // scratchpadLineAddr --
    //     Line of scratchpad address, dropping the word index.
    //
    function t_LINE_ADDR scratchpadLineAddr(SCRATCHPAD_MEM_ADDRESS addr);
        Tuple2#(t_LINE_ADDR, t_WORD_IDX) t = unpack(addr);
        return tpl_1(t);
    endfunction

    //
    // scratchpadWordIdx --
    //     Word index within a scratchpad line.
    //
    function SCRATCHPAD_WORD_IDX scratchpadWordIdx(SCRATCHPAD_MEM_ADDRESS addr);
        Tuple2#(t_LINE_ADDR, t_WORD_IDX) t = unpack(addr);
        return tpl_2(t);
    endfunction


    //
    // makeCacheAddr --
    //     Compute the cache line given a port and address within a region.
    //
    function Tuple2#(CENTRAL_CACHE_LINE_ADDR, SCRATCHPAD_WORD_IDX) makeCacheAddr(SCRATCHPAD_PORT_NUM port, SCRATCHPAD_MEM_ADDRESS addr);
        // Split incoming address into line and word index
        let l_addr = scratchpadLineAddr(addr);
        let w_idx = scratchpadWordIdx(addr);

        // Host address is the concatenation of the port ID and the line
        // address within the region.
        CENTRAL_CACHE_LINE_ADDR c_addr = zeroExtend({port, l_addr});
    
        return tuple2(c_addr, w_idx);
    endfunction


    //
    // makeScratchpadAddr --
    //     The inverse of makeCacheAddr.  Compute a scratchpad word address given
    //     a cache line address and word index.
    //
    function SCRATCHPAD_MEM_ADDRESS makeScratchpadAddr(CENTRAL_CACHE_LINE_ADDR cAddr, Bit#(t_WORD_IDX_SZ) wIdx);
        // Drop the port ID from the line address
        Bit#(t_LINE_ADDR_SZ) l_addr = truncate(cAddr);

        // Make the address a word address
        return {l_addr, wIdx};
    endfunction


    function Bit#(64) hostAddrFromLineAddr(SCRATCHPAD_PORT_NUM port, t_LINE_ADDR addr);
        Bit#(t_WORD_IDX_SZ) w_zero = 0;
        return zeroExtend({port, addr, w_zero});
    endfunction


    //
    // hostAddrFromCacheAddr --
    //     Compute the host scratchpad address given a central cache line address.
    //     Host scratchpad addresses are word-based, so adding low bits to the
    //     cache line address converts to the proper address.
    //
    function Bit#(64) hostAddrFromCacheAddr(CENTRAL_CACHE_LINE_ADDR cAddr);
        Bit#(t_WORD_IDX_SZ) w_zero = 0;

        // We don't know here whether the central cache line address size is
        // larger or smaller than 64 bits.  The following sequence keeps
        // Bluespec happy and should do the right thing.
        Bit#(128) tmp = zeroExtend({cAddr, w_zero});
        Bit#(64) host_addr = truncate(tmp);

        return host_addr;
    endfunction


    //
    // maskmoveqMask --
    //     The x86 SSE maskmovq instruction writes a masked set of 8 bytes
    //     to memory, which is almost exactly what we want.  The problem is
    //     it uses the high bit of each byte in a 64 bit mask instead of
    //     a packed set of low bits.  This function sets up the high 4
    //     bits in each byte, corresponding to the 4 words in a line.
    //     The host side will use the mask as it is for the first word,
    //     shift the mask left 1, use the shifted mask for the second
    //     word, etc.
    //
    function Bit#(64) maskmovqMask(t_SCRATCHPAD_LINE_MASK mask);
        Bit#(64) out_mask = 0;
        for (Integer w = 0; w < valueOf(SCRATCHPAD_WORDS_PER_LINE); w = w + 1)
        begin
            for (Integer b = 0; b < valueOf(t_SCRATCHPAD_MEM_MASK_SZ); b = b + 1)
            begin
                out_mask[b * 8 + 7 - w] = pack(mask[w][b]);
            end
        end

        return out_mask;
    endfunction


    function Bool maskIsSet(SCRATCHPAD_MEM_MASK m) = (pack(m) != 0);

    //
    // storeLine --
    //     Emit a line to the host, sending as little data as possible.
    //
    function Action storeLine(t_SCRATCHPAD_LINE_MASK mask,
                              Bit#(64) hostAddr,
                              t_SCRATCHPAD_LINE val);
    action
        if (countIf(maskIsSet, mask) != 1)
        begin
            //
            // More than one word is changed.  Write the whole line.
            //
            scratchpad_rrr.makeRequest_StoreLine(maskmovqMask(mask),
                                                 hostAddr,
                                                 val[3],
                                                 val[2],
                                                 val[1],
                                                 val[0]);
        end
        else
        begin
            //
            // Only one word is changed.  Just write the word.
            //
            let idx = validValue(findIndex(maskIsSet, mask));

            t_SCRATCHPAD_LINE_MASK w_mask = replicate(replicate(False));
            w_mask[0] = mask[idx];

            scratchpad_rrr.makeRequest_StoreWord(maskmovqMask(w_mask),
                                                 hostAddr | zeroExtend(pack(idx)),
                                                 val[idx]);
        end
    endaction
    endfunction


    // ====================================================================
    //
    // Initialization.
    //
    // ====================================================================
    
    // FIFO1 because it isn't worth the space to pipeline initialization.
    FIFOF#(Tuple3#(SCRATCHPAD_PORT_NUM, SCRATCHPAD_MEM_ADDRESS, Bool)) initQ <- mkFIFOF1();

    rule initRegion (True);
        match {.port, .alloc_last_word_idx, .use_central_cache} = initQ.first();
        initQ.deq();

        portUsesCentralCache[port] <= use_central_cache;
        scratchpad_rrr.makeRequest_InitRegion(zeroExtend(port), alloc_last_word_idx);
    endrule


    // ====================================================================
    //
    // Rules for consuming requests from the central cache to communicate
    // with the backing storage.  Forward requests through RRR to the host.
    //
    // ====================================================================

    let centralCacheBackingPort = centralCache.backingPorts[`VDEV_CACHE_SCRATCH - `VDEV_CACHE__BASE];


    rule backingReadReq (! initQ.notEmpty());
        let r <- centralCacheBackingPort.getReadReq();
        let h_addr = hostAddrFromCacheAddr(r.addr);
        debugLog.record($format("backingReadReq: addr=0x%x", h_addr));

        scratchpad_rrr.makeRequest_LoadLine(h_addr);

        SCRATCHPAD_HYBRID_READ_INFO info = ?;
        info.fromCentralCache = True;
        readReqInfoQ.enq(info);
    endrule

    Reg#(Bit#(TLog#(SCRATCHPAD_WORDS_PER_LINE))) readWordIdx <- mkReg(0);

    rule backingReadResp (readReqInfoQ.first().fromCentralCache);
        // Pick a word from the current incoming value.  Pop the entry if on
        // the last word.
        OUT_TYPE_LoadLine r;
        if (readWordIdx == maxBound)
        begin
            r <- scratchpad_rrr.getResponse_LoadLine();
            readReqInfoQ.deq();
        end
        else
        begin
            r = scratchpad_rrr.peekResponse_LoadLine();
        end

        t_SCRATCHPAD_LINE line;
        line[0] = r.data0;
        line[1] = r.data1;
        line[2] = r.data2;
        line[3] = r.data3;

        let v = line[readWordIdx];
        readWordIdx <= readWordIdx + 1;

        debugLog.record($format("backingReadResp: val=0x%x", pack(v)));
        centralCacheBackingPort.sendReadResp(pack(v));
    endrule

    //
    // Writes are pipelined.  First with a control message and then with data.
    // The cache guarantees they messages come in the right order.
    //
    FIFO#(CENTRAL_CACHE_BACKING_WRITE_REQ) writeCtrlQ <- mkFIFO();
    Reg#(t_SCRATCHPAD_LINE) writeData <- mkRegU();
    Reg#(Bit#(TLog#(SCRATCHPAD_WORDS_PER_LINE))) writeWordIdx <- mkReg(0);

    rule backingWriteCtrlReq (True);
        let r <- centralCacheBackingPort.getWriteReq();
        let h_addr = hostAddrFromCacheAddr(r.addr);
        debugLog.record($format("backingWriteReq: addr=0x%x, wMask=0x%x", h_addr, r.wordValidMask));

        writeCtrlQ.enq(r);
    endrule

    rule backingWriteDataReq (! initQ.notEmpty());
        let v <- centralCacheBackingPort.getWriteData();
        debugLog.record($format("backingWriteData: val=0x%x", v));

        if (writeWordIdx != maxBound)
        begin
            writeData[writeWordIdx] <= v;
        end
        else
        begin
            let ctrl = writeCtrlQ.first();
            writeCtrlQ.deq();

            let h_addr = hostAddrFromCacheAddr(ctrl.addr);

            // Convert word-based valid mask to byte-based
            t_SCRATCHPAD_LINE_MASK mask = newVector();
            for (Integer w = 0; w < valueOf(SCRATCHPAD_WORDS_PER_LINE); w = w + 1)
            begin
                mask[w] = ctrl.wordValidMask[w] ? replicate(True) : replicate(False);
            end

            let w_data = writeData;
            w_data[3] = v;
            storeLine(mask, h_addr, w_data);
        end

        writeWordIdx <= writeWordIdx + 1;
    endrule



    // ====================================================================
    //
    // Uncached reads and writes.  These references bypass the central
    // cache.
    //
    // ====================================================================

    // Uncached read and write requests share a FIFO to enforce ordering.
    FIFO#(SCRATCHPAD_HYBRID_REQ) uncachedReqQ <- mkFIFO();

    //
    // One line write buffer for each port to catch streaming writes
    //

    // Addresses
    LUTRAM_MULTI_READ#(1, SCRATCHPAD_PORT_NUM, Maybe#(t_LINE_ADDR)) uncachedStoreBufAddr <- mkMultiReadLUTRAM(tagged Invalid);
    // Data and masks
    Vector#(SCRATCHPAD_WORDS_PER_LINE,
            LUTRAM_MULTI_READ#(1, SCRATCHPAD_PORT_NUM,
                               Tuple2#(SCRATCHPAD_MEM_VALUE,
                                       SCRATCHPAD_MEM_MASK))) uncachedStoreBuf <-
        replicateM(mkMultiReadLUTRAMU());

    //
    // One line read cache to catch streaming reads.
    //
    LUTRAM_MULTI_READ#(1, SCRATCHPAD_PORT_NUM, Maybe#(t_LINE_ADDR)) uncachedLastReadAddr <- mkMultiReadLUTRAM(tagged Invalid);
    // Data
    LUTRAM_MULTI_READ#(1, SCRATCHPAD_PORT_NUM,
                       t_SCRATCHPAD_LINE) uncachedLastReadBuf <- mkMultiReadLUTRAMU();

    //
    // uncachedWriteReq --
    //     Write a portion of a word to the system.
    //
    (* conservative_implicit_conditions *)
    rule uncachedWriteReq (! initQ.notEmpty() &&&
                           uncachedReqQ.first() matches tagged SCRATCHPAD_HYBRID_WRITE .w_req);
        let port = w_req.port;
        let l_addr = scratchpadLineAddr(w_req.addr);
        let word_idx = scratchpadWordIdx(w_req.addr);

        if (uncachedStoreBufAddr.readPorts[0].sub(port) matches tagged Valid .sb_addr)
        begin
            // Get the store buffer data and mask.  It will either be flushed
            // to the host or merged with the new data.
            t_SCRATCHPAD_LINE sb_val = newVector();
            t_SCRATCHPAD_LINE_MASK sb_mask = newVector();
            for (Integer w = 0; w < valueOf(SCRATCHPAD_WORDS_PER_LINE); w = w + 1)
            begin
                match {.val, .bmask} = uncachedStoreBuf[w].readPorts[0].sub(port);
                sb_val[w] = val;
                sb_mask[w] = bmask;
            end

            // Does the address match?
            if (sb_addr != l_addr)
            begin
                // No match.  Flush the old line.
                //
                // NOTE:  There is no deq of uncachedReqQ on this path.  The
                // request will be processed again now that the store buffer
                // is empty.
                let h_addr = hostAddrFromLineAddr(port, sb_addr);
                storeLine(sb_mask, h_addr, sb_val);

                uncachedStoreBufAddr.upd(port, tagged Invalid);
                debugLog.record($format("port %0d: uncachedWriteReq: Flush SB entry, addr=0x%x, mask=%b", port, l_addr, pack(sb_mask)));
            end
            else
            begin
                // Address matches.  Merge the new line.
                SCRATCHPAD_MEM_MASK new_mask = unpack(pack(sb_mask[word_idx]) |
                                                      pack(w_req.byteMask));

                Vector#(t_SCRATCHPAD_MEM_MASK_SZ, Bit#(8)) bytes_out = newVector();
                Vector#(t_SCRATCHPAD_MEM_MASK_SZ, Bit#(8)) bytes_sb = unpack(sb_val[word_idx]);
                Vector#(t_SCRATCHPAD_MEM_MASK_SZ, Bit#(8)) bytes_new = unpack(w_req.val);
                for (Integer b = 0; b < valueOf(t_SCRATCHPAD_MEM_MASK_SZ); b = b + 1)
                begin
                    bytes_out[b] = w_req.byteMask[b] ? bytes_new[b] : bytes_sb[b];
                end

                uncachedStoreBuf[word_idx].upd(port, tuple2(pack(bytes_out),
                                                            new_mask));

                uncachedReqQ.deq();
                debugLog.record($format("port %0d: uncachedWriteReq: Merge SB entry, addr=0x%x, w_idx=%d, val=0x%x, mask=%b", port, l_addr, word_idx, pack(bytes_out), new_mask));
            end
        end
        else
        begin
            //
            // The store buffer is empty.  Write the new word to the buffer.
            //
            uncachedReqQ.deq();
            uncachedStoreBufAddr.upd(port, tagged Valid l_addr);

            for (Integer w = 0; w < valueOf(SCRATCHPAD_WORDS_PER_LINE); w = w + 1)
            begin
                SCRATCHPAD_MEM_MASK mask = (fromInteger(w) == word_idx) ?
                                           w_req.byteMask : replicate(False);
                uncachedStoreBuf[w].upd(port, tuple2(w_req.val, mask));
            end

            debugLog.record($format("port %0d: uncachedWriteReq: New SB entry, addr=0x%x, w_idx=%d, val=0x%x, mask=%b", port, l_addr, word_idx, w_req.val, w_req.byteMask));

            // Invalidate the read buffer if it matches the new address
            if (uncachedLastReadAddr.readPorts[0].sub(port) matches tagged Valid .r_addr &&&
                r_addr == l_addr)
            begin
                uncachedLastReadAddr.upd(port, tagged Invalid);
                debugLog.record($format("port %0d: uncachedWriteReq: Inval matching read buf", port));
            end
        end
    endrule


    //
    // uncachedReadReq --
    //      Request from scratchpad client for data not stored in the central
    //      cache.
    //
    (* conservative_implicit_conditions *)
    rule uncachedReadReq (! initQ.notEmpty() &&&
                          uncachedReqQ.first() matches tagged SCRATCHPAD_HYBRID_READ .r_req);
        let port = r_req.refInfo.portNum;
        let l_addr = scratchpadLineAddr(r_req.addr);
        let w_idx = scratchpadWordIdx(r_req.addr);

        if (uncachedStoreBufAddr.readPorts[0].sub(port) matches tagged Valid .sb_addr &&&
            sb_addr == l_addr)
        begin
            // Address being read is in the store buffer!

            // Get the store buffer data and mask.
            t_SCRATCHPAD_LINE sb_val = newVector();
            t_SCRATCHPAD_LINE_MASK sb_mask = newVector();
            for (Integer w = 0; w < valueOf(SCRATCHPAD_WORDS_PER_LINE); w = w + 1)
            begin
                match {.val, .bmask} = uncachedStoreBuf[w].readPorts[0].sub(port);
                sb_val[w] = val;
                sb_mask[w] = bmask;
            end

            //
            // Two possible cases:  if the word in the store buffer is valid
            // then just return the word from the store buffer.  If any of the
            // store buffer is invalid then merge the store buffer with the
            // host by flushing the buffer.  In the latter case the current load
            // request remains unhandled.  It will be rerun on the next FPGA
            // cycle in this rule.
            //
            // The client specified which bytes must be valid.
            //
            if ((pack(sb_mask[w_idx]) & pack(r_req.byteMask)) == pack(r_req.byteMask))
            begin
                // Hit.  Return the store buffer.
                uncachedReqQ.deq();
                uncachedReadRspQ.enq(tuple3(r_req.addr, sb_val[w_idx], r_req.refInfo));
                debugLog.record($format("port %0d: uncachedReadReq: SB hit, addr=0x%x, idx=%0d, val=0x%x, mask=%b", port, l_addr, w_idx, sb_val[w_idx], pack(r_req.byteMask)));
            end
            else
            begin
                // Flush the store buffer to the host
                let h_addr = hostAddrFromLineAddr(port, sb_addr);
                storeLine(sb_mask, h_addr, sb_val);

                uncachedStoreBufAddr.upd(port, tagged Invalid);
                debugLog.record($format("port %0d: uncachedReadReq: Flush SB entry, addr=0x%x, mask=%b", port, l_addr, pack(sb_mask)));
            end
        end
        else if (uncachedLastReadAddr.readPorts[0].sub(port) matches tagged Valid .lr_addr &&&
                 lr_addr == l_addr)
        begin
            //
            // Streaming read: the requested line was already requested by the
            // last read.  Don't ask the host again.  Instead, use the last
            // line cache.
            //
            uncachedReqQ.deq();

            // Record reference metadata for use when the value comes back.
            SCRATCHPAD_HYBRID_READ_INFO info;
            info.fromCentralCache = False;
            info.mergedWithLastLineReq = True;
            info.addr = r_req.addr;
            info.wordIdx = w_idx;
            info.refInfo = r_req.refInfo;
            readReqInfoQ.enq(info);

            debugLog.record($format("port %0d: uncachedReadReq: Stream addr=0x%x", port, l_addr));
        end
        else
        begin
            //
            // The line is not in either the store buffer or the last read buffer.
            // Generate a request to the host.
            //
            uncachedReqQ.deq();

            let h_addr = hostAddrFromLineAddr(port, l_addr);
            scratchpad_rrr.makeRequest_LoadLine(h_addr);

            // Reference metadata for use when the value comes back.
            // Responses from the system are ordered.
            SCRATCHPAD_HYBRID_READ_INFO info;
            info.fromCentralCache = False;
            info.mergedWithLastLineReq = False;
            info.addr = r_req.addr;
            info.wordIdx = w_idx;
            info.refInfo = r_req.refInfo;
            readReqInfoQ.enq(info);

            uncachedLastReadAddr.upd(port, tagged Valid l_addr);

            debugLog.record($format("port %0d: uncachedReadReq: Read addr=0x%x", port, l_addr));
        end
    endrule


    //
    // uncachedReadResp --
    //     Forward response from host directly to the scratchpad client.
    //
    (* descending_urgency = "uncachedReadResp, uncachedReadReq, uncachedWriteReq, backingWriteDataReq, backingReadReq" *)
    rule uncachedReadResp (! readReqInfoQ.first().fromCentralCache);
        let info = readReqInfoQ.first();
        readReqInfoQ.deq();

        let port = info.refInfo.portNum;
        let l_addr = scratchpadLineAddr(info.addr);

        t_SCRATCHPAD_LINE line;
        String read_source;

        if (! info.mergedWithLastLineReq)
        begin
            // Consume response from host
            read_source = "host";

            let r <- scratchpad_rrr.getResponse_LoadLine();

            line[0] = r.data0;
            line[1] = r.data1;
            line[2] = r.data2;
            line[3] = r.data3;

            // Record the line in case it is reused by later reads.
            uncachedLastReadBuf.upd(port, line);
        end
        else
        begin
            // Re-use previous response
            read_source = "stream";

            line = uncachedLastReadBuf.readPorts[0].sub(port);
        end

        // Only one word from the line is expected.  Pick the right one.
        let v = line[info.wordIdx];
        uncachedReadRspQ.enq(tuple3(info.addr, v, info.refInfo));

        debugLog.record($format("port %0d: uncachedReadResp %s: val=0x%x", port, read_source, pack(v)));
    endrule


    //
    // Compute debug scan state.
    //
    PulseWire uncachedReqWritePending <- mkPulseWire();    
    PulseWire uncachedReqReadPending <- mkPulseWire();    

    (* fire_when_enabled *)
    rule uncachedDebugState (True);
        if (uncachedReqQ.first() matches tagged SCRATCHPAD_HYBRID_WRITE .w_req)
        begin
            uncachedReqWritePending.send();
        end

        if (uncachedReqQ.first() matches tagged SCRATCHPAD_HYBRID_READ .r_req)
        begin
            uncachedReqReadPending.send();
        end
    endrule


    // ====================================================================
    //
    // Scratchpad port methods.
    //
    // ====================================================================

    //
    // readReq --
    //     Incoming read requests.
    //
    method Action readReq(SCRATCHPAD_MEM_ADDRESS addr,
                          SCRATCHPAD_MEM_MASK byteMask,
                          SCRATCHPAD_REF_INFO refInfo);
        //
        // Take different paths depending on whether the scratchpad is permitted
        // to store data in the central cache.
        //
        if (! portUsesCentralCache[refInfo.portNum])
        begin
            // No caching.  Direct to host.
            SCRATCHPAD_HYBRID_READ_REQ r_req;
            r_req.addr = addr;
            r_req.byteMask = byteMask;
            r_req.refInfo = refInfo;

            uncachedReqQ.enq(tagged SCRATCHPAD_HYBRID_READ r_req);
            debugLog.record($format("port %0d: readReq uncached addr=0x%x", refInfo.portNum, addr));
        end
        else
        begin
            // Forward the read request to the central cache.

            match {.line_addr, .word_idx} = makeCacheAddr(refInfo.portNum, addr);
            debugLog.record($format("port %0d: readReq addr=0x%x, l_addr=0x%x, wIdx=%0d", refInfo.portNum, addr, line_addr, word_idx));

            // Add the word index to the reference info sent to the central cache.
            // We'll need it to pick out the right word from the returned line.
            Tuple2#(SCRATCHPAD_REF_INFO, SCRATCHPAD_WORD_IDX) local_ref_info = tuple2(refInfo, word_idx);

            // Look for the value in the central cache
            let req = CENTRAL_CACHE_READ_REQ { addr: line_addr,
                                               wordIdx: word_idx,
                                               refInfo: zeroExtend(pack(local_ref_info)) };
            centralCachePort.newReq(tagged CENTRAL_CACHE_READ req);
        end
    endmethod


    //
    // readRsp --
    //     Collect read responses both from the central cache and from, for
    //     uncached references, from the system.  All responses are funnelled
    //     back through the same interface.
    //
    method ActionValue#(SCRATCHPAD_READ_RESP#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE)) readRsp();
        SCRATCHPAD_READ_RESP#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE) r = ?;

        //
        // Arbitration shouldn't be necessary, since neither source of data
        // can respond with a message every cycle.
        //
        if (uncachedReadRspQ.notEmpty())
        begin
            //
            // Uncached response directly from the host.
            //
            match {.addr, .val, .ref_info} = uncachedReadRspQ.first();
            uncachedReadRspQ.deq();
            
            r.val = val;
            r.addr = addr;
            r.refInfo = ref_info;
        end
        else
        begin
            //
            // Central cache response.
            //
            let d <- centralCachePort.readResp();

            // Extract the base reference info and the word index stored by readReq.
            Tuple2#(SCRATCHPAD_REF_INFO, SCRATCHPAD_WORD_IDX) local_ref_info = unpack(truncate(d.refInfo));
            match {.ref_info, .word_idx} = local_ref_info;

            r.val = d.val;
            // Reconstruct the scratchpad word address from the line address and
            // the word index.  This will fail if the central cache address space
            // is too small for the scratchpad address space:
            r.addr = makeScratchpadAddr(d.addr, word_idx);
            r.refInfo = ref_info;
        end

        debugLog.record($format("port %0d: readRsp addr=0x%x, val=0x%x", r.refInfo.portNum, r.addr, r.val));
        return r;
    endmethod
 

    //
    // write --
    //     Write to scratchpad.  WARNING: this is permitted only for scratchpads
    //     that use the central cache.
    //
    method Action write(SCRATCHPAD_MEM_ADDRESS addr, SCRATCHPAD_MEM_VALUE val, SCRATCHPAD_PORT_NUM portNum);
        match {.line_addr, .word_idx} = makeCacheAddr(portNum, addr);
        debugLog.record($format("port %0d: write addr=0x%x, l_addr=0x%x, wIdx=%0d, val=0x%x", portNum, addr, line_addr, word_idx, val));

        // Store the value in the central cache.  Don't bother constructing
        // a useful refInfo for the cache since nothing will ever see it.
        let req = CENTRAL_CACHE_WRITE_REQ { addr: line_addr,
                                            wordIdx: word_idx,
                                            val: val,
                                            refInfo: ? };
        centralCachePort.newReq(tagged CENTRAL_CACHE_WRITE req);
    endmethod


    //
    // writeMasked --
    //     Same as write but provides byte-level masking to control which bytes
    //     are updated.  WARNING: this method is permitted only for scratchpads
    //     that DO NOT USE the central cache.
    //
    method Action writeMasked(SCRATCHPAD_MEM_ADDRESS addr,
                              SCRATCHPAD_MEM_VALUE val,
                              SCRATCHPAD_MEM_MASK byteWriteMask,
                              SCRATCHPAD_PORT_NUM portNum);
        SCRATCHPAD_HYBRID_WRITE_REQ w_req;
        w_req.addr = addr;
        w_req.val = val;
        w_req.byteMask = byteWriteMask;
        w_req.port = portNum;

        uncachedReqQ.enq(tagged SCRATCHPAD_HYBRID_WRITE w_req);
        debugLog.record($format("port %0d: write addr=0x%x, val=0x%x, mask=0x%x", portNum, addr, val, byteWriteMask));
    endmethod


    //
    // Initialization
    //
    method ActionValue#(Bool) init(SCRATCHPAD_MEM_ADDRESS allocLastWordIdx,
                                   SCRATCHPAD_PORT_NUM portNum,
                                   Bool useCentralCache);
        debugLog.record($format("port %0d: init lastWordIdx=0x%x", portNum, allocLastWordIdx));

        initQ.enq(tuple3(portNum, allocLastWordIdx, useCentralCache));
        return True;
    endmethod


    //
    // Debug (deadlock) scan chain
    //
    method SCRATCHPAD_MEMORY_DEBUG_SCAN debugScanState();
        SCRATCHPAD_MEMORY_DEBUG_SCAN state;
        state.uncachedReqWritePending = uncachedReqWritePending;
        state.uncachedReqReadPending = uncachedReqReadPending;
        state.initQnotEmpty = initQ.notEmpty();

        return state;
    endmethod
endmodule
