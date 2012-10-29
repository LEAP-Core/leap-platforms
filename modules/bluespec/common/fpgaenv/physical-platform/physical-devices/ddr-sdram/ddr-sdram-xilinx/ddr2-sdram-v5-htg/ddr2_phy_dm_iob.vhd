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
--  /   /         Filename: ddr2_phy_dm_iob.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/05/21 14:53:09 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR2
--Purpose:
--   This module places the data mask signals into the IOBs.
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_phy_dm_iob is
  port (
    clk90           : in std_logic;
    dm_ce           : in std_logic;
    mask_data_rise  : in std_logic;
    mask_data_fall  : in std_logic;
    ddr_dm          : out std_logic
  );
end entity ddr2_phy_dm_iob;

architecture syn of ddr2_phy_dm_iob is

  signal dm_out        : std_logic;
  signal dm_ce_r       : std_logic;

begin

  u_dm_ce : FDRSE_1
    port map (
      Q    => dm_ce_r,
      C    => clk90,
      CE   => '1',
      D    => dm_ce,
      R    => '0',
      S    => '0'
      );

  u_oddr_dm : ODDR
    generic map (
      SRTYPE        => "SYNC",
      DDR_CLK_EDGE  => "SAME_EDGE"
      )
    port map (
      Q  => dm_out,
      C  => clk90,
      CE => dm_ce_r,
      D1 => mask_data_rise,
      D2 => mask_data_fall,
      R  => '0',
      S  => '0'
      );

  u_obuf_dm : OBUF
    port map (
      I  => dm_out,
      O  => ddr_dm
    );

end architecture syn;


