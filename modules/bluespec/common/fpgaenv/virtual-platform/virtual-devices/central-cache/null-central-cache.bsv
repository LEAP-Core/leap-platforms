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
`include "asim/provides/fpga_components.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/physical_platform.bsh"



typedef CENTRAL_CACHE_VIRTUAL_DEVICE CENTRAL_CACHE_IFC;

module mkCentralCache#(LowLevelPlatformInterface llpi)
    // interface:
    (CENTRAL_CACHE_IFC);
    
    DEBUG_FILE debugLog <- mkDebugFile("memory_central_cache.out");

    //
    // Internal communication
    //
    Vector#(CENTRAL_CACHE_N_CLIENTS, FIFOF#(Tuple3#(CENTRAL_CACHE_LINE_ADDR,
                                                    CENTRAL_CACHE_WORD_IDX,
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
                method Action newReq(CENTRAL_CACHE_REQ req);
                    case (req) matches
                        tagged CENTRAL_CACHE_READ .rd:
                        begin
                            debugLog.record($format("port %0d: readReq addr=0x%x, wordIdx=0x%x, refInfo=0x%x", p, rd.addr, rd.wordIdx, rd.refInfo));

                            backing_source.readReq(rd.addr, rd.refInfo);
                            readQ[p].enq(tuple3(rd.addr, rd.wordIdx, rd.refInfo));
                        end

                        tagged CENTRAL_CACHE_WRITE .wr:
                        begin
                            debugLog.record($format("port %0d: write addr=0x%x, refInfo=0x%x, wIdx=%d, val=0x%x", p, wr.addr, wr.refInfo, wr.wordIdx, wr.val));

                            //
                            // Backing storage write takes a line and a mask to indicate
                            // which words are valid in the line.  Build the line and mask.
                            //
                            Vector#(CENTRAL_CACHE_WORDS_PER_LINE, CENTRAL_CACHE_WORD) v = ?;
                            v[wr.wordIdx] = wr.val;

                            Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) mask = replicate(False);
                            mask[wr.wordIdx] = True;
           
                            backing_source.write(wr.addr, mask, pack(v), wr.refInfo);
                        end

                        tagged CENTRAL_CACHE_INVAL .inv:
                        begin
                            debugLog.record($format("port %0d: inval addr=0x%x, refInfo=0x%x, ack=%d", p, inv.addr, inv.refInfo, inv.sendAck));

                            if (inv.sendAck)
                            begin
                                invalAckQ[p].enq(True);
                            end
                        end

                        tagged CENTRAL_CACHE_FLUSH .fl:
                        begin
                            debugLog.record($format("port %0d: flush addr=0x%x, refInfo=0x%x, ack=%d", p, fl.addr, fl.refInfo, fl.sendAck));

                            if (fl.sendAck)
                            begin
                                invalAckQ[p].enq(True);
                            end
                        end
                    endcase
                endmethod


                method ActionValue#(CENTRAL_CACHE_READ_RESP) readResp();
                    let d <- backing_source.readResp();

                    match {.addr, .word_idx, .ref_info} = readQ[p].first();
                    readQ[p].deq();
           
                    debugLog.record($format("port %0d: readResp addr=0x%x, refInfo=0x%x, val=0x%x", p, addr, ref_info, d));

                    Vector#(CENTRAL_CACHE_WORDS_PER_LINE, CENTRAL_CACHE_WORD) v = unpack(d);
                    CENTRAL_CACHE_READ_RESP r;
                    r.val = v[word_idx];
                    r.addr = addr;
                    r.wordIdx = word_idx;
                    r.refInfo = ref_info;

                    return r;
                endmethod

    
                //
                // Inval / flush don't need to do anything (no cache).
                //
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
    
    method CENTRAL_CACHE_DEBUG_SCAN debugScanState();
        CENTRAL_CACHE_DEBUG_SCAN state = unpack(0);
        return state;
    endmethod

    method Action init(RL_SA_CACHE_MODE mode, Bool enableRecentLineCache);
        noAction;
    endmethod

    interface CENTRAL_CACHE_STATS stats = ?;
endmodule
