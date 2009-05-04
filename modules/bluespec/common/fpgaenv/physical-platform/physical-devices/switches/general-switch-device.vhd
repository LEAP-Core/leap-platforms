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

entity switches_device is
  
  generic (
    
    SWITCHES_WIDTH : integer := 2              -- number of switches

    );
  
  port (

    -- input signals
    switches_in  : in  std_logic_vector((SWITCHES_WIDTH - 1) downto 0);

    clk          : in std_logic;
    rst_n        : in std_logic;
    
    -- output signals
    switches_out : out std_logic_vector((SWITCHES_WIDTH - 1) downto 0)

    );
  
end switches_device;

architecture rtl of switches_device is

begin

  switches_out <= switches_in;

end;
