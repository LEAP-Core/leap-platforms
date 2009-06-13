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
import Vector::*;

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/local_mem.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/virtual_devices.bsh"
`include "asim/provides/central_cache.bsh"
`include "asim/provides/fpga_components.bsh"

`include "asim/rrr/remote_client_stub_SCRATCHPAD_MEMORY.bsh"
`include "asim/rrr/remote_server_stub_SCRATCHPAD_MEMORY.bsh"
`include "asim/dict/VDEV_CACHE.bsh"


//
// Scratchpad memory address and value.  Value size and words per line must
// match local memory and the central cache.
//
typedef Bit#(`SCRATCHPAD_MEMORY_ADDR_BITS) SCRATCHPAD_MEM_ADDRESS;

typedef LOCAL_MEM_WORD SCRATCHPAD_MEM_VALUE;

// Number of scratchpad words in a line.  The line is the basic I/O size
// for RRR messages and caching of scratchpad values.
typedef LOCAL_MEM_WORDS_PER_LINE SCRATCHPAD_WORDS_PER_LINE;
typedef LOCAL_MEM_WORD_IDX SCRATCHPAD_WORD_IDX;


// Host scratchpad addresses are 64 bits
typedef Bit#(64) HOST_SCRATCHPAD_ADDR;

typedef SCRATCHPAD_MEMORY_VIRTUAL_DEVICE#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE) SCRATCHPAD_MEMORY_VDEV;


//
// mkMemoryVirtualDevice --
//     Build a device interface with the requested number of ports.
//
module [HASIM_MODULE] mkMemoryVirtualDevice#(LowLevelPlatformInterface llpi,
                                             CENTRAL_CACHE_IFC centralCache)
    // interface:
    (SCRATCHPAD_MEMORY_VDEV)
    provisos (Bits#(SCRATCHPAD_MEM_ADDRESS, t_SCRATCHPAD_MEM_ADDRESS_SZ));

    DEBUG_FILE debugLog <- mkDebugFile("memory_scratchpad.out");

    ClientStub_SCRATCHPAD_MEMORY scratchpad_rrr <- mkClientStub_SCRATCHPAD_MEMORY();

    //
    // Scratchpad's central cache port
    //
    let centralCachePort = centralCache.clientPorts[`VDEV_CACHE_SCRATCH - `VDEV_CACHE__BASE];


    // ====================================================================
    //
    // Initialization.
    //
    // ====================================================================
    
    // FIFO1 because it isn't worth the space to pipeline initialization.
    FIFO#(Tuple2#(SCRATCHPAD_PORT_NUM, SCRATCHPAD_MEM_ADDRESS)) initQ <- mkFIFO1();

    rule initRegion (True);
        match {.port, .alloc_last_word_idx} = initQ.first();
        initQ.deq();

        scratchpad_rrr.makeRequest_InitRegion(zeroExtend(port), alloc_last_word_idx);
    endrule


    // ====================================================================
    //
    // Rules for consuming requests from the cache to communicate with the
    // backing storage.  Forward requests through RRR to the host.
    //
    // ====================================================================

    let centralCacheBackingPort = centralCache.backingPorts[`VDEV_CACHE_SCRATCH - `VDEV_CACHE__BASE];

    //
    // hostScratchpadAddr --
    //     Compute the host scratchpad address given a central cache line address.
    //     Host scratchpad addresses are word-based, so adding low bits to the
    //     cache line address converts to the proper address.
    //
    function Bit#(64) hostScratchpadAddr(CENTRAL_CACHE_LINE_ADDR cAddr)
        provisos(Log#(SCRATCHPAD_WORDS_PER_LINE, t_WORD_IDX_SZ),
                 Add#(t_WORD_IDX_SZ, t_LINE_ADDR_SZ, `SCRATCHPAD_MEMORY_ADDR_BITS));
        Bit#(t_WORD_IDX_SZ) w_zero = 0;
        return zeroExtend({cAddr, w_zero});
    endfunction


    rule backingReadReq (True);
        let r <- centralCacheBackingPort.getReadReq();
        let h_addr = hostScratchpadAddr(r.addr);
        debugLog.record($format("backingReadReq: addr=0x%x", h_addr));

        scratchpad_rrr.makeRequest_LoadLine(h_addr);
    endrule

    Reg#(Bit#(TLog#(SCRATCHPAD_WORDS_PER_LINE))) readWordIdx <- mkReg(0);

    rule backingReadResp (True);
        // Pick a word from the current incoming value.  Pop the entry if on
        // the last word.
        OUT_TYPE_LoadLine r;
        if (readWordIdx == maxBound)
            r <- scratchpad_rrr.getResponse_LoadLine();
        else
            r = scratchpad_rrr.peekResponse_LoadLine();

        Vector#(SCRATCHPAD_WORDS_PER_LINE, SCRATCHPAD_MEM_VALUE) line;
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
    Reg#(Vector#(SCRATCHPAD_WORDS_PER_LINE, SCRATCHPAD_MEM_VALUE)) writeData <- mkRegU();
    Reg#(Bit#(TLog#(SCRATCHPAD_WORDS_PER_LINE))) writeWordIdx <- mkReg(0);

    rule backingWriteCtrlReq (True);
        let r <- centralCacheBackingPort.getWriteReq();
        let h_addr = hostScratchpadAddr(r.addr);
        debugLog.record($format("backingWriteReq: addr=0x%x, wMask=0x%x", h_addr, r.wordValidMask));

        writeCtrlQ.enq(r);
    endrule

    (* descending_urgency = "initRegion, backingWriteDataReq, backingWriteCtrlReq, backingReadReq" *)
    rule backingWriteDataReq (True);
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

            let h_addr = hostScratchpadAddr(ctrl.addr);
            scratchpad_rrr.makeRequest_StoreLine(h_addr,
                                                 zeroExtend(pack(ctrl.wordValidMask)),
                                                 writeData[0],
                                                 writeData[1],
                                                 writeData[2],
                                                 v);
        end

        writeWordIdx <= writeWordIdx + 1;
    endrule


    // ====================================================================
    //
    // Scratchpad port methods.
    //
    // ====================================================================

    //
    // makeCacheAddr --
    //     Compute the cache line given a port and address within a region.
    //
    function Tuple2#(CENTRAL_CACHE_LINE_ADDR, SCRATCHPAD_WORD_IDX) makeCacheAddr(SCRATCHPAD_PORT_NUM port, SCRATCHPAD_MEM_ADDRESS addr)
        provisos(Log#(SCRATCHPAD_WORDS_PER_LINE, t_WORD_IDX_SZ),
                 Add#(t_WORD_IDX_SZ, t_LINE_ADDR_SZ, `SCRATCHPAD_MEMORY_ADDR_BITS));

        // Split incoming address into line and word index
        Tuple2#(Bit#(t_LINE_ADDR_SZ), SCRATCHPAD_WORD_IDX) t = unpack(addr);
        match {.l_addr, .w_idx} = t;

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
    function SCRATCHPAD_MEM_ADDRESS makeScratchpadAddr(CENTRAL_CACHE_LINE_ADDR cAddr, Bit#(t_WORD_IDX_SZ) wIdx)
        provisos(Log#(SCRATCHPAD_WORDS_PER_LINE, t_WORD_IDX_SZ),
                 Add#(t_WORD_IDX_SZ, t_LINE_ADDR_SZ, `SCRATCHPAD_MEMORY_ADDR_BITS));

        // Drop the port ID from the line address
        Bit#(t_LINE_ADDR_SZ) l_addr = truncate(cAddr);

        // Make the address a word address
        return {l_addr, wIdx};
    endfunction


    method Action readReq(SCRATCHPAD_MEM_ADDRESS addr, SCRATCHPAD_REF_INFO refInfo);
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
    endmethod

    method ActionValue#(SCRATCHPAD_READ_RESP#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE)) readRsp();
        let d <- centralCachePort.readResp();

        // Extract the base reference info and the word index stored by readReq.
        Tuple2#(SCRATCHPAD_REF_INFO, SCRATCHPAD_WORD_IDX) local_ref_info = unpack(truncate(d.refInfo));
        match {.ref_info, .word_idx} = local_ref_info;

        SCRATCHPAD_READ_RESP#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE) r;
        r.val = d.val;
        // Reconstruct the scratchpad word address from the line address and
        // the word index.  This will fail if the central cache address space
        // is too small for the scratchpad address space:
        r.addr = makeScratchpadAddr(d.addr, word_idx);
        r.refInfo = ref_info;

        debugLog.record($format("port %0d: readRsp addr=0x%x, val=0x%x", ref_info.portNum, r.addr, r.val));

        return r;
    endmethod
 
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
    // Initialization
    //
    method ActionValue#(Bool) init(SCRATCHPAD_MEM_ADDRESS allocLastWordIdx, SCRATCHPAD_PORT_NUM portNum);
        debugLog.record($format("port %0d: init lastWordIdx=0x%x", portNum, allocLastWordIdx));

        initQ.enq(tuple2(portNum, allocLastWordIdx));
        return True;
    endmethod
endmodule
