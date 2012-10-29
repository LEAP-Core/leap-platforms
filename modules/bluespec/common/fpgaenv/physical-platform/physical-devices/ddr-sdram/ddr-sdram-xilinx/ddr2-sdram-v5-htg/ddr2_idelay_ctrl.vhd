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
--  /   /         Filename: ddr2_idelay_ctrl.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/05/08 15:20:48 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR2
--Purpose:
--   This module instantiates the IDELAYCTRL primitive of the Virtex-5 device
--   which continuously calibrates the IDELAY elements in the region in case of
--   varying operating conditions. It takes a 200MHz clock as an input
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_idelay_ctrl is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference 
    -- board design). Actual values may be different. Actual parameters values 
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    IDELAYCTRL_NUM : integer := 4
    );
  port (
    clk200           : in std_logic;
    rst200           : in std_logic;
    idelay_ctrl_rdy  : out std_logic
  );
end entity ddr2_idelay_ctrl;

architecture syn of ddr2_idelay_ctrl is

  constant ONES : std_logic_vector(IDELAYCTRL_NUM-1 downto 0) := (others => '1');

  signal idelay_ctrl_rdy_i : std_logic_vector(IDELAYCTRL_NUM-1 downto 0);

begin

IDELAYCTRL_INST : for bnk_i in 0 to IDELAYCTRL_NUM-1 generate
  u_idelayctrl : IDELAYCTRL
    port map (
      rdy     => idelay_ctrl_rdy_i(bnk_i),
      refclk  => clk200,
      rst     => rst200
    );
end generate IDELAYCTRL_INST;

idelay_ctrl_rdy <= '1' when (idelay_ctrl_rdy_i = ONES) else
                   '0';

end architecture syn;
