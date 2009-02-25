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
--  /   /         Filename: ddr2_infrastructure.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/07/29 15:24:03 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR2
--Purpose:
--   Clock generation/distribution and reset synchronization
--Reference:
--Revision History:
--   Rev 1.1 - Parameter CLK_TYPE added and logic for  DIFFERENTIAL and 
--             SINGLE_ENDED added. PK. 20/6/08
--*****************************************************************************


library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_infrastructure is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference
    -- board design). Actual values may be different. Actual parameters values
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    CLK_PERIOD    : integer := 3000;
    CLK_TYPE      : string  := "DIFFERENTIAL";
    DLL_FREQ_MODE : string  := "HIGH";
    RST_ACT_LOW   : integer := 1
    );
  port (
    sys_clk_p       : in std_logic;
    sys_clk_n       : in std_logic;
    sys_clk         : in std_logic;
    clk200_p        : in std_logic;
    clk200_n        : in std_logic;
    idly_clk_200    : in std_logic;
    clk0            : out std_logic;
    clk90           : out std_logic;
    clk200          : out std_logic;
    clkdiv0         : out std_logic;

    sys_rst_n       : in  std_logic;
    idelay_ctrl_rdy : in  std_logic;
    rst0            : out std_logic;
    rst90           : out std_logic;
    rst200          : out std_logic;
    rstdiv0         : out std_logic
    );
end entity ddr2_infrastructure;

architecture syn of ddr2_infrastructure is

  -- # of clock cycles to delay deassertion of reset. Needs to be a fairly
  -- high number not so much for metastability protection, but to give time
  -- for reset (i.e. stable clock cycles) to propagate through all state
  -- machines and to all control signals (i.e. not all control signals have
  -- resets, instead they rely on base state logic being reset, and the effect
  -- of that reset propagating through the logic). Need this because we may not
  -- be getting stable clock cycles while reset asserted (i.e. since reset
  -- depends on DCM lock status)
  constant RST_SYNC_NUM  : integer := 25;

  constant CLK_PERIOD_NS : real := (real(CLK_PERIOD)) / 1000.0;

  signal clk0_bufg      : std_logic;
  signal clk90_bufg     : std_logic;
  signal clk200_bufg    : std_logic;
  signal clkdiv0_bufg   : std_logic;
  signal clk200_ibufg   : std_logic;
  signal dcm_clk0       : std_logic;
  signal dcm_clk90      : std_logic;
  signal dcm_clkdiv0    : std_logic;
  signal dcm_lock       : std_logic;
  signal rst0_sync_r    : std_logic_vector(RST_SYNC_NUM-1 downto 0);
  signal rst200_sync_r  : std_logic_vector(RST_SYNC_NUM-1 downto 0);
  signal rst90_sync_r   : std_logic_vector(RST_SYNC_NUM-1 downto 0);
  signal rstdiv0_sync_r : std_logic_vector((RST_SYNC_NUM/2)-1 downto 0);
  signal rst_tmp        : std_logic;
  signal sys_clk_ibufg  : std_logic;
  signal sys_rst        : std_logic;

  attribute max_fanout : string;
  attribute syn_maxfan : integer;
  attribute max_fanout of rst0_sync_r    : signal is "10";
  attribute syn_maxfan of rst0_sync_r    : signal is 10;
  attribute max_fanout of rst200_sync_r  : signal is "10";
  attribute syn_maxfan of rst200_sync_r  : signal is 10;
  attribute max_fanout of rst90_sync_r   : signal is "10";
  attribute syn_maxfan of rst90_sync_r   : signal is 10;
  attribute max_fanout of rstdiv0_sync_r : signal is "10";
  attribute syn_maxfan of rstdiv0_sync_r : signal is 10;

begin

  sys_rst <= not(sys_rst_n) when (RST_ACT_LOW /= 0) else sys_rst_n;

  clk0    <= clk0_bufg;
  clk90   <= clk90_bufg;
  clk200  <= clk200_bufg;
  clkdiv0 <= clkdiv0_bufg;

  DIFF_ENDED_CLKS_INST : if(CLK_TYPE = "DIFFERENTIAL") generate
  begin
    --**************************************************************************
    -- Differential input clock input buffers
    --**************************************************************************

    SYS_CLK_INST : IBUFGDS_LVPECL_25
      port map (
        I  => sys_clk_p,
        IB => sys_clk_n,
        O  => sys_clk_ibufg
        );

    IDLY_CLK_INST : IBUFGDS_LVPECL_25
      port map (
        I  => clk200_p,
        IB => clk200_n,
        O  => clk200_ibufg
        );

  end generate;

  SINGLE_ENDED_CLKS_INST : if(CLK_TYPE = "SINGLE_ENDED") generate
  begin
    --**************************************************************************
    -- Single ended input clock input buffers
    --**************************************************************************

    -- Angshuman - remove input buffers
    --SYS_CLK_INST : IBUFG
    --  port map (
    --    I  => sys_clk,
    --    O  => sys_clk_ibufg
    --    );

    --IDLY_CLK_INST : IBUFG
    --  port map (
    --    I  => idly_clk_200,
    --    O  => clk200_ibufg
    --    );

    sys_clk_ibufg <= sys_clk;
    clk200_ibufg <= idly_clk_200;

  end generate;

  CLK_200_BUFG : BUFG
    port map (
      O => clk200_bufg,
      I => clk200_ibufg
      );

  --***************************************************************************
  -- Global clock generation and distribution
  --***************************************************************************

  u_dcm_base : DCM_BASE
    generic map (
      CLKIN_PERIOD          => CLK_PERIOD_NS,
      CLKDV_DIVIDE          => 2.0,
      DLL_FREQUENCY_MODE    => DLL_FREQ_MODE,
      DUTY_CYCLE_CORRECTION => true,
      FACTORY_JF            => X"F0F0"
      )
    port map (
      CLK0                  => dcm_clk0,
      CLK180                => open,
      CLK270                => open,
      CLK2X                 => open,
      CLK2X180              => open,
      CLK90                 => dcm_clk90,
      CLKDV                 => dcm_clkdiv0,
      CLKFX                 => open,
      CLKFX180              => open,
      LOCKED                => dcm_lock,
      CLKFB                 => clk0_bufg,
      CLKIN                 => sys_clk_ibufg,
      RST                   => sys_rst
      );

  U_BUFG_CLK0 : BUFG
    port map (
      O => clk0_bufg,
      I => dcm_clk0
      );

  U_BUFG_CLK90 : BUFG
    port map (
      O => clk90_bufg,
      I => dcm_clk90
      );

  U_BUFG_CLKDIV0 : BUFG
    port map (
      O  => clkdiv0_bufg,
      I  => dcm_clkdiv0
    );



  --***************************************************************************
  -- Reset synchronization
  -- NOTES:
  --   1. shut down the whole operation if the DCM hasn't yet locked (and by
  --      inference, this means that external SYS_RST_IN has been asserted -
  --      DCM deasserts DCM_LOCK as soon as SYS_RST_IN asserted)
  --   2. In the case of all resets except rst200, also assert reset if the
  --      IDELAY master controller is not yet ready
  --   3. asynchronously assert reset. This was we can assert reset even if
  --      there is no clock (needed for things like 3-stating output buffers).
  --      reset deassertion is synchronous.
  --***************************************************************************

  rst_tmp <= sys_rst or not(dcm_lock) or not(idelay_ctrl_rdy);

  process (clk0_bufg, rst_tmp)
  begin
    if (rst_tmp = '1') then
      rst0_sync_r <= (others => '1');
    elsif (rising_edge(clk0_bufg)) then
      -- logical left shift by one (pads with 0)
      rst0_sync_r <= rst0_sync_r(RST_SYNC_NUM-2 downto 0) & '0';
    end if;
  end process;

  process (clkdiv0_bufg, rst_tmp)
  begin
    if (rst_tmp = '1') then
      rstdiv0_sync_r <= (others => '1');
    elsif (rising_edge(clkdiv0_bufg)) then
      -- logical left shift by one (pads with 0)
      rstdiv0_sync_r <= rstdiv0_sync_r((RST_SYNC_NUM/2)-2 downto 0) & '0';
    end if;
  end process;

  process (clk90_bufg, rst_tmp)
  begin
    if (rst_tmp = '1') then
      rst90_sync_r <= (others => '1');
    elsif (rising_edge(clk90_bufg)) then
      rst90_sync_r <= rst90_sync_r(RST_SYNC_NUM-2 downto 0) & '0';
    end if;
  end process;

  -- make sure CLK200 doesn't depend on IDELAY_CTRL_RDY, else chicken n' egg
  process (clk200_bufg, dcm_lock)
  begin
    if ((not(dcm_lock)) = '1') then
      rst200_sync_r <= (others => '1');
    elsif (rising_edge(clk200_bufg)) then
      rst200_sync_r <= rst200_sync_r(RST_SYNC_NUM-2 downto 0) & '0';
    end if;
  end process;

  rst0    <= rst0_sync_r(RST_SYNC_NUM-1);
  rst90   <= rst90_sync_r(RST_SYNC_NUM-1);
  rst200  <= rst200_sync_r(RST_SYNC_NUM-1);
  rstdiv0 <= rstdiv0_sync_r((RST_SYNC_NUM/2)-1);

end architecture syn;


