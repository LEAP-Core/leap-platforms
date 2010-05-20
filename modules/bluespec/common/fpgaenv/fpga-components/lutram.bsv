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

interface LUTRAM#(type t_ADDR, type t_DATA);
    method Action upd(t_ADDR addr, t_DATA d);
    method t_DATA sub(t_ADDR addr);
    method Bool initialized();
endinterface: LUTRAM

//
// Internal only --
//   RegFile version of mkLUTRAMU.  Uses LUT registers for storage.
//
module mkLUTRAMU_RegFile
    // interface:
        (LUTRAM#(t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ),
             Bits#(t_ADDR, t_ADDR_SZ),
             Bounded#(t_ADDR));

    RegFile#(t_ADDR, t_DATA) mem <- mkRegFileWCF(minBound, maxBound);

    //
    // Access methods
    //
    method Action upd(t_ADDR addr, t_DATA d) = mem.upd(addr, d);
    method t_DATA sub(t_ADDR addr) = mem.sub(addr);
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
        (LUTRAM#(t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ),
             Bits#(t_ADDR, t_ADDR_SZ),
             Bounded#(t_ADDR));

    RegFile#(t_ADDR, t_DATA) mem <- mkRegFileWCF(minBound, maxBound);

    function tweakAddr(t_ADDR addr);
        let t = pack(addr);
        t[0] = t[0] ^ 1;
        return unpack(t);
    endfunction

    method Action upd(t_ADDR addr, t_DATA d) = mem.upd(tweakAddr(addr), d);
    method t_DATA sub(t_ADDR addr) = mem.sub(tweakAddr(addr));
    method Bool initialized() = True;
endmodule


//
// mkLUTRAMU -- pick either the hardware or the simulated version of LUTRAMU.
//
module mkLUTRAMU
    // interface:
        (LUTRAM#(t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ),
             Bits#(t_ADDR, t_ADDR_SZ),
             Bounded#(t_ADDR));

    LUTRAM#(t_ADDR, t_DATA) mem;

    //
    // RegFile and Async versions have the same timing, so we always use the
    // RegFile version for simulation since it compiles more quickly.
    //

    Bool use_regfile = True;

    `ifdef SYNTH
    if ((`BROKEN_REGFILE != 0) && (valueOf(t_DATA_SZ) > 1))
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
module mkLUTRAMWith#(function t_DATA initfunc(t_ADDR idx))
    // interface:
        (LUTRAM#(t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ),
             Bits#(t_ADDR, t_ADDR_SZ),
             Bounded#(t_ADDR));

    LUTRAM#(t_ADDR, t_DATA) mem <- mkLUTRAMU();

    //
    // Initialize storage
    //

    Reg#(Bool) initialized_m <- mkReg(False);
    Reg#(t_ADDR) init_idx <- mkReg(minBound);

    rule initializing (! initialized_m);
        mem.upd(init_idx, initfunc(init_idx));

        // Hack to avoid needing Eq proviso for comparison
        t_ADDR max = maxBound;
        initialized_m <= (pack(init_idx) == pack(max));

        // Hack to avoid needing Arith proviso
        init_idx <= unpack(pack(init_idx) + 1);
    endrule

    //
    // Access methods
    //

    method Action upd(t_ADDR addr, t_DATA d) if (initialized_m);
        mem.upd(addr, d);
    endmethod

    method t_DATA sub(t_ADDR addr) if (initialized_m);
        return mem.sub(addr);
    endmethod
    
    method Bool initialized() = initialized_m;

endmodule


//
// Initialized LUTRAM
//
module mkLUTRAM#(t_DATA init)
    // interface:
        (LUTRAM#(t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ),
             Bits#(t_ADDR, t_ADDR_SZ),
             Bounded#(t_ADDR));


    // A dummy function which returns the same value for any index.
    function t_DATA const_func(t_ADDR idx);
        return init;
    endfunction

    LUTRAM#(t_ADDR, t_DATA) mem <- mkLUTRAMWith(const_func);

    return mem;

endmodule




// ========================================================================
//
// Multi-read-port LUTRAM.  Unlike RegFile, which has up to 5 compiler-
// managed read ports, the LUTRAM_MULTI_READ has user-managed read
// ports.  Unlike the compiler-managed RegFile, in which every instance
// of a reader is allocated a unique port, the user-managed implementation
// allows for sharing of read ports among non-conflicting rules.  Xilinx
// LUT usage increases linearly with the number of ports, so this can
// be a significant space savings.
//
// ========================================================================


// Read port interface (internal)
interface LUTRAM_READER_IFC#(type t_ADDR, type t_DATA);
    method t_DATA sub(t_ADDR addr);
endinterface: LUTRAM_READER_IFC

//
// Multi-reader interface.
//
interface LUTRAM_MULTI_READ#(numeric type n_READERS, type t_ADDR, type t_DATA);
    method Action upd(t_ADDR addr, t_DATA d);
    interface Vector#(n_READERS, LUTRAM_READER_IFC#(t_ADDR, t_DATA)) readPorts;

    method Bool initialized();
endinterface: LUTRAM_MULTI_READ


//
// mkLUTRAMUSinglePort --
//     Wrapper for Verilog implementation of a dual ported LUT memory with
//     one reader and one writer.
//
import "BVI" LUTRAMUDualPort = module mkLUTRAMUDualPort
    // interface:
    (LUTRAM#(Bit#(t_ADDR_SZ), Bit#(t_DATA_SZ)));

    parameter addr_width = valueOf(t_ADDR_SZ);
    parameter data_width = valueOf(t_DATA_SZ);
    parameter lo = 0;
    parameter hi = valueOf(TSub#(TExp#(t_ADDR_SZ), 1));

    method D_OUT_1 sub(ADDR_1);
    method upd(ADDR_IN, D_IN) enable(WE);
    method INIT initialized();

    schedule upd C upd;
    schedule sub C sub;
    schedule upd CF sub;
    schedule initialized CF (sub, upd, initialized);
endmodule


//
// mkMultiReadLUTRAMU -- pick either the hardware or the simulated version
//     of a multi-reader LUTRAMU.
//
//     Note:  the simulator version uses a separate RegFile for each read
//     port.  This limits the number of unique readers of each port to 5.
//     The hardware version has no limit.
//
module mkMultiReadLUTRAMU
    // interface:
    (LUTRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ),
             Bits#(t_ADDR, t_ADDR_SZ),
             Bounded#(t_ADDR));

    // Multiple ports are implemented by allocating a vector of memories, one
    // for each port.  This is basically what the hardware does, so there isn't
    // much cost.  At the cost of complexity here, it might be a good idea to
    // detect read ports in groups of 3 and add a quad-port version of the
    // Verilog primitive.  Quad port has 3 read ports per write port.
    Vector#(n_READERS, LUTRAM#(Bit#(t_ADDR_SZ), Bit#(t_DATA_SZ))) mem = newVector();

    //
    // RegFile and Async versions have the same timing, so we always use the
    // RegFile version for simulation since it compiles more quickly.
    //

    Bool use_regfile = True;
    `ifdef SYNTH
        use_regfile = False;
    `endif

    for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        mem[p] <- use_regfile ? mkLUTRAMU_RegFile() : mkLUTRAMUDualPort();
    end

    Vector#(n_READERS, LUTRAM_READER_IFC#(t_ADDR, t_DATA)) portsLocal = newVector();
    for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        portsLocal[p] =
            interface LUTRAM_READER_IFC#(t_ADDR, t_DATA);
                method t_DATA sub(t_ADDR addr);
                    return unpack(mem[p].sub(pack(addr)));
                endmethod
            endinterface;
    end

    method Action upd(t_ADDR addr, t_DATA d);
        // Update writes all the ports
        for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
        begin
            mem[p].upd(pack(addr), pack(d));
        end
    endmethod

    interface readPorts = portsLocal;

    method Bool initialized() = True;
endmodule




//
// LUTRAM Initialized with a function :: idx -> data
//
module mkMultiReadLUTRAMWith#(function t_DATA initfunc(t_ADDR idx))
    // interface:
    (LUTRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ),
             Bits#(t_ADDR, t_ADDR_SZ),
             Bounded#(t_ADDR));

    LUTRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA) mem <- mkMultiReadLUTRAMU();

    //
    // Initialize storage
    //

    Reg#(Bool) initialized_m <- mkReg(False);
    Reg#(t_ADDR) init_idx <- mkReg(minBound);

    rule initializing (! initialized_m);
        mem.upd(init_idx, initfunc(init_idx));

        // Hack to avoid needing Eq proviso for comparison
        t_ADDR max = maxBound;
        initialized_m <= (pack(init_idx) == pack(max));

        // Hack to avoid needing Arith proviso
        init_idx <= unpack(pack(init_idx) + 1);
    endrule


    //
    // Access methods
    //

    Vector#(n_READERS, LUTRAM_READER_IFC#(t_ADDR, t_DATA)) portsLocal = newVector();
    for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        portsLocal[p] =
            interface LUTRAM_READER_IFC#(t_ADDR, t_DATA);
                method t_DATA sub(t_ADDR addr) if (initialized_m);
                    return mem.readPorts[p].sub(addr);
                endmethod
            endinterface;
    end

    method Action upd(t_ADDR addr, t_DATA d) if (initialized_m);
        mem.upd(addr, d);
    endmethod

    interface readPorts = portsLocal;

    method Bool initialized() = initialized_m;
endmodule


//
// Initialized LUTRAM
//
module mkMultiReadLUTRAM#(t_DATA init)
    // interface:
    (LUTRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ),
             Bits#(t_ADDR, t_ADDR_SZ),
             Bounded#(t_ADDR));

    // A dummy function which returns the same value for any index.
    function t_DATA const_func(t_ADDR idx);
        return init;
    endfunction

    LUTRAM_MULTI_READ#(n_READERS, t_ADDR, t_DATA) mem <-
        mkMultiReadLUTRAMWith(const_func);

    return mem;
endmodule
