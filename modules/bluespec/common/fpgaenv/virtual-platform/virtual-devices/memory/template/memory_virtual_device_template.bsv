// virtual_device_memory_template

// A code template for the memory virtual device.


`include "low_level_platform_interface.bsh"


// ***** Modules *****


// mkMemoryVirtualDevice

// You write this.

module mkMemoryVirtualDevice#(LowLevelPlatformInterface pint) (MEMORY_VIRTUAL_DEVICE);

    // ***** Local State *****
    
    // Goes here.

    // ***** Methods ******

    // makeMemRequest

    // Service a memory request.

    method Action makeMemRequest(MEM_REQUEST req);

        noAction; // You write this.

    endmethod
  

    // getMemResponse
    
    // Give a response back to the user.

    method ActionValue#(MEM_VALUE) getMemResponse();
    
        noAction; // You write this.
        return 0; 

    endmethod


    // getInvalidateRequest
    
    // Issue an invalidate request to anybody caching the memory.

    method ActionValue#(MEM_ADDRESS) getInvalidateRequest();
    
        noAction; // You write this.
        return 0;

    endmethod

endmodule
