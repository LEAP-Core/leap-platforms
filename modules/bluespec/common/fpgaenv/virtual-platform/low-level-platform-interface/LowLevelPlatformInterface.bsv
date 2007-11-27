import rrr::*;
import channelio::*;
import toplevel_wires::*;

interface LowLevelPlatformInterface;
    interface RRRClient             rrrClient;
    interface RRRServer             rrrServer;
    interface ChannelIO             channelIO;
    interface TopLevelWiresDriver   topLevelWires;
endinterface

module mkLowLevelPlatformInterface(LowLevelPlatformInterface);

    // instantiate submodules
    TopLevelWiresDriver     wires   <- mkTopLevelWiresDriver();
    ChannelIO               cio     <- mkChannelIO(wires);
    RRRClient               rrrc    <- mkRRRClient(cio);
    RRRServer               rrrs    <- mkRRRServer(cio);

    // plumb interfaces
    interface               rrrClient       = rrrc;
    interface               rrrServer       = rrrs;
    interface               channelIO       = cio;
    interface               topLevelWires   = wires;

endmodule
