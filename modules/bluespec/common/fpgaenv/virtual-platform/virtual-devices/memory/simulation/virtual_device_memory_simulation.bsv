// bluesim_memory

// Puts the memory in one big register file.

// To speed up simulation it truncates the address space to a parameter.

import FIFO::*;
import RegFile::*;

`include "low_level_platform_interface.bsh"

// ***** Modules *****


// mkMemoryVirtualDevice

// The module which instantiates a simulation-only memory.

module mkMemoryVirtualDevice#(LowLevelPlatformInterface pint) (MEMORY_VIRTUAL_DEVICE);

    // ***** Local State *****

    // The maximum simulation address.
    SIM_ADDRESS maxSimAddr = maxBound();

    // The maximum address we can address. References outside of this range are an error.
    MEM_ADDRESS maxAddr = zeroExtend(maxSimAddr);

    // The memory itself is a magic register file.
    // This should never be synthesized into the FPGA.

    RegFile#(SIM_ADDRESS, MEM_VALUE)  memory <- mkRegFileFullLoad(`MEMORY_SIM_STATE_FILE);

    // A queue for load results.
    
    FIFO#(MEM_VALUE) resultQ <- mkFIFO();


    // ***** Methods ******

    // makeMemRequest

    // Service a memory request using our magic register file.

    method Action makeMemRequest(MEM_REQUEST req);

        case (req) matches
          tagged MEM_LOAD .addr:
          begin

              // Check if the address is in range.
              if (addr>>2 > maxAddr)
                  $display("WARNING: BRAMMemory: Load address 0x%h out of bounds. Increase parameter MEM_SIM_ADDR_SIZE!", addr);

              // Convert to simulation address.
              SIM_ADDRESS sim_addr = truncate(addr>>2);

              // Look up the value.
              MEM_VALUE val = memory.sub(sim_addr);

              // Enqueue the result
              resultQ.enq(val);

          end
          tagged MEM_STORE .st_info:
          begin

              // Check if the address is within range.
              if ((st_info.addr>>2) > maxAddr)
                  $display("WARNING: Memory Virtual Device: Store address 0x%h out of bounds. Increase parameter MEM_SIM_ADDR_SIZE!", st_info.addr);

              // Calculate the simulation address.
              SIM_ADDRESS sim_addr = truncate(st_info.addr>>2);

              // Update the memory.
              memory.upd(sim_addr, st_info.val);

          end
        endcase

    endmethod
  

    // getMemResponse
    
    // Just return the first thing in the resultQ.

    method ActionValue#(MEM_VALUE) getMemResponse();
    
        resultQ.deq();
        return resultQ.first();

    endmethod


    // getInvalidateRequest
    
    // Never issue an invalidate request.
    // Note that method is never ready.

    method ActionValue#(MEM_ADDRESS) getInvalidateRequest() if (False);
    
        noAction;
        return 0;

    endmethod

endmodule
