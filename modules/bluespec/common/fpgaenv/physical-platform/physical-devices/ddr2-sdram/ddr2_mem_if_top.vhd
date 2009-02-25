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
--  /   /         Filename: ddr2_mem_if_top.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/07/22 15:41:06 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR2
--Purpose:
--   Top-level for parameterizable (DDR or DDR2) memory interface
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;

entity ddr2_mem_if_top is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference
    -- board design). Actual values may be different. Actual parameters values
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    BANK_WIDTH             :       integer := 2;
    CKE_WIDTH              :       integer := 1;
    CLK_WIDTH              :       integer := 1;
    COL_WIDTH              :       integer := 10;
    CS_BITS                :       integer := 0;
    CS_NUM                 :       integer := 1;
    CS_WIDTH               :       integer := 1;
    USE_DM_PORT            :       integer := 1;
    DM_WIDTH               :       integer := 9;
    DQ_WIDTH               :       integer := 72;
    DQ_BITS                :       integer := 7;
    DQ_PER_DQS             :       integer := 8;
    DQS_BITS               :       integer := 4;
    DQS_WIDTH              :       integer := 9;
    HIGH_PERFORMANCE_MODE  :       boolean := TRUE;
    ODT_WIDTH              :       integer := 1;
    ROW_WIDTH              :       integer := 14;
    ADDITIVE_LAT           :       integer := 0;
    BURST_LEN              :       integer := 4;
    BURST_TYPE             :       integer := 0;
    CAS_LAT                :       integer := 5;
    ECC_ENABLE             :       integer := 0;
    APPDATA_WIDTH          :       integer := 128;
    MULTI_BANK_EN          :       integer := 1;
    TWO_T_TIME_EN          :       integer := 0;
    ODT_TYPE               :       integer := 1;
    DDR_TYPE               :       integer := 1;
    REDUCE_DRV             :       integer := 0;
    REG_ENABLE             :       integer := 1;
    TREFI_NS               :       integer := 7800;
    TRAS                   :       integer := 40000;
    TRCD                   :       integer := 15000;
    TRFC                   :       integer := 105000;
    TRP                    :       integer := 15000;
    TRTP                   :       integer := 7500;
    TWR                    :       integer := 15000;
    TWTR                   :       integer := 10000;
    CLK_PERIOD             :       integer := 3000;
    SIM_ONLY               :       integer := 0;
    DEBUG_EN               :       integer := 0;
    DQS_IO_COL             :       bit_vector := "0";
    DQ_IO_MS               :       bit_vector := "0"
    );
  port (
    clk0                   : in    std_logic;
    clk90                  : in    std_logic;
    clkdiv0                : in    std_logic;
    rst0                   : in    std_logic;
    rst90                  : in    std_logic;
    rstdiv0                : in    std_logic;
    app_af_cmd             : in    std_logic_vector(2 downto 0);
    app_af_addr            : in    std_logic_vector(30 downto 0);
    app_af_wren            : in    std_logic;
    app_wdf_wren           : in    std_logic;
    app_wdf_data           : in    std_logic_vector(APPDATA_WIDTH-1 downto 0);
    app_wdf_mask_data      : in    std_logic_vector((APPDATA_WIDTH/8)-1
                                                    downto 0);
    rd_ecc_error           : out   std_logic_vector(1 downto 0);
    app_af_afull           : out   std_logic;
    app_wdf_afull          : out   std_logic;
    rd_data_valid          : out   std_logic;
    rd_data_fifo_out       : out   std_logic_vector(APPDATA_WIDTH-1 downto 0);
    phy_init_done          : out   std_logic;
    ddr_ck                 : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddr_ck_n               : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddr_addr               : out   std_logic_vector(ROW_WIDTH-1 downto 0);
    ddr_ba                 : out   std_logic_vector(BANK_WIDTH-1 downto 0);
    ddr_ras_n              : out   std_logic;
    ddr_cas_n              : out   std_logic;
    ddr_we_n               : out   std_logic;
    ddr_cs_n               : out   std_logic_vector(CS_WIDTH-1 downto 0);
    ddr_cke                : out   std_logic_vector(CKE_WIDTH-1 downto 0);
    ddr_odt                : out   std_logic_vector(ODT_WIDTH-1 downto 0);
    ddr_dm                 : out   std_logic_vector(DM_WIDTH-1 downto 0);
    ddr_dqs                : inout std_logic_vector(DQS_WIDTH-1 downto 0);
    ddr_dqs_n              : inout std_logic_vector(DQS_WIDTH-1 downto 0);
    ddr_dq                 : inout std_logic_vector(DQ_WIDTH-1 downto 0);
    -- Debug signals (optional use)
    dbg_idel_up_all        : in    std_logic;
    dbg_idel_down_all      : in    std_logic;
    dbg_idel_up_dq         : in    std_logic;
    dbg_idel_down_dq       : in    std_logic;
    dbg_idel_up_dqs        : in    std_logic;
    dbg_idel_down_dqs      : in    std_logic;
    dbg_idel_up_gate       : in    std_logic;
    dbg_idel_down_gate     : in    std_logic;
    dbg_sel_idel_dq        : in    std_logic_vector(DQ_BITS-1 downto 0);
    dbg_sel_all_idel_dq    : in    std_logic;
    dbg_sel_idel_dqs       : in    std_logic_vector(DQS_BITS downto 0);
    dbg_sel_all_idel_dqs   : in    std_logic;
    dbg_sel_idel_gate      : in    std_logic_vector(DQS_BITS downto 0);
    dbg_sel_all_idel_gate  : in    std_logic;
    dbg_calib_done         : out   std_logic_vector(3 downto 0);
    dbg_calib_err          : out   std_logic_vector(3 downto 0);
    dbg_calib_dq_tap_cnt   : out   std_logic_vector((6*DQ_WIDTH)-1 downto 0);
    dbg_calib_dqs_tap_cnt  : out   std_logic_vector((6*DQS_WIDTH)-1 downto 0);
    dbg_calib_gate_tap_cnt : out   std_logic_vector((6*DQS_WIDTH)-1 downto 0);
    dbg_calib_rd_data_sel  : out   std_logic_vector(DQS_WIDTH-1 downto 0);
    dbg_calib_rden_dly     : out   std_logic_vector((5*DQS_WIDTH)-1 downto 0);
    dbg_calib_gate_dly     : out   std_logic_vector((5*DQS_WIDTH)-1 downto 0)
    );
end entity ddr2_mem_if_top;

architecture syn of ddr2_mem_if_top is

  component ddr2_phy_top
    generic (
      BANK_WIDTH            : integer;
      CLK_WIDTH             : integer;
      CKE_WIDTH             : integer;
      COL_WIDTH             : integer;
      CS_NUM                : integer;
      CS_WIDTH              : integer;
      USE_DM_PORT           : integer;
      DM_WIDTH              : integer;
      DQ_WIDTH              : integer;
      DQ_BITS               : integer;
      DQ_PER_DQS            : integer;
      DQS_WIDTH             : integer;
      DQS_BITS              : integer;
      HIGH_PERFORMANCE_MODE : boolean;
      ODT_WIDTH             : integer;
      ROW_WIDTH             : integer;
      ADDITIVE_LAT          : integer;
      TWO_T_TIME_EN         : integer;
      BURST_LEN             : integer;
      BURST_TYPE            : integer;
      CAS_LAT               : integer;
      ECC_ENABLE            : integer;
      ODT_TYPE              : integer;
      DDR_TYPE              : integer;
      REDUCE_DRV            : integer;
      REG_ENABLE            : integer;
      TWR                   : integer;
      CLK_PERIOD            : integer;
      SIM_ONLY              : integer;
      DEBUG_EN              : integer;
      DQS_IO_COL            : bit_vector;
      DQ_IO_MS              : bit_vector);
    port (
      clk0                   : in    std_logic;
      clk90                  : in    std_logic;
      clkdiv0                : in    std_logic;
      rst0                   : in    std_logic;
      rst90                  : in    std_logic;
      rstdiv0                : in    std_logic;
      ctrl_wren              : in    std_logic;
      ctrl_addr              : in    std_logic_vector(ROW_WIDTH-1 downto 0);
      ctrl_ba                : in    std_logic_vector(BANK_WIDTH-1 downto 0);
      ctrl_ras_n             : in    std_logic;
      ctrl_cas_n             : in    std_logic;
      ctrl_we_n              : in    std_logic;
      ctrl_cs_n              : in    std_logic_vector(CS_NUM-1 downto 0);
      ctrl_rden              : in    std_logic;
      ctrl_ref_flag          : in    std_logic;
      wdf_data               : in    std_logic_vector((2*DQ_WIDTH)-1 downto 0);
      wdf_mask_data          : in    std_logic_vector((2*DQ_WIDTH/8)-1
                                                      downto 0);
      wdf_rden               : out   std_logic;
      phy_init_done          : out   std_logic;
      phy_calib_rden         : out   std_logic_vector(DQS_WIDTH-1 downto 0);
      phy_calib_rden_sel     : out   std_logic_vector(DQS_WIDTH-1 downto 0);
      rd_data_rise           : out   std_logic_vector(DQ_WIDTH-1 downto 0);
      rd_data_fall           : out   std_logic_vector(DQ_WIDTH-1 downto 0);
      ddr_ck                 : out   std_logic_vector(CLK_WIDTH-1 downto 0);
      ddr_ck_n               : out   std_logic_vector(CLK_WIDTH-1 downto 0);
      ddr_addr               : out   std_logic_vector(ROW_WIDTH-1 downto 0);
      ddr_ba                 : out   std_logic_vector(BANK_WIDTH-1 downto 0);
      ddr_ras_n              : out   std_logic;
      ddr_cas_n              : out   std_logic;
      ddr_we_n               : out   std_logic;
      ddr_cs_n               : out   std_logic_vector(CS_WIDTH-1 downto 0);
      ddr_cke                : out   std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr_odt                : out   std_logic_vector(ODT_WIDTH-1 downto 0);
      ddr_dm                 : out   std_logic_vector(DM_WIDTH-1 downto 0);
      ddr_dqs                : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      ddr_dqs_n              : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      ddr_dq                 : inout std_logic_vector(DQ_WIDTH-1 downto 0);
      dbg_idel_up_all        : in    std_logic;
      dbg_idel_down_all      : in    std_logic;
      dbg_idel_up_dq         : in    std_logic;
      dbg_idel_down_dq       : in    std_logic;
      dbg_idel_up_dqs        : in    std_logic;
      dbg_idel_down_dqs      : in    std_logic;
      dbg_idel_up_gate       : in    std_logic;
      dbg_idel_down_gate     : in    std_logic;
      dbg_sel_idel_dq        : in    std_logic_vector(DQ_BITS-1 downto 0);
      dbg_sel_all_idel_dq    : in    std_logic;
      dbg_sel_idel_dqs       : in    std_logic_vector(DQS_BITS downto 0);
      dbg_sel_all_idel_dqs   : in    std_logic;
      dbg_sel_idel_gate      : in    std_logic_vector(DQS_BITS downto 0);
      dbg_sel_all_idel_gate  : in    std_logic;
      dbg_calib_done         : out   std_logic_vector(3 downto 0);
      dbg_calib_err          : out   std_logic_vector(3 downto 0);
      dbg_calib_dq_tap_cnt   : out   std_logic_vector((6*DQ_WIDTH)-1 downto 0);
      dbg_calib_dqs_tap_cnt  : out   std_logic_vector((6*DQS_WIDTH)-1
                                                      downto 0);
      dbg_calib_gate_tap_cnt : out   std_logic_vector((6*DQS_WIDTH)-1
                                                      downto 0);
      dbg_calib_rd_data_sel  : out   std_logic_vector(DQS_WIDTH-1 downto 0);
      dbg_calib_rden_dly     : out   std_logic_vector((5*DQS_WIDTH)-1
                                                      downto 0);
      dbg_calib_gate_dly     : out   std_logic_vector((5*DQS_WIDTH)-1
                                                      downto 0));
  end component;

  component ddr2_usr_top
    generic (
      BANK_WIDTH    : integer;
      CS_BITS       : integer;
      COL_WIDTH     : integer;
      DQ_WIDTH      : integer;
      DQ_PER_DQS    : integer;
      ECC_ENABLE    : integer;
      APPDATA_WIDTH : integer;
      DQS_WIDTH     : integer;
      ROW_WIDTH     : integer);
    port (
      clk0               : in  std_logic;
      clk90              : in  std_logic;
      rst0               : in  std_logic;
      rd_data_in_rise    : in  std_logic_vector(DQ_WIDTH-1 downto 0);
      rd_data_in_fall    : in  std_logic_vector(DQ_WIDTH-1 downto 0);
      phy_calib_rden     : in  std_logic_vector(DQS_WIDTH-1 downto 0);
      phy_calib_rden_sel : in  std_logic_vector(DQS_WIDTH-1 downto 0);
      rd_data_valid      : out std_logic;
      rd_data_fifo_out   : out std_logic_vector(APPDATA_WIDTH-1 downto 0);
      app_af_cmd         : in  std_logic_vector(2 downto 0);
      app_af_addr        : in  std_logic_vector(30 downto 0);
      app_af_wren        : in  std_logic;
      ctrl_af_rden       : in  std_logic;
      af_cmd             : out std_logic_vector(2 downto 0);
      af_addr            : out std_logic_vector(30 downto 0);
      af_empty           : out std_logic;
      app_af_afull       : out std_logic;
      rd_ecc_error       : out std_logic_vector(1 downto 0);
      app_wdf_wren       : in  std_logic;
      app_wdf_data       : in  std_logic_vector(APPDATA_WIDTH-1 downto 0);
      app_wdf_mask_data  : in  std_logic_vector((APPDATA_WIDTH/8)-1 downto 0);
      wdf_rden           : in  std_logic;
      app_wdf_afull      : out std_logic;
      wdf_data           : out std_logic_vector((2*DQ_WIDTH)-1 downto 0);
      wdf_mask_data      : out std_logic_vector(((2*DQ_WIDTH)/8)-1 downto 0));
  end component;

  component ddr2_ctrl
    generic (
      BANK_WIDTH    : integer;
      COL_WIDTH     : integer;
      CS_BITS       : integer;
      CS_NUM        : integer;
      ROW_WIDTH     : integer;
      ADDITIVE_LAT  : integer;
      BURST_LEN     : integer;
      CAS_LAT       : integer;
      ECC_ENABLE    : integer;
      REG_ENABLE    : integer;
      TREFI_NS      : integer;
      TRAS          : integer;
      TRCD          : integer;
      TRFC          : integer;
      TRP           : integer;
      TRTP          : integer;
      TWR           : integer;
      TWTR          : integer;
      CLK_PERIOD    : integer;
      MULTI_BANK_EN : integer;
      TWO_T_TIME_EN : integer;
      DDR_TYPE      : integer);
    port (
      clk           : in  std_logic;
      rst           : in  std_logic;
      af_cmd        : in  std_logic_vector(2 downto 0);
      af_addr       : in  std_logic_vector(30 downto 0);
      af_empty      : in  std_logic;
      phy_init_done : in  std_logic;
      ctrl_ref_flag : out std_logic;
      ctrl_af_rden  : out std_logic;
      ctrl_wren     : out std_logic;
      ctrl_rden     : out std_logic;
      ctrl_addr     : out std_logic_vector(ROW_WIDTH-1 downto 0);
      ctrl_ba       : out std_logic_vector(BANK_WIDTH-1 downto 0);
      ctrl_ras_n    : out std_logic;
      ctrl_cas_n    : out std_logic;
      ctrl_we_n     : out std_logic;
      ctrl_cs_n     : out std_logic_vector(CS_NUM-1 downto 0));
  end component;

  signal af_addr            : std_logic_vector(30 downto 0);
  signal af_cmd             : std_logic_vector(2 downto 0);
  signal af_empty           : std_logic;
  signal ctrl_addr          : std_logic_vector(ROW_WIDTH-1 downto 0);
  signal ctrl_af_rden       : std_logic;
  signal ctrl_ba            : std_logic_vector(BANK_WIDTH-1 downto 0);
  signal ctrl_cas_n         : std_logic;
  signal ctrl_cs_n          : std_logic_vector(CS_NUM-1 downto 0);
  signal ctrl_ras_n         : std_logic;
  signal ctrl_rden          : std_logic;
  signal ctrl_ref_flag      : std_logic;
  signal ctrl_we_n          : std_logic;
  signal ctrl_wren          : std_logic;
  signal phy_calib_rden     : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal phy_calib_rden_sel : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rd_data_fall       : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal rd_data_rise       : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal wdf_data           : std_logic_vector((2*DQ_WIDTH)-1 downto 0);
  signal wdf_mask_data      : std_logic_vector(((2*DQ_WIDTH)/8)-1 downto 0);
  signal wdf_rden           : std_logic;

  signal i_phy_init_done   : std_logic;

begin

  --***************************************************************************

  u_phy_top : ddr2_phy_top
    generic map (
      BANK_WIDTH            => BANK_WIDTH,
      CKE_WIDTH             => CKE_WIDTH,
      CLK_WIDTH             => CLK_WIDTH,
      COL_WIDTH             => COL_WIDTH,
      CS_NUM                => CS_NUM,
      CS_WIDTH              => CS_WIDTH,
      USE_DM_PORT           => USE_DM_PORT,
      DM_WIDTH              => DM_WIDTH,
      DQ_WIDTH              => DQ_WIDTH,
      DQ_BITS               => DQ_BITS,
      DQ_PER_DQS            => DQ_PER_DQS,
      DQS_BITS              => DQS_BITS,
      DQS_WIDTH             => DQS_WIDTH,
      HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
      ODT_WIDTH             => ODT_WIDTH,
      ROW_WIDTH             => ROW_WIDTH,
      TWO_T_TIME_EN         => TWO_T_TIME_EN,
      ADDITIVE_LAT          => ADDITIVE_LAT,
      BURST_LEN             => BURST_LEN,
      BURST_TYPE            => BURST_TYPE,
      CAS_LAT               => CAS_LAT,
      ECC_ENABLE            => ECC_ENABLE,
      ODT_TYPE              => ODT_TYPE,
      DDR_TYPE              => DDR_TYPE,
      REDUCE_DRV            => REDUCE_DRV,
      REG_ENABLE            => REG_ENABLE,
      TWR                   => TWR,
      CLK_PERIOD            => CLK_PERIOD,
      SIM_ONLY              => SIM_ONLY,
      DEBUG_EN              => DEBUG_EN,
      DQS_IO_COL            => DQS_IO_COL,
      DQ_IO_MS              => DQ_IO_MS
    )
    port map (
      clk0                   => clk0,
      clk90                  => clk90,
      clkdiv0                => clkdiv0,
      rst0                   => rst0,
      rst90                  => rst90,
      rstdiv0                => rstdiv0,
      ctrl_wren              => ctrl_wren,
      ctrl_addr              => ctrl_addr,
      ctrl_ba                => ctrl_ba,
      ctrl_ras_n             => ctrl_ras_n,
      ctrl_cas_n             => ctrl_cas_n,
      ctrl_we_n              => ctrl_we_n,
      ctrl_cs_n              => ctrl_cs_n,
      ctrl_rden              => ctrl_rden,
      ctrl_ref_flag          => ctrl_ref_flag,
      wdf_data               => wdf_data,
      wdf_mask_data          => wdf_mask_data,
      wdf_rden               => wdf_rden,
      phy_init_done          => i_phy_init_done,
      phy_calib_rden         => phy_calib_rden,
      phy_calib_rden_sel     => phy_calib_rden_sel,
      rd_data_rise           => rd_data_rise,
      rd_data_fall           => rd_data_fall,
      ddr_ck                 => ddr_ck,
      ddr_ck_n               => ddr_ck_n,
      ddr_addr               => ddr_addr,
      ddr_ba                 => ddr_ba,
      ddr_ras_n              => ddr_ras_n,
      ddr_cas_n              => ddr_cas_n,
      ddr_we_n               => ddr_we_n,
      ddr_cs_n               => ddr_cs_n,
      ddr_cke                => ddr_cke,
      ddr_odt                => ddr_odt,
      ddr_dm                 => ddr_dm,
      ddr_dqs                => ddr_dqs,
      ddr_dqs_n              => ddr_dqs_n,
      ddr_dq                 => ddr_dq,
      dbg_idel_up_all        => dbg_idel_up_all,
      dbg_idel_down_all      => dbg_idel_down_all,
      dbg_idel_up_dq         => dbg_idel_up_dq,
      dbg_idel_down_dq       => dbg_idel_down_dq,
      dbg_idel_up_dqs        => dbg_idel_up_dqs,
      dbg_idel_down_dqs      => dbg_idel_down_dqs,
      dbg_idel_up_gate       => dbg_idel_up_gate,
      dbg_idel_down_gate     => dbg_idel_down_gate,
      dbg_sel_idel_dq        => dbg_sel_idel_dq,
      dbg_sel_all_idel_dq    => dbg_sel_all_idel_dq,
      dbg_sel_idel_dqs       => dbg_sel_idel_dqs,
      dbg_sel_all_idel_dqs   => dbg_sel_all_idel_dqs,
      dbg_sel_idel_gate      => dbg_sel_idel_gate,
      dbg_sel_all_idel_gate  => dbg_sel_all_idel_gate,
      dbg_calib_done         => dbg_calib_done,
      dbg_calib_err          => dbg_calib_err,
      dbg_calib_dq_tap_cnt   => dbg_calib_dq_tap_cnt,
      dbg_calib_dqs_tap_cnt  => dbg_calib_dqs_tap_cnt,
      dbg_calib_gate_tap_cnt => dbg_calib_gate_tap_cnt,
      dbg_calib_rd_data_sel  => dbg_calib_rd_data_sel,
      dbg_calib_rden_dly     => dbg_calib_rden_dly,
      dbg_calib_gate_dly     => dbg_calib_gate_dly
      );

  u_usr_top : ddr2_usr_top
    generic map (
      BANK_WIDTH    => BANK_WIDTH,
      COL_WIDTH     => COL_WIDTH,
      CS_BITS       => CS_BITS,
      DQ_WIDTH      => DQ_WIDTH,
      DQ_PER_DQS    => DQ_PER_DQS,
      DQS_WIDTH     => DQS_WIDTH,
      ECC_ENABLE    => ECC_ENABLE,
      APPDATA_WIDTH => APPDATA_WIDTH,
      ROW_WIDTH     => ROW_WIDTH
    )
    port map (
      clk0                => clk0,
      clk90               => clk90,
      rst0                => rst0,
      rd_data_in_rise     => rd_data_rise,
      rd_data_in_fall     => rd_data_fall,
      phy_calib_rden      => phy_calib_rden,
      phy_calib_rden_sel  => phy_calib_rden_sel,
      rd_data_valid       => rd_data_valid,
      rd_ecc_error        => rd_ecc_error,
      rd_data_fifo_out    => rd_data_fifo_out,
      app_af_cmd          => app_af_cmd,
      app_af_addr         => app_af_addr,
      app_af_wren         => app_af_wren,
      ctrl_af_rden        => ctrl_af_rden,
      af_cmd              => af_cmd,
      af_addr             => af_addr,
      af_empty            => af_empty,
      app_af_afull        => app_af_afull,
      app_wdf_wren        => app_wdf_wren,
      app_wdf_data        => app_wdf_data,
      app_wdf_mask_data   => app_wdf_mask_data,
      wdf_rden            => wdf_rden,
      app_wdf_afull       => app_wdf_afull,
      wdf_data            => wdf_data,
      wdf_mask_data       => wdf_mask_data
      );

  u_ctrl : ddr2_ctrl
    generic map (
      BANK_WIDTH     => BANK_WIDTH,
      COL_WIDTH      => COL_WIDTH,
      CS_BITS        => CS_BITS,
      CS_NUM         => CS_NUM,
      ROW_WIDTH      => ROW_WIDTH,
      ADDITIVE_LAT   => ADDITIVE_LAT,
      BURST_LEN      => BURST_LEN,
      CAS_LAT        => CAS_LAT,
      ECC_ENABLE     => ECC_ENABLE,
      REG_ENABLE     => REG_ENABLE,
      MULTI_BANK_EN  => MULTI_BANK_EN,
      TWO_T_TIME_EN  => TWO_T_TIME_EN,
      TREFI_NS       => TREFI_NS,
      TRAS           => TRAS,
      TRCD           => TRCD,
      TRFC           => TRFC,
      TRP            => TRP,
      TRTP           => TRTP,
      TWR            => TWR,
      TWTR           => TWTR,
      CLK_PERIOD     => CLK_PERIOD,
      DDR_TYPE       => DDR_TYPE
      )
    port map (
      clk            => clk0,
      rst            => rst0,
      af_cmd         => af_cmd,
      af_addr        => af_addr,
      af_empty       => af_empty,
      phy_init_done  => i_phy_init_done,
      ctrl_ref_flag  => ctrl_ref_flag,
      ctrl_af_rden   => ctrl_af_rden,
      ctrl_wren      => ctrl_wren,
      ctrl_rden      => ctrl_rden,
      ctrl_addr      => ctrl_addr,
      ctrl_ba        => ctrl_ba,
      ctrl_ras_n     => ctrl_ras_n,
      ctrl_cas_n     => ctrl_cas_n,
      ctrl_we_n      => ctrl_we_n,
      ctrl_cs_n      => ctrl_cs_n
    );

  phy_init_done <= i_phy_init_done;

end architecture syn;


