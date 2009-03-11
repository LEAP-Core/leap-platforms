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

// Bram_multi_read

// A convenient instantiation of Block RAMs with multiple read ports.
// TODO: Make n=2 a special case that uses the second physical read port.

import Vector::*;
import FIFO::*;

`include "asim/provides/libfpga_bsv_base.bsh"


typedef MEMORY_READER_IFC#(t_ADDR, t_DATA) BROM#(type t_ADDR, type t_DATA);
typedef MEMORY_MULTI_READ_IFC#(nReaders, t_ADDR, t_DATA) BRAM_MULTI_READ#(numeric type nReaders, type t_ADDR, type t_DATA);


// mkBRAMMultiRead

// Give the illusion of more read ports by replicating the RAM
// TODO: Make n=2 a special case that actually uses both physical ports
//       with reads conflicting with writes.

module mkBRAMMultiRead
    // interface:
        (BRAM_MULTI_READ#(n, t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, data_SZ));

    Vector#(n, BRAM#(t_ADDR, t_DATA)) rams <- replicateM(mkBRAM());

    Vector#(n, BROM#(t_ADDR, t_DATA)) portsLocal = newVector();

    // readPorts
    
    // The vector of read ports is just the read ports of the BRAMs.

    for(Integer i = 0; i < valueOf(n); i = i + 1)
    begin
        portsLocal[i] = (interface BROM#(t_ADDR, t_DATA);
                             method readReq = rams[i].readReq;
                             method readRsp = rams[i].readRsp;
                         endinterface);
    end

    interface readPorts = portsLocal;

 
    // write
    
    // When:   Any time
    // Effect: Replicate the writes to all the RAMs. 
 
    method Action write(t_ADDR a, t_DATA d);

        for(Integer i = 0; i < valueOf(n); i = i + 1)
        begin
            rams[i].write(a, d);
        end

    endmethod

endmodule


//
// mkBRAMPseudoMultiRead
//
// Give the illusion of more read ports by managing reader access to a single,
// shared, read port.
//
module mkBRAMPseudoMultiRead
    // interface:
        (BRAM_MULTI_READ#(n, t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, data_SZ));

    BRAM#(t_ADDR, t_DATA) ram <- mkBRAM();
    FIFO#(Bit#(TLog#(n))) readReqPort <- mkFIFO();

    //
    // readPorts
    //

    Vector#(n, BROM#(t_ADDR, t_DATA)) portsLocal = newVector();

    for(Integer i = 0; i < valueOf(n); i = i + 1)
    begin
        portsLocal[i] =
            interface BROM#(t_ADDR, t_DATA);
                method Action readReq(t_ADDR a);
                    readReqPort.enq(fromInteger(i));
                    ram.readReq(a);
                endmethod

                method ActionValue#(t_DATA) readRsp() if (readReqPort.first() == fromInteger(i));
                    readReqPort.deq();
                    let rsp <- ram.readRsp();
                    return rsp;
                endmethod
            endinterface;
    end

    interface readPorts = portsLocal;

 
    method write = ram.write;

endmodule


//
// mkBRAMBaseMultiReadInitializedWith
//
// This is intended to be an INTERNAL module from which all other initialized
// multi-read modules are derived.
//
// Makes a Multiport BRAM and initializes it using a single FSM.
// The RAM cannot be accessed until the FSM is done.
// Uses an ADDR->VAL function to determine the initial values.
//
// If realPorts is true multiple read ports are available.  Otherwise,
// a single read port is multiplexed across the read interfaces.
//
module mkBRAMBaseMultiReadInitializedWith#(Bool realPorts, function t_DATA init(t_ADDR a))
    // interface:
        (BRAM_MULTI_READ#(n, t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, dataSz));

    // The primitive BRAMs.
    BRAM_MULTI_READ#(n, t_ADDR, t_DATA) mems <- mkBRAMMultiRead();
    if (realPorts)
        mems <- mkBRAMMultiRead();
    else
        mems <- mkBRAMPseudoMultiRead();
    
    //
    // initialize
    //
    // When:   After a reset until every value is initialized.
    // Effect: Update the RAM with the user-provided initial value.
    //
    Reg#(Bit#(addr_SZ))   cur <- mkReg(0);
    Reg#(Bool) initializing <- mkReg(True);

    rule initialize (initializing);
        t_ADDR cur_a = unpack(cur);
        mems.write(cur_a, init(cur_a));
        cur <= cur + 1;

        if (cur + 1 == 0)
        begin
            initializing <= False;
        end
    endrule


    //
    // readPorts, write
    //
    // When:   Guard all requests until we're done initializing.
    //
    Vector#(readNum, BROM#(t_ADDR, t_DATA)) portsLocal = newVector();

    for(Integer i = 0; i < valueOf(readNum); i = i + 1)
    begin
        portsLocal[i] = (interface BROM#(t_ADDR, t_DATA);
                             method Action readReq(t_ADDR a) if (!initializing) = mems.readPorts[i].readReq(a);
                             method ActionValue#(t_DATA) readRsp() = mems.readPorts[i].readRsp();
                         endinterface);
    end

    interface readPorts = portsLocal;

    method Action write(t_ADDR a, t_DATA d) if (!initializing);
        mems.write(a, d);
    endmethod

endmodule



// mkBRAMMultiReadInitializedWith

// Makes a Multiport BRAM and initializes it using a single FSM.
// The RAM cannot be accessed until the FSM is done.
// Uses an ADDR->VAL function to determine the initial values.

module mkBRAMMultiReadInitializedWith#(function t_DATA init(t_ADDR a))
    // interface:
        (BRAM_MULTI_READ#(n, t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, dataSz));

    BRAM_MULTI_READ#(n, t_ADDR, t_DATA) m <- mkBRAMBaseMultiReadInitializedWith(True, init);
    return m;

endmodule


//
// mkBRAMMultiReadInitialized
//
// A convenience-wrapper of mkBRAMMultiReadInitializedWith where the value
// is constant.
//
module mkBRAMMultiReadInitialized#(t_DATA initval)
    // interface:
        (BRAM_MULTI_READ#(n, t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, data_SZ));

    // Wrap the data value in a dummy function.
    function t_DATA initfunc(t_ADDR a);
        return initval;
    endfunction

    //Just instantiate the RAMs.
    BRAM_MULTI_READ#(n, t_ADDR, t_DATA) m <- mkBRAMBaseMultiReadInitializedWith(True, initfunc);
    
    return m;

endmodule



// mkBRAMPseudoMultiReadInitializedWith
//
// Logical read ports share a single, multiplexed physical read port.
//
// Makes a Multiport BRAM and initializes it using a single FSM.
// The RAM cannot be accessed until the FSM is done.
// Uses an ADDR->VAL function to determine the initial values.

module mkBRAMPseudoMultiReadInitializedWith#(function t_DATA init(t_ADDR a))
    // interface:
        (BRAM_MULTI_READ#(n, t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, dataSz));

    BRAM_MULTI_READ#(n, t_ADDR, t_DATA) m <- mkBRAMBaseMultiReadInitializedWith(False, init);
    return m;

endmodule


//
// mkBRAMPseudoMultiReadInitialized
//
// Logical read ports share a single, multiplexed physical read port.
//
// A convenience-wrapper of mkBRAMMultiReadInitializedWith where the value
// is constant.
//
module mkBRAMPseudoMultiReadInitialized#(t_DATA initval)
    // interface:
        (BRAM_MULTI_READ#(n, t_ADDR, t_DATA))
    provisos
        (Bits#(t_ADDR, addr_SZ),
         Bits#(t_DATA, data_SZ));

    // Wrap the data value in a dummy function.
    function t_DATA initfunc(t_ADDR a);
        return initval;
    endfunction

    //Just instantiate the RAMs.
    BRAM_MULTI_READ#(n, t_ADDR, t_DATA) m <- mkBRAMBaseMultiReadInitializedWith(False, initfunc);
    
    return m;

endmodule
