

interface XILINX_MPMC_DDR_DRAM_CONTROLLER;
    
    // wires
    method    Bit#(3)           ck_p;
    method    Bit#(3)           ck_n;
    method    Bit#(13)          a;
    method    Bit#(2)           ba;
    method    Bit#(1)           ras_n;
    method    Bit#(1)           cas_n;
    method    Bit#(1)           we_n;
    method    Bit#(1)           cs_n;
    method    Bit#(1)           ce;
    method    Bit#(8)           dm;
    interface Inout#(Bit#(64))  dq;
    interface Inout#(Bit#(8))   dqs;
        
    // application interface
   (* always_ready, always_enabled *)
    method Bit#(1) initDone();

   // request interface
   (* always_ready, always_enabled *)
   method Action addrReq(Bit#(1) addrReqIn);

   (* always_ready, always_enabled *)
   method Bit#(1) addrAck();

   (* always_ready, always_enabled *)
   method Action addr(Bit#(32) addrIn);

   (* always_ready, always_enabled *)
   method Action rnw(Bit#(1) rnwIn);

   (* always_ready, always_enabled *)
   method Action size(Bit#(4) sizeIn);

   (* always_ready, always_enabled *)
   method Action rdModWr(Bit#(1) rdModWrIn);

   // read FIFO interface
   (* always_ready, always_enabled *)
   method Bit#(1) rdFIFO_Empty();

  (* always_ready, always_enabled *)
  method Action rdFIFO_Pop(Bit#(1) rdFIFO_PopIn);

  (* always_ready, always_enabled *)
  method Action rdFIFO_Flush(Bit#(1) rdFIFO_FlushIn);

  (* always_ready, always_enabled *)
  method Bit#(2) rdFIFO_Latency();

  (* always_ready, always_enabled *)
  method Bit#(64) rdFIFO_Data();

  (* always_ready, always_enabled *)
  method Bit#(4) rdFIFO_RdWdAddr();

  // write FIFO interface
  (* always_ready, always_enabled *)
  method Bit#(1) wrFIFO_Empty();

  (* always_ready, always_enabled *)
  method Bit#(1) wrFIFO_AlmostFull();

  (* always_ready, always_enabled *)
  method Action wrFIFO_Push(Bit#(1) wrFIFO_PushIn);

  (* always_ready, always_enabled *)
  method Action wrFIFO_Flush(Bit#(1) wrFIFO_FlushIn);

  (* always_ready, always_enabled *)
  method Action wrFIFO_Data(Bit#(64) wrFIFO_DataIn);

  (* always_ready, always_enabled *)
  method Action wrFIFO_BE(Bit#(8) wrFIFO_BEIn);
   
  interface Clock controller_clk;
  interface Reset controller_rst;
       
endinterface

// I need to think about the reset signal
import "BVI" ddr_sdram =
module mkXilinxMPMCDDRDRAMController    

    // interface:
        (XILINX_MPMC_DDR_DRAM_CONTROLLER);
    default_clock clk(sys_clk_pin);
    default_reset rst(sys_rst_pin);    

    
    output_clock controller_clk(controller_clk_pin);
    output_reset controller_rst(controller_rst_pin) clocked_by (controller_clk);


    method fpga_0_DDR_SDRAM_DDR_Clk_pin             ck_p clocked_by(no_clock) reset_by(no_reset);
    method fpga_0_DDR_SDRAM_DDR_Clk_n_pin           ck_n clocked_by(no_clock) reset_by(no_reset);
    method fpga_0_DDR_SDRAM_DDR_Addr_pin            a clocked_by(no_clock) reset_by(no_reset);
    method fpga_0_DDR_SDRAM_DDR_BankAddr_pin        ba clocked_by(no_clock) reset_by(no_reset);
    method fpga_0_DDR_SDRAM_DDR_RAS_n_pin           ras_n clocked_by(no_clock) reset_by(no_reset);
    method fpga_0_DDR_SDRAM_DDR_CAS_n_pin           cas_n clocked_by(no_clock) reset_by(no_reset);
    method fpga_0_DDR_SDRAM_DDR_WE_n_pin            we_n clocked_by(no_clock) reset_by(no_reset);
    method fpga_0_DDR_SDRAM_DDR_CS_n_pin            cs_n clocked_by(no_clock) reset_by(no_reset);
    method fpga_0_DDR_SDRAM_DDR_CE_pin              ce clocked_by(no_clock) reset_by(no_reset);
    method fpga_0_DDR_SDRAM_DDR_DM_pin              dm clocked_by(no_clock) reset_by(no_reset);
    ifc_inout                   dq(fpga_0_DDR_SDRAM_DDR_DQ) clocked_by(no_clock) reset_by(no_reset);
    ifc_inout                   dqs(fpga_0_DDR_SDRAM_DDR_DQS) clocked_by(no_clock) reset_by(no_reset);      

    method DDR_SDRAM_PIM0_InitDone_pin initDone() clocked_by (controller_clk) reset_by (controller_rst);

    method addrReq(DDR_SDRAM_PIM0_AddrReq_pin) enable(addrReqDummyEn) clocked_by (controller_clk) reset_by (controller_rst);

    method DDR_SDRAM_PIM0_AddrAck_pin addrAck() clocked_by (controller_clk) reset_by (controller_rst);

    method addr(DDR_SDRAM_PIM0_Addr_pin) enable(addrDummyEn) clocked_by (controller_clk) reset_by (controller_rst);

    method rnw(DDR_SDRAM_PIM0_RNW_pin) enable(rnwDummyEn) clocked_by (controller_clk) reset_by (controller_rst);

    method size(DDR_SDRAM_PIM0_Size_pin) enable(sizeDummyEn) clocked_by (controller_clk) reset_by (controller_rst);

    method rdModWr(DDR_SDRAM_PIM0_RdModWr_pin) enable(rdModWrDummyEn) clocked_by (controller_clk) reset_by (controller_rst);

    method DDR_SDRAM_PIM0_RdFIFO_Empty_pin rdFIFO_Empty() clocked_by (controller_clk) reset_by (controller_rst);

    method rdFIFO_Pop(DDR_SDRAM_PIM0_RdFIFO_Pop_pin) enable(rdFIFO_PopDummyEn) clocked_by (controller_clk) reset_by (controller_rst);

    method rdFIFO_Flush(DDR_SDRAM_PIM0_RdFIFO_Flush_pin) enable(rdFIFO_FlushDummyEn)  clocked_by (controller_clk) reset_by (controller_rst);

    method DDR_SDRAM_PIM0_RdFIFO_Latency_pin rdFIFO_Latency() clocked_by (controller_clk) reset_by (controller_rst);

    method DDR_SDRAM_PIM0_RdFIFO_Data_pin rdFIFO_Data() clocked_by (controller_clk) reset_by (controller_rst);

    method DDR_SDRAM_PIM0_RdFIFO_RdWdAddr_pin rdFIFO_RdWdAddr() clocked_by (controller_clk) reset_by (controller_rst);

    method DDR_SDRAM_PIM0_WrFIFO_Empty_pin wrFIFO_Empty() clocked_by (controller_clk) reset_by (controller_rst);

    method DDR_SDRAM_PIM0_WrFIFO_AlmostFull_pin wrFIFO_AlmostFull() clocked_by (controller_clk) reset_by (controller_rst);

    method wrFIFO_Push(DDR_SDRAM_PIM0_WrFIFO_Push_pin) enable(wrFIFO_PushDummyEn)  clocked_by (controller_clk) reset_by (controller_rst);

    method wrFIFO_Flush(DDR_SDRAM_PIM0_WrFIFO_Flush_pin) enable(wrFIFO_FlushDummyEn) clocked_by (controller_clk) reset_by (controller_rst);

    method wrFIFO_Data(DDR_SDRAM_PIM0_WrFIFO_Data_pin) enable(wrFIFO_DataDummyEn) clocked_by (controller_clk) reset_by (controller_rst);

    method wrFIFO_BE(DDR_SDRAM_PIM0_WrFIFO_BE_pin) enable(wrFIFO_BEDummyEn) clocked_by (controller_clk) reset_by (controller_rst);


       
    schedule (ck_p, ck_n, a, ba, ras_n, cas_n, we_n, cs_n, ce, dm, initDone, 
              addrReq, addrAck, addr, rnw, size, rdModWr, rdFIFO_Empty, rdFIFO_Pop, 
              rdFIFO_Flush, rdFIFO_Latency, rdFIFO_Data, rdFIFO_RdWdAddr, wrFIFO_Empty,
              wrFIFO_AlmostFull, wrFIFO_Push, wrFIFO_Flush, wrFIFO_Data, wrFIFO_BE) CF
             (ck_p, ck_n, a, ba, ras_n, cas_n, we_n, cs_n, ce, dm, initDone,
              addrReq, addrAck, addr, rnw, size, rdModWr, rdFIFO_Empty, rdFIFO_Pop, 
              rdFIFO_Flush, rdFIFO_Latency, rdFIFO_Data, rdFIFO_RdWdAddr, wrFIFO_Empty,
              wrFIFO_AlmostFull, wrFIFO_Push, wrFIFO_Flush, wrFIFO_Data, wrFIFO_BE);
   
endmodule
