
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

  // DMA Write

  //method Action start_dma_write(PCIE_Physical_Address pa, PCIE_Length len);
  //method Action dma_write_data(PhysicalData data);

  // DMA Read

  //method Action start_dma_read(PCIE_Physical_Address pa, PCIE_Length len);
  //method ActionValue#(PhysicalData) dma_read_data();

  // CSR Read

  //method Action csr_read_req(PCIE_CSR_Index idx);
  //method ActionValue#(PCIE_CSR_Data) csr_read_resp();

  // CSR Write

  //method Action csr_write(PCIE_CSR_Index idx, PCIE_CSR_Data data);

  // CSR 0 is special in that we can always access it.
  //method PCIE_CSR_Data csr_h2f_reg0_read();
  //method Action  csr_f2h_reg0_write(PCIE_CSR_Data data);

  // Misc.

  method Bit#(1) read_led_switch();
  
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

interface PCI_EXPRESS_DEVICE

  interface PCI_EXPRESS_DRIVER driver;
  interface PCI_EXPRESS_WIRES  wires;

endinterface



// mkPCIExpressDevice

// Straightforward import of the VHDL into Bluespec.

import "BVI" xilinx_pci_exp_ep = module mkPCIExpressDevice
  // interface:
               (PCI_EXPRESS_DEVICE);

  // Clocks and reset are handled by the UCF for now
  default_clock no_clock;
  default_reset no_reset;

  // Import the wires as Bluespec methods

  /*
  method csr_read_req(csr_in_rd_index)
                      ready(csr_out_rd_ready)
                      enable(csr_in_rd_en);

  method csr_out_data csr_read_resp()
                                      ready(csr_out_rd_done)
                                      enable(csr_in_rd_ack);

  method csr_write(csr_in_wr_index, csr_in_wr_data)
                   ready(csr_out_wr_ready)
                   enable(csr_in_wr_en);

  method csr_out_h2f_reg0 csr_h2f_reg0_read();

  method csr_f2h_reg0_write(csr_in_f2h_reg0)
                    enable(csr_in_f2h_reg0_wr_en);

  method start_dma_write(dma_in_f2h_paddr, dma_in_f2h_len)
                         ready(dma_out_f2h_ready) 
                         enable(dma_in_f2h_en);
  
  method  dma_write_data(dma_in_f2h_fifo_data) 
                         ready(dma_out_f2h_fifo_ready) 
                         enable(dma_in_f2h_data_valid);

  method  start_dma_read(dma_in_h2f_paddr, dma_in_h2f_len)
                         ready(dma_out_h2f_ready) 
                         enable(dma_in_h2f_en);

  method  dma_out_h2f_fifo_data dma_read_data()
                         ready(dma_out_h2f_fifo_ready) 
                         enable(dma_in_h2f_fifo_ack);

  method  interrupt_host()
                           ready(int_out_ready)
                           enable(int_in_en);

  // Methods are assumed to Conflict unless we tell Bluespec otherwise.

  // csr_read_req
  // CF with everything (except itself).

  schedule csr_read_req CF (csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, start_dma_write, dma_write_data, start_dma_read, dma_read_data, interrupt_host);

  // csr_read_resp
  // CF with everything (except itself).

  schedule csr_read_resp CF (csr_read_req, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, start_dma_write, dma_write_data, start_dma_read, dma_read_data, interrupt_host);

  // csr_write
  // C with csr_read_req/csr_read_resp (For now. Change this if the line is split).
  // SB with itself (A time-honored Bluespec convention)
  // CF with everything else.
  schedule csr_write C (csr_read_req, csr_read_resp);
  schedule csr_write SB (csr_write);
  schedule csr_write CF (csr_h2f_reg0_read, csr_f2h_reg0_write, start_dma_write, dma_write_data, start_dma_read, dma_read_data, interrupt_host);
  
  // csr_h2f_reg0_read
  // CF with everything (EXPLICITLY including itself).

  schedule csr_h2f_reg0_read CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, start_dma_write, dma_write_data, start_dma_read, dma_read_data, interrupt_host);

  // csr_f2h_reg0_write
  // SB with itself (A time-honored Bluespec convention)
  // CF with everything else.

  schedule csr_f2h_reg0_write SB csr_f2h_reg0_write
  schedule csr_f2h_reg0_write CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, start_dma_write, dma_write_data, start_dma_read, dma_read_data, interrupt_host);

  // start_dma_write
  // CF with everything (except itself).

  schedule start_dma_write CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, dma_write_data, start_dma_read, dma_read_data, interrupt_host);
  
  // dma_write_data
  // CF with everything (except itself)
  
  schedule dma_write_data CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, start_dma_write, start_dma_read, dma_read_data, interrupt_host);

  // start_dma_read
  // CF with everything (except itself)

  schedule start_dma_read CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, start_dma_write, dma_write_data, dma_read_data, interrupt_host);

  // dma_read_data
  // CF with everything (except itself)
  
  schedule dma_read_data CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, start_dma_write, dma_write_data, start_dma_read, interrupt_host);
  
  // interrupt_host
  // CF with everyting (except itself)
  
  schedule interrupt_host CF (csr_read_req, csr_read_resp, csr_write, csr_h2f_reg0_read, csr_f2h_reg0_write, start_dma_write, dma_write_data, start_dma_read, dma_read_data);
  */

  interface PCIE_DEVICE device;

      method led_switch read_led_switch();
  
  endinterface

  interface PCIE_Wires wires;
  

      method sys_clk_p() enable(sys_clk_p);

      method sys_clk_n() enable(sys_clk_n);

      method sys_reset_n() enable(sys_reset_n);

      method pci_exp_rxn(pci_exp_rxn) enable ((*inhigh*) EN);

      method pci_exp_rxp(pci_exp_rxp) enable ((*inhigh*) EN2);

      method pci_exp_txn pci_exp_txn();

      method pci_exp_txp pci_exp_txp();
    
  endinterface
  
endmodule
