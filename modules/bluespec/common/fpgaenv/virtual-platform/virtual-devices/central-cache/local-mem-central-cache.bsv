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
import Vector::*;

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/fpga_components.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/virtual_devices.bsh"
`include "asim/provides/local_mem.bsh"


typedef CENTRAL_CACHE_VIRTUAL_DEVICE CENTRAL_CACHE_IFC;


//
// mkCentralCache --
//     Central cache using local memory.  One port is created for each
//     client.
//
module mkCentralCache#(LowLevelPlatformInterface llpi)
    // interface:
    (CENTRAL_CACHE_IFC)
    provisos (Bits#(CENTRAL_CACHE_ADDR, t_CENTRAL_CACHE_ADDR_SZ),
              // Central cache addresses are the concetenation of a client's
              // port number and client addresses.  Compute the size of the
              // central cache's internal addresses.  The Max#() function
              // guarantees that the port ID is at least 1 bit.
              Max#(1, TLog#(CENTRAL_CACHE_N_CLIENTS), t_CENTRAL_CACHE_PORT_ID_SZ),
              Add#(t_CENTRAL_CACHE_PORT_ID_SZ, t_CENTRAL_CACHE_ADDR_SZ, t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),

              Alias#(Bit#(t_CENTRAL_CACHE_PORT_ID_SZ), t_CENTRAL_CACHE_PORT_ID),
              Alias#(Tuple2#(t_CENTRAL_CACHE_PORT_ID, CENTRAL_CACHE_ADDR), t_CENTRAL_CACHE_INTERNAL_ADDR),

              // Compute the number of sets in the cache based on the size of local
              // memory.  Assumptions:
              //   - Cache data uses half of the available memory, reserving the
              //     reset for tags.  In reality tags would take less than 25%
              //     of the memory, but the current cache algorithm requires the
              //     number of sets to be a power of 2.
              //   - 4 ways per set.
              Alias#(Bit#(TSub#(TSub#(LOCAL_MEM_LINE_ADDR_SZ, 1),  // Half the memory
                                2)),   // 4 ways per set
                     t_CENTRAL_CACHE_SET_IDX),
              Bits#(t_CENTRAL_CACHE_SET_IDX, t_CENTRAL_CACHE_SET_IDX_SZ));

    DEBUG_FILE debugLog <- mkDebugFile("memory_central_cache.out");

    Reg#(Bool) initialized <- mkReg(False);

    // Use the cache?  If not, requests are routed directly to backing storage.
    Reg#(Bool) cacheEnabled <- mkRegU();

    // Allocate connector between a standard cache backing storage interface
    // and a central cache backing storage port.
    Vector#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_BACKING_CONNECTION) backingStore = newVector();
    for (Integer p = 0; p < valueOf(CENTRAL_CACHE_N_CLIENTS); p = p + 1)
    begin
        backingStore[p] <- mkCentralCacheBackingConnection(p, debugLog);
    end

    //
    // The cache talks to a single backing storage interface.  The module allocated
    // here routes cache requests to client ports.
    //
    RL_SA_CACHE_SOURCE_DATA#(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),
                             CENTRAL_CACHE_LINE,
                             CENTRAL_CACHE_WORDS_PER_LINE,
                             CENTRAL_CACHE_REF_INFO) backingConnection <- mkCentralCacheBacking(backingStore);


    //
    // Internal communication
    //
    Vector#(CENTRAL_CACHE_N_CLIENTS, FIFO#(Tuple2#(CENTRAL_CACHE_ADDR,
                                                   CENTRAL_CACHE_REF_INFO))) readQ <- replicateM(mkFIFO());
    Vector#(CENTRAL_CACHE_N_CLIENTS, FIFO#(Bool)) invalAckQ <- replicateM(mkFIFO());


    //
    // The cache
    //
    RL_SA_CACHE_STATS stats <- mkNullRLCacheStats();

    RL_SA_CACHE_LOCAL_DATA#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ,
                            CENTRAL_CACHE_WORD,
                            CENTRAL_CACHE_WORDS_PER_LINE,
                            TExp#(t_CENTRAL_CACHE_SET_IDX_SZ),
                            4) cacheLocalData <- mkLocalMemCacheData(llpi, debugLog);

    RL_SA_CACHE#(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),
                 CENTRAL_CACHE_WORD,
                 CENTRAL_CACHE_WORDS_PER_LINE,
                 CENTRAL_CACHE_REF_INFO,
                 0) cache <- mkCacheSetAssoc(backingConnection,
                                             cacheLocalData,
                                             stats,
                                             True,
                                             debugLog);


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
    // addPortToAddr --
    //     Convert from a client's private address space to the global central
    //     cache address space by concatenating the port ID and the client
    //     address.
    //
    function Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ) addPortToAddr(Integer port,
                                                                  CENTRAL_CACHE_ADDR addr);
        t_CENTRAL_CACHE_PORT_ID p = fromInteger(port);
        return pack(tuple2(p, addr));
    endfunction
    

    //
    // Allocate an interface for each port.
    //
    for (Integer p = 0; p < valueOf(CENTRAL_CACHE_N_CLIENTS); p = p + 1)
    begin
        let backing_source = backingStore[p].cacheSourceData;

        clientPortsLocal[p] = (
            interface CENTRAL_CACHE_CLIENT_PORT;
                method Action readReq(CENTRAL_CACHE_ADDR addr,
                                      Bit#(TLog#(CENTRAL_CACHE_WORDS_PER_LINE)) wordIdx,
                                      CENTRAL_CACHE_REF_INFO refInfo) if (initialized);
                    debugLog.record($format("port %0d: readReq addr=0x%x, wordIdx=0x%x, refInfo=0x%x", p, addr, wordIdx, refInfo));

                    if (cacheEnabled)
                    begin
                        cache.readReq(addPortToAddr(p, addr), wordIdx, refInfo);
                    end
                    else
                    begin
                        // Cache disabled -- access backing storage directly.
                        backing_source.readReq(addr, refInfo);
                        readQ[p].enq(tuple2(addr, refInfo));
                    end
                endmethod

                method ActionValue#(CENTRAL_CACHE_READ_RESP) readResp();
                    CENTRAL_CACHE_READ_RESP r;

                    if (cacheEnabled)
                    begin
                        let d <- cache.readResp();

                        //
                        // Convert internal cache response to port-specific response.
                        // The only change is dropping the port ID from the address.
                        //
                        t_CENTRAL_CACHE_INTERNAL_ADDR i_addr = unpack(d.addr);
                        r.addr = tpl_2(i_addr);
                        r.refInfo = d.refInfo;
                        r.words = d.words;
                    end
                    else
                    begin
                        // Cache disabled...
                        let d <- backing_source.readResp();

                        match {.addr, .ref_info} = readQ[p].first();
                        readQ[p].deq();
           
                        //
                        // Convert backing storage response to central cache response
                        // by adding a valid bit to each word of the line.
                        //
                        Vector#(CENTRAL_CACHE_WORDS_PER_LINE, CENTRAL_CACHE_WORD) v = unpack(d);
                        r.addr = addr;
                        r.refInfo = ref_info;
                        for (Integer w = 0; w < valueOf(CENTRAL_CACHE_WORDS_PER_LINE); w = w + 1)
                            r.words[w] = tagged Valid v[w];
                    end

                    debugLog.record($format("port %0d: readResp addr=0x%x, refInfo=0x%x", p, r.addr, r.refInfo));
                    return r;
                endmethod

                method Action write(CENTRAL_CACHE_ADDR addr,
                                    CENTRAL_CACHE_WORD val,
                                    Bit#(TLog#(CENTRAL_CACHE_WORDS_PER_LINE)) wordIdx,
                                    CENTRAL_CACHE_REF_INFO refInfo) if (initialized);

                    debugLog.record($format("port %0d: write addr=0x%x, refInfo=0x%x, wIdx=%d, val=0x%x", p, addr, refInfo, wordIdx, val));

                    if (cacheEnabled)
                    begin
                        cache.write(addPortToAddr(p, addr), val, wordIdx, refInfo);
                    end
                    else
                    begin
                        //
                        // Backing storage write takes a line and a mask to indicate
                        // which words are valid in the line.  Build the line and mask.
                        //
                        Vector#(CENTRAL_CACHE_WORDS_PER_LINE, CENTRAL_CACHE_WORD) v = ?;
                        v[wordIdx] = val;

                        Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) mask = replicate(False);
                        mask[wordIdx] = True;
           
                        backing_source.write(addr, mask, pack(v), refInfo);
                    end
                endmethod
    

                method Action invalReq(CENTRAL_CACHE_ADDR addr, Bool sendAck, CENTRAL_CACHE_REF_INFO refInfo) if (initialized);
                    debugLog.record($format("port %0d: inval addr=0x%x, refInfo=0x%x, ack=%d", p, addr, refInfo, sendAck));
                    if (cacheEnabled)
                    begin
                        cache.invalReq(addPortToAddr(p, addr), sendAck, refInfo);
                    end
                    else if (sendAck)
                    begin
                        invalAckQ[p].enq(True);
                    end
                endmethod

                method Action flushReq(CENTRAL_CACHE_ADDR addr, Bool sendAck, CENTRAL_CACHE_REF_INFO refInfo) if (initialized);
                    debugLog.record($format("port %0d: flush addr=0x%x, refInfo=0x%x, ack=%d", p, addr, refInfo, sendAck));
                    if (cacheEnabled)
                    begin
                        cache.flushReq(addPortToAddr(p, addr), sendAck, refInfo);
                    end
                    else if (sendAck)
                    begin
                        invalAckQ[p].enq(True);
                    end
                endmethod

                method Action invalOrFlushWait();
                    debugLog.record($format("port %0d: inval/flush done"));
                    if (cacheEnabled)
                    begin
                        cache.invalOrFlushWait();
                    end
                    else
                    begin
                        invalAckQ[p].deq();
                    end
                endmethod
            endinterface
        );

        backingPortsLocal[p] = backingStore[p].backingPort;
    end
    
    interface clientPorts = clientPortsLocal;
    interface backingPorts = backingPortsLocal;
    
    method Action init(Bool enableCache, Bool cacheIsWriteBack) if (! initialized);
        cacheEnabled <= enableCache;
        cache.setModeWriteBack(cacheIsWriteBack);
        initialized <= True;
    endmethod
endmodule


//
// mkCentralCacheBacking --
//     Connect cache module, that talks to a single backing storage interface,
//     to individual backing storage of each client connected to the central
//     cache.  The client port ID is part of the central cache address.
//
module mkCentralCacheBacking#(Vector#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_BACKING_CONNECTION) backingStore)
    // interface:
    (RL_SA_CACHE_SOURCE_DATA#(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),
                              CENTRAL_CACHE_LINE,
                              CENTRAL_CACHE_WORDS_PER_LINE,
                              CENTRAL_CACHE_REF_INFO))
    provisos (Bits#(CENTRAL_CACHE_ADDR, t_CENTRAL_CACHE_ADDR_SZ),
              // See mkCentralCache above for a description.
              Max#(1, TLog#(CENTRAL_CACHE_N_CLIENTS), t_CENTRAL_CACHE_PORT_ID_SZ),
              Add#(t_CENTRAL_CACHE_PORT_ID_SZ, t_CENTRAL_CACHE_ADDR_SZ, t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),

              Alias#(Bit#(t_CENTRAL_CACHE_PORT_ID_SZ), t_CENTRAL_CACHE_PORT_ID),
              Alias#(Tuple2#(t_CENTRAL_CACHE_PORT_ID, CENTRAL_CACHE_ADDR), t_CENTRAL_CACHE_INTERNAL_ADDR));

    FIFO#(t_CENTRAL_CACHE_PORT_ID) readQ <- mkSizedFIFO(16);
    FIFO#(t_CENTRAL_CACHE_PORT_ID) writeSyncQ <- mkSizedFIFO(16);


    //
    // splitInternalAddr --
    //     Break central cache address into port ID and client address.
    //
    function t_CENTRAL_CACHE_INTERNAL_ADDR splitInternalAddr(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ) addr);
        t_CENTRAL_CACHE_INTERNAL_ADDR i_addr = unpack(addr);
        return i_addr;
    endfunction


    method Action readReq(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ) addr, CENTRAL_CACHE_REF_INFO refInfo);
        match {.i_port, .i_addr} = splitInternalAddr(addr);
        backingStore[i_port].cacheSourceData.readReq(i_addr, refInfo);
        readQ.enq(i_port);
    endmethod

    method ActionValue#(CENTRAL_CACHE_LINE) readResp();
        let r <- backingStore[readQ.first()].cacheSourceData.readResp();
        readQ.deq();
        return r;
    endmethod
    
    // Asynchronous write (no response)
    method Action write(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ) addr,
                        Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) wordValidMask,
                        CENTRAL_CACHE_LINE val,
                        CENTRAL_CACHE_REF_INFO refInfo);
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
    endmethod

    method Action writeSyncWait();
        backingStore[writeSyncQ.first()].cacheSourceData.writeSyncWait();
        writeSyncQ.deq();
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

    FIFOF#(Bit#(TLog#(nReadPorts))) readQ <- mkSizedFIFOF(16);

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
              Add#(t_CACHE_SET_IDX_SZ, TAdd#(t_CACHE_WAY_IDX_SZ, 1), LOCAL_MEM_LINE_ADDR_SZ),
              Add#(t_CACHE_WAY_IDX_SZ, 1, TAdd#(t_CACHE_WAY_IDX_SZ, 1)),

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
        // Data is in memory with high bit set to 0
        return localMemLineAddrToAddr({ pack(set), pack(way), 1'b0 });
    endfunction


    //
    // getMetadataAddr --
    //     Convert set and way into a local memory address.
    //
    function LOCAL_MEM_ADDR getMetadataIdx(t_CACHE_SET_IDX set);
        t_CACHE_WAY_IDX dummy = 0;
        return localMemLineAddrToAddr({ pack(set), pack(dummy), 1'b1 });
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

    FIFO#(RL_SA_CACHE_SET_IDX#(nSets)) readMetadataReqQ <- mkFIFO();
    FIFO#(Tuple3#(Bit#(TLog#(t_N_READ_PORTS)), RL_SA_CACHE_SET_IDX#(nSets), RL_SA_CACHE_WAY_IDX#(nWays))) readDataReqQ <- mkFIFO();

    rule forwardMetadataReq (initialized);
        let set = readMetadataReqQ.first();
        readMetadataReqQ.deq();

        memory.readPorts[valueOf(t_METADATA_READ_PORT)].readLineReq(getMetadataIdx(set));
    endrule

    rule forwardDataReq (initialized);
        match {.port, .set, .way} = readDataReqQ.first();
        readDataReqQ.deq();

        memory.readPorts[port].readLineReq(getDataIdx(set, way));
    endrule


    //
    // Metadata access methods
    //

    interface MEMORY_IFC metaData;
        method Action readReq(RL_SA_CACHE_SET_IDX#(nSets) set);
            readMetadataReqQ.enq(set);
        endmethod

        method ActionValue#(t_SET_METADATA) readRsp();
            let d <- memory.readPorts[valueOf(t_METADATA_READ_PORT)].readLineRsp();
            return unpack(truncate(pack(d)));
        endmethod

        method Action write(RL_SA_CACHE_SET_IDX#(nSets) set, t_SET_METADATA mData) if (initialized);
            memory.writeLine(getMetadataIdx(set), zeroExtend(pack(mData)));
        endmethod
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


    method Action dataWrite(RL_SA_CACHE_SET_IDX#(nSets) set,
                            RL_SA_CACHE_WAY_IDX#(nWays) way,
                            Vector#(LOCAL_MEM_WORDS_PER_LINE, Bool) wordMask,
                            Vector#(LOCAL_MEM_WORDS_PER_LINE, t_CACHE_WORD) val) if (initialized);

        memory.writeLineMasked(getDataIdx(set, way), pack(val), wordMask);
    endmethod

    method Action dataWriteWord(RL_SA_CACHE_SET_IDX#(nSets) set,
                                RL_SA_CACHE_WAY_IDX#(nWays) way,
                                Bit#(TLog#(LOCAL_MEM_WORDS_PER_LINE)) wordIdx,
                                t_CACHE_WORD val) if (initialized);

        memory.writeWord(getDataIdx(set, way) | zeroExtendNP(wordIdx), pack(val));
    endmethod

endmodule
