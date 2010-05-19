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
    method Bool initialized();

endinterface: LUTRAM

//
// Internal only --
//   RegFile version of mkLUTRAMU.  Uses LUT registers for storage.
//
module mkLUTRAMU_RegFile
    // interface:
        (LUTRAM#(index_t, data_t))
    provisos(Bits#(data_t, data_SZ),
             Bits#(index_t, index_SZ),
             Bounded#(index_t));

    RegFile#(index_t, data_t) mem <- mkRegFileWCF(minBound, maxBound);

    //
    // Access methods
    //
    method Action upd(index_t addr, data_t d) = mem.upd(addr, d);
    method data_t sub(index_t addr) = mem.sub(addr);
    method Bool initialized() = True;
endmodule


//
// Internal only --
//   LUTRAMU_Async is used when LUT registers don't work due to bugs.
//
//   Xilinx Xst seems to have bugs with Verilog registers that look almost like
//   block RAM but have readers needing results in the same cycle when the
//   data size is greater than 1 bit.  The failed Xst inference seems to happen
//   only when the index source is a register.  This function inverts the low
//   bit of the index, guaranteeing that the index source is logic.
//
module mkLUTRAMU_Async
    // interface:
        (LUTRAM#(index_t, data_t))
    provisos(Bits#(data_t, data_SZ),
             Bits#(index_t, index_SZ),
             Bounded#(index_t));

    RegFile#(index_t, data_t) mem <- mkRegFileWCF(minBound, maxBound);

    function tweakAddr(index_t addr);
        let t = pack(addr);
        t[0] = t[0] ^ 1;
        return unpack(t);
    endfunction

    method Action upd(index_t addr, data_t d) = mem.upd(tweakAddr(addr), d);
    method data_t sub(index_t addr) = mem.sub(tweakAddr(addr));
    method Bool initialized() = True;
endmodule


//
// mkLUTRAMU -- pick either the hardware or the simulated version of LUTRAMU.
//
module mkLUTRAMU
    // interface:
        (LUTRAM#(index_t, data_t))
    provisos(Bits#(data_t, data_SZ),
             Bits#(index_t, index_SZ),
             Bounded#(index_t));

    LUTRAM#(index_t, data_t) mem;

    //
    // RegFile and Async versions have the same timing, so we always use the
    // RegFile version for simulation since it compiles more quickly.
    //

    Bool use_regfile = True;

    `ifdef SYNTH
    if ((`BROKEN_REGFILE != 0) && (valueOf(data_SZ) > 1))
    begin
        // There is a bug in some versions of Xilinx.  See the comment
        // on mkLUTRAMU_Async().
        use_regfile = False;
    end
    `endif

    mem <- use_regfile ? mkLUTRAMU_RegFile() : mkLUTRAMU_Async();

    return mem;

endmodule


//
// LUTRAM Initialized with a function :: idx -> data
//
module mkLUTRAMWith#(function data_t initfunc(index_t idx))
    // interface:
        (LUTRAM#(index_t, data_t))
    provisos(Bits#(data_t, data_SZ),
             Bits#(index_t, index_SZ),
             Bounded#(index_t));

    LUTRAM#(index_t, data_t) mem <- mkLUTRAMU();

    //
    // Initialize storage
    //

    Reg#(Bool) initializedR <- mkReg(False);
    Reg#(index_t) init_idx <- mkReg(minBound);

    rule initializing (!initializedR);
        mem.upd(init_idx, initfunc(init_idx));

        // Hack to avoid needing Eq proviso for comparison
        index_t max = maxBound;
        initializedR <= (pack(init_idx) == pack(max));

        // Hack to avoid needing Arith proviso
        init_idx <= unpack(pack(init_idx) + 1);
    endrule

    //
    // Access methods
    //

    method Action upd(index_t addr, data_t d) if (initializedR);
        mem.upd(addr, d);
    endmethod

    method data_t sub(index_t addr) if (initializedR);
        return mem.sub(addr);
    endmethod
    
    method Bool initialized() = initializedR;

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


    // A dummy function which returns the same value for any index.
    function data_t const_func(index_t idx);
        return init;
    endfunction

    LUTRAM#(index_t, data_t) mem <- mkLUTRAMWith(const_func);

    return mem;

endmodule
