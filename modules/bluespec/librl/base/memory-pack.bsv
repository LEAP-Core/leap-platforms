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
// This package provides a wrapper class that maps underlying indexed storage
// with a fixed word size to a new array of storage with a different word
// size.  Scratchpad memory, that is always presented as a system-wide
// fixed size can thus be marshalled into arbitrary-sized types.
//
// Note:  all type marshalling is in buckets with sizes that are powers of 2.
// While this may waste space it drastically simplifies addressing.
//


import Vector::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;


`include "asim/provides/librl_bsv_base.bsh"

//
// Compute the number of objects of desired type that can fit inside a container
// type.  To simplify addressing, the computed number of objects per container
// or containers per object will always be a power of 2.  Thus the maximum wasted
// bits when objects are smaller than containers is (container size / 2) + 1
// and the maximum wasted bits when objects are larger than containers is
// (2 * object size) - 1.
//
// For a given data and container size, one of the two object index sizes will
// always be 0.  This becomes important in MEM_PACK_CONTAINER_ADDR!
//
typedef TLog#(TDiv#(TExp#(TLog#(t_DATA_SZ)), t_CONTAINER_DATA_SZ)) MEM_PACK_LARGER_OBJ_IDX_SZ#(numeric type t_DATA_SZ, numeric type t_CONTAINER_DATA_SZ);
typedef TLog#(TDiv#(t_CONTAINER_DATA_SZ, TExp#(TLog#(t_DATA_SZ)))) MEM_PACK_SMALLER_OBJ_IDX_SZ#(numeric type t_DATA_SZ, numeric type t_CONTAINER_DATA_SZ);


// ************************************************************************
//
// KEY DATA TYPE:
//
// MEM_PACK_CONTAINER_ADDR is the address type of a container that will
// hold a vector of the desired quantity of the desired data.  Given a
// MEM_PACK#(t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA)
// it is the caller's responsibility to provide a corresponding container
// with the interface:
//
//  MEMORY_IFC#(MEM_PACK_CONTAINER_ADDR#(t_ADDR_SZ, t_DATA_SZ, t_CONTAINER_DATA_SZ),
//              t_CONTAINER_DATA)
//
//
// The computation works because at least one of MEM_PACK_SMALLER_OBJ_IDX_SZ
// and MEM_PACK_LARGER_OBJ_IDX_SZ must be 0.
//
// ************************************************************************

typedef Bit#(TAdd#(TSub#(t_ADDR_SZ,
                         MEM_PACK_SMALLER_OBJ_IDX_SZ#(t_DATA_SZ, t_CONTAINER_DATA_SZ)),
                   MEM_PACK_LARGER_OBJ_IDX_SZ#(t_DATA_SZ, t_CONTAINER_DATA_SZ)))
        MEM_PACK_CONTAINER_ADDR#(numeric type t_ADDR_SZ, numeric type t_DATA_SZ, numeric type t_CONTAINER_DATA_SZ);


//
// A MEM_PACK presents a memory interface to access the requested
// numer of objects of the requested type.
//
typedef MEMORY_IFC#(t_ADDR, t_DATA) MEM_PACK#(type t_ADDR, type t_DATA, type t_CONTAINER_ADDR, type t_CONTAINER_DATA);

//
// A MEM_PACK_MULTI_READ behaves like a MEM_PACK but has multiple read ports.
//
typedef MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA) MEM_PACK_MULTI_READ#(numeric type n_READERS, type t_ADDR, type t_DATA, type t_CONTAINER_ADDR, type t_CONTAINER_DATA);


//
// Internal type used by mkMemPackManyTo1
//
typedef struct
{
    Bool isReadForWrite;
    Bit#(MEM_PACK_SMALLER_OBJ_IDX_SZ#(t_DATA_SZ, t_CONTAINER_DATA_SZ)) objIdx;
}
PACK_REQ_INFO#(numeric type t_DATA_SZ, numeric type t_CONTAINER_DATA_SZ)
    deriving (Bits, Eq);



//
// mkMemPack --
//     The general wrapper to use for all allocations.  Map an array indexed
//     by t_ADDR_SZ bits of Bit#(t_DATA_SZ) objects onto backing storage
//     made up of objects of type Bit#(t_CONTAINDER_DATA_SZ).
//
//     This wrapper picks the right implementation module depending on whether
//     there is a 1:1 mapping of objects to containers or a more complicated
//     mapping.
//
module mkMemPack#(MEMORY_IFC#(t_CONTAINER_ADDR, t_CONTAINER_DATA) containerMem)
    // interface:
    (MEM_PACK#(t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Bits#(t_CONTAINER_ADDR, t_CONTAINER_ADDR_SZ),
              Bits#(t_CONTAINER_DATA, t_CONTAINER_DATA_SZ));

    if (valueOf(t_ADDR_SZ) == valueOf(t_CONTAINER_ADDR_SZ))
    begin
        // One object per container
        let mem <- mkMemPack1To1(containerMem);
        return mem;
    end
    else if (valueOf(t_ADDR_SZ) > valueOf(t_CONTAINER_ADDR_SZ))
    begin
        // Multiple objects per container
        let mem <- mkMemPackManyTo1(containerMem);
        return mem;
    end
    else
    begin
        // Object bigger than one container.  Use multiple containers for
        // each object.
        let mem <- mkMemPack1ToMany(containerMem);
        return mem;
    end
endmodule


//
// mkMemPackPseudoMultiRead
//
// Give the illusion of more read ports by managing reader access to a single,
// shared, read port.
//
module mkMemPackPseudoMultiRead#(MEMORY_IFC#(t_CONTAINER_ADDR, t_CONTAINER_DATA) containerMem)
    // interface:
    (MEM_PACK_MULTI_READ#(n_READERS, t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Bits#(t_CONTAINER_ADDR, t_CONTAINER_ADDR_SZ),
              Bits#(t_CONTAINER_DATA, t_CONTAINER_DATA_SZ));

    MEM_PACK#(t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA) memory <- mkMemPack(containerMem);
    FIFO#(Bit#(TLog#(n_READERS))) readReqPort <- mkFIFO();

    //
    // readPorts
    //

    Vector#(n_READERS, MEMORY_READER_IFC#(t_ADDR, t_DATA)) portsLocal = newVector();

    for(Integer i = 0; i < valueOf(n_READERS); i = i + 1)
    begin
        portsLocal[i] =
            interface MEMORY_READER_IFC#(t_ADDR, t_DATA);
                method Action readReq(t_ADDR a);
                    readReqPort.enq(fromInteger(i));
                    memory.readReq(a);
                endmethod

                method ActionValue#(t_DATA) readRsp() if (readReqPort.first() == fromInteger(i));
                    readReqPort.deq();
                    let rsp <- memory.readRsp();
                    return rsp;
                endmethod
            endinterface;
    end

    interface readPorts = portsLocal;

    method write = memory.write;
endmodule



// ========================================================================
//
// Internal modules.
//
// ========================================================================

//
// mkMemPack1To1 --
//     Map desired storage to a container for the case where one object
//     is stored per container.  The address spaces of the container and
//     and desired data are thus identical and the mapping is trivial.
//
module mkMemPack1To1#(MEMORY_IFC#(t_CONTAINER_ADDR, t_CONTAINER_DATA) containerMem)
    // interface:
    (MEM_PACK#(t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Bits#(t_CONTAINER_ADDR, t_CONTAINER_ADDR_SZ),
              Bits#(t_CONTAINER_DATA, t_CONTAINER_DATA_SZ));

    method Action readReq(t_ADDR addr);
        containerMem.readReq(unpack(zeroExtendNP(pack(addr))));
    endmethod

    method ActionValue#(t_DATA) readRsp();
        let v <- containerMem.readRsp();
        return unpack(truncateNP(pack(v)));
    endmethod

    method Action write(t_ADDR addr, t_DATA val);
        containerMem.write(unpack(zeroExtendNP(pack(addr))), unpack(zeroExtendNP(pack(val))));
    endmethod
endmodule



//
// mkMemPackManyTo1 --
//     Pack multiple objects into a single container object.
//
module mkMemPackManyTo1#(MEMORY_IFC#(t_CONTAINER_ADDR, t_CONTAINER_DATA) containerMem)
    // interface:
    (MEM_PACK#(t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Bits#(t_CONTAINER_ADDR, t_CONTAINER_ADDR_SZ),
              Bits#(t_CONTAINER_DATA, t_CONTAINER_DATA_SZ),
       
              Alias#(Bit#(MEM_PACK_SMALLER_OBJ_IDX_SZ#(t_DATA_SZ, t_CONTAINER_DATA_SZ)), t_OBJ_IDX),
              Bits#(t_OBJ_IDX, t_OBJ_IDX_SZ),

              // Arrangement of objects packed in a container.  Objects are evenly
              // spaced to make packed values easier to read while debugging.
              Alias#(Vector#(TExp#(t_OBJ_IDX_SZ), Bit#(TDiv#(t_CONTAINER_DATA_SZ, TExp#(t_OBJ_IDX_SZ)))), t_PACKED_CONTAINER));

    // Incoming read and write requests go into queues so they can be processed
    // in rules with defined order and flow control instead of in the base
    // methods.
    FIFOF#(t_ADDR) readReqQ <- mkFIFOF();

    // Save space for writeQ with a FIFO1 since the pipelines will continue
    // to be blocked until the read-modify-write completes.
    FIFOF#(Tuple2#(t_ADDR, t_DATA)) writeQ <- mkFIFOF1();

    // Shared read request queue directs responses either to the readRsp method
    // or to the doRMW rule.
    FIFO#(PACK_REQ_INFO#(t_DATA_SZ, t_CONTAINER_DATA_SZ)) sharedReadReqQ <- mkSizedFIFO(8);

    // Forward read data to the readRsp method
    FIFO#(t_DATA) readRspQ <- mkBypassFIFO();

    // Writes must be read-modify-write.  Read the full container, update the
    // object, and write it back.  We must be careful of read/write ordering
    // to maintain memory consistency.  For now block everything else when a
    // write is being processed.
    Reg#(Bool) doingRMW <- mkReg(False);
    Reg#(t_CONTAINER_ADDR) rmwContainerAddr <- mkRegU();
    Reg#(t_DATA) rmwData <- mkRegU();


    //
    // Functions that govern new requests.
    //

    function Bool isBusyForRead();
        return (doingRMW || writeQ.notEmpty());
    endfunction

    function Bool isBusyForWrite();
        return (doingRMW || writeQ.notEmpty() || readReqQ.notEmpty());
    endfunction


    //
    // addrSplit --
    //     Split an incoming address into two components:  the container address
    //     and the index of the requested object within the container.
    //
    function Tuple2#(t_CONTAINER_ADDR, t_OBJ_IDX) addrSplit(t_ADDR addr);
        Bit#(t_ADDR_SZ) p_addr = pack(addr);
        return tuple2(unpack(p_addr[valueOf(t_ADDR_SZ)-1 : valueOf(t_OBJ_IDX_SZ)]), p_addr[valueOf(t_OBJ_IDX_SZ)-1 : 0]);
    endfunction


    //
    // doRMW --
    //     Process read response for a write.  Update the object within the
    //     container and write it back.
    //
    rule doRMW (doingRMW && sharedReadReqQ.first().isReadForWrite && ! readReqQ.notEmpty());
        let o_idx = sharedReadReqQ.first().objIdx;
        sharedReadReqQ.deq();

        let d <- containerMem.readRsp();

        // Pack the current data into a vector of the number of objects
        // per container.
        t_PACKED_CONTAINER pack_data = unpack(truncateNP(pack(d)));
        
        // Update the object in the container and write it back.
        pack_data[o_idx] = zeroExtendNP(pack(rmwData));
        containerMem.write(rmwContainerAddr, unpack(zeroExtendNP(pack(pack_data))));
        
        doingRMW <= False;
    endrule


    //
    // Process requests
    //
    rule processWriteReq (! doingRMW);
        match {.addr, .val} = writeQ.first();
        writeQ.deq();

        match {.c_addr, .o_idx} = addrSplit(addr);
        containerMem.readReq(c_addr);
        sharedReadReqQ.enq(PACK_REQ_INFO {isReadForWrite: True, objIdx: o_idx});
    
        doingRMW <= True;
        rmwContainerAddr <= c_addr;
        rmwData <= val;
    endrule

    // Writes go before reads to begin the read-modify-write.  A predicate
    // on doRMW guarantees read requests fire at the right time.
    (* descending_urgency = "processWriteReq, processReadReq" *)
    rule processReadReq (True);
        let addr = readReqQ.first();
        readReqQ.deq();

        match {.c_addr, .o_idx} = addrSplit(addr);
        containerMem.readReq(c_addr);
        sharedReadReqQ.enq(PACK_REQ_INFO {isReadForWrite: False, objIdx: o_idx});
    endrule

    //
    // processReadRsp --
    //     In theory the body of this rule could all go in the readRsp method
    //     below.  In practice, the Bluespec scheduler can get confused and
    //     introduce conflicts between callers of readRsp and doRMW above,
    //     causing deadlocks.  Putting the code here is a rule and forwarding
    //     through a 0-latency FIFO seems to solve the problem.
    //
    rule processReadRsp (! sharedReadReqQ.first().isReadForWrite);
        let o_idx = sharedReadReqQ.first().objIdx;
        sharedReadReqQ.deq();
    
        // Receive the data and return the desired object from the container.
        let d <- containerMem.readRsp();
        t_PACKED_CONTAINER pack_data = unpack(truncateNP(pack(d)));
        readRspQ.enq(unpack(truncateNP(pack_data[o_idx])));
    endrule


    method Action readReq(t_ADDR addr) if (! isBusyForRead);
        readReqQ.enq(addr);
    endmethod

    method ActionValue#(t_DATA) readRsp();
        let d = readRspQ.first();
        readRspQ.deq();

        return d;
    endmethod

    method Action write(t_ADDR addr, t_DATA val) if (! isBusyForWrite);
        writeQ.enq(tuple2(addr, val));
    endmethod
endmodule


//
// mkMemPack1ToMany --
//     Spread one object across multiple container objects.
//
module mkMemPack1ToMany#(MEMORY_IFC#(t_CONTAINER_ADDR, t_CONTAINER_DATA) containerMem)
    // interface:
    (MEM_PACK#(t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Bits#(t_CONTAINER_ADDR, t_CONTAINER_ADDR_SZ),
              Bits#(t_CONTAINER_DATA, t_CONTAINER_DATA_SZ),

              Alias#(Bit#(MEM_PACK_LARGER_OBJ_IDX_SZ#(t_DATA_SZ, t_CONTAINER_DATA_SZ)), t_OBJ_IDX),
              Bits#(t_OBJ_IDX, t_OBJ_IDX_SZ),
       
              // Vector of multiple containers holding one object
              Alias#(Vector#(TExp#(t_OBJ_IDX_SZ), t_CONTAINER_DATA), t_PACKED_CONTAINER));

    // Write state
    Reg#(Bool) doingWrite <- mkReg(False);
    Reg#(t_PACKED_CONTAINER) writeData <- mkRegU();

    // Read state
    Reg#(Bool) doingReadReq <- mkReg(False);
    Reg#(t_OBJ_IDX) readIdx <- mkReg(0);
    Reg#(t_PACKED_CONTAINER) readData <- mkRegU();
    FIFO#(t_DATA) readRspQ <- mkBypassFIFO();

    // Shared read/write state
    Reg#(t_ADDR) reqAddr <- mkRegU();
    Reg#(t_OBJ_IDX) reqIdx <- mkRegU();


    //
    // Need multiple containers for a single object, so the container
    // address is formed by concatenating the object address and a
    // container index.
    //
    function t_CONTAINER_ADDR addrContainer(t_ADDR addr, t_OBJ_IDX objIdx);
        return unpack(zeroExtendNP({pack(addr), objIdx}));
    endfunction


    //
    // doWrite --
    //     Multi-stage write.
    //
    rule doWrite (doingWrite);
        let obj_idx = reqIdx + 1;
        let c_addr = addrContainer(reqAddr, obj_idx);

        containerMem.write(c_addr, writeData[obj_idx]);

        reqIdx <= obj_idx;
        if (obj_idx == maxBound)
        begin
            doingWrite <= False;
        end
    endrule

    //
    // doReadReq --
    //     Multi-stage read request.
    //
    rule doReadReq (doingReadReq);
        let obj_idx = reqIdx + 1;
        let c_addr = addrContainer(reqAddr, obj_idx);

        containerMem.readReq(c_addr);

        reqIdx <= obj_idx;
        if (obj_idx == maxBound)
        begin
            doingReadReq <= False;
        end
    endrule

    //
    // doReadRsp --
    //     Merge read responses into single values.  Forward values as they
    //     complete.
    //
    rule doReadRsp (True);
        let v <- containerMem.readRsp();
        if (readIdx != maxBound)
        begin
            readData[readIdx] <= v;
        end
        else
        begin
            let r = readData;
            r[readIdx] = v;
            readRspQ.enq(unpack(truncateNP(pack(r))));
        end
        
        readIdx <= readIdx + 1;
    endrule


    method Action readReq(t_ADDR addr) if (! doingWrite && ! doingReadReq);
        let c_addr = addrContainer(addr, 0);
        containerMem.readReq(c_addr);

        doingReadReq <= True;
        reqAddr <= addr;
        reqIdx <= 0;
    endmethod

    method ActionValue#(t_DATA) readRsp();
        let v = readRspQ.first();
        readRspQ.deq();
    
        return v;
    endmethod

    method Action write(t_ADDR addr, t_DATA val) if (! doingWrite && ! doingReadReq);
        let c_addr = addrContainer(addr, 0);

        t_PACKED_CONTAINER write_data = unpack(zeroExtendNP(pack(val)));
        containerMem.write(c_addr, write_data[0]);

        doingWrite <= True;
        reqAddr <= addr;
        reqIdx <= 0;
        writeData <= write_data;
    endmethod
endmodule
