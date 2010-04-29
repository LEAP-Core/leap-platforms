-------------------------------------------------------------------------------
-- $Id: baudrate.vhd,v 1.2 2003/01/16 22:32:37 tise Exp $
-------------------------------------------------------------------------------
-- baudrate.vhd
-------------------------------------------------------------------------------
--
--  ***************************************************************************
--  **  Copyright(C) 2003 by Xilinx, Inc. All rights reserved.               **
--  **                                                                       **
--  **  This text contains proprietary, confidential                         **
--  **  information of Xilinx, Inc. , is distributed by                      **
--  **  under license from Xilinx, Inc., and may be used,                    **
--  **  copied and/or disclosed only pursuant to the terms                   **
--  **  of a valid license agreement with Xilinx, Inc.                       **
--  **                                                                       **
--  **  Unmodified source code is guaranteed to place and route,             **
--  **  function and run at speed according to the datasheet                 **
--  **  specification. Source code is provided "as-is", with no              **
--  **  obligation on the part of Xilinx to provide support.                 **
--  **                                                                       **
--  **  Xilinx Hotline support of source code IP shall only include          **
--  **  standard level Xilinx Hotline support, and will only address         **
--  **  issues and questions related to the standard released Netlist        **
--  **  version of the core (and thus indirectly, the original core source). **
--  **                                                                       **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Support Hotline will only be able          **
--  **  to confirm the problem in the Netlist version of the core.           **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        baudrate.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              baudrate.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision: 1.2 $
-- Date:            $Date: 2003/01/16 22:32:37 $
--
-- History:
--   goran  2001-06-12    First Version
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity Baud_Rate is

  generic (
    C_RATIO      :     integer := 814;  -- The ratio between clk and the asked
                                        -- baudrate multiplied with 16
    C_INACCURACY :     integer := 20    -- The maximum inaccuracy of the clk
    );                                  -- division in per thousands
  port (
    Clk          : in  std_logic;
    EN_16x_Baud  : out std_logic);

end entity Baud_Rate;

architecture VHDL_RTL of Baud_Rate is

  signal Count : natural range 0 to C_RATIO-1;

begin  -- architecture VHDL_RTL

  Counter : process (Clk) is
  begin  -- process Counter
    if Clk'event and Clk = '1' then     -- rising clock edge
      if (Count = 0) then
        Count       <= C_RATIO-1;
        EN_16x_Baud <= '1';
      else
        Count       <= Count - 1;
        EN_16x_Baud <= '0';
      end if;
    end if;
  end process Counter;

end architecture VHDL_RTL;

