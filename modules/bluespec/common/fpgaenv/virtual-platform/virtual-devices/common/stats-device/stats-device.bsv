//
// Copyright (C) 2008 Intel Corporation
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

`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/rrr.bsh"

`include "asim/rrr/client_stub_STATS.bsh"
`include "asim/rrr/server_stub_STATS.bsh"
`include "asim/dict/STATS.bsh"

typedef Bit#(`STATS_SIZE) STAT_VALUE;


// STATS: Send a dictionary-defined stat value back to hardware.

// STATS

// After Dump command is asserted dumping() becomes true. All stats should be
// reported with reportStat() until finishDump() is called.

interface STATS;

  method Bool   dumping();
  method Action reportStat(STATS_DICT_TYPE stat, STAT_VALUE value);
  method Action finishDump();

endinterface


// mkStatsDevice

// Wraps all communication to the software.

module mkStatsDevice#(LowLevelPlatformInterface llpi)
    //interface:
                (STATS);

    // ****** State Elements ******

    // Communication to/from software
    ClientStub_STATS clientStub <- mkClientStub_STATS(llpi.rrrClient);
    ServerStub_STATS serverStub <- mkServerStub_STATS(llpi.rrrServer);

    // Track if we are dumping
    Reg#(Bool) dumpState  <- mkReg(False);


    // ****** Rules ******

    rule beginDump (!dumpState);
    
        let dummy <- serverStub.acceptRequest_DumpStats();
        dumpState <= True;
    
    endrule
    
    method Bool dumping();
        return dumpState;
    endmethod

    method Action reportStat(STATS_DICT_TYPE id, STAT_VALUE value);
    
        clientStub.makeRequest_Send(zeroExtend(id), value);

    endmethod
    
    method Action finishDump();
    
        serverStub.sendResponse_DumpStats(0);
        dumpState <= False;
    
    endmethod

endmodule
