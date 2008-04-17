`include "rrr.bsh"
`include "channelio.bsh"
`include "physical_platform.bsh"

// LowLevelPlatformInterface

// A convenient bundle of all ways to interact with the outside world.

interface LowLevelPlatformInterface;
    interface RRRClient             oldrrrClient;
    interface RRR_CLIENT            rrrClient;
    interface RRR_SERVER            rrrServer;
    interface CHANNEL_IO            channelIO;
    interface PHYSICAL_DRIVERS      physicalDrivers;
    interface TOP_LEVEL_WIRES       topLevelWires;
endinterface

// mkLowLevelPlatformInterface

// Instantiate the subcomponents in one module.

module mkLowLevelPlatformInterface
    //interface:
    (LowLevelPlatformInterface);

    // instantiate submodules
    
    PHYSICAL_PLATFORM       phys_plat   <- mkPhysicalPlatform();
    CHANNEL_IO              cio         <- mkChannelIO(phys_plat.physicalDrivers);
    RRRClient               orrrc       <- mkOldRRRClient(cio);
    RRR_CLIENT              rrrc        <- mkRRRClient(cio);
    RRR_SERVER              rrrs        <- mkRRRServer(cio);

    // plumb interfaces

    interface               oldrrrClient     = orrrc;
    interface               rrrClient        = rrrc;
    interface               rrrServer        = rrrs;
    interface               channelIO        = cio;
    interface               physicalDrivers  = phys_plat.physicalDrivers;
    interface               topLevelWires    = phys_plat.topLevelWires;

endmodule
