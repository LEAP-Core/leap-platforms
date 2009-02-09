// bram_multi_read

// A convenient instantiation of Block RAMs with multiple read ports.
// TODO: Make n=2 a special case that uses the second physical read port.

import Vector::*;
import FIFO::*;

// BROM

// Read-only interface

interface BROM#(parameter type addr_T, parameter type data_T);

    method Action readReq(addr_T a);
    method ActionValue#(data_T) readRsp();

endinterface


// BRAM_MULTI_READ

// Interface with multiple read ports.

interface BRAM_MULTI_READ#(parameter numeric type n, parameter type addr_T, type data_T);

    interface Vector#(n, BROM#(addr_T, data_T)) readPorts;
    method Action write(addr_T a, data_T d);

endinterface


// mkBRAMMultiRead

// Give the illusion of more read ports by replicating the RAM
// TODO: Make n=2 a special case that actually uses both physical ports
//       with reads conflicting with writes.

module mkBRAMMultiRead
    // interface:
        (BRAM_MULTI_READ#(n, addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, data_SZ));

    Vector#(n, BRAM#(addr_T, data_T)) rams <- replicateM(mkBRAM());

    Vector#(n, BROM#(addr_T, data_T)) portsLocal = newVector();

    // readPorts
    
    // The vector of read ports is just the read ports of the BRAMs.

    for(Integer i = 0; i < valueOf(n); i = i + 1)
    begin
        portsLocal[i] = (interface BROM#(addr_T, data_T);
                             method readReq = rams[i].readReq;
                             method readRsp = rams[i].readRsp;
                         endinterface);
    end

    interface readPorts = portsLocal;

 
    // write
    
    // When:   Any time
    // Effect: Replicate the writes to all the RAMs. 
 
    method Action write(addr_T a, data_T d);

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
        (BRAM_MULTI_READ#(n, addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, data_SZ));

    BRAM#(addr_T, data_T) ram <- mkBRAM();
    FIFO#(Bit#(TLog#(n))) readReqPort <- mkFIFO();

    //
    // readPorts
    //

    Vector#(n, BROM#(addr_T, data_T)) portsLocal = newVector();

    for(Integer i = 0; i < valueOf(n); i = i + 1)
    begin
        portsLocal[i] =
            interface BROM#(addr_T, data_T);
                method Action readReq(addr_T a);
                    readReqPort.enq(fromInteger(i));
                    ram.readReq(a);
                endmethod

                method ActionValue#(data_T) readRsp() if (readReqPort.first() == fromInteger(i));
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
module mkBRAMBaseMultiReadInitializedWith#(Bool realPorts, function data_T init(addr_T a))
    // interface:
        (BRAM_MULTI_READ#(n, addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, dataSz));

    // The primitive BRAMs.
    BRAM_MULTI_READ#(n, addr_T, data_T) mems <- mkBRAMMultiRead();
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
        addr_T cur_a = unpack(cur);
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
    Vector#(readNum, BROM#(addr_T, data_T)) portsLocal = newVector();

    for(Integer i = 0; i < valueOf(readNum); i = i + 1)
    begin
        portsLocal[i] = (interface BROM#(addr_T, data_T);
                             method Action readReq(addr_T a) if (!initializing) = mems.readPorts[i].readReq(a);
                             method ActionValue#(data_T) readRsp() = mems.readPorts[i].readRsp();
                         endinterface);
    end

    interface readPorts = portsLocal;

    method Action write(addr_T a, data_T d) if (!initializing);
        mems.write(a, d);
    endmethod

endmodule



// mkBRAMMultiReadInitializedWith

// Makes a Multiport BRAM and initializes it using a single FSM.
// The RAM cannot be accessed until the FSM is done.
// Uses an ADDR->VAL function to determine the initial values.

module mkBRAMMultiReadInitializedWith#(function data_T init(addr_T a))
    // interface:
        (BRAM_MULTI_READ#(n, addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, dataSz));

    BRAM_MULTI_READ#(n, addr_T, data_T) m <- mkBRAMBaseMultiReadInitializedWith(True, init);
    return m;

endmodule


//
// mkBRAMMultiReadInitialized
//
// A convenience-wrapper of mkBRAMMultiReadInitializedWith where the value
// is constant.
//
module mkBRAMMultiReadInitialized#(data_T initval)
    // interface:
        (BRAM_MULTI_READ#(n, addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, data_SZ));

    // Wrap the data value in a dummy function.
    function data_T initfunc(addr_T a);
        return initval;
    endfunction

    //Just instantiate the RAMs.
    BRAM_MULTI_READ#(n, addr_T, data_T) m <- mkBRAMBaseMultiReadInitializedWith(True, initfunc);
    
    return m;

endmodule



// mkBRAMPseudoMultiReadInitializedWith
//
// Logical read ports share a single, multiplexed physical read port.
//
// Makes a Multiport BRAM and initializes it using a single FSM.
// The RAM cannot be accessed until the FSM is done.
// Uses an ADDR->VAL function to determine the initial values.

module mkBRAMPseudoMultiReadInitializedWith#(function data_T init(addr_T a))
    // interface:
        (BRAM_MULTI_READ#(n, addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, dataSz));

    BRAM_MULTI_READ#(n, addr_T, data_T) m <- mkBRAMBaseMultiReadInitializedWith(False, init);
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
module mkBRAMPseudoMultiReadInitialized#(data_T initval)
    // interface:
        (BRAM_MULTI_READ#(n, addr_T, data_T))
    provisos
        (Bits#(addr_T, addr_SZ),
         Bits#(data_T, data_SZ));

    // Wrap the data value in a dummy function.
    function data_T initfunc(addr_T a);
        return initval;
    endfunction

    //Just instantiate the RAMs.
    BRAM_MULTI_READ#(n, addr_T, data_T) m <- mkBRAMBaseMultiReadInitializedWith(False, initfunc);
    
    return m;

endmodule