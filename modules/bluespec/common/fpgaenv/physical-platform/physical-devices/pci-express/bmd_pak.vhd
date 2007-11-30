----------------------------------------------------------------------------------
----
---- This file is owned and controlled by Xilinx and must be used solely
---- for design, simulation, implementation and creation of design files
---- limited to Xilinx devices or technologies. Use with non-Xilinx
---- devices or technologies is expressly prohibited and immediately
---- terminates your license.
----
---- Xilinx products are not intended for use in life support
---- appliances, devices, or systems. Use in such applications is
---- expressly prohibited.
----
----            **************************************
----            ** Copyright (C) 2005, Xilinx, Inc. **
----            ** All Rights Reserved.             **
----            **************************************
----
----------------------------------------------------------------------------------
---- Filename: bmd_pak.vhd
----
---- Description: Defines constants, functions, & procedures used by BMD design
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package bmd_pak is

    constant bmd_64 : Boolean := TRUE;
    constant msb_64_32 : integer := 63;
--`define BMD_RX_ENGINE    BMD_64_RX_ENGINE
--`define BMD_TX_ENGINE    BMD_64_TX_ENGINE


end bmd_pak;

package body bmd_pak is

    

end bmd_pak;
