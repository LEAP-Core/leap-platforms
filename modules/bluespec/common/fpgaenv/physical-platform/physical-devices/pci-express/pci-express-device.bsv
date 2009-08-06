//
// Copyright (C) 2008 Intel Corporation
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

import Vector::*;
import Clocks::*;
import LevelFIFO::*;

`include "physical_platform_utils.bsh"

// Subinterfaces

interface COMMON_CSR_ARRAY;
    
    method Action                      readRequest(PCIE_CSR_INDEX index);
    method ActionValue#(PCIE_CSR_DATA) readResponse();
    method Action                      write(PCIE_CSR_INDEX index, PCIE_CSR_DATA data);
        
endinterface

interface SYSTEM_CSR;
    
    method PCIE_CSR_DATA _read();
    method Action        _write(PCIE_CSR_DATA data);
        
endinterface

interface DMA_DRIVER;
    
    method Action                      startRead(PCIE_PHYSICAL_ADDRESS addr, PCIE_LENGTH len);
    method ActionValue#(PCIE_DMA_DATA) readData();
    method Action                      startWrite(PCIE_PHYSICAL_ADDRESS addr, PCIE_LENGTH len);
    method Action                      writeData(PCIE_DMA_DATA data);
        
endinterface
        
// PCI_EXPRESS_DRIVER

// The PCIE Platform supports reading and writing data and csrs,
// as well as interrupting the host processor.

interface PCI_EXPRESS_DRIVER;

    // CSRs
    interface COMMON_CSR_ARRAY commonCSRs;
    interface SYSTEM_CSR       systemCSR;
    
    // DMA
    interface DMA_DRIVER dmaDriver;

    // interrupt
    method Action interruptHost();
        
endinterface

// PCI_EXPRESS_WIRES

// These are wires which are simply passed up to the toplevel,
// where the UCF file ties them to pins.

interface PCI_EXPRESS_WIRES;

    // (* always_enabled *) // , always_ready *)
    method Action sys_clk_p();

    // (* always_enabled *) // , always_ready *)
    method Action sys_clk_n();

    // (* always_enabled *) // , always_ready *)
    method Action sys_reset_n();

    // (* always_enabled *) // , always_ready *)
    method Action pci_exp_rxn((* port="pci_exp_rxn" *) Bit#(4) rxn);

    // (* always_enabled *) // , always_ready *)
    method Action pci_exp_rxp((* port="pci_exp_rxp" *) Bit#(4) rxp);

    (* always_ready *)
    (* result="pci_exp_txn" *)
    method Bit#(4) pci_exp_txn();

    (* always_ready *)
    (* result="pci_exp_txp" *)
    method Bit#(4) pci_exp_txp();

endinterface

// PCIE_DEVICE_STATE

typedef enum
{
    PCIE_DEVICE_STATE_init,
    PCIE_DEVICE_STATE_waitForAck,
    PCIE_DEVICE_STATE_ready
}
PCIE_DEVICE_STATE
    deriving (Bits, Eq);

// PCI_EXPRESS_DEVICE

// By convention a Device is a Driver and a Wires

interface PCI_EXPRESS_DEVICE;

  interface PCI_EXPRESS_DRIVER driver;
  interface PCI_EXPRESS_WIRES  wires;

endinterface


// mkPCIExpressDevice

// Take the primitive PCI Express import and cross the clock domains into the default bluespec domain.

module mkPCIExpressDevice#(SOFT_RESET_TRIGGER softResetTrigger)
    // interface:
                 (PCI_EXPRESS_DEVICE);

    // Instantiate the primitive device.

    PRIMITIVE_PCI_EXPRESS_DEVICE prim_pci <- mkPrimitivePCIExpressDevice();

    Clock bsv_clk <- exposeCurrentClock();
    Reset bsv_rst <- exposeCurrentReset();
    
    // translate our reset (bsv_rst) to the PCIe clock domain. Note that this is
    // different from the PCIe's native reset.
    // WE DON'T USE THIS ANYMORE, WE SIMPLY USE PCIE'S EXPORTED RESET (WHICH IS
    // ANDED WITH THE SOFT RESET SIGNAL IN THE VHDL)
    // Reset trans_rst <- mkAsyncResetFromCR(0, prim_pci.pcie_clk);
    
    // Device state
    Reg#(PCIE_DEVICE_STATE) state <- mkReg(PCIE_DEVICE_STATE_init);
    
    // CSR Read Port state
    Reg#(Bool) csrReadPortBusy <- mkReg(False);
    
    // Device is ready only in a particular state
    Bool ready = (state == PCIE_DEVICE_STATE_ready);

    // Synchronizers from PCIE to Bluespec.    
    Reg#(PCIE_CSR_DATA)          sync_csr_h2f_reg0_read_r
                              <- mkSyncReg(?, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);
    
    SyncFIFOIfc#(PCIE_CSR_DATA)  sync_csr_read_resp_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);
    
    SyncFIFOIfc#(Bool)           sync_reset_req_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);
    SyncFIFOIfc#(Bool)           sync_init_resp_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);

    SyncFIFOIfc#(PCIE_DMA_DATA)  sync_dma_read_data_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);

    // Synchronizers from BSV to PCIe
    SyncFIFOIfc#(PCIE_CSR_INDEX) sync_csr_read_req_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOLevelIfc#(Tuple2#(PCIE_CSR_INDEX, PCIE_CSR_DATA), 2) sync_csr_write_q
                              <- mkSyncFIFOLevel(bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOIfc#(PCIE_CSR_DATA)  sync_csr_f2h_reg0_write_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOIfc#(Bool)           sync_interrupt_host_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOIfc#(Bool)           sync_reset_resp_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOIfc#(Bool)           sync_init_req_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOLevelIfc#(Tuple2#(PCIE_PHYSICAL_ADDRESS, PCIE_LENGTH), 2) sync_dma_read_start_q
                              <- mkSyncFIFOLevel(bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOLevelIfc#(Tuple2#(PCIE_PHYSICAL_ADDRESS, PCIE_LENGTH), 2) sync_dma_write_start_q
                              <- mkSyncFIFOLevel(bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOIfc#(PCIE_DMA_DATA)  sync_dma_write_data_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    // function to swap endianness
    function t swapEndian(t inData)
        provisos(Bits#(t, nbits),
                 Div#(nbits, 8, nbytes),
                 Bits#(Vector::Vector#(nbytes, Bit#(8)), nbits));

        Vector#(nbytes, Bit#(8)) vec = unpack(pack(inData));
        Vector#(nbytes, Bit#(8)) rev = reverse(vec);

        return unpack(pack(rev));

    endfunction

    //
    // Initialization/Reset Rules
    //
    // Reset Protocol: when the reset_req signal (from VHDL) goes high, the top
    // level will reset the entire module hierarchy in the Bluepsec clock domain.
    // On being reset -- which could occur immediately after the bitfile was
    // downloaded (hard reset) or as a result of the above protocol (soft reset),
    // this module will ask the VHDL to init(). Once we receive a response to
    // the init() call, we send a "response" to the reset request and are then
    // ready to function normally.
    //
    
    // ask VHDL to initialize
    rule init (state == PCIE_DEVICE_STATE_init);
        
        // tell primitive device (VHDL) to initialize
        sync_init_req_q.enq(?);
        
        // wait for response from VHDL
        state <= PCIE_DEVICE_STATE_waitForAck;
        
    endrule
    
    // wait for VHDL to finish initializing
    rule wait_for_ack (state == PCIE_DEVICE_STATE_waitForAck);

        // dequeue a dummy message from the init response queue.
        sync_init_resp_q.deq();
        
        // send "response" to reset request to primitive device.
        // this response will be sent on both a hard as well as
        // a soft reset
        sync_reset_resp_q.enq(?);
        
        // transition to ready state
        state <= PCIE_DEVICE_STATE_ready;
    
    endrule
    
    // actually trigger the reset
    rule trigger_soft_reset (True);
        
        // dequeue from the reset request queue
        sync_reset_req_q.deq();
        
        // trigger!
        softResetTrigger.reset();

    endrule

    //
    // Rules for synchronizing from PCIe to Bluespec
    //
    
    rule sync_reset_req (True);

        prim_pci.reset_req();
        sync_reset_req_q.enq(?);
        
    endrule
    
    rule sync_init_resp (True);

        prim_pci.init_resp();
        sync_init_resp_q.enq(?);
        
    endrule

    rule sync_csr_h2f_reg0_read (True);
    
        sync_csr_h2f_reg0_read_r <= swapEndian(prim_pci.csr_h2f_reg0_read());

    endrule

    rule sync_csr_read_resp (True);

        let x <- prim_pci.csr_read_resp();
        sync_csr_read_resp_q.enq(swapEndian(x));

    endrule

    rule sync_dma_read_data (True);
        
        let x <- prim_pci.dma_read_data();
        sync_dma_read_data_q.enq(swapEndian(x));
        
    endrule
    
    // Rules for synchronizing from BSV to PCIe.

    rule sync_reset_resp (True);
        
        sync_reset_resp_q.deq();
        prim_pci.reset_resp();
        
    endrule
    
    rule sync_init_req (True);
        
        sync_init_req_q.deq();
        prim_pci.init_req();
        
    endrule

    rule sync_csr_read_req (True);

        sync_csr_read_req_q.deq();
        prim_pci.csr_read_req(sync_csr_read_req_q.first());

    endrule

    rule sync_csr_write (True);

        sync_csr_write_q.deq();
        match {.a, .v} = sync_csr_write_q.first();
        prim_pci.csr_write(a, swapEndian(v));

    endrule

    rule sync_csr_f2h_reg0_write (True);

        sync_csr_f2h_reg0_write_q.deq();
        prim_pci.csr_f2h_reg0_write(swapEndian(sync_csr_f2h_reg0_write_q.first()));

    endrule

    rule sync_interrupt_host (True);

        sync_interrupt_host_q.deq();
        prim_pci.interrupt_host();

    endrule
    
    rule sync_dma_read_start (True);

        sync_dma_read_start_q.deq();
        match {.a, .l} = sync_dma_read_start_q.first();
        prim_pci.dma_read_start(a, l);

    endrule

    rule sync_dma_write_start (True);

        sync_dma_write_start_q.deq();
        match {.a, .l} = sync_dma_write_start_q.first();
        prim_pci.dma_write_start(a, l);

    endrule

    rule sync_dma_write_data (True);

        sync_dma_write_data_q.deq();
        prim_pci.dma_write_data(swapEndian(sync_dma_write_data_q.first()));

    endrule

    // The wires are not domain-crossed because no one should ever look at them.

    interface PCI_EXPRESS_WIRES wires;
      
        method sys_clk_p   = prim_pci.sys_clk_p;

        method sys_clk_n   = prim_pci.sys_clk_n;

        method sys_reset_n = prim_pci.sys_reset_n;

        method pci_exp_rxn = prim_pci.pci_exp_rxn;

        method pci_exp_rxp = prim_pci.pci_exp_rxp;

        method pci_exp_txn = prim_pci.pci_exp_txn;

        method pci_exp_txp = prim_pci.pci_exp_txp;
      
    endinterface
    
    // Drivers visible to upper layers
    
    interface PCI_EXPRESS_DRIVER driver;
    
        // Common CSRs
        
        interface COMMON_CSR_ARRAY commonCSRs;
    
            method Action readRequest(PCIE_CSR_INDEX idx) if (ready);

                sync_csr_read_req_q.enq(idx);

            endmethod

            method ActionValue#(PCIE_CSR_DATA) readResponse() if (ready);

                sync_csr_read_resp_q.deq();
                return sync_csr_read_resp_q.first();

            endmethod
        
            method Action write(PCIE_CSR_INDEX idx, PCIE_CSR_DATA d) if (ready);

                sync_csr_write_q.enq(tuple2(idx, d));

            endmethod
            
        endinterface
    
        // System CSR
        
        interface SYSTEM_CSR systemCSR;
        
            method _read = sync_csr_h2f_reg0_read_r;
        
            method Action _write(PCIE_CSR_DATA d) if (ready);

                sync_csr_f2h_reg0_write_q.enq(d);

            endmethod
                
        endinterface
    
        // DMA
            
        interface DMA_DRIVER dmaDriver;

            method Action startRead(PCIE_PHYSICAL_ADDRESS addr, PCIE_LENGTH len) if (ready);
            
                sync_dma_read_start_q.enq(tuple2(addr, len));
            
            endmethod
            
            method ActionValue#(PCIE_DMA_DATA) readData() if (ready);
            
                sync_dma_read_data_q.deq();
                return sync_dma_read_data_q.first();
            
            endmethod
            
            method Action startWrite(PCIE_PHYSICAL_ADDRESS addr, PCIE_LENGTH len) if (ready);
            
                sync_dma_write_start_q.enq(tuple2(addr, len));
            
            endmethod
            
            method Action writeData(PCIE_DMA_DATA data) if (ready);
            
                sync_dma_write_data_q.enq(data);
            
            endmethod
            
        endinterface

        // Interrupt
        
        method Action interruptHost() if (ready);

            sync_interrupt_host_q.enq(?);

        endmethod

    endinterface

endmodule


// mkPCIExpressDeviceDisabled

// An empty version of the PCI Device for configurations which do not use PCIE.

module mkPCIExpressDeviceDisabled (PCI_EXPRESS_DEVICE);

  return ?;
  
endmodule
