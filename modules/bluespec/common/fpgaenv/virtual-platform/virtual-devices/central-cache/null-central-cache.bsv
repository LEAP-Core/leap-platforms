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
// NULL implementation of a central cache.  The NULL version still implements
// full central cache semantics by routing incoming requests to the backing
// storage.  Without a cache all requests are routed to backing storage.
//


import FIFO::*;
import FIFOF::*;
import Vector::*;

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/virtual_devices.bsh"

typedef CENTRAL_CACHE_VIRTUAL_DEVICE CENTRAL_CACHE_IFC;

module mkCentralCache#(LowLevelPlatformInterface llpi)
    // interface:
    (CENTRAL_CACHE_IFC);
    
    DEBUG_FILE debugLog <- mkDebugFile("memory_central_cache.out");

    //
    // Internal communication
    //
    Vector#(CENTRAL_CACHE_N_CLIENTS, FIFOF#(Tuple2#(CENTRAL_CACHE_ADDR,
                                                    CENTRAL_CACHE_REF_INFO))) readQ <- replicateM(mkFIFOF());
    Vector#(CENTRAL_CACHE_N_CLIENTS, FIFO#(Bool)) invalAckQ <- replicateM(mkFIFO());


    // ====================================================================
    //
    // Central cache port methods.
    //
    // ====================================================================

    //
    // Allocate the interfaces.
    //

    // Allocate connector between a standard cache backing storage interface
    // and a central back backing storage port.
    Vector#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_BACKING_CONNECTION) backingStore = newVector();

    // These vectors will be the central cache ports.
    Vector#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_CLIENT_PORT) clientPortsLocal = newVector();
    Vector#(CENTRAL_CACHE_N_CLIENTS, CENTRAL_CACHE_BACKING_PORT) backingPortsLocal = newVector();
    
    //
    // Allocate an interface for each port.
    //
    for (Integer p = 0; p < valueOf(CENTRAL_CACHE_N_CLIENTS); p = p + 1)
    begin
        backingStore[p] <- mkCentralCacheBackingConnection(p, debugLog);

        let backing_source = backingStore[p].cacheSourceData;

        clientPortsLocal[p] = (
            interface CENTRAL_CACHE_CLIENT_PORT;
                method Action readReq(CENTRAL_CACHE_ADDR addr,
                                      Bit#(TLog#(CENTRAL_CACHE_WORDS_PER_LINE)) wordIdx,
                                      CENTRAL_CACHE_REF_INFO refInfo);
                    debugLog.record($format("port %0d: readReq addr=0x%x, wordIdx=0x%x, refInfo=0x%x", p, addr, wordIdx, refInfo));

                    backing_source.readReq(addr, refInfo);
                    readQ[p].enq(tuple2(addr, refInfo));
                endmethod

                method ActionValue#(CENTRAL_CACHE_READ_RESP) readResp();
                    let d <- backing_source.readResp();

                    match {.addr, .ref_info} = readQ[p].first();
                    readQ[p].deq();
           
                    debugLog.record($format("port %0d: readResp addr=0x%x, refInfo=0x%x, val=0x%x", p, addr, ref_info, d));

                    Vector#(CENTRAL_CACHE_WORDS_PER_LINE, CENTRAL_CACHE_WORD) v = unpack(d);
                    CENTRAL_CACHE_READ_RESP r;
                    r.addr = addr;
                    r.refInfo = ref_info;
                    for (Integer w = 0; w < valueOf(CENTRAL_CACHE_WORDS_PER_LINE); w = w + 1)
                        r.words[w] = tagged Valid v[w];

                    return r;
                endmethod

                method Action write(CENTRAL_CACHE_ADDR addr,
                                    CENTRAL_CACHE_WORD val,
                                    Bit#(TLog#(CENTRAL_CACHE_WORDS_PER_LINE)) wordIdx,
                                    CENTRAL_CACHE_REF_INFO refInfo) if (readQ[p].notFull());

                    debugLog.record($format("port %0d: write addr=0x%x, refInfo=0x%x, wIdx=%d, val=0x%x", p, addr, refInfo, wordIdx, val));

                    //
                    // Backing storage write takes a line and a mask to indicate
                    // which words are valid in the line.  Build the line and mask.
                    //
                    Vector#(CENTRAL_CACHE_WORDS_PER_LINE, CENTRAL_CACHE_WORD) v = ?;
                    v[wordIdx] = val;

                    Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) mask = replicate(False);
                    mask[wordIdx] = True;
           
                    backing_source.write(addr, mask, pack(v), refInfo);
                endmethod
    
                //
                // Inval / flush don't need to do anything (no cache).
                //
                method Action invalReq(CENTRAL_CACHE_ADDR addr, Bool sendAck, CENTRAL_CACHE_REF_INFO refInfo);
                    debugLog.record($format("port %0d: inval addr=0x%x, refInfo=0x%x, ack=%d", p, addr, refInfo, sendAck));

                    if (sendAck)
                    begin
                        invalAckQ[p].enq(True);
                    end
                endmethod

                method Action flushReq(CENTRAL_CACHE_ADDR addr, Bool sendAck, CENTRAL_CACHE_REF_INFO refInfo);
                    debugLog.record($format("port %0d: flush addr=0x%x, refInfo=0x%x, ack=%d", p, addr, refInfo, sendAck));

                    if (sendAck)
                    begin
                        invalAckQ[p].enq(True);
                    end
                endmethod

                method Action invalOrFlushWait();
                    debugLog.record($format("port %0d: inval/flush done"));
                    invalAckQ[p].deq();
                endmethod
            endinterface
        );

        backingPortsLocal[p] = backingStore[p].backingPort;
    end
    
    interface clientPorts = clientPortsLocal;
    interface backingPorts = backingPortsLocal;
    
    method Action init(Bool enableCache, Bool cacheIsWriteBack);
        noAction;
    endmethod
endmodule
