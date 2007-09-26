import low_level_platform_interface::*;
import rrr::*;

typedef Bit#(`MEMORY_ADDR_SIZE) MEM_Addr;
typedef Bit#(`MEMORY_VALUE_SIZE) MEM_Value;

typedef union tagged 
{
  MEM_Addr MEM_Load;
  struct {MEM_Addr addr; MEM_Value val; } MEM_Store;
}
  MEM_Request
    deriving
            (Eq, Bits);

interface Memory;

  method Action makeMemRequest(MEM_Request req);
  method ActionValue#(MEM_Value) getMemResponse(); //Data is assumed to come back inorder
  method ActionValue#(MEM_Addr) getInvalidateRequest();

endinterface

module mkMemory#(LowLevelPlatformInterface llpint) (Memory);

  Reg#(Bit#(8)) state   <- mkReg(0);

  method Action makeMemRequest(MEM_Request req) if (state == 0);
    case (req) matches
      tagged MEM_Load .addr:
      begin

        // send request via RRR
        RRR_Request request;
        request.serviceID       = `SID_MEMORY;  /* memory */
        request.param0          = 0;            /* load */
        request.param1          = addr;         /* address */
        request.param2          = 0;            /* don't care */
        request.needResponse    = True;         /* need response */

        llpint.rrrClient.makeRequest(request);

        state <= 1;

      end
      tagged MEM_Store .stinfo:
      begin

        // send request via RRR
        RRR_Request request;
        request.serviceID       = `SID_MEMORY;  /* memory */
        request.param0          = 1;            /* store */
        request.param1          = stinfo.addr;  /* address */
        request.param2          = stinfo.val;   /* data */
        request.needResponse    = False;        /* no response */

        llpint.rrrClient.makeRequest(request);

        state <= 0;

      end
    endcase

  endmethod
  
  method ActionValue#(Bit#(32)) getMemResponse() if (state == 1);
    MEM_Value v <- llpint.rrrClient.getResponse();
    state <= 0;
    return v;
  endmethod
  
  method ActionValue#(Bit#(32)) getInvalidateRequest() if (False); //Never invalidate. Remove the "if" to enable invalidates.
    noAction;
    return 0; //Fill this in
  endmethod

endmodule
