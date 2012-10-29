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
-- done at the users sole risk and will be unsupported.
--
-- Copyright (c) 2006-2007 Xilinx, Inc. All rights reserved.
--
-- This copyright and support notice must be retained as part
-- of this text at all times.
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 2.3
--  \   \         Application        : MIG
--  /   /         Filename           : ddr2_chipscope.v
-- /___/   /\     Timestamp          : 15 May 2006
-- \   \  /  \    Date Last Modified : $Date: 2008/05/08 15:20:47 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDR2
--
--Purpose:
--   This module has the declaration of ddr2_chipscope modules. It has the module
--   declaration of VIO and ICON
--
--Revision History:
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package ddr2_chipscope is

  component icon4
    port (
      control0               : out   std_logic_vector(35 downto 0);
      control1               : out   std_logic_vector(35 downto 0);
      control2               : out   std_logic_vector(35 downto 0);
      control3               : out   std_logic_vector(35 downto 0)
      );
  end component;

  component vio_async_in192
    port (
      control                 : in   std_logic_vector(35 downto 0);
      async_in                : in   std_logic_vector(191 downto 0)
      );
  end component;

  component vio_async_in96
    port (
      control                 : in   std_logic_vector(35 downto 0);
      async_in                : in   std_logic_vector(95 downto 0)
      );
  end component;

  component vio_async_in100
    port (
      control                 : in   std_logic_vector(35 downto 0);
      async_in                : in   std_logic_vector(99 downto 0)
      );
  end component;

  component vio_sync_out32
    port (
      control                 : in   std_logic_vector(35 downto 0);
      clk                     : in   std_logic;
      sync_out                : out   std_logic_vector(31 downto 0)
      );
  end component;


  attribute syn_black_box : boolean;
  attribute syn_noprune   : boolean;
  attribute syn_noprune   of icon4            : component is TRUE;
  attribute syn_noprune   of vio_async_in192  : component is TRUE;
  attribute syn_noprune   of vio_async_in96   : component is TRUE;
  attribute syn_noprune   of vio_async_in100  : component is TRUE;
  attribute syn_noprune   of vio_sync_out32   : component is TRUE;
  attribute syn_black_box of icon4           : component is TRUE;
  attribute syn_black_box of vio_async_in192 : component is TRUE;
  attribute syn_black_box of vio_async_in96  : component is TRUE;
  attribute syn_black_box of vio_async_in100 : component is TRUE;
  attribute syn_black_box of vio_sync_out32  : component is TRUE;

end ddr2_chipscope;