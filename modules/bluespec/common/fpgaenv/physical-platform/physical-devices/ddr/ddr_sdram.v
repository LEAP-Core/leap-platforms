module ddr_sdram( 
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
    sys_clk_pin,
    DDR_SDRAM_PIM0_Addr_pin,
    DDR_SDRAM_PIM0_AddrReq_pin,
    DDR_SDRAM_PIM0_AddrAck_pin,
    DDR_SDRAM_PIM0_RNW_pin,
    DDR_SDRAM_PIM0_Size_pin,
    DDR_SDRAM_PIM0_RdModWr_pin,
    DDR_SDRAM_PIM0_WrFIFO_Data_pin,
    DDR_SDRAM_PIM0_WrFIFO_BE_pin,
    DDR_SDRAM_PIM0_WrFIFO_Push_pin,
    DDR_SDRAM_PIM0_RdFIFO_Data_pin,
    DDR_SDRAM_PIM0_RdFIFO_Pop_pin,
    DDR_SDRAM_PIM0_RdFIFO_RdWdAddr_pin,
    DDR_SDRAM_PIM0_WrFIFO_Empty_pin,
    DDR_SDRAM_PIM0_WrFIFO_AlmostFull_pin,
    DDR_SDRAM_PIM0_WrFIFO_Flush_pin,
    DDR_SDRAM_PIM0_RdFIFO_Empty_pin,
    DDR_SDRAM_PIM0_RdFIFO_Flush_pin,
    DDR_SDRAM_PIM0_RdFIFO_Latency_pin,
    DDR_SDRAM_PIM0_InitDone_pin,
    DDR_SDRAM_MPMC_Rst_pin,
    // Dummy Enable lines
    addrReqDummyEn,
    addrDummyEn,
    rnwDummyEn,
    sizeDummyEn,
    rdModWrDummyEn,
    rdFIFO_PopDummyEn,
    rdFIFO_FlushDummyEn,
  
    wrFIFO_PushDummyEn,
    wrFIFO_FlushDummyEn,
    wrFIFO_DataDummyEn,
    wrFIFO_BEDummyEn
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
  input sys_clk_pin;
  input [31:0] DDR_SDRAM_PIM0_Addr_pin;
  input DDR_SDRAM_PIM0_AddrReq_pin;
  output DDR_SDRAM_PIM0_AddrAck_pin;
  input DDR_SDRAM_PIM0_RNW_pin;
  input [3:0] DDR_SDRAM_PIM0_Size_pin;
  input DDR_SDRAM_PIM0_RdModWr_pin;
  input [63:0] DDR_SDRAM_PIM0_WrFIFO_Data_pin;
  input [7:0] DDR_SDRAM_PIM0_WrFIFO_BE_pin;
  input DDR_SDRAM_PIM0_WrFIFO_Push_pin;
  output [63:0] DDR_SDRAM_PIM0_RdFIFO_Data_pin;
  input DDR_SDRAM_PIM0_RdFIFO_Pop_pin;
  output [3:0] DDR_SDRAM_PIM0_RdFIFO_RdWdAddr_pin;
  output DDR_SDRAM_PIM0_WrFIFO_Empty_pin;
  output DDR_SDRAM_PIM0_WrFIFO_AlmostFull_pin;
  input DDR_SDRAM_PIM0_WrFIFO_Flush_pin;
  output DDR_SDRAM_PIM0_RdFIFO_Empty_pin;
  input DDR_SDRAM_PIM0_RdFIFO_Flush_pin;
  output [1:0] DDR_SDRAM_PIM0_RdFIFO_Latency_pin;
  output DDR_SDRAM_PIM0_InitDone_pin;
  input DDR_SDRAM_MPMC_Rst_pin;
  input addrReqDummyEn;
  input addrDummyEn;
  input rnwDummyEn;
  input sizeDummyEn;
  input rdModWrDummyEn;
  input rdFIFO_PopDummyEn;
  input rdFIFO_FlushDummyEn;
  
  input wrFIFO_PushDummyEn;
  input wrFIFO_FlushDummyEn;
  input wrFIFO_DataDummyEn;
  input wrFIFO_BEDummyEn;

 ddr_sdram_xilinx dram
  (
    .fpga_0_DDR_SDRAM_DDR_Clk_pin(fpga_0_DDR_SDRAM_DDR_Clk_pin),
    .fpga_0_DDR_SDRAM_DDR_Clk_n_pin(fpga_0_DDR_SDRAM_DDR_Clk_n_pin),
    .fpga_0_DDR_SDRAM_DDR_Addr_pin(fpga_0_DDR_SDRAM_DDR_Addr_pin),
    .fpga_0_DDR_SDRAM_DDR_BankAddr_pin(fpga_0_DDR_SDRAM_DDR_BankAddr_pin),
    .fpga_0_DDR_SDRAM_DDR_CAS_n_pin(fpga_0_DDR_SDRAM_DDR_CAS_n_pin),
    .fpga_0_DDR_SDRAM_DDR_CE_pin(fpga_0_DDR_SDRAM_DDR_CE_pin),
    .fpga_0_DDR_SDRAM_DDR_CS_n_pin(fpga_0_DDR_SDRAM_DDR_CS_n_pin),
    .fpga_0_DDR_SDRAM_DDR_RAS_n_pin(fpga_0_DDR_SDRAM_DDR_RAS_n_pin),
    .fpga_0_DDR_SDRAM_DDR_WE_n_pin(fpga_0_DDR_SDRAM_DDR_WE_n_pin),
    .fpga_0_DDR_SDRAM_DDR_DM_pin(fpga_0_DDR_SDRAM_DDR_DM_pin),
    .fpga_0_DDR_SDRAM_DDR_DQS(fpga_0_DDR_SDRAM_DDR_DQS),
    .fpga_0_DDR_SDRAM_DDR_DQ(fpga_0_DDR_SDRAM_DDR_DQ),
    .fpga_0_net_gnd_pin(),
    .fpga_0_net_gnd_1_pin(),
    .fpga_0_net_gnd_2_pin(),
    .fpga_0_net_gnd_3_pin(),
    .fpga_0_net_gnd_4_pin(),
    .fpga_0_net_gnd_5_pin(),
    .fpga_0_net_gnd_6_pin(),
    .sys_clk_pin(sys_clk_pin),
    .DDR_SDRAM_PIM0_Addr_pin(DDR_SDRAM_PIM0_Addr_pin),
    .DDR_SDRAM_PIM0_AddrReq_pin(DDR_SDRAM_PIM0_AddrReq_pin),
    .DDR_SDRAM_PIM0_AddrAck_pin(DDR_SDRAM_PIM0_AddrAck_pin),
    .DDR_SDRAM_PIM0_RNW_pin(DDR_SDRAM_PIM0_RNW_pin),
    .DDR_SDRAM_PIM0_Size_pin(DDR_SDRAM_PIM0_Size_pin),
    .DDR_SDRAM_PIM0_RdModWr_pin(DR_SDRAM_PIM0_RdModWr_pin),
    .DDR_SDRAM_PIM0_WrFIFO_Data_pin(DDR_SDRAM_PIM0_WrFIFO_Data_pin),
    .DDR_SDRAM_PIM0_WrFIFO_BE_pin(DDR_SDRAM_PIM0_WrFIFO_BE_pin),
    .DDR_SDRAM_PIM0_WrFIFO_Push_pin(DDR_SDRAM_PIM0_WrFIFO_Push_pin),
    .DDR_SDRAM_PIM0_RdFIFO_Data_pin(DDR_SDRAM_PIM0_RdFIFO_Data_pin),
    .DDR_SDRAM_PIM0_RdFIFO_Pop_pin(DDR_SDRAM_PIM0_RdFIFO_Pop_pin),
    .DDR_SDRAM_PIM0_RdFIFO_RdWdAddr_pin(DDR_SDRAM_PIM0_RdFIFO_RdWdAddr_pin),
    .DDR_SDRAM_PIM0_WrFIFO_Empty_pin(DDR_SDRAM_PIM0_WrFIFO_Empty_pin),
    .DDR_SDRAM_PIM0_WrFIFO_AlmostFull_pin(DDR_SDRAM_PIM0_WrFIFO_AlmostFull_pin),
    .DDR_SDRAM_PIM0_WrFIFO_Flush_pin(DDR_SDRAM_PIM0_WrFIFO_Flush_pin),
    .DDR_SDRAM_PIM0_RdFIFO_Empty_pin(DDR_SDRAM_PIM0_RdFIFO_Empty_pin),
    .DDR_SDRAM_PIM0_RdFIFO_Flush_pin(DDR_SDRAM_PIM0_RdFIFO_Flush_pin),
    .DDR_SDRAM_PIM0_RdFIFO_Latency_pin(DDR_SDRAM_PIM0_RdFIFO_Latency_pin),
    .DDR_SDRAM_PIM0_InitDone_pin(DDR_SDRAM_PIM0_InitDone_pin),
    .DDR_SDRAM_MPMC_Rst_pin(DDR_SDRAM_MPMC_Rst_pin)
  );

endmodule