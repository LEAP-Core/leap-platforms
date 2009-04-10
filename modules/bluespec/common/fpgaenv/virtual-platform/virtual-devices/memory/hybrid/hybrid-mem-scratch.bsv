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
`include "asim/provides/virtual_devices.bsh"
`include "asim/provides/central_cache.bsh"
`include "asim/provides/fpga_components.bsh"

`include "asim/rrr/remote_client_stub_SCRATCHPAD_MEMORY.bsh"
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

typedef SCRATCHPAD_MEMORY_VIRTUAL_DEVICE#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE) SCRATCHPAD_MEMORY_IFC;
typedef SCRATCHPAD_MEMORY_PORT#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE) SCRATCHPAD_MEMORY_PORT_IFC;

//
// mkMemoryVirtualDevice --
//     Build a device interface with the requested number of ports.
//
module [HASIM_MODULE] mkMemoryVirtualDevice#(LowLevelPlatformInterface llpi,
                                             CENTRAL_CACHE_IFC centralCache)
    // interface:
    (SCRATCHPAD_MEMORY_IFC)
    provisos (Bits#(SCRATCHPAD_MEM_ADDRESS, t_SCRATCHPAD_MEM_ADDRESS_SZ),

              // Storage breaks with 0-sized index
              Max#(2, SCRATCHPAD_N_CLIENTS, t_SAFE_N_CLIENTS),
              Alias#(Bit#(TLog#(t_SAFE_N_CLIENTS)), t_PORT_ID),
       
              // Pass details of load request in cache refInfo parameter
              Alias#(Tuple3#(t_PORT_ID, SCOREBOARD_FIFO_ENTRY_ID#(2), SCRATCHPAD_WORD_IDX), t_REF_INFO));

    DEBUG_FILE debugLog <- mkDebugFile("memory_scrathpad.out");

    //
    // Scratchpad's central cache port
    //
    let centralCachePort = centralCache.clientPorts[`VDEV_CACHE_SCRATCH - `VDEV_CACHE__BASE];


    // ====================================================================
    //
    // Rules for consuming requests from the cache to communicate with the
    // backing storage.  Forward requests through RRR to the host.
    //
    // ====================================================================

    ClientStub_SCRATCHPAD_MEMORY scratchpad_rrr <- mkClientStub_SCRATCHPAD_MEMORY();
    let centralCacheBackingPort = centralCache.backingPorts[`VDEV_CACHE_SCRATCH - `VDEV_CACHE__BASE];

    rule backingReadReq (True);
        let r <- centralCacheBackingPort.getReadReq();
        debugLog.record($format("backingReadReq: addr=0x%x", r.addr));

        scratchpad_rrr.makeRequest_Load(zeroExtend(r.addr));
    endrule

    rule backingReadResp (True);
        let d <- scratchpad_rrr.getResponse_Load();
        Vector#(SCRATCHPAD_WORDS_PER_LINE, SCRATCHPAD_MEM_VALUE) v = unpack(pack(d));

        debugLog.record($format("backingReadResp: val=0x%x", pack(v)));
        centralCacheBackingPort.sendReadResp(pack(v));
    endrule

    rule backingWriteReq (True);
        let r <- centralCacheBackingPort.getWriteReq();
        debugLog.record($format("backingWriteReq: addr=0x%x, wMask=0x%x val=0x%x", r.addr, r.wordValidMask, r.val));

        Vector#(SCRATCHPAD_WORDS_PER_LINE, SCRATCHPAD_MEM_VALUE) v = unpack(pack(r.val));
        scratchpad_rrr.makeRequest_Store(zeroExtend(r.addr), zeroExtend(pack(r.wordValidMask)), v[3], v[2], v[1], v[0]);
    endrule


    // ====================================================================
    //
    // Route central cache read responses back to scratchpad ports.
    //
    // ====================================================================

    //
    // Responses may come back from the cache out of order.  Each scratchpad
    // port gets its own reorder buffer, since the scratchpad clients expect
    // responses in order.  If the storage required for individual reorder
    // buffers is too large they could all be merged into a single buffer
    // at the cost of all scratchpad reads blocking when one misses in
    // the cache.  With separate buffers only the scratchpad that misses
    // is blocked.
    //
    Vector#(SCRATCHPAD_N_CLIENTS, SCOREBOARD_FIFO#(2, SCRATCHPAD_MEM_VALUE)) readRspQ <- replicateM(mkScoreboardFIFO());

    rule routeCacheResponse (True);
        let d <- centralCachePort.readResp();

        t_REF_INFO ref_info = unpack(truncate(d.refInfo));
        match {.port, .entry_id, .word_idx} = ref_info;

        let v = validValue(d.words[word_idx]);
        debugLog.record($format("port %0d: cacheRsp addr=0x%x, wIdx=%0d, id=%0d, val=0x%x", port, d.addr, word_idx, entry_id, v));
        
        readRspQ[port].setValue(entry_id, v);
    endrule


    // ====================================================================
    //
    // Scratchpad port methods.
    //
    // ====================================================================

    //
    // makeHostAddr --
    //     Compute the host address given a port and address within a region.
    //
    function Tuple2#(HOST_SCRATCHPAD_ADDR, SCRATCHPAD_WORD_IDX) makeHostAddr(Integer port, SCRATCHPAD_MEM_ADDRESS addr)
        provisos(Log#(SCRATCHPAD_WORDS_PER_LINE, t_WORD_IDX_SZ),
                 Add#(t_WORD_IDX_SZ, t_LINE_ADDR_SZ, `SCRATCHPAD_MEMORY_ADDR_BITS));

        // Split incoming address into line and word index
        Tuple2#(Bit#(t_LINE_ADDR_SZ), SCRATCHPAD_WORD_IDX) t = unpack(addr);
        match {.l_addr, .w_idx} = t;

        // Host address is the concatenation of the port ID and the line
        // address within the region.
        SCRATCHPAD_WORD_IDX w_zero = 0;
        HOST_SCRATCHPAD_ADDR h_addr = { fromInteger(port), l_addr, w_zero };
    
        return tuple2(h_addr, w_idx);
    endfunction

    //
    // Allocate the memory interfaces.
    //
    Vector#(SCRATCHPAD_N_CLIENTS, SCRATCHPAD_MEMORY_PORT_IFC) portsLocal = newVector();
    
    for (Integer p = 0; p < valueOf(SCRATCHPAD_N_CLIENTS); p = p + 1)
    begin
        portsLocal[p] = (
            interface SCRATCHPAD_MEMORY_PORT;
                interface MEMORY_IFC mem;
                    method Action readReq(SCRATCHPAD_MEM_ADDRESS addr);
                        match {.line_addr, .word_idx} = makeHostAddr(p, addr);
                        debugLog.record($format("port %0d: readReq addr=0x%x, l_addr=0x%x, wIdx=%0d", p, addr, line_addr, word_idx));
           
                        // Allocate a slot in the reorder buffer so OOO responses
                        // from the cache are returned by readRsp in order.
                        let slot <- readRspQ[p].enq();

                        //
                        // Ask the central cache for the value.
                        //

                        // Pass port ID, reorder slot ID and word index in the refInfo
                        t_REF_INFO ref_info = tuple3(fromInteger(p), slot, word_idx);
                        centralCachePort.readReq(truncate(line_addr), word_idx, zeroExtend(pack(ref_info)));
                    endmethod

                    method ActionValue#(SCRATCHPAD_MEM_VALUE) readRsp();
                        let v = readRspQ[p].first();
                        readRspQ[p].deq();

                        debugLog.record($format("port %0d: readRsp val=0x%x", p, v));

                        return v;
                    endmethod

                    method Action write(SCRATCHPAD_MEM_ADDRESS addr, SCRATCHPAD_MEM_VALUE val) if (readRspQ[p].notFull());
                        match {.line_addr, .word_idx} = makeHostAddr(p, addr);
                        debugLog.record($format("port %0d: write addr=0x%x, l_addr=0x%x, wIdx=%0d, val=0x%x", p, addr, line_addr, word_idx, val));
           
                        // Store the value in the central cache.
                        centralCachePort.write(truncate(line_addr), val, word_idx, ?);
                    endmethod
                endinterface


                //
                // Initialization
                //
                method ActionValue#(Bool) init(SCRATCHPAD_MEM_ADDRESS allocLastWordIdx);
                    debugLog.record($format("port %0d: init lastWordIdx=0x%x", p, allocLastWordIdx));

                    scratchpad_rrr.makeRequest_InitRegion(fromInteger(p), allocLastWordIdx);
                    return True;
                endmethod

            endinterface
        );
    end
    
    interface ports = portsLocal;
endmodule
