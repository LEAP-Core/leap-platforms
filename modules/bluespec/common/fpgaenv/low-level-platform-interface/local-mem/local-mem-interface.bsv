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
// Standard interface to local memory.  Implementations of local memory
// are in the local-mem subdirectory.
//

import Vector::*;

//
// Local memory is the interface between a single local memory device (e.g.
// the DDR2 driver) and one or more clients of the local memory.  All of local
// memory is exposed as fixed sized words.  Groups of words may also be
// accessed as a fixed size line, allowing for efficient caches using local
// memory as storage.
//
// The word and line sizes must be chosen carefully to match the capabilities
// of the physical memory device and the needs of the local memory clients.
//

typedef `LOCAL_MEM_WORD_BITS LOCAL_MEM_WORD_SZ;
typedef `LOCAL_MEM_WORDS_PER_LINE LOCAL_MEM_WORDS_PER_LINE;
typedef TMul#(LOCAL_MEM_WORD_SZ, LOCAL_MEM_WORDS_PER_LINE) LOCAL_MEM_LINE_SZ;

typedef Bit#(LOCAL_MEM_WORD_SZ) LOCAL_MEM_WORD;
typedef Bit#(LOCAL_MEM_LINE_SZ) LOCAL_MEM_LINE;

// Index of a word within a line.  ASSUMES A POWER OF 2 WORDS PER LINE!
typedef TLog#(LOCAL_MEM_WORDS_PER_LINE) LOCAL_MEM_WORD_IDX_SZ;
typedef Bit#(LOCAL_MEM_WORD_IDX_SZ) LOCAL_MEM_WORD_IDX;


// Mask bytes within words and lines
typedef TDiv#(LOCAL_MEM_WORD_SZ, 8) LOCAL_MEM_BYTES_PER_WORD;
typedef Vector#(LOCAL_MEM_BYTES_PER_WORD, Bool) LOCAL_MEM_WORD_MASK;
typedef Vector#(LOCAL_MEM_WORDS_PER_LINE, LOCAL_MEM_WORD_MASK) LOCAL_MEM_LINE_MASK;


// Address size comes from the underlying memory.  For real memory (e.g.
// DDR) it is a function of the hardware.  The address is for words.
typedef Bit#(LOCAL_MEM_ADDR_SZ) LOCAL_MEM_ADDR;

// Address of a line (drops the word index)
typedef TSub#(LOCAL_MEM_ADDR_SZ, LOCAL_MEM_WORD_IDX_SZ) LOCAL_MEM_LINE_ADDR_SZ;
typedef Bit#(LOCAL_MEM_LINE_ADDR_SZ) LOCAL_MEM_LINE_ADDR;


interface LOCAL_MEM;
    //
    // The implementation of reading words and lines may use a shared FIFO.
    // Callers must expect to receive the response from alternating word and
    // line read requests in order to avoid deadlocks.
    //
    method Action readWordReq(LOCAL_MEM_ADDR addr);
    method ActionValue#(LOCAL_MEM_WORD) readWordRsp();

    method Action readLineReq(LOCAL_MEM_ADDR addr);
    method ActionValue#(LOCAL_MEM_LINE) readLineRsp();
    
    //
    // Write requests.
    //
    method Action writeWord(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data);
    method Action writeLine(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data);

    // Only write bytes in a line with corresponding True in mask
    method Action writeWordMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data, LOCAL_MEM_WORD_MASK mask);
    method Action writeLineMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data, LOCAL_MEM_LINE_MASK mask);
endinterface: LOCAL_MEM


//
// localMemSeparateAddr --
//     Separate an address into a line-aligned address and a word offset.
//
function Tuple2#(LOCAL_MEM_LINE_ADDR,
                 LOCAL_MEM_WORD_IDX) localMemSeparateAddr(LOCAL_MEM_ADDR addr);
    return unpack(addr);
endfunction

function LOCAL_MEM_ADDR localMemLineAddrToAddr(LOCAL_MEM_LINE_ADDR lineAddr);
    LOCAL_MEM_WORD_IDX w_idx = 0;
    return { lineAddr, w_idx };
endfunction
