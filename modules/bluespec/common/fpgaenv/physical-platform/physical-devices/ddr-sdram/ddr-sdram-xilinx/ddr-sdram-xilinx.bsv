//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

//
// A general wrapper for Xilinx DDR memories, providing clock transition
// and request timing managagement.  The wrapper instantiates device-specific
// drivers.
//

import Clocks::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import List::*;
import RWire::*;
import GetPut::*;
import DefaultValue::*;

`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/ddr_sdram_device.bsh"
`include "awb/provides/ddr_sdram_definitions.bsh"
`include "awb/provides/ddr_sdram_xilinx_driver.bsh"
`include "awb/provides/soft_connections.bsh"
`include "awb/provides/debug_scan_service.bsh"
`include "awb/provides/fpga_components.bsh"


//
// Data sizes are fixed by the VHDL DRAM controller and the hardware and are
// not flexible.
//

typedef `DRAM_NUM_BANKS FPGA_DDR_BANKS;
typedef `DRAM_MAX_OUTSTANDING_READS FPGA_DDR_MAX_OUTSTANDING_READS;

// The smallest addressable word:
typedef `DRAM_WORD_WIDTH FPGA_DDR_WORD_SZ;
typedef Bit#(FPGA_DDR_WORD_SZ) FPGA_DDR_WORD;

// The DRAM controller uses both clock edges to pass data, which appears to
// be 2 words per cycle.  Addresses are little endian, so the low address
// goes in the low bits.  Most of the interfaces in this module pass:
typedef `DRAM_BEAT_WIDTH FPGA_DDR_DUALEDGE_BEAT_SZ;
typedef Bit#(FPGA_DDR_DUALEDGE_BEAT_SZ) FPGA_DDR_DUALEDGE_BEAT;

typedef TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, FPGA_DDR_WORD_SZ) FPGA_DDR_WORDS_PER_BEAT;
typedef TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, 8) FPGA_DDR_BYTES_PER_BEAT;
typedef TDiv#(FPGA_DDR_WORD_SZ, 8) FPGA_DDR_BYTES_PER_WORD;

// The DRAM controller reads and writes multiple dual-edge data values for
// a single request.  The number of dual-edge data values per request is:
typedef `DRAM_MIN_BURST FPGA_DDR_BURST_LENGTH;

// Each byte in a write may be disabled for writes using a bit mask.
// !!! NOTE: to conform to the controller, a mask bit is 0 to request a write !!!
typedef Bit#(FPGA_DDR_BYTES_PER_WORD) FPGA_DDR_WORD_MASK;
typedef Bit#(FPGA_DDR_BYTES_PER_BEAT) FPGA_DDR_DUALEDGE_BEAT_MASK;

// Capacity of the memory (addressing FPGA_DDR_WORDs):
typedef `DRAM_ADDR_BITS FPGA_DDR_ADDRESS_SZ;
typedef Bit#(FPGA_DDR_ADDRESS_SZ) FPGA_DDR_ADDRESS;


//
// DDR_BANK_DRIVER
//
// The driver interface could be expressed as a simple BRAM style interface
// with write, readReq and readResp.  It is not.  Instead, the driver interface
// corresponds to the DDR controller interface, passing dual-edge data
// sized objects.  For some designs this will make the logic smaller without
// a performance penalty.
//
interface DDR_BANK_DRIVER;
    // Read request/response pair.  NOTE: every read request generates
    // FPGA_DDR_BURST_LENGTH responses.  If the address is not aligned to
    // the full response the DRAM controller rotates the response so the
    // requested address is returned in the low bits of the first response.
    method Action readReq(FPGA_DDR_ADDRESS addr);
    method ActionValue#(FPGA_DDR_DUALEDGE_BEAT) readRsp();

    // Write requests and data are separate since the data will ultimately
    // be streamed to the DDR controller.
    method Action writeReq(FPGA_DDR_ADDRESS addr);

    // Write data corresponding to a write request.  Call writeData
    // FPGA_DDR_BURST_LENGTH times for every write request.  The order of
    // writeReq() and writeData() calls are not important.
    method Action writeData(FPGA_DDR_DUALEDGE_BEAT data, FPGA_DDR_DUALEDGE_BEAT_MASK mask);

`ifndef DRAM_DEBUG_Z
    // Methods enabled only for debugging the controller:

    // Get status.  Should never block.
    method Bit#(64) statusCheck();
    // Set the maximum number of outstanding reads permitted.  Useful for
    // calibrating sync buffer sizes.
    method Action setMaxReads(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) maxReads);
`endif
endinterface


//
// DDR_BANK_DRIVER_SYNTH
//
// Same interface as above.  However, debug signals are explicitly exported as set of 
// boolean methods, which enables us to put Bluespec-style synthesis boundaries on 
// the bank code.  
//

interface DDR_BANK_DRIVER_SYNTH;
    // Read request/response pair.  NOTE: every read request generates
    // FPGA_DDR_BURST_LENGTH responses.  If the address is not aligned to
    // the full response the DRAM controller rotates the response so the
    // requested address is returned in the low bits of the first response.
    method Action readReq(FPGA_DDR_ADDRESS addr);
    method ActionValue#(FPGA_DDR_DUALEDGE_BEAT) readRsp();

    // Write requests and data are separate since the data will ultimately
    // be streamed to the DDR controller.
    method Action writeReq(FPGA_DDR_ADDRESS addr);

    // Write data corresponding to a write request.  Call writeData
    // FPGA_DDR_BURST_LENGTH times for every write request.  The order of
    // writeReq() and writeData() calls are not important.
    method Action writeData(FPGA_DDR_DUALEDGE_BEAT data, FPGA_DDR_DUALEDGE_BEAT_MASK mask);

    method Bool stateReady();
    method Bool init();
    method Bool mergeReqQ_notEmpty();
    method Bool mergeReqQ_notFull();
    method Bool syncRequestQ_notFull();
    method Bool syncWriteDataQ_notFull();
    method Bool syncReadDataQ_notEmpty();

`ifndef DEBUG_DDR3_Z

    method Bool debug_wrlvl_start();
    method Bool debug_wrlvl_done();
    method Bool debug_wrlvl_err();

    method Bool debug_rdlvl_start_0();
    method Bool debug_rdlvl_start_1();
    method Bool debug_rdlvl_done_0();
    method Bool debug_rdlvl_done_1();
    method Bool debug_rdlvl_err_0();
    method Bool debug_rdlvl_err_1();

`endif

`ifndef DRAM_DEBUG_Z
    // Methods enabled only for debugging the controller:

    // Get status.  Should never block.
    method Bit#(64) statusCheck();
    // Set the maximum number of outstanding reads permitted.  Useful for
    // calibrating sync buffer sizes.
    method Action setMaxReads(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) maxReads);
`endif
endinterface


interface DDR_WIRES;

    interface Put#(Bit#(1)) clk_p;
    interface Put#(Bit#(1)) clk_n;
    interface Put#(Bit#(1)) clk_single;

    interface Vector#(FPGA_DDR_BANKS, DDR_BANK_WIRES)  bank_wires;

endinterface

typedef Vector#(FPGA_DDR_BANKS, DDR_BANK_DRIVER) DDR_DRIVER;


//
// DDR_DEVICE --
//     By convention a device is both a driver and a wires interface.
//     Drivers are exposed as a vector of devices since they may be accessed
//     independently by clients.  The wires are exposed as a monolithic
//     type since they will typically be tied down to pins and not used
//     elsewhere in the design.
//
interface DDR_DEVICE;
    interface DDR_DRIVER driver;
    interface DDR_WIRES  wires;
endinterface


//
// DDR_BANK --
//     A bank is one driver and corresponding wires, but in this case 
//     debug signals have been wrapped.
//
interface DDR_BANK;
    interface DDR_BANK_DRIVER driver;
    interface DDR_BANK_WIRES  wires;
endinterface

//
// DDR_BANK_SYNTH --
//     A bank is one driver and corresponding wires.
//
interface DDR_BANK_SYNTH;
    interface DDR_BANK_DRIVER_SYNTH driver;
    interface DDR_BANK_WIRES        wires;
endinterface


//
// mkDDRDevice
//
module [CONNECTED_MODULE] mkDDRDevice#(DDRControllerConfigure ddrConfig)
    // interface:
    (DDR_DEVICE);

    // Figure out device clocking 
    let ddrClock = ddrConfig.internalClock;
    let ddrReset = ddrConfig.internalReset; 

    CLOCK_FROM_PUT incomingClockN <- mkClockFromPut;
    CLOCK_FROM_PUT incomingClockP <- mkClockFromPut;

    CLOCK_FROM_PUT incomingClockSingle <- mkClockFromPut;


    if(ddrConfig.clockArchitecture == CLOCK_EXTERNAL_DIFFERENTIAL)
    begin
        messageM("DDR: CLOCK_EXTERNAL_DIFFERENTIAL");
        Clock ddrClockIncoming <- mkDifferentialClock(incomingClockP.clock, incomingClockN.clock);        
        // Clean the incoming reset.
        ddrClock <- mkClockBuffer(clocked_by ddrClockIncoming);
        ddrReset <- mkAsyncReset(4, ddrReset, ddrClock);
    end

    if(ddrConfig.clockArchitecture == CLOCK_INTERNAL_UNBUFFERED)
    begin
        messageM("DDR: CLOCK_INTERNAL_UNBUFFERED");
        ddrClock <- mkClockBuffer(clocked_by ddrClock);
    end
    
    Vector#(FPGA_DDR_BANKS, DDR_BANK) b <-
        replicateM(mkDDRBank(ddrClock, ddrReset));

    function DDR_BANK_DRIVER getDriver(DDR_BANK bank) = bank.driver;
    function DDR_BANK_WIRES getWires(DDR_BANK bank) = bank.wires;

    interface driver = map(getDriver, b);

    interface DDR_WIRES wires;

        interface clk_p      = incomingClockP.clock_wire;
        interface clk_n      = incomingClockN.clock_wire;
        interface clk_single = incomingClockSingle.clock_wire;

        interface bank_wires = map(getWires, b);

    endinterface

endmodule
    


//
// A DRAM Request is either a read or write with an address
//
typedef union tagged
{
    FPGA_DDR_ADDRESS DRAM_READ;
    FPGA_DDR_ADDRESS DRAM_WRITE;
}
FPGA_DDR_REQUEST
    deriving (Bits, Eq);


// State
typedef enum
{
    STATE_init,
    STATE_ready
}
FPGA_DDR_STATE
    deriving (Bits, Eq);


//
// Debug DDR interface, exported to upper levels. 
//
module [CONNECTED_MODULE] mkDDRBank#(Clock rawClock, Reset rawReset)
    // interface:
    (DDR_BANK);

    DDR_BANK_SYNTH ddrSynth <- mkDDRBankSynth(rawClock, rawReset);
  
    //
    // Debug scan state
    //
    DEBUG_SCAN_FIELD_LIST dbg_list = List::nil;

    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM ready", ddrSynth.driver.stateReady);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM initPhase", ddrSynth.driver.init);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM mergeReqQ not empty", ddrSynth.driver.mergeReqQ_notEmpty);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM mergeReqQ not full", ddrSynth.driver.mergeReqQ_notFull);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM syncRequestQ not full", ddrSynth.driver.syncRequestQ_notFull);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM syncWriteDataQ not full", ddrSynth.driver.syncWriteDataQ_notFull);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM syncReadDataQ not empty", ddrSynth.driver.syncReadDataQ_notEmpty);

`ifndef DEBUG_DDR3_Z
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM dbg_wrlvl_start",  ddrSynth.driver.debug_wrlvl_start);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM dbg_wrlvl_done",  ddrSynth.driver.debug_wrlvl_done);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM dbg_wrlvl_err",  ddrSynth.driver.debug_wrlvl_err);

    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM dbg_rdlvl_start[0]", ddrSynth.driver.debug_rdlvl_start_0);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM dbg_rdlvl_start[1]",  ddrSynth.driver.debug_rdlvl_start_1);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM dbg_rdlvl_done[0]",  ddrSynth.driver.debug_rdlvl_done_0);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM dbg_rdlvl_done[1]",  ddrSynth.driver.debug_rdlvl_done_1);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM dbg_rdlvl_err[0]",  ddrSynth.driver.debug_rdlvl_err_0);
    dbg_list <- addDebugScanField(dbg_list,"Xilinx DDR SDRAM dbg_rdlvl_err[1] ",  ddrSynth.driver.debug_rdlvl_err_1);
`endif


    let dbgNode <- mkDebugScanNode("Local Memory (ddr-sdram-xilinx.bsv)", dbg_list);

    interface DDR_BANK_DRIVER driver;
        method readReq = ddrSynth.driver.readReq;
        method readRsp = ddrSynth.driver.readRsp;
        method writeReq = ddrSynth.driver.writeReq;
        method writeData = ddrSynth.driver.writeData;

`ifndef DRAM_DEBUG_Z

        method statusCheck = ddrSynth.driver.statusCheck;
        method setMaxReads = ddrSynth.driver.setMaxReads;

`endif
    endinterface       
    
    interface wires = ddrSynth.wires;

endmodule

//
// Bluespec synthesizable ddr interface. 
//
(* synthesize *) 
module mkDDRBankSynth#(Clock rawClock, Reset rawReset)
    // interface:
    (DDR_BANK_SYNTH);
    
    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();

    Reset modelResetInRaw <- mkAsyncReset(4, modelReset, rawClock);
    Reset modelOrRawReset <- mkResetEither(modelResetInRaw, rawReset,
                                           clocked_by rawClock);

    //
    // Instantiate the Xilinx Memory Controller
    //
    XILINX_DRAM_CONTROLLER dramCtrl <-
        mkXilinxDRAMController(rawClock, modelOrRawReset);
    
    // Clock the glue logic with the Controller's clock
    Clock controllerClock = dramCtrl.controller_clock;
    Reset controllerReset = dramCtrl.controller_reset;

    // State
    Reg#(FPGA_DDR_STATE) state <- mkReg(STATE_init);

    CrossingReg#(Bool) dramReady <-
        mkNullCrossingReg(modelClock, False,
                          clocked_by controllerClock, reset_by controllerReset);
    Reg#(Bool) dramReady_Model <- mkReg(False);

    //
    // Synchronizers from Controller to Model
    //

    // Read buffer (size this buffer to sustain as many DRAM bursts as needed)
    SyncFIFOIfc#(FPGA_DDR_DUALEDGE_BEAT) syncReadDataQ <-
        mkSyncFIFO(`DRAM_MAX_OUTSTANDING_READS * valueOf(FPGA_DDR_BURST_LENGTH),
                   controllerClock, controllerReset, modelClock);

    //
    // Synchronizers from Model to Controller
    //

    // Request queue
    SyncFIFOIfc#(FPGA_DDR_REQUEST) syncRequestQ <- mkSyncFIFO(16, modelClock, modelReset, controllerClock);

    // Write data queue
    SyncFIFOIfc#(Tuple2#(FPGA_DDR_DUALEDGE_BEAT, FPGA_DDR_DUALEDGE_BEAT_MASK))
        syncWriteDataQ <- mkSyncFIFO(16, modelClock, modelReset, controllerClock);
    
    // Debug signals
`ifndef DEBUG_DDR3_Z
    ReadOnly#(Bool) dbg_wrlvl_start <- mkNullCrossingWire(modelClock, dramCtrl.dbg_wrlvl_start(), clocked_by controllerClock, reset_by controllerReset);
    ReadOnly#(Bool) dbg_wrlvl_done  <- mkNullCrossingWire(modelClock, dramCtrl.dbg_wrlvl_done(), clocked_by controllerClock, reset_by controllerReset);
    ReadOnly#(Bool) dbg_wrlvl_err   <- mkNullCrossingWire(modelClock, dramCtrl.dbg_wrlvl_err(), clocked_by controllerClock, reset_by controllerReset);

    ReadOnly#(Bit#(2)) dbg_rdlvl_start <- mkNullCrossingWire(modelClock, dramCtrl.dbg_rdlvl_start(), clocked_by controllerClock, reset_by controllerReset);
    ReadOnly#(Bit#(2)) dbg_rdlvl_done  <- mkNullCrossingWire(modelClock, dramCtrl.dbg_rdlvl_done(), clocked_by controllerClock, reset_by controllerReset);
    ReadOnly#(Bit#(2)) dbg_rdlvl_err   <- mkNullCrossingWire(modelClock, dramCtrl.dbg_rdlvl_err(), clocked_by controllerClock, reset_by controllerReset);
`endif

    ReadOnly#(Bool) resetAssertedCast <- isResetAsserted(clocked_by controllerClock, reset_by controllerReset);
    ReadOnly#(Bit#(1)) resetAsserted  <- mkNullCrossingWire(modelClock, pack(resetAssertedCast._read()), clocked_by controllerClock, reset_by controllerReset);

    // Keep track of the number of reads in flight
    COUNTER#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) nInflightReads <- mkLCounter(0);
    Reg#(Bit#(TLog#(TAdd#(FPGA_DDR_BURST_LENGTH, 1)))) readBurstCnt <- mkReg(fromInteger(valueOf(TSub#(FPGA_DDR_BURST_LENGTH, 1))));

    //
    // ===== Rules =====
    //
    
    // Rules for synchronizing from Controller to Model
    
    // Push incoming data into read buffer. This rule *MUST* fire if the explicit
    // conditions are true, else we will lose data.
    (* fire_when_enabled *)
    rule readDataToBuffer (dramReady);
        syncReadDataQ.enq(dramCtrl.dequeue_data());
    endrule

    
    // 
    // Rules for synchronizing from Model to Controller
    //
    
    rule processReadRequest (dramReady &&&
                             syncRequestQ.first() matches tagged DRAM_READ .address);
        syncRequestQ.deq();
        dramCtrl.enqueue_address(READ, zeroExtend(address));
    endrule

    
    //
    // Writes come in as two data messages and a control message.  They
    // must be forwarded with precise timing to the DRAM.  Timing of reading
    // directly from the sync FIFO seems to be unreliable.  The code here
    // avoids timing problems by copying an entire write request into
    // registers within the DRAM clock domain before forwarding a request.
    //

    Vector#(FPGA_DDR_BURST_LENGTH, Reg#(FPGA_DDR_DUALEDGE_BEAT)) writeValue <-
        replicateM(mkRegU(clocked_by controllerClock, reset_by controllerReset));

    Vector#(FPGA_DDR_BURST_LENGTH, Reg#(FPGA_DDR_DUALEDGE_BEAT_MASK)) writeValueMask <-
        replicateM(mkRegU(clocked_by controllerClock, reset_by controllerReset));

    Reg#(Bit#(TLog#(TAdd#(1, FPGA_DDR_BURST_LENGTH)))) writeBurstIdx <-
        mkReg(0, clocked_by controllerClock, reset_by controllerReset);

    Reg#(Bit#(TLog#(TAdd#(1, FPGA_DDR_BURST_LENGTH)))) writeEmitIdx <-
        mkReg(0, clocked_by controllerClock, reset_by controllerReset);

    //
    // copyWriteData --
    //     Copy incoming write data from the sync FIFO to local registers.
    //
    rule copyWriteData (writeBurstIdx != fromInteger(valueOf(FPGA_DDR_BURST_LENGTH)));
        match {.data, .mask} = syncWriteDataQ.first();
        syncWriteDataQ.deq();        

        writeValue[writeBurstIdx] <= data;
        writeValueMask[writeBurstIdx] <= mask;
        
        writeBurstIdx <= writeBurstIdx + 1;
    endrule

    //
    // processWriteRequest0 --
    //     Stage 0 of write request.  Send control message and first half of data
    //     to the memory controller.
    //
    rule processWriteRequest0 (dramReady &&&
                               (writeBurstIdx == fromInteger(valueOf(FPGA_DDR_BURST_LENGTH))) &&&
                               (writeEmitIdx == 0) &&&
                               syncRequestQ.first() matches tagged DRAM_WRITE .address);

        syncRequestQ.deq();

        // address + command
        dramCtrl.enqueue_address(WRITE, zeroExtend(address));
        
        // Data + mask
        dramCtrl.enqueue_data(writeValue[0], writeValueMask[0], False);
                    
        // Write the rest of the beats
        if (valueOf(FPGA_DDR_BURST_LENGTH) != 1)
        begin
            writeEmitIdx <= 1;
        end

        // Allow new incoming data.  It is safe to allow incoming data at the
        // same time as the current write is emitted since write beats must
        // go out in consecutive cycles.
        writeBurstIdx <= 0;
    endrule
    
    //
    // processWriteRequest 1--
    //   Stage two of write request.  Forward remainder of data to the memory.
    //   This rule *MUST* fire in the cycles immediately after the previous rule.
    //
    (* fire_when_enabled *)
    rule processWriteRequest1 (writeEmitIdx != 0);
        // data + mask
        dramCtrl.enqueue_data(writeValue[writeEmitIdx],
                              writeValueMask[writeEmitIdx],
                              True);
        
        if (writeEmitIdx == fromInteger(valueOf(TSub#(FPGA_DDR_BURST_LENGTH, 1))))
        begin
            // Done
            writeEmitIdx <= 0;
        end
        else
        begin
            writeEmitIdx <= writeEmitIdx + 1;
        end
    endrule    


    // ====================================================================
    //
    // Initialization
    //
    // ====================================================================

    (* fire_when_enabled, no_implicit_conditions *)
    rule dramReadyInit (True);
        dramReady <= dramCtrl.init_done();
    endrule

    (* fire_when_enabled, no_implicit_conditions *)
    rule dramReadyToModel (True);
        dramReady_Model <= dramReady.crossed();
    endrule

    // UGLY HACK, now disabled by parameter.
    // Initialization rules: write and read some junk into the DRAM so that
    // the Sync FIFOs don't get optimized away by the synthesis tools. If the
    // Sync FIFOs get optimized away, then the TIG constraints in the UCF
    // file become invalid and ngdbuild complains.

    Reg#(Bit#(1)) initPhase <- mkReg(0);
    if(`USE_INITIALIZATION_PATCH > 0)
    begin
        Reg#(Bit#(TLog#(TAdd#(FPGA_DDR_BURST_LENGTH, 1)))) initBurstIdx <- mkReg(0);

        rule initPhase0 ((state == STATE_init) && (initPhase == 0) && dramReady_Model);
            if (initBurstIdx == 0)
            begin
                // First: read from address 0
                syncRequestQ.enq(tagged DRAM_READ 0);
            end
            else
            begin
                // Copy read to a write back to the memory
                let data = syncReadDataQ.first();
                syncReadDataQ.deq();

                syncWriteDataQ.enq(tuple2(data, 0));

                // Request a write (once)
                if (initBurstIdx == 1)
                begin
                    syncRequestQ.enq(tagged DRAM_WRITE 0);
                end
            end

            if (initBurstIdx != fromInteger(valueOf(FPGA_DDR_BURST_LENGTH)))
            begin
                initBurstIdx <= initBurstIdx + 1;
            end
            else
            begin
                initBurstIdx <= 0;
                initPhase <= 1;
            end
        endrule

        //
        // initPhase1 --
        //     Write a constant pattern to initialize memory.
        //
        Reg#(FPGA_DDR_ADDRESS) initAddr <- mkReg(0);

        rule initPhase1 ((state == STATE_init) && (initPhase == 1));
            // Data to write
            Vector#(FPGA_DDR_BYTES_PER_BEAT, Bit#(8)) init_data = replicate('haa);

            if (initBurstIdx == 0)
            begin
                // First stage write.  Write the control message and the first
                // half of the data.
                syncRequestQ.enq(tagged DRAM_WRITE initAddr);
                syncWriteDataQ.enq(tuple2(pack(init_data), 0));
            end
            else
            begin
                // Write the rest of the data.
                syncWriteDataQ.enq(tuple2(pack(init_data), 0));
            end

            // Done with this burst?
            if (initBurstIdx == fromInteger(valueOf(TSub#(FPGA_DDR_BURST_LENGTH, 1))))
            begin
                initBurstIdx <= 0;

                // Point to next dual-edge data address
                let next_addr = initAddr +
                                fromInteger(valueOf(TMul#(FPGA_DDR_BURST_LENGTH,
                                                          FPGA_DDR_WORDS_PER_BEAT)));
                initAddr <= next_addr;

                if (next_addr == 0)
                begin
                    state <= STATE_ready;
                end
            end
            else
            begin
                initBurstIdx <= initBurstIdx + 1;
            end
        endrule
    end
    else
    begin
        rule initPhase0 ((state == STATE_init) && dramReady_Model);
            state <= STATE_ready;
             initPhase <= 1;
        endrule
    end        

    // ====================================================================
    //
    // Incoming read and write synchronization
    //
    // ====================================================================

    //
    // The sync fifos for the clock crossing are very temperamental.
    // These FIFOs both merge incoming read and write requests temporally
    // and isolate the synchronization from logic calling the read and
    // write methods in the interface.
    //

    MERGE_FIFOF#(2, FPGA_DDR_REQUEST) mergeReqQ <- mkMergeFIFOF();
    
    rule forwardIncomingReq (state == STATE_ready);
        let r = mergeReqQ.first();
        mergeReqQ.deq();

        syncRequestQ.enq(r);
    endrule

    Reg#(Bit#(64)) statusReg <- mkRegU;

`ifndef DRAM_DEBUG_Z
    (* fire_when_enabled, no_implicit_conditions *)
    rule assignStatus;
        // Attempting to read deqRdy, enqRdy, or cmdRdy appears to cause hangs or incorrect values in the memory.
        // This doesn't make much sense, given that they are output signals.  Something else may be wrong.  For
        // now we simply won't read them.
        statusReg <= zeroExtend({pack(syncWriteDataQ.notFull()),1'b0,1'b0,resetAsserted,1'b0,pack(syncReadDataQ.notEmpty()),1'b0,1'b0,pack(mergeReqQ.notEmpty()),
                                 3'b0, // Replaces "deqRdy,enqRdy,cmdRdy" that were causing hangs
                                 pack(dramReady_Model)});
    endrule
`endif


`ifndef DRAM_DEBUG_Z
    // Useful for calibrating the optimal size of DRAM_MAX_OUTSTANDING_READS
    Reg#(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1)))) calibrateMaxReads <-
        mkReg(`DRAM_MAX_OUTSTANDING_READS);
`endif


    interface DDR_BANK_DRIVER_SYNTH driver;

/*
RAM status:0
    [prim_device.ram1.enqueue_address_RDY()]: 0
    [prim_device.ram1.enqueue_data_RDY()]: 0
    [prim_device.ram1.dequeue_data_RDY()]: 0
    [mergeReqQ.notEmpty()]: 0
    [mergeReqQ.ports[0].notFull()]: 0
    [mergeReqQ.ports[1].notFull()]: 0
    [syncReadDataQ.notEmpty()]: 0
    [syncReadDataQ.notFull()]: 0
    [unused]: 0
    [unused]: 0
    [syncRequestQ.notEmpty()]: 0
    [syncRequestQ.notFull()]: 0
    [syncWriteDataQ.notEmpty()]: 0
    [syncWriteDataQ.notFull()]: 0
    [writePending]: 0
    [readPending]: 0
    [nInflightReads.value() == 0]: 0
    [readBurstCnt == 0]: 0
    [writeBurstIdx == 0]: 0
    [state]: 0 
*/

`ifndef DRAM_DEBUG_Z

        method Bit#(64) statusCheck();
            return statusReg;
        endmethod

        //
        // setMaxReads --
        //     Set a maximum number of outstanding reads that may be lower than
        //     the available buffer size.  Useful for building one time and
        //     finding the optimal buffer size.
        //
        method Action setMaxReads(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) maxReads);
            calibrateMaxReads <= maxReads;
        endmethod
`endif

        method Action readReq(FPGA_DDR_ADDRESS addr) if ((state == STATE_ready) &&
`ifndef DRAM_DEBUG_Z
                                                         (nInflightReads.value() < calibrateMaxReads) &&
`endif
                                                         (nInflightReads.value() < `DRAM_MAX_OUTSTANDING_READS));
            mergeReqQ.ports[0].enq(tagged DRAM_READ addr);
            nInflightReads.up();
        endmethod

        method ActionValue#(FPGA_DDR_DUALEDGE_BEAT) readRsp() if (state == STATE_ready);
            let d = syncReadDataQ.first();
            syncReadDataQ.deq();

            if (readBurstCnt == 0)
            begin
                nInflightReads.down();
                readBurstCnt <= fromInteger(valueOf(FPGA_DDR_BURST_LENGTH)) - 1;
            end
            else
            begin
                readBurstCnt <= readBurstCnt - 1;
            end

            return d;
        endmethod


        method Action writeReq(FPGA_DDR_ADDRESS addr) if (state == STATE_ready);
            mergeReqQ.ports[1].enq(tagged DRAM_WRITE addr);
        endmethod
        
        method Action writeData(FPGA_DDR_DUALEDGE_BEAT data, FPGA_DDR_DUALEDGE_BEAT_MASK mask) if (state == STATE_ready);
            syncWriteDataQ.enq(tuple2(data, mask));
        endmethod

        // Debug state for debug scan.

        method Bool stateReady = (state == STATE_ready);
        method Bool init = unpack(initPhase);
        method Bool mergeReqQ_notEmpty = mergeReqQ.notEmpty;
        method Bool mergeReqQ_notFull = mergeReqQ.ports[0].notFull;
        method Bool syncRequestQ_notFull = syncRequestQ.notFull;
        method Bool syncWriteDataQ_notFull = syncWriteDataQ.notFull;
        method Bool syncReadDataQ_notEmpty = syncReadDataQ.notEmpty;

`ifndef DEBUG_DDR3_Z

        method Bool debug_wrlvl_start = dbg_wrlvl_start;
        method Bool debug_wrlvl_done = dbg_wrlvl_done;
        method Bool debug_wrlvl_err = dbg_wrlvl_err;

        method Bool debug_rdlvl_start_0 = unpack(dbg_rdlvl_start[0]);
        method Bool debug_rdlvl_start_1 = unpack(dbg_rdlvl_start[1]);
        method Bool debug_rdlvl_done_0 = unpack(dbg_rdlvl_done[0]);
        method Bool debug_rdlvl_done_1 = unpack(dbg_rdlvl_done[1]);
        method Bool debug_rdlvl_err_0 = unpack(dbg_rdlvl_err[0]);
        method Bool debug_rdlvl_err_1 = unpack(dbg_rdlvl_err[1]);

`endif
        
    endinterface


    // The wires are not domain-crossed because no one should ever look at them.
    interface wires = dramCtrl.wires;

endmodule
