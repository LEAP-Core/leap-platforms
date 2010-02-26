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
    
    // The read port ID corresponding to the current first() value.
    method Bit#(TLog#(n_INPUTS)) firstPortID();

    method t_DATA first();
    method Action deq();
    method Bool notEmpty();

    // True iff current first() entry is the last in the oldest group if inputs.
    method Bool lastInGroup();
endinterface: MERGE_FIFOF


//
// Standard merge FIFOF
//
module mkMergeFIFOF
    // interface:
    (MERGE_FIFOF#(n_INPUTS, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ));

    FIFOF#(Vector#(n_INPUTS, Maybe#(t_DATA))) dataQ <- mkFIFOF();

    let m <- mkMergeFIFOFImpl(dataQ);
    return m;
endmodule


//
// Merge FIFO with LFIFO as the internal FIFO.
//
module mkMergeLFIFOF
    // interface:
    (MERGE_FIFOF#(n_INPUTS, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ));

    FIFOF#(Vector#(n_INPUTS, Maybe#(t_DATA))) dataQ <- mkLFIFOF();

    let m <- mkMergeFIFOFImpl(dataQ);
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

    FIFOF#(Vector#(n_INPUTS, Maybe#(t_DATA))) dataQ <- mkBypassFIFOF();

    let m <- mkMergeFIFOFImpl(dataQ);
    return m;
endmodule


//
// Internal implementation of the merge FIFO, invoked by the exposed modules
// above.
//
module mkMergeFIFOFImpl#(FIFOF#(Vector#(n_INPUTS, Maybe#(t_DATA))) dataQ)
    // interface:
    (MERGE_FIFOF#(n_INPUTS, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ));

    // Wire with data coming in this cycle
    Vector#(n_INPUTS, RWire#(t_DATA)) incomingData <- replicateM(mkRWire());

    // Mask of dataQ.first that has already been dequeued.
    Reg#(Vector#(n_INPUTS, Bool)) notDeqPort <- mkReg(replicate(True));

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
    // findValidPort --
    //     Find the first port in the head of dataQ that is valid and
    //     has not been dequeued, according to the didDeq bit mask parameter.
    //
    function Maybe#(UInt#(TLog#(n_INPUTS))) findValidPort(Vector#(n_INPUTS, Bool) notDeq);
        // Vector indicating valid incoming ports
        Vector#(n_INPUTS, Bool) valid_ports = map(isValid, dataQ.first());

        // Vector indicating valid incoming ports not yet seen
        Vector#(n_INPUTS, Bool) new_valid_ports = unpack(pack(valid_ports) &
                                                         pack(notDeq));

        return findElem(True, new_valid_ports);
    endfunction


    //
    // Rules to compute the output state of the merged FIFO.  We put this
    // computation in rules and write the value to wires in order to keep
    // the complex computation and vector reads out of the scheduling
    // predictes for the first() and deq() methods.
    //
    Wire#(Maybe#(UInt#(TLog#(n_INPUTS)))) firstIndex <- mkDWire(tagged Invalid);
    (* fire_when_enabled *)
    rule findFirstValidPort (True);
        // Compute the index of the next output value
        firstIndex <= findValidPort(notDeqPort);
    endrule

    // If output is available write the value to a wire for consumption by first().
    Wire#(Maybe#(t_DATA)) firstValue <- mkDWire(tagged Invalid);
    (* fire_when_enabled *)
    rule findFirstValue (firstIndex matches tagged Valid .idx);
        firstValue <= dataQ.first()[idx];
    endrule

    // Is first() element the last valid value in the head of the data queue?
    Wire#(Bool) firstIsLastInDataQ <- mkDWire(False);
    (* fire_when_enabled *)
    rule readyForDataDeq (firstIndex matches tagged Valid .idx);
        let not_deq = notDeqPort;
        not_deq[idx] = False;

        // Any more valid entries from this set of data?
        if (findValidPort(not_deq) matches tagged Invalid)
            firstIsLastInDataQ <= True;
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


    method Bit#(TLog#(n_INPUTS)) firstPortID() if (firstIndex matches tagged Valid .idx);
        return pack(idx);
    endmethod

    method t_DATA first() if (firstValue matches tagged Valid .v);
        return v;
    endmethod

    method Action deq() if (firstIndex matches tagged Valid .idx);
        // Mark current first element dequeued
        // Any more valid entries from this set of data?
        if (firstIsLastInDataQ)
        begin
            // No more
            dataQ.deq();
            notDeqPort <= replicate(True);
        end
        else
        begin
            // There are still more
            notDeqPort[idx] <= False;
        end
    endmethod

    method Bool notEmpty();
        return dataQ.notEmpty();
    endmethod

    method Bool lastInGroup();
        return firstIsLastInDataQ;
    endmethod

    interface ports = portsLocal;
endmodule
