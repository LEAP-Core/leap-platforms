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

// Author: Kermin Fleming kfleming@mit.edu

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/ddr_sdram_device.bsh"

import NPICommon::*;

interface DDR_SDRAM_WIRES;
    //
    // wires from the mem controller to the DRAM device
    //
    
    (* always_ready *)
    method    Bit#(3)           ck_p;

    (* always_ready *)
    method    Bit#(3)           ck_n;
        
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
    method    Bit#(1)           cs_n;
        
    (* always_ready *)
    method    Bit#(1)           ce;

    (* always_ready *)
    method    Bit#(8)           dm;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(64))  dq;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(8))   dqs;

endinterface


// For now we use this typedef...
interface DDR_SDRAM_DRIVER;
  interface BURST_MEMORY_IFC#(Bit#(`DRAM_ADDRESS_SIZE), Bit#(`DRAM_WORD_SIZE), `DRAM_MAX_BURST_SIZE) burstIfc;
  method Bit#(32) readsReturned();
  method Bit#(32) writesReceived();
  method Bit#(32) writeCommandsReceived();
  method Bit#(32) readCommandsReceived();
endinterface

// At some point, we should add counters to track how much buffer capacity we have actually got

module  mkNPIWrapper#(NPIServer npiServer) (DDR_SDRAM_DRIVER);
    Reg#(Bool) handlingRead <- mkReg(True);
    Reg#(Bit#(TAdd#(1,TLog#(`DRAM_MAX_BURST_SIZE)))) wordsRemaining <- mkReg(0);
    Reg#(Bit#(TAdd#(1,TLog#(`DRAM_MAX_BURST_SIZE)))) outstandingReqs <- mkReg(0);
    Reg#(Bit#(`DRAM_ADDRESS_SIZE)) address <- mkReg(0);

    Reg#(Bit#(32)) readsReturnedCount <- mkReg(0);
    Reg#(Bit#(32)) writesReturnedCount <- mkReg(0);
    Reg#(Bit#(32)) writeCommandsReceivedCount <- mkReg(0);
    Reg#(Bit#(32)) readCommandsReceivedCount <- mkReg(0);

    // We have to check for aligned accesses here...

    rule handleRead(handlingRead && wordsRemaining > 0 && outstandingReqs == 0);
      if(wordsRemaining >= 32 && address[4:0] == 0)
        begin
          npiServer.command.put(tagged ReadCommand{addr: zeroExtend({address,3'b000}), size: BURST_32});
          address <= address + 32;
          wordsRemaining <= wordsRemaining - 32;
          outstandingReqs <= 32; 
        end
      else if(wordsRemaining >= 16 && address[3:0] == 0) 
        begin
          npiServer.command.put(tagged ReadCommand{addr: zeroExtend({address,3'b000}), size: BURST_16});
          address <= address + 16;
          wordsRemaining <= wordsRemaining - 16;
          outstandingReqs <= 16; 
        end    
      else if(wordsRemaining >= 8 && address[2:0] == 0) 
        begin
          npiServer.command.put(tagged ReadCommand{addr: zeroExtend({address,3'b000}), size: BURST_8});
          address <= address + 8;
          wordsRemaining <= wordsRemaining - 8;
          outstandingReqs <= 8; 
        end    
      else if(wordsRemaining >= 4 && address[1:0] == 0) 
        begin
          npiServer.command.put(tagged ReadCommand{addr: zeroExtend({address,3'b000}), size: BURST_4});
          address <= address + 4;
          wordsRemaining <= wordsRemaining - 4;
          outstandingReqs <= 4; 
        end    
      else if(wordsRemaining >= 2 && address[0] == 0) 
        begin
          npiServer.command.put(tagged ReadCommand{addr: zeroExtend({address,3'b000}), size: BURST_2});
          address <= address + 2;
          wordsRemaining <= wordsRemaining - 2;
          outstandingReqs <= 2; 
        end    
      else  
        begin
          npiServer.command.put(tagged ReadCommand{addr: zeroExtend({address,3'b000}), size: BURST_1});
          address <= address + 1;
          wordsRemaining <= wordsRemaining - 1;
          outstandingReqs <= 1; 
        end    
    endrule

    rule handleWrite(!handlingRead && wordsRemaining > 0);
      if(wordsRemaining >= 32 && address[4:0] == 0)
        begin
          npiServer.command.put(tagged WriteCommand{addr: zeroExtend({address,3'b000}), size: BURST_32, rmw: False});
          address <= address + 32;
          wordsRemaining <= wordsRemaining - 32;
        end
      else if(wordsRemaining >= 16 && address[3:0] == 0) 
        begin
          npiServer.command.put(tagged WriteCommand{addr: zeroExtend({address,3'b000}), size: BURST_16, rmw: False});
          address <= address + 16;
          wordsRemaining <= wordsRemaining - 16;
        end    
      else if(wordsRemaining >= 8 && address[2:0] == 0) 
        begin
          npiServer.command.put(tagged WriteCommand{addr: zeroExtend({address,3'b000}), size: BURST_8, rmw: False});
          address <= address + 8;
          wordsRemaining <= wordsRemaining - 8;
        end    
      else if(wordsRemaining >= 4 && address[1:0] == 0) 
        begin
          npiServer.command.put(tagged WriteCommand{addr: zeroExtend({address,3'b000}), size: BURST_4, rmw: False});
          address <= address + 4;
          wordsRemaining <= wordsRemaining - 4;
        end    
      else if(wordsRemaining >= 2 && address[0] == 0) 
        begin
          npiServer.command.put(tagged WriteCommand{addr: zeroExtend({address,3'b000}), size: BURST_2, rmw: False});
          address <= address + 2;
          wordsRemaining <= wordsRemaining - 2;
        end    
      else  
        begin
          npiServer.command.put(tagged WriteCommand{addr: zeroExtend({address,3'b000}), size: BURST_1, rmw: False});
          address <= address + 1;
          wordsRemaining <= wordsRemaining - 1;
        end    
    endrule


    interface BURST_MEMORY_IFC burstIfc;
      method Action readReq(BURST_REQUEST#(Bit#(`DRAM_ADDRESS_SIZE),`DRAM_MAX_BURST_SIZE) burstReq) if(wordsRemaining == 0); 
        wordsRemaining <= burstReq.size;
        address <= burstReq.addr;
        handlingRead <= True;
        readCommandsReceivedCount <= readCommandsReceivedCount + 1;
      endmethod

      method ActionValue#(Bit#(`DRAM_WORD_SIZE)) readRsp();
        let npiResp <- npiServer.read.get;
        outstandingReqs <= outstandingReqs - 1;
        readsReturnedCount <= readsReturnedCount + 1;
        return npiResp.data;
      endmethod

      // Look at the read response value without popping it
      method Bit#(`DRAM_WORD_SIZE) peek();
        return peekGet(npiServer.read).data;  
      endmethod

      // Read response ready
      method notEmpty = ?;

      // Read request possible?
      method notFull = ?;

      // We must split the write request and response...
      method Action writeData(Bit#(`DRAM_WORD_SIZE) data);
        npiServer.write.put(NPIWriteWord{data: data, be: ~0}); 
        writesReturnedCount <= writesReturnedCount + 1;
      endmethod

      method Action writeReq(BURST_REQUEST#(Bit#(`DRAM_ADDRESS_SIZE),`DRAM_MAX_BURST_SIZE) burstReq) if(wordsRemaining == 0); 
        wordsRemaining <= burstReq.size;
        address <= burstReq.addr;
        handlingRead <= False;
        writeCommandsReceivedCount <= writeCommandsReceivedCount + 1;
      endmethod
    
      // Write request possible?
      method writeNotFull = ?;
    endinterface

    method readsReturned = readsReturnedCount._read;
    method writesReceived = writesReturnedCount._read;
    method writeCommandsReceived = writeCommandsReceivedCount._read;
    method readCommandsReceived = readCommandsReceivedCount._read;

endmodule




//
// DDR_SDRAM_DEVICE --
//     By convention a device is both a driver and a wires interface.
//     Currently we use the original NPI Bluespec interface here, but 
//     this might change at some point.
//
interface DDR_SDRAM_DEVICE;
    interface DDR_SDRAM_DRIVER driver;
    interface DDR_SDRAM_WIRES  wires;
endinterface




// This device should be clocked at raw clock.  

module mkDDRSDRAMDevice#(Clock rawClock, Reset rawReset) (DDR_SDRAM_DEVICE);

  Clock systemClock <- exposeCurrentClock;
  Reset systemReset <- exposeCurrentReset;

  XILINX_MPMC_DDR_DRAM_CONTROLLER controller <- mkXilinxMPMCDDRDRAMController(clocked_by rawClock, reset_by rawReset);

  NPIMaster master <- mkNPIMaster(systemClock, systemReset, clocked_by controller.controller_clk, reset_by controller.controller_rst);

  DDR_SDRAM_DRIVER burstIfc <- mkNPIWrapper(master.npi_server);

  rule driveAddrReq;
    controller.addrReq(master.npiMasterWires.addrReq());
  endrule

  rule driveMasteraddrAck;
    master.npiMasterWires.addrAck(controller.addrAck());
  endrule

  rule driveAddr;
    controller.addr(master.npiMasterWires.addr());
  endrule

  rule driveRNW;
    controller.rnw(master.npiMasterWires.rnw());
  endrule

  rule driveSize;
    controller.size(master.npiMasterWires.size());
  endrule

  rule driveRdModWr;
    controller.rdModWr(master.npiMasterWires.rdModWr());
  endrule

  rule driveMasterrdFIFO_Empty;
    master.npiMasterWires.rdFIFO_Empty(controller.rdFIFO_Empty());
  endrule

  rule driverdFIFO_Pop;
    controller.rdFIFO_Pop(master.npiMasterWires.rdFIFO_Pop());
  endrule

  rule driverdFIFO_Flush;
    controller.rdFIFO_Flush(master.npiMasterWires.rdFIFO_Flush());
  endrule

  rule driveMasterrdFIFO_Latency;
    master.npiMasterWires.rdFIFO_Latency(controller.rdFIFO_Latency());
  endrule

  rule driveMasterrdFIFO_Data;
    master.npiMasterWires.rdFIFO_Data(controller.rdFIFO_Data());
  endrule

  rule driveMasterrdFIFO_RdWdAddr;
    master.npiMasterWires.rdFIFO_RdWdAddr(controller.rdFIFO_RdWdAddr());
  endrule

  rule driveMasterwrFIFO_Empty;
    master.npiMasterWires.wrFIFO_Empty(controller.wrFIFO_Empty());
  endrule

  rule driveMasterwrFIFO_AlmostFull;
    master.npiMasterWires.wrFIFO_AlmostFull(controller.wrFIFO_AlmostFull());
  endrule

  rule drivewrFIFO_Push;
    controller.wrFIFO_Push(master.npiMasterWires.wrFIFO_Push());
  endrule

  rule drivewrFIFO_Flush;
    controller.wrFIFO_Flush(master.npiMasterWires.wrFIFO_Flush());
  endrule

  rule drivewrFIFO_Data;
    controller.wrFIFO_Data(master.npiMasterWires.wrFIFO_Data());
  endrule

  rule drivewrFIFO_BE;
    controller.wrFIFO_BE(master.npiMasterWires.wrFIFO_BE());
  endrule

  rule driveMasterinitDone;
    master.npiMasterWires.initDone(controller.initDone());
  endrule


  interface driver = burstIfc; 

  interface DDR_SDRAM_WIRES wires;
    
    method  ck_p = controller.ck_p;

    method  ck_n = controller.ck_n;

    method  a = controller.a;

    method  ba = controller.ba;

    method  ras_n = controller.ras_n;

    method  cas_n = controller.cas_n;

    method  we_n = controller.we_n;

    method  cs_n = controller.cs_n;
        
    method  ce = controller.ce;

    method  dm = controller.dm;

    interface  dq = controller.dq;

    interface  dqs = controller.dqs;

  endinterface

endmodule