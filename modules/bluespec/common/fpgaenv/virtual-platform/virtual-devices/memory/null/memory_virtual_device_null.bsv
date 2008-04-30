// virtual_device_memory_null

// A null memory device which does nothing.


`include "low_level_platform_interface.bsh"


// ***** Modules *****


// mkMemoryVirtualDevice

// You write this.

module mkMemoryVirtualDevice#(LowLevelPlatformInterface pint) (SCRATCHPAD_MEMORY_VIRTUAL_DEVICE);

    // ***** Local State *****
    
    // Goes here.

    // ***** Methods ******

    // makeMemRequest

    // Service a memory request.

    method Action makeMemRequest(SCRATCHPAD_MEM_REQUEST req);

        noAction;

    endmethod
  

    // getMemResponse
    
    // Give a response back to the user.

    method ActionValue#(SCRATCHPAD_MEM_VALUE) getMemResponse();
    
        noAction;
        return 0; 

    endmethod


    // getInvalidateRequest
    
    // Issue an invalidate request to anybody caching the memory.
    
    // Note: this method is disabled so it never invalidates.

    method ActionValue#(SCRATCHPAD_MEM_ADDRESS) getInvalidateRequest() if (False);
    
        noAction;
        return 0;

    endmethod

endmodule
