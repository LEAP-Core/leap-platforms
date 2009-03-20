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

`include "asim/provides/libfpga_bsv_base.bsh"

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

interface SCOREBOARD_FIFO#(numeric type t_NUM_ENTRIES, type t_DATA);
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
// mkScoreboardFIFO --
//     A scoreboard FIFO with data stores in LUTs.
//
module mkScoreboardFIFO
    // Interface:
    (SCOREBOARD_FIFO#(t_NUM_ENTRIES, t_DATA))
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
    Reg#(Vector#(t_NUM_ENTRIES, Bool)) reqVec <- mkReg(replicate(False));
    Reg#(Vector#(t_NUM_ENTRIES, Bool)) readyVec <- mkReg(replicate(False));

    // Value flowing out from the FIFO to first() / deq().
    RWire#(t_DATA) exitVal <- mkRWire();
    Wire#(Bool) oldestIsReady <- mkDWire(False);

    function isNotFull() = (nEntries.value() != fromInteger(valueOf(t_NUM_ENTRIES)));
    function isNotEmpty() = (nEntries.value() != 0);


    //
    // Send the outbound, oldest, value out on a wire instead of reading
    // the values in the methods below to avoid painfully slow Bluespec
    // scheduler attempts to see through subscripting.
    //
    (* fire_when_enabled, no_implicit_conditions *)
    rule checkOldest (True);
        //
        // To be ready there must be an entry in the queue and the reqVec bit
        // must match the readyVec bit for the oldest entry.
        //
        Bit#(t_NUM_ENTRIES) r = pack(reqVec) ^ pack(readyVec);
        oldestIsReady <= isNotEmpty() && (r[nextDeq] == 0);
    endrule

    (* fire_when_enabled, no_implicit_conditions *)
    rule readOldest if (oldestIsReady);
        exitVal.wset(values[nextDeq]);
    endrule


    method ActionValue#(t_SCOREBOARD_FIFO_ENTRY_ID) enq() if (isNotFull());
        nEntries.up();

        // Mark FIFO slot as waiting for data
        let slot = nextEnq;
        reqVec[slot] <= ! reqVec[slot];
    
        // Update next slot pointer
        nextEnq <= slot + 1;

        return slot;
    endmethod

    method Action setValue(t_SCOREBOARD_FIFO_ENTRY_ID id, t_DATA data);
        // Write value to buffer
        values[id] <= data;
        // Mark slot data ready
        readyVec[id] <= reqVec[id];
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
// mkBRAMScoreboardFIFO --
//     A scoreboard FIFO with data stores in BRAM.  The code bypasses the
//     BRAM when first() and deq() are blocked waiting for incoming data,
//     so the timing should be similar to mkScoreboardFIFO.
//
module mkBRAMScoreboardFIFO
    // Interface:
    (SCOREBOARD_FIFO#(t_NUM_ENTRIES, t_DATA))
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
    Reg#(Vector#(t_NUM_ENTRIES, Bool)) reqVec <- mkReg(replicate(False));
    Reg#(Vector#(t_NUM_ENTRIES, Bool)) readyVec <- mkReg(replicate(False));

    // Value flowing out from the FIFO to first() / deq().
    FIFOF#(t_DATA) exitVal <- mkBypassFIFOF();
    FIFOF#(t_SCOREBOARD_FIFO_ENTRY_ID) exitEntryId <- mkFIFOF();

    Wire#(Bool) oldestIsReady <- mkDWire(False);

    function isNotFull() = (nEntries.value() != fromInteger(valueOf(t_NUM_ENTRIES)));
    function isNotEmpty() = (nEntries.value() != 0);


    //
    // Compute whether oldest is ready to a wire to simplify scheduling predicates.
    //
    (* fire_when_enabled, no_implicit_conditions *)
    rule checkOldest (True);
        //
        // To be ready there must be an entry in the queue and the reqVec bit
        // must match the readyVec bit for the oldest entry.
        //
        Bit#(t_NUM_ENTRIES) r = pack(reqVec) ^ pack(readyVec);
        oldestIsReady <= isNotEmpty() && (r[nextDeq] == 0);
    endrule

    //
    // Request outgoing value from BRAM when it is ready.
    //
    rule readReqOldest if (oldestIsReady);
        values.readReq(nextDeq);
        exitEntryId.enq(nextDeq);
        nextDeq <= nextDeq + 1;
        nEntries.down();
    endrule

    //
    // Forward outgoing value from BRAM to the outgoing exitVal FIFO.
    //
    rule readRespOldest (exitEntryId.notEmpty());
        let v <- values.readRsp();
        exitVal.enq(v);
    endrule


    method ActionValue#(t_SCOREBOARD_FIFO_ENTRY_ID) enq() if (isNotFull());
        nEntries.up();

        // Mark FIFO slot as waiting for data
        let slot = nextEnq;
        reqVec[slot] <= ! reqVec[slot];
    
        // Update next slot pointer
        nextEnq <= slot + 1;

        return slot;
    endmethod

    method Action setValue(t_SCOREBOARD_FIFO_ENTRY_ID id, t_DATA data);
        // Write value to buffer
        values.write(id, data);
        // Mark slot data ready
        readyVec[id] <= reqVec[id];
    
        // Bypass BRAM if incoming value is the oldest and the outgoing
        // pipelines are empty.
        if (! oldestIsReady && ! exitEntryId.notEmpty() && (id == nextDeq))
        begin
            exitVal.enq(data);
            exitEntryId.enq(nextDeq);
            nextDeq <= nextDeq + 1;
            nEntries.down();
        end
    endmethod

    method t_DATA first();
        return exitVal.first();
    endmethod

    method Action deq();
        exitVal.deq();
        exitEntryId.deq();
    endmethod

    method Bool notFull();
        return isNotFull();
    endmethod

    method Bool notEmpty();
        return exitVal.notEmpty();
    endmethod

    method SCOREBOARD_FIFO_ENTRY_ID#(t_NUM_ENTRIES) deqEntryId();
        return exitEntryId.first();
    endmethod
endmodule
