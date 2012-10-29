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
--  /   /         Filename: ddr2_phy_dqs_iob.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/07/22 15:41:06 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR/DDR2
--Purpose:
--   This module places the data strobes in the IOBs.
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_phy_dqs_iob is
  generic (
    DDR_TYPE              : integer := 1;
    HIGH_PERFORMANCE_MODE : boolean := TRUE
  );
  port (
    clk0           : in std_logic;
    clkdiv0        : in std_logic;
    rst0           : in std_logic;
    dlyinc_dqs     : in std_logic;
    dlyce_dqs      : in std_logic;
    dlyrst_dqs     : in std_logic;
    dlyinc_gate    : in std_logic;
    dlyce_gate     : in std_logic;
    dlyrst_gate    : in std_logic;
    dqs_oe_n       : in std_logic;
    dqs_rst_n      : in std_logic;
    en_dqs         : in std_logic;
    ddr_dqs        : inout std_logic;
    ddr_dqs_n      : inout std_logic;
    dq_ce          : out std_logic;
    delayed_dqs    : out std_logic
  );
end entity ddr2_phy_dqs_iob;

architecture syn of ddr2_phy_dqs_iob is

  -- only need explicit component declarations for IODELAY
  -- for pre-Synplify Pro 8.8 (Synplify Pro 8.8+ and XST understands this
  -- primitive)
  component IODELAY
    generic (
      DELAY_SRC             : string;
      HIGH_PERFORMANCE_MODE : boolean;
      IDELAY_TYPE           : string;
      IDELAY_VALUE          : integer;
      ODELAY_VALUE          : integer);
    port (
      DATAOUT : out std_ulogic;
      C       : in  std_ulogic;
      CE      : in  std_ulogic;
      DATAIN  : in  std_ulogic;
      IDATAIN : in  std_ulogic;
      INC     : in  std_ulogic;
      ODATAIN : in  std_ulogic;
      RST     : in  std_ulogic;
      T       : in  std_ulogic);
  end component;

  -- for simulation only. Synthesis should ignore this delay
  constant DQS_NET_DELAY : time := 0.8 ns;

  signal clk180          : std_logic;
  signal dqs_bufio       : std_logic;
  signal dqs_ibuf        : std_logic;
  signal dqs_idelay      : std_logic;
  signal dqs_oe_n_delay  : std_logic;
  signal dqs_oe_n_r      : std_logic;
  signal dqs_rst_n_delay : std_logic;
  signal dqs_rst_n_r     : std_logic;
  signal dqs_out         : std_logic;
  signal en_dqs_sync     : std_logic;

  attribute syn_black_box : boolean;
  attribute syn_black_box of IODELAY : component is true;
  attribute IOB : string;
  attribute syn_useioff : boolean;
  attribute IOB of u_tri_state_dqs : label is "true";
  attribute syn_useioff of u_tri_state_dqs : label is true;

  attribute equivalent_register_removal : string;
  attribute max_fanout : string;
  attribute syn_keep : boolean;
  attribute syn_maxfan : integer;
  attribute syn_preserve : boolean;
  attribute max_fanout of dqs_rst_n_r : signal is "1";
  attribute syn_maxfan of dqs_rst_n_r : signal is 1;
  attribute equivalent_register_removal of dqs_rst_n_r : signal is "no";
  attribute syn_preserve of dqs_rst_n_r : signal is true;
  attribute syn_keep of dqs_rst_n_r : signal is true;

  signal i_delayed_dqs : std_logic;

begin

  clk180 <= not(clk0);

  -- add delta delay to inputs clocked by clk180 to avoid delta-delay
  -- simulation issues
  dqs_rst_n_delay <= dqs_rst_n;
  dqs_oe_n_delay  <= dqs_oe_n;

  --***************************************************************************
  -- DQS input-side resources:
  --  - IODELAY (pad -> IDELAY)
  --  - BUFIO (IDELAY -> BUFIO)
  --***************************************************************************

  -- Route DQS from PAD to IDELAY
  u_idelay_dqs : IODELAY
    generic map (
      DELAY_SRC             => "I",
      IDELAY_TYPE           => "VARIABLE",
      HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
      IDELAY_VALUE          => 0,
      ODELAY_VALUE          => 0
      )
    port map (
      DATAOUT => dqs_idelay,
      C       => clkdiv0,
      CE      => dlyce_dqs,
      DATAIN  => '0',
      IDATAIN => dqs_ibuf,
      INC     => dlyinc_dqs,
      ODATAIN => '0',
      RST     => dlyrst_dqs,
      T       => '0'
      );

  -- From IDELAY to BUFIO
  u_bufio_dqs : BUFIO
    port map (
      I  => dqs_idelay,
      O  => dqs_bufio
    );

  -- To model additional delay of DQS BUFIO + gating network
  -- for behavioral simulation. Make sure to select a delay number smaller
  -- than half clock cycle (otherwise output will not track input changes
  -- because of inertial delay). Duplicate to avoid delta delay issues.
  i_delayed_dqs <= dqs_bufio after DQS_NET_DELAY;
  delayed_dqs <= dqs_bufio after DQS_NET_DELAY;

  --***************************************************************************
  -- DQS gate circuit (not supported for all controllers)
  --***************************************************************************

  -- Gate routing:
  --   en_dqs -> IDELAY -> en_dqs_sync -> IDDR.S -> dq_ce ->
  --   capture IDDR.CE

  -- Delay CE control so that it's in phase with delayed DQS
  u_iodelay_dq_ce : IODELAY
    generic map (
      DELAY_SRC             => "DATAIN",
      IDELAY_TYPE           => "VARIABLE",
      HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
      IDELAY_VALUE          => 0,
      ODELAY_VALUE          => 0
      )
    port map (
      DATAOUT => en_dqs_sync,
      C       => clkdiv0,
      CE      => dlyce_gate,
      DATAIN  => en_dqs,
      IDATAIN => '0',
      INC     => dlyinc_gate,
      ODATAIN => '0',
      RST     => dlyrst_gate,
      T       => '0'
      );

  -- Generate sync'ed CE to DQ IDDR's using an IDDR clocked by DQS
  -- We could also instantiate a negative-edge SDR flop here
  u_iddr_dq_ce : IDDR
    generic map (
      DDR_CLK_EDGE  => "OPPOSITE_EDGE",
      INIT_Q1       => '0',
      INIT_Q2       => '0',
      SRTYPE        => "ASYNC"
      )
    port map (
      Q1 => open,
      Q2 => dq_ce,                      -- output on falling edge
      C  => i_delayed_dqs,
      CE => '1',
      D  => en_dqs_sync,
      R  => '0',
      S  => en_dqs_sync
      );

  --***************************************************************************
  -- DQS output-side resources
  --***************************************************************************

  process (clk180)
  begin
    if (rising_edge(clk180)) then
      dqs_rst_n_r <= dqs_rst_n_delay;
    end if;
  end process;

  u_oddr_dqs : ODDR
    generic map (
      SRTYPE        => "SYNC",
      DDR_CLK_EDGE  => "OPPOSITE_EDGE"
    )
    port map (
      Q  => dqs_out,
      C  => clk180,
      CE => '1',
      D1 => dqs_rst_n_r, -- keep output deasserted for write preamble
      D2 => '0',
      R  => '0',
      S  => '0'
      );

  u_tri_state_dqs : FDP
    port map (
      D   => dqs_oe_n_delay,
      Q   => dqs_oe_n_r,
      C   => clk180,
      PRE => rst0
      );

  --***************************************************************************

  -- use either single-ended (for DDR1) or differential (for DDR2) DQS input

  gen_dqs_iob_ddr2_ddr3: if (DDR_TYPE > 0) generate
    u_iobuf_dqs : IOBUFDS
      port map (
        O   => dqs_ibuf,
        IO  => ddr_dqs,
        IOB => ddr_dqs_n,
        I   => dqs_out,
        T   => dqs_oe_n_r
        );
  end generate;

  gen_dqs_iob_ddr1: if (DDR_TYPE = 0) generate
    u_iobuf_dqs : IOBUF
      port map (
        O  => dqs_ibuf,
        IO => ddr_dqs,
        I  => dqs_out,
        T  => dqs_oe_n_r
        );
  end generate;

end architecture syn;


