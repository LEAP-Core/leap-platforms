--*****************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This text/file contains proprietary, confidential
-- information of Xilinx, Inc., is distributed under license
-- from Xilinx, Inc., and may be used, copied and/or
-- disclosed only pursuant to the terms of a valid license
-- agreement with Xilinx, Inc. Xilinx hereby grants you a
-- license to use this text/file solely for design, simulation,
-- implementation and creation of design files limited
-- to Xilinx devices or technologies. Use with non-Xilinx
-- devices or technologies is expressly prohibited and
-- immediately terminates your license unless covered by
-- a separate agreement.
--
-- Xilinx is providing this design, code, or information
-- "as-is" solely for use in developing programs and
-- solutions for Xilinx devices, with no obligation on the
-- part of Xilinx to provide support. By providing this design,
-- code, or information as one possible implementation of
-- this feature, application or standard, Xilinx is making no
-- representation that this implementation is free from any
-- claims of infringement. You are responsible for
-- obtaining any rights you may require for your implementation.
-- Xilinx expressly disclaims any warranty whatsoever with
-- respect to the adequacy of the implementation, including
-- but not limited to any warranties or representations that this
-- implementation is free from claims of infringement, implied
-- warranties of merchantability or fitness for a particular
-- purpose.
--
-- Xilinx products are not intended for use in life support
-- appliances, devices, or systems. Use in such applications is
-- expressly prohibited.
--
-- Any modifications that are made to the Source Code are
-- done at the user's sole risk and will be unsupported.
--
-- Copyright (c) 2006-2007 Xilinx, Inc. All rights reserved.
--
-- This copyright and support notice must be retained as part
-- of this text at all times.
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: 2.3
--  \   \         Application: MIG
--  /   /         Filename: ddr2_sdram.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/07/09 12:33:12 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR2
--Purpose:
--   Top-level  module. Simple model for what the user might use
--   Typically, the user will only instantiate MEM_INTERFACE_TOP in their
--   code, and generate all backend logic (test bench) separately. 
--   In addition to the memory controller, the module instantiates:
--     1. Clock generation/distribution, reset logic
--     2. IDELAY control block
--Reference:
--Revision History:
--*****************************************************************************

library ieee;

use ieee.std_logic_1164.all;

use work.ddr2_chipscope.all;

entity ddr2_sdram is
  generic(
   BANK_WIDTH               : integer := 2; 
                              -- # of memory bank addr bits.
   CKE_WIDTH                : integer := 2; 
                              -- # of memory clock enable outputs.
   CLK_WIDTH                : integer := 2; 
                              -- # of clock outputs.
   COL_WIDTH                : integer := 10; 
                              -- # of memory column bits.
   CS_NUM                   : integer := 2; 
                              -- # of separate memory chip selects.
   CS_WIDTH                 : integer := 2; 
                              -- # of total memory chip selects.
   CS_BITS                  : integer := 1; 
                              -- set to log2(CS_NUM) (rounded up).
   DM_WIDTH                 : integer := 8; 
                              -- # of data mask bits.
   DQ_WIDTH                 : integer := 64; 
                              -- # of data width.
   DQ_PER_DQS               : integer := 8; 
                              -- # of DQ data bits per strobe.
   DQS_WIDTH                : integer := 8; 
                              -- # of DQS strobes.
   DQ_BITS                  : integer := 6; 
                              -- set to log2(DQS_WIDTH*DQ_PER_DQS).
   DQS_BITS                 : integer := 3; 
                              -- set to log2(DQS_WIDTH).
   ODT_WIDTH                : integer := 2; 
                              -- # of memory on-die term enables.
   ROW_WIDTH                : integer := 13; 
                              -- # of memory row and # of addr bits.
   ADDITIVE_LAT             : integer := 0; 
                              -- additive write latency.
   BURST_LEN                : integer := 4; 
                              -- burst length (in double words).
   BURST_TYPE               : integer := 0; 
                              -- burst type (=0 seq; =1 interleaved).
   CAS_LAT                  : integer := 3; 
                              -- CAS latency.
   ECC_ENABLE               : integer := 0; 
                              -- enable ECC (=1 enable).
   APPDATA_WIDTH            : integer := 128; 
                              -- # of usr read/write data bus bits.
   MULTI_BANK_EN            : integer := 1; 
                              -- Keeps multiple banks open. (= 1 enable).
   TWO_T_TIME_EN            : integer := 1; 
                              -- 2t timing for unbuffered dimms.
   ODT_TYPE                 : integer := 1; 
                              -- ODT (=0(none),=1(75),=2(150),=3(50)).
   REDUCE_DRV               : integer := 0; 
                              -- reduced strength mem I/O (=1 yes).
   REG_ENABLE               : integer := 0; 
                              -- registered addr/ctrl (=1 yes).
   TREFI_NS                 : integer := 7800; 
                              -- auto refresh interval (ns).
   TRAS                     : integer := 45000; 
                              -- active->precharge delay.
   TRCD                     : integer := 15000; 
                              -- active->read/write delay.
   TRFC                     : integer := 105000; 
                              -- refresh->refresh, refresh->active delay.
   TRP                      : integer := 15000; 
                              -- precharge->command delay.
   TRTP                     : integer := 7500; 
                              -- read->precharge delay.
   TWR                      : integer := 15000; 
                              -- used to determine write->precharge.
   TWTR                     : integer := 7500; 
                              -- write->read delay.
   HIGH_PERFORMANCE_MODE    : boolean := FALSE; 
                              -- # = TRUE, the IODELAY performance mode is set
                              -- to high.
                              -- # = FALSE, the IODELAY performance mode is set
                              -- to low.
   SIM_ONLY                 : integer := 0; 
                              -- = 1 to skip SDRAM power up delay.
   DEBUG_EN                 : integer := 0; 
                              -- Enable debug signals/controls.
                              -- When this parameter is changed from 0 to 1,
                              -- make sure to uncomment the coregen commands
                              -- in ise_flow.bat or create_ise.bat files in
                              -- par folder.
   CLK_PERIOD               : integer := 6666; 
                              -- Core/Memory clock period (in ps).
   DQS_IO_COL               : bit_vector := "0000001010101010";
                              -- I/O column location of DQS groups
                              -- (=0, left; =1 center, =2 right).
   DQ_IO_MS                 : bit_vector := "1010011101110100011010001100111001011010000111100110010101101010";
                              -- Master/Slave location of DQ I/O (=0 slave).
   CLK_TYPE                 : string := "SINGLE_ENDED"; 
                              -- # = "DIFFERENTIAL " ->; Differential input clocks ,
                              -- # = "SINGLE_ENDED" -> Single ended input clocks.
   DLL_FREQ_MODE            : string := "HIGH"; 
                              -- DCM Frequency range.
   RST_ACT_LOW              : integer := 1  
                              -- =1 for active low reset, =0 for active high.
   );
  port(
   -- DRAM pins
   ddr2_dq               : inout  std_logic_vector((DQ_WIDTH-1) downto 0);
   ddr2_a                : out   std_logic_vector((ROW_WIDTH-1) downto 0);
   ddr2_ba               : out   std_logic_vector((BANK_WIDTH-1) downto 0);
   ddr2_ras_n            : out   std_logic;
   ddr2_cas_n            : out   std_logic;
   ddr2_we_n             : out   std_logic;
   ddr2_cs_n             : out   std_logic_vector((CS_WIDTH-1) downto 0);
   ddr2_odt              : out   std_logic_vector((ODT_WIDTH-1) downto 0);
   ddr2_cke              : out   std_logic_vector((CKE_WIDTH-1) downto 0);
   ddr2_dm               : out   std_logic_vector((DM_WIDTH-1) downto 0);

   ddr2_dqs              : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
   ddr2_dqs_n            : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
   ddr2_ck               : out   std_logic_vector((CLK_WIDTH-1) downto 0);
   ddr2_ck_n             : out   std_logic_vector((CLK_WIDTH-1) downto 0);

   -- application interface
   sys_clk               : in    std_logic;
   idly_clk_200          : in    std_logic;
   sys_rst_n             : in    std_logic;
   phy_init_done         : out   std_logic;
   rst0_n_tb             : out   std_logic;
   clk0_tb               : out   std_logic;

   app_wdf_afull_n       : out   std_logic;
   app_af_afull_n        : out   std_logic;
   rd_data_valid         : out   std_logic;
   app_wdf_wren          : in    std_logic;
   app_af_wren           : in    std_logic;
   app_af_addr           : in    std_logic_vector(30 downto 0);
   app_af_cmd            : in    std_logic_vector(2 downto 0);
   rd_data_fifo_out      : out   std_logic_vector((APPDATA_WIDTH-1) downto 0);
   app_wdf_data          : in    std_logic_vector((APPDATA_WIDTH-1) downto 0);
   app_wdf_mask_data     : in    std_logic_vector((APPDATA_WIDTH/8-1) downto 0)
   );

end entity ddr2_sdram;

architecture arc_mem_interface_top of ddr2_sdram is

  ------------------------------------------------------------------------------
  -- The following constant "IDELAYCTRL_NUM" indicates the number of IDELAYCTRLs
  -- that are LOCed for the design. The IDELAYCTRL LOCs are provided in the
  -- UCF file of par folder. MIG provides the constant value and the LOCs in the
  -- UCF file based on the selected Data Read banks for the design. You must not
  -- alter this value unless it is needed. If you modify this value, you should
  -- make sure that the value of "IDELAYCTRL_NUM" and IDELAYCTRL LOCs in the
  -- UCF file are same and are relavent to the Data Read banks used.
  ------------------------------------------------------------------------------
  constant IDELAYCTRL_NUM : integer := 3;



  component ddr2_idelay_ctrl
    generic (
      IDELAYCTRL_NUM       : integer
      );
    port (
      rst200               : in    std_logic;
      clk200               : in    std_logic;
      idelay_ctrl_rdy      : out   std_logic
      );
  end component;

component ddr2_infrastructure
    generic (
      CLK_PERIOD            : integer;
      CLK_TYPE              : string;
      DLL_FREQ_MODE         : string;
      RST_ACT_LOW           : integer

      );
    port (
      sys_clk_p            : in    std_logic;
      sys_clk_n            : in    std_logic;
      sys_clk              : in    std_logic;
      clk200_p             : in    std_logic;
      clk200_n             : in    std_logic;
      idly_clk_200         : in    std_logic;
      sys_rst_n            : in    std_logic;
      rst0                 : out   std_logic;
      rst90                : out   std_logic;
      rstdiv0              : out   std_logic;
      rst200               : out   std_logic;
      clk0                 : out   std_logic;
      clk90                : out   std_logic;
      clkdiv0              : out   std_logic;
      clk200               : out   std_logic;
      idelay_ctrl_rdy      : in    std_logic

      );
  end component;


component ddr2_top
    generic (
      BANK_WIDTH            : integer;
      CKE_WIDTH             : integer;
      CLK_WIDTH             : integer;
      COL_WIDTH             : integer;
      CS_NUM                : integer;
      CS_WIDTH              : integer;
      CS_BITS               : integer;
      DM_WIDTH              : integer;
      DQ_WIDTH              : integer;
      DQ_PER_DQS            : integer;
      DQS_WIDTH             : integer;
      DQ_BITS               : integer;
      DQS_BITS              : integer;
      ODT_WIDTH             : integer;
      ROW_WIDTH             : integer;
      ADDITIVE_LAT          : integer;
      BURST_LEN             : integer;
      BURST_TYPE            : integer;
      CAS_LAT               : integer;
      ECC_ENABLE            : integer;
      APPDATA_WIDTH         : integer;
      MULTI_BANK_EN         : integer;
      TWO_T_TIME_EN         : integer;
      ODT_TYPE              : integer;
      REDUCE_DRV            : integer;
      REG_ENABLE            : integer;
      TREFI_NS              : integer;
      TRAS                  : integer;
      TRCD                  : integer;
      TRFC                  : integer;
      TRP                   : integer;
      TRTP                  : integer;
      TWR                   : integer;
      TWTR                  : integer;
      HIGH_PERFORMANCE_MODE   : boolean;
      SIM_ONLY              : integer;
      DEBUG_EN              : integer;
      CLK_PERIOD            : integer;
      DQS_IO_COL            : bit_vector;
      DQ_IO_MS              : bit_vector;
      USE_DM_PORT           : integer
      );
    port (
      ddr2_dq              : inout  std_logic_vector((DQ_WIDTH-1) downto 0);
      ddr2_a               : out   std_logic_vector((ROW_WIDTH-1) downto 0);
      ddr2_ba              : out   std_logic_vector((BANK_WIDTH-1) downto 0);
      ddr2_ras_n           : out   std_logic;
      ddr2_cas_n           : out   std_logic;
      ddr2_we_n            : out   std_logic;
      ddr2_cs_n            : out   std_logic_vector((CS_WIDTH-1) downto 0);
      ddr2_odt             : out   std_logic_vector((ODT_WIDTH-1) downto 0);
      ddr2_cke             : out   std_logic_vector((CKE_WIDTH-1) downto 0);
      ddr2_dm              : out   std_logic_vector((DM_WIDTH-1) downto 0);
      phy_init_done        : out   std_logic;
      rst0                 : in    std_logic;
      rst90                : in    std_logic;
      rstdiv0              : in    std_logic;
      clk0                 : in    std_logic;
      clk90                : in    std_logic;
      clkdiv0              : in    std_logic;
      app_wdf_afull        : out   std_logic;
      app_af_afull         : out   std_logic;
      rd_data_valid        : out   std_logic;
      app_wdf_wren         : in    std_logic;
      app_af_wren          : in    std_logic;
      app_af_addr          : in    std_logic_vector(30 downto 0);
      app_af_cmd           : in    std_logic_vector(2 downto 0);
      rd_data_fifo_out     : out   std_logic_vector((APPDATA_WIDTH-1) downto 0);
      app_wdf_data         : in    std_logic_vector((APPDATA_WIDTH-1) downto 0);
      app_wdf_mask_data    : in    std_logic_vector((APPDATA_WIDTH/8-1) downto 0);
      ddr2_dqs             : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
      ddr2_dqs_n           : inout  std_logic_vector((DQS_WIDTH-1) downto 0);
      ddr2_ck              : out   std_logic_vector((CLK_WIDTH-1) downto 0);
      rd_ecc_error         : out   std_logic_vector(1 downto 0);
      ddr2_ck_n            : out   std_logic_vector((CLK_WIDTH-1) downto 0);
      dbg_calib_done          : out  std_logic_vector(3 downto 0);
      dbg_calib_err           : out  std_logic_vector(3 downto 0);
      dbg_calib_dq_tap_cnt    : out  std_logic_vector(((6*DQ_WIDTH)-1) downto 0);
      dbg_calib_dqs_tap_cnt   : out  std_logic_vector(((6*DQS_WIDTH)-1) downto 0);
      dbg_calib_gate_tap_cnt   : out  std_logic_vector(((6*DQS_WIDTH)-1) downto 0);
      dbg_calib_rd_data_sel   : out  std_logic_vector((DQS_WIDTH-1) downto 0);
      dbg_calib_rden_dly      : out  std_logic_vector(((5*DQS_WIDTH)-1) downto 0);
      dbg_calib_gate_dly      : out  std_logic_vector(((5*DQS_WIDTH)-1) downto 0);
      dbg_idel_up_all         : in  std_logic;
      dbg_idel_down_all       : in  std_logic;
      dbg_idel_up_dq          : in  std_logic;
      dbg_idel_down_dq        : in  std_logic;
      dbg_idel_up_dqs         : in  std_logic;
      dbg_idel_down_dqs       : in  std_logic;
      dbg_idel_up_gate        : in  std_logic;
      dbg_idel_down_gate      : in  std_logic;
      dbg_sel_idel_dq         : in  std_logic_vector((DQ_BITS-1) downto 0);
      dbg_sel_all_idel_dq     : in  std_logic;
      dbg_sel_idel_dqs        : in  std_logic_vector(DQS_BITS downto 0);
      dbg_sel_all_idel_dqs    : in  std_logic;
      dbg_sel_idel_gate       : in  std_logic_vector(DQS_BITS downto 0);
      dbg_sel_all_idel_gate   : in  std_logic

      );
  end component;

  -- invert almost-full signals for BSV convenience
  signal app_wdf_afull_c : std_logic;
  signal app_af_afull_c  : std_logic;


  signal  sys_clk_p              : std_logic;
  signal  sys_clk_n              : std_logic;
  signal  clk200_p               : std_logic;
  signal  clk200_n               : std_logic;
  signal  rst0                   : std_logic;
  signal  rst90                  : std_logic;
  signal  rstdiv0                : std_logic;
  signal  rst200                 : std_logic;
  signal  clk0                   : std_logic;
  signal  clk90                  : std_logic;
  signal  clkdiv0                : std_logic;
  signal  clk200                 : std_logic;
  signal  idelay_ctrl_rdy        : std_logic;
  signal  i_phy_init_done      : std_logic;


  --Debug signals


  signal  dbg_calib_done             : std_logic_vector(3 downto 0);
  signal  dbg_calib_err              : std_logic_vector(3 downto 0);
  signal  dbg_calib_dq_tap_cnt       : std_logic_vector(((6*DQ_WIDTH)-1) downto 0);
  signal  dbg_calib_dqs_tap_cnt      : std_logic_vector(((6*DQS_WIDTH)-1) downto 0);
  signal  dbg_calib_gate_tap_cnt     : std_logic_vector(((6*DQS_WIDTH)-1) downto 0);
  signal  dbg_calib_rd_data_sel      : std_logic_vector((DQS_WIDTH-1) downto 0);
  signal  dbg_calib_rden_dly         : std_logic_vector(((5*DQS_WIDTH)-1) downto 0);
  signal  dbg_calib_gate_dly         : std_logic_vector(((5*DQS_WIDTH)-1) downto 0);
  signal  dbg_idel_up_all            : std_logic;
  signal  dbg_idel_down_all          : std_logic;
  signal  dbg_idel_up_dq             : std_logic;
  signal  dbg_idel_down_dq           : std_logic;
  signal  dbg_idel_up_dqs            : std_logic;
  signal  dbg_idel_down_dqs          : std_logic;
  signal  dbg_idel_up_gate           : std_logic;
  signal  dbg_idel_down_gate         : std_logic;
  signal  dbg_sel_idel_dq            : std_logic_vector((DQ_BITS-1) downto 0);
  signal  dbg_sel_all_idel_dq        : std_logic;
  signal  dbg_sel_idel_dqs           : std_logic_vector(DQS_BITS downto 0);
  signal  dbg_sel_all_idel_dqs       : std_logic;
  signal  dbg_sel_idel_gate          : std_logic_vector(DQS_BITS downto 0);
  signal  dbg_sel_all_idel_gate      : std_logic;


 -- Debug signals (optional use)

  --***********************************
  -- PHY Debug Port demo
  --***********************************
  signal cs_control0            : std_logic_vector(35 downto 0);
  signal cs_control1            : std_logic_vector(35 downto 0);
  signal cs_control2            : std_logic_vector(35 downto 0);
  signal cs_control3            : std_logic_vector(35 downto 0);
  signal vio0_in                : std_logic_vector(191 downto 0);
  signal vio1_in                : std_logic_vector(95 downto 0);
  signal vio2_in                : std_logic_vector(99 downto 0);
  signal vio3_out               : std_logic_vector(31 downto 0);




  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arc_mem_interface_top : architecture IS
    "mig_v2_3_ddr2_sdram_v5, Coregen 10.1.02";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arc_mem_interface_top : architecture IS "ddr2_sdram_v5,mig_v2_3,{component_name=ddr2_sdram, BANK_WIDTH=2, CKE_WIDTH=2, CLK_WIDTH=2, COL_WIDTH=10, CS_NUM=2, CS_WIDTH=2, DM_WIDTH=8, DQ_WIDTH=64, DQ_PER_DQS=8, DQS_WIDTH=8, ODT_WIDTH=2, ROW_WIDTH=13, ADDITIVE_LAT=0, BURST_LEN=4, BURST_TYPE=0, CAS_LAT=3, ECC_ENABLE=0, MULTI_BANK_EN=1, TWO_T_TIME_EN=1, ODT_TYPE=1, REDUCE_DRV=0, REG_ENABLE=0, TREFI_NS=7800, TRAS=45000, TRCD=15000, TRFC=105000, TRP=15000, TRTP=7500, TWR=15000, TWTR=7500, DDR2_CLK_PERIOD=6666, RST_ACT_LOW=1}";

begin

  --***************************************************************************
  -- Angshuman -- invert almost-full signals for BSV convenience
  app_wdf_afull_n <= not app_wdf_afull_c;
  app_af_afull_n  <= not app_af_afull_c;

  rst0_n_tb <= not rst0;                -- Angshuman -- invert rst to rst_n
  clk0_tb <= clk0;
  phy_init_done   <= i_phy_init_done;
  sys_clk_p <= '1';
  sys_clk_n <= '0';
  clk200_p <= '1';
  clk200_n <= '0';

  u_ddr2_idelay_ctrl : ddr2_idelay_ctrl
    generic map (
      IDELAYCTRL_NUM        => IDELAYCTRL_NUM
   )
    port map (
      rst200                => rst200,
      clk200                => clk200,
      idelay_ctrl_rdy       => idelay_ctrl_rdy
   );

  u_ddr2_infrastructure : ddr2_infrastructure
    generic map (
      CLK_PERIOD            => CLK_PERIOD,
      CLK_TYPE              => CLK_TYPE,
      DLL_FREQ_MODE         => DLL_FREQ_MODE,
      RST_ACT_LOW           => RST_ACT_LOW
   )
    port map (
      sys_clk_p             => sys_clk_p,
      sys_clk_n             => sys_clk_n,
      sys_clk               => sys_clk,
      clk200_p              => clk200_p,
      clk200_n              => clk200_n,
      idly_clk_200          => idly_clk_200,
      sys_rst_n             => sys_rst_n,
      rst0                  => rst0,
      rst90                 => rst90,
      rstdiv0               => rstdiv0,
      rst200                => rst200,
      clk0                  => clk0,
      clk90                 => clk90,
      clkdiv0               => clkdiv0,
      clk200                => clk200,
      idelay_ctrl_rdy       => idelay_ctrl_rdy
   );

  u_ddr2_top_0 : ddr2_top
    generic map (
      BANK_WIDTH            => BANK_WIDTH,
      CKE_WIDTH             => CKE_WIDTH,
      CLK_WIDTH             => CLK_WIDTH,
      COL_WIDTH             => COL_WIDTH,
      CS_NUM                => CS_NUM,
      CS_WIDTH              => CS_WIDTH,
      CS_BITS               => CS_BITS,
      DM_WIDTH              => DM_WIDTH,
      DQ_WIDTH              => DQ_WIDTH,
      DQ_PER_DQS            => DQ_PER_DQS,
      DQS_WIDTH             => DQS_WIDTH,
      DQ_BITS               => DQ_BITS,
      DQS_BITS              => DQS_BITS,
      ODT_WIDTH             => ODT_WIDTH,
      ROW_WIDTH             => ROW_WIDTH,
      ADDITIVE_LAT          => ADDITIVE_LAT,
      BURST_LEN             => BURST_LEN,
      BURST_TYPE            => BURST_TYPE,
      CAS_LAT               => CAS_LAT,
      ECC_ENABLE            => ECC_ENABLE,
      APPDATA_WIDTH         => APPDATA_WIDTH,
      MULTI_BANK_EN         => MULTI_BANK_EN,
      TWO_T_TIME_EN         => TWO_T_TIME_EN,
      ODT_TYPE              => ODT_TYPE,
      REDUCE_DRV            => REDUCE_DRV,
      REG_ENABLE            => REG_ENABLE,
      TREFI_NS              => TREFI_NS,
      TRAS                  => TRAS,
      TRCD                  => TRCD,
      TRFC                  => TRFC,
      TRP                   => TRP,
      TRTP                  => TRTP,
      TWR                   => TWR,
      TWTR                  => TWTR,
      HIGH_PERFORMANCE_MODE   => HIGH_PERFORMANCE_MODE,
      SIM_ONLY              => SIM_ONLY,
      DEBUG_EN              => DEBUG_EN,
      CLK_PERIOD            => CLK_PERIOD,
      DQS_IO_COL            => DQS_IO_COL,
      DQ_IO_MS              => DQ_IO_MS,
      USE_DM_PORT           => 1
      )
    port map (
      ddr2_dq               => ddr2_dq,
      ddr2_a                => ddr2_a,
      ddr2_ba               => ddr2_ba,
      ddr2_ras_n            => ddr2_ras_n,
      ddr2_cas_n            => ddr2_cas_n,
      ddr2_we_n             => ddr2_we_n,
      ddr2_cs_n             => ddr2_cs_n,
      ddr2_odt              => ddr2_odt,
      ddr2_cke              => ddr2_cke,
      ddr2_dm               => ddr2_dm,
      phy_init_done         => i_phy_init_done,
      rst0                  => rst0,
      rst90                 => rst90,
      rstdiv0               => rstdiv0,
      clk0                  => clk0,
      clk90                 => clk90,
      clkdiv0               => clkdiv0,
      app_wdf_afull         => app_wdf_afull_c,
      app_af_afull          => app_af_afull_c,
      rd_data_valid         => rd_data_valid,
      app_wdf_wren          => app_wdf_wren,
      app_af_wren           => app_af_wren,
      app_af_addr           => app_af_addr,
      app_af_cmd            => app_af_cmd,
      rd_data_fifo_out      => rd_data_fifo_out,
      app_wdf_data          => app_wdf_data,
      app_wdf_mask_data     => app_wdf_mask_data,
      ddr2_dqs              => ddr2_dqs,
      ddr2_dqs_n            => ddr2_dqs_n,
      ddr2_ck               => ddr2_ck,
      rd_ecc_error          => open,
      ddr2_ck_n             => ddr2_ck_n,

      dbg_calib_done          => dbg_calib_done,
      dbg_calib_err           => dbg_calib_err,
      dbg_calib_dq_tap_cnt    => dbg_calib_dq_tap_cnt,
      dbg_calib_dqs_tap_cnt   => dbg_calib_dqs_tap_cnt,
      dbg_calib_gate_tap_cnt   => dbg_calib_gate_tap_cnt,
      dbg_calib_rd_data_sel   => dbg_calib_rd_data_sel,
      dbg_calib_rden_dly      => dbg_calib_rden_dly,
      dbg_calib_gate_dly      => dbg_calib_gate_dly,
      dbg_idel_up_all         => dbg_idel_up_all,
      dbg_idel_down_all       => dbg_idel_down_all,
      dbg_idel_up_dq          => dbg_idel_up_dq,
      dbg_idel_down_dq        => dbg_idel_down_dq,
      dbg_idel_up_dqs         => dbg_idel_up_dqs,
      dbg_idel_down_dqs       => dbg_idel_down_dqs,
      dbg_idel_up_gate        => dbg_idel_up_gate,
      dbg_idel_down_gate      => dbg_idel_down_gate,
      dbg_sel_idel_dq         => dbg_sel_idel_dq,
      dbg_sel_all_idel_dq     => dbg_sel_all_idel_dq,
      dbg_sel_idel_dqs        => dbg_sel_idel_dqs,
      dbg_sel_all_idel_dqs    => dbg_sel_all_idel_dqs,
      dbg_sel_idel_gate       => dbg_sel_idel_gate,
      dbg_sel_all_idel_gate   => dbg_sel_all_idel_gate
      );


  --*****************************************************************
  -- Hooks to prevent sim/syn compilation errors (mainly for VHDL - but
  -- keep it also in Verilog version of code) w/ floating inputs if
  -- DEBUG_EN = 0.
  --*****************************************************************

  gen_dbg_tie_off: if (DEBUG_EN = 0) generate
    dbg_idel_up_all       <= '0';
    dbg_idel_down_all     <= '0';
    dbg_idel_up_dq        <= '0';
    dbg_idel_down_dq      <= '0';
    dbg_idel_up_dqs       <= '0';
    dbg_idel_down_dqs     <= '0';
    dbg_idel_up_gate      <= '0';
    dbg_idel_down_gate    <= '0';
    dbg_sel_idel_dq       <= (others => '0');
    dbg_sel_all_idel_dq   <= '0';
    dbg_sel_idel_dqs      <= (others => '0');
    dbg_sel_all_idel_dqs  <= '0';
    dbg_sel_idel_gate     <= (others => '0');
    dbg_sel_all_idel_gate <= '0';

  end generate;

  gen_dbg_tie_on: if (DEBUG_EN = 1) generate
   
      --*****************************************************************
      -- Bit assignments:
      -- NOTE: Not all VIO, ILA inputs/outputs may be used - these will
      --       be dependent on the user's particular bit width
      --*****************************************************************

      gen_dq_le_32: if (DQ_WIDTH <= 32) generate
        vio0_in((6*DQ_WIDTH)-1 downto 0) <= 
	                    dbg_calib_dq_tap_cnt((6*DQ_WIDTH)-1 downto 0);
      end generate;

      gen_dq_gt_32: if (DQ_WIDTH > 32) generate 
        vio0_in <= dbg_calib_dq_tap_cnt(191 downto 0);
      end generate;

      gen_dqs_le_8: if (DQS_WIDTH <= 8) generate
        vio1_in((6*DQS_WIDTH)-1 downto 0) <= 
	                    dbg_calib_dqs_tap_cnt((6*DQS_WIDTH)-1 downto 0);
        vio1_in((12*DQS_WIDTH)-1 downto (6*DQS_WIDTH)) <=
	                    dbg_calib_gate_tap_cnt((6*DQS_WIDTH)-1 downto 0);
      end generate;
      
      gen_dqs_gt_8: if (DQS_WIDTH > 8) generate
        vio1_in(47 downto 0) <= dbg_calib_dqs_tap_cnt(47 downto 0);
        vio1_in(95 downto 48) <= dbg_calib_gate_tap_cnt(47 downto 0);
      end generate;
 
      --dbg_calib_rd_data_sel

      gen_rdsel_le_8: if (DQS_WIDTH <= 8) generate
        vio2_in((DQS_WIDTH)+7 downto 8) <= 
	                    dbg_calib_rd_data_sel((DQS_WIDTH)-1 downto 0);
      end generate;
      gen_rdsel_gt_8: if (DQS_WIDTH > 8) generate
        vio2_in(15 downto 8) <= dbg_calib_rd_data_sel(7 downto 0);
      end generate;
 
      --dbg_calib_rden_dly

      gen_calrd_le_8: if (DQS_WIDTH <= 8) generate
        vio2_in((5*DQS_WIDTH)+19 downto 20) <= 
	                    dbg_calib_rden_dly((5*DQS_WIDTH)-1 downto 0);
      end generate; 
     
      gen_calrd_gt_8: if (DQS_WIDTH > 8) generate
        vio2_in(59 downto 20) <= dbg_calib_rden_dly(39 downto 0);
      end generate;

      --dbg_calib_gate_dly

      gen_calgt_le_8: if (DQS_WIDTH <= 8) generate
        vio2_in((5*DQS_WIDTH)+59 downto 60) <= 
	                    dbg_calib_gate_dly((5*DQS_WIDTH)-1 downto 0);
      end generate; 

      gen_calgt_gt_8: if (DQS_WIDTH > 8) generate
        vio2_in(99 downto 60) <= dbg_calib_gate_dly(39 downto 0);
      end generate;

      --dbg_sel_idel_dq

      gen_selid_le_5: if (DQ_BITS <= 5) generate
        dbg_sel_idel_dq(DQ_BITS-1 downto 0) <= vio3_out(DQ_BITS+7 downto 8);
      end generate;
      
      gen_selid_gt_5: if (DQ_BITS > 5) generate
        dbg_sel_idel_dq(4 downto 0) <= vio3_out(12 downto 8);
      end generate;

      --dbg_sel_idel_dqs

      gen_seldqs_le_3: if (DQS_BITS <= 3) generate
        dbg_sel_idel_dqs(DQS_BITS downto 0) <= 
	                    vio3_out((DQS_BITS+16) downto 16);
      end generate;
      
      gen_seldqs_gt_3: if (DQS_BITS > 3) generate
        dbg_sel_idel_dqs(3 downto 0) <= vio3_out(19 downto 16);
      end generate;

      --dbg_sel_idel_gate

      gen_gtdqs_le_3: if (DQS_BITS <= 3) generate
        dbg_sel_idel_gate(DQS_BITS downto 0) <= vio3_out((DQS_BITS+21) downto 21);
      end generate;

      gen_gtdqs_gt_3: if (DQS_BITS > 3) generate
        dbg_sel_idel_gate(3 downto 0) <= vio3_out(24 downto 21);
     end generate;

      vio2_in(3 downto 0)              <= dbg_calib_done;
      vio2_in(7 downto 4)       <= dbg_calib_err;
      
      dbg_idel_up_all           <= vio3_out(0);
      dbg_idel_down_all         <= vio3_out(1);
      dbg_idel_up_dq            <= vio3_out(2);
      dbg_idel_down_dq          <= vio3_out(3);
      dbg_idel_up_dqs           <= vio3_out(4);
      dbg_idel_down_dqs         <= vio3_out(5);
      dbg_idel_up_gate          <= vio3_out(6);
      dbg_idel_down_gate        <= vio3_out(7);
      dbg_sel_all_idel_dq       <= vio3_out(15);
      dbg_sel_all_idel_dqs      <= vio3_out(20);
      dbg_sel_all_idel_gate     <= vio3_out(25);

    u_icon  : icon4
    port map (
      control0              => cs_control0,
      control1              => cs_control1,
      control2              => cs_control2,
      control3              => cs_control3
      );

      --*****************************************************************
      -- VIO ASYNC input: Display current IDELAY setting for up to 32
      -- DQ taps (32x6) = 192
      --*****************************************************************

    u_vio0 : vio_async_in192
    port map (
      control               => cs_control0,
      async_in              => vio0_in
      );

      --*****************************************************************
      -- VIO ASYNC input: Display current IDELAY setting for up to 8 DQS
      -- and DQS Gate taps (8x6x2) = 96
      --*****************************************************************

    u_vio1 : vio_async_in96 
    port map (
      control               => cs_control1,
      async_in              => vio1_in
      );

      --*****************************************************************
      -- VIO ASYNC input: Display other calibration results
      --*****************************************************************

    u_vio2 : vio_async_in100 
    port map (
      control               => cs_control2,
      async_in              => vio2_in
      );
      
      --*****************************************************************
      -- VIO SYNC output: Dynamically change IDELAY taps
      --*****************************************************************
      
    u_vio3 : vio_sync_out32 
    port map (
      control               => cs_control3,
      clk                   => clkdiv0,
      sync_out              => vio3_out
      );

  end generate;


end architecture arc_mem_interface_top;
