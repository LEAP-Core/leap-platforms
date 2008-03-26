// virtual_device_memory_null

// A null memory device which does nothing.


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

        noAction;

    endmethod
  

    // getMemResponse
    
    // Give a response back to the user.

    method ActionValue#(MEM_VALUE) getMemResponse();
    
        noAction;
        return 0; 

    endmethod


    // getInvalidateRequest
    
    // Issue an invalidate request to anybody caching the memory.
    
    // Note: this method is disabled so it never invalidates.

    method ActionValue#(MEM_ADDRESS) getInvalidateRequest() if (False);
    
        noAction;
        return 0;

    endmethod

endmodule
