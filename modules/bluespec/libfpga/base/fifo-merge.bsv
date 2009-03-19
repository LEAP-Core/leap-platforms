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

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;
import RWire::*;

// ========================================================================
//
// MERGE_FIFOF
//
// A merge FIFO combines multiple input ports with FIFO-style inputs into
// a single output with a FIFO-style output.  The inputs are sorted
// temporally by arrival time.  When two inputs arrive in the same FPGA
// cycle on different ports, the lower numbered port has higher priority.
//
// ========================================================================

// Internal interface for input ports in the MERGE_FIFOF interface below.
interface MERGE_FIFOF_IN_PORT#(numeric type n_INPUTS, type t_DATA);
    method Action enq(t_DATA data);
    method Bool notFull();
endinterface: MERGE_FIFOF_IN_PORT

//
// MERGE_FIFOF has multiple input ports and a single output port.
//
interface MERGE_FIFOF#(numeric type n_INPUTS, type t_DATA);
    interface Vector#(n_INPUTS, MERGE_FIFOF_IN_PORT#(n_INPUTS, t_DATA)) ports;
    
    method t_DATA first();
    method Action deq();
    method Bool notEmpty();
endinterface: MERGE_FIFOF


//
// Standard merge FIFOF
//
module mkMergeFIFOF
    // interface:
    (MERGE_FIFOF#(n_INPUTS, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ));

    let m <- mkMergeFIFOFImpl(False);
    return m;
endmodule


//
// Bypass merge FIFOF.  Zero latency but introduces a dependence within a cycle
// between deq and enq.
//
module mkMergeBypassFIFOF
    // interface:
    (MERGE_FIFOF#(n_INPUTS, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ));

    let m <- mkMergeFIFOFImpl(True);
    return m;
endmodule


//
// Internal implementation of the merge FIFO, invoked by the exposed modules
// above.
//
module mkMergeFIFOFImpl#(Bool useBypassFIFO)
    // interface:
    (MERGE_FIFOF#(n_INPUTS, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ));

    // Queue that merges all input ports that arrive together into a single entry
    FIFOF#(Vector#(n_INPUTS, Maybe#(t_DATA))) dataQ <- (useBypassFIFO ? mkBypassFIFOF() : mkFIFOF());

    // Wire with data coming in this cycle
    Vector#(n_INPUTS, RWire#(t_DATA)) incomingData <- replicateM(mkRWire());

    // Mask of dataQ.first that has already been dequeued.
    Reg#(Vector#(n_INPUTS, Bool)) alreadyDeq <- mkReg(replicate(False));

    // Incoming port interfaces
    Vector#(n_INPUTS, MERGE_FIFOF_IN_PORT#(n_INPUTS, t_DATA)) portsLocal = newVector();

    //
    // mergeIncoming --
    //     Merge wires holding new data for this cycle into a single vector and
    //     queue it in the FIFO.
    //
    (* fire_when_enabled *)
    rule mergeIncoming (dataQ.notFull());
        //
        // Collect the incoming data into a single vector.
        //
        Vector#(n_INPUTS, Maybe#(t_DATA)) new_data = newVector();
        for (Integer p = 0; p < valueOf(n_INPUTS); p = p + 1)
        begin
            new_data[p] = incomingData[p].wget();
        end
        
        //
        // If any port has data write the vector to the FIFO.
        //
        if (any(isValid, new_data))
        begin
            dataQ.enq(new_data);
        end
    endrule

    //
    // Define the methods for incoming ports.
    //
    for (Integer p = 0; p < valueOf(n_INPUTS); p = p + 1)
    begin
        portsLocal[p] = (
            interface MERGE_FIFOF_IN_PORT;
                method Action enq(t_DATA data) if (dataQ.notFull());
                    incomingData[p].wset(data);
                endmethod

                method Bool notFull();
                    return dataQ.notFull();
                endmethod
            endinterface
        );
    end

    //
    // findFirstValidPort --
    //     Find the first port in the head of dataQ that is valid and
    //     has not been dequeued, according to the didDeq bit mask parameter.
    //
    function Maybe#(Integer) findFirstValidPort(Vector#(n_INPUTS, Bool) didDeq);
        let d = dataQ.first();

        // Find the lowest number input port with data that hasn't been dequeued.
        Maybe#(Integer) idx = tagged Invalid;
        for (Integer p = 0; p < valueOf(n_INPUTS); p = p + 1)
        begin
            if (isValid(d[p]) && ! didDeq[p] && ! isValid(idx))
            begin
                idx = tagged Valid p;
            end
        end
    
        return idx;
    endfunction


    method t_DATA first();
        // Based on the algorithm, findFirstValidPort must return a valid value.
        let idx = findFirstValidPort(alreadyDeq);
        return validValue(dataQ.first()[validValue(idx)]);
    endmethod

    method Action deq();
        // Mark current first element dequeued
        let idx = findFirstValidPort(alreadyDeq);
        let did_deq = alreadyDeq;
        did_deq[validValue(idx)] = True;
    
        // Any more valid entries from this set of data?
        if (findFirstValidPort(did_deq) matches tagged Invalid)
        begin
            // No more
            dataQ.deq();
            alreadyDeq <= replicate(False);
        end
        else
        begin
            // There are still more
            alreadyDeq <= did_deq;
        end
    endmethod

    method Bool notEmpty();
        return dataQ.notEmpty();
    endmethod

    interface ports = portsLocal;
endmodule
