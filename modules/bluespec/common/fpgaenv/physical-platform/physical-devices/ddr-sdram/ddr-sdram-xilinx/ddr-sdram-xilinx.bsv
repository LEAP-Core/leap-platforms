//
// Copyright (C) 2012 Intel Corporation
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

//
// A general wrapper for Xilinx DDR memories, providing clock transition
// and request timing managagement.  The wrapper instantiates device-specific
// drivers.
//

import Clocks::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import RWire::*;


`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/ddr_sdram_device.bsh"
`include "awb/provides/ddr_sdram_xilinx_driver.bsh"


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

// The DRAM controller reads and writes multiple dual-edge data values for
// a single request.  The number of dual-edge data values per request is:
typedef `DRAM_MIN_BURST FPGA_DDR_BURST_LENGTH;

// Each byte in a write may be disabled for writes using a bit mask.
// !!! NOTE: to conform to the controller, a mask bit is 0 to request a write !!!
typedef Bit#(TDiv#(FPGA_DDR_WORD_SZ, 8)) FPGA_DDR_WORD_MASK;
typedef Bit#(TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, 8)) FPGA_DDR_DUALEDGE_BEAT_MASK;

// Capacity of the memory (addressing FPGA_DDR_WORDs):
typedef `DRAM_ADDR_BITS FPGA_DDR_ADDRESS_SZ;
typedef Bit#(FPGA_DDR_ADDRESS_SZ) FPGA_DDR_ADDRESS;


//
// DDR_DRIVER
//
// The driver interface could be expressed as a simple BRAM style interface
// with write, readReq and readResp.  It is not.  Instead, the driver interface
// corresponds to the DDR controller interface, passing dual-edge data
// sized objects.  For some designs this will make the logic smaller without
// a performance penalty.
//
interface DDR_DRIVER;
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


typedef Vector#(FPGA_DDR_BANKS, DDR_BANK_WIRES) DDR_WIRES;


//
// DDR_DEVICE --
//     By convention a device is both a driver and a wires interface.
//     Drivers are exposed as a vector of devices since they may be accessed
//     independently by clients.  The wires are exposed as a monolithic
//     type since they will typically be tied down to pins and not used
//     elsewhere in the design.
//
interface DDR_DEVICE;
    interface Vector#(FPGA_DDR_BANKS, DDR_DRIVER) driver;
    interface DDR_WIRES wires;
endinterface


//
// DDR_BANK --
//     A bank is one driver and corresponding wires.
//
interface DDR_BANK;
    interface DDR_DRIVER driver;
    interface DDR_BANK_WIRES wires;
endinterface


//
// mkDDRDevice
//
module mkDDRDevice#(Clock rawClock, Reset rawReset)
    // interface:
    (DDR_DEVICE);

    Vector#(FPGA_DDR_BANKS, DDR_BANK) b <-
        replicateM(mkDDRBank(rawClock, rawReset));

    function DDR_DRIVER getDriver(DDR_BANK bank) = bank.driver;
    function DDR_BANK_WIRES getWires(DDR_BANK bank) = bank.wires;

    interface driver = map(getDriver, b);
    interface wires = map(getWires, b);
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
// mkDDRDevice
//
module mkDDRBank#(Clock rawClock, Reset rawReset)
    // interface:
    (DDR_BANK);
    
    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();
    
    //
    // Instantiate the Xilinx Memory Controller
    //
    XILINX_DRAM_CONTROLLER dramCtrl <- mkXilinxDRAMController(rawClock, rawReset);
    
    // Clock the glue logic with the Controller's clock
    Clock controllerClock = dramCtrl.controller_clock;
    Reset controllerReset = dramCtrl.controller_reset;

    // State
    Reg#(FPGA_DDR_STATE) state <- mkReg(STATE_init);

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

    // Model requests a reset
    SyncFIFOIfc#(Bool) syncResetQ <- mkSyncFIFO(2, modelClock, modelReset, controllerClock);

    // Request queue
    SyncFIFOIfc#(FPGA_DDR_REQUEST) syncRequestQ <- mkSyncFIFO(2, modelClock, modelReset, controllerClock);

    // Write data queue
    SyncFIFOIfc#(Tuple2#(FPGA_DDR_DUALEDGE_BEAT, FPGA_DDR_DUALEDGE_BEAT_MASK))
        syncWriteDataQ <- mkSyncFIFO(2, modelClock, modelReset, controllerClock);
    
    Reg#(Bool) writePending <- mkReg(False, clocked_by controllerClock, reset_by controllerReset);
    
    ReadOnly#(Bit#(1)) initDone  <- mkNullCrossingWire(modelClock, pack(dramCtrl.init_done()), clocked_by controllerClock, reset_by controllerReset);
`ifdef DEBUG_DDR3
    ReadOnly#(Bit#(1)) cmdRdy  <- mkNullCrossingWire(modelClock, pack(dramCtrl.cmd_rdy()), clocked_by controllerClock, reset_by controllerReset);
    ReadOnly#(Bit#(1)) enqRdy  <- mkNullCrossingWire(modelClock, pack(dramCtrl.enq_rdy()), clocked_by controllerClock, reset_by controllerReset); 
    ReadOnly#(Bit#(1)) deqRdy  <- mkNullCrossingWire(modelClock, pack(dramCtrl.deq_rdy()), clocked_by controllerClock, reset_by controllerReset);
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
    rule readDataToBuffer (dramCtrl.init_done());
        syncReadDataQ.enq(dramCtrl.dequeue_data());
    endrule

    
    // 
    // Rules for synchronizing from Model to Controller
    //
    
    rule processReadRequest (dramCtrl.init_done() &&&
                             ! syncResetQ.notEmpty() &&&
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

    Reg#(Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_BEAT)) writeValue <- mkRegU(clocked_by controllerClock, reset_by controllerReset);
    Reg#(Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_BEAT_MASK)) writeValueMask <- mkRegU(clocked_by controllerClock, reset_by controllerReset);
    Reg#(Bit#(TLog#(TAdd#(1, FPGA_DDR_BURST_LENGTH)))) writeBurstIdx <- mkReg(0, clocked_by controllerClock, reset_by controllerReset);

    //
    // copyWriteData --
    //     Copy incoming write data from the sync FIFO to local registers.
    //
    rule copyWriteData (writeBurstIdx != fromInteger(valueOf(FPGA_DDR_BURST_LENGTH)) &&
                        ! syncResetQ.notEmpty());
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
    rule processWriteRequest0 (dramCtrl.init_done() &&&
                               ! syncResetQ.notEmpty() &&&
                               ! writePending &&&
                               (writeBurstIdx == fromInteger(valueOf(FPGA_DDR_BURST_LENGTH))) &&&
                               syncRequestQ.first() matches tagged DRAM_WRITE .address);

        syncRequestQ.deq();

        // address + command
        dramCtrl.enqueue_address(WRITE, zeroExtend(address));
        
        // Data + mask
        dramCtrl.enqueue_data(writeValue[0], writeValueMask[0], False);
                    
        writeBurstIdx <= 0;
        writePending <= True;
    endrule
    
    //
    // processWriteRequest 1--
    //   Stage two of write request.  Forward remainder of data to the memory.
    //   This rule *MUST* fire in the cycle immediately after the previous rule.
    //
    (* fire_when_enabled *)
    rule processWriteRequest1 (dramCtrl.init_done() &&
                               writePending);
        // data + mask
        dramCtrl.enqueue_data(writeValue[1], writeValueMask[1], True);
        
        writePending <= False;
    endrule    


    //
    // processModelReset --
    //     Model reset needs to clear out partial writes.
    //
    rule processModelReset (dramCtrl.init_done());
        syncResetQ.deq();

        writeBurstIdx <= 0;

        if (syncRequestQ.notEmpty())
            syncRequestQ.deq();

        if (syncWriteDataQ.notEmpty())
            syncWriteDataQ.deq();
    endrule


    // ====================================================================
    //
    // Initialization
    //
    // ====================================================================

    Reg#(Bit#(2)) initPhase <- mkReg(0);

    Reg#(Bit#(10)) init0Loop <- mkReg(0);

    //
    // initPhase0 --
    //     A delay loop to make sure reset settles.  Also, the DDR low level
    //     driver is not reset by a soft reset.  There may be some reads left
    //     over from the last run.  Sync them.
    //
    rule initPhase0 ((state == STATE_init) && (initPhase == 0));
        if (syncReadDataQ.notEmpty())
        begin
            syncReadDataQ.deq();
        end

        // Reset partial store state in the DDR clock domain.  Send a few times
        // so the incoming request queue is guaranteed empty.
        if (init0Loop < 8)
            syncResetQ.enq(?);

        if (init0Loop == maxBound)
            initPhase <= 1;
        
        init0Loop <= init0Loop + 1;
    endrule


    Reg#(Bit#(2)) init1Loop <- mkReg(0);
    Reg#(Bit#(1)) datasink  <- mkReg(0);

    // UGLY HACK
    // Initialization rules: write and read some junk into the DRAM so that
    // the Sync FIFOs don't get optimized away by the synthesis tools. If the
    // Sync FIFOs get optimized away, then the TIG constraints in the UCF
    // file become invalid and ngdbuild complains.
    rule initPhase1 ((state == STATE_init) && (initPhase == 1));
        case (init1Loop) matches
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
                   initPhase <= 2;
               end
        endcase

        init1Loop <= init1Loop + 1;
    endrule

    //
    // initPhase2 --
    //     Write a constant pattern to initialize memory.
    //
    Reg#(FPGA_DDR_ADDRESS) initAddr <- mkReg(0);
    Reg#(Bit#(1)) initPart <- mkReg(0);
    
    rule initPhase2 ((state == STATE_init) && (initPhase == 2));
        // Data to write
        Vector#(TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, 8), Bit#(8)) init_data = replicate('haa);

        if (initPart == 0)
        begin
            // First stage write.  Write the control message and the first
            // half of the data.
            syncWriteDataQ.enq(tuple2(pack(init_data), 0));
        end
        else
        begin
            // Second stage write.  Write the rest of the data and check whether
            // initialization is done.
            syncRequestQ.enq(tagged DRAM_WRITE initAddr);
            syncWriteDataQ.enq(tuple2(pack(init_data), 0));

            // Point to next dual-edge data address
            let next_addr = initAddr + fromInteger(valueOf(TMul#(FPGA_DDR_BURST_LENGTH, TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, FPGA_DDR_WORD_SZ))));
            initAddr <= next_addr;

            if (next_addr == 0)
            begin
                state <= STATE_ready;
            end
        end

        initPart <= initPart + 1;
    endrule


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
                                 initDone});
    endrule
`endif


`ifndef DRAM_DEBUG_Z
    // Useful for calibrating the optimal size of DRAM_MAX_OUTSTANDING_READS
    Reg#(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1)))) calibrateMaxReads <-
        mkReg(`DRAM_MAX_OUTSTANDING_READS);
`endif

    interface DDR_DRIVER driver;
    
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

    endinterface


    // The wires are not domain-crossed because no one should ever look at them.
    interface wires = dramCtrl.wires;

endmodule
