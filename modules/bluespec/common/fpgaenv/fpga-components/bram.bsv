// bram

// Instantiate primitive Block RAM components and wrap them with nice guards.

import Counter::*;
import FIFO::*;
import Vector::*;
import RegFile::*;

// BRAM

// Standard BRAM interface

interface BRAM#(parameter type addr_T, parameter type data_T);

    method Action readReq(addr_T a);
    method ActionValue#(data_T) readRsp();

    method Action write(addr_T a, data_T v);

endinterface


// mkBRAMUnguardedNonZero

// An import of the primitive unguarded Verilog BRAM.

import "BVI" Bram = module mkBRAMUnguardedNonZero
    // interface:
        (BRAM#(Bit#(addr_SZ), Bit#(data_SZ)));

    parameter addrSize = valueOf(addr_SZ);
    parameter dataSize = valueOf(data_SZ);
    parameter numRows = valueOf(TExp#(addr_SZ));

    method readReq(readAddr) enable(readEnable) ready(readReady);
    method readData readRsp() enable(readDataEnable) ready(readDataReady);
    method write(writeAddr, writeData) enable(writeEnable) ready(writeReady);

    schedule readReq C readReq;
    schedule readRsp C readRsp;
    schedule write C write;
    schedule readReq CF (readRsp, write);
    schedule readRsp CF write;

endmodule


// mkBRAMUnguardedZero

// Used when address or data-width is zero.
// Does not actually contain a RAM.

module mkBRAMUnguardedZero
    // interface:
        (BRAM#(Bit#(addr_SZ), Bit#(data_SZ)));

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


// mkBRAMUnguardedSim

// Simulation version of the BRAM using a register file.

module mkBRAMUnguardedSim
    // interface:
        (BRAM#(Bit#(addr_SZ), Bit#(data_SZ)));

    RegFile#(Bit#(addr_SZ), Bit#(data_SZ))       ram <- mkRegFileFull();
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


// mkBRAMUnguarded

// Instantiate the appropriate BRAM based on parameters.

module mkBRAMUnguarded
    // interface:
        (BRAM#(Bit#(addr_SZ), Bit#(data_SZ)));

    `ifdef SYNTH
    let mem <- (valueOf(addr_SZ) == 0 || valueOf(data_SZ) == 0)? mkBRAMUnguardedZero(): mkBRAMUnguardedNonZero();
    `else
    let mem <- mkBRAMUnguardedSim();
    `endif
    return mem;

endmodule



// mkBRAM

// The actual guarded BRAM. Uses the classic
// "turn a synchronous RAM into a buffered RAM" 
// Bluespec technique.

module mkBRAM
    // interface:
        (BRAM#(addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, data_SZ));

    // The primitive RAM.
    BRAM#(Bit#(addr_SZ), Bit#(data_SZ)) ram <- mkBRAMUnguarded();

    // Buffer the responses so nothing is dropped.
    FIFO#(Bit#(data_SZ)) buffer <- mkFIFO();

    // Is there a response coming from the unguarded RAM?
    Counter#(1) readReqMade <- mkCounter(0);

    // How much buffering is available?
    Counter#(2) bufferingAvailable <- mkCounter(2);

    // enqIntoFIFO
    
    // When:   The cycle after a readReq happens
    // Effect: Put the response into the buffer.

    rule enqIntoFIFO(readReqMade.value() == 1);
        readReqMade.down();
        Bit#(data_SZ) data <- ram.readRsp();
        buffer.enq(data);
    endrule
    
    // readReq
    
    // When:   Any time that sufficient buffering is available.
    // Effect: Make the request and reserve the buffering spot.

    method Action readReq(addr_T a) if (bufferingAvailable.value() > 0);
        ram.readReq(pack(a));
        readReqMade.up();
        bufferingAvailable.down();
    endmethod

    // readRsp
    
    // When:   Any time there's something in the response buffer.
    // Effect: Deq the buffering and record the new space available.

    method ActionValue#(data_T) readRsp();
        bufferingAvailable.up();
        buffer.deq();
        return unpack(buffer.first());
    endmethod
   
    // write
    
    // When:   Any time.
    // Effect: Just update the RAM.
    // TODO:   Check that there is not a write to the same address as a simultaneous read.

    method Action write(addr_T a, data_T d);
        ram.write(pack(a), pack(d));
    endmethod

endmodule


// mkBRAMInitializedWith

// Makes a BRAM and initializes it using an FSM.
// The RAM cannot be accessed until the FSM is done.
// Uses an ADDR->VAL function to determine the initial values.

module mkBRAMInitializedWith#(function data_T init(addr_T x))
    // interface:
        (BRAM#(addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, data_SZ));

    // The primitive RAM.
    BRAM#(addr_T, data_T) mem <- mkBRAM();
    
    // The current adddress we're updating.
    Reg#(Bit#(addr_SZ))   cur <- mkReg(0);
    
    // Are we initializing?
    Reg#(Bool) initializing <- mkReg(True);

    // initialize
    
    // When:   After a reset until every value is initialized.
    // Effect: Update the RAM with the user-provided initial value.

    rule initialize (initializing);

        addr_T cur_a = unpack(cur);
        mem.write(cur_a, init(cur_a));
        cur <= cur + 1;

        if (cur + 1 == 0)
        begin
            initializing <= False;
        end

    endrule

    // readReq, readRsp, write
    
    // When:   Any time we're not initializing.
    // Effect: Just do the request.

    method Action readReq(addr_T a) if (!initializing);

        mem.readReq(a);

    endmethod

    method ActionValue#(data_T) readRsp();

        data_T rsp <- mem.readRsp();
        return rsp;

    endmethod

    method Action write(addr_T a, data_T d) if (!initializing);

        mem.write(a, d);

    endmethod

endmodule


// mkBRAMInitialized

// A convenience-wrapper of mkBRAMInitializedWith where the value is constant.

module mkBRAMInitialized#(data_T initval)
    // interface:
        (BRAM#(addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, data_SZ));

    // Wrap the data value in a dummy function.
    
    function data_T initfunc(addr_T a);
    
        return initval;
    
    endfunction

    // Just instantiate the RAM.
    BRAM#(addr_T, data_T) m <- mkBRAMInitializedWith(initfunc);
    
    return m;

endmodule
