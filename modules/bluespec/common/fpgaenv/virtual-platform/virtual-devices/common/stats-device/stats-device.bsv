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

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/rrr.bsh"

`include "asim/rrr/client_stub_STATS.bsh"
`include "asim/rrr/server_stub_STATS.bsh"
`include "asim/dict/STATS.bsh"

typedef Bit#(`STATS_SIZE) STAT_VALUE;
typedef 8 STAT_VECTOR_INDEX_SZ;
typedef Bit#(STAT_VECTOR_INDEX_SZ) STAT_VECTOR_INDEX;


// STATS: Send a dictionary-defined stat value back to hardware.

interface STATS;
    method ActionValue#(STATS_DEV_CMD) getCmd();
    method STATS_DEV_CMD peekCmd();
    method Action finishCmd(STATS_DEV_CMD cmd);

    method Action setVectorLength(STATS_DICT_TYPE stat, STAT_VECTOR_INDEX len, Bool buildVector);
    method Action reportStat(STATS_DICT_TYPE stat, STAT_VECTOR_INDEX pos, STAT_VALUE value);
endinterface


//
// Commands
//
typedef enum
{
    STATS_CMD_GETLENGTHS,
    STATS_CMD_DUMP,
    STATS_CMD_RESET,
    STATS_CMD_TOGGLE
}
STATS_DEV_CMD
    deriving (Eq, Bits);


//
// mkStatsDevice --
//
//     Wraps all communication to the software.
//
module mkStatsDevice#(LowLevelPlatformInterface llpi)
    //interface:
    (STATS);

    // ****** State Elements ******

    // Communication to/from software
    ClientStub_STATS clientStub <- mkClientStub_STATS(llpi.rrrClient);
    ServerStub_STATS serverStub <- mkServerStub_STATS(llpi.rrrServer);

    // Track commands internally
    FIFO#(STATS_DEV_CMD) cmdQ <- mkFIFO();


    //
    // Rules receiving incoming commands
    //
    rule beginVectorLengths (True);
        let dummy <- serverStub.acceptRequest_GetVectorLengths();
        cmdQ.enq(STATS_CMD_GETLENGTHS);
    endrule

    rule beginDump (True);
        let dummy <- serverStub.acceptRequest_DumpStats();
        cmdQ.enq(STATS_CMD_DUMP);
    endrule

    rule beginReset (True);
        let dummy <- serverStub.acceptRequest_Reset();
        cmdQ.enq(STATS_CMD_RESET);
    endrule

    rule beginToggle (True);
        let dummy <- serverStub.acceptRequest_Toggle();
        cmdQ.enq(STATS_CMD_TOGGLE);
    endrule


    //
    // Methods
    //

    //
    // getCmd --
    //     Retrieve the next command.
    //
    method ActionValue#(STATS_DEV_CMD) getCmd();
        let c = cmdQ.first();
        cmdQ.deq();
    
        return c;
    endmethod
    
    method STATS_DEV_CMD peekCmd();
        return cmdQ.first();
    endmethod


    //
    // finishCmd --
    //     Report that a command is complete.
    //
    method Action finishCmd(STATS_DEV_CMD cmd);
        case (cmd)
            STATS_CMD_GETLENGTHS:
                serverStub.sendResponse_GetVectorLengths(0);

            STATS_CMD_DUMP:
                serverStub.sendResponse_DumpStats(0);

            STATS_CMD_RESET:
                serverStub.sendResponse_Reset(0);

            STATS_CMD_TOGGLE:
                serverStub.sendResponse_Toggle(0);
        endcase
    endmethod


    //
    // Module-specific actions
    //

    method Action setVectorLength(STATS_DICT_TYPE id, STAT_VECTOR_INDEX len, Bool buildArray);
        clientStub.makeRequest_SetVectorLength(zeroExtend(id), len, zeroExtend(pack(buildArray)));
    endmethod

    method Action reportStat(STATS_DICT_TYPE id, STAT_VECTOR_INDEX idx, STAT_VALUE value);
        clientStub.makeRequest_ReportStat(zeroExtend(id), idx, zeroExtend(value));
    endmethod
endmodule
