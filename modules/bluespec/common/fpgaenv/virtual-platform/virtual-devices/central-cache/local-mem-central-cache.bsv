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
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/virtual_devices.bsh"


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
              Alias#(Tuple2#(t_CENTRAL_CACHE_PORT_ID, CENTRAL_CACHE_ADDR), t_CENTRAL_CACHE_INTERNAL_ADDR));
    
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
    HASIM_CACHE_SOURCE_DATA#(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),
                             CENTRAL_CACHE_LINE,
                             CENTRAL_CACHE_WORDS_PER_LINE,
                             CENTRAL_CACHE_REF_INFO) backingConnection <- mkCentralCacheBacking(backingStore);


    //
    // Internal communication
    //
    Vector#(CENTRAL_CACHE_N_CLIENTS, FIFOF#(Tuple2#(CENTRAL_CACHE_ADDR,
                                                    CENTRAL_CACHE_REF_INFO))) readQ <- replicateM(mkFIFOF());
    Vector#(CENTRAL_CACHE_N_CLIENTS, FIFO#(Bool)) invalAckQ <- replicateM(mkFIFO());


    //
    // The cache
    //
    HASIM_CACHE_STATS stats <- mkNullHAsimCacheStats();
    HASIM_CACHE#(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),
                 CENTRAL_CACHE_LINE,
                 CENTRAL_CACHE_WORD,
                 CENTRAL_CACHE_WORDS_PER_LINE,
                 CENTRAL_CACHE_REF_INFO,
                 256,
                 4,
                 0) cache <- mkCacheSetAssoc(backingConnection,
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
                                    CENTRAL_CACHE_REF_INFO refInfo) if (initialized && readQ[p].notFull());

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
    (HASIM_CACHE_SOURCE_DATA#(Bit#(t_CENTRAL_CACHE_INTERNAL_ADDR_SZ),
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
