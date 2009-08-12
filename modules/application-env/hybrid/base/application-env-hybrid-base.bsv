`include "asim/provides/virtual_platform.bsh"
`include "asim/provides/hybrid_application.bsh"

module mkApplicationEnv#(VIRTUAL_PLATFORM vp)
    // interface:
        ();
        
    let app <- mkApplication(vp);

endmodule
