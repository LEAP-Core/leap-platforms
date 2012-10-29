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
--  /   /         Filename: ddr2_usr_addr_fifo.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/05/08 15:20:48 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR/DDR2
--Purpose:
--   This module instantiates the block RAM based FIFO to store the user
--   address and the command information. Also calculates potential bank/row
--   conflicts by comparing the new address with last address issued.
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_usr_addr_fifo is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference 
    -- board design). Actual values may be different. Actual parameters values 
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    BANK_WIDTH         : integer := 2;
    COL_WIDTH          : integer := 10;
    CS_BITS            : integer := 0;
    ROW_WIDTH          : integer := 14
  );
  port (
    clk0               : in std_logic;
    rst0               : in std_logic;
    app_af_cmd         : in std_logic_vector(2 downto 0);
    app_af_addr        : in std_logic_vector(30 downto 0);
    app_af_wren        : in std_logic;
    ctrl_af_rden       : in std_logic;
    af_cmd             : out std_logic_vector(2 downto 0);
    af_addr            : out std_logic_vector(30 downto 0);
    af_empty           : out std_logic;
    app_af_afull       : out std_logic
  );
end entity ddr2_usr_addr_fifo;

architecture syn of ddr2_usr_addr_fifo is

  signal fifo_data_out : std_logic_vector(35 downto 0);
  signal rst_r         : std_logic;

  signal i_fifo_data_in : std_logic_vector(35 downto 0);

begin

  i_fifo_data_in(31 downto 0)  <= app_af_cmd(0) & app_af_addr;
  i_fifo_data_in(35 downto 32) <= "00" & app_af_cmd(2 downto 1);

  process (clk0)
  begin
    if (rising_edge(clk0)) then
      rst_r <= rst0;
    end if;
  end process;

  --***************************************************************************

  af_cmd  <= fifo_data_out(33 downto 31);
  af_addr <= fifo_data_out(30 downto 0);

  --***************************************************************************

  u_af : FIFO36
    generic map (
      ALMOST_EMPTY_OFFSET      => X"0007",
      ALMOST_FULL_OFFSET       => X"000F",
      DATA_WIDTH               => 36,
      DO_REG                   => 1,
      EN_SYN                   => true,
      FIRST_WORD_FALL_THROUGH  => false
    )
    port map (
      ALMOSTEMPTY  => open,
      ALMOSTFULL   => app_af_afull,
      DO           => fifo_data_out(31 downto 0),
      DOP          => fifo_data_out(35 downto 32),
      EMPTY        => af_empty,
      FULL         => open,
      RDCOUNT      => open,
      RDERR        => open,
      WRCOUNT      => open,
      WRERR        => open,
      DI           => i_fifo_data_in(31 downto 0),
      DIP          => i_fifo_data_in(35 downto 32),
      RDCLK        => clk0,
      RDEN         => ctrl_af_rden,
      RST          => rst_r,
      WRCLK        => clk0,
      WREN         => app_af_wren
    );

end architecture syn;


