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

`include "asim/dict/DEBUG_SCAN.bsh"

`include "asim/rrr/client_stub_DEBUG_SCAN.bsh"
`include "asim/rrr/server_stub_DEBUG_SCAN.bsh"

//
// Debug scan is a set of nodes that scan out debug state to the host when
// commanded.
//
// Scanning begins when the dump command is received.  The device should be
// signaled when the scan is complete via finishScan().
//

interface DEBUG_SCAN_DEVICE;
    method ActionValue#(DEBUG_SCAN_CMD) getCmd();
    method DEBUG_SCAN_CMD peekCmd();
    method Action finishCmd(DEBUG_SCAN_CMD cmd);

    method Action scanValue(DEBUG_SCAN_DICT_TYPE id, DEBUG_SCAN_VALUE value);
endinterface


//
// Commands
//
typedef enum
{
    DEBUG_SCAN_CMD_DOSCAN
}
DEBUG_SCAN_CMD
    deriving (Eq, Bits);


typedef 8 DEBUG_SCAN_VALUE_SZ;
typedef Bit#(DEBUG_SCAN_VALUE_SZ) DEBUG_SCAN_VALUE;


//
// mkDebugScan --
//
// Manage debug scan nodes.
//
module mkDebugScanDevice#(LowLevelPlatformInterface llpi)
    // interface:
    (DEBUG_SCAN_DEVICE);

    // ****** State Elements ******

    // Communication to/from our SW via RRR
    ClientStub_DEBUG_SCAN clientStub <- mkClientStub_DEBUG_SCAN(llpi.rrrClient);
    ServerStub_DEBUG_SCAN serverStub <- mkServerStub_DEBUG_SCAN(llpi.rrrServer);


    //
    // Methods
    //

    //
    // getCmd --
    //     Retrieve the next command.
    //
    method ActionValue#(DEBUG_SCAN_CMD) getCmd();
        // There is only one command...
        let dummy <- serverStub.acceptRequest_Scan();
        return DEBUG_SCAN_CMD_DOSCAN;
    endmethod

    method DEBUG_SCAN_CMD peekCmd();
        let dummy = serverStub.peekRequest_Scan();
        return DEBUG_SCAN_CMD_DOSCAN;
    endmethod


    //
    // finishCmd --
    //     Report that a command is complete.
    //
    method Action finishCmd(DEBUG_SCAN_CMD cmd);
        serverStub.sendResponse_Scan(0);
    endmethod


    //
    // Module-specific actions
    //

    method Action scanValue(DEBUG_SCAN_DICT_TYPE id, DEBUG_SCAN_VALUE value);
        clientStub.makeRequest_Send(zeroExtend(id), value);
    endmethod
endmodule
