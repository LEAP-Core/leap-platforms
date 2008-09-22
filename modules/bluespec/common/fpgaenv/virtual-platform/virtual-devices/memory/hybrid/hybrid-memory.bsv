// virtual_device_memory_template

// A code template for the memory virtual device.


`include "low_level_platform_interface.bsh"
`include "rrr.bsh"
`include "channelio.bsh"

`include "asim/rrr/service_ids.bsh"
`include "asim/rrr/client_stub_SCRATCHPAD_MEMORY.bsh"
`include "asim/rrr/server_stub_SCRATCHPAD_MEMORY.bsh"


// ***** Modules *****


// mkMemoryVirtualDevice

// You write this.

module mkMemoryVirtualDevice#(LowLevelPlatformInterface llpint)
    // interface:
        (SCRATCHPAD_MEMORY_VIRTUAL_DEVICE);

    // ***** Local State *****
    
    // Our state.
    Reg#(Bit#(8)) state   <- mkReg(0);
    
    // The stubs to the memory RRR service.
    ClientStub_SCRATCHPAD_MEMORY clientStub <- mkClientStub_SCRATCHPAD_MEMORY(llpint.rrrClient);
    ServerStub_SCRATCHPAD_MEMORY serverStub <- mkServerStub_SCRATCHPAD_MEMORY(llpint.rrrServer);

    // ***** Methods ******

    // makeMemRequest

    // Service a memory request by passing it on to the RRR service.

    method Action makeMemRequest(SCRATCHPAD_MEM_REQUEST req) if (state == 0);
      case (req) matches
        tagged SCRATCHPAD_MEM_LOAD .addr:
        begin

          // send request via RRR
          clientStub.makeRequest_Load(pack(addr));
          state <= 1;

        end
        tagged SCRATCHPAD_MEM_STORE .stinfo:
        begin

          // send request via RRR
          clientStub.makeRequest_Store(pack(stinfo.addr), pack(stinfo.val));
          state <= 0;

        end
      endcase

    endmethod
  

    // getMemResponse
    
    // Get a response from the stub and pass it back to the user.

    method ActionValue#(SCRATCHPAD_MEM_VALUE) getMemResponse() if (state == 1);

      UINT32 v <- clientStub.getResponse_Load();
      state <= 0;
      return unpack(v);

    endmethod


    // getInvalidateRequest
    
    // Get an invalidate request from the RRR service and pass it to anybody caching the memory.

    method ActionValue#(SCRATCHPAD_MEM_ADDRESS) getInvalidateRequest();

      UINT32 inval_addr <- serverStub.acceptRequest_Invalidate();
      return unpack(inval_addr);

    endmethod

endmodule
