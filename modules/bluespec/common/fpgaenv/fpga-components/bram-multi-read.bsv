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
// ========================================================================

module mkBRAMBufferedPseudoMultiRead
    // interface:
    (BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),

              // Compute minimum size for storing read port ID (must be at least
              // 1 bit).
              Log#(n_READERS, n_READERS_SZ),
              Max#(n_READERS_SZ, 1, n_READERS_SAFE_SZ));

    // The primitive RAM.
    BRAM#(Bit#(t_ADDR_SZ), Bit#(t_DATA_SZ)) ram <- mkBRAMUnguarded();

    // Sort incoming requests.  One port for each read port and another for writes.
    MERGE_FIFOF#(TAdd#(n_READERS, 1), t_ADDR) incomingReqQ <- mkMergeBypassFIFOF();

    // Write data
    FIFO#(t_DATA) writeDataQ <- mkBypassFIFO();

    // Match requests to ports.  Add 1 to the number of readers to guarantee
    // we never try to allocate a Bit#(0).
    FIFO#(Bit#(n_READERS_SAFE_SZ)) noteReqQ <- mkFIFO();

    // How much buffering is available?
    Vector#(n_READERS, COUNTER#(2)) bufferingAvailable <- replicateM(mkLCounter(2));

    // Two stage output buffering, one entry in each stage for each read port.
    // See buffer0 and buffer1 in mkBRAM for more details.
    Vector#(n_READERS, FIFO#(Bit#(t_DATA_SZ))) buffer0 <- replicateM(mkBypassFIFO());
    Vector#(n_READERS, FIFOF#(Bit#(t_DATA_SZ))) buffer1 <- replicateM(mkBypassFIFOF());

    //
    // processWriteReq --
    //     Send writes to the BRAM.  Write port is the last port in the
    //     request queue.
    //
    rule processWriteReq (incomingReqQ.firstPortID() == fromInteger(valueOf(n_READERS)));
        let addr = incomingReqQ.first();
        incomingReqQ.deq();

        let val = writeDataQ.first();
        writeDataQ.deq();
        
        ram.write(pack(addr), pack(val));
    endrule


    //
    // Read rules
    //
    for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        //
        // processReadReq --
        //     Forward read requests to the memory.
        //
        rule processReadReq ((incomingReqQ.firstPortID() == fromInteger(p)) &&
                             (bufferingAvailable[p].value() > 0));
            let addr = incomingReqQ.first();
            incomingReqQ.deq();

            ram.readReq(pack(addr));

            noteReqQ.enq(fromInteger(p));
            bufferingAvailable[p].down();
        endrule

        //
        // enqIntoFIFO --
        //     First stage buffering.  Forward BRAM response to read port's
        //     response buffer chain.
        //
        rule enqIntoFIFO (noteReqQ.first() == fromInteger(p));
            noteReqQ.deq();

            Bit#(t_DATA_SZ) data <- ram.readRsp();
            buffer0[p].enq(data);
        endrule
    
        // Forward data between the two outgoing read buffers
        rule forwardReadData (True);
            let data = buffer0[p].first();
            buffer0[p].deq();
            buffer1[p].enq(data);
        endrule
    end
    

    //
    // readPorts
    //

    Vector#(n_READERS, BROM#(t_ADDR, t_DATA)) portsLocal = newVector();

    for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        portsLocal[p] =
            interface BROM#(t_ADDR, t_DATA);
                method Action readReq(t_ADDR a);
                    incomingReqQ.ports[p].enq(a);
                endmethod

                method ActionValue#(t_DATA) readRsp();
                    bufferingAvailable[p].up();

                    let v = buffer1[p].first();
                    buffer1[p].deq();

                    return unpack(v);
                endmethod

                method t_DATA peek() = unpack(buffer1[p].first());
                method Bool notEmpty() = buffer1[p].notEmpty();
                method Bool notFull() = incomingReqQ.ports[p].notFull();
            endinterface;
    end

    interface readPorts = portsLocal;

    method Action write(t_ADDR addr, t_DATA val);
        // Write port is the last of the incomingReqQ ports.
        incomingReqQ.ports[valueOf(n_READERS)].enq(addr);
        writeDataQ.enq(val);
    endmethod

    method Bool writeNotFull = incomingReqQ.ports[valueOf(n_READERS)].notFull();
endmodule


//
// mkBRAMBufferedPseudoMultiReadInitialized
//     Convenience implementation of mkBRAMBufferedPseudoMultiRead with constant initialization.
//
module mkBRAMBufferedPseudoMultiReadInitialized#(t_DATA initVal)
    // interface:
    (BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    BRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA) mem <- mkBRAMBufferedPseudoMultiRead();
    
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
