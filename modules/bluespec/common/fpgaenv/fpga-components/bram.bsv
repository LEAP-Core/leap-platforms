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
// Instantiate primitive Block RAM components and wrap them with nice guards.
//

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;
import RegFile::*;
import DReg::*;
import AlignedFIFOs::*;
import Connectable::*;
import GetPut::*;


`include "awb/provides/librl_bsv_base.bsh"


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
// mkBRAMUnguardedNonZeroSized --
//     Wrapper for the Verilog module that actually turns into a block RAM.
//
import "BVI" Bram = module mkBRAMUnguardedNonZeroSized#(Integer bram_SZ)
    // interface:
    (BRAM_INTERNAL_IFC#(Bit#(t_ADDR_SZ), Bit#(t_DATA_SZ)));

    parameter addrSize = valueOf(t_ADDR_SZ);
    parameter dataSize = valueOf(t_DATA_SZ);
    parameter numRows = bram_SZ;

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
// mkBRAMUnguardedNonZero --
//     Wrapper for the Verilog module that actually turns into a block RAM.
//
module mkBRAMUnguardedNonZero
    // interface:
    (BRAM_INTERNAL_IFC#(Bit#(t_ADDR_SZ), Bit#(t_DATA_SZ)));

    let m <- mkBRAMUnguardedNonZeroSized(valueOf(TExp#(t_ADDR_SZ)));
    return m;

endmodule


//
// mkBRAMUnguardedZero --
//     Special case used when address or data-width is zero.
//     *** Does not actually contain a RAM. ***
//
module mkBRAMUnguardedZero
    // interface:
    (BRAM_INTERNAL_IFC#(Bit#(t_ADDR_SZ), Bit#(t_DATA_SZ)));

    method Action readReq(Bit#(t_ADDR_SZ) a);
        noAction;
    endmethod

    method ActionValue#(Bit#(t__SZ)) readRsp();
        noAction;
        return ?;
    endmethod

    method Action write(Bit#(t_ADDR_SZ) a, Bit#(t_DATA_SZ) v);
        noAction;
    endmethod

endmodule


//
// mkBRAMUnguardedSim --
//     Simulation version of the BRAM using a register file.
//
module mkBRAMUnguardedSim
    // interface:
    (BRAM_INTERNAL_IFC#(Bit#(t_ADDR_SZ), Bit#(t_DATA_SZ)));

    RegFile#(Bit#(t_ADDR_SZ), Bit#(t_DATA_SZ))       ram <- mkRegFileWCF(minBound, maxBound);
    Reg#(Bit#(t_DATA_SZ))                      outputR <- mkRegU();

    method Action readReq(Bit#(t_ADDR_SZ) a);
        outputR <= ram.sub(a);
    endmethod

    method ActionValue#(Bit#(t_DATA_SZ)) readRsp();
        return outputR;
    endmethod

    method Action write(Bit#(t_ADDR_SZ) a, Bit#(t_DATA_SZ) d);
        ram.upd(a, d);
    endmethod

endmodule

//
// mkBRAMUnguardedSized --
//     Instantiate the appropriate BRAM based on parameters.  Unlike the other BRAM versions, 
//     this BRAM does not necessarily fill the full address space.  Instead, we instantiate a 
//     set of small BRAMs which fill the same function. 
//
module mkBRAMUnguardedSized#(Integer bram_size)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));


    `ifndef SYNTH_Z
    let mem <- (valueOf(t_ADDR_SZ) == 0 || valueOf(t_DATA_SZ) == 0)? mkBRAMUnguardedZero(): mkBRAMUnguardedNonZeroSized(bram_size);
    `else
    let mem <- mkBRAMUnguardedSim();
    `endif

    method Action readReq(t_ADDR addr);
        mem.readReq(pack(addr));

        Bit#(TAdd#(1,t_ADDR_SZ)) addrExtended = zeroExtend(pack(addr)); 
        if(addrExtended > fromInteger(bram_size))
        begin
            $display("Warning: Read beyond end of BRAM with size %d: %d", bram_size, addr);
        end
    endmethod

    method ActionValue#(t_DATA) readRsp();
        let m <- mem.readRsp();
        return unpack(m);
    endmethod

    method t_DATA peek() = ?;     // Don't use this method
    method Bool notEmpty() = ?;   // Don't use this method
    method Bool notFull() = True;

    method Action write(t_ADDR addr, t_DATA val);
        mem.write(pack(addr), pack(val));

        Bit#(TAdd#(1,t_ADDR_SZ)) addrExtended = zeroExtend(pack(addr)); 
        if(addrExtended > fromInteger(bram_size))
        begin
            $display("Warning: Write beyond end of BRAM with size %d: %d", bram_size, addr);
        end
    endmethod
    method Bool writeNotFull() = True;
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

    let m <- mkBRAMUnguardedSized(valueOf(TExp#(t_ADDR_SZ)));
    return m;
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

    `ifndef SYNTH_Z
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
// mkBRAMSizedM --
//     The actual guarded BRAM. Uses the classic "turn a synchronous RAM into a
//     buffered RAM" Bluespec technique.  Takes a constructor arguement.
//
module [m] mkBRAMSizedM#(Integer bram_size, function m#(BRAM#(t_ADDR, t_DATA)) ramImpl(Integer ramImpl_size))
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (IsModule#(m, a__),
         Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    // The primitive RAM.
    BRAM#(t_ADDR, t_DATA) ram <- ramImpl(bram_size);

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
// mkBRAMSized --
//     The actual guarded BRAM. Uses the classic "turn a synchronous RAM into a
//     buffered RAM" Bluespec technique.
//
module mkBRAMSized#(Integer bram_size)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    let m <- mkBRAMSizedM(bram_size, mkBRAMUnguardedSized);

    return m;
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

    let m <- mkBRAMSized(valueOf(TExp#(t_ADDR_SZ)));
    return m;
endmodule


//
// mkRamImpl --
//    Helper for making a fully elaborated RAM constructor look like one that takes an
//    argument.  Necessary for making constructor types match.
//
module [m] mkRamImpl#(function m#(BRAM#(t_ADDR, t_DATA)) ramImpl, Integer bram_size)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (IsModule#(m, a__),
         Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ)); 

    let m <- ramImpl();
    return m;
endmodule

//
// mkBRAMM --
//     The actual guarded BRAM. Uses the classic "turn a synchronous RAM into a
//     buffered RAM" Bluespec technique.  Takes a mondaic constructor for 
//     underlying ram implementation.
//
module [m] mkBRAMM#(function m#(BRAM#(t_ADDR, t_DATA)) ramImpl)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (
         IsModule#(m, a__),
         Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    let m <- mkBRAMSizedM(valueOf(TExp#(t_ADDR_SZ)), mkRamImpl(ramImpl));
    return m;
endmodule

//
// mkBRAMClockDividerM --
//     Wrap BRAM in a clock divided interface and run it at half speed.
//
module [m] mkBRAMClockDividerM#(function m#(BRAM#(t_ADDR, t_DATA)) ramImpl)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (IsModule#(m, a__),
         Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    let baseClock <- exposeCurrentClock();
    let baseReset <- exposeCurrentReset();

    let bramClock <- mkUserClock_Divider(2);

    // For now, we just wrap the underlying BRAM. 
    BRAM#(t_ADDR, t_DATA) ram <- ramImpl(clocked_by bramClock.clk.slowClock, reset_by bramClock.rst);

    Store#(UInt#(1), t_ADDR, 0) readQueueStore <-
        mkRegVectorStore(baseClock, bramClock.clk.slowClock);
    AlignedFIFO#(t_ADDR) readQueue <-
        mkAlignedFIFO(baseClock, baseReset,
                      bramClock.clk.slowClock, bramClock.rst,
                      readQueueStore, bramClock.clk.clockReady, True);

    Store#(UInt#(1), Tuple2#(t_ADDR, t_DATA), 0) writeQueueStore <-
        mkRegVectorStore(baseClock, bramClock.clk.slowClock);
    AlignedFIFO#(Tuple2#(t_ADDR, t_DATA)) writeQueue <-
        mkAlignedFIFO(baseClock, baseReset,
                      bramClock.clk.slowClock, bramClock.rst,
                      writeQueueStore, bramClock.clk.clockReady, True);

    Store#(UInt#(1), t_DATA, 0) responseQueueStore <-
        mkRegVectorStore(bramClock.clk.slowClock, baseClock);
    AlignedFIFO#(t_DATA) responseQueue <-
        mkAlignedFIFO(bramClock.clk.slowClock, bramClock.rst,
                      baseClock, baseReset,
                      responseQueueStore, True, bramClock.clk.clockReady);

    // Bypass FIFO used to put readQueue.enq inside a rule (instead of a method)
    FIFOF#(t_ADDR) readReqQ <- mkBypassFIFOF();
    mkConnection(toGet(readReqQ), toPut(readQueue));
    
    rule moveReadReq;
        readQueue.deq();
        ram.readReq(readQueue.first);
    endrule

    rule moveWriteReq;
        writeQueue.deq();
        ram.write(tpl_1(writeQueue.first), tpl_2(writeQueue.first));
    endrule

    rule moveReadResp;
        let data <- ram.readRsp();
        responseQueue.enq(data);
    endrule

    // readReq
    
    // When:   Any time that sufficient buffering is available.
    // Effect: Make the request and reserve the buffering spot.

    method Action readReq(t_ADDR a);
        readReqQ.enq(a);
    endmethod

    // readRsp
    
    // When:   Any time there's something in the response buffer.
    // Effect: Deq the buffering and record the new space available.

    method ActionValue#(t_DATA) readRsp();
        responseQueue.deq;
        return responseQueue.first;
    endmethod
   
    method t_DATA peek()   = responseQueue.first();
    method Bool notEmpty() = responseQueue.dNotEmpty();
    method Bool notFull()  = readReqQ.notFull();

    // write
    
    // When:   Any time.
    // Effect: Just update the RAM.

    method Action write(t_ADDR a, t_DATA d);
        writeQueue.enq(tuple2(a, d));
    endmethod

    method Bool writeNotFull() = writeQueue.sNotFull();
endmodule


//
// mkBRAMClockDivider --
//     Wrapper for monadic version.
//
module mkBRAMClockDivider
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    let _m <- mkBRAMClockDividerM(mkBRAM);
    return _m;
endmodule

//
// mkBRAMSizedClockDivider --
//     Wrapper for monadic version.
//
module mkBRAMSizedClockDivider#(Integer bram_size)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    let _m <- mkBRAMClockDividerM(mkBRAMSized(bram_size));
    return _m;
endmodule


//
// mkBRAMSizedBuffered --
//     A wrapper of the guarded BRAM with buffers (FIFOs) for requests 
// and responses. 
//
module mkBRAMSizedBuffered#(Integer bram_size)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    BRAM#(t_ADDR, t_DATA) bram <- mkBRAMSized(bram_size);
    FIFOF#(t_ADDR) incomingReadReqQ <- mkFIFOF();
    FIFOF#(Tuple2#(t_ADDR, t_DATA)) incomingWriteReqQ <- mkFIFOF();
    FIFOF#(t_DATA) responseQ <- mkFIFOF();

    rule fwdReadReq(True);
       let addr = incomingReadReqQ.first();
       incomingReadReqQ.deq();
       bram.readReq(addr);   
    endrule
    
    rule fwdWriteReq(True);
       match {.addr, .data} = incomingWriteReqQ.first();
       incomingWriteReqQ.deq();
       bram.write(addr, data);
    endrule

    rule recvResp (True);
       let r <- bram.readRsp();
       responseQ.enq(r);
    endrule

    method Action readReq(t_ADDR addr);
        incomingReadReqQ.enq(addr);
    endmethod

    method ActionValue#(t_DATA) readRsp();
        let r = responseQ.first();
        responseQ.deq();
        return r;
    endmethod

    method t_DATA peek();
        return responseQ.first();
    endmethod

    method Bool notEmpty() = responseQ.notEmpty();
    method Bool notFull() = incomingReadReqQ.notFull();

    method Action write(t_ADDR addr, t_DATA val);
        incomingWriteReqQ.enq(tuple2(addr, val));
    endmethod
    method Bool writeNotFull() = True;

endmodule

//
// mkBRAMBuffered --
//     A wrapper of the guarded BRAM with buffers (FIFOs) for requests 
// and responses. 
//
module mkBRAMBuffered
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    let m <- mkBRAMSizedBuffered(valueOf(TExp#(t_ADDR_SZ)));
    return m;

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
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

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
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    // The primitive RAM.
    BRAM#(t_ADDR, t_DATA) mem <- mkBRAM();
    
    BRAM#(t_ADDR, t_DATA) m <- mkMemInitialized(mem, initVal);
    return m;
endmodule


//
// mkBRAMInitializedBuffered --
//     Initialize with a buffered BRAM with a constant value.
//
module mkBRAMInitializedBuffered#(t_DATA initVal)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    // The primitive RAM.
    BRAM#(t_ADDR, t_DATA) mem <- mkBRAMBuffered();
    
    BRAM#(t_ADDR, t_DATA) m <- mkMemInitialized(mem, initVal);
    return m;
endmodule


//
// mkBRAMInitializedClockDivider --
//     Initialize with a constant value, but uses the clock divider BRAM constructor.
//
module mkBRAMInitializedClockDivider#(t_DATA initVal)
    // interface:
        (BRAM#(t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ));

    // The primitive RAM.
    BRAM#(t_ADDR, t_DATA) mem <- mkBRAMClockDivider();
    
    BRAM#(t_ADDR, t_DATA) m <- mkMemInitialized(mem, initVal);
    return m;
endmodule


//
// mkBRAMSizedLog2 --
//     Creates a non-power of two memory.  This memory is most useful in hacking around AR 61995.  
//     This wrapper creates a full ram if the memory size is too large, and calls a recursive RAM 
//     generator if the memory size is too small.
//
module mkBRAMSizedLog2#(Integer mem_size)
    // interface:
        (MEMORY_IFC#(t_ADDR, t_DATA))
    provisos
        (
         Bits#(t_ADDR, t_ADDR_SZ),
         Bits#(t_DATA, t_DATA_SZ)         
        );

    MEMORY_IFC#(t_ADDR, t_DATA) m;

    // convert size to a slighly larger bit representation.

    // If the size is larger than the address space, 
    if(mem_size > valueof(TExp#(t_ADDR_SZ))) 
    begin
        m <- mkBRAM();
    end  
    else
    begin
        Bit#(TAdd#(t_ADDR_SZ,1)) mem_size_extended = fromInteger(mem_size);
        Bit#(t_ADDR_SZ) mem_size_base = truncate(mem_size_extended);         
        let mem <- mkBRAMM(mkBRAMSizedLog2Helper(unpack(mem_size_base)));

        m = interface MEMORY_IFC;
            method Action readReq(t_ADDR addr);
                mem.readReq(unpack(pack(addr)));
            endmethod

            method readRsp = mem.readRsp;

            method peek = mem.peek;    
            method notEmpty = mem.notEmpty;
            method notFull = mem.notFull();

            method Action write(t_ADDR addr, t_DATA val);
                mem.write(unpack(pack(addr)), val);
            endmethod

            method writeNotFull = mem.writeNotFull;
        endinterface;              

    end

    return m;
endmodule


//
// mkBRAMSizedLog2Helper --
//     Does the heavy lifting of creating a non-power of two memory. If the mem_size is 1, we 
//     create a half size BRAM and pair it with a half-sized memory created by a recursive call, which 
//     constructs the remainder of the address space. If mem_size is 0, this part of the address space 
//     is empty, and we do not create a half-sized BRAM. We terminate if the remainder of the address 
//     space is empty, or if the address space is so small that we can capture it in a single BRAM.      
//
module mkBRAMSizedLog2Helper#(Vector#(t_ADDR_SZ,Bit#(1)) mem_size)
    // interface:
        (MEMORY_IFC#(Vector#(t_ADDR_SZ,Bit#(1)), t_DATA))
    provisos
        (Bits#(t_DATA, t_DATA_SZ));

    MEMORY_IFC#(Vector#(t_ADDR_SZ,Bit#(1)), t_DATA) m;

    // If there's no more address space left, we don't require more memory.
    if(pack(mem_size) == 0) 
    begin  
        m = ?;
    end 
    // If we have a small address space, just build the memory.
    else if(valueof(t_ADDR_SZ) < 10) 
    begin  
        m <- mkBRAMUnguarded();
    end
    // In this case, we have a local memory. 
    else if(reverse(mem_size)[0] == 1'b1)
    begin
        // this is a half size memory, where we will send the lower half of the address space.
        MEMORY_IFC#(Vector#(TSub#(t_ADDR_SZ,1),Bit#(1)), t_DATA) memBottomHalf  <- mkBRAMUnguarded();
        MEMORY_IFC#(Vector#(TSub#(t_ADDR_SZ,1),Bit#(1)), t_DATA) memTopHalf <- mkBRAMSizedLog2Helper(take(mem_size));

        FIFOF#(Bit#(1)) oneRemoteZeroLocal <- mkFIFOF();

        m = interface MEMORY_IFC;
            method Action readReq(Vector#(t_ADDR_SZ,Bit#(1)) addr);
                memBottomHalf.readReq(take(addr));
                memTopHalf.readReq(take(addr));
                oneRemoteZeroLocal.enq(reverse(addr)[0]);
            endmethod

            method ActionValue#(t_DATA) readRsp();
                let memBottomHalfResp <- memBottomHalf.readRsp();
                let memTopHalfResp <- memTopHalf.readRsp();
                oneRemoteZeroLocal.deq();
                let result = memBottomHalfResp;
                if(oneRemoteZeroLocal.first() == 1)
                begin
                    result = memTopHalfResp;
                end
                return result;
            endmethod

            method t_DATA peek() = (oneRemoteZeroLocal.first() == 0) ? memBottomHalf.peek() : memTopHalf.peek();    
            method Bool notEmpty() = oneRemoteZeroLocal.notEmpty();   
            method Bool notFull() = oneRemoteZeroLocal.notFull();

            method Action write(Vector#(t_ADDR_SZ,Bit#(1)) addr, t_DATA val);
                if(reverse(addr)[0] == 1'b0)
                begin
                    memBottomHalf.write(take(addr), val);
                end
                else
                begin 
                    memTopHalf.write(take(addr), val);
                end
            endmethod

            method Bool writeNotFull() = memBottomHalf.writeNotFull && memTopHalf.writeNotFull;
        endinterface;        
        
    end
    else
    begin
        MEMORY_IFC#(Vector#(TSub#(t_ADDR_SZ,1),Bit#(1)), t_DATA) memBottomHalf <- mkBRAMSizedLog2Helper(take(mem_size));
        
        m = interface MEMORY_IFC;
            method Action readReq(Vector#(t_ADDR_SZ,Bit#(1)) addr);
                memBottomHalf.readReq(take(addr));
            endmethod

            method readRsp = memBottomHalf.readRsp;

            method peek = memBottomHalf.peek;   
            method notEmpty = memBottomHalf.notEmpty;  
            method notFull = memBottomHalf.notFull();

            method Action write(Vector#(t_ADDR_SZ,Bit#(1)) addr, t_DATA val);
                memBottomHalf.write(take(addr), val);
            endmethod

            method writeNotFull = memBottomHalf.writeNotFull;
        endinterface;              
    end

    return m;
endmodule



