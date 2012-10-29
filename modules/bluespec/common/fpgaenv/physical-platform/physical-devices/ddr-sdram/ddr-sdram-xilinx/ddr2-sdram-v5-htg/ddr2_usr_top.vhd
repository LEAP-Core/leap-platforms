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
--  /   /         Filename: ddr2_usr_top.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/05/08 15:20:48 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR/DDR2
--Purpose:
--   This module interfaces with the user. The user should provide the data
--   and various commands.
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;

entity ddr2_usr_top is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference 
    -- board design). Actual values may be different. Actual parameters values 
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    BANK_WIDTH         :     integer := 2;
    CS_BITS            :     integer := 0;
    COL_WIDTH          :     integer := 10;
    DQ_WIDTH           :     integer := 72;
    DQ_PER_DQS         :     integer := 8;
    ECC_ENABLE         :     integer := 0;
    APPDATA_WIDTH      :     integer := 144;
    DQS_WIDTH          :     integer := 9;
    ROW_WIDTH          :     integer := 14
    );
  port (
    clk0               : in  std_logic;
    clk90              : in  std_logic;
    rst0               : in  std_logic;
    rd_data_in_rise    : in  std_logic_vector(DQ_WIDTH-1 downto 0);
    rd_data_in_fall    : in  std_logic_vector(DQ_WIDTH-1 downto 0);
    phy_calib_rden     : in  std_logic_vector(DQS_WIDTH-1 downto 0);
    phy_calib_rden_sel : in  std_logic_vector(DQS_WIDTH-1 downto 0);
    rd_data_valid      : out std_logic;
    rd_data_fifo_out   : out std_logic_vector((APPDATA_WIDTH)-1 downto 0);
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
    wdf_mask_data      : out std_logic_vector(((2*DQ_WIDTH)/8)-1 downto 0)
    );
end entity ddr2_usr_top;

architecture syn of ddr2_usr_top is

  component ddr2_usr_addr_fifo
    generic (
      BANK_WIDTH    : integer;
      COL_WIDTH     : integer;
      CS_BITS       : integer;
      ROW_WIDTH     : integer);
    port (
      clk0         : in  std_logic;
      rst0         : in  std_logic;
      app_af_cmd   : in  std_logic_vector(2 downto 0);
      app_af_addr  : in  std_logic_vector(30 downto 0);
      app_af_wren  : in  std_logic;
      ctrl_af_rden : in  std_logic;
      af_cmd       : out std_logic_vector(2 downto 0);
      af_addr      : out std_logic_vector(30 downto 0);
      af_empty     : out std_logic;
      app_af_afull : out std_logic);
  end component;

  component ddr2_usr_rd
    generic (
      DQ_PER_DQS     : integer;
      DQS_WIDTH      : integer;
      APPDATA_WIDTH  : integer;
      ECC_ENABLE     : integer);
    port (
      clk0             : in  std_logic;
      rst0             : in  std_logic;
      rd_data_in_rise  : in  std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1
                                              downto 0);
      rd_data_in_fall  : in  std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1
                                              downto 0);
      ctrl_rden        : in  std_logic_vector(DQS_WIDTH-1 downto 0);
      ctrl_rden_sel    : in  std_logic_vector(DQS_WIDTH-1 downto 0);
      rd_ecc_error     : out std_logic_vector(1 downto 0);
      rd_data_valid    : out std_logic;
      rd_data_out_rise : out std_logic_vector((APPDATA_WIDTH/2)-1 downto 0);
      rd_data_out_fall : out std_logic_vector((APPDATA_WIDTH/2)-1 downto 0));
  end component;

  component ddr2_usr_wr
    generic (
      BANK_WIDTH     : integer;
      COL_WIDTH      : integer;
      CS_BITS        : integer;
      DQ_WIDTH       : integer;
      ECC_ENABLE     : integer;
      APPDATA_WIDTH  : integer;
      ROW_WIDTH      : integer);
    port (
      clk0              : in  std_logic;
      clk90             : in  std_logic;
      rst0              : in  std_logic;
      app_wdf_wren      : in  std_logic;
      app_wdf_data      : in  std_logic_vector(APPDATA_WIDTH-1 downto 0);
      app_wdf_mask_data : in  std_logic_vector((APPDATA_WIDTH/8)-1 downto 0);
      wdf_rden          : in  std_logic;
      app_wdf_afull     : out std_logic;
      wdf_data          : out std_logic_vector((2*DQ_WIDTH)-1 downto 0);
      wdf_mask_data     : out std_logic_vector(((2*DQ_WIDTH)/8)-1 downto 0));
  end component;

  signal i_rd_data_fifo_out_fall : std_logic_vector((APPDATA_WIDTH/2)-1
                                                    downto 0);
  signal i_rd_data_fifo_out_rise : std_logic_vector((APPDATA_WIDTH/2)-1
                                                    downto 0);

begin

  --***************************************************************************

  rd_data_fifo_out <= (i_rd_data_fifo_out_fall &
                       i_rd_data_fifo_out_rise);

  -- read data de-skew and ECC calculation
  u_usr_rd : ddr2_usr_rd
    generic map (
      DQ_PER_DQS       => DQ_PER_DQS,
      ECC_ENABLE       => ECC_ENABLE,
      APPDATA_WIDTH    => APPDATA_WIDTH,
      DQS_WIDTH        => DQS_WIDTH
      )
    port map (
      clk0             => clk0,
      rst0             => rst0,
      rd_data_in_rise  => rd_data_in_rise,
      rd_data_in_fall  => rd_data_in_fall,
      rd_ecc_error     => rd_ecc_error,
      ctrl_rden        => phy_calib_rden,
      ctrl_rden_sel    => phy_calib_rden_sel,
      rd_data_valid    => rd_data_valid,
      rd_data_out_rise => i_rd_data_fifo_out_rise,
      rd_data_out_fall => i_rd_data_fifo_out_fall
      );

  -- Command/Addres FIFO
  u_usr_addr_fifo : ddr2_usr_addr_fifo
    generic map (
      BANK_WIDTH   => BANK_WIDTH,
      COL_WIDTH    => COL_WIDTH,
      CS_BITS      => CS_BITS,
      ROW_WIDTH    => ROW_WIDTH
      )
    port map (
      clk0         => clk0,
      rst0         => rst0,
      app_af_cmd   => app_af_cmd,
      app_af_addr  => app_af_addr,
      app_af_wren  => app_af_wren,
      ctrl_af_rden => ctrl_af_rden,
      af_cmd       => af_cmd,
      af_addr      => af_addr,
      af_empty     => af_empty,
      app_af_afull => app_af_afull
      );

  u_usr_wr : ddr2_usr_wr
    generic map (
      BANK_WIDTH        => BANK_WIDTH,
      COL_WIDTH         => COL_WIDTH,
      CS_BITS           => CS_BITS,
      DQ_WIDTH          => DQ_WIDTH,
      ECC_ENABLE        => ECC_ENABLE,
      APPDATA_WIDTH     => APPDATA_WIDTH,
      ROW_WIDTH         => ROW_WIDTH
      )
    port map (
      clk0              => clk0,
      clk90             => clk90,
      rst0              => rst0,
      app_wdf_wren      => app_wdf_wren,
      app_wdf_data      => app_wdf_data,
      app_wdf_mask_data => app_wdf_mask_data,
      wdf_rden          => wdf_rden,
      app_wdf_afull     => app_wdf_afull,
      wdf_data          => wdf_data,
      wdf_mask_data     => wdf_mask_data
      );

end architecture syn;



