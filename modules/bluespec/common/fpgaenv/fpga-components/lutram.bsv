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
// Author: Michael Adler
//

//
// LUT-based storage that compiles more effeciently than a vector in a register.
//
// Ideally this module wouldn't exist and we would use RegFile directly.
// Unfortunately, some instances of RegFiles don't synthesize correctly using
// Xilinx tools.  The code here provides a single RegFile-style interface and
// constructor for LUT-based storage and uses the most efficient storage that
// works, given the size request.
//

import RegFile::*;

interface LUTRAM#(type index_t, type data_t);

    method Action upd(index_t addr, data_t d);
    method data_t sub(index_t addr);

endinterface: LUTRAM

//
// mkLUTRAMU --
//   Uninitialized version of LUTRAM, implemented with a RegFile.
//
module mkLUTRAMU
    // interface:
        (LUTRAM#(index_t, data_t))
    provisos(Bits#(data_t, data_SZ),
             Bits#(index_t, index_SZ),
             Bounded#(index_t));

    RegFile#(index_t, data_t) mem <- mkRegFileWCF(minBound, maxBound);

    //
    // Access methods
    //

    method Action upd(index_t addr, data_t d);
        mem.upd(addr, d);
    endmethod

    method data_t sub(index_t addr);
        return mem.sub(addr);
    endmethod

endmodule


//
// Initialized LUTRAM
//
module mkLUTRAM#(data_t init)
    // interface:
        (LUTRAM#(index_t, data_t))
    provisos(Bits#(data_t, data_SZ),
             Bits#(index_t, index_SZ),
             Bounded#(index_t));

    LUTRAM#(index_t, data_t) mem <- mkLUTRAMU();

    //
    // Initialize storage
    //

    Reg#(Bool) initialized <- mkReg(False);
    Reg#(index_t) init_idx <- mkReg(minBound);

    rule initializing (!initialized);
        mem.upd(init_idx, init);

        // Hack to avoid needing Eq proviso for comparison
        index_t max = maxBound;
        initialized <= (pack(init_idx) == pack(max));

        // Hack to avoid needing Arith proviso
        init_idx <= unpack(pack(init_idx) + 1);
    endrule

    //
    // Access methods
    //

    method Action upd(index_t addr, data_t d) if (initialized);
        mem.upd(addr, d);
    endmethod

    method data_t sub(index_t addr) if (initialized);
        return mem.sub(addr);
    endmethod

endmodule
