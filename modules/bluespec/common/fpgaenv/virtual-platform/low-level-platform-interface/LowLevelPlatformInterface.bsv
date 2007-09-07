import rrr::*;
import channelio::*;
import toplevel_wires::*;

interface LowLevelPlatformInterface;
    interface ChannelIO             channelIO;
    interface RRRClient             rrrClient;
    interface TopLevelWiresDriver   topLevelWires;
endinterface

module mkLowLevelPlatformInterface(LowLevelPlatformInterface);

    // instantiate submodules
    TopLevelWiresDriver     wires   <- mkTopLevelWiresDriver();
    ChannelIO               cio     <- mkChannelIO();
    RRRClient               rrrc    <- mkRRRClient(cio);

    // plumb interfaces
    interface               channelIO       = cio;
    interface               rrrClient       = rrrc;
    interface               topLevelWires   = wires;

endmodule
