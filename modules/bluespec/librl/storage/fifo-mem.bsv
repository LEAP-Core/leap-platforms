//
// Copyright (C) 2010 Intel Corporation
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
// FIFOs with data stored in a large memory (e.g. BRAM).
//

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;

`include "asim/provides/fpga_components.bsh"
`include "asim/provides/librl_bsv_base.bsh"


//
// mkSizedBRAMFIFO --
//     BRAM version of a memory FIFO.
//
module mkSizedBRAMFIFO#(NumTypeParam#(n_ENTRIES) p)
    // Interface:
    (FIFO#(t_DATA))
    provisos (Bits#(t_DATA, t_DATA_SZ));
     
    FIFOF#(t_DATA) fifof <- mkSizedBRAMFIFOF(p);
    return fifofToFifo(fifof);
endmodule


//
// mkSizedBRAMFIFOF --
//     BRAM version of a memory FIFOF.
//
module mkSizedBRAMFIFOF#(NumTypeParam#(n_ENTRIES) p)
    // Interface:
    (FIFOF#(t_DATA))
    provisos (Bits#(t_DATA, t_DATA_SZ));
     
    MEMORY_IFC#(Bit#(TLog#(n_ENTRIES)), t_DATA) mem <- mkBRAMUnguarded();
    FIFOF#(t_DATA) fifo <- mkMemoryFIFOF(p,mem);
    return fifo;
endmodule


//
// mkMemoryFIFOF --
//     Implement a FIFOF in the provided memory (e.g. BRAM).
//
//     To guarantee timing, the memory must have two characteristics:
//         1.  Reads and writes are unguarded.
//         2.  Read data is available one cycle following a read request.
//
//
module mkMemoryFIFOF#(NumTypeParam#(n_ENTRIES) p, MEMORY_IFC#(Bit#(TLog#(n_ENTRIES)), t_DATA) mem)
    // Interface:
    (FIFOF#(t_DATA))
    provisos (Bits#(t_DATA, t_DATA_SZ));
    
    Reg#(FUNC_FIFO_IDX#(n_ENTRIES)) state <- mkReg(funcFIFO_IDX_Init());


    //
    // updateState --
    //     Combine deq and enq requests into an update of the FIFO state.
    //     Also fetch the value that could be returned by first() in the
    //     next cycle.
    RWire#(t_DATA) enqData <- mkRWire();
    PulseWire deqReq <- mkPulseWire();
    PulseWire clearReq <- mkPulseWire();
    
    Reg#(Maybe#(t_DATA)) bypassFirstVal <- mkReg(tagged Invalid);

    (* fire_when_enabled *)
    (* no_implicit_conditions *)
    rule updateState (! clearReq);
        let new_state = state;
        Bool made_mem_req = False;
        
        // DEQ requested?
        if (deqReq)
        begin
            new_state = funcFIFO_IDX_UGdeq(new_state);
        end

        // After DEQ does the FIFO have more entries?  If yes, request the
        // value of the next entry.  It will be consumed by firstFromMem.
        if (funcFIFO_IDX_notEmpty(new_state))
        begin
            mem.readReq(funcFIFO_IDX_UGfirst(new_state));
            made_mem_req = True;
        end

        Maybe#(t_DATA) bypass_first = tagged Invalid;

        if (enqData.wget() matches tagged Valid .data)
        begin
            match {.s, .idx} = funcFIFO_IDX_UGenq(new_state);
            new_state = s;
            mem.write(idx, data);

            if (! made_mem_req)
            begin
                // No memory request is being issued this cycle either because
                // the FIFO was empty or is now empty following a deq.
                // Pass the new data directly to next cycle's first().
                bypass_first = tagged Valid data;
            end
        end

        bypassFirstVal <= bypass_first;
        state <= new_state;
    endrule


    //
    // The value for the first() method must be requested the previous cycle
    // since memory reads are two phases.  The value comes from the updateState
    // rule either as a bypass or as a memory read response.
    //
    RWire#(t_DATA) firstVal <- mkRWire();

    (* fire_when_enabled *)
    (* no_implicit_conditions *)
    rule firstFromBypass (bypassFirstVal matches tagged Valid .val);
        firstVal.wset(val);
    endrule

    (* fire_when_enabled *)
    (* no_implicit_conditions *)
    rule firstFromMemRsp (! isValid(bypassFirstVal) &&
                          funcFIFO_IDX_notEmpty(state));
        let v <- mem.readRsp();
        firstVal.wset(v);
    endrule


    // ====================================================================
    //
    // Methods
    //
    // ====================================================================

    method Action enq(t_DATA data) if (funcFIFO_IDX_notFull(state) && ! clearReq);
        enqData.wset(data);
    endmethod

    method t_DATA first() if (firstVal.wget() matches tagged Valid .val);
        return val;
    endmethod

    method Action deq() if (firstVal.wget() matches tagged Valid .val &&&
                            ! clearReq);
        deqReq.send();
    endmethod

    method Action clear();
        clearReq.send();
        state <= funcFIFO_IDX_Init();
    endmethod

    method Bool notEmpty();
        return funcFIFO_IDX_notEmpty(state);
    endmethod

    method Bool notFull();
        return funcFIFO_IDX_notFull(state);
    endmethod
endmodule



module mkSizedLUTRAMFIFOF#(NumTypeParam#(t_DEPTH) dummy) 
  //
  //interface:
              (FIFOF#(data_T))
  provisos
          (Bits#(data_T, data_SZ));

  LUTRAM#(Bit#(TLog#(t_DEPTH)), data_T) rs <- mkLUTRAMU();
  
  COUNTER#(TLog#(t_DEPTH)) head <- mkLCounter(0);
  COUNTER#(TLog#(t_DEPTH)) tail <- mkLCounter(0);

  Bool full  = head.value() == (tail.value() + 1);
  Bool empty = head.value() == tail.value();
    
  method Action enq(data_T d) if (!full);
  
    rs.upd(tail.value(), d);
    tail.up();
   
  endmethod  
  
  method data_T first() if (!empty);
    
    return rs.sub(head.value());
  
  endmethod   
  
  method Action deq();
  
    head.up();
    
  endmethod

  method Action clear();
  
    tail.setC(0);
    head.setC(0);
    
  endmethod

  method Bool notEmpty();
    return !empty;
  endmethod
  
  method Bool notFull();
    return !full;
  endmethod

endmodule

module mkSizedLUTRAMFIFO#(NumTypeParam#(t_DETPH) dummy) (FIFO#(data_T))
  provisos
          (Bits#(data_T, data_SZ));

    let q <- mkSizedLUTRAMFIFOF(dummy);
    return fifofToFifo(q);

endmodule
