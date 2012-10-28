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
import FIFO::*;

`include "asim/provides/physical_platform_utils.bsh"
`include "asim/provides/fpga_components.bsh"
`include "asim/provides/librl_bsv_base.bsh"

typedef Bit#(9) DMA_BURST_INDEX;

typedef enum
{
    DMA_WRITE_STATE_idle,
    DMA_WRITE_STATE_buffering,
    DMA_WRITE_STATE_writing
}
DMA_WRITE_STATE
    deriving (Bits, Eq);

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
    SyncFIFOIfc#(PCIE_CSR_DATA) sync_csr_h2f_reg0_read_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);
    
    SyncFIFOIfc#(PCIE_CSR_DATA)  sync_csr_read_resp_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);

    SyncFIFOIfc#(Bool)           sync_reset_req_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);
    
    SyncFIFOIfc#(Bool)           sync_init_resp_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);

    SyncFIFOLevelIfc#(PCIE_DMA_DATA, 4) sync_dma_read_data_q
                              <- mkSyncFIFOLevel(prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);
    
    // Synchronizers from BSV to PCIe
    SyncFIFOIfc#(PCIE_CSR_INDEX) sync_csr_read_req_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOIfc#(Tuple2#(PCIE_CSR_INDEX, PCIE_CSR_DATA)) sync_csr_write_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOIfc#(PCIE_CSR_DATA)  sync_csr_f2h_reg0_write_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOIfc#(Bool)           sync_interrupt_host_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOIfc#(Bool)           sync_reset_resp_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOIfc#(Bool)           sync_init_req_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOIfc#(Tuple2#(PCIE_PHYSICAL_ADDRESS, PCIE_LENGTH)) sync_dma_read_start_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOIfc#(Tuple2#(PCIE_PHYSICAL_ADDRESS, PCIE_LENGTH)) sync_dma_write_start_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOIfc#(PCIE_DMA_DATA)  sync_dma_write_data_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    /*
    // temporary buffer for DMA write data 
    FIFO#(Tuple2#(PCIE_PHYSICAL_ADDRESS, PCIE_LENGTH)) dma_write_start_buf
                              <- mkFIFO(clocked_by prim_pci.pcie_clk, reset_by prim_pci.pcie_rst);

    FIFOCountIfc#(PCIE_DMA_DATA, 15) dma_write_data_buf
                              <- mkFIFOCount(clocked_by prim_pci.pcie_clk, reset_by prim_pci.pcie_rst);
     */

    // function to swap endianness
    function t swapEndian(t inData)
        provisos(Bits#(t, nbits),
                 Div#(nbits, 8, nbytes),
                 Bits#(Vector::Vector#(nbytes, Bit#(8)), nbits));

        Vector#(nbytes, Bit#(8)) vec = unpack(pack(inData));
        Vector#(nbytes, Bit#(8)) rev = reverse(vec);

        return unpack(pack(rev));

    endfunction

    // DMA data needs to be flipped at the 32-bit boundary
    function t swapHalves(t inData)
        provisos(Bits#(t, nbits),
                 Div#(nbits, 2, nhalfbits),
                 Bits#(Vector::Vector#(2, Bit#(nhalfbits)), nbits));
    
        Vector#(2, Bit#(nhalfbits)) vec = unpack(pack(inData));
        Vector#(2, Bit#(nhalfbits)) rev = reverse(vec);
        
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
    
        sync_csr_h2f_reg0_read_q.enq(swapEndian(prim_pci.csr_h2f_reg0_read()));

    endrule
        
    //
    // copy_csr_reg0 --
    //    Move the copy of CSR reg 0 to the Bluespec clock domain.
    //
    Reg#(PCIE_CSR_DATA) csr_reg0_local <- mkRegU();

    rule copy_csr_reg0 (True);

        sync_csr_h2f_reg0_read_q.deq();
        csr_reg0_local <= sync_csr_h2f_reg0_read_q.first();

    endrule

    rule sync_csr_read_resp (True);

        let x <- prim_pci.csr_read_resp();
        sync_csr_read_resp_q.enq(swapEndian(x));

    endrule
    
    /*
    // To read in the data, we need to issue a Read into the Xilinx FIFO
    // one cycle before we can actually latch the data. We need to make
    // sure there's space in the Sync FIFO before issuing the request.
    // We'll spam read requests into the FIFO and if there's no data it'll
    // simply underflow.
    
    rule issue_dma_read_data_req (sync_dma_read_data_q.sNotFull());
        
        prim_pci.dma_read_data_req();
        
    endrule
    */
    
    rule sync_dma_read_data (True);
        
        let x <- prim_pci.dma_read_data();
        sync_dma_read_data_q.enq(swapHalves(swapEndian(x)));
        
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

    //
    // managed/buffered DMA write
    //
    
    // 4KB DMA buffer (512 x 64-bit entries)
    
    BRAM#(DMA_BURST_INDEX, PCIE_DMA_DATA) dmaBuffer <- mkBRAM(clocked_by prim_pci.pcie_clk,
                                                 reset_by prim_pci.pcie_rst);

    Reg#(DMA_WRITE_STATE) dmaWriteState <- mkReg(DMA_WRITE_STATE_idle,
                                                 clocked_by prim_pci.pcie_clk,
                                                 reset_by prim_pci.pcie_rst);
    
    Reg#(DMA_BURST_INDEX) dmaBufferIndex <- mkReg(0,
                                                 clocked_by prim_pci.pcie_clk,
                                                 reset_by prim_pci.pcie_rst);

    Reg#(DMA_BURST_INDEX) dmaBurstLengthMinusOne <- mkReg(0,
                                                 clocked_by prim_pci.pcie_clk,
                                                 reset_by prim_pci.pcie_rst);
    
    Reg#(PCIE_PHYSICAL_ADDRESS) dmaWriteAddr   <- mkReg(0,
                                                 clocked_by prim_pci.pcie_clk,
                                                 reset_by prim_pci.pcie_rst);

    Reg#(PCIE_LENGTH)           dmaWriteLength <- mkReg(0,
                                                 clocked_by prim_pci.pcie_clk,
                                                 reset_by prim_pci.pcie_rst);
    
    Reg#(Bool) dmaEnqueueCmd <- mkReg(False,
                                                 clocked_by prim_pci.pcie_clk,
                                                 reset_by prim_pci.pcie_rst);

    // transfer from sync FIFO into internal buffer
    rule dma_write_start_buffering (dmaWriteState == DMA_WRITE_STATE_idle);

        match { .address, .length } = sync_dma_write_start_q.first();
        sync_dma_write_start_q.deq();
        
        PCIE_LENGTH data_chunks = length >> `PCIE_LOG_DMA_DATA_BYTES;
    
        // store address and burst length for this request
        dmaBurstLengthMinusOne <= truncate(data_chunks - 1);
        dmaWriteAddr           <= address;
        dmaWriteLength         <= length;
        
        // start buffering into BRAM
        dmaBufferIndex <= 0;
        dmaWriteState <= DMA_WRITE_STATE_buffering;

    endrule
    
    rule dma_write_continue_buffering (dmaWriteState == DMA_WRITE_STATE_buffering);

        sync_dma_write_data_q.deq();
        let x = swapHalves(swapEndian(sync_dma_write_data_q.first()));

        dmaBuffer.write(dmaBufferIndex, x);
        
        if (dmaBufferIndex == dmaBurstLengthMinusOne)
        begin
            dmaBufferIndex <= 0;
            dmaWriteState <= DMA_WRITE_STATE_writing;
            
            prim_pci.dma_write_start(dmaWriteAddr, dmaWriteLength);
        end
        else
        begin
            dmaBufferIndex <= dmaBufferIndex + 1;
        end

    endrule

    // issue the read into the BRAM
    rule issue_bram_read (dmaWriteState == DMA_WRITE_STATE_writing);
        
        dmaBuffer.readReq(dmaBufferIndex);
        
        if (dmaBufferIndex == dmaBurstLengthMinusOne)
        begin
            dmaBufferIndex <= 0;
            dmaWriteState <= DMA_WRITE_STATE_idle;
        end
        else
        begin
            dmaBufferIndex <= dmaBufferIndex + 1;
        end

    endrule
    
    // stream data out of BRAM into DMA engine
    rule dma_bram_to_engine (True); // dmaWriteState == DMA_WRITE_STATE_writing);

        let x <- dmaBuffer.readRsp();
        prim_pci.dma_write_data(x);
        
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

            method PCIE_CSR_DATA _read();

                return csr_reg0_local;

            endmethod

        
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
