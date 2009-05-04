--
-- Copyright (C) 2008 Intel Corporation
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity differential_clocks_device is
  port (

    -- input signals
    clk_p : in std_logic;
    clk_n : in std_logic;
    rst_n : in std_logic;

    -- exported clock
    clk_out   : out std_logic;
    rst_n_out : out std_logic

    );
end differential_clocks_device;

architecture rtl of differential_clocks_device is

begin

  -------------------------------------------------------
  -- Virtex5-FX Global Clock Buffer
  -------------------------------------------------------
  refclk_ibuf : IBUFDS port map (
    O  => clk_out,
    I  => clk_p,
    IB => clk_n);

  -- not sure if we need an IBUF for the reset
  sys_reset_n_ibuf : IBUF port map (
    O => rst_n_out,
    I => rst_n);
  
end;
