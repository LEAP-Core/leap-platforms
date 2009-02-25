import Vector::*;
import Clocks::*;
import FIFO::*;
import FIFOLevel::*;

`include "fpga_components.bsh"

// Assumption throughout this module: DRAM_BURST_DATA_WIDTH == 2 * DRAM_DUALEDGE_DATA_WIDTH
// (i.e., burst length is 4 DDR2 DRAM words)

// NOTE TO USER: No throttling has been implemented for Reads yet. Please do not push in
// more Read requests than the internal read buffer can handle (`MAX_OUTSTANDING_READS)
// before reading out the data from previously issued Reads.

`define MAX_OUTSTANDING_READS    2

//
// Types
//

typedef Bit#(`DRAM_ADDRESS_WIDTH) DRAM_ADDRESS;

typedef Bit#(`DRAM_DATA_WIDTH) DRAM_DATA;
typedef Bit#(`DRAM_MASK_WIDTH) DRAM_MASK;

typedef Bit#(`DRAM_DUALEDGE_DATA_WIDTH) DRAM_DUALEDGE_DATA;
typedef Bit#(`DRAM_DUALEDGE_MASK_WIDTH) DRAM_DUALEDGE_MASK;

typedef Bit#(`DRAM_BURST_DATA_WIDTH) DRAM_BURST_DATA;
typedef Bit#(`DRAM_BURST_MASK_WIDTH) DRAM_BURST_MASK;

// A DRAM Request is either a Read or Write with an Address
typedef union tagged
{
    DRAM_ADDRESS DRAM_READ;
    DRAM_ADDRESS DRAM_WRITE;
}
DRAM_REQUEST
    deriving (Bits, Eq);

// State
typedef enum
{
    STATE_init,
    STATE_ready
}
STATE
    deriving (Bits, Eq);

//
// DDR2_SDRAM_DRIVER
//

interface DDR2_SDRAM_DRIVER;

    method Action             makeRequest(DRAM_REQUEST request);

    // enqueue a chunk of write data + write mask
    method Action             enq(DRAM_DUALEDGE_DATA data, DRAM_DUALEDGE_MASK mask);
        
    // read/dequeue read data
    method DRAM_DUALEDGE_DATA first();
    method Action             deq();

endinterface

//        
// DDR2_SDRAM_WIRES
//

// These are wires which are simply passed up to the toplevel,
// where the UCF file ties them to pins.

interface DDR2_SDRAM_WIRES;
    
    //
    // wires from the mem controller to the DRAM device
    //
    
    (* always_ready *)
    method    Bit#(2)           ck_p;

    (* always_ready *)
    method    Bit#(2)           ck_n;
        
    (* always_ready *)
    method    Bit#(13)          a;
        
    (* always_ready *)
    method    Bit#(2)           ba;

    (* always_ready *)
    method    Bit#(1)           ras_n;

    (* always_ready *)
    method    Bit#(1)           cas_n;

    (* always_ready *)
    method    Bit#(1)           we_n;
        
    (* always_ready *)        
    method    Bit#(2)           cs_n;
        
    (* always_ready *)
    method    Bit#(2)           odt;

    (* always_ready *)
    method    Bit#(2)           cke;

    (* always_ready *)
    method    Bit#(8)           dm;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(64))  dq;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(8))   dqs;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(8))   dqs_n;

endinterface

//
// DDR2_SDRAM_DEVICE
//

// By convention a Device is a Driver and a Wires

interface DDR2_SDRAM_DEVICE;

    interface DDR2_SDRAM_DRIVER driver;
    interface DDR2_SDRAM_WIRES  wires;

endinterface

//
// mkDDR2SDRAMDevice
//

module mkDDR2SDRAMDevice#(Clock topLevelClock, Reset topLevelReset)
    // interface:
                 (DDR2_SDRAM_DEVICE);
    
    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();
    
    DDR2_PLL pll <- mkDDR2PLL(clocked_by topLevelClock, reset_by topLevelReset);
    
    // The PLL gets its Reset from the toplevel, so OR it with the Model Reset to get Soft Resets
    // Soft reset doesn't seem to play nice with the VHDL. For now, we'll use the raw PLL reset
    // for the controller, but we'll leave the softPLLReset signal available for now.
    Reset transReset   <- mkAsyncReset(0, modelReset, pll.clk_150);
    Reset softPLLReset <- mkResetEither(transReset, pll.rst, clocked_by pll.clk_150);

    //
    // Instantiate the Xilinx Memory Controller
    //
    XILINX_DRAM_CONTROLLER dramController <- mkXilinxDRAMController(pll.clk_150, pll.clk_200, pll.rst);

    // Clock the glue logic with the Controller's clock
    Clock controllerClock = dramController.clk_out;
    Reset controllerReset = dramController.rst_out;

    // State
    Reg#(STATE) state <- mkReg(STATE_init);

    //
    // Synchronizers from Controller to Model
    //

    // read buffer (size this buffer to sustain as many DRAM bursts as needed)
    SyncFIFOIfc#(DRAM_DUALEDGE_DATA) sync_read_data_q <- mkSyncFIFO(`MAX_OUTSTANDING_READS * `DRAM_BURST_LENGTH,
                                                                    controllerClock, controllerReset, modelClock);

    //
    // Synchronizers from Model to Controller
    //

    // request queue
    SyncFIFOIfc#(DRAM_REQUEST) sync_request_q <- mkSyncFIFO(2, modelClock, modelReset, controllerClock);

    // write data queue. Ideally its size should be min(2, `DRAM_BURST_LENGTH)
    // but I don't know how to do that in Bluespec
    SyncFIFOLevelIfc#(Tuple2#(DRAM_DUALEDGE_DATA, DRAM_DUALEDGE_MASK), `DRAM_BURST_LENGTH)
        sync_write_data_q <- mkSyncFIFOLevel(modelClock, modelReset, controllerClock);
    
    Reg#(Bool) writePending <- mkReg(False, clocked_by controllerClock, reset_by controllerReset);
    
    //
    // ===== Rules =====
    //
    
    // Rules for synchronizing from Controller to Model
    
    // Push incoming data into read buffer. This rule *MUST* fire if the explicit conditions
    // are true, else we will lose data
    rule read_data_to_buffer (dramController.init_done());
        
        sync_read_data_q.enq(dramController.dequeue_data());

    endrule
    
    // 
    // Rules for synchronizing from Model to Controller
    //
    
    // peek at first request in request sync FIFO
    DRAM_REQUEST req = sync_request_q.first();
    
    // process Read request
    rule process_read_request (dramController.init_done() &&&
                               req matches tagged DRAM_READ .address);
    
        sync_request_q.deq();
        dramController.enqueue_address(READ, zeroExtend(address));
    
    endrule
    
    // process Write request - stage 1
    // Enqueue the first half of the write data. We can write the command (a) in the next
    // cycle, or (b) in this cycle if we're sure that we can guarantee that we'll be able
    // to also write the remainder of the data in the next cycle. We use (b), and allow
    // the rule to fire only if the full burst data is already available in the data FIFO
    rule process_write_request (dramController.init_done()                               &&&
                                !writePending                                            &&&
                                sync_write_data_q.dIsGreaterThan(`DRAM_BURST_LENGTH - 1) &&&
                                req matches tagged DRAM_WRITE .address);
        
        // address + command
        dramController.enqueue_address(WRITE, zeroExtend(address));
        
        // if we dequeue the Request queue now, we can allow a Read to be processed in
        // parallel with the second stage of the Write, which *should* work fine. I can't
        // see any race conditions, but BEWARE
        sync_request_q.deq();
        
        // data + mask
        match { .data, .mask } = sync_write_data_q.first();
        sync_write_data_q.deq();        
        dramController.enqueue_data(data, mask);
                    
        writePending <= True;
    
    endrule
    
    // process Write request - stage 2
    // this rule *MUST* fire in the cycle immediately after the previous rule
    rule continue_write_request (dramController.init_done() &&& writePending);
        
        // data + mask
        match { .data, .mask } = sync_write_data_q.first();
        sync_write_data_q.deq();        
        dramController.enqueue_data(data, mask);

        writePending <= False;
        
    endrule    
    
    // UGLY HACK
    // initialization rules: write and read some junk into the DRAM so that
    // the Sync FIFOs don't get optimized away by the synthesis tools. If the
    // Sync FIFOs get optimized away, then the TIG constraints in the UCF
    // file become invalid and ngdbuild complains.
    
    Reg#(Bit#(4)) initStage <- mkReg(0);
    Reg#(Bit#(1)) datasink  <- mkReg(0);

    rule init_do_write (state == STATE_init);

        case (initStage) matches
            
            0: sync_request_q.enq(tagged DRAM_READ 0);
            
            1: begin
                   datasink <= sync_read_data_q.first()[0];
                   sync_read_data_q.deq();
               end
            
            2: begin
                   sync_request_q.enq(tagged DRAM_WRITE 0);
                   sync_write_data_q.enq(tuple2(zeroExtend(datasink), 0));

                   datasink <= sync_read_data_q.first()[0];
                   sync_read_data_q.deq();
               end
            
            3: begin
                   sync_write_data_q.enq(tuple2(zeroExtend(datasink), 0));
                   state <= STATE_ready;
               end

        endcase

        initStage <= initStage + 1;

    endrule

    // The wires are not domain-crossed because no one should ever look at them.

    interface DDR2_SDRAM_WIRES wires;
      
        method ck_p  = dramController.ck_p;
        method ck_n  = dramController.ck_n;
        method a     = dramController.a;
        method ba    = dramController.ba;
        method ras_n = dramController.ras_n;
        method cas_n = dramController.cas_n;
        method we_n  = dramController.we_n;        
        method cs_n  = dramController.cs_n;
        method odt   = dramController.odt;
        method cke   = dramController.cke;
        method dm    = dramController.dm;
            
        interface dq    = dramController.dq;
        interface dqs   = dramController.dqs;
        interface dqs_n = dramController.dqs_n;
      
    endinterface
    
    // Drivers visible to upper layers
    
    interface DDR2_SDRAM_DRIVER driver;
    
        method Action makeRequest(DRAM_REQUEST request) if (state == STATE_ready);
        
            sync_request_q.enq(request);
        
        endmethod
        
        method Action enq(DRAM_DUALEDGE_DATA data, DRAM_DUALEDGE_MASK mask) if (state == STATE_ready);
            
            sync_write_data_q.enq(tuple2(data, mask));
            
        endmethod
        
        method DRAM_DUALEDGE_DATA first() if (state == STATE_ready);
            
            return sync_read_data_q.first();

        endmethod
            
        method Action deq() if (state == STATE_ready);

            sync_read_data_q.deq();
            
        endmethod

    endinterface

endmodule
