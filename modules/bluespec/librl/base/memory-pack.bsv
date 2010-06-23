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
// Number of slots in read state buffers.  This value controls the number
// of reads that may be in flight.  It is likely you want this value to be
// equal to (definitely not greater than) the number of scratchpad port ROB
// slots.
//
typedef 8 MEM_PACK_READ_SLOTS;


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
//     Map an array indexed by t_ADDR_SZ bits of Bit#(t_DATA_SZ) objects onto
//     backing storage made up of objects of type Bit#(t_CONTAINDER_DATA_SZ).
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

    //
    // The internal pack modules all support multiple read ports.  Instead
    // of replicating the code for the basic memory interface, convert the
    // container to a multi-reader interface with a single read port.
    //
    MEMORY_MULTI_READ_IFC#(1, t_CONTAINER_ADDR, t_CONTAINER_DATA) mread_container <-
        mkMemIfcToMultiMemIfc(containerMem);

    //
    // Allocate the packed memory.
    //
    MEM_PACK_MULTI_READ#(1, t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA) pack_mem <-
        mkMemPackMultiRead(mread_container);

    // Convert multi-reader interface to a single reader version.
    MEM_PACK#(t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA) mem <-
        mkMultiMemIfcToMemIfc(pack_mem);

    return mem;
endmodule


//
// mkMemPackMultiRead
//     The general wrapper to use for all allocations.  Map an array indexed
//     by t_ADDR_SZ bits of Bit#(t_DATA_SZ) objects onto backing storage
//     made up of objects of type Bit#(t_CONTAINDER_DATA_SZ).
//
//     This wrapper picks the right implementation module depending on whether
//     there is a 1:1 mapping of objects to containers or a more complicated
//     mapping.
//
module mkMemPackMultiRead#(MEMORY_MULTI_READ_IFC#(n_READERS, t_CONTAINER_ADDR, t_CONTAINER_DATA) containerMem)
    // interface:
    (MEM_PACK_MULTI_READ#(n_READERS, t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Bits#(t_CONTAINER_ADDR, t_CONTAINER_ADDR_SZ),
              Bits#(t_CONTAINER_DATA, t_CONTAINER_DATA_SZ));

    //
    // Pick the appropriate packed memory module depending on the relative sizes
    // of the container and the target.
    //

    MEM_PACK_MULTI_READ#(n_READERS, t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA) pack_mem;
    if (valueOf(t_ADDR_SZ) == valueOf(t_CONTAINER_ADDR_SZ))
    begin
        // One object per container
        pack_mem <- mkMemPack1To1(containerMem);
    end
    else if (valueOf(t_ADDR_SZ) > valueOf(t_CONTAINER_ADDR_SZ))
    begin
        // Multiple objects per container
        pack_mem <- mkMemPackManyTo1(containerMem);
    end
    else
    begin
        // Object bigger than one container.  Use multiple containers for
        // each object.
        pack_mem <- mkMemPack1ToMany(containerMem);
    end

    return pack_mem;
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
module mkMemPack1To1#(MEMORY_MULTI_READ_IFC#(n_READERS, t_CONTAINER_ADDR, t_CONTAINER_DATA) containerMem)
    // interface:
    (MEM_PACK_MULTI_READ#(n_READERS, t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Bits#(t_CONTAINER_ADDR, t_CONTAINER_ADDR_SZ),
              Bits#(t_CONTAINER_DATA, t_CONTAINER_DATA_SZ));

    //
    // Read ports
    //
    Vector#(n_READERS, MEMORY_READER_IFC#(t_ADDR, t_DATA)) portsLocal = newVector();

    for(Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        portsLocal[p] =
            interface MEMORY_READER_IFC#(t_ADDR, t_DATA);
                method Action readReq(t_ADDR addr) = containerMem.readPorts[p].readReq(unpack(zeroExtendNP(pack(addr))));

                method ActionValue#(t_DATA) readRsp();
                    let v <- containerMem.readPorts[p].readRsp();
                    return unpack(truncateNP(pack(v)));
                endmethod

                method t_DATA peek() = unpack(truncateNP(pack(containerMem.readPorts[p].peek())));
                method Bool notEmpty() = containerMem.readPorts[p].notEmpty();
                method Bool notFull() = containerMem.readPorts[p].notFull();
            endinterface;
    end

    interface readPorts = portsLocal;

    //
    // Write
    //
    method Action write(t_ADDR addr, t_DATA val);
        containerMem.write(unpack(zeroExtendNP(pack(addr))), unpack(zeroExtendNP(pack(val))));
    endmethod

    method Bool writeNotFull() = containerMem.writeNotFull();
endmodule



//
// mkMemPackManyTo1 --
//     Pack multiple objects into a single container object.
//
module mkMemPackManyTo1#(MEMORY_MULTI_READ_IFC#(n_READERS, t_CONTAINER_ADDR, t_CONTAINER_DATA) containerMem)
    // interface:
    (MEM_PACK_MULTI_READ#(n_READERS, t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Bits#(t_CONTAINER_ADDR, t_CONTAINER_ADDR_SZ),
              Bits#(t_CONTAINER_DATA, t_CONTAINER_DATA_SZ),
       
              Alias#(Bit#(MEM_PACK_SMALLER_OBJ_IDX_SZ#(t_DATA_SZ, t_CONTAINER_DATA_SZ)), t_OBJ_IDX),
              Bits#(t_OBJ_IDX, t_OBJ_IDX_SZ),

              // Arrangement of objects packed in a container.  Objects are evenly
              // spaced to make packed values easier to read while debugging.
              Alias#(Vector#(TExp#(t_OBJ_IDX_SZ), Bit#(TDiv#(t_CONTAINER_DATA_SZ, TExp#(t_OBJ_IDX_SZ)))), t_PACKED_CONTAINER));

    // Sort incoming requests.  One port for each read port and another for writes.
    MERGE_FIFOF#(TAdd#(n_READERS, 1), t_ADDR) incomingReqQ <- mkMergeBypassFIFOF();

    // Write data
    FIFO#(t_DATA) writeDataQ <- mkBypassFIFO();

    // Read request info holds the address of the requested data within the
    // container.  It is also used to route reads to either the RMW path or
    // back to the client.  Separate FIFOs are allocated for each read port.
    //
    // Beware!  The FIFOs are unguarded so there can be no predicates on methods
    // below such as the memory's notEmpty method.
    FIFOF#(PACK_REQ_INFO#(t_DATA_SZ, t_CONTAINER_DATA_SZ)) readReqInfoQ[valueOf(n_READERS)];

    // Track the number of reads in flight to prevent deadlocks in which a
    // client needs to do a write following a series of queued reads.
    COUNTER_Z#(TLog#(MEM_PACK_READ_SLOTS)) readReqCnt[valueOf(n_READERS)];

    for (Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        readReqCnt[p] <- mkLCounter_Z(fromInteger(valueOf(TSub#(MEM_PACK_READ_SLOTS, 1))));

        // Port 0 gets one extra slot for the RMW
        if (p == 0)
            readReqInfoQ[p] <- mkUGSizedFIFOF(1 + valueOf(MEM_PACK_READ_SLOTS));
        else
            readReqInfoQ[p] <- mkUGSizedFIFOF(valueOf(MEM_PACK_READ_SLOTS));
    end

    //
    // Read port 0 is shared with the RMW pipeline.  To avoid deadlock, this
    // module must provide local buffering of read results.
    //
    FIFOF#(t_DATA) readResultPort0Q <- mkSizedFIFOF(valueOf(MEM_PACK_READ_SLOTS));

    // Writes must be read-modify-write.  Read the full container, update the
    // object, and write it back.  We must be careful of read/write ordering
    // to maintain memory consistency.  For now block everything else when a
    // write is being processed.
    Reg#(Bool) doingRMW <- mkReg(False);
    Reg#(t_CONTAINER_ADDR) rmwContainerAddr <- mkRegU();

    // See method readRsp
    Wire#(Bool) schedHack <- mkDWire(False);

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
    // Writes
    //

    // Write port ID is last in the merge FIFO (nREADERS since it is 0 based).
    rule processWriteReq (! doingRMW &&
                          readReqInfoQ[0].notFull() &&
                          (incomingReqQ.firstPortID() == fromInteger(valueOf(n_READERS))));
        let addr = incomingReqQ.first();
        incomingReqQ.deq();

        match {.c_addr, .o_idx} = addrSplit(addr);
        // Use read port 0 for the RMW
        containerMem.readPorts[0].readReq(c_addr);
        readReqInfoQ[0].enq(PACK_REQ_INFO {isReadForWrite: True, objIdx: o_idx});
    
        doingRMW <= True;
        rmwContainerAddr <= c_addr;
    endrule

    //
    // finishRMW --
    //     Process read response for a write.  Update the object within the
    //     container and write it back.
    //
    (* descending_urgency = "finishRMW, processWriteReq" *)
    rule finishRMW (readReqInfoQ[0].notEmpty() &&
                    readReqInfoQ[0].first().isReadForWrite &&
                    ! schedHack);
        let o_idx = readReqInfoQ[0].first().objIdx;
        readReqInfoQ[0].deq();

        let d <- containerMem.readPorts[0].readRsp();

        // Pack the current data into a vector of the number of objects
        // per container.
        t_PACKED_CONTAINER pack_data = unpack(truncateNP(pack(d)));
        
        // Update the object in the container and write it back.
        let val = writeDataQ.first();
        writeDataQ.deq();
        pack_data[o_idx] = zeroExtendNP(pack(val));
        containerMem.write(rmwContainerAddr, unpack(zeroExtendNP(pack(pack_data))));
        
        doingRMW <= False;
    endrule


    //
    // processReadReq --
    //     Forward read requests to the container memory.
    //
    for(Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        rule processReadReq (! doingRMW &&
                             readReqInfoQ[p].notFull() &&
                             (incomingReqQ.firstPortID() == fromInteger(p)));
            let addr = incomingReqQ.first();
            incomingReqQ.deq();

            match {.c_addr, .o_idx} = addrSplit(addr);
            containerMem.readPorts[p].readReq(c_addr);

            readReqInfoQ[p].enq(PACK_REQ_INFO {isReadForWrite: False, objIdx: o_idx});
        endrule
    end


    //
    // processReadPort0Rsp --
    //     The RMW pipeline shares read port 0.  The pipelines will deadlock
    //     if read port 0 is blocked for true reads.  Providing a local buffer
    //     for all possible outstanding read requests breaks the dependence.
    //
    rule processReadPort0Rsp (readReqInfoQ[0].notEmpty() &&
                              ! readReqInfoQ[0].first().isReadForWrite);
        let o_idx = readReqInfoQ[0].first().objIdx;
        readReqInfoQ[0].deq();

        readReqCnt[0].up();

        let d <- containerMem.readPorts[0].readRsp();
        t_PACKED_CONTAINER pack_data = unpack(truncateNP(pack(d)));
        readResultPort0Q.enq(unpack(truncateNP(pack_data[o_idx])));
    endrule


    //
    // Methods
    //
    Vector#(n_READERS, MEMORY_READER_IFC#(t_ADDR, t_DATA)) portsLocal = newVector();

    //
    // Port 0 read response has local buffering in order to
    // avoid deadlock.  The underlying port is shared with
    // the read-modify-write pipeline.
    //
    portsLocal[0] =
        interface MEMORY_READER_IFC#(t_ADDR, t_DATA);
            method Action readReq(t_ADDR addr) if (! readReqCnt[0].isZero());
                incomingReqQ.ports[0].enq(addr);
                readReqCnt[0].down();
            endmethod

            method ActionValue#(t_DATA) readRsp();
                let d = readResultPort0Q.first();
                readResultPort0Q.deq();

                return d;
            endmethod

            method t_DATA peek();
                return readResultPort0Q.first();
            endmethod

            method Bool notEmpty();
                return readResultPort0Q.notEmpty();
            endmethod

            method Bool notFull() = incomingReqQ.ports[0].notFull();
        endinterface;


    //
    // Read response for ports other than 0 can uses the underlying ports.
    //
    for (Integer p = 1; p < valueOf(n_READERS); p = p + 1)
    begin
        portsLocal[p] =
            interface MEMORY_READER_IFC#(t_ADDR, t_DATA);
                method Action readReq(t_ADDR addr) if (! readReqCnt[p].isZero());
                    incomingReqQ.ports[p].enq(addr);
                    readReqCnt[p].down();
                endmethod

                method ActionValue#(t_DATA) readRsp() if (readReqInfoQ[p].notEmpty() &&
                                                          ! readReqInfoQ[p].first().isReadForWrite);
                    let o_idx = readReqInfoQ[p].first().objIdx;
                    readReqInfoQ[p].deq();
    
                    readReqCnt[p].up();

                    // The compiler ought to be able to detect that this method and rule
                    // finishRMW are mutually exclusive due to their predicates.  For some
                    // reason it does not.  The schedHack wire seems to quiet the warnings.
                    if (p == 0)
                        schedHack <= True;

                    // Receive the data and return the desired object from the container.
                    let d <- containerMem.readPorts[p].readRsp();
                    t_PACKED_CONTAINER pack_data = unpack(truncateNP(pack(d)));
                    return unpack(truncateNP(pack_data[o_idx]));
                endmethod

                method t_DATA peek() if (readReqInfoQ[p].notEmpty() &&
                                         ! readReqInfoQ[p].first().isReadForWrite);
                    let o_idx = readReqInfoQ[p].first().objIdx;
    
                    // Receive the data and return the desired object from the container.
                    let d = containerMem.readPorts[p].peek();
                    t_PACKED_CONTAINER pack_data = unpack(truncateNP(pack(d)));
                    return unpack(truncateNP(pack_data[o_idx]));
                endmethod

                method Bool notEmpty();
                    // Verify that the queue has data and that the response isn't
                    // part of a RMW.
                    return containerMem.readPorts[p].notEmpty() &&
                           readReqInfoQ[p].notEmpty &&
                           ! readReqInfoQ[p].first().isReadForWrite;
                endmethod

                method Bool notFull() = incomingReqQ.ports[p].notFull();
            endinterface;
    end

    interface readPorts = portsLocal;

    method Action write(t_ADDR addr, t_DATA val);
        // Write port is the last of the incomingReqQ ports.
        incomingReqQ.ports[valueOf(n_READERS)].enq(addr);
        writeDataQ.enq(val);
    endmethod

    method Bool writeNotFull() = incomingReqQ.ports[valueOf(n_READERS)].notFull();
endmodule


//
// mkMemPack1ToMany --
//     Spread one object across multiple container objects.
//
module mkMemPack1ToMany#(MEMORY_MULTI_READ_IFC#(n_READERS, t_CONTAINER_ADDR, t_CONTAINER_DATA) containerMem)
    // interface:
    (MEM_PACK_MULTI_READ#(n_READERS, t_ADDR, t_DATA, t_CONTAINER_ADDR, t_CONTAINER_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Bits#(t_CONTAINER_ADDR, t_CONTAINER_ADDR_SZ),
              Bits#(t_CONTAINER_DATA, t_CONTAINER_DATA_SZ),

              Alias#(Bit#(MEM_PACK_LARGER_OBJ_IDX_SZ#(t_DATA_SZ, t_CONTAINER_DATA_SZ)), t_OBJ_IDX),
              Bits#(t_OBJ_IDX, t_OBJ_IDX_SZ),
       
              // Vector of multiple containers holding one object
              Alias#(Vector#(TExp#(t_OBJ_IDX_SZ), t_CONTAINER_DATA), t_PACKED_CONTAINER));

    // Sort incoming requests.  One port for each read port and another for writes.
    MERGE_FIFOF#(TAdd#(n_READERS, 1), t_ADDR) incomingReqQ <- mkMergeBypassFIFOF();

    // Shared read/write state
    Reg#(Bool) busy <- mkReg(False);
    Reg#(t_OBJ_IDX) reqIdx <- mkRegU();

    // Write state
    FIFO#(t_PACKED_CONTAINER) writeDataQ <- mkBypassFIFO();

    // Read response state.  One per read port.
    Vector#(n_READERS, Reg#(t_OBJ_IDX)) readIdx <- replicateM(mkReg(0));
    Vector#(n_READERS, Reg#(t_PACKED_CONTAINER)) readData <- replicateM(mkRegU());
    Vector#(n_READERS, FIFOF#(t_DATA)) readRspQ <- replicateM(mkBypassFIFOF());


    //
    // Need multiple containers for a single object, so the container
    // address is formed by concatenating the object address and a
    // container index.
    //
    function t_CONTAINER_ADDR addrContainer(t_ADDR addr, t_OBJ_IDX objIdx);
        return unpack(zeroExtendNP({pack(addr), objIdx}));
    endfunction


    //
    // startNewRead --
    //     First stage handling a new read request.  All but the last of the
    //     incomingReqQ ports are read request ports.
    //
    rule startNewReadReq (! busy && (incomingReqQ.firstPortID() < fromInteger(valueOf(n_READERS))));
        let addr = incomingReqQ.first();
        let c_addr = addrContainer(addr, 0);
        let port = incomingReqQ.firstPortID();

        containerMem.readPorts[port].readReq(c_addr);

        busy <= True;
        reqIdx <= 1;
    endrule

    //
    // completeReadReq --
    //     Multi-stage read request.
    //
    rule completeReadReq (busy && (incomingReqQ.firstPortID() < fromInteger(valueOf(n_READERS))));
        let addr = incomingReqQ.first();
        let c_addr = addrContainer(addr, reqIdx);
        let port = incomingReqQ.firstPortID();

        containerMem.readPorts[port].readReq(c_addr);

        if (reqIdx == maxBound)
        begin
            incomingReqQ.deq();
            busy <= False;
        end

        reqIdx <= reqIdx + 1;
    endrule

    //
    // startNewWrite --
    //     First stage handling a new write request.  The last incomingReqQ port
    //     is the write port.
    //
    rule startNewWriteReq (! busy && (incomingReqQ.firstPortID() == fromInteger(valueOf(n_READERS))));
        let addr = incomingReqQ.first();
        let c_addr = addrContainer(addr, 0);
        let write_data = writeDataQ.first();
        containerMem.write(c_addr, write_data[0]);

        busy <= True;
        reqIdx <= 1;
    endrule

    //
    // completeWrite --
    //     Multi-stage write.
    //
    rule completeWrite (busy && (incomingReqQ.firstPortID() == fromInteger(valueOf(n_READERS))));
        let addr = incomingReqQ.first();
        let c_addr = addrContainer(addr, reqIdx);

        let write_data = writeDataQ.first();
        containerMem.write(c_addr, write_data[reqIdx]);

        if (reqIdx == maxBound)
        begin
            incomingReqQ.deq();
            writeDataQ.deq();
            busy <= False;
        end

        reqIdx <= reqIdx + 1;
    endrule

    //
    // doReadRsp --
    //     Merge read responses into single values.  Forward values as they
    //     complete.
    //
    //     Each read port gets its own read response rule and data.
    //
    for (Integer i = 0; i < valueOf(n_READERS); i = i + 1)
    begin
        rule doReadRsp (True);
            let v <- containerMem.readPorts[i].readRsp();
            if (readIdx[i] != maxBound)
            begin
                readData[i][readIdx[i]] <= v;
            end
            else
            begin
                let r = readData[i];
                r[readIdx[i]] = v;
                readRspQ[i].enq(unpack(truncateNP(pack(r))));
            end
        
            readIdx[i] <= readIdx[i] + 1;
        endrule
    end

    Vector#(n_READERS, MEMORY_READER_IFC#(t_ADDR, t_DATA)) portsLocal = newVector();

    for(Integer p = 0; p < valueOf(n_READERS); p = p + 1)
    begin
        portsLocal[p] =
            interface MEMORY_READER_IFC#(t_ADDR, t_DATA);
                method Action readReq(t_ADDR addr);
                    incomingReqQ.ports[p].enq(addr);
                endmethod

                method ActionValue#(t_DATA) readRsp();
                    let v = readRspQ[p].first();
                    readRspQ[p].deq();

                    return v;
                endmethod

                method t_DATA peek() = readRspQ[p].first();
                method Bool notEmpty() = readRspQ[p].notEmpty();
                method Bool notFull() = incomingReqQ.ports[p].notFull();
            endinterface;
    end

    interface readPorts = portsLocal;

    method Action write(t_ADDR addr, t_DATA val);
        // Write port is the last of the imcomingReqQ ports.
        incomingReqQ.ports[valueOf(n_READERS)].enq(addr);

        t_PACKED_CONTAINER write_data = unpack(zeroExtendNP(pack(val)));
        writeDataQ.enq(write_data);
    endmethod

    method Bool writeNotFull() = incomingReqQ.ports[valueOf(n_READERS)].notFull();
endmodule
