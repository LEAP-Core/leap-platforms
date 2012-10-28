//
// Copyright (C) 2012 Intel Corporation
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
// Simple switch provides one primary port and N secondary ports.  The primary
// port is routed to secondary ports.  All secondary ports route only to the
// primary port.
//

import FIFO::*;
import BlueNoC::*;
import Connectable::*;
import TieOff::*;

`include "awb/provides/librl_bsv_base.bsh"


interface SIMPLE_SWITCH#(numeric type n_PORTS, numeric type n_BPB);
   interface MsgPort#(n_BPB) primary;
   interface Vector#(n_PORTS, MsgPort#(n_BPB)) ports;
endinterface

//
// mkSimpleSwitch --
//   The current implementation assumes the primary port is destination 0
//   in the network and that the routed ports are destinations 1 .. n_PORTS.
//
module mkSimpleSwitch#(module#(FifoMsgSink#(n_BPB)) mkFIFOSink,
                       module#(FifoMsgSource#(n_BPB)) mkFIFOSource)
    // Interface:
    (SIMPLE_SWITCH#(n_PORTS, n_BPB))
    provisos (Alias#(t_PORT_IDX, UInt#(TLog#(n_PORTS))),
              Add#(_a, 8, TMul#(8, n_BPB)),
              Add#(_b, TLog#(n_PORTS), 8));

    Integer bytes_per_beat = valueOf(n_BPB);
    check_bytes_per_beat("mkSimpleSwitch", bytes_per_beat);

    // Message ports
    Vector#(n_PORTS, FifoMsgSink#(n_BPB)) sinkPorts <- replicateM(mkFIFOSink);
    Vector#(n_PORTS, FifoMsgSource#(n_BPB)) sourcePorts <- replicateM(mkFIFOSource);
    FifoMsgSink#(n_BPB) primSinkPort <- mkFIFOSink();
    FifoMsgSource#(n_BPB) primSourcePort <- mkFIFOSource();

    // Track message flows.  One tracker for the entire vector of ports is
    // sufficient because multi-beat messages hold the switch until complete.
    MsgRoute#(n_BPB) sinkRoute <- mkMsgRoute();
    MsgRoute#(n_BPB) primRoute <- mkMsgRoute();


    //
    // checkPrimarySink --
    //    Note the current beat arriving on the primary port and prepare to
    //    route it.
    //
    Wire#(MsgBeat#(n_BPB)) primSinkBeat <- mkWire();
    Reg#(t_PORT_IDX) curDst <- mkReg(0);

    rule checkPrimarySink (! primSinkPort.empty);
        let beat = primSinkPort.first();
        primRoute.beat(beat);

        primSinkBeat <= beat;
    endrule

    //
    // routeFromPrimary --
    //     Messages coming in on the primary port require actual routing.
    // 
    (* fire_when_enabled *)
    rule routeFromPrimary (True);
        let beat = primSinkBeat;
        primSinkPort.deq();
        primRoute.advance();

        // Remember route from multi-beat backets
        t_PORT_IDX dst = curDst;

        // Note new destinations as headers arrive
        if (primRoute.first_beat())
        begin
            // Any destination larger than the number of ports goes to the
            // last port.
            if (primRoute.dst() >= fromInteger(valueOf(n_PORTS)))
                dst = fromInteger(valueOf(TSub#(n_PORTS, 1)));
            else
                dst = truncate(unpack(pack(primRoute.dst - 1)));
        end

        // Forward the beat and remember the destination.
        sourcePorts[dst].enq(beat);
        curDst <= dst;
    endrule


    // Lock the primary sink port while a multi-beat message is in flight.
    Reg#(Maybe#(t_PORT_IDX)) curSink <- mkReg(tagged Invalid);
    LOCAL_ARBITER#(n_PORTS) sinkArb <- mkLocalArbiter();
    RWire#(t_PORT_IDX) updateSinkRoute <- mkRWire();

    rule routeToPrimary (True);
        Maybe#(t_PORT_IDX) sink_idx = curSink;

        // Note which sink ports have a beat available
        LOCAL_ARBITER_CLIENT_MASK#(n_PORTS) sink_req = newVector();
        for (Integer p = 0; p < valueOf(n_PORTS); p = p + 1)
        begin
            sink_req[p] = ! sinkPorts[p].empty;
        end

        // Time to pick a new sink port?
        if (! isValid(sink_idx))
        begin
            sink_idx <- sinkArb.arbitrate(sink_req, False);
        end

        if (sink_idx matches tagged Valid .idx &&&
            ! sinkPorts[idx].empty)
        begin
            // Forward a beat
            let beat = sinkPorts[idx].first();
            sinkPorts[idx].deq();
            
            primSourcePort.enq(beat);
            sinkRoute.beat(beat);

            updateSinkRoute.wset(idx);
        end
    endrule                               

    //
    // updateCurSink --
    //     Updating routing history When a message is routed from a
    //     secondary port to the primary one.
    //
    (* fire_when_enabled, no_implicit_conditions *)
    rule updateCurSink (updateSinkRoute.wget() matches tagged Valid .sink_idx);
        sinkRoute.advance();

        // Remember the port.  Messages must be delivered completely.
        curSink <= (sinkRoute.last_beat() ? tagged Invalid :
                                            tagged Valid sink_idx);
    endrule


    interface primary = as_port(primSourcePort.source, primSinkPort.sink);
    interface ports = zipWith(as_port,
                              map(get_source_ifc, sourcePorts),
                              map(get_sink_ifc, sinkPorts));
endmodule
