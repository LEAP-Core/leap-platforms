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
// Simple scratchpad interface that uses WORD-SIZED local memory refereces
// as the only backing storage.
//
// The scratchpad can access all of local memory and assumes that any sharing
// is managed by clients of the scratchpad.
// 

import Vector::*;

`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/local_mem.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/fpga_components.bsh"


// Scratchpad memory address
typedef LOCAL_MEM_ADDR SCRATCHPAD_MEM_ADDRESS;


// Scratchpad memory value
typedef LOCAL_MEM_WORD SCRATCHPAD_MEM_VALUE;


// Scratchpad requests (either a load or a store).
typedef union tagged 
{
    SCRATCHPAD_MEM_ADDRESS SCRATCHPAD_MEM_LOAD;
    struct {SCRATCHPAD_MEM_ADDRESS addr; SCRATCHPAD_MEM_VALUE val;} SCRATCHPAD_MEM_STORE;
}
SCRATCHPAD_MEM_REQUEST
    deriving (Eq, Bits);


interface SCRATCHPAD_MEMORY_VIRTUAL_DEVICE;
    method Action makeMemRequest(SCRATCHPAD_MEM_REQUEST req);
    method ActionValue#(SCRATCHPAD_MEM_VALUE) getMemResponse(); //Data is assumed to come back inorder
    method ActionValue#(SCRATCHPAD_MEM_ADDRESS) getInvalidateRequest();
endinterface



//
// Modules
//

// mkMemoryVirtualDevice

module mkMemoryVirtualDevice#(LowLevelPlatformInterface llpi)
    // interface:
    (SCRATCHPAD_MEMORY_VIRTUAL_DEVICE);

    method Action makeMemRequest(SCRATCHPAD_MEM_REQUEST req);
        case (req) matches
          tagged SCRATCHPAD_MEM_LOAD .addr:
          begin
              llpi.localMem.readWordReq(addr);
          end
          tagged SCRATCHPAD_MEM_STORE .st_info:
          begin
              llpi.localMem.writeWord(st_info.addr, st_info.val);
          end
        endcase
    endmethod
  

    method ActionValue#(SCRATCHPAD_MEM_VALUE) getMemResponse();
        let d <- llpi.localMem.readWordRsp();
        return d;
    endmethod


    //
    // getInvalidateRequest --
    //     Nothing happens (deadlocks).
    //
    method ActionValue#(SCRATCHPAD_MEM_ADDRESS) getInvalidateRequest() if (False);
        return 0;
    endmethod
endmodule
