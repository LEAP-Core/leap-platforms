import low_level_platform_interface::*;
import rrr::*;

`define MEM_SERVICE_ID  1

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

  method Action makeMemRequest(MEM_Request req);
    case (req) matches
      tagged MEM_Load .addr:
      begin

        // send request via RRR
        // LOAD has commandID = 0, STORE has commandID = 1
        llpint.rrrClient.sendReq(`MEM_SERVICE_ID,   /* memory */
                                 0,                 /* load */
                                 addr,              /* address */
                                 0                  /* don't care */
                                 );
      end
      tagged MEM_Store .stinfo:
      begin

        // send request via RRR
        // LOAD has commandID = 0, STORE has commandID = 1
        llpint.rrrClient.sendVoidReq(`MEM_SERVICE_ID,   /* memory */
                                     1,                 /* store */
                                     stinfo.addr,       /* address */
                                     stinfo.val         /* data */
                                     );

      end
    endcase
    
  endmethod
  
  method ActionValue#(Bit#(32)) getMemResponse() if (llpint.rrrClient.isRespAvailable(`MEM_SERVICE_ID));
    MEM_Value v <- llpint.rrrClient.getResp();
    return v;
  endmethod
  
  method ActionValue#(Bit#(32)) getInvalidateRequest() if (False); //Never invalidate. Remove the "if" to enable invalidates.
    noAction;
    return 0; //Fill this in
  endmethod

endmodule
