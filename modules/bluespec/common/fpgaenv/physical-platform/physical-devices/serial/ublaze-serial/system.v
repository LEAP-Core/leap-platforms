//-----------------------------------------------------------------------------
// system.v
//-----------------------------------------------------------------------------

module system
  (
    fpga_0_RS232_Uart_1_ctsN_pin,
    fpga_0_RS232_Uart_1_rtsN_pin,
    fpga_0_RS232_Uart_1_sin_pin,
    fpga_0_RS232_Uart_1_sout_pin,
    fpga_0_net_gnd_pin,
    fpga_0_net_gnd_1_pin,
    fpga_0_net_gnd_2_pin,
    fpga_0_net_gnd_3_pin,
    fpga_0_net_gnd_4_pin,
    fpga_0_net_gnd_5_pin,
    fpga_0_net_gnd_6_pin,
    sys_clk_pin,
    sys_rst_pin,
    bramfeeder_0_RDY_ppcMessageOutput_get_pin,
    bramfeeder_0_ppcMessageInput_put_pin,
    bramfeeder_0_ppcMessageOutput_get_pin,
    bramfeeder_0_EN_ppcMessageOutput_get_pin,
    bramfeeder_0_RDY_ppcMessageInput_put_pin,
    bramfeeder_0_EN_ppcMessageInput_put_pin,
    clock_generator_0_RSTOUT0_pin,
    clock_generator_0_CLKOUT0_pin
  );
  input fpga_0_RS232_Uart_1_ctsN_pin;
  output fpga_0_RS232_Uart_1_rtsN_pin;
  input fpga_0_RS232_Uart_1_sin_pin;
  output fpga_0_RS232_Uart_1_sout_pin;
  output fpga_0_net_gnd_pin;
  output fpga_0_net_gnd_1_pin;
  output fpga_0_net_gnd_2_pin;
  output fpga_0_net_gnd_3_pin;
  output fpga_0_net_gnd_4_pin;
  output fpga_0_net_gnd_5_pin;
  output fpga_0_net_gnd_6_pin;
  input sys_clk_pin;
  input sys_rst_pin;
  output bramfeeder_0_RDY_ppcMessageOutput_get_pin;
  input [31:0] bramfeeder_0_ppcMessageInput_put_pin;
  output [31:0] bramfeeder_0_ppcMessageOutput_get_pin;
  input bramfeeder_0_EN_ppcMessageOutput_get_pin;
  output bramfeeder_0_RDY_ppcMessageInput_put_pin;
  input bramfeeder_0_EN_ppcMessageInput_put_pin;
  output clock_generator_0_RSTOUT0_pin;
  output clock_generator_0_CLKOUT0_pin;

  // Internal signals

  wire Dcm_all_locked;
  wire bramfeeder_0_EN_ppcMessageInput_put;
  wire bramfeeder_0_EN_ppcMessageOutput_get;
  wire [0:31] bramfeeder_0_PORTA_BRAM_Addr;
  wire bramfeeder_0_PORTA_BRAM_Clk;
  wire [31:0] bramfeeder_0_PORTA_BRAM_Din;
  wire [0:31] bramfeeder_0_PORTA_BRAM_Dout;
  wire bramfeeder_0_PORTA_BRAM_EN;
  wire bramfeeder_0_PORTA_BRAM_Rst;
  wire [0:3] bramfeeder_0_PORTA_BRAM_WEN;
  wire bramfeeder_0_RDY_ppcMessageInput_put;
  wire bramfeeder_0_RDY_ppcMessageOutput_get;
  wire [31:0] bramfeeder_0_ppcMessageInput_put;
  wire [31:0] bramfeeder_0_ppcMessageOutput_get;
  wire dcm_clk_s;
  wire [0:31] dlmb_LMB_ABus;
  wire dlmb_LMB_AddrStrobe;
  wire [0:3] dlmb_LMB_BE;
  wire [0:31] dlmb_LMB_ReadDBus;
  wire dlmb_LMB_ReadStrobe;
  wire dlmb_LMB_Ready;
  wire [0:31] dlmb_LMB_WriteDBus;
  wire dlmb_LMB_WriteStrobe;
  wire [0:31] dlmb_M_ABus;
  wire dlmb_M_AddrStrobe;
  wire [0:3] dlmb_M_BE;
  wire [0:31] dlmb_M_DBus;
  wire dlmb_M_ReadStrobe;
  wire dlmb_M_WriteStrobe;
  wire dlmb_OPB_Rst;
  wire [0:31] dlmb_Sl_DBus;
  wire [0:0] dlmb_Sl_Ready;
  wire [0:31] dlmb_port_BRAM_Addr;
  wire dlmb_port_BRAM_Clk;
  wire [0:31] dlmb_port_BRAM_Din;
  wire [0:31] dlmb_port_BRAM_Dout;
  wire dlmb_port_BRAM_EN;
  wire dlmb_port_BRAM_Rst;
  wire [0:3] dlmb_port_BRAM_WEN;
  wire fpga_0_RS232_Uart_1_ctsN;
  wire fpga_0_RS232_Uart_1_rtsN;
  wire fpga_0_RS232_Uart_1_sin;
  wire fpga_0_RS232_Uart_1_sout;
  wire [0:31] ilmb_LMB_ABus;
  wire ilmb_LMB_AddrStrobe;
  wire [0:3] ilmb_LMB_BE;
  wire [0:31] ilmb_LMB_ReadDBus;
  wire ilmb_LMB_ReadStrobe;
  wire ilmb_LMB_Ready;
  wire [0:31] ilmb_LMB_WriteDBus;
  wire ilmb_LMB_WriteStrobe;
  wire [0:31] ilmb_M_ABus;
  wire ilmb_M_AddrStrobe;
  wire ilmb_M_ReadStrobe;
  wire ilmb_OPB_Rst;
  wire [0:31] ilmb_Sl_DBus;
  wire [0:0] ilmb_Sl_Ready;
  wire [0:31] ilmb_port_BRAM_Addr;
  wire ilmb_port_BRAM_Clk;
  wire [0:31] ilmb_port_BRAM_Din;
  wire [0:31] ilmb_port_BRAM_Dout;
  wire ilmb_port_BRAM_EN;
  wire ilmb_port_BRAM_Rst;
  wire [0:3] ilmb_port_BRAM_WEN;
  wire [0:1] mb_plb_M_ABort;
  wire [0:63] mb_plb_M_ABus;
  wire [0:7] mb_plb_M_BE;
  wire [0:3] mb_plb_M_MSize;
  wire [0:1] mb_plb_M_RNW;
  wire [0:31] mb_plb_M_TAttribute;
  wire [0:63] mb_plb_M_UABus;
  wire [0:1] mb_plb_M_busLock;
  wire [0:1] mb_plb_M_lockErr;
  wire [0:3] mb_plb_M_priority;
  wire [0:1] mb_plb_M_rdBurst;
  wire [0:1] mb_plb_M_request;
  wire [0:7] mb_plb_M_size;
  wire [0:5] mb_plb_M_type;
  wire [0:1] mb_plb_M_wrBurst;
  wire [0:63] mb_plb_M_wrDBus;
  wire [0:31] mb_plb_PLB_ABus;
  wire [0:3] mb_plb_PLB_BE;
  wire [0:1] mb_plb_PLB_MAddrAck;
  wire [0:1] mb_plb_PLB_MBusy;
  wire [0:1] mb_plb_PLB_MIRQ;
  wire [0:1] mb_plb_PLB_MRdBTerm;
  wire [0:1] mb_plb_PLB_MRdDAck;
  wire [0:63] mb_plb_PLB_MRdDBus;
  wire [0:1] mb_plb_PLB_MRdErr;
  wire [0:7] mb_plb_PLB_MRdWdAddr;
  wire [0:1] mb_plb_PLB_MRearbitrate;
  wire [0:3] mb_plb_PLB_MSSize;
  wire [0:1] mb_plb_PLB_MSize;
  wire [0:1] mb_plb_PLB_MTimeout;
  wire [0:1] mb_plb_PLB_MWrBTerm;
  wire [0:1] mb_plb_PLB_MWrDAck;
  wire [0:1] mb_plb_PLB_MWrErr;
  wire mb_plb_PLB_PAValid;
  wire mb_plb_PLB_RNW;
  wire mb_plb_PLB_SAValid;
  wire [0:15] mb_plb_PLB_TAttribute;
  wire [0:31] mb_plb_PLB_UABus;
  wire mb_plb_PLB_abort;
  wire mb_plb_PLB_busLock;
  wire mb_plb_PLB_lockErr;
  wire [0:0] mb_plb_PLB_masterID;
  wire mb_plb_PLB_rdBurst;
  wire [0:1] mb_plb_PLB_rdPendPri;
  wire mb_plb_PLB_rdPendReq;
  wire [0:1] mb_plb_PLB_rdPrim;
  wire [0:1] mb_plb_PLB_reqPri;
  wire [0:3] mb_plb_PLB_size;
  wire [0:2] mb_plb_PLB_type;
  wire mb_plb_PLB_wrBurst;
  wire [0:31] mb_plb_PLB_wrDBus;
  wire [0:1] mb_plb_PLB_wrPendPri;
  wire mb_plb_PLB_wrPendReq;
  wire [0:1] mb_plb_PLB_wrPrim;
  wire [0:1] mb_plb_SPLB_Rst;
  wire [0:3] mb_plb_Sl_MBusy;
  wire [0:3] mb_plb_Sl_MIRQ;
  wire [0:3] mb_plb_Sl_MRdErr;
  wire [0:3] mb_plb_Sl_MWrErr;
  wire [0:3] mb_plb_Sl_SSize;
  wire [0:1] mb_plb_Sl_addrAck;
  wire [0:1] mb_plb_Sl_rdBTerm;
  wire [0:1] mb_plb_Sl_rdComp;
  wire [0:1] mb_plb_Sl_rdDAck;
  wire [0:63] mb_plb_Sl_rdDBus;
  wire [0:7] mb_plb_Sl_rdWdAddr;
  wire [0:1] mb_plb_Sl_rearbitrate;
  wire [0:1] mb_plb_Sl_wait;
  wire [0:1] mb_plb_Sl_wrBTerm;
  wire [0:1] mb_plb_Sl_wrComp;
  wire [0:1] mb_plb_Sl_wrDAck;
  wire mb_reset;
  wire net_gnd0;
  wire [0:3] net_gnd4;
  wire [0:4] net_gnd5;
  wire [0:9] net_gnd10;
  wire [0:31] net_gnd32;
  wire [0:0] sys_bus_reset;
  wire sys_clk_s;
  wire [0:0] sys_periph_reset;
  wire sys_rst_s;
  wire [0:31] xps_bram_if_cntlr_1_port_BRAM_Addr;
  wire xps_bram_if_cntlr_1_port_BRAM_Clk;
  wire [0:31] xps_bram_if_cntlr_1_port_BRAM_Din;
  wire [0:31] xps_bram_if_cntlr_1_port_BRAM_Dout;
  wire xps_bram_if_cntlr_1_port_BRAM_EN;
  wire xps_bram_if_cntlr_1_port_BRAM_Rst;
  wire [0:3] xps_bram_if_cntlr_1_port_BRAM_WEN;

  // Internal assignments

  assign fpga_0_RS232_Uart_1_ctsN = fpga_0_RS232_Uart_1_ctsN_pin;
  assign fpga_0_RS232_Uart_1_rtsN_pin = fpga_0_RS232_Uart_1_rtsN;
  assign fpga_0_RS232_Uart_1_sin = fpga_0_RS232_Uart_1_sin_pin;
  assign fpga_0_RS232_Uart_1_sout_pin = fpga_0_RS232_Uart_1_sout;
  assign dcm_clk_s = sys_clk_pin;
  assign sys_rst_s = sys_rst_pin;
  assign bramfeeder_0_RDY_ppcMessageOutput_get_pin = bramfeeder_0_RDY_ppcMessageOutput_get;
  assign bramfeeder_0_ppcMessageInput_put = bramfeeder_0_ppcMessageInput_put_pin;
  assign bramfeeder_0_ppcMessageOutput_get_pin = bramfeeder_0_ppcMessageOutput_get;
  assign bramfeeder_0_EN_ppcMessageOutput_get = bramfeeder_0_EN_ppcMessageOutput_get_pin;
  assign bramfeeder_0_RDY_ppcMessageInput_put_pin = bramfeeder_0_RDY_ppcMessageInput_put;
  assign bramfeeder_0_EN_ppcMessageInput_put = bramfeeder_0_EN_ppcMessageInput_put_pin;
  assign clock_generator_0_RSTOUT0_pin = sys_periph_reset[0];
  assign clock_generator_0_CLKOUT0_pin = sys_clk_s;
  assign net_gnd0 = 1'b0;
  assign fpga_0_net_gnd_pin = net_gnd0;
  assign fpga_0_net_gnd_1_pin = net_gnd0;
  assign fpga_0_net_gnd_2_pin = net_gnd0;
  assign fpga_0_net_gnd_3_pin = net_gnd0;
  assign fpga_0_net_gnd_4_pin = net_gnd0;
  assign fpga_0_net_gnd_5_pin = net_gnd0;
  assign fpga_0_net_gnd_6_pin = net_gnd0;
  assign net_gnd10[0:9] = 10'b0000000000;
  assign net_gnd32[0:31] = 32'b00000000000000000000000000000000;
  assign net_gnd4[0:3] = 4'b0000;
  assign net_gnd5[0:4] = 5'b00000;

  microblaze_0_wrapper
    microblaze_0 (
      .CLK ( sys_clk_s ),
      .RESET ( dlmb_OPB_Rst ),
      .MB_RESET ( mb_reset ),
      .INTERRUPT ( net_gnd0 ),
      .EXT_BRK ( net_gnd0 ),
      .EXT_NM_BRK ( net_gnd0 ),
      .DBG_STOP ( net_gnd0 ),
      .MB_Halted (  ),
      .INSTR ( ilmb_LMB_ReadDBus ),
      .I_ADDRTAG (  ),
      .IREADY ( ilmb_LMB_Ready ),
      .IWAIT ( net_gnd0 ),
      .INSTR_ADDR ( ilmb_M_ABus ),
      .IFETCH ( ilmb_M_ReadStrobe ),
      .I_AS ( ilmb_M_AddrStrobe ),
      .IPLB_M_ABort ( mb_plb_M_ABort[1] ),
      .IPLB_M_ABus ( mb_plb_M_ABus[32:63] ),
      .IPLB_M_UABus ( mb_plb_M_UABus[32:63] ),
      .IPLB_M_BE ( mb_plb_M_BE[4:7] ),
      .IPLB_M_busLock ( mb_plb_M_busLock[1] ),
      .IPLB_M_lockErr ( mb_plb_M_lockErr[1] ),
      .IPLB_M_MSize ( mb_plb_M_MSize[2:3] ),
      .IPLB_M_priority ( mb_plb_M_priority[2:3] ),
      .IPLB_M_rdBurst ( mb_plb_M_rdBurst[1] ),
      .IPLB_M_request ( mb_plb_M_request[1] ),
      .IPLB_M_RNW ( mb_plb_M_RNW[1] ),
      .IPLB_M_size ( mb_plb_M_size[4:7] ),
      .IPLB_M_TAttribute ( mb_plb_M_TAttribute[16:31] ),
      .IPLB_M_type ( mb_plb_M_type[3:5] ),
      .IPLB_M_wrBurst ( mb_plb_M_wrBurst[1] ),
      .IPLB_M_wrDBus ( mb_plb_M_wrDBus[32:63] ),
      .IPLB_MBusy ( mb_plb_PLB_MBusy[1] ),
      .IPLB_MRdErr ( mb_plb_PLB_MRdErr[1] ),
      .IPLB_MWrErr ( mb_plb_PLB_MWrErr[1] ),
      .IPLB_MIRQ ( mb_plb_PLB_MIRQ[1] ),
      .IPLB_MWrBTerm ( mb_plb_PLB_MWrBTerm[1] ),
      .IPLB_MWrDAck ( mb_plb_PLB_MWrDAck[1] ),
      .IPLB_MAddrAck ( mb_plb_PLB_MAddrAck[1] ),
      .IPLB_MRdBTerm ( mb_plb_PLB_MRdBTerm[1] ),
      .IPLB_MRdDAck ( mb_plb_PLB_MRdDAck[1] ),
      .IPLB_MRdDBus ( mb_plb_PLB_MRdDBus[32:63] ),
      .IPLB_MRdWdAddr ( mb_plb_PLB_MRdWdAddr[4:7] ),
      .IPLB_MRearbitrate ( mb_plb_PLB_MRearbitrate[1] ),
      .IPLB_MSSize ( mb_plb_PLB_MSSize[2:3] ),
      .IPLB_MTimeout ( mb_plb_PLB_MTimeout[1] ),
      .DATA_READ ( dlmb_LMB_ReadDBus ),
      .DREADY ( dlmb_LMB_Ready ),
      .DWAIT ( net_gnd0 ),
      .DATA_WRITE ( dlmb_M_DBus ),
      .DATA_ADDR ( dlmb_M_ABus ),
      .D_ADDRTAG (  ),
      .D_AS ( dlmb_M_AddrStrobe ),
      .READ_STROBE ( dlmb_M_ReadStrobe ),
      .WRITE_STROBE ( dlmb_M_WriteStrobe ),
      .BYTE_ENABLE ( dlmb_M_BE ),
      .DM_ABUS (  ),
      .DM_BE (  ),
      .DM_BUSLOCK (  ),
      .DM_DBUS (  ),
      .DM_REQUEST (  ),
      .DM_RNW (  ),
      .DM_SELECT (  ),
      .DM_SEQADDR (  ),
      .DOPB_DBUS ( net_gnd32 ),
      .DOPB_ERRACK ( net_gnd0 ),
      .DOPB_MGRANT ( net_gnd0 ),
      .DOPB_RETRY ( net_gnd0 ),
      .DOPB_TIMEOUT ( net_gnd0 ),
      .DOPB_XFERACK ( net_gnd0 ),
      .DPLB_M_ABort ( mb_plb_M_ABort[0] ),
      .DPLB_M_ABus ( mb_plb_M_ABus[0:31] ),
      .DPLB_M_UABus ( mb_plb_M_UABus[0:31] ),
      .DPLB_M_BE ( mb_plb_M_BE[0:3] ),
      .DPLB_M_busLock ( mb_plb_M_busLock[0] ),
      .DPLB_M_lockErr ( mb_plb_M_lockErr[0] ),
      .DPLB_M_MSize ( mb_plb_M_MSize[0:1] ),
      .DPLB_M_priority ( mb_plb_M_priority[0:1] ),
      .DPLB_M_rdBurst ( mb_plb_M_rdBurst[0] ),
      .DPLB_M_request ( mb_plb_M_request[0] ),
      .DPLB_M_RNW ( mb_plb_M_RNW[0] ),
      .DPLB_M_size ( mb_plb_M_size[0:3] ),
      .DPLB_M_TAttribute ( mb_plb_M_TAttribute[0:15] ),
      .DPLB_M_type ( mb_plb_M_type[0:2] ),
      .DPLB_M_wrBurst ( mb_plb_M_wrBurst[0] ),
      .DPLB_M_wrDBus ( mb_plb_M_wrDBus[0:31] ),
      .DPLB_MBusy ( mb_plb_PLB_MBusy[0] ),
      .DPLB_MRdErr ( mb_plb_PLB_MRdErr[0] ),
      .DPLB_MWrErr ( mb_plb_PLB_MWrErr[0] ),
      .DPLB_MIRQ ( mb_plb_PLB_MIRQ[0] ),
      .DPLB_MWrBTerm ( mb_plb_PLB_MWrBTerm[0] ),
      .DPLB_MWrDAck ( mb_plb_PLB_MWrDAck[0] ),
      .DPLB_MAddrAck ( mb_plb_PLB_MAddrAck[0] ),
      .DPLB_MRdBTerm ( mb_plb_PLB_MRdBTerm[0] ),
      .DPLB_MRdDAck ( mb_plb_PLB_MRdDAck[0] ),
      .DPLB_MRdDBus ( mb_plb_PLB_MRdDBus[0:31] ),
      .DPLB_MRdWdAddr ( mb_plb_PLB_MRdWdAddr[0:3] ),
      .DPLB_MRearbitrate ( mb_plb_PLB_MRearbitrate[0] ),
      .DPLB_MSSize ( mb_plb_PLB_MSSize[0:1] ),
      .DPLB_MTimeout ( mb_plb_PLB_MTimeout[0] ),
      .IM_ABUS (  ),
      .IM_BE (  ),
      .IM_BUSLOCK (  ),
      .IM_DBUS (  ),
      .IM_REQUEST (  ),
      .IM_RNW (  ),
      .IM_SELECT (  ),
      .IM_SEQADDR (  ),
      .IOPB_DBUS ( net_gnd32 ),
      .IOPB_ERRACK ( net_gnd0 ),
      .IOPB_MGRANT ( net_gnd0 ),
      .IOPB_RETRY ( net_gnd0 ),
      .IOPB_TIMEOUT ( net_gnd0 ),
      .IOPB_XFERACK ( net_gnd0 ),
      .DBG_CLK ( net_gnd0 ),
      .DBG_TDI ( net_gnd0 ),
      .DBG_TDO (  ),
      .DBG_REG_EN ( net_gnd5 ),
      .DBG_SHIFT ( net_gnd0 ),
      .DBG_CAPTURE ( net_gnd0 ),
      .DBG_UPDATE ( net_gnd0 ),
      .DEBUG_RST ( net_gnd0 ),
      .Trace_Instruction (  ),
      .Trace_Valid_Instr (  ),
      .Trace_PC (  ),
      .Trace_Reg_Write (  ),
      .Trace_Reg_Addr (  ),
      .Trace_MSR_Reg (  ),
      .Trace_PID_Reg (  ),
      .Trace_New_Reg_Value (  ),
      .Trace_Exception_Taken (  ),
      .Trace_Exception_Kind (  ),
      .Trace_Jump_Taken (  ),
      .Trace_Delay_Slot (  ),
      .Trace_Data_Address (  ),
      .Trace_Data_Access (  ),
      .Trace_Data_Read (  ),
      .Trace_Data_Write (  ),
      .Trace_Data_Write_Value (  ),
      .Trace_Data_Byte_Enable (  ),
      .Trace_DCache_Req (  ),
      .Trace_DCache_Hit (  ),
      .Trace_ICache_Req (  ),
      .Trace_ICache_Hit (  ),
      .Trace_OF_PipeRun (  ),
      .Trace_EX_PipeRun (  ),
      .Trace_MEM_PipeRun (  ),
      .Trace_MB_Halted (  ),
      .FSL0_S_CLK (  ),
      .FSL0_S_READ (  ),
      .FSL0_S_DATA ( net_gnd32 ),
      .FSL0_S_CONTROL ( net_gnd0 ),
      .FSL0_S_EXISTS ( net_gnd0 ),
      .FSL0_M_CLK (  ),
      .FSL0_M_WRITE (  ),
      .FSL0_M_DATA (  ),
      .FSL0_M_CONTROL (  ),
      .FSL0_M_FULL ( net_gnd0 ),
      .FSL1_S_CLK (  ),
      .FSL1_S_READ (  ),
      .FSL1_S_DATA ( net_gnd32 ),
      .FSL1_S_CONTROL ( net_gnd0 ),
      .FSL1_S_EXISTS ( net_gnd0 ),
      .FSL1_M_CLK (  ),
      .FSL1_M_WRITE (  ),
      .FSL1_M_DATA (  ),
      .FSL1_M_CONTROL (  ),
      .FSL1_M_FULL ( net_gnd0 ),
      .FSL2_S_CLK (  ),
      .FSL2_S_READ (  ),
      .FSL2_S_DATA ( net_gnd32 ),
      .FSL2_S_CONTROL ( net_gnd0 ),
      .FSL2_S_EXISTS ( net_gnd0 ),
      .FSL2_M_CLK (  ),
      .FSL2_M_WRITE (  ),
      .FSL2_M_DATA (  ),
      .FSL2_M_CONTROL (  ),
      .FSL2_M_FULL ( net_gnd0 ),
      .FSL3_S_CLK (  ),
      .FSL3_S_READ (  ),
      .FSL3_S_DATA ( net_gnd32 ),
      .FSL3_S_CONTROL ( net_gnd0 ),
      .FSL3_S_EXISTS ( net_gnd0 ),
      .FSL3_M_CLK (  ),
      .FSL3_M_WRITE (  ),
      .FSL3_M_DATA (  ),
      .FSL3_M_CONTROL (  ),
      .FSL3_M_FULL ( net_gnd0 ),
      .FSL4_S_CLK (  ),
      .FSL4_S_READ (  ),
      .FSL4_S_DATA ( net_gnd32 ),
      .FSL4_S_CONTROL ( net_gnd0 ),
      .FSL4_S_EXISTS ( net_gnd0 ),
      .FSL4_M_CLK (  ),
      .FSL4_M_WRITE (  ),
      .FSL4_M_DATA (  ),
      .FSL4_M_CONTROL (  ),
      .FSL4_M_FULL ( net_gnd0 ),
      .FSL5_S_CLK (  ),
      .FSL5_S_READ (  ),
      .FSL5_S_DATA ( net_gnd32 ),
      .FSL5_S_CONTROL ( net_gnd0 ),
      .FSL5_S_EXISTS ( net_gnd0 ),
      .FSL5_M_CLK (  ),
      .FSL5_M_WRITE (  ),
      .FSL5_M_DATA (  ),
      .FSL5_M_CONTROL (  ),
      .FSL5_M_FULL ( net_gnd0 ),
      .FSL6_S_CLK (  ),
      .FSL6_S_READ (  ),
      .FSL6_S_DATA ( net_gnd32 ),
      .FSL6_S_CONTROL ( net_gnd0 ),
      .FSL6_S_EXISTS ( net_gnd0 ),
      .FSL6_M_CLK (  ),
      .FSL6_M_WRITE (  ),
      .FSL6_M_DATA (  ),
      .FSL6_M_CONTROL (  ),
      .FSL6_M_FULL ( net_gnd0 ),
      .FSL7_S_CLK (  ),
      .FSL7_S_READ (  ),
      .FSL7_S_DATA ( net_gnd32 ),
      .FSL7_S_CONTROL ( net_gnd0 ),
      .FSL7_S_EXISTS ( net_gnd0 ),
      .FSL7_M_CLK (  ),
      .FSL7_M_WRITE (  ),
      .FSL7_M_DATA (  ),
      .FSL7_M_CONTROL (  ),
      .FSL7_M_FULL ( net_gnd0 ),
      .FSL8_S_CLK (  ),
      .FSL8_S_READ (  ),
      .FSL8_S_DATA ( net_gnd32 ),
      .FSL8_S_CONTROL ( net_gnd0 ),
      .FSL8_S_EXISTS ( net_gnd0 ),
      .FSL8_M_CLK (  ),
      .FSL8_M_WRITE (  ),
      .FSL8_M_DATA (  ),
      .FSL8_M_CONTROL (  ),
      .FSL8_M_FULL ( net_gnd0 ),
      .FSL9_S_CLK (  ),
      .FSL9_S_READ (  ),
      .FSL9_S_DATA ( net_gnd32 ),
      .FSL9_S_CONTROL ( net_gnd0 ),
      .FSL9_S_EXISTS ( net_gnd0 ),
      .FSL9_M_CLK (  ),
      .FSL9_M_WRITE (  ),
      .FSL9_M_DATA (  ),
      .FSL9_M_CONTROL (  ),
      .FSL9_M_FULL ( net_gnd0 ),
      .FSL10_S_CLK (  ),
      .FSL10_S_READ (  ),
      .FSL10_S_DATA ( net_gnd32 ),
      .FSL10_S_CONTROL ( net_gnd0 ),
      .FSL10_S_EXISTS ( net_gnd0 ),
      .FSL10_M_CLK (  ),
      .FSL10_M_WRITE (  ),
      .FSL10_M_DATA (  ),
      .FSL10_M_CONTROL (  ),
      .FSL10_M_FULL ( net_gnd0 ),
      .FSL11_S_CLK (  ),
      .FSL11_S_READ (  ),
      .FSL11_S_DATA ( net_gnd32 ),
      .FSL11_S_CONTROL ( net_gnd0 ),
      .FSL11_S_EXISTS ( net_gnd0 ),
      .FSL11_M_CLK (  ),
      .FSL11_M_WRITE (  ),
      .FSL11_M_DATA (  ),
      .FSL11_M_CONTROL (  ),
      .FSL11_M_FULL ( net_gnd0 ),
      .FSL12_S_CLK (  ),
      .FSL12_S_READ (  ),
      .FSL12_S_DATA ( net_gnd32 ),
      .FSL12_S_CONTROL ( net_gnd0 ),
      .FSL12_S_EXISTS ( net_gnd0 ),
      .FSL12_M_CLK (  ),
      .FSL12_M_WRITE (  ),
      .FSL12_M_DATA (  ),
      .FSL12_M_CONTROL (  ),
      .FSL12_M_FULL ( net_gnd0 ),
      .FSL13_S_CLK (  ),
      .FSL13_S_READ (  ),
      .FSL13_S_DATA ( net_gnd32 ),
      .FSL13_S_CONTROL ( net_gnd0 ),
      .FSL13_S_EXISTS ( net_gnd0 ),
      .FSL13_M_CLK (  ),
      .FSL13_M_WRITE (  ),
      .FSL13_M_DATA (  ),
      .FSL13_M_CONTROL (  ),
      .FSL13_M_FULL ( net_gnd0 ),
      .FSL14_S_CLK (  ),
      .FSL14_S_READ (  ),
      .FSL14_S_DATA ( net_gnd32 ),
      .FSL14_S_CONTROL ( net_gnd0 ),
      .FSL14_S_EXISTS ( net_gnd0 ),
      .FSL14_M_CLK (  ),
      .FSL14_M_WRITE (  ),
      .FSL14_M_DATA (  ),
      .FSL14_M_CONTROL (  ),
      .FSL14_M_FULL ( net_gnd0 ),
      .FSL15_S_CLK (  ),
      .FSL15_S_READ (  ),
      .FSL15_S_DATA ( net_gnd32 ),
      .FSL15_S_CONTROL ( net_gnd0 ),
      .FSL15_S_EXISTS ( net_gnd0 ),
      .FSL15_M_CLK (  ),
      .FSL15_M_WRITE (  ),
      .FSL15_M_DATA (  ),
      .FSL15_M_CONTROL (  ),
      .FSL15_M_FULL ( net_gnd0 ),
      .ICACHE_FSL_IN_CLK (  ),
      .ICACHE_FSL_IN_READ (  ),
      .ICACHE_FSL_IN_DATA ( net_gnd32 ),
      .ICACHE_FSL_IN_CONTROL ( net_gnd0 ),
      .ICACHE_FSL_IN_EXISTS ( net_gnd0 ),
      .ICACHE_FSL_OUT_CLK (  ),
      .ICACHE_FSL_OUT_WRITE (  ),
      .ICACHE_FSL_OUT_DATA (  ),
      .ICACHE_FSL_OUT_CONTROL (  ),
      .ICACHE_FSL_OUT_FULL ( net_gnd0 ),
      .DCACHE_FSL_IN_CLK (  ),
      .DCACHE_FSL_IN_READ (  ),
      .DCACHE_FSL_IN_DATA ( net_gnd32 ),
      .DCACHE_FSL_IN_CONTROL ( net_gnd0 ),
      .DCACHE_FSL_IN_EXISTS ( net_gnd0 ),
      .DCACHE_FSL_OUT_CLK (  ),
      .DCACHE_FSL_OUT_WRITE (  ),
      .DCACHE_FSL_OUT_DATA (  ),
      .DCACHE_FSL_OUT_CONTROL (  ),
      .DCACHE_FSL_OUT_FULL ( net_gnd0 )
    );

  mb_plb_wrapper
    mb_plb (
      .PLB_Clk ( sys_clk_s ),
      .SYS_Rst ( sys_bus_reset[0] ),
      .PLB_Rst (  ),
      .SPLB_Rst ( mb_plb_SPLB_Rst ),
      .MPLB_Rst (  ),
      .PLB_dcrAck (  ),
      .PLB_dcrDBus (  ),
      .DCR_ABus ( net_gnd10 ),
      .DCR_DBus ( net_gnd32 ),
      .DCR_Read ( net_gnd0 ),
      .DCR_Write ( net_gnd0 ),
      .M_ABus ( mb_plb_M_ABus ),
      .M_UABus ( mb_plb_M_UABus ),
      .M_BE ( mb_plb_M_BE ),
      .M_RNW ( mb_plb_M_RNW ),
      .M_abort ( mb_plb_M_ABort ),
      .M_busLock ( mb_plb_M_busLock ),
      .M_TAttribute ( mb_plb_M_TAttribute ),
      .M_lockErr ( mb_plb_M_lockErr ),
      .M_MSize ( mb_plb_M_MSize ),
      .M_priority ( mb_plb_M_priority ),
      .M_rdBurst ( mb_plb_M_rdBurst ),
      .M_request ( mb_plb_M_request ),
      .M_size ( mb_plb_M_size ),
      .M_type ( mb_plb_M_type ),
      .M_wrBurst ( mb_plb_M_wrBurst ),
      .M_wrDBus ( mb_plb_M_wrDBus ),
      .Sl_addrAck ( mb_plb_Sl_addrAck ),
      .Sl_MRdErr ( mb_plb_Sl_MRdErr ),
      .Sl_MWrErr ( mb_plb_Sl_MWrErr ),
      .Sl_MBusy ( mb_plb_Sl_MBusy ),
      .Sl_rdBTerm ( mb_plb_Sl_rdBTerm ),
      .Sl_rdComp ( mb_plb_Sl_rdComp ),
      .Sl_rdDAck ( mb_plb_Sl_rdDAck ),
      .Sl_rdDBus ( mb_plb_Sl_rdDBus ),
      .Sl_rdWdAddr ( mb_plb_Sl_rdWdAddr ),
      .Sl_rearbitrate ( mb_plb_Sl_rearbitrate ),
      .Sl_SSize ( mb_plb_Sl_SSize ),
      .Sl_wait ( mb_plb_Sl_wait ),
      .Sl_wrBTerm ( mb_plb_Sl_wrBTerm ),
      .Sl_wrComp ( mb_plb_Sl_wrComp ),
      .Sl_wrDAck ( mb_plb_Sl_wrDAck ),
      .Sl_MIRQ ( mb_plb_Sl_MIRQ ),
      .PLB_MIRQ ( mb_plb_PLB_MIRQ ),
      .PLB_ABus ( mb_plb_PLB_ABus ),
      .PLB_UABus ( mb_plb_PLB_UABus ),
      .PLB_BE ( mb_plb_PLB_BE ),
      .PLB_MAddrAck ( mb_plb_PLB_MAddrAck ),
      .PLB_MTimeout ( mb_plb_PLB_MTimeout ),
      .PLB_MBusy ( mb_plb_PLB_MBusy ),
      .PLB_MRdErr ( mb_plb_PLB_MRdErr ),
      .PLB_MWrErr ( mb_plb_PLB_MWrErr ),
      .PLB_MRdBTerm ( mb_plb_PLB_MRdBTerm ),
      .PLB_MRdDAck ( mb_plb_PLB_MRdDAck ),
      .PLB_MRdDBus ( mb_plb_PLB_MRdDBus ),
      .PLB_MRdWdAddr ( mb_plb_PLB_MRdWdAddr ),
      .PLB_MRearbitrate ( mb_plb_PLB_MRearbitrate ),
      .PLB_MWrBTerm ( mb_plb_PLB_MWrBTerm ),
      .PLB_MWrDAck ( mb_plb_PLB_MWrDAck ),
      .PLB_MSSize ( mb_plb_PLB_MSSize ),
      .PLB_PAValid ( mb_plb_PLB_PAValid ),
      .PLB_RNW ( mb_plb_PLB_RNW ),
      .PLB_SAValid ( mb_plb_PLB_SAValid ),
      .PLB_abort ( mb_plb_PLB_abort ),
      .PLB_busLock ( mb_plb_PLB_busLock ),
      .PLB_TAttribute ( mb_plb_PLB_TAttribute ),
      .PLB_lockErr ( mb_plb_PLB_lockErr ),
      .PLB_masterID ( mb_plb_PLB_masterID[0:0] ),
      .PLB_MSize ( mb_plb_PLB_MSize ),
      .PLB_rdPendPri ( mb_plb_PLB_rdPendPri ),
      .PLB_wrPendPri ( mb_plb_PLB_wrPendPri ),
      .PLB_rdPendReq ( mb_plb_PLB_rdPendReq ),
      .PLB_wrPendReq ( mb_plb_PLB_wrPendReq ),
      .PLB_rdBurst ( mb_plb_PLB_rdBurst ),
      .PLB_rdPrim ( mb_plb_PLB_rdPrim ),
      .PLB_reqPri ( mb_plb_PLB_reqPri ),
      .PLB_size ( mb_plb_PLB_size ),
      .PLB_type ( mb_plb_PLB_type ),
      .PLB_wrBurst ( mb_plb_PLB_wrBurst ),
      .PLB_wrDBus ( mb_plb_PLB_wrDBus ),
      .PLB_wrPrim ( mb_plb_PLB_wrPrim ),
      .PLB_SaddrAck (  ),
      .PLB_SMRdErr (  ),
      .PLB_SMWrErr (  ),
      .PLB_SMBusy (  ),
      .PLB_SrdBTerm (  ),
      .PLB_SrdComp (  ),
      .PLB_SrdDAck (  ),
      .PLB_SrdDBus (  ),
      .PLB_SrdWdAddr (  ),
      .PLB_Srearbitrate (  ),
      .PLB_Sssize (  ),
      .PLB_Swait (  ),
      .PLB_SwrBTerm (  ),
      .PLB_SwrComp (  ),
      .PLB_SwrDAck (  ),
      .Bus_Error_Det (  )
    );

  ilmb_wrapper
    ilmb (
      .LMB_Clk ( sys_clk_s ),
      .SYS_Rst ( sys_bus_reset[0] ),
      .LMB_Rst ( ilmb_OPB_Rst ),
      .M_ABus ( ilmb_M_ABus ),
      .M_ReadStrobe ( ilmb_M_ReadStrobe ),
      .M_WriteStrobe ( net_gnd0 ),
      .M_AddrStrobe ( ilmb_M_AddrStrobe ),
      .M_DBus ( net_gnd32 ),
      .M_BE ( net_gnd4 ),
      .Sl_DBus ( ilmb_Sl_DBus ),
      .Sl_Ready ( ilmb_Sl_Ready[0:0] ),
      .LMB_ABus ( ilmb_LMB_ABus ),
      .LMB_ReadStrobe ( ilmb_LMB_ReadStrobe ),
      .LMB_WriteStrobe ( ilmb_LMB_WriteStrobe ),
      .LMB_AddrStrobe ( ilmb_LMB_AddrStrobe ),
      .LMB_ReadDBus ( ilmb_LMB_ReadDBus ),
      .LMB_WriteDBus ( ilmb_LMB_WriteDBus ),
      .LMB_Ready ( ilmb_LMB_Ready ),
      .LMB_BE ( ilmb_LMB_BE )
    );

  dlmb_wrapper
    dlmb (
      .LMB_Clk ( sys_clk_s ),
      .SYS_Rst ( sys_bus_reset[0] ),
      .LMB_Rst ( dlmb_OPB_Rst ),
      .M_ABus ( dlmb_M_ABus ),
      .M_ReadStrobe ( dlmb_M_ReadStrobe ),
      .M_WriteStrobe ( dlmb_M_WriteStrobe ),
      .M_AddrStrobe ( dlmb_M_AddrStrobe ),
      .M_DBus ( dlmb_M_DBus ),
      .M_BE ( dlmb_M_BE ),
      .Sl_DBus ( dlmb_Sl_DBus ),
      .Sl_Ready ( dlmb_Sl_Ready[0:0] ),
      .LMB_ABus ( dlmb_LMB_ABus ),
      .LMB_ReadStrobe ( dlmb_LMB_ReadStrobe ),
      .LMB_WriteStrobe ( dlmb_LMB_WriteStrobe ),
      .LMB_AddrStrobe ( dlmb_LMB_AddrStrobe ),
      .LMB_ReadDBus ( dlmb_LMB_ReadDBus ),
      .LMB_WriteDBus ( dlmb_LMB_WriteDBus ),
      .LMB_Ready ( dlmb_LMB_Ready ),
      .LMB_BE ( dlmb_LMB_BE )
    );

  dlmb_cntlr_wrapper
    dlmb_cntlr (
      .LMB_Clk ( sys_clk_s ),
      .LMB_Rst ( dlmb_OPB_Rst ),
      .LMB_ABus ( dlmb_LMB_ABus ),
      .LMB_WriteDBus ( dlmb_LMB_WriteDBus ),
      .LMB_AddrStrobe ( dlmb_LMB_AddrStrobe ),
      .LMB_ReadStrobe ( dlmb_LMB_ReadStrobe ),
      .LMB_WriteStrobe ( dlmb_LMB_WriteStrobe ),
      .LMB_BE ( dlmb_LMB_BE ),
      .Sl_DBus ( dlmb_Sl_DBus ),
      .Sl_Ready ( dlmb_Sl_Ready[0] ),
      .BRAM_Rst_A ( dlmb_port_BRAM_Rst ),
      .BRAM_Clk_A ( dlmb_port_BRAM_Clk ),
      .BRAM_EN_A ( dlmb_port_BRAM_EN ),
      .BRAM_WEN_A ( dlmb_port_BRAM_WEN ),
      .BRAM_Addr_A ( dlmb_port_BRAM_Addr ),
      .BRAM_Din_A ( dlmb_port_BRAM_Din ),
      .BRAM_Dout_A ( dlmb_port_BRAM_Dout )
    );

  ilmb_cntlr_wrapper
    ilmb_cntlr (
      .LMB_Clk ( sys_clk_s ),
      .LMB_Rst ( ilmb_OPB_Rst ),
      .LMB_ABus ( ilmb_LMB_ABus ),
      .LMB_WriteDBus ( ilmb_LMB_WriteDBus ),
      .LMB_AddrStrobe ( ilmb_LMB_AddrStrobe ),
      .LMB_ReadStrobe ( ilmb_LMB_ReadStrobe ),
      .LMB_WriteStrobe ( ilmb_LMB_WriteStrobe ),
      .LMB_BE ( ilmb_LMB_BE ),
      .Sl_DBus ( ilmb_Sl_DBus ),
      .Sl_Ready ( ilmb_Sl_Ready[0] ),
      .BRAM_Rst_A ( ilmb_port_BRAM_Rst ),
      .BRAM_Clk_A ( ilmb_port_BRAM_Clk ),
      .BRAM_EN_A ( ilmb_port_BRAM_EN ),
      .BRAM_WEN_A ( ilmb_port_BRAM_WEN ),
      .BRAM_Addr_A ( ilmb_port_BRAM_Addr ),
      .BRAM_Din_A ( ilmb_port_BRAM_Din ),
      .BRAM_Dout_A ( ilmb_port_BRAM_Dout )
    );

  lmb_bram_wrapper
    lmb_bram (
      .BRAM_Rst_A ( ilmb_port_BRAM_Rst ),
      .BRAM_Clk_A ( ilmb_port_BRAM_Clk ),
      .BRAM_EN_A ( ilmb_port_BRAM_EN ),
      .BRAM_WEN_A ( ilmb_port_BRAM_WEN ),
      .BRAM_Addr_A ( ilmb_port_BRAM_Addr ),
      .BRAM_Din_A ( ilmb_port_BRAM_Din ),
      .BRAM_Dout_A ( ilmb_port_BRAM_Dout ),
      .BRAM_Rst_B ( dlmb_port_BRAM_Rst ),
      .BRAM_Clk_B ( dlmb_port_BRAM_Clk ),
      .BRAM_EN_B ( dlmb_port_BRAM_EN ),
      .BRAM_WEN_B ( dlmb_port_BRAM_WEN ),
      .BRAM_Addr_B ( dlmb_port_BRAM_Addr ),
      .BRAM_Din_B ( dlmb_port_BRAM_Din ),
      .BRAM_Dout_B ( dlmb_port_BRAM_Dout )
    );

  rs232_uart_1_wrapper
    RS232_Uart_1 (
      .SPLB_Clk ( sys_clk_s ),
      .SPLB_Rst ( mb_plb_SPLB_Rst[0] ),
      .PLB_ABus ( mb_plb_PLB_ABus ),
      .PLB_UABus ( mb_plb_PLB_UABus ),
      .PLB_PAValid ( mb_plb_PLB_PAValid ),
      .PLB_SAValid ( mb_plb_PLB_SAValid ),
      .PLB_rdPrim ( mb_plb_PLB_rdPrim[0] ),
      .PLB_wrPrim ( mb_plb_PLB_wrPrim[0] ),
      .PLB_masterID ( mb_plb_PLB_masterID[0:0] ),
      .PLB_abort ( mb_plb_PLB_abort ),
      .PLB_busLock ( mb_plb_PLB_busLock ),
      .PLB_RNW ( mb_plb_PLB_RNW ),
      .PLB_BE ( mb_plb_PLB_BE ),
      .PLB_MSize ( mb_plb_PLB_MSize ),
      .PLB_size ( mb_plb_PLB_size ),
      .PLB_type ( mb_plb_PLB_type ),
      .PLB_lockErr ( mb_plb_PLB_lockErr ),
      .PLB_wrDBus ( mb_plb_PLB_wrDBus ),
      .PLB_wrBurst ( mb_plb_PLB_wrBurst ),
      .PLB_rdBurst ( mb_plb_PLB_rdBurst ),
      .PLB_wrPendReq ( mb_plb_PLB_wrPendReq ),
      .PLB_rdPendReq ( mb_plb_PLB_rdPendReq ),
      .PLB_wrPendPri ( mb_plb_PLB_wrPendPri ),
      .PLB_rdPendPri ( mb_plb_PLB_rdPendPri ),
      .PLB_reqPri ( mb_plb_PLB_reqPri ),
      .PLB_TAttribute ( mb_plb_PLB_TAttribute ),
      .Sl_addrAck ( mb_plb_Sl_addrAck[0] ),
      .Sl_SSize ( mb_plb_Sl_SSize[0:1] ),
      .Sl_wait ( mb_plb_Sl_wait[0] ),
      .Sl_rearbitrate ( mb_plb_Sl_rearbitrate[0] ),
      .Sl_wrDAck ( mb_plb_Sl_wrDAck[0] ),
      .Sl_wrComp ( mb_plb_Sl_wrComp[0] ),
      .Sl_wrBTerm ( mb_plb_Sl_wrBTerm[0] ),
      .Sl_rdDBus ( mb_plb_Sl_rdDBus[0:31] ),
      .Sl_rdWdAddr ( mb_plb_Sl_rdWdAddr[0:3] ),
      .Sl_rdDAck ( mb_plb_Sl_rdDAck[0] ),
      .Sl_rdComp ( mb_plb_Sl_rdComp[0] ),
      .Sl_rdBTerm ( mb_plb_Sl_rdBTerm[0] ),
      .Sl_MBusy ( mb_plb_Sl_MBusy[0:1] ),
      .Sl_MWrErr ( mb_plb_Sl_MWrErr[0:1] ),
      .Sl_MRdErr ( mb_plb_Sl_MRdErr[0:1] ),
      .Sl_MIRQ ( mb_plb_Sl_MIRQ[0:1] ),
      .baudoutN (  ),
      .ctsN ( fpga_0_RS232_Uart_1_ctsN ),
      .dcdN ( net_gnd0 ),
      .ddis (  ),
      .dsrN ( net_gnd0 ),
      .dtrN (  ),
      .out1N (  ),
      .out2N (  ),
      .rclk ( net_gnd0 ),
      .riN ( net_gnd0 ),
      .rtsN ( fpga_0_RS232_Uart_1_rtsN ),
      .rxrdyN (  ),
      .sin ( fpga_0_RS232_Uart_1_sin ),
      .sout ( fpga_0_RS232_Uart_1_sout ),
      .IP2INTC_Irpt (  ),
      .txrdyN (  ),
      .xin ( net_gnd0 ),
      .xout (  ),
      .Freeze ( net_gnd0 )
    );

  xps_bram_if_cntlr_1_wrapper
    xps_bram_if_cntlr_1 (
      .SPLB_Clk ( sys_clk_s ),
      .SPLB_Rst ( mb_plb_SPLB_Rst[1] ),
      .PLB_ABus ( mb_plb_PLB_ABus ),
      .PLB_UABus ( mb_plb_PLB_UABus ),
      .PLB_PAValid ( mb_plb_PLB_PAValid ),
      .PLB_SAValid ( mb_plb_PLB_SAValid ),
      .PLB_rdPrim ( mb_plb_PLB_rdPrim[1] ),
      .PLB_wrPrim ( mb_plb_PLB_wrPrim[1] ),
      .PLB_masterID ( mb_plb_PLB_masterID[0:0] ),
      .PLB_abort ( mb_plb_PLB_abort ),
      .PLB_busLock ( mb_plb_PLB_busLock ),
      .PLB_RNW ( mb_plb_PLB_RNW ),
      .PLB_BE ( mb_plb_PLB_BE ),
      .PLB_MSize ( mb_plb_PLB_MSize ),
      .PLB_size ( mb_plb_PLB_size ),
      .PLB_type ( mb_plb_PLB_type ),
      .PLB_lockErr ( mb_plb_PLB_lockErr ),
      .PLB_wrDBus ( mb_plb_PLB_wrDBus ),
      .PLB_wrBurst ( mb_plb_PLB_wrBurst ),
      .PLB_rdBurst ( mb_plb_PLB_rdBurst ),
      .PLB_wrPendReq ( mb_plb_PLB_wrPendReq ),
      .PLB_rdPendReq ( mb_plb_PLB_rdPendReq ),
      .PLB_wrPendPri ( mb_plb_PLB_wrPendPri ),
      .PLB_rdPendPri ( mb_plb_PLB_rdPendPri ),
      .PLB_reqPri ( mb_plb_PLB_reqPri ),
      .PLB_TAttribute ( mb_plb_PLB_TAttribute ),
      .Sl_addrAck ( mb_plb_Sl_addrAck[1] ),
      .Sl_SSize ( mb_plb_Sl_SSize[2:3] ),
      .Sl_wait ( mb_plb_Sl_wait[1] ),
      .Sl_rearbitrate ( mb_plb_Sl_rearbitrate[1] ),
      .Sl_wrDAck ( mb_plb_Sl_wrDAck[1] ),
      .Sl_wrComp ( mb_plb_Sl_wrComp[1] ),
      .Sl_wrBTerm ( mb_plb_Sl_wrBTerm[1] ),
      .Sl_rdDBus ( mb_plb_Sl_rdDBus[32:63] ),
      .Sl_rdWdAddr ( mb_plb_Sl_rdWdAddr[4:7] ),
      .Sl_rdDAck ( mb_plb_Sl_rdDAck[1] ),
      .Sl_rdComp ( mb_plb_Sl_rdComp[1] ),
      .Sl_rdBTerm ( mb_plb_Sl_rdBTerm[1] ),
      .Sl_MBusy ( mb_plb_Sl_MBusy[2:3] ),
      .Sl_MWrErr ( mb_plb_Sl_MWrErr[2:3] ),
      .Sl_MRdErr ( mb_plb_Sl_MRdErr[2:3] ),
      .Sl_MIRQ ( mb_plb_Sl_MIRQ[2:3] ),
      .BRAM_Rst ( xps_bram_if_cntlr_1_port_BRAM_Rst ),
      .BRAM_Clk ( xps_bram_if_cntlr_1_port_BRAM_Clk ),
      .BRAM_EN ( xps_bram_if_cntlr_1_port_BRAM_EN ),
      .BRAM_WEN ( xps_bram_if_cntlr_1_port_BRAM_WEN ),
      .BRAM_Addr ( xps_bram_if_cntlr_1_port_BRAM_Addr ),
      .BRAM_Din ( xps_bram_if_cntlr_1_port_BRAM_Din ),
      .BRAM_Dout ( xps_bram_if_cntlr_1_port_BRAM_Dout )
    );

  xps_bram_if_cntlr_1_bram_wrapper
    xps_bram_if_cntlr_1_bram (
      .BRAM_Rst_A ( xps_bram_if_cntlr_1_port_BRAM_Rst ),
      .BRAM_Clk_A ( xps_bram_if_cntlr_1_port_BRAM_Clk ),
      .BRAM_EN_A ( xps_bram_if_cntlr_1_port_BRAM_EN ),
      .BRAM_WEN_A ( xps_bram_if_cntlr_1_port_BRAM_WEN ),
      .BRAM_Addr_A ( xps_bram_if_cntlr_1_port_BRAM_Addr ),
      .BRAM_Din_A ( xps_bram_if_cntlr_1_port_BRAM_Din ),
      .BRAM_Dout_A ( xps_bram_if_cntlr_1_port_BRAM_Dout ),
      .BRAM_Rst_B ( bramfeeder_0_PORTA_BRAM_Rst ),
      .BRAM_Clk_B ( bramfeeder_0_PORTA_BRAM_Clk ),
      .BRAM_EN_B ( bramfeeder_0_PORTA_BRAM_EN ),
      .BRAM_WEN_B ( bramfeeder_0_PORTA_BRAM_WEN ),
      .BRAM_Addr_B ( bramfeeder_0_PORTA_BRAM_Addr ),
      .BRAM_Din_B ( bramfeeder_0_PORTA_BRAM_Din[31:0] ),
      .BRAM_Dout_B ( bramfeeder_0_PORTA_BRAM_Dout )
    );

  clock_generator_0_wrapper
    clock_generator_0 (
      .CLKIN ( dcm_clk_s ),
      .CLKFBIN ( net_gnd0 ),
      .CLKOUT0 ( sys_clk_s ),
      .CLKOUT1 (  ),
      .CLKOUT2 (  ),
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

  proc_sys_reset_0_wrapper
    proc_sys_reset_0 (
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
      .MB_Reset ( mb_reset ),
      .Bus_Struct_Reset ( sys_bus_reset[0:0] ),
      .Peripheral_Reset ( sys_periph_reset[0:0] )
    );

  bramfeeder_0_wrapper
    bramfeeder_0 (
      .CLK ( sys_clk_s ),
      .RST ( sys_periph_reset[0] ),
      .ppcMessageInput_put ( bramfeeder_0_ppcMessageInput_put ),
      .EN_ppcMessageInput_put ( bramfeeder_0_EN_ppcMessageInput_put ),
      .RDY_ppcMessageInput_put ( bramfeeder_0_RDY_ppcMessageInput_put ),
      .EN_ppcMessageOutput_get ( bramfeeder_0_EN_ppcMessageOutput_get ),
      .ppcMessageOutput_get ( bramfeeder_0_ppcMessageOutput_get ),
      .RDY_ppcMessageOutput_get ( bramfeeder_0_RDY_ppcMessageOutput_get ),
      .bramInitiatorWires_bramCLK ( bramfeeder_0_PORTA_BRAM_Clk ),
      .bramInitiatorWires_bramRST ( bramfeeder_0_PORTA_BRAM_Rst ),
      .bramInitiatorWires_bramAddr ( bramfeeder_0_PORTA_BRAM_Addr[0:31] ),
      .bramInitiatorWires_bramDout ( bramfeeder_0_PORTA_BRAM_Dout[0:31] ),
      .bramInitiatorWires_bramWEN ( bramfeeder_0_PORTA_BRAM_WEN[0:3] ),
      .bramInitiatorWires_bramEN ( bramfeeder_0_PORTA_BRAM_EN ),
      .bramInitiatorWires_bramDin ( bramfeeder_0_PORTA_BRAM_Din )
    );

endmodule

// synthesis attribute BOX_TYPE of microblaze_0_wrapper is black_box;
// synthesis attribute BOX_TYPE of mb_plb_wrapper is black_box;
// synthesis attribute BOX_TYPE of ilmb_wrapper is black_box;
// synthesis attribute BOX_TYPE of dlmb_wrapper is black_box;
// synthesis attribute BOX_TYPE of dlmb_cntlr_wrapper is black_box;
// synthesis attribute BOX_TYPE of ilmb_cntlr_wrapper is black_box;
// synthesis attribute BOX_TYPE of lmb_bram_wrapper is black_box;
// synthesis attribute BOX_TYPE of rs232_uart_1_wrapper is black_box;
// synthesis attribute BOX_TYPE of xps_bram_if_cntlr_1_wrapper is black_box;
// synthesis attribute BOX_TYPE of xps_bram_if_cntlr_1_bram_wrapper is black_box;
// synthesis attribute BOX_TYPE of clock_generator_0_wrapper is black_box;
// synthesis attribute BOX_TYPE of proc_sys_reset_0_wrapper is black_box;
// synthesis attribute BOX_TYPE of bramfeeder_0_wrapper is black_box;

module microblaze_0_wrapper
  (
    CLK,
    RESET,
    MB_RESET,
    INTERRUPT,
    EXT_BRK,
    EXT_NM_BRK,
    DBG_STOP,
    MB_Halted,
    INSTR,
    I_ADDRTAG,
    IREADY,
    IWAIT,
    INSTR_ADDR,
    IFETCH,
    I_AS,
    IPLB_M_ABort,
    IPLB_M_ABus,
    IPLB_M_UABus,
    IPLB_M_BE,
    IPLB_M_busLock,
    IPLB_M_lockErr,
    IPLB_M_MSize,
    IPLB_M_priority,
    IPLB_M_rdBurst,
    IPLB_M_request,
    IPLB_M_RNW,
    IPLB_M_size,
    IPLB_M_TAttribute,
    IPLB_M_type,
    IPLB_M_wrBurst,
    IPLB_M_wrDBus,
    IPLB_MBusy,
    IPLB_MRdErr,
    IPLB_MWrErr,
    IPLB_MIRQ,
    IPLB_MWrBTerm,
    IPLB_MWrDAck,
    IPLB_MAddrAck,
    IPLB_MRdBTerm,
    IPLB_MRdDAck,
    IPLB_MRdDBus,
    IPLB_MRdWdAddr,
    IPLB_MRearbitrate,
    IPLB_MSSize,
    IPLB_MTimeout,
    DATA_READ,
    DREADY,
    DWAIT,
    DATA_WRITE,
    DATA_ADDR,
    D_ADDRTAG,
    D_AS,
    READ_STROBE,
    WRITE_STROBE,
    BYTE_ENABLE,
    DM_ABUS,
    DM_BE,
    DM_BUSLOCK,
    DM_DBUS,
    DM_REQUEST,
    DM_RNW,
    DM_SELECT,
    DM_SEQADDR,
    DOPB_DBUS,
    DOPB_ERRACK,
    DOPB_MGRANT,
    DOPB_RETRY,
    DOPB_TIMEOUT,
    DOPB_XFERACK,
    DPLB_M_ABort,
    DPLB_M_ABus,
    DPLB_M_UABus,
    DPLB_M_BE,
    DPLB_M_busLock,
    DPLB_M_lockErr,
    DPLB_M_MSize,
    DPLB_M_priority,
    DPLB_M_rdBurst,
    DPLB_M_request,
    DPLB_M_RNW,
    DPLB_M_size,
    DPLB_M_TAttribute,
    DPLB_M_type,
    DPLB_M_wrBurst,
    DPLB_M_wrDBus,
    DPLB_MBusy,
    DPLB_MRdErr,
    DPLB_MWrErr,
    DPLB_MIRQ,
    DPLB_MWrBTerm,
    DPLB_MWrDAck,
    DPLB_MAddrAck,
    DPLB_MRdBTerm,
    DPLB_MRdDAck,
    DPLB_MRdDBus,
    DPLB_MRdWdAddr,
    DPLB_MRearbitrate,
    DPLB_MSSize,
    DPLB_MTimeout,
    IM_ABUS,
    IM_BE,
    IM_BUSLOCK,
    IM_DBUS,
    IM_REQUEST,
    IM_RNW,
    IM_SELECT,
    IM_SEQADDR,
    IOPB_DBUS,
    IOPB_ERRACK,
    IOPB_MGRANT,
    IOPB_RETRY,
    IOPB_TIMEOUT,
    IOPB_XFERACK,
    DBG_CLK,
    DBG_TDI,
    DBG_TDO,
    DBG_REG_EN,
    DBG_SHIFT,
    DBG_CAPTURE,
    DBG_UPDATE,
    DEBUG_RST,
    Trace_Instruction,
    Trace_Valid_Instr,
    Trace_PC,
    Trace_Reg_Write,
    Trace_Reg_Addr,
    Trace_MSR_Reg,
    Trace_PID_Reg,
    Trace_New_Reg_Value,
    Trace_Exception_Taken,
    Trace_Exception_Kind,
    Trace_Jump_Taken,
    Trace_Delay_Slot,
    Trace_Data_Address,
    Trace_Data_Access,
    Trace_Data_Read,
    Trace_Data_Write,
    Trace_Data_Write_Value,
    Trace_Data_Byte_Enable,
    Trace_DCache_Req,
    Trace_DCache_Hit,
    Trace_ICache_Req,
    Trace_ICache_Hit,
    Trace_OF_PipeRun,
    Trace_EX_PipeRun,
    Trace_MEM_PipeRun,
    Trace_MB_Halted,
    FSL0_S_CLK,
    FSL0_S_READ,
    FSL0_S_DATA,
    FSL0_S_CONTROL,
    FSL0_S_EXISTS,
    FSL0_M_CLK,
    FSL0_M_WRITE,
    FSL0_M_DATA,
    FSL0_M_CONTROL,
    FSL0_M_FULL,
    FSL1_S_CLK,
    FSL1_S_READ,
    FSL1_S_DATA,
    FSL1_S_CONTROL,
    FSL1_S_EXISTS,
    FSL1_M_CLK,
    FSL1_M_WRITE,
    FSL1_M_DATA,
    FSL1_M_CONTROL,
    FSL1_M_FULL,
    FSL2_S_CLK,
    FSL2_S_READ,
    FSL2_S_DATA,
    FSL2_S_CONTROL,
    FSL2_S_EXISTS,
    FSL2_M_CLK,
    FSL2_M_WRITE,
    FSL2_M_DATA,
    FSL2_M_CONTROL,
    FSL2_M_FULL,
    FSL3_S_CLK,
    FSL3_S_READ,
    FSL3_S_DATA,
    FSL3_S_CONTROL,
    FSL3_S_EXISTS,
    FSL3_M_CLK,
    FSL3_M_WRITE,
    FSL3_M_DATA,
    FSL3_M_CONTROL,
    FSL3_M_FULL,
    FSL4_S_CLK,
    FSL4_S_READ,
    FSL4_S_DATA,
    FSL4_S_CONTROL,
    FSL4_S_EXISTS,
    FSL4_M_CLK,
    FSL4_M_WRITE,
    FSL4_M_DATA,
    FSL4_M_CONTROL,
    FSL4_M_FULL,
    FSL5_S_CLK,
    FSL5_S_READ,
    FSL5_S_DATA,
    FSL5_S_CONTROL,
    FSL5_S_EXISTS,
    FSL5_M_CLK,
    FSL5_M_WRITE,
    FSL5_M_DATA,
    FSL5_M_CONTROL,
    FSL5_M_FULL,
    FSL6_S_CLK,
    FSL6_S_READ,
    FSL6_S_DATA,
    FSL6_S_CONTROL,
    FSL6_S_EXISTS,
    FSL6_M_CLK,
    FSL6_M_WRITE,
    FSL6_M_DATA,
    FSL6_M_CONTROL,
    FSL6_M_FULL,
    FSL7_S_CLK,
    FSL7_S_READ,
    FSL7_S_DATA,
    FSL7_S_CONTROL,
    FSL7_S_EXISTS,
    FSL7_M_CLK,
    FSL7_M_WRITE,
    FSL7_M_DATA,
    FSL7_M_CONTROL,
    FSL7_M_FULL,
    FSL8_S_CLK,
    FSL8_S_READ,
    FSL8_S_DATA,
    FSL8_S_CONTROL,
    FSL8_S_EXISTS,
    FSL8_M_CLK,
    FSL8_M_WRITE,
    FSL8_M_DATA,
    FSL8_M_CONTROL,
    FSL8_M_FULL,
    FSL9_S_CLK,
    FSL9_S_READ,
    FSL9_S_DATA,
    FSL9_S_CONTROL,
    FSL9_S_EXISTS,
    FSL9_M_CLK,
    FSL9_M_WRITE,
    FSL9_M_DATA,
    FSL9_M_CONTROL,
    FSL9_M_FULL,
    FSL10_S_CLK,
    FSL10_S_READ,
    FSL10_S_DATA,
    FSL10_S_CONTROL,
    FSL10_S_EXISTS,
    FSL10_M_CLK,
    FSL10_M_WRITE,
    FSL10_M_DATA,
    FSL10_M_CONTROL,
    FSL10_M_FULL,
    FSL11_S_CLK,
    FSL11_S_READ,
    FSL11_S_DATA,
    FSL11_S_CONTROL,
    FSL11_S_EXISTS,
    FSL11_M_CLK,
    FSL11_M_WRITE,
    FSL11_M_DATA,
    FSL11_M_CONTROL,
    FSL11_M_FULL,
    FSL12_S_CLK,
    FSL12_S_READ,
    FSL12_S_DATA,
    FSL12_S_CONTROL,
    FSL12_S_EXISTS,
    FSL12_M_CLK,
    FSL12_M_WRITE,
    FSL12_M_DATA,
    FSL12_M_CONTROL,
    FSL12_M_FULL,
    FSL13_S_CLK,
    FSL13_S_READ,
    FSL13_S_DATA,
    FSL13_S_CONTROL,
    FSL13_S_EXISTS,
    FSL13_M_CLK,
    FSL13_M_WRITE,
    FSL13_M_DATA,
    FSL13_M_CONTROL,
    FSL13_M_FULL,
    FSL14_S_CLK,
    FSL14_S_READ,
    FSL14_S_DATA,
    FSL14_S_CONTROL,
    FSL14_S_EXISTS,
    FSL14_M_CLK,
    FSL14_M_WRITE,
    FSL14_M_DATA,
    FSL14_M_CONTROL,
    FSL14_M_FULL,
    FSL15_S_CLK,
    FSL15_S_READ,
    FSL15_S_DATA,
    FSL15_S_CONTROL,
    FSL15_S_EXISTS,
    FSL15_M_CLK,
    FSL15_M_WRITE,
    FSL15_M_DATA,
    FSL15_M_CONTROL,
    FSL15_M_FULL,
    ICACHE_FSL_IN_CLK,
    ICACHE_FSL_IN_READ,
    ICACHE_FSL_IN_DATA,
    ICACHE_FSL_IN_CONTROL,
    ICACHE_FSL_IN_EXISTS,
    ICACHE_FSL_OUT_CLK,
    ICACHE_FSL_OUT_WRITE,
    ICACHE_FSL_OUT_DATA,
    ICACHE_FSL_OUT_CONTROL,
    ICACHE_FSL_OUT_FULL,
    DCACHE_FSL_IN_CLK,
    DCACHE_FSL_IN_READ,
    DCACHE_FSL_IN_DATA,
    DCACHE_FSL_IN_CONTROL,
    DCACHE_FSL_IN_EXISTS,
    DCACHE_FSL_OUT_CLK,
    DCACHE_FSL_OUT_WRITE,
    DCACHE_FSL_OUT_DATA,
    DCACHE_FSL_OUT_CONTROL,
    DCACHE_FSL_OUT_FULL
  );
  input CLK;
  input RESET;
  input MB_RESET;
  input INTERRUPT;
  input EXT_BRK;
  input EXT_NM_BRK;
  input DBG_STOP;
  output MB_Halted;
  input [0:31] INSTR;
  output [0:3] I_ADDRTAG;
  input IREADY;
  input IWAIT;
  output [0:31] INSTR_ADDR;
  output IFETCH;
  output I_AS;
  output IPLB_M_ABort;
  output [0:31] IPLB_M_ABus;
  output [0:31] IPLB_M_UABus;
  output [0:3] IPLB_M_BE;
  output IPLB_M_busLock;
  output IPLB_M_lockErr;
  output [0:1] IPLB_M_MSize;
  output [0:1] IPLB_M_priority;
  output IPLB_M_rdBurst;
  output IPLB_M_request;
  output IPLB_M_RNW;
  output [0:3] IPLB_M_size;
  output [0:15] IPLB_M_TAttribute;
  output [0:2] IPLB_M_type;
  output IPLB_M_wrBurst;
  output [0:31] IPLB_M_wrDBus;
  input IPLB_MBusy;
  input IPLB_MRdErr;
  input IPLB_MWrErr;
  input IPLB_MIRQ;
  input IPLB_MWrBTerm;
  input IPLB_MWrDAck;
  input IPLB_MAddrAck;
  input IPLB_MRdBTerm;
  input IPLB_MRdDAck;
  input [0:31] IPLB_MRdDBus;
  input [0:3] IPLB_MRdWdAddr;
  input IPLB_MRearbitrate;
  input [0:1] IPLB_MSSize;
  input IPLB_MTimeout;
  input [0:31] DATA_READ;
  input DREADY;
  input DWAIT;
  output [0:31] DATA_WRITE;
  output [0:31] DATA_ADDR;
  output [0:3] D_ADDRTAG;
  output D_AS;
  output READ_STROBE;
  output WRITE_STROBE;
  output [0:3] BYTE_ENABLE;
  output [0:31] DM_ABUS;
  output [0:3] DM_BE;
  output DM_BUSLOCK;
  output [0:31] DM_DBUS;
  output DM_REQUEST;
  output DM_RNW;
  output DM_SELECT;
  output DM_SEQADDR;
  input [0:31] DOPB_DBUS;
  input DOPB_ERRACK;
  input DOPB_MGRANT;
  input DOPB_RETRY;
  input DOPB_TIMEOUT;
  input DOPB_XFERACK;
  output DPLB_M_ABort;
  output [0:31] DPLB_M_ABus;
  output [0:31] DPLB_M_UABus;
  output [0:3] DPLB_M_BE;
  output DPLB_M_busLock;
  output DPLB_M_lockErr;
  output [0:1] DPLB_M_MSize;
  output [0:1] DPLB_M_priority;
  output DPLB_M_rdBurst;
  output DPLB_M_request;
  output DPLB_M_RNW;
  output [0:3] DPLB_M_size;
  output [0:15] DPLB_M_TAttribute;
  output [0:2] DPLB_M_type;
  output DPLB_M_wrBurst;
  output [0:31] DPLB_M_wrDBus;
  input DPLB_MBusy;
  input DPLB_MRdErr;
  input DPLB_MWrErr;
  input DPLB_MIRQ;
  input DPLB_MWrBTerm;
  input DPLB_MWrDAck;
  input DPLB_MAddrAck;
  input DPLB_MRdBTerm;
  input DPLB_MRdDAck;
  input [0:31] DPLB_MRdDBus;
  input [0:3] DPLB_MRdWdAddr;
  input DPLB_MRearbitrate;
  input [0:1] DPLB_MSSize;
  input DPLB_MTimeout;
  output [0:31] IM_ABUS;
  output [0:3] IM_BE;
  output IM_BUSLOCK;
  output [0:31] IM_DBUS;
  output IM_REQUEST;
  output IM_RNW;
  output IM_SELECT;
  output IM_SEQADDR;
  input [0:31] IOPB_DBUS;
  input IOPB_ERRACK;
  input IOPB_MGRANT;
  input IOPB_RETRY;
  input IOPB_TIMEOUT;
  input IOPB_XFERACK;
  input DBG_CLK;
  input DBG_TDI;
  output DBG_TDO;
  input [0:4] DBG_REG_EN;
  input DBG_SHIFT;
  input DBG_CAPTURE;
  input DBG_UPDATE;
  input DEBUG_RST;
  output [0:31] Trace_Instruction;
  output Trace_Valid_Instr;
  output [0:31] Trace_PC;
  output Trace_Reg_Write;
  output [0:4] Trace_Reg_Addr;
  output [0:14] Trace_MSR_Reg;
  output [0:7] Trace_PID_Reg;
  output [0:31] Trace_New_Reg_Value;
  output Trace_Exception_Taken;
  output [0:4] Trace_Exception_Kind;
  output Trace_Jump_Taken;
  output Trace_Delay_Slot;
  output [0:31] Trace_Data_Address;
  output Trace_Data_Access;
  output Trace_Data_Read;
  output Trace_Data_Write;
  output [0:31] Trace_Data_Write_Value;
  output [0:3] Trace_Data_Byte_Enable;
  output Trace_DCache_Req;
  output Trace_DCache_Hit;
  output Trace_ICache_Req;
  output Trace_ICache_Hit;
  output Trace_OF_PipeRun;
  output Trace_EX_PipeRun;
  output Trace_MEM_PipeRun;
  output Trace_MB_Halted;
  output FSL0_S_CLK;
  output FSL0_S_READ;
  input [0:31] FSL0_S_DATA;
  input FSL0_S_CONTROL;
  input FSL0_S_EXISTS;
  output FSL0_M_CLK;
  output FSL0_M_WRITE;
  output [0:31] FSL0_M_DATA;
  output FSL0_M_CONTROL;
  input FSL0_M_FULL;
  output FSL1_S_CLK;
  output FSL1_S_READ;
  input [0:31] FSL1_S_DATA;
  input FSL1_S_CONTROL;
  input FSL1_S_EXISTS;
  output FSL1_M_CLK;
  output FSL1_M_WRITE;
  output [0:31] FSL1_M_DATA;
  output FSL1_M_CONTROL;
  input FSL1_M_FULL;
  output FSL2_S_CLK;
  output FSL2_S_READ;
  input [0:31] FSL2_S_DATA;
  input FSL2_S_CONTROL;
  input FSL2_S_EXISTS;
  output FSL2_M_CLK;
  output FSL2_M_WRITE;
  output [0:31] FSL2_M_DATA;
  output FSL2_M_CONTROL;
  input FSL2_M_FULL;
  output FSL3_S_CLK;
  output FSL3_S_READ;
  input [0:31] FSL3_S_DATA;
  input FSL3_S_CONTROL;
  input FSL3_S_EXISTS;
  output FSL3_M_CLK;
  output FSL3_M_WRITE;
  output [0:31] FSL3_M_DATA;
  output FSL3_M_CONTROL;
  input FSL3_M_FULL;
  output FSL4_S_CLK;
  output FSL4_S_READ;
  input [0:31] FSL4_S_DATA;
  input FSL4_S_CONTROL;
  input FSL4_S_EXISTS;
  output FSL4_M_CLK;
  output FSL4_M_WRITE;
  output [0:31] FSL4_M_DATA;
  output FSL4_M_CONTROL;
  input FSL4_M_FULL;
  output FSL5_S_CLK;
  output FSL5_S_READ;
  input [0:31] FSL5_S_DATA;
  input FSL5_S_CONTROL;
  input FSL5_S_EXISTS;
  output FSL5_M_CLK;
  output FSL5_M_WRITE;
  output [0:31] FSL5_M_DATA;
  output FSL5_M_CONTROL;
  input FSL5_M_FULL;
  output FSL6_S_CLK;
  output FSL6_S_READ;
  input [0:31] FSL6_S_DATA;
  input FSL6_S_CONTROL;
  input FSL6_S_EXISTS;
  output FSL6_M_CLK;
  output FSL6_M_WRITE;
  output [0:31] FSL6_M_DATA;
  output FSL6_M_CONTROL;
  input FSL6_M_FULL;
  output FSL7_S_CLK;
  output FSL7_S_READ;
  input [0:31] FSL7_S_DATA;
  input FSL7_S_CONTROL;
  input FSL7_S_EXISTS;
  output FSL7_M_CLK;
  output FSL7_M_WRITE;
  output [0:31] FSL7_M_DATA;
  output FSL7_M_CONTROL;
  input FSL7_M_FULL;
  output FSL8_S_CLK;
  output FSL8_S_READ;
  input [0:31] FSL8_S_DATA;
  input FSL8_S_CONTROL;
  input FSL8_S_EXISTS;
  output FSL8_M_CLK;
  output FSL8_M_WRITE;
  output [0:31] FSL8_M_DATA;
  output FSL8_M_CONTROL;
  input FSL8_M_FULL;
  output FSL9_S_CLK;
  output FSL9_S_READ;
  input [0:31] FSL9_S_DATA;
  input FSL9_S_CONTROL;
  input FSL9_S_EXISTS;
  output FSL9_M_CLK;
  output FSL9_M_WRITE;
  output [0:31] FSL9_M_DATA;
  output FSL9_M_CONTROL;
  input FSL9_M_FULL;
  output FSL10_S_CLK;
  output FSL10_S_READ;
  input [0:31] FSL10_S_DATA;
  input FSL10_S_CONTROL;
  input FSL10_S_EXISTS;
  output FSL10_M_CLK;
  output FSL10_M_WRITE;
  output [0:31] FSL10_M_DATA;
  output FSL10_M_CONTROL;
  input FSL10_M_FULL;
  output FSL11_S_CLK;
  output FSL11_S_READ;
  input [0:31] FSL11_S_DATA;
  input FSL11_S_CONTROL;
  input FSL11_S_EXISTS;
  output FSL11_M_CLK;
  output FSL11_M_WRITE;
  output [0:31] FSL11_M_DATA;
  output FSL11_M_CONTROL;
  input FSL11_M_FULL;
  output FSL12_S_CLK;
  output FSL12_S_READ;
  input [0:31] FSL12_S_DATA;
  input FSL12_S_CONTROL;
  input FSL12_S_EXISTS;
  output FSL12_M_CLK;
  output FSL12_M_WRITE;
  output [0:31] FSL12_M_DATA;
  output FSL12_M_CONTROL;
  input FSL12_M_FULL;
  output FSL13_S_CLK;
  output FSL13_S_READ;
  input [0:31] FSL13_S_DATA;
  input FSL13_S_CONTROL;
  input FSL13_S_EXISTS;
  output FSL13_M_CLK;
  output FSL13_M_WRITE;
  output [0:31] FSL13_M_DATA;
  output FSL13_M_CONTROL;
  input FSL13_M_FULL;
  output FSL14_S_CLK;
  output FSL14_S_READ;
  input [0:31] FSL14_S_DATA;
  input FSL14_S_CONTROL;
  input FSL14_S_EXISTS;
  output FSL14_M_CLK;
  output FSL14_M_WRITE;
  output [0:31] FSL14_M_DATA;
  output FSL14_M_CONTROL;
  input FSL14_M_FULL;
  output FSL15_S_CLK;
  output FSL15_S_READ;
  input [0:31] FSL15_S_DATA;
  input FSL15_S_CONTROL;
  input FSL15_S_EXISTS;
  output FSL15_M_CLK;
  output FSL15_M_WRITE;
  output [0:31] FSL15_M_DATA;
  output FSL15_M_CONTROL;
  input FSL15_M_FULL;
  output ICACHE_FSL_IN_CLK;
  output ICACHE_FSL_IN_READ;
  input [0:31] ICACHE_FSL_IN_DATA;
  input ICACHE_FSL_IN_CONTROL;
  input ICACHE_FSL_IN_EXISTS;
  output ICACHE_FSL_OUT_CLK;
  output ICACHE_FSL_OUT_WRITE;
  output [0:31] ICACHE_FSL_OUT_DATA;
  output ICACHE_FSL_OUT_CONTROL;
  input ICACHE_FSL_OUT_FULL;
  output DCACHE_FSL_IN_CLK;
  output DCACHE_FSL_IN_READ;
  input [0:31] DCACHE_FSL_IN_DATA;
  input DCACHE_FSL_IN_CONTROL;
  input DCACHE_FSL_IN_EXISTS;
  output DCACHE_FSL_OUT_CLK;
  output DCACHE_FSL_OUT_WRITE;
  output [0:31] DCACHE_FSL_OUT_DATA;
  output DCACHE_FSL_OUT_CONTROL;
  input DCACHE_FSL_OUT_FULL;
endmodule

module mb_plb_wrapper
  (
    PLB_Clk,
    SYS_Rst,
    PLB_Rst,
    SPLB_Rst,
    MPLB_Rst,
    PLB_dcrAck,
    PLB_dcrDBus,
    DCR_ABus,
    DCR_DBus,
    DCR_Read,
    DCR_Write,
    M_ABus,
    M_UABus,
    M_BE,
    M_RNW,
    M_abort,
    M_busLock,
    M_TAttribute,
    M_lockErr,
    M_MSize,
    M_priority,
    M_rdBurst,
    M_request,
    M_size,
    M_type,
    M_wrBurst,
    M_wrDBus,
    Sl_addrAck,
    Sl_MRdErr,
    Sl_MWrErr,
    Sl_MBusy,
    Sl_rdBTerm,
    Sl_rdComp,
    Sl_rdDAck,
    Sl_rdDBus,
    Sl_rdWdAddr,
    Sl_rearbitrate,
    Sl_SSize,
    Sl_wait,
    Sl_wrBTerm,
    Sl_wrComp,
    Sl_wrDAck,
    Sl_MIRQ,
    PLB_MIRQ,
    PLB_ABus,
    PLB_UABus,
    PLB_BE,
    PLB_MAddrAck,
    PLB_MTimeout,
    PLB_MBusy,
    PLB_MRdErr,
    PLB_MWrErr,
    PLB_MRdBTerm,
    PLB_MRdDAck,
    PLB_MRdDBus,
    PLB_MRdWdAddr,
    PLB_MRearbitrate,
    PLB_MWrBTerm,
    PLB_MWrDAck,
    PLB_MSSize,
    PLB_PAValid,
    PLB_RNW,
    PLB_SAValid,
    PLB_abort,
    PLB_busLock,
    PLB_TAttribute,
    PLB_lockErr,
    PLB_masterID,
    PLB_MSize,
    PLB_rdPendPri,
    PLB_wrPendPri,
    PLB_rdPendReq,
    PLB_wrPendReq,
    PLB_rdBurst,
    PLB_rdPrim,
    PLB_reqPri,
    PLB_size,
    PLB_type,
    PLB_wrBurst,
    PLB_wrDBus,
    PLB_wrPrim,
    PLB_SaddrAck,
    PLB_SMRdErr,
    PLB_SMWrErr,
    PLB_SMBusy,
    PLB_SrdBTerm,
    PLB_SrdComp,
    PLB_SrdDAck,
    PLB_SrdDBus,
    PLB_SrdWdAddr,
    PLB_Srearbitrate,
    PLB_Sssize,
    PLB_Swait,
    PLB_SwrBTerm,
    PLB_SwrComp,
    PLB_SwrDAck,
    Bus_Error_Det
  );
  input PLB_Clk;
  input SYS_Rst;
  output PLB_Rst;
  output [0:1] SPLB_Rst;
  output [0:1] MPLB_Rst;
  output PLB_dcrAck;
  output [0:31] PLB_dcrDBus;
  input [0:9] DCR_ABus;
  input [0:31] DCR_DBus;
  input DCR_Read;
  input DCR_Write;
  input [0:63] M_ABus;
  input [0:63] M_UABus;
  input [0:7] M_BE;
  input [0:1] M_RNW;
  input [0:1] M_abort;
  input [0:1] M_busLock;
  input [0:31] M_TAttribute;
  input [0:1] M_lockErr;
  input [0:3] M_MSize;
  input [0:3] M_priority;
  input [0:1] M_rdBurst;
  input [0:1] M_request;
  input [0:7] M_size;
  input [0:5] M_type;
  input [0:1] M_wrBurst;
  input [0:63] M_wrDBus;
  input [0:1] Sl_addrAck;
  input [0:3] Sl_MRdErr;
  input [0:3] Sl_MWrErr;
  input [0:3] Sl_MBusy;
  input [0:1] Sl_rdBTerm;
  input [0:1] Sl_rdComp;
  input [0:1] Sl_rdDAck;
  input [0:63] Sl_rdDBus;
  input [0:7] Sl_rdWdAddr;
  input [0:1] Sl_rearbitrate;
  input [0:3] Sl_SSize;
  input [0:1] Sl_wait;
  input [0:1] Sl_wrBTerm;
  input [0:1] Sl_wrComp;
  input [0:1] Sl_wrDAck;
  input [0:3] Sl_MIRQ;
  output [0:1] PLB_MIRQ;
  output [0:31] PLB_ABus;
  output [0:31] PLB_UABus;
  output [0:3] PLB_BE;
  output [0:1] PLB_MAddrAck;
  output [0:1] PLB_MTimeout;
  output [0:1] PLB_MBusy;
  output [0:1] PLB_MRdErr;
  output [0:1] PLB_MWrErr;
  output [0:1] PLB_MRdBTerm;
  output [0:1] PLB_MRdDAck;
  output [0:63] PLB_MRdDBus;
  output [0:7] PLB_MRdWdAddr;
  output [0:1] PLB_MRearbitrate;
  output [0:1] PLB_MWrBTerm;
  output [0:1] PLB_MWrDAck;
  output [0:3] PLB_MSSize;
  output PLB_PAValid;
  output PLB_RNW;
  output PLB_SAValid;
  output PLB_abort;
  output PLB_busLock;
  output [0:15] PLB_TAttribute;
  output PLB_lockErr;
  output [0:0] PLB_masterID;
  output [0:1] PLB_MSize;
  output [0:1] PLB_rdPendPri;
  output [0:1] PLB_wrPendPri;
  output PLB_rdPendReq;
  output PLB_wrPendReq;
  output PLB_rdBurst;
  output [0:1] PLB_rdPrim;
  output [0:1] PLB_reqPri;
  output [0:3] PLB_size;
  output [0:2] PLB_type;
  output PLB_wrBurst;
  output [0:31] PLB_wrDBus;
  output [0:1] PLB_wrPrim;
  output PLB_SaddrAck;
  output [0:1] PLB_SMRdErr;
  output [0:1] PLB_SMWrErr;
  output [0:1] PLB_SMBusy;
  output PLB_SrdBTerm;
  output PLB_SrdComp;
  output PLB_SrdDAck;
  output [0:31] PLB_SrdDBus;
  output [0:3] PLB_SrdWdAddr;
  output PLB_Srearbitrate;
  output [0:1] PLB_Sssize;
  output PLB_Swait;
  output PLB_SwrBTerm;
  output PLB_SwrComp;
  output PLB_SwrDAck;
  output Bus_Error_Det;
endmodule

module ilmb_wrapper
  (
    LMB_Clk,
    SYS_Rst,
    LMB_Rst,
    M_ABus,
    M_ReadStrobe,
    M_WriteStrobe,
    M_AddrStrobe,
    M_DBus,
    M_BE,
    Sl_DBus,
    Sl_Ready,
    LMB_ABus,
    LMB_ReadStrobe,
    LMB_WriteStrobe,
    LMB_AddrStrobe,
    LMB_ReadDBus,
    LMB_WriteDBus,
    LMB_Ready,
    LMB_BE
  );
  input LMB_Clk;
  input SYS_Rst;
  output LMB_Rst;
  input [0:31] M_ABus;
  input M_ReadStrobe;
  input M_WriteStrobe;
  input M_AddrStrobe;
  input [0:31] M_DBus;
  input [0:3] M_BE;
  input [0:31] Sl_DBus;
  input [0:0] Sl_Ready;
  output [0:31] LMB_ABus;
  output LMB_ReadStrobe;
  output LMB_WriteStrobe;
  output LMB_AddrStrobe;
  output [0:31] LMB_ReadDBus;
  output [0:31] LMB_WriteDBus;
  output LMB_Ready;
  output [0:3] LMB_BE;
endmodule

module dlmb_wrapper
  (
    LMB_Clk,
    SYS_Rst,
    LMB_Rst,
    M_ABus,
    M_ReadStrobe,
    M_WriteStrobe,
    M_AddrStrobe,
    M_DBus,
    M_BE,
    Sl_DBus,
    Sl_Ready,
    LMB_ABus,
    LMB_ReadStrobe,
    LMB_WriteStrobe,
    LMB_AddrStrobe,
    LMB_ReadDBus,
    LMB_WriteDBus,
    LMB_Ready,
    LMB_BE
  );
  input LMB_Clk;
  input SYS_Rst;
  output LMB_Rst;
  input [0:31] M_ABus;
  input M_ReadStrobe;
  input M_WriteStrobe;
  input M_AddrStrobe;
  input [0:31] M_DBus;
  input [0:3] M_BE;
  input [0:31] Sl_DBus;
  input [0:0] Sl_Ready;
  output [0:31] LMB_ABus;
  output LMB_ReadStrobe;
  output LMB_WriteStrobe;
  output LMB_AddrStrobe;
  output [0:31] LMB_ReadDBus;
  output [0:31] LMB_WriteDBus;
  output LMB_Ready;
  output [0:3] LMB_BE;
endmodule

module dlmb_cntlr_wrapper
  (
    LMB_Clk,
    LMB_Rst,
    LMB_ABus,
    LMB_WriteDBus,
    LMB_AddrStrobe,
    LMB_ReadStrobe,
    LMB_WriteStrobe,
    LMB_BE,
    Sl_DBus,
    Sl_Ready,
    BRAM_Rst_A,
    BRAM_Clk_A,
    BRAM_EN_A,
    BRAM_WEN_A,
    BRAM_Addr_A,
    BRAM_Din_A,
    BRAM_Dout_A
  );
  input LMB_Clk;
  input LMB_Rst;
  input [0:31] LMB_ABus;
  input [0:31] LMB_WriteDBus;
  input LMB_AddrStrobe;
  input LMB_ReadStrobe;
  input LMB_WriteStrobe;
  input [0:3] LMB_BE;
  output [0:31] Sl_DBus;
  output Sl_Ready;
  output BRAM_Rst_A;
  output BRAM_Clk_A;
  output BRAM_EN_A;
  output [0:3] BRAM_WEN_A;
  output [0:31] BRAM_Addr_A;
  input [0:31] BRAM_Din_A;
  output [0:31] BRAM_Dout_A;
endmodule

module ilmb_cntlr_wrapper
  (
    LMB_Clk,
    LMB_Rst,
    LMB_ABus,
    LMB_WriteDBus,
    LMB_AddrStrobe,
    LMB_ReadStrobe,
    LMB_WriteStrobe,
    LMB_BE,
    Sl_DBus,
    Sl_Ready,
    BRAM_Rst_A,
    BRAM_Clk_A,
    BRAM_EN_A,
    BRAM_WEN_A,
    BRAM_Addr_A,
    BRAM_Din_A,
    BRAM_Dout_A
  );
  input LMB_Clk;
  input LMB_Rst;
  input [0:31] LMB_ABus;
  input [0:31] LMB_WriteDBus;
  input LMB_AddrStrobe;
  input LMB_ReadStrobe;
  input LMB_WriteStrobe;
  input [0:3] LMB_BE;
  output [0:31] Sl_DBus;
  output Sl_Ready;
  output BRAM_Rst_A;
  output BRAM_Clk_A;
  output BRAM_EN_A;
  output [0:3] BRAM_WEN_A;
  output [0:31] BRAM_Addr_A;
  input [0:31] BRAM_Din_A;
  output [0:31] BRAM_Dout_A;
endmodule

module lmb_bram_wrapper
  (
    BRAM_Rst_A,
    BRAM_Clk_A,
    BRAM_EN_A,
    BRAM_WEN_A,
    BRAM_Addr_A,
    BRAM_Din_A,
    BRAM_Dout_A,
    BRAM_Rst_B,
    BRAM_Clk_B,
    BRAM_EN_B,
    BRAM_WEN_B,
    BRAM_Addr_B,
    BRAM_Din_B,
    BRAM_Dout_B
  );
  input BRAM_Rst_A;
  input BRAM_Clk_A;
  input BRAM_EN_A;
  input [0:3] BRAM_WEN_A;
  input [0:31] BRAM_Addr_A;
  output [0:31] BRAM_Din_A;
  input [0:31] BRAM_Dout_A;
  input BRAM_Rst_B;
  input BRAM_Clk_B;
  input BRAM_EN_B;
  input [0:3] BRAM_WEN_B;
  input [0:31] BRAM_Addr_B;
  output [0:31] BRAM_Din_B;
  input [0:31] BRAM_Dout_B;
endmodule

module rs232_uart_1_wrapper
  (
    SPLB_Clk,
    SPLB_Rst,
    PLB_ABus,
    PLB_UABus,
    PLB_PAValid,
    PLB_SAValid,
    PLB_rdPrim,
    PLB_wrPrim,
    PLB_masterID,
    PLB_abort,
    PLB_busLock,
    PLB_RNW,
    PLB_BE,
    PLB_MSize,
    PLB_size,
    PLB_type,
    PLB_lockErr,
    PLB_wrDBus,
    PLB_wrBurst,
    PLB_rdBurst,
    PLB_wrPendReq,
    PLB_rdPendReq,
    PLB_wrPendPri,
    PLB_rdPendPri,
    PLB_reqPri,
    PLB_TAttribute,
    Sl_addrAck,
    Sl_SSize,
    Sl_wait,
    Sl_rearbitrate,
    Sl_wrDAck,
    Sl_wrComp,
    Sl_wrBTerm,
    Sl_rdDBus,
    Sl_rdWdAddr,
    Sl_rdDAck,
    Sl_rdComp,
    Sl_rdBTerm,
    Sl_MBusy,
    Sl_MWrErr,
    Sl_MRdErr,
    Sl_MIRQ,
    baudoutN,
    ctsN,
    dcdN,
    ddis,
    dsrN,
    dtrN,
    out1N,
    out2N,
    rclk,
    riN,
    rtsN,
    rxrdyN,
    sin,
    sout,
    IP2INTC_Irpt,
    txrdyN,
    xin,
    xout,
    Freeze
  );
  input SPLB_Clk;
  input SPLB_Rst;
  input [0:31] PLB_ABus;
  input [0:31] PLB_UABus;
  input PLB_PAValid;
  input PLB_SAValid;
  input PLB_rdPrim;
  input PLB_wrPrim;
  input [0:0] PLB_masterID;
  input PLB_abort;
  input PLB_busLock;
  input PLB_RNW;
  input [0:3] PLB_BE;
  input [0:1] PLB_MSize;
  input [0:3] PLB_size;
  input [0:2] PLB_type;
  input PLB_lockErr;
  input [0:31] PLB_wrDBus;
  input PLB_wrBurst;
  input PLB_rdBurst;
  input PLB_wrPendReq;
  input PLB_rdPendReq;
  input [0:1] PLB_wrPendPri;
  input [0:1] PLB_rdPendPri;
  input [0:1] PLB_reqPri;
  input [0:15] PLB_TAttribute;
  output Sl_addrAck;
  output [0:1] Sl_SSize;
  output Sl_wait;
  output Sl_rearbitrate;
  output Sl_wrDAck;
  output Sl_wrComp;
  output Sl_wrBTerm;
  output [0:31] Sl_rdDBus;
  output [0:3] Sl_rdWdAddr;
  output Sl_rdDAck;
  output Sl_rdComp;
  output Sl_rdBTerm;
  output [0:1] Sl_MBusy;
  output [0:1] Sl_MWrErr;
  output [0:1] Sl_MRdErr;
  output [0:1] Sl_MIRQ;
  output baudoutN;
  input ctsN;
  input dcdN;
  output ddis;
  input dsrN;
  output dtrN;
  output out1N;
  output out2N;
  input rclk;
  input riN;
  output rtsN;
  output rxrdyN;
  input sin;
  output sout;
  output IP2INTC_Irpt;
  output txrdyN;
  input xin;
  output xout;
  input Freeze;
endmodule

module xps_bram_if_cntlr_1_wrapper
  (
    SPLB_Clk,
    SPLB_Rst,
    PLB_ABus,
    PLB_UABus,
    PLB_PAValid,
    PLB_SAValid,
    PLB_rdPrim,
    PLB_wrPrim,
    PLB_masterID,
    PLB_abort,
    PLB_busLock,
    PLB_RNW,
    PLB_BE,
    PLB_MSize,
    PLB_size,
    PLB_type,
    PLB_lockErr,
    PLB_wrDBus,
    PLB_wrBurst,
    PLB_rdBurst,
    PLB_wrPendReq,
    PLB_rdPendReq,
    PLB_wrPendPri,
    PLB_rdPendPri,
    PLB_reqPri,
    PLB_TAttribute,
    Sl_addrAck,
    Sl_SSize,
    Sl_wait,
    Sl_rearbitrate,
    Sl_wrDAck,
    Sl_wrComp,
    Sl_wrBTerm,
    Sl_rdDBus,
    Sl_rdWdAddr,
    Sl_rdDAck,
    Sl_rdComp,
    Sl_rdBTerm,
    Sl_MBusy,
    Sl_MWrErr,
    Sl_MRdErr,
    Sl_MIRQ,
    BRAM_Rst,
    BRAM_Clk,
    BRAM_EN,
    BRAM_WEN,
    BRAM_Addr,
    BRAM_Din,
    BRAM_Dout
  );
  input SPLB_Clk;
  input SPLB_Rst;
  input [0:31] PLB_ABus;
  input [0:31] PLB_UABus;
  input PLB_PAValid;
  input PLB_SAValid;
  input PLB_rdPrim;
  input PLB_wrPrim;
  input [0:0] PLB_masterID;
  input PLB_abort;
  input PLB_busLock;
  input PLB_RNW;
  input [0:3] PLB_BE;
  input [0:1] PLB_MSize;
  input [0:3] PLB_size;
  input [0:2] PLB_type;
  input PLB_lockErr;
  input [0:31] PLB_wrDBus;
  input PLB_wrBurst;
  input PLB_rdBurst;
  input PLB_wrPendReq;
  input PLB_rdPendReq;
  input [0:1] PLB_wrPendPri;
  input [0:1] PLB_rdPendPri;
  input [0:1] PLB_reqPri;
  input [0:15] PLB_TAttribute;
  output Sl_addrAck;
  output [0:1] Sl_SSize;
  output Sl_wait;
  output Sl_rearbitrate;
  output Sl_wrDAck;
  output Sl_wrComp;
  output Sl_wrBTerm;
  output [0:31] Sl_rdDBus;
  output [0:3] Sl_rdWdAddr;
  output Sl_rdDAck;
  output Sl_rdComp;
  output Sl_rdBTerm;
  output [0:1] Sl_MBusy;
  output [0:1] Sl_MWrErr;
  output [0:1] Sl_MRdErr;
  output [0:1] Sl_MIRQ;
  output BRAM_Rst;
  output BRAM_Clk;
  output BRAM_EN;
  output [0:3] BRAM_WEN;
  output [0:31] BRAM_Addr;
  input [0:31] BRAM_Din;
  output [0:31] BRAM_Dout;
endmodule

module xps_bram_if_cntlr_1_bram_wrapper
  (
    BRAM_Rst_A,
    BRAM_Clk_A,
    BRAM_EN_A,
    BRAM_WEN_A,
    BRAM_Addr_A,
    BRAM_Din_A,
    BRAM_Dout_A,
    BRAM_Rst_B,
    BRAM_Clk_B,
    BRAM_EN_B,
    BRAM_WEN_B,
    BRAM_Addr_B,
    BRAM_Din_B,
    BRAM_Dout_B
  );
  input BRAM_Rst_A;
  input BRAM_Clk_A;
  input BRAM_EN_A;
  input [0:3] BRAM_WEN_A;
  input [0:31] BRAM_Addr_A;
  output [0:31] BRAM_Din_A;
  input [0:31] BRAM_Dout_A;
  input BRAM_Rst_B;
  input BRAM_Clk_B;
  input BRAM_EN_B;
  input [0:3] BRAM_WEN_B;
  input [0:31] BRAM_Addr_B;
  output [0:31] BRAM_Din_B;
  input [0:31] BRAM_Dout_B;
endmodule

module clock_generator_0_wrapper
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

module proc_sys_reset_0_wrapper
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

module bramfeeder_0_wrapper
  (
    CLK,
    RST,
    ppcMessageInput_put,
    EN_ppcMessageInput_put,
    RDY_ppcMessageInput_put,
    EN_ppcMessageOutput_get,
    ppcMessageOutput_get,
    RDY_ppcMessageOutput_get,
    bramInitiatorWires_bramCLK,
    bramInitiatorWires_bramRST,
    bramInitiatorWires_bramAddr,
    bramInitiatorWires_bramDout,
    bramInitiatorWires_bramWEN,
    bramInitiatorWires_bramEN,
    bramInitiatorWires_bramDin
  );
  input CLK;
  input RST;
  input [31:0] ppcMessageInput_put;
  input EN_ppcMessageInput_put;
  output RDY_ppcMessageInput_put;
  input EN_ppcMessageOutput_get;
  output [31:0] ppcMessageOutput_get;
  output RDY_ppcMessageOutput_get;
  output bramInitiatorWires_bramCLK;
  output bramInitiatorWires_bramRST;
  output [31:0] bramInitiatorWires_bramAddr;
  output [31:0] bramInitiatorWires_bramDout;
  output [3:0] bramInitiatorWires_bramWEN;
  output bramInitiatorWires_bramEN;
  input [31:0] bramInitiatorWires_bramDin;
endmodule

