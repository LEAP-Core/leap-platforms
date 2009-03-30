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
`include "asim/provides/fpga_components.bsh"

`include "asim/rrr/remote_client_stub_SCRATCHPAD_MEMORY.bsh"
`include "asim/dict/VDEV.bsh"

//
// Compute the clients of scratchpad memory.  Clients register by adding entries
// to the VDEV.SCRATCH dictionary.
//

`ifndef VDEV_SCRATCH__NENTRIES
// No clients.
`define VDEV_SCRATCH__NENTRIES 0
`endif

typedef `VDEV_SCRATCH__NENTRIES SCRATCHPAD_N_CLIENTS;


//
// Scratchpad memory address and value.
//
typedef Bit#(`SCRATCHPAD_MEMORY_ADDR_BITS) SCRATCHPAD_MEM_ADDRESS;
// For now we support only 64 bit words
typedef Bit#(64) SCRATCHPAD_MEM_VALUE;

// Number of scratchpad words in a line.  The line is the basic I/O size
// for RRR messages and caching of scratchpad values.
typedef 4 SCRATCHPAD_WORDS_PER_LINE;
typedef Bit#(TLog#(SCRATCHPAD_WORDS_PER_LINE)) SCRATCHPAD_WORD_IDX;


// Host scratchpad addresses are 64 bits
typedef Bit#(64) HOST_SCRATCHPAD_ADDR;

//
// Now that the address and value sizes are defined the common interface
// definition can be included.
//
`include "asim/provides/scratchpad_memory_interface.bsh"


//
// mkMemoryVirtualDevice --
//     Build a device interface with the requested number of ports.
//
module [HASIM_MODULE] mkMemoryVirtualDevice#(LowLevelPlatformInterface llpi)
    // interface:
    (SCRATCHPAD_MEMORY_VIRTUAL_DEVICE)
    provisos (Bits#(SCRATCHPAD_MEM_ADDRESS, t_SCRATCHPAD_MEM_ADDRESS_SZ),

              // Storage breaks with 0-sized index
              Max#(2, SCRATCHPAD_N_CLIENTS, t_SAFE_N_CLIENTS),
              Alias#(Bit#(TLog#(t_SAFE_N_CLIENTS)), t_PORT_ID));

    DEBUG_FILE debugLog <- mkDebugFile("memory_scrathpad.out");

    ClientStub_SCRATCHPAD_MEMORY scratchpad_rrr <- mkClientStub_SCRATCHPAD_MEMORY();
    FIFOF#(Tuple2#(t_PORT_ID, SCRATCHPAD_WORD_IDX)) reqQ <- mkSizedFIFOF(16);

    //
    // makeHostAddr --
    //     Compute the host address given a port and addression within a region.
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


    // ====================================================================
    //
    // Scratchpad port methods.
    //
    // ====================================================================

    //
    // Allocate the memory interfaces.
    //
    Vector#(SCRATCHPAD_N_CLIENTS, SCRATCHPAD_MEMORY_PORT) portsLocal = newVector();
    
    for (Integer p = 0; p < valueOf(SCRATCHPAD_N_CLIENTS); p = p + 1)
    begin
        portsLocal[p] = (
            interface SCRATCHPAD_MEMORY_PORT;
                interface MEMORY_IFC mem;
                    method Action readReq(SCRATCHPAD_MEM_ADDRESS addr);
                        match {.line_addr, .line_idx} = makeHostAddr(p, addr);
                        debugLog.record($format("readReq port %0d: addr 0x%x, l_addr 0x%x, l_idx 0x%x", p, addr, line_addr, line_idx));
           
                        scratchpad_rrr.makeRequest_Load(line_addr);
                        reqQ.enq(tuple2(fromInteger(p), line_idx));
                    endmethod

                    method ActionValue#(SCRATCHPAD_MEM_VALUE) readRsp() if (tpl_1(reqQ.first()) == fromInteger(p));
                        match {.port, .line_idx} = reqQ.first();
                        reqQ.deq();

                        let d <- scratchpad_rrr.getResponse_Load();
                        Vector#(SCRATCHPAD_WORDS_PER_LINE, SCRATCHPAD_MEM_VALUE) v = unpack(pack(d));
                        debugLog.record($format("readRsp port %0d: 0x%x", p, v[line_idx]));

                        return v[line_idx];
                    endmethod

                    method Action write(SCRATCHPAD_MEM_ADDRESS addr, SCRATCHPAD_MEM_VALUE val) if (reqQ.notFull());
                        match {.line_addr, .line_idx} = makeHostAddr(p, addr);
                        debugLog.record($format("write port %0d: addr 0x%x, l_addr 0x%x, l_idx 0x%x, 0x%x", p, addr, line_addr, line_idx, val));
           
                        scratchpad_rrr.makeRequest_StoreWord(line_addr + zeroExtend(line_idx), val);
                    endmethod
                endinterface


                //
                // Initialization
                //
                method ActionValue#(Bool) init(SCRATCHPAD_MEM_ADDRESS allocLastWordIdx);
                    debugLog.record($format("init port %0d: lastWordIdx 0x%x", p, allocLastWordIdx));

                    scratchpad_rrr.makeRequest_InitRegion(fromInteger(p), allocLastWordIdx);
                    return True;
                endmethod

            endinterface
        );
    end
    
    interface ports = portsLocal;
endmodule
