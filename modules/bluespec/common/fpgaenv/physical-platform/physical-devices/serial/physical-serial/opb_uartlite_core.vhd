-------------------------------------------------------------------------------
-- $Id: opb_uartlite_core.vhd,v 1.3 2003/08/04 17:20:53 goran Exp $
-------------------------------------------------------------------------------
-- opb_uartlite.vhd
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
-- Filename:        opb_uartlite.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              opb_uartlite.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision: 1.3 $
-- Date:            $Date: 2003/08/04 17:20:53 $
--
-- History:
--   goran  2001-05-11    First Version
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

entity OPB_UARTLITE_Core is
  generic (
    C_DATA_BITS  : integer range 5 to 8 := 8;
    C_CLK_FREQ   : integer              := 100_000_000;
    C_BAUDRATE   : integer              := 115200;
    C_USE_PARITY : integer              := 1;
    C_ODD_PARITY : integer              := 1
    );
  port (
    Clk   : in std_logic;
    Reset : in std_logic;

    --RX signals
      RX               : in  std_logic;
      Read_RX_FIFO     : in  std_logic;
      Reset_RX_FIFO    : in  std_logic;
      RX_Data          : out std_logic_vector(0 to C_DATA_BITS-1);
      RX_Data_Present  : out std_logic;
    --RX_BUFFER_FULL   : out std_logic;
    --RX_Frame_Error   : out std_logic;
    --RX_Overrun_Error : out std_logic;
    --RX_Parity_Error  : out std_logic;
    
    --TX signals
      TX              : out std_logic;
      Write_TX_FIFO   : in  std_logic;
      Reset_TX_FIFO   : in  std_logic;
      TX_Data         : in  std_logic_vector(0 to C_DATA_BITS-1);
    --TX_Buffer_Full  : out std_logic;
      TX_Buffer_Empty : out std_logic;    

    -- UART signals
    CTS       : in  std_logic;
    RTS       : out std_logic;
    DTR       : out std_logic;
   

    --Dummy enables
    dummy_enable_rx: in std_logic;
    dummy_enable_rts: in std_logic
    
    );

end entity OPB_UARTLITE_Core;

library unisim;
use unisim.all;



architecture IMP of OPB_UARTLITE_Core is

  component Baud_Rate is
    generic (
      C_RATIO      : integer;           -- The ratio between clk and the asked
                                        -- baudrate multiplied with 16
      C_INACCURACY : integer);          -- The maximum inaccuracy of the clk
    port (
      Clk         : in  std_logic;
      EN_16x_Baud : out std_logic);
  end component Baud_Rate;

  component OPB_UARTLITE_RX is
    generic (
      C_DATA_BITS  : integer range 5 to 8;
      C_USE_PARITY : integer;
      C_ODD_PARITY : integer);
    port (
      Clk         : in std_logic;
      Reset       : in std_logic;
      EN_16x_Baud : in std_logic;

      RX               : in  std_logic;
      Read_RX_FIFO     : in  std_logic;
      Reset_RX_FIFO    : in  std_logic;
      RX_Data          : out std_logic_vector(0 to C_DATA_BITS-1);
      RX_Data_Present  : out std_logic;
      RX_BUFFER_FULL   : out std_logic;
      RX_Frame_Error   : out std_logic;
      RX_Overrun_Error : out std_logic;
      RX_Parity_Error  : out std_logic);
  end component OPB_UARTLITE_RX;

  component OPB_UARTLITE_TX is
    generic (
      C_DATA_BITS  : integer range 5 to 8;
      C_USE_PARITY : integer;
      C_ODD_PARITY : integer);
    port (
      Clk         : in std_logic;
      Reset       : in std_logic;
      EN_16x_Baud : in std_logic;

      TX              : out std_logic;
      Write_TX_FIFO   : in  std_logic;
      Reset_TX_FIFO   : in  std_logic;
      TX_Data         : in  std_logic_vector(0 to C_DATA_BITS-1);
      TX_Buffer_Full  : out std_logic;
      TX_Buffer_Empty : out std_logic);
  end component OPB_UARTLITE_TX;

  component FDRE is
    port (
      Q  : out std_logic;
      C  : in  std_logic;
      CE : in  std_logic;
      D  : in  std_logic;
      R  : in  std_logic);
  end component FDRE;

  component FDR is
    port (Q : out std_logic;
          C : in  std_logic;
          D : in  std_logic;
          R : in  std_logic);
  end component FDR;

  signal en_16x_Baud : std_logic;

  constant RX_FIFO_ADR    : std_logic_vector(0 to 1) := "00";
  constant TX_FIFO_ADR    : std_logic_vector(0 to 1) := "01";
  constant STATUS_REG_ADR : std_logic_vector(0 to 1) := "10";
  constant CTRL_REG_ADR   : std_logic_vector(0 to 1) := "11";

  -- Read Only
  signal status_Reg : std_logic_vector(0 to 7);
  -- bit 7 rx_Data_Present
  -- bit 6 rx_Buffer_Full
  -- bit 5 tx_Buffer_Empty
  -- bit 4 tx_Buffer_Full
  -- bit 3 enable_interrupts
  -- bit 2 Overrun Error
  -- bit 1 Frame Error
  -- bit 0 Parity Error (If C_USE_PARITY is true, otherwise '0')

  -- Write Only
  -- Control Register
  -- bit 0-2 Dont'Care
  -- bit 3   enable_interrupts
  -- bit 4-5 Dont'Care
  -- bit 6   Reset_RX_FIFO
  -- bit 7   Reset_TX_FIFO

  signal TxBufferEmpty : std_logic;
  signal RxDataPresent : std_logic;

  signal RX_BUFFER_FULL   : std_logic;
  signal RX_Frame_Error   : std_logic;
  signal RX_Overrun_Error : std_logic;
  signal RX_Parity_Error  : std_logic;
  signal TX_Buffer_Full   : std_logic;

  
  constant RATIO : integer := C_CLK_FREQ / (16 * C_BAUDRATE);

begin  -- architecture IMP

  TX_Buffer_Empty <= TxBufferEmpty and not(CTS);
  RTS <= RxDataPresent;
  RX_Data_Present <= RxDataPresent;
  DTR <= not(Reset);                     
  -----------------------------------------------------------------------------
  -- Instanciating the BaudRate module
  -----------------------------------------------------------------------------
  Baud_Rate_I : Baud_Rate
    generic map (
      C_RATIO      => RATIO,            -- [integer]
      C_INACCURACY => 20)               -- [integer]
    port map (
      Clk         => Clk,               -- [in  std_logic]
      EN_16x_Baud => en_16x_Baud);      -- [out std_logic]

  -----------------------------------------------------------------------------
  -- Instanciating the receive and transmit modules
  -----------------------------------------------------------------------------
  OPB_UARTLITE_RX_I : OPB_UARTLITE_RX
    generic map (
      C_DATA_BITS  => C_DATA_BITS,      -- [integer range 5 to 8]
      C_USE_PARITY => C_USE_PARITY,     -- [integer]
      C_ODD_PARITY => C_ODD_PARITY)     -- [integer]
    port map (
      Clk              => Clk,          -- [in  std_logic]
      Reset            => not Reset,        -- [in  std_logic]
      EN_16x_Baud      => en_16x_Baud,  -- [in  std_logic]
      RX               => RX,           -- [in  std_logic]
      Read_RX_FIFO     => Read_RX_FIFO,      -- [in  std_logic]
      Reset_RX_FIFO    => Reset_RX_FIFO,     -- [in  std_logic]
      RX_Data          => RX_Data,  -- [out std_logic_vector(0 to C_DATA_BITS-1)]
      RX_Data_Present  => RxDataPresent,   -- [out std_logic]
      RX_BUFFER_FULL   => RX_BUFFER_FULL,    -- [out std_logic]
      RX_Frame_Error   => RX_Frame_Error,    -- [out std_logic]
      RX_Overrun_Error => RX_Overrun_Error,  -- [out std_logic]
      RX_Parity_Error  => RX_Parity_Error);  -- [out std_logic]

  OPB_UARTLITE_TX_I : OPB_UARTLITE_TX
    generic map (
      C_DATA_BITS  => C_DATA_BITS,      -- [integer range 5 to 8]
      C_USE_PARITY => C_USE_PARITY,     -- [integer]
      C_ODD_PARITY => C_ODD_PARITY)     -- [integer]
    port map (
      Clk             => Clk,           -- [in  std_logic]
      Reset           => not Reset,         -- [in  std_logic]
      EN_16x_Baud     => en_16x_Baud,   -- [in  std_logic]
      TX              => TX,            -- [out std_logic]
      Write_TX_FIFO   => Write_TX_FIFO,                 -- [in  std_logic]
      Reset_TX_FIFO   => Reset_TX_FIFO,                 -- [in  std_logic]
      TX_Data         => TX_Data,  -- [in  std_logic_vector(0 to C_DATA_BITS-1)]
      TX_Buffer_Full  => TX_Buffer_Full,                -- [out std_logic]
      TX_Buffer_Empty => TxBufferEmpty);              -- [out std_logic]

end architecture IMP;



