//-----------------------------------------------------------------------------
// system.v
//-----------------------------------------------------------------------------

module ddr_sdram_xilinx
  (
    fpga_0_DDR_SDRAM_DDR_Clk_pin,
    fpga_0_DDR_SDRAM_DDR_Clk_n_pin,
    fpga_0_DDR_SDRAM_DDR_Addr_pin,
    fpga_0_DDR_SDRAM_DDR_BankAddr_pin,
    fpga_0_DDR_SDRAM_DDR_CAS_n_pin,
    fpga_0_DDR_SDRAM_DDR_CE_pin,
    fpga_0_DDR_SDRAM_DDR_CS_n_pin,
    fpga_0_DDR_SDRAM_DDR_RAS_n_pin,
    fpga_0_DDR_SDRAM_DDR_WE_n_pin,
    fpga_0_DDR_SDRAM_DDR_DM_pin,
    fpga_0_DDR_SDRAM_DDR_DQS,
    fpga_0_DDR_SDRAM_DDR_DQ,
    fpga_0_net_gnd_pin,
    fpga_0_net_gnd_1_pin,
    fpga_0_net_gnd_2_pin,
    fpga_0_net_gnd_3_pin,
    fpga_0_net_gnd_4_pin,
    fpga_0_net_gnd_5_pin,
    fpga_0_net_gnd_6_pin,
    sys_clk_pin,
    sys_rst_pin,
    clock_generator_0_CLKOUT2_pin,
    proc_sys_reset_0_Peripheral_Reset_pin,
    DDR_SDRAM_PIM0_InitDone_pin,
    DDR_SDRAM_PIM0_RdFIFO_Latency_pin,
    DDR_SDRAM_PIM0_RdFIFO_Flush_pin,
    DDR_SDRAM_PIM0_RdFIFO_Empty_pin,
    DDR_SDRAM_PIM0_WrFIFO_Flush_pin,
    DDR_SDRAM_PIM0_WrFIFO_AlmostFull_pin,
    DDR_SDRAM_PIM0_WrFIFO_Empty_pin,
    DDR_SDRAM_PIM0_RdFIFO_RdWdAddr_pin,
    DDR_SDRAM_PIM0_RdFIFO_Pop_pin,
    DDR_SDRAM_PIM0_RdFIFO_Data_pin,
    DDR_SDRAM_PIM0_WrFIFO_Push_pin,
    DDR_SDRAM_PIM0_WrFIFO_BE_pin,
    DDR_SDRAM_PIM0_WrFIFO_Data_pin,
    DDR_SDRAM_PIM0_RdModWr_pin,
    DDR_SDRAM_PIM0_Size_pin,
    DDR_SDRAM_PIM0_RNW_pin,
    DDR_SDRAM_PIM0_AddrAck_pin,
    DDR_SDRAM_PIM0_AddrReq_pin,
    DDR_SDRAM_PIM0_Addr_pin
  );
  output [2:0] fpga_0_DDR_SDRAM_DDR_Clk_pin;
  output [2:0] fpga_0_DDR_SDRAM_DDR_Clk_n_pin;
  output [12:0] fpga_0_DDR_SDRAM_DDR_Addr_pin;
  output [1:0] fpga_0_DDR_SDRAM_DDR_BankAddr_pin;
  output fpga_0_DDR_SDRAM_DDR_CAS_n_pin;
  output fpga_0_DDR_SDRAM_DDR_CE_pin;
  output fpga_0_DDR_SDRAM_DDR_CS_n_pin;
  output fpga_0_DDR_SDRAM_DDR_RAS_n_pin;
  output fpga_0_DDR_SDRAM_DDR_WE_n_pin;
  output [7:0] fpga_0_DDR_SDRAM_DDR_DM_pin;
  inout [7:0] fpga_0_DDR_SDRAM_DDR_DQS;
  inout [63:0] fpga_0_DDR_SDRAM_DDR_DQ;
  output fpga_0_net_gnd_pin;
  output fpga_0_net_gnd_1_pin;
  output fpga_0_net_gnd_2_pin;
  output fpga_0_net_gnd_3_pin;
  output fpga_0_net_gnd_4_pin;
  output fpga_0_net_gnd_5_pin;
  output fpga_0_net_gnd_6_pin;
  input sys_clk_pin;
  input sys_rst_pin;
  output clock_generator_0_CLKOUT2_pin;
  output [0:0] proc_sys_reset_0_Peripheral_Reset_pin;
  output DDR_SDRAM_PIM0_InitDone_pin;
  output [1:0] DDR_SDRAM_PIM0_RdFIFO_Latency_pin;
  input DDR_SDRAM_PIM0_RdFIFO_Flush_pin;
  output DDR_SDRAM_PIM0_RdFIFO_Empty_pin;
  input DDR_SDRAM_PIM0_WrFIFO_Flush_pin;
  output DDR_SDRAM_PIM0_WrFIFO_AlmostFull_pin;
  output DDR_SDRAM_PIM0_WrFIFO_Empty_pin;
  output [3:0] DDR_SDRAM_PIM0_RdFIFO_RdWdAddr_pin;
  input DDR_SDRAM_PIM0_RdFIFO_Pop_pin;
  output [63:0] DDR_SDRAM_PIM0_RdFIFO_Data_pin;
  input DDR_SDRAM_PIM0_WrFIFO_Push_pin;
  input [7:0] DDR_SDRAM_PIM0_WrFIFO_BE_pin;
  input [63:0] DDR_SDRAM_PIM0_WrFIFO_Data_pin;
  input DDR_SDRAM_PIM0_RdModWr_pin;
  input [3:0] DDR_SDRAM_PIM0_Size_pin;
  input DDR_SDRAM_PIM0_RNW_pin;
  output DDR_SDRAM_PIM0_AddrAck_pin;
  input DDR_SDRAM_PIM0_AddrReq_pin;
  input [31:0] DDR_SDRAM_PIM0_Addr_pin;

  // Internal signals

  wire DDR_SDRAM_MPMC_Clk_Mem;
  wire [31:0] DDR_SDRAM_PIM0_Addr;
  wire DDR_SDRAM_PIM0_AddrAck;
  wire DDR_SDRAM_PIM0_AddrReq;
  wire DDR_SDRAM_PIM0_InitDone;
  wire DDR_SDRAM_PIM0_RNW;
  wire [63:0] DDR_SDRAM_PIM0_RdFIFO_Data;
  wire DDR_SDRAM_PIM0_RdFIFO_Empty;
  wire DDR_SDRAM_PIM0_RdFIFO_Flush;
  wire [1:0] DDR_SDRAM_PIM0_RdFIFO_Latency;
  wire DDR_SDRAM_PIM0_RdFIFO_Pop;
  wire [3:0] DDR_SDRAM_PIM0_RdFIFO_RdWdAddr;
  wire DDR_SDRAM_PIM0_RdModWr;
  wire [3:0] DDR_SDRAM_PIM0_Size;
  wire DDR_SDRAM_PIM0_WrFIFO_AlmostFull;
  wire [7:0] DDR_SDRAM_PIM0_WrFIFO_BE;
  wire [63:0] DDR_SDRAM_PIM0_WrFIFO_Data;
  wire DDR_SDRAM_PIM0_WrFIFO_Empty;
  wire DDR_SDRAM_PIM0_WrFIFO_Flush;
  wire DDR_SDRAM_PIM0_WrFIFO_Push;
  wire DDR_SDRAM_mpmc_clk_90_s;
  wire Dcm_all_locked;
  wire dcm_clk_s;
  wire [12:0] fpga_0_DDR_SDRAM_DDR_Addr;
  wire [1:0] fpga_0_DDR_SDRAM_DDR_BankAddr;
  wire fpga_0_DDR_SDRAM_DDR_CAS_n;
  wire [0:0] fpga_0_DDR_SDRAM_DDR_CE;
  wire [0:0] fpga_0_DDR_SDRAM_DDR_CS_n;
  wire [2:0] fpga_0_DDR_SDRAM_DDR_Clk;
  wire [2:0] fpga_0_DDR_SDRAM_DDR_Clk_n;
  wire [7:0] fpga_0_DDR_SDRAM_DDR_DM;
  wire fpga_0_DDR_SDRAM_DDR_RAS_n;
  wire fpga_0_DDR_SDRAM_DDR_WE_n;
  wire net_gnd0;
  wire [0:0] net_gnd1;
  wire [0:1] net_gnd2;
  wire [0:2] net_gnd3;
  wire [0:3] net_gnd4;
  wire [0:7] net_gnd8;
  wire [0:15] net_gnd16;
  wire [0:31] net_gnd32;
  wire [0:35] net_gnd36;
  wire [0:63] net_gnd64;
  wire [0:127] net_gnd128;
  wire net_vcc0;
  wire [0:3] net_vcc4;
  wire sys_clk_s;
  wire [0:0] sys_periph_reset;
  wire sys_rst_s;

  // Internal assignments

  assign fpga_0_DDR_SDRAM_DDR_Clk_pin = fpga_0_DDR_SDRAM_DDR_Clk;
  assign fpga_0_DDR_SDRAM_DDR_Clk_n_pin = fpga_0_DDR_SDRAM_DDR_Clk_n;
  assign fpga_0_DDR_SDRAM_DDR_Addr_pin = fpga_0_DDR_SDRAM_DDR_Addr;
  assign fpga_0_DDR_SDRAM_DDR_BankAddr_pin = fpga_0_DDR_SDRAM_DDR_BankAddr;
  assign fpga_0_DDR_SDRAM_DDR_CAS_n_pin = fpga_0_DDR_SDRAM_DDR_CAS_n;
  assign fpga_0_DDR_SDRAM_DDR_CE_pin = fpga_0_DDR_SDRAM_DDR_CE[0];
  assign fpga_0_DDR_SDRAM_DDR_CS_n_pin = fpga_0_DDR_SDRAM_DDR_CS_n[0];
  assign fpga_0_DDR_SDRAM_DDR_RAS_n_pin = fpga_0_DDR_SDRAM_DDR_RAS_n;
  assign fpga_0_DDR_SDRAM_DDR_WE_n_pin = fpga_0_DDR_SDRAM_DDR_WE_n;
  assign fpga_0_DDR_SDRAM_DDR_DM_pin = fpga_0_DDR_SDRAM_DDR_DM;
  assign dcm_clk_s = sys_clk_pin;
  assign sys_rst_s = sys_rst_pin;
  assign clock_generator_0_CLKOUT2_pin = sys_clk_s;
  assign proc_sys_reset_0_Peripheral_Reset_pin[0:0] = sys_periph_reset[0:0];
  assign DDR_SDRAM_PIM0_InitDone_pin = DDR_SDRAM_PIM0_InitDone;
  assign DDR_SDRAM_PIM0_RdFIFO_Latency_pin = DDR_SDRAM_PIM0_RdFIFO_Latency;
  assign DDR_SDRAM_PIM0_RdFIFO_Flush = DDR_SDRAM_PIM0_RdFIFO_Flush_pin;
  assign DDR_SDRAM_PIM0_RdFIFO_Empty_pin = DDR_SDRAM_PIM0_RdFIFO_Empty;
  assign DDR_SDRAM_PIM0_WrFIFO_Flush = DDR_SDRAM_PIM0_WrFIFO_Flush_pin;
  assign DDR_SDRAM_PIM0_WrFIFO_AlmostFull_pin = DDR_SDRAM_PIM0_WrFIFO_AlmostFull;
  assign DDR_SDRAM_PIM0_WrFIFO_Empty_pin = DDR_SDRAM_PIM0_WrFIFO_Empty;
  assign DDR_SDRAM_PIM0_RdFIFO_RdWdAddr_pin = DDR_SDRAM_PIM0_RdFIFO_RdWdAddr;
  assign DDR_SDRAM_PIM0_RdFIFO_Pop = DDR_SDRAM_PIM0_RdFIFO_Pop_pin;
  assign DDR_SDRAM_PIM0_RdFIFO_Data_pin = DDR_SDRAM_PIM0_RdFIFO_Data;
  assign DDR_SDRAM_PIM0_WrFIFO_Push = DDR_SDRAM_PIM0_WrFIFO_Push_pin;
  assign DDR_SDRAM_PIM0_WrFIFO_BE = DDR_SDRAM_PIM0_WrFIFO_BE_pin;
  assign DDR_SDRAM_PIM0_WrFIFO_Data = DDR_SDRAM_PIM0_WrFIFO_Data_pin;
  assign DDR_SDRAM_PIM0_RdModWr = DDR_SDRAM_PIM0_RdModWr_pin;
  assign DDR_SDRAM_PIM0_Size = DDR_SDRAM_PIM0_Size_pin;
  assign DDR_SDRAM_PIM0_RNW = DDR_SDRAM_PIM0_RNW_pin;
  assign DDR_SDRAM_PIM0_AddrAck_pin = DDR_SDRAM_PIM0_AddrAck;
  assign DDR_SDRAM_PIM0_AddrReq = DDR_SDRAM_PIM0_AddrReq_pin;
  assign DDR_SDRAM_PIM0_Addr = DDR_SDRAM_PIM0_Addr_pin;
  assign net_gnd0 = 1'b0;
  assign fpga_0_net_gnd_pin = net_gnd0;
  assign fpga_0_net_gnd_1_pin = net_gnd0;
  assign fpga_0_net_gnd_2_pin = net_gnd0;
  assign fpga_0_net_gnd_3_pin = net_gnd0;
  assign fpga_0_net_gnd_4_pin = net_gnd0;
  assign fpga_0_net_gnd_5_pin = net_gnd0;
  assign fpga_0_net_gnd_6_pin = net_gnd0;
  assign net_gnd1[0:0] = 1'b0;
  assign net_gnd128[0:127] = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
  assign net_gnd16[0:15] = 16'b0000000000000000;
  assign net_gnd2[0:1] = 2'b00;
  assign net_gnd3[0:2] = 3'b000;
  assign net_gnd32[0:31] = 32'b00000000000000000000000000000000;
  assign net_gnd36[0:35] = 36'b000000000000000000000000000000000000;
  assign net_gnd4[0:3] = 4'b0000;
  assign net_gnd64[0:63] = 64'b0000000000000000000000000000000000000000000000000000000000000000;
  assign net_gnd8[0:7] = 8'b00000000;
  assign net_vcc0 = 1'b1;
  assign net_vcc4[0:3] = 4'b1111;

  ddr_sdram_wrapper
    DDR_SDRAM (
      .FSL0_M_Clk ( net_vcc0 ),
      .FSL0_M_Write ( net_gnd0 ),
      .FSL0_M_Data ( net_gnd32 ),
      .FSL0_M_Control ( net_gnd0 ),
      .FSL0_M_Full (  ),
      .FSL0_S_Clk ( net_gnd0 ),
      .FSL0_S_Read ( net_gnd0 ),
      .FSL0_S_Data (  ),
      .FSL0_S_Control (  ),
      .FSL0_S_Exists (  ),
      .SPLB0_Clk ( net_vcc0 ),
      .SPLB0_Rst ( net_gnd0 ),
      .SPLB0_PLB_ABus ( net_gnd32 ),
      .SPLB0_PLB_PAValid ( net_gnd0 ),
      .SPLB0_PLB_SAValid ( net_gnd0 ),
      .SPLB0_PLB_masterID ( net_gnd1[0:0] ),
      .SPLB0_PLB_RNW ( net_gnd0 ),
      .SPLB0_PLB_BE ( net_gnd8 ),
      .SPLB0_PLB_UABus ( net_gnd32 ),
      .SPLB0_PLB_rdPrim ( net_gnd0 ),
      .SPLB0_PLB_wrPrim ( net_gnd0 ),
      .SPLB0_PLB_abort ( net_gnd0 ),
      .SPLB0_PLB_busLock ( net_gnd0 ),
      .SPLB0_PLB_MSize ( net_gnd2 ),
      .SPLB0_PLB_size ( net_gnd4 ),
      .SPLB0_PLB_type ( net_gnd3 ),
      .SPLB0_PLB_lockErr ( net_gnd0 ),
      .SPLB0_PLB_wrPendReq ( net_gnd0 ),
      .SPLB0_PLB_wrPendPri ( net_gnd2 ),
      .SPLB0_PLB_rdPendReq ( net_gnd0 ),
      .SPLB0_PLB_rdPendPri ( net_gnd2 ),
      .SPLB0_PLB_reqPri ( net_gnd2 ),
      .SPLB0_PLB_TAttribute ( net_gnd16 ),
      .SPLB0_PLB_rdBurst ( net_gnd0 ),
      .SPLB0_PLB_wrBurst ( net_gnd0 ),
      .SPLB0_PLB_wrDBus ( net_gnd64 ),
      .SPLB0_Sl_addrAck (  ),
      .SPLB0_Sl_SSize (  ),
      .SPLB0_Sl_wait (  ),
      .SPLB0_Sl_rearbitrate (  ),
      .SPLB0_Sl_wrDAck (  ),
      .SPLB0_Sl_wrComp (  ),
      .SPLB0_Sl_wrBTerm (  ),
      .SPLB0_Sl_rdDBus (  ),
      .SPLB0_Sl_rdWdAddr (  ),
      .SPLB0_Sl_rdDAck (  ),
      .SPLB0_Sl_rdComp (  ),
      .SPLB0_Sl_rdBTerm (  ),
      .SPLB0_Sl_MBusy (  ),
      .SPLB0_Sl_MRdErr (  ),
      .SPLB0_Sl_MWrErr (  ),
      .SPLB0_Sl_MIRQ (  ),
      .SDMA0_Clk ( net_gnd0 ),
      .SDMA0_Rx_IntOut (  ),
      .SDMA0_Tx_IntOut (  ),
      .SDMA0_RstOut (  ),
      .SDMA0_TX_D (  ),
      .SDMA0_TX_Rem (  ),
      .SDMA0_TX_SOF (  ),
      .SDMA0_TX_EOF (  ),
      .SDMA0_TX_SOP (  ),
      .SDMA0_TX_EOP (  ),
      .SDMA0_TX_Src_Rdy (  ),
      .SDMA0_TX_Dst_Rdy ( net_vcc0 ),
      .SDMA0_RX_D ( net_gnd32 ),
      .SDMA0_RX_Rem ( net_vcc4 ),
      .SDMA0_RX_SOF ( net_vcc0 ),
      .SDMA0_RX_EOF ( net_vcc0 ),
      .SDMA0_RX_SOP ( net_vcc0 ),
      .SDMA0_RX_EOP ( net_vcc0 ),
      .SDMA0_RX_Src_Rdy ( net_vcc0 ),
      .SDMA0_RX_Dst_Rdy (  ),
      .SDMA_CTRL0_Clk ( net_vcc0 ),
      .SDMA_CTRL0_Rst ( net_gnd0 ),
      .SDMA_CTRL0_PLB_ABus ( net_gnd32 ),
      .SDMA_CTRL0_PLB_PAValid ( net_gnd0 ),
      .SDMA_CTRL0_PLB_SAValid ( net_gnd0 ),
      .SDMA_CTRL0_PLB_masterID ( net_gnd1[0:0] ),
      .SDMA_CTRL0_PLB_RNW ( net_gnd0 ),
      .SDMA_CTRL0_PLB_BE ( net_gnd8 ),
      .SDMA_CTRL0_PLB_UABus ( net_gnd32 ),
      .SDMA_CTRL0_PLB_rdPrim ( net_gnd0 ),
      .SDMA_CTRL0_PLB_wrPrim ( net_gnd0 ),
      .SDMA_CTRL0_PLB_abort ( net_gnd0 ),
      .SDMA_CTRL0_PLB_busLock ( net_gnd0 ),
      .SDMA_CTRL0_PLB_MSize ( net_gnd2 ),
      .SDMA_CTRL0_PLB_size ( net_gnd4 ),
      .SDMA_CTRL0_PLB_type ( net_gnd3 ),
      .SDMA_CTRL0_PLB_lockErr ( net_gnd0 ),
      .SDMA_CTRL0_PLB_wrPendReq ( net_gnd0 ),
      .SDMA_CTRL0_PLB_wrPendPri ( net_gnd2 ),
      .SDMA_CTRL0_PLB_rdPendReq ( net_gnd0 ),
      .SDMA_CTRL0_PLB_rdPendPri ( net_gnd2 ),
      .SDMA_CTRL0_PLB_reqPri ( net_gnd2 ),
      .SDMA_CTRL0_PLB_TAttribute ( net_gnd16 ),
      .SDMA_CTRL0_PLB_rdBurst ( net_gnd0 ),
      .SDMA_CTRL0_PLB_wrBurst ( net_gnd0 ),
      .SDMA_CTRL0_PLB_wrDBus ( net_gnd64 ),
      .SDMA_CTRL0_Sl_addrAck (  ),
      .SDMA_CTRL0_Sl_SSize (  ),
      .SDMA_CTRL0_Sl_wait (  ),
      .SDMA_CTRL0_Sl_rearbitrate (  ),
      .SDMA_CTRL0_Sl_wrDAck (  ),
      .SDMA_CTRL0_Sl_wrComp (  ),
      .SDMA_CTRL0_Sl_wrBTerm (  ),
      .SDMA_CTRL0_Sl_rdDBus (  ),
      .SDMA_CTRL0_Sl_rdWdAddr (  ),
      .SDMA_CTRL0_Sl_rdDAck (  ),
      .SDMA_CTRL0_Sl_rdComp (  ),
      .SDMA_CTRL0_Sl_rdBTerm (  ),
      .SDMA_CTRL0_Sl_MBusy (  ),
      .SDMA_CTRL0_Sl_MRdErr (  ),
      .SDMA_CTRL0_Sl_MWrErr (  ),
      .SDMA_CTRL0_Sl_MIRQ (  ),
      .PIM0_Addr ( DDR_SDRAM_PIM0_Addr ),
      .PIM0_AddrReq ( DDR_SDRAM_PIM0_AddrReq ),
      .PIM0_AddrAck ( DDR_SDRAM_PIM0_AddrAck ),
      .PIM0_RNW ( DDR_SDRAM_PIM0_RNW ),
      .PIM0_Size ( DDR_SDRAM_PIM0_Size ),
      .PIM0_RdModWr ( DDR_SDRAM_PIM0_RdModWr ),
      .PIM0_WrFIFO_Data ( DDR_SDRAM_PIM0_WrFIFO_Data ),
      .PIM0_WrFIFO_BE ( DDR_SDRAM_PIM0_WrFIFO_BE ),
      .PIM0_WrFIFO_Push ( DDR_SDRAM_PIM0_WrFIFO_Push ),
      .PIM0_RdFIFO_Data ( DDR_SDRAM_PIM0_RdFIFO_Data ),
      .PIM0_RdFIFO_Pop ( DDR_SDRAM_PIM0_RdFIFO_Pop ),
      .PIM0_RdFIFO_RdWdAddr ( DDR_SDRAM_PIM0_RdFIFO_RdWdAddr ),
      .PIM0_WrFIFO_Empty ( DDR_SDRAM_PIM0_WrFIFO_Empty ),
      .PIM0_WrFIFO_AlmostFull ( DDR_SDRAM_PIM0_WrFIFO_AlmostFull ),
      .PIM0_WrFIFO_Flush ( DDR_SDRAM_PIM0_WrFIFO_Flush ),
      .PIM0_RdFIFO_Empty ( DDR_SDRAM_PIM0_RdFIFO_Empty ),
      .PIM0_RdFIFO_Flush ( DDR_SDRAM_PIM0_RdFIFO_Flush ),
      .PIM0_RdFIFO_Latency ( DDR_SDRAM_PIM0_RdFIFO_Latency ),
      .PIM0_InitDone ( DDR_SDRAM_PIM0_InitDone ),
      .PPC440MC0_MIMCReadNotWrite ( net_gnd0 ),
      .PPC440MC0_MIMCAddress ( net_gnd36 ),
      .PPC440MC0_MIMCAddressValid ( net_gnd0 ),
      .PPC440MC0_MIMCWriteData ( net_gnd128 ),
      .PPC440MC0_MIMCWriteDataValid ( net_gnd0 ),
      .PPC440MC0_MIMCByteEnable ( net_gnd16 ),
      .PPC440MC0_MIMCBankConflict ( net_gnd0 ),
      .PPC440MC0_MIMCRowConflict ( net_gnd0 ),
      .PPC440MC0_MCMIReadData (  ),
      .PPC440MC0_MCMIReadDataValid (  ),
      .PPC440MC0_MCMIReadDataErr (  ),
      .PPC440MC0_MCMIAddrReadyToAccept (  ),
      .VFBC0_Cmd_Clk ( net_gnd0 ),
      .VFBC0_Cmd_Reset ( net_gnd0 ),
      .VFBC0_Cmd_Data ( net_gnd32[0:31] ),
      .VFBC0_Cmd_Write ( net_gnd0 ),
      .VFBC0_Cmd_End ( net_gnd0 ),
      .VFBC0_Cmd_Full (  ),
      .VFBC0_Cmd_Almost_Full (  ),
      .VFBC0_Cmd_Idle (  ),
      .VFBC0_Wd_Clk ( net_gnd0 ),
      .VFBC0_Wd_Reset ( net_gnd0 ),
      .VFBC0_Wd_Write ( net_gnd0 ),
      .VFBC0_Wd_End_Burst ( net_gnd0 ),
      .VFBC0_Wd_Flush ( net_gnd0 ),
      .VFBC0_Wd_Data ( net_gnd32[0:31] ),
      .VFBC0_Wd_Data_BE ( net_gnd4[0:3] ),
      .VFBC0_Wd_Full (  ),
      .VFBC0_Wd_Almost_Full (  ),
      .VFBC0_Rd_Clk ( net_gnd0 ),
      .VFBC0_Rd_Reset ( net_gnd0 ),
      .VFBC0_Rd_Read ( net_gnd0 ),
      .VFBC0_Rd_End_Burst ( net_gnd0 ),
      .VFBC0_Rd_Flush ( net_gnd0 ),
      .VFBC0_Rd_Data (  ),
      .VFBC0_Rd_Empty (  ),
      .VFBC0_Rd_Almost_Empty (  ),
      .FSL1_M_Clk ( net_vcc0 ),
      .FSL1_M_Write ( net_gnd0 ),
      .FSL1_M_Data ( net_gnd32 ),
      .FSL1_M_Control ( net_gnd0 ),
      .FSL1_M_Full (  ),
      .FSL1_S_Clk ( net_gnd0 ),
      .FSL1_S_Read ( net_gnd0 ),
      .FSL1_S_Data (  ),
      .FSL1_S_Control (  ),
      .FSL1_S_Exists (  ),
      .SPLB1_Clk ( net_vcc0 ),
      .SPLB1_Rst ( net_gnd0 ),
      .SPLB1_PLB_ABus ( net_gnd32 ),
      .SPLB1_PLB_PAValid ( net_gnd0 ),
      .SPLB1_PLB_SAValid ( net_gnd0 ),
      .SPLB1_PLB_masterID ( net_gnd1[0:0] ),
      .SPLB1_PLB_RNW ( net_gnd0 ),
      .SPLB1_PLB_BE ( net_gnd8 ),
      .SPLB1_PLB_UABus ( net_gnd32 ),
      .SPLB1_PLB_rdPrim ( net_gnd0 ),
      .SPLB1_PLB_wrPrim ( net_gnd0 ),
      .SPLB1_PLB_abort ( net_gnd0 ),
      .SPLB1_PLB_busLock ( net_gnd0 ),
      .SPLB1_PLB_MSize ( net_gnd2 ),
      .SPLB1_PLB_size ( net_gnd4 ),
      .SPLB1_PLB_type ( net_gnd3 ),
      .SPLB1_PLB_lockErr ( net_gnd0 ),
      .SPLB1_PLB_wrPendReq ( net_gnd0 ),
      .SPLB1_PLB_wrPendPri ( net_gnd2 ),
      .SPLB1_PLB_rdPendReq ( net_gnd0 ),
      .SPLB1_PLB_rdPendPri ( net_gnd2 ),
      .SPLB1_PLB_reqPri ( net_gnd2 ),
      .SPLB1_PLB_TAttribute ( net_gnd16 ),
      .SPLB1_PLB_rdBurst ( net_gnd0 ),
      .SPLB1_PLB_wrBurst ( net_gnd0 ),
      .SPLB1_PLB_wrDBus ( net_gnd64 ),
      .SPLB1_Sl_addrAck (  ),
      .SPLB1_Sl_SSize (  ),
      .SPLB1_Sl_wait (  ),
      .SPLB1_Sl_rearbitrate (  ),
      .SPLB1_Sl_wrDAck (  ),
      .SPLB1_Sl_wrComp (  ),
      .SPLB1_Sl_wrBTerm (  ),
      .SPLB1_Sl_rdDBus (  ),
      .SPLB1_Sl_rdWdAddr (  ),
      .SPLB1_Sl_rdDAck (  ),
      .SPLB1_Sl_rdComp (  ),
      .SPLB1_Sl_rdBTerm (  ),
      .SPLB1_Sl_MBusy (  ),
      .SPLB1_Sl_MRdErr (  ),
      .SPLB1_Sl_MWrErr (  ),
      .SPLB1_Sl_MIRQ (  ),
      .SDMA1_Clk ( net_gnd0 ),
      .SDMA1_Rx_IntOut (  ),
      .SDMA1_Tx_IntOut (  ),
      .SDMA1_RstOut (  ),
      .SDMA1_TX_D (  ),
      .SDMA1_TX_Rem (  ),
      .SDMA1_TX_SOF (  ),
      .SDMA1_TX_EOF (  ),
      .SDMA1_TX_SOP (  ),
      .SDMA1_TX_EOP (  ),
      .SDMA1_TX_Src_Rdy (  ),
      .SDMA1_TX_Dst_Rdy ( net_vcc0 ),
      .SDMA1_RX_D ( net_gnd32 ),
      .SDMA1_RX_Rem ( net_vcc4 ),
      .SDMA1_RX_SOF ( net_vcc0 ),
      .SDMA1_RX_EOF ( net_vcc0 ),
      .SDMA1_RX_SOP ( net_vcc0 ),
      .SDMA1_RX_EOP ( net_vcc0 ),
      .SDMA1_RX_Src_Rdy ( net_vcc0 ),
      .SDMA1_RX_Dst_Rdy (  ),
      .SDMA_CTRL1_Clk ( net_vcc0 ),
      .SDMA_CTRL1_Rst ( net_gnd0 ),
      .SDMA_CTRL1_PLB_ABus ( net_gnd32 ),
      .SDMA_CTRL1_PLB_PAValid ( net_gnd0 ),
      .SDMA_CTRL1_PLB_SAValid ( net_gnd0 ),
      .SDMA_CTRL1_PLB_masterID ( net_gnd1[0:0] ),
      .SDMA_CTRL1_PLB_RNW ( net_gnd0 ),
      .SDMA_CTRL1_PLB_BE ( net_gnd8 ),
      .SDMA_CTRL1_PLB_UABus ( net_gnd32 ),
      .SDMA_CTRL1_PLB_rdPrim ( net_gnd0 ),
      .SDMA_CTRL1_PLB_wrPrim ( net_gnd0 ),
      .SDMA_CTRL1_PLB_abort ( net_gnd0 ),
      .SDMA_CTRL1_PLB_busLock ( net_gnd0 ),
      .SDMA_CTRL1_PLB_MSize ( net_gnd2 ),
      .SDMA_CTRL1_PLB_size ( net_gnd4 ),
      .SDMA_CTRL1_PLB_type ( net_gnd3 ),
      .SDMA_CTRL1_PLB_lockErr ( net_gnd0 ),
      .SDMA_CTRL1_PLB_wrPendReq ( net_gnd0 ),
      .SDMA_CTRL1_PLB_wrPendPri ( net_gnd2 ),
      .SDMA_CTRL1_PLB_rdPendReq ( net_gnd0 ),
      .SDMA_CTRL1_PLB_rdPendPri ( net_gnd2 ),
      .SDMA_CTRL1_PLB_reqPri ( net_gnd2 ),
      .SDMA_CTRL1_PLB_TAttribute ( net_gnd16 ),
      .SDMA_CTRL1_PLB_rdBurst ( net_gnd0 ),
      .SDMA_CTRL1_PLB_wrBurst ( net_gnd0 ),
      .SDMA_CTRL1_PLB_wrDBus ( net_gnd64 ),
      .SDMA_CTRL1_Sl_addrAck (  ),
      .SDMA_CTRL1_Sl_SSize (  ),
      .SDMA_CTRL1_Sl_wait (  ),
      .SDMA_CTRL1_Sl_rearbitrate (  ),
      .SDMA_CTRL1_Sl_wrDAck (  ),
      .SDMA_CTRL1_Sl_wrComp (  ),
      .SDMA_CTRL1_Sl_wrBTerm (  ),
      .SDMA_CTRL1_Sl_rdDBus (  ),
      .SDMA_CTRL1_Sl_rdWdAddr (  ),
      .SDMA_CTRL1_Sl_rdDAck (  ),
      .SDMA_CTRL1_Sl_rdComp (  ),
      .SDMA_CTRL1_Sl_rdBTerm (  ),
      .SDMA_CTRL1_Sl_MBusy (  ),
      .SDMA_CTRL1_Sl_MRdErr (  ),
      .SDMA_CTRL1_Sl_MWrErr (  ),
      .SDMA_CTRL1_Sl_MIRQ (  ),
      .PIM1_Addr ( net_gnd32[0:31] ),
      .PIM1_AddrReq ( net_gnd0 ),
      .PIM1_AddrAck (  ),
      .PIM1_RNW ( net_gnd0 ),
      .PIM1_Size ( net_gnd4[0:3] ),
      .PIM1_RdModWr ( net_gnd0 ),
      .PIM1_WrFIFO_Data ( net_gnd64[0:63] ),
      .PIM1_WrFIFO_BE ( net_gnd8[0:7] ),
      .PIM1_WrFIFO_Push ( net_gnd0 ),
      .PIM1_RdFIFO_Data (  ),
      .PIM1_RdFIFO_Pop ( net_gnd0 ),
      .PIM1_RdFIFO_RdWdAddr (  ),
      .PIM1_WrFIFO_Empty (  ),
      .PIM1_WrFIFO_AlmostFull (  ),
      .PIM1_WrFIFO_Flush ( net_gnd0 ),
      .PIM1_RdFIFO_Empty (  ),
      .PIM1_RdFIFO_Flush ( net_gnd0 ),
      .PIM1_RdFIFO_Latency (  ),
      .PIM1_InitDone (  ),
      .PPC440MC1_MIMCReadNotWrite ( net_gnd0 ),
      .PPC440MC1_MIMCAddress ( net_gnd36 ),
      .PPC440MC1_MIMCAddressValid ( net_gnd0 ),
      .PPC440MC1_MIMCWriteData ( net_gnd128 ),
      .PPC440MC1_MIMCWriteDataValid ( net_gnd0 ),
      .PPC440MC1_MIMCByteEnable ( net_gnd16 ),
      .PPC440MC1_MIMCBankConflict ( net_gnd0 ),
      .PPC440MC1_MIMCRowConflict ( net_gnd0 ),
      .PPC440MC1_MCMIReadData (  ),
      .PPC440MC1_MCMIReadDataValid (  ),
      .PPC440MC1_MCMIReadDataErr (  ),
      .PPC440MC1_MCMIAddrReadyToAccept (  ),
      .VFBC1_Cmd_Clk ( net_gnd0 ),
      .VFBC1_Cmd_Reset ( net_gnd0 ),
      .VFBC1_Cmd_Data ( net_gnd32[0:31] ),
      .VFBC1_Cmd_Write ( net_gnd0 ),
      .VFBC1_Cmd_End ( net_gnd0 ),
      .VFBC1_Cmd_Full (  ),
      .VFBC1_Cmd_Almost_Full (  ),
      .VFBC1_Cmd_Idle (  ),
      .VFBC1_Wd_Clk ( net_gnd0 ),
      .VFBC1_Wd_Reset ( net_gnd0 ),
      .VFBC1_Wd_Write ( net_gnd0 ),
      .VFBC1_Wd_End_Burst ( net_gnd0 ),
      .VFBC1_Wd_Flush ( net_gnd0 ),
      .VFBC1_Wd_Data ( net_gnd32[0:31] ),
      .VFBC1_Wd_Data_BE ( net_gnd4[0:3] ),
      .VFBC1_Wd_Full (  ),
      .VFBC1_Wd_Almost_Full (  ),
      .VFBC1_Rd_Clk ( net_gnd0 ),
      .VFBC1_Rd_Reset ( net_gnd0 ),
      .VFBC1_Rd_Read ( net_gnd0 ),
      .VFBC1_Rd_End_Burst ( net_gnd0 ),
      .VFBC1_Rd_Flush ( net_gnd0 ),
      .VFBC1_Rd_Data (  ),
      .VFBC1_Rd_Empty (  ),
      .VFBC1_Rd_Almost_Empty (  ),
      .FSL2_M_Clk ( net_vcc0 ),
      .FSL2_M_Write ( net_gnd0 ),
      .FSL2_M_Data ( net_gnd32 ),
      .FSL2_M_Control ( net_gnd0 ),
      .FSL2_M_Full (  ),
      .FSL2_S_Clk ( net_gnd0 ),
      .FSL2_S_Read ( net_gnd0 ),
      .FSL2_S_Data (  ),
      .FSL2_S_Control (  ),
      .FSL2_S_Exists (  ),
      .SPLB2_Clk ( net_vcc0 ),
      .SPLB2_Rst ( net_gnd0 ),
      .SPLB2_PLB_ABus ( net_gnd32 ),
      .SPLB2_PLB_PAValid ( net_gnd0 ),
      .SPLB2_PLB_SAValid ( net_gnd0 ),
      .SPLB2_PLB_masterID ( net_gnd1[0:0] ),
      .SPLB2_PLB_RNW ( net_gnd0 ),
      .SPLB2_PLB_BE ( net_gnd8 ),
      .SPLB2_PLB_UABus ( net_gnd32 ),
      .SPLB2_PLB_rdPrim ( net_gnd0 ),
      .SPLB2_PLB_wrPrim ( net_gnd0 ),
      .SPLB2_PLB_abort ( net_gnd0 ),
      .SPLB2_PLB_busLock ( net_gnd0 ),
      .SPLB2_PLB_MSize ( net_gnd2 ),
      .SPLB2_PLB_size ( net_gnd4 ),
      .SPLB2_PLB_type ( net_gnd3 ),
      .SPLB2_PLB_lockErr ( net_gnd0 ),
      .SPLB2_PLB_wrPendReq ( net_gnd0 ),
      .SPLB2_PLB_wrPendPri ( net_gnd2 ),
      .SPLB2_PLB_rdPendReq ( net_gnd0 ),
      .SPLB2_PLB_rdPendPri ( net_gnd2 ),
      .SPLB2_PLB_reqPri ( net_gnd2 ),
      .SPLB2_PLB_TAttribute ( net_gnd16 ),
      .SPLB2_PLB_rdBurst ( net_gnd0 ),
      .SPLB2_PLB_wrBurst ( net_gnd0 ),
      .SPLB2_PLB_wrDBus ( net_gnd64 ),
      .SPLB2_Sl_addrAck (  ),
      .SPLB2_Sl_SSize (  ),
      .SPLB2_Sl_wait (  ),
      .SPLB2_Sl_rearbitrate (  ),
      .SPLB2_Sl_wrDAck (  ),
      .SPLB2_Sl_wrComp (  ),
      .SPLB2_Sl_wrBTerm (  ),
      .SPLB2_Sl_rdDBus (  ),
      .SPLB2_Sl_rdWdAddr (  ),
      .SPLB2_Sl_rdDAck (  ),
      .SPLB2_Sl_rdComp (  ),
      .SPLB2_Sl_rdBTerm (  ),
      .SPLB2_Sl_MBusy (  ),
      .SPLB2_Sl_MRdErr (  ),
      .SPLB2_Sl_MWrErr (  ),
      .SPLB2_Sl_MIRQ (  ),
      .SDMA2_Clk ( net_gnd0 ),
      .SDMA2_Rx_IntOut (  ),
      .SDMA2_Tx_IntOut (  ),
      .SDMA2_RstOut (  ),
      .SDMA2_TX_D (  ),
      .SDMA2_TX_Rem (  ),
      .SDMA2_TX_SOF (  ),
      .SDMA2_TX_EOF (  ),
      .SDMA2_TX_SOP (  ),
      .SDMA2_TX_EOP (  ),
      .SDMA2_TX_Src_Rdy (  ),
      .SDMA2_TX_Dst_Rdy ( net_vcc0 ),
      .SDMA2_RX_D ( net_gnd32 ),
      .SDMA2_RX_Rem ( net_vcc4 ),
      .SDMA2_RX_SOF ( net_vcc0 ),
      .SDMA2_RX_EOF ( net_vcc0 ),
      .SDMA2_RX_SOP ( net_vcc0 ),
      .SDMA2_RX_EOP ( net_vcc0 ),
      .SDMA2_RX_Src_Rdy ( net_vcc0 ),
      .SDMA2_RX_Dst_Rdy (  ),
      .SDMA_CTRL2_Clk ( net_vcc0 ),
      .SDMA_CTRL2_Rst ( net_gnd0 ),
      .SDMA_CTRL2_PLB_ABus ( net_gnd32 ),
      .SDMA_CTRL2_PLB_PAValid ( net_gnd0 ),
      .SDMA_CTRL2_PLB_SAValid ( net_gnd0 ),
      .SDMA_CTRL2_PLB_masterID ( net_gnd1[0:0] ),
      .SDMA_CTRL2_PLB_RNW ( net_gnd0 ),
      .SDMA_CTRL2_PLB_BE ( net_gnd8 ),
      .SDMA_CTRL2_PLB_UABus ( net_gnd32 ),
      .SDMA_CTRL2_PLB_rdPrim ( net_gnd0 ),
      .SDMA_CTRL2_PLB_wrPrim ( net_gnd0 ),
      .SDMA_CTRL2_PLB_abort ( net_gnd0 ),
      .SDMA_CTRL2_PLB_busLock ( net_gnd0 ),
      .SDMA_CTRL2_PLB_MSize ( net_gnd2 ),
      .SDMA_CTRL2_PLB_size ( net_gnd4 ),
      .SDMA_CTRL2_PLB_type ( net_gnd3 ),
      .SDMA_CTRL2_PLB_lockErr ( net_gnd0 ),
      .SDMA_CTRL2_PLB_wrPendReq ( net_gnd0 ),
      .SDMA_CTRL2_PLB_wrPendPri ( net_gnd2 ),
      .SDMA_CTRL2_PLB_rdPendReq ( net_gnd0 ),
      .SDMA_CTRL2_PLB_rdPendPri ( net_gnd2 ),
      .SDMA_CTRL2_PLB_reqPri ( net_gnd2 ),
      .SDMA_CTRL2_PLB_TAttribute ( net_gnd16 ),
      .SDMA_CTRL2_PLB_rdBurst ( net_gnd0 ),
      .SDMA_CTRL2_PLB_wrBurst ( net_gnd0 ),
      .SDMA_CTRL2_PLB_wrDBus ( net_gnd64 ),
      .SDMA_CTRL2_Sl_addrAck (  ),
      .SDMA_CTRL2_Sl_SSize (  ),
      .SDMA_CTRL2_Sl_wait (  ),
      .SDMA_CTRL2_Sl_rearbitrate (  ),
      .SDMA_CTRL2_Sl_wrDAck (  ),
      .SDMA_CTRL2_Sl_wrComp (  ),
      .SDMA_CTRL2_Sl_wrBTerm (  ),
      .SDMA_CTRL2_Sl_rdDBus (  ),
      .SDMA_CTRL2_Sl_rdWdAddr (  ),
      .SDMA_CTRL2_Sl_rdDAck (  ),
      .SDMA_CTRL2_Sl_rdComp (  ),
      .SDMA_CTRL2_Sl_rdBTerm (  ),
      .SDMA_CTRL2_Sl_MBusy (  ),
      .SDMA_CTRL2_Sl_MRdErr (  ),
      .SDMA_CTRL2_Sl_MWrErr (  ),
      .SDMA_CTRL2_Sl_MIRQ (  ),
      .PIM2_Addr ( net_gnd32[0:31] ),
      .PIM2_AddrReq ( net_gnd0 ),
      .PIM2_AddrAck (  ),
      .PIM2_RNW ( net_gnd0 ),
      .PIM2_Size ( net_gnd4[0:3] ),
      .PIM2_RdModWr ( net_gnd0 ),
      .PIM2_WrFIFO_Data ( net_gnd64[0:63] ),
      .PIM2_WrFIFO_BE ( net_gnd8[0:7] ),
      .PIM2_WrFIFO_Push ( net_gnd0 ),
      .PIM2_RdFIFO_Data (  ),
      .PIM2_RdFIFO_Pop ( net_gnd0 ),
      .PIM2_RdFIFO_RdWdAddr (  ),
      .PIM2_WrFIFO_Empty (  ),
      .PIM2_WrFIFO_AlmostFull (  ),
      .PIM2_WrFIFO_Flush ( net_gnd0 ),
      .PIM2_RdFIFO_Empty (  ),
      .PIM2_RdFIFO_Flush ( net_gnd0 ),
      .PIM2_RdFIFO_Latency (  ),
      .PIM2_InitDone (  ),
      .PPC440MC2_MIMCReadNotWrite ( net_gnd0 ),
      .PPC440MC2_MIMCAddress ( net_gnd36 ),
      .PPC440MC2_MIMCAddressValid ( net_gnd0 ),
      .PPC440MC2_MIMCWriteData ( net_gnd128 ),
      .PPC440MC2_MIMCWriteDataValid ( net_gnd0 ),
      .PPC440MC2_MIMCByteEnable ( net_gnd16 ),
      .PPC440MC2_MIMCBankConflict ( net_gnd0 ),
      .PPC440MC2_MIMCRowConflict ( net_gnd0 ),
      .PPC440MC2_MCMIReadData (  ),
      .PPC440MC2_MCMIReadDataValid (  ),
      .PPC440MC2_MCMIReadDataErr (  ),
      .PPC440MC2_MCMIAddrReadyToAccept (  ),
      .VFBC2_Cmd_Clk ( net_gnd0 ),
      .VFBC2_Cmd_Reset ( net_gnd0 ),
      .VFBC2_Cmd_Data ( net_gnd32[0:31] ),
      .VFBC2_Cmd_Write ( net_gnd0 ),
      .VFBC2_Cmd_End ( net_gnd0 ),
      .VFBC2_Cmd_Full (  ),
      .VFBC2_Cmd_Almost_Full (  ),
      .VFBC2_Cmd_Idle (  ),
      .VFBC2_Wd_Clk ( net_gnd0 ),
      .VFBC2_Wd_Reset ( net_gnd0 ),
      .VFBC2_Wd_Write ( net_gnd0 ),
      .VFBC2_Wd_End_Burst ( net_gnd0 ),
      .VFBC2_Wd_Flush ( net_gnd0 ),
      .VFBC2_Wd_Data ( net_gnd32[0:31] ),
      .VFBC2_Wd_Data_BE ( net_gnd4[0:3] ),
      .VFBC2_Wd_Full (  ),
      .VFBC2_Wd_Almost_Full (  ),
      .VFBC2_Rd_Clk ( net_gnd0 ),
      .VFBC2_Rd_Reset ( net_gnd0 ),
      .VFBC2_Rd_Read ( net_gnd0 ),
      .VFBC2_Rd_End_Burst ( net_gnd0 ),
      .VFBC2_Rd_Flush ( net_gnd0 ),
      .VFBC2_Rd_Data (  ),
      .VFBC2_Rd_Empty (  ),
      .VFBC2_Rd_Almost_Empty (  ),
      .FSL3_M_Clk ( net_vcc0 ),
      .FSL3_M_Write ( net_gnd0 ),
      .FSL3_M_Data ( net_gnd32 ),
      .FSL3_M_Control ( net_gnd0 ),
      .FSL3_M_Full (  ),
      .FSL3_S_Clk ( net_gnd0 ),
      .FSL3_S_Read ( net_gnd0 ),
      .FSL3_S_Data (  ),
      .FSL3_S_Control (  ),
      .FSL3_S_Exists (  ),
      .SPLB3_Clk ( net_vcc0 ),
      .SPLB3_Rst ( net_gnd0 ),
      .SPLB3_PLB_ABus ( net_gnd32 ),
      .SPLB3_PLB_PAValid ( net_gnd0 ),
      .SPLB3_PLB_SAValid ( net_gnd0 ),
      .SPLB3_PLB_masterID ( net_gnd1[0:0] ),
      .SPLB3_PLB_RNW ( net_gnd0 ),
      .SPLB3_PLB_BE ( net_gnd8 ),
      .SPLB3_PLB_UABus ( net_gnd32 ),
      .SPLB3_PLB_rdPrim ( net_gnd0 ),
      .SPLB3_PLB_wrPrim ( net_gnd0 ),
      .SPLB3_PLB_abort ( net_gnd0 ),
      .SPLB3_PLB_busLock ( net_gnd0 ),
      .SPLB3_PLB_MSize ( net_gnd2 ),
      .SPLB3_PLB_size ( net_gnd4 ),
      .SPLB3_PLB_type ( net_gnd3 ),
      .SPLB3_PLB_lockErr ( net_gnd0 ),
      .SPLB3_PLB_wrPendReq ( net_gnd0 ),
      .SPLB3_PLB_wrPendPri ( net_gnd2 ),
      .SPLB3_PLB_rdPendReq ( net_gnd0 ),
      .SPLB3_PLB_rdPendPri ( net_gnd2 ),
      .SPLB3_PLB_reqPri ( net_gnd2 ),
      .SPLB3_PLB_TAttribute ( net_gnd16 ),
      .SPLB3_PLB_rdBurst ( net_gnd0 ),
      .SPLB3_PLB_wrBurst ( net_gnd0 ),
      .SPLB3_PLB_wrDBus ( net_gnd64 ),
      .SPLB3_Sl_addrAck (  ),
      .SPLB3_Sl_SSize (  ),
      .SPLB3_Sl_wait (  ),
      .SPLB3_Sl_rearbitrate (  ),
      .SPLB3_Sl_wrDAck (  ),
      .SPLB3_Sl_wrComp (  ),
      .SPLB3_Sl_wrBTerm (  ),
      .SPLB3_Sl_rdDBus (  ),
      .SPLB3_Sl_rdWdAddr (  ),
      .SPLB3_Sl_rdDAck (  ),
      .SPLB3_Sl_rdComp (  ),
      .SPLB3_Sl_rdBTerm (  ),
      .SPLB3_Sl_MBusy (  ),
      .SPLB3_Sl_MRdErr (  ),
      .SPLB3_Sl_MWrErr (  ),
      .SPLB3_Sl_MIRQ (  ),
      .SDMA3_Clk ( net_gnd0 ),
      .SDMA3_Rx_IntOut (  ),
      .SDMA3_Tx_IntOut (  ),
      .SDMA3_RstOut (  ),
      .SDMA3_TX_D (  ),
      .SDMA3_TX_Rem (  ),
      .SDMA3_TX_SOF (  ),
      .SDMA3_TX_EOF (  ),
      .SDMA3_TX_SOP (  ),
      .SDMA3_TX_EOP (  ),
      .SDMA3_TX_Src_Rdy (  ),
      .SDMA3_TX_Dst_Rdy ( net_vcc0 ),
      .SDMA3_RX_D ( net_gnd32 ),
      .SDMA3_RX_Rem ( net_vcc4 ),
      .SDMA3_RX_SOF ( net_vcc0 ),
      .SDMA3_RX_EOF ( net_vcc0 ),
      .SDMA3_RX_SOP ( net_vcc0 ),
      .SDMA3_RX_EOP ( net_vcc0 ),
      .SDMA3_RX_Src_Rdy ( net_vcc0 ),
      .SDMA3_RX_Dst_Rdy (  ),
      .SDMA_CTRL3_Clk ( net_vcc0 ),
      .SDMA_CTRL3_Rst ( net_gnd0 ),
      .SDMA_CTRL3_PLB_ABus ( net_gnd32 ),
      .SDMA_CTRL3_PLB_PAValid ( net_gnd0 ),
      .SDMA_CTRL3_PLB_SAValid ( net_gnd0 ),
      .SDMA_CTRL3_PLB_masterID ( net_gnd1[0:0] ),
      .SDMA_CTRL3_PLB_RNW ( net_gnd0 ),
      .SDMA_CTRL3_PLB_BE ( net_gnd8 ),
      .SDMA_CTRL3_PLB_UABus ( net_gnd32 ),
      .SDMA_CTRL3_PLB_rdPrim ( net_gnd0 ),
      .SDMA_CTRL3_PLB_wrPrim ( net_gnd0 ),
      .SDMA_CTRL3_PLB_abort ( net_gnd0 ),
      .SDMA_CTRL3_PLB_busLock ( net_gnd0 ),
      .SDMA_CTRL3_PLB_MSize ( net_gnd2 ),
      .SDMA_CTRL3_PLB_size ( net_gnd4 ),
      .SDMA_CTRL3_PLB_type ( net_gnd3 ),
      .SDMA_CTRL3_PLB_lockErr ( net_gnd0 ),
      .SDMA_CTRL3_PLB_wrPendReq ( net_gnd0 ),
      .SDMA_CTRL3_PLB_wrPendPri ( net_gnd2 ),
      .SDMA_CTRL3_PLB_rdPendReq ( net_gnd0 ),
      .SDMA_CTRL3_PLB_rdPendPri ( net_gnd2 ),
      .SDMA_CTRL3_PLB_reqPri ( net_gnd2 ),
      .SDMA_CTRL3_PLB_TAttribute ( net_gnd16 ),
      .SDMA_CTRL3_PLB_rdBurst ( net_gnd0 ),
      .SDMA_CTRL3_PLB_wrBurst ( net_gnd0 ),
      .SDMA_CTRL3_PLB_wrDBus ( net_gnd64 ),
      .SDMA_CTRL3_Sl_addrAck (  ),
      .SDMA_CTRL3_Sl_SSize (  ),
      .SDMA_CTRL3_Sl_wait (  ),
      .SDMA_CTRL3_Sl_rearbitrate (  ),
      .SDMA_CTRL3_Sl_wrDAck (  ),
      .SDMA_CTRL3_Sl_wrComp (  ),
      .SDMA_CTRL3_Sl_wrBTerm (  ),
      .SDMA_CTRL3_Sl_rdDBus (  ),
      .SDMA_CTRL3_Sl_rdWdAddr (  ),
      .SDMA_CTRL3_Sl_rdDAck (  ),
      .SDMA_CTRL3_Sl_rdComp (  ),
      .SDMA_CTRL3_Sl_rdBTerm (  ),
      .SDMA_CTRL3_Sl_MBusy (  ),
      .SDMA_CTRL3_Sl_MRdErr (  ),
      .SDMA_CTRL3_Sl_MWrErr (  ),
      .SDMA_CTRL3_Sl_MIRQ (  ),
      .PIM3_Addr ( net_gnd32[0:31] ),
      .PIM3_AddrReq ( net_gnd0 ),
      .PIM3_AddrAck (  ),
      .PIM3_RNW ( net_gnd0 ),
      .PIM3_Size ( net_gnd4[0:3] ),
      .PIM3_RdModWr ( net_gnd0 ),
      .PIM3_WrFIFO_Data ( net_gnd64[0:63] ),
      .PIM3_WrFIFO_BE ( net_gnd8[0:7] ),
      .PIM3_WrFIFO_Push ( net_gnd0 ),
      .PIM3_RdFIFO_Data (  ),
      .PIM3_RdFIFO_Pop ( net_gnd0 ),
      .PIM3_RdFIFO_RdWdAddr (  ),
      .PIM3_WrFIFO_Empty (  ),
      .PIM3_WrFIFO_AlmostFull (  ),
      .PIM3_WrFIFO_Flush ( net_gnd0 ),
      .PIM3_RdFIFO_Empty (  ),
      .PIM3_RdFIFO_Flush ( net_gnd0 ),
      .PIM3_RdFIFO_Latency (  ),
      .PIM3_InitDone (  ),
      .PPC440MC3_MIMCReadNotWrite ( net_gnd0 ),
      .PPC440MC3_MIMCAddress ( net_gnd36 ),
      .PPC440MC3_MIMCAddressValid ( net_gnd0 ),
      .PPC440MC3_MIMCWriteData ( net_gnd128 ),
      .PPC440MC3_MIMCWriteDataValid ( net_gnd0 ),
      .PPC440MC3_MIMCByteEnable ( net_gnd16 ),
      .PPC440MC3_MIMCBankConflict ( net_gnd0 ),
      .PPC440MC3_MIMCRowConflict ( net_gnd0 ),
      .PPC440MC3_MCMIReadData (  ),
      .PPC440MC3_MCMIReadDataValid (  ),
      .PPC440MC3_MCMIReadDataErr (  ),
      .PPC440MC3_MCMIAddrReadyToAccept (  ),
      .VFBC3_Cmd_Clk ( net_gnd0 ),
      .VFBC3_Cmd_Reset ( net_gnd0 ),
      .VFBC3_Cmd_Data ( net_gnd32[0:31] ),
      .VFBC3_Cmd_Write ( net_gnd0 ),
      .VFBC3_Cmd_End ( net_gnd0 ),
      .VFBC3_Cmd_Full (  ),
      .VFBC3_Cmd_Almost_Full (  ),
      .VFBC3_Cmd_Idle (  ),
      .VFBC3_Wd_Clk ( net_gnd0 ),
      .VFBC3_Wd_Reset ( net_gnd0 ),
      .VFBC3_Wd_Write ( net_gnd0 ),
      .VFBC3_Wd_End_Burst ( net_gnd0 ),
      .VFBC3_Wd_Flush ( net_gnd0 ),
      .VFBC3_Wd_Data ( net_gnd32[0:31] ),
      .VFBC3_Wd_Data_BE ( net_gnd4[0:3] ),
      .VFBC3_Wd_Full (  ),
      .VFBC3_Wd_Almost_Full (  ),
      .VFBC3_Rd_Clk ( net_gnd0 ),
      .VFBC3_Rd_Reset ( net_gnd0 ),
      .VFBC3_Rd_Read ( net_gnd0 ),
      .VFBC3_Rd_End_Burst ( net_gnd0 ),
      .VFBC3_Rd_Flush ( net_gnd0 ),
      .VFBC3_Rd_Data (  ),
      .VFBC3_Rd_Empty (  ),
      .VFBC3_Rd_Almost_Empty (  ),
      .FSL4_M_Clk ( net_vcc0 ),
      .FSL4_M_Write ( net_gnd0 ),
      .FSL4_M_Data ( net_gnd32 ),
      .FSL4_M_Control ( net_gnd0 ),
      .FSL4_M_Full (  ),
      .FSL4_S_Clk ( net_gnd0 ),
      .FSL4_S_Read ( net_gnd0 ),
      .FSL4_S_Data (  ),
      .FSL4_S_Control (  ),
      .FSL4_S_Exists (  ),
      .SPLB4_Clk ( net_vcc0 ),
      .SPLB4_Rst ( net_gnd0 ),
      .SPLB4_PLB_ABus ( net_gnd32 ),
      .SPLB4_PLB_PAValid ( net_gnd0 ),
      .SPLB4_PLB_SAValid ( net_gnd0 ),
      .SPLB4_PLB_masterID ( net_gnd1[0:0] ),
      .SPLB4_PLB_RNW ( net_gnd0 ),
      .SPLB4_PLB_BE ( net_gnd8 ),
      .SPLB4_PLB_UABus ( net_gnd32 ),
      .SPLB4_PLB_rdPrim ( net_gnd0 ),
      .SPLB4_PLB_wrPrim ( net_gnd0 ),
      .SPLB4_PLB_abort ( net_gnd0 ),
      .SPLB4_PLB_busLock ( net_gnd0 ),
      .SPLB4_PLB_MSize ( net_gnd2 ),
      .SPLB4_PLB_size ( net_gnd4 ),
      .SPLB4_PLB_type ( net_gnd3 ),
      .SPLB4_PLB_lockErr ( net_gnd0 ),
      .SPLB4_PLB_wrPendReq ( net_gnd0 ),
      .SPLB4_PLB_wrPendPri ( net_gnd2 ),
      .SPLB4_PLB_rdPendReq ( net_gnd0 ),
      .SPLB4_PLB_rdPendPri ( net_gnd2 ),
      .SPLB4_PLB_reqPri ( net_gnd2 ),
      .SPLB4_PLB_TAttribute ( net_gnd16 ),
      .SPLB4_PLB_rdBurst ( net_gnd0 ),
      .SPLB4_PLB_wrBurst ( net_gnd0 ),
      .SPLB4_PLB_wrDBus ( net_gnd64 ),
      .SPLB4_Sl_addrAck (  ),
      .SPLB4_Sl_SSize (  ),
      .SPLB4_Sl_wait (  ),
      .SPLB4_Sl_rearbitrate (  ),
      .SPLB4_Sl_wrDAck (  ),
      .SPLB4_Sl_wrComp (  ),
      .SPLB4_Sl_wrBTerm (  ),
      .SPLB4_Sl_rdDBus (  ),
      .SPLB4_Sl_rdWdAddr (  ),
      .SPLB4_Sl_rdDAck (  ),
      .SPLB4_Sl_rdComp (  ),
      .SPLB4_Sl_rdBTerm (  ),
      .SPLB4_Sl_MBusy (  ),
      .SPLB4_Sl_MRdErr (  ),
      .SPLB4_Sl_MWrErr (  ),
      .SPLB4_Sl_MIRQ (  ),
      .SDMA4_Clk ( net_gnd0 ),
      .SDMA4_Rx_IntOut (  ),
      .SDMA4_Tx_IntOut (  ),
      .SDMA4_RstOut (  ),
      .SDMA4_TX_D (  ),
      .SDMA4_TX_Rem (  ),
      .SDMA4_TX_SOF (  ),
      .SDMA4_TX_EOF (  ),
      .SDMA4_TX_SOP (  ),
      .SDMA4_TX_EOP (  ),
      .SDMA4_TX_Src_Rdy (  ),
      .SDMA4_TX_Dst_Rdy ( net_vcc0 ),
      .SDMA4_RX_D ( net_gnd32 ),
      .SDMA4_RX_Rem ( net_vcc4 ),
      .SDMA4_RX_SOF ( net_vcc0 ),
      .SDMA4_RX_EOF ( net_vcc0 ),
      .SDMA4_RX_SOP ( net_vcc0 ),
      .SDMA4_RX_EOP ( net_vcc0 ),
      .SDMA4_RX_Src_Rdy ( net_vcc0 ),
      .SDMA4_RX_Dst_Rdy (  ),
      .SDMA_CTRL4_Clk ( net_vcc0 ),
      .SDMA_CTRL4_Rst ( net_gnd0 ),
      .SDMA_CTRL4_PLB_ABus ( net_gnd32 ),
      .SDMA_CTRL4_PLB_PAValid ( net_gnd0 ),
      .SDMA_CTRL4_PLB_SAValid ( net_gnd0 ),
      .SDMA_CTRL4_PLB_masterID ( net_gnd1[0:0] ),
      .SDMA_CTRL4_PLB_RNW ( net_gnd0 ),
      .SDMA_CTRL4_PLB_BE ( net_gnd8 ),
      .SDMA_CTRL4_PLB_UABus ( net_gnd32 ),
      .SDMA_CTRL4_PLB_rdPrim ( net_gnd0 ),
      .SDMA_CTRL4_PLB_wrPrim ( net_gnd0 ),
      .SDMA_CTRL4_PLB_abort ( net_gnd0 ),
      .SDMA_CTRL4_PLB_busLock ( net_gnd0 ),
      .SDMA_CTRL4_PLB_MSize ( net_gnd2 ),
      .SDMA_CTRL4_PLB_size ( net_gnd4 ),
      .SDMA_CTRL4_PLB_type ( net_gnd3 ),
      .SDMA_CTRL4_PLB_lockErr ( net_gnd0 ),
      .SDMA_CTRL4_PLB_wrPendReq ( net_gnd0 ),
      .SDMA_CTRL4_PLB_wrPendPri ( net_gnd2 ),
      .SDMA_CTRL4_PLB_rdPendReq ( net_gnd0 ),
      .SDMA_CTRL4_PLB_rdPendPri ( net_gnd2 ),
      .SDMA_CTRL4_PLB_reqPri ( net_gnd2 ),
      .SDMA_CTRL4_PLB_TAttribute ( net_gnd16 ),
      .SDMA_CTRL4_PLB_rdBurst ( net_gnd0 ),
      .SDMA_CTRL4_PLB_wrBurst ( net_gnd0 ),
      .SDMA_CTRL4_PLB_wrDBus ( net_gnd64 ),
      .SDMA_CTRL4_Sl_addrAck (  ),
      .SDMA_CTRL4_Sl_SSize (  ),
      .SDMA_CTRL4_Sl_wait (  ),
      .SDMA_CTRL4_Sl_rearbitrate (  ),
      .SDMA_CTRL4_Sl_wrDAck (  ),
      .SDMA_CTRL4_Sl_wrComp (  ),
      .SDMA_CTRL4_Sl_wrBTerm (  ),
      .SDMA_CTRL4_Sl_rdDBus (  ),
      .SDMA_CTRL4_Sl_rdWdAddr (  ),
      .SDMA_CTRL4_Sl_rdDAck (  ),
      .SDMA_CTRL4_Sl_rdComp (  ),
      .SDMA_CTRL4_Sl_rdBTerm (  ),
      .SDMA_CTRL4_Sl_MBusy (  ),
      .SDMA_CTRL4_Sl_MRdErr (  ),
      .SDMA_CTRL4_Sl_MWrErr (  ),
      .SDMA_CTRL4_Sl_MIRQ (  ),
      .PIM4_Addr ( net_gnd32[0:31] ),
      .PIM4_AddrReq ( net_gnd0 ),
      .PIM4_AddrAck (  ),
      .PIM4_RNW ( net_gnd0 ),
      .PIM4_Size ( net_gnd4[0:3] ),
      .PIM4_RdModWr ( net_gnd0 ),
      .PIM4_WrFIFO_Data ( net_gnd64[0:63] ),
      .PIM4_WrFIFO_BE ( net_gnd8[0:7] ),
      .PIM4_WrFIFO_Push ( net_gnd0 ),
      .PIM4_RdFIFO_Data (  ),
      .PIM4_RdFIFO_Pop ( net_gnd0 ),
      .PIM4_RdFIFO_RdWdAddr (  ),
      .PIM4_WrFIFO_Empty (  ),
      .PIM4_WrFIFO_AlmostFull (  ),
      .PIM4_WrFIFO_Flush ( net_gnd0 ),
      .PIM4_RdFIFO_Empty (  ),
      .PIM4_RdFIFO_Flush ( net_gnd0 ),
      .PIM4_RdFIFO_Latency (  ),
      .PIM4_InitDone (  ),
      .PPC440MC4_MIMCReadNotWrite ( net_gnd0 ),
      .PPC440MC4_MIMCAddress ( net_gnd36 ),
      .PPC440MC4_MIMCAddressValid ( net_gnd0 ),
      .PPC440MC4_MIMCWriteData ( net_gnd128 ),
      .PPC440MC4_MIMCWriteDataValid ( net_gnd0 ),
      .PPC440MC4_MIMCByteEnable ( net_gnd16 ),
      .PPC440MC4_MIMCBankConflict ( net_gnd0 ),
      .PPC440MC4_MIMCRowConflict ( net_gnd0 ),
      .PPC440MC4_MCMIReadData (  ),
      .PPC440MC4_MCMIReadDataValid (  ),
      .PPC440MC4_MCMIReadDataErr (  ),
      .PPC440MC4_MCMIAddrReadyToAccept (  ),
      .VFBC4_Cmd_Clk ( net_gnd0 ),
      .VFBC4_Cmd_Reset ( net_gnd0 ),
      .VFBC4_Cmd_Data ( net_gnd32[0:31] ),
      .VFBC4_Cmd_Write ( net_gnd0 ),
      .VFBC4_Cmd_End ( net_gnd0 ),
      .VFBC4_Cmd_Full (  ),
      .VFBC4_Cmd_Almost_Full (  ),
      .VFBC4_Cmd_Idle (  ),
      .VFBC4_Wd_Clk ( net_gnd0 ),
      .VFBC4_Wd_Reset ( net_gnd0 ),
      .VFBC4_Wd_Write ( net_gnd0 ),
      .VFBC4_Wd_End_Burst ( net_gnd0 ),
      .VFBC4_Wd_Flush ( net_gnd0 ),
      .VFBC4_Wd_Data ( net_gnd32[0:31] ),
      .VFBC4_Wd_Data_BE ( net_gnd4[0:3] ),
      .VFBC4_Wd_Full (  ),
      .VFBC4_Wd_Almost_Full (  ),
      .VFBC4_Rd_Clk ( net_gnd0 ),
      .VFBC4_Rd_Reset ( net_gnd0 ),
      .VFBC4_Rd_Read ( net_gnd0 ),
      .VFBC4_Rd_End_Burst ( net_gnd0 ),
      .VFBC4_Rd_Flush ( net_gnd0 ),
      .VFBC4_Rd_Data (  ),
      .VFBC4_Rd_Empty (  ),
      .VFBC4_Rd_Almost_Empty (  ),
      .FSL5_M_Clk ( net_vcc0 ),
      .FSL5_M_Write ( net_gnd0 ),
      .FSL5_M_Data ( net_gnd32 ),
      .FSL5_M_Control ( net_gnd0 ),
      .FSL5_M_Full (  ),
      .FSL5_S_Clk ( net_gnd0 ),
      .FSL5_S_Read ( net_gnd0 ),
      .FSL5_S_Data (  ),
      .FSL5_S_Control (  ),
      .FSL5_S_Exists (  ),
      .SPLB5_Clk ( net_vcc0 ),
      .SPLB5_Rst ( net_gnd0 ),
      .SPLB5_PLB_ABus ( net_gnd32 ),
      .SPLB5_PLB_PAValid ( net_gnd0 ),
      .SPLB5_PLB_SAValid ( net_gnd0 ),
      .SPLB5_PLB_masterID ( net_gnd1[0:0] ),
      .SPLB5_PLB_RNW ( net_gnd0 ),
      .SPLB5_PLB_BE ( net_gnd8 ),
      .SPLB5_PLB_UABus ( net_gnd32 ),
      .SPLB5_PLB_rdPrim ( net_gnd0 ),
      .SPLB5_PLB_wrPrim ( net_gnd0 ),
      .SPLB5_PLB_abort ( net_gnd0 ),
      .SPLB5_PLB_busLock ( net_gnd0 ),
      .SPLB5_PLB_MSize ( net_gnd2 ),
      .SPLB5_PLB_size ( net_gnd4 ),
      .SPLB5_PLB_type ( net_gnd3 ),
      .SPLB5_PLB_lockErr ( net_gnd0 ),
      .SPLB5_PLB_wrPendReq ( net_gnd0 ),
      .SPLB5_PLB_wrPendPri ( net_gnd2 ),
      .SPLB5_PLB_rdPendReq ( net_gnd0 ),
      .SPLB5_PLB_rdPendPri ( net_gnd2 ),
      .SPLB5_PLB_reqPri ( net_gnd2 ),
      .SPLB5_PLB_TAttribute ( net_gnd16 ),
      .SPLB5_PLB_rdBurst ( net_gnd0 ),
      .SPLB5_PLB_wrBurst ( net_gnd0 ),
      .SPLB5_PLB_wrDBus ( net_gnd64 ),
      .SPLB5_Sl_addrAck (  ),
      .SPLB5_Sl_SSize (  ),
      .SPLB5_Sl_wait (  ),
      .SPLB5_Sl_rearbitrate (  ),
      .SPLB5_Sl_wrDAck (  ),
      .SPLB5_Sl_wrComp (  ),
      .SPLB5_Sl_wrBTerm (  ),
      .SPLB5_Sl_rdDBus (  ),
      .SPLB5_Sl_rdWdAddr (  ),
      .SPLB5_Sl_rdDAck (  ),
      .SPLB5_Sl_rdComp (  ),
      .SPLB5_Sl_rdBTerm (  ),
      .SPLB5_Sl_MBusy (  ),
      .SPLB5_Sl_MRdErr (  ),
      .SPLB5_Sl_MWrErr (  ),
      .SPLB5_Sl_MIRQ (  ),
      .SDMA5_Clk ( net_gnd0 ),
      .SDMA5_Rx_IntOut (  ),
      .SDMA5_Tx_IntOut (  ),
      .SDMA5_RstOut (  ),
      .SDMA5_TX_D (  ),
      .SDMA5_TX_Rem (  ),
      .SDMA5_TX_SOF (  ),
      .SDMA5_TX_EOF (  ),
      .SDMA5_TX_SOP (  ),
      .SDMA5_TX_EOP (  ),
      .SDMA5_TX_Src_Rdy (  ),
      .SDMA5_TX_Dst_Rdy ( net_vcc0 ),
      .SDMA5_RX_D ( net_gnd32 ),
      .SDMA5_RX_Rem ( net_vcc4 ),
      .SDMA5_RX_SOF ( net_vcc0 ),
      .SDMA5_RX_EOF ( net_vcc0 ),
      .SDMA5_RX_SOP ( net_vcc0 ),
      .SDMA5_RX_EOP ( net_vcc0 ),
      .SDMA5_RX_Src_Rdy ( net_vcc0 ),
      .SDMA5_RX_Dst_Rdy (  ),
      .SDMA_CTRL5_Clk ( net_vcc0 ),
      .SDMA_CTRL5_Rst ( net_gnd0 ),
      .SDMA_CTRL5_PLB_ABus ( net_gnd32 ),
      .SDMA_CTRL5_PLB_PAValid ( net_gnd0 ),
      .SDMA_CTRL5_PLB_SAValid ( net_gnd0 ),
      .SDMA_CTRL5_PLB_masterID ( net_gnd1[0:0] ),
      .SDMA_CTRL5_PLB_RNW ( net_gnd0 ),
      .SDMA_CTRL5_PLB_BE ( net_gnd8 ),
      .SDMA_CTRL5_PLB_UABus ( net_gnd32 ),
      .SDMA_CTRL5_PLB_rdPrim ( net_gnd0 ),
      .SDMA_CTRL5_PLB_wrPrim ( net_gnd0 ),
      .SDMA_CTRL5_PLB_abort ( net_gnd0 ),
      .SDMA_CTRL5_PLB_busLock ( net_gnd0 ),
      .SDMA_CTRL5_PLB_MSize ( net_gnd2 ),
      .SDMA_CTRL5_PLB_size ( net_gnd4 ),
      .SDMA_CTRL5_PLB_type ( net_gnd3 ),
      .SDMA_CTRL5_PLB_lockErr ( net_gnd0 ),
      .SDMA_CTRL5_PLB_wrPendReq ( net_gnd0 ),
      .SDMA_CTRL5_PLB_wrPendPri ( net_gnd2 ),
      .SDMA_CTRL5_PLB_rdPendReq ( net_gnd0 ),
      .SDMA_CTRL5_PLB_rdPendPri ( net_gnd2 ),
      .SDMA_CTRL5_PLB_reqPri ( net_gnd2 ),
      .SDMA_CTRL5_PLB_TAttribute ( net_gnd16 ),
      .SDMA_CTRL5_PLB_rdBurst ( net_gnd0 ),
      .SDMA_CTRL5_PLB_wrBurst ( net_gnd0 ),
      .SDMA_CTRL5_PLB_wrDBus ( net_gnd64 ),
      .SDMA_CTRL5_Sl_addrAck (  ),
      .SDMA_CTRL5_Sl_SSize (  ),
      .SDMA_CTRL5_Sl_wait (  ),
      .SDMA_CTRL5_Sl_rearbitrate (  ),
      .SDMA_CTRL5_Sl_wrDAck (  ),
      .SDMA_CTRL5_Sl_wrComp (  ),
      .SDMA_CTRL5_Sl_wrBTerm (  ),
      .SDMA_CTRL5_Sl_rdDBus (  ),
      .SDMA_CTRL5_Sl_rdWdAddr (  ),
      .SDMA_CTRL5_Sl_rdDAck (  ),
      .SDMA_CTRL5_Sl_rdComp (  ),
      .SDMA_CTRL5_Sl_rdBTerm (  ),
      .SDMA_CTRL5_Sl_MBusy (  ),
      .SDMA_CTRL5_Sl_MRdErr (  ),
      .SDMA_CTRL5_Sl_MWrErr (  ),
      .SDMA_CTRL5_Sl_MIRQ (  ),
      .PIM5_Addr ( net_gnd32[0:31] ),
      .PIM5_AddrReq ( net_gnd0 ),
      .PIM5_AddrAck (  ),
      .PIM5_RNW ( net_gnd0 ),
      .PIM5_Size ( net_gnd4[0:3] ),
      .PIM5_RdModWr ( net_gnd0 ),
      .PIM5_WrFIFO_Data ( net_gnd64[0:63] ),
      .PIM5_WrFIFO_BE ( net_gnd8[0:7] ),
      .PIM5_WrFIFO_Push ( net_gnd0 ),
      .PIM5_RdFIFO_Data (  ),
      .PIM5_RdFIFO_Pop ( net_gnd0 ),
      .PIM5_RdFIFO_RdWdAddr (  ),
      .PIM5_WrFIFO_Empty (  ),
      .PIM5_WrFIFO_AlmostFull (  ),
      .PIM5_WrFIFO_Flush ( net_gnd0 ),
      .PIM5_RdFIFO_Empty (  ),
      .PIM5_RdFIFO_Flush ( net_gnd0 ),
      .PIM5_RdFIFO_Latency (  ),
      .PIM5_InitDone (  ),
      .PPC440MC5_MIMCReadNotWrite ( net_gnd0 ),
      .PPC440MC5_MIMCAddress ( net_gnd36 ),
      .PPC440MC5_MIMCAddressValid ( net_gnd0 ),
      .PPC440MC5_MIMCWriteData ( net_gnd128 ),
      .PPC440MC5_MIMCWriteDataValid ( net_gnd0 ),
      .PPC440MC5_MIMCByteEnable ( net_gnd16 ),
      .PPC440MC5_MIMCBankConflict ( net_gnd0 ),
      .PPC440MC5_MIMCRowConflict ( net_gnd0 ),
      .PPC440MC5_MCMIReadData (  ),
      .PPC440MC5_MCMIReadDataValid (  ),
      .PPC440MC5_MCMIReadDataErr (  ),
      .PPC440MC5_MCMIAddrReadyToAccept (  ),
      .VFBC5_Cmd_Clk ( net_gnd0 ),
      .VFBC5_Cmd_Reset ( net_gnd0 ),
      .VFBC5_Cmd_Data ( net_gnd32[0:31] ),
      .VFBC5_Cmd_Write ( net_gnd0 ),
      .VFBC5_Cmd_End ( net_gnd0 ),
      .VFBC5_Cmd_Full (  ),
      .VFBC5_Cmd_Almost_Full (  ),
      .VFBC5_Cmd_Idle (  ),
      .VFBC5_Wd_Clk ( net_gnd0 ),
      .VFBC5_Wd_Reset ( net_gnd0 ),
      .VFBC5_Wd_Write ( net_gnd0 ),
      .VFBC5_Wd_End_Burst ( net_gnd0 ),
      .VFBC5_Wd_Flush ( net_gnd0 ),
      .VFBC5_Wd_Data ( net_gnd32[0:31] ),
      .VFBC5_Wd_Data_BE ( net_gnd4[0:3] ),
      .VFBC5_Wd_Full (  ),
      .VFBC5_Wd_Almost_Full (  ),
      .VFBC5_Rd_Clk ( net_gnd0 ),
      .VFBC5_Rd_Reset ( net_gnd0 ),
      .VFBC5_Rd_Read ( net_gnd0 ),
      .VFBC5_Rd_End_Burst ( net_gnd0 ),
      .VFBC5_Rd_Flush ( net_gnd0 ),
      .VFBC5_Rd_Data (  ),
      .VFBC5_Rd_Empty (  ),
      .VFBC5_Rd_Almost_Empty (  ),
      .FSL6_M_Clk ( net_vcc0 ),
      .FSL6_M_Write ( net_gnd0 ),
      .FSL6_M_Data ( net_gnd32 ),
      .FSL6_M_Control ( net_gnd0 ),
      .FSL6_M_Full (  ),
      .FSL6_S_Clk ( net_gnd0 ),
      .FSL6_S_Read ( net_gnd0 ),
      .FSL6_S_Data (  ),
      .FSL6_S_Control (  ),
      .FSL6_S_Exists (  ),
      .SPLB6_Clk ( net_vcc0 ),
      .SPLB6_Rst ( net_gnd0 ),
      .SPLB6_PLB_ABus ( net_gnd32 ),
      .SPLB6_PLB_PAValid ( net_gnd0 ),
      .SPLB6_PLB_SAValid ( net_gnd0 ),
      .SPLB6_PLB_masterID ( net_gnd1[0:0] ),
      .SPLB6_PLB_RNW ( net_gnd0 ),
      .SPLB6_PLB_BE ( net_gnd8 ),
      .SPLB6_PLB_UABus ( net_gnd32 ),
      .SPLB6_PLB_rdPrim ( net_gnd0 ),
      .SPLB6_PLB_wrPrim ( net_gnd0 ),
      .SPLB6_PLB_abort ( net_gnd0 ),
      .SPLB6_PLB_busLock ( net_gnd0 ),
      .SPLB6_PLB_MSize ( net_gnd2 ),
      .SPLB6_PLB_size ( net_gnd4 ),
      .SPLB6_PLB_type ( net_gnd3 ),
      .SPLB6_PLB_lockErr ( net_gnd0 ),
      .SPLB6_PLB_wrPendReq ( net_gnd0 ),
      .SPLB6_PLB_wrPendPri ( net_gnd2 ),
      .SPLB6_PLB_rdPendReq ( net_gnd0 ),
      .SPLB6_PLB_rdPendPri ( net_gnd2 ),
      .SPLB6_PLB_reqPri ( net_gnd2 ),
      .SPLB6_PLB_TAttribute ( net_gnd16 ),
      .SPLB6_PLB_rdBurst ( net_gnd0 ),
      .SPLB6_PLB_wrBurst ( net_gnd0 ),
      .SPLB6_PLB_wrDBus ( net_gnd64 ),
      .SPLB6_Sl_addrAck (  ),
      .SPLB6_Sl_SSize (  ),
      .SPLB6_Sl_wait (  ),
      .SPLB6_Sl_rearbitrate (  ),
      .SPLB6_Sl_wrDAck (  ),
      .SPLB6_Sl_wrComp (  ),
      .SPLB6_Sl_wrBTerm (  ),
      .SPLB6_Sl_rdDBus (  ),
      .SPLB6_Sl_rdWdAddr (  ),
      .SPLB6_Sl_rdDAck (  ),
      .SPLB6_Sl_rdComp (  ),
      .SPLB6_Sl_rdBTerm (  ),
      .SPLB6_Sl_MBusy (  ),
      .SPLB6_Sl_MRdErr (  ),
      .SPLB6_Sl_MWrErr (  ),
      .SPLB6_Sl_MIRQ (  ),
      .SDMA6_Clk ( net_gnd0 ),
      .SDMA6_Rx_IntOut (  ),
      .SDMA6_Tx_IntOut (  ),
      .SDMA6_RstOut (  ),
      .SDMA6_TX_D (  ),
      .SDMA6_TX_Rem (  ),
      .SDMA6_TX_SOF (  ),
      .SDMA6_TX_EOF (  ),
      .SDMA6_TX_SOP (  ),
      .SDMA6_TX_EOP (  ),
      .SDMA6_TX_Src_Rdy (  ),
      .SDMA6_TX_Dst_Rdy ( net_vcc0 ),
      .SDMA6_RX_D ( net_gnd32 ),
      .SDMA6_RX_Rem ( net_vcc4 ),
      .SDMA6_RX_SOF ( net_vcc0 ),
      .SDMA6_RX_EOF ( net_vcc0 ),
      .SDMA6_RX_SOP ( net_vcc0 ),
      .SDMA6_RX_EOP ( net_vcc0 ),
      .SDMA6_RX_Src_Rdy ( net_vcc0 ),
      .SDMA6_RX_Dst_Rdy (  ),
      .SDMA_CTRL6_Clk ( net_vcc0 ),
      .SDMA_CTRL6_Rst ( net_gnd0 ),
      .SDMA_CTRL6_PLB_ABus ( net_gnd32 ),
      .SDMA_CTRL6_PLB_PAValid ( net_gnd0 ),
      .SDMA_CTRL6_PLB_SAValid ( net_gnd0 ),
      .SDMA_CTRL6_PLB_masterID ( net_gnd1[0:0] ),
      .SDMA_CTRL6_PLB_RNW ( net_gnd0 ),
      .SDMA_CTRL6_PLB_BE ( net_gnd8 ),
      .SDMA_CTRL6_PLB_UABus ( net_gnd32 ),
      .SDMA_CTRL6_PLB_rdPrim ( net_gnd0 ),
      .SDMA_CTRL6_PLB_wrPrim ( net_gnd0 ),
      .SDMA_CTRL6_PLB_abort ( net_gnd0 ),
      .SDMA_CTRL6_PLB_busLock ( net_gnd0 ),
      .SDMA_CTRL6_PLB_MSize ( net_gnd2 ),
      .SDMA_CTRL6_PLB_size ( net_gnd4 ),
      .SDMA_CTRL6_PLB_type ( net_gnd3 ),
      .SDMA_CTRL6_PLB_lockErr ( net_gnd0 ),
      .SDMA_CTRL6_PLB_wrPendReq ( net_gnd0 ),
      .SDMA_CTRL6_PLB_wrPendPri ( net_gnd2 ),
      .SDMA_CTRL6_PLB_rdPendReq ( net_gnd0 ),
      .SDMA_CTRL6_PLB_rdPendPri ( net_gnd2 ),
      .SDMA_CTRL6_PLB_reqPri ( net_gnd2 ),
      .SDMA_CTRL6_PLB_TAttribute ( net_gnd16 ),
      .SDMA_CTRL6_PLB_rdBurst ( net_gnd0 ),
      .SDMA_CTRL6_PLB_wrBurst ( net_gnd0 ),
      .SDMA_CTRL6_PLB_wrDBus ( net_gnd64 ),
      .SDMA_CTRL6_Sl_addrAck (  ),
      .SDMA_CTRL6_Sl_SSize (  ),
      .SDMA_CTRL6_Sl_wait (  ),
      .SDMA_CTRL6_Sl_rearbitrate (  ),
      .SDMA_CTRL6_Sl_wrDAck (  ),
      .SDMA_CTRL6_Sl_wrComp (  ),
      .SDMA_CTRL6_Sl_wrBTerm (  ),
      .SDMA_CTRL6_Sl_rdDBus (  ),
      .SDMA_CTRL6_Sl_rdWdAddr (  ),
      .SDMA_CTRL6_Sl_rdDAck (  ),
      .SDMA_CTRL6_Sl_rdComp (  ),
      .SDMA_CTRL6_Sl_rdBTerm (  ),
      .SDMA_CTRL6_Sl_MBusy (  ),
      .SDMA_CTRL6_Sl_MRdErr (  ),
      .SDMA_CTRL6_Sl_MWrErr (  ),
      .SDMA_CTRL6_Sl_MIRQ (  ),
      .PIM6_Addr ( net_gnd32[0:31] ),
      .PIM6_AddrReq ( net_gnd0 ),
      .PIM6_AddrAck (  ),
      .PIM6_RNW ( net_gnd0 ),
      .PIM6_Size ( net_gnd4[0:3] ),
      .PIM6_RdModWr ( net_gnd0 ),
      .PIM6_WrFIFO_Data ( net_gnd64[0:63] ),
      .PIM6_WrFIFO_BE ( net_gnd8[0:7] ),
      .PIM6_WrFIFO_Push ( net_gnd0 ),
      .PIM6_RdFIFO_Data (  ),
      .PIM6_RdFIFO_Pop ( net_gnd0 ),
      .PIM6_RdFIFO_RdWdAddr (  ),
      .PIM6_WrFIFO_Empty (  ),
      .PIM6_WrFIFO_AlmostFull (  ),
      .PIM6_WrFIFO_Flush ( net_gnd0 ),
      .PIM6_RdFIFO_Empty (  ),
      .PIM6_RdFIFO_Flush ( net_gnd0 ),
      .PIM6_RdFIFO_Latency (  ),
      .PIM6_InitDone (  ),
      .PPC440MC6_MIMCReadNotWrite ( net_gnd0 ),
      .PPC440MC6_MIMCAddress ( net_gnd36 ),
      .PPC440MC6_MIMCAddressValid ( net_gnd0 ),
      .PPC440MC6_MIMCWriteData ( net_gnd128 ),
      .PPC440MC6_MIMCWriteDataValid ( net_gnd0 ),
      .PPC440MC6_MIMCByteEnable ( net_gnd16 ),
      .PPC440MC6_MIMCBankConflict ( net_gnd0 ),
      .PPC440MC6_MIMCRowConflict ( net_gnd0 ),
      .PPC440MC6_MCMIReadData (  ),
      .PPC440MC6_MCMIReadDataValid (  ),
      .PPC440MC6_MCMIReadDataErr (  ),
      .PPC440MC6_MCMIAddrReadyToAccept (  ),
      .VFBC6_Cmd_Clk ( net_gnd0 ),
      .VFBC6_Cmd_Reset ( net_gnd0 ),
      .VFBC6_Cmd_Data ( net_gnd32[0:31] ),
      .VFBC6_Cmd_Write ( net_gnd0 ),
      .VFBC6_Cmd_End ( net_gnd0 ),
      .VFBC6_Cmd_Full (  ),
      .VFBC6_Cmd_Almost_Full (  ),
      .VFBC6_Cmd_Idle (  ),
      .VFBC6_Wd_Clk ( net_gnd0 ),
      .VFBC6_Wd_Reset ( net_gnd0 ),
      .VFBC6_Wd_Write ( net_gnd0 ),
      .VFBC6_Wd_End_Burst ( net_gnd0 ),
      .VFBC6_Wd_Flush ( net_gnd0 ),
      .VFBC6_Wd_Data ( net_gnd32[0:31] ),
      .VFBC6_Wd_Data_BE ( net_gnd4[0:3] ),
      .VFBC6_Wd_Full (  ),
      .VFBC6_Wd_Almost_Full (  ),
      .VFBC6_Rd_Clk ( net_gnd0 ),
      .VFBC6_Rd_Reset ( net_gnd0 ),
      .VFBC6_Rd_Read ( net_gnd0 ),
      .VFBC6_Rd_End_Burst ( net_gnd0 ),
      .VFBC6_Rd_Flush ( net_gnd0 ),
      .VFBC6_Rd_Data (  ),
      .VFBC6_Rd_Empty (  ),
      .VFBC6_Rd_Almost_Empty (  ),
      .FSL7_M_Clk ( net_vcc0 ),
      .FSL7_M_Write ( net_gnd0 ),
      .FSL7_M_Data ( net_gnd32 ),
      .FSL7_M_Control ( net_gnd0 ),
      .FSL7_M_Full (  ),
      .FSL7_S_Clk ( net_gnd0 ),
      .FSL7_S_Read ( net_gnd0 ),
      .FSL7_S_Data (  ),
      .FSL7_S_Control (  ),
      .FSL7_S_Exists (  ),
      .SPLB7_Clk ( net_vcc0 ),
      .SPLB7_Rst ( net_gnd0 ),
      .SPLB7_PLB_ABus ( net_gnd32 ),
      .SPLB7_PLB_PAValid ( net_gnd0 ),
      .SPLB7_PLB_SAValid ( net_gnd0 ),
      .SPLB7_PLB_masterID ( net_gnd1[0:0] ),
      .SPLB7_PLB_RNW ( net_gnd0 ),
      .SPLB7_PLB_BE ( net_gnd8 ),
      .SPLB7_PLB_UABus ( net_gnd32 ),
      .SPLB7_PLB_rdPrim ( net_gnd0 ),
      .SPLB7_PLB_wrPrim ( net_gnd0 ),
      .SPLB7_PLB_abort ( net_gnd0 ),
      .SPLB7_PLB_busLock ( net_gnd0 ),
      .SPLB7_PLB_MSize ( net_gnd2 ),
      .SPLB7_PLB_size ( net_gnd4 ),
      .SPLB7_PLB_type ( net_gnd3 ),
      .SPLB7_PLB_lockErr ( net_gnd0 ),
      .SPLB7_PLB_wrPendReq ( net_gnd0 ),
      .SPLB7_PLB_wrPendPri ( net_gnd2 ),
      .SPLB7_PLB_rdPendReq ( net_gnd0 ),
      .SPLB7_PLB_rdPendPri ( net_gnd2 ),
      .SPLB7_PLB_reqPri ( net_gnd2 ),
      .SPLB7_PLB_TAttribute ( net_gnd16 ),
      .SPLB7_PLB_rdBurst ( net_gnd0 ),
      .SPLB7_PLB_wrBurst ( net_gnd0 ),
      .SPLB7_PLB_wrDBus ( net_gnd64 ),
      .SPLB7_Sl_addrAck (  ),
      .SPLB7_Sl_SSize (  ),
      .SPLB7_Sl_wait (  ),
      .SPLB7_Sl_rearbitrate (  ),
      .SPLB7_Sl_wrDAck (  ),
      .SPLB7_Sl_wrComp (  ),
      .SPLB7_Sl_wrBTerm (  ),
      .SPLB7_Sl_rdDBus (  ),
      .SPLB7_Sl_rdWdAddr (  ),
      .SPLB7_Sl_rdDAck (  ),
      .SPLB7_Sl_rdComp (  ),
      .SPLB7_Sl_rdBTerm (  ),
      .SPLB7_Sl_MBusy (  ),
      .SPLB7_Sl_MRdErr (  ),
      .SPLB7_Sl_MWrErr (  ),
      .SPLB7_Sl_MIRQ (  ),
      .SDMA7_Clk ( net_gnd0 ),
      .SDMA7_Rx_IntOut (  ),
      .SDMA7_Tx_IntOut (  ),
      .SDMA7_RstOut (  ),
      .SDMA7_TX_D (  ),
      .SDMA7_TX_Rem (  ),
      .SDMA7_TX_SOF (  ),
      .SDMA7_TX_EOF (  ),
      .SDMA7_TX_SOP (  ),
      .SDMA7_TX_EOP (  ),
      .SDMA7_TX_Src_Rdy (  ),
      .SDMA7_TX_Dst_Rdy ( net_vcc0 ),
      .SDMA7_RX_D ( net_gnd32 ),
      .SDMA7_RX_Rem ( net_vcc4 ),
      .SDMA7_RX_SOF ( net_vcc0 ),
      .SDMA7_RX_EOF ( net_vcc0 ),
      .SDMA7_RX_SOP ( net_vcc0 ),
      .SDMA7_RX_EOP ( net_vcc0 ),
      .SDMA7_RX_Src_Rdy ( net_vcc0 ),
      .SDMA7_RX_Dst_Rdy (  ),
      .SDMA_CTRL7_Clk ( net_vcc0 ),
      .SDMA_CTRL7_Rst ( net_gnd0 ),
      .SDMA_CTRL7_PLB_ABus ( net_gnd32 ),
      .SDMA_CTRL7_PLB_PAValid ( net_gnd0 ),
      .SDMA_CTRL7_PLB_SAValid ( net_gnd0 ),
      .SDMA_CTRL7_PLB_masterID ( net_gnd1[0:0] ),
      .SDMA_CTRL7_PLB_RNW ( net_gnd0 ),
      .SDMA_CTRL7_PLB_BE ( net_gnd8 ),
      .SDMA_CTRL7_PLB_UABus ( net_gnd32 ),
      .SDMA_CTRL7_PLB_rdPrim ( net_gnd0 ),
      .SDMA_CTRL7_PLB_wrPrim ( net_gnd0 ),
      .SDMA_CTRL7_PLB_abort ( net_gnd0 ),
      .SDMA_CTRL7_PLB_busLock ( net_gnd0 ),
      .SDMA_CTRL7_PLB_MSize ( net_gnd2 ),
      .SDMA_CTRL7_PLB_size ( net_gnd4 ),
      .SDMA_CTRL7_PLB_type ( net_gnd3 ),
      .SDMA_CTRL7_PLB_lockErr ( net_gnd0 ),
      .SDMA_CTRL7_PLB_wrPendReq ( net_gnd0 ),
      .SDMA_CTRL7_PLB_wrPendPri ( net_gnd2 ),
      .SDMA_CTRL7_PLB_rdPendReq ( net_gnd0 ),
      .SDMA_CTRL7_PLB_rdPendPri ( net_gnd2 ),
      .SDMA_CTRL7_PLB_reqPri ( net_gnd2 ),
      .SDMA_CTRL7_PLB_TAttribute ( net_gnd16 ),
      .SDMA_CTRL7_PLB_rdBurst ( net_gnd0 ),
      .SDMA_CTRL7_PLB_wrBurst ( net_gnd0 ),
      .SDMA_CTRL7_PLB_wrDBus ( net_gnd64 ),
      .SDMA_CTRL7_Sl_addrAck (  ),
      .SDMA_CTRL7_Sl_SSize (  ),
      .SDMA_CTRL7_Sl_wait (  ),
      .SDMA_CTRL7_Sl_rearbitrate (  ),
      .SDMA_CTRL7_Sl_wrDAck (  ),
      .SDMA_CTRL7_Sl_wrComp (  ),
      .SDMA_CTRL7_Sl_wrBTerm (  ),
      .SDMA_CTRL7_Sl_rdDBus (  ),
      .SDMA_CTRL7_Sl_rdWdAddr (  ),
      .SDMA_CTRL7_Sl_rdDAck (  ),
      .SDMA_CTRL7_Sl_rdComp (  ),
      .SDMA_CTRL7_Sl_rdBTerm (  ),
      .SDMA_CTRL7_Sl_MBusy (  ),
      .SDMA_CTRL7_Sl_MRdErr (  ),
      .SDMA_CTRL7_Sl_MWrErr (  ),
      .SDMA_CTRL7_Sl_MIRQ (  ),
      .PIM7_Addr ( net_gnd32[0:31] ),
      .PIM7_AddrReq ( net_gnd0 ),
      .PIM7_AddrAck (  ),
      .PIM7_RNW ( net_gnd0 ),
      .PIM7_Size ( net_gnd4[0:3] ),
      .PIM7_RdModWr ( net_gnd0 ),
      .PIM7_WrFIFO_Data ( net_gnd64[0:63] ),
      .PIM7_WrFIFO_BE ( net_gnd8[0:7] ),
      .PIM7_WrFIFO_Push ( net_gnd0 ),
      .PIM7_RdFIFO_Data (  ),
      .PIM7_RdFIFO_Pop ( net_gnd0 ),
      .PIM7_RdFIFO_RdWdAddr (  ),
      .PIM7_WrFIFO_Empty (  ),
      .PIM7_WrFIFO_AlmostFull (  ),
      .PIM7_WrFIFO_Flush ( net_gnd0 ),
      .PIM7_RdFIFO_Empty (  ),
      .PIM7_RdFIFO_Flush ( net_gnd0 ),
      .PIM7_RdFIFO_Latency (  ),
      .PIM7_InitDone (  ),
      .PPC440MC7_MIMCReadNotWrite ( net_gnd0 ),
      .PPC440MC7_MIMCAddress ( net_gnd36 ),
      .PPC440MC7_MIMCAddressValid ( net_gnd0 ),
      .PPC440MC7_MIMCWriteData ( net_gnd128 ),
      .PPC440MC7_MIMCWriteDataValid ( net_gnd0 ),
      .PPC440MC7_MIMCByteEnable ( net_gnd16 ),
      .PPC440MC7_MIMCBankConflict ( net_gnd0 ),
      .PPC440MC7_MIMCRowConflict ( net_gnd0 ),
      .PPC440MC7_MCMIReadData (  ),
      .PPC440MC7_MCMIReadDataValid (  ),
      .PPC440MC7_MCMIReadDataErr (  ),
      .PPC440MC7_MCMIAddrReadyToAccept (  ),
      .VFBC7_Cmd_Clk ( net_gnd0 ),
      .VFBC7_Cmd_Reset ( net_gnd0 ),
      .VFBC7_Cmd_Data ( net_gnd32[0:31] ),
      .VFBC7_Cmd_Write ( net_gnd0 ),
      .VFBC7_Cmd_End ( net_gnd0 ),
      .VFBC7_Cmd_Full (  ),
      .VFBC7_Cmd_Almost_Full (  ),
      .VFBC7_Cmd_Idle (  ),
      .VFBC7_Wd_Clk ( net_gnd0 ),
      .VFBC7_Wd_Reset ( net_gnd0 ),
      .VFBC7_Wd_Write ( net_gnd0 ),
      .VFBC7_Wd_End_Burst ( net_gnd0 ),
      .VFBC7_Wd_Flush ( net_gnd0 ),
      .VFBC7_Wd_Data ( net_gnd32[0:31] ),
      .VFBC7_Wd_Data_BE ( net_gnd4[0:3] ),
      .VFBC7_Wd_Full (  ),
      .VFBC7_Wd_Almost_Full (  ),
      .VFBC7_Rd_Clk ( net_gnd0 ),
      .VFBC7_Rd_Reset ( net_gnd0 ),
      .VFBC7_Rd_Read ( net_gnd0 ),
      .VFBC7_Rd_End_Burst ( net_gnd0 ),
      .VFBC7_Rd_Flush ( net_gnd0 ),
      .VFBC7_Rd_Data (  ),
      .VFBC7_Rd_Empty (  ),
      .VFBC7_Rd_Almost_Empty (  ),
      .MPMC_CTRL_Clk ( net_vcc0 ),
      .MPMC_CTRL_Rst ( net_gnd0 ),
      .MPMC_CTRL_PLB_ABus ( net_gnd32 ),
      .MPMC_CTRL_PLB_PAValid ( net_gnd0 ),
      .MPMC_CTRL_PLB_SAValid ( net_gnd0 ),
      .MPMC_CTRL_PLB_masterID ( net_gnd1[0:0] ),
      .MPMC_CTRL_PLB_RNW ( net_gnd0 ),
      .MPMC_CTRL_PLB_BE ( net_gnd8 ),
      .MPMC_CTRL_PLB_UABus ( net_gnd32 ),
      .MPMC_CTRL_PLB_rdPrim ( net_gnd0 ),
      .MPMC_CTRL_PLB_wrPrim ( net_gnd0 ),
      .MPMC_CTRL_PLB_abort ( net_gnd0 ),
      .MPMC_CTRL_PLB_busLock ( net_gnd0 ),
      .MPMC_CTRL_PLB_MSize ( net_gnd2 ),
      .MPMC_CTRL_PLB_size ( net_gnd4 ),
      .MPMC_CTRL_PLB_type ( net_gnd3 ),
      .MPMC_CTRL_PLB_lockErr ( net_gnd0 ),
      .MPMC_CTRL_PLB_wrPendReq ( net_gnd0 ),
      .MPMC_CTRL_PLB_wrPendPri ( net_gnd2 ),
      .MPMC_CTRL_PLB_rdPendReq ( net_gnd0 ),
      .MPMC_CTRL_PLB_rdPendPri ( net_gnd2 ),
      .MPMC_CTRL_PLB_reqPri ( net_gnd2 ),
      .MPMC_CTRL_PLB_TAttribute ( net_gnd16 ),
      .MPMC_CTRL_PLB_rdBurst ( net_gnd0 ),
      .MPMC_CTRL_PLB_wrBurst ( net_gnd0 ),
      .MPMC_CTRL_PLB_wrDBus ( net_gnd64 ),
      .MPMC_CTRL_Sl_addrAck (  ),
      .MPMC_CTRL_Sl_SSize (  ),
      .MPMC_CTRL_Sl_wait (  ),
      .MPMC_CTRL_Sl_rearbitrate (  ),
      .MPMC_CTRL_Sl_wrDAck (  ),
      .MPMC_CTRL_Sl_wrComp (  ),
      .MPMC_CTRL_Sl_wrBTerm (  ),
      .MPMC_CTRL_Sl_rdDBus (  ),
      .MPMC_CTRL_Sl_rdWdAddr (  ),
      .MPMC_CTRL_Sl_rdDAck (  ),
      .MPMC_CTRL_Sl_rdComp (  ),
      .MPMC_CTRL_Sl_rdBTerm (  ),
      .MPMC_CTRL_Sl_MBusy (  ),
      .MPMC_CTRL_Sl_MRdErr (  ),
      .MPMC_CTRL_Sl_MWrErr (  ),
      .MPMC_CTRL_Sl_MIRQ (  ),
      .MPMC_Clk0 ( sys_clk_s ),
      .MPMC_Clk0_DIV2 ( net_vcc0 ),
      .MPMC_Clk90 ( DDR_SDRAM_mpmc_clk_90_s ),
      .MPMC_Clk_200MHz ( net_vcc0 ),
      .MPMC_Rst ( sys_periph_reset[0] ),
      .MPMC_Clk_Mem ( DDR_SDRAM_MPMC_Clk_Mem ),
      .MPMC_Idelayctrl_Rdy_I ( net_vcc0 ),
      .MPMC_Idelayctrl_Rdy_O (  ),
      .MPMC_InitDone (  ),
      .MPMC_ECC_Intr (  ),
      .MPMC_DCM_PSEN (  ),
      .MPMC_DCM_PSINCDEC (  ),
      .MPMC_DCM_PSDONE ( net_gnd0 ),
      .SDRAM_Clk (  ),
      .SDRAM_CE (  ),
      .SDRAM_CS_n (  ),
      .SDRAM_RAS_n (  ),
      .SDRAM_CAS_n (  ),
      .SDRAM_WE_n (  ),
      .SDRAM_BankAddr (  ),
      .SDRAM_Addr (  ),
      .SDRAM_DQ (  ),
      .SDRAM_DM (  ),
      .DDR_Clk ( fpga_0_DDR_SDRAM_DDR_Clk ),
      .DDR_Clk_n ( fpga_0_DDR_SDRAM_DDR_Clk_n ),
      .DDR_CE ( fpga_0_DDR_SDRAM_DDR_CE[0:0] ),
      .DDR_CS_n ( fpga_0_DDR_SDRAM_DDR_CS_n[0:0] ),
      .DDR_RAS_n ( fpga_0_DDR_SDRAM_DDR_RAS_n ),
      .DDR_CAS_n ( fpga_0_DDR_SDRAM_DDR_CAS_n ),
      .DDR_WE_n ( fpga_0_DDR_SDRAM_DDR_WE_n ),
      .DDR_BankAddr ( fpga_0_DDR_SDRAM_DDR_BankAddr ),
      .DDR_Addr ( fpga_0_DDR_SDRAM_DDR_Addr ),
      .DDR_DQ ( fpga_0_DDR_SDRAM_DDR_DQ ),
      .DDR_DM ( fpga_0_DDR_SDRAM_DDR_DM ),
      .DDR_DQS ( fpga_0_DDR_SDRAM_DDR_DQS ),
      .DDR_DQS_Div_O (  ),
      .DDR_DQS_Div_I ( net_gnd0 ),
      .DDR2_Clk (  ),
      .DDR2_Clk_n (  ),
      .DDR2_CE (  ),
      .DDR2_CS_n (  ),
      .DDR2_ODT (  ),
      .DDR2_RAS_n (  ),
      .DDR2_CAS_n (  ),
      .DDR2_WE_n (  ),
      .DDR2_BankAddr (  ),
      .DDR2_Addr (  ),
      .DDR2_DQ (  ),
      .DDR2_DM (  ),
      .DDR2_DQS (  ),
      .DDR2_DQS_n (  ),
      .DDR2_DQS_Div_O (  ),
      .DDR2_DQS_Div_I ( net_gnd0 )
    );

  clock_generator_ddr_wrapper
    clock_generator_ddr (
      .CLKIN ( dcm_clk_s ),
      .CLKFBIN ( net_gnd0 ),
      .CLKOUT0 ( sys_clk_s ),
      .CLKOUT1 ( DDR_SDRAM_mpmc_clk_90_s ),
      .CLKOUT2 ( DDR_SDRAM_MPMC_Clk_Mem ),
      .CLKOUT3 (  ),
      .CLKOUT4 (  ),
      .CLKOUT5 (  ),
      .CLKOUT6 (  ),
      .CLKOUT7 (  ),
      .CLKOUT8 (  ),
      .CLKOUT9 (  ),
      .CLKOUT10 (  ),
      .CLKOUT11 (  ),
      .CLKOUT12 (  ),
      .CLKOUT13 (  ),
      .CLKOUT14 (  ),
      .CLKOUT15 (  ),
      .CLKFBOUT (  ),
      .RST ( net_gnd0 ),
      .LOCKED ( Dcm_all_locked )
    );

  proc_sys_reset_ddr_wrapper
    proc_sys_reset_ddr (
      .Slowest_sync_clk ( sys_clk_s ),
      .Ext_Reset_In ( sys_rst_s ),
      .Aux_Reset_In ( net_gnd0 ),
      .MB_Debug_Sys_Rst ( net_gnd0 ),
      .Core_Reset_Req_0 ( net_gnd0 ),
      .Chip_Reset_Req_0 ( net_gnd0 ),
      .System_Reset_Req_0 ( net_gnd0 ),
      .Core_Reset_Req_1 ( net_gnd0 ),
      .Chip_Reset_Req_1 ( net_gnd0 ),
      .System_Reset_Req_1 ( net_gnd0 ),
      .Dcm_locked ( Dcm_all_locked ),
      .RstcPPCresetcore_0 (  ),
      .RstcPPCresetchip_0 (  ),
      .RstcPPCresetsys_0 (  ),
      .RstcPPCresetcore_1 (  ),
      .RstcPPCresetchip_1 (  ),
      .RstcPPCresetsys_1 (  ),
      .MB_Reset (  ),
      .Bus_Struct_Reset (  ),
      .Peripheral_Reset ( sys_periph_reset[0:0] )
    );

endmodule

// synthesis attribute BOX_TYPE of ddr_sdram_wrapper is black_box;
// synthesis attribute BOX_TYPE of clock_generator_ddr_wrapper is black_box;
// synthesis attribute BOX_TYPE of proc_sys_reset_ddr_wrapper is black_box;

module ddr_sdram_wrapper
  (
    FSL0_M_Clk,
    FSL0_M_Write,
    FSL0_M_Data,
    FSL0_M_Control,
    FSL0_M_Full,
    FSL0_S_Clk,
    FSL0_S_Read,
    FSL0_S_Data,
    FSL0_S_Control,
    FSL0_S_Exists,
    SPLB0_Clk,
    SPLB0_Rst,
    SPLB0_PLB_ABus,
    SPLB0_PLB_PAValid,
    SPLB0_PLB_SAValid,
    SPLB0_PLB_masterID,
    SPLB0_PLB_RNW,
    SPLB0_PLB_BE,
    SPLB0_PLB_UABus,
    SPLB0_PLB_rdPrim,
    SPLB0_PLB_wrPrim,
    SPLB0_PLB_abort,
    SPLB0_PLB_busLock,
    SPLB0_PLB_MSize,
    SPLB0_PLB_size,
    SPLB0_PLB_type,
    SPLB0_PLB_lockErr,
    SPLB0_PLB_wrPendReq,
    SPLB0_PLB_wrPendPri,
    SPLB0_PLB_rdPendReq,
    SPLB0_PLB_rdPendPri,
    SPLB0_PLB_reqPri,
    SPLB0_PLB_TAttribute,
    SPLB0_PLB_rdBurst,
    SPLB0_PLB_wrBurst,
    SPLB0_PLB_wrDBus,
    SPLB0_Sl_addrAck,
    SPLB0_Sl_SSize,
    SPLB0_Sl_wait,
    SPLB0_Sl_rearbitrate,
    SPLB0_Sl_wrDAck,
    SPLB0_Sl_wrComp,
    SPLB0_Sl_wrBTerm,
    SPLB0_Sl_rdDBus,
    SPLB0_Sl_rdWdAddr,
    SPLB0_Sl_rdDAck,
    SPLB0_Sl_rdComp,
    SPLB0_Sl_rdBTerm,
    SPLB0_Sl_MBusy,
    SPLB0_Sl_MRdErr,
    SPLB0_Sl_MWrErr,
    SPLB0_Sl_MIRQ,
    SDMA0_Clk,
    SDMA0_Rx_IntOut,
    SDMA0_Tx_IntOut,
    SDMA0_RstOut,
    SDMA0_TX_D,
    SDMA0_TX_Rem,
    SDMA0_TX_SOF,
    SDMA0_TX_EOF,
    SDMA0_TX_SOP,
    SDMA0_TX_EOP,
    SDMA0_TX_Src_Rdy,
    SDMA0_TX_Dst_Rdy,
    SDMA0_RX_D,
    SDMA0_RX_Rem,
    SDMA0_RX_SOF,
    SDMA0_RX_EOF,
    SDMA0_RX_SOP,
    SDMA0_RX_EOP,
    SDMA0_RX_Src_Rdy,
    SDMA0_RX_Dst_Rdy,
    SDMA_CTRL0_Clk,
    SDMA_CTRL0_Rst,
    SDMA_CTRL0_PLB_ABus,
    SDMA_CTRL0_PLB_PAValid,
    SDMA_CTRL0_PLB_SAValid,
    SDMA_CTRL0_PLB_masterID,
    SDMA_CTRL0_PLB_RNW,
    SDMA_CTRL0_PLB_BE,
    SDMA_CTRL0_PLB_UABus,
    SDMA_CTRL0_PLB_rdPrim,
    SDMA_CTRL0_PLB_wrPrim,
    SDMA_CTRL0_PLB_abort,
    SDMA_CTRL0_PLB_busLock,
    SDMA_CTRL0_PLB_MSize,
    SDMA_CTRL0_PLB_size,
    SDMA_CTRL0_PLB_type,
    SDMA_CTRL0_PLB_lockErr,
    SDMA_CTRL0_PLB_wrPendReq,
    SDMA_CTRL0_PLB_wrPendPri,
    SDMA_CTRL0_PLB_rdPendReq,
    SDMA_CTRL0_PLB_rdPendPri,
    SDMA_CTRL0_PLB_reqPri,
    SDMA_CTRL0_PLB_TAttribute,
    SDMA_CTRL0_PLB_rdBurst,
    SDMA_CTRL0_PLB_wrBurst,
    SDMA_CTRL0_PLB_wrDBus,
    SDMA_CTRL0_Sl_addrAck,
    SDMA_CTRL0_Sl_SSize,
    SDMA_CTRL0_Sl_wait,
    SDMA_CTRL0_Sl_rearbitrate,
    SDMA_CTRL0_Sl_wrDAck,
    SDMA_CTRL0_Sl_wrComp,
    SDMA_CTRL0_Sl_wrBTerm,
    SDMA_CTRL0_Sl_rdDBus,
    SDMA_CTRL0_Sl_rdWdAddr,
    SDMA_CTRL0_Sl_rdDAck,
    SDMA_CTRL0_Sl_rdComp,
    SDMA_CTRL0_Sl_rdBTerm,
    SDMA_CTRL0_Sl_MBusy,
    SDMA_CTRL0_Sl_MRdErr,
    SDMA_CTRL0_Sl_MWrErr,
    SDMA_CTRL0_Sl_MIRQ,
    PIM0_Addr,
    PIM0_AddrReq,
    PIM0_AddrAck,
    PIM0_RNW,
    PIM0_Size,
    PIM0_RdModWr,
    PIM0_WrFIFO_Data,
    PIM0_WrFIFO_BE,
    PIM0_WrFIFO_Push,
    PIM0_RdFIFO_Data,
    PIM0_RdFIFO_Pop,
    PIM0_RdFIFO_RdWdAddr,
    PIM0_WrFIFO_Empty,
    PIM0_WrFIFO_AlmostFull,
    PIM0_WrFIFO_Flush,
    PIM0_RdFIFO_Empty,
    PIM0_RdFIFO_Flush,
    PIM0_RdFIFO_Latency,
    PIM0_InitDone,
    PPC440MC0_MIMCReadNotWrite,
    PPC440MC0_MIMCAddress,
    PPC440MC0_MIMCAddressValid,
    PPC440MC0_MIMCWriteData,
    PPC440MC0_MIMCWriteDataValid,
    PPC440MC0_MIMCByteEnable,
    PPC440MC0_MIMCBankConflict,
    PPC440MC0_MIMCRowConflict,
    PPC440MC0_MCMIReadData,
    PPC440MC0_MCMIReadDataValid,
    PPC440MC0_MCMIReadDataErr,
    PPC440MC0_MCMIAddrReadyToAccept,
    VFBC0_Cmd_Clk,
    VFBC0_Cmd_Reset,
    VFBC0_Cmd_Data,
    VFBC0_Cmd_Write,
    VFBC0_Cmd_End,
    VFBC0_Cmd_Full,
    VFBC0_Cmd_Almost_Full,
    VFBC0_Cmd_Idle,
    VFBC0_Wd_Clk,
    VFBC0_Wd_Reset,
    VFBC0_Wd_Write,
    VFBC0_Wd_End_Burst,
    VFBC0_Wd_Flush,
    VFBC0_Wd_Data,
    VFBC0_Wd_Data_BE,
    VFBC0_Wd_Full,
    VFBC0_Wd_Almost_Full,
    VFBC0_Rd_Clk,
    VFBC0_Rd_Reset,
    VFBC0_Rd_Read,
    VFBC0_Rd_End_Burst,
    VFBC0_Rd_Flush,
    VFBC0_Rd_Data,
    VFBC0_Rd_Empty,
    VFBC0_Rd_Almost_Empty,
    FSL1_M_Clk,
    FSL1_M_Write,
    FSL1_M_Data,
    FSL1_M_Control,
    FSL1_M_Full,
    FSL1_S_Clk,
    FSL1_S_Read,
    FSL1_S_Data,
    FSL1_S_Control,
    FSL1_S_Exists,
    SPLB1_Clk,
    SPLB1_Rst,
    SPLB1_PLB_ABus,
    SPLB1_PLB_PAValid,
    SPLB1_PLB_SAValid,
    SPLB1_PLB_masterID,
    SPLB1_PLB_RNW,
    SPLB1_PLB_BE,
    SPLB1_PLB_UABus,
    SPLB1_PLB_rdPrim,
    SPLB1_PLB_wrPrim,
    SPLB1_PLB_abort,
    SPLB1_PLB_busLock,
    SPLB1_PLB_MSize,
    SPLB1_PLB_size,
    SPLB1_PLB_type,
    SPLB1_PLB_lockErr,
    SPLB1_PLB_wrPendReq,
    SPLB1_PLB_wrPendPri,
    SPLB1_PLB_rdPendReq,
    SPLB1_PLB_rdPendPri,
    SPLB1_PLB_reqPri,
    SPLB1_PLB_TAttribute,
    SPLB1_PLB_rdBurst,
    SPLB1_PLB_wrBurst,
    SPLB1_PLB_wrDBus,
    SPLB1_Sl_addrAck,
    SPLB1_Sl_SSize,
    SPLB1_Sl_wait,
    SPLB1_Sl_rearbitrate,
    SPLB1_Sl_wrDAck,
    SPLB1_Sl_wrComp,
    SPLB1_Sl_wrBTerm,
    SPLB1_Sl_rdDBus,
    SPLB1_Sl_rdWdAddr,
    SPLB1_Sl_rdDAck,
    SPLB1_Sl_rdComp,
    SPLB1_Sl_rdBTerm,
    SPLB1_Sl_MBusy,
    SPLB1_Sl_MRdErr,
    SPLB1_Sl_MWrErr,
    SPLB1_Sl_MIRQ,
    SDMA1_Clk,
    SDMA1_Rx_IntOut,
    SDMA1_Tx_IntOut,
    SDMA1_RstOut,
    SDMA1_TX_D,
    SDMA1_TX_Rem,
    SDMA1_TX_SOF,
    SDMA1_TX_EOF,
    SDMA1_TX_SOP,
    SDMA1_TX_EOP,
    SDMA1_TX_Src_Rdy,
    SDMA1_TX_Dst_Rdy,
    SDMA1_RX_D,
    SDMA1_RX_Rem,
    SDMA1_RX_SOF,
    SDMA1_RX_EOF,
    SDMA1_RX_SOP,
    SDMA1_RX_EOP,
    SDMA1_RX_Src_Rdy,
    SDMA1_RX_Dst_Rdy,
    SDMA_CTRL1_Clk,
    SDMA_CTRL1_Rst,
    SDMA_CTRL1_PLB_ABus,
    SDMA_CTRL1_PLB_PAValid,
    SDMA_CTRL1_PLB_SAValid,
    SDMA_CTRL1_PLB_masterID,
    SDMA_CTRL1_PLB_RNW,
    SDMA_CTRL1_PLB_BE,
    SDMA_CTRL1_PLB_UABus,
    SDMA_CTRL1_PLB_rdPrim,
    SDMA_CTRL1_PLB_wrPrim,
    SDMA_CTRL1_PLB_abort,
    SDMA_CTRL1_PLB_busLock,
    SDMA_CTRL1_PLB_MSize,
    SDMA_CTRL1_PLB_size,
    SDMA_CTRL1_PLB_type,
    SDMA_CTRL1_PLB_lockErr,
    SDMA_CTRL1_PLB_wrPendReq,
    SDMA_CTRL1_PLB_wrPendPri,
    SDMA_CTRL1_PLB_rdPendReq,
    SDMA_CTRL1_PLB_rdPendPri,
    SDMA_CTRL1_PLB_reqPri,
    SDMA_CTRL1_PLB_TAttribute,
    SDMA_CTRL1_PLB_rdBurst,
    SDMA_CTRL1_PLB_wrBurst,
    SDMA_CTRL1_PLB_wrDBus,
    SDMA_CTRL1_Sl_addrAck,
    SDMA_CTRL1_Sl_SSize,
    SDMA_CTRL1_Sl_wait,
    SDMA_CTRL1_Sl_rearbitrate,
    SDMA_CTRL1_Sl_wrDAck,
    SDMA_CTRL1_Sl_wrComp,
    SDMA_CTRL1_Sl_wrBTerm,
    SDMA_CTRL1_Sl_rdDBus,
    SDMA_CTRL1_Sl_rdWdAddr,
    SDMA_CTRL1_Sl_rdDAck,
    SDMA_CTRL1_Sl_rdComp,
    SDMA_CTRL1_Sl_rdBTerm,
    SDMA_CTRL1_Sl_MBusy,
    SDMA_CTRL1_Sl_MRdErr,
    SDMA_CTRL1_Sl_MWrErr,
    SDMA_CTRL1_Sl_MIRQ,
    PIM1_Addr,
    PIM1_AddrReq,
    PIM1_AddrAck,
    PIM1_RNW,
    PIM1_Size,
    PIM1_RdModWr,
    PIM1_WrFIFO_Data,
    PIM1_WrFIFO_BE,
    PIM1_WrFIFO_Push,
    PIM1_RdFIFO_Data,
    PIM1_RdFIFO_Pop,
    PIM1_RdFIFO_RdWdAddr,
    PIM1_WrFIFO_Empty,
    PIM1_WrFIFO_AlmostFull,
    PIM1_WrFIFO_Flush,
    PIM1_RdFIFO_Empty,
    PIM1_RdFIFO_Flush,
    PIM1_RdFIFO_Latency,
    PIM1_InitDone,
    PPC440MC1_MIMCReadNotWrite,
    PPC440MC1_MIMCAddress,
    PPC440MC1_MIMCAddressValid,
    PPC440MC1_MIMCWriteData,
    PPC440MC1_MIMCWriteDataValid,
    PPC440MC1_MIMCByteEnable,
    PPC440MC1_MIMCBankConflict,
    PPC440MC1_MIMCRowConflict,
    PPC440MC1_MCMIReadData,
    PPC440MC1_MCMIReadDataValid,
    PPC440MC1_MCMIReadDataErr,
    PPC440MC1_MCMIAddrReadyToAccept,
    VFBC1_Cmd_Clk,
    VFBC1_Cmd_Reset,
    VFBC1_Cmd_Data,
    VFBC1_Cmd_Write,
    VFBC1_Cmd_End,
    VFBC1_Cmd_Full,
    VFBC1_Cmd_Almost_Full,
    VFBC1_Cmd_Idle,
    VFBC1_Wd_Clk,
    VFBC1_Wd_Reset,
    VFBC1_Wd_Write,
    VFBC1_Wd_End_Burst,
    VFBC1_Wd_Flush,
    VFBC1_Wd_Data,
    VFBC1_Wd_Data_BE,
    VFBC1_Wd_Full,
    VFBC1_Wd_Almost_Full,
    VFBC1_Rd_Clk,
    VFBC1_Rd_Reset,
    VFBC1_Rd_Read,
    VFBC1_Rd_End_Burst,
    VFBC1_Rd_Flush,
    VFBC1_Rd_Data,
    VFBC1_Rd_Empty,
    VFBC1_Rd_Almost_Empty,
    FSL2_M_Clk,
    FSL2_M_Write,
    FSL2_M_Data,
    FSL2_M_Control,
    FSL2_M_Full,
    FSL2_S_Clk,
    FSL2_S_Read,
    FSL2_S_Data,
    FSL2_S_Control,
    FSL2_S_Exists,
    SPLB2_Clk,
    SPLB2_Rst,
    SPLB2_PLB_ABus,
    SPLB2_PLB_PAValid,
    SPLB2_PLB_SAValid,
    SPLB2_PLB_masterID,
    SPLB2_PLB_RNW,
    SPLB2_PLB_BE,
    SPLB2_PLB_UABus,
    SPLB2_PLB_rdPrim,
    SPLB2_PLB_wrPrim,
    SPLB2_PLB_abort,
    SPLB2_PLB_busLock,
    SPLB2_PLB_MSize,
    SPLB2_PLB_size,
    SPLB2_PLB_type,
    SPLB2_PLB_lockErr,
    SPLB2_PLB_wrPendReq,
    SPLB2_PLB_wrPendPri,
    SPLB2_PLB_rdPendReq,
    SPLB2_PLB_rdPendPri,
    SPLB2_PLB_reqPri,
    SPLB2_PLB_TAttribute,
    SPLB2_PLB_rdBurst,
    SPLB2_PLB_wrBurst,
    SPLB2_PLB_wrDBus,
    SPLB2_Sl_addrAck,
    SPLB2_Sl_SSize,
    SPLB2_Sl_wait,
    SPLB2_Sl_rearbitrate,
    SPLB2_Sl_wrDAck,
    SPLB2_Sl_wrComp,
    SPLB2_Sl_wrBTerm,
    SPLB2_Sl_rdDBus,
    SPLB2_Sl_rdWdAddr,
    SPLB2_Sl_rdDAck,
    SPLB2_Sl_rdComp,
    SPLB2_Sl_rdBTerm,
    SPLB2_Sl_MBusy,
    SPLB2_Sl_MRdErr,
    SPLB2_Sl_MWrErr,
    SPLB2_Sl_MIRQ,
    SDMA2_Clk,
    SDMA2_Rx_IntOut,
    SDMA2_Tx_IntOut,
    SDMA2_RstOut,
    SDMA2_TX_D,
    SDMA2_TX_Rem,
    SDMA2_TX_SOF,
    SDMA2_TX_EOF,
    SDMA2_TX_SOP,
    SDMA2_TX_EOP,
    SDMA2_TX_Src_Rdy,
    SDMA2_TX_Dst_Rdy,
    SDMA2_RX_D,
    SDMA2_RX_Rem,
    SDMA2_RX_SOF,
    SDMA2_RX_EOF,
    SDMA2_RX_SOP,
    SDMA2_RX_EOP,
    SDMA2_RX_Src_Rdy,
    SDMA2_RX_Dst_Rdy,
    SDMA_CTRL2_Clk,
    SDMA_CTRL2_Rst,
    SDMA_CTRL2_PLB_ABus,
    SDMA_CTRL2_PLB_PAValid,
    SDMA_CTRL2_PLB_SAValid,
    SDMA_CTRL2_PLB_masterID,
    SDMA_CTRL2_PLB_RNW,
    SDMA_CTRL2_PLB_BE,
    SDMA_CTRL2_PLB_UABus,
    SDMA_CTRL2_PLB_rdPrim,
    SDMA_CTRL2_PLB_wrPrim,
    SDMA_CTRL2_PLB_abort,
    SDMA_CTRL2_PLB_busLock,
    SDMA_CTRL2_PLB_MSize,
    SDMA_CTRL2_PLB_size,
    SDMA_CTRL2_PLB_type,
    SDMA_CTRL2_PLB_lockErr,
    SDMA_CTRL2_PLB_wrPendReq,
    SDMA_CTRL2_PLB_wrPendPri,
    SDMA_CTRL2_PLB_rdPendReq,
    SDMA_CTRL2_PLB_rdPendPri,
    SDMA_CTRL2_PLB_reqPri,
    SDMA_CTRL2_PLB_TAttribute,
    SDMA_CTRL2_PLB_rdBurst,
    SDMA_CTRL2_PLB_wrBurst,
    SDMA_CTRL2_PLB_wrDBus,
    SDMA_CTRL2_Sl_addrAck,
    SDMA_CTRL2_Sl_SSize,
    SDMA_CTRL2_Sl_wait,
    SDMA_CTRL2_Sl_rearbitrate,
    SDMA_CTRL2_Sl_wrDAck,
    SDMA_CTRL2_Sl_wrComp,
    SDMA_CTRL2_Sl_wrBTerm,
    SDMA_CTRL2_Sl_rdDBus,
    SDMA_CTRL2_Sl_rdWdAddr,
    SDMA_CTRL2_Sl_rdDAck,
    SDMA_CTRL2_Sl_rdComp,
    SDMA_CTRL2_Sl_rdBTerm,
    SDMA_CTRL2_Sl_MBusy,
    SDMA_CTRL2_Sl_MRdErr,
    SDMA_CTRL2_Sl_MWrErr,
    SDMA_CTRL2_Sl_MIRQ,
    PIM2_Addr,
    PIM2_AddrReq,
    PIM2_AddrAck,
    PIM2_RNW,
    PIM2_Size,
    PIM2_RdModWr,
    PIM2_WrFIFO_Data,
    PIM2_WrFIFO_BE,
    PIM2_WrFIFO_Push,
    PIM2_RdFIFO_Data,
    PIM2_RdFIFO_Pop,
    PIM2_RdFIFO_RdWdAddr,
    PIM2_WrFIFO_Empty,
    PIM2_WrFIFO_AlmostFull,
    PIM2_WrFIFO_Flush,
    PIM2_RdFIFO_Empty,
    PIM2_RdFIFO_Flush,
    PIM2_RdFIFO_Latency,
    PIM2_InitDone,
    PPC440MC2_MIMCReadNotWrite,
    PPC440MC2_MIMCAddress,
    PPC440MC2_MIMCAddressValid,
    PPC440MC2_MIMCWriteData,
    PPC440MC2_MIMCWriteDataValid,
    PPC440MC2_MIMCByteEnable,
    PPC440MC2_MIMCBankConflict,
    PPC440MC2_MIMCRowConflict,
    PPC440MC2_MCMIReadData,
    PPC440MC2_MCMIReadDataValid,
    PPC440MC2_MCMIReadDataErr,
    PPC440MC2_MCMIAddrReadyToAccept,
    VFBC2_Cmd_Clk,
    VFBC2_Cmd_Reset,
    VFBC2_Cmd_Data,
    VFBC2_Cmd_Write,
    VFBC2_Cmd_End,
    VFBC2_Cmd_Full,
    VFBC2_Cmd_Almost_Full,
    VFBC2_Cmd_Idle,
    VFBC2_Wd_Clk,
    VFBC2_Wd_Reset,
    VFBC2_Wd_Write,
    VFBC2_Wd_End_Burst,
    VFBC2_Wd_Flush,
    VFBC2_Wd_Data,
    VFBC2_Wd_Data_BE,
    VFBC2_Wd_Full,
    VFBC2_Wd_Almost_Full,
    VFBC2_Rd_Clk,
    VFBC2_Rd_Reset,
    VFBC2_Rd_Read,
    VFBC2_Rd_End_Burst,
    VFBC2_Rd_Flush,
    VFBC2_Rd_Data,
    VFBC2_Rd_Empty,
    VFBC2_Rd_Almost_Empty,
    FSL3_M_Clk,
    FSL3_M_Write,
    FSL3_M_Data,
    FSL3_M_Control,
    FSL3_M_Full,
    FSL3_S_Clk,
    FSL3_S_Read,
    FSL3_S_Data,
    FSL3_S_Control,
    FSL3_S_Exists,
    SPLB3_Clk,
    SPLB3_Rst,
    SPLB3_PLB_ABus,
    SPLB3_PLB_PAValid,
    SPLB3_PLB_SAValid,
    SPLB3_PLB_masterID,
    SPLB3_PLB_RNW,
    SPLB3_PLB_BE,
    SPLB3_PLB_UABus,
    SPLB3_PLB_rdPrim,
    SPLB3_PLB_wrPrim,
    SPLB3_PLB_abort,
    SPLB3_PLB_busLock,
    SPLB3_PLB_MSize,
    SPLB3_PLB_size,
    SPLB3_PLB_type,
    SPLB3_PLB_lockErr,
    SPLB3_PLB_wrPendReq,
    SPLB3_PLB_wrPendPri,
    SPLB3_PLB_rdPendReq,
    SPLB3_PLB_rdPendPri,
    SPLB3_PLB_reqPri,
    SPLB3_PLB_TAttribute,
    SPLB3_PLB_rdBurst,
    SPLB3_PLB_wrBurst,
    SPLB3_PLB_wrDBus,
    SPLB3_Sl_addrAck,
    SPLB3_Sl_SSize,
    SPLB3_Sl_wait,
    SPLB3_Sl_rearbitrate,
    SPLB3_Sl_wrDAck,
    SPLB3_Sl_wrComp,
    SPLB3_Sl_wrBTerm,
    SPLB3_Sl_rdDBus,
    SPLB3_Sl_rdWdAddr,
    SPLB3_Sl_rdDAck,
    SPLB3_Sl_rdComp,
    SPLB3_Sl_rdBTerm,
    SPLB3_Sl_MBusy,
    SPLB3_Sl_MRdErr,
    SPLB3_Sl_MWrErr,
    SPLB3_Sl_MIRQ,
    SDMA3_Clk,
    SDMA3_Rx_IntOut,
    SDMA3_Tx_IntOut,
    SDMA3_RstOut,
    SDMA3_TX_D,
    SDMA3_TX_Rem,
    SDMA3_TX_SOF,
    SDMA3_TX_EOF,
    SDMA3_TX_SOP,
    SDMA3_TX_EOP,
    SDMA3_TX_Src_Rdy,
    SDMA3_TX_Dst_Rdy,
    SDMA3_RX_D,
    SDMA3_RX_Rem,
    SDMA3_RX_SOF,
    SDMA3_RX_EOF,
    SDMA3_RX_SOP,
    SDMA3_RX_EOP,
    SDMA3_RX_Src_Rdy,
    SDMA3_RX_Dst_Rdy,
    SDMA_CTRL3_Clk,
    SDMA_CTRL3_Rst,
    SDMA_CTRL3_PLB_ABus,
    SDMA_CTRL3_PLB_PAValid,
    SDMA_CTRL3_PLB_SAValid,
    SDMA_CTRL3_PLB_masterID,
    SDMA_CTRL3_PLB_RNW,
    SDMA_CTRL3_PLB_BE,
    SDMA_CTRL3_PLB_UABus,
    SDMA_CTRL3_PLB_rdPrim,
    SDMA_CTRL3_PLB_wrPrim,
    SDMA_CTRL3_PLB_abort,
    SDMA_CTRL3_PLB_busLock,
    SDMA_CTRL3_PLB_MSize,
    SDMA_CTRL3_PLB_size,
    SDMA_CTRL3_PLB_type,
    SDMA_CTRL3_PLB_lockErr,
    SDMA_CTRL3_PLB_wrPendReq,
    SDMA_CTRL3_PLB_wrPendPri,
    SDMA_CTRL3_PLB_rdPendReq,
    SDMA_CTRL3_PLB_rdPendPri,
    SDMA_CTRL3_PLB_reqPri,
    SDMA_CTRL3_PLB_TAttribute,
    SDMA_CTRL3_PLB_rdBurst,
    SDMA_CTRL3_PLB_wrBurst,
    SDMA_CTRL3_PLB_wrDBus,
    SDMA_CTRL3_Sl_addrAck,
    SDMA_CTRL3_Sl_SSize,
    SDMA_CTRL3_Sl_wait,
    SDMA_CTRL3_Sl_rearbitrate,
    SDMA_CTRL3_Sl_wrDAck,
    SDMA_CTRL3_Sl_wrComp,
    SDMA_CTRL3_Sl_wrBTerm,
    SDMA_CTRL3_Sl_rdDBus,
    SDMA_CTRL3_Sl_rdWdAddr,
    SDMA_CTRL3_Sl_rdDAck,
    SDMA_CTRL3_Sl_rdComp,
    SDMA_CTRL3_Sl_rdBTerm,
    SDMA_CTRL3_Sl_MBusy,
    SDMA_CTRL3_Sl_MRdErr,
    SDMA_CTRL3_Sl_MWrErr,
    SDMA_CTRL3_Sl_MIRQ,
    PIM3_Addr,
    PIM3_AddrReq,
    PIM3_AddrAck,
    PIM3_RNW,
    PIM3_Size,
    PIM3_RdModWr,
    PIM3_WrFIFO_Data,
    PIM3_WrFIFO_BE,
    PIM3_WrFIFO_Push,
    PIM3_RdFIFO_Data,
    PIM3_RdFIFO_Pop,
    PIM3_RdFIFO_RdWdAddr,
    PIM3_WrFIFO_Empty,
    PIM3_WrFIFO_AlmostFull,
    PIM3_WrFIFO_Flush,
    PIM3_RdFIFO_Empty,
    PIM3_RdFIFO_Flush,
    PIM3_RdFIFO_Latency,
    PIM3_InitDone,
    PPC440MC3_MIMCReadNotWrite,
    PPC440MC3_MIMCAddress,
    PPC440MC3_MIMCAddressValid,
    PPC440MC3_MIMCWriteData,
    PPC440MC3_MIMCWriteDataValid,
    PPC440MC3_MIMCByteEnable,
    PPC440MC3_MIMCBankConflict,
    PPC440MC3_MIMCRowConflict,
    PPC440MC3_MCMIReadData,
    PPC440MC3_MCMIReadDataValid,
    PPC440MC3_MCMIReadDataErr,
    PPC440MC3_MCMIAddrReadyToAccept,
    VFBC3_Cmd_Clk,
    VFBC3_Cmd_Reset,
    VFBC3_Cmd_Data,
    VFBC3_Cmd_Write,
    VFBC3_Cmd_End,
    VFBC3_Cmd_Full,
    VFBC3_Cmd_Almost_Full,
    VFBC3_Cmd_Idle,
    VFBC3_Wd_Clk,
    VFBC3_Wd_Reset,
    VFBC3_Wd_Write,
    VFBC3_Wd_End_Burst,
    VFBC3_Wd_Flush,
    VFBC3_Wd_Data,
    VFBC3_Wd_Data_BE,
    VFBC3_Wd_Full,
    VFBC3_Wd_Almost_Full,
    VFBC3_Rd_Clk,
    VFBC3_Rd_Reset,
    VFBC3_Rd_Read,
    VFBC3_Rd_End_Burst,
    VFBC3_Rd_Flush,
    VFBC3_Rd_Data,
    VFBC3_Rd_Empty,
    VFBC3_Rd_Almost_Empty,
    FSL4_M_Clk,
    FSL4_M_Write,
    FSL4_M_Data,
    FSL4_M_Control,
    FSL4_M_Full,
    FSL4_S_Clk,
    FSL4_S_Read,
    FSL4_S_Data,
    FSL4_S_Control,
    FSL4_S_Exists,
    SPLB4_Clk,
    SPLB4_Rst,
    SPLB4_PLB_ABus,
    SPLB4_PLB_PAValid,
    SPLB4_PLB_SAValid,
    SPLB4_PLB_masterID,
    SPLB4_PLB_RNW,
    SPLB4_PLB_BE,
    SPLB4_PLB_UABus,
    SPLB4_PLB_rdPrim,
    SPLB4_PLB_wrPrim,
    SPLB4_PLB_abort,
    SPLB4_PLB_busLock,
    SPLB4_PLB_MSize,
    SPLB4_PLB_size,
    SPLB4_PLB_type,
    SPLB4_PLB_lockErr,
    SPLB4_PLB_wrPendReq,
    SPLB4_PLB_wrPendPri,
    SPLB4_PLB_rdPendReq,
    SPLB4_PLB_rdPendPri,
    SPLB4_PLB_reqPri,
    SPLB4_PLB_TAttribute,
    SPLB4_PLB_rdBurst,
    SPLB4_PLB_wrBurst,
    SPLB4_PLB_wrDBus,
    SPLB4_Sl_addrAck,
    SPLB4_Sl_SSize,
    SPLB4_Sl_wait,
    SPLB4_Sl_rearbitrate,
    SPLB4_Sl_wrDAck,
    SPLB4_Sl_wrComp,
    SPLB4_Sl_wrBTerm,
    SPLB4_Sl_rdDBus,
    SPLB4_Sl_rdWdAddr,
    SPLB4_Sl_rdDAck,
    SPLB4_Sl_rdComp,
    SPLB4_Sl_rdBTerm,
    SPLB4_Sl_MBusy,
    SPLB4_Sl_MRdErr,
    SPLB4_Sl_MWrErr,
    SPLB4_Sl_MIRQ,
    SDMA4_Clk,
    SDMA4_Rx_IntOut,
    SDMA4_Tx_IntOut,
    SDMA4_RstOut,
    SDMA4_TX_D,
    SDMA4_TX_Rem,
    SDMA4_TX_SOF,
    SDMA4_TX_EOF,
    SDMA4_TX_SOP,
    SDMA4_TX_EOP,
    SDMA4_TX_Src_Rdy,
    SDMA4_TX_Dst_Rdy,
    SDMA4_RX_D,
    SDMA4_RX_Rem,
    SDMA4_RX_SOF,
    SDMA4_RX_EOF,
    SDMA4_RX_SOP,
    SDMA4_RX_EOP,
    SDMA4_RX_Src_Rdy,
    SDMA4_RX_Dst_Rdy,
    SDMA_CTRL4_Clk,
    SDMA_CTRL4_Rst,
    SDMA_CTRL4_PLB_ABus,
    SDMA_CTRL4_PLB_PAValid,
    SDMA_CTRL4_PLB_SAValid,
    SDMA_CTRL4_PLB_masterID,
    SDMA_CTRL4_PLB_RNW,
    SDMA_CTRL4_PLB_BE,
    SDMA_CTRL4_PLB_UABus,
    SDMA_CTRL4_PLB_rdPrim,
    SDMA_CTRL4_PLB_wrPrim,
    SDMA_CTRL4_PLB_abort,
    SDMA_CTRL4_PLB_busLock,
    SDMA_CTRL4_PLB_MSize,
    SDMA_CTRL4_PLB_size,
    SDMA_CTRL4_PLB_type,
    SDMA_CTRL4_PLB_lockErr,
    SDMA_CTRL4_PLB_wrPendReq,
    SDMA_CTRL4_PLB_wrPendPri,
    SDMA_CTRL4_PLB_rdPendReq,
    SDMA_CTRL4_PLB_rdPendPri,
    SDMA_CTRL4_PLB_reqPri,
    SDMA_CTRL4_PLB_TAttribute,
    SDMA_CTRL4_PLB_rdBurst,
    SDMA_CTRL4_PLB_wrBurst,
    SDMA_CTRL4_PLB_wrDBus,
    SDMA_CTRL4_Sl_addrAck,
    SDMA_CTRL4_Sl_SSize,
    SDMA_CTRL4_Sl_wait,
    SDMA_CTRL4_Sl_rearbitrate,
    SDMA_CTRL4_Sl_wrDAck,
    SDMA_CTRL4_Sl_wrComp,
    SDMA_CTRL4_Sl_wrBTerm,
    SDMA_CTRL4_Sl_rdDBus,
    SDMA_CTRL4_Sl_rdWdAddr,
    SDMA_CTRL4_Sl_rdDAck,
    SDMA_CTRL4_Sl_rdComp,
    SDMA_CTRL4_Sl_rdBTerm,
    SDMA_CTRL4_Sl_MBusy,
    SDMA_CTRL4_Sl_MRdErr,
    SDMA_CTRL4_Sl_MWrErr,
    SDMA_CTRL4_Sl_MIRQ,
    PIM4_Addr,
    PIM4_AddrReq,
    PIM4_AddrAck,
    PIM4_RNW,
    PIM4_Size,
    PIM4_RdModWr,
    PIM4_WrFIFO_Data,
    PIM4_WrFIFO_BE,
    PIM4_WrFIFO_Push,
    PIM4_RdFIFO_Data,
    PIM4_RdFIFO_Pop,
    PIM4_RdFIFO_RdWdAddr,
    PIM4_WrFIFO_Empty,
    PIM4_WrFIFO_AlmostFull,
    PIM4_WrFIFO_Flush,
    PIM4_RdFIFO_Empty,
    PIM4_RdFIFO_Flush,
    PIM4_RdFIFO_Latency,
    PIM4_InitDone,
    PPC440MC4_MIMCReadNotWrite,
    PPC440MC4_MIMCAddress,
    PPC440MC4_MIMCAddressValid,
    PPC440MC4_MIMCWriteData,
    PPC440MC4_MIMCWriteDataValid,
    PPC440MC4_MIMCByteEnable,
    PPC440MC4_MIMCBankConflict,
    PPC440MC4_MIMCRowConflict,
    PPC440MC4_MCMIReadData,
    PPC440MC4_MCMIReadDataValid,
    PPC440MC4_MCMIReadDataErr,
    PPC440MC4_MCMIAddrReadyToAccept,
    VFBC4_Cmd_Clk,
    VFBC4_Cmd_Reset,
    VFBC4_Cmd_Data,
    VFBC4_Cmd_Write,
    VFBC4_Cmd_End,
    VFBC4_Cmd_Full,
    VFBC4_Cmd_Almost_Full,
    VFBC4_Cmd_Idle,
    VFBC4_Wd_Clk,
    VFBC4_Wd_Reset,
    VFBC4_Wd_Write,
    VFBC4_Wd_End_Burst,
    VFBC4_Wd_Flush,
    VFBC4_Wd_Data,
    VFBC4_Wd_Data_BE,
    VFBC4_Wd_Full,
    VFBC4_Wd_Almost_Full,
    VFBC4_Rd_Clk,
    VFBC4_Rd_Reset,
    VFBC4_Rd_Read,
    VFBC4_Rd_End_Burst,
    VFBC4_Rd_Flush,
    VFBC4_Rd_Data,
    VFBC4_Rd_Empty,
    VFBC4_Rd_Almost_Empty,
    FSL5_M_Clk,
    FSL5_M_Write,
    FSL5_M_Data,
    FSL5_M_Control,
    FSL5_M_Full,
    FSL5_S_Clk,
    FSL5_S_Read,
    FSL5_S_Data,
    FSL5_S_Control,
    FSL5_S_Exists,
    SPLB5_Clk,
    SPLB5_Rst,
    SPLB5_PLB_ABus,
    SPLB5_PLB_PAValid,
    SPLB5_PLB_SAValid,
    SPLB5_PLB_masterID,
    SPLB5_PLB_RNW,
    SPLB5_PLB_BE,
    SPLB5_PLB_UABus,
    SPLB5_PLB_rdPrim,
    SPLB5_PLB_wrPrim,
    SPLB5_PLB_abort,
    SPLB5_PLB_busLock,
    SPLB5_PLB_MSize,
    SPLB5_PLB_size,
    SPLB5_PLB_type,
    SPLB5_PLB_lockErr,
    SPLB5_PLB_wrPendReq,
    SPLB5_PLB_wrPendPri,
    SPLB5_PLB_rdPendReq,
    SPLB5_PLB_rdPendPri,
    SPLB5_PLB_reqPri,
    SPLB5_PLB_TAttribute,
    SPLB5_PLB_rdBurst,
    SPLB5_PLB_wrBurst,
    SPLB5_PLB_wrDBus,
    SPLB5_Sl_addrAck,
    SPLB5_Sl_SSize,
    SPLB5_Sl_wait,
    SPLB5_Sl_rearbitrate,
    SPLB5_Sl_wrDAck,
    SPLB5_Sl_wrComp,
    SPLB5_Sl_wrBTerm,
    SPLB5_Sl_rdDBus,
    SPLB5_Sl_rdWdAddr,
    SPLB5_Sl_rdDAck,
    SPLB5_Sl_rdComp,
    SPLB5_Sl_rdBTerm,
    SPLB5_Sl_MBusy,
    SPLB5_Sl_MRdErr,
    SPLB5_Sl_MWrErr,
    SPLB5_Sl_MIRQ,
    SDMA5_Clk,
    SDMA5_Rx_IntOut,
    SDMA5_Tx_IntOut,
    SDMA5_RstOut,
    SDMA5_TX_D,
    SDMA5_TX_Rem,
    SDMA5_TX_SOF,
    SDMA5_TX_EOF,
    SDMA5_TX_SOP,
    SDMA5_TX_EOP,
    SDMA5_TX_Src_Rdy,
    SDMA5_TX_Dst_Rdy,
    SDMA5_RX_D,
    SDMA5_RX_Rem,
    SDMA5_RX_SOF,
    SDMA5_RX_EOF,
    SDMA5_RX_SOP,
    SDMA5_RX_EOP,
    SDMA5_RX_Src_Rdy,
    SDMA5_RX_Dst_Rdy,
    SDMA_CTRL5_Clk,
    SDMA_CTRL5_Rst,
    SDMA_CTRL5_PLB_ABus,
    SDMA_CTRL5_PLB_PAValid,
    SDMA_CTRL5_PLB_SAValid,
    SDMA_CTRL5_PLB_masterID,
    SDMA_CTRL5_PLB_RNW,
    SDMA_CTRL5_PLB_BE,
    SDMA_CTRL5_PLB_UABus,
    SDMA_CTRL5_PLB_rdPrim,
    SDMA_CTRL5_PLB_wrPrim,
    SDMA_CTRL5_PLB_abort,
    SDMA_CTRL5_PLB_busLock,
    SDMA_CTRL5_PLB_MSize,
    SDMA_CTRL5_PLB_size,
    SDMA_CTRL5_PLB_type,
    SDMA_CTRL5_PLB_lockErr,
    SDMA_CTRL5_PLB_wrPendReq,
    SDMA_CTRL5_PLB_wrPendPri,
    SDMA_CTRL5_PLB_rdPendReq,
    SDMA_CTRL5_PLB_rdPendPri,
    SDMA_CTRL5_PLB_reqPri,
    SDMA_CTRL5_PLB_TAttribute,
    SDMA_CTRL5_PLB_rdBurst,
    SDMA_CTRL5_PLB_wrBurst,
    SDMA_CTRL5_PLB_wrDBus,
    SDMA_CTRL5_Sl_addrAck,
    SDMA_CTRL5_Sl_SSize,
    SDMA_CTRL5_Sl_wait,
    SDMA_CTRL5_Sl_rearbitrate,
    SDMA_CTRL5_Sl_wrDAck,
    SDMA_CTRL5_Sl_wrComp,
    SDMA_CTRL5_Sl_wrBTerm,
    SDMA_CTRL5_Sl_rdDBus,
    SDMA_CTRL5_Sl_rdWdAddr,
    SDMA_CTRL5_Sl_rdDAck,
    SDMA_CTRL5_Sl_rdComp,
    SDMA_CTRL5_Sl_rdBTerm,
    SDMA_CTRL5_Sl_MBusy,
    SDMA_CTRL5_Sl_MRdErr,
    SDMA_CTRL5_Sl_MWrErr,
    SDMA_CTRL5_Sl_MIRQ,
    PIM5_Addr,
    PIM5_AddrReq,
    PIM5_AddrAck,
    PIM5_RNW,
    PIM5_Size,
    PIM5_RdModWr,
    PIM5_WrFIFO_Data,
    PIM5_WrFIFO_BE,
    PIM5_WrFIFO_Push,
    PIM5_RdFIFO_Data,
    PIM5_RdFIFO_Pop,
    PIM5_RdFIFO_RdWdAddr,
    PIM5_WrFIFO_Empty,
    PIM5_WrFIFO_AlmostFull,
    PIM5_WrFIFO_Flush,
    PIM5_RdFIFO_Empty,
    PIM5_RdFIFO_Flush,
    PIM5_RdFIFO_Latency,
    PIM5_InitDone,
    PPC440MC5_MIMCReadNotWrite,
    PPC440MC5_MIMCAddress,
    PPC440MC5_MIMCAddressValid,
    PPC440MC5_MIMCWriteData,
    PPC440MC5_MIMCWriteDataValid,
    PPC440MC5_MIMCByteEnable,
    PPC440MC5_MIMCBankConflict,
    PPC440MC5_MIMCRowConflict,
    PPC440MC5_MCMIReadData,
    PPC440MC5_MCMIReadDataValid,
    PPC440MC5_MCMIReadDataErr,
    PPC440MC5_MCMIAddrReadyToAccept,
    VFBC5_Cmd_Clk,
    VFBC5_Cmd_Reset,
    VFBC5_Cmd_Data,
    VFBC5_Cmd_Write,
    VFBC5_Cmd_End,
    VFBC5_Cmd_Full,
    VFBC5_Cmd_Almost_Full,
    VFBC5_Cmd_Idle,
    VFBC5_Wd_Clk,
    VFBC5_Wd_Reset,
    VFBC5_Wd_Write,
    VFBC5_Wd_End_Burst,
    VFBC5_Wd_Flush,
    VFBC5_Wd_Data,
    VFBC5_Wd_Data_BE,
    VFBC5_Wd_Full,
    VFBC5_Wd_Almost_Full,
    VFBC5_Rd_Clk,
    VFBC5_Rd_Reset,
    VFBC5_Rd_Read,
    VFBC5_Rd_End_Burst,
    VFBC5_Rd_Flush,
    VFBC5_Rd_Data,
    VFBC5_Rd_Empty,
    VFBC5_Rd_Almost_Empty,
    FSL6_M_Clk,
    FSL6_M_Write,
    FSL6_M_Data,
    FSL6_M_Control,
    FSL6_M_Full,
    FSL6_S_Clk,
    FSL6_S_Read,
    FSL6_S_Data,
    FSL6_S_Control,
    FSL6_S_Exists,
    SPLB6_Clk,
    SPLB6_Rst,
    SPLB6_PLB_ABus,
    SPLB6_PLB_PAValid,
    SPLB6_PLB_SAValid,
    SPLB6_PLB_masterID,
    SPLB6_PLB_RNW,
    SPLB6_PLB_BE,
    SPLB6_PLB_UABus,
    SPLB6_PLB_rdPrim,
    SPLB6_PLB_wrPrim,
    SPLB6_PLB_abort,
    SPLB6_PLB_busLock,
    SPLB6_PLB_MSize,
    SPLB6_PLB_size,
    SPLB6_PLB_type,
    SPLB6_PLB_lockErr,
    SPLB6_PLB_wrPendReq,
    SPLB6_PLB_wrPendPri,
    SPLB6_PLB_rdPendReq,
    SPLB6_PLB_rdPendPri,
    SPLB6_PLB_reqPri,
    SPLB6_PLB_TAttribute,
    SPLB6_PLB_rdBurst,
    SPLB6_PLB_wrBurst,
    SPLB6_PLB_wrDBus,
    SPLB6_Sl_addrAck,
    SPLB6_Sl_SSize,
    SPLB6_Sl_wait,
    SPLB6_Sl_rearbitrate,
    SPLB6_Sl_wrDAck,
    SPLB6_Sl_wrComp,
    SPLB6_Sl_wrBTerm,
    SPLB6_Sl_rdDBus,
    SPLB6_Sl_rdWdAddr,
    SPLB6_Sl_rdDAck,
    SPLB6_Sl_rdComp,
    SPLB6_Sl_rdBTerm,
    SPLB6_Sl_MBusy,
    SPLB6_Sl_MRdErr,
    SPLB6_Sl_MWrErr,
    SPLB6_Sl_MIRQ,
    SDMA6_Clk,
    SDMA6_Rx_IntOut,
    SDMA6_Tx_IntOut,
    SDMA6_RstOut,
    SDMA6_TX_D,
    SDMA6_TX_Rem,
    SDMA6_TX_SOF,
    SDMA6_TX_EOF,
    SDMA6_TX_SOP,
    SDMA6_TX_EOP,
    SDMA6_TX_Src_Rdy,
    SDMA6_TX_Dst_Rdy,
    SDMA6_RX_D,
    SDMA6_RX_Rem,
    SDMA6_RX_SOF,
    SDMA6_RX_EOF,
    SDMA6_RX_SOP,
    SDMA6_RX_EOP,
    SDMA6_RX_Src_Rdy,
    SDMA6_RX_Dst_Rdy,
    SDMA_CTRL6_Clk,
    SDMA_CTRL6_Rst,
    SDMA_CTRL6_PLB_ABus,
    SDMA_CTRL6_PLB_PAValid,
    SDMA_CTRL6_PLB_SAValid,
    SDMA_CTRL6_PLB_masterID,
    SDMA_CTRL6_PLB_RNW,
    SDMA_CTRL6_PLB_BE,
    SDMA_CTRL6_PLB_UABus,
    SDMA_CTRL6_PLB_rdPrim,
    SDMA_CTRL6_PLB_wrPrim,
    SDMA_CTRL6_PLB_abort,
    SDMA_CTRL6_PLB_busLock,
    SDMA_CTRL6_PLB_MSize,
    SDMA_CTRL6_PLB_size,
    SDMA_CTRL6_PLB_type,
    SDMA_CTRL6_PLB_lockErr,
    SDMA_CTRL6_PLB_wrPendReq,
    SDMA_CTRL6_PLB_wrPendPri,
    SDMA_CTRL6_PLB_rdPendReq,
    SDMA_CTRL6_PLB_rdPendPri,
    SDMA_CTRL6_PLB_reqPri,
    SDMA_CTRL6_PLB_TAttribute,
    SDMA_CTRL6_PLB_rdBurst,
    SDMA_CTRL6_PLB_wrBurst,
    SDMA_CTRL6_PLB_wrDBus,
    SDMA_CTRL6_Sl_addrAck,
    SDMA_CTRL6_Sl_SSize,
    SDMA_CTRL6_Sl_wait,
    SDMA_CTRL6_Sl_rearbitrate,
    SDMA_CTRL6_Sl_wrDAck,
    SDMA_CTRL6_Sl_wrComp,
    SDMA_CTRL6_Sl_wrBTerm,
    SDMA_CTRL6_Sl_rdDBus,
    SDMA_CTRL6_Sl_rdWdAddr,
    SDMA_CTRL6_Sl_rdDAck,
    SDMA_CTRL6_Sl_rdComp,
    SDMA_CTRL6_Sl_rdBTerm,
    SDMA_CTRL6_Sl_MBusy,
    SDMA_CTRL6_Sl_MRdErr,
    SDMA_CTRL6_Sl_MWrErr,
    SDMA_CTRL6_Sl_MIRQ,
    PIM6_Addr,
    PIM6_AddrReq,
    PIM6_AddrAck,
    PIM6_RNW,
    PIM6_Size,
    PIM6_RdModWr,
    PIM6_WrFIFO_Data,
    PIM6_WrFIFO_BE,
    PIM6_WrFIFO_Push,
    PIM6_RdFIFO_Data,
    PIM6_RdFIFO_Pop,
    PIM6_RdFIFO_RdWdAddr,
    PIM6_WrFIFO_Empty,
    PIM6_WrFIFO_AlmostFull,
    PIM6_WrFIFO_Flush,
    PIM6_RdFIFO_Empty,
    PIM6_RdFIFO_Flush,
    PIM6_RdFIFO_Latency,
    PIM6_InitDone,
    PPC440MC6_MIMCReadNotWrite,
    PPC440MC6_MIMCAddress,
    PPC440MC6_MIMCAddressValid,
    PPC440MC6_MIMCWriteData,
    PPC440MC6_MIMCWriteDataValid,
    PPC440MC6_MIMCByteEnable,
    PPC440MC6_MIMCBankConflict,
    PPC440MC6_MIMCRowConflict,
    PPC440MC6_MCMIReadData,
    PPC440MC6_MCMIReadDataValid,
    PPC440MC6_MCMIReadDataErr,
    PPC440MC6_MCMIAddrReadyToAccept,
    VFBC6_Cmd_Clk,
    VFBC6_Cmd_Reset,
    VFBC6_Cmd_Data,
    VFBC6_Cmd_Write,
    VFBC6_Cmd_End,
    VFBC6_Cmd_Full,
    VFBC6_Cmd_Almost_Full,
    VFBC6_Cmd_Idle,
    VFBC6_Wd_Clk,
    VFBC6_Wd_Reset,
    VFBC6_Wd_Write,
    VFBC6_Wd_End_Burst,
    VFBC6_Wd_Flush,
    VFBC6_Wd_Data,
    VFBC6_Wd_Data_BE,
    VFBC6_Wd_Full,
    VFBC6_Wd_Almost_Full,
    VFBC6_Rd_Clk,
    VFBC6_Rd_Reset,
    VFBC6_Rd_Read,
    VFBC6_Rd_End_Burst,
    VFBC6_Rd_Flush,
    VFBC6_Rd_Data,
    VFBC6_Rd_Empty,
    VFBC6_Rd_Almost_Empty,
    FSL7_M_Clk,
    FSL7_M_Write,
    FSL7_M_Data,
    FSL7_M_Control,
    FSL7_M_Full,
    FSL7_S_Clk,
    FSL7_S_Read,
    FSL7_S_Data,
    FSL7_S_Control,
    FSL7_S_Exists,
    SPLB7_Clk,
    SPLB7_Rst,
    SPLB7_PLB_ABus,
    SPLB7_PLB_PAValid,
    SPLB7_PLB_SAValid,
    SPLB7_PLB_masterID,
    SPLB7_PLB_RNW,
    SPLB7_PLB_BE,
    SPLB7_PLB_UABus,
    SPLB7_PLB_rdPrim,
    SPLB7_PLB_wrPrim,
    SPLB7_PLB_abort,
    SPLB7_PLB_busLock,
    SPLB7_PLB_MSize,
    SPLB7_PLB_size,
    SPLB7_PLB_type,
    SPLB7_PLB_lockErr,
    SPLB7_PLB_wrPendReq,
    SPLB7_PLB_wrPendPri,
    SPLB7_PLB_rdPendReq,
    SPLB7_PLB_rdPendPri,
    SPLB7_PLB_reqPri,
    SPLB7_PLB_TAttribute,
    SPLB7_PLB_rdBurst,
    SPLB7_PLB_wrBurst,
    SPLB7_PLB_wrDBus,
    SPLB7_Sl_addrAck,
    SPLB7_Sl_SSize,
    SPLB7_Sl_wait,
    SPLB7_Sl_rearbitrate,
    SPLB7_Sl_wrDAck,
    SPLB7_Sl_wrComp,
    SPLB7_Sl_wrBTerm,
    SPLB7_Sl_rdDBus,
    SPLB7_Sl_rdWdAddr,
    SPLB7_Sl_rdDAck,
    SPLB7_Sl_rdComp,
    SPLB7_Sl_rdBTerm,
    SPLB7_Sl_MBusy,
    SPLB7_Sl_MRdErr,
    SPLB7_Sl_MWrErr,
    SPLB7_Sl_MIRQ,
    SDMA7_Clk,
    SDMA7_Rx_IntOut,
    SDMA7_Tx_IntOut,
    SDMA7_RstOut,
    SDMA7_TX_D,
    SDMA7_TX_Rem,
    SDMA7_TX_SOF,
    SDMA7_TX_EOF,
    SDMA7_TX_SOP,
    SDMA7_TX_EOP,
    SDMA7_TX_Src_Rdy,
    SDMA7_TX_Dst_Rdy,
    SDMA7_RX_D,
    SDMA7_RX_Rem,
    SDMA7_RX_SOF,
    SDMA7_RX_EOF,
    SDMA7_RX_SOP,
    SDMA7_RX_EOP,
    SDMA7_RX_Src_Rdy,
    SDMA7_RX_Dst_Rdy,
    SDMA_CTRL7_Clk,
    SDMA_CTRL7_Rst,
    SDMA_CTRL7_PLB_ABus,
    SDMA_CTRL7_PLB_PAValid,
    SDMA_CTRL7_PLB_SAValid,
    SDMA_CTRL7_PLB_masterID,
    SDMA_CTRL7_PLB_RNW,
    SDMA_CTRL7_PLB_BE,
    SDMA_CTRL7_PLB_UABus,
    SDMA_CTRL7_PLB_rdPrim,
    SDMA_CTRL7_PLB_wrPrim,
    SDMA_CTRL7_PLB_abort,
    SDMA_CTRL7_PLB_busLock,
    SDMA_CTRL7_PLB_MSize,
    SDMA_CTRL7_PLB_size,
    SDMA_CTRL7_PLB_type,
    SDMA_CTRL7_PLB_lockErr,
    SDMA_CTRL7_PLB_wrPendReq,
    SDMA_CTRL7_PLB_wrPendPri,
    SDMA_CTRL7_PLB_rdPendReq,
    SDMA_CTRL7_PLB_rdPendPri,
    SDMA_CTRL7_PLB_reqPri,
    SDMA_CTRL7_PLB_TAttribute,
    SDMA_CTRL7_PLB_rdBurst,
    SDMA_CTRL7_PLB_wrBurst,
    SDMA_CTRL7_PLB_wrDBus,
    SDMA_CTRL7_Sl_addrAck,
    SDMA_CTRL7_Sl_SSize,
    SDMA_CTRL7_Sl_wait,
    SDMA_CTRL7_Sl_rearbitrate,
    SDMA_CTRL7_Sl_wrDAck,
    SDMA_CTRL7_Sl_wrComp,
    SDMA_CTRL7_Sl_wrBTerm,
    SDMA_CTRL7_Sl_rdDBus,
    SDMA_CTRL7_Sl_rdWdAddr,
    SDMA_CTRL7_Sl_rdDAck,
    SDMA_CTRL7_Sl_rdComp,
    SDMA_CTRL7_Sl_rdBTerm,
    SDMA_CTRL7_Sl_MBusy,
    SDMA_CTRL7_Sl_MRdErr,
    SDMA_CTRL7_Sl_MWrErr,
    SDMA_CTRL7_Sl_MIRQ,
    PIM7_Addr,
    PIM7_AddrReq,
    PIM7_AddrAck,
    PIM7_RNW,
    PIM7_Size,
    PIM7_RdModWr,
    PIM7_WrFIFO_Data,
    PIM7_WrFIFO_BE,
    PIM7_WrFIFO_Push,
    PIM7_RdFIFO_Data,
    PIM7_RdFIFO_Pop,
    PIM7_RdFIFO_RdWdAddr,
    PIM7_WrFIFO_Empty,
    PIM7_WrFIFO_AlmostFull,
    PIM7_WrFIFO_Flush,
    PIM7_RdFIFO_Empty,
    PIM7_RdFIFO_Flush,
    PIM7_RdFIFO_Latency,
    PIM7_InitDone,
    PPC440MC7_MIMCReadNotWrite,
    PPC440MC7_MIMCAddress,
    PPC440MC7_MIMCAddressValid,
    PPC440MC7_MIMCWriteData,
    PPC440MC7_MIMCWriteDataValid,
    PPC440MC7_MIMCByteEnable,
    PPC440MC7_MIMCBankConflict,
    PPC440MC7_MIMCRowConflict,
    PPC440MC7_MCMIReadData,
    PPC440MC7_MCMIReadDataValid,
    PPC440MC7_MCMIReadDataErr,
    PPC440MC7_MCMIAddrReadyToAccept,
    VFBC7_Cmd_Clk,
    VFBC7_Cmd_Reset,
    VFBC7_Cmd_Data,
    VFBC7_Cmd_Write,
    VFBC7_Cmd_End,
    VFBC7_Cmd_Full,
    VFBC7_Cmd_Almost_Full,
    VFBC7_Cmd_Idle,
    VFBC7_Wd_Clk,
    VFBC7_Wd_Reset,
    VFBC7_Wd_Write,
    VFBC7_Wd_End_Burst,
    VFBC7_Wd_Flush,
    VFBC7_Wd_Data,
    VFBC7_Wd_Data_BE,
    VFBC7_Wd_Full,
    VFBC7_Wd_Almost_Full,
    VFBC7_Rd_Clk,
    VFBC7_Rd_Reset,
    VFBC7_Rd_Read,
    VFBC7_Rd_End_Burst,
    VFBC7_Rd_Flush,
    VFBC7_Rd_Data,
    VFBC7_Rd_Empty,
    VFBC7_Rd_Almost_Empty,
    MPMC_CTRL_Clk,
    MPMC_CTRL_Rst,
    MPMC_CTRL_PLB_ABus,
    MPMC_CTRL_PLB_PAValid,
    MPMC_CTRL_PLB_SAValid,
    MPMC_CTRL_PLB_masterID,
    MPMC_CTRL_PLB_RNW,
    MPMC_CTRL_PLB_BE,
    MPMC_CTRL_PLB_UABus,
    MPMC_CTRL_PLB_rdPrim,
    MPMC_CTRL_PLB_wrPrim,
    MPMC_CTRL_PLB_abort,
    MPMC_CTRL_PLB_busLock,
    MPMC_CTRL_PLB_MSize,
    MPMC_CTRL_PLB_size,
    MPMC_CTRL_PLB_type,
    MPMC_CTRL_PLB_lockErr,
    MPMC_CTRL_PLB_wrPendReq,
    MPMC_CTRL_PLB_wrPendPri,
    MPMC_CTRL_PLB_rdPendReq,
    MPMC_CTRL_PLB_rdPendPri,
    MPMC_CTRL_PLB_reqPri,
    MPMC_CTRL_PLB_TAttribute,
    MPMC_CTRL_PLB_rdBurst,
    MPMC_CTRL_PLB_wrBurst,
    MPMC_CTRL_PLB_wrDBus,
    MPMC_CTRL_Sl_addrAck,
    MPMC_CTRL_Sl_SSize,
    MPMC_CTRL_Sl_wait,
    MPMC_CTRL_Sl_rearbitrate,
    MPMC_CTRL_Sl_wrDAck,
    MPMC_CTRL_Sl_wrComp,
    MPMC_CTRL_Sl_wrBTerm,
    MPMC_CTRL_Sl_rdDBus,
    MPMC_CTRL_Sl_rdWdAddr,
    MPMC_CTRL_Sl_rdDAck,
    MPMC_CTRL_Sl_rdComp,
    MPMC_CTRL_Sl_rdBTerm,
    MPMC_CTRL_Sl_MBusy,
    MPMC_CTRL_Sl_MRdErr,
    MPMC_CTRL_Sl_MWrErr,
    MPMC_CTRL_Sl_MIRQ,
    MPMC_Clk0,
    MPMC_Clk0_DIV2,
    MPMC_Clk90,
    MPMC_Clk_200MHz,
    MPMC_Rst,
    MPMC_Clk_Mem,
    MPMC_Idelayctrl_Rdy_I,
    MPMC_Idelayctrl_Rdy_O,
    MPMC_InitDone,
    MPMC_ECC_Intr,
    MPMC_DCM_PSEN,
    MPMC_DCM_PSINCDEC,
    MPMC_DCM_PSDONE,
    SDRAM_Clk,
    SDRAM_CE,
    SDRAM_CS_n,
    SDRAM_RAS_n,
    SDRAM_CAS_n,
    SDRAM_WE_n,
    SDRAM_BankAddr,
    SDRAM_Addr,
    SDRAM_DQ,
    SDRAM_DM,
    DDR_Clk,
    DDR_Clk_n,
    DDR_CE,
    DDR_CS_n,
    DDR_RAS_n,
    DDR_CAS_n,
    DDR_WE_n,
    DDR_BankAddr,
    DDR_Addr,
    DDR_DQ,
    DDR_DM,
    DDR_DQS,
    DDR_DQS_Div_O,
    DDR_DQS_Div_I,
    DDR2_Clk,
    DDR2_Clk_n,
    DDR2_CE,
    DDR2_CS_n,
    DDR2_ODT,
    DDR2_RAS_n,
    DDR2_CAS_n,
    DDR2_WE_n,
    DDR2_BankAddr,
    DDR2_Addr,
    DDR2_DQ,
    DDR2_DM,
    DDR2_DQS,
    DDR2_DQS_n,
    DDR2_DQS_Div_O,
    DDR2_DQS_Div_I
  )
/* synthesis syn_black_box black_box_pad_pin="  
    DDR_Clk[2:0],
    DDR_Clk_n[2:0],
    DDR_CE,
    DDR_CS_n,
    DDR_RAS_n,
    DDR_CAS_n,
    DDR_WE_n,
    DDR_BankAddr[1:0],
    DDR_Addr[12:0],
    DDR_DM[7:0]" 
  synthesis syn_black_box black_box_tri_pins="
    DDR_DQS[7:0],
    DDR_DQ[63:0]" */
;
  input FSL0_M_Clk;
  input FSL0_M_Write;
  input [0:31] FSL0_M_Data;
  input FSL0_M_Control;
  output FSL0_M_Full;
  input FSL0_S_Clk;
  input FSL0_S_Read;
  output [0:31] FSL0_S_Data;
  output FSL0_S_Control;
  output FSL0_S_Exists;
  input SPLB0_Clk;
  input SPLB0_Rst;
  input [0:31] SPLB0_PLB_ABus;
  input SPLB0_PLB_PAValid;
  input SPLB0_PLB_SAValid;
  input [0:0] SPLB0_PLB_masterID;
  input SPLB0_PLB_RNW;
  input [0:7] SPLB0_PLB_BE;
  input [0:31] SPLB0_PLB_UABus;
  input SPLB0_PLB_rdPrim;
  input SPLB0_PLB_wrPrim;
  input SPLB0_PLB_abort;
  input SPLB0_PLB_busLock;
  input [0:1] SPLB0_PLB_MSize;
  input [0:3] SPLB0_PLB_size;
  input [0:2] SPLB0_PLB_type;
  input SPLB0_PLB_lockErr;
  input SPLB0_PLB_wrPendReq;
  input [0:1] SPLB0_PLB_wrPendPri;
  input SPLB0_PLB_rdPendReq;
  input [0:1] SPLB0_PLB_rdPendPri;
  input [0:1] SPLB0_PLB_reqPri;
  input [0:15] SPLB0_PLB_TAttribute;
  input SPLB0_PLB_rdBurst;
  input SPLB0_PLB_wrBurst;
  input [0:63] SPLB0_PLB_wrDBus;
  output SPLB0_Sl_addrAck;
  output [0:1] SPLB0_Sl_SSize;
  output SPLB0_Sl_wait;
  output SPLB0_Sl_rearbitrate;
  output SPLB0_Sl_wrDAck;
  output SPLB0_Sl_wrComp;
  output SPLB0_Sl_wrBTerm;
  output [0:63] SPLB0_Sl_rdDBus;
  output [0:3] SPLB0_Sl_rdWdAddr;
  output SPLB0_Sl_rdDAck;
  output SPLB0_Sl_rdComp;
  output SPLB0_Sl_rdBTerm;
  output [0:0] SPLB0_Sl_MBusy;
  output [0:0] SPLB0_Sl_MRdErr;
  output [0:0] SPLB0_Sl_MWrErr;
  output [0:0] SPLB0_Sl_MIRQ;
  input SDMA0_Clk;
  output SDMA0_Rx_IntOut;
  output SDMA0_Tx_IntOut;
  output SDMA0_RstOut;
  output [0:31] SDMA0_TX_D;
  output [0:3] SDMA0_TX_Rem;
  output SDMA0_TX_SOF;
  output SDMA0_TX_EOF;
  output SDMA0_TX_SOP;
  output SDMA0_TX_EOP;
  output SDMA0_TX_Src_Rdy;
  input SDMA0_TX_Dst_Rdy;
  input [0:31] SDMA0_RX_D;
  input [0:3] SDMA0_RX_Rem;
  input SDMA0_RX_SOF;
  input SDMA0_RX_EOF;
  input SDMA0_RX_SOP;
  input SDMA0_RX_EOP;
  input SDMA0_RX_Src_Rdy;
  output SDMA0_RX_Dst_Rdy;
  input SDMA_CTRL0_Clk;
  input SDMA_CTRL0_Rst;
  input [0:31] SDMA_CTRL0_PLB_ABus;
  input SDMA_CTRL0_PLB_PAValid;
  input SDMA_CTRL0_PLB_SAValid;
  input [0:0] SDMA_CTRL0_PLB_masterID;
  input SDMA_CTRL0_PLB_RNW;
  input [0:7] SDMA_CTRL0_PLB_BE;
  input [0:31] SDMA_CTRL0_PLB_UABus;
  input SDMA_CTRL0_PLB_rdPrim;
  input SDMA_CTRL0_PLB_wrPrim;
  input SDMA_CTRL0_PLB_abort;
  input SDMA_CTRL0_PLB_busLock;
  input [0:1] SDMA_CTRL0_PLB_MSize;
  input [0:3] SDMA_CTRL0_PLB_size;
  input [0:2] SDMA_CTRL0_PLB_type;
  input SDMA_CTRL0_PLB_lockErr;
  input SDMA_CTRL0_PLB_wrPendReq;
  input [0:1] SDMA_CTRL0_PLB_wrPendPri;
  input SDMA_CTRL0_PLB_rdPendReq;
  input [0:1] SDMA_CTRL0_PLB_rdPendPri;
  input [0:1] SDMA_CTRL0_PLB_reqPri;
  input [0:15] SDMA_CTRL0_PLB_TAttribute;
  input SDMA_CTRL0_PLB_rdBurst;
  input SDMA_CTRL0_PLB_wrBurst;
  input [0:63] SDMA_CTRL0_PLB_wrDBus;
  output SDMA_CTRL0_Sl_addrAck;
  output [0:1] SDMA_CTRL0_Sl_SSize;
  output SDMA_CTRL0_Sl_wait;
  output SDMA_CTRL0_Sl_rearbitrate;
  output SDMA_CTRL0_Sl_wrDAck;
  output SDMA_CTRL0_Sl_wrComp;
  output SDMA_CTRL0_Sl_wrBTerm;
  output [0:63] SDMA_CTRL0_Sl_rdDBus;
  output [0:3] SDMA_CTRL0_Sl_rdWdAddr;
  output SDMA_CTRL0_Sl_rdDAck;
  output SDMA_CTRL0_Sl_rdComp;
  output SDMA_CTRL0_Sl_rdBTerm;
  output [0:0] SDMA_CTRL0_Sl_MBusy;
  output [0:0] SDMA_CTRL0_Sl_MRdErr;
  output [0:0] SDMA_CTRL0_Sl_MWrErr;
  output [0:0] SDMA_CTRL0_Sl_MIRQ;
  input [31:0] PIM0_Addr;
  input PIM0_AddrReq;
  output PIM0_AddrAck;
  input PIM0_RNW;
  input [3:0] PIM0_Size;
  input PIM0_RdModWr;
  input [63:0] PIM0_WrFIFO_Data;
  input [7:0] PIM0_WrFIFO_BE;
  input PIM0_WrFIFO_Push;
  output [63:0] PIM0_RdFIFO_Data;
  input PIM0_RdFIFO_Pop;
  output [3:0] PIM0_RdFIFO_RdWdAddr;
  output PIM0_WrFIFO_Empty;
  output PIM0_WrFIFO_AlmostFull;
  input PIM0_WrFIFO_Flush;
  output PIM0_RdFIFO_Empty;
  input PIM0_RdFIFO_Flush;
  output [1:0] PIM0_RdFIFO_Latency;
  output PIM0_InitDone;
  input PPC440MC0_MIMCReadNotWrite;
  input [0:35] PPC440MC0_MIMCAddress;
  input PPC440MC0_MIMCAddressValid;
  input [0:127] PPC440MC0_MIMCWriteData;
  input PPC440MC0_MIMCWriteDataValid;
  input [0:15] PPC440MC0_MIMCByteEnable;
  input PPC440MC0_MIMCBankConflict;
  input PPC440MC0_MIMCRowConflict;
  output [0:127] PPC440MC0_MCMIReadData;
  output PPC440MC0_MCMIReadDataValid;
  output PPC440MC0_MCMIReadDataErr;
  output PPC440MC0_MCMIAddrReadyToAccept;
  input VFBC0_Cmd_Clk;
  input VFBC0_Cmd_Reset;
  input [31:0] VFBC0_Cmd_Data;
  input VFBC0_Cmd_Write;
  input VFBC0_Cmd_End;
  output VFBC0_Cmd_Full;
  output VFBC0_Cmd_Almost_Full;
  output VFBC0_Cmd_Idle;
  input VFBC0_Wd_Clk;
  input VFBC0_Wd_Reset;
  input VFBC0_Wd_Write;
  input VFBC0_Wd_End_Burst;
  input VFBC0_Wd_Flush;
  input [31:0] VFBC0_Wd_Data;
  input [3:0] VFBC0_Wd_Data_BE;
  output VFBC0_Wd_Full;
  output VFBC0_Wd_Almost_Full;
  input VFBC0_Rd_Clk;
  input VFBC0_Rd_Reset;
  input VFBC0_Rd_Read;
  input VFBC0_Rd_End_Burst;
  input VFBC0_Rd_Flush;
  output [31:0] VFBC0_Rd_Data;
  output VFBC0_Rd_Empty;
  output VFBC0_Rd_Almost_Empty;
  input FSL1_M_Clk;
  input FSL1_M_Write;
  input [0:31] FSL1_M_Data;
  input FSL1_M_Control;
  output FSL1_M_Full;
  input FSL1_S_Clk;
  input FSL1_S_Read;
  output [0:31] FSL1_S_Data;
  output FSL1_S_Control;
  output FSL1_S_Exists;
  input SPLB1_Clk;
  input SPLB1_Rst;
  input [0:31] SPLB1_PLB_ABus;
  input SPLB1_PLB_PAValid;
  input SPLB1_PLB_SAValid;
  input [0:0] SPLB1_PLB_masterID;
  input SPLB1_PLB_RNW;
  input [0:7] SPLB1_PLB_BE;
  input [0:31] SPLB1_PLB_UABus;
  input SPLB1_PLB_rdPrim;
  input SPLB1_PLB_wrPrim;
  input SPLB1_PLB_abort;
  input SPLB1_PLB_busLock;
  input [0:1] SPLB1_PLB_MSize;
  input [0:3] SPLB1_PLB_size;
  input [0:2] SPLB1_PLB_type;
  input SPLB1_PLB_lockErr;
  input SPLB1_PLB_wrPendReq;
  input [0:1] SPLB1_PLB_wrPendPri;
  input SPLB1_PLB_rdPendReq;
  input [0:1] SPLB1_PLB_rdPendPri;
  input [0:1] SPLB1_PLB_reqPri;
  input [0:15] SPLB1_PLB_TAttribute;
  input SPLB1_PLB_rdBurst;
  input SPLB1_PLB_wrBurst;
  input [0:63] SPLB1_PLB_wrDBus;
  output SPLB1_Sl_addrAck;
  output [0:1] SPLB1_Sl_SSize;
  output SPLB1_Sl_wait;
  output SPLB1_Sl_rearbitrate;
  output SPLB1_Sl_wrDAck;
  output SPLB1_Sl_wrComp;
  output SPLB1_Sl_wrBTerm;
  output [0:63] SPLB1_Sl_rdDBus;
  output [0:3] SPLB1_Sl_rdWdAddr;
  output SPLB1_Sl_rdDAck;
  output SPLB1_Sl_rdComp;
  output SPLB1_Sl_rdBTerm;
  output [0:0] SPLB1_Sl_MBusy;
  output [0:0] SPLB1_Sl_MRdErr;
  output [0:0] SPLB1_Sl_MWrErr;
  output [0:0] SPLB1_Sl_MIRQ;
  input SDMA1_Clk;
  output SDMA1_Rx_IntOut;
  output SDMA1_Tx_IntOut;
  output SDMA1_RstOut;
  output [0:31] SDMA1_TX_D;
  output [0:3] SDMA1_TX_Rem;
  output SDMA1_TX_SOF;
  output SDMA1_TX_EOF;
  output SDMA1_TX_SOP;
  output SDMA1_TX_EOP;
  output SDMA1_TX_Src_Rdy;
  input SDMA1_TX_Dst_Rdy;
  input [0:31] SDMA1_RX_D;
  input [0:3] SDMA1_RX_Rem;
  input SDMA1_RX_SOF;
  input SDMA1_RX_EOF;
  input SDMA1_RX_SOP;
  input SDMA1_RX_EOP;
  input SDMA1_RX_Src_Rdy;
  output SDMA1_RX_Dst_Rdy;
  input SDMA_CTRL1_Clk;
  input SDMA_CTRL1_Rst;
  input [0:31] SDMA_CTRL1_PLB_ABus;
  input SDMA_CTRL1_PLB_PAValid;
  input SDMA_CTRL1_PLB_SAValid;
  input [0:0] SDMA_CTRL1_PLB_masterID;
  input SDMA_CTRL1_PLB_RNW;
  input [0:7] SDMA_CTRL1_PLB_BE;
  input [0:31] SDMA_CTRL1_PLB_UABus;
  input SDMA_CTRL1_PLB_rdPrim;
  input SDMA_CTRL1_PLB_wrPrim;
  input SDMA_CTRL1_PLB_abort;
  input SDMA_CTRL1_PLB_busLock;
  input [0:1] SDMA_CTRL1_PLB_MSize;
  input [0:3] SDMA_CTRL1_PLB_size;
  input [0:2] SDMA_CTRL1_PLB_type;
  input SDMA_CTRL1_PLB_lockErr;
  input SDMA_CTRL1_PLB_wrPendReq;
  input [0:1] SDMA_CTRL1_PLB_wrPendPri;
  input SDMA_CTRL1_PLB_rdPendReq;
  input [0:1] SDMA_CTRL1_PLB_rdPendPri;
  input [0:1] SDMA_CTRL1_PLB_reqPri;
  input [0:15] SDMA_CTRL1_PLB_TAttribute;
  input SDMA_CTRL1_PLB_rdBurst;
  input SDMA_CTRL1_PLB_wrBurst;
  input [0:63] SDMA_CTRL1_PLB_wrDBus;
  output SDMA_CTRL1_Sl_addrAck;
  output [0:1] SDMA_CTRL1_Sl_SSize;
  output SDMA_CTRL1_Sl_wait;
  output SDMA_CTRL1_Sl_rearbitrate;
  output SDMA_CTRL1_Sl_wrDAck;
  output SDMA_CTRL1_Sl_wrComp;
  output SDMA_CTRL1_Sl_wrBTerm;
  output [0:63] SDMA_CTRL1_Sl_rdDBus;
  output [0:3] SDMA_CTRL1_Sl_rdWdAddr;
  output SDMA_CTRL1_Sl_rdDAck;
  output SDMA_CTRL1_Sl_rdComp;
  output SDMA_CTRL1_Sl_rdBTerm;
  output [0:0] SDMA_CTRL1_Sl_MBusy;
  output [0:0] SDMA_CTRL1_Sl_MRdErr;
  output [0:0] SDMA_CTRL1_Sl_MWrErr;
  output [0:0] SDMA_CTRL1_Sl_MIRQ;
  input [31:0] PIM1_Addr;
  input PIM1_AddrReq;
  output PIM1_AddrAck;
  input PIM1_RNW;
  input [3:0] PIM1_Size;
  input PIM1_RdModWr;
  input [63:0] PIM1_WrFIFO_Data;
  input [7:0] PIM1_WrFIFO_BE;
  input PIM1_WrFIFO_Push;
  output [63:0] PIM1_RdFIFO_Data;
  input PIM1_RdFIFO_Pop;
  output [3:0] PIM1_RdFIFO_RdWdAddr;
  output PIM1_WrFIFO_Empty;
  output PIM1_WrFIFO_AlmostFull;
  input PIM1_WrFIFO_Flush;
  output PIM1_RdFIFO_Empty;
  input PIM1_RdFIFO_Flush;
  output [1:0] PIM1_RdFIFO_Latency;
  output PIM1_InitDone;
  input PPC440MC1_MIMCReadNotWrite;
  input [0:35] PPC440MC1_MIMCAddress;
  input PPC440MC1_MIMCAddressValid;
  input [0:127] PPC440MC1_MIMCWriteData;
  input PPC440MC1_MIMCWriteDataValid;
  input [0:15] PPC440MC1_MIMCByteEnable;
  input PPC440MC1_MIMCBankConflict;
  input PPC440MC1_MIMCRowConflict;
  output [0:127] PPC440MC1_MCMIReadData;
  output PPC440MC1_MCMIReadDataValid;
  output PPC440MC1_MCMIReadDataErr;
  output PPC440MC1_MCMIAddrReadyToAccept;
  input VFBC1_Cmd_Clk;
  input VFBC1_Cmd_Reset;
  input [31:0] VFBC1_Cmd_Data;
  input VFBC1_Cmd_Write;
  input VFBC1_Cmd_End;
  output VFBC1_Cmd_Full;
  output VFBC1_Cmd_Almost_Full;
  output VFBC1_Cmd_Idle;
  input VFBC1_Wd_Clk;
  input VFBC1_Wd_Reset;
  input VFBC1_Wd_Write;
  input VFBC1_Wd_End_Burst;
  input VFBC1_Wd_Flush;
  input [31:0] VFBC1_Wd_Data;
  input [3:0] VFBC1_Wd_Data_BE;
  output VFBC1_Wd_Full;
  output VFBC1_Wd_Almost_Full;
  input VFBC1_Rd_Clk;
  input VFBC1_Rd_Reset;
  input VFBC1_Rd_Read;
  input VFBC1_Rd_End_Burst;
  input VFBC1_Rd_Flush;
  output [31:0] VFBC1_Rd_Data;
  output VFBC1_Rd_Empty;
  output VFBC1_Rd_Almost_Empty;
  input FSL2_M_Clk;
  input FSL2_M_Write;
  input [0:31] FSL2_M_Data;
  input FSL2_M_Control;
  output FSL2_M_Full;
  input FSL2_S_Clk;
  input FSL2_S_Read;
  output [0:31] FSL2_S_Data;
  output FSL2_S_Control;
  output FSL2_S_Exists;
  input SPLB2_Clk;
  input SPLB2_Rst;
  input [0:31] SPLB2_PLB_ABus;
  input SPLB2_PLB_PAValid;
  input SPLB2_PLB_SAValid;
  input [0:0] SPLB2_PLB_masterID;
  input SPLB2_PLB_RNW;
  input [0:7] SPLB2_PLB_BE;
  input [0:31] SPLB2_PLB_UABus;
  input SPLB2_PLB_rdPrim;
  input SPLB2_PLB_wrPrim;
  input SPLB2_PLB_abort;
  input SPLB2_PLB_busLock;
  input [0:1] SPLB2_PLB_MSize;
  input [0:3] SPLB2_PLB_size;
  input [0:2] SPLB2_PLB_type;
  input SPLB2_PLB_lockErr;
  input SPLB2_PLB_wrPendReq;
  input [0:1] SPLB2_PLB_wrPendPri;
  input SPLB2_PLB_rdPendReq;
  input [0:1] SPLB2_PLB_rdPendPri;
  input [0:1] SPLB2_PLB_reqPri;
  input [0:15] SPLB2_PLB_TAttribute;
  input SPLB2_PLB_rdBurst;
  input SPLB2_PLB_wrBurst;
  input [0:63] SPLB2_PLB_wrDBus;
  output SPLB2_Sl_addrAck;
  output [0:1] SPLB2_Sl_SSize;
  output SPLB2_Sl_wait;
  output SPLB2_Sl_rearbitrate;
  output SPLB2_Sl_wrDAck;
  output SPLB2_Sl_wrComp;
  output SPLB2_Sl_wrBTerm;
  output [0:63] SPLB2_Sl_rdDBus;
  output [0:3] SPLB2_Sl_rdWdAddr;
  output SPLB2_Sl_rdDAck;
  output SPLB2_Sl_rdComp;
  output SPLB2_Sl_rdBTerm;
  output [0:0] SPLB2_Sl_MBusy;
  output [0:0] SPLB2_Sl_MRdErr;
  output [0:0] SPLB2_Sl_MWrErr;
  output [0:0] SPLB2_Sl_MIRQ;
  input SDMA2_Clk;
  output SDMA2_Rx_IntOut;
  output SDMA2_Tx_IntOut;
  output SDMA2_RstOut;
  output [0:31] SDMA2_TX_D;
  output [0:3] SDMA2_TX_Rem;
  output SDMA2_TX_SOF;
  output SDMA2_TX_EOF;
  output SDMA2_TX_SOP;
  output SDMA2_TX_EOP;
  output SDMA2_TX_Src_Rdy;
  input SDMA2_TX_Dst_Rdy;
  input [0:31] SDMA2_RX_D;
  input [0:3] SDMA2_RX_Rem;
  input SDMA2_RX_SOF;
  input SDMA2_RX_EOF;
  input SDMA2_RX_SOP;
  input SDMA2_RX_EOP;
  input SDMA2_RX_Src_Rdy;
  output SDMA2_RX_Dst_Rdy;
  input SDMA_CTRL2_Clk;
  input SDMA_CTRL2_Rst;
  input [0:31] SDMA_CTRL2_PLB_ABus;
  input SDMA_CTRL2_PLB_PAValid;
  input SDMA_CTRL2_PLB_SAValid;
  input [0:0] SDMA_CTRL2_PLB_masterID;
  input SDMA_CTRL2_PLB_RNW;
  input [0:7] SDMA_CTRL2_PLB_BE;
  input [0:31] SDMA_CTRL2_PLB_UABus;
  input SDMA_CTRL2_PLB_rdPrim;
  input SDMA_CTRL2_PLB_wrPrim;
  input SDMA_CTRL2_PLB_abort;
  input SDMA_CTRL2_PLB_busLock;
  input [0:1] SDMA_CTRL2_PLB_MSize;
  input [0:3] SDMA_CTRL2_PLB_size;
  input [0:2] SDMA_CTRL2_PLB_type;
  input SDMA_CTRL2_PLB_lockErr;
  input SDMA_CTRL2_PLB_wrPendReq;
  input [0:1] SDMA_CTRL2_PLB_wrPendPri;
  input SDMA_CTRL2_PLB_rdPendReq;
  input [0:1] SDMA_CTRL2_PLB_rdPendPri;
  input [0:1] SDMA_CTRL2_PLB_reqPri;
  input [0:15] SDMA_CTRL2_PLB_TAttribute;
  input SDMA_CTRL2_PLB_rdBurst;
  input SDMA_CTRL2_PLB_wrBurst;
  input [0:63] SDMA_CTRL2_PLB_wrDBus;
  output SDMA_CTRL2_Sl_addrAck;
  output [0:1] SDMA_CTRL2_Sl_SSize;
  output SDMA_CTRL2_Sl_wait;
  output SDMA_CTRL2_Sl_rearbitrate;
  output SDMA_CTRL2_Sl_wrDAck;
  output SDMA_CTRL2_Sl_wrComp;
  output SDMA_CTRL2_Sl_wrBTerm;
  output [0:63] SDMA_CTRL2_Sl_rdDBus;
  output [0:3] SDMA_CTRL2_Sl_rdWdAddr;
  output SDMA_CTRL2_Sl_rdDAck;
  output SDMA_CTRL2_Sl_rdComp;
  output SDMA_CTRL2_Sl_rdBTerm;
  output [0:0] SDMA_CTRL2_Sl_MBusy;
  output [0:0] SDMA_CTRL2_Sl_MRdErr;
  output [0:0] SDMA_CTRL2_Sl_MWrErr;
  output [0:0] SDMA_CTRL2_Sl_MIRQ;
  input [31:0] PIM2_Addr;
  input PIM2_AddrReq;
  output PIM2_AddrAck;
  input PIM2_RNW;
  input [3:0] PIM2_Size;
  input PIM2_RdModWr;
  input [63:0] PIM2_WrFIFO_Data;
  input [7:0] PIM2_WrFIFO_BE;
  input PIM2_WrFIFO_Push;
  output [63:0] PIM2_RdFIFO_Data;
  input PIM2_RdFIFO_Pop;
  output [3:0] PIM2_RdFIFO_RdWdAddr;
  output PIM2_WrFIFO_Empty;
  output PIM2_WrFIFO_AlmostFull;
  input PIM2_WrFIFO_Flush;
  output PIM2_RdFIFO_Empty;
  input PIM2_RdFIFO_Flush;
  output [1:0] PIM2_RdFIFO_Latency;
  output PIM2_InitDone;
  input PPC440MC2_MIMCReadNotWrite;
  input [0:35] PPC440MC2_MIMCAddress;
  input PPC440MC2_MIMCAddressValid;
  input [0:127] PPC440MC2_MIMCWriteData;
  input PPC440MC2_MIMCWriteDataValid;
  input [0:15] PPC440MC2_MIMCByteEnable;
  input PPC440MC2_MIMCBankConflict;
  input PPC440MC2_MIMCRowConflict;
  output [0:127] PPC440MC2_MCMIReadData;
  output PPC440MC2_MCMIReadDataValid;
  output PPC440MC2_MCMIReadDataErr;
  output PPC440MC2_MCMIAddrReadyToAccept;
  input VFBC2_Cmd_Clk;
  input VFBC2_Cmd_Reset;
  input [31:0] VFBC2_Cmd_Data;
  input VFBC2_Cmd_Write;
  input VFBC2_Cmd_End;
  output VFBC2_Cmd_Full;
  output VFBC2_Cmd_Almost_Full;
  output VFBC2_Cmd_Idle;
  input VFBC2_Wd_Clk;
  input VFBC2_Wd_Reset;
  input VFBC2_Wd_Write;
  input VFBC2_Wd_End_Burst;
  input VFBC2_Wd_Flush;
  input [31:0] VFBC2_Wd_Data;
  input [3:0] VFBC2_Wd_Data_BE;
  output VFBC2_Wd_Full;
  output VFBC2_Wd_Almost_Full;
  input VFBC2_Rd_Clk;
  input VFBC2_Rd_Reset;
  input VFBC2_Rd_Read;
  input VFBC2_Rd_End_Burst;
  input VFBC2_Rd_Flush;
  output [31:0] VFBC2_Rd_Data;
  output VFBC2_Rd_Empty;
  output VFBC2_Rd_Almost_Empty;
  input FSL3_M_Clk;
  input FSL3_M_Write;
  input [0:31] FSL3_M_Data;
  input FSL3_M_Control;
  output FSL3_M_Full;
  input FSL3_S_Clk;
  input FSL3_S_Read;
  output [0:31] FSL3_S_Data;
  output FSL3_S_Control;
  output FSL3_S_Exists;
  input SPLB3_Clk;
  input SPLB3_Rst;
  input [0:31] SPLB3_PLB_ABus;
  input SPLB3_PLB_PAValid;
  input SPLB3_PLB_SAValid;
  input [0:0] SPLB3_PLB_masterID;
  input SPLB3_PLB_RNW;
  input [0:7] SPLB3_PLB_BE;
  input [0:31] SPLB3_PLB_UABus;
  input SPLB3_PLB_rdPrim;
  input SPLB3_PLB_wrPrim;
  input SPLB3_PLB_abort;
  input SPLB3_PLB_busLock;
  input [0:1] SPLB3_PLB_MSize;
  input [0:3] SPLB3_PLB_size;
  input [0:2] SPLB3_PLB_type;
  input SPLB3_PLB_lockErr;
  input SPLB3_PLB_wrPendReq;
  input [0:1] SPLB3_PLB_wrPendPri;
  input SPLB3_PLB_rdPendReq;
  input [0:1] SPLB3_PLB_rdPendPri;
  input [0:1] SPLB3_PLB_reqPri;
  input [0:15] SPLB3_PLB_TAttribute;
  input SPLB3_PLB_rdBurst;
  input SPLB3_PLB_wrBurst;
  input [0:63] SPLB3_PLB_wrDBus;
  output SPLB3_Sl_addrAck;
  output [0:1] SPLB3_Sl_SSize;
  output SPLB3_Sl_wait;
  output SPLB3_Sl_rearbitrate;
  output SPLB3_Sl_wrDAck;
  output SPLB3_Sl_wrComp;
  output SPLB3_Sl_wrBTerm;
  output [0:63] SPLB3_Sl_rdDBus;
  output [0:3] SPLB3_Sl_rdWdAddr;
  output SPLB3_Sl_rdDAck;
  output SPLB3_Sl_rdComp;
  output SPLB3_Sl_rdBTerm;
  output [0:0] SPLB3_Sl_MBusy;
  output [0:0] SPLB3_Sl_MRdErr;
  output [0:0] SPLB3_Sl_MWrErr;
  output [0:0] SPLB3_Sl_MIRQ;
  input SDMA3_Clk;
  output SDMA3_Rx_IntOut;
  output SDMA3_Tx_IntOut;
  output SDMA3_RstOut;
  output [0:31] SDMA3_TX_D;
  output [0:3] SDMA3_TX_Rem;
  output SDMA3_TX_SOF;
  output SDMA3_TX_EOF;
  output SDMA3_TX_SOP;
  output SDMA3_TX_EOP;
  output SDMA3_TX_Src_Rdy;
  input SDMA3_TX_Dst_Rdy;
  input [0:31] SDMA3_RX_D;
  input [0:3] SDMA3_RX_Rem;
  input SDMA3_RX_SOF;
  input SDMA3_RX_EOF;
  input SDMA3_RX_SOP;
  input SDMA3_RX_EOP;
  input SDMA3_RX_Src_Rdy;
  output SDMA3_RX_Dst_Rdy;
  input SDMA_CTRL3_Clk;
  input SDMA_CTRL3_Rst;
  input [0:31] SDMA_CTRL3_PLB_ABus;
  input SDMA_CTRL3_PLB_PAValid;
  input SDMA_CTRL3_PLB_SAValid;
  input [0:0] SDMA_CTRL3_PLB_masterID;
  input SDMA_CTRL3_PLB_RNW;
  input [0:7] SDMA_CTRL3_PLB_BE;
  input [0:31] SDMA_CTRL3_PLB_UABus;
  input SDMA_CTRL3_PLB_rdPrim;
  input SDMA_CTRL3_PLB_wrPrim;
  input SDMA_CTRL3_PLB_abort;
  input SDMA_CTRL3_PLB_busLock;
  input [0:1] SDMA_CTRL3_PLB_MSize;
  input [0:3] SDMA_CTRL3_PLB_size;
  input [0:2] SDMA_CTRL3_PLB_type;
  input SDMA_CTRL3_PLB_lockErr;
  input SDMA_CTRL3_PLB_wrPendReq;
  input [0:1] SDMA_CTRL3_PLB_wrPendPri;
  input SDMA_CTRL3_PLB_rdPendReq;
  input [0:1] SDMA_CTRL3_PLB_rdPendPri;
  input [0:1] SDMA_CTRL3_PLB_reqPri;
  input [0:15] SDMA_CTRL3_PLB_TAttribute;
  input SDMA_CTRL3_PLB_rdBurst;
  input SDMA_CTRL3_PLB_wrBurst;
  input [0:63] SDMA_CTRL3_PLB_wrDBus;
  output SDMA_CTRL3_Sl_addrAck;
  output [0:1] SDMA_CTRL3_Sl_SSize;
  output SDMA_CTRL3_Sl_wait;
  output SDMA_CTRL3_Sl_rearbitrate;
  output SDMA_CTRL3_Sl_wrDAck;
  output SDMA_CTRL3_Sl_wrComp;
  output SDMA_CTRL3_Sl_wrBTerm;
  output [0:63] SDMA_CTRL3_Sl_rdDBus;
  output [0:3] SDMA_CTRL3_Sl_rdWdAddr;
  output SDMA_CTRL3_Sl_rdDAck;
  output SDMA_CTRL3_Sl_rdComp;
  output SDMA_CTRL3_Sl_rdBTerm;
  output [0:0] SDMA_CTRL3_Sl_MBusy;
  output [0:0] SDMA_CTRL3_Sl_MRdErr;
  output [0:0] SDMA_CTRL3_Sl_MWrErr;
  output [0:0] SDMA_CTRL3_Sl_MIRQ;
  input [31:0] PIM3_Addr;
  input PIM3_AddrReq;
  output PIM3_AddrAck;
  input PIM3_RNW;
  input [3:0] PIM3_Size;
  input PIM3_RdModWr;
  input [63:0] PIM3_WrFIFO_Data;
  input [7:0] PIM3_WrFIFO_BE;
  input PIM3_WrFIFO_Push;
  output [63:0] PIM3_RdFIFO_Data;
  input PIM3_RdFIFO_Pop;
  output [3:0] PIM3_RdFIFO_RdWdAddr;
  output PIM3_WrFIFO_Empty;
  output PIM3_WrFIFO_AlmostFull;
  input PIM3_WrFIFO_Flush;
  output PIM3_RdFIFO_Empty;
  input PIM3_RdFIFO_Flush;
  output [1:0] PIM3_RdFIFO_Latency;
  output PIM3_InitDone;
  input PPC440MC3_MIMCReadNotWrite;
  input [0:35] PPC440MC3_MIMCAddress;
  input PPC440MC3_MIMCAddressValid;
  input [0:127] PPC440MC3_MIMCWriteData;
  input PPC440MC3_MIMCWriteDataValid;
  input [0:15] PPC440MC3_MIMCByteEnable;
  input PPC440MC3_MIMCBankConflict;
  input PPC440MC3_MIMCRowConflict;
  output [0:127] PPC440MC3_MCMIReadData;
  output PPC440MC3_MCMIReadDataValid;
  output PPC440MC3_MCMIReadDataErr;
  output PPC440MC3_MCMIAddrReadyToAccept;
  input VFBC3_Cmd_Clk;
  input VFBC3_Cmd_Reset;
  input [31:0] VFBC3_Cmd_Data;
  input VFBC3_Cmd_Write;
  input VFBC3_Cmd_End;
  output VFBC3_Cmd_Full;
  output VFBC3_Cmd_Almost_Full;
  output VFBC3_Cmd_Idle;
  input VFBC3_Wd_Clk;
  input VFBC3_Wd_Reset;
  input VFBC3_Wd_Write;
  input VFBC3_Wd_End_Burst;
  input VFBC3_Wd_Flush;
  input [31:0] VFBC3_Wd_Data;
  input [3:0] VFBC3_Wd_Data_BE;
  output VFBC3_Wd_Full;
  output VFBC3_Wd_Almost_Full;
  input VFBC3_Rd_Clk;
  input VFBC3_Rd_Reset;
  input VFBC3_Rd_Read;
  input VFBC3_Rd_End_Burst;
  input VFBC3_Rd_Flush;
  output [31:0] VFBC3_Rd_Data;
  output VFBC3_Rd_Empty;
  output VFBC3_Rd_Almost_Empty;
  input FSL4_M_Clk;
  input FSL4_M_Write;
  input [0:31] FSL4_M_Data;
  input FSL4_M_Control;
  output FSL4_M_Full;
  input FSL4_S_Clk;
  input FSL4_S_Read;
  output [0:31] FSL4_S_Data;
  output FSL4_S_Control;
  output FSL4_S_Exists;
  input SPLB4_Clk;
  input SPLB4_Rst;
  input [0:31] SPLB4_PLB_ABus;
  input SPLB4_PLB_PAValid;
  input SPLB4_PLB_SAValid;
  input [0:0] SPLB4_PLB_masterID;
  input SPLB4_PLB_RNW;
  input [0:7] SPLB4_PLB_BE;
  input [0:31] SPLB4_PLB_UABus;
  input SPLB4_PLB_rdPrim;
  input SPLB4_PLB_wrPrim;
  input SPLB4_PLB_abort;
  input SPLB4_PLB_busLock;
  input [0:1] SPLB4_PLB_MSize;
  input [0:3] SPLB4_PLB_size;
  input [0:2] SPLB4_PLB_type;
  input SPLB4_PLB_lockErr;
  input SPLB4_PLB_wrPendReq;
  input [0:1] SPLB4_PLB_wrPendPri;
  input SPLB4_PLB_rdPendReq;
  input [0:1] SPLB4_PLB_rdPendPri;
  input [0:1] SPLB4_PLB_reqPri;
  input [0:15] SPLB4_PLB_TAttribute;
  input SPLB4_PLB_rdBurst;
  input SPLB4_PLB_wrBurst;
  input [0:63] SPLB4_PLB_wrDBus;
  output SPLB4_Sl_addrAck;
  output [0:1] SPLB4_Sl_SSize;
  output SPLB4_Sl_wait;
  output SPLB4_Sl_rearbitrate;
  output SPLB4_Sl_wrDAck;
  output SPLB4_Sl_wrComp;
  output SPLB4_Sl_wrBTerm;
  output [0:63] SPLB4_Sl_rdDBus;
  output [0:3] SPLB4_Sl_rdWdAddr;
  output SPLB4_Sl_rdDAck;
  output SPLB4_Sl_rdComp;
  output SPLB4_Sl_rdBTerm;
  output [0:0] SPLB4_Sl_MBusy;
  output [0:0] SPLB4_Sl_MRdErr;
  output [0:0] SPLB4_Sl_MWrErr;
  output [0:0] SPLB4_Sl_MIRQ;
  input SDMA4_Clk;
  output SDMA4_Rx_IntOut;
  output SDMA4_Tx_IntOut;
  output SDMA4_RstOut;
  output [0:31] SDMA4_TX_D;
  output [0:3] SDMA4_TX_Rem;
  output SDMA4_TX_SOF;
  output SDMA4_TX_EOF;
  output SDMA4_TX_SOP;
  output SDMA4_TX_EOP;
  output SDMA4_TX_Src_Rdy;
  input SDMA4_TX_Dst_Rdy;
  input [0:31] SDMA4_RX_D;
  input [0:3] SDMA4_RX_Rem;
  input SDMA4_RX_SOF;
  input SDMA4_RX_EOF;
  input SDMA4_RX_SOP;
  input SDMA4_RX_EOP;
  input SDMA4_RX_Src_Rdy;
  output SDMA4_RX_Dst_Rdy;
  input SDMA_CTRL4_Clk;
  input SDMA_CTRL4_Rst;
  input [0:31] SDMA_CTRL4_PLB_ABus;
  input SDMA_CTRL4_PLB_PAValid;
  input SDMA_CTRL4_PLB_SAValid;
  input [0:0] SDMA_CTRL4_PLB_masterID;
  input SDMA_CTRL4_PLB_RNW;
  input [0:7] SDMA_CTRL4_PLB_BE;
  input [0:31] SDMA_CTRL4_PLB_UABus;
  input SDMA_CTRL4_PLB_rdPrim;
  input SDMA_CTRL4_PLB_wrPrim;
  input SDMA_CTRL4_PLB_abort;
  input SDMA_CTRL4_PLB_busLock;
  input [0:1] SDMA_CTRL4_PLB_MSize;
  input [0:3] SDMA_CTRL4_PLB_size;
  input [0:2] SDMA_CTRL4_PLB_type;
  input SDMA_CTRL4_PLB_lockErr;
  input SDMA_CTRL4_PLB_wrPendReq;
  input [0:1] SDMA_CTRL4_PLB_wrPendPri;
  input SDMA_CTRL4_PLB_rdPendReq;
  input [0:1] SDMA_CTRL4_PLB_rdPendPri;
  input [0:1] SDMA_CTRL4_PLB_reqPri;
  input [0:15] SDMA_CTRL4_PLB_TAttribute;
  input SDMA_CTRL4_PLB_rdBurst;
  input SDMA_CTRL4_PLB_wrBurst;
  input [0:63] SDMA_CTRL4_PLB_wrDBus;
  output SDMA_CTRL4_Sl_addrAck;
  output [0:1] SDMA_CTRL4_Sl_SSize;
  output SDMA_CTRL4_Sl_wait;
  output SDMA_CTRL4_Sl_rearbitrate;
  output SDMA_CTRL4_Sl_wrDAck;
  output SDMA_CTRL4_Sl_wrComp;
  output SDMA_CTRL4_Sl_wrBTerm;
  output [0:63] SDMA_CTRL4_Sl_rdDBus;
  output [0:3] SDMA_CTRL4_Sl_rdWdAddr;
  output SDMA_CTRL4_Sl_rdDAck;
  output SDMA_CTRL4_Sl_rdComp;
  output SDMA_CTRL4_Sl_rdBTerm;
  output [0:0] SDMA_CTRL4_Sl_MBusy;
  output [0:0] SDMA_CTRL4_Sl_MRdErr;
  output [0:0] SDMA_CTRL4_Sl_MWrErr;
  output [0:0] SDMA_CTRL4_Sl_MIRQ;
  input [31:0] PIM4_Addr;
  input PIM4_AddrReq;
  output PIM4_AddrAck;
  input PIM4_RNW;
  input [3:0] PIM4_Size;
  input PIM4_RdModWr;
  input [63:0] PIM4_WrFIFO_Data;
  input [7:0] PIM4_WrFIFO_BE;
  input PIM4_WrFIFO_Push;
  output [63:0] PIM4_RdFIFO_Data;
  input PIM4_RdFIFO_Pop;
  output [3:0] PIM4_RdFIFO_RdWdAddr;
  output PIM4_WrFIFO_Empty;
  output PIM4_WrFIFO_AlmostFull;
  input PIM4_WrFIFO_Flush;
  output PIM4_RdFIFO_Empty;
  input PIM4_RdFIFO_Flush;
  output [1:0] PIM4_RdFIFO_Latency;
  output PIM4_InitDone;
  input PPC440MC4_MIMCReadNotWrite;
  input [0:35] PPC440MC4_MIMCAddress;
  input PPC440MC4_MIMCAddressValid;
  input [0:127] PPC440MC4_MIMCWriteData;
  input PPC440MC4_MIMCWriteDataValid;
  input [0:15] PPC440MC4_MIMCByteEnable;
  input PPC440MC4_MIMCBankConflict;
  input PPC440MC4_MIMCRowConflict;
  output [0:127] PPC440MC4_MCMIReadData;
  output PPC440MC4_MCMIReadDataValid;
  output PPC440MC4_MCMIReadDataErr;
  output PPC440MC4_MCMIAddrReadyToAccept;
  input VFBC4_Cmd_Clk;
  input VFBC4_Cmd_Reset;
  input [31:0] VFBC4_Cmd_Data;
  input VFBC4_Cmd_Write;
  input VFBC4_Cmd_End;
  output VFBC4_Cmd_Full;
  output VFBC4_Cmd_Almost_Full;
  output VFBC4_Cmd_Idle;
  input VFBC4_Wd_Clk;
  input VFBC4_Wd_Reset;
  input VFBC4_Wd_Write;
  input VFBC4_Wd_End_Burst;
  input VFBC4_Wd_Flush;
  input [31:0] VFBC4_Wd_Data;
  input [3:0] VFBC4_Wd_Data_BE;
  output VFBC4_Wd_Full;
  output VFBC4_Wd_Almost_Full;
  input VFBC4_Rd_Clk;
  input VFBC4_Rd_Reset;
  input VFBC4_Rd_Read;
  input VFBC4_Rd_End_Burst;
  input VFBC4_Rd_Flush;
  output [31:0] VFBC4_Rd_Data;
  output VFBC4_Rd_Empty;
  output VFBC4_Rd_Almost_Empty;
  input FSL5_M_Clk;
  input FSL5_M_Write;
  input [0:31] FSL5_M_Data;
  input FSL5_M_Control;
  output FSL5_M_Full;
  input FSL5_S_Clk;
  input FSL5_S_Read;
  output [0:31] FSL5_S_Data;
  output FSL5_S_Control;
  output FSL5_S_Exists;
  input SPLB5_Clk;
  input SPLB5_Rst;
  input [0:31] SPLB5_PLB_ABus;
  input SPLB5_PLB_PAValid;
  input SPLB5_PLB_SAValid;
  input [0:0] SPLB5_PLB_masterID;
  input SPLB5_PLB_RNW;
  input [0:7] SPLB5_PLB_BE;
  input [0:31] SPLB5_PLB_UABus;
  input SPLB5_PLB_rdPrim;
  input SPLB5_PLB_wrPrim;
  input SPLB5_PLB_abort;
  input SPLB5_PLB_busLock;
  input [0:1] SPLB5_PLB_MSize;
  input [0:3] SPLB5_PLB_size;
  input [0:2] SPLB5_PLB_type;
  input SPLB5_PLB_lockErr;
  input SPLB5_PLB_wrPendReq;
  input [0:1] SPLB5_PLB_wrPendPri;
  input SPLB5_PLB_rdPendReq;
  input [0:1] SPLB5_PLB_rdPendPri;
  input [0:1] SPLB5_PLB_reqPri;
  input [0:15] SPLB5_PLB_TAttribute;
  input SPLB5_PLB_rdBurst;
  input SPLB5_PLB_wrBurst;
  input [0:63] SPLB5_PLB_wrDBus;
  output SPLB5_Sl_addrAck;
  output [0:1] SPLB5_Sl_SSize;
  output SPLB5_Sl_wait;
  output SPLB5_Sl_rearbitrate;
  output SPLB5_Sl_wrDAck;
  output SPLB5_Sl_wrComp;
  output SPLB5_Sl_wrBTerm;
  output [0:63] SPLB5_Sl_rdDBus;
  output [0:3] SPLB5_Sl_rdWdAddr;
  output SPLB5_Sl_rdDAck;
  output SPLB5_Sl_rdComp;
  output SPLB5_Sl_rdBTerm;
  output [0:0] SPLB5_Sl_MBusy;
  output [0:0] SPLB5_Sl_MRdErr;
  output [0:0] SPLB5_Sl_MWrErr;
  output [0:0] SPLB5_Sl_MIRQ;
  input SDMA5_Clk;
  output SDMA5_Rx_IntOut;
  output SDMA5_Tx_IntOut;
  output SDMA5_RstOut;
  output [0:31] SDMA5_TX_D;
  output [0:3] SDMA5_TX_Rem;
  output SDMA5_TX_SOF;
  output SDMA5_TX_EOF;
  output SDMA5_TX_SOP;
  output SDMA5_TX_EOP;
  output SDMA5_TX_Src_Rdy;
  input SDMA5_TX_Dst_Rdy;
  input [0:31] SDMA5_RX_D;
  input [0:3] SDMA5_RX_Rem;
  input SDMA5_RX_SOF;
  input SDMA5_RX_EOF;
  input SDMA5_RX_SOP;
  input SDMA5_RX_EOP;
  input SDMA5_RX_Src_Rdy;
  output SDMA5_RX_Dst_Rdy;
  input SDMA_CTRL5_Clk;
  input SDMA_CTRL5_Rst;
  input [0:31] SDMA_CTRL5_PLB_ABus;
  input SDMA_CTRL5_PLB_PAValid;
  input SDMA_CTRL5_PLB_SAValid;
  input [0:0] SDMA_CTRL5_PLB_masterID;
  input SDMA_CTRL5_PLB_RNW;
  input [0:7] SDMA_CTRL5_PLB_BE;
  input [0:31] SDMA_CTRL5_PLB_UABus;
  input SDMA_CTRL5_PLB_rdPrim;
  input SDMA_CTRL5_PLB_wrPrim;
  input SDMA_CTRL5_PLB_abort;
  input SDMA_CTRL5_PLB_busLock;
  input [0:1] SDMA_CTRL5_PLB_MSize;
  input [0:3] SDMA_CTRL5_PLB_size;
  input [0:2] SDMA_CTRL5_PLB_type;
  input SDMA_CTRL5_PLB_lockErr;
  input SDMA_CTRL5_PLB_wrPendReq;
  input [0:1] SDMA_CTRL5_PLB_wrPendPri;
  input SDMA_CTRL5_PLB_rdPendReq;
  input [0:1] SDMA_CTRL5_PLB_rdPendPri;
  input [0:1] SDMA_CTRL5_PLB_reqPri;
  input [0:15] SDMA_CTRL5_PLB_TAttribute;
  input SDMA_CTRL5_PLB_rdBurst;
  input SDMA_CTRL5_PLB_wrBurst;
  input [0:63] SDMA_CTRL5_PLB_wrDBus;
  output SDMA_CTRL5_Sl_addrAck;
  output [0:1] SDMA_CTRL5_Sl_SSize;
  output SDMA_CTRL5_Sl_wait;
  output SDMA_CTRL5_Sl_rearbitrate;
  output SDMA_CTRL5_Sl_wrDAck;
  output SDMA_CTRL5_Sl_wrComp;
  output SDMA_CTRL5_Sl_wrBTerm;
  output [0:63] SDMA_CTRL5_Sl_rdDBus;
  output [0:3] SDMA_CTRL5_Sl_rdWdAddr;
  output SDMA_CTRL5_Sl_rdDAck;
  output SDMA_CTRL5_Sl_rdComp;
  output SDMA_CTRL5_Sl_rdBTerm;
  output [0:0] SDMA_CTRL5_Sl_MBusy;
  output [0:0] SDMA_CTRL5_Sl_MRdErr;
  output [0:0] SDMA_CTRL5_Sl_MWrErr;
  output [0:0] SDMA_CTRL5_Sl_MIRQ;
  input [31:0] PIM5_Addr;
  input PIM5_AddrReq;
  output PIM5_AddrAck;
  input PIM5_RNW;
  input [3:0] PIM5_Size;
  input PIM5_RdModWr;
  input [63:0] PIM5_WrFIFO_Data;
  input [7:0] PIM5_WrFIFO_BE;
  input PIM5_WrFIFO_Push;
  output [63:0] PIM5_RdFIFO_Data;
  input PIM5_RdFIFO_Pop;
  output [3:0] PIM5_RdFIFO_RdWdAddr;
  output PIM5_WrFIFO_Empty;
  output PIM5_WrFIFO_AlmostFull;
  input PIM5_WrFIFO_Flush;
  output PIM5_RdFIFO_Empty;
  input PIM5_RdFIFO_Flush;
  output [1:0] PIM5_RdFIFO_Latency;
  output PIM5_InitDone;
  input PPC440MC5_MIMCReadNotWrite;
  input [0:35] PPC440MC5_MIMCAddress;
  input PPC440MC5_MIMCAddressValid;
  input [0:127] PPC440MC5_MIMCWriteData;
  input PPC440MC5_MIMCWriteDataValid;
  input [0:15] PPC440MC5_MIMCByteEnable;
  input PPC440MC5_MIMCBankConflict;
  input PPC440MC5_MIMCRowConflict;
  output [0:127] PPC440MC5_MCMIReadData;
  output PPC440MC5_MCMIReadDataValid;
  output PPC440MC5_MCMIReadDataErr;
  output PPC440MC5_MCMIAddrReadyToAccept;
  input VFBC5_Cmd_Clk;
  input VFBC5_Cmd_Reset;
  input [31:0] VFBC5_Cmd_Data;
  input VFBC5_Cmd_Write;
  input VFBC5_Cmd_End;
  output VFBC5_Cmd_Full;
  output VFBC5_Cmd_Almost_Full;
  output VFBC5_Cmd_Idle;
  input VFBC5_Wd_Clk;
  input VFBC5_Wd_Reset;
  input VFBC5_Wd_Write;
  input VFBC5_Wd_End_Burst;
  input VFBC5_Wd_Flush;
  input [31:0] VFBC5_Wd_Data;
  input [3:0] VFBC5_Wd_Data_BE;
  output VFBC5_Wd_Full;
  output VFBC5_Wd_Almost_Full;
  input VFBC5_Rd_Clk;
  input VFBC5_Rd_Reset;
  input VFBC5_Rd_Read;
  input VFBC5_Rd_End_Burst;
  input VFBC5_Rd_Flush;
  output [31:0] VFBC5_Rd_Data;
  output VFBC5_Rd_Empty;
  output VFBC5_Rd_Almost_Empty;
  input FSL6_M_Clk;
  input FSL6_M_Write;
  input [0:31] FSL6_M_Data;
  input FSL6_M_Control;
  output FSL6_M_Full;
  input FSL6_S_Clk;
  input FSL6_S_Read;
  output [0:31] FSL6_S_Data;
  output FSL6_S_Control;
  output FSL6_S_Exists;
  input SPLB6_Clk;
  input SPLB6_Rst;
  input [0:31] SPLB6_PLB_ABus;
  input SPLB6_PLB_PAValid;
  input SPLB6_PLB_SAValid;
  input [0:0] SPLB6_PLB_masterID;
  input SPLB6_PLB_RNW;
  input [0:7] SPLB6_PLB_BE;
  input [0:31] SPLB6_PLB_UABus;
  input SPLB6_PLB_rdPrim;
  input SPLB6_PLB_wrPrim;
  input SPLB6_PLB_abort;
  input SPLB6_PLB_busLock;
  input [0:1] SPLB6_PLB_MSize;
  input [0:3] SPLB6_PLB_size;
  input [0:2] SPLB6_PLB_type;
  input SPLB6_PLB_lockErr;
  input SPLB6_PLB_wrPendReq;
  input [0:1] SPLB6_PLB_wrPendPri;
  input SPLB6_PLB_rdPendReq;
  input [0:1] SPLB6_PLB_rdPendPri;
  input [0:1] SPLB6_PLB_reqPri;
  input [0:15] SPLB6_PLB_TAttribute;
  input SPLB6_PLB_rdBurst;
  input SPLB6_PLB_wrBurst;
  input [0:63] SPLB6_PLB_wrDBus;
  output SPLB6_Sl_addrAck;
  output [0:1] SPLB6_Sl_SSize;
  output SPLB6_Sl_wait;
  output SPLB6_Sl_rearbitrate;
  output SPLB6_Sl_wrDAck;
  output SPLB6_Sl_wrComp;
  output SPLB6_Sl_wrBTerm;
  output [0:63] SPLB6_Sl_rdDBus;
  output [0:3] SPLB6_Sl_rdWdAddr;
  output SPLB6_Sl_rdDAck;
  output SPLB6_Sl_rdComp;
  output SPLB6_Sl_rdBTerm;
  output [0:0] SPLB6_Sl_MBusy;
  output [0:0] SPLB6_Sl_MRdErr;
  output [0:0] SPLB6_Sl_MWrErr;
  output [0:0] SPLB6_Sl_MIRQ;
  input SDMA6_Clk;
  output SDMA6_Rx_IntOut;
  output SDMA6_Tx_IntOut;
  output SDMA6_RstOut;
  output [0:31] SDMA6_TX_D;
  output [0:3] SDMA6_TX_Rem;
  output SDMA6_TX_SOF;
  output SDMA6_TX_EOF;
  output SDMA6_TX_SOP;
  output SDMA6_TX_EOP;
  output SDMA6_TX_Src_Rdy;
  input SDMA6_TX_Dst_Rdy;
  input [0:31] SDMA6_RX_D;
  input [0:3] SDMA6_RX_Rem;
  input SDMA6_RX_SOF;
  input SDMA6_RX_EOF;
  input SDMA6_RX_SOP;
  input SDMA6_RX_EOP;
  input SDMA6_RX_Src_Rdy;
  output SDMA6_RX_Dst_Rdy;
  input SDMA_CTRL6_Clk;
  input SDMA_CTRL6_Rst;
  input [0:31] SDMA_CTRL6_PLB_ABus;
  input SDMA_CTRL6_PLB_PAValid;
  input SDMA_CTRL6_PLB_SAValid;
  input [0:0] SDMA_CTRL6_PLB_masterID;
  input SDMA_CTRL6_PLB_RNW;
  input [0:7] SDMA_CTRL6_PLB_BE;
  input [0:31] SDMA_CTRL6_PLB_UABus;
  input SDMA_CTRL6_PLB_rdPrim;
  input SDMA_CTRL6_PLB_wrPrim;
  input SDMA_CTRL6_PLB_abort;
  input SDMA_CTRL6_PLB_busLock;
  input [0:1] SDMA_CTRL6_PLB_MSize;
  input [0:3] SDMA_CTRL6_PLB_size;
  input [0:2] SDMA_CTRL6_PLB_type;
  input SDMA_CTRL6_PLB_lockErr;
  input SDMA_CTRL6_PLB_wrPendReq;
  input [0:1] SDMA_CTRL6_PLB_wrPendPri;
  input SDMA_CTRL6_PLB_rdPendReq;
  input [0:1] SDMA_CTRL6_PLB_rdPendPri;
  input [0:1] SDMA_CTRL6_PLB_reqPri;
  input [0:15] SDMA_CTRL6_PLB_TAttribute;
  input SDMA_CTRL6_PLB_rdBurst;
  input SDMA_CTRL6_PLB_wrBurst;
  input [0:63] SDMA_CTRL6_PLB_wrDBus;
  output SDMA_CTRL6_Sl_addrAck;
  output [0:1] SDMA_CTRL6_Sl_SSize;
  output SDMA_CTRL6_Sl_wait;
  output SDMA_CTRL6_Sl_rearbitrate;
  output SDMA_CTRL6_Sl_wrDAck;
  output SDMA_CTRL6_Sl_wrComp;
  output SDMA_CTRL6_Sl_wrBTerm;
  output [0:63] SDMA_CTRL6_Sl_rdDBus;
  output [0:3] SDMA_CTRL6_Sl_rdWdAddr;
  output SDMA_CTRL6_Sl_rdDAck;
  output SDMA_CTRL6_Sl_rdComp;
  output SDMA_CTRL6_Sl_rdBTerm;
  output [0:0] SDMA_CTRL6_Sl_MBusy;
  output [0:0] SDMA_CTRL6_Sl_MRdErr;
  output [0:0] SDMA_CTRL6_Sl_MWrErr;
  output [0:0] SDMA_CTRL6_Sl_MIRQ;
  input [31:0] PIM6_Addr;
  input PIM6_AddrReq;
  output PIM6_AddrAck;
  input PIM6_RNW;
  input [3:0] PIM6_Size;
  input PIM6_RdModWr;
  input [63:0] PIM6_WrFIFO_Data;
  input [7:0] PIM6_WrFIFO_BE;
  input PIM6_WrFIFO_Push;
  output [63:0] PIM6_RdFIFO_Data;
  input PIM6_RdFIFO_Pop;
  output [3:0] PIM6_RdFIFO_RdWdAddr;
  output PIM6_WrFIFO_Empty;
  output PIM6_WrFIFO_AlmostFull;
  input PIM6_WrFIFO_Flush;
  output PIM6_RdFIFO_Empty;
  input PIM6_RdFIFO_Flush;
  output [1:0] PIM6_RdFIFO_Latency;
  output PIM6_InitDone;
  input PPC440MC6_MIMCReadNotWrite;
  input [0:35] PPC440MC6_MIMCAddress;
  input PPC440MC6_MIMCAddressValid;
  input [0:127] PPC440MC6_MIMCWriteData;
  input PPC440MC6_MIMCWriteDataValid;
  input [0:15] PPC440MC6_MIMCByteEnable;
  input PPC440MC6_MIMCBankConflict;
  input PPC440MC6_MIMCRowConflict;
  output [0:127] PPC440MC6_MCMIReadData;
  output PPC440MC6_MCMIReadDataValid;
  output PPC440MC6_MCMIReadDataErr;
  output PPC440MC6_MCMIAddrReadyToAccept;
  input VFBC6_Cmd_Clk;
  input VFBC6_Cmd_Reset;
  input [31:0] VFBC6_Cmd_Data;
  input VFBC6_Cmd_Write;
  input VFBC6_Cmd_End;
  output VFBC6_Cmd_Full;
  output VFBC6_Cmd_Almost_Full;
  output VFBC6_Cmd_Idle;
  input VFBC6_Wd_Clk;
  input VFBC6_Wd_Reset;
  input VFBC6_Wd_Write;
  input VFBC6_Wd_End_Burst;
  input VFBC6_Wd_Flush;
  input [31:0] VFBC6_Wd_Data;
  input [3:0] VFBC6_Wd_Data_BE;
  output VFBC6_Wd_Full;
  output VFBC6_Wd_Almost_Full;
  input VFBC6_Rd_Clk;
  input VFBC6_Rd_Reset;
  input VFBC6_Rd_Read;
  input VFBC6_Rd_End_Burst;
  input VFBC6_Rd_Flush;
  output [31:0] VFBC6_Rd_Data;
  output VFBC6_Rd_Empty;
  output VFBC6_Rd_Almost_Empty;
  input FSL7_M_Clk;
  input FSL7_M_Write;
  input [0:31] FSL7_M_Data;
  input FSL7_M_Control;
  output FSL7_M_Full;
  input FSL7_S_Clk;
  input FSL7_S_Read;
  output [0:31] FSL7_S_Data;
  output FSL7_S_Control;
  output FSL7_S_Exists;
  input SPLB7_Clk;
  input SPLB7_Rst;
  input [0:31] SPLB7_PLB_ABus;
  input SPLB7_PLB_PAValid;
  input SPLB7_PLB_SAValid;
  input [0:0] SPLB7_PLB_masterID;
  input SPLB7_PLB_RNW;
  input [0:7] SPLB7_PLB_BE;
  input [0:31] SPLB7_PLB_UABus;
  input SPLB7_PLB_rdPrim;
  input SPLB7_PLB_wrPrim;
  input SPLB7_PLB_abort;
  input SPLB7_PLB_busLock;
  input [0:1] SPLB7_PLB_MSize;
  input [0:3] SPLB7_PLB_size;
  input [0:2] SPLB7_PLB_type;
  input SPLB7_PLB_lockErr;
  input SPLB7_PLB_wrPendReq;
  input [0:1] SPLB7_PLB_wrPendPri;
  input SPLB7_PLB_rdPendReq;
  input [0:1] SPLB7_PLB_rdPendPri;
  input [0:1] SPLB7_PLB_reqPri;
  input [0:15] SPLB7_PLB_TAttribute;
  input SPLB7_PLB_rdBurst;
  input SPLB7_PLB_wrBurst;
  input [0:63] SPLB7_PLB_wrDBus;
  output SPLB7_Sl_addrAck;
  output [0:1] SPLB7_Sl_SSize;
  output SPLB7_Sl_wait;
  output SPLB7_Sl_rearbitrate;
  output SPLB7_Sl_wrDAck;
  output SPLB7_Sl_wrComp;
  output SPLB7_Sl_wrBTerm;
  output [0:63] SPLB7_Sl_rdDBus;
  output [0:3] SPLB7_Sl_rdWdAddr;
  output SPLB7_Sl_rdDAck;
  output SPLB7_Sl_rdComp;
  output SPLB7_Sl_rdBTerm;
  output [0:0] SPLB7_Sl_MBusy;
  output [0:0] SPLB7_Sl_MRdErr;
  output [0:0] SPLB7_Sl_MWrErr;
  output [0:0] SPLB7_Sl_MIRQ;
  input SDMA7_Clk;
  output SDMA7_Rx_IntOut;
  output SDMA7_Tx_IntOut;
  output SDMA7_RstOut;
  output [0:31] SDMA7_TX_D;
  output [0:3] SDMA7_TX_Rem;
  output SDMA7_TX_SOF;
  output SDMA7_TX_EOF;
  output SDMA7_TX_SOP;
  output SDMA7_TX_EOP;
  output SDMA7_TX_Src_Rdy;
  input SDMA7_TX_Dst_Rdy;
  input [0:31] SDMA7_RX_D;
  input [0:3] SDMA7_RX_Rem;
  input SDMA7_RX_SOF;
  input SDMA7_RX_EOF;
  input SDMA7_RX_SOP;
  input SDMA7_RX_EOP;
  input SDMA7_RX_Src_Rdy;
  output SDMA7_RX_Dst_Rdy;
  input SDMA_CTRL7_Clk;
  input SDMA_CTRL7_Rst;
  input [0:31] SDMA_CTRL7_PLB_ABus;
  input SDMA_CTRL7_PLB_PAValid;
  input SDMA_CTRL7_PLB_SAValid;
  input [0:0] SDMA_CTRL7_PLB_masterID;
  input SDMA_CTRL7_PLB_RNW;
  input [0:7] SDMA_CTRL7_PLB_BE;
  input [0:31] SDMA_CTRL7_PLB_UABus;
  input SDMA_CTRL7_PLB_rdPrim;
  input SDMA_CTRL7_PLB_wrPrim;
  input SDMA_CTRL7_PLB_abort;
  input SDMA_CTRL7_PLB_busLock;
  input [0:1] SDMA_CTRL7_PLB_MSize;
  input [0:3] SDMA_CTRL7_PLB_size;
  input [0:2] SDMA_CTRL7_PLB_type;
  input SDMA_CTRL7_PLB_lockErr;
  input SDMA_CTRL7_PLB_wrPendReq;
  input [0:1] SDMA_CTRL7_PLB_wrPendPri;
  input SDMA_CTRL7_PLB_rdPendReq;
  input [0:1] SDMA_CTRL7_PLB_rdPendPri;
  input [0:1] SDMA_CTRL7_PLB_reqPri;
  input [0:15] SDMA_CTRL7_PLB_TAttribute;
  input SDMA_CTRL7_PLB_rdBurst;
  input SDMA_CTRL7_PLB_wrBurst;
  input [0:63] SDMA_CTRL7_PLB_wrDBus;
  output SDMA_CTRL7_Sl_addrAck;
  output [0:1] SDMA_CTRL7_Sl_SSize;
  output SDMA_CTRL7_Sl_wait;
  output SDMA_CTRL7_Sl_rearbitrate;
  output SDMA_CTRL7_Sl_wrDAck;
  output SDMA_CTRL7_Sl_wrComp;
  output SDMA_CTRL7_Sl_wrBTerm;
  output [0:63] SDMA_CTRL7_Sl_rdDBus;
  output [0:3] SDMA_CTRL7_Sl_rdWdAddr;
  output SDMA_CTRL7_Sl_rdDAck;
  output SDMA_CTRL7_Sl_rdComp;
  output SDMA_CTRL7_Sl_rdBTerm;
  output [0:0] SDMA_CTRL7_Sl_MBusy;
  output [0:0] SDMA_CTRL7_Sl_MRdErr;
  output [0:0] SDMA_CTRL7_Sl_MWrErr;
  output [0:0] SDMA_CTRL7_Sl_MIRQ;
  input [31:0] PIM7_Addr;
  input PIM7_AddrReq;
  output PIM7_AddrAck;
  input PIM7_RNW;
  input [3:0] PIM7_Size;
  input PIM7_RdModWr;
  input [63:0] PIM7_WrFIFO_Data;
  input [7:0] PIM7_WrFIFO_BE;
  input PIM7_WrFIFO_Push;
  output [63:0] PIM7_RdFIFO_Data;
  input PIM7_RdFIFO_Pop;
  output [3:0] PIM7_RdFIFO_RdWdAddr;
  output PIM7_WrFIFO_Empty;
  output PIM7_WrFIFO_AlmostFull;
  input PIM7_WrFIFO_Flush;
  output PIM7_RdFIFO_Empty;
  input PIM7_RdFIFO_Flush;
  output [1:0] PIM7_RdFIFO_Latency;
  output PIM7_InitDone;
  input PPC440MC7_MIMCReadNotWrite;
  input [0:35] PPC440MC7_MIMCAddress;
  input PPC440MC7_MIMCAddressValid;
  input [0:127] PPC440MC7_MIMCWriteData;
  input PPC440MC7_MIMCWriteDataValid;
  input [0:15] PPC440MC7_MIMCByteEnable;
  input PPC440MC7_MIMCBankConflict;
  input PPC440MC7_MIMCRowConflict;
  output [0:127] PPC440MC7_MCMIReadData;
  output PPC440MC7_MCMIReadDataValid;
  output PPC440MC7_MCMIReadDataErr;
  output PPC440MC7_MCMIAddrReadyToAccept;
  input VFBC7_Cmd_Clk;
  input VFBC7_Cmd_Reset;
  input [31:0] VFBC7_Cmd_Data;
  input VFBC7_Cmd_Write;
  input VFBC7_Cmd_End;
  output VFBC7_Cmd_Full;
  output VFBC7_Cmd_Almost_Full;
  output VFBC7_Cmd_Idle;
  input VFBC7_Wd_Clk;
  input VFBC7_Wd_Reset;
  input VFBC7_Wd_Write;
  input VFBC7_Wd_End_Burst;
  input VFBC7_Wd_Flush;
  input [31:0] VFBC7_Wd_Data;
  input [3:0] VFBC7_Wd_Data_BE;
  output VFBC7_Wd_Full;
  output VFBC7_Wd_Almost_Full;
  input VFBC7_Rd_Clk;
  input VFBC7_Rd_Reset;
  input VFBC7_Rd_Read;
  input VFBC7_Rd_End_Burst;
  input VFBC7_Rd_Flush;
  output [31:0] VFBC7_Rd_Data;
  output VFBC7_Rd_Empty;
  output VFBC7_Rd_Almost_Empty;
  input MPMC_CTRL_Clk;
  input MPMC_CTRL_Rst;
  input [0:31] MPMC_CTRL_PLB_ABus;
  input MPMC_CTRL_PLB_PAValid;
  input MPMC_CTRL_PLB_SAValid;
  input [0:0] MPMC_CTRL_PLB_masterID;
  input MPMC_CTRL_PLB_RNW;
  input [0:7] MPMC_CTRL_PLB_BE;
  input [0:31] MPMC_CTRL_PLB_UABus;
  input MPMC_CTRL_PLB_rdPrim;
  input MPMC_CTRL_PLB_wrPrim;
  input MPMC_CTRL_PLB_abort;
  input MPMC_CTRL_PLB_busLock;
  input [0:1] MPMC_CTRL_PLB_MSize;
  input [0:3] MPMC_CTRL_PLB_size;
  input [0:2] MPMC_CTRL_PLB_type;
  input MPMC_CTRL_PLB_lockErr;
  input MPMC_CTRL_PLB_wrPendReq;
  input [0:1] MPMC_CTRL_PLB_wrPendPri;
  input MPMC_CTRL_PLB_rdPendReq;
  input [0:1] MPMC_CTRL_PLB_rdPendPri;
  input [0:1] MPMC_CTRL_PLB_reqPri;
  input [0:15] MPMC_CTRL_PLB_TAttribute;
  input MPMC_CTRL_PLB_rdBurst;
  input MPMC_CTRL_PLB_wrBurst;
  input [0:63] MPMC_CTRL_PLB_wrDBus;
  output MPMC_CTRL_Sl_addrAck;
  output [0:1] MPMC_CTRL_Sl_SSize;
  output MPMC_CTRL_Sl_wait;
  output MPMC_CTRL_Sl_rearbitrate;
  output MPMC_CTRL_Sl_wrDAck;
  output MPMC_CTRL_Sl_wrComp;
  output MPMC_CTRL_Sl_wrBTerm;
  output [0:63] MPMC_CTRL_Sl_rdDBus;
  output [0:3] MPMC_CTRL_Sl_rdWdAddr;
  output MPMC_CTRL_Sl_rdDAck;
  output MPMC_CTRL_Sl_rdComp;
  output MPMC_CTRL_Sl_rdBTerm;
  output [0:0] MPMC_CTRL_Sl_MBusy;
  output [0:0] MPMC_CTRL_Sl_MRdErr;
  output [0:0] MPMC_CTRL_Sl_MWrErr;
  output [0:0] MPMC_CTRL_Sl_MIRQ;
  input MPMC_Clk0;
  input MPMC_Clk0_DIV2;
  input MPMC_Clk90;
  input MPMC_Clk_200MHz;
  input MPMC_Rst;
  input MPMC_Clk_Mem;
  input MPMC_Idelayctrl_Rdy_I;
  output MPMC_Idelayctrl_Rdy_O;
  output MPMC_InitDone;
  output MPMC_ECC_Intr;
  output MPMC_DCM_PSEN;
  output MPMC_DCM_PSINCDEC;
  input MPMC_DCM_PSDONE;
  output [2:0] SDRAM_Clk;
  output [0:0] SDRAM_CE;
  output [0:0] SDRAM_CS_n;
  output SDRAM_RAS_n;
  output SDRAM_CAS_n;
  output SDRAM_WE_n;
  output [1:0] SDRAM_BankAddr;
  output [12:0] SDRAM_Addr;
  inout [63:0] SDRAM_DQ;
  output [7:0] SDRAM_DM;
  output [2:0] DDR_Clk;
  output [2:0] DDR_Clk_n;
  output [0:0] DDR_CE;
  output [0:0] DDR_CS_n;
  output DDR_RAS_n;
  output DDR_CAS_n;
  output DDR_WE_n;
  output [1:0] DDR_BankAddr;
  output [12:0] DDR_Addr;
  inout [63:0] DDR_DQ;
  output [7:0] DDR_DM;
  inout [7:0] DDR_DQS;
  output DDR_DQS_Div_O;
  input DDR_DQS_Div_I;
  output [2:0] DDR2_Clk;
  output [2:0] DDR2_Clk_n;
  output [0:0] DDR2_CE;
  output [0:0] DDR2_CS_n;
  output [0:0] DDR2_ODT;
  output DDR2_RAS_n;
  output DDR2_CAS_n;
  output DDR2_WE_n;
  output [1:0] DDR2_BankAddr;
  output [12:0] DDR2_Addr;
  inout [63:0] DDR2_DQ;
  output [7:0] DDR2_DM;
  inout [7:0] DDR2_DQS;
  inout [7:0] DDR2_DQS_n;
  output DDR2_DQS_Div_O;
  input DDR2_DQS_Div_I;
endmodule

module clock_generator_ddr_wrapper
  (
    CLKIN,
    CLKFBIN,
    CLKOUT0,
    CLKOUT1,
    CLKOUT2,
    CLKOUT3,
    CLKOUT4,
    CLKOUT5,
    CLKOUT6,
    CLKOUT7,
    CLKOUT8,
    CLKOUT9,
    CLKOUT10,
    CLKOUT11,
    CLKOUT12,
    CLKOUT13,
    CLKOUT14,
    CLKOUT15,
    CLKFBOUT,
    RST,
    LOCKED
  );
  input CLKIN;
  input CLKFBIN;
  output CLKOUT0;
  output CLKOUT1;
  output CLKOUT2;
  output CLKOUT3;
  output CLKOUT4;
  output CLKOUT5;
  output CLKOUT6;
  output CLKOUT7;
  output CLKOUT8;
  output CLKOUT9;
  output CLKOUT10;
  output CLKOUT11;
  output CLKOUT12;
  output CLKOUT13;
  output CLKOUT14;
  output CLKOUT15;
  output CLKFBOUT;
  input RST;
  output LOCKED;
endmodule

module proc_sys_reset_ddr_wrapper
  (
    Slowest_sync_clk,
    Ext_Reset_In,
    Aux_Reset_In,
    MB_Debug_Sys_Rst,
    Core_Reset_Req_0,
    Chip_Reset_Req_0,
    System_Reset_Req_0,
    Core_Reset_Req_1,
    Chip_Reset_Req_1,
    System_Reset_Req_1,
    Dcm_locked,
    RstcPPCresetcore_0,
    RstcPPCresetchip_0,
    RstcPPCresetsys_0,
    RstcPPCresetcore_1,
    RstcPPCresetchip_1,
    RstcPPCresetsys_1,
    MB_Reset,
    Bus_Struct_Reset,
    Peripheral_Reset
  );
  input Slowest_sync_clk;
  input Ext_Reset_In;
  input Aux_Reset_In;
  input MB_Debug_Sys_Rst;
  input Core_Reset_Req_0;
  input Chip_Reset_Req_0;
  input System_Reset_Req_0;
  input Core_Reset_Req_1;
  input Chip_Reset_Req_1;
  input System_Reset_Req_1;
  input Dcm_locked;
  output RstcPPCresetcore_0;
  output RstcPPCresetchip_0;
  output RstcPPCresetsys_0;
  output RstcPPCresetcore_1;
  output RstcPPCresetchip_1;
  output RstcPPCresetsys_1;
  output MB_Reset;
  output [0:0] Bus_Struct_Reset;
  output [0:0] Peripheral_Reset;
endmodule

