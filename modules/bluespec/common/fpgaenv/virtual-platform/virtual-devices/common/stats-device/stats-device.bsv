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
typedef Bit#(8) STAT_VECTOR_INDEX;


// STATS: Send a dictionary-defined stat value back to hardware.

// STATS

// After Dump command is asserted dumping() becomes true. All stats should be
// reported with reportStat() until finishDump() is called.

interface STATS;

    method Bool   gettingVectorLengths();
    method Action setVectorLength(STATS_DICT_TYPE stat, STAT_VECTOR_INDEX len);
    method Action finishVectorLengths();

    method Bool   dumping();
    method Action reportStat(STATS_DICT_TYPE stat, STAT_VECTOR_INDEX pos, STAT_VALUE value);
    method Action finishDump();

    method Bool   reseting();
    method Action finishReseting();

    method Bool   toggling();
    method Action finishToggling();

    method Action statOverflow(STATS_DICT_TYPE stat, STAT_VECTOR_INDEX pos);

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

    // Track commands internally
    Reg#(Bool) dumpState <- mkReg(False);
    Reg#(Bool) lengthState <- mkReg(False);
    Reg#(Bool) toggleState <- mkReg(False);
    Reg#(Bool) resetState <- mkReg(False);


    // ****** Rules ******

    rule beginVectorLengths (!lengthState);
    
        let dummy <- serverStub.acceptRequest_GetVectorLengths();
        lengthState <= True;
    
    endrule

    rule beginDump (!dumpState);
    
        let dummy <- serverStub.acceptRequest_DumpStats();
        dumpState <= True;
    
    endrule
    
    rule beginReset (!resetState);
    
        let dummy <- serverStub.acceptRequest_Reset();
        resetState <= True;
    
    endrule

    rule beginToggle (!toggleState);
    
        let dummy <- serverStub.acceptRequest_Toggle();
        toggleState <= True;
    
    endrule

    method Bool gettingVectorLengths();
        return lengthState;
    endmethod
    

    method Action setVectorLength(STATS_DICT_TYPE id, STAT_VECTOR_INDEX len);
    
        clientStub.makeRequest_SetVectorLength(zeroExtend(id), len);

    endmethod
    
    
    method Action finishVectorLengths();
    
        lengthState <= False;
    
    endmethod

    
    method Bool dumping();
        return dumpState;
    endmethod

    method Action reportStat(STATS_DICT_TYPE id, STAT_VECTOR_INDEX idx, STAT_VALUE value);
    
        clientStub.makeRequest_ReportStat(zeroExtend(id), idx, value);

    endmethod
    
    method Action finishDump();
    
        serverStub.sendResponse_DumpStats(0);
        dumpState <= False;
    
    endmethod
    
    method Bool reseting();
        return resetState;
    endmethod

    method Action finishReseting();
        serverStub.sendResponse_Reset(0);
        resetState <= False;
    endmethod

    method Bool toggling();
        return toggleState;
    endmethod

    method Action finishToggling();
        serverStub.sendResponse_Toggle(0);
        toggleState <= False;
    endmethod

    method Action statOverflow(STATS_DICT_TYPE id, STAT_VECTOR_INDEX index);
        clientStub.makeRequest_StatOverflow(zeroExtend(id), index);
    endmethod

endmodule
