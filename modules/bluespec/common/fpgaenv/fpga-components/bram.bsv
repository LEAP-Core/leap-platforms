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
import SpecialFIFOs::*;
import Vector::*;
import RegFile::*;


// ========================================================================
//
//  BRAM
//
// ========================================================================

// Standard BRAM interface

interface BRAM#(parameter type addr_T, parameter type data_T);
    method Action readReq(addr_T a);
    method ActionValue#(data_T) readRsp();

    method Action write(addr_T a, data_T v);
endinterface


//
// mkBRAM_BVI --
//     Wrapper for the Verilog module that actually turns into a block RAM.
//
import "BVI" Bram = module mkBRAM_BVI
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


//
// mkBRAMUnguardedNonZero --
//     Pass requests to the Verilog wrapper.  Continue to hold the read request
//     address of the last request.  This allows us to reduce the output FIFO
//     size by one entry and save FPGA area since addr_SZ is typically
//     smaller than data_SZ.  It also lets us use a generic bypass FIFO instead
//     of having to write a new 2-entry bypass FIFO.
//
module mkBRAMUnguardedNonZero
    // interface:
        (BRAM#(Bit#(addr_SZ), Bit#(data_SZ)));

    BRAM#(Bit#(addr_SZ), Bit#(data_SZ)) ram <- mkBRAM_BVI();

    // Address from last read request    
    Reg#(Bit#(addr_SZ)) holdAddr <- mkRegU();
    // Pass new addresses from readReq() method to updateAddr() rule.
    RWire#(Bit#(addr_SZ)) newAddr <- mkRWire();

    //
    // Read request is asserted every cycle using either a new address if it
    // arrives via readReq() below or the cached address from the last request.
    //
    rule updateAddr (True);
        Bit#(addr_SZ) addr;

        if (newAddr.wget() matches tagged Valid .new_a)
        begin
            holdAddr <= new_a;
            addr = new_a;
        end
        else
        begin
            addr = holdAddr;
        end

        ram.readReq(addr);
    endrule

    method Action readReq(Bit#(addr_SZ) a);
        newAddr.wset(a);
    endmethod

    method ActionValue#(Bit#(data_SZ)) readRsp();
        let v <- ram.readRsp();
        return v;
    endmethod

    method Action write(Bit#(addr_SZ) a, Bit#(data_SZ) v);
        ram.write(a, v);
    endmethod

endmodule


//
// mkBRAMUnguardedZero --
//     Special case used when address or data-width is zero.
//     *** Does not actually contain a RAM. ***
//
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


//
// mkBRAMUnguardedSim --
//     Simulation version of the BRAM using a register file.
//
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


//
// mkBRAMUnguarded --
//     Instantiate the appropriate BRAM based on parameters.
//
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



//
// mkBRAM --
//     The actual guarded BRAM. Uses the classic "turn a synchronous RAM into a
//     buffered RAM" Bluespec technique.
//
module mkBRAM
    // interface:
        (BRAM#(addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, data_SZ));

    // The primitive RAM.
    BRAM#(Bit#(addr_SZ), Bit#(data_SZ)) ram <- mkBRAMUnguarded();

    // Buffer the responses so nothing is dropped.  Bypass FIFO has 0 cycle
    // latency for enq -> deq.
    FIFO#(Bit#(data_SZ)) buffer <- mkBypassFIFO();

    // Is there a response coming from the unguarded RAM?
    COUNTER#(1) readReqMade <- mkLCounter(0);

    // How much buffering is available?
    COUNTER#(2) bufferingAvailable <- mkLCounter(2);

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
        let v = buffer.first();
        buffer.deq();
        return unpack(v);
    endmethod
   
    // write
    
    // When:   Any time.
    // Effect: Just update the RAM.
    // TODO:   Check that there is not a write to the same address as a simultaneous read.

    method Action write(addr_T a, data_T d);
        ram.write(pack(a), pack(d));
    endmethod

endmodule


//
// mkBRAMInitializedWith --
//     Makes a BRAM and initializes it using an FSM.  The RAM cannot be accessed
//     until the FSM is done.   Uses an ADDR->VAL function to determine the
//     initial values.
//
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


    // initialize --
    //     When:   After a reset until every value is initialized.
    //     Effect: Update the RAM with the user-provided initial value.
    //
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
    //     When:   Any time we're not initializing.
    //     Effect: Just do the request.

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


//
// mkBRAMInitialized --
//     A convenience-wrapper of mkBRAMInitializedWith where the value is
//     constant.
//
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



// ========================================================================
//
//  Counter type used by the BRAM code.  The standard Bluespec counter
//  package doesn't support simultaneous up/down firing in separate rules.
//  We need this for full BRAM read pipelining.
//
//  Ideally, this code would come from the utilities in the hasim library.
//  Unfortunately, the hasim library utilities depend on this code, so it
//  would cause a circular dependence.
//
// ========================================================================

// Code start with the Bluespec training samples...

interface COUNTER#(numeric type nBits);

    method Bit#(nBits) value();

    method Action up();
    method Action down();
    method Action setC(Bit#(nBits) newVal);

endinterface: COUNTER


module mkLCounter#(Bit#(nBits) initial_value)
    // interface:
        (COUNTER#(nBits));

    // Counter value
    Reg#(Bit#(nBits)) ctr <- mkReg(initial_value);

    PulseWire up_called   <- mkPulseWire();
    PulseWire down_called <- mkPulseWire();
    RWire#(Bit#(nBits)) setc_called <- mkRWire();

    (* fire_when_enabled, no_implicit_conditions *)
    rule update_counter;
        let new_value = ctr;

        if (setc_called.wget() matches tagged Valid .v)
            new_value = v;

        if (up_called == down_called)
            noAction;
        else if (up_called)
            new_value = new_value + 1;
        else
            new_value = new_value - 1;

        ctr <= new_value;
    endrule

    method Bit#(nBits) value();
        return ctr;
    endmethod

    method Action up();
        up_called.send();
    endmethod

    method Action down();
        down_called.send();
    endmethod

    method Action setC(Bit#(nBits) newVal);
        setc_called.wset(newVal);
    endmethod

endmodule: mkLCounter
