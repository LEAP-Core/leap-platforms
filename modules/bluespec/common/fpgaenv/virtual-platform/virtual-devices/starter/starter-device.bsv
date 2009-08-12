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

`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/rrr.bsh"

`include "asim/rrr/client_stub_STARTER_DEVICE.bsh"
`include "asim/rrr/server_stub_STARTER_DEVICE.bsh"

// Starter
interface STARTER;

    // server methods
    method Action acceptRequest_Start();

    // client methods
    method Action makeRequest_End(Bit#(8) exit_code);
    
    //
    // FPGA Heartbeat --
    //   Message the number of FPGA cycles passed.
    //   Useful for detecting deadlocks.
    //
    method Action makeRequest_Heartbeat(Bit#(64) fpga_cycles);

endinterface

// mkStarter
module mkStarter#(LowLevelPlatformInterface llpi)
    // interface:
        (STARTER);

    // ----------- stubs -----------
    ClientStub_STARTER_DEVICE client_stub <- mkClientStub_STARTER_DEVICE(llpi.rrrClient);
    ServerStub_STARTER_DEVICE server_stub <- mkServerStub_STARTER_DEVICE(llpi.rrrServer);
    
    // ----------- server methods ------------

    // Run
    method Action acceptRequest_Start ();
        let r <- server_stub.acceptRequest_Start();
    endmethod

    // ------------ client methods ------------

    // signal end of simulation
    method Action makeRequest_End(Bit#(8) exit_code);
        client_stub.makeRequest_End(exit_code);
    endmethod

    // Heartbeat
    method Action makeRequest_Heartbeat(Bit#(64) fpga_cycles);
        client_stub.makeRequest_Heartbeat(fpga_cycles);
    endmethod

endmodule
