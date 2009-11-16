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
