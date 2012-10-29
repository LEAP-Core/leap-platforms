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
--  /   /         Filename: ddr2_phy_calib.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/07/02 14:03:08 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR2
--Purpose:
--   This module handles calibration after memory initialization.
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_phy_calib is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference 
    -- board design). Actual values may be different. Actual parameters values 
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    DQ_WIDTH     : integer := 72;
    DQ_BITS      : integer := 7;
    DQ_PER_DQS   : integer := 8;
    DQS_BITS     : integer := 4;
    DQS_WIDTH    : integer := 9;
    ADDITIVE_LAT : integer := 0;
    CAS_LAT      : integer := 5;
    REG_ENABLE   : integer := 1;
    CLK_PERIOD   : integer := 3000;
    SIM_ONLY     : integer := 0;
    DEBUG_EN     : integer := 0
  );
  port (
    clk                    : in  std_logic;
    clkdiv                 : in  std_logic;
    rstdiv                 : in  std_logic;
    calib_start            : in  std_logic_vector(3 downto 0);
    ctrl_rden              : in  std_logic;
    phy_init_rden          : in  std_logic;
    rd_data_rise           : in  std_logic_vector(DQ_WIDTH-1 downto 0);
    rd_data_fall           : in  std_logic_vector(DQ_WIDTH-1 downto 0);
    calib_ref_done         : in  std_logic;
    calib_done             : out std_logic_vector(3 downto 0);
    calib_ref_req          : out std_logic;
    calib_rden             : out std_logic_vector(DQS_WIDTH-1 downto 0);
    calib_rden_sel         : out std_logic_vector(DQS_WIDTH-1 downto 0);
    dlyrst_dq              : out std_logic;
    dlyce_dq               : out std_logic_vector(DQ_WIDTH-1 downto 0);
    dlyinc_dq              : out std_logic_vector(DQ_WIDTH-1 downto 0);
    dlyrst_dqs             : out std_logic;
    dlyce_dqs              : out std_logic_vector(DQS_WIDTH-1 downto 0);
    dlyinc_dqs             : out std_logic_vector(DQS_WIDTH-1 downto 0);
    dlyrst_gate            : out std_logic_vector(DQS_WIDTH-1 downto 0);
    dlyce_gate             : out std_logic_vector(DQS_WIDTH-1 downto 0);
    dlyinc_gate            : out std_logic_vector(DQS_WIDTH-1 downto 0);
    en_dqs                 : out std_logic_vector(DQS_WIDTH-1 downto 0);
    rd_data_sel            : out std_logic_vector(DQS_WIDTH-1 downto 0);
    -- Debug signals (optional use)
    dbg_idel_up_all        : in  std_logic;
    dbg_idel_down_all      : in  std_logic;
    dbg_idel_up_dq         : in  std_logic;
    dbg_idel_down_dq       : in  std_logic;
    dbg_idel_up_dqs        : in  std_logic;
    dbg_idel_down_dqs      : in  std_logic;
    dbg_idel_up_gate       : in  std_logic;
    dbg_idel_down_gate     : in  std_logic;
    dbg_sel_idel_dq        : in  std_logic_vector(DQ_BITS-1 downto 0);
    dbg_sel_all_idel_dq    : in  std_logic;
    dbg_sel_idel_dqs       : in  std_logic_vector(DQS_BITS downto 0);
    dbg_sel_all_idel_dqs   : in  std_logic;
    dbg_sel_idel_gate      : in  std_logic_vector(DQS_BITS downto 0);
    dbg_sel_all_idel_gate  : in  std_logic;
    dbg_calib_done         : out std_logic_vector(3 downto 0);
    dbg_calib_err          : out std_logic_vector(3 downto 0);
    dbg_calib_dq_tap_cnt   : out std_logic_vector((6*DQ_WIDTH)-1 downto 0);
    dbg_calib_dqs_tap_cnt  : out std_logic_vector((6*DQS_WIDTH)-1 downto 0);
    dbg_calib_gate_tap_cnt : out std_logic_vector((6*DQS_WIDTH)-1 downto 0);
    dbg_calib_rd_data_sel  : out std_logic_vector(DQS_WIDTH-1 downto 0);
    dbg_calib_rden_dly     : out std_logic_vector((5*DQS_WIDTH)-1 downto 0);
    dbg_calib_gate_dly     : out std_logic_vector((5*DQS_WIDTH)-1 downto 0)
    );
end entity ddr2_phy_calib;

architecture syn of ddr2_phy_calib is

  function or_br (val : std_logic_vector) return std_logic is
    variable rtn : std_logic := '0';
  begin
    for index in val'range loop
      rtn := rtn or val(index);
    end loop;
    return(rtn);
  end or_br;

  function FIX_ARRAY_SIZE (size_i : integer) return integer is
  begin
    if (size_i < 1) then
      return 1;
    else
      return size_i;
    end if;
  end function FIX_ARRAY_SIZE;

  function CALC_CAS_LAT_RDEN return integer is
  begin
    if (CAS_LAT = 25) then
      return 2;
    else
      return CAS_LAT;
    end if;
  end function CALC_CAS_LAT_RDEN;

  function CALC_BIT_TIME_TAPS return integer is
  begin
    if (CLK_PERIOD/150 < 64) then
      return CLK_PERIOD/150;
    else
      return 63;
    end if;
  end function CALC_BIT_TIME_TAPS;

  function CALC_CAL4_IDEL_BIT_VAL (val_i : integer) return integer is
  begin
    if (val_i >= 32) then
      return 32;
    else
      return val_i;
    end if;
  end function CALC_CAL4_IDEL_BIT_VAL;

  function CALC_GATE_BASE_INIT (val_i : integer) return integer is
  begin
    if (val_i <= 1) then
      return 0;
    else
      return val_i;
    end if;
  end function CALC_GATE_BASE_INIT;

  -- minimum time (in IDELAY taps) for which capture data must be stable for
  -- algorithm to consider
  constant MIN_WIN_SIZE : integer := 5;
  -- IDEL_SET_VAL = (# of cycles - 1) to wait after changing IDELAY value
  -- we only have to wait enough for input with new IDELAY value to
  -- propagate through pipeline stages.
  constant IDEL_SET_VAL : unsigned(2 downto 0) := "111";
  -- # of clock cycles to delay read enable to determine if read data pattern
  -- is correct for stage 3/4 (RDEN, DQS gate) calibration
  constant CALIB_RDEN_PIPE_LEN : integer := 31;
  -- translate CAS latency into number of clock cycles for read valid delay
  -- determination. Really only needed for CL = 2.5 (set to 2)
  constant CAS_LAT_RDEN : integer := CALC_CAS_LAT_RDEN;
  -- an SRL32 is used to delay CTRL_RDEN to generate read valid signal. This
  -- is min possible value delay through SRL32 can be
  constant RDEN_BASE_DELAY : integer := CAS_LAT_RDEN + ADDITIVE_LAT +
                                        REG_ENABLE;
  -- an SRL32 is used to delay the CTRL_RDEN from the read postamble DQS
  -- gate. This is min possible value the SRL32 delay can be:
  --  - Delay from end of deassertion of CTRL_RDEN to last falling edge of
  --    read burst = 3.5 (CTRL_RDEN -> CAS delay) + 3 (min CAS latency) = 6.5
  --  - Minimum time for DQS gate circuit to be generated:
  --      * 1 cyc to register CTRL_RDEN from controller
  --      * 1 cyc after RDEN_CTRL falling edge
  --      * 1 cyc min through SRL32
  --      * 1 cyc through SRL32 output flop
  --      * 0 (<1) cyc of synchronization to DQS domain via IDELAY
  --      * 1 cyc of delay through IDDR to generate CE to DQ IDDR's
  --    Total = 5 cyc < 6.5 cycles
  --    The total should be less than 5.5 cycles to account prop delays
  --    adding one cycle to the synchronization time via the IDELAY.
  --    NOTE: Value differs because of optional pipeline register added
  --      for case of RDEN_BASE_DELAY > 3 to improve timing
  constant GATE_BASE_DELAY : integer := RDEN_BASE_DELAY - 3;
  constant GATE_BASE_INIT : integer := CALC_GATE_BASE_INIT(GATE_BASE_DELAY);
  -- used for RDEN calibration: difference between shift value used during
  -- calibration, and shift value for actual RDEN SRL. Only applies when
  -- RDEN edge is immediately captured by CLKDIV0. If not (depends on phase
  -- of CLK0 and CLKDIV0 when RDEN is asserted), then add 1 to this value.
  constant CAL3_RDEN_SRL_DLY_DELTA : unsigned(4 downto 0) := "00110";
  -- fix minimum value of DQS to be 1 to handle the case where's there's only
  -- one DQS group. We could also enforce that user always inputs minimum
  -- value of 1 for DQS_BITS (even when DQS_WIDTH=1). Leave this as safeguard
  -- Assume we don't have to do this for DQ, DQ_WIDTH always > 1
  constant DQS_BITS_FIX : integer := FIX_ARRAY_SIZE(DQS_BITS);
  -- how many taps to "pre-delay" DQ before stg 1 calibration - not needed for
  -- current calibration, but leave for debug
  constant DQ_IDEL_INIT : unsigned(5 downto 0) := "000000";
  -- # IDELAY taps per bit time (i.e. half cycle). Limit to 63.
  constant BIT_TIME_TAPS : integer := CALC_BIT_TIME_TAPS;

  -- used in various places during stage 4 cal: (1) determines maximum taps
  -- to increment when finding right edge, (2) amount to decrement after
  -- finding left edge, (3) amount to increment after finding right edge
  constant CAL4_IDEL_BIT_VAL : integer :=
    CALC_CAL4_IDEL_BIT_VAL(BIT_TIME_TAPS);

  type CAL1_STATE_TYPE is (CAL1_IDLE,
                           CAL1_INIT,
                           CAL1_INC_IDEL,
                           CAL1_FIND_FIRST_EDGE,
                           CAL1_FIRST_EDGE_IDEL_WAIT,
                           CAL1_FOUND_FIRST_EDGE_WAIT,
                           CAL1_FIND_SECOND_EDGE,
                           CAL1_SECOND_EDGE_IDEL_WAIT,
                           CAL1_CALC_IDEL,
                           CAL1_DEC_IDEL,
                           CAL1_DONE);
  type CAL2_STATE_TYPE is (CAL2_IDLE,
                           CAL2_INIT,
                           CAL2_INIT_IDEL_WAIT,
                           CAL2_FIND_EDGE_POS,
                           CAL2_FIND_EDGE_IDEL_WAIT_POS,
                           CAL2_FIND_EDGE_NEG,
                           CAL2_FIND_EDGE_IDEL_WAIT_NEG,
                           CAL2_DEC_IDEL,
                           CAL2_DONE);
  type CAL3_STATE_TYPE is (CAL3_IDLE,
                           CAL3_INIT,
                           CAL3_DETECT,
                           CAL3_RDEN_PIPE_CLR_WAIT,
                           CAL3_DONE);
  type CAL4_STATE_TYPE is (CAL4_IDLE,
                           CAL4_INIT,
                           CAL4_FIND_WINDOW,
                           CAL4_FIND_EDGE,
                           CAL4_IDEL_WAIT,
                           CAL4_RDEN_PIPE_CLR_WAIT,
                           CAL4_ADJ_IDEL,
                           CAL4_DONE);

  signal cal1_bit_time_tap_cnt       : unsigned(5 downto 0);
  signal cal1_data_chk_last          : std_logic_vector(1 downto 0);
  signal cal1_data_chk_last_valid    : std_logic;
  signal cal1_data_chk_r             : std_logic_vector(1 downto 0);
  signal cal1_dlyce_dq               : std_logic;
  signal cal1_dlyinc_dq              : std_logic;
  signal cal1_dqs_dq_init_phase      : std_logic;
  signal cal1_detect_edge            : std_logic;
  signal cal1_detect_stable          : std_logic;
  signal cal1_found_second_edge      : std_logic;
  signal cal1_found_rising           : std_logic;
  signal cal1_found_window           : std_logic;
  signal cal1_first_edge_done        : std_logic;
  signal cal1_first_edge_tap_cnt     : unsigned(5 downto 0);
  signal cal1_idel_dec_cnt           : unsigned(6 downto 0);
  signal cal1_idel_inc_cnt           : unsigned(5 downto 0);
  signal cal1_idel_max_tap           : unsigned(5 downto 0);
  signal cal1_idel_max_tap_we        : std_logic;
  signal cal1_idel_tap_cnt           : unsigned(5 downto 0);
  signal cal1_idel_tap_limit_hit     : std_logic;
  signal cal1_low_freq_idel_dec      : unsigned(6 downto 0);
  signal cal1_ref_req                : std_logic;
  signal cal1_refresh                : std_logic;
  signal cal1_state                  : CAL1_STATE_TYPE;
  signal cal1_window_cnt             : unsigned(3 downto 0);
  signal cal2_curr_sel               : std_logic;
  signal cal2_detect_edge            : std_logic;
  signal cal2_dlyce_dqs              : std_logic;
  signal cal2_dlyinc_dqs             : std_logic;
  signal cal2_idel_dec_cnt           : unsigned(5 downto 0);
  signal cal2_idel_tap_cnt           : unsigned(5 downto 0);
  signal cal2_idel_tap_limit         : unsigned(5 downto 0);
  signal cal2_idel_tap_limit_hit     : std_logic;
  signal cal2_rd_data_fall_last_neg  : std_logic;
  signal cal2_rd_data_fall_last_pos  : std_logic;
  signal cal2_rd_data_last_valid_neg : std_logic;
  signal cal2_rd_data_last_valid_pos : std_logic;
  signal cal2_rd_data_rise_last_neg  : std_logic;
  signal cal2_rd_data_rise_last_pos  : std_logic;
  signal cal2_rd_data_sel            : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal cal2_rd_data_sel_edge       : std_logic;
  signal cal2_rd_data_sel_r          : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal cal2_ref_req                : std_logic;
  signal cal2_state                  : CAL2_STATE_TYPE;
  signal cal3_data_match             : std_logic;
  signal cal3_data_match_stgd        : std_logic;
  signal cal3_data_valid             : std_logic;
  signal cal3_match_found            : std_logic;
  signal cal3_rden_dly               : unsigned(4 downto 0);
  signal cal3_rden_srl_a             : unsigned(4 downto 0);
  signal cal3_state                  : CAL3_STATE_TYPE;
  signal cal4_data_good              : std_logic;
  signal cal4_data_match             : std_logic;
  signal cal4_data_match_stgd        : std_logic;
  signal cal4_data_valid             : std_logic;
  signal cal4_dlyce_gate             : std_logic;
  signal cal4_dlyinc_gate            : std_logic;
  signal cal4_dlyrst_gate            : std_logic;
  signal cal4_gate_srl_a             : unsigned(4 downto 0);
  signal cal4_idel_adj_cnt           : unsigned(5 downto 0);
  signal cal4_idel_adj_inc           : std_logic;
  signal cal4_idel_bit_tap           : std_logic;
  signal cal4_idel_tap_cnt           : unsigned(5 downto 0);
  signal cal4_idel_max_tap           : std_logic;
  signal cal4_rden_srl_a             : unsigned(4 downto 0);
  signal cal4_ref_req                : std_logic;
  signal cal4_seek_left              : std_logic;
  signal cal4_stable_window          : std_logic;
  signal cal4_state                  : CAL4_STATE_TYPE;
  -- only for stg1/2/4
  signal cal4_window_cnt             : unsigned(3 downto 0);
  signal calib_done_tmp              : std_logic_vector(3 downto 0);
  signal calib_ctrl_gate_pulse       : std_logic;
  signal calib_ctrl_gate_pulse_r     : std_logic;
  signal calib_ctrl_rden             : std_logic;
  signal calib_ctrl_rden_r           : std_logic;
  signal calib_ctrl_rden_negedge     : std_logic;
  signal calib_ctrl_rden_negedge_r   : std_logic;
  signal calib_done_r                : std_logic_vector(3 downto 0);
  signal calib_err                   : std_logic_vector(3 downto 0);
  signal calib_err_2                 : std_logic_vector(1 downto 0);
  signal calib_init_gate_pulse       : std_logic;
  signal calib_init_gate_pulse_r     : std_logic;
  signal calib_init_gate_pulse_r1    : std_logic;
  signal calib_init_rden             : std_logic;
  signal calib_init_rden_r           : std_logic;
  signal calib_rden_srl_a            : unsigned(4 downto 0);
  signal calib_rden_srl_a_r          : unsigned(4 downto 0);
  signal calib_rden_dly              : unsigned((5*DQS_WIDTH)-1 downto 0);
  signal calib_rden_edge_r           : std_logic;
  signal calib_rden_pipe_cnt         : unsigned(4 downto 0);
  signal calib_rden_srl_out          : std_logic;
  signal calib_rden_srl_out_r        : std_logic;
  signal calib_rden_srl_out_r1       : std_logic;
  signal calib_rden_valid            : std_logic;
  signal calib_rden_valid_stgd       : std_logic;
  signal count_dq                    : unsigned(DQ_BITS-1 downto 0);
  signal count_dqs                   : unsigned(DQS_BITS_FIX-1 downto 0);
  signal count_gate                  : unsigned(DQS_BITS_FIX-1 downto 0);
  signal count_rden                  : unsigned(DQS_BITS_FIX-1 downto 0);
  signal ctrl_rden_r                 : std_logic;
  signal dlyce_or                    : std_logic;
  signal gate_dly                    : std_logic_vector((5*DQS_WIDTH)-1
                                                        downto 0);
  signal gate_dly_r                  : std_logic_vector((5*DQS_WIDTH)-1
                                                        downto 0);
  signal gate_srl_in                 : std_logic;
  signal gate_srl_out                : unsigned(DQS_WIDTH-1 downto 0);
  signal gate_srl_out_r              : unsigned(DQS_WIDTH-1 downto 0);
  signal idel_set_cnt                : unsigned(2 downto 0);
  signal idel_set_wait               : std_logic;
  signal next_count_dq               : unsigned(DQ_BITS-1 downto 0);
  signal next_count_dqs              : unsigned(DQS_BITS_FIX-1 downto 0);
  signal next_count_gate             : unsigned(DQS_BITS_FIX-1 downto 0);
  signal phy_init_rden_r             : std_logic;
  signal phy_init_rden_r1            : std_logic;
  signal rd_data_fall_1x_r           : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal rd_data_fall_1x_r1          : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rd_data_fall_2x_r           : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rd_data_fall_chk_q1         : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rd_data_fall_chk_q2         : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rd_data_rise_1x_r           : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal rd_data_rise_1x_r1          : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rd_data_rise_2x_r           : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rd_data_rise_chk_q1         : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rd_data_rise_chk_q2         : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rdd_fall_q1                 : std_logic;
  signal rdd_fall_q1_r               : std_logic;
  signal rdd_fall_q1_r1              : std_logic;
  signal rdd_fall_q2                 : std_logic;
  signal rdd_fall_q2_r               : std_logic;
  signal rdd_rise_q1                 : std_logic;
  signal rdd_rise_q1_r               : std_logic;
  signal rdd_rise_q1_r1              : std_logic;
  signal rdd_rise_q2                 : std_logic;
  signal rdd_rise_q2_r               : std_logic;
  signal rdd_mux_sel                 : unsigned(DQS_BITS_FIX-1 downto 0);
  signal rden_dec                    : std_logic;
  signal rden_dly                    : std_logic_vector((5*DQS_WIDTH)-1
                                                        downto 0);
  signal rden_dly_r                  : std_logic_vector((5*DQS_WIDTH)-1
                                                        downto 0);
  signal rden_dly_0                  : unsigned(4 downto 0);
  signal rden_inc                    : std_logic;
  signal rden_mux                    : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rden_srl_out                : std_logic_vector(DQS_WIDTH-1 downto 0);

  -- Debug
  type TYPE_DBG_DQ_ARRAY is array (DQ_WIDTH-1 downto 0) of
    unsigned(5 downto 0);
  type TYPE_DBG_DQS_ARRAY is array (DQS_WIDTH-1 downto 0) of
    unsigned(5 downto 0);
  signal dbg_dq_tap_cnt   : TYPE_DBG_DQ_ARRAY;
  signal dbg_dqs_tap_cnt  : TYPE_DBG_DQS_ARRAY;
  signal dbg_gate_tap_cnt : TYPE_DBG_DQS_ARRAY;

  signal i_calib_done  : std_logic_vector(3 downto 0);
  signal i_dlyrst_dq   : std_logic;
  signal i_dlyce_dq    : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal i_dlyinc_dq   : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal i_dlyrst_dqs  : std_logic;
  signal i_dlyce_dqs   : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal i_dlyinc_dqs  : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal i_dlyrst_gate : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal i_dlyce_gate  : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal i_dlyinc_gate : std_logic_vector(DQS_WIDTH-1 downto 0);

  attribute syn_preserve : boolean;
  attribute syn_replicate : boolean;
  attribute syn_preserve of u_calib_rden_srl_out_r  : label is true;

begin

  calib_done  <= i_calib_done;
  dlyrst_dq   <= i_dlyrst_dq;
  dlyce_dq    <= i_dlyce_dq;
  dlyinc_dq   <= i_dlyinc_dq;
  dlyrst_dqs  <= i_dlyrst_dqs;
  dlyce_dqs   <= i_dlyce_dqs;
  dlyinc_dqs  <= i_dlyinc_dqs;
  dlyrst_gate <= i_dlyrst_gate;
  dlyce_gate  <= i_dlyce_gate;
  dlyinc_gate <= i_dlyinc_gate;

  --***************************************************************************
  -- Debug output ("dbg_phy_calib_*")
  -- NOTES:
  --  1. All debug outputs coming out of PHY_CALIB are clocked off CLKDIV0,
  --     although they are also static after calibration is complete. This
  --     means the user can either connect them to a Chipscope ILA, or to
  --     either a sync/async VIO input block. Using an async VIO has the
  --     advantage of not requiring these paths to meet cycle-to-cycle timing.
  --  2. The widths of most of these debug buses are dependent on the # of
  --     DQS/DQ bits (e.g. dq_tap_cnt width = 6 * (# of DQ bits)
  -- SIGNAL DESCRIPTION:
  --  1. calib_done:   4 bits - each one asserted as each phase of calibration
  --                   is completed.
  --  2. calib_err:    4 bits - each one asserted when a calibration error
  --                   encountered for that stage. Some of these bits may not
  --                   be used (not all cal stages report an error).
  --  3. dq_tap_cnt:   final IDELAY tap counts for all DQ IDELAYs
  --  4. dqs_tap_cnt:  final IDELAY tap counts for all DQS IDELAYs
  --  5. gate_tap_cnt: final IDELAY tap counts for all DQS gate
  --                   synchronization IDELAYs
  --  6. rd_data_sel:  final read capture MUX (either "positive" or "negative"
  --                   edge capture) settings for all DQS groups
  --  7. rden_dly:     related to # of cycles after issuing a read until when
  --                   read data is valid - for all DQS groups
  --  8. gate_dly:     related to # of cycles after issuing a read until when
  --                   clock enable for all DQ's is deasserted to prevent
  --                   effect of DQS postamble glitch - for all DQS groups
  --***************************************************************************

  --*****************************************************************
  -- Record IDELAY tap values by "snooping" IDELAY control signals
  --*****************************************************************

  -- record DQ IDELAY tap values
  gen_dbg_dq_tc: for dbg_dq_tc_i in 0 to DQ_WIDTH-1 generate
    dbg_calib_dq_tap_cnt((6*dbg_dq_tc_i)+5 downto 6*dbg_dq_tc_i) <=
      std_logic_vector(dbg_dq_tap_cnt(dbg_dq_tc_i));
    process (clkdiv)
    begin
      if (rising_edge(clkdiv)) then
        if ((rstdiv = '1') or (i_dlyrst_dq = '1')) then
          dbg_dq_tap_cnt(dbg_dq_tc_i) <= TO_UNSIGNED(0,6);
        elsif (i_dlyce_dq(dbg_dq_tc_i) = '1') then
          if (i_dlyinc_dq(dbg_dq_tc_i) = '1') then
            dbg_dq_tap_cnt(dbg_dq_tc_i) <= dbg_dq_tap_cnt(dbg_dq_tc_i) + 1;
          else
            dbg_dq_tap_cnt(dbg_dq_tc_i) <= dbg_dq_tap_cnt(dbg_dq_tc_i) - 1;
          end if;
        end if;
      end if;
    end process;
  end generate;

  -- record DQS IDELAY tap values
  gen_dbg_dqs_tc: for dbg_dqs_tc_i in 0 to DQS_WIDTH-1 generate
    dbg_calib_dqs_tap_cnt((6*dbg_dqs_tc_i)+5 downto 6*dbg_dqs_tc_i) <=
      std_logic_vector(dbg_dqs_tap_cnt(dbg_dqs_tc_i));
    process (clkdiv)
    begin
      if (rising_edge(clkdiv)) then
        if ((rstdiv = '1') or (i_dlyrst_dqs = '1')) then
          dbg_dqs_tap_cnt(dbg_dqs_tc_i) <= TO_UNSIGNED(0,6);
        elsif (i_dlyce_dqs(dbg_dqs_tc_i) = '1') then
          if (i_dlyinc_dqs(dbg_dqs_tc_i) = '1') then
            dbg_dqs_tap_cnt(dbg_dqs_tc_i) <= dbg_dqs_tap_cnt(dbg_dqs_tc_i) + 1;
          else
            dbg_dqs_tap_cnt(dbg_dqs_tc_i) <= dbg_dqs_tap_cnt(dbg_dqs_tc_i) - 1;
          end if;
        end if;
      end if;
    end process;
  end generate;

  -- record DQS gate IDELAY tap values
  gen_dbg_gate_tc: for dbg_gate_tc_i in 0 to DQS_WIDTH-1 generate
    dbg_calib_gate_tap_cnt((6*dbg_gate_tc_i)+5 downto 6*dbg_gate_tc_i) <=
      std_logic_vector(dbg_gate_tap_cnt(dbg_gate_tc_i));
    process (clkdiv)
    begin
      if (rising_edge(clkdiv)) then
        if ((rstdiv = '1') or (i_dlyrst_gate(dbg_gate_tc_i) = '1')) then
          dbg_gate_tap_cnt(dbg_gate_tc_i) <= TO_UNSIGNED(0,6);
        elsif (i_dlyce_gate(dbg_gate_tc_i) = '1') then
          if (i_dlyinc_gate(dbg_gate_tc_i) = '1') then
            dbg_gate_tap_cnt(dbg_gate_tc_i) <=
              dbg_gate_tap_cnt(dbg_gate_tc_i) + 1;
          else
            dbg_gate_tap_cnt(dbg_gate_tc_i) <=
              dbg_gate_tap_cnt(dbg_gate_tc_i) - 1;
          end if;
        end if;
      end if;
    end process;
  end generate;

  dbg_calib_done        <= i_calib_done;
  dbg_calib_err         <= calib_err;
  dbg_calib_rd_data_sel <= cal2_rd_data_sel;
  dbg_calib_rden_dly    <= rden_dly;
  dbg_calib_gate_dly    <= gate_dly;

  --***************************************************************************
  -- Read data pipelining, and read data "ISERDES" data width expansion
  --***************************************************************************

  -- For all data bits, register incoming capture data to slow clock to improve
  -- timing. Adding single pipeline stage does not affect functionality (as
  -- long as we make sure to wait extra clock cycle after changing DQ IDELAY)
  -- Also note in this case that we're "missing" every other clock cycle's
  -- worth of data capture since we're sync'ing to the slow clock. This is
  -- fine for stage 1 and stage 2 cal, but not for stage 3 and 4 (see below
  -- for different circuit to handle those stages)
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      rd_data_rise_1x_r <= rd_data_rise;
      rd_data_fall_1x_r <= rd_data_fall;
    end if;
  end process;

  -- For every DQ_PER_DQS bit, generate what is essentially a ISERDES-type
  -- data width expander. Will need this for stage 3 and 4 cal, where we need
  -- to compare data over consecutive clock cycles. We can also use this for
  -- stage 2 as well (stage 2 doesn't require every bit to be looked at, only
  -- one bit per DQS group)
  -- first stage: keep data in fast clk domain. Store data over two
  -- consecutive clock cycles for rise/fall data for proper transfer
  -- to slow clock domain
  gen_rdd: for rdd_i in 0 to DQS_WIDTH-1 generate
    process (clk)
    begin
      if (rising_edge(clk)) then
        rd_data_rise_2x_r(rdd_i) <= rd_data_rise(rdd_i*DQ_PER_DQS);
        rd_data_fall_2x_r(rdd_i) <= rd_data_fall(rdd_i*DQ_PER_DQS);
      end if;
    end process;
    -- second stage, register first stage to slow clock domain, 2nd stage
    -- consists of both these flops, and the rd_data_rise_1x_r flops
    process (clkdiv)
    begin
      if (rising_edge(clkdiv)) then
        rd_data_rise_1x_r1(rdd_i) <= rd_data_rise_2x_r(rdd_i);
        rd_data_fall_1x_r1(rdd_i) <= rd_data_fall_2x_r(rdd_i);
      end if;
    end process;
    -- now we have four outputs - representing rise/fall outputs over last
    -- 2 fast clock cycles. However, the ordering these represent can either
    -- be: (1) Q2 = data @ time = n, Q1 = data @ time = n+1, or (2)
    -- Q2 = data @ time = n - 1, Q1 = data @ time = n (and data at [Q1,Q2]
    -- is "staggered") - leave it up to the stage of calibration using this
    -- to figure out which is which, if they care at all (e.g. stage 2 cal
    -- doesn't care about the ordering)
    rd_data_rise_chk_q1(rdd_i) <= rd_data_rise_1x_r((rdd_i*DQ_PER_DQS));
    rd_data_rise_chk_q2(rdd_i) <= rd_data_rise_1x_r1(rdd_i);
    rd_data_fall_chk_q1(rdd_i) <= rd_data_fall_1x_r((rdd_i*DQ_PER_DQS));
    rd_data_fall_chk_q2(rdd_i) <= rd_data_fall_1x_r1(rdd_i);
  end generate;

  --*****************************************************************
  -- Outputs of these simplified ISERDES circuits then feed MUXes based on
  -- which DQ the current calibration algorithm needs to look at
  --*****************************************************************

  -- generate MUX control; assume that adding an extra pipeline stage isn't
  -- an issue - whatever stage cal logic is using output of MUX will wait
  -- enough time after changing it
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      case (i_calib_done(2 downto 0)) is
        when "001" =>
          rdd_mux_sel <= next_count_dqs;
        when "011" =>
          rdd_mux_sel <= count_rden;
        when "111" =>
          rdd_mux_sel <= next_count_gate;
        when others =>
          rdd_mux_sel <= (others => 'X');
      end case;
    end if;
  end process;

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      rdd_rise_q1 <= rd_data_rise_chk_q1(to_integer(rdd_mux_sel));
      rdd_rise_q2 <= rd_data_rise_chk_q2(to_integer(rdd_mux_sel));
      rdd_fall_q1 <= rd_data_fall_chk_q1(to_integer(rdd_mux_sel));
      rdd_fall_q2 <= rd_data_fall_chk_q2(to_integer(rdd_mux_sel));
    end if;
  end process;

  --***************************************************************************
  -- Demultiplexor to control (reset, increment, decrement) IDELAY tap values
  --   For DQ:
  --     STG1: for per-bit-deskew, only inc/dec the current DQ. For non-per
  --       deskew, increment all bits in the current DQS set
  --     STG2: inc/dec all DQ's in the current DQS set.
  -- NOTE: Nice to add some error checking logic here (or elsewhere in the
  --       code) to check if logic attempts to overflow tap value
  --***************************************************************************

  -- don't use DLYRST to reset value of IDELAY after reset. Need to change this
  -- if we want to allow user to recalibrate after initial reset
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        i_dlyrst_dq  <= '1';
        i_dlyrst_dqs <= '1';
      else
        i_dlyrst_dq  <= '0';
        i_dlyrst_dqs <= '0';
      end if;
    end if;
  end process;

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        i_dlyce_dq   <= (others => '0');
        i_dlyinc_dq  <= (others => '0');
        i_dlyce_dqs  <= (others => '0');
        i_dlyinc_dqs <= (others => '0');
      else
        i_dlyce_dq   <= (others => '0');
        i_dlyinc_dq  <= (others => '0');
        i_dlyce_dqs  <= (others => '0');
        i_dlyinc_dqs <= (others => '0');

        -- stage 1 cal: change only specified DQ
        if (cal1_dlyce_dq = '1') then
          if (SIM_ONLY = 0) then
            i_dlyce_dq(to_integer(count_dq)) <= '1';
            i_dlyinc_dq(to_integer(count_dq)) <= cal1_dlyinc_dq;
          else
            -- if simulation, then calibrate only first DQ, apply results
            -- to all DQs (i.e. assume delay on all DQs is the same)
            for i in 0 to DQ_WIDTH-1 loop
              i_dlyce_dq(i) <= '1';
              i_dlyinc_dq(i) <= cal1_dlyinc_dq;
            end loop;
          end if;
        elsif (cal2_dlyce_dqs = '1') then
          -- stage 2 cal: change DQS and all corresponding DQ's
          if (SIM_ONLY = 0) then
            i_dlyce_dqs(to_integer(count_dqs)) <= '1';
            i_dlyinc_dqs(to_integer(count_dqs)) <= cal2_dlyinc_dqs;
            for i in 0 to DQ_PER_DQS-1 loop
              i_dlyce_dq((DQ_PER_DQS*to_integer(count_dqs))+i) <= '1';
              i_dlyinc_dq((DQ_PER_DQS*to_integer(count_dqs))+i) <=
                cal2_dlyinc_dqs;
            end loop;
          else
            for i in 0 to DQS_WIDTH-1 loop
              -- if simulation, then calibrate only first DQS
              i_dlyce_dqs(i) <= '1';
              i_dlyinc_dqs(i) <= cal2_dlyinc_dqs;
              for j in 0 to DQ_PER_DQS-1 loop
                i_dlyce_dq((DQ_PER_DQS*i)+j) <= '1';
                i_dlyinc_dq((DQ_PER_DQS*i)+j) <= cal2_dlyinc_dqs;
              end loop;
            end loop;
          end if;
        elsif (DEBUG_EN /= 0) then
          -- DEBUG: allow user to vary IDELAY tap settings
          -- For DQ IDELAY taps
          if ((dbg_idel_up_all = '1') or (dbg_idel_down_all = '1') or
              (dbg_sel_all_idel_dq = '1')) then
            for x in 0 to DQ_WIDTH-1 loop
              i_dlyce_dq(x) <= dbg_idel_up_all or dbg_idel_down_all or
                               dbg_idel_up_dq or dbg_idel_down_dq;
              i_dlyinc_dq(x) <= dbg_idel_up_all or dbg_idel_up_dq;
            end loop;
          else
            i_dlyce_dq <= (others => '0');
            i_dlyce_dq(to_integer(unsigned(dbg_sel_idel_dq)))
              <= dbg_idel_up_dq or dbg_idel_down_dq;
            i_dlyinc_dq(to_integer(unsigned(dbg_sel_idel_dq)))
              <= dbg_idel_up_dq;
          end if;
          -- For DQS IDELAY taps
          if ((dbg_idel_up_all = '1') or (dbg_idel_down_all = '1') or
              (dbg_sel_all_idel_dqs = '1')) then
            for x in 0 to DQS_WIDTH-1 loop
              i_dlyce_dqs(x) <= dbg_idel_up_all or dbg_idel_down_all or
                                dbg_idel_up_dqs or dbg_idel_down_dqs;
              i_dlyinc_dqs(x) <= dbg_idel_up_all or dbg_idel_up_dqs;
            end loop;
          else
            i_dlyce_dqs <= (others => '0');
            i_dlyce_dqs(to_integer(unsigned(dbg_sel_idel_dqs)))
              <= dbg_idel_up_dqs or dbg_idel_down_dqs;
            i_dlyinc_dqs(to_integer(unsigned(dbg_sel_idel_dqs)))
              <= dbg_idel_up_dqs;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- GATE synchronization is handled directly by Stage 4 calibration FSM
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        i_dlyrst_gate <= (others => '1');
        i_dlyce_gate  <= (others => '0');
        i_dlyinc_gate <= (others => '0');
      else
        i_dlyrst_gate <= (others => '0');
        i_dlyce_gate  <= (others => '0');
        i_dlyinc_gate <= (others => '0');

        if (cal4_dlyrst_gate = '1') then
          if (SIM_ONLY = 0) then
            i_dlyrst_gate(to_integer(count_gate)) <= '1';
          else
            for i in 0 to DQS_WIDTH-1 loop
              i_dlyrst_gate(i) <= '1';
            end loop;
          end if;
        end if;

        if (cal4_dlyce_gate = '1') then
          if (SIM_ONLY = 0) then
            i_dlyce_gate(to_integer(count_gate)) <= '1';
            i_dlyinc_gate(to_integer(count_gate)) <= cal4_dlyinc_gate;
          else
            -- if simulation, then calibrate only first gate
            for i in 0 to DQS_WIDTH-1 loop
              i_dlyce_gate(i) <= '1';
              i_dlyinc_gate(i) <= cal4_dlyinc_gate;
            end loop;
          end if;
        elsif (DEBUG_EN /= 0) then
          -- DEBUG: allow user to vary IDELAY tap settings
          if ((dbg_idel_up_all = '1') or (dbg_idel_down_all = '1') or
              (dbg_sel_all_idel_gate = '1')) then
            for x in 0 to  DQS_WIDTH-1 loop
              i_dlyce_gate(x) <= dbg_idel_up_all or dbg_idel_down_all or
                                 dbg_idel_up_gate or dbg_idel_down_gate;
              i_dlyinc_gate(x) <= dbg_idel_up_all or dbg_idel_up_gate;
            end loop;
          else
            i_dlyce_gate <= (others => '0');
            i_dlyce_gate(to_integer(unsigned(dbg_sel_idel_gate))) <=
              dbg_idel_up_gate or dbg_idel_down_gate;
            i_dlyinc_gate(to_integer(unsigned(dbg_sel_idel_gate))) <=
              dbg_idel_up_gate;
          end if;
        end if;
      end if;
    end if;
  end process;

  --***************************************************************************
  -- signal to tell calibration state machines to wait and give IDELAY time to
  -- settle after it's value is changed (both time for IDELAY chain to settle,
  -- and for settled output to propagate through ISERDES). For general use: use
  -- for any calibration state machines that modify any IDELAY.
  -- Should give at least enough time for IDELAY output to settle (technically
  -- for V5, this should be "glitchless" when IDELAY taps are changed, so don't
  -- need any time here), and also time for new data to propagate through both
  -- ISERDES and the "RDD" MUX + associated pipelining
  -- For now, give very "generous" delay - doesn't really matter since only
  -- needed during calibration
  --***************************************************************************

  -- determine if calibration polarity has changed
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      cal2_rd_data_sel_r <= cal2_rd_data_sel;
    end if;
  end process;

  cal2_rd_data_sel_edge <= or_br(cal2_rd_data_sel xor cal2_rd_data_sel_r);

  -- combine requests to modify any of the IDELAYs into one. Also when second
  -- stage capture "edge" polarity is changed (IDELAY isn't changed in this
  -- case, but use the same counter to stall cal logic)
  dlyce_or <= cal1_dlyce_dq or
              cal2_dlyce_dqs or
              cal2_rd_data_sel_edge or
              cal4_dlyce_gate or
              cal4_dlyrst_gate;

  -- SYN_NOTE: Can later recode to avoid combinational path
  idel_set_wait <= '1' when ((dlyce_or  = '1') or
                             (idel_set_cnt /= IDEL_SET_VAL)) else '0';

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        idel_set_cnt <= (others => '0');
      elsif (dlyce_or = '1') then
        idel_set_cnt <= (others => '0');
      elsif (idel_set_cnt /= IDEL_SET_VAL) then
        idel_set_cnt <= idel_set_cnt + "001";
      end if;
    end if;
  end process;

  -- generate request to PHY_INIT logic to issue auto-refresh
  -- used by certain states to force prech/auto-refresh part way through
  -- calibration to avoid a tRAS violation (which will happen if that
  -- stage of calibration lasts long enough). This signal must meet the
  -- following requirements: (1) only transition from 0->1 when the refresh
  -- request is needed, (2) stay at 1 and only transition 1->0 when
  -- CALIB_REF_DONE is asserted
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        calib_ref_req <= '0';
      else
        calib_ref_req <= cal1_ref_req or
                         cal2_ref_req or
                         cal4_ref_req;
      end if;
    end if;
  end process;

  -- stage 1 calibration requests auto-refresh every 4 bits
  gen_cal1_refresh_dq_lte4: if (DQ_BITS < 2) generate
    cal1_refresh <= '0';
  end generate;
  gen_cal1_refresh_dq_gt4: if (DQ_BITS >= 2) generate
    cal1_refresh <= '1' when (next_count_dq(1 downto 0) = "00") else '0';
  end generate;

  --***************************************************************************
  -- First stage calibration: DQ-DQS
  -- Definitions:
  --  edge: detected when varying IDELAY, and current capture data != prev
  --    capture data
  --  valid bit window: detected when current capture data == prev capture
  --    data for more than half the bit time
  --  starting conditions for DQS-DQ phase:
  --    case 1: when DQS starts somewhere in rising edge bit window, or
  --      on the right edge of the rising bit window.
  --    case 2: when DQS starts somewhere in falling edge bit window, or
  --      on the right edge of the falling bit window.
  -- Algorithm Description:
  --  1. Increment DQ IDELAY until we find an edge.
  --  2. While we're finding the first edge, note whether a valid bit window
  --     has been detected before we found an edge. If so, then figure out if
  --     this is the rising or falling bit window. If rising, then our starting
  --     DQS-DQ phase is case 1. If falling, then it's case 2. If don't detect
  --     a valid bit window, then we must have started on the edge of a window.
  --     Need to wait until later on to decide which case we are.
  --       - Store FIRST_EDGE IDELAY value
  --  3. Now look for second edge.
  --  4. While we're finding the second edge, note whether valid bit window
  --     is detected. If so, then use to, along with results from (2) to figure
  --     out what the starting case is. If in rising bit window, then we're in
  --     case 2. If falling, then case 1.
  --       - Store SECOND_EDGE IDELAY value
  --     NOTES:
  --       a. Finding two edges allows us to calculate the bit time (although
  --          not the "same" bit time polarity - need to investigate this
  --          more).
  --       b. If we run out of taps looking for the second edge, then the bit
  --       time must be too long (>= 2.5ns, and DQS-DQ starting phase must be
  --       case 1).
  --  5. Calculate absolute amount to delay DQ as:
  --       If second edge found, and case 1:
  --         - DQ_IDELAY = FIRST_EDGE - 0.5*(SECOND_EDGE - FIRST_EDGE)
  --       If second edge found, and case 2:
  --         - DQ_IDELAY = SECOND_EDGE - 0.5*(SECOND_EDGE - FIRST_EDGE)
  --       If second edge not found, then need to make an approximation on
  --       how much to shift by (should be okay, because we have more timing
  --       margin):
  --         - DQ_IDELAY = FIRST_EDGE - 0.5 * (bit_time)
  --     NOTE: Does this account for either case 1 or case 2?????
  --     NOTE: It's also possible even when we find the second edge, that
  --           to instead just use half the bit time to subtract from either
  --           FIRST or SECOND_EDGE. Finding the actual bit time (which is
  --           what (SECOND_EDGE - FIRST_EDGE) is, is slightly more accurate,
  --           since it takes into account duty cycle distortion.
  --  6. Repeat for each DQ in current DQS set.
  --***************************************************************************

  --*****************************************************************
  -- for first stage calibration - used for checking if DQS is aligned to the
  -- particular DQ, such that we're in the data valid window. Basically, this
  -- is one giant MUX.
  --  = [falling data, rising data]
  --  = [0, 1] = rising DQS aligned in proper (rising edge) bit window
  --  = [1, 0] = rising DQS aligned in wrong (falling edge) bit window
  --  = [0, 0], or [1,1] = in uncertain region between windows
  --*****************************************************************

  -- SYN_NOTE: May have to split this up into multiple levels - MUX can get
  --  very wide - as wide as the data bus width

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      cal1_data_chk_r <= (rd_data_fall_1x_r(TO_INTEGER(next_count_dq)) &
                          rd_data_rise_1x_r(TO_INTEGER(next_count_dq)));
    end if;
  end process;

  --*****************************************************************
  -- determine when an edge has occurred - when either the current value
  -- is different from the previous latched value or when the DATA_CHK
  -- outputs are the same (rare, but indicates that we're at an edge)
  -- This is only valid when the IDELAY output and propagation of the
  -- data through the capture flops has had a chance to settle out.
  --*****************************************************************

  -- write CAL1_DETECT_EDGE and CAL1_DETECT_STABLE in such a way that
  -- if X's are captured on the bus during functional simulation, that
  -- the logic will register this as an edge detected. Do this to allow
  -- use of this HDL with Denali memory models (Denali models drive DQ
  -- to X's on both edges of the data valid window to simulate jitter)
  -- This is only done for functional simulation purposes. **Should not**
  -- make the final synthesized logic more complicated, but it does make
  -- the HDL harder to understand b/c we have to "phrase" the logic
  -- slightly differently than when not worrying about X's
  process (cal1_data_chk_last, cal1_data_chk_last_valid, cal1_data_chk_r)
  begin
    -- no edge found if: (1) we have recorded prev edge, and rise
    -- data == fall data, (2) we haven't yet recorded prev edge, but
    -- rise/fall data is equal to either [0,1] or [1,0] (i.e. rise/fall
    -- data isn't either X's, or [0,0] or [1,1], which indicates we're
    -- in the middle of an edge, since normally rise != fall data for stg1)
    if (((cal1_data_chk_last_valid = '1') and
         (cal1_data_chk_r = cal1_data_chk_last)) or
        ((cal1_data_chk_last_valid = '0') and
         ((cal1_data_chk_r = "01") or (cal1_data_chk_r = "10")))) then
      cal1_detect_edge <= '0';
    else
      cal1_detect_edge <= '1';
    end if;
  end process;

  process (cal1_data_chk_last, cal1_data_chk_last_valid, cal1_data_chk_r)
  begin
    -- assert if we've found a region where data valid window is stable
    -- over consecutive IDELAY taps, and either rise/fall = [1,0], or [0,1]
    if (((cal1_data_chk_last_valid = '1') and
         (cal1_data_chk_r = cal1_data_chk_last)) and
        ((cal1_data_chk_r = "01") or (cal1_data_chk_r = "10"))) then
      cal1_detect_stable <= '1';
    else
      cal1_detect_stable <= '0';
    end if;
  end process;

  --*****************************************************************
  -- Find valid window: keep track of how long we've been in the same data
  -- window. If it's been long enough, then declare that we've found a valid
  -- window. Also returns whether we found a rising or falling window (only
  -- valid when found_window is asserted)
  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (cal1_state = CAL1_INIT) then
        cal1_window_cnt <= (others => '0');
        cal1_found_window <= '0';
        cal1_found_rising <= 'X';
      elsif (cal1_data_chk_last_valid = '0') then
        -- if we haven't stored a previous value of CAL1_DATA_CHK (or it got
        -- invalidated because we detected an edge, and are now looking for the
        -- second edge), then make sure FOUND_WINDOW deasserted on following
        -- clk edge (to avoid finding a false window immediately after finding
        -- an edge). Note that because of jitter, it's possible to not find an
        -- edge at the end of the IDELAY inc settling time, but to find an
        -- edge on the next clock cycle (e.g. during CAL1_FIND_FIRST_EDGE)
        cal1_window_cnt   <= (others => '0');
        cal1_found_window <= '0';
        cal1_found_rising <= 'X';
      elsif (((cal1_state = CAL1_FIRST_EDGE_IDEL_WAIT) or
              (cal1_state = CAL1_SECOND_EDGE_IDEL_WAIT)) and
             (idel_set_wait = '0')) then
        -- while finding the first and second edges, see if we can detect a
        -- stable bit window (occurs over MIN_WIN_SIZE number of taps). If
        -- so, then we're away from an edge, and can conclusively determine the
        -- starting DQS-DQ phase.
        if (cal1_detect_stable = '1') then
          cal1_window_cnt <= cal1_window_cnt + 1;
          if (cal1_window_cnt = TO_UNSIGNED(MIN_WIN_SIZE-1,4)) then
            cal1_found_window <= '1';
            if (cal1_data_chk_r = "01") then
              cal1_found_rising <= '1';
            else
              cal1_found_rising <= '0';
            end if;
          end if;
        else
          -- otherwise, we're not in a data valid window, reset the window
          -- counter, and indicate we're not currently in window. This should
          -- happen by design at least once after finding the first edge.
          cal1_window_cnt <= (others => '0');
          cal1_found_window <= '0';
          cal1_found_rising <= 'X';
        end if;
      end if;
    end if;
  end process;

  --*****************************************************************
  -- keep track of edge tap counts found, and whether we've
  -- incremented to the maximum number of taps allowed
  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (cal1_state = CAL1_INIT) then
        cal1_idel_tap_limit_hit <= '0';
        cal1_idel_tap_cnt <= (others => '0');
      elsif (cal1_dlyce_dq = '1') then
        if (cal1_dlyinc_dq = '1') then
          cal1_idel_tap_cnt <= cal1_idel_tap_cnt + 1;
          if (cal1_idel_tap_cnt = "111110") then
            cal1_idel_tap_limit_hit <= '1';
          else
            cal1_idel_tap_limit_hit <= '0';
          end if;
        else
          cal1_idel_tap_cnt <= cal1_idel_tap_cnt - 1;
          cal1_idel_tap_limit_hit <= '0';
        end if;
      end if;
    end if;
  end process;

  --*****************************************************************
  -- Pipeline for better timing - amount to decrement by if second
  -- edge not found
  --*****************************************************************
  -- if only one edge found (possible for low frequencies), then:
  --  1. Assume starting DQS-DQ phase has DQS in DQ window (aka "case 1")
  --  2. We have to decrement by (63 - first_edge_tap_cnt) + (BIT_TIME_TAPS/2)
  --     (i.e. decrement by 63-first_edge_tap_cnt to get to right edge of
  --     DQ window. Then decrement again by (BIT_TIME_TAPS/2) to get to center
  --     of DQ window.
  --  3. Clamp the above value at 63 to ensure we don't underflow IDELAY
  --     (note: clamping happens in the CAL1 state machine)
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      cal1_low_freq_idel_dec <= "0111111" -
                                ('0' & cal1_first_edge_tap_cnt) +
                                TO_UNSIGNED(BIT_TIME_TAPS/2,7);
    end if;
  end process;

  --*****************************************************************
  -- Keep track of max taps used during stage 1, use this to limit
  -- the number of taps that can be used in stage 2
  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        cal1_idel_max_tap    <= (others => '0');
        cal1_idel_max_tap_we <= '0';
      else
        -- pipeline latch enable for CAL1_IDEL_MAX_TAP - we have plenty
        -- of time, tap count gets updated, then dead cycles waiting for
        -- IDELAY output to settle
        if (cal1_idel_max_tap < cal1_idel_tap_cnt) then
          cal1_idel_max_tap_we <= '1';
        else
          cal1_idel_max_tap_we <= '0';
        end if;
        -- record maximum # of taps used for stg 1 cal
        if ((cal1_state = CAL1_DONE) and (cal1_idel_max_tap_we = '1')) then
          cal1_idel_max_tap <= cal1_idel_tap_cnt;
        end if;
      end if;
    end if;
  end process;

  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        i_calib_done(0)            <= '0';
        calib_done_tmp(0)        <= 'X';
        calib_err(0)             <= '0';
        count_dq                 <= (others => '0');
        next_count_dq            <= (others => '0');
        cal1_bit_time_tap_cnt    <= (others => 'X');
        cal1_data_chk_last       <= (others => 'X');
        cal1_data_chk_last_valid <= 'X';
        cal1_dlyce_dq            <= '0';
        cal1_dlyinc_dq           <= '0';
        cal1_dqs_dq_init_phase   <= 'X';
        cal1_first_edge_done     <= 'X';
        cal1_found_second_edge   <= 'X';
        cal1_first_edge_tap_cnt  <= (others => 'X');
        cal1_idel_dec_cnt        <= (others => 'X');
        cal1_idel_inc_cnt        <= (others => 'X');
        cal1_ref_req             <= '0';
        cal1_state               <= CAL1_IDLE;
      else
        -- default values for all "pulse" outputs
        cal1_ref_req <= '0';
        cal1_dlyce_dq <= '0';
        cal1_dlyinc_dq <= '0';

        case (cal1_state) is
          when CAL1_IDLE =>
            count_dq      <= (others => '0');
            next_count_dq <= (others => '0');
            if ((calib_start(0)) = '1') then
              i_calib_done(0) <= '0';
              calib_done_tmp(0) <= '0';
              cal1_state <= CAL1_INIT;
            end if;

          when CAL1_INIT =>
            cal1_data_chk_last_valid <= '0';
            cal1_found_second_edge <= '0';
            cal1_dqs_dq_init_phase <= '0';
            cal1_idel_inc_cnt      <= (others => '0');
            cal1_state <= CAL1_INC_IDEL;

          -- increment DQ IDELAY so that either: (1) DQS starts somewhere in
          -- first rising DQ window, or (2) DQS starts in first falling DQ
          -- window. The amount to shift is frequency dependent (and is either
          -- precalculated by MIG or possibly adjusted by the user)
          when CAL1_INC_IDEL =>
            if ((cal1_idel_inc_cnt = DQ_IDEL_INIT) and
                (idel_set_wait = '0')) then
              cal1_state <= CAL1_FIND_FIRST_EDGE;
            elsif (cal1_idel_inc_cnt /= DQ_IDEL_INIT) then
              cal1_idel_inc_cnt <= cal1_idel_inc_cnt + 1;
              cal1_dlyce_dq <= '1';
              cal1_dlyinc_dq <= '1';
            end if;

          -- look for first edge
          when CAL1_FIND_FIRST_EDGE =>
            -- Determine DQS-DQ phase if we can detect enough of a valid window
            if (cal1_found_window = '1') then
              cal1_dqs_dq_init_phase <= not(cal1_found_rising);
            end if;
            -- find first edge - if found then record position
            if (cal1_detect_edge = '1') then
              cal1_state <= CAL1_FOUND_FIRST_EDGE_WAIT;
              cal1_first_edge_done <= '0';
              cal1_first_edge_tap_cnt <= cal1_idel_tap_cnt;
              cal1_data_chk_last_valid <= '0';
            else
              -- otherwise, store the current value of DATA_CHK, increment
              -- DQ IDELAY, and compare again
              cal1_state <= CAL1_FIRST_EDGE_IDEL_WAIT;
              cal1_data_chk_last <= cal1_data_chk_r;
              -- avoid comparing against DATA_CHK_LAST for previous iteration
              cal1_data_chk_last_valid <= '1';
              cal1_dlyce_dq <= '1';
              cal1_dlyinc_dq <= '1';
            end if;

          -- wait for DQ IDELAY to settle
          when CAL1_FIRST_EDGE_IDEL_WAIT =>
            if (idel_set_wait = '0') then
              cal1_state <= CAL1_FIND_FIRST_EDGE;
            end if;

          -- delay state between finding first edge and looking for second
          -- edge. Necessary in order to invalidate CAL1_FOUND_WINDOW before
          -- starting to look for second edge
          when CAL1_FOUND_FIRST_EDGE_WAIT =>
            cal1_state <= CAL1_FIND_SECOND_EDGE;

          -- Try and find second edge
          when CAL1_FIND_SECOND_EDGE =>
            -- When looking for 2nd edge, first make sure data stabilized (by
            -- detecting valid data window) - needed to avoid false edges
            if (cal1_found_window = '1') then
              cal1_first_edge_done <= '1';
              cal1_dqs_dq_init_phase <= cal1_found_rising;
            end if;
            -- exit if run out of taps to increment
            if (cal1_idel_tap_limit_hit = '1') then
              cal1_state <= CAL1_CALC_IDEL;
            else
              -- found second edge, record the current edge count
              if ((cal1_first_edge_done = '1') and
                  (cal1_detect_edge = '1')) then
                cal1_state <= CAL1_CALC_IDEL;
                cal1_found_second_edge <= '1';
                cal1_bit_time_tap_cnt <= cal1_idel_tap_cnt -
                                         cal1_first_edge_tap_cnt + 1;
              else
                cal1_state <= CAL1_SECOND_EDGE_IDEL_WAIT;
                cal1_data_chk_last <= cal1_data_chk_r;
                cal1_data_chk_last_valid <= '1';
                cal1_dlyce_dq <= '1';
                cal1_dlyinc_dq <= '1';
              end if;
            end if;

          -- wait for DQ IDELAY to settle, then store ISERDES output
          when CAL1_SECOND_EDGE_IDEL_WAIT =>
            if ((not(idel_set_wait)) = '1') then
              cal1_state <= CAL1_FIND_SECOND_EDGE;
            end if;

          -- pipeline delay state to calculate amount to decrement DQ IDELAY
          -- NOTE: We're calculating the amount to decrement by, not the
          --  absolute setting for DQ IDELAY
          when CAL1_CALC_IDEL =>
            -- if two edges found
            if (cal1_found_second_edge = '1') then
              -- case 1: DQS was in DQ window to start with. First edge found
              -- corresponds to left edge of DQ rising window. Backup by 1.5*BT
              -- NOTE: In this particular case, it is possible to decrement
              --  "below 0" in the case where DQS delay is less than 0.5*BT,
              --  need to limit decrement to prevent IDELAY tap underflow
              if (cal1_dqs_dq_init_phase = '0') then
                cal1_idel_dec_cnt <= ('0' & cal1_bit_time_tap_cnt) +
                                     ('0' & (cal1_bit_time_tap_cnt srl 1));
              -- case 2: DQS was in wrong DQ window (in DQ falling window).
              -- First edge found is right edge of DQ rising window. Second
              -- edge is left edge of DQ rising window. Backup by 0.5*BT
              else
                cal1_idel_dec_cnt <= ('0' & (cal1_bit_time_tap_cnt srl 1));
              end if;
            -- if only one edge found - assume will always be case 1 - DQS in
            -- DQS window. Case 2 only possible if path delay on DQS > 5ns
            else
              cal1_idel_dec_cnt <= cal1_low_freq_idel_dec;
            end if;
            cal1_state <= CAL1_DEC_IDEL;

          -- decrement DQ IDELAY for final adjustment
          when CAL1_DEC_IDEL =>
            -- once adjustment is complete, we're done with calibration for
            -- this DQ, now return to IDLE state and repeat for next DQ
            -- Add underflow protection for case of 2 edges found and DQS
            -- starting in DQ window (see comments for above state) - note we
            -- have to take into account delayed value of CAL1_IDEL_TAP_CNT -
            -- gets updated one clock cycle after CAL1_DLYCE/INC_DQ
            if ((cal1_idel_dec_cnt = "0000000") or
                ((cal1_dlyce_dq = '1') and
                 (cal1_idel_tap_cnt = "000001"))) then
              cal1_state <= CAL1_DONE;
              -- stop when all DQ's calibrated, or DQ[0] cal'ed (for sim)
              if ((count_dq = TO_UNSIGNED(DQ_WIDTH-1,DQ_BITS)) or
                  (SIM_ONLY /= 0)) then
                calib_done_tmp(0) <= '1';
              else
                -- need for VHDL simulation to prevent out-of-index error
                next_count_dq <= count_dq + 1;
              end if;
            else
              -- keep decrementing until final tap count reached
              cal1_idel_dec_cnt <= cal1_idel_dec_cnt - 1;
              cal1_dlyce_dq <= '1';
              cal1_dlyinc_dq <= '0';
            end if;

          -- delay state to allow count_dq and DATA_CHK to point to the next
          -- DQ bit (allows us to potentially begin checking for an edge on
          -- next DQ right away).
          when CAL1_DONE =>
            if (idel_set_wait = '0') then
              count_dq <= next_count_dq;
              if (calib_done_tmp(0) = '1') then
                i_calib_done(0) <= '1';
                cal1_state <= CAL1_IDLE;
              else
                -- request auto-refresh after every 8-bits calibrated to
                -- avoid tRAS violation
                if (cal1_refresh = '1') then
                  cal1_ref_req <= '1';
                  if (calib_ref_done = '1') then
                    cal1_state <= CAL1_INIT;
                  end if;
                else
                  -- if no need this time for refresh, proceed to next bit
                  cal1_state <= CAL1_INIT;
                end if;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

  --***************************************************************************
  -- Second stage calibration: DQS-FPGA Clock
  -- Algorithm Description:
  --  1. Assumes a training pattern that will produce a pattern oscillating at
  --     half the core clock frequency each on rise and fall outputs, and such
  --     that rise and fall outputs are 180 degrees out of phase from each
  --     other. Note that since the calibration logic runs at half the speed
  --     of the interface, expect that data sampled with the slow clock always
  --     to be constant (either always = 1, or = 0, and rise data != fall data)
  --     unless we cross the edge of the data valid window
  --  2. Start by setting RD_DATA_SEL = 0. This selects the rising capture data
  --     sync'ed to rising edge of core clock, and falling edge data sync'ed
  --     to falling edge of core clock
  --  3. Start looking for an edge. An edge is defined as either: (1) a
  --     change in capture value or (2) an invalid capture value (e.g. rising
  --     data != falling data for that same clock cycle).
  --  4. If an edge is found, go to step (6). If edge hasn't been found, then
  --     set RD_DATA_SEL = 1, and try again.
  --  5. If no edge is found, then increment IDELAY and return to step (3)
  --  6. If an edge if found, then invert RD_DATA_SEL - this shifts the
  --     capture point 180 degrees from the edge of the window (minus duty
  --     cycle distortion, delay skew between rising/falling edge capture
  --     paths, etc.)
  --  7. If no edge is found by CAL2_IDEL_TAP_LIMIT (= 63 - # taps used for
  --     stage 1 calibration), then decrement IDELAY (without reinverting
  --     RD_DATA_SEL) by CAL2_IDEL_TAP_LIMIT/2. This guarantees we at least
  --     have CAL2_IDEL_TAP_LIMIT/2 of slack both before and after the
  --     capture point (not optimal, but best we can do not having found an
  --     of the window). This happens only for very low frequencies.
  --  8. Repeat for each DQS group.
  --  NOTE: Step 6 is not optimal. A better (and perhaps more complicated)
  --   algorithm might be to find both edges of the data valid window (using
  --   the same polarity of RD_DATA_SEL), and then decrement to the midpoint.
  --***************************************************************************

  -- RD_DATA_SEL should be tagged with FROM-TO (multi-cycle) constraint in
  -- UCF file to relax timing. This net is "pseudo-static" (after value is
  -- changed, FSM waits number of cycles before using the output).
  -- Note that we are adding one clock cycle of delay (to isolate it from
  -- the other logic CAL2_RD_DATA_SEL feeds), make sure FSM waits long
  -- enough to compensate (by default it does, it waits a few cycles more
  -- than minimum # of clock cycles)
  gen_rd_data_sel: for rd_i in 0 to DQS_WIDTH-1 generate
    attribute syn_preserve of u_ff_rd_data_sel  : label is true;
    attribute syn_replicate of u_ff_rd_data_sel : label is false;
  begin
    u_ff_rd_data_sel : FDRSE
      port map (
        Q    => rd_data_sel(rd_i),
        C    => clkdiv,
        CE   => '1',
        D    => cal2_rd_data_sel(rd_i),
        R    => '0',
        S    => '0'
        );
  end generate;

    --*****************************************************************
  -- Max number of taps used for stg2 cal dependent on number of taps
  -- used for stg1 (give priority to stg1 cal - let it use as many
  -- taps as it needs - the remainder of the IDELAY taps can be used
  -- by stg2)
  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      cal2_idel_tap_limit <= "111111" - cal1_idel_max_tap;
    end if;
  end process;

  --*****************************************************************
  -- second stage calibration uses readback pattern of "1100" (i.e.
  -- 1st rising = 1, 1st falling = 1, 2nd rising = 0, 2nd falling = 0)
  -- only look at the first bit of each DQS group
  --*****************************************************************

  -- deasserted when captured data has changed since IDELAY was
  -- incremented, or when we're right on the edge (i.e. rise data =
  -- fall data).
  cal2_detect_edge <= '1' when
                      ((((rdd_rise_q1 /= cal2_rd_data_rise_last_pos) or
                         (rdd_fall_q1 /= cal2_rd_data_fall_last_pos)) and
                        (cal2_rd_data_last_valid_pos = '1') and
                        (cal2_curr_sel = '0')) or
                       (((rdd_rise_q1 /= cal2_rd_data_rise_last_neg) or
                         (rdd_fall_q1 /= cal2_rd_data_fall_last_neg)) and
                        (cal2_rd_data_last_valid_neg = '1') and
                        (cal2_curr_sel = '1')) or
                       (rdd_rise_q1 /= rdd_fall_q1))
                      else '0';

  --*****************************************************************
  -- keep track of edge tap counts found, and whether we've
  -- incremented to the maximum number of taps allowed
  -- NOTE: Assume stage 2 cal always increments the tap count (never
  --       decrements) when searching for edge of the data valid window
  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (cal2_state = CAL2_INIT) then
        cal2_idel_tap_limit_hit <= '0';
        cal2_idel_tap_cnt <= (others => '0');
      elsif (cal2_dlyce_dqs = '1') then
        cal2_idel_tap_cnt <= cal2_idel_tap_cnt + 1;
        if (cal2_idel_tap_cnt = cal2_idel_tap_limit - 1) then
          cal2_idel_tap_limit_hit <= '1';
        else
          cal2_idel_tap_limit_hit <= '0';
        end if;
      end if;
    end if;
  end process;

  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        i_calib_done(1)             <= '0';
        calib_done_tmp(1)           <= 'X';
        calib_err(1)                <= '0';
        count_dqs                   <= (others => '0');
        next_count_dqs              <= (others => '0');
        cal2_dlyce_dqs              <= '0';
        cal2_dlyinc_dqs             <= '0';
        cal2_idel_dec_cnt           <= (others => 'X');
        cal2_rd_data_last_valid_neg <= 'X';
        cal2_rd_data_last_valid_pos <= 'X';
        cal2_rd_data_sel            <= (others => '0');
        cal2_ref_req                <= '0';
        cal2_state                  <= CAL2_IDLE;
      else
        cal2_ref_req <= '0';
        cal2_dlyce_dqs <= '0';
        cal2_dlyinc_dqs <= '0';

        case (cal2_state) is
          when CAL2_IDLE =>
            count_dqs      <= (others => '0');
            next_count_dqs <= (others => '0');
            if (calib_start(1) = '1') then
              cal2_rd_data_sel  <= (others => '0');
              i_calib_done(1)   <= '0';
              calib_done_tmp(1) <= '0';
              cal2_state <= CAL2_INIT;
            end if;

          -- Pass through this state every time we calibrate a new DQS group
          when CAL2_INIT =>
            cal2_curr_sel <= '0';
            cal2_rd_data_last_valid_neg <= '0';
            cal2_rd_data_last_valid_pos <= '0';
            cal2_state <= CAL2_INIT_IDEL_WAIT;

          -- Stall state only used if calibration run more than once. Can take
          -- this state out if design never runs calibration more than once.
          -- We need this state to give time for MUX'ed data to settle after
          -- resetting RD_DATA_SEL
          when CAL2_INIT_IDEL_WAIT =>
            if (idel_set_wait = '0') then
              cal2_state <= CAL2_FIND_EDGE_POS;
            end if;

          -- Look for an edge - first check "positive-edge" stage 2 capture
          when CAL2_FIND_EDGE_POS =>
            -- if found an edge, then switch to the opposite edge stage 2
            -- capture and we're done - no need to decrement the tap count,
            -- since switching to the opposite edge will shift the capture
            -- point by 180 degrees
            if (cal2_detect_edge = '1') then
              cal2_curr_sel <= '1';
              cal2_state <= CAL2_DONE;
              -- set all DQS groups to be the same for simulation
              if (SIM_ONLY /= 0) then
                cal2_rd_data_sel <= (others => '1');
              else
                cal2_rd_data_sel(TO_INTEGER(count_dqs)) <= '1';
              end if;
              if ((count_dqs = TO_UNSIGNED(DQS_WIDTH-1,DQS_BITS_FIX)) or
                  (SIM_ONLY /= 0)) then
                calib_done_tmp(1) <= '1';
              else
                -- MIG 2.1: Fix for simulation out-of-bounds error when
                -- SIM_ONLY=0, and DQS_WIDTH=(power of 2) (needed for VHDL)
                next_count_dqs <= count_dqs + 1;
              end if;
            else
              -- otherwise, invert polarity of stage 2 capture and look for
              -- an edge with opposite capture clock polarity
              cal2_curr_sel <= '1';
              cal2_rd_data_sel(TO_INTEGER(count_dqs)) <= '1';
              cal2_state <= CAL2_FIND_EDGE_IDEL_WAIT_POS;
              cal2_rd_data_rise_last_pos  <= rdd_rise_q1;
              cal2_rd_data_fall_last_pos  <= rdd_fall_q1;
              cal2_rd_data_last_valid_pos <= '1';
            end if;

          -- Give time to switch from positive-edge to negative-edge second
          -- stage capture (need time for data to filter though pipe stages)
          when CAL2_FIND_EDGE_IDEL_WAIT_POS =>
            if (idel_set_wait = '0') then
              cal2_state <= CAL2_FIND_EDGE_NEG;
            end if;

          -- Look for an edge - check "negative-edge" stage 2 capture
          when CAL2_FIND_EDGE_NEG =>
            if (cal2_detect_edge = '1') then
              cal2_curr_sel <= '0';
              cal2_state <= CAL2_DONE;
              -- set all DQS groups to be the same for simulation
              if (SIM_ONLY /= 0) then
                cal2_rd_data_sel <= (others => '0');
              else
                cal2_rd_data_sel(TO_INTEGER(count_dqs)) <= '0';
              end if;
              if ((count_dqs = TO_UNSIGNED(DQS_WIDTH-1,DQS_BITS_FIX)) or
                  (SIM_ONLY /= 0)) then
                calib_done_tmp(1) <= '1';
              else
                -- MIG 2.1: Fix for simulation out-of-bounds error when
                -- SIM_ONLY=0, and DQS_WIDTH=(power of 2) (needed for VHDL)
                next_count_dqs <= count_dqs + 1;                
              end if;
            elsif (cal2_idel_tap_limit_hit = '1') then
              -- otherwise, if we've run out of taps, then immediately
              -- backoff by half # of taps used - that's our best estimate
              -- for optimal calibration point. Doesn't matter whether which
              -- polarity we're using for capture (we don't know which one is
              -- best to use)
              cal2_idel_dec_cnt <= ('0' & cal2_idel_tap_limit(5 downto 1));
              cal2_state <= CAL2_DEC_IDEL;
              if ((count_dqs = TO_UNSIGNED(DQS_WIDTH-1,DQS_BITS_FIX)) or
                  (SIM_ONLY /= 0)) then
                calib_done_tmp(1) <= '1';
              else
                -- MIG 2.1: Fix for simulation out-of-bounds error when
                -- SIM_ONLY=0, and DQS_WIDTH=(power of 2) (needed for VHDL)   
                next_count_dqs <= count_dqs + 1;              
              end if;
            else
              -- otherwise, increment IDELAY, and start looking for edge again
              cal2_curr_sel <= '0';
              cal2_rd_data_sel(to_integer(count_dqs)) <= '0';
              cal2_state <= CAL2_FIND_EDGE_IDEL_WAIT_NEG;
              cal2_rd_data_rise_last_neg <= rdd_rise_q1;
              cal2_rd_data_fall_last_neg <= rdd_fall_q1;
              cal2_rd_data_last_valid_neg <= '1';
              cal2_dlyce_dqs <= '1';
              cal2_dlyinc_dqs <= '1';
            end if;

          when CAL2_FIND_EDGE_IDEL_WAIT_NEG =>
            if (idel_set_wait = '0') then
              cal2_state <= CAL2_FIND_EDGE_POS;
            end if;

          -- if no edge found, then decrement by half # of taps used
          when CAL2_DEC_IDEL =>
            if (cal2_idel_dec_cnt = "000000") then
              cal2_state <= CAL2_DONE;
            else
              cal2_idel_dec_cnt <= cal2_idel_dec_cnt - 1;
              cal2_dlyce_dqs <= '1';
              cal2_dlyinc_dqs <= '0';
            end if;

          -- delay state to allow count_dqs and ISERDES data to point to next
          -- DQ bit (DQS group) before going to INIT
          when CAL2_DONE =>
            if (idel_set_wait = '0') then
              count_dqs <= next_count_dqs;
              if (calib_done_tmp(1) = '1') then
                i_calib_done(1) <= '1';
                cal2_state <= CAL2_IDLE;
              else
                -- request auto-refresh after every DQS group calibrated to
                -- avoid tRAS violation
                cal2_ref_req <= '1';
                if (calib_ref_done = '1') then
                  cal2_state <= CAL2_INIT;
                end if;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

  --***************************************************************************
  -- Stage 3 calibration: Read Enable
  -- Description:
  -- read enable calibration determines the "round-trip" time (in # of CLK0
  -- cycles) between when a read command is issued by the controller, and
  -- when the corresponding read data is synchronized by into the CLK0 domain
  -- this is a long delay chain to delay read enable signal from controller/
  -- initialization logic (i.e. this is used for both initialization and
  -- during normal controller operation). Stage 3 calibration logic decides
  -- which delayed version is appropriate to use (which is affected by the
  -- round trip delay of DQ/DQS) as a "valid" signal to tell rest of logic
  -- when the captured data output from ISERDES is valid.
  --***************************************************************************

  --*****************************************************************
  -- Delay chains: Use shift registers
  -- Two sets of delay chains are used:
  --  1. One to delay RDEN from PHY_INIT module for calibration
  --     purposes (delay required for RDEN for calibration is different
  --     than during normal operation)
  --  2. One per DQS group to delay RDEN from controller for normal
  --     operation - the value to delay for each DQS group can be different
  --     as is determined during calibration
  --*****************************************************************

  --*****************************************************************
  -- First delay chain, use only for calibration
  -- input = asserted on rising edge of RDEN from PHY_INIT module
  --*****************************************************************

  process (clk)
  begin
    if (rising_edge(clk)) then
      ctrl_rden_r       <= ctrl_rden;
      phy_init_rden_r   <= phy_init_rden;
      phy_init_rden_r1  <= phy_init_rden_r;
      calib_rden_edge_r <= phy_init_rden_r and not(phy_init_rden_r1);
    end if;
  end process;

  -- Calibration shift register used for both Stage 3 and Stage 4 cal
  -- (not strictly necessary for stage 4, but use as an additional check
  -- to make sure we're checking for correct data on the right clock cycle)
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (i_calib_done(2) = '0') then
        calib_rden_srl_a <= cal3_rden_srl_a;
      else
        calib_rden_srl_a <= cal4_rden_srl_a;
      end if;
    end if;
  end process;

  -- Flops for targetting of multi-cycle path in UCF
  gen_cal_rden_dly: for cal_rden_ff_i in 0 to 4 generate
    attribute syn_preserve of u_ff_cal_rden_dly  : label is true;
    attribute syn_replicate of u_ff_cal_rden_dly : label is false;
  begin
    u_ff_cal_rden_dly : FDRSE
      port map (
        Q    => calib_rden_srl_a_r(cal_rden_ff_i),
        C    => clkdiv,
        CE   => '1',
        D    => calib_rden_srl_a(cal_rden_ff_i),
        R    => '0',
        S    => '0'
        );
  end generate;

  u_calib_rden_srl : SRLC32E
    port map (
      Q    => calib_rden_srl_out,
      Q31  => open,
      A    => std_logic_vector(calib_rden_srl_a_r),
      CE   => '1',
      CLK  => clk,
      D    => calib_rden_edge_r
    );

  u_calib_rden_srl_out_r : FDRSE
    port map (
      Q    => calib_rden_srl_out_r,
      C    => clk,
      CE   => '1',
      D    => calib_rden_srl_out,
      R    => '0',
      S    => '0'
    );

  -- convert to CLKDIV domain. Two version are generated because we need
  -- to be able to tell exactly which fast (clk) clock cycle the read
  -- enable was asserted in. Only one of CALIB_DATA_VALID or
  -- CALIB_DATA_VALID_STGD will be asserted for any given shift value
  process (clk)
  begin
    if (rising_edge(clk)) then
      calib_rden_srl_out_r1 <= calib_rden_srl_out_r;
    end if;
  end process;

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      calib_rden_valid      <= calib_rden_srl_out_r;
      calib_rden_valid_stgd <= calib_rden_srl_out_r1;
    end if;
  end process;

  --*****************************************************************
  -- Second set of delays chain, use for normal reads
  -- input = RDEN from controller
  --*****************************************************************

  -- Flops for targetting of multi-cycle path in UCF
  gen_rden_dly: for rden_ff_i in 0 to (5*DQS_WIDTH)-1 generate
    attribute syn_preserve of u_ff_rden_dly  : label is true;
    attribute syn_replicate of u_ff_rden_dly : label is false;
  begin
    u_ff_rden_dly : FDRSE
      port map (
        Q    => rden_dly_r(rden_ff_i),
        C    => clkdiv,
        CE   => '1',
        D    => rden_dly(rden_ff_i),
        R    => '0',
        S    => '0'
        );
  end generate;

  -- NOTE: Comment this section explaining purpose of SRL's
  gen_rden: for rden_i in 0 to DQS_WIDTH-1 generate
    signal rden_srl_a : std_logic_vector(4 downto 0);
    attribute syn_preserve of u_calib_rden_r  : label is true;
  begin
    rden_srl_a <= (rden_dly_r((rden_i*5)+4) &
                   rden_dly_r((rden_i*5)+3) &
                   rden_dly_r((rden_i*5)+2) &
                   rden_dly_r((rden_i*5)+1) &
                   rden_dly_r((rden_i*5)));

    u_rden_srl : SRLC32E
      port map (
        Q    => rden_srl_out(rden_i),
        Q31  => open,
        A    => rden_srl_a,
        CE   => '1',
        CLK  => clk,
        D    => ctrl_rden_r
      );
    u_calib_rden_r : FDRSE
      port map (
        Q    => calib_rden(rden_i),
        C    => clk,
        CE   => '1',
        D    => rden_srl_out(rden_i),
        R    => '0',
        S    => '0'
      );
  end generate;

  --*****************************************************************
  -- indicates that current received data is the correct pattern. Check both
  -- rising and falling data for first DQ in each DQS group. Note that
  -- we're checking using a pipelined version of read data, so need to take
  -- this inherent delay into account in determining final read valid delay
  -- Data is written to the memory in the following order (first -> last):
  --   0x1, 0xE, 0xE, 0x1, 0x1, 0xE, 0xE, 0x1
  -- Looking just at LSb, expect data in sequence (in binary):
  --   1, 0, 0, 1, 1, 0, 0, 1
  -- Check for the presence of the first 7 words, and compensate read valid
  -- delay accordingly. Don't check last falling edge data, it may be
  -- corrupted by the DQS tri-state glitch at end of read postamble
  -- (glitch protection not yet active until stage 4 cal)
  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      rdd_rise_q1_r  <= rdd_rise_q1;
      rdd_fall_q1_r  <= rdd_fall_q1;
      rdd_rise_q2_r  <= rdd_rise_q2;
      rdd_fall_q2_r  <= rdd_fall_q2;
      rdd_rise_q1_r1 <= rdd_rise_q1_r;
      rdd_fall_q1_r1 <= rdd_fall_q1_r;
    end if;
  end process;

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      -- For the following sequence from memory:
      --   rise[0], fall[0], rise[1], fall[1]
      -- if data is aligned out of fabric ISERDES:
      --   RDD_RISE_Q2 = rise[0]
      --   RDD_FALL_Q2 = fall[0]
      --   RDD_RISE_Q1 = rise[1]
      --   RDD_FALL_Q1 = fall[1]
      if ((rdd_rise_q2_r = '1') and
          (rdd_fall_q2_r = '0') and
          (rdd_rise_q1_r = '0') and
          (rdd_fall_q1_r = '1') and
          (rdd_rise_q2   = '1') and
          (rdd_fall_q2   = '0') and
          (rdd_rise_q1   = '0')) then
        cal3_data_match <= '1';
      else
        cal3_data_match <= '0';
      end if;
      -- if data is staggered out of fabric ISERDES:
      --   RDD_RISE_Q1_R = rise[0]
      --   RDD_FALL_Q1_R = fall[0]
      --   RDD_RISE_Q2   = rise[1]
      --   RDD_FALL_Q2   = fall[1]
      if ((rdd_rise_q1_r1 = '1') and
          (rdd_fall_q1_r1 = '0') and
          (rdd_rise_q2_r  = '0') and
          (rdd_fall_q2_r  = '1') and
          (rdd_rise_q1_r  = '1') and
          (rdd_fall_q1_r  = '0') and
          (rdd_rise_q2    = '0')) then
        cal3_data_match_stgd <= '1';
      else
        cal3_data_match_stgd <= '0';
      end if;
    end if;
  end process;

  cal3_rden_dly <= cal3_rden_srl_a - CAL3_RDEN_SRL_DLY_DELTA;
  cal3_data_valid <= (calib_rden_valid or calib_rden_valid_stgd);
  cal3_match_found <= '1' when
                      (((calib_rden_valid = '1') and
                        (cal3_data_match = '1')) or
                       ((calib_rden_valid_stgd = '1') and
                        (cal3_data_match_stgd = '1')))
                      else '0';

  -- when calibrating, check to see which clock cycle (after the read is
  -- issued) does the expected data pattern arrive. Record this result
  -- NOTE: Can add error checking here in case valid data not found on any
  --  of the available pipeline stages
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        cal3_rden_srl_a <= (others => 'X');
        cal3_state      <= CAL3_IDLE;
        i_calib_done(2) <= '0';
        calib_err_2(0)  <= '0';
        count_rden      <= (others => '0');
        rden_dly        <= (others => '0');
      else

        case (cal3_state) is
          when CAL3_IDLE =>
            count_rden <= (others => '0');
            if (calib_start(2) = '1') then
              i_calib_done(2) <= '0';
              cal3_state <= CAL3_INIT;
            end if;

          when CAL3_INIT =>
            cal3_rden_srl_a <= TO_UNSIGNED(RDEN_BASE_DELAY,5);
            -- let SRL pipe clear after loading initial shift value
            cal3_state <= CAL3_RDEN_PIPE_CLR_WAIT;

          when CAL3_DETECT =>
            if (cal3_data_valid = '1') then
              -- if match found at the correct clock cycle
              if (cal3_match_found = '1') then
                -- For simulation, load SRL addresses for all DQS with same val
                if (SIM_ONLY /= 0) then
                  for i in 0 to DQS_WIDTH-1 loop
                    rden_dly((i*5))   <= cal3_rden_dly(0);
                    rden_dly((i*5)+1) <= cal3_rden_dly(1);
                    rden_dly((i*5)+2) <= cal3_rden_dly(2);
                    rden_dly((i*5)+3) <= cal3_rden_dly(3);
                    rden_dly((i*5)+4) <= cal3_rden_dly(4);
                  end loop;
                else
                  rden_dly((to_integer(count_rden)*5))   <= cal3_rden_dly(0);
                  rden_dly((to_integer(count_rden)*5)+1) <= cal3_rden_dly(1);
                  rden_dly((to_integer(count_rden)*5)+2) <= cal3_rden_dly(2);
                  rden_dly((to_integer(count_rden)*5)+3) <= cal3_rden_dly(3);
                  rden_dly((to_integer(count_rden)*5)+4) <= cal3_rden_dly(4);
                end if;

                -- Use for stage 4 calibration
                calib_rden_dly((to_integer(count_rden)*5))   <=
                  cal3_rden_srl_a(0);
                calib_rden_dly((to_integer(count_rden)*5)+1) <=
                  cal3_rden_srl_a(1);
                calib_rden_dly((to_integer(count_rden)*5)+2) <=
                  cal3_rden_srl_a(2);
                calib_rden_dly((to_integer(count_rden)*5)+3) <=
                  cal3_rden_srl_a(3);
                calib_rden_dly((to_integer(count_rden)*5)+4) <=
                  cal3_rden_srl_a(4);
                cal3_state <= CAL3_DONE;
              else
                -- If we run out of stages to shift, without finding correct
                -- result, the stop and assert error
                if (cal3_rden_srl_a = "11111") then
                  calib_err_2(0) <= '1';
                  cal3_state <= CAL3_IDLE;
                else
                  -- otherwise, increase the shift value and try again
                  cal3_rden_srl_a <= cal3_rden_srl_a + 1;
                  cal3_state      <= CAL3_RDEN_PIPE_CLR_WAIT;
                end if;
              end if;
            end if;

          -- give additional time for RDEN_R pipe to clear from effects of
          -- previous pipeline or IDELAY tap change
          when CAL3_RDEN_PIPE_CLR_WAIT =>
            if (calib_rden_pipe_cnt = "00000") then
              cal3_state <= CAL3_DETECT;
            end if;

          when CAL3_DONE =>
            if ((count_rden = TO_UNSIGNED(DQS_WIDTH-1,DQS_BITS_FIX)) or
                (SIM_ONLY /= 0)) then
              i_calib_done(2) <= '1';
              cal3_state    <= CAL3_IDLE;
            else
              count_rden <= count_rden + 1;
              cal3_state <= CAL3_INIT;
            end if;
        end case;
      end if;
    end if;
  end process;

  --*****************************************************************
  -- Last part of stage 3 calibration - compensate for differences
  -- in delay between different DQS groups. Assume that in the worst
  -- case, DQS groups can only differ by one clock cycle. Data for
  -- certain DQS groups must be delayed by one clock cycle.
  -- NOTE: May need to increase allowable variation to greater than
  --  one clock cycle in certain customer designs.
  -- Algorithm is:
  --   1. Record shift delay value for DQS[0]
  --   2. Compare each DQS[x] delay value to that of DQS[0]:
  --     - If different, than record this fact (RDEN_MUX)
  --     - If greater than DQS[0], set RDEN_INC. Assume greater by
  --       one clock cycle only - this is a key assumption, assume no
  --       more than a one clock cycle variation.
  --     - If less than DQS[0], set RDEN_DEC
  --   3. After calibration is complete, set control for DQS group
  --      delay (CALIB_RDEN_SEL):
  --     - If RDEN_DEC = 1, then assume that DQS[0] is the lowest
  --       delay (and at least one other DQS group has a higher
  --       delay).
  --     - If RDEN_INC = 1, then assume that DQS[0] is the highest
  --       delay (and that all other DQS groups have the same or
  --       lower delay).
  --     - If both RDEN_INC and RDEN_DEC = 1, then flag error
  --       (variation is too high for this algorithm to handle)
  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        calib_err_2(1) <= '0';
        calib_rden_sel <= (others => 'X');
        rden_dec       <= '0';
        rden_dly_0     <= (others => 'X');
        rden_inc       <= '0';
        rden_mux       <= (others => '0');
      else
        -- if a match if found, then store the value of rden_dly
        if (i_calib_done(2) = '0') then
          if ((cal3_state = CAL3_DETECT) and (cal3_match_found = '1')) then
            -- store the value for DQS[0] as a reference
            if (count_rden = TO_UNSIGNED(0,DQS_BITS_FIX)) then
              -- for simulation, RDEN calibration only happens for DQS[0]
              -- set RDEN_MUX for all DQS groups to be the same as DQS[0]
              if (SIM_ONLY /= 0) then
                rden_mux <= (others => '0');
              else
                -- otherwise, load values for DQS[0]
                rden_dly_0 <= cal3_rden_srl_a;
                rden_mux(0) <= '0';
              end if;
            elsif (SIM_ONLY = 0) then
              -- for all other DQS groups, compare RDEN_DLY delay value with
              -- that of DQS[0]
              if (rden_dly_0 /= cal3_rden_srl_a) then
                -- record that current DQS group has a different delay
                -- than DQS[0] (the "reference" DQS group)
                rden_mux(TO_INTEGER(count_rden)) <= '1';
                if (rden_dly_0 > cal3_rden_srl_a) then
                  rden_inc <= '1';
                elsif (rden_dly_0 < cal3_rden_srl_a) then
                  rden_dec <= '1';
                -- otherwise, if current DQS group has same delay as DQS[0],
                -- then rden_mux[count_rden] remains at 0 (since rden_mux
                -- array contents initialized to 0)
                end if;
              end if;
            end if;
          end if;
        else
          -- Otherwise - if we're done w/ stage 2 calibration:
          -- set final value for RDEN data delay
          -- flag error if there's more than one cycle variation from DQS[0]
          calib_err_2(1) <= (rden_inc and rden_dec);
          if (rden_inc = '1') then
            -- if DQS[0] delay represents max delay
            calib_rden_sel <= not(rden_mux);
          else
            -- if DQS[0] delay represents min delay (or all the delays are
            -- the same between DQS groups)
            calib_rden_sel <= rden_mux;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- flag error for stage 3 if appropriate
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      calib_err(2) <= calib_err_2(0) or calib_err_2(1);
    end if;
  end process;

  --***************************************************************************
  -- Stage 4 calibration: DQS gate
  --***************************************************************************

  --*****************************************************************
  -- indicates that current received data is the correct pattern. Same as
  -- for READ VALID calibration, except that the expected data sequence is
  -- different since DQS gate is asserted after the 6th word.
  -- Data sequence:
  --  Arrives from memory (at FPGA input) (R, F): 1 0 0 1 1 0 0 1
  --  After gating the sequence looks like: 1 0 0 1 1 0 1 0 (7th word =
  --   5th word, 8th word = 6th word)
  -- What is the gate timing is off? Need to make sure we can distinquish
  -- between the results of correct vs. incorrect gate timing. We also use
  -- the "read_valid" signal from stage 3 calibration to help us determine
  -- when to check for a valid sequence for stage 4 calibration (i.e. use
  -- CAL4_DATA_VALID in addition to CAL4_DATA_MATCH/CAL4_DATA_MATCH_STGD)
  -- Note that since the gate signal from the CLK0 domain is synchronized
  -- to the falling edge of DQS, that the effect of the gate will only be
  -- seen starting with a rising edge data (although it is possible
  -- the GATE IDDR output could go metastable and cause a unexpected result
  -- on the first rising and falling edges after the gate is enabled). 
  -- Also note that the actual DQS glitch can come more than 0.5*tCK after 
  -- the last falling edge of DQS and the constraint for this path is can 
  -- be > 0.5*tCK; however, this means when calibrating, the output of the 
  -- GATE IDDR may miss the setup time requirement of the rising edge flop 
  -- and only meet it for the falling edge flop. Therefore the rising
  -- edge data immediately following the assertion of the gate can either
  -- be a 1 or 0 (can rely on either)
  -- As the timing on the gate is varied, we expect to see (sequence of
  -- captured read data shown below):
  --       - 1 0 0 1 1 0 0 1 (gate is really early, starts and ends before
  --                          read burst even starts)
  --       - x 0 0 1 1 0 0 1 (gate pulse starts before the burst, and ends
  --       - x y 0 1 1 0 0 1  sometime during the burst; x,y = 0, or 1, but 
  --       - x y x 1 1 0 0 1  all bits that show an x are the same value, 
  --       - x y x y 1 0 0 1  and y are the same value)
  --       - x y x y x 0 0 1
  --       - x y x y x y 0 1 (gate starts just before start of burst)
  --       - 1 0 x 0 x 0 x 0 (gate starts after 1st falling word. The "x"
  --                          represents possiblity that gate may not disable
  --                          clock for 2nd rising word in time)
  --       - 1 0 0 1 x 1 x 1 (gate starts after 2nd falling word)
  --       - 1 0 0 1 1 0 x 0 (gate starts after 3rd falling word - GOOD!!)
  --       - 1 0 0 1 1 0 0 1 (gate starts after burst is already done)
  --*****************************************************************
  
  cal4_data_valid <= calib_rden_valid or calib_rden_valid_stgd;
  cal4_data_good <= '1' when
                    (((calib_rden_valid = '1') and
                      (cal4_data_match = '1')) or
                     ((calib_rden_valid_stgd = '1') and
                      (cal4_data_match_stgd = '1')))
                    else '0';

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      -- if data is aligned out of fabric ISERDES:
      if ((rdd_rise_q2_r = '1') and
          (rdd_fall_q2_r = '0') and
          (rdd_rise_q1_r = '0') and
          (rdd_fall_q1_r = '1') and
          (rdd_rise_q2   = '1') and
          (rdd_fall_q2   = '0') and
          -- MIG 2.1: Last rising edge data value not
          -- guaranteed to be certain value at higher
          -- frequencies
          -- (rdd_rise_q1 = '0') and
          (rdd_fall_q1   = '0')) then
        cal4_data_match <= '1';
      else
        cal4_data_match <= '0';
      end if;
      -- if data is staggered out of fabric ISERDES:
      if ((rdd_rise_q1_r1 = '1') and
          (rdd_fall_q1_r1 = '0') and
          (rdd_rise_q2_r  = '0') and
          (rdd_fall_q2_r  = '1') and
          (rdd_rise_q1_r  = '1') and
          (rdd_fall_q1_r  = '0') and
          -- MIG 2.1: Last rising edge data value not
          -- guaranteed to be certain value at higher
          -- frequencies          
          -- (rdd_rise_q2 = '0') and
          (rdd_fall_q2    = '0')) then
        cal4_data_match_stgd <= '1';
      else
        cal4_data_match_stgd <= '0';
      end if;
    end if;
  end process;

  --*****************************************************************
  -- DQS gate enable generation:
  -- This signal gets synchronized to DQS domain, and drives IDDR
  -- register that in turn asserts/deasserts CE to all 4 or 8 DQ
  -- IDDR's in that DQS group.
  --   1. During normal (post-cal) operation, this is only for 2 clock
  --      cycles following the end of a burst. Check for falling edge
  --      of RDEN. But must also make sure NOT assert for a read-idle-
  --      read (two non-consecutive reads, separated by exactly one
  --      idle cycle) - in this case, don't assert the gate because:
  --      (1) we don't have enough time to deassert the gate before the
  --          first rising edge of DQS for second burst (b/c of fact
  --          that DQS gate is generated in the fabric only off rising
  --          edge of CLK0 - if we somehow had an ODDR in fabric, we
  --          could pull this off, (2) assumption is that the DQS glitch
  --          will not rise enough to cause a glitch because the
  --          post-amble of the first burst is followed immediately by
  --          the pre-amble of the next burst
  --   2. During stage 4 calibration, assert for 3 clock cycles
  --      (assert gate enable one clock cycle early), since we gate out
  --      the last two words (in addition to the crap on the DQ bus after
  --      the DQS read postamble).
  -- NOTE: PHY_INIT_RDEN and CTRL_RDEN have slightly different timing w/r
  --  to when they are asserted w/r to the start of the read burst
  --  (PHY_INIT_RDEN is one cycle earlier than CTRL_RDEN).
  --*****************************************************************

  -- register for timing purposes for fast clock path - currently only
  -- calib_done_r[2] used
  process (clk)
  begin
    if (rising_edge(clk)) then
      calib_done_r <= i_calib_done;
    end if;
  end process;

  calib_ctrl_rden <= ctrl_rden;
  calib_init_rden <= calib_done_r(2) and phy_init_rden;

  calib_ctrl_rden_negedge <= not(calib_ctrl_rden) and calib_ctrl_rden_r;
  -- check for read-idle-read before asserting DQS pulse at end of read
  calib_ctrl_gate_pulse <= calib_ctrl_rden_negedge_r and
                           not(calib_ctrl_rden);
  process (clk)
  begin
    if (rising_edge(clk)) then
      calib_ctrl_rden_r         <= calib_ctrl_rden;
      calib_ctrl_rden_negedge_r <= calib_ctrl_rden_negedge;
      calib_ctrl_gate_pulse_r   <= calib_ctrl_gate_pulse;
    end if;
  end process;

  calib_init_gate_pulse <= not(calib_init_rden) and calib_init_rden_r;
  process (clk)
  begin
    if (rising_edge(clk)) then
      calib_init_rden_r        <= calib_init_rden;
      calib_init_gate_pulse_r  <= calib_init_gate_pulse;
      calib_init_gate_pulse_r1 <= calib_init_gate_pulse_r;
    end if;
  end process;

  -- Gate is asserted: (1) during cal, for 3 cycles, starting 1 cycle
  -- after falling edge of CTRL_RDEN, (2) during normal ops, for 2
  -- cycles, starting 2 cycles after falling edge of CTRL_RDEN
  gate_srl_in <= '0' when (((calib_ctrl_gate_pulse or
                             calib_ctrl_gate_pulse_r) or
                            (calib_init_gate_pulse   or
                             calib_init_gate_pulse_r or
                             calib_init_gate_pulse_r1)) = '1') else '1';

  --*****************************************************************
  -- generate DQS enable signal for each DQS group
  -- There are differences between DQS gate signal for calibration vs. during
  -- normal operation:
  --  * calibration gates the second to last clock cycle of the burst,
  --    rather than after the last word (e.g. for a 8-word, 4-cycle burst,
  --    cycle 4 is gated for calibration; during normal operation, cycle
  --    5 (i.e. cycle after the last word) is gated)
  -- enable for DQS is deasserted for two clock cycles, except when
  -- we have the preamble for the next read immediately following
  -- the postamble of the current read - assume DQS does not glitch
  -- during this time, that it stays low. Also if we did have to gate
  -- the DQS for this case, then we don't have enough time to deassert
  -- the gate in time for the first rising edge of DQS for the second
  -- read
  --*****************************************************************

  -- Flops for targetting of multi-cycle path in UCF
  gen_gate_dly: for gate_ff_i in 0 to (5*DQS_WIDTH)-1 generate
    attribute syn_preserve of u_ff_gate_dly  : label is true;
    attribute syn_replicate of u_ff_gate_dly : label is false;
  begin
    u_ff_gate_dly : FDRSE
      port map (
        Q    => gate_dly_r(gate_ff_i),
        C    => clkdiv,
        CE   => '1',
        D    => gate_dly(gate_ff_i),
        R    => '0',
        S    => '0'
      );
  end generate;

  gen_gate: for gate_i in 0 to DQS_WIDTH-1 generate
    signal gate_srl_a : std_logic_vector(4 downto 0);
    attribute syn_preserve of u_en_dqs_ff  : label is true;
    attribute syn_replicate of u_en_dqs_ff : label is false;
  begin
    gate_srl_a <= (gate_dly_r((gate_i*5)+4) &
                   gate_dly_r((gate_i*5)+3) &
                   gate_dly_r((gate_i*5)+2) &
                   gate_dly_r((gate_i*5)+1) &
                   gate_dly_r((gate_i*5)));
    u_gate_srl : SRLC32E
      port map (
        Q    => gate_srl_out(gate_i),
        Q31  => open,
        A    => gate_srl_a,
        CE   => '1',
        CLK  => clk,
        D    => gate_srl_in
      );

    gen_gate_base_dly_gt3: if (GATE_BASE_DELAY > 0) generate
      attribute syn_preserve of u_gate_srl_ff  : label is true;
    begin
      -- add flop between SRL32 and EN_DQS flop (which is located near the
      -- DDR2 IOB's)
      u_gate_srl_ff : FDRSE
        port map (
          Q    => gate_srl_out_r(gate_i),
          C    => clk,
          CE   => '1',
          D    => gate_srl_out(gate_i),
          R    => '0',
          S    => '0'
          );
    end generate;
    gen_gate_base_dly_le3: if (GATE_BASE_DELAY <= 0) generate
      gate_srl_out_r(gate_i) <= gate_srl_out(gate_i);
    end generate;

    u_en_dqs_ff : FDRSE
      port map (
        Q    => en_dqs(gate_i),
        C    => clk,
        CE   => '1',
        D    => gate_srl_out_r(gate_i),
        R    => '0',
        S    => '0'
      );
  end generate;

  --*****************************************************************
  -- Find valid window: keep track of how long we've been in the same data
  -- window. If it's been long enough, then declare that we've found a stable
  -- valid window - in particular, that we're past any region of instability
  -- associated with the edge of the window. Use only when finding left edge
  --*****************************************************************

  -- reset before we start to look for window
  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (cal4_state = CAL4_INIT) then
        cal4_window_cnt    <= (others => '0');
        cal4_stable_window <= '0';
      elsif ((cal4_state = CAL4_FIND_EDGE) and (cal4_seek_left = '1')) then
        -- if we're looking for left edge, and incrementing IDELAY, count
        -- consecutive taps over which we're in the window
        if (cal4_data_valid = '1') then
          if (cal4_data_good = '1') then
            cal4_window_cnt <= cal4_window_cnt + 1;
          else
            cal4_window_cnt <= (others => '0');
          end if;
        end if;

        if (cal4_window_cnt = TO_UNSIGNED(MIN_WIN_SIZE-1,4)) then
          cal4_stable_window <= '1';
        end if;
      end if;
    end if;
  end process;

  --*****************************************************************
  -- keep track of edge tap counts found, and whether we've
  -- incremented to the maximum number of taps allowed
  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if ((cal4_state = CAL4_INIT) or (cal4_dlyrst_gate = '1')) then
        cal4_idel_max_tap <= '0';
        cal4_idel_bit_tap <= '0';
        cal4_idel_tap_cnt <= (others => '0');
      elsif (cal4_dlyce_gate = '1') then
        if (cal4_dlyinc_gate = '1') then
          cal4_idel_tap_cnt <= cal4_idel_tap_cnt + 1;
          if (cal4_idel_tap_cnt = TO_UNSIGNED(CAL4_IDEL_BIT_VAL-2,6)) then
            cal4_idel_bit_tap <= '1';
          else
            cal4_idel_bit_tap <= '0';
          end if;
          if (cal4_idel_tap_cnt = "111110") then
            cal4_idel_max_tap <= '1';
          else
            cal4_idel_max_tap <= '0';
          end if;
        else
          cal4_idel_tap_cnt <= cal4_idel_tap_cnt - 1;
          cal4_idel_bit_tap <= '0';
          cal4_idel_max_tap <= '0';
        end if;
      end if;
    end if;
  end process;

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if ((cal4_state /= CAL4_RDEN_PIPE_CLR_WAIT) and
          (cal3_state /= CAL3_RDEN_PIPE_CLR_WAIT)) then
        calib_rden_pipe_cnt <= TO_UNSIGNED(CALIB_RDEN_PIPE_LEN-1,5);
      else
        calib_rden_pipe_cnt <= calib_rden_pipe_cnt - 1;
      end if;
    end if;
  end process;

  --*****************************************************************
  -- Stage 4 cal state machine
  --*****************************************************************

  process (clkdiv)
  begin
    if (rising_edge(clkdiv)) then
      if (rstdiv = '1') then
        i_calib_done(3)   <= '0';
        calib_done_tmp(3) <= '0';
        calib_err(3)      <= '0';
        count_gate        <= (others => '0');
        gate_dly          <= (others => '0');
        next_count_gate   <= (others => '0');
        cal4_idel_adj_cnt <= (others => 'X');
        cal4_dlyce_gate   <= '0';
        cal4_dlyinc_gate  <= '0';
        cal4_dlyrst_gate  <= '0';          -- reset handled elsewhere in code
        cal4_gate_srl_a   <= (others => 'X');
        cal4_rden_srl_a   <= (others => 'X');
        cal4_ref_req      <= '0';
        cal4_seek_left    <= 'X';
        cal4_state        <= CAL4_IDLE;
      else
        cal4_ref_req     <= '0';
        cal4_dlyce_gate  <= '0';
        cal4_dlyinc_gate <= '0';
        cal4_dlyrst_gate <= '0';

        case (cal4_state) is
          when CAL4_IDLE =>
            count_gate      <= (others => '0');
            next_count_gate <= (others => '0');
            if (calib_start(3) = '1') then
              gate_dly <= (others => '0');
              i_calib_done(3) <= '0';
              cal4_state <= CAL4_INIT;
            end if;

          when CAL4_INIT =>
            -- load: (1) initial value of gate delay SRL, (2) appropriate
            -- value of RDEN SRL (so that we get correct "data valid" timing)
            cal4_gate_srl_a <= to_unsigned(GATE_BASE_INIT,5);
            cal4_rden_srl_a <=
              (calib_rden_dly((to_integer(count_gate)*5)+4) &
               calib_rden_dly((to_integer(count_gate)*5)+3) &
               calib_rden_dly((to_integer(count_gate)*5)+2) &
               calib_rden_dly((to_integer(count_gate)*5)+1) &
               calib_rden_dly((to_integer(count_gate)*5)));
            -- let SRL pipe clear after loading initial shift value
            cal4_state <= CAL4_RDEN_PIPE_CLR_WAIT;

          -- sort of an initial state - start checking to see whether we're
          -- already in the window or not
          when CAL4_FIND_WINDOW =>
            -- decide right away if we start in the proper window - this
            -- determines if we are then looking for the left (trailing) or
            -- right (leading) edge of the data valid window
            if (cal4_data_valid = '1') then
              -- if we find a match - then we're already in window, now look
              -- for left edge. Otherwise, look for right edge of window
              cal4_seek_left <= cal4_data_good;
              cal4_state <= CAL4_FIND_EDGE;
            end if;

          when CAL4_FIND_EDGE =>
            -- don't do anything until the exact clock cycle when to check that
            -- readback data is valid or not
            if (cal4_data_valid = '1') then
              -- we're currently in the window, look for left edge of window
              if (cal4_seek_left = '1') then
                -- make sure we've passed the right edge before trying to detect
                -- the left edge (i.e. avoid any edge "instability") - else, we
                -- may detect an "false" edge too soon. By design, if we start in
                -- the data valid window, always expect at least
                -- MIN(BIT_TIME_TAPS,32) (-/+ jitter, see below) taps of valid
                -- window before we hit the left edge (this is because when stage
                -- 4 calibration first begins (i.e., gate_dly = 00, and IDELAY =
                -- 00), we're guaranteed to NOT be in the window, and we always
                -- start searching for MIN(BIT_TIME_TAPS,32) for the right edge
                -- of window. If we don't find it, increment gate_dly, and if we
                -- now start in the window, we have at least approximately
                -- CLK_PERIOD-MIN(BIT_TIME_TAPS,32) = MIN(BIT_TIME_TAPS,32) taps.
                -- It's approximately because jitter, noise, etc. can bring this
                -- value down slightly. Because of this (although VERY UNLIKELY),
                -- we have to protect against not decrementing IDELAY below 0
                -- during adjustment phase).
                if ((cal4_stable_window = '1') and
                    (cal4_data_good = '0')) then
                  -- found left edge of window, dec by MIN(BIT_TIME_TAPS,32)
                  cal4_idel_adj_cnt <= TO_UNSIGNED(CAL4_IDEL_BIT_VAL,6);
                  cal4_idel_adj_inc <= '0';
                  cal4_state <= CAL4_ADJ_IDEL;
                else
                  -- Otherwise, keep looking for left edge:
                  if (cal4_idel_max_tap = '1') then
                    -- ran out of taps looking for left edge (max=63) - happens
                    -- for low frequency case, decrement by 32
                    cal4_idel_adj_cnt <= "100000";
                    cal4_idel_adj_inc <= '0';
                    cal4_state <= CAL4_ADJ_IDEL;
                  else
                    cal4_dlyce_gate <= '1';
                    cal4_dlyinc_gate <= '1';
                    cal4_state <= CAL4_IDEL_WAIT;
                  end if;
                end if;
              else
                -- looking for right edge of window:
                -- look for the first match - this means we've found the right
                -- (leading) edge of the data valid window, increment by
                -- MIN(BIT_TIME_TAPS,32)
                if (cal4_data_good = '1') then
                  cal4_idel_adj_cnt <= TO_UNSIGNED(CAL4_IDEL_BIT_VAL,6);
                  cal4_idel_adj_inc <= '1';
                  cal4_state <= CAL4_ADJ_IDEL;
                else
                  -- Otherwise, keep looking:
                  -- only look for MIN(BIT_TIME_TAPS,32) taps for right edge,
                  -- if we haven't found it, then inc gate delay, try again
                  if (cal4_idel_bit_tap = '1') then
                    -- if we're already maxed out on gate delay, then error out
                    -- (simulation only - calib_err isn't currently connected)
                    if (cal4_gate_srl_a = "11111") then
                      calib_err(3) <= '1';
                      cal4_state <= CAL4_IDLE;
                    else
                      -- otherwise, increment gate delay count, and start
                      -- over again
                      cal4_gate_srl_a <= cal4_gate_srl_a + 1;
                      cal4_dlyrst_gate <= '1';
                      cal4_state <= CAL4_RDEN_PIPE_CLR_WAIT;
                    end if;
                  else
                    -- keep looking for right edge
                    cal4_dlyce_gate <= '1';
                    cal4_dlyinc_gate <= '1';
                    cal4_state <= CAL4_IDEL_WAIT;
                  end if;
                end if;
              end if;
            end if;

          -- wait for GATE IDELAY to settle, after reset or increment
          when CAL4_IDEL_WAIT =>
            -- For simulation, load SRL addresses for all DQS with same value
            if (SIM_ONLY /= 0) then
              loop_sim_gate_dly: for i in 0 to  DQS_WIDTH - 1 loop
                gate_dly((i*5)+4) <= cal4_gate_srl_a(4);
                gate_dly((i*5)+3) <= cal4_gate_srl_a(3);
                gate_dly((i*5)+2) <= cal4_gate_srl_a(2);
                gate_dly((i*5)+1) <= cal4_gate_srl_a(1);
                gate_dly((i*5))   <= cal4_gate_srl_a(0);
              end loop;
            else
              gate_dly((to_integer(count_gate)*5)+4) <= cal4_gate_srl_a(4);
              gate_dly((to_integer(count_gate)*5)+3) <= cal4_gate_srl_a(3);
              gate_dly((to_integer(count_gate)*5)+2) <= cal4_gate_srl_a(2);
              gate_dly((to_integer(count_gate)*5)+1) <= cal4_gate_srl_a(1);
              gate_dly((to_integer(count_gate)*5))   <= cal4_gate_srl_a(0);
            end if;
            -- check to see if we've found edge of window
            if (idel_set_wait = '0') then
              cal4_state <= CAL4_FIND_EDGE;
            end if;

          -- give additional time for RDEN_R pipe to clear from effects of
          -- previous pipeline (and IDELAY reset)
          when CAL4_RDEN_PIPE_CLR_WAIT =>
            -- MIG 2.2: Bug fix - make sure to update GATE_DLY count, since
            -- possible for FIND_EDGE->RDEN_PIPE_CLR_WAIT->FIND_WINDOW
            -- transition (i.e. need to make sure the gate count updated in
            -- FIND_EDGE gets reflected in GATE_DLY by the time we reach
            -- state FIND_WINDOW) - previously GATE_DLY only being updated
            -- during state CAL4_IDEL_WAIT
            if (SIM_ONLY /= 0) then
              loop_sim_gate_dly_pipe: for i in 0 to  DQS_WIDTH - 1 loop
                gate_dly((i*5)+4) <= cal4_gate_srl_a(4);
                gate_dly((i*5)+3) <= cal4_gate_srl_a(3);
                gate_dly((i*5)+2) <= cal4_gate_srl_a(2);
                gate_dly((i*5)+1) <= cal4_gate_srl_a(1);
                gate_dly((i*5))   <= cal4_gate_srl_a(0);
              end loop;
            else
              gate_dly((to_integer(count_gate)*5)+4) <= cal4_gate_srl_a(4);
              gate_dly((to_integer(count_gate)*5)+3) <= cal4_gate_srl_a(3);
              gate_dly((to_integer(count_gate)*5)+2) <= cal4_gate_srl_a(2);
              gate_dly((to_integer(count_gate)*5)+1) <= cal4_gate_srl_a(1);
              gate_dly((to_integer(count_gate)*5))   <= cal4_gate_srl_a(0);
            end if;
            -- look for new window
            if (calib_rden_pipe_cnt = "00000") then
              cal4_state <= CAL4_FIND_WINDOW;
            end if;

          -- increment/decrement DQS/DQ IDELAY for final adjustment
          when CAL4_ADJ_IDEL =>
            -- add underflow protection for corner case when left edge found
            -- using fewer than MIN(BIT_TIME_TAPS,32) taps
            if ((cal4_idel_adj_cnt = "000000") or
                ((cal4_dlyce_gate = '1') and (cal4_dlyinc_gate = '0') and
                 (cal4_idel_tap_cnt = "000001"))) then
              cal4_state <= CAL4_DONE;
              -- stop when all gates calibrated, or gate[0] cal'ed (for sim)
              if ((count_gate = TO_UNSIGNED(DQS_WIDTH-1,DQS_BITS_FIX)) or
                  (SIM_ONLY /= 0)) then
                calib_done_tmp(3) <= '1';
              else
                -- need for VHDL simulation to prevent out-of-index error
                next_count_gate <= count_gate + 1;
              end if;
            else
              cal4_idel_adj_cnt <= cal4_idel_adj_cnt - 1;
              cal4_dlyce_gate <= '1';
              -- whether inc or dec depends on whether left or right edge found
              cal4_dlyinc_gate <= cal4_idel_adj_inc;
            end if;

          -- wait for IDELAY output to settle after decrement. Check current
          -- COUNT_GATE value and decide if we're done
          when CAL4_DONE =>
            if (idel_set_wait = '0') then
              count_gate <= next_count_gate;
              if (calib_done_tmp(3) = '1') then
                i_calib_done(3) <= '1';
                cal4_state <= CAL4_IDLE;
              else
                -- request auto-refresh after every DQS group calibrated to
                -- avoid tRAS violation
                cal4_ref_req <= '1';
                if (calib_ref_done = '1') then
                  cal4_state <= CAL4_INIT;
                end if;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

end architecture syn;


