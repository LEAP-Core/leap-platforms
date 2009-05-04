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

entity single_ended_clocks_device is
  port (

    -- input signals
    clk   : in std_logic;
    rst_n : in std_logic;

    -- exported clock
    clk_out   : out std_logic;
    rst_n_out : out std_logic

    );
end single_ended_clocks_device;

architecture rtl of single_ended_clocks_device is

begin

  clk_out   <= clk;
  rst_n_out <= rst_n;

end;
