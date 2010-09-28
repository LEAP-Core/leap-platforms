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


import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/fpga_components.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/local_mem.bsh"


typedef CENTRAL_CACHE_VIRTUAL_DEVICE CENTRAL_CACHE_IFC;


//
// Internal CENTRAL_CACHE_BACKING interface is mostly a backing storage interface
// for a set-associative cache.  In addition it has a debugging method.
//
interface CENTRAL_CACHE_BACKING#(type t_CACHE_ADDR,
                                 type t_CACHE_LINE,
                                 numeric type nWordsPerLine,
                                 type t_CACHE_REF_INFO);
    interface RL_SA_CACHE_SOURCE_DATA#(t_CACHE_ADDR,
                                       t_CACHE_LINE,
                                       nWordsPerLine,
                                       t_CACHE_REF_INFO) sourceData;
    
    // Debug info for DEBUG_SCAN
    method Bit#(4) nReadsInFlight();
endinterface: CENTRAL_CACHE_BACKING


//
// mkCentralCache --
//     Central cache using local memory.  One port is created for each
//     client.
//
module mkCentralCache#(LowLevelPlatformInterface llpi)
    // interface:
    (CENTRAL_CACHE_IFC)
    provisos (Bits#(CENTRAL_CACHE_LINE_ADDR, t_CENTRAL_CACHE_LINE_ADDR_SZ),
              Bits#(CENTRAL_CACHE_PORT_NUM, t_CENTRAL_CACHE_PORT_NUM_SZ),
              Add#(t_CENTRAL_CACHE_PORT_NUM_SZ, t_CENTRAL_CACHE_LINE_ADDR_SZ, t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),

              Alias#(Tuple2#(CENTRAL_CACHE_PORT_NUM, CENTRAL_CACHE_LINE_ADDR), t_CENTRAL_CACHE_INTERNAL_ADDR),

              // Compute the number of sets in the cache based on the size of local
              // memory.  The memory is broken down into 4 equal chunks:
              // 3 for the 3 ways in each set and one for a set's tag.
              Alias#(Bit#(TSub#(LOCAL_MEM_LINE_ADDR_SZ, 2)),  // 4 regions per set
                     t_CENTRAL_CACHE_SET_IDX),
              Bits#(t_CENTRAL_CACHE_SET_IDX, t_CENTRAL_CACHE_SET_IDX_SZ));

    DEBUG_FILE debugLog <- (`CENTRAL_CACHE_DEBUG_ENABLE == 1)?
                           mkDebugFile("memory_central_cache.out"):
                           mkDebugFileNull("memory_central_cache.out"); 

    DEBUG_FILE debugLogBacking <- (`CENTRAL_CACHE_DEBUG_ENABLE == 1)?
                           mkDebugFile("memory_central_cache_backing.out"):
                           mkDebugFileNull("memory_central_cache_backing.out"); 

    DEBUG_FILE debugLogInt <- (`CENTRAL_CACHE_DEBUG_ENABLE == 1)?
                             mkDebugFile("memory_central_cache_internal.out"):
                             mkDebugFileNull("memory_central_cache_internal.out"); 
   

    // Debug state
    COUNTER#(5) dbgCacheReadsInFlight <- mkLCounter(0);
    Wire#(Bool) dbgCacheReadRespReady <- mkBypassWire();
    Wire#(Bool) dbgReqLineLocked <- mkDWire(False);
    Wire#(Bit#(2)) dbgReqRuleFired <- mkDWire(0);


    Reg#(Bool) initialized <- mkReg(False);

    // Allocate connector between a standard cache backing storage interface
    // and a central cache backing storage port.
    Vector#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_BACKING_CONNECTION) backingStore = newVector();
    for (Integer p = 0; p < valueOf(CENTRAL_CACHE_N_CLIENTS); p = p + 1)
    begin
        backingStore[p] <- mkCentralCacheBackingConnection(p, debugLogBacking);
    end

    //
    // The cache talks to a single backing storage interface.  The module allocated
    // here routes cache requests to client ports.
    //
    CENTRAL_CACHE_BACKING#(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),
                           CENTRAL_CACHE_LINE,
                           CENTRAL_CACHE_WORDS_PER_LINE,
                           CENTRAL_CACHE_REF_INFO) backingConnection <- mkCentralCacheBacking(backingStore);


    //
    // The cache
    //
    RL_SA_CACHE_LOCAL_DATA#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ,
                            CENTRAL_CACHE_WORD,
                            CENTRAL_CACHE_WORDS_PER_LINE,
                            TExp#(t_CENTRAL_CACHE_SET_IDX_SZ),
                            3) cacheLocalData <- mkLocalMemCacheData(llpi, debugLogInt);

    NumTypeParam#(`CENTRAL_CACHE_LINE_RESP_CACHE_IDX_BITS) nRecentReadCacheIdxBits = ?;
    NumTypeParam#(0) nTagExtraLowBits = ?;
    RL_SA_CACHE#(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),
                 CENTRAL_CACHE_WORD,
                 CENTRAL_CACHE_WORDS_PER_LINE,
                 CENTRAL_CACHE_REF_INFO
                 ) cache <- mkCacheSetAssoc(backingConnection.sourceData,
                                            cacheLocalData,
                                            nRecentReadCacheIdxBits,
                                            nTagExtraLowBits,
                                            debugLogInt);

    // Manage routing of flush/inval ACK back to requesting port
    FIFO#(CENTRAL_CACHE_PORT_NUM) flushAckRespQ <- mkFIFO();

    //
    // addPortToAddr --
    //     Convert from a client's private address space to the global central
    //     cache address space by concatenating the port ID and the client
    //     address.
    //
    function Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ) addPortToAddr(CENTRAL_CACHE_PORT_NUM port,
                                                                  CENTRAL_CACHE_LINE_ADDR addr);
        return pack(tuple2(port, addr));
    endfunction


    // ====================================================================
    //
    // Process incoming requests here.  All requests are merged in the
    // module's methods into a single FIFO.  This is both fair and
    // eliminates compiler warnings about rule schedule conflicts.
    //
    // ====================================================================

    MERGE_FIFOF#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_REQ) reqQ <- mkMergeFIFOF();

    (* conservative_implicit_conditions *)
    rule processWriteReq (initialized &&&
                          reqQ.first() matches tagged CENTRAL_CACHE_WRITE .r);
        dbgReqRuleFired <= 2;
        CENTRAL_CACHE_PORT_NUM port = zeroExtend(reqQ.firstPortID());
        let addr = addPortToAddr(port, r.addr);

        reqQ.deq();

        debugLog.record($format("port %0d: write addr=0x%x, refInfo=0x%x, wIdx=%d, val=0x%x", port, r.addr, r.refInfo, r.wordIdx, r.val));
        cache.write(addr, r.val, r.wordIdx, r.refInfo);
    endrule


    (* conservative_implicit_conditions *)
    rule processInvalReq (initialized &&&
                          reqQ.first() matches tagged CENTRAL_CACHE_INVAL .r);
        dbgReqRuleFired <= 3;
        CENTRAL_CACHE_PORT_NUM port = zeroExtend(reqQ.firstPortID());
        let addr = addPortToAddr(port, r.addr);

        reqQ.deq();

        debugLog.record($format("port %0d: inval addr=0x%x, refInfo=0x%x, ack=%d", port, r.addr, r.refInfo, r.sendAck));
        cache.invalReq(addr, r.sendAck, r.refInfo);

        if (r.sendAck)
        begin
            // Keep track of ACK requests for routing back to the port
            flushAckRespQ.enq(port);
        end
    endrule


    (* conservative_implicit_conditions *)
    rule processFlushReq (initialized &&&
                          reqQ.first() matches tagged CENTRAL_CACHE_FLUSH .r);
        dbgReqRuleFired <= 3;
        CENTRAL_CACHE_PORT_NUM port = zeroExtend(reqQ.firstPortID());
        let addr = addPortToAddr(port, r.addr);

        reqQ.deq();

        debugLog.record($format("port %0d: flush addr=0x%x, refInfo=0x%x, ack=%d", port, r.addr, r.refInfo, r.sendAck));
        cache.flushReq(addr, r.sendAck, r.refInfo);

        if (r.sendAck)
        begin
            // Keep track of ACK requests for routing back to the port
            flushAckRespQ.enq(port);
        end
    endrule


    // ====================================================================
    //
    // Read pipeline.
    //
    // ====================================================================

    // Route read responses back to the correct port.
    FIFOF#(Tuple2#(CENTRAL_CACHE_PORT_NUM, CENTRAL_CACHE_READ_RESP)) readRespQ <- mkBypassFIFOF();

    //
    // processReadReq --
    //     Forward read requests to the cache.
    //
    (* conservative_implicit_conditions *)
    rule processReadReq (initialized &&&
                         reqQ.first() matches tagged CENTRAL_CACHE_READ .r);
        dbgReqRuleFired <= 1;
        CENTRAL_CACHE_PORT_NUM port = zeroExtend(reqQ.firstPortID());
        let addr = addPortToAddr(port, r.addr);

        reqQ.deq();

        debugLog.record($format("port %0d: readReq addr=0x%x, wordIdx=0x%x, refInfo=0x%x", port, r.addr, r.wordIdx, r.refInfo));
        cache.readReq(addr, r.wordIdx, r.refInfo);

        dbgCacheReadsInFlight.up();
    endrule


    // Descending urgency for sub-components that can't see each other
    (* descending_urgency = "cache.handleWrite, cacheLocalData.forwardDataReq" *)

    //
    // cacheReadResp --
    //     Optional 3rd stage of read request.  Forward main cache response to
    //     the client port.
    //
    rule cacheReadResp (True);
        let d <- cache.readResp();
        dbgCacheReadsInFlight.down();

        //
        // Convert internal cache response to port-specific response.
        //
        t_CENTRAL_CACHE_INTERNAL_ADDR i_addr = unpack(d.addr);
        match {.port, .addr} = i_addr;

        CENTRAL_CACHE_READ_RESP r;
        r.val = validValue(d.words[d.reqWordIdx]);
        r.addr = addr;
        r.wordIdx = d.reqWordIdx;
        r.refInfo = d.refInfo;

        // Forward data to the correct port
        readRespQ.enq(tuple2(port, r));

        debugLog.record($format("port %0d: queue readResp addr=0x%x, wordIdx=0x%x, refInfo=0x%x", port, r.addr, r.wordIdx, r.refInfo));
    endrule


    //
    // debugReadRespReady --
    //     Collect debug scan info about the cache that the scheduler.  This
    //     ought to work in the method, below, but the Bluespec scheduler
    //     can't deal with it.
    //
    rule debugReadRespReady (True);
        dbgCacheReadRespReady <= cache.readRespReady();
    endrule


    // ====================================================================
    //
    // Central cache port methods.
    //
    // ====================================================================

    //
    // Allocate the interfaces.
    //

    // These vectors will be the central cache ports.
    Vector#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_CLIENT_PORT) clientPortsLocal = newVector();
    Vector#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_BACKING_PORT) backingPortsLocal = newVector();


    //
    // Allocate an interface for each port.
    //
    for (Integer p = 0; p < valueOf(CENTRAL_CACHE_N_CLIENTS); p = p + 1)
    begin
        let backing_source = backingStore[p].cacheSourceData;

        clientPortsLocal[p] = (
            interface CENTRAL_CACHE_CLIENT_PORT;
                method Action newReq(CENTRAL_CACHE_REQ req);
                    // Add request to the FIFO.  Requests will be processed in
                    // order across all ports.
                    reqQ.ports[p].enq(req);
                endmethod

                method ActionValue#(CENTRAL_CACHE_READ_RESP) readResp() if (tpl_1(readRespQ.first()) == fromInteger(p));
                    let r = tpl_2(readRespQ.first());
                    readRespQ.deq();

                    debugLog.record($format("port %0d: readResp addr=0x%x, refInfo=0x%x", p, r.addr, r.refInfo));
                    return r;
                endmethod

                method Action invalOrFlushWait() if (flushAckRespQ.first() == fromInteger(p));
                    flushAckRespQ.deq();
                    debugLog.record($format("port %0d: inval/flush done", p));

                    cache.invalOrFlushWait();
                endmethod
            endinterface
        );

        backingPortsLocal[p] = backingStore[p].backingPort;
    end
    
    interface clientPorts = clientPortsLocal;
    interface backingPorts = backingPortsLocal;
    
    //
    // debugScanState --
    //     Compute state for a DEBUG_SCAN node.  This method must have no
    //     implicit conditions.
    //
    method CENTRAL_CACHE_DEBUG_SCAN debugScanState();
        CENTRAL_CACHE_DEBUG_SCAN d;

        d.cacheState = cache.debugScanState();

        d.dummy = 0;
        d.cacheReadRespReady = dbgCacheReadRespReady;
        d.readRespQNotEmpty = readRespQ.notEmpty();
        d.nBackingReadsInFlight = backingConnection.nReadsInFlight();

        d.reqRuleFired = dbgReqRuleFired;
        d.reqLineLocked = dbgReqLineLocked;
        d.cacheReadsInFlight = dbgCacheReadsInFlight.value();

        return d;
    endmethod

    method Action init(RL_SA_CACHE_MODE mode, Bool enableRecentLineCache) if (! initialized);
        cache.setCacheMode(mode);
        cache.setRecentLineCacheMode(enableRecentLineCache);
        initialized <= True;
    endmethod
    
    interface CENTRAL_CACHE_STATS stats;
        interface cacheStats = cache.stats;
    endinterface
endmodule


//
// mkCentralCacheBacking --
//     Connect cache module, that talks to a single backing storage interface,
//     to individual backing storage of each client connected to the central
//     cache.  The client port ID is part of the central cache address.
//
module mkCentralCacheBacking#(Vector#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_BACKING_CONNECTION) backingStore)
    // interface:
    (CENTRAL_CACHE_BACKING#(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),
                            CENTRAL_CACHE_LINE,
                            CENTRAL_CACHE_WORDS_PER_LINE,
                            CENTRAL_CACHE_REF_INFO))
    provisos (Bits#(CENTRAL_CACHE_LINE_ADDR, t_CENTRAL_CACHE_LINE_ADDR_SZ),
              Bits#(CENTRAL_CACHE_PORT_NUM, t_CENTRAL_CACHE_PORT_NUM_SZ),
              Add#(t_CENTRAL_CACHE_PORT_NUM_SZ, t_CENTRAL_CACHE_LINE_ADDR_SZ, t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),

              Alias#(Tuple2#(CENTRAL_CACHE_PORT_NUM, CENTRAL_CACHE_LINE_ADDR), t_CENTRAL_CACHE_INTERNAL_ADDR));

    FIFO#(CENTRAL_CACHE_PORT_NUM) readQ <- mkSizedFIFO(8);
    FIFO#(CENTRAL_CACHE_PORT_NUM) writeSyncQ <- mkSizedFIFO(8);

    // Debug state
    COUNTER#(4) nActiveReads <- mkLCounter(0);


    //
    // splitInternalAddr --
    //     Break central cache address into port ID and client address.
    //
    function t_CENTRAL_CACHE_INTERNAL_ADDR splitInternalAddr(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ) addr);
        t_CENTRAL_CACHE_INTERNAL_ADDR i_addr = unpack(addr);
        return i_addr;
    endfunction


    interface RL_SA_CACHE_SOURCE_DATA sourceData;
        method Action readReq(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ) addr, CENTRAL_CACHE_REF_INFO refInfo);
            // Figure out from which central cache port to request the data and
            // forward the request.
            match {.i_port, .i_addr} = splitInternalAddr(addr);
            backingStore[i_port].cacheSourceData.readReq(i_addr, refInfo);

            // Note read request port ID
            readQ.enq(i_port);
            nActiveReads.up();
        endmethod

        method ActionValue#(CENTRAL_CACHE_LINE) readResp();
            // The cache expects readReq/readResp in order.  Forward the response from
            // the appropriate central cache port.
            let r <- backingStore[readQ.first()].cacheSourceData.readResp();
            readQ.deq();
            nActiveReads.down();
            return r;
        endmethod

        // Asynchronous write (no response)
        method Action write(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ) addr,
                            Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) wordValidMask,
                            CENTRAL_CACHE_LINE val,
                            CENTRAL_CACHE_REF_INFO refInfo);
            // Figure out to which central cache port the write should be sent.
            match {.i_port, .i_addr} = splitInternalAddr(addr);
            backingStore[i_port].cacheSourceData.write(i_addr, wordValidMask, val, refInfo);
        endmethod

        // Synchronous write.  writeSyncWait() blocks until the response arrives.
        method Action writeSyncReq(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ) addr,
                                   Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) wordValidMask,
                                   CENTRAL_CACHE_LINE val,
                                   CENTRAL_CACHE_REF_INFO refInfo);
            match {.i_port, .i_addr} = splitInternalAddr(addr);
            backingStore[i_port].cacheSourceData.writeSyncReq(i_addr, wordValidMask, val, refInfo);

            // Note sync request port ID
            writeSyncQ.enq(i_port);
        endmethod

        method Action writeSyncWait();
            // Tell cache when write syncs send an ACK
            backingStore[writeSyncQ.first()].cacheSourceData.writeSyncWait();
            writeSyncQ.deq();
        endmethod
    endinterface

    // Debug info for DEBUG_SCAN
    method Bit#(4) nReadsInFlight();
        return nActiveReads.value();
    endmethod
endmodule



// ========================================================================
//
// Set associative cache's local memory storage.
//
// ========================================================================


//
// mkMultiReaderLocalMem --
//     Manage multiple, virtual, read ports from the local memory.
//

interface LOCAL_MEMORY_CACHE_IFC;
    method Action readLineReq(LOCAL_MEM_ADDR addr);
    method ActionValue#(LOCAL_MEM_LINE) readLineRsp();
    method Bool notEmpty();
endinterface: LOCAL_MEMORY_CACHE_IFC


interface LOCAL_MEMORY_MULTI_READ_CACHE_IFC#(numeric type nReadPorts);
    interface Vector#(nReadPorts, LOCAL_MEMORY_CACHE_IFC) readPorts;

    method Action writeWord(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data);
    method Action writeLine(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data);
    method Action writeLineMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data, LOCAL_MEM_LINE_MASK mask);
endinterface: LOCAL_MEMORY_MULTI_READ_CACHE_IFC


module mkMultiReaderLocalMem#(LowLevelPlatformInterface llpi, DEBUG_FILE debugLog)
    // interface:
    (LOCAL_MEMORY_MULTI_READ_CACHE_IFC#(nReadPorts));

    FIFOF#(Bit#(TLog#(nReadPorts))) readQ <- mkSizedFIFOF(8);

    //
    // Compute the notEmpty read port state using a rule and wires so the
    // scheduling is local to this module.
    //
    Vector#(nReadPorts, Wire#(Bool)) readPortNotEmpty <- replicateM(mkDWire(False));

    for (Integer p = 0; p < valueOf(nReadPorts); p = p + 1)
    begin
        rule computeReadPortNotEmpty (readQ.first() == fromInteger(p));
            // Read data is for this port
            readPortNotEmpty[p] <= True;
        endrule
    end


    //
    // Read port methods
    //
    Vector#(nReadPorts, LOCAL_MEMORY_CACHE_IFC) portsLocal = newVector;
    for (Integer p = 0; p < valueOf(nReadPorts); p = p + 1)
    begin
        portsLocal[p] = (
            interface LOCAL_MEMORY_CACHE_IFC;
                method Action readLineReq(LOCAL_MEM_ADDR addr);
                    llpi.localMem.readLineReq(addr);
                    readQ.enq(fromInteger(p));
                    debugLog.record($format("      DDR readLineReq port %0d: addr=0x%x", p, addr));
                endmethod

                method ActionValue#(LOCAL_MEM_LINE) readLineRsp() if (readQ.first() == fromInteger(p));
                    readQ.deq();

                    let d <- llpi.localMem.readLineRsp();
                    debugLog.record($format("      DDR readLineRsp port %0d: val=0x%x", p, d));

                    return d;
                endmethod

                method Bool notEmpty() = readPortNotEmpty[p];
            endinterface
            );
    end

    interface readPorts = portsLocal;

    method Action writeWord(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data);
        llpi.localMem.writeWord(addr, data);
    endmethod

    method Action writeLine(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data);
        llpi.localMem.writeLine(addr, data);
    endmethod

    method Action writeLineMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data, LOCAL_MEM_LINE_MASK mask);
        llpi.localMem.writeLineMasked(addr, data, mask);
    endmethod
endmodule


//
// mkLocalMemCacheData --
//     Set associative cache local storage.
//
module mkLocalMemCacheData#(LowLevelPlatformInterface llpi, DEBUG_FILE debugLog)
    // interface:
    (RL_SA_CACHE_LOCAL_DATA#(t_CACHE_ADDR_SZ, t_CACHE_WORD, LOCAL_MEM_WORDS_PER_LINE, nSets, nWays))
    provisos (Bits#(t_CACHE_WORD, LOCAL_MEM_WORD_SZ),
              Alias#(RL_SA_CACHE_SET_METADATA#(t_CACHE_ADDR_SZ, LOCAL_MEM_WORDS_PER_LINE, nSets, nWays), t_SET_METADATA),
              Bits#(t_SET_METADATA, t_SET_METADATA_SZ),
              Alias#(RL_SA_CACHE_SET_IDX#(nSets), t_CACHE_SET_IDX),
              Alias#(RL_SA_CACHE_WAY_IDX#(nWays), t_CACHE_WAY_IDX),

              // Need an extra read port for the metadata
              Add#(RL_SA_CACHE_DATA_READ_PORTS, 1, t_N_READ_PORTS),
              Add#(RL_SA_CACHE_DATA_READ_PORTS, 0, t_METADATA_READ_PORT),

              // Assert size relationship of number of sets & ways to address
              Bits#(t_CACHE_SET_IDX, t_CACHE_SET_IDX_SZ),
              Bits#(t_CACHE_WAY_IDX, t_CACHE_WAY_IDX_SZ),
              Add#(t_CACHE_SET_IDX_SZ, t_CACHE_WAY_IDX_SZ, LOCAL_MEM_LINE_ADDR_SZ),

              // Assert size of data relative to local memory
              Add#(t_SET_METADATA_SZ, t_UNUSED_META_BIT_SZ, LOCAL_MEM_LINE_SZ),
              Bits#(Vector#(LOCAL_MEM_WORDS_PER_LINE, t_CACHE_WORD), LOCAL_MEM_LINE_SZ));

    // Connection to local memory
    LOCAL_MEMORY_MULTI_READ_CACHE_IFC#(t_N_READ_PORTS) memory <- mkMultiReaderLocalMem(llpi, debugLog);


    // ====================================================================
    //
    // Data and metadata address mapping functions.  The data is limited
    // to half of available memory since the cache algorithm depends on
    // sets being a power of 2.  The mapping here uses the low bit of 0 to
    // indicate data and 1 for metadata.  The metadata is not dense.
    //
    // Using the low bit keeps metadata on the same page as the data.
    // Toggling the low bit instead of the high bit for the metadata
    // read may open the DDR page for the data read.
    //
    // ====================================================================

    //
    // getDataAddr --
    //     Convert set and way into a local memory address.
    //
    function LOCAL_MEM_ADDR getDataIdx(t_CACHE_SET_IDX set, t_CACHE_WAY_IDX way);
        // Way must not be 3!  Cache only has 3 ways, so that shouldn't happen.
        return localMemLineAddrToAddr({ pack(set), pack(way) });
    endfunction


    //
    // getMetadataAddr --
    //     Convert set and way into a local memory address.
    //
    function LOCAL_MEM_ADDR getMetadataIdx(t_CACHE_SET_IDX set);
        // Last way slot is the metadata
        t_CACHE_WAY_IDX metaWay = maxBound;
        return localMemLineAddrToAddr({ pack(set), pack(metaWay) });
    endfunction


    // ====================================================================
    //
    // Initialization
    //
    // ====================================================================

    Reg#(Bool) initialized <- mkReg(False);
    Reg#(RL_SA_CACHE_SET_IDX#(nSets)) initIdx <- mkReg(0);
    
    rule initMetaData (! initialized);
        t_SET_METADATA mInit = RL_SA_CACHE_SET_METADATA { lru: Vector::genWith(fromInteger),
                                                          ways: Vector::replicate(tagged Invalid) };
        memory.writeLine(getMetadataIdx(initIdx), zeroExtend(pack(mInit)));

        if (initIdx == maxBound)
        begin
            initialized <= True;
        end

        initIdx <= initIdx + 1;
    endrule


    // ====================================================================
    //
    // Read request FIFOs.  Read requests are buffered through FIFOs in
    // order to break scheduling dependence between data and metadata
    // reads and between reads and writes.  The cache may deadlock
    // without it.  Relaxed read/write ordering is fine here since the
    // cache already guarantees to handle at most one reference at 
    // a time per set.
    //
    // ====================================================================

    FIFO#(RL_SA_CACHE_SET_IDX#(nSets)) readMetadataReqQ <- mkBypassFIFO();
    FIFO#(Tuple3#(Bit#(TLog#(t_N_READ_PORTS)), RL_SA_CACHE_SET_IDX#(nSets), RL_SA_CACHE_WAY_IDX#(nWays))) readDataReqQ <- mkBypassFIFO();

    rule forwardMetadataReq (initialized);
        let set = readMetadataReqQ.first();
        readMetadataReqQ.deq();

        memory.readPorts[valueOf(t_METADATA_READ_PORT)].readLineReq(getMetadataIdx(set));
    endrule

    //
    // Reading data must have higher priority than reading metadata to avoid
    // deadlocks in the cache.
    //
    (* descending_urgency = "forwardDataReq, forwardMetadataReq" *)
    rule forwardDataReq (initialized);
        match {.port, .set, .way} = readDataReqQ.first();
        readDataReqQ.deq();

        memory.readPorts[port].readLineReq(getDataIdx(set, way));
    endrule


    // ====================================================================
    //
    // Metadata read response buffer.  Avoid deadlock between metadata and
    // data reads by providing output buffer space for all outstanding
    // metdata read requests.
    //
    // ====================================================================

    FIFOF#(t_SET_METADATA) readMetadataRespQ <- mkSizedFIFOF(8);
    COUNTER#(4) readMetadataCnt <- mkLCounter(8);

    rule forwardMetadataResp (True);
        let d <- memory.readPorts[valueOf(t_METADATA_READ_PORT)].readLineRsp();
        readMetadataRespQ.enq(unpack(truncate(pack(d))));
    endrule


    //
    // Metadata access methods
    //

    interface MEMORY_IFC metaData;
        method Action readReq(RL_SA_CACHE_SET_IDX#(nSets) set) if (readMetadataCnt.value != 0);
            readMetadataCnt.down();
            readMetadataReqQ.enq(set);
        endmethod

        method ActionValue#(t_SET_METADATA) readRsp();
            let d = readMetadataRespQ.first();
            readMetadataRespQ.deq();
    
            readMetadataCnt.up();

            return d;
        endmethod

        method Action write(RL_SA_CACHE_SET_IDX#(nSets) set, t_SET_METADATA mData) if (initialized);
            memory.writeLine(getMetadataIdx(set), zeroExtend(pack(mData)));
        endmethod
    
        // Required for memory interface but doesn't make sense for local memory
        method t_SET_METADATA peek() if (False);
            return ?;
        endmethod
    
        method Bool notEmpty();
            return readMetadataRespQ.notEmpty();
        endmethod
    
        method Bool notFull() = (readMetadataCnt.value != 0);
        method Bool writeNotFull() = True;
    endinterface


    //
    // Data access methods
    //

    // Read all words in a line
    method Action dataReadReq(Integer readPort,
                              RL_SA_CACHE_SET_IDX#(nSets) set,
                              RL_SA_CACHE_WAY_IDX#(nWays) way);
        readDataReqQ.enq(tuple3(fromInteger(readPort), set, way));
    endmethod

    method ActionValue#(Vector#(LOCAL_MEM_WORDS_PER_LINE, t_CACHE_WORD)) dataReadRsp(Integer readPort);
        let d <- memory.readPorts[readPort].readLineRsp();
        return unpack(d);
    endmethod

    method Bool dataReadNotEmpty(Integer readPort);
        return memory.readPorts[readPort].notEmpty();
    endmethod


    method Action dataWrite(RL_SA_CACHE_SET_IDX#(nSets) set,
                            RL_SA_CACHE_WAY_IDX#(nWays) way,
                            Vector#(LOCAL_MEM_WORDS_PER_LINE, Bool) wordMask,
                            Vector#(LOCAL_MEM_WORDS_PER_LINE, t_CACHE_WORD) val) if (initialized);

        // The memory interface uses byte write masks.  Convert the word mask
        // to bytes.
        Vector#(LOCAL_MEM_WORDS_PER_LINE,
                Vector#(LOCAL_MEM_BYTES_PER_WORD, Bool)) byte_mask = newVector();
        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            byte_mask[w] = replicate(wordMask[w]);
        end

        memory.writeLineMasked(getDataIdx(set, way), pack(val), byte_mask);
    endmethod

    method Action dataWriteWord(RL_SA_CACHE_SET_IDX#(nSets) set,
                                RL_SA_CACHE_WAY_IDX#(nWays) way,
                                Bit#(TLog#(LOCAL_MEM_WORDS_PER_LINE)) wordIdx,
                                t_CACHE_WORD val) if (initialized);

        memory.writeWord(getDataIdx(set, way) | zeroExtendNP(wordIdx), pack(val));
    endmethod

endmodule
