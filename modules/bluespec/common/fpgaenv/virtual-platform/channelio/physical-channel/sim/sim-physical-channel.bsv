import FIFOF::*;
import Vector::*;

`include "unix_pipe_device.bsh"
`include "physical_platform.bsh"
`include "umf.bsh"

// physical channel interface
interface PhysicalChannel;
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
endinterface

// physical channel module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
                  (PhysicalChannel);
    
    // read
    method ActionValue#(UMF_CHUNK) read();
        UMF_CHUNK chunk <- drivers.unixPipeDriver.read();
        return chunk;
    endmethod

    // write
    method Action write(UMF_CHUNK chunk);
        drivers.unixPipeDriver.write(chunk);
    endmethod

endmodule
