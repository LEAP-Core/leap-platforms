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

import Vector::*;


// ========================================================================
//
// Memory interface definition
//
// ========================================================================

//
// This is a general interface to a multi-cycle memory.  By making it common we
// hope that code can switch between different memories changing only the
// call to a module constructor.
//

interface MEMORY_IFC#(type t_ADDR, type t_DATA);
    method Action readReq(t_ADDR addr);
    method ActionValue#(t_DATA) readRsp();

    // Look at the read response value without popping it
    method t_DATA peek();

    // Read response ready
    method Bool notEmpty();

    // Read request possible?
    method Bool notFull();


    method Action write(t_ADDR addr, t_DATA val);
    
    // Write request possible?
    method Bool writeNotFull();
endinterface


//
// Memory with one writer and multiple readers.
//

// Single reader interface
interface MEMORY_READER_IFC#(type t_ADDR, type t_DATA);
    method Action readReq(t_ADDR addr);
    method ActionValue#(t_DATA) readRsp();
    method t_DATA peek();
    method Bool notEmpty();
    method Bool notFull();
endinterface

interface MEMORY_MULTI_READ_IFC#(numeric type n_READERS, type t_ADDR, type t_DATA);
    interface Vector#(n_READERS, MEMORY_READER_IFC#(t_ADDR, t_DATA)) readPorts;

    method Action write(t_ADDR addr, t_DATA val);
    method Bool writeNotFull();
endinterface


// ========================================================================
//
// Memory interface conversion
//
// ========================================================================

//
// mkMultiMemIfcToMemIfc --
//     Interface conversion from a MEMORY_MULTI_READ_IFC with one port to a
//     MEMORY_IFC.  Useful for implementing a memory that supports an arbitrary
//     number of ports without having to special case the code for a single port.
//
module mkMultiMemIfcToMemIfc#(MEMORY_MULTI_READ_IFC#(1, t_ADDR, t_DATA) multiMem)
    // interface:
    (MEMORY_IFC#(t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    method Action readReq(t_ADDR addr) = multiMem.readPorts[0].readReq(addr);

    method ActionValue#(t_DATA) readRsp();
        let v <- multiMem.readPorts[0].readRsp();
        return v;
    endmethod

    method t_DATA peek() = multiMem.readPorts[0].peek();
    method Bool notEmpty() = multiMem.readPorts[0].notEmpty();
    method Bool notFull() = multiMem.readPorts[0].notFull();

    method Action write(t_ADDR addr, t_DATA val) = multiMem.write(addr, val);
    method Bool writeNotFull() = multiMem.writeNotFull();
endmodule


//
// mkMemIfcToMultiMemIfc --
//     Inverse of mkMultiMemIfcToMemIfc above.  Convert a standard MEMORY_IFC
//     to a MEMORY_MULTI_READ_IFC with a single read port.
//
module mkMemIfcToMultiMemIfc#(MEMORY_IFC#(t_ADDR, t_DATA) mem)
    // interface:
    (MEMORY_MULTI_READ_IFC#(1, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    Vector#(1, MEMORY_READER_IFC#(t_ADDR, t_DATA)) portsLocal = newVector();
    portsLocal[0] =
        interface MEMORY_READER_IFC#(t_ADDR, t_DATA);
            method Action readReq(t_ADDR addr) = mem.readReq(addr);

            method ActionValue#(t_DATA) readRsp();
                let v <- mem.readRsp();
                return v;
            endmethod

            method t_DATA peek() = mem.peek();
            method Bool notEmpty() = mem.notEmpty();
            method Bool notFull() = mem.notFull();
        endinterface;

    interface readPorts = portsLocal;

    method Action write(t_ADDR addr, t_DATA val) = mem.write(addr, val);
    method Bool writeNotFull() = mem.writeNotFull();
endmodule


// ========================================================================
//
// Memory initialization
//
// ========================================================================


//
// mkMultiMemInitializedWith --
//     Initializes a memory using an FSM and provide a memory interface to
//     the initialized storage.  The memory cannot be accessed until the
//     FSM is done.   Uses an ADDR->VAL function to determine the
//     initial values.
//
module mkMultiMemInitializedWith#(MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA) mem,
                                  function t_DATA init(t_ADDR x))
    // interface:
    (MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    // The current adddress we're updating.
    Reg#(Bit#(t_ADDR_SZ)) cur <- mkReg(0);
    
    // Are we initializing?
    Reg#(Bool) initializing <- mkReg(True);


    // initialize --
    //     When:   After a reset until every value is initialized.
    //     Effect: Update the RAM with the user-provided initial value.
    //
    rule initialize (initializing);
        t_ADDR cur_a = unpack(cur);
        mem.write(cur_a, init(cur_a));
        cur <= cur + 1;

        if (cur + 1 == 0)
        begin
            initializing <= False;
        end
    endrule


    Vector#(n_READERS, MEMORY_READER_IFC#(t_ADDR, t_DATA)) portsLocal = newVector();
    for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        portsLocal[p] =
            interface MEMORY_READER_IFC#(t_ADDR, t_DATA);
                method Action readReq(t_ADDR addr) if (!initializing);
                    mem.readPorts[p].readReq(addr);
                endmethod

                method ActionValue#(t_DATA) readRsp();
                    let v <- mem.readPorts[p].readRsp();
                    return v;
                endmethod

                method t_DATA peek() if (!initializing);
                    return mem.readPorts[p].peek();
                endmethod

                method Bool notEmpty() = mem.readPorts[p].notEmpty();

                method Bool notFull();
                    return !initializing && mem.readPorts[p].notFull();
                endmethod
            endinterface;
    end

    interface readPorts = portsLocal;

    method Action write(t_ADDR a, t_DATA d) if (!initializing);
        mem.write(a, d);
    endmethod

    method Bool writeNotFull();
        return !initializing && mem.writeNotFull();
    endmethod
endmodule


//
// mkMultiMemInitialized --
//     A convenience-wrapper of mkMultiMemInitializedWith where the value is
//     constant.
//
module mkMultiMemInitialized#(MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA) mem,
                              t_DATA initVal)
    // interface:
    (MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    // Wrap the data value in a dummy function.
    function t_DATA initFunc(t_ADDR a);
        return initVal;
    endfunction

    MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA) m <- mkMultiMemInitializedWith(mem, initFunc);

    return m;
endmodule


//
// mkMemInitializedWith --
//     Initializes a memory using an FSM and provide a memory interface to
//     the initialized storage.  The memory cannot be accessed until the
//     FSM is done.   Uses an ADDR->VAL function to determine the
//     initial values.
//
module mkMemInitializedWith#(MEMORY_IFC#(t_ADDR, t_DATA) mem,
                             function t_DATA init(t_ADDR x))
    // interface:
    (MEMORY_IFC#(t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    // Convert to a multi-reader interface and use the initialization module.
    MEMORY_MULTI_READ_IFC#(1, t_ADDR, t_DATA) multi_m <- mkMemIfcToMultiMemIfc(mem);
    MEMORY_MULTI_READ_IFC#(1, t_ADDR, t_DATA) init_m <- mkMultiMemInitializedWith(multi_m, init);

    // Convert back to single reader interface.
    MEMORY_IFC#(t_ADDR, t_DATA) m <- mkMultiMemIfcToMemIfc(init_m);

    return m;
endmodule


//
// mkMemInitialized --
//     A convenience-wrapper of mkMemInitializedWith where the value is
//     constant.
//
module mkMemInitialized#(MEMORY_IFC#(t_ADDR, t_DATA) mem,
                         t_DATA initVal)
    // interface:
    (MEMORY_IFC#(t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    // Wrap the data value in a dummy function.
    function t_DATA initFunc(t_ADDR a);
        return initVal;
    endfunction

    MEMORY_IFC#(t_ADDR, t_DATA) m <- mkMemInitializedWith(mem, initFunc);

    return m;
endmodule
