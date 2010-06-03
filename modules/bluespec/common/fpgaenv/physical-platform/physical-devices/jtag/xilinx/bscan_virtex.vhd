-------------------------------------------------------------------------------
-- $Id: bscan_virtex.vhd,v 1.1.2.1 2008/06/26 19:59:12 tshui Exp $
-------------------------------------------------------------------------------
-- bscan_virtex.vhd - Entity and architecture
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
-- Filename:        bscan_virtex.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              bscan_virtex.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision: 1.1.2.1 $
-- Date:            $Date: 2008/06/26 19:59:12 $
--
-- History:
--   goran  2003-02-13    First Version
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity BSCAN_VIRTEX is
  port (
    UPDATE : out std_logic := '0';
    SHIFT  : out std_logic := '0';
    RESET  : out std_logic := '0';
    TDI    : out std_logic := '0';
    SEL1   : out std_logic := '0';
    DRCK1  : out std_logic := '0';
    SEL2   : out std_logic := '0';
    DRCK2  : out std_logic := '0';
    TDO1   : in  std_logic;
    TDO2   : in  std_logic
    );
end BSCAN_VIRTEX;

architecture Behavioral of BSCAN_VIRTEX is

  type STATE_TYPE is (TLR, IDLE, DRSELECT, DRCAPTURE, DRSHIFT, DREXIT1, DRPAUSE, DREXIT2, DRUPDATE, IRSELECT, IRCAPTURE, IRSHIFT, IREXIT1, IRPAUSE, IREXIT2, IRUPDATE);

  constant USER1 : std_logic_vector(4 downto 0) := "01000";
  constant USER2 : std_logic_vector(4 downto 0) := "11000";

  signal current_state, next_state : STATE_TYPE := IDLE;

  signal IR : std_logic_vector(4 downto 0) := (others => '0');

  signal TDI_EXT : std_logic;
  signal TDO_EXT : std_logic := '0';
  signal TMS_EXT : std_logic;
  signal TCK_EXT : std_logic;

  signal SEL1_I : std_logic := '0';
  signal SEL2_I : std_logic := '0';
  
begin

  TDI <= TDI_EXT;

  process (TCK_EXT)
  begin
    if (TCK_EXT'event and TCK_EXT = '1') then
      current_state <= next_state;
    end if;
  end process;

  process (current_state, TMS_EXT, TCK_EXT, TDO1, TDO2)
  begin
    RESET <= '0';
    UPDATE <= '0';
    case current_state is
      
      when TLR =>
        if (TMS_EXT = '0') then
          next_state <= IDLE;
        else
          next_state <= TLR;
        end if;
        RESET <= '1';
        
      when IDLE =>
        if (TMS_EXT = '0') then
          next_state <= IDLE;
        else
          next_state <= DRSELECT;
        end if;
        
      when DRSELECT =>
        if (TMS_EXT = '0') then
          next_state <= DRCAPTURE;
        else
          next_state <= IRSELECT;
        end if;
        
      when DRCAPTURE =>
        if (TMS_EXT = '0') then
          next_state <= DRSHIFT;
        else
          next_state <= DREXIT1;
        end if;

      when DRSHIFT =>
        if (TMS_EXT = '0') then
          next_state <= DRSHIFT;
        else
          next_state <= DREXIT1;
        end if;

      when DREXIT1 =>
        if (TMS_EXT = '0') then
          next_state <= DRPAUSE;
        else
          next_state <= DRUPDATE;
        end if;

      when DRPAUSE =>
        if (TMS_EXT = '0') then
          next_state <= DRPAUSE;
        else
          next_state <= DREXIT2;
        end if;

      when DREXIT2 =>
        if (TMS_EXT = '0') then
          next_state <= DRSHIFT;
        else
          next_state <= DRUPDATE;
        end if;
        
      when DRUPDATE =>
        UPDATE <= '1';
        if (TMS_EXT = '0') then
          next_state <= IDLE;
        else
          next_state <= DRSELECT;
        end if;

      when IRSELECT =>
        if (TMS_EXT = '0') then
          next_state <= IRCAPTURE;
        else
          next_state <= TLR;
        end if;

      when IRCAPTURE =>
        if (TMS_EXT = '0') then
          next_state <= IRSHIFT;
        else
          next_state <= IREXIT1;
        end if;
        
      when IRSHIFT =>
        if (TMS_EXT = '0') then
          next_state <= IRSHIFT;
        else
          next_state <= IREXIT1;
        end if;
        
      when IREXIT1 =>
        if (TMS_EXT = '0') then
          next_state <= IRPAUSE;
        else
          next_state <= IRUPDATE;
        end if;

      when IRPAUSE =>
        if (TMS_EXT = '0') then
          next_state <= IRPAUSE;
        else
          next_state <= IREXIT2;
        end if;

      when IREXIT2 =>
        if (TMS_EXT = '0') then
          next_state <= IRSHIFT;
        else
          next_state <= IRUPDATE;
        end if;

      when IRUPDATE =>
        if (TMS_EXT = '0') then
          next_state <= IDLE;
        else
          next_state <= DRSELECT;
        end if;
        if (IR = USER1) then
          SEL1_I  <= '1';
          SEL2_I  <= '0';
        end if;
        if (IR = USER2) then
          SEL2_I  <= '1';
          SEL1_I  <= '0';
        else
          SEL1_I  <= '0';
          SEL2_I  <= '0';
        end if;
    end case;
  end process;

  SEL1 <= SEL1_I;
  SEL2 <= SEL2_I;
  
  SHIFT <= '1' when current_state = DRSHIFT else '0';
 
  DRCK1 <= TCK_EXT when (IR=USER1) and (
                        (current_state = DRSHIFT) or (current_state = DRCAPTURE))
           else SEL1_I;
  DRCK2 <= TCK_EXT when (IR=USER2) and (
                        (current_state = DRSHIFT) or (current_state = DRCAPTURE))
           else SEL2_I;
  
  process (TCK_EXT)
  begin
    if (TCK_EXT'event and TCK_EXT = '1') then
      case current_state is

        when DRSHIFT =>
          if (IR = USER1) then
            TDO_EXT <= TDO1;
          end if;
          if (IR = USER2) then
            TDO_EXT <= TDO2;
          end if;

        when IRCAPTURE =>
          IR <= "00001";
          
        when IRSHIFT =>
          TDO_EXT <= IR(4);
          IR      <= IR(3 downto 0) & TDI_EXT;
        when others => null;
      end case;
    end if;
  end process;

end Behavioral;



