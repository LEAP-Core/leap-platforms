import Clocks::*;

`include "asim/provides/model.bsh"
`include "asim/provides/application_env.bsh"

// TODO: better story on command line args
`include "asim/provides/command_switches.bsh"

module mkModel
    //interface:
        (TOP_LEVEL_WIRES);

    // instantiate application environment
    TOP_LEVEL_WIRES appEnv <- mkApplicationEnv();
    
    // return the app's wires as our own.
    return appEnv;
    
endmodule
