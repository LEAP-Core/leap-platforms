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
// Functions implementing a FIFO that can be stored in any type of storage,
// including BRAM and LUTRAM.
//
// The functions implement the standard methods available on either unguarded
// or guarded FIFOs.  The functional implementation is stateless.  Functions
// that update the FIFO (enq and deq) take a FIFO state as an input and return
// the updated FIFO state.  It is the caller's responsibility to manage
// loading and storing the state to a memory.
//
// These functions DO NOT behave exactly like a standard FIFO.  Updating the
// FIFO from different rules in the same cycle will not work.  Similarly,
// calling the enq function followed by deq within a single rule will
// forward the data immediately, within a single cycle.
//

import Vector::*;


// ========================================================================
// ========================================================================
//
//   First implementation:  full FIFO in a struct.
//
// ========================================================================
// ========================================================================

//
// FUNC_FIFO --
//     Base data type.  The oldest entry is always in slot 0 of the data
//     vector.  Values are shifted as entries are dequeued.  Shifting
//     is generally less expensive than the indexing that would be required
//     of a ring buffer.
//
typedef struct
{
    Vector#(n_ENTRIES, t_DATA) data;
    Bit#(TLog#(TAdd#(n_ENTRIES, 1))) activeEntries;
}
FUNC_FIFO#(type t_DATA, numeric type n_ENTRIES)
    deriving (Eq, Bits);


//
// funcFIFO_Init --
//     Initialize a FIFO.
//
function FUNC_FIFO#(t_DATA, n_ENTRIES) funcFIFO_Init();
    return FUNC_FIFO { data: newVector(),
                       activeEntries: 0 };
endfunction


// ========================================================================
//
//   Queries
//
// ========================================================================

//
// funcFIFO_notEmpty
//
function Bool funcFIFO_notEmpty(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo);
    return fifo.activeEntries != 0;
endfunction


//
// funcFIFO_notFull
//
function Bool funcFIFO_notFull(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo);
    return fifo.activeEntries < fromInteger(valueOf(n_ENTRIES));
endfunction


//
// funcFIFO_numBusySlots
//
function Bit#(TLog#(TAdd#(n_ENTRIES, 1))) funcFIFO_numBusySlots(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo);
    return fifo.activeEntries;
endfunction


// ========================================================================
//
//   Unguarded updates
//
// ========================================================================

//
// funcFIFO_UGfirst
//
function t_DATA funcFIFO_UGfirst(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo);
    return fifo.data[0];
endfunction


//
// funcFIFO_UGdeq
//
function FUNC_FIFO#(t_DATA, n_ENTRIES) funcFIFO_UGdeq(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo);
    fifo.data = shiftInAtN(fifo.data, ?);
    fifo.activeEntries = fifo.activeEntries - 1;

    return fifo;
endfunction


//
// funcFIFO_UGenq
//
function FUNC_FIFO#(t_DATA, n_ENTRIES) funcFIFO_UGenq(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo,
                                                      t_DATA val);
    fifo.data[fifo.activeEntries] = val;
    fifo.activeEntries = fifo.activeEntries + 1;
    
    return fifo;
endfunction


// ========================================================================
//
//   Guarded updates
//
// ========================================================================

//
// funcFIFO_first
//
function t_DATA funcFIFO_first(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo);
    return when (funcFIFO_notEmpty(fifo), funcFIFO_UGfirst(fifo));
endfunction


//
// funcFIFO_deq
//
function FUNC_FIFO#(t_DATA, n_ENTRIES) funcFIFO_deq(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo);
    return when (funcFIFO_notEmpty(fifo), funcFIFO_UGdeq(fifo));
endfunction


//
// funcFIFO_enq
//
function FUNC_FIFO#(t_DATA, n_ENTRIES) funcFIFO_enq(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo,
                                                    t_DATA val);
    return when (funcFIFO_notFull(fifo), funcFIFO_UGenq(fifo, val));
endfunction


// ========================================================================
//
//   Non-FIFO data access for callers that need to access an arbitrary
//   object in the buffer.
//
// ========================================================================

//
// funcFIFO_peek --
//     Read data in a specific slot.
//
function Maybe#(t_DATA) funcFIFO_peek(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo,
                                      Bit#(TLog#(n_ENTRIES)) idx);
    if (fifo.activeEntries > zeroExtendNP(idx))
        return tagged Valid fifo.data[idx];
    else
        return tagged Invalid;
endfunction


//
// funcFIFO_poke --
//     Write data to a specific slot.
//
function FUNC_FIFO#(t_DATA, n_ENTRIES) funcFIFO_poke(FUNC_FIFO#(t_DATA, n_ENTRIES) fifo,
                                                     Bit#(TLog#(n_ENTRIES)) idx,
                                                     t_DATA value);
    fifo.data[idx] = value;
    return fifo;
endfunction





// ========================================================================
// ========================================================================
//
//   Second implementation:  struct holds only the metadata for a FIFO.
//       The full data must be managed outside the functions.  Functions
//       return the index that must be read/written to complete the
//       operation.
//
// ========================================================================
// ========================================================================

//
// FUNC_FIFO_IDX --
//     Base data type for the FIFO index manages the oldest and newest
//     pointers.
//
typedef struct
{
    Bit#(TLog#(n_ENTRIES)) idxOldest;
    Bit#(TLog#(n_ENTRIES)) idxNextNew;
    Bool notEmpty;
}
FUNC_FIFO_IDX#(numeric type n_ENTRIES)
    deriving (Eq, Bits);


//
// funcFIFO_IDX_Init --
//     Initialize a FIFO.
//
function FUNC_FIFO_IDX#(n_ENTRIES) funcFIFO_IDX_Init();
    return FUNC_FIFO_IDX { idxOldest: 0,
                           idxNextNew: 0,
                           notEmpty: False };
endfunction


// ========================================================================
//
//   Queries
//
// ========================================================================

//
// funcFIFO_IDX_notEmpty
//
function Bool funcFIFO_IDX_notEmpty(FUNC_FIFO_IDX#(n_ENTRIES) fifo);
    return fifo.notEmpty;
endfunction


//
// funcFIFO_IDX_notFull
//
function Bool funcFIFO_IDX_notFull(FUNC_FIFO_IDX#(n_ENTRIES) fifo);
    return (fifo.idxOldest != fifo.idxNextNew) || ! fifo.notEmpty;
endfunction


//
// funcFIFO_IDX_numBusySlots
//
function Bit#(TLog#(TAdd#(n_ENTRIES, 1))) funcFIFO_IDX_numBusySlots(FUNC_FIFO_IDX#(n_ENTRIES) fifo);
    Bit#(TLog#(TAdd#(n_ENTRIES, 1))) n_busy;

    if (fifo.idxOldest == fifo.idxNextNew)
    begin
        n_busy = funcFIFO_IDX_notEmpty(fifo) ? fromInteger(valueOf(n_ENTRIES)) : 0;
    end
    else if (fifo.idxOldest < fifo.idxNextNew)
    begin
        n_busy = zeroExtendNP(fifo.idxNextNew - fifo.idxOldest);
    end
    else
    begin
        n_busy = fromInteger(valueOf(n_ENTRIES)) - zeroExtendNP(fifo.idxOldest - fifo.idxNextNew);
    end

    return n_busy;
endfunction


// ========================================================================
//
//   Unguarded updates
//
// ========================================================================

//
// funcFIFO_IDX_UGfirst
//
function Bit#(TLog#(n_ENTRIES)) funcFIFO_IDX_UGfirst(FUNC_FIFO_IDX#(n_ENTRIES) fifo);
    return fifo.idxOldest;
endfunction


//
// funcFIFO_IDX_UGdeq
//
function FUNC_FIFO_IDX#(n_ENTRIES) funcFIFO_IDX_UGdeq(FUNC_FIFO_IDX#(n_ENTRIES) fifo);
    if (fifo.idxOldest == fromInteger(valueOf(TSub#(n_ENTRIES, 1))))
        fifo.idxOldest = 0;
    else
        fifo.idxOldest = fifo.idxOldest + 1;

    fifo.notEmpty = (fifo.idxOldest != fifo.idxNextNew);

    return fifo;
endfunction


//
// funcFIFO_IDX_UGenq
//
function Tuple2#(FUNC_FIFO_IDX#(n_ENTRIES),
                 Bit#(TLog#(n_ENTRIES))) funcFIFO_IDX_UGenq(FUNC_FIFO_IDX#(n_ENTRIES) fifo);

    let enq_idx = fifo.idxNextNew;
    fifo.notEmpty = True;
    
    if (fifo.idxNextNew == fromInteger(valueOf(TSub#(n_ENTRIES, 1))))
        fifo.idxNextNew = 0;
    else
        fifo.idxNextNew = fifo.idxNextNew + 1;

    return tuple2(fifo, enq_idx);
endfunction


// ========================================================================
//
//   Guarded updates
//
// ========================================================================

//
// funcFIFO_IDX_first
//
function Bit#(TLog#(n_ENTRIES)) funcFIFO_IDX_first(FUNC_FIFO_IDX#(n_ENTRIES) fifo);
    return when (funcFIFO_IDX_notEmpty(fifo), funcFIFO_IDX_UGfirst(fifo));
endfunction


//
// funcFIFO_IDX_deq
//
function FUNC_FIFO_IDX#(n_ENTRIES) funcFIFO_IDX_deq(FUNC_FIFO_IDX#(n_ENTRIES) fifo);
    return when (funcFIFO_IDX_notEmpty(fifo), funcFIFO_IDX_UGdeq(fifo));
endfunction


//
// funcFIFO_IDX_enq
//
function Tuple2#(FUNC_FIFO_IDX#(n_ENTRIES),
                 Bit#(TLog#(n_ENTRIES))) funcFIFO_IDX_enq(FUNC_FIFO_IDX#(n_ENTRIES) fifo);
    return when (funcFIFO_IDX_notFull(fifo), funcFIFO_IDX_UGenq(fifo));
endfunction


// ========================================================================
//
//   Non-FIFO data access for callers that need to access an arbitrary
//   object in the buffer.
//
// ========================================================================

//
// funcFIFO_IDX_index --
//     Compute the index of a particular position in the FIFO.
//
function Maybe#(Bit#(TLog#(n_ENTRIES))) funcFIFO_IDX_index(FUNC_FIFO_IDX#(n_ENTRIES) fifo,
                                                           Bit#(TLog#(n_ENTRIES)) idx);
    let active_slots = funcFIFO_IDX_numBusySlots(fifo);
    if (zeroExtendNP(idx) >= active_slots)
    begin
        return tagged Invalid;
    end
    else
    begin
        Bit#(TLog#(TAdd#(n_ENTRIES, 1))) s = zeroExtendNP(idx);
        s = s + zeroExtendNP(fifo.idxOldest);
        s = s % fromInteger(valueOf(n_ENTRIES));
        return tagged Valid truncateNP(s);
    end
endfunction
