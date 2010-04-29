-------------------------------------------------------------------------------
-- $Id: opb_uartlite_tx.vhd,v 1.3 2003/06/29 21:40:14 jcanaris Exp $
-------------------------------------------------------------------------------
-- opb_uartlite_tx.vhd
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
-- Filename:        opb_uartlite_tx.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              opb_uartlite_tx.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision: 1.3 $
-- Date:            $Date: 2003/06/29 21:40:14 $
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

entity OPB_UARTLITE_TX is
  generic (
    C_DATA_BITS  : integer range 5 to 8 := 8;
    C_USE_PARITY : integer              := 1;
    C_ODD_PARITY : integer              := 1
    );
  port (
    Clk         : in std_logic;
    Reset       : in std_logic;
    EN_16x_Baud : in std_logic;

    TX              : out std_logic;
    Write_TX_FIFO   : in  std_logic;
    Reset_TX_FIFO   : in  std_logic;
    TX_Data         : in  std_logic_vector(0 to C_DATA_BITS-1);
    TX_Buffer_Full  : out std_logic;
    TX_Buffer_Empty : out std_logic
    );

end entity OPB_UARTLITE_TX;

library ieee;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.all;


architecture IMP of OPB_UARTLITE_TX is

  component SRL16E is
    -- pragma translate_off
    generic (
      INIT : bit_vector := X"0000");
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

  component MUXCY_L
    port (
      DI : in  std_logic;
      CI : in  std_logic;
      S  : in  std_logic;
      LO : out std_logic);
  end component;

  component XORCY
    port (
      LI : in  std_logic;
      CI : in  std_logic;
      O  : out std_logic);
  end component;

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

  component MUXF5
    port (
      O  : out std_logic;
      I0 : in  std_logic;
      I1 : in  std_logic;
      S  : in  std_logic);
  end component;

  component MUXF6
    port (
      O  : out std_logic;
      I0 : in  std_logic;
      I1 : in  std_logic;
      S  : in  std_logic);
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

  -- signals for parity
  signal parity           : std_logic;
  signal calc_Parity      : std_logic;
  signal tx_Run1          : std_logic;
  signal select_Parity    : std_logic;
  signal data_to_transfer : std_logic_vector(0 to C_DATA_BITS-1);

  signal div16          : std_logic;
  signal tx_Data_Enable : std_logic;
  signal tx_Start       : std_logic;
  signal tx_DataBits    : std_logic;
  signal tx_Run         : std_logic;

  signal cnt_cy          : std_logic_vector(0 to 3);
  signal h_Cnt           : std_logic_vector(0 to 2);
  signal sum_cnt         : std_logic_vector(0 to 2);
  signal mux_sel         : std_logic_vector(0 to 2);
  signal mux_sel_is_zero : std_logic;

  constant mux_sel_init : std_logic_vector(0 to 2) :=
    std_logic_vector(to_unsigned(C_DATA_BITS-1, 3));

  signal mux_01      : std_logic;
  signal mux_23      : std_logic;
  signal mux_45      : std_logic;
  signal mux_67      : std_logic;
  signal mux_0123    : std_logic;
  signal mux_4567    : std_logic;
  signal mux_Out     : std_logic;
  signal serial_Data : std_logic;

  signal fifo_Read         : std_logic;
  signal fifo_Data_Present : std_logic;
  signal fifo_DOut         : std_logic_vector(0 to C_DATA_BITS-1);

  attribute INIT                 : string;
  attribute INIT of DIV16_SRL16E : label is "0001";
  
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Divide the EN_16x_Baud by 16 to get the correct baudrate
  -----------------------------------------------------------------------------
  DIV16_SRL16E : SRL16E
    -- pragma translate_off    
    generic map (
      INIT => X"0001")
    -- pragma translate_on    
    port map (
      CE  => EN_16x_Baud,               -- [in  std_logic]
      D   => div16,                     -- [in  std_logic]
      Clk => Clk,                       -- [in  std_logic]
      A0  => '1',                       -- [in  std_logic]
      A1  => '1',                       -- [in  std_logic]
      A2  => '1',                       -- [in  std_logic]
      A3  => '1',                       -- [in  std_logic]
      Q   => div16);                    -- [out std_logic]

  FDRE_I : FDRE
    -- pragma translate_off
    generic map (
      INIT => '0')                      -- [bit]
    -- pragma translate_on
    port map (
      Q  => tx_Data_Enable,             -- [out std_logic]
      C  => Clk,                        -- [in  std_logic]
      CE => EN_16x_Baud,                -- [in  std_logic]
      D  => div16,                      -- [in  std_logic]
      R  => tx_Data_Enable);            -- [in std_logic]


  -----------------------------------------------------------------------------
  -- tx_start is '1' for the start bit in a transmission
  -----------------------------------------------------------------------------
  TX_Start_DFF : process (Clk, Reset) is
  begin  -- process TX_Start_DFF
    if Reset = '1' then                 -- asynchronous reset (active high)
      tx_Start <= '0';
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      tx_Start <= not(tx_Run) and (tx_Start or (fifo_Data_Present and tx_Data_Enable));
    end if;
  end process TX_Start_DFF;

  -----------------------------------------------------------------------------
  -- tx_DataBits is '1' during all databits transmission
  -----------------------------------------------------------------------------
  TX_Data_DFF : process (Clk, Reset) is
  begin  -- process TX_Data_DFF
    if Reset = '1' then                 -- asynchronous reset (active high)
      tx_DataBits <= '0';
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      tx_DataBits <= not(fifo_Read) and (tx_DataBits or (tx_Start and tx_Data_Enable));
    end if;
  end process TX_Data_DFF;

  -- only decrement during data bits transfer
  cnt_cy(3) <= not tx_DataBits;

  Counter : for I in 2 downto 0 generate

    ---------------------------------------------------------------------------
    -- If mux_sel is zero then reload with the init value
    -- else decrement
    ---------------------------------------------------------------------------
    h_Cnt(I) <= mux_sel_init(I) when mux_sel_is_zero = '1' else not mux_sel(I);

    -- Don't need the last muxcy, cnt_cy(0) is not used anywhere
    Used_MuxCY: if I> 0 generate      
      MUXCY_L_I : MUXCY_L
        port map (
          DI => mux_sel(I),               -- [in  std_logic]
          CI => cnt_cy(I+1),              -- [in  std_logic]
          S  => h_cnt(I),                 -- [in  std_logic]
          LO => cnt_cy(I));               -- [out std_logic]
    end generate Used_MuxCY;

    XORCY_I : XORCY
      port map (
        LI => h_cnt(I),                 -- [in  std_logic]
        CI => cnt_cy(I+1),              -- [in  std_logic]
        O  => sum_cnt(I));              -- [out std_logic]
  end generate Counter;

  Mux_Addr_DFF : process (Clk, Reset) is
  begin  -- process Mux_Addr_DFF
    if Reset = '1' then                 -- asynchronous reset (active high)
      mux_sel <= std_logic_vector(to_unsigned(C_DATA_BITS-1, mux_sel'length));
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      if (tx_Data_Enable = '1') then
        mux_sel <= sum_cnt;
      end if;
    end if;
  end process Mux_Addr_DFF;

  -- Detecting when mux_sel is zero ie. all data bits is transfered
  mux_sel_is_zero <= '1' when mux_sel = "000" else '0';

  -- Read out the next data from the transmit fifo when the data has been
  -- transmitted 
  FIFO_Read_DFF : process (Clk, Reset) is
  begin  -- process FIFO_Read_DFF
    if Reset = '1' then                 -- asynchronous reset (active high)
      fifo_Read <= '0';
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      fifo_Read <= tx_Data_Enable and mux_sel_is_zero;
    end if;
  end process FIFO_Read_DFF;

  -----------------------------------------------------------------------------
  -- Select which bit within the data word to transmit
  -----------------------------------------------------------------------------

  -- Need special treatment for inserting the parity bit because of parity generation
  Parity_Bit_Insertion : process (parity, select_Parity, fifo_DOut) is
  begin  -- process Parity_Bit_Insertion
    data_to_transfer <= fifo_DOut;
    if (select_Parity = '1') then
      data_to_transfer(C_DATA_BITS-1) <= parity;
    end if;
  end process Parity_Bit_Insertion;

  mux_01 <= data_to_transfer(1) when mux_sel(2) = '1' else data_to_transfer(0);
  mux_23 <= data_to_transfer(3) when mux_sel(2) = '1' else data_to_transfer(2);

  Data_Bits_Is_5 : if (C_DATA_BITS = 5) generate
    mux_45 <= data_to_transfer(4);
    mux_67 <= '0';
  end generate Data_Bits_Is_5;

  Data_Bits_Is_6 : if (C_DATA_BITS = 6) generate
    mux_45 <= data_to_transfer(5) when mux_sel(2) = '1' else data_to_transfer(4);
    mux_67 <= '0';
  end generate Data_Bits_Is_6;

  Data_Bits_Is_7 : if (C_DATA_BITS = 7) generate
    mux_45 <= data_to_transfer(5) when mux_sel(2) = '1' else data_to_transfer(4);
    mux_67 <= data_to_transfer(6);
  end generate Data_Bits_Is_7;

  Data_Bits_Is_8 : if (C_DATA_BITS = 8) generate
    mux_45 <= data_to_transfer(5) when mux_sel(2) = '1' else data_to_transfer(4);
    mux_67 <= data_to_transfer(7) when mux_sel(2) = '1' else data_to_transfer(6);
  end generate Data_Bits_Is_8;

  MUX_F5_1 : MUXF5
    port map (
      O  => mux_0123,                   -- [out std_logic]
      I0 => mux_01,                     -- [in  std_logic]
      I1 => mux_23,                     -- [in  std_logic]
      S  => mux_sel(1));                -- [in std_logic]

  MUX_F5_2 : MUXF5
    port map (
      O  => mux_4567,                   -- [out std_logic]
      I0 => mux_45,                     -- [in  std_logic]
      I1 => mux_67,                     -- [in  std_logic]
      S  => mux_sel(1));                -- [in std_logic]

  MUXF6_I : MUXF6
    port map (
      O  => mux_out,                    -- [out std_logic]
      I0 => mux_0123,                   -- [in  std_logic]
      I1 => mux_4567,                   -- [in  std_logic]
      S  => mux_sel(0));                -- [in std_logic]

  Serial_Data_DFF : process (Clk, Reset) is
  begin  -- process Serial_Data_DFF
    if Reset = '1' then                 -- asynchronous reset (active high)
      serial_Data <= '0';
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      serial_Data <= mux_Out;
    end if;
  end process Serial_Data_DFF;

  -----------------------------------------------------------------------------
  -- Force a '0' when tx_start is '1', Start_bit
  -- Force a '1' when tx_run is '0',   Idle
  -- otherwise put out the serial_data
  -----------------------------------------------------------------------------
  Serial_Out_DFF : process (Clk, Reset) is
  begin  -- process Serial_Out_DFF
    if Reset = '1' then                 -- asynchronous reset (active high)
      TX <= '1';
    elsif Clk'event and Clk = '1' then  -- rising clock edge
      TX <= (not(tx_run) or serial_Data) and not(tx_Start);
    end if;
  end process Serial_Out_DFF;

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
          CE => tx_Data_Enable,         -- [in  std_logic]
          D  => calc_Parity,            -- [in  std_logic]
          S  => tx_Start);              -- [in std_logic]
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
          CE => tx_Data_Enable,         -- [in  std_logic]
          D  => calc_Parity,            -- [in  std_logic]
          R  => tx_Start);              -- [in std_logic]      
    end generate Using_Even_Parity;

    calc_Parity <= parity xor serial_data;

    tx_Run_DFF : process (Clk, Reset) is
    begin  -- process tx_Run_DFF
      if Reset = '1' then                 -- asynchronous reset (active high)
        tx_Run1 <= '0';
      elsif Clk'event and Clk = '1' then  -- rising clock edge
        if (tx_Data_Enable = '1') then
          tx_Run1 <= tx_DataBits;
        end if;
      end if;
    end process tx_Run_DFF;

    tx_Run <= tx_Run1 or tx_DataBits;

    Select_Parity_DFF : process (Clk, Reset) is
    begin  -- process Select_Parity_DFF
      if Reset = '1' then                 -- asynchronous reset (active high)
        select_Parity <= '0';
      elsif Clk'event and Clk = '1' then  -- rising clock edge
        if (tx_Data_Enable = '1') then
          select_Parity <= mux_sel_is_zero;
        end if;
      end if;
    end process Select_Parity_DFF;
  end generate Using_Parity;

  No_Parity : if (C_USE_PARITY = 0) generate
    tx_Run        <= tx_DataBits;
    select_Parity <= '0';
  end generate No_Parity;
  -----------------------------------------------------------------------------
  -- Transmit FIFO
  -----------------------------------------------------------------------------
  SRL_FIFO_I : SRL_FIFO
    generic map (
      C_DATA_BITS => C_DATA_BITS,       -- [integer]
      C_DEPTH     => 16)                -- [integer]
    port map (
      Clk         => Clk,               -- [in  std_logic]
      Reset       => Reset_TX_FIFO,     -- [in  std_logic]
      FIFO_Write  => Write_TX_FIFO,     -- [in  std_logic]
      Data_In     => TX_Data,    -- [in  std_logic_vector(0 to C_DATA_BITS-1)]
      FIFO_Read   => fifo_Read,         -- [in  std_logic]
      Data_Out    => fifo_DOut,  -- [out std_logic_vector(0 to C_DATA_BITS-1)]
      FIFO_Full   => TX_BUFFER_FULL,    -- [out std_logic]
      Data_Exists => fifo_Data_Present);  -- [out std_logic]

  TX_Buffer_Empty <= not fifo_Data_Present;
end architecture IMP;
