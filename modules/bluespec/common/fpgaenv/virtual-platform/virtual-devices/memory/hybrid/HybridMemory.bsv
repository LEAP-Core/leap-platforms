import low_level_platform_interface::*;

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
    noAction; //Fill this in
  endmethod
  
  method ActionValue#(Bit#(32)) getMemResponse();
    noAction;
    return 0; //Fill this in
  endmethod
  
  method ActionValue#(Bit#(32)) getInvalidateRequest() if (False); //Never invalidate. Remove the "if" to enable invalidates.
    noAction;
    return 0; //Fill this in
  endmethod

endmodule
