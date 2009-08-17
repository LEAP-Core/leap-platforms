import Clocks::*;

`include "asim/provides/model.bsh"
`include "asim/provides/application_env.bsh"
`include "asim/provides/fpgaenv.bsh"
`include "asim/provides/virtual_platform.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/clocks_device.bsh"

module mkModel
    //interface:
        (TOP_LEVEL_WIRES);

    // The Model is instantiated inside a NULL (noClock) clock domain,
    // so first instantiate the LLPI and get a clock and reset from it.

    // name must be pi_llpint --- explain!!!
    VIRTUAL_PLATFORM vp <- mkVirtualPlatform();

    Clock clk = vp.llpint.physicalDrivers.clocksDriver.clock;
    Reset rst = vp.llpint.physicalDrivers.clocksDriver.reset;
    
    // instantiate application environment with new clock and reset
    let appEnv <- mkApplicationEnv(vp, clocked_by clk, reset_by rst);
    
    // return top level wires interface
    return vp.llpint.topLevelWires;

endmodule
