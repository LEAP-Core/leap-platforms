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

`include "asim/provides/rrr.bsh"
`include "asim/provides/channelio.bsh"
`include "asim/provides/local_mem.bsh"
`include "asim/provides/remote_memory.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/physical_platform_debugger.bsh"
`include "asim/provides/clocks_device.bsh"

// LowLevelPlatformInterface

// A convenient bundle of all ways to interact with the outside world.

interface LowLevelPlatformInterface;

    interface RRR_CLIENT            rrrClient;
    interface RRR_SERVER            rrrServer;
    interface CHANNEL_IO            channelIO;
    interface LOCAL_MEM             localMem;
    interface REMOTE_MEMORY         remoteMemory;
    interface PHYSICAL_DRIVERS      physicalDrivers;
    interface TOP_LEVEL_WIRES       topLevelWires;

endinterface

// mkLowLevelPlatformInterface

// Instantiate the subcomponents in one module.

module mkLowLevelPlatformInterface
    //interface:
    (LowLevelPlatformInterface);

    // instantiate physical platform
    
    PHYSICAL_PLATFORM phys_plat <- mkPhysicalPlatform();
    
    // LLPI is instantiated in a NULL clock domain, so first get some clocks
    // from the physical platform, which we'll pass down into the debugger
    // and virtual platform
    
    Clock clk = phys_plat.physicalDrivers.clocksDriver.clock;
    Reset rst = phys_plat.physicalDrivers.clocksDriver.reset;
    
    // instantiate physical platform debugger and obtain gated drivers from it
    PHYSICAL_DRIVERS  drivers   <- mkPhysicalPlatformDebugger(phys_plat.physicalDrivers, clocked_by clk, reset_by rst);
    
    // interfaces to the physical platform
    LOCAL_MEM     locMem <- mkLocalMem(drivers, clocked_by clk, reset_by rst);
    REMOTE_MEMORY remMem <- mkRemoteMemory(drivers, clocked_by clk, reset_by rst);
    CHANNEL_IO    cio    <- mkChannelIO(drivers, clocked_by clk, reset_by rst);

    // RRR
    RRR_CLIENT rrrc <- mkRRRClient(cio, clocked_by clk, reset_by rst);
    RRR_SERVER rrrs <- mkRRRServer(cio, clocked_by clk, reset_by rst);

    // plumb interfaces

    interface rrrClient        = rrrc;
    interface rrrServer        = rrrs;
    interface channelIO        = cio;
    interface localMem         = locMem;
    interface remoteMemory     = remMem;
    interface physicalDrivers  = drivers;
    interface topLevelWires    = phys_plat.topLevelWires;

endmodule
