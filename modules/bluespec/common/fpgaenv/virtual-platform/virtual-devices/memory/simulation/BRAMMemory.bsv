`include "fpga_components.bsh"
`include "low_level_platform_interface.bsh"

typedef Bit#(`MEMORY_ADDR_SIZE) MEM_Addr;
typedef Bit#(`MEMORY_VALUE_SIZE) MEM_Value;

//Simulation memory is a smaller size to speed up simulation.
typedef Bit#(`MEMORY_SIM_ADDR_SIZE) SIM_Addr;

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

module mkMemory#(LowLevelPlatformInterface pint) (Memory);

  SIM_Addr maxSimAddr = maxBound();
  MEM_Addr maxAddr = zeroExtend(maxSimAddr);

  BRAM#(SIM_Addr, MEM_Value)  memory <- mkBRAM_Full_Load(`MEMORY_SIM_STATE_FILE);

  method Action makeMemRequest(MEM_Request req);
    case (req) matches
      tagged MEM_Load .addr:
      begin

        MEM_Addr sa = addr>>2;

        if (sa > maxAddr)
          $display("WARNING: BRAMMemory: Load address 0x%h out of bounds. Increase parameter MEM_SIM_ADDR_SIZE!", addr);

        SIM_Addr simaddr = truncate(sa);
        memory.read_req(simaddr);

      end
      tagged MEM_Store .stinfo:
      begin

        MEM_Addr sa = stinfo.addr>>2;

        if (sa > maxAddr)
          $display("WARNING: BRAMMemory: Store address 0x%h out of bounds. Increase parameter MEM_SIM_ADDR_SIZE!", stinfo.addr);

        SIM_Addr simaddr = truncate(sa);
        memory.write(simaddr, stinfo.val);
      
      end
    endcase
    
  endmethod
  
  method ActionValue#(Bit#(32)) getMemResponse();
    MEM_Value v <- memory.read_resp();
    return v;
  endmethod
  
  method ActionValue#(Bit#(32)) getInvalidateRequest() if (False); //Never invalidate
    noAction;
    return 0;
  endmethod

endmodule
