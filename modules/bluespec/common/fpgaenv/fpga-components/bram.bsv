//
// Copyright (C) 2008 Intel Corporation
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
// Instantiate primitive Block RAM components and wrap them with nice guards.
//

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;
import RegFile::*;
import DReg::*;

`include "asim/provides/librl_bsv_base.bsh"


// ========================================================================
//
//  BRAM
//
// ========================================================================

// Standard BRAM interface

typedef MEMORY_IFC#(t_ADDR, t_DATA) BRAM#(type t_ADDR, type t_DATA);


//
// Internal, HW level BRAM interface.  This level has the minimum needed
// to read/write data.
//

interface BRAM_INTERNAL_IFC#(type t_ADDR, type t_DATA);
    method Action readReq(t_ADDR addr);
    method ActionValue#(t_DATA) readRsp();
    method Action write(t_ADDR addr, t_DATA val);
endinterface


//
// mkBRAMUnguardedNonZero --
//     Wrapper for the Verilog module that actually turns into a block RAM.
//
import "BVI" Bram = module mkBRAMUnguardedNonZero
    // interface:
    (BRAM_INTERNAL_IFC#(Bit#(addr_SZ), Bit#(data_SZ)));

    parameter addrSize = valueOf(addr_SZ);
    parameter dataSize = valueOf(data_SZ);
    parameter numRows = valueOf(TExp#(addr_SZ));

    default_reset rst (RST_N);
    default_clock clk (CLK);

    method readReq(readAddr) enable(readEnable);
    method readData readRsp() enable(readDataEnable);
    method write(writeAddr, writeData) enable(writeEnable);

    schedule readReq C readReq;
    schedule readRsp C readRsp;
    schedule write C write;
    schedule readReq CF (readRsp, write);
    schedule readRsp CF write;

endmodule


//
// mkBRAMUnguardedZero --
//     Special case used when address or data-width is zero.
//     *** Does not actually contain a RAM. ***
//
module mkBRAMUnguardedZero
    // interface:
    (BRAM_INTERNAL_IFC#(Bit#(addr_SZ), Bit#(data_SZ)));

    method Action readReq(Bit#(addr_SZ) a);
        noAction;
    endmethod

    method ActionValue#(Bit#(data_SZ)) readRsp();
        noAction;
        return ?;
    endmethod

    method Action write(Bit#(addr_SZ) a, Bit#(data_SZ) v);
        noAction;
    endmethod

endmodule


//
// mkBRAMUnguardedSim --
//     Simulation version of the BRAM using a register file.
//
module mkBRAMUnguardedSim
    // interface:
    (BRAM_INTERNAL_IFC#(Bit#(addr_SZ), Bit#(data_SZ)));

    RegFile#(Bit#(addr_SZ), Bit#(data_SZ))       ram <- mkRegFileWCF(minBound, maxBound);
    Reg#(Bit#(data_SZ))                      outputR <- mkRegU();

    method Action readReq(Bit#(addr_SZ) a);
        outputR <= ram.sub(a);
    endmethod

    method ActionValue#(Bit#(data_SZ)) readRsp();
        return outputR;
    endmethod

    method Action write(Bit#(addr_SZ) a, Bit#(data_SZ) d);
        ram.upd(a, d);
    endmethod

endmodule


//
// mkBRAMUnguarded --
//     Instantiate the appropriate BRAM based on parameters.
//
module mkBRAMUnguarded
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    `ifdef SYNTH
    let mem <- (valueOf(t_ADDR_SZ) == 0 || valueOf(t_DATA_SZ) == 0)? mkBRAMUnguardedZero(): mkBRAMUnguardedNonZero();
    `else
    let mem <- mkBRAMUnguardedSim();
    `endif

    method Action readReq(t_ADDR addr) = mem.readReq(pack(addr));

    method ActionValue#(t_DATA) readRsp();
        let m <- mem.readRsp();
        return unpack(m);
    endmethod

    method t_DATA peek() = ?;     // Don't use this method
    method Bool notEmpty() = ?;   // Don't use this method
    method Bool notFull() = True;

    method Action write(t_ADDR addr, t_DATA val) = mem.write(pack(addr), pack(val));
    method Bool writeNotFull() = True;
endmodule

//
// mkBypassBRAMUnguarded --
//     Creates an unguarded BRAM with a bypass path to handle the case of read and write touching the same address.
//     Librl provides a similar functionality (mkReadBeforeWriteMemory), but with guards.  
//
module mkBypassBRAMUnguarded
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Eq#(t_ADDR),
         Bits#(t_DATA, t_DATA_SZ));

    `ifdef SYNTH
    let mem <- (valueOf(t_ADDR_SZ) == 0 || valueOf(t_DATA_SZ) == 0)? mkBRAMUnguardedZero(): mkBRAMUnguardedNonZero();
    `else
    let mem <- mkBRAMUnguardedSim();
    `endif

    Reg#(Maybe#(t_ADDR)) readAddr <- mkDReg(tagged Invalid);
    Reg#(Maybe#(t_ADDR)) writeAddr <- mkDReg(tagged Invalid);
    Reg#(t_DATA) writeData <- mkRegU();

    method Action readReq(t_ADDR addr);
        mem.readReq(pack(addr));
        readAddr <= tagged Valid addr;
    endmethod

    method ActionValue#(t_DATA) readRsp();
       let m <- mem.readRsp();
       let result = unpack(m);

       if(readAddr matches tagged Valid .rAddr &&& 
           writeAddr matches tagged Valid .wAddr &&&
           rAddr == wAddr)
        begin
            result = writeData;    
        end
 
        return result;
    endmethod

    method t_DATA peek() = ?;     // Don't use this method
    method Bool notEmpty() = ?;   // Don't use this method
    method Bool notFull() = True;

    method Action write(t_ADDR addr, t_DATA val);
        mem.write(pack(addr), pack(val));
        writeData <= val;
        writeAddr <= tagged Valid addr;
    endmethod

    method Bool writeNotFull() = True;
endmodule



//
// mkBRAM --
//     The actual guarded BRAM. Uses the classic "turn a synchronous RAM into a
//     buffered RAM" Bluespec technique.
//
module mkBRAM
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    // The primitive RAM.
    BRAM#(t_ADDR, t_DATA) ram <- mkBRAMUnguarded();

    // Buffer the responses so nothing is dropped.
    FIFOF#(t_DATA) buffer <- mkSizedBypassFIFOF(2);

    // Is there a response coming from the unguarded RAM?
    COUNTER#(1) readReqMade <- mkLCounter(0);

    // How much buffering is available?
    COUNTER#(2) bufferingAvailable <- mkLCounter(2);

    // enqIntoFIFO
    
    // When:   The cycle after a readReq happens
    // Effect: Put the response into the buffer.

    rule enqIntoFIFO(readReqMade.value() == 1);
        readReqMade.down();
        let data <- ram.readRsp();
        buffer.enq(data);
    endrule

    // readReq
    
    // When:   Any time that sufficient buffering is available.
    // Effect: Make the request and reserve the buffering spot.

    method Action readReq(t_ADDR a) if (bufferingAvailable.value() > 0);
        ram.readReq(a);
        readReqMade.up();
        bufferingAvailable.down();
    endmethod

    // readRsp
    
    // When:   Any time there's something in the response buffer.
    // Effect: Deq the buffering and record the new space available.

    method ActionValue#(t_DATA) readRsp();
        bufferingAvailable.up();
        let v = buffer.first();
        buffer.deq();
        return v;
    endmethod
   
    method t_DATA peek() = buffer.first();
    method Bool notEmpty() = buffer.notEmpty();
    method Bool notFull() = (bufferingAvailable.value() > 0);

    // write
    
    // When:   Any time.
    // Effect: Just update the RAM.

    // ***
    // Do NOT make "if (bufferingAvailable.value() > 0)" a requirement for
    // all writes.  There are some algorithms (such as in the central cache)
    // where write/read order slips prevent deadlocks.  Code that needs
    // absolute read/write orders when reads block will need to manage
    // the order on its own.
    // ***

    method Action write(t_ADDR a, t_DATA d);
        ram.write(a, d);
    endmethod

    method Bool writeNotFull() = True;
endmodule


//
// mkBRAMInitializedWith --
//     Makes a BRAM and initializes it using an FSM.  The RAM cannot be accessed
//     until the FSM is done.   Uses an ADDR->VAL function to determine the
//     initial values.
//
module mkBRAMInitializedWith#(function t_DATA init(t_ADDR x))
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, data_SZ));

    // The primitive RAM.
    BRAM#(t_ADDR, t_DATA) mem <- mkBRAM();
    
    BRAM#(t_ADDR, t_DATA) m <- mkMemInitializedWith(mem, init);
    return m;
endmodule


//
// mkBRAMInitialized --
//     Initialize with a constant value.
//
module mkBRAMInitialized#(t_DATA initVal)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, data_SZ));

    // The primitive RAM.
    BRAM#(t_ADDR, t_DATA) mem <- mkBRAM();
    
    BRAM#(t_ADDR, t_DATA) m <- mkMemInitialized(mem, initVal);
    return m;
endmodule
