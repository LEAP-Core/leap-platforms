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

import Clocks::*;

// pci-express-vhdl-import

// Import the VHDL device into BSV

// AWB parameters        default:
// PCIE_PHYS_ADDR_SIZE   64
// PCIE_DMA_DATA_SIZE    64
// PCIE_LEN_SIZE         32
// PCIE_CSR_DATA_SIZE    32
// PCIE_CSR_IDX_SIZE     8

// Datatype definitions

typedef Bit#(`PCIE_PHYS_ADDR_SIZE) PCIE_PHYSICAL_ADDRESS;
typedef Bit#(`PCIE_DMA_DATA_SIZE)  PCIE_DMA_DATA;
typedef Bit#(`PCIE_LEN_SIZE)       PCIE_LENGTH;
typedef Bit#(`PCIE_CSR_DATA_SIZE)  PCIE_CSR_DATA;
typedef Bit#(`PCIE_CSR_IDX_SIZE)   PCIE_CSR_INDEX;


// PRIMITIVE_PCI_EXPRESS_DEVICE

// The primitive vhdl import which we will wrap in clock-domain synchronizers.

interface PRIMITIVE_PCI_EXPRESS_DEVICE;

    // Methods for the Driver

    // CSR Read
    method Action csr_read_req(PCIE_CSR_INDEX idx);
    method ActionValue#(PCIE_CSR_DATA) csr_read_resp();

    // CSR Write
    method Action csr_write(PCIE_CSR_INDEX idx, PCIE_CSR_DATA data);

    // CSR 0 is special in that we can always access it.
    method PCIE_CSR_DATA csr_h2f_reg0_read();
    method Action  csr_f2h_reg0_write(PCIE_CSR_DATA data);

    // DMA
    method Action dma_read_start(PCIE_PHYSICAL_ADDRESS addr, PCIE_LENGTH len);
    // method Action dma_read_data_req();
    method ActionValue#(PCIE_DMA_DATA) dma_read_data();
    method Action dma_write_start(PCIE_PHYSICAL_ADDRESS addr, PCIE_LENGTH len);
    method Action dma_write_data(PCIE_DMA_DATA data);

    // interrupt
    method Action interrupt_host();
        
    // soft reset and init
    method Action reset_req();
    method Action reset_resp();
    method Action init_req();
    method Action init_resp();

    // Wires to be sent to the top level.

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
    
    // The PCIe clock and reset for synchronization.

    interface Clock pcie_clk;

    interface Reset pcie_rst;

endinterface


// mkPrimitivePCIExpressDevice

// Straightforward import of the VHDL into Bluespec.

import "BVI" Channel_top = module mkPrimitivePCIExpressDevice
    // interface:
                 (PRIMITIVE_PCI_EXPRESS_DEVICE);

    // Clocks and reset are handled by the UCF for now
    default_clock no_clock;
    default_reset no_reset;
  
    output_clock pcie_clk(clk);

    output_reset pcie_rst(rst_n) clocked_by(pcie_clk);
  
    method sys_clk_p() enable(sys_clk_p);

    method sys_clk_n() enable(sys_clk_n);
        
    method sys_reset_n() enable(sys_reset_n);
        
    method pci_exp_rxn(pci_exp_rxn) enable ((*inhigh*) EN);

    method pci_exp_rxp(pci_exp_rxp) enable ((*inhigh*) EN2);

    method pci_exp_txn pci_exp_txn();

    method pci_exp_txp pci_exp_txp();
  
    //
    // Import the wires as Bluespec methods
    //
        
    // CSR access methods
        
    method csr_read_req(csr_in_rd_index)
                      ready(csr_out_rd_ready)
                      enable(csr_in_rd_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);

    method csr_out_rd_data csr_read_resp()
                      ready(csr_out_rd_done)
                      enable(csr_in_rd_ack)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);

    method csr_write(csr_in_wr_index, csr_in_wr_data)
                      ready(csr_out_wr_ready)
                      enable(csr_in_wr_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);

    method csr_out_h2f_reg0 csr_h2f_reg0_read() clocked_by(pcie_clk);

    method csr_f2h_reg0_write(csr_in_f2h_reg0)
                      enable(csr_in_f2h_reg0_wr_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);
        
    // DMA
        
    method dma_read_start(dma_in_h2f_paddr, dma_in_h2f_len)
                      ready(dma_out_h2f_ready)
                      enable(dma_in_h2f_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);
/*        
    method dma_read_data_req()
                      ready(dma_out_h2f_fifo_notempty)
                      enable(dma_in_h2f_fifo_ack)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);
*/        
    method dma_out_h2f_fifo_data dma_read_data()
                      ready(dma_out_h2f_fifo_ready)
                      enable(dma_in_h2f_fifo_ack)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);
        
    method dma_write_start(dma_in_f2h_paddr, dma_in_f2h_len)
                      ready(dma_out_f2h_ready)
                      enable(dma_in_f2h_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);
        
    method dma_write_data(dma_in_f2h_fifo_data)
                      ready(dma_out_f2h_fifo_ready)
                      enable(dma_in_f2h_fifo_data_valid)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);
        
    // Interrupts
        
    method  interrupt_host()
                      ready(int_out_ready)
                      enable(int_in_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);
        
    // Reset / Init methods
        
    method reset_req()
                      ready(rst_softrst_req_rdy)
                      enable(rst_softrst_req_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);
        
    method reset_resp()
                      ready(rst_softrst_resp_rdy)
                      enable(rst_softrst_resp_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);
        
    method init_req()
                      ready(rst_init_req_rdy)
                      enable(rst_init_req_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);

    method init_resp()
                      ready(rst_init_resp_rdy)
                      enable(rst_init_resp_en)
                      clocked_by(pcie_clk)
                      reset_by(pcie_rst);

    // Methods are assumed to Conflict unless we tell Bluespec otherwise.

    // csr_read_req
    // C with csr_write
    // SBR with itself (testing)
    // CF with everything else (except itself).
    schedule csr_read_req C    (csr_write);
    schedule csr_read_req SBR  (csr_read_req);
    schedule csr_read_req CF   (csr_read_resp,
                                csr_h2f_reg0_read,
                                csr_f2h_reg0_write,
                                dma_read_start,
                                // dma_read_data_req,
                                dma_read_data,
                                dma_write_start,
                                dma_write_data,
                                interrupt_host,
                                reset_req,
                                reset_resp,
                                init_req,
                                init_resp,
                                pci_exp_rxn,
                                pci_exp_rxp,
                                pci_exp_txn,
                                pci_exp_txp,
                                sys_clk_p,
                                sys_clk_n,
                                sys_reset_n);

    // csr_read_resp
    // C with csr_write
    // SBR with itself (testing)
    // CF with everything else (except itself).
    schedule csr_read_resp C   (csr_write);
    schedule csr_read_resp SBR (csr_read_resp);
    schedule csr_read_resp CF  (csr_h2f_reg0_read,
                                csr_f2h_reg0_write,
                                dma_read_start,
                                // dma_read_data_req,
                                dma_read_data,
                                dma_write_start,
                                dma_write_data,
                                interrupt_host,
                                reset_req,
                                reset_resp,
                                init_req,
                                init_resp,
                                pci_exp_rxn,
                                pci_exp_rxp,
                                pci_exp_txn,
                                pci_exp_txp,
                                sys_clk_p,
                                sys_clk_n,
                                sys_reset_n);

    // csr_write
    // SBR with itself (A time-honored Bluespec convention)
    // CF with everything else (except itself)
    schedule csr_write SBR     (csr_write);
    schedule csr_write CF      (csr_h2f_reg0_read,
                                csr_f2h_reg0_write,
                                dma_read_start,
                                // dma_read_data_req,
                                dma_read_data,
                                dma_write_start,
                                dma_write_data,
                                interrupt_host,
                                reset_req,
                                reset_resp,
                                init_req,
                                init_resp,
                                pci_exp_rxn,
                                pci_exp_rxp,
                                pci_exp_txn,
                                pci_exp_txp,
                                sys_clk_p,
                                sys_clk_n,
                                sys_reset_n);

    // csr_h2f_reg0_read
    // CF with everything (EXPLICITLY including itself)
    schedule csr_h2f_reg0_read CF   (csr_h2f_reg0_read,
                                     csr_f2h_reg0_write,
                                     dma_read_start,
                                     // dma_read_data_req,
                                     dma_read_data,
                                     dma_write_start,
                                     dma_write_data,
                                     interrupt_host,
                                     reset_req,
                                     reset_resp,
                                     init_req,
                                     init_resp,
                                     pci_exp_rxn,
                                     pci_exp_rxp,
                                     pci_exp_txn,
                                     pci_exp_txp,
                                     sys_clk_p,
                                     sys_clk_n,
                                     sys_reset_n);

    // csr_f2h_reg0_write
    // SBR with itself (A time-honored Bluespec convention)
    // CF with everything else (except itself)
    schedule csr_f2h_reg0_write SBR (csr_f2h_reg0_write);
    schedule csr_f2h_reg0_write CF  (dma_read_start,
                                     // dma_read_data_req,
                                     dma_read_data,
                                     dma_write_start,
                                     dma_write_data,
                                     interrupt_host,
                                     reset_req,
                                     reset_resp,
                                     init_req,
                                     init_resp,
                                     pci_exp_rxn,
                                     pci_exp_rxp,
                                     pci_exp_txn,
                                     pci_exp_txp,
                                     sys_clk_p,
                                     sys_clk_n,
                                     sys_reset_n);
        
    // dma_read_start
    // SBR with itself (testing)
    // CF with everything else (except itself)
    schedule dma_read_start SBR  (dma_read_start);
    schedule dma_read_start CF   (// dma_read_data_req,
                                  dma_read_data,
                                  dma_write_start,
                                  dma_write_data,
                                  interrupt_host,
                                  reset_req,
                                  reset_resp,
                                  init_req,
                                  init_resp,
                                  pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);
/*
    // dma_read_data_req
    // SBR with itself (testing)
    // CF with everything else (except itself)
    schedule dma_read_data_req SBR (dma_read_data_req);
    schedule dma_read_data_req CF  (dma_read_data,
                                    dma_write_start,
                                    dma_write_data,
                                    interrupt_host,
                                    reset_req,
                                    reset_resp,
                                    init_req,
                                    init_resp,
                                    pci_exp_rxn,
                                    pci_exp_rxp,
                                    pci_exp_txn,
                                    pci_exp_txp,
                                    sys_clk_p,
                                    sys_clk_n,
                                    sys_reset_n);
      
    // dma_read_data
    // CF with everything (including itself)
    schedule dma_read_data CF    (dma_read_data,
                                  dma_write_start,
                                  dma_write_data,
                                  interrupt_host,
                                  reset_req,
                                  reset_resp,
                                  init_req,
                                  init_resp,
                                  pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);
*/
 
    // dma_read_data
    // SBR with itself (testing)
    // CF with everything else (except itself)
    schedule dma_read_data SBR   (dma_read_data);
    schedule dma_read_data CF    (dma_write_start,
                                  dma_write_data,
                                  interrupt_host,
                                  reset_req,
                                  reset_resp,
                                  init_req,
                                  init_resp,
                                  pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);
        
    // dma_write_start
    // SBR with itself (testing)
    // CF with everything else (except itself)
    schedule dma_write_start SBR (dma_write_start);
    schedule dma_write_start CF  (dma_write_data,
                                  interrupt_host,
                                  reset_req,
                                  reset_resp,
                                  init_req,
                                  init_resp,
                                  pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);

    // dma_write_data
    // SBR with itself (A time-honored Bluespec convention)
    // CF with everything else (except itself)
    schedule dma_write_data SBR  (dma_write_data);
    schedule dma_write_data CF   (interrupt_host,
                                  reset_req,
                                  reset_resp,
                                  init_req,
                                  init_resp,
                                  pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);

    // interrupt_host
    // SBR with itself
    // CF with everyting (except itself)
    schedule interrupt_host SBR  (interrupt_host);
    schedule interrupt_host CF   (reset_req,
                                  reset_resp,
                                  init_req,
                                  init_resp,
                                  pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);

    // reset_req
    // SBR with itself (testing)
    // CF with everything else (except itself)
    schedule reset_req SBR       (reset_req);
    schedule reset_req CF        (reset_resp,
                                  init_req,
                                  init_resp,
                                  pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);

    // reset_resp
    // SBR with itself (testing)
    // CF with everything else (except itself)
    schedule reset_resp SBR      (reset_resp);
    schedule reset_resp CF       (init_req,
                                  init_resp,
                                  pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);

    // init_req
    // SBR with itself (testing)
    // CF with everything else (except itself)
    schedule init_req SBR        (init_req);
    schedule init_req CF         (init_resp,
                                  pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);

    // init_resp
    // SBR with itself (testing)
    // CF with everything else (except itself)
    schedule init_resp SBR       (init_resp);
    schedule init_resp CF        (pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);

    // pci_exp_*
    // CF with everything (EXPLICITLY including themselves)
    schedule pci_exp_rxn CF      (pci_exp_rxn,
                                  pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);
        
    schedule pci_exp_rxp CF      (pci_exp_rxp,
                                  pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);

    schedule pci_exp_txn CF      (pci_exp_txn,
                                  pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);

    schedule pci_exp_txp CF      (pci_exp_txp,
                                  sys_clk_p,
                                  sys_clk_n,
                                  sys_reset_n);
        
endmodule
