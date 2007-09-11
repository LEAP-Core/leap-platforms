import low_level_platform_interface::*;

typedef Bit#(32) MEM_Addr;
typedef Bit#(32) MEM_Value;

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
  method ActionValue#(MEM_Value) getMemResponse();
  method ActionValue#(MEM_Addr) getInvalidateRequest();

endinterface

module mkMemory#(LowLevelPlatformInterface pint) (Memory);

  method Action makeMemRequest(MEM_Request req);
  endmethod
  
  method ActionValue#(MEM_Value) getMemResponse();
    return 0;
  endmethod
  
  method ActionValue#(MEM_Addr) getInvalidateRequest();
    return 0;
  endmethod

endmodule
