`include "asim/provides/virtual_platform.bsh"
`include "asim/provides/hybrid_application.bsh"

module mkApplicationEnv
    // interface:
        (TOP_LEVEL_WIRES);
        
    let app <- mkApplication();
    
    return app;

endmodule
