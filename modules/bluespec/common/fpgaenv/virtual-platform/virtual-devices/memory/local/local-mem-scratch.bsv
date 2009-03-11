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

import Vector::*;

`include "asim/provides/libfpga_bsv_base.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/local_mem.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/fpga_components.bsh"

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


//
// A scratchpad interface has one memory interface for each client.
//
interface SCRATCHPAD_MEMORY_VIRTUAL_DEVICE;
    interface Vector#(SCRATCHPAD_N_CLIENTS, MEMORY_IFC#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE)) ports;
endinterface



//
// mkMemoryVirtualDevice --
//     Build a device interface with the requested number of ports.
//
module mkMemoryVirtualDevice#(LowLevelPlatformInterface llpi)
    // interface:
    (SCRATCHPAD_MEMORY_VIRTUAL_DEVICE);

    Vector#(SCRATCHPAD_N_CLIENTS, MEMORY_IFC#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE)) portsLocal = newVector();

    for (Integer p = 0; p < valueOf(SCRATCHPAD_N_CLIENTS); p = p + 1)
    begin
        portsLocal[p] = (
            interface MEMORY_IFC#(SCRATCHPAD_MEM_ADDRESS, SCRATCHPAD_MEM_VALUE);
                method Action readReq(SCRATCHPAD_MEM_ADDRESS addr);
`ifdef LOCAL_MEM_USE_LINES_Z
                    llpi.localMem.readWordReq(addr);
`else
                    llpi.localMem.readLineReq(localMemLineAddrToAddr(addr));
`endif

                    //
                    // This implementation of a scratchpad supports only one
                    // client.  Multiple client support requires an algorithm
                    // for dividing up the local memory among clients.
                    //
                    if (p != 0)
                        $error("local-mem-scratch supports only one client");
                endmethod

                method ActionValue#(SCRATCHPAD_MEM_VALUE) readRsp();
`ifdef LOCAL_MEM_USE_LINES_Z
                    let d <- llpi.localMem.readWordRsp();
`else
                    let d <- llpi.localMem.readLineRsp();
`endif
                    return d;
                endmethod

                method Action write(SCRATCHPAD_MEM_ADDRESS addr, SCRATCHPAD_MEM_VALUE val);
`ifdef LOCAL_MEM_USE_LINES_Z
                    llpi.localMem.writeWord(addr, val);
`else
                    llpi.localMem.writeLine(localMemLineAddrToAddr(addr), val);
`endif
                endmethod
            endinterface
        );
    end
    
    interface ports = portsLocal;
endmodule
