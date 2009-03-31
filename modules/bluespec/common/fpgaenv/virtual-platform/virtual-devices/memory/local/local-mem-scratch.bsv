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
// Simple scratchpad interface that uses local memory refereces
// as the only backing storage.
//
// The scratchpad can access all of local memory and assumes that any sharing
// is managed by clients of the scratchpad.
// 

import FIFO::*;
import FIFOF::*;
import Vector::*;

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/local_mem.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/virtual_devices.bsh"
`include "asim/provides/fpga_components.bsh"

//
// Scratchpad memory address and value.  awb parameter controls whether accesses
// are to local memory words or lines.
//
`ifdef LOCAL_MEM_USE_LINES_Z
typedef LOCAL_MEM_ADDR SCRATCHPAD_MEM_ADDRESS;
typedef LOCAL_MEM_WORD SCRATCHPAD_MEM_VALUE;
`else
typedef LOCAL_MEM_LINE_ADDR SCRATCHPAD_MEM_ADDRESS;
typedef LOCAL_MEM_LINE SCRATCHPAD_MEM_VALUE;
`endif

typedef SCRATCHPAD_MEMORY_VIRTUAL_DEVICE#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE) SCRATCHPAD_MEMORY_IFC;
typedef SCRATCHPAD_MEMORY_PORT#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE) SCRATCHPAD_MEMORY_PORT_IFC;


//
// mkMemoryVirtualDevice --
//     Build a device interface with the requested number of ports.
//
module mkMemoryVirtualDevice#(LowLevelPlatformInterface llpi)
    // interface:
    (SCRATCHPAD_MEMORY_IFC)
    provisos (Bits#(SCRATCHPAD_MEM_ADDRESS, t_SCRATCHPAD_MEM_ADDRESS_SZ),

              // LUTRAM breaks with 0-sized index
              Max#(2, SCRATCHPAD_N_CLIENTS, t_SAFE_N_CLIENTS),
              Alias#(Bit#(TLog#(t_SAFE_N_CLIENTS)), t_PORT_ID));

    DEBUG_FILE debugLog <- mkDebugFile("memory_scrathpad.out");

    // Total memory allocated
    Reg#(SCRATCHPAD_MEM_ADDRESS) totalAlloc <- mkReg(0);

    // Port base-address within global memory.  Assigned dynamically as
    // allocation requests arrive.
    LUTRAM#(t_PORT_ID, Maybe#(SCRATCHPAD_MEM_ADDRESS)) portSegmentBase <- mkLUTRAM(tagged Invalid);

    // Direct read responses to the correct port
    FIFOF#(t_PORT_ID) readQ <- mkSizedFIFOF(8);


    // ====================================================================
    //
    // Initialization.  All scratchpad memory is guaranteed to start
    // filled with zeros.
    //
    // ====================================================================

    FIFO#(Tuple3#(t_PORT_ID, SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_ADDRESS)) initQ <- mkFIFO1();
    Reg#(Bool) initBusy <- mkReg(False);
    Reg#(t_PORT_ID) initPort <- mkRegU();
    Reg#(SCRATCHPAD_MEM_ADDRESS) initAddrBase <- mkRegU();
    Reg#(SCRATCHPAD_MEM_ADDRESS) initAddr <- mkRegU();
    Reg#(SCRATCHPAD_MEM_ADDRESS) initCnt <- mkRegU();

    //
    // processInitReq --
    //     Initialization requests come from the init port interface below.
    //
    rule processInitReq (! initBusy);
        match {.port, .base_addr, .n_init} = initQ.first();
        initQ.deq();
        
        initBusy <= True;
        initPort <= port;
        initAddrBase <= base_addr;
        initAddr <= base_addr;
        initCnt <= n_init;
    endrule

    //
    // doInit --
    //     Main initialization loop.  Write 0 to a scratchpad.
    //
    rule doInit (initBusy);
`ifdef LOCAL_MEM_USE_LINES_Z
        llpi.localMem.writeWord(initAddr, 0);
`else
        llpi.localMem.writeLine(localMemLineAddrToAddr(initAddr), 0);
`endif

        // Done?
        if (initCnt == 0)
        begin
            // Flag the segment ready by setting its translation to a local
            // memory region.
            portSegmentBase.upd(initPort, tagged Valid initAddrBase);
            initBusy <= False;
            debugLog.record($format("INIT port %0d: done", initPort));
        end
        
        initAddr <= initAddr + 1;
        initCnt <= initCnt - 1;
    endrule


    // ====================================================================
    //
    // Scratchpad port methods.
    //
    // ====================================================================

    //
    // Allocate the memory interfaces.
    //
    Vector#(SCRATCHPAD_N_CLIENTS, SCRATCHPAD_MEMORY_PORT_IFC) portsLocal = newVector();
    
    for (Integer p = 0; p < valueOf(SCRATCHPAD_N_CLIENTS); p = p + 1)
    begin
        portsLocal[p] = (
            interface SCRATCHPAD_MEMORY_PORT;
                interface MEMORY_IFC mem;
                    method Action readReq(SCRATCHPAD_MEM_ADDRESS addr) if (! initBusy &&& portSegmentBase.sub(fromInteger(p)) matches tagged Valid .segment_base);
                        let p_addr = addr + segment_base;
                        debugLog.record($format("readReq port %0d: addr 0x%x, p_addr 0x%x", p, addr, p_addr));

                        readQ.enq(fromInteger(p));

`ifdef LOCAL_MEM_USE_LINES_Z
                        llpi.localMem.readWordReq(p_addr);
`else
                        llpi.localMem.readLineReq(localMemLineAddrToAddr(p_addr));
`endif
                    endmethod

                    method ActionValue#(SCRATCHPAD_MEM_VALUE) readRsp() if (readQ.first() == fromInteger(p));
                        readQ.deq();

`ifdef LOCAL_MEM_USE_LINES_Z
                        let d <- llpi.localMem.readWordRsp();
`else
                        let d <- llpi.localMem.readLineRsp();
`endif

                        debugLog.record($format("readRsp port %0d: 0x%x", p, d));

                        return d;
                    endmethod

                    //
                    // write --
                    //     write method is predicated by readQ.notFull() to ensure
                    //     synchronization of read and write requests.
                    //
                    method Action write(SCRATCHPAD_MEM_ADDRESS addr, SCRATCHPAD_MEM_VALUE val) if (! initBusy &&& readQ.notFull() &&& portSegmentBase.sub(fromInteger(p)) matches tagged Valid .segment_base);
                        let p_addr = addr + segment_base;
                        debugLog.record($format("write port %0d: addr 0x%x, p_addr 0x%x, 0x%x", p, addr, p_addr, val));

`ifdef LOCAL_MEM_USE_LINES_Z
                        llpi.localMem.writeWord(p_addr, val);
`else
                        llpi.localMem.writeLine(localMemLineAddrToAddr(p_addr), val);
`endif
                    endmethod
                endinterface


                //
                // Initialization
                //
                method ActionValue#(Bool) init(SCRATCHPAD_MEM_ADDRESS allocLastWordIdx);
                    SCRATCHPAD_MEM_ADDRESS last_word = totalAlloc + allocLastWordIdx;

                    // Arithmetic for debug (includes overflow bit)
                    Bit#(TAdd#(1, t_SCRATCHPAD_MEM_ADDRESS_SZ)) dbg_alloc_last_word_idx = zeroExtend(allocLastWordIdx) + 1;
                    Bit#(TAdd#(1, t_SCRATCHPAD_MEM_ADDRESS_SZ)) dbg_last_word = zeroExtend(last_word) + 1;
                    debugLog.record($format("INIT port %0d: 0x%x words, base 0x%x, next 0x%x", p, dbg_alloc_last_word_idx, totalAlloc, dbg_last_word));

                    Bool ok = True;
                    if (last_word > totalAlloc)
                    begin
                        initQ.enq(tuple3(fromInteger(p), totalAlloc, allocLastWordIdx));
                    end
                    else
                    begin
                        debugLog.record($format("INIT port %0d: OUT OF MEMORY", p));
                        ok = False;
                    end

                    totalAlloc <= last_word + 1;
                    return ok;
                endmethod

            endinterface
        );
    end
    
    interface ports = portsLocal;
endmodule
