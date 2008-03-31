// virtual_device_memory_template

// A code template for the memory virtual device.


`include "low_level_platform_interface.bsh"
`include "rrr.bsh"
`include "channelio.bsh"
`include "asim/rrr/rrr_service_ids.bsh"
`include "asim/rrr/rrr_service_stub_MEMORY.bsh"


// ***** Modules *****


// mkMemoryVirtualDevice

// You write this.

module mkMemoryVirtualDevice#(LowLevelPlatformInterface llpint)
    // interface:
        (MEMORY_VIRTUAL_DEVICE);

    // ***** Local State *****
    
    // Our state.
    Reg#(Bit#(8)) state   <- mkReg(0);
    
    // The stub to the memory RRR service.
    ServiceStub_MEMORY stub <- mkServiceStub_MEMORY(llpint.rrrServer);

    // ***** Methods ******

    // makeMemRequest

    // Service a memory request by passing it on to the RRR service.

    method Action makeMemRequest(MEM_REQUEST req) if (state == 0);
      case (req) matches
        tagged MEM_LOAD .addr:
        begin

          // send request via RRR
          RRR_Request request;
          request.serviceID       = `MEMORY_SERVICE_ID;  /* memory */
          request.param0          = 0;            /* load */
          request.param1          = addr;         /* address */
          request.param2          = 0;            /* don't care */
          request.param3          = 0;            /* don't care */
          request.needResponse    = True;         /* need response */

          llpint.rrrClient.makeRequest(request);

          state <= 1;

        end
        tagged MEM_STORE .stinfo:
        begin

          // send request via RRR
          RRR_Request request;
          request.serviceID       = `MEMORY_SERVICE_ID;  /* memory */
          request.param0          = 1;            /* store */
          request.param1          = stinfo.addr;  /* address */
          request.param2          = stinfo.val;   /* data */
          request.param3          = 0;            /* don't care */
          request.needResponse    = False;        /* no response */

          llpint.rrrClient.makeRequest(request);

          state <= 0;

        end
      endcase

    endmethod
  

    // getMemResponse
    
    // Get a response from the stub and pass it back to the user.

    method ActionValue#(MEM_VALUE) getMemResponse() if (state == 1);

      MEM_VALUE v <- llpint.rrrClient.getResponse();
      state <= 0;
      return v;

    endmethod


    // getInvalidateRequest
    
    // Get an invalidate request from the RRR service and pass it to anybody caching the memory.

    method ActionValue#(MEM_ADDRESS) getInvalidateRequest();

      MEM_ADDRESS inval_addr <- stub.acceptRequest_Invalidate();
      return inval_addr;

    endmethod

endmodule
