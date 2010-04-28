//
// Copyright (C) 2008 Massachusetts Institute of Technology
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

import Vector::*;
import RWire::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;

`include "asim/provides/librl_bsv_base.bsh"

// ========================================================================
//
// SCOREBOARD_FIFO --
//
//   A FIFO where objects flow out in the order they are allocated but
//   the data associated with a FIFO entry may arrive both late and out
//   of order.  Instead of taking data as an argument, the enq() method
//   returns a SCOREBOARD_FIFO_ENTRY_ID.  The value of the entry must be
//   set using the setValue() method before the entry may be accessed
//   as it exits the FIFO.
//
// ========================================================================

typedef Bit#(TLog#(t_NUM_ENTRIES)) SCOREBOARD_FIFO_ENTRY_ID#(numeric type t_NUM_ENTRIES);

interface SCOREBOARD_FIFOF#(numeric type t_NUM_ENTRIES, type t_DATA);
    method ActionValue#(SCOREBOARD_FIFO_ENTRY_ID#(t_NUM_ENTRIES)) enq();
    method Action setValue(SCOREBOARD_FIFO_ENTRY_ID#(t_NUM_ENTRIES) id, t_DATA data);
    method t_DATA first();
    method Action deq();
    method Bool notFull();
    method Bool notEmpty();
    
    // For debug output:
    method SCOREBOARD_FIFO_ENTRY_ID#(t_NUM_ENTRIES) deqEntryId();
endinterface


//
// mkScoreboardFIFOF --
//     A scoreboard FIFO with data stores in LUTs.
//
module mkScoreboardFIFOF
    // Interface:
    (SCOREBOARD_FIFOF#(t_NUM_ENTRIES, t_DATA))
    provisos(
        Bits#(t_DATA, t_DATA_SZ),
        Alias#(SCOREBOARD_FIFO_ENTRY_ID#(t_NUM_ENTRIES), t_SCOREBOARD_FIFO_ENTRY_ID));
    
    COUNTER#(TLog#(TAdd#(t_NUM_ENTRIES, 1))) nEntries <- mkLCounter(0);
    Vector#(t_NUM_ENTRIES, Reg#(t_DATA)) values <- replicateM(mkRegU());

    // Pointers to next enq and deq slots in the ring buffer
    Reg#(t_SCOREBOARD_FIFO_ENTRY_ID) nextEnq <- mkReg(0);
    Reg#(t_SCOREBOARD_FIFO_ENTRY_ID) nextDeq <- mkReg(0);

    // reqVec and readyVec are used to determine whether an entry's data is
    // ready.  When ready, the bits corresponding to an entry match.  Using
    // separate vectors for enq() and deq() avoids write contention.
    LUTRAM#(Bit#(TLog#(t_NUM_ENTRIES)), Bool) reqVec <- mkLUTRAMU();
    LUTRAM#(Bit#(TLog#(t_NUM_ENTRIES)), Bool) readyVec <- mkLUTRAMU();

    // Value flowing out from the FIFO to first() / deq().
    RWire#(t_DATA) exitVal <- mkRWire();
    Wire#(Bool) oldestIsReady <- mkDWire(False);

    function isNotFull() = (nEntries.value() != fromInteger(valueOf(t_NUM_ENTRIES)));
    function isNotEmpty() = (nEntries.value() != 0);


    Reg#(Bool) didInit <- mkReg(False);
    Reg#(Bit#(TLog#(t_NUM_ENTRIES))) initIdx <- mkReg(0);

    rule doInit (! didInit);
        reqVec.upd(initIdx, False);
        readyVec.upd(initIdx, False);

        if (initIdx == fromInteger(valueOf(TSub#(t_NUM_ENTRIES, 1))))
        begin
            didInit <= True;
        end

        initIdx <= initIdx + 1;
    endrule


    //
    // Send the outbound, oldest, value out on a wire instead of reading
    // the values in the methods below to avoid painfully slow Bluespec
    // scheduler attempts to see through subscripting.
    //
    (* fire_when_enabled, no_implicit_conditions *)
    rule checkOldest (didInit);
        //
        // To be ready there must be an entry in the queue and the reqVec bit
        // must match the readyVec bit for the oldest entry.
        //
        Bool ready = (reqVec.sub(nextDeq) == readyVec.sub(nextDeq));
        oldestIsReady <= isNotEmpty() && ready;
    endrule

    (* fire_when_enabled, no_implicit_conditions *)
    rule readOldest if (oldestIsReady);
        exitVal.wset(values[nextDeq]);
    endrule


    //
    // Rules supporting methods.  Here to avoid exposing a LUTRAM in a method.
    //

    //
    // allocSlot --
    //     Allocate a slot for the enq() method.  This rule must fire in the
    //     same cycle as the corresponding enq() or the slot may appear data
    //     ready before the data arrives.
    //
    RWire#(t_SCOREBOARD_FIFO_ENTRY_ID) allocSlot <- mkRWire();
    (* no_implicit_conditions *)
    (* fire_when_enabled *)
    rule doAllocSlot (didInit &&& allocSlot.wget() matches tagged Valid .slot);
        // Mark slot not data ready
        reqVec.upd(slot, ! reqVec.sub(slot));
    endrule


    //
    // valueReady --
    //     Data has arrived for a slot.
    //
    RWire#(t_SCOREBOARD_FIFO_ENTRY_ID) valueSlot <- mkRWire();
    (* no_implicit_conditions *)
    (* fire_when_enabled *)
    rule valueReady (didInit &&& valueSlot.wget() matches tagged Valid .slot);
        // Mark slot data ready
        readyVec.upd(slot, reqVec.sub(slot));
    endrule


    //
    // Methods
    //

    method ActionValue#(t_SCOREBOARD_FIFO_ENTRY_ID) enq() if (didInit && isNotFull());
        nEntries.up();

        // Mark FIFO slot as waiting for data
        let slot = nextEnq;
        allocSlot.wset(slot);
    
        // Update next slot pointer
        nextEnq <= slot + 1;

        return slot;
    endmethod

    method Action setValue(t_SCOREBOARD_FIFO_ENTRY_ID id, t_DATA data);
        valueSlot.wset(id);

        // Write value to buffer
        values[id] <= data;
    endmethod

    method t_DATA first() if (exitVal.wget() matches tagged Valid .v);
        return v;
    endmethod

    method Action deq() if (exitVal.wget() matches tagged Valid .v);
        // Pop oldest entry from FIFO
        nEntries.down();
        nextDeq <= nextDeq + 1;
    endmethod

    method Bool notFull();
        return isNotFull();
    endmethod

    method Bool notEmpty();
        return isNotEmpty();
    endmethod

    method SCOREBOARD_FIFO_ENTRY_ID#(t_NUM_ENTRIES) deqEntryId();
        return nextDeq;
    endmethod
endmodule


//
// mkBRAMScoreboardFIFOF --
//     A scoreboard FIFO with data stores in BRAM.  The code bypasses the
//     BRAM when first() and deq() are blocked waiting for incoming data,
//     so the timing should be similar to mkScoreboardFIFO.
//
module mkBRAMScoreboardFIFOF
    // Interface:
    (SCOREBOARD_FIFOF#(t_NUM_ENTRIES, t_DATA))
    provisos(
        Bits#(t_DATA, t_DATA_SZ),
        Alias#(SCOREBOARD_FIFO_ENTRY_ID#(t_NUM_ENTRIES), t_SCOREBOARD_FIFO_ENTRY_ID));
    
    COUNTER#(TLog#(TAdd#(t_NUM_ENTRIES, 1))) nEntries <- mkLCounter(0);
    BRAM#(t_SCOREBOARD_FIFO_ENTRY_ID, t_DATA) values <- mkBRAM();

    // Pointers to next enq and deq slots in the ring buffer
    Reg#(t_SCOREBOARD_FIFO_ENTRY_ID) nextEnq <- mkReg(0);
    Reg#(t_SCOREBOARD_FIFO_ENTRY_ID) nextDeq <- mkReg(0);

    // reqVec and readyVec are used to determine whether an entry's data is
    // ready.  When ready, the bits corresponding to an entry match.  Using
    // separate vectors for enq() and deq() avoids write contention.
    LUTRAM#(Bit#(TLog#(t_NUM_ENTRIES)), Bool) reqVec <- mkLUTRAMU();
    LUTRAM#(Bit#(TLog#(t_NUM_ENTRIES)), Bool) readyVec <- mkLUTRAMU();

    // Value flowing out from the FIFO to first() / deq().
    FIFOF#(Tuple2#(t_DATA, t_SCOREBOARD_FIFO_ENTRY_ID)) exitValQ <- mkBypassFIFOF();
    FIFOF#(t_SCOREBOARD_FIFO_ENTRY_ID) exitEntryIdQ <- mkFIFOF();

    FIFO#(Tuple2#(t_SCOREBOARD_FIFO_ENTRY_ID, t_DATA)) setValueQ <- mkBypassFIFO();
    RWire#(Tuple2#(t_SCOREBOARD_FIFO_ENTRY_ID, t_DATA)) bypassValue <- mkRWire();

    Wire#(Bool) oldestIsReady <- mkDWire(False);

    function isNotFull() = (nEntries.value() != fromInteger(valueOf(t_NUM_ENTRIES)));
    function isNotEmpty() = (nEntries.value() != 0);


    Reg#(Bool) didInit <- mkReg(False);
    Reg#(Bit#(TLog#(t_NUM_ENTRIES))) initIdx <- mkReg(0);

    rule doInit (! didInit);
        reqVec.upd(initIdx, False);
        readyVec.upd(initIdx, False);

        if (initIdx == fromInteger(valueOf(TSub#(t_NUM_ENTRIES, 1))))
        begin
            didInit <= True;
        end

        initIdx <= initIdx + 1;
    endrule


    //
    // Receive values.  This code could be in the setValue method but putting
    // it in a rule allows for more local scheduling control.
    //
    rule receiveValues (didInit);
        match {.id, .data} = setValueQ.first();
        setValueQ.deq();

        // Write value to buffer
        values.write(id, data);
        // Mark slot data ready
        readyVec.upd(id, reqVec.sub(id));
    
        // Forward value to bypass logic.
        bypassValue.wset(tuple2(id, data));
    endrule


    //
    // Compute whether oldest is ready to a wire to simplify scheduling predicates.
    //
    (* fire_when_enabled, no_implicit_conditions *)
    rule checkOldest (didInit);
        //
        // To be ready there must be an entry in the queue and the reqVec bit
        // must match the readyVec bit for the oldest entry.
        //
        Bool ready = (reqVec.sub(nextDeq) == readyVec.sub(nextDeq));
        oldestIsReady <= isNotEmpty() && ready;
    endrule

    //
    // Did the value for the oldest entry just arrive?  Bypass BRAM and forward
    // directly to the client.
    //
    rule bypassOldest if (! oldestIsReady &&&
                          ! exitEntryIdQ.notEmpty() &&&
                          bypassValue.wget() matches tagged Valid {.id, .data} &&&
                          id == nextDeq);
        nextDeq <= nextDeq + 1;
        nEntries.down();

        exitValQ.enq(tuple2(data, nextDeq));
    endrule

    //
    // Request outgoing value from BRAM when it is ready.
    //
    rule readReqOldest if (oldestIsReady);
        values.readReq(nextDeq);
        exitEntryIdQ.enq(nextDeq);
        nextDeq <= nextDeq + 1;
        nEntries.down();
    endrule

    //
    // Forward outgoing value from BRAM to the outgoing exitValQ FIFO.
    //
    (* descending_urgency = "readRespOldest, bypassOldest" *)
    rule readRespOldest (True);
        let v <- values.readRsp();

        let id = exitEntryIdQ.first();
        exitEntryIdQ.deq();

        exitValQ.enq(tuple2(v, id));
    endrule


    //
    // Rules supporting methods.  Here to avoid exposing a LUTRAM in a method.
    //

    //
    // allocSlot --
    //     Allocate a slot for the enq() method.  This rule must fire in the
    //     same cycle as the corresponding enq() or the slot may appear data
    //     ready before the data arrives.
    //
    RWire#(t_SCOREBOARD_FIFO_ENTRY_ID) allocSlot <- mkRWire();
    (* no_implicit_conditions *)
    (* fire_when_enabled *)
    rule doAllocSlot (didInit &&& allocSlot.wget() matches tagged Valid .slot);
        // Mark slot not data ready
        reqVec.upd(slot, ! reqVec.sub(slot));
    endrule


    //
    // Methods
    //

    method ActionValue#(t_SCOREBOARD_FIFO_ENTRY_ID) enq() if (isNotFull());
        nEntries.up();

        // Mark FIFO slot as waiting for data
        let slot = nextEnq;
        allocSlot.wset(slot);
    
        // Update next slot pointer
        nextEnq <= slot + 1;

        return slot;
    endmethod

    method Action setValue(t_SCOREBOARD_FIFO_ENTRY_ID id, t_DATA data);
        setValueQ.enq(tuple2(id, data));
    endmethod

    method t_DATA first();
        return tpl_1(exitValQ.first());
    endmethod

    method Action deq();
        exitValQ.deq();
    endmethod

    method Bool notFull();
        return isNotFull();
    endmethod

    method Bool notEmpty();
        return exitValQ.notEmpty();
    endmethod

    method SCOREBOARD_FIFO_ENTRY_ID#(t_NUM_ENTRIES) deqEntryId();
        return tpl_2(exitValQ.first());
    endmethod
endmodule
