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
import Connectable::*;


// ========================================================================
//
// Memory interface definition
//
// ========================================================================


typedef struct {
  t_ADDR addr;
  Bit#(TAdd#(1,TLog#(n_MAX_BURST))) size;
} BURST_COMMAND#(type t_ADDR, numeric type n_MAX_BURST)
  deriving(Bits,Eq);

typedef union tagged {
  BURST_COMMAND#(t_ADDR,n_MAX_BURST) ReadReq;
  BURST_COMMAND#(t_ADDR,n_MAX_BURST) WriteReq;
} BURST_REQUEST#(type t_ADDR, numeric type n_MAX_BURST)
  deriving(Bits,Eq);



//
// This is a general interface to a multi-cycle memory, which may also 
// support burst requests. MEMORY_IFC can be expressed in terms of this 
// interface.  That would be a good excercise for some lazy Friday.
//

interface BURST_MEMORY_IFC#(type t_ADDR, type t_DATA, numeric type n_MAX_BURST);
    method ActionValue#(t_DATA) readRsp();

    // Look at the read response value without popping it
    method t_DATA peek();

    // Read response ready
    method Bool notEmpty();

    // Read request possible?
    method Bool notFull();

    // We must split the write request and response...
    method Action writeData(t_DATA data); 

    method Action burstReq(BURST_REQUEST#(t_ADDR, n_MAX_BURST) burstReq);
    
    // Write request possible?
    method Bool writeNotFull();
endinterface

//
// This is a complimentary interface to BURST_MEMORY_IFC and is intended to be connectable
//

interface BURST_MEMORY_CLIENT_IFC#(type t_ADDR, type t_DATA, numeric type n_MAX_BURST);
    method Action readRsp(t_DATA data);

    // Look at the read response value without popping it
    method Action peek(t_DATA value);

    // Read response ready
    method Action notEmpty(Bool value);

    // Read request possible?
    method Action notFull(Bool value);

    // We must split the write request and response...
    method ActionValue#(t_DATA) writeData(); 

    method ActionValue#(BURST_REQUEST#(t_ADDR, n_MAX_BURST)) burstReq();
    
    // Write request possible?
    method Action writeNotFull(Bool value);
endinterface


//
//  Connect a BURST_MEMORY_IFC to a BURST_MEMORY_CLIENT_IFC
//

instance Connectable#(BURST_MEMORY_IFC#(t_ADDR,t_DATA,n_MAX_BURST),
                      BURST_MEMORY_CLIENT_IFC#(t_ADDR,t_DATA,n_MAX_BURST));
  module mkConnection#(BURST_MEMORY_IFC#(t_ADDR,t_DATA,n_MAX_BURST) server,
                       BURST_MEMORY_CLIENT_IFC#(t_ADDR,t_DATA,n_MAX_BURST) client) (Empty);
    mkConnection(server.burstReq, client.burstReq);    
    mkConnection(client.readRsp, server.readRsp);    
    mkConnection(server.writeData, client.writeData);    
 
    rule peekRule;
      client.peek(server.peek);
    endrule

    rule notEmptyRule;
      client.notEmpty(server.notEmpty);
    endrule

    rule notFullRule;
      client.notFull(server.notFull);
    endrule

    rule writeNotFullRule;
      client.writeNotFull(server.writeNotFull);
    endrule

  endmodule
endinstance

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

// Single writer interface
// This might initially seem counter-intuitive, but we'll use this function
// to manipulate vectorized interfaces later.
interface MEMORY_WRITER_IFC#(type t_ADDR, type t_DATA);
    method Action write(t_ADDR addr, t_DATA val);
    // Write request possible?
    method Bool writeNotFull();
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
//  mkMemIfcToMemReaderIfc
//  Converts a memory interface down into a reader
//

module mkMemIfcToMemReaderIfc#(MEMORY_IFC#(t_ADDR, t_DATA) memory)
    // interface:
    (MEMORY_READER_IFC#(t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    method Action readReq(t_ADDR addr) = memory.readReq(addr);

    method ActionValue#(t_DATA) readRsp();
        let v <- memory.readRsp();
        return v;
    endmethod

    method t_DATA peek() = memory.peek();
    method Bool notEmpty() = memory.notEmpty();
    method Bool notFull() = memory.notFull();
endmodule

//
//  mkMemIfcToMemWriterIfc
//  Converts a memory interface down into a writer
//
module mkMemIfcToMemWriterIfc#(MEMORY_IFC#(t_ADDR, t_DATA) memory)
    // interface:
    (MEMORY_WRITER_IFC#(t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));
    method Action write(t_ADDR addr, t_DATA val) = memory.write(addr, val);
    method Bool writeNotFull() = memory.writeNotFull();
endmodule

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

//
// mkMultiReadMemToVectorMemIfc --
//     Converts a MEMORY_MULTI_READ_IFC to a Vector of MEMORY_IFC each of which 
//     share the write port.  Used to split up the memory interfaces in the multicache.

module mkMultiReadMemIfcToVectorMemIfc#(MEMORY_MULTI_READ_IFC#(n_Readers, 
                                                               t_ADDR, 
                                                               t_DATA) multiMem)
    (Vector#(n_Readers, MEMORY_IFC#(t_ADDR, t_DATA)))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));
    Vector#(n_Readers, MEMORY_IFC#(t_ADDR, t_DATA)) memories = newVector();
 
    for(Integer i = 0; i < valueof(n_Readers); i = i + 1) 
    begin
        MEMORY_IFC#(t_ADDR, t_DATA) memory = interface MEMORY_IFC
            method readReq = multiMem.readPorts[i].readReq;
            method readRsp =multiMem.readPorts[i].readRsp;
            method peek = multiMem.readPorts[i].peek;
            method notEmpty = multiMem.readPorts[i].notEmpty;
            method notFull = multiMem.readPorts[i].notFull;
            method write = multiMem.write;
            method writeNotFull = multiMem.writeNotFull;
        endinterface;
        memories[i] = memory;
    end

    return memories;
endmodule


//
//  mkVectorMemIfcToMultiReadMemIfc --
//     Converts a Vector of MEMORY_IFC to a each MEMORY_MULTI_READ_IFC.  
//     Each of the write functions are tied to the single write function of
//     the MEMORY_MULTI_READ_IFC. 

module mkVectorMemIfcToMultiReadMemIfc#(Vector#(n_Readers, MEMORY_IFC#(t_ADDR, t_DATA)) memories)
    (MEMORY_MULTI_READ_IFC#(n_Readers, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    Vector#(n_Readers, MEMORY_READER_IFC#(t_ADDR, t_DATA)) readPortsLocal = newVector();  
    
    for(Integer i = 0; i < valueof(n_Readers); i = i + 1) 
    begin
        MEMORY_READER_IFC#(t_ADDR, t_DATA) reader = interface MEMORY_READER_IFC
            method readReq = memories[i].readReq;
            method readRsp = memories[i].readRsp;
            method peek    = memories[i].peek;
            method notEmpty= memories[i].notEmpty;
            method notFull = memories[i].notFull;
        endinterface;
        readPortsLocal[i] = reader;
    end
    
    MEMORY_MULTI_READ_IFC#(n_Readers, t_ADDR, t_DATA) multiMem = interface MEMORY_MULTI_READ_IFC
        interface readPorts = readPortsLocal;    

        // One write to touch them all, one write to bind them.
        method Action write(t_ADDR addr, t_DATA data);
            for(Integer i = 0; i < valueof(n_Readers); i = i + 1) 
            begin            
              memories[i].write(addr,data);
            end
        endmethod

        // If any of the memories are full, they are all full.
        method Bool writeNotFull;
            Bool notFull = True;
            for(Integer i = 0; i < valueof(n_Readers); i = i + 1) 
            begin            
              notFull = notFull && memories[i].writeNotFull();
            end

            return notFull;
        endmethod
    endinterface;

    return multiMem;
endmodule

//
//  mkVectorMemIfcToMultiReadMemIfc --
//     Converts a Vector of MEMORY_IFC to a each MEMORY_MULTI_READ_IFC.  
//     Each of the write functions are tied to the single write function of
//     the MEMORY_MULTI_READ_IFC. 

module mkMemWriterAndVectorMemReaderIfcToMultiReadMemIfc#(
    MEMORY_WRITER_IFC#(t_ADDR, t_DATA) writer,
    Vector#(n_Readers, MEMORY_READER_IFC#(t_ADDR, t_DATA)) readers)
    (MEMORY_MULTI_READ_IFC#(n_Readers, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    Vector#(n_Readers, MEMORY_READER_IFC#(t_ADDR, t_DATA)) readPortsLocal = newVector();  
    
    for(Integer i = 0; i < valueof(n_Readers); i = i + 1) 
    begin
        MEMORY_READER_IFC#(t_ADDR, t_DATA) reader = interface MEMORY_READER_IFC
            method readReq = readers[i].readReq;
            method readRsp = readers[i].readRsp;
            method peek    = readers[i].peek;
            method notEmpty= readers[i].notEmpty;
            method notFull = readers[i].notFull;
        endinterface;
        readPortsLocal[i] = reader;
    end
    
    MEMORY_MULTI_READ_IFC#(n_Readers, t_ADDR, t_DATA) multiMem = interface MEMORY_MULTI_READ_IFC
        interface readPorts = readPortsLocal;    
 
         // One write to touch them all, one write to bind them.
         method Action write(t_ADDR addr, t_DATA data);
             writer.write(addr,data);
         endmethod

         // If any of the memories are full, they are all full.
         method Bool writeNotFull;
             return writer.writeNotFull();
         endmethod
    endinterface;

    return multiMem;
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


//
// mkSafeMemoryReader --
//     A wrapper for memory reader that guarantees output buffer space
//     before issuing a request to memory.  This helps in deadlock avoidance,
//     by guaranteeing that memory responses are drained, in the case that a 
//     memory is shared by several readers.
//
module mkSafeMemoryReader#(MEMORY_READER_IFC#(t_ADDR, t_DATA) unsafeReader) (MEMORY_READER_IFC#(t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ));
  
    // State elements.  Notice that bypass/loopy fifo usage preserves performance
    FIFOF#(Bit#(0)) tokenFIFO <- mkLFIFOF();
    FIFOF#(t_DATA) outputFIFO <- mkBypassFIFOF();
    
    rule response;
        t_DATA data <- unsafeReader.readRsp;
        outputFIFO.enq(data);
    endrule

    method Action readReq(t_ADDR addr);
        tokenFIFO.enq(0);
        unsafeReader.readReq(addr);
    endmethod

    method ActionValue#(t_DATA) readRsp();
        tokenFIFO.deq;
        outputFIFO.deq;
        return outputFIFO.first;
    endmethod

    method peek = outputFIFO.first;
    method notEmpty = outputFIFO.notEmpty;
    method notFull = tokenFIFO.notFull;

endmodule


//
// mkSizedSafeMemoryReader --
//     A wrapper for memory reader that guarantees output buffer space
//     before issuing a request to memory.  This helps in deadlock avoidance,
//     by guaranteeing that memory responses are drained, in the case that a 
//     memory is shared by several readers.  Unlike the preceding non-size module,
//     this one takes a size parameter, but doesn't have the LFIFOF. This might 
//     introduce some latency
//
module mkSafeSizedMemoryReader#(NumTypeParam#(n_ENTRIES) p, MEMORY_READER_IFC#(t_ADDR, t_DATA) unsafeReader) (MEMORY_READER_IFC#(t_ADDR, t_DATA))
    provisos(Bits#(t_DATA, t_DATA_SZ));
  
    // State elements.  Notice that bypass/loopy fifo usage preserves performance
    FIFOF#(Bit#(0)) tokenFIFO <- mkSizedFIFOF(valueof(n_ENTRIES));
    FIFOF#(t_DATA) outputFIFO <- mkSizedBypassFIFOF(valueof(n_ENTRIES));
    
    rule response;
        t_DATA data <- unsafeReader.readRsp;
        outputFIFO.enq(data);
    endrule

    method Action readReq(t_ADDR addr);
        tokenFIFO.enq(0);
        unsafeReader.readReq(addr);
    endmethod

    method ActionValue#(t_DATA) readRsp();
        tokenFIFO.deq;
        outputFIFO.deq;
        return outputFIFO.first;
    endmethod

    method peek = outputFIFO.first;
    method notEmpty = outputFIFO.notEmpty;
    method notFull = tokenFIFO.notFull;

endmodule
