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
--  /   /         Filename: ddr2_phy_init.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/07/29 15:24:03 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR/DDR2
--Purpose:
--Reference:
--   This module is the intialization control logic of the memory interface.
--   All commands are issued from here acoording to the burst, CAS Latency and
--   the user commands.
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_phy_init is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference 
    -- board design). Actual values may be different. Actual parameters values 
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    BANK_WIDTH               : integer := 2;
    CKE_WIDTH                : integer := 1;
    COL_WIDTH                : integer := 10;
    CS_NUM                   : integer := 1;
    DQ_WIDTH                 : integer := 72;
    ODT_WIDTH                : integer := 1;
    ROW_WIDTH                : integer := 14;
    ADDITIVE_LAT             : integer := 0;
    BURST_LEN                : integer := 4;
    TWO_T_TIME_EN            : integer := 0;
    BURST_TYPE               : integer := 0;
    CAS_LAT                  : integer := 5;
    ODT_TYPE                 : integer := 1;
    REDUCE_DRV               : integer := 0;
    REG_ENABLE               : integer := 1;
    TWR                      : integer := 15000;
    CLK_PERIOD               : integer := 3000;
    DDR_TYPE                 : integer := 1;
    SIM_ONLY                 : integer := 0
  );
  port (
    clk0                     : in std_logic;
    clkdiv0                  : in std_logic;
    rst0                     : in std_logic;
    rstdiv0                  : in std_logic;
    calib_done               : in std_logic_vector(3 downto 0);
    ctrl_ref_flag            : in std_logic;
    calib_ref_req            : in  std_logic;
    calib_start              : out std_logic_vector(3 downto 0);
    calib_ref_done           : out std_logic;
    phy_init_wren            : out std_logic;
    phy_init_rden            : out std_logic;
    phy_init_addr            : out std_logic_vector(ROW_WIDTH-1 downto 0);
    phy_init_ba              : out std_logic_vector(BANK_WIDTH-1 downto 0);
    phy_init_ras_n           : out std_logic;
    phy_init_cas_n           : out std_logic;
    phy_init_we_n            : out std_logic;
    phy_init_cs_n            : out std_logic_vector(CS_NUM-1 downto 0);
    phy_init_cke             : out std_logic_vector(CKE_WIDTH-1 downto 0);
    phy_init_done            : out std_logic;
    phy_init_data_sel        : out std_logic
  );
end entity ddr2_phy_init;

architecture syn of ddr2_phy_init is

  function and_br (val : std_logic_vector) return std_logic is
    variable rtn : std_logic := '1';
  begin
    for index in val'range loop
      rtn := rtn and val(index);
    end loop;
    return(rtn);
  end and_br;

  function CALC_WR_REC_CYC return integer is
  begin
    return (TWR+CLK_PERIOD-1)/CLK_PERIOD;
  end function CALC_WR_REC_CYC;

  -- time to wait between consecutive commands in PHY_INIT - this is a
  -- generic number, and must be large enough to account for worst case
  -- timing parameter (tRFC - refresh-to-active) across all memory speed
  -- grades and operating frequencies. Expressed in CLKDIV clock cycles.
  constant CNTNEXT_CMD : unsigned(6 downto 0) := "1111111";
  -- time to wait between read and read or precharge for stage 3 & 4
  -- the larger CNTNEXT_CMD can also be used, use smaller number to
  -- speed up calibration - avoid tRAS violation, and speeds up simulation
  constant CNTNEXT_RD  : unsigned(3 downto 0) := "1111";
  -- Write recovery (WR) time - is defined by 
  -- tWR (in nanoseconds) by tCK (in nanoseconds) and rounding up a 
  -- noninteger value to the next integer
  constant WR_RECOVERY : integer :=  CALC_WR_REC_CYC;

  type INIT_STATE_TYPE is (INIT_CAL1_READ,
                           INIT_CAL2_READ,
                           INIT_CAL3_READ,
                           INIT_CAL4_READ,
                           INIT_CAL1_WRITE,
                           INIT_CAL2_WRITE,
                           INIT_CAL3_WRITE,
                           INIT_DUMMY_ACTIVE_WAIT,
                           INIT_PRECHARGE,
                           INIT_LOAD_MODE,
                           INIT_AUTO_REFRESH,
                           INIT_IDLE,
                           INIT_CNT_200,
                           INIT_CNT_200_WAIT,
                           INIT_PRECHARGE_WAIT,
                           INIT_MODE_REGISTER_WAIT,
                           INIT_AUTO_REFRESH_WAIT,
                           INIT_DEEP_MEMORY_ST,
                           INIT_DUMMY_ACTIVE,
                           INIT_CAL1_WRITE_READ,
                           INIT_CAL1_READ_WAIT,
                           INIT_CAL2_WRITE_READ,
                           INIT_CAL2_READ_WAIT,
                           INIT_CAL3_WRITE_READ,
                           INIT_CAL3_READ_WAIT,
                           INIT_CAL4_READ_WAIT,
                           INIT_CALIB_REF,
                           INIT_ZQCL,
                           INIT_WAIT_DLLK_ZQINIT);

  constant INIT_CNTR_INIT         : unsigned(3 downto 0) := X"0";
  constant INIT_CNTR_PRECH_1      : unsigned(3 downto 0) := X"1";
  constant INIT_CNTR_EMR2_INIT    : unsigned(3 downto 0) := X"2";
  constant INIT_CNTR_EMR3_INIT    : unsigned(3 downto 0) := X"3";
  constant INIT_CNTR_EMR_EN_DLL   : unsigned(3 downto 0) := X"4";
  constant INIT_CNTR_MR_RST_DLL   : unsigned(3 downto 0) := X"5";
  constant INIT_CNTR_CNT_200_WAIT : unsigned(3 downto 0) := X"6";
  constant INIT_CNTR_PRECH_2      : unsigned(3 downto 0) := X"7";
  constant INIT_CNTR_AR_1         : unsigned(3 downto 0) := X"8";
  constant INIT_CNTR_AR_2         : unsigned(3 downto 0) := X"9";
  constant INIT_CNTR_MR_ACT_DLL   : unsigned(3 downto 0) := X"A";
  constant INIT_CNTR_EMR_DEF_OCD  : unsigned(3 downto 0) := X"B";
  constant INIT_CNTR_EMR_EXIT_OCD : unsigned(3 downto 0) := X"C";
  constant INIT_CNTR_DEEP_MEM     : unsigned(3 downto 0) := X"D";
  constant INIT_CNTR_PRECH_3      : unsigned(3 downto 0) := X"E";
  constant INIT_CNTR_DONE         : unsigned(3 downto 0) := X"F";

  constant DDR1 : integer := 0;
  constant DDR2 : integer := 1;
  constant DDR3 : integer := 2;

  signal burst_addr_r          : unsigned(1 downto 0);
  signal burst_cnt_r           : unsigned(1 downto 0);
  signal burst_val             : unsigned(1 downto 0);
  signal cal_read              : std_logic;
  signal cal_write             : std_logic;
  signal cal_write_read        : std_logic;
  signal cal1_started_r        : std_logic;
  signal cal2_started_r        : std_logic;
  signal cal4_started_r        : std_logic;
  signal calib_done_r          : std_logic_vector(3 downto 0);
  signal calib_ref_req_posedge : std_logic;
  signal calib_ref_req_r       : std_logic;
  signal calib_start_shift0_r  : std_logic_vector(15 downto 0);
  signal calib_start_shift1_r  : std_logic_vector(15 downto 0);
  signal calib_start_shift2_r  : std_logic_vector(15 downto 0);
  signal calib_start_shift3_r  : std_logic_vector(15 downto 0);
  signal chip_cnt_r            : unsigned(1 downto 0);
  signal cke_200us_cnt_r       : unsigned(4 downto 0);
  signal cke_200us_cnt_en_r    : std_logic;
  signal cnt_200_cycle_r       : unsigned(7 downto 0);
  signal cnt_200_cycle_done_r  : std_logic;
  signal cnt_cmd_r             : unsigned(6 downto 0);
  signal cnt_cmd_ok_r          : std_logic;
  signal cnt_rd_r              : unsigned(3 downto 0);
  signal cnt_rd_ok_r           : std_logic;
  signal ctrl_ref_flag_r       : std_logic;
  signal done_200us_r          : std_logic;
  signal ddr_addr_r            : std_logic_vector(ROW_WIDTH-1 downto 0);
  signal ddr_addr_r1           : std_logic_vector(ROW_WIDTH-1 downto 0);
  signal ddr_ba_r              : std_logic_vector(BANK_WIDTH-1 downto 0);
  signal ddr_ba_r1             : std_logic_vector(BANK_WIDTH-1 downto 0);
  signal ddr_cas_n_r           : std_logic;
  signal ddr_cas_n_r1          : std_logic;
  signal ddr_cke_r             : std_logic_vector(CKE_WIDTH-1 downto 0);
  signal ddr_cs_n_r            : std_logic_vector(CS_NUM-1 downto 0);
  signal ddr_cs_n_r1           : std_logic_vector(CS_NUM-1 downto 0);
  signal ddr_cs_disable_r      : std_logic_vector(CS_NUM-1 downto 0);
  signal ddr_ras_n_r           : std_logic;
  signal ddr_ras_n_r1          : std_logic;
  signal ddr_we_n_r            : std_logic;
  signal ddr_we_n_r1           : std_logic;
  signal ext_mode_reg          : std_logic_vector(15 downto 0);
  signal init_cnt_r            : unsigned(3 downto 0);
  signal init_done_r           : std_logic;
  signal init_next_state       : INIT_STATE_TYPE;
  signal init_state_r          : INIT_STATE_TYPE;
  signal init_state_r1         : INIT_STATE_TYPE;
  signal init_state_r2         : INIT_STATE_TYPE;
  signal load_mode_reg         : std_logic_vector(15 downto 0);
  signal load_mode_reg0        : std_logic_vector(15 downto 0);
  signal load_mode_reg1        : std_logic_vector(15 downto 0);
  signal load_mode_reg2        : std_logic_vector(15 downto 0);
  signal load_mode_reg3        : std_logic_vector(15 downto 0);
  signal phy_init_done_r       : std_logic;
  signal phy_init_done_r1      : std_logic;
  signal phy_init_done_r2      : std_logic;
  signal phy_init_done_r3      : std_logic;
  signal refresh_req           : std_logic;
  signal start_cal             : std_logic_vector(3 downto 0);

  signal i_calib_start        : std_logic_vector(3 downto 0);
  signal i_phy_init_done      : std_logic;

  attribute syn_preserve : boolean;
  attribute syn_replicate : boolean;
  attribute syn_preserve of u_ff_phy_init_data_sel : label is true;
  attribute syn_replicate of u_ff_phy_init_data_sel : label is false;

begin

  phy_init_done <= i_phy_init_done;
  calib_start <= i_calib_start;

  --***************************************************************************

  --*****************************************************************
  -- DDR1 and DDR2 Load mode register
  -- Mode Register (MR):
  --   [15:14] - unused          - 00
  --   [13]    - reserved        - 0
  --   [12]    - Power-down mode - 0 (normal)
  --   [11:9]  - write recovery  - for Auto Precharge (tWR/tCK)
  --   [8]     - DLL reset       - 0 or 1
  --   [7]     - Test Mode       - 0 (normal)
  --   [6:4]   - CAS latency     - CAS_LAT
  --   [3]     - Burst Type      - BURST_TYPE
  --   [2:0]   - Burst Length    - BURST_LEN
  --*****************************************************************

  gen_load_mode_reg_ddr2: if (DDR_TYPE = DDR2) generate
    load_mode_reg(2 downto 0)  <= "011" when (BURST_LEN = 8) else
                                  "010" when (BURST_LEN = 4) else
                                  "111";
    load_mode_reg(3) <= '1' when (BURST_TYPE = 1) else '0';
    load_mode_reg(6 downto 4)  <= "011" when (CAS_LAT = 3) else
                                  "100" when (CAS_LAT = 4) else
                                  "101" when (CAS_LAT = 5) else
                                  "111";
    load_mode_reg(7)            <= '0';
    load_mode_reg(8)            <= '0'; -- init value only (DLL not reset)
    load_mode_reg(11 downto 9)  <= "101" when (WR_RECOVERY = 6) else
                                   "100" when (WR_RECOVERY = 5) else
				   "011" when (WR_RECOVERY = 4) else
				   "010" when (WR_RECOVERY = 3) else
				   "001";
    load_mode_reg(15 downto 12) <= "0000";
  end generate;

  gen_load_mode_reg_ddr1: if (DDR_TYPE = DDR1) generate
    load_mode_reg(2 downto 0)   <= "011" when (BURST_LEN = 8) else
                                   "010" when (BURST_LEN = 4) else
                                   "001" when (BURST_LEN = 2) else
                                   "111";
    load_mode_reg(3)            <= '1' when (BURST_TYPE = 1) else '0';
    load_mode_reg(6 downto 4)   <= "010" when (CAS_LAT = 2) else
                                   "011" when (CAS_LAT = 3) else
                                   "110" when (CAS_LAT = 25) else
                                   "111";
    load_mode_reg(12 downto 7)  <= "000000";            -- init value only
    load_mode_reg(15 downto 13) <= "000";
  end generate;

  --*****************************************************************
  -- DDR1 and DDR2 ext mode register
  -- Extended Mode Register (MR):
  --   [15:14] - unused          - 00
  --   [13]    - reserved        - 0
  --   [12]    - output enable   - 0 (enabled)
  --   [11]    - RDQS enable     - 0 (disabled)
  --   [10]    - DQS# enable     - 0 (enabled)
  --   [9:7]   - OCD Program     - 111 or 000 (first 111, then 000 during init)
  --   [6]     - RTT[1]          - RTT[1:0] = 0(no ODT), 1(75), 2(150), 3(50)
  --   [5:3]   - Additive CAS    - ADDITIVE_CAS
  --   [2]     - RTT[0]
  --   [1]     - Output drive    - REDUCE_DRV (= 0(full), = 1 (reduced)
  --   [0]     - DLL enable      - 0 (normal)
  --*****************************************************************

  gen_ext_mode_reg_ddr2: if (DDR_TYPE = DDR2) generate
    ext_mode_reg(0) <= '0';
    ext_mode_reg(1) <= '1' when (REDUCE_DRV = 1) else '0';
    ext_mode_reg(2) <= '1' when ((ODT_TYPE = 1) or (ODT_TYPE = 3)) else '0';
    ext_mode_reg(5 downto 3) <= "000" when (ADDITIVE_LAT = 0) else
                                "001" when (ADDITIVE_LAT = 1) else
                                "010" when (ADDITIVE_LAT = 2) else
                                "011" when (ADDITIVE_LAT = 3) else
                                "100" when (ADDITIVE_LAT = 4) else
                                "111";
    ext_mode_reg(6) <= '1' when ((ODT_TYPE = 2) or (ODT_TYPE = 3)) else '0';
    ext_mode_reg(9 downto 7) <= "000";
    ext_mode_reg(10) <= '0';
    ext_mode_reg(15 downto 10) <= "000000";
  end generate;

  gen_ext_mode_reg_ddr1: if (DDR_TYPE = DDR1) generate
    ext_mode_reg(0) <= '0';
    ext_mode_reg(1) <= '1' when (REDUCE_DRV = 1) else '0';
    ext_mode_reg(12 downto 2) <= "00000000000";
    ext_mode_reg(15 downto 13) <= "000";
  end generate;

  --*****************************************************************
  -- DDR3 Load mode reg0
  -- Mode Register (MR0):
  --   [15:13] - unused          - 000
  --   [12]    - Precharge Power-down DLL usage - 0 (DLL frozen, slow-exit),
  --             1 (DLL maintained)
  --   [11:9]  - write recovery for Auto Precharge (tWR/tCK = 6)
  --   [8]     - DLL reset       - 0 or 1
  --   [7]     - Test Mode       - 0 (normal)
  --   [6:4],[2]   - CAS latency     - CAS_LAT
  --   [3]     - Burst Type      - BURST_TYPE
  --   [1:0]   - Burst Length    - BURST_LEN
  --*****************************************************************

  gen_load_mode_reg0_ddr3: if (DDR_TYPE = DDR3) generate
    load_mode_reg0(1 downto 0) <= "00" when (BURST_LEN = 8) else
                                  "10" when (BURST_LEN = 4) else
                                  "11";
    -- Part of CAS latency. This bit is '0' for all CAS latencies
    load_mode_reg0(2) <= '0';
    load_mode_reg0(3) <= '1' when (BURST_TYPE = 1) else '0';
    load_mode_reg0(6 downto 4) <= "001" when (CAS_LAT = 5) else
                                  "010" when (CAS_LAT = 6) else
                                  "111";
    load_mode_reg0(7) <= '0';
    -- init value only (DLL reset)
    load_mode_reg0(8) <= '1';
    load_mode_reg0(11 downto 9) <= "010";
    -- Precharge Power-Down DLL 'slow-exit'
    load_mode_reg0(12) <= '0';
    load_mode_reg0(15 downto 13) <= "000";
  end generate;

  --*****************************************************************
  -- DDR3 Load mode reg1
  -- Mode Register (MR1):
  --   [15:13] - unused          - 00
  --   [12]    - output enable   - 0 (enabled for DQ, DQS, DQS#)
  --   [11]    - TDQS enable     - 0 (TDQS disabled and DM enabled)
  --   [10]    - reserved   - 0 (must be '0')
  --   [9]     - RTT[2]     - 0
  --   [8]     - reserved   - 0 (must be '0')
  --   [7]     - write leveling - 0 (disabled), 1 (enabled)
  --   [6]     - RTT[1]          - RTT[1:0] = 0(no ODT), 1(75), 2(150), 3(50)
  --   [5]     - Output driver impedance[1] - 0 (RZQ/6 and RZQ/7)
  --   [4:3]   - Additive CAS    - ADDITIVE_CAS
  --   [2]     - RTT[0]
  --   [1]     - Output driver impedance[0] - 0(RZQ/6), or 1 (RZQ/7)
  --   [0]     - DLL enable      - 0 (normal)
  --*****************************************************************

  gen_ext_mode_reg1_ddr3: if (DDR_TYPE = DDR3) generate
    -- DLL enabled during Imitialization
    load_mode_reg1(0) <= '0';
    -- RZQ/6
    load_mode_reg1(1) <= '1' when (REDUCE_DRV = 1) else '0';
    load_mode_reg1(2) <= '1' when ((ODT_TYPE = 1) or (ODT_TYPE = 3)) else '0';
    load_mode_reg1(4 downto 3) <= "00" when (ADDITIVE_LAT = 0) else
                                  "01" when (ADDITIVE_LAT = 1) else
                                  "10" when (ADDITIVE_LAT = 2) else
                                  "11";
    -- RZQ/6
    load_mode_reg1(5) <= '0';
    load_mode_reg1(6) <= '1' when ((ODT_TYPE = 2) or (ODT_TYPE = 3)) else '0';
    -- Make zero WRITE_LEVEL
    load_mode_reg1(7) <= '0';
    load_mode_reg1(8) <= '0';
    load_mode_reg1(9) <= '0';
    load_mode_reg1(10) <= '0';
    load_mode_reg1(15 downto 11) <= "00000";
  end generate;

  --*****************************************************************
  -- DDR3 Load mode reg2
  -- Mode Register (MR2):
  --   [15:11] - unused     - 00
  --   [10:9]  - RTT_WR     - 00 (Dynamic ODT off)
  --   [8]     - reserved   - 0 (must be '0')
  --   [7]     - self-refresh temperature range -
  --               0 (normal), 1 (extended)
  --   [6]     - Auto Self-Refresh - 0 (manual), 1(auto)
  --   [5:3]   - CAS Write Latency (CWL) -
  --               000 (5 for 400 MHz device),
  --               001 (6 for 400 MHz to 533 MHz devices),
  --               010 (7 for 533 MHz to 667 MHz devices),
  --               011 (8 for 667 MHz to 800 MHz)
  --   [2:0]   - Partial Array Self-Refresh (Optional)      -
  --               000 (full array)
  --*****************************************************************

  gen_ext_mode_reg2_ddr3: if (DDR_TYPE = DDR3) generate
    load_mode_reg2(2 downto 0) <= "000";
    load_mode_reg2(5 downto 3) <= "000" when (CAS_LAT = 5) else
                                  "001" when (CAS_LAT = 6) else
                                  "111";
    load_mode_reg2(6) <= '0';           -- Manual Self-Refresh
    load_mode_reg2(7) <= '0';
    load_mode_reg2(8) <= '0';
    load_mode_reg2(10 downto 9) <= "00";
    load_mode_reg2(15 downto 11) <= "00000";
  end generate;

  --*****************************************************************
  -- DDR3 Load mode reg3
  -- Mode Register (MR3):
  --   [15:3] - unused          - All zeros
  --   [2]     - MPR Operation - 0(normal operation), 1(data flow from MPR)
  --   [1:0]   - MPR location     - 00 (Predefined pattern)
  --*****************************************************************

  gen_ext_mode_reg3_ddr3: if (DDR_TYPE = DDR3) generate
    load_mode_reg3(1 downto 0) <= "00";
    load_mode_reg3(2) <= '0';
    load_mode_reg3(15 downto 3) <= "0000000000000";
  end generate;

  --***************************************************************************
  -- Logic for calibration start, and for auto-refresh during cal request
  -- CALIB_REF_REQ is used by calibration logic to request auto-refresh
  -- durign calibration (used to avoid tRAS violation is certain calibration
  -- stages take a long time). Once the auto-refresh is complete and cal can
  -- be resumed, CALIB_REF_DONE is asserted by PHY_INIT.
  --***************************************************************************

  -- generate pulse for each of calibration start controls
  start_cal(0) <= '1' when ((init_state_r1 = INIT_CAL1_READ) and
                            (init_state_r2 /= INIT_CAL1_READ)) else '0';
  start_cal(1) <= '1' when ((init_state_r1 = INIT_CAL2_READ) and
                            (init_state_r2 /= INIT_CAL2_READ)) else '0';
  start_cal(2) <= '1' when ((init_state_r1 = INIT_CAL3_READ) and
                            (init_state_r2 = INIT_CAL3_WRITE_READ)) else '0';
  start_cal(3) <= '1' when ((init_state_r1 = INIT_CAL4_READ) and
                            (init_state_r2 = INIT_DUMMY_ACTIVE_WAIT)) else '0';

  -- Generate positive-edge triggered, latched signal to force initialization
  -- to pause calibration, and to issue auto-refresh. Clear flag as soon as
  -- refresh initiated
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (rstdiv0 = '1') then
        calib_ref_req_r       <= '0';
        calib_ref_req_posedge <= '0';
        refresh_req           <= '0';
      else
        calib_ref_req_r       <= calib_ref_req;
        calib_ref_req_posedge <= calib_ref_req and not(calib_ref_req_r);
        if (init_state_r1 = INIT_AUTO_REFRESH) then
          refresh_req <= '0';
        elsif (calib_ref_req_posedge = '1') then
          refresh_req <= '1';
        end if;
      end if;
    end if;
  end process;

  -- flag to tell cal1 calibration was started.
  -- This flag is used for cal1 auto refreshes
  -- some of these bits may not be needed - only needed for those stages that
  -- need refreshes within the stage (i.e. very long stages)
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (rstdiv0 = '1') then
        cal1_started_r <= '0';
        cal2_started_r <= '0';
        cal4_started_r <= '0';
      else
        if (i_calib_start(0) = '1') then
          cal1_started_r <= '1';
        end if;
        if (i_calib_start(1) = '1') then
          cal2_started_r <= '1';
        end if;
        if (i_calib_start(3) = '1') then
          cal4_started_r <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Delay start of each calibration by 16 clock cycles to
  -- ensure that when calibration logic begins, that read data is already
  -- appearing on the bus. Don't really need it, it's more for simulation
  -- purposes. Each circuit should synthesize using an SRL16.
  -- In first stage of calibration  periodic auto refreshes
  -- will be issued to meet memory timing. calib_start_shift0_r[15] will be
  -- asserted more than once.calib_start[0] is anded with cal1_started_r so
  -- that it is asserted only once. cal1_refresh_done is anded with
  -- cal1_started_r so that it is asserted after the auto refreshes.
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      calib_start_shift0_r <= (calib_start_shift0_r(14 downto 0) &
                               start_cal(0));
      calib_start_shift1_r <= (calib_start_shift1_r(14 downto 0) &
                               start_cal(1));
      calib_start_shift2_r <= (calib_start_shift2_r(14 downto 0) &
                               start_cal(2));
      calib_start_shift3_r <= (calib_start_shift3_r(14 downto 0) &
                               start_cal(3));
      i_calib_start(0) <= calib_start_shift0_r(15) and not(cal1_started_r);
      i_calib_start(1) <= calib_start_shift1_r(15) and not(cal2_started_r);
      i_calib_start(2) <= calib_start_shift2_r(15);
      i_calib_start(3) <= calib_start_shift3_r(15) and not(cal4_started_r);
      calib_ref_done <= calib_start_shift0_r(15) or
                        calib_start_shift1_r(15) or
                        calib_start_shift3_r(15);
    end if;
  end process;

  -- generate delay for various states that require it (no maximum delay
  -- requirement, make sure that terminal count is large enough to cover
  -- all cases)
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      case (init_state_r) is
        when INIT_PRECHARGE_WAIT |
             INIT_MODE_REGISTER_WAIT |
             INIT_AUTO_REFRESH_WAIT |
             INIT_DUMMY_ACTIVE_WAIT |
             INIT_CAL1_WRITE_READ |
             INIT_CAL1_READ_WAIT |
             INIT_CAL2_WRITE_READ |
             INIT_CAL2_READ_WAIT |
             INIT_CAL3_WRITE_READ =>
          cnt_cmd_r <= cnt_cmd_r + 1;
        when others =>
          cnt_cmd_r <= (others => '0');
      end case;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (cnt_cmd_r = CNTNEXT_CMD) then
        cnt_cmd_ok_r <= '1';
      else
        cnt_cmd_ok_r <= '0';
      end if;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      case (init_state_r) is
        when INIT_CAL3_READ_WAIT |
             INIT_CAL4_READ_WAIT =>
          cnt_rd_r <= cnt_rd_r + 1;
        when others =>
          cnt_rd_r <= (others => '0');
      end case;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (cnt_rd_r = CNTNEXT_RD) then
        cnt_rd_ok_r <= '1';
      else
        cnt_rd_ok_r <= '0';
      end if;
    end if;
  end process;

  --***************************************************************************
  -- Initial delay after power-on
  --***************************************************************************

  -- register the refresh flag from the controller.
  -- The refresh flag is in full frequency domain - so a pulsed version must
  -- be generated for half freq domain using 2 consecutive full clk cycles
  process (clk0)
  begin
    if (rising_edge(clk0)) then
      ctrl_ref_flag_r <= ctrl_ref_flag;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      cke_200us_cnt_en_r <= ctrl_ref_flag or ctrl_ref_flag_r;
    end if;
  end process;

  -- 200us counter for cke
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (rstdiv0 = '1') then
        -- skip power-up count if only simulating
        if (SIM_ONLY /= 0) then
          cke_200us_cnt_r <= "00001";
        else
          cke_200us_cnt_r <= "11011";
        end if;
      elsif (cke_200us_cnt_en_r = '1') then
        cke_200us_cnt_r <= cke_200us_cnt_r - 1;
      end if;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (rstdiv0 = '1') then
        done_200us_r <= '0';
      elsif (done_200us_r = '0') then
        if (cke_200us_cnt_r = "00000") then
          done_200us_r <= '1';
        else
          done_200us_r <= '0';
        end if;
      end if;
    end if;
  end process;

  -- 200 clocks counter - count value : h'64 required for initialization
  -- Counts 100 divided by two clocks
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if ((rstdiv0 = '1') or (init_state_r = INIT_CNT_200)) then
        cnt_200_cycle_r <= X"64";
      elsif (init_state_r = INIT_ZQCL) then  -- ddr3
        cnt_200_cycle_r <= X"C8";
      elsif (cnt_200_cycle_r /= X"00") then
        cnt_200_cycle_r <= cnt_200_cycle_r - 1;
      end if;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if ((rstdiv0 = '1') or (init_state_r = INIT_CNT_200) or
          (init_state_r = INIT_ZQCL)) then
        cnt_200_cycle_done_r <= '0';
      elsif (cnt_200_cycle_r = X"00") then
        cnt_200_cycle_done_r <= '1';
      end if;
    end if;
  end process;

  --*****************************************************************
  --   handle deep memory configuration:
  --   During initialization: Repeat initialization sequence once for each
  --   chip select. Note that we could perform initalization for all chip
  --   selects simulataneously. Probably fine - any potential SI issues with
  --   auto refreshing all chip selects at once?
  --   Once initialization complete, assert only CS[0] for calibration.
  --*****************************************************************

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (rstdiv0 = '1') then
        chip_cnt_r <= "00";
      elsif (init_state_r = INIT_DEEP_MEMORY_ST) then
        if (chip_cnt_r /= to_unsigned(CS_NUM,2)) then
          chip_cnt_r <= chip_cnt_r + 1;
        else
          chip_cnt_r <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (rstdiv0 = '1') then
        ddr_cs_n_r <= (others => '1');
      else
        ddr_cs_n_r <= (others => '1');
        if ((init_state_r = INIT_DUMMY_ACTIVE) or
            (init_state_r = INIT_PRECHARGE) or
            (init_state_r = INIT_LOAD_MODE) or
            (init_state_r = INIT_AUTO_REFRESH) or
            (init_state_r  = INIT_ZQCL    ) or
            (((init_state_r = INIT_CAL1_READ) or
              (init_state_r = INIT_CAL2_READ) or
              (init_state_r = INIT_CAL3_READ) or
              (init_state_r = INIT_CAL4_READ) or
              (init_state_r = INIT_CAL1_WRITE) or
              (init_state_r = INIT_CAL2_WRITE) or
              (init_state_r = INIT_CAL3_WRITE)) and
             (burst_cnt_r = "00"))) then
          ddr_cs_n_r(to_integer(chip_cnt_r)) <= '0';
        else
          ddr_cs_n_r(to_integer(chip_cnt_r)) <= '1';
        end if;
      end if;
    end if;
  end process;

  --***************************************************************************
  -- Write/read burst logic
  --***************************************************************************

  cal_write <= '1' when ((init_state_r = INIT_CAL1_WRITE) or
                         (init_state_r = INIT_CAL2_WRITE) or
                         (init_state_r = INIT_CAL3_WRITE)) else '0';
  cal_read <= '1' when ((init_state_r = INIT_CAL1_READ) or
                        (init_state_r = INIT_CAL2_READ) or
                        (init_state_r = INIT_CAL3_READ) or
                        (init_state_r = INIT_CAL4_READ)) else '0';
  cal_write_read <= '1' when ((init_state_r = INIT_CAL1_READ) or
                              (init_state_r = INIT_CAL2_READ) or
                              (init_state_r = INIT_CAL3_READ) or
                              (init_state_r = INIT_CAL4_READ) or
                              (init_state_r = INIT_CAL1_WRITE) or
                              (init_state_r = INIT_CAL2_WRITE) or
                              (init_state_r = INIT_CAL3_WRITE)) else '0';

  burst_val <= "00" when (BURST_LEN = 4) else
               "01" when (BURST_LEN = 8) else
               "00";

  -- keep track of current address - need this if burst length < 8 for
  -- stage 2-4 calibration writes and reads. Make sure value always gets
  -- initialized to 0 before we enter write/read state. This is used to
  -- keep track of when another burst must be issued
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (cal_write_read = '1') then
        burst_addr_r <= burst_addr_r + 2;
      else
        burst_addr_r <= (others => '0');
      end if;
    end if;
  end process;

  -- write/read burst count
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (cal_write_read = '1') then
        if (burst_cnt_r = "00") then
          burst_cnt_r <= burst_val;
        else          -- SHOULD THIS BE -2 CHECK THIS LOGIC
          burst_cnt_r <= burst_cnt_r - 1;
        end if;
      else
        burst_cnt_r <= (others => '0');
      end if;
    end if;
  end process;

  -- indicate when a write is occurring
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      -- MIG 2.1: Remove (burst_addr_r<4) term - not used 
      -- if ((cal_write = '1') and (burst_addr_r < "100")) then
      if (cal_write = '1') then
        phy_init_wren <= '1';
      else
        phy_init_wren <= '0';
      end if;
    end if;
  end process;

  -- used for read enable calibration, pulse to indicate when read issued
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      -- MIG 2.1: Remove (burst_addr_r<4) term - not used       
      -- if ((cal_read = '1') and (burst_addr_r < "100")) then
      if (cal_read = '1') then
        phy_init_rden <= '1';
      else
        phy_init_rden <= '0';
      end if;
    end if;
  end process;

  --***************************************************************************
  -- Initialization state machine
  --***************************************************************************

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      -- every time we need to initialize another rank of memory, need to
      -- reset init count, and repeat the entire initialization (but not
      -- calibration) sequence
      if ((rstdiv0 = '1') or (init_state_r = INIT_DEEP_MEMORY_ST)) then
        init_cnt_r <= INIT_CNTR_INIT;
      elsif ((DDR_TYPE = DDR1) and (init_state_r = INIT_PRECHARGE) and
             (init_cnt_r = INIT_CNTR_PRECH_1)) then
        -- skip EMR(2) and EMR(3) register loads
        init_cnt_r <= INIT_CNTR_EMR_EN_DLL;
      elsif ((DDR_TYPE = DDR1) and (init_state_r = INIT_LOAD_MODE) and
             (init_cnt_r = INIT_CNTR_MR_ACT_DLL)) then
        -- skip OCD calibration for DDR1
        init_cnt_r <= INIT_CNTR_DEEP_MEM;
      elsif ((DDR_TYPE = DDR3) and (init_state_r = INIT_ZQCL)) then
        -- skip states for DDR3
        init_cnt_r <= INIT_CNTR_DEEP_MEM;
      elsif ((init_state_r = INIT_LOAD_MODE) or
             ((init_state_r = INIT_PRECHARGE) and
              (init_state_r1 /= INIT_CALIB_REF)) or
             ((init_state_r = INIT_AUTO_REFRESH) and
              (init_done_r = '0')) or
             (init_state_r = INIT_CNT_200)) then
        init_cnt_r <= init_cnt_r + 1;
      end if;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if ((init_state_r = INIT_IDLE) and (init_cnt_r = INIT_CNTR_DONE)) then
        phy_init_done_r <= '1';
      else
        phy_init_done_r <= '0';
      end if;
    end if;
  end process;

  -- phy_init_done to the controller and the user interface.
  -- It is delayed by four clocks to account for the
  -- multi cycle path constraint to the (phy_init_data_sel)
  -- to the phy layer.
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      phy_init_done_r1 <= phy_init_done_r;
      phy_init_done_r2 <= phy_init_done_r1;
      phy_init_done_r3 <= phy_init_done_r2;
      i_phy_init_done <= phy_init_done_r3;
    end if;
  end process;

  -- Instantiate primitive to allow this flop to be attached to multicycle
  -- path constraint in UCF. This signal goes to PHY_WRITE and PHY_CTL_IO
  -- datapath logic only. Because it is a multi-cycle path, it can be
  -- clocked by either CLKDIV0 or CLK0.
  u_ff_phy_init_data_sel : FDRSE
    port map (
     Q    => phy_init_data_sel,
     C    => clkdiv0,
     CE   => '1',
     D    => phy_init_done_r1,
     R    => '0',
     S    => '0'
     );

  -- synthesis translate_off
  process (calib_done(0))
  begin
    if (rising_edge(calib_done(0))) then
        report "First Stage Calibration completed at time " & time'image(now);
    end if;
  end process;

  process (calib_done(1))
  begin
    if (rising_edge(calib_done(1))) then
        report "Second Stage Calibration completed at time " & time'image(now);
    end if;
  end process;

  process (calib_done(2))
  begin
    if (rising_edge(calib_done(2))) then
        report "Third Stage Calibration completed at time " & time'image(now);
    end if;
  end process;

  process (calib_done(3))
  begin
    if (rising_edge(calib_done(3))) then
        report "Fourth Stage Calibration completed at time " & time'image(now);
        report "Calibration completed at time " & time'image(now);
    end if;
  end process;
  -- synthesis translate_on

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (init_cnt_r >= INIT_CNTR_DEEP_MEM) then
        init_done_r <= '1';
      else
        init_done_r <= '0';
      end if;
    end if;
  end process;

  --*****************************************************************
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if (rstdiv0 = '1') then
        init_state_r  <= INIT_IDLE;
        init_state_r1 <= INIT_IDLE;
        init_state_r2 <= INIT_IDLE;
        calib_done_r  <= (others => '0');
      else
        init_state_r  <= init_next_state;
        init_state_r1 <= init_state_r;
        init_state_r2 <= init_state_r1;
        calib_done_r  <= calib_done;    -- register for timing
      end if;
    end if;
  end process;

  process (burst_addr_r, cal1_started_r, cal2_started_r, calib_done,
           calib_done_r, chip_cnt_r, cnt_200_cycle_done_r, cnt_cmd_ok_r,
           cnt_rd_ok_r, done_200us_r, init_cnt_r, init_done_r, init_state_r,
           refresh_req)
  begin
    init_next_state <= init_state_r;
    case (init_state_r) is
      when INIT_IDLE =>
        if (done_200us_r = '1') then
          case (init_cnt_r) is
            when INIT_CNTR_INIT =>
              init_next_state <= INIT_CNT_200;
            when INIT_CNTR_PRECH_1 =>
              init_next_state <= INIT_PRECHARGE;
            when INIT_CNTR_EMR2_INIT =>
              init_next_state <= INIT_LOAD_MODE;  -- EMR(2)
            when INIT_CNTR_EMR3_INIT =>
              init_next_state <= INIT_LOAD_MODE;  -- EMR(3);
            when INIT_CNTR_EMR_EN_DLL =>
              init_next_state <= INIT_LOAD_MODE;  -- EMR, enable DLL
            when INIT_CNTR_MR_RST_DLL =>
              init_next_state <= INIT_LOAD_MODE;  -- MR, reset DLL
            when INIT_CNTR_CNT_200_WAIT =>
              if (DDR_TYPE = DDR3) then
                init_next_state <= INIT_ZQCL;     -- DDR3
              else
                -- Wait 200cc after reset DLL
                init_next_state <= INIT_CNT_200;
              end if;
            when INIT_CNTR_PRECH_2 =>
              init_next_state <= INIT_PRECHARGE;
            when INIT_CNTR_AR_1 =>
              init_next_state <= INIT_AUTO_REFRESH;
            when INIT_CNTR_AR_2 =>
              init_next_state <= INIT_AUTO_REFRESH;
            when INIT_CNTR_MR_ACT_DLL =>
              init_next_state <= INIT_LOAD_MODE;  -- MR, unreset DLL
            when INIT_CNTR_EMR_DEF_OCD =>
              init_next_state <= INIT_LOAD_MODE;  -- EMR, OCD default
            when INIT_CNTR_EMR_EXIT_OCD =>
              init_next_state <= INIT_LOAD_MODE;  -- EMR, enable OCD exit
            when INIT_CNTR_DEEP_MEM =>
              if (chip_cnt_r < CS_NUM-1) then
                init_next_state <= INIT_DEEP_MEMORY_ST;
              elsif (cnt_200_cycle_done_r = '1') then
                init_next_state <= INIT_DUMMY_ACTIVE;
              else
                init_next_state <= INIT_IDLE;
              end if;
            when INIT_CNTR_PRECH_3 =>
              init_next_state <= INIT_PRECHARGE;
            when INIT_CNTR_DONE =>
              init_next_state <= INIT_IDLE;
            when others =>
              init_next_state <= INIT_IDLE;
          end case;
        end if;
      when INIT_CNT_200 =>
        init_next_state <= INIT_CNT_200_WAIT;
      when INIT_CNT_200_WAIT =>
        if (cnt_200_cycle_done_r = '1') then
          init_next_state <= INIT_IDLE;
        end if;
      when INIT_PRECHARGE =>
        init_next_state <= INIT_PRECHARGE_WAIT;
      when INIT_PRECHARGE_WAIT =>
        if (cnt_cmd_ok_r = '1') then
          if ((init_done_r = '1') and (and_br(calib_done_r) = '0')) then
            init_next_state <= INIT_AUTO_REFRESH;
          else
            init_next_state <= INIT_IDLE;
          end if;
        end if;
      when INIT_ZQCL =>
        init_next_state <= INIT_WAIT_DLLK_ZQINIT;
      when INIT_WAIT_DLLK_ZQINIT =>
        if (cnt_200_cycle_done_r = '1') then
          init_next_state <= INIT_IDLE;
        end if;
      when INIT_LOAD_MODE =>
        init_next_state <= INIT_MODE_REGISTER_WAIT;
      when INIT_MODE_REGISTER_WAIT =>
        if (cnt_cmd_ok_r = '1') then
          init_next_state <= INIT_IDLE;
        end if;
      when INIT_AUTO_REFRESH =>
        init_next_state <= INIT_AUTO_REFRESH_WAIT;
      when INIT_AUTO_REFRESH_WAIT =>
        if (cnt_cmd_ok_r = '1') then
          if (init_done_r = '1') then
            init_next_state <= INIT_DUMMY_ACTIVE;
          else
            init_next_state <= INIT_IDLE;
          end if;
        end if;
      when INIT_DEEP_MEMORY_ST =>
        init_next_state <= INIT_IDLE;
      -- single row activate. All subsequent calibration writes and
      -- read will take place in this row
      when INIT_DUMMY_ACTIVE =>
        init_next_state <= INIT_DUMMY_ACTIVE_WAIT;
      -- Stage 1 calibration (write and continuous read)
      when INIT_DUMMY_ACTIVE_WAIT =>
        if (cnt_cmd_ok_r = '1') then
          if (calib_done_r(0) = '0') then
            -- if returning to stg1 after refresh, don't need to write
            if (cal1_started_r = '1') then
              init_next_state <= INIT_CAL1_READ;
            -- if first entering stg1, need to write training pattern
            else
              init_next_state <= INIT_CAL1_WRITE;
            end if;
          elsif (calib_done(1) = '0') then
            if (cal2_started_r = '1') then
              init_next_state <= INIT_CAL2_READ;
            else
              init_next_state <= INIT_CAL2_WRITE;
            end if;
          elsif (calib_done_r(2) = '0') then
             init_next_state <= INIT_CAL3_WRITE;
          else
            init_next_state <= INIT_CAL4_READ;
          end if;
        end if;
      -- Stage 1 calibration (write and continuous read)
      when INIT_CAL1_WRITE =>
        if (burst_addr_r = "10") then
          init_next_state <= INIT_CAL1_WRITE_READ;
        end if;
      when INIT_CAL1_WRITE_READ =>
        if (cnt_cmd_ok_r = '1') then
          init_next_state <= INIT_CAL1_READ;
        end if;
      when INIT_CAL1_READ =>
        -- Stage 1 requires inter-stage auto-refresh
        if ((calib_done_r(0) = '1') or (refresh_req = '1')) then
          init_next_state <= INIT_CAL1_READ_WAIT;
        end if;
      when INIT_CAL1_READ_WAIT =>
        if (cnt_cmd_ok_r = '1') then
          init_next_state <= INIT_CALIB_REF;
        end if;
      -- Stage 2 calibration (write and continuous read)
      when INIT_CAL2_WRITE =>
        if (burst_addr_r = "10") then
          init_next_state <= INIT_CAL2_WRITE_READ;
        end if;
      when INIT_CAL2_WRITE_READ =>
        if (cnt_cmd_ok_r = '1') then
          init_next_state <= INIT_CAL2_READ;
        end if;
      when INIT_CAL2_READ =>
        -- Stage 2 requires inter-stage auto-refresh
        if ((calib_done_r(1) = '1') or (refresh_req = '1')) then
          init_next_state <= INIT_CAL2_READ_WAIT;
        end if;
      when INIT_CAL2_READ_WAIT =>
        if (cnt_cmd_ok_r = '1') then
          init_next_state <= INIT_CALIB_REF;
        end if;
      -- Stage 3 calibration (write and continuous read)
      when INIT_CAL3_WRITE =>
        if (burst_addr_r = "10") then
          init_next_state <= INIT_CAL3_WRITE_READ;
        end if;
      when INIT_CAL3_WRITE_READ =>
        if (cnt_cmd_ok_r = '1') then
          init_next_state <= INIT_CAL3_READ;
        end if;
      when INIT_CAL3_READ =>
        if (burst_addr_r = "10") then
          init_next_state <= INIT_CAL3_READ_WAIT;
        end if;
      when INIT_CAL3_READ_WAIT =>
        if (cnt_rd_ok_r = '1') then
          if (calib_done_r(2) = '1') then
            init_next_state <= INIT_CALIB_REF;
          else
            init_next_state <= INIT_CAL3_READ;
          end if;
        end if;
      -- Stage 4 calibration (continuous read only, same pattern as stage 3)
      -- only used if DQS_GATE supported
      when INIT_CAL4_READ =>
        if (burst_addr_r = "10") then
          init_next_state <= INIT_CAL4_READ_WAIT;
        end if;
      when INIT_CAL4_READ_WAIT =>
        if (cnt_rd_ok_r = '1') then
          -- Stage 4 requires inter-stage auto-refresh
          if ((calib_done_r(3) = '1') or (refresh_req = '1')) then
            init_next_state <= INIT_PRECHARGE;
          else
            init_next_state <= INIT_CAL4_READ;
          end if;
        end if;
      when INIT_CALIB_REF =>
        init_next_state <= INIT_PRECHARGE;
      when others =>
        null;
    end case;
  end process;

  --***************************************************************************
  -- Memory control/address
  --***************************************************************************

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if ((init_state_r = INIT_DUMMY_ACTIVE) or
          (init_state_r = INIT_PRECHARGE) or
          (init_state_r = INIT_LOAD_MODE) or
          (init_state_r = INIT_AUTO_REFRESH)) then
        ddr_ras_n_r <= '0';
      else
        ddr_ras_n_r <= '1';
      end if;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if ((init_state_r = INIT_LOAD_MODE) or
          (init_state_r = INIT_AUTO_REFRESH) or
          (cal_write_read = '1' and (burst_cnt_r = "00"))) then
        ddr_cas_n_r <= '0';
      else
        ddr_cas_n_r <= '1';
      end if;
    end if;
  end process;

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if ((init_state_r = INIT_LOAD_MODE) or
          (init_state_r = INIT_PRECHARGE) or
          (init_state_r = INIT_ZQCL) or
          (cal_write = '1' and (burst_cnt_r = "00"))) then
        ddr_we_n_r <= '0';
      else
        ddr_we_n_r <= '1';
      end if;
    end if;
  end process;

  --*****************************************************************
  -- memory address during init
  --*****************************************************************

  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      if ((init_state_r = INIT_PRECHARGE) or
          (init_state_r = INIT_ZQCL)) then
        -- Precharge all - set A10 = 1
        ddr_addr_r <= (others => '0');
        ddr_addr_r(10) <= '1';
        ddr_ba_r <= (others => '0');
      elsif (init_state_r = INIT_LOAD_MODE) then
        ddr_ba_r <= (others => '0');
        ddr_addr_r <= (others => '0');
        case (init_cnt_r) is
          -- EMR (2)
          when INIT_CNTR_EMR2_INIT =>
            ddr_ba_r(1 downto 0) <= "10";
            ddr_addr_r <= (others => '0');
          -- EMR (3)
          when INIT_CNTR_EMR3_INIT =>
            ddr_ba_r(1 downto 0) <= "11";
            if (DDR_TYPE = DDR3) then
              ddr_addr_r <= load_mode_reg3(ROW_WIDTH-1 downto 0);
            else
              ddr_addr_r <= (others => '0');
            end if;
          -- EMR write - A0 = 0 for DLL enable
          when INIT_CNTR_EMR_EN_DLL =>
            ddr_ba_r(1 downto 0) <= "01";
            if (DDR_TYPE = DDR3) then
              ddr_addr_r <= load_mode_reg1(ROW_WIDTH-1 downto 0);
            else
              ddr_addr_r <= ext_mode_reg(ROW_WIDTH-1 downto 0);
            end if;
          -- MR write, reset DLL (A8=1)
          when INIT_CNTR_MR_RST_DLL =>
            if (DDR_TYPE = DDR3) then
              ddr_addr_r <= load_mode_reg0(ROW_WIDTH-1 downto 0);
            else
              ddr_addr_r <= load_mode_reg(ROW_WIDTH-1 downto 0);
            end if;
            ddr_ba_r(1 downto 0) <= "00";
            ddr_addr_r(8) <= '1';
          -- MR write, unreset DLL (A8=0)
          when INIT_CNTR_MR_ACT_DLL =>
            ddr_ba_r(1 downto 0) <= "00";
            ddr_addr_r <= load_mode_reg(ROW_WIDTH-1 downto 0);
          -- EMR write, OCD default state
          when INIT_CNTR_EMR_DEF_OCD =>
            ddr_ba_r(1 downto 0) <= "01";
            ddr_addr_r <= ext_mode_reg(ROW_WIDTH-1 downto 0);
            ddr_addr_r(9 downto 7) <= "111";
          -- EMR write - OCD exit
          when INIT_CNTR_EMR_EXIT_OCD =>
            ddr_ba_r(1 downto 0) <= "01";
            ddr_addr_r <= ext_mode_reg(ROW_WIDTH-1 downto 0);
          when others =>
            ddr_ba_r <= (others => 'X');
            ddr_addr_r <= (others => 'X');
        end case;
      elsif (cal_write_read = '1') then
        -- when writing or reading for Stages 2-4, since training pattern is
        -- either 4 (stage 2) or 8 (stage 3-4) long, if BURST LEN < 8, then
        -- need to issue multiple bursts to read entire training pattern
        ddr_addr_r(ROW_WIDTH - 1 downto 3) <= (others => '0');
        ddr_addr_r(2 downto 0)             <= (std_logic_vector(burst_addr_r)
                                               & '0');
        ddr_ba_r                           <= (others => '0');
      elsif (init_state_r = INIT_DUMMY_ACTIVE) then
        -- all calibration writing read takes place in row 0x0 only
        ddr_ba_r   <= (others => '0');
        ddr_addr_r <= (others => '0');
      else
        -- otherwise, cry me a river
        ddr_ba_r   <= (others => 'X');
        ddr_addr_r <= (others => 'X');
      end if;
    end if;
  end process;

  -- Keep CKE asserted after initial power-on delay
  process (clkdiv0)
  begin
    if (rising_edge(clkdiv0)) then
      ddr_cke_r <= (others => done_200us_r);
    end if;
  end process;

  -- register commands to memory. Two clock cycle delay from state -> output
  process (clk0)
  begin
    if (rising_edge(clk0)) then
      ddr_addr_r1  <= ddr_addr_r;
      ddr_ba_r1    <= ddr_ba_r;
      ddr_cas_n_r1 <= ddr_cas_n_r;
      ddr_ras_n_r1 <= ddr_ras_n_r;
      ddr_we_n_r1  <= ddr_we_n_r;
      ddr_cs_n_r1  <= ddr_cs_n_r;
    end if;
  end process;

  -- logic to toggle chip select. The chip_select is
  -- clocked of clkdiv0 and will be asserted for
  -- two clock cycles.
  process (clk0)
  begin
    if (rising_edge(clk0)) then
      if (rst0 = '1') then
        ddr_cs_disable_r <= (others => '0');
      else
        if (ddr_cs_disable_r(to_integer(chip_cnt_r)) = '1') then
          ddr_cs_disable_r(to_integer(chip_cnt_r)) <= '0';
        else
          if (TWO_T_TIME_EN /= 0) then
            ddr_cs_disable_r(to_integer(chip_cnt_r)) <=
              not(ddr_cs_n_r1(to_integer(chip_cnt_r)));
          else
            ddr_cs_disable_r(to_integer(chip_cnt_r)) <=
              not(ddr_cs_n_r(to_integer(chip_cnt_r)));
          end if;
        end if;
      end if;
    end if;
  end process;

  phy_init_addr  <= ddr_addr_r;
  phy_init_ba    <= ddr_ba_r;
  phy_init_cas_n <= ddr_cas_n_r;
  phy_init_cke   <= ddr_cke_r;
  phy_init_ras_n <= ddr_ras_n_r;
  phy_init_we_n  <= ddr_we_n_r;
  phy_init_cs_n  <= (ddr_cs_n_r1 or ddr_cs_disable_r)
                    when (TWO_T_TIME_EN /= 0) else
                    (ddr_cs_n_r or ddr_cs_disable_r);

end architecture syn;


