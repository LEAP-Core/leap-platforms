import Vector::*;
import Clocks::*;
import LevelFIFO::*;

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
        
    // soft reset
    method Action soft_reset();
    
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

module mkPCIExpressDevice
    // interface:
                 (PCI_EXPRESS_DEVICE);

    // Instantiate the primitive device.

    PRIMITIVE_PCI_EXPRESS_DEVICE prim_pci <- mkPrimitivePCIExpressDevice();

    Clock bsv_clk <- exposeCurrentClock();
    Reset bsv_rst <- exposeCurrentReset();
    
    // translate our reset (bst_rst) to the PCIe clock domain. Note that this is
    // different from the PCIe's native reset.
    Reset trans_rst <- mkAsyncResetFromCR(0, prim_pci.pcie_clk);
    
    // Device state
    Reg#(PCIE_DEVICE_STATE) state <- mkReg(PCIE_DEVICE_STATE_init);
    
    // Device is ready only in a particular state
    Bool ready = (state == PCIE_DEVICE_STATE_ready);

    // Synchronizers from PCIE to Bluespec.    
    Reg#(PCIE_CSR_Data)          sync_csr_h2f_reg0_read_r
                              <- mkSyncReg(?, prim_pci.pcie_clk, trans_rst, bsv_clk);
    
    SyncFIFOIfc#(PCIE_CSR_Data)  sync_csr_read_resp_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, trans_rst, bsv_clk);

    SyncFIFOIfc#(Bool)           sync_reset_req_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, trans_rst, bsv_clk);
    
    SyncFIFOIfc#(Bool)           sync_init_resp_q
                              <- mkSyncFIFO(2, prim_pci.pcie_clk, trans_rst, bsv_clk);

    // Synchronizers from BSV to PCIe
    SyncFIFOIfc#(PCIE_CSR_Index) sync_csr_read_req_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOLevelIfc#(Tuple2#(PCIE_CSR_Index, PCIE_CSR_Data), 2) sync_csr_write_q
                              <- mkSyncFIFOLevel(bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOIfc#(PCIE_CSR_Data)  sync_csr_f2h_reg0_write_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOIfc#(Bool)           sync_interrupt_host_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);
    
    SyncFIFOIfc#(Bool)           sync_reset_resp_q
                              <- mkSyncFIFO(2, bsv_clk, bsv_rst, prim_pci.pcie_clk);

    SyncFIFOIfc#(Bool)           sync_init_req_q
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
    
    interface PCI_EXPRESS_DRIVER driver;

        method csr_h2f_reg0_read = sync_csr_h2f_reg0_read_r;
        
        method ActionValue#(PCIE_CSR_Data) csr_read_resp() if (ready);

            sync_csr_read_resp_q.deq();
            return sync_csr_read_resp_q.first();

        endmethod
        
        method Action csr_read_req(PCIE_CSR_Index idx) if (ready);

            sync_csr_read_req_q.enq(idx);

        endmethod

        method Action csr_write(PCIE_CSR_Index idx, PCIE_CSR_Data d) if (ready);

            sync_csr_write_q.enq(tuple2(idx, d));

        endmethod

        method Action csr_f2h_reg0_write(PCIE_CSR_Data d) if (ready);

            sync_csr_f2h_reg0_write_q.enq(d);

        endmethod

        method Action interrupt_host() if (ready);

            sync_interrupt_host_q.enq(?);

        endmethod

        // Reset interface

        method Action soft_reset() if (ready);

            sync_reset_req_q.deq();
            
        endmethod

    endinterface

endmodule


// mkPCIExpressDeviceDisabled

// An empty version of the PCI Device for configurations which do not use PCIE.

module mkPCIExpressDeviceDisabled (PCI_EXPRESS_DEVICE);

  return ?;
  
endmodule
