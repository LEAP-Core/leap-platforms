-------------------------------------------------------------------------------
-- $Id: mdm.vhd,v 1.1.2.2 2008/07/30 00:33:55 jece Exp $
-------------------------------------------------------------------------------
-- mdm.vhd - Entity and architecture
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
-- Filename:        mdm.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              mdm.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision: 1.1.2.2 $
-- Date:            $Date: 2008/07/30 00:33:55 $
--
-- History:
--   goran  2006-10-27    First Version
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

library unisim;
use unisim.vcomponents.all;

entity MDM is
  generic (
    C_FAMILY              : string                    := "virtex2";
    C_JTAG_CHAIN          : integer                   := 2;
    C_INTERCONNECT        : integer                   := 0;
    C_BASEADDR            : std_logic_vector(0 to 31) := X"FFFF_8000";
    C_HIGHADDR            : std_logic_vector(0 to 31) := X"FFFF_80FF";
    C_SPLB_AWIDTH         : integer                   := 32;
    C_SPLB_DWIDTH         : integer                   := 32;
    C_SPLB_P2P            : integer                   := 0;
    C_SPLB_MID_WIDTH      : integer                   := 3;
    C_SPLB_NUM_MASTERS    : integer                   := 8;
    C_SPLB_NATIVE_DWIDTH  : integer                   := 32;
    C_SPLB_SUPPORT_BURSTS : integer                   := 0;
    C_OPB_DWIDTH          : integer                   := 32;
    C_OPB_AWIDTH          : integer                   := 32;
    C_MB_DBG_PORTS        : integer                   := 0;
    C_USE_UART            : integer                   := 1;
    C_UART_WIDTH          : integer                   := 8;
    C_WRITE_FSL_PORTS     : integer                   := 0

  );
  port (
    Clk : in std_logic;
    Rst : in std_logic;

    Read_RX_FIFO    : in  std_logic;
    Reset_RX_FIFO   : in  std_logic;
    RX_Data         : out std_logic_vector(0 to C_UART_WIDTH-1);
    RX_Data_Present : out std_logic;
    --RX_BUFFER_FULL  : out std_logic;
    
    Write_TX_FIFO   : in  std_logic;
    Reset_TX_FIFO   : in  std_logic;
    TX_Data         : in  std_logic_vector(0 to C_UART_WIDTH-1);
    --TX_Buffer_Full  : out std_logic;
    TX_Buffer_Empty : out std_logic
        
  );

end entity MDM;

architecture IMP of MDM is

  constant C_FSL_DATA_SIZE : integer := 32;

  component BSCAN
      port (
        TDO     : in  std_logic;
        UPDATE  : out std_logic;
        SHIFT   : out std_logic;
        RESET   : out std_logic;
        TDI     : out std_logic;
        SEL     : out std_logic;
        DRCK    : out std_logic;
        CAPTURE : out std_logic
        );
  end component BSCAN;

  component MDM_Core
    generic (
      C_INTERCONNECT        : integer := 0;
      C_SPLB_AWIDTH         : integer := 32;
      C_SPLB_DWIDTH         : integer := 32;
      C_SPLB_P2P            : integer := 0;
      C_SPLB_MID_WIDTH      : integer := 3;
      C_SPLB_NUM_MASTERS    : integer := 8;
      C_SPLB_NATIVE_DWIDTH  : integer := 32;
      C_SPLB_SUPPORT_BURSTS : integer := 0;
      C_MB_DBG_PORTS        : integer := 0;
      C_USE_UART            : integer := 1;
      C_UART_WIDTH          : integer := 8;
      C_USE_FSL             : integer := 0;
      C_FSL_DATA_SIZE       : integer);
    port (
      -- Global signals
      Clk             : in std_logic;
      Rst             : in std_logic;

      Ext_BRK       : out std_logic;
      Ext_NM_BRK    : out std_logic;
      Debug_SYS_Rst : out std_logic;
--      Debug_Rst     : out std_logic;

      Read_RX_FIFO    : in  std_logic;
      Reset_RX_FIFO   : in  std_logic;
      RX_Data         : out std_logic_vector(0 to 7);
      RX_Data_Present : out std_logic;
--      RX_BUFFER_FULL  : out std_logic;

      Write_TX_FIFO   : in  std_logic;
      Reset_TX_FIFO   : in  std_logic;
      TX_Data         : in  std_logic_vector(0 to 7);
--      TX_Buffer_Full  : out std_logic;
      TX_Buffer_Empty : out std_logic;

      -- MDM signals
      TDI     : in  std_logic;
      RESET   : in  std_logic;
      UPDATE  : in  std_logic;
      SHIFT   : in  std_logic;
      CAPTURE : in  std_logic;
      SEL     : in  std_logic;
      DRCK    : in  std_logic;
      TDO     : out std_logic;

      -- MicroBlaze Debug Signals
      Dbg_Clk_0     : out std_logic;
      Dbg_TDI_0     : out std_logic;
      Dbg_TDO_0     : in  std_logic;
      Dbg_Reg_En_0  : out std_logic_vector(0 to 4);
      Dbg_Capture_0 : out std_logic;
      Dbg_Shift_0   : out std_logic;
      Dbg_Update_0  : out std_logic;
      Dbg_Rst_0     : out std_logic;

      Dbg_Clk_1     : out std_logic;
      Dbg_TDI_1     : out std_logic;
      Dbg_TDO_1     : in  std_logic;
      Dbg_Reg_En_1  : out std_logic_vector(0 to 4);
      Dbg_Capture_1 : out std_logic;
      Dbg_Shift_1   : out std_logic;
      Dbg_Update_1  : out std_logic;
      Dbg_Rst_1     : out std_logic;

      Dbg_Clk_2     : out std_logic;
      Dbg_TDI_2     : out std_logic;
      Dbg_TDO_2     : in  std_logic;
      Dbg_Reg_En_2  : out std_logic_vector(0 to 4);
      Dbg_Capture_2 : out std_logic;
      Dbg_Shift_2   : out std_logic;
      Dbg_Update_2  : out std_logic;
      Dbg_Rst_2     : out std_logic;

           Dbg_Clk_3     : out std_logic;
      Dbg_TDI_3     : out std_logic;
      Dbg_TDO_3     : in  std_logic;
      Dbg_Reg_En_3  : out std_logic_vector(0 to 4);
      Dbg_Capture_3 : out std_logic;
      Dbg_Shift_3   : out std_logic;
      Dbg_Update_3  : out std_logic;
      Dbg_Rst_3     : out std_logic;

      Dbg_Clk_4     : out std_logic;
      Dbg_TDI_4     : out std_logic;
      Dbg_TDO_4     : in  std_logic;
      Dbg_Reg_En_4  : out std_logic_vector(0 to 4);
      Dbg_Capture_4 : out std_logic;
      Dbg_Shift_4   : out std_logic;
      Dbg_Update_4  : out std_logic;
      Dbg_Rst_4     : out std_logic;

      Dbg_Clk_5     : out std_logic;
      Dbg_TDI_5     : out std_logic;
      Dbg_TDO_5     : in  std_logic;
      Dbg_Reg_En_5  : out std_logic_vector(0 to 4);
      Dbg_Capture_5 : out std_logic;
      Dbg_Shift_5   : out std_logic;
      Dbg_Update_5  : out std_logic;
      Dbg_Rst_5     : out std_logic;

      Dbg_Clk_6     : out std_logic;
      Dbg_TDI_6     : out std_logic;
      Dbg_TDO_6     : in  std_logic;
      Dbg_Reg_En_6  : out std_logic_vector(0 to 4);
      Dbg_Capture_6 : out std_logic;
      Dbg_Shift_6   : out std_logic;
      Dbg_Update_6  : out std_logic;
      Dbg_Rst_6     : out std_logic;

      Dbg_Clk_7     : out std_logic;
      Dbg_TDI_7     : out std_logic;
      Dbg_TDO_7     : in  std_logic;
      Dbg_Reg_En_7  : out std_logic_vector(0 to 4);
      Dbg_Capture_7 : out std_logic;
      Dbg_Shift_7   : out std_logic;
      Dbg_Update_7  : out std_logic;
      Dbg_Rst_7     : out std_logic;

      FSL0_S_Clk     : out std_logic;
      FSL0_S_Read    : out std_logic;
      FSL0_S_Data    : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL0_S_Control : in  std_logic;
      FSL0_S_Exists  : in  std_logic;
      FSL0_M_Clk     : out std_logic;
      FSL0_M_Write   : out std_logic;
      FSL0_M_Data    : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL0_M_Control : out std_logic;
      FSL0_M_Full    : in  std_logic;

      Ext_JTAG_DRCK    : out std_logic;
      Ext_JTAG_RESET   : out std_logic;
      Ext_JTAG_SEL     : out std_logic;
      Ext_JTAG_CAPTURE : out std_logic;
      Ext_JTAG_SHIFT   : out std_logic;
      Ext_JTAG_UPDATE  : out std_logic;
      Ext_JTAG_TDI     : out std_logic;
      Ext_JTAG_TDO     : in  std_logic
      
    );
  end component MDM_Core;

  -- MDM signals
  signal tdi     : std_logic;
  signal reset   : std_logic;
  signal update  : std_logic;
  signal capture : std_logic;
  signal shift   : std_logic;
  signal sel     : std_logic;
  signal drck    : std_logic;
  signal tdo     : std_logic;

  signal tdo1  : std_logic;
  signal sel1  : std_logic;
  signal drck1 : std_logic;

  signal drck_i   : std_logic;
  signal drck1_i  : std_logic;
  signal update_i : std_logic;

  signal read_RX_FIFO_i      : std_logic;
  signal reset_RX_FIFO_i     : std_logic;
  signal RstInv : std_logic;
  
  signal rx_Data_i         : std_logic_vector(0 to 7);
  signal rx_Data_Present_i : std_logic;
  signal rx_BUFFER_FULL_i  : std_logic;

  signal tx_Data_i         : std_logic_vector(0 to 7);
  signal write_TX_FIFO_i   : std_logic;
  signal reset_TX_FIFO_i   : std_logic;
  signal tx_BUFFER_FULL_i  : std_logic;
  signal tx_Buffer_Empty_i : std_logic;

  signal gnd : std_logic;
  
begin  -- architecture IMP
  RstInv <= not Rst;
  gnd <= '0';
  read_RX_FIFO_i <= Read_RX_FIFO;
  reset_RX_FIFO_i <= Reset_RX_FIFO; 
  RX_Data         <= rx_Data_i;
  RX_Data_Present <= rx_Data_Present_i; 
  --RX_BUFFER_FULL <= rx_BUFFER_FULL_i;
  
  write_TX_FIFO_i <= Write_TX_FIFO;
  reset_TX_FIFO_i <= Reset_TX_FIFO;
  tx_Data_i <= TX_Data;
  --TX_Buffer_Full  <= tx_Buffer_Full_i;
  TX_Buffer_Empty <= tx_Buffer_Empty_i;
  
  BSCAN_VIRTEX5_I : BSCAN
      port map (
        TDO     => tdo,                 -- [in  std_logic]
        UPDATE  => update_i,            -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        SEL     => sel,                 -- [out std_logic]
        DRCK    => drck_i,              -- [out std_logic]
        CAPTURE => capture);            -- [out std_logic]

--  drck1 <= drck1_i;
  
  BUFG_DRCK : BUFG
    port map (
      O => drck,
      I => drck_i
    );

  update <= update_i;



    MDM_CORE_I: MDM_Core    
      generic map (
        C_MB_DBG_PORTS  => C_MB_DBG_PORTS,
        C_USE_UART      => C_USE_UART,
        C_UART_WIDTH    => C_UART_WIDTH,
        C_FSL_DATA_SIZE => C_FSL_DATA_SIZE  -- [integer]
      )
      port map (
        -- Global signals
        Clk             => Clk,         -- [in  std_logic]
        Rst             => RstInv,         -- [in  std_logic] BSV is negative edge


        --Clear_Ext_BRK => '0',  -- [in  std_logic]
        Ext_BRK       => open,        -- [out std_logic]
        Ext_NM_BRK    => open,     -- [out std_logic]
        Debug_SYS_Rst => open,  -- [out std_logic]
        --Debug_Rst     => open,    -- [out std_logic]

        Read_RX_FIFO    => read_RX_FIFO_i,     -- [in  std_logic]
        Reset_RX_FIFO   => reset_RX_FIFO_i,    -- [in  std_logic]
        RX_Data         => rx_Data_i,          -- [out std_logic_vector(0 to 7)]
        RX_Data_Present => rx_Data_Present_i,  -- [out std_logic]
        --RX_BUFFER_FULL  => rx_BUFFER_FULL_i,   -- [out std_logic]

        Write_TX_FIFO   => write_TX_FIFO_i,  -- [in  std_logic]
        Reset_TX_FIFO   => reset_TX_FIFO_i,  -- [in  std_logic]
        TX_Data         => tx_Data_i,  -- [in  std_logic_vector(0 to 7)]
        --TX_Buffer_Full  => tx_Buffer_Full_i,  -- [out std_logic]
        TX_Buffer_Empty => tx_Buffer_Empty_i,  -- [out std_logic]

              -- JTAG signals
        TDI     => tdi,                   -- [in  std_logic]
        RESET   => reset,                 -- [in  std_logic]
        UPDATE  => update,                -- [in  std_logic]
        SHIFT   => shift,                 -- [in  std_logic]
        CAPTURE => capture,               -- [in  std_logic]
        SEL     => sel,                   -- [in  std_logic]
        DRCK    => drck,                  -- [in  std_logic]
        TDO     => tdo,                   -- [out std_logic]

        -- MicroBlaze Debug Signals
        Dbg_TDO_0 => gnd,
        Dbg_TDO_1 => gnd,
        Dbg_TDO_2 => gnd,
        Dbg_TDO_3 => gnd,
        Dbg_TDO_4 => gnd,
        Dbg_TDO_5 => gnd,
        Dbg_TDO_6 => gnd,
        Dbg_TDO_7 => gnd,
        
        FSL0_S_Clk     => open,
        FSL0_S_Read    => open,
--        FSL0_S_Data    => '0000000000000000',
        FSL0_S_Control => '0',
        FSL0_S_Exists  => '0',
        FSL0_M_Clk     => open,
        FSL0_M_Write   => open,
        FSL0_M_Data    => open,
        FSL0_M_Control => open,
        FSL0_M_Full    => '0',

        Ext_JTAG_TDO => gnd
      );        

end architecture IMP;



