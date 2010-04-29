-------------------------------------------------------------------------------
-- $Id: opb_uartlite_rx.vhd,v 1.3 2003/06/29 21:39:50 jcanaris Exp $
-------------------------------------------------------------------------------
-- opb_uartlite_rx.vhd
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
-- Filename:        opb_uartlite_rx.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              opb_uartlite_rx.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision: 1.3 $
-- Date:            $Date: 2003/06/29 21:39:50 $
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

entity OPB_UARTLITE_RX is
  generic (
    C_DATA_BITS  : integer range 5 to 8 := 8;
    C_USE_PARITY : integer              := 1;
    C_ODD_PARITY : integer              := 1
    );
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
    RX_Parity_Error  : out std_logic
    );

end entity OPB_UARTLITE_RX;

library UNISIM;
use UNISIM.all;

--library opb_uartlite_v1_00_b;
--use SRL_FIFO;

architecture IMP of OPB_UARTLITE_RX is

  component SRL16E is
    -- pragma translate_off
    generic (
      INIT : bit_vector := X"0000"
      );
    -- pragma translate_on    
    port (
      CE  : in  std_logic;
      D   : in  std_logic;
      Clk : in  std_logic;
      A0  : in  std_logic;
      A1  : in  std_logic;
      A2  : in  std_logic;
      A3  : in  std_logic;
      Q   : out std_logic);
  end component SRL16E;

  component LUT4
    generic(
      INIT : bit_vector := X"0000"
      );
    port (
      O  : out std_logic;
      I0 : in  std_logic;
      I1 : in  std_logic;
      I2 : in  std_logic;
      I3 : in  std_logic);
  end component;

  component FDRE is
    -- pragma translate_off
    generic (
      INIT : bit);
    -- pragma translate_on
    port (
      Q  : out std_logic;
      C  : in  std_logic;
      CE : in  std_logic;
      D  : in  std_logic;
      R  : in  std_logic);
  end component FDRE;

  component FDSE is
    -- pragma translate_off
    generic (
      INIT : bit);
    -- pragma translate_on
    port (
      Q  : out std_logic;
      C  : in  std_logic;
      CE : in  std_logic;
      D  : in  std_logic;
      S  : in  std_logic);
  end component FDSE;

  component SRL_FIFO is
    generic (
      C_DATA_BITS : integer;
      C_DEPTH     : integer);
    port (
      Clk         : in  std_logic;
      Reset       : in  std_logic;
      FIFO_Write  : in  std_logic;
      Data_In     : in  std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Read   : in  std_logic;
      Data_Out    : out std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Full   : out std_logic;
      Data_Exists : out std_logic);
  end component SRL_FIFO;

  signal previous_RX             : std_logic;
  signal start_Edge_Detected     : boolean;
  signal start_Edge_Detected_Bit : std_logic;
  signal running                 : boolean;
  signal mid_Start_Bit           : std_logic;
  signal recycle                 : std_logic;
  signal sample_Point            : std_logic;
  signal stop_Bit_Position       : std_logic;

  function Calc_Length return integer is
  begin  -- function Calc_Length
    if (C_USE_PARITY = 1) then
      return 1 + C_DATA_BITS;
    else
      return C_DATA_BITS;
    end if;
  end function Calc_Length;

  constant SERIAL_TO_PAR_LENGTH : integer := Calc_Length;
  constant STOP_BIT_POS         : integer := SERIAL_TO_PAR_LENGTH;
  constant DATA_LSB_POS         : integer := SERIAL_TO_PAR_LENGTH;
  constant CALC_PAR_POS         : integer := SERIAL_TO_PAR_LENGTH;

  signal FIFO_Write    : std_logic;
  signal fifo_Din      : std_logic_vector(0 to SERIAL_TO_PAR_LENGTH);
  signal serial_to_Par : std_logic_vector(1 to SERIAL_TO_PAR_LENGTH);

  signal calc_Parity : std_logic;
  signal parity      : std_logic;

  signal rx_Buffer_Full_I : std_logic;

  signal rx_1 : std_logic;
  signal rx_2 : std_logic;
  
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Double sample to avoid meta-stability
  -----------------------------------------------------------------------------
  RX_Sampling: process (Clk, Reset)
  begin  -- process RX_Sampling
    if Reset = '1' then                 -- asynchronous reset (active high)
      rx_1 <= '1';
      rx_2 <= '1';
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      rx_1 <= RX;
      rx_2 <= rx_1;
    end if;
  end process RX_Sampling;

  -----------------------------------------------------------------------------
  -- Detect a falling edge on RX and start a new receiption if idle
  -----------------------------------------------------------------------------
  Prev_RX_DFF : process (Reset, Clk) is
  begin  -- process Prev_RX_DFF
    if (Reset = '1') then
      previous_RX <= '0';
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      if (EN_16x_Baud = '1') then
        previous_RX <= rx_2;
      end if;
    end if;
  end process Prev_RX_DFF;

  Start_Edge_DFF : process (Reset, Clk) is
  begin  -- process Start_Edge_DFF
    if (Reset = '1') then
      start_Edge_Detected <= false;
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      if (EN_16x_Baud = '1') then
        start_Edge_Detected <= not running and
                               (previous_RX = '1') and (rx_2 = '0');
      end if;
    end if;
  end process Start_Edge_DFF;

  -----------------------------------------------------------------------------
  -- Running is '1' during a receiption
  -----------------------------------------------------------------------------
  Running_DFF : process (Clk, Reset) is
  begin  -- process Running_DFF
    if Reset = '1' then                 -- asynchronous reset (active high)
      running <= false;
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      if (EN_16x_Baud = '1') then
        if (start_Edge_Detected) then
          running <= true;
        elsif ((sample_Point = '1') and (stop_Bit_Position = '1')) then
          running <= false;
        end if;
      end if;
    end if;
  end process Running_DFF;

  -----------------------------------------------------------------------------
  -- Delay start_Edge_Detected 7 clocks to get the mid-point in a bit
  -- The address needs to be 6 "0110" to get a delay of 7.
  -----------------------------------------------------------------------------

  start_Edge_Detected_Bit <= '1' when start_Edge_Detected else '0';

  Mid_Start_Bit_SRL16 : SRL16E
    -- pragma translate_off
    generic map (
      INIT => x"0000")
    -- pragma translate_on
    port map (
      CE  => EN_16x_Baud,               -- [in  std_logic]
      D   => start_Edge_Detected_Bit,   -- [in  std_logic]
      Clk => Clk,                       -- [in  std_logic]
      A0  => '0',                       -- [in  std_logic]
      A1  => '1',                       -- [in  std_logic]
      A2  => '1',                       -- [in  std_logic]
      A3  => '0',                       -- [in  std_logic]
      Q   => mid_Start_Bit);            -- [out std_logic]

  -- Keep regenerating new values into the 16 clock delay
  -- Starting with the first mid_Start_Bit and for every new sample_points
  -- until stop_Bit_Position is reached
  recycle <= not (stop_Bit_Position) and (mid_Start_Bit or sample_Point);

  Delay_16 : SRL16E
    -- pragma translate_off
    generic map (
      INIT => x"0000")
    -- pragma translate_on
    port map (
      CE  => EN_16x_Baud,               -- [in  std_logic]
      D   => recycle,                   -- [in  std_logic]
      Clk => Clk,                       -- [in  std_logic]
      A0  => '1',                       -- [in  std_logic]
      A1  => '1',                       -- [in  std_logic]
      A2  => '1',                       -- [in  std_logic]
      A3  => '1',                       -- [in  std_logic]
      Q   => sample_Point);             -- [out std_logic]

  -----------------------------------------------------------------------------
  -- Detect when the stop bit is received
  -----------------------------------------------------------------------------
  Stop_Bit_Handler : process (Clk, Reset) is
  begin  -- process Stop_Bit_Handler
    if Reset = '1' then                 -- asynchronous reset (active high)
      stop_Bit_Position <= '0';
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      if (EN_16x_Baud = '1') then
        if (stop_Bit_Position = '0') then
          -- Start bit has reached the end of the shift register (Stop bit position)
          stop_Bit_Position <= sample_Point and fifo_Din(STOP_BIT_POS);
        elsif (sample_Point = '1') then
          -- if stop_Bit_Position = '1', then clear it at the next sample_Point
          stop_Bit_Position <= '0';
        end if;
      end if;
    end if;
  end process Stop_Bit_Handler;

  -----------------------------------------------------------------------------
  -- Parity handling
  -----------------------------------------------------------------------------
  Using_Parity : if (C_USE_PARITY = 1) generate

    Using_Odd_Parity : if (C_ODD_PARITY = 1) generate
      Parity_Bit : FDSE
        -- pragma translate_off
        generic map (
          INIT => '1')                  -- [bit]
        -- pragma translate_on
        port map (
          Q  => Parity,                 -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => EN_16x_Baud,            -- [in  std_logic]
          D  => calc_Parity,            -- [in  std_logic]
          S  => mid_Start_Bit);         -- [in std_logic]
    end generate Using_Odd_Parity;

    Using_Even_Parity : if (C_ODD_PARITY = 0) generate
      Parity_Bit : FDRE
        -- pragma translate_off
        generic map (
          INIT => '0')                  -- [bit]
        -- pragma translate_on
        port map (
          Q  => Parity,                 -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => EN_16x_Baud,            -- [in  std_logic]
          D  => calc_Parity,            -- [in  std_logic]
          R  => mid_Start_Bit);         -- [in std_logic]      
    end generate Using_Even_Parity;

    calc_Parity <= parity when (stop_Bit_Position or not sample_Point) = '1'
                   else parity xor rx_2;

    RX_Parity_Error <= (EN_16x_Baud and sample_Point) and (fifo_Din(CALC_PAR_POS)) and
                       not stop_Bit_Position
                       when running and (rx_2 /= Parity) else '0';
  end generate Using_Parity;


  -----------------------------------------------------------------------------
  -- Data part
  -----------------------------------------------------------------------------

  fifo_Din(0) <= rx_2;

  Serial_To_Parallel : for I in 1 to serial_to_Par'length generate

    serial_to_Par(I) <= fifo_Din(I) when (stop_Bit_Position or not sample_Point) = '1'
                        else fifo_Din(I-1);
    
    First_Bit : if (I = 1) generate
      First_Bit_I : FDSE
        -- pragma translate_off
        generic map (
          INIT => '0')                  -- [bit]
        -- pragma translate_on
        port map (
          Q  => fifo_Din(I),            -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => EN_16x_Baud,            -- [in  std_logic]
          D  => serial_to_Par(I),       -- [in  std_logic]
          S  => mid_Start_Bit);         -- [in std_logic]
    end generate First_Bit;

    Rest_Bits : if (I /= 1) generate
      Others_I : FDRE
        -- pragma translate_off
        generic map (
          INIT => '0')                  -- [bit]
        -- pragma translate_on
        port map (
          Q  => fifo_Din(I),            -- [out std_logic]
          C  => Clk,                    -- [in  std_logic]
          CE => EN_16x_Baud,            -- [in  std_logic]
          D  => serial_to_Par(I),       -- [in  std_logic]
          R  => mid_Start_Bit);         -- [in std_logic]
    end generate Rest_Bits;

  end generate Serial_To_Parallel;

  -----------------------------------------------------------------------------
  -- Write in the received word when the stop_bit has been received and it is a
  -- '1'
  -----------------------------------------------------------------------------
  FIFO_Write_DFF : process (Clk, Reset) is
  begin  -- process FIFO_Write_DFF
    if Reset = '1' then                 -- asynchronous reset (active high)
      FIFO_Write <= '0';
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      fifo_Write <= stop_Bit_Position and rx_2 and sample_Point and EN_16x_Baud;
    end if;
  end process FIFO_Write_DFF;

  RX_Frame_Error <= stop_Bit_Position and sample_Point and EN_16x_Baud and not rx_2;

  SRL_FIFO_I : SRL_FIFO
    generic map (
      C_DATA_BITS => C_DATA_BITS,       -- [integer]
      C_DEPTH     => 16)                -- [integer]
    port map (
      Clk         => Clk,               -- [in  std_logic]
      Reset       => Reset_RX_FIFO,     -- [in  std_logic]
      FIFO_Write  => fifo_Write,        -- [in  std_logic]
      Data_In     => fifo_Din(DATA_LSB_POS - C_DATA_BITS + 1 to DATA_LSB_POS),  -- [in  std_logic_vector(0 to C_DATA_BITS-1)]
      FIFO_Read   => Read_RX_FIFO,      -- [in  std_logic]
      Data_Out    => RX_Data,  -- [out std_logic_vector(0 to C_DATA_BITS-1)]
      FIFO_Full   => rx_Buffer_Full_I,  -- [out std_logic]
      Data_Exists => RX_Data_Present);  -- [out std_logic]

  RX_Overrun_Error <= rx_Buffer_Full_I and fifo_write;
  RX_Buffer_Full   <= rx_Buffer_Full_I;
  
end architecture IMP;

