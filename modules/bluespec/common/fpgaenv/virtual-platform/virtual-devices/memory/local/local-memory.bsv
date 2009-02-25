import Vector::*;

`include "low_level_platform_interface.bsh"
`include "physical_platform.bsh"
`include "ddr2_sdram_device.bsh"
`include "fpga_components.bsh"

// A very simple Scratchpad memory frontend to interface
// with the DDR2 device. We use a single line buffer the
// size of one DDR2 burst for Reads. Writes are unbuffered
// and write-through. All widths are hard-coded.

// All Read misses are blocking. Writes will not allow any
// further requests until the write request has been
// transferred completely to the DRAM controller (takes 2
// cycles).

// `SCRATCHPAD_MEM_VALUE == 32 bits
// `DRAM_BURST_DATA      == 256 bits

// 32-bit SCRATCHPAD address breakdown (only aligned accesses
// are supported, so last 2-bit byte offset is ignored):

// |<------------------------ 32 ------------------------>|
// ========================================================
// | 000 | DRAM word index | 64 -> 32 index | byte offset |
// ========================================================
// |<-3->|<------ 26 ----->|<----- 1 ------>|<---- 2 ---->|

//       /                 \
//      /                   \
//     /                     \
//    /                       \
//   /                         \
//  /                           \

// 26-bit DRAM word address breakdown:

// |<-------------- 26 ------------>|
// ==================================
// | burst index | DRAM word offset |
// ==================================
// <---- 24 ---->|<------- 2 ------>|


//
// Types
//

typedef Bit#(TSub#(`DRAM_ADDRESS_WIDTH, 2)) DRAM_BURST_ADDRESS;

typedef enum
{
    STATE_ready,
    STATE_missServicing_1,
    STATE_missServicing_2,
    STATE_dataReady,
    STATE_continueWrite
}
STATE
    deriving (Bits, Eq);

//
// Modules
//

// mkMemoryVirtualDevice

module mkMemoryVirtualDevice#(LowLevelPlatformInterface llpi)
    // interface:
        (SCRATCHPAD_MEMORY_VIRTUAL_DEVICE);

    //
    // Local State
    //
    
    // Line buffer arranged as an array of SCRATCHPAD_MEM_VALUEs
    Vector#(8, Reg#(SCRATCHPAD_MEM_VALUE)) burstBuffer = newVector();
    for (Integer i = 0; i < 8; i = i + 1)
    begin
        burstBuffer[i] <- mkReg(0);
    end
    Reg#(DRAM_BURST_ADDRESS) burstAddress <- mkReg(0);
    Reg#(Bool)               isValid      <- mkReg(False);

    // index of current read hit in buffer
    Reg#(Bit#(3)) hitIndex <- mkReg(0);

    // pending write info
    Reg#(DRAM_DUALEDGE_DATA) pendingWriteData <- mkReg(0);
    Reg#(DRAM_DUALEDGE_MASK) pendingWriteMask <- mkReg(0);

    // Our state.
    Reg#(STATE) state <- mkReg(STATE_ready);
    
    // Get a handle to the DDR2 DRAM Controller
    DDR2_SDRAM_DRIVER dramDriver = llpi.physicalDrivers.ddr2SDRAMDriver;
    
    //
    // Methods
    //

    // service read miss: stage 1   
    rule service_read_miss_1 (state == STATE_missServicing_1);

        DRAM_DUALEDGE_DATA chunk = dramDriver.first();
        dramDriver.deq();

        // stuff data into line buffer, address is already set up
        for (Integer i = 0; i < 4; i = i + 1)
        begin
                
            burstBuffer[i] <= chunk[((i+1)*32)-1 : i*32];
            
        end
                
        state <= STATE_missServicing_2;

    endrule
  
    // service read miss: stage 2
    rule service_read_miss_2 (state == STATE_missServicing_2);

        DRAM_DUALEDGE_DATA chunk = dramDriver.first();
        dramDriver.deq();

        // stuff data into line buffer, address is already set up
        for (Integer i = 0; i < 4; i = i + 1)
        begin
                
            burstBuffer[i+4] <= chunk[((i+1)*32)-1 : i*32];
            
        end

        state <= STATE_dataReady;

    endrule
    
    // continue write
    rule continue_write (state == STATE_continueWrite);
        
        dramDriver.enq(pendingWriteData, pendingWriteMask);
        state <= STATE_ready;
        
    endrule

    //
    // Methods
    //

    // makeMemRequest
    method Action makeMemRequest(SCRATCHPAD_MEM_REQUEST req) if (state == STATE_ready);
        
        case (req) matches
           
            // LOAD
            tagged SCRATCHPAD_MEM_LOAD .addr:
            begin
                    
                DRAM_BURST_ADDRESS baddr  = truncate(addr >> 5);
                DRAM_ADDRESS       waddr  = zeroExtend(baddr) << 2;
                Bit#(3)            offset = truncate(addr >> 2);
                
                // check for buffer hit
                if (isValid && baddr == burstAddress)
                begin

                    // HIT!
                    hitIndex <= offset;
                    state <= STATE_dataReady;
                        
                end
                else
                begin

                    // MISS!
                    dramDriver.makeRequest(tagged DRAM_READ waddr);
                    
                    // update the address, valid bit and hit index immediately
                    // so that we don't have to maintain an additional MSHR
                    burstAddress <= baddr;
                    isValid      <= True;
                    hitIndex     <= offset;

                    // wait for data to return
                    state <= STATE_missServicing_1;
                    
                end

            end
            
            // STORE
            tagged SCRATCHPAD_MEM_STORE .stinfo:
            begin

                DRAM_BURST_ADDRESS baddr  = truncate(stinfo.addr >> 5);
                DRAM_ADDRESS       waddr  = zeroExtend(baddr) << 2;
                Bit#(3)            offset = truncate(stinfo.addr >> 2);
                
                // check for buffer hit
                if (isValid && baddr == burstAddress)
                begin

                    // HIT! update buffer
                    burstBuffer[offset] <= stinfo.val;
                        
                end

                // enqueue the address and command in this cycle along
                // with the first chunk of data. The second chunk will
                // be sent in the next cycle (our controller is smart
                // enough to not process the request until both chunks
                // are in the data FIFO)
                
                DRAM_BURST_DATA fulldata = zeroExtend(stinfo.val);
                Bit#(8) dataoffset = zeroExtend(offset) << 5;
                fulldata = fulldata << dataoffset;
                
                DRAM_BURST_MASK fullmask = 'h0000000F;
                Bit#(5) maskoffset = zeroExtend(offset) << 2;
                fullmask = fullmask << maskoffset;
                fullmask = ~fullmask;
                
                DRAM_DUALEDGE_DATA dataLO = fulldata[`DRAM_DUALEDGE_DATA_WIDTH - 1 : 0];
                DRAM_DUALEDGE_DATA dataHI = fulldata[`DRAM_BURST_DATA_WIDTH - 1 : `DRAM_DUALEDGE_DATA_WIDTH];
                
                DRAM_DUALEDGE_MASK maskLO = fullmask[`DRAM_DUALEDGE_MASK_WIDTH - 1 : 0];
                DRAM_DUALEDGE_MASK maskHI = fullmask[`DRAM_BURST_MASK_WIDTH - 1 : `DRAM_DUALEDGE_MASK_WIDTH];
                
                dramDriver.makeRequest(tagged DRAM_WRITE waddr);
                dramDriver.enq(dataLO, maskLO);
                
                pendingWriteData <= dataHI;
                pendingWriteMask <= maskHI;
                
                state <= STATE_continueWrite;
                    
            end

        endcase
        
    endmethod

    // getMemResponse
    method ActionValue#(SCRATCHPAD_MEM_VALUE) getMemResponse() if (state == STATE_dataReady);
    
        SCRATCHPAD_MEM_VALUE resp = burstBuffer[hitIndex];
        state <= STATE_ready;
        return resp;

    endmethod

    // getInvalidateRequest
    method ActionValue#(SCRATCHPAD_MEM_ADDRESS) getInvalidateRequest() if (False);

        noAction;
        return unpack('0);

    endmethod

endmodule
