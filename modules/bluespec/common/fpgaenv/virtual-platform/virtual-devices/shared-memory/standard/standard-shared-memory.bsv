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
`include "asim/provides/rrr.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/remote_memory.bsh"

`include "asim/rrr/server_stub_SHARED_MEMORY.bsh"
`include "asim/rrr/client_stub_SHARED_MEMORY.bsh"

// types
typedef enum
{
    STATE_init,
    STATE_waiting,
    STATE_ready
}
STATE
    deriving (Bits, Eq);

// hard-code addressable region to 4K size
typedef Bit#(9)                    SHARED_MEMORY_ADDRESS;
typedef REMOTE_MEMORY_DATA         SHARED_MEMORY_DATA;
typedef REMOTE_MEMORY_BURST_LENGTH SHARED_MEMORY_BURST_LENGTH;

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

// ============== mkSharedMemory Module ===============

// Translate our private virtual address to a remote physical address.

module mkSharedMemory#(LowLevelPlatformInterface llpi)
    // interface
        (SHARED_MEMORY);

    // stubs
    ServerStub_SHARED_MEMORY server_stub <- mkServerStub_SHARED_MEMORY(llpi.rrrServer);
    ClientStub_SHARED_MEMORY client_stub <- mkClientStub_SHARED_MEMORY(llpi.rrrClient);
    
    // TLB
    Reg#(REMOTE_MEMORY_PHYSICAL_ADDRESS) theOnlyPhysicalAddress <- mkReg(0);

    // get link to remote memory
    REMOTE_MEMORY remoteMemory = llpi.remoteMemory;

    // state
    Reg#(STATE) state <- mkReg(STATE_init);

    // translation macros
    function REMOTE_MEMORY_PHYSICAL_ADDRESS va_to_pa(SHARED_MEMORY_ADDRESS addr) =
        (theOnlyPhysicalAddress | zeroExtend(addr));
        
    //
    // Rules
    //
    
    // Wait for translation push from software
    
    rule wait_for_translation (state == STATE_init);
        
        let pa <- server_stub.acceptRequest_UpdateTranslation();
        theOnlyPhysicalAddress <= pa;
        
        server_stub.sendResponse_UpdateTranslation(?);

        state <= STATE_ready;
        
    endrule
    
    //
    // Methods
    //
    
    // line interface
    
    method Action readLineReq(SHARED_MEMORY_ADDRESS addr) if (state == STATE_ready);
        
        remoteMemory.readLineReq(va_to_pa(addr));
        
    endmethod

    method ActionValue#(SHARED_MEMORY_DATA) readLineResp() if (state == STATE_ready);
        
        let data <- remoteMemory.readLineResp();
        return data;
        
    endmethod
        
    method Action writeLine(SHARED_MEMORY_ADDRESS addr,
                            SHARED_MEMORY_DATA    data) if (state == STATE_ready);

        remoteMemory.writeLine(va_to_pa(addr), data);
        
    endmethod
    
    // burst interface
    
    method Action readBurstReq(SHARED_MEMORY_ADDRESS      addr,
                               SHARED_MEMORY_BURST_LENGTH nwords) if (state == STATE_ready);

        remoteMemory.readBurstReq(va_to_pa(addr), nwords);
        
    endmethod

    method ActionValue#(SHARED_MEMORY_DATA) readBurstResp() if (state == STATE_ready);
        
        let data <- remoteMemory.readBurstResp();    
        return data;
        
    endmethod
    
    // for burst writes, the first data word can only be written in the cycle following
    // the initial write request. Probably easy to optimize this.
    
    method Action writeBurstReq(SHARED_MEMORY_ADDRESS      addr,
                                SHARED_MEMORY_BURST_LENGTH len) if (state == STATE_ready);
        
        remoteMemory.writeBurstReq(va_to_pa(addr), len);
        
    endmethod
        
    method Action writeBurstData(SHARED_MEMORY_DATA data) if (state == STATE_ready);

        remoteMemory.writeBurstData(data);
        
    endmethod    
    
endmodule
