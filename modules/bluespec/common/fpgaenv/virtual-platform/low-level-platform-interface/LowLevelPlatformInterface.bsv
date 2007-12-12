`include "rrr.bsh"
`include "channelio.bsh"
`include "physical_platform.bsh"

// LowLevelPlatformInterface

// A convenient bundle of all ways to interact with the outside world.

interface LowLevelPlatformInterface;
    interface RRRClient             rrrClient;
    interface RRRServer             rrrServer;
    interface ChannelIO             channelIO;
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
    ChannelIO               cio         <- mkChannelIO(phys_plat.physicalDrivers);
    RRRClient               rrrc        <- mkRRRClient(cio);
    RRRServer               rrrs        <- mkRRRServer(cio);

    // plumb interfaces

    interface               rrrClient        = rrrc;
    interface               rrrServer        = rrrs;
    interface               channelIO        = cio;
    interface               physicalDrivers  = phys_plat.physicalDrivers;
    interface               topLevelWires    = phys_plat.topLevelWires;

endmodule
