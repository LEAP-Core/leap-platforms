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

`include "asim/provides/low_level_platform_interface.bsh"

//
// Although this is a NULL module, we need to have a fleshed-out
// interface because Platform Interface translates these methods
// into soft connections.
//

// hard-code addressable region to 4K size
typedef Bit#(0) SHARED_MEMORY_ADDRESS;
typedef Bit#(0) SHARED_MEMORY_DATA;
typedef Bit#(0) SHARED_MEMORY_BURST_LENGTH;

typedef struct
{
    SHARED_MEMORY_ADDRESS addr;
    SHARED_MEMORY_BURST_LENGTH len;
}
SHARED_MEMORY_REQ_INFO
    deriving (Bits, Eq);

typedef union tagged
{
    SHARED_MEMORY_REQ_INFO SHARED_MEMORY_READ;
    SHARED_MEMORY_REQ_INFO SHARED_MEMORY_WRITE;
}
SHARED_MEMORY_REQUEST
    deriving (Bits, Eq);

// ============== SHARED_MEMORY Interface ===============

// This device should export the generic MEMORY_IFC interface, but for debugging
// purposes we will use the basic hard-wired REMOTE_MEMORY interface for now.
// Also, MEMORY_IFC needs to be updated to include methods for burst access.

interface SHARED_MEMORY;

    // line interface
    method Action                           readLineReq(SHARED_MEMORY_ADDRESS addr);
    method ActionValue#(SHARED_MEMORY_DATA) readLineResp();
    method Action                           writeLine(SHARED_MEMORY_ADDRESS addr,
                                                      SHARED_MEMORY_DATA    data);
    
    // burst interface -- assumption: burst word == single word
    method Action                           readBurstReq(SHARED_MEMORY_ADDRESS      addr,
                                                         SHARED_MEMORY_BURST_LENGTH len);
    method ActionValue#(SHARED_MEMORY_DATA) readBurstResp();
    method Action                           writeBurstReq(SHARED_MEMORY_ADDRESS      addr,
                                                          SHARED_MEMORY_BURST_LENGTH len);
    method Action                           writeBurstData(SHARED_MEMORY_DATA data);    
        
endinterface

module mkSharedMemory#(LowLevelPlatformInterface llpi)
    // interface
        (SHARED_MEMORY);
    
    // line interface
    method Action readLineReq(SHARED_MEMORY_ADDRESS addr);
        noAction;
    endmethod
    
    method ActionValue#(SHARED_MEMORY_DATA) readLineResp();
        noAction;
        return ?;
    endmethod
    
    method Action writeLine(SHARED_MEMORY_ADDRESS addr,
                            SHARED_MEMORY_DATA    data);
        noAction;
    endmethod
    
    // burst interface -- assumption: burst word == single word
    method Action readBurstReq(SHARED_MEMORY_ADDRESS      addr,
                               SHARED_MEMORY_BURST_LENGTH len);
        noAction;
    endmethod
    
    method ActionValue#(SHARED_MEMORY_DATA) readBurstResp();
        noAction;
        return ?;
    endmethod
    
    method Action writeBurstReq(SHARED_MEMORY_ADDRESS      addr,
                                SHARED_MEMORY_BURST_LENGTH len);
        noAction;
    endmethod
    
    method Action writeBurstData(SHARED_MEMORY_DATA data);
        noAction;
    endmethod

endmodule
