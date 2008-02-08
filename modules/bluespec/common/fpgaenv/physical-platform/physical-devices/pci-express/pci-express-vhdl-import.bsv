
import Clocks::*;

// pci-express-vhdl-import

// Import the VHDL device into BSV

// AWB parameters        default:
// PCIE_PHYS_ADDR_SIZE   64
// PCIE_LEN_SIZE         32
// PCIE_CSR_DATA_SIZE    32
// PCIE_CSR_IDX_SIZE     8


// Datatype definitions

typedef Bit#(`PCIE_PHYS_ADDR_SIZE) PCIE_Physical_Address;
typedef Bit#(`PCIE_LEN_SIZE)       PCIE_Length;
typedef Bit#(`PCIE_CSR_DATA_SIZE)  PCIE_CSR_Data;
typedef Bit#(`PCIE_CSR_IDX_SIZE)   PCIE_CSR_Index;


// PCI_EXPRESS_DRIVER

// The PCIE Platform supports reading and writing data and csrs,
// as well as interrupting the host processor.

interface PCI_EXPRESS_DRIVER;

  // CSR Read
  method Action csr_read_req(PCIE_CSR_Index idx);
  method ActionValue#(PCIE_CSR_Data) csr_read_resp();

  // CSR Write
  method Action csr_write(PCIE_CSR_Index idx, PCIE_CSR_Data data);

  // CSR 0 is special in that we can always access it.
  method PCIE_CSR_Data csr_h2f_reg0_read();
  method Action  csr_f2h_reg0_write(PCIE_CSR_Data data);

  // interrupt
  method Action interrupt_host();

  // DEBUG
  method Bit#(1) read_resp_ready();

endinterface


// PCI_EXPRESS_WIRES

// These are wires which are simply passed up to the toplevel,
// where the UCF file ties them to pins.

interface PCI_EXPRESS_WIRES;

    (* always_enabled, always_ready *)
    method Action sys_clk_p();

    (* always_enabled, always_ready *)
    method Action sys_clk_n();

    (* always_enabled, always_ready *)
    method Action sys_reset_n();

    (* always_enabled, always_ready *)
    method Action pci_exp_rxn((* port="pci_exp_rxn" *) Bit#(4) rxn);

    (* always_enabled, always_ready *)
    method Action pci_exp_rxp((* port="pci_exp_rxp" *) Bit#(4) rxp);

    (* always_ready *)
    (* result="pci_exp_txn" *)
    method Bit#(4) pci_exp_txn();

    (* always_ready *)
    (* result="pci_exp_txp" *)
    method Bit#(4) pci_exp_txp();

endinterface


// PCI_EXPRESS_DEVICE

// By convention a Device is a Driver and a Wires

interface PCI_EXPRESS_DEVICE;

  interface PCI_EXPRESS_DRIVER driver;
  interface PCI_EXPRESS_WIRES  wires;

endinterface

// PRIMITIVE_PCI_EXPRESS_DEVICE

// The primitive vhdl import which we will wrap in clock-domain synchronizers.

interface PRIMITIVE_PCI_EXPRESS_DEVICE;

    // Methods for the Driver

    // CSR Read
    method Action csr_read_req(PCIE_CSR_Index idx);
    method ActionValue#(PCIE_CSR_Data) csr_read_resp();

    // CSR Write
    method Action csr_write(PCIE_CSR_Index idx, PCIE_CSR_Data data);

    // CSR 0 is special in that we can always access it.
    method PCIE_CSR_Data csr_h2f_reg0_read();
    method Action  csr_f2h_reg0_write(PCIE_CSR_Data data);

    // interrupt
    method Action interrupt_host();

    // DEBUG
    method Bit#(1) read_resp_ready();
    
    // Wires to be sent to the top level.

    (* always_enabled, always_ready *)
    method Action sys_clk_p();

    (* always_enabled, always_ready *)
    method Action sys_clk_n();

    (* always_enabled, always_ready *)
    method Action sys_reset_n();

    (* always_enabled, always_ready *)
    method Action pci_exp_rxn((* port="pci_exp_rxn" *) Bit#(4) rxn);

    (* always_enabled, always_ready *)
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

// mkPCIExpressDevice

// Take the primitive PCI Express import and cross the clock domains into the default bluespec domain.

module mkPCIExpressDevice
    // interface:
                 (PCI_EXPRESS_DEVICE);

    // Instantiate the primitive device.

    PRIMITIVE_PCI_EXPRESS_DEVICE prim_pci <- mkPrimitivePCIExpressDevice();

    Clock bsv_clk <- exposeCurrentClock();
    Reset bsv_rst <- exposeCurrentReset();

    // Synchronizers from PCIE to Bluespec.    
    Reg#(PCIE_CSR_Data) sync_csr_h2f_reg0_read_r <- mkSyncReg(?, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);
    SyncFIFOIfc#(PCIE_CSR_Data) sync_csr_read_resp_q     <- mkSyncFIFO(2, prim_pci.pcie_clk, prim_pci.pcie_rst, bsv_clk);
    
    // Synchronizers from BSV to PCIe
    SyncFIFOIfc#(PCIE_CSR_Index) sync_csr_read_req_q <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);
    SyncFIFOIfc#(Tuple2#(PCIE_CSR_Index, PCIE_CSR_Data)) sync_csr_write_q <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);
    SyncFIFOIfc#(PCIE_CSR_Data) sync_csr_f2h_reg0_write_q <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);
    SyncFIFOIfc#(Bool) sync_interrupt_host_q <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    // Rules for synchronizing from PCIe to Bluespec

    rule sync_csr_h2f_reg0_read (True);
    
        sync_csr_h2f_reg0_read_r <= prim_pci.csr_h2f_reg0_read();

    endrule

    rule sync_csr_read_resp (True);

        let x <- prim_pci.csr_read_resp();
        sync_csr_read_resp_q.enq(x);

    endrule

    // Rules for synchronizing from BSV to PCIe.

    rule sync_csr_read_req (True);

        sync_csr_read_req_q.deq();
        prim_pci.csr_read_req(sync_csr_read_req_q.first());

    endrule

    rule sync_csr_write (True);

        sync_csr_write_q.deq();
        match {.a, .v} = sync_csr_write_q.first();
        prim_pci.csr_write(a, v);

    endrule

    rule sync_csr_f2h_reg0_write (True);

        sync_csr_f2h_reg0_write_q.deq();
        prim_pci.csr_f2h_reg0_write(sync_csr_f2h_reg0_write_q.first());

    endrule

    rule sync_interrupt_host (True);

        sync_interrupt_host_q.deq();
        prim_pci.interrupt_host();

    endrule


    // The wires are not domain-crossed because no one should ever look at them.

    interface PCI_EXPRESS_WIRES wires;
      
        method sys_clk_p = prim_pci.sys_clk_p;

        method sys_clk_n = prim_pci.sys_clk_n;

        method sys_reset_n = prim_pci.sys_reset_n;

        method pci_exp_rxn = prim_pci.pci_exp_rxn;

        method pci_exp_rxp = prim_pci.pci_exp_rxp;

        method pci_exp_txn = prim_pci.pci_exp_txn;

        method pci_exp_txp = prim_pci.pci_exp_txp;
        
    endinterface
    
    interface PCI_EXPRESS_DRIVER driver;

        method csr_h2f_reg0_read = sync_csr_h2f_reg0_read_r;
        
        method ActionValue#(PCIE_CSR_Data) csr_read_resp();

            sync_csr_read_resp_q.deq();
            return sync_csr_read_resp_q.first();

        endmethod
        
        method Action csr_read_req(PCIE_CSR_Index idx);

            sync_csr_read_req_q.enq(idx);

        endmethod

        method Action csr_write(PCIE_CSR_Index idx, PCIE_CSR_Data d);

            sync_csr_write_q.enq(tuple2(idx, d));

        endmethod

        method Action csr_f2h_reg0_write(PCIE_CSR_Data d);

            sync_csr_f2h_reg0_write_q.enq(d);

        endmethod

        method Action interrupt_host();

            sync_interrupt_host_q.enq(?);

        endmethod

        // DEBUG
        method Bit#(1) read_resp_ready();
            return prim_pci.read_resp_ready();
        endmethod

    endinterface

endmodule

// mkPCIPrimitiveExpressDevice

// Straightforward import of the VHDL into Bluespec.

import "BVI" Channel_top = module mkPrimitivePCIExpressDevice
    // interface:
                 (PRIMITIVE_PCI_EXPRESS_DEVICE);

    // Clocks and reset are handled by the UCF for now
    default_clock no_clock;
    default_reset no_reset;

    output_clock pcie_clk(hwchn_clk);

    output_reset pcie_rst(hwchn_rst) clocked_by(pcie_clk);
  
  
    method sys_clk_p() enable(sys_clk_p);

    method sys_clk_n() enable(sys_clk_n);

    method sys_reset_n() enable(sys_reset_n);

    method pci_exp_rxn(pci_exp_rxn) enable ((*inhigh*) EN);

    method pci_exp_rxp(pci_exp_rxp) enable ((*inhigh*) EN2);

    method pci_exp_txn pci_exp_txn();

    method pci_exp_txp pci_exp_txp();
    
  
    // Import the wires as Bluespec methods

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

    method  interrupt_host()
                           ready(int_out_ready)
                           enable(int_in_en)
                           clocked_by(pcie_clk)
                           reset_by(pcie_rst);

    // DEBUG
    method csr_out_rd_done read_resp_ready() clocked_by(no_clock);

    // Methods are assumed to Conflict unless we tell Bluespec otherwise.

    // csr_read_req
    // C with csr_write
    // CF with everything else (except itself).
    schedule csr_read_req C (csr_write);
    schedule csr_read_req CF (csr_read_resp, csr_h2f_reg0_read, csr_f2h_reg0_write, interrupt_host, sys_clk_p, sys_clk_n, sys_reset_n);

    // csr_read_resp
    // C with csr_write
    // CF with everything else (except itself).
    schedule csr_read_resp C (csr_write);
    schedule csr_read_resp CF (csr_read_req, csr_h2f_reg0_read, csr_f2h_reg0_write, interrupt_host, sys_clk_p, sys_clk_n, sys_reset_n);

    // csr_write
    // C with csr_read_req/csr_read_resp (For now. Change this if the line is split).
    // SBR with itself (A time-honored Bluespec convention)
    // CF with everything else.
    schedule csr_write C (csr_read_req, csr_read_resp);
    schedule csr_write SBR (csr_write);
    schedule csr_write CF (csr_h2f_reg0_read, csr_f2h_reg0_write, interrupt_host, sys_clk_p, sys_clk_n, sys_reset_n);

    // csr_h2f_reg0_read
    // CF with everything (EXPLICITLY including itself).
    schedule csr_h2f_reg0_read CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, interrupt_host, sys_clk_p,  sys_clk_n, sys_reset_n);

    // csr_f2h_reg0_write
    // SBR with itself (A time-honored Bluespec convention)
    // CF with everything else.
    schedule csr_f2h_reg0_write SBR csr_f2h_reg0_write;
    schedule csr_f2h_reg0_write CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, interrupt_host, sys_clk_p, sys_clk_n, sys_reset_n);

    // interrupt_host
    // CF with everyting (except itself)
    schedule interrupt_host CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, sys_clk_p, sys_clk_n, sys_reset_n);
  
    // DEBUG
    schedule read_resp_ready CF (read_resp_ready, csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, interrupt_host, sys_clk_p,  sys_clk_n, sys_reset_n);

endmodule

// mkPCIExpressDeviceDisabled

// An empty version of the PCI Device for configurations which do not use PCIE.

module mkPCIExpressDeviceDisabled (PCI_EXPRESS_DEVICE);

  return ?;
  
endmodule
