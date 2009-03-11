//
// Copyright (C) 2009 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

import Clocks::*;
import FIFO::*;
import FIFOLevel::*;


`include "asim/provides/libfpga_bsv_base.bsh"


//
// Data sizes are fixed by the VHDL DRAM controller and the hardware and are
// not flexible.
//

// The smallest addressable word:
typedef 64 FPGA_DRAM_WORD_SZ;
typedef Bit#(FPGA_DRAM_WORD_SZ) FPGA_DRAM_WORD;

// The DRAM controller uses both clock edges to pass data, which appears to
// be 2 words per cycle.  Addresses are little endian, so the low address
// goes in the low bits.  Most of the interfaces in this module pass:
typedef 128 FPGA_DRAM_DUALEDGE_DATA_SZ;
typedef Bit#(FPGA_DRAM_DUALEDGE_DATA_SZ) FPGA_DRAM_DUALEDGE_DATA;

// The DRAM controller reads and writes multiple dual-edge data values for
// a single request.  The number of dual-edge data values per request is:
typedef 2 FPGA_DRAM_BURST_LENGTH;

// Each byte in a write may be disabled for writes using a bit mask.
// !!! NOTE: to conform to the controller, a mask bit is 0 to request a write !!!
typedef Bit#(TDiv#(FPGA_DRAM_WORD_SZ, 8)) FPGA_DRAM_WORD_MASK;
typedef Bit#(TDiv#(FPGA_DRAM_DUALEDGE_DATA_SZ, 8)) FPGA_DRAM_DUALEDGE_DATA_MASK;

// Capacity of the memory (addressing FPGA_DRAM_WORDs):
typedef 26 FPGA_DRAM_ADDRESS_SZ;
typedef Bit#(FPGA_DRAM_ADDRESS_SZ) FPGA_DRAM_ADDRESS;


//
// DDR2_SDRAM_DRIVER
//
// The driver interface could be expressed as a simple BRAM style interface
// with write, readReq and readResp.  It is not.  Instead, the driver interface
// corresponds to the DDR2 controller interface, passing dual-edge data
// sized objects.  For some designs this will make the logic smaller without
// a performance penalty.
//
interface DDR2_SDRAM_DRIVER;
    // Read request/response pair.  NOTE: every read request generates
    // FPGA_DRAM_BURST_LENGTH responses.  If the address is not aligned to
    // the full response the DRAM controller rotates the response so the
    // requested address is returned in the low bits of the first response.
    method Action readReq(FPGA_DRAM_ADDRESS addr);
    method ActionValue#(FPGA_DRAM_DUALEDGE_DATA) readRsp();

    // Write requests and data are separate since the data will ultimately
    // be streamed to the DDR2 controller.
    method Action writeReq(FPGA_DRAM_ADDRESS addr);

    // Write data corresponding to a write request.  Call writeData
    // FPGA_DRAM_BURST_LENGTH times for every write request.  The order of
    // writeReq() and writeData() calls are not important.
    method Action writeData(FPGA_DRAM_DUALEDGE_DATA data, FPGA_DRAM_DUALEDGE_DATA_MASK mask);
endinterface


//        
// DDR2_SDRAM_WIRES --
//     These are wires which are simply passed up to the toplevel,
//     where the UCF file ties them to pins.
//
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
// DDR2_SDRAM_DEVICE --
//     By convention a device is both a driver and a wires interface.
//
interface DDR2_SDRAM_DEVICE;
    interface DDR2_SDRAM_DRIVER driver;
    interface DDR2_SDRAM_WIRES  wires;
endinterface


//
// A DRAM Request is either a read or write with an address
//
typedef union tagged
{
    FPGA_DRAM_ADDRESS DRAM_READ;
    FPGA_DRAM_ADDRESS DRAM_WRITE;
}
FPGA_DRAM_REQUEST
    deriving (Bits, Eq);


// State
typedef enum
{
    STATE_init,
    STATE_ready
}
FPGA_DRAM_STATE
    deriving (Bits, Eq);


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
    Reg#(FPGA_DRAM_STATE) state <- mkReg(STATE_init);

    //
    // Synchronizers from Controller to Model
    //

    // Read buffer (size this buffer to sustain as many DRAM bursts as needed)
    SyncFIFOIfc#(FPGA_DRAM_DUALEDGE_DATA) syncReadDataQ <-
        mkSyncFIFO(`DRAM_MAX_OUTSTANDING_READS * valueOf(FPGA_DRAM_BURST_LENGTH),
                   controllerClock, controllerReset, modelClock);

    //
    // Synchronizers from Model to Controller
    //

    // Request queue
    SyncFIFOIfc#(FPGA_DRAM_REQUEST) syncRequestQ <- mkSyncFIFO(2, modelClock, modelReset, controllerClock);

    // Write data queue. Holds one full write.
    SyncFIFOLevelIfc#(Tuple2#(FPGA_DRAM_DUALEDGE_DATA, FPGA_DRAM_DUALEDGE_DATA_MASK), FPGA_DRAM_BURST_LENGTH)
        syncWriteDataQ <- mkSyncFIFOLevel(modelClock, modelReset, controllerClock);
    
    Reg#(Bool) writePending <- mkReg(False, clocked_by controllerClock, reset_by controllerReset);
    
    // Keep track of the number of reads in flight
    COUNTER#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) nInflightReads <- mkLCounter(0);
    Reg#(Bit#(TLog#(TAdd#(FPGA_DRAM_BURST_LENGTH, 1)))) readBurstCnt <- mkReg(fromInteger(valueOf(TSub#(FPGA_DRAM_BURST_LENGTH, 1))));

    //
    // ===== Rules =====
    //
    
    // Rules for synchronizing from Controller to Model
    
    // Push incoming data into read buffer. This rule *MUST* fire if the explicit
    // conditions are true, else we will lose data.
    (* fire_when_enabled *)
    rule readDataToBuffer (dramController.init_done());
        syncReadDataQ.enq(dramController.dequeue_data());
    endrule

    
    // 
    // Rules for synchronizing from Model to Controller
    //
    
    // Peek at first request in request sync FIFO
    FPGA_DRAM_REQUEST req = syncRequestQ.first();
    
    rule processReadRequest (dramController.init_done() &&&
                             req matches tagged DRAM_READ .address);
        syncRequestQ.deq();
        dramController.enqueue_address(READ, zeroExtend(address));
    endrule

    
    //
    // Process write request - stage 1
    //   Enqueue the first half of the write data. We can write the command
    //   (a) in the next cycle, or (b) in this cycle if we're sure that we can
    //   guarantee that we'll be able to also write the remainder of the data
    //   in the next cycle. We use (b), and allow the rule to fire only if the
    //   full burst data is already available in the data FIFO.
    //
    rule processWriteRequest (dramController.init_done() &&&
                              ! writePending &&&
                              syncWriteDataQ.dIsGreaterThan(valueOf(TSub#(FPGA_DRAM_BURST_LENGTH, 1))) &&&
                              req matches tagged DRAM_WRITE .address);
        // address + command
        dramController.enqueue_address(WRITE, zeroExtend(address));
        
        // If we dequeue the Request queue now, we can allow a read to be
        // processed in parallel with the second stage of the write, which
        // *should* work fine. I can't see any race conditions, but BEWARE.
        syncRequestQ.deq();
        
        // Data + mask
        match { .data, .mask } = syncWriteDataQ.first();
        syncWriteDataQ.deq();        
        dramController.enqueue_data(data, mask);
                    
        writePending <= True;
    endrule
    
    //
    // Process write request - stage 2
    //   This rule *MUST* fire in the cycle immediately after the previous rule.
    (* fire_when_enabled *)
    rule continueWriteRequest (dramController.init_done() &&& writePending);
        // data + mask
        match { .data, .mask } = syncWriteDataQ.first();
        syncWriteDataQ.deq();        
        dramController.enqueue_data(data, mask);

        writePending <= False;
    endrule    

    
    // UGLY HACK
    // Initialization rules: write and read some junk into the DRAM so that
    // the Sync FIFOs don't get optimized away by the synthesis tools. If the
    // Sync FIFOs get optimized away, then the TIG constraints in the UCF
    // file become invalid and ngdbuild complains.
    
    Reg#(Bit#(4)) initStage <- mkReg(0);
    Reg#(Bit#(1)) datasink  <- mkReg(0);

    rule initDoWrite (state == STATE_init);

        case (initStage) matches
            
            0: syncRequestQ.enq(tagged DRAM_READ 0);
            
            1: begin
                   datasink <= syncReadDataQ.first()[0];
                   syncReadDataQ.deq();
               end
            
            2: begin
                   syncRequestQ.enq(tagged DRAM_WRITE 0);
                   syncWriteDataQ.enq(tuple2(zeroExtend(datasink), 0));

                   datasink <= syncReadDataQ.first()[0];
                   syncReadDataQ.deq();
               end
            
            3: begin
                   syncWriteDataQ.enq(tuple2(zeroExtend(datasink), 0));
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
    
        method Action readReq(FPGA_DRAM_ADDRESS addr) if ((state == STATE_ready) &&
                                                          (nInflightReads.value() < `DRAM_MAX_OUTSTANDING_READS));
            syncRequestQ.enq(tagged DRAM_READ addr);
            nInflightReads.up();
        endmethod

        method ActionValue#(FPGA_DRAM_DUALEDGE_DATA) readRsp() if (state == STATE_ready);
            let d = syncReadDataQ.first();
            syncReadDataQ.deq();

            if (readBurstCnt == 0)
            begin
                nInflightReads.down();
                readBurstCnt <= fromInteger(valueOf(FPGA_DRAM_BURST_LENGTH)) - 1;
            end
            else
            begin
                readBurstCnt <= readBurstCnt - 1;
            end

            return d;
        endmethod


        method Action writeReq(FPGA_DRAM_ADDRESS addr) if (state == STATE_ready);
            syncRequestQ.enq(tagged DRAM_WRITE addr);
        endmethod
        
        method Action writeData(FPGA_DRAM_DUALEDGE_DATA data, FPGA_DRAM_DUALEDGE_DATA_MASK mask) if (state == STATE_ready);
            syncWriteDataQ.enq(tuple2(data, mask));
        endmethod

    endinterface

endmodule
