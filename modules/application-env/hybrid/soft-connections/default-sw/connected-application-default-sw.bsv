`include "asim/provides/soft_connections.bsh"
`include "asim/provides/hardware_system.bsh"

// mkConnectedApplication

// Just instantiate the hardware system.

module [CONNECTED_MODULE] mkConnectedApplication
    // interface:
        ();
    
    let sys <- mkSystem();

endmodule
