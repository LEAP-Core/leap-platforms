import rrr::*;
import channelio::*;
import toplevel_wires::*;

interface LowLevelPlatformInterface;
    interface ChannelIO             channelIO;
    interface RPCClient             rpcClient;
    interface TopLevelWiresDriver   topLevelWires;
endinterface

module mkLowLevelPlatformInterface(LowLevelPlatformInterface);

    // instantiate submodules
    TopLevelWiresDriver     wires   <- mkTopLevelWiresDriver();
    ChannelIO               cio     <- mkChannelIO();
    RPCClient               rpcc    <- mkRPCClient(cio);

    // plumb interfaces
    interface               channelIO       = cio;
    interface               rpcClient       = rpcc;
    interface               topLevelWires   = wires;

endmodule
