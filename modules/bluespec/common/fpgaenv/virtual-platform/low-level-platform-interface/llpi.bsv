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

`include "rrr.bsh"
`include "channelio.bsh"
`include "physical_platform.bsh"
`include "physical_platform_debugger.bsh"

// LowLevelPlatformInterface

// A convenient bundle of all ways to interact with the outside world.

interface LowLevelPlatformInterface;

    interface RRR_CLIENT            rrrClient;
    interface RRR_SERVER            rrrServer;
    interface CHANNEL_IO            channelIO;
    interface PHYSICAL_DRIVERS      physicalDrivers;
    interface TOP_LEVEL_WIRES       topLevelWires;

endinterface

// mkLowLevelPlatformInterface

// Instantiate the subcomponents in one module.

module mkLowLevelPlatformInterface#(Clock topLevelClock, Reset topLevelReset)
    //interface:
    (LowLevelPlatformInterface);

    // instantiate physical platform
    PHYSICAL_PLATFORM phys_plat <- mkPhysicalPlatform(topLevelClock, topLevelReset);
    
    // instantiate physical platform debugger and obtain gated drivers from it
    PHYSICAL_DRIVERS  drivers   <- mkPhysicalPlatformDebugger(phys_plat.physicalDrivers);
    
    // instantiate layers of virtual platform
    CHANNEL_IO        cio       <- mkChannelIO(drivers);
    RRR_CLIENT        rrrc      <- mkRRRClient(cio);
    RRR_SERVER        rrrs      <- mkRRRServer(cio);

    // plumb interfaces

    interface               rrrClient        = rrrc;
    interface               rrrServer        = rrrs;
    interface               channelIO        = cio;
    interface               physicalDrivers  = drivers;
    interface               topLevelWires    = phys_plat.topLevelWires;

endmodule
