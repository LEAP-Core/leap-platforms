typedef enum {
	      WRITE = 0,
	      READ  = 1,
	      VOID  = 7  // unused
	      } DDR2Command deriving(Bits, Eq);

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
   (* always_ready, always_enabled, prefix="", result="initDone" *)
    method Bit#(1) initDone();

   // request interface
   (* always_ready, always_enabled, prefix="", result="addrReq" *)
   method Action addrReq(Bit#(1) addrReqIn);

   (* always_ready, always_enabled, prefix="", result="addrAck" *)
   method Bit#(1) addrAck();

   (* always_ready, always_enabled, prefix="", result="addr" *)
   method Action addr(Bit#(32) addrIn);

   (* always_ready, always_enabled, prefix="", result="rnw" *)
   method Action rnw(Bit#(1) rnwIn);

   (* always_ready, always_enabled, prefix="", result="size" *)
   method Action size(Bit#(4) sizeIn);

   (* always_ready, always_enabled, prefix="", result="rdModWr" *)
   method Action rdModWr(Bit#(1) rdModWrIn);

   // read FIFO interface
   (* always_ready, always_enabled, prefix="", result="rdFIFO_Empty" *)
   method Bit#(1) rdFIFO_Empty();

  (* always_ready, always_enabled, prefix="", result="rdFIFO_Pop" *)
  method Action rdFIFO_Pop(Bit#(1) rdFIFO_PopIn);

  (* always_ready, always_enabled, prefix="", result="rdFIFO_Flush" *)
  method Action rdFIFO_Flush(Bit#(1) rdFIFO_FlushIn);

  (* always_ready, always_enabled, prefix="", result="rdFIFO_Latency" *)
  method Bit#(2) rdFIFO_Latency();

  (* always_ready, always_enabled, prefix="", result="rdFIFO_Data" *)
  method Bit#(64) rdFIFO_Data();

  (* always_ready, always_enabled, prefix="", result="rdFIFO_RdWdAddr" *)
  method Bit#(4) rdFIFO_RdWdAddr();

  // write FIFO interface
  (* always_ready, always_enabled, prefix="", result="wrFIFO_Empty" *)
  method Bit#(1) wrFIFO_Empty();

  (* always_ready, always_enabled, prefix="", result="wrFIFO_AlmostFull" *)
  method Bit#(1) wrFIFO_AlmostFull();

  (* always_ready, always_enabled, prefix="", result="wrFIFO_Push" *)
  method Action wrFIFO_Push(Bit#(1) wrFIFO_PushIn);

  (* always_ready, always_enabled, prefix="", result="wrFIFO_Flush" *)
  method Action wrFIFO_Flush(Bit#(1) wrFIFO_FlushIn);

  (* always_ready, always_enabled, prefix="", result="wrFIFO_Data" *)
  method Action wrFIFO_Data(Bit#(64) wrFIFO_DataIn);

  (* always_ready, always_enabled, prefix="", result="wrFIFO_BE" *)
  method Action wrFIFO_BE(Bit#(8) wrFIFO_BEIn);
   
       
endinterface

// I need to think about the reset signal
import "BVI" ddr_sdram =
module mkXilinxMPMCDDRDRAMController#(Clock bsv_clk100,
                                      Reset bsv_rst100)

    // interface:
        (XILINX_MPMC_DDR_DRAM_CONTROLLER);
    
    default_clock no_clock;
    default_reset no_reset;
    
    // default_clock clk();                          // huh?
    // default_reset rst(sys_rst_n) clocked_by(clk); // huh?
    
    input_clock   (sys_clk_pin)      = bsv_clk100;
    
    input_reset   (DDR_SDRAM_MPMC_Rst_pin) clocked_by  (bsv_clk100) = bsv_rst100;
    
    method fpga_0_DDR_SDRAM_DDR_Clk_pin             ck_p;
    method fpga_0_DDR_SDRAM_DDR_Clk_n_pin           ck_n;
    method fpga_0_DDR_SDRAM_DDR_Addr_pin            a;
    method fpga_0_DDR_SDRAM_DDR_BankAddr_pin        ba;
    method fpga_0_DDR_SDRAM_DDR_RAS_n_pin           ras_n;
    method fpga_0_DDR_SDRAM_DDR_CAS_n_pin           cas_n;
    method fpga_0_DDR_SDRAM_DDR_WE_n_pin            we_n;
    method fpga_0_DDR_SDRAM_DDR_CS_n_pin            cs_n;
    method fpga_0_DDR_SDRAM_DDR_CE_pin              ce;
    method fpga_0_DDR_SDRAM_DDR_DM_pin              dm;
    ifc_inout                   dq(fpga_0_DDR_SDRAM_DDR_DQ);
    ifc_inout                   dqs(fpga_0_DDR_SDRAM_DDR_DQS);      

    //method phy_init_done        init_done clocked_by (bsv_clk100) reset_by (bsv_rst100);
        
    //method                      enqueue_address(app_af_cmd, app_af_addr) enable(app_af_wren) ready(app_af_afull_n) clocked_by (clk_out) reset_by (rst_out);
    //method                      enqueue_data(app_wdf_data, app_wdf_mask_data) enable(app_wdf_wren) ready(app_wdf_afull_n) clocked_by (clk_out) reset_by (rst_out);
    //method rd_data_fifo_out     dequeue_data ready(rd_data_valid) clocked_by (clk_out) reset_by (rst_out);
              
    method DDR_SDRAM_PIM0_InitDone_pin initDone() clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method addrReq(DDR_SDRAM_PIM0_AddrReq_pin) enable(addrReqDummyEn) clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method DDR_SDRAM_PIM0_AddrAck_pin addrAck() clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method addr(DDR_SDRAM_PIM0_Addr_pin) enable(addrDummyEn) clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method rnw(DDR_SDRAM_PIM0_RNW_pin) enable(rnwDummyEn) clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method size(DDR_SDRAM_PIM0_Size_pin) enable(sizeDummyEn) clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method rdModWr(DDR_SDRAM_PIM0_RdModWr_pin) enable(rdModWrDummyEn) clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method DDR_SDRAM_PIM0_RdFIFO_Empty_pin rdFIFO_Empty() clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method rdFIFO_Pop(DDR_SDRAM_PIM0_RdFIFO_Pop_pin) enable(rdFIFO_PopDummyEn) clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method rdFIFO_Flush(DDR_SDRAM_PIM0_WrFIFO_Flush_pin) enable(rdFIFO_FlushDummyEn)  clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method DDR_SDRAM_PIM0_RdFIFO_Latency_pin rdFIFO_Latency() clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method DDR_SDRAM_PIM0_RdFIFO_Data_pin rdFIFO_Data() clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method DDR_SDRAM_PIM0_RdFIFO_RdWdAddr_pin rdFIFO_RdWdAddr() clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method DDR_SDRAM_PIM0_WrFIFO_Empty_pin wrFIFO_Empty() clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method DDR_SDRAM_PIM0_WrFIFO_AlmostFull_pin wrFIFO_AlmostFull() clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method wrFIFO_Push(DDR_SDRAM_PIM0_WrFIFO_Push_pin) enable(wrFIFO_PushDummyEn)  clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method wrFIFO_Flush(DDR_SDRAM_PIM0_RdFIFO_Flush_pin) enable(wrFIFO_FlushDummyEn) clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method wrFIFO_Data(DDR_SDRAM_PIM0_WrFIFO_Data_pin) enable(wrFIFO_DataDummyEn) clocked_by (bsv_clk100) reset_by (bsv_rst100);

    method wrFIFO_BE(DDR_SDRAM_PIM0_WrFIFO_BE_pin) enable(wrFIFO_BEDummyEn) clocked_by (bsv_clk100) reset_by (bsv_rst100);

       
    schedule (ck_p, ck_n, a, ba, ras_n, cas_n, we_n, cs_n, ce, dm, initDone, 
              addrReq, addrAck, addr, rnw, size, rdModWr, rdFIFO_Empty, rdFIFO_Pop, 
              rdFIFO_Flush, rdFIFO_Latency, rdFIFO_Data, rdFIFO_RdWdAddr, wrFIFO_Empty,
              wrFIFO_AlmostFull, wrFIFO_Push, wrFIFO_Flush, wrFIFO_Data, wrFIFO_BE) CF
             (ck_p, ck_n, a, ba, ras_n, cas_n, we_n, cs_n, ce, dm, initDone,
              addrReq, addrAck, addr, rnw, size, rdModWr, rdFIFO_Empty, rdFIFO_Pop, 
              rdFIFO_Flush, rdFIFO_Latency, rdFIFO_Data, rdFIFO_RdWdAddr, wrFIFO_Empty,
              wrFIFO_AlmostFull, wrFIFO_Push, wrFIFO_Flush, wrFIFO_Data, wrFIFO_BE);
   
endmodule
