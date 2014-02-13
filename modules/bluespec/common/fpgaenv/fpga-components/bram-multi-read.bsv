//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

//
// Several different flavors of multi-reader BRAMs are provided here, ranging
// from parallel readers with multiple underlying BRAMs to shared BRAMs with
// guards on the read methods to route responses.
//

import Vector::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;

`include "asim/provides/librl_bsv_base.bsh"

//
// Interfaces
//

typedef MEMORY_READER_IFC#(t_ADDR, t_DATA) BROM#(type t_ADDR, type t_DATA);
typedef MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA) BRAM_MULTI_READ#(numeric type n_READERS, type t_ADDR, type t_DATA);


// ========================================================================
//
// True multi-read port using multiple BRAMs.  Highest performance and
// resource usage of all the modules.
//
// Most of the modules have a corresponding convenience wrapper for
// allocation with initialization to a constant value.  For other flavors
// of initialization use the general modules in the memory interface
// definition package.
//
// ========================================================================

//
// mkBRAMMultiRead --
//     Give the illusion of more read ports by replicating the RAM.
//
module mkBRAMMultiRead
    // interface:
    (BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    Vector#(n_READERS, BRAM#(t_ADDR, t_DATA)) rams <- replicateM(mkBRAM());
    Vector#(n_READERS, BROM#(t_ADDR, t_DATA)) portsLocal = newVector();

    // readPorts
    
    // The vector of read ports is just the read ports of the BRAMs.

    for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        portsLocal[p] = (interface BROM#(t_ADDR, t_DATA);
                             method readReq = rams[p].readReq;
                             method readRsp = rams[p].readRsp;
                             method t_DATA peek() = rams[p].peek;
                             method Bool notEmpty() = rams[p].notEmpty;
                             method Bool notFull() = rams[p].notFull;
                         endinterface);
    end

    interface readPorts = portsLocal;

 
    // write
    
    // When:   Any time
    // Effect: Replicate the writes to all the RAMs. 
 
    method Action write(t_ADDR a, t_DATA d);
        for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
        begin
            rams[p].write(a, d);
        end
    endmethod

    method Bool writeNotFull();
        Bool not_full = True;

        for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
        begin
            not_full = not_full && rams[p].notFull();
        end
    
        return not_full;
    endmethod
endmodule


//
// mkBRAMMultiReadInitialized --
//     Convenience implementation of mkBRAMMultiRead with constant initialization.
//
module mkBRAMMultiReadInitialized#(t_DATA initVal)
    // interface:
        (BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, data_SZ));

    BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA) mem <- mkBRAMMultiRead();
    
    BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA) m <- mkMultiMemInitialized(mem, initVal);
    return m;
endmodule



// ========================================================================
//
// Buffered pseudo multi read port is a middle ground between multiple
// BRAMs and the unbuffered implementation below.  Each response port
// has a private buffer, making response flow on one port independent
// of all other ports.  This avoids deadlocks possible in the unbuffered
// version.
//
// This module has the appearance of permitting multiple read requests
// in the same cycle, though the underlying implementation only satisfies
// one request per cycle.  As a side effect of the implementation,
// read and write requests are handled in separate cycles.
//
// The parameter "syncWrites" controls whether writes are ordered with
// reads:
//
//   - When true, the reads requested in a given cycle complete and then
//     the write requested during the same cycle completes.  Writes
//     from later cycles do not update memory until after reads requested
//     in earlier cycles have read their values.  This is a "safe" mode
//     but with lower performance, since writes are serialized with reads.
//
//   - When false, reads and writes are independent.  Since there is only
//     one write port, writes complete in the cycle they are requested.
//
// ========================================================================

module mkBRAMBufferedPseudoMultiRead#(Bool syncWrites)
    // interface:
    (BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),

              // Compute minimum size for storing read port ID (must be at least
              // 1 bit).
              Log#(n_READERS, n_READERS_SZ),
              Max#(n_READERS_SZ, 1, n_READERS_SAFE_SZ));

    // The primitive RAM.
    BRAM#(t_ADDR, t_DATA) ram <- mkBRAMUnguarded();

    let m <- syncWrites ? mkMemIfcToPseudoMultiMemSyncWrites(ram) :
                          mkMemIfcToPseudoMultiMemAsyncWrites(ram);

    return m;
endmodule


//
// mkBRAMBufferedPseudoMultiReadInitialized
//     Convenience implementation of mkBRAMBufferedPseudoMultiRead with constant initialization.
//
module mkBRAMBufferedPseudoMultiReadInitialized#(Bool syncWrites, t_DATA initVal)
    // interface:
    (BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA) mem <- mkBRAMBufferedPseudoMultiRead(syncWrites);
    
    BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA) m <- mkMultiMemInitialized(mem, initVal);
    return m;
endmodule



// ========================================================================
//
// Pseudo multi read port with all readers sharing a single underlying
// memory.  This version takes the least area.  BEWARE: all output ports
// share a single response buffer.  Reads on all ports are blocked until
// the response for the oldest request from any port is retrieved.
//
// Due to the write to readReqPort, only one readReq may fire at a time.
//
// ========================================================================

module mkBRAMPseudoMultiRead
    // interface:
    (BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    BRAM#(t_ADDR, t_DATA) ram <- mkBRAM();

    //
    // Beware the unguarded FIFO!  It is unguarded so notEmpty() for read ports
    // below has no predicates.
    //
    FIFOF#(Bit#(TLog#(n_READERS))) readReqPort <- mkUGFIFOF();

    //
    // readPorts
    //

    Vector#(n_READERS, BROM#(t_ADDR, t_DATA)) portsLocal = newVector();

    for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        portsLocal[p] =
            interface BROM#(t_ADDR, t_DATA);
                method Action readReq(t_ADDR a) if (readReqPort.notFull());
                    readReqPort.enq(fromInteger(p));
                    ram.readReq(a);
                endmethod

                method ActionValue#(t_DATA) readRsp() if (readReqPort.notEmpty() &&
                                                          (readReqPort.first() == fromInteger(p)));
                    readReqPort.deq();
                    let rsp <- ram.readRsp();
                    return rsp;
                endmethod

                method t_DATA peek() if (readReqPort.notEmpty() &&
                                         readReqPort.first() == fromInteger(p));
                    return ram.peek();
                endmethod

                method Bool notEmpty();
                    return ram.notEmpty() &&
                           readReqPort.notEmpty &&
                           (readReqPort.first() == fromInteger(p));
                endmethod

                method Bool notFull();
                    return ram.notFull() &&
                           readReqPort.notFull();
                endmethod
            endinterface;
    end

    interface readPorts = portsLocal;

 
    method write = ram.write;
    method writeNotFull = ram.writeNotFull;
endmodule

//
// mkBRAMPseudoMultiReadInitialized
//     Convenience implementation of mkBRAMPseudoMultiRead with constant initialization.
//
module mkBRAMPseudoMultiReadInitialized#(t_DATA initVal)
    // interface:
    (BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA) mem <- mkBRAMPseudoMultiRead();
    
    BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA) m <- mkMultiMemInitialized(mem, initVal);
    return m;
endmodule
