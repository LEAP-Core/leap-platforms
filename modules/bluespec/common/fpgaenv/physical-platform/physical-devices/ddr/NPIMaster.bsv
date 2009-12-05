// The MIT License

// Copyright (c) 2009 Massachusetts Institute of Technology

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Author: Sam Gross sgross@mit.edu

import NPICommon::*;
import GetPut::*;
import FIFO::*;
import Clocks::*;
import FIFOLevel::*;
import Vector::*;

interface NPIMasterWires;
  (* always_ready, always_enabled, prefix="", result="initDone" *)
  method Action initDone(Bit#(1) initDoneIn);

  // request interface
  (* always_ready, always_enabled, prefix="", result="addrReq" *)
  method Bit#(1) addrReq();

  (* always_ready, always_enabled, prefix="", result="addrAck" *)
  method Action addrAck(Bit#(1) addrAckIn);

  (* always_ready, always_enabled, prefix="", result="addr" *)
  method Bit#(32) addr();

  (* always_ready, always_enabled, prefix="", result="rnw" *)
  method Bit#(1) rnw();

  (* always_ready, always_enabled, prefix="", result="size" *)
  method Bit#(4) size();

  (* always_ready, always_enabled, prefix="", result="rdModWr" *)
  method Bit#(1) rdModWr();

  // read FIFO interface
  (* always_ready, always_enabled, prefix="", result="rdFIFO_Empty" *)
  method Action rdFIFO_Empty(Bit#(1) rdFIFO_EmptyIn);

  (* always_ready, always_enabled, prefix="", result="rdFIFO_Pop" *)
  method Bit#(1) rdFIFO_Pop();

  (* always_ready, always_enabled, prefix="", result="rdFIFO_Flush" *)
  method Bit#(1) rdFIFO_Flush();

  (* always_ready, always_enabled, prefix="", result="rdFIFO_Latency" *)
  method Action rdFIFO_Latency(Bit#(2) rdFIFO_Latency);

  (* always_ready, always_enabled, prefix="", result="rdFIFO_Data" *)
  method Action rdFIFO_Data(Bit#(64) rdFIFO_Data);

  (* always_ready, always_enabled, prefix="", result="rdFIFO_RdWdAddr" *)
  method Action rdFIFO_RdWdAddr(Bit#(4) rdFIFO_RdWdAddr);

  // write FIFO interface
  (* always_ready, always_enabled, prefix="", result="wrFIFO_Empty" *)
  method Action wrFIFO_Empty(Bit#(1) wrFIFO_Empty);

  (* always_ready, always_enabled, prefix="", result="wrFIFO_AlmostFull" *)
  method Action wrFIFO_AlmostFull(Bit#(1) wrFIFO_AlmostFull);

  (* always_ready, always_enabled, prefix="", result="wrFIFO_Push" *)
  method Bit#(1) wrFIFO_Push();

  (* always_ready, always_enabled, prefix="", result="wrFIFO_Flush" *)
  method Bit#(1) wrFIFO_Flush();

  (* always_ready, always_enabled, prefix="", result="wrFIFO_Data" *)
  method Bit#(64) wrFIFO_Data();

  (* always_ready, always_enabled, prefix="", result="wrFIFO_BE" *)
  method Bit#(8) wrFIFO_BE();

endinterface

interface NPIMaster;
  interface NPIServer npi_server;
  interface NPIMasterWires npiMasterWires;
endinterface

typedef enum {
  ProcessCmd,
  ProcessWrite,
  ProcessWriteSpecial,
  ProcessWriteSpecialData,
  SendWrite
} InboundProcessState deriving (Eq,Bits);

module mkNPIMaster#(Clock coreClock, Reset coreReset)(NPIMaster);
  // default clock for this module is the NPI clock!!
  // core clock is the clock that the Get/Put interfaces use
  Clock npiClock <- exposeCurrentClock;
  Reset npiReset <- exposeCurrentReset;

  Wire#(Bit#(64)) rdFIFO_Data_val <- mkBypassWire;
  Wire#(Bit#(1)) rdFIFO_Empty_val <- mkBypassWire;
  Wire#(Bit#(1)) rdFIFO_Flush_val <- mkDWire(0);
  Wire#(Bit#(4)) rdFIFO_RdWdAddr_val <- mkBypassWire;
  //
  Wire#(Bit#(1)) initDone_val <- mkBypassWire;
  Wire#(Bit#(1)) addrReq_val <- mkDWire(0);
  Wire#(Bit#(1)) addrAck_val <- mkBypassWire;
  Wire#(Bit#(32)) addr_val <- mkDWire(0);
  Wire#(Bit#(1)) rnw_val <- mkDWire(0);
  Wire#(Bit#(4)) size_val <- mkDWire(0);
  Wire#(Bit#(1)) rdModWr_val <- mkDWire(0);
  //
  Wire#(Bit#(1)) wrFIFO_AlmostFull_val <- mkBypassWire;
  Wire#(Bit#(1)) wrFIFO_Push_val <- mkDWire(0);
  Wire#(Bit#(64)) wrFIFO_Data_val <- mkDWire(0);
  Wire#(Bit#(8)) wrFIFO_BE_val <- mkDWire(0);

  Wire#(Bit#(2)) rdFIFO_Latency_val <- mkBypassWire;
  Reg#(InboundProcessState) state <- mkReg(ProcessCmd);

  Reg#(Bit#(5)) xfer_count <- mkRegU;
  PulseWire assertPop <- mkPulseWire;
  Vector#(2, Reg#(Bool)) assertPopDelay <- replicateM(mkReg(False));

  // Reset reg since we seem to be having init issues
  Reg#(Bool) initialized <- mkReg(False);

  // Dual-Domain FIFOs
  SyncFIFOLevelIfc#(NPIWriteWord, 32) writeQ <- mkSyncFIFOLevel(coreClock, coreReset, npiClock);
  SyncFIFOIfc#(NPIReadWord) readQ <- mkSyncFIFO(32, npiClock, npiReset, coreClock);
  SyncFIFOIfc#(Bit#(1)) readTokenQ <- mkSyncFIFO(32, npiClock, npiReset, coreClock);
  SyncFIFOIfc#(NPICommand) commandQ <- mkSyncFIFO(4, coreClock, coreReset, npiClock);


  // Dual domain debug regs

  Reg#(Bit#(32)) addrAcksReadSync <- mkSyncRegFromCC(0,coreClock);
  Reg#(Bit#(32)) addrAcksReadLocal <- mkReg(0);
  Reg#(Bit#(32)) addrAcksWriteSync <- mkSyncRegFromCC(0,coreClock);
  Reg#(Bit#(32)) addrAcksWriteLocal <- mkReg(0);
  Reg#(Bit#(32)) clockTicksSync <- mkSyncRegFromCC(0,coreClock);
  Reg#(Bit#(32)) clockTicksLocal <- mkReg(0);
  Reg#(Bit#(32)) clockTicksCore <- mkReg(0, clocked_by coreClock, reset_by coreReset);
  
  //
  // Some assignments
  //

  let init_done = (initDone_val == 0) ? False : True;

  //
  // Rules
  //

  //Sometimes the xilinx ip has leftover data in it from previous runs clear it out.
  rule initializePHY(init_done && !initialized);
    initialized <= True;
    // send a flush if necessary
    //if(rdFIFO_Empty_val == 0)
    //  begin
    rdFIFO_Flush_val <= 1;
    //  end
  endrule

  rule assert_pop (initialized && (rdFIFO_Empty_val == 0));
    readTokenQ.enq(?);
    assertPop.send;
  endrule

  rule make_delay_line;
    assertPopDelay[0] <= assertPop;
    assertPopDelay[1] <= assertPopDelay[0];
  endrule

  // dequeue read data whenever its ready
  // but only if init is done
  rule process_read_fifo(initialized);
    // MPMC specifies the latency between pop assert and data valid
    // by way of a "latency" signal - can be 0, 1, or 2 cycles
    let delay = rdFIFO_Latency_val;

    let pop_dvalid = (delay == 0) ? assertPop : assertPopDelay[(delay-1)];

    // note: readQ should NEVER be full if pop_dvalid == True
    // i.e. the rule should always fire when pop_dvalid is true
    if(pop_dvalid) begin
      readQ.enq(NPIReadWord { data: rdFIFO_Data_val,
                              addr: rdFIFO_RdWdAddr_val });
    end
  endrule


  rule clockTicksCount;
    clockTicksLocal <= clockTicksLocal + 1;
    clockTicksSync <= clockTicksLocal + 1;
  endrule

  rule clockTicksCoreCount;
    clockTicksCore <= clockTicksCore + 1;
  endrule

  // FSM for processing commands/injecting write data into MPMC

  rule process_command_fifo (state == ProcessCmd && initialized);
    case (commandQ.first()) matches
      tagged ReadCommand .rc: begin
        addrReq_val <= 1'b1;
        addr_val <= rc.addr;
        rnw_val <= 1'b1;
        size_val <= zeroExtend(pack(rc.size));

        rdModWr_val <= 1'b0;

        if(addrAck_val == 1) 
          begin
            commandQ.deq();
            addrAcksReadLocal <= addrAcksReadLocal + 1;
            addrAcksReadSync <= addrAcksReadLocal + 1;
          end
      end
      tagged WriteCommand .wc: begin
        let burst_ready =
          case (wc.size)
            BURST_1: return writeQ.dIsGreaterThan(0);
            BURST_2: return writeQ.dIsGreaterThan(1);
            BURST_4: return writeQ.dIsGreaterThan(3);
            BURST_8: return writeQ.dIsGreaterThan(7);
            BURST_16: return writeQ.dIsGreaterThan(15);
            BURST_32: return writeQ.dIsGreaterThan(31);
            default: return writeQ.dIsGreaterThan(0);
          endcase;

        let burst_count_max =
          case (wc.size)
            BURST_1: return 0;
            BURST_2: return 1;
            BURST_4: return 3;
            BURST_8: return 7;
            BURST_16: return 15;
            BURST_32: return 31;
            default: 0;
          endcase;

        // make sure we have a full burst ready to go
        // Size 0 is a special case.  In this case, we need to push data 1 cycle _after_ the addr ack
        if(burst_ready) begin
          xfer_count <= burst_count_max;
          state <= (wc.size == BURST_1) ? ProcessWriteSpecial:ProcessWrite;
        end
      end
    endcase
  endrule

  rule process_write_fifo (state == ProcessWrite && initialized);
    if(wrFIFO_AlmostFull_val == 0) begin
      if(xfer_count == 0) state <= SendWrite;
      else xfer_count <= xfer_count - 1;

      wrFIFO_Push_val <= 1'b1;
      wrFIFO_Data_val <= writeQ.first().data;
      if(commandQ.first() matches tagged WriteCommand .wc &&& wc.rmw)
        wrFIFO_BE_val <= writeQ.first().be;
      else
        wrFIFO_BE_val <= 8'hff;

      writeQ.deq();
    end
  endrule


  rule send_write_cmd (state == SendWrite && initialized);
    case (commandQ.first()) matches
      tagged ReadCommand .rc: state <= ProcessCmd;
      tagged WriteCommand .wc: begin
        addrReq_val <= 1'b1;
        addr_val <= wc.addr;
        rnw_val <= 1'b0;
        size_val <= zeroExtend(pack(wc.size));
        rdModWr_val <= ((wc.rmw || wc.size == BURST_1 || wc.size == BURST_2) ? 1 : 0);

        if(addrAck_val == 1) begin
          commandQ.deq();
          state <= ProcessCmd;
        end
      end
    endcase
  endrule

  rule send_write_cmd_special (state == ProcessWriteSpecial && initialized);
    case (commandQ.first()) matches
      tagged ReadCommand .rc: state <= ProcessCmd; // Not really possible...
      tagged WriteCommand .wc: begin
        addrReq_val <= 1'b1;
        addr_val <= wc.addr;
        rnw_val <= 1'b0;
        size_val <= zeroExtend(pack(wc.size));
        rdModWr_val <= ((wc.rmw || wc.size == BURST_1 || wc.size == BURST_2) ? 1 : 0);

        if(addrAck_val == 1) begin
          addrAcksWriteLocal <= addrAcksWriteLocal + 1;
          addrAcksWriteSync <= addrAcksWriteLocal + 1;
          state <= ProcessWriteSpecialData;
        end
      end
    endcase
  endrule

  rule process_write_fifo_special (state == ProcessWriteSpecialData && initialized);
    if(wrFIFO_AlmostFull_val == 0) begin
      state <= ProcessCmd;
      
      wrFIFO_Push_val <= 1'b1;
      wrFIFO_Data_val <= writeQ.first().data;
      if(commandQ.first() matches tagged WriteCommand .wc &&& wc.rmw)
        wrFIFO_BE_val <= writeQ.first().be;
      else
        wrFIFO_BE_val <= 8'hff;
      commandQ.deq();
      writeQ.deq();
    end
  endrule


  //
  // Interfaces and Methods
  //
  interface NPIServer npi_server;
    interface Get read;
      method ActionValue#(NPIReadWord) get();
        readQ.deq();
        readTokenQ.deq();
        return readQ.first();
      endmethod
    endinterface
    interface Put write;
      method Action put(NPIWriteWord in);
        writeQ.enq(in);
      endmethod
    endinterface
    interface Put command;
      method Action put(NPICommand in);
       commandQ.enq(in);
      endmethod
    endinterface

    method addrAcksRead = addrAcksReadSync._read();
    method addrAcksWrite = addrAcksWriteSync._read();
    method clockTicks = clockTicksSync._read();
    method clockTicksCore = clockTicksCore._read();
  endinterface


  interface NPIMasterWires npiMasterWires;
    // Init Done
    method Action initDone(Bit#(1) in);
      initDone_val <= in;
    endmethod
    // Request Interface
    method Bit#(1) addrReq();
      return addrReq_val;
    endmethod
    method Action addrAck(Bit#(1) in);
      addrAck_val <= in;
    endmethod
    method Bit#(32) addr();
      return addr_val;
    endmethod
    method Bit#(1) rnw();
      return rnw_val;
    endmethod
    method Bit#(4) size();
      return size_val;
    endmethod
    method Bit#(1) rdModWr();
      return rdModWr_val;
    endmethod
    // Read FIFO Interface
    method Action rdFIFO_Empty(Bit#(1) in);
      rdFIFO_Empty_val <= in;
    endmethod
    method Action rdFIFO_Latency(Bit#(2) in);
      rdFIFO_Latency_val <= in;
    endmethod
    method Action rdFIFO_Data(Bit#(64) in);
      rdFIFO_Data_val <= in;
    endmethod
    method Action rdFIFO_RdWdAddr(Bit#(4) in);
      rdFIFO_RdWdAddr_val <= in;
    endmethod
    method Bit#(1) rdFIFO_Pop();
      return assertPop ? 1 : 0;
    endmethod
    method Bit#(1) rdFIFO_Flush();
      return 0;//rdFIFO_Flush_val;
    endmethod
    // Write FIFO Interface
    method Action wrFIFO_Empty(Bit#(1) in);
      noAction;
    endmethod
    method Action wrFIFO_AlmostFull(Bit#(1) in);
      wrFIFO_AlmostFull_val <= in;
    endmethod
    method Bit#(1) wrFIFO_Push();
      return wrFIFO_Push_val;
    endmethod
    method Bit#(1) wrFIFO_Flush();
      return 0;
    endmethod
    method Bit#(64) wrFIFO_Data();
      return wrFIFO_Data_val;
    endmethod
    method Bit#(8) wrFIFO_BE();
      return wrFIFO_BE_val;
    endmethod
  endinterface
endmodule
