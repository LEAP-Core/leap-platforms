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
--  /   /         Filename: ddr2_ctrl.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/07/29 15:24:03 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR2
--Purpose:
--   This module is the main control logic of the memory interface. All
--   commands are issued from here according to the burst, CAS Latency and the
--   user commands.
--Reference:
--Revision History:
--   Rev 1.2 - Fixed autorefresh to activate bug KP. 11-19-2007
--   Rev 1.3 - For Dual Rank parts support CS logic modified. KP. 08/05/08
--   Rev 1.4 - AUTO_REFRESH_WAIT state modified for Auto Refresh flag asserted
--             immediately after calibration is completed. KP. 07/28/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ddr2_ctrl is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference
    -- board design). Actual values may be different. Actual parameters values
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    BANK_WIDTH    : integer := 2;
    COL_WIDTH     : integer := 10;
    CS_BITS       : integer := 0;
    CS_NUM        : integer := 1;
    ROW_WIDTH     : integer := 14;
    ADDITIVE_LAT  : integer := 0;
    BURST_LEN     : integer := 4;
    CAS_LAT       : integer := 5;
    ECC_ENABLE    : integer := 0;
    REG_ENABLE    : integer := 1;
    TREFI_NS      : integer := 7800;
    TRAS          : integer := 40000;
    TRCD          : integer := 15000;
    TRRD          : integer := 10000;
    TRFC          : integer := 105000;
    TRP           : integer := 15000;
    TRTP          : integer := 7500;
    TWR           : integer := 15000;
    TWTR          : integer := 10000;
    CLK_PERIOD    : integer := 3000;
    MULTI_BANK_EN : integer := 1;
    TWO_T_TIME_EN : integer := 0;
    DDR_TYPE      : integer := 1
    );
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
    ctrl_cs_n     : out std_logic_vector(CS_NUM-1 downto 0)
    );
end entity ddr2_ctrl;

architecture syn of ddr2_ctrl is

  function and_br (val : std_logic_vector) return std_logic is
    variable rtn : std_logic := '1';
  begin
    for index in val'range loop
      rtn := rtn and val(index);
    end loop;
    return(rtn);
  end and_br;

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

  function LIMIT_CALC_VAL (val_i : integer) return integer is
  begin
    if (val_i < 0) then
      return 0;
    else
      return val_i;
    end if;
  end function LIMIT_CALC_VAL;

  function CALC_TRAS_CYC return integer is
  begin
    return (TRAS+CLK_PERIOD)/CLK_PERIOD;
  end function CALC_TRAS_CYC;

  function CALC_TRRD_CYC return integer is
  begin
    return (TRRD + CLK_PERIOD) / CLK_PERIOD;
  end function CALC_TRRD_CYC;

  function CALC_TRCD_CYC return integer is
  begin
    if ((TRCD + CLK_PERIOD) / CLK_PERIOD > ADDITIVE_LAT) then
      return ((TRCD + CLK_PERIOD) / CLK_PERIOD) - ADDITIVE_LAT;
    else
      return 0;
    end if;
  end function CALC_TRCD_CYC;

  function CALC_TRFC_CYC return integer is
  begin
    return (TRFC + CLK_PERIOD) / CLK_PERIOD;
  end function CALC_TRFC_CYC;

  function CALC_TRP_CYC return integer is
  begin
    -- for precharge all add 1 extra clock cycle
    return ((TRP + CLK_PERIOD) / CLK_PERIOD) + 1;
  end function CALC_TRP_CYC;

  function CALC_TRTP_CYC return integer is
  begin
    if (((TRTP + CLK_PERIOD) / CLK_PERIOD) >= 2) then
      return ((TRTP + CLK_PERIOD) / CLK_PERIOD) + ADDITIVE_LAT +
        (BURST_LEN/2) - 2;
    else
      return ADDITIVE_LAT + (BURST_LEN/2);
    end if;
  end function CALC_TRTP_CYC;

  function CALC_TWR_CYC return integer is
  begin
    return ((TWR + CLK_PERIOD) / CLK_PERIOD) + (BURST_LEN/2) +
      CAS_LAT + ADDITIVE_LAT - 1;
  end function CALC_TWR_CYC;

  function CALC_TWTR_CYC return integer is
  begin
    return ((TWTR + CLK_PERIOD) / CLK_PERIOD) + (CAS_LAT - 1) +
      (BURST_LEN/2);
  end function CALC_TWTR_CYC;

  function CALC_TRTW_CYC return integer is
  begin
    if (DDR_TYPE > 0) then
      return (BURST_LEN/2) + 4;
    elsif (CAS_LAT = 25) then
      return 2 + (BURST_LEN/2);
    else
      return CAS_LAT + (BURST_LEN/2);
    end if;
  end function CALC_TRTW_CYC;

  -- input address split into various ranges
  constant ROW_RANGE_START  : integer := COL_WIDTH;
  constant ROW_RANGE_END    : integer := ROW_WIDTH + ROW_RANGE_START - 1;
  constant BANK_RANGE_START : integer := ROW_RANGE_END + 1;
  constant BANK_RANGE_END   : integer := BANK_WIDTH + BANK_RANGE_START - 1;
  constant CS_RANGE_START   : integer := BANK_RANGE_START + BANK_WIDTH;
  constant CS_RANGE_END     : integer := CS_BITS + CS_RANGE_START - 1;
  -- compare address (for determining bank/row hits) split into various ranges
  -- (compare address doesn't include column bits)
  constant CMP_WIDTH            : integer := CS_BITS + BANK_WIDTH + ROW_WIDTH;
  constant CMP_ROW_RANGE_START  : integer := 0;
  constant CMP_ROW_RANGE_END    : integer := ROW_WIDTH +
                                             CMP_ROW_RANGE_START - 1;
  constant CMP_BANK_RANGE_START : integer := CMP_ROW_RANGE_END + 1;
  constant CMP_BANK_RANGE_END   : integer := BANK_WIDTH +
                                             CMP_BANK_RANGE_START - 1;
  constant CMP_CS_RANGE_START   : integer := CMP_BANK_RANGE_END + 1;
  constant CMP_CS_RANGE_END     : integer := CS_BITS + CMP_CS_RANGE_START - 1;

  constant BURST_LEN_DIV2 : integer := BURST_LEN / 2;
  constant OPEN_BANK_NUM  : integer := 4;
  constant CS_BITS_FIX    : integer := FIX_ARRAY_SIZE(CS_BITS);

  -- calculation counters based on clock cycle and memory parameters
  -- TRAS: ACTIVE->PRECHARGE interval - 2
  constant TRAS_CYC     : integer := CALC_TRAS_CYC;
  -- TRCD: ACTIVE->READ/WRITE interval - 3 (for DDR2 factor in ADD_LAT)
  constant TRRD_CYC     : integer := CALC_TRRD_CYC;
  constant TRCD_CYC     : integer := CALC_TRCD_CYC;
  -- TRFC: REFRESH->REFRESH, REFRESH->ACTIVE interval - 2
  constant TRFC_CYC     : integer := CALC_TRFC_CYC;
  -- TRP: PRECHARGE->COMMAND interval - 2
  constant TRP_CYC      : integer := CALC_TRP_CYC;
  -- TRTP: READ->PRECHARGE interval - 2 (Al + BL/2 + (max (TRTP, 2tck))-2
  constant TRTP_CYC     : integer := CALC_TRTP_CYC;
  -- TWR: WRITE->PRECHARGE interval - 2
  constant TWR_CYC      : integer := CALC_TWR_CYC;
  -- TWTR: WRITE->READ interval - 3 (for DDR1, TWTR = 2 clks)
  -- DDR2 = CL-1 + BL/2 +TWTR
  constant TWTR_CYC     : integer := CALC_TWTR_CYC;

  --  TRTW: READ->WRITE interval - 3
  --  DDR1: CL + (BL/2)
  --  DDR2: (BL/2) + 2. Two more clocks are added to
  --  the DDR2 counter to account for the delay in
  --  arrival of the DQS during reads (pcb trace + buffer
  --  delays + memory parameters).
  constant TRTW_CYC : integer := CALC_TRTW_CYC;

  -- Make sure all values >= 0 (some may be = 0)
  constant TRAS_COUNT : integer := LIMIT_CALC_VAL(TRAS_CYC);
  constant TRCD_COUNT : integer := LIMIT_CALC_VAL(TRCD_CYC);
  constant TRRD_COUNT : integer := LIMIT_CALC_VAL(TRRD_CYC);
  constant TRFC_COUNT : integer := LIMIT_CALC_VAL(TRFC_CYC);
  constant TRP_COUNT  : integer := LIMIT_CALC_VAL(TRP_CYC);
  constant TRTP_COUNT : integer := LIMIT_CALC_VAL(TRTP_CYC);
  constant TWR_COUNT  : integer := LIMIT_CALC_VAL(TWR_CYC);
  constant TWTR_COUNT : integer := LIMIT_CALC_VAL(TWTR_CYC);
  constant TRTW_COUNT : integer := LIMIT_CALC_VAL(TRTW_CYC);

  -- Auto refresh interval
  constant TREFI_COUNT : integer := ((TREFI_NS * 1000) / CLK_PERIOD) - 1;

  -- memory controller states
  type CTRL_STATE_TYPE is (CTRL_IDLE,
                           CTRL_PRECHARGE,
                           CTRL_PRECHARGE_WAIT,
                           CTRL_AUTO_REFRESH,
                           CTRL_AUTO_REFRESH_WAIT,
                           CTRL_ACTIVE,
                           CTRL_ACTIVE_WAIT,
                           CTRL_BURST_READ,
                           CTRL_READ_WAIT,
                           CTRL_BURST_WRITE,
                           CTRL_WRITE_WAIT,
                           CTRL_PRECHARGE_WAIT1);

  signal act_addr_r          : std_logic_vector(CMP_WIDTH-1 downto 0);
  signal af_addr_r           : std_logic_vector(30 downto 0);
  signal af_addr_r1          : std_logic_vector(30 downto 0);
  signal af_addr_r2          : std_logic_vector(30 downto 0);
  signal af_addr_r3          : std_logic_vector(30 downto 0);
  signal af_cmd_r            : std_logic_vector(2 downto 0);
  signal af_cmd_r1           : std_logic_vector(2 downto 0);
  signal af_cmd_r2           : std_logic_vector(2 downto 0);
  signal af_valid_r          : std_logic;
  signal af_valid_r1         : std_logic;
  signal af_valid_r2         : std_logic;
  signal auto_cnt_r          : unsigned(CS_BITS_FIX downto 0);
  signal auto_ref_r          : std_logic;
  signal bank_cmp_addr_r     : std_logic_vector((OPEN_BANK_NUM*CMP_WIDTH)-1
                                                downto 0);
  signal bank_hit            : std_logic_vector(OPEN_BANK_NUM-1 downto 0);
  signal bank_hit_r          : std_logic_vector(OPEN_BANK_NUM-1 downto 0);
  signal bank_hit_r1         : std_logic_vector(OPEN_BANK_NUM-1 downto 0);
  signal bank_valid_r        : std_logic_vector(OPEN_BANK_NUM-1 downto 0);
  signal bank_conflict_r     : std_logic;
  signal conflict_resolved_r : std_logic;
  signal ctrl_af_rden_r      : std_logic;
  signal ctrl_af_rden_r1     : std_logic;
  signal conflict_detect_r   : std_logic;
  signal conflict_detect     : std_logic;
  signal cs_change_r         : std_logic;
  signal cs_change_sticky_r  : std_logic;
  signal ddr_addr_r          : std_logic_vector(ROW_WIDTH-1 downto 0);
  signal ddr_addr_col        : std_logic_vector(ROW_WIDTH-1 downto 0);
  signal ddr_addr_row        : std_logic_vector(ROW_WIDTH-1 downto 0);
  signal ddr_ba_r            : std_logic_vector(BANK_WIDTH-1 downto 0);
  signal ddr_cas_n_r         : std_logic;
  signal ddr_cs_n_r          : std_logic_vector(CS_NUM-1 downto 0);
  signal ddr_ras_n_r         : std_logic;
  signal ddr_we_n_r          : std_logic;
  signal next_state          : CTRL_STATE_TYPE;
  signal no_precharge_wait_r : std_logic;
  signal no_precharge_r      : std_logic;
  signal no_precharge_r1     : std_logic;
  signal phy_init_done_r     : std_logic;
  signal precharge_ok_cnt_r  : unsigned(4 downto 0);
  signal precharge_ok_r      : std_logic;
  signal ras_cnt_r           : unsigned(4 downto 0);
  signal rcd_cnt_r           : unsigned(3 downto 0);
  signal rcd_cnt_ok_r        : std_logic;
  signal rdburst_cnt_r       : unsigned(2 downto 0);
  signal rdburst_ok_r        : std_logic;
  signal rdburst_rden_ok_r   : std_logic;
  signal rd_af_flag_r        : std_logic;
  signal rd_flag             : std_logic;
  signal rd_flag_r           : std_logic;
  signal rd_to_wr_cnt_r      : unsigned(4 downto 0);
  signal rd_to_wr_ok_r       : std_logic;
  signal ref_flag_r          : std_logic;
  signal refi_cnt_r          : unsigned(11 downto 0);
  signal refi_cnt_ok_r       : std_logic;
  signal rst_r               : std_logic;
  signal rst_r1              : std_logic;
  signal rfc_cnt_r           : unsigned(7 downto 0);
  signal rfc_ok_r            : std_logic;
  signal row_miss            : std_logic_vector(3 downto 0);
  signal row_conflict_r      : std_logic_vector(3 downto 0);
  signal rp_cnt_r            : unsigned(3 downto 0);
  signal rp_cnt_ok_r         : std_logic;
  signal sb_open_add_r       : std_logic_vector(CMP_WIDTH-1 downto 0);
  signal state_r             : CTRL_STATE_TYPE;
  signal state_r1            : CTRL_STATE_TYPE;
  signal sm_rden             : std_logic;
  signal sm_rden_r           : std_logic;
  signal trrd_cnt_r          : unsigned(2 downto 0);
  signal trrd_cnt_ok_r       : std_logic;
  signal two_t_enable_r      : std_logic_vector(2 downto 0);
  signal two_t_enable_r1     : std_logic_vector(CS_NUM-1 downto 0);
  signal wrburst_cnt_r       : unsigned(2 downto 0);
  signal wrburst_ok_r        : std_logic;
  signal wrburst_wren_ok_r   : std_logic;
  signal wr_flag             : std_logic;
  signal wr_flag_r           : std_logic;
  signal wr_to_rd_cnt_r      : unsigned(4 downto 0);
  signal wr_to_rd_ok_r       : std_logic;

  signal i_ctrl_af_rden       : std_logic;

  attribute syn_maxfan : integer;
  attribute syn_preserve : boolean;
  attribute equivalent_register_removal : string;
  attribute shreg_extract : string;
  attribute equivalent_register_removal of rst_r  : signal is "no";
  attribute syn_preserve                of rst_r  : signal is true;
  attribute shreg_extract               of rst_r  : signal is "no";
  attribute shreg_extract               of rst_r1 : signal is "no";
  attribute syn_maxfan of rst_r1           : signal is 10;

begin

  ctrl_af_rden <= i_ctrl_af_rden;

  --***************************************************************************

  -- sm_rden is used to assert read enable to the address FIFO
  sm_rden <= '1' when ((state_r = CTRL_BURST_WRITE) or
                       (state_r = CTRL_BURST_READ)) else '0';

  -- assert read flag to the adress FIFO
  i_ctrl_af_rden <= sm_rden or rd_af_flag_r;

  -- local reset "tree" for controller logic only. Create this to ease timing
  -- on reset path. Prohibit equivalent register removal on RST_R to prevent
  -- "sharing" with other local reset trees (caution: make sure global fanout
  -- limit is set to large enough value, otherwise SLICES may be used for
  -- fanout control on RST_R.
  process (clk)
  begin
    if (rising_edge(clk)) then
      rst_r  <= rst;
      rst_r1 <= rst_r;
    end if;
  end process;

  --*****************************************************************
  -- interpret commands from Command/Address FIFO
  --*****************************************************************

  wr_flag <= '0' when (af_valid_r2 = '0') else
             '1' when (af_cmd_r2 = "000") else
             '0';

  rd_flag <= '0' when (af_valid_r2 = '0') else
             '1' when (af_cmd_r2 = "001") else
             '0';

  process (clk)
  begin
    if (rising_edge(clk)) then
      rd_flag_r <= rd_flag;
      wr_flag_r <= wr_flag;
    end if;
  end process;

  --////////////////////////////////////////////////
  -- The data from the address FIFO is fetched and
  -- stored in two register stages. The data will be
  -- pulled out of the second register stage whenever
  -- the state machine can handle new data from the
  -- address FIFO.

  -- This flag is asserted when there is no
  -- cmd & address in the pipe. When there is
  -- valid cmd & addr from the address FIFO the
  -- af_valid signals will be asserted. This flag will
  -- be set the cycle af_valid_r is de-asserted.
  process (clk)
  begin
    if (rising_edge(clk)) then
      -- for simulation purposes - to force CTRL_AF_RDEN low during reset
      if (rst_r1 = '1') then
        rd_af_flag_r <= '0';
      elsif ((ctrl_af_rden_r = '1') or
             ((rd_af_flag_r = '1') and
              ((af_valid_r = '1') or (af_valid_r1 = '1')))) then
        rd_af_flag_r <= '0';
      elsif ((af_valid_r1 = '0') or (af_valid_r = '0')) then
        rd_af_flag_r <= '1';
      end if;
    end if;
  end process;

  -- First register stage for the cmd & add from the FIFO.
  -- The af_valid_r signal gives the status of the data
  -- in this stage. The af_valid_r will be asserted when there
  -- is valid data. This register stage will be updated
  -- 1. read to the FIFO and the FIFO not empty
  -- 2. After write and read states
  -- 3. The valid signal is not asserted in the last stage.
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1') then
        af_valid_r <= '0';
      else
      if ((ctrl_af_rden_r = '1') or (sm_rden_r = '1') or
          (af_valid_r1 = '0') or (af_valid_r2 = '0')) then
          af_valid_r <= ctrl_af_rden_r;
        end if;
      end if;
    end if;
  end process;

  -- The output register in the FIFO is used. The addr
  -- and command are already registered in the FIFO.
  af_addr_r <= af_addr;
  af_cmd_r <= af_cmd;

  -- Second register stage for the cmd & add from the FIFO.
  -- The af_valid_r1 signal gives the status of the data
  -- in this stage. The af_valid_r will be asserted when there
  -- is valid data. This register stage will be updated
  -- 1. read to the FIFO and the FIFO not empty and there
  -- is no valid data on this stage
  -- 2. After write and read states
  -- 3. The valid signal is not asserted in the last stage.
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1') then
        af_valid_r1 <= '0';
        af_addr_r1 <= (others => 'X');
        af_cmd_r1 <= (others => 'X');
      elsif ((af_valid_r1 = '0') or (sm_rden_r = '1') or
             (af_valid_r2 = '0')) then
        af_valid_r1 <= af_valid_r;
        af_addr_r1 <= af_addr_r;
        af_cmd_r1 <= af_cmd_r;
      end if;
    end if;
  end process;

  -- The state machine uses the address and command in this
  -- register stage. The data is fetched from the second
  -- register stage whenever the state machine can accept new
  -- addr. The conflict flags are also generated based on the
  -- second register stage and updated when the new address
  -- is loaded for the state machine.
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1') then
        af_valid_r2 <= '0';
        af_addr_r2 <= (others => 'X');
        af_cmd_r2 <= (others => 'X');
        bank_hit_r <= (others => 'X');
        bank_conflict_r <= 'X';
        row_conflict_r <= (others => 'X');
      elsif ((sm_rden = '1') or (af_valid_r2 = '0')) then
        af_valid_r2 <= af_valid_r1;
        af_addr_r2 <= af_addr_r1;
        af_cmd_r2 <= af_cmd_r1;
        if (MULTI_BANK_EN /= 0) then
          bank_hit_r <= bank_hit;
          row_conflict_r <= row_miss;
          bank_conflict_r <= (not(or_br(bank_hit)));
        else
          bank_hit_r <= (others => '0');
          bank_conflict_r <= '0';
          if (af_addr_r1(CS_RANGE_END downto ROW_RANGE_START) /=
              sb_open_add_r(CMP_WIDTH-1 downto 0)) then
            row_conflict_r(0) <= '1';
          else
            row_conflict_r(0) <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  --detecting cs change for multi chip select case
  gen_cs_change_cs1 : if (CS_NUM > 1) generate
    process (clk)
    begin
      if (rising_edge(clk)) then
        if ((sm_rden = '1') or (not(af_valid_r2) = '1')) then
          if (af_addr_r1(CS_RANGE_END downto CS_RANGE_START) /=
              af_addr_r2(CS_RANGE_END downto CS_RANGE_START)) then
            cs_change_r <= '1';
          else
            cs_change_r <= '0' ;
          end if;
          if (af_addr_r1(CS_RANGE_END downto CS_RANGE_START) /=
              af_addr_r2(CS_RANGE_END downto CS_RANGE_START)) then
            cs_change_sticky_r <= '1';
          else
            cs_change_sticky_r <= '0' ;
          end if;
        else
          cs_change_r <= '0';
        end if;
      end if;
    end process;
  end generate;

  gen_cs_change_cs0 : if (CS_NUM = 1) generate
    process (clk)
    begin
      if (rising_edge(clk)) then
        cs_change_r        <= '0';
        cs_change_sticky_r <= '0' ;
      end if;
    end process;
  end generate;

  conflict_detect <=
    ((or_br(row_conflict_r(3 downto 0) and bank_hit_r(3 downto 0))) or
     bank_conflict_r) and af_valid_r2 when (MULTI_BANK_EN) /= 0 else
    row_conflict_r(0) and af_valid_r2;

  process (clk)
  begin
    if (rising_edge(clk)) then
      conflict_detect_r <= conflict_detect;
      sm_rden_r <= sm_rden;
      af_addr_r3 <= af_addr_r2;
      ctrl_af_rden_r <= i_ctrl_af_rden and not(af_empty);
      ctrl_af_rden_r1 <= ctrl_af_rden_r;
    end if;
  end process;

  -- conflict resolved signal. When this signal is asserted
  -- the conflict is resolved. The address to be compared
  -- for the conflict_resolved_r will be stored in act_add_r
  -- when the bank is opened.
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (act_addr_r = af_addr_r2(CS_RANGE_END downto ROW_RANGE_START)) then
        conflict_resolved_r <= '1';
      else
        conflict_resolved_r <= '0';
      end if;
      if (state_r = CTRL_ACTIVE) then
        act_addr_r <= af_addr_r2(CS_RANGE_END downto ROW_RANGE_START);
      end if;
    end if;
  end process;

  --***************************************************************************
  -- Bank management logic
  -- Semi-hardcoded for now for 4 banks
  -- will keep multiple banks open if MULTI_BANK_EN is true.
  --***************************************************************************

  -- if multiple bank option chosen
  gen_multi_bank_open: if (MULTI_BANK_EN /= 0) generate
    gen_bank_hit1: for bank_i in 0 to OPEN_BANK_NUM-1 generate
      -- asserted if bank address match + open bank entry is valid
      bank_hit(bank_i)
        <= '1' when
        ((bank_cmp_addr_r((CMP_WIDTH*(bank_i+1))-1 downto
                          (CMP_WIDTH*bank_i)+ROW_WIDTH) =
          af_addr_r1(CS_RANGE_END downto BANK_RANGE_START))
         and (bank_valid_r(bank_i) = '1'))
        else '0';
      -- asserted if row address match (no check for bank entry valid, rely
      -- on this term to be used in conjunction with BANK_HIT[])
      row_miss(bank_i)
        <= '1' when
        (bank_cmp_addr_r((CMP_WIDTH*bank_i)+ROW_WIDTH-1
                         downto (CMP_WIDTH*bank_i)) /=
         af_addr_r1(ROW_RANGE_END downto ROW_RANGE_START))
        else '0';
    end generate;

    process (clk)
    begin
      if (rising_edge(clk)) then
        no_precharge_wait_r <= bank_valid_r(3) and bank_conflict_r;
        bank_hit_r1 <= bank_hit_r;
      end if;
    end process;

    process (bank_conflict_r, bank_valid_r)
    begin
      no_precharge_r <= not(bank_valid_r(3)) and bank_conflict_r;
    end process;

    process (clk)
    begin
      if (rising_edge(clk)) then
        no_precharge_r1 <= no_precharge_r;
      end if;
    end process;

    process (clk)
    begin
      if (rising_edge(clk)) then
        -- Clear all bank valid bits during AR (i.e. since all banks get
        -- precharged during auto-refresh)
        if (state_r1 = CTRL_AUTO_REFRESH) then
          bank_valid_r <= (others => '0');
          bank_cmp_addr_r <= (others => '0');
        else
          if (state_r1 = CTRL_ACTIVE) then
            -- 00 is always going to have the latest bank and row.
            bank_cmp_addr_r(CMP_WIDTH-1 downto 0) <=
              af_addr_r3(CS_RANGE_END downto ROW_RANGE_START);
            -- This indicates the bank was activated
            bank_valid_r(0) <= '1';

            case (bank_hit_r1(2 downto 0)) is
              when "001" =>
                bank_cmp_addr_r(CMP_WIDTH-1 downto 0) <=
                  af_addr_r3(CS_RANGE_END downto ROW_RANGE_START);
                -- This indicates the bank was activated
                bank_valid_r(0) <= '1';
              when "010" =>             --(b0->b1)
                bank_cmp_addr_r((2*CMP_WIDTH)-1 downto CMP_WIDTH) <=
                  bank_cmp_addr_r(CMP_WIDTH-1 downto 0);
                bank_valid_r(1) <= bank_valid_r(0);
              when "100" =>             --(b0->b1, b1->b2)
                bank_cmp_addr_r((2*CMP_WIDTH)-1 downto CMP_WIDTH) <=
                  bank_cmp_addr_r(CMP_WIDTH-1 downto 0);
                bank_cmp_addr_r((3*CMP_WIDTH)-1 downto 2*CMP_WIDTH) <=
                  bank_cmp_addr_r((2*CMP_WIDTH)-1 downto CMP_WIDTH);
                bank_valid_r(1) <= bank_valid_r(0);
                bank_valid_r(2) <= bank_valid_r(1);
              when others =>            --(b0->b1, b1->b2, b2->b3)
                bank_cmp_addr_r((2*CMP_WIDTH)-1 downto CMP_WIDTH) <=
                  bank_cmp_addr_r(CMP_WIDTH-1 downto 0);
                bank_cmp_addr_r((3*CMP_WIDTH)-1 downto 2*CMP_WIDTH) <=
                  bank_cmp_addr_r((2*CMP_WIDTH)-1 downto CMP_WIDTH);
                bank_cmp_addr_r((4*CMP_WIDTH)-1 downto 3*CMP_WIDTH) <=
                  bank_cmp_addr_r((3*CMP_WIDTH)-1 downto 2*CMP_WIDTH);
                bank_valid_r(1) <= bank_valid_r(0);
                bank_valid_r(2) <= bank_valid_r(1);
                bank_valid_r(3) <= bank_valid_r(2);
            end case;
          end if;
        end if;
      end if;
    end process;
  end generate;

  -- single bank option
  gen_single_bank_open: if (not(MULTI_BANK_EN /= 0)) generate
    process (clk)
    begin
      if (rising_edge(clk)) then
        no_precharge_r <= '0';
        no_precharge_r1 <= '0';
        no_precharge_wait_r <= '0';
        if (rst_r1 = '1') then
          sb_open_add_r <= (others => '0');
        elsif (state_r = CTRL_ACTIVE) then
          sb_open_add_r <= af_addr_r2(CS_RANGE_END downto ROW_RANGE_START);
        end if;
      end if;
    end process;
  end generate;

  --***************************************************************************
  -- Timing counters
  --***************************************************************************

  --*****************************************************************
  -- Write and read enable generation for PHY
  --*****************************************************************

  -- write burst count. Counts from (BL/2 to 1).
  -- Also logic for controller write enable.
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_BURST_WRITE) then
        wrburst_cnt_r <= TO_UNSIGNED(BURST_LEN_DIV2,3);
      elsif (wrburst_cnt_r >= "001") then
        wrburst_cnt_r <= wrburst_cnt_r - 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1') then
        ctrl_wren <= '0';
      elsif (state_r = CTRL_BURST_WRITE) then
        ctrl_wren <= '1';
      elsif (wrburst_wren_ok_r = '1') then
        ctrl_wren <= '0';
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((state_r = CTRL_BURST_WRITE) and (BURST_LEN_DIV2 > 2)) then
        wrburst_ok_r <= '0';
      elsif ((wrburst_cnt_r <= "011") or (BURST_LEN_DIV2 <= 2)) then
        wrburst_ok_r <= '1';
      end if;
    end if;
  end process;

  -- flag to check when wrburst count has reached
  -- a value of 1. This flag is used in the ctrl_wren
  -- logic
  process (clk)
  begin
    if (rising_edge(clk)) then
     if (wrburst_cnt_r = "010") then
       wrburst_wren_ok_r <= '1';
     else
       wrburst_wren_ok_r <= '0';
     end if;
    end if;
  end process;

  -- read burst count. Counts from (BL/2 to 1)
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_BURST_READ) then
        rdburst_cnt_r <= TO_UNSIGNED(BURST_LEN_DIV2,3);
      elsif (rdburst_cnt_r >= "001") then
        rdburst_cnt_r <= rdburst_cnt_r - 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1') then
        ctrl_rden <= '0';
      elsif (state_r = CTRL_BURST_READ) then
        ctrl_rden <= '1';
      elsif (rdburst_rden_ok_r = '1') then
        ctrl_rden <= '0';
      end if;
    end if;
  end process;

  -- the rd_burst_ok_r signal will be asserted one cycle later
  -- in multi chip select cases if the back to back read is to
  -- different chip selects. The cs_changed_sticky_r signal will
  -- be asserted only for multi chip select cases.
  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((state_r = CTRL_BURST_READ) and (BURST_LEN_DIV2 > 2)) then
        rdburst_ok_r <= '0';
      elsif ((rdburst_cnt_r <= ("011" - ("00" & cs_change_sticky_r))) or
             (BURST_LEN_DIV2 <= 2)) then
        rdburst_ok_r <= '1';
      end if;
    end if;
  end process;

  -- flag to check when rdburst count has reached
  -- a value of 1. This flag is used in the ctrl_rden
  -- logic
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rdburst_cnt_r = "010") then
        rdburst_rden_ok_r <= '1';
      else
        rdburst_rden_ok_r <= '0';
      end if;
    end if;
  end process;

  --*****************************************************************
  -- Various delay counters
  -- The counters are checked for value of <= 3 to determine the
  -- if the count values are reached during different commands.
  -- It is checked for 3 because
  -- 1. The counters are loaded during the state when the command
  --    state is reached (+1)
  -- 2. After the <= 3 condition is reached the sm takes two cycles
  --    to transition to the new command state (+2)
  --*****************************************************************

  -- tRP count - precharge command period
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_PRECHARGE) then
        rp_cnt_r <= TO_UNSIGNED(TRP_COUNT,4);
      elsif (rp_cnt_r /= "0000") then
        rp_cnt_r <= rp_cnt_r - 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_PRECHARGE) then
        rp_cnt_ok_r <= '0';
      elsif (rp_cnt_r <= "0011") then
        rp_cnt_ok_r <= '1';
      end if;
    end if;
  end process;

  -- tRFC count - refresh-refresh, refresh-active
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_AUTO_REFRESH) then
        rfc_cnt_r <= TO_UNSIGNED(TRFC_COUNT,8);
      elsif (rfc_cnt_r /= "00000000") then
        rfc_cnt_r <= rfc_cnt_r - 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_AUTO_REFRESH) then
        rfc_ok_r <= '0';
      elsif (rfc_cnt_r <= TO_UNSIGNED(3,8)) then
        rfc_ok_r <= '1';
      end if;
    end if;
  end process;

  -- tRCD count - active to read/write
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_ACTIVE) then
        rcd_cnt_r <= TO_UNSIGNED(TRCD_COUNT,4);
      elsif (rcd_cnt_r /= "0000") then
        rcd_cnt_r <= rcd_cnt_r - "0001";
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((state_r = CTRL_ACTIVE) and (TRCD_COUNT > 2)) then
        rcd_cnt_ok_r <= '0';
      elsif (rcd_cnt_r <= "0011") then
        rcd_cnt_ok_r <= '1';
      end if;
    end if;
  end process;

  -- tRRD count - active to active
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_ACTIVE) then
        trrd_cnt_r <= TO_UNSIGNED(TRRD_COUNT,3);
      elsif (trrd_cnt_r /= "000") then
        trrd_cnt_r <= trrd_cnt_r - 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_ACTIVE) then
        trrd_cnt_ok_r <= '0';
      elsif (trrd_cnt_r <= "011") then
        trrd_cnt_ok_r <= '1';
      end if;
    end if;
  end process;

  -- tRAS count - active to precharge
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_ACTIVE) then
        ras_cnt_r <= TO_UNSIGNED(TRAS_COUNT,5);
      elsif (ras_cnt_r /= "00000") then
        ras_cnt_r <= ras_cnt_r - 1;
      end if;
    end if;
  end process;

  -- counter for write to prcharge
  -- read to precharge and
  -- activate to precharge
  -- precharge_ok_cnt_r is added with trtp count,
  -- there can be cases where the sm can go from
  -- activate to read and the act->pre count time
  -- would not have been satisfied. The rd->pre
  -- time is very less. wr->pre time is almost the
  -- same as act-> pre
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_BURST_READ) then
        -- assign only if the cnt is < TRTP_COUNT
        if (precharge_ok_cnt_r < TO_UNSIGNED(TRTP_COUNT,5)) then
          precharge_ok_cnt_r <= TO_UNSIGNED(TRTP_COUNT,5);
        end if;
      elsif (state_r = CTRL_BURST_WRITE) then
        precharge_ok_cnt_r <= TO_UNSIGNED(TWR_COUNT,5);
      elsif (state_r = CTRL_ACTIVE) then
        precharge_ok_cnt_r <= TO_UNSIGNED(TRAS_COUNT,5);
      elsif (precharge_ok_cnt_r /= "00000") then
        precharge_ok_cnt_r <= precharge_ok_cnt_r - 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((state_r = CTRL_BURST_READ) or
          (state_r = CTRL_BURST_WRITE) or
          (state_r = CTRL_ACTIVE)) then
          precharge_ok_r <= '0';
        elsif (precharge_ok_cnt_r <= TO_UNSIGNED(3,5)) then
          precharge_ok_r <= '1';
        end if;
      end if;
    end process;

  -- write to read counter
  -- write to read includes : write latency + burst time + tWTR
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1') then
        wr_to_rd_cnt_r <= (others => '0');
      elsif (state_r = CTRL_BURST_WRITE) then
        wr_to_rd_cnt_r <= TO_UNSIGNED(TWTR_COUNT,5);
      elsif (wr_to_rd_cnt_r /= "00000") then
        wr_to_rd_cnt_r <= wr_to_rd_cnt_r - 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_BURST_WRITE) then
        wr_to_rd_ok_r <= '0';
      elsif (wr_to_rd_cnt_r <= TO_UNSIGNED(3,5)) then
        wr_to_rd_ok_r <= '1';
      end if;
    end if;
  end process;

  -- read to write counter
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1') then
        rd_to_wr_cnt_r <= (others => '0');
      elsif (state_r = CTRL_BURST_READ) then
        rd_to_wr_cnt_r <= TO_UNSIGNED(TRTW_COUNT,5);
      elsif (rd_to_wr_cnt_r /= "00000") then
        rd_to_wr_cnt_r <= rd_to_wr_cnt_r - 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (state_r = CTRL_BURST_READ) then
        rd_to_wr_ok_r <= '0';
      elsif (rd_to_wr_cnt_r <= TO_UNSIGNED(3,5)) then
        rd_to_wr_ok_r <= '1';
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
     if (refi_cnt_r = TO_UNSIGNED(TREFI_COUNT-1,12)) then
       refi_cnt_ok_r <= '1';
     else
       refi_cnt_ok_r <= '0';
     end if;
    end if;
  end process;

  -- auto refresh interval counter in refresh_clk domain
  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((rst_r1 = '1') or (refi_cnt_ok_r = '1'))  then
        refi_cnt_r <= (others => '0');
      else
        refi_cnt_r <= refi_cnt_r + 1;
      end if;
    end if;
  end process;

  -- auto refresh flag
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (refi_cnt_ok_r = '1') then
        ref_flag_r <= '1';
      else
        ref_flag_r <= '0';
      end if;
    end if;
  end process;

  ctrl_ref_flag <= ref_flag_r;

  --refresh flag detect
  --auto_ref high indicates auto_refresh requirement
  --auto_ref is held high until auto refresh command is issued.
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1') then
        auto_ref_r <= '0';
      elsif (ref_flag_r = '1') then
        auto_ref_r <= '1';
      elsif (state_r = CTRL_AUTO_REFRESH) then
        auto_ref_r <= '0';
      end if;
    end if;
  end process;

  -- keep track of which chip selects got auto-refreshed (avoid auto-refreshing
  -- all CS's at once to avoid current spike)
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1' or (state_r1 = CTRL_PRECHARGE)) then
        auto_cnt_r <= (others => '0');
      elsif (state_r1 = CTRL_AUTO_REFRESH) then
        auto_cnt_r <= auto_cnt_r + 1;
      end if;
    end if;
  end process;

  -- register for timing purposes. Extra delay doesn't really matter
  process (clk)
  begin
    if (rising_edge(clk)) then
      phy_init_done_r <= phy_init_done;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst_r1 = '1') then
        state_r <= CTRL_IDLE;
        state_r1 <= CTRL_IDLE;
      else
        state_r <= next_state;
        state_r1 <= state_r;
      end if;
    end if;
  end process;

  --***************************************************************************
  -- main control state machine
  --***************************************************************************

  process (auto_cnt_r, auto_ref_r, conflict_detect, conflict_detect_r,
           conflict_resolved_r, cs_change_r, no_precharge_r,
           no_precharge_wait_r, phy_init_done_r, precharge_ok_r,
           rcd_cnt_ok_r, rd_flag, rd_flag_r, rd_to_wr_ok_r, rdburst_ok_r,
           rfc_ok_r, state_r, rp_cnt_ok_r, trrd_cnt_ok_r, wr_flag, wr_flag_r,
           wr_to_rd_ok_r, wrburst_ok_r)
  begin
    next_state <= state_r;

    case (state_r) is
      when CTRL_IDLE =>
        -- perform auto refresh as soon as we are done with calibration.
        -- The calibration logic does not do any refreshes.
        if (phy_init_done_r = '1') then
          next_state <= CTRL_AUTO_REFRESH;
        end if;

      when CTRL_PRECHARGE =>
        if (auto_ref_r = '1') then
          next_state <= CTRL_PRECHARGE_WAIT1;
          -- when precharging an LRU bank, do not have to go to wait state
          -- since we can't possibly be activating row in same bank next
          -- disabled for 2t timing. There needs to be a gap between cmds
          -- in 2t timing
        elsif ((no_precharge_wait_r = '1') and (TWO_T_TIME_EN = 0)) then
          next_state <= CTRL_ACTIVE;
        else
          next_state <= CTRL_PRECHARGE_WAIT;
      end if;

      when CTRL_PRECHARGE_WAIT =>
        if (rp_cnt_ok_r = '1') then
          if (auto_ref_r = '1') then
            -- precharge again to make sure we close all the banks
            next_state <= CTRL_PRECHARGE;
          else
            next_state <= CTRL_ACTIVE;
          end if;
        end if;

      when CTRL_PRECHARGE_WAIT1 =>
        if (rp_cnt_ok_r = '1') then
          next_state <= CTRL_AUTO_REFRESH;
        end if;

      when CTRL_AUTO_REFRESH =>
        next_state <= CTRL_AUTO_REFRESH_WAIT;

      when CTRL_AUTO_REFRESH_WAIT =>
        --staggering Auto refresh for multi
        -- chip select designs. The SM waits
        -- for the rfc time before issuing the
        -- next auto refresh.
        if (auto_cnt_r < TO_UNSIGNED(CS_NUM,(CS_BITS_FIX+1))) then
          if (rfc_ok_r = '1') then
            next_state <= CTRL_AUTO_REFRESH;
          end if;
        elsif (rfc_ok_r = '1') then
          if(auto_ref_r = '1') then
             -- MIG 2.3: For deep designs if Auto Refresh
             -- flag asserted immediately after calibration is completed
             next_state <= CTRL_PRECHARGE;
          elsif ((wr_flag = '1') or (rd_flag = '1')) then
             next_state <= CTRL_ACTIVE;
          end if;
        end if;


      when CTRL_ACTIVE =>
        next_state <= CTRL_ACTIVE_WAIT;

      when CTRL_ACTIVE_WAIT =>
        if (rcd_cnt_ok_r = '1') then
          if (((conflict_detect_r = '1') and (conflict_resolved_r = '0')) or
              (auto_ref_r = '1')) then
            if ((no_precharge_r = '1') and (auto_ref_r = '0') and
                (trrd_cnt_ok_r = '1')) then
              next_state <= CTRL_ACTIVE;
            elsif (precharge_ok_r = '1') then
              next_state <= CTRL_PRECHARGE;
            end if;
          elsif ((wr_flag_r = '1') and (rd_to_wr_ok_r = '1')) then
            next_state <= CTRL_BURST_WRITE;
          elsif ((rd_flag_r = '1') and (wr_to_rd_ok_r = '1')) then
            next_state <= CTRL_BURST_READ;
          end if;
        end if;

      -- beginning of write burst
      when CTRL_BURST_WRITE =>
        if (BURST_LEN_DIV2 = 1) then
          -- special case if BL = 2 (i.e. burst lasts only one clk cycle)
          if (wr_flag = '1') then
            -- if we have another non-conflict write command right after the
            -- current write, then stay in this state
            next_state <= CTRL_BURST_WRITE;
          else
            -- otherwise, if we're done with this burst, and have no write
            -- immediately scheduled after this one, wait until write-read
            -- delay has passed
            next_state <= CTRL_WRITE_WAIT;
          end if;
        else
          -- otherwise BL > 2, and we  have at least one more write cycle for
          -- current burst
          next_state <= CTRL_WRITE_WAIT;
          -- continuation of write burst (also covers waiting after write burst
          -- has completed for write-read delay to pass)
        end if;

      when CTRL_WRITE_WAIT =>
        if ((conflict_detect = '1') or (auto_ref_r = '1')) then
          if ((no_precharge_r = '1') and (auto_ref_r = '0') and
              (wrburst_ok_r = '1')) then
            next_state <= CTRL_ACTIVE;
          elsif (precharge_ok_r = '1') then
            next_state <= CTRL_PRECHARGE;
          end if;
        elsif ((wrburst_ok_r = '1') and (wr_flag = '1')) then
          next_state <= CTRL_BURST_WRITE;
        elsif ((rd_flag = '1') and (wr_to_rd_ok_r = '1')) then
          next_state <= CTRL_BURST_READ;
        end if;

      when CTRL_BURST_READ =>
        if (BURST_LEN_DIV2 = 1) then
          -- special case if BL = 2 (i.e. burst lasts only one clk cycle)
          if (rd_flag = '1') then
            next_state <= CTRL_BURST_READ;
          else
            next_state <= CTRL_READ_WAIT;
          end if;
        else
          next_state <= CTRL_READ_WAIT;
        end if;

      when CTRL_READ_WAIT =>
        if ((conflict_detect = '1') or (auto_ref_r = '1')) then
          if ((no_precharge_r = '1') and (auto_ref_r = '0') and
              (rdburst_ok_r = '1')) then
            next_state <= CTRL_ACTIVE;
          elsif (precharge_ok_r = '1') then
            next_state <= CTRL_PRECHARGE;
          end if;
        -- for burst of 4 in multi chip select
        -- if there is a change in cs wait one cycle before the
        -- next read command. cs_change_r will be asserted.
        elsif ((rdburst_ok_r = '1') and (rd_flag = '1') and
               (cs_change_r = '0')) then
          next_state <= CTRL_BURST_READ;
        elsif ((wr_flag = '1') and (rd_to_wr_ok_r = '1')) then
          next_state <= CTRL_BURST_WRITE;
        end if;
    end case;
  end process;

  --***************************************************************************
  -- control signals to memory
  --***************************************************************************

  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((state_r = CTRL_AUTO_REFRESH) or
          (state_r = CTRL_ACTIVE) or
          (state_r = CTRL_PRECHARGE)) then
        ddr_ras_n_r <= '0';
        two_t_enable_r(0) <= '0';
      else
        if (TWO_T_TIME_EN /= 0) then
          ddr_ras_n_r <= two_t_enable_r(0);
        else
          ddr_ras_n_r <= '1';
        end if;
        two_t_enable_r(0) <= '1';
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((state_r = CTRL_BURST_WRITE) or
          (state_r = CTRL_BURST_READ) or
          (state_r = CTRL_AUTO_REFRESH)) then
        ddr_cas_n_r <= '0';
        two_t_enable_r(1) <= '0';
      else
        if (TWO_T_TIME_EN /= 0) then
          ddr_cas_n_r <= two_t_enable_r(1);
        else
          ddr_cas_n_r <= '1';
        end if;
        two_t_enable_r(1) <= '1';
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((state_r = CTRL_BURST_WRITE) or (state_r = CTRL_PRECHARGE)) then
        ddr_we_n_r <= '0';
        two_t_enable_r(2) <= '0';
      else
        if (TWO_T_TIME_EN /= 0) then
          ddr_we_n_r <= two_t_enable_r(2);
        else
          ddr_we_n_r <= '1';
        end if;
        two_t_enable_r(2) <= '1';
      end if;
    end if;
  end process;

  -- turn off auto-precharge when issuing commands (A10 = 0)
  -- mapping the col add for linear addressing.
  gen_addr_col_two_t: if (TWO_T_TIME_EN /= 0) generate
    gen_ddr_addr_col_0: if (COL_WIDTH = ROW_WIDTH-1) generate
      ddr_addr_col <= (af_addr_r3(COL_WIDTH-1 downto 10) & '0' &
                       af_addr_r3(9 downto 0));
    end generate;
    gen_ddr_addr_col_1: if ((COL_WIDTH > 10) and
                            not(COL_WIDTH = ROW_WIDTH-1)) generate
      ddr_addr_col(ROW_WIDTH-1 downto COL_WIDTH+1) <= (others => '0');
      ddr_addr_col(COL_WIDTH downto 0) <=
        (af_addr_r3(COL_WIDTH-1 downto 10) & '0' & af_addr_r3(9 downto 0));
    end generate;
    gen_ddr_addr_col_2: if (not((COL_WIDTH > 10) or
                                (COL_WIDTH = ROW_WIDTH-1))) generate
      ddr_addr_col(ROW_WIDTH-1 downto COL_WIDTH+1) <= (others => '0');
      ddr_addr_col(COL_WIDTH downto 0) <=
        ('0' & af_addr_r3(COL_WIDTH-1 downto 0));
    end generate;
  end generate;
  gen_addr_col_one_t: if (TWO_T_TIME_EN = 0) generate
    gen_ddr_addr_col_0_1: if (COL_WIDTH = ROW_WIDTH-1) generate
      ddr_addr_col <= (af_addr_r2(COL_WIDTH-1 downto 10) & '0' &
                       af_addr_r2(9 downto 0));
    end generate;
    gen_ddr_addr_col_1_1: if ((COL_WIDTH > 10) and
                            not(COL_WIDTH = ROW_WIDTH-1)) generate
      ddr_addr_col(ROW_WIDTH-1 downto COL_WIDTH+1) <= (others => '0');
      ddr_addr_col(COL_WIDTH downto 0) <=
        (af_addr_r2(COL_WIDTH-1 downto 10) & '0' & af_addr_r2(9 downto 0));
    end generate;
    gen_ddr_addr_col_2_1: if (not((COL_WIDTH > 10) or
                                  (COL_WIDTH = ROW_WIDTH-1))) generate
      ddr_addr_col(ROW_WIDTH-1 downto COL_WIDTH+1) <= (others => '0');
      ddr_addr_col(COL_WIDTH downto 0) <=
        ('0' & af_addr_r2(COL_WIDTH-1 downto 0));
    end generate;
  end generate;

  -- Assign address during row activate
  gen_addr_row_two_t: if (TWO_T_TIME_EN /= 0) generate
    ddr_addr_row <= af_addr_r3(ROW_RANGE_END downto ROW_RANGE_START);
  end generate;
  gen_addr_row_one_t: if (TWO_T_TIME_EN = 0) generate
    ddr_addr_row <= af_addr_r2(ROW_RANGE_END downto ROW_RANGE_START);
  end generate;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((state_r = CTRL_ACTIVE) or
          ((state_r1 = CTRL_ACTIVE) and (TWO_T_TIME_EN /= 0))) then
        ddr_addr_r <= ddr_addr_row;
      elsif ((state_r = CTRL_BURST_WRITE) or
             (state_r = CTRL_BURST_READ) or
             (((state_r1 = CTRL_BURST_WRITE) or
               (state_r1 = CTRL_BURST_READ)) and
              TWO_T_TIME_EN /= 0)) then
        ddr_addr_r <= ddr_addr_col;
      elsif (((state_r = CTRL_PRECHARGE) or
              ((state_r1 = CTRL_PRECHARGE) and (TWO_T_TIME_EN /= 0))) and
             (auto_ref_r = '1')) then
        -- if we're precharging as a result of AUTO-REFRESH, prech all banks
        ddr_addr_r <= (others => '0');
        ddr_addr_r(10) <= '1';
      elsif ((state_r = CTRL_PRECHARGE) or
             ((state_r1 = CTRL_PRECHARGE) and (TWO_T_TIME_EN /= 0))) then
        -- if we're precharging to close a specific bank/row, set A10=0
        ddr_addr_r <= (others => '0');
      else
        ddr_addr_r <= (others => 'X');
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      -- whenever we're precharging, we're either: (1) prech all banks (in
      -- which case banks bits are don't care, (2) precharging the LRU bank,
      -- b/c we've exceeded the limit of # of banks open (need to close the LRU
      -- bank to make room for a new one), (3) we haven't exceed the maximum #
      -- of banks open, but we trying to open a different row in a bank that's
      -- already open
      if (((state_r = CTRL_PRECHARGE) or
           ((state_r1 = CTRL_PRECHARGE) and (TWO_T_TIME_EN /= 0))) and
          (bank_conflict_r = '1') and (MULTI_BANK_EN /= 0)) then
        -- When LRU bank needs to be closed
        ddr_ba_r <= bank_cmp_addr_r((3*CMP_WIDTH)+CMP_BANK_RANGE_END downto
                                    (3*CMP_WIDTH)+CMP_BANK_RANGE_START);
      else
        -- Either precharge due to refresh or bank hit case
        if (TWO_T_TIME_EN /= 0) then
          ddr_ba_r <= af_addr_r3(BANK_RANGE_END downto BANK_RANGE_START);
        else
          ddr_ba_r <= af_addr_r2(BANK_RANGE_END downto BANK_RANGE_START);
        end if;
      end if;
    end if;
  end process;

  -- chip enable generation logic
  -- if only one chip select, always assert it after reset
  gen_ddr_cs_0: if (CS_BITS = 0) generate
    process (clk)
    begin
      if (rising_edge(clk)) then
        if (rst_r1 = '1') then
          ddr_cs_n_r(0) <= '1';
        else
          ddr_cs_n_r(0) <= '0';
        end if;
      end if;
    end process;
  end generate;

  gen_ddr_cs_1_2t: if (not(CS_BITS = 0)) generate
    gen_2t_cs: if (TWO_T_TIME_EN /= 0) generate
      process (clk)
      begin
        if (rising_edge(clk)) then
          if (rst_r1 = '1') then
            ddr_cs_n_r <= (others => '1');
          elsif (state_r1 = CTRL_AUTO_REFRESH) then
            -- if auto-refreshing, only auto-refresh one CS at any time (avoid
            -- beating on the ground plane by refreshing all CS's at same time)
            ddr_cs_n_r <= (others => '1');
            ddr_cs_n_r(TO_INTEGER(auto_cnt_r)) <= '0';
          elsif ((auto_ref_r = '1') and (state_r1 = CTRL_PRECHARGE)) then
            ddr_cs_n_r <= (others => '0');
          elsif ((state_r1 = CTRL_PRECHARGE) and (bank_conflict_r = '1') and
                 (MULTI_BANK_EN /= 0)) then
            -- precharging the LRU bank
            ddr_cs_n_r <= (others => '1');
            ddr_cs_n_r(to_integer(
              unsigned(bank_cmp_addr_r((3*CMP_WIDTH)+CMP_CS_RANGE_END downto
                                       (3*CMP_WIDTH)+
                                       CMP_CS_RANGE_START)))) <= '0';
          else
            -- otherwise, check the upper address bits to see which CS to assert
            ddr_cs_n_r <= (others => '1');
            ddr_cs_n_r(to_integer(
              unsigned(af_addr_r3(CS_RANGE_END downto CS_RANGE_START)))) <= '0';
          end if;
        end if;
      end process;
    end generate;
  end generate;

  -- otherwise if we have multiple chip selects
  gen_ddr_cs_1_1t: if (not(CS_BITS = 0)) generate
    gen_1t_cs: if (TWO_T_TIME_EN = 0) generate
      process (clk)
      begin
        if (rising_edge(clk)) then
          if (rst_r1 = '1') then
            ddr_cs_n_r <= (others => '1');
          elsif (state_r = CTRL_AUTO_REFRESH) then
            -- if auto-refreshing, only auto-refresh one CS at any time (avoid
            -- beating on the ground plane by refreshing all CS's at same time)
            ddr_cs_n_r <= (others => '1');
            ddr_cs_n_r(TO_INTEGER(auto_cnt_r)) <= '0';
          elsif ((auto_ref_r = '1') and (state_r = CTRL_PRECHARGE)) then
            ddr_cs_n_r <= (others => '0');
          elsif ((state_r = CTRL_PRECHARGE) and (bank_conflict_r = '1') and
                 (MULTI_BANK_EN /= 0)) then
            -- precharging the LRU bank
            ddr_cs_n_r <= (others => '1');
            ddr_cs_n_r(to_integer(
              unsigned(bank_cmp_addr_r((3*CMP_WIDTH)+CMP_CS_RANGE_END downto
                                       (3*CMP_WIDTH)+
                                       CMP_CS_RANGE_START)))) <= '0';
          else
            -- otherwise, check the upper address bits to see which CS to assert
            ddr_cs_n_r <= (others => '1');
            ddr_cs_n_r(to_integer(
              unsigned(af_addr_r2(CS_RANGE_END downto CS_RANGE_START)))) <= '0';
          end if;
        end if;
      end process;
    end generate;
  end generate;

  -- registring the two_t timing enable signal.
  -- This signal will be asserted (low) when the
  -- chip select has to be asserted.
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (and_br(two_t_enable_r) = '1') then
        two_t_enable_r1 <= (others => '1');
      else
        two_t_enable_r1 <= (others => '0');
      end if;
    end if;
  end process;

  ctrl_addr  <= ddr_addr_r;
  ctrl_ba    <= ddr_ba_r;
  ctrl_ras_n <= ddr_ras_n_r;
  ctrl_cas_n <= ddr_cas_n_r;
  ctrl_we_n  <= ddr_we_n_r;
  ctrl_cs_n  <= (ddr_cs_n_r or two_t_enable_r1) when
                (TWO_T_TIME_EN /= 0) else
                ddr_cs_n_r;

end architecture syn;


