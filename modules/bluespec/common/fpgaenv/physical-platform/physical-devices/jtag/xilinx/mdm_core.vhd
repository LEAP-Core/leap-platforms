-------------------------------------------------------------------------------
-- $Id: mdm_core.vhd,v 1.1.2.1 2008/06/26 19:59:12 tshui Exp $
-------------------------------------------------------------------------------
-- mdm_core.vhd - Entity and architecture
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
-- Filename:        mdm_core.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              mdm_core.vhd
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
entity MDM_Core is

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
    C_FSL_DATA_SIZE       : integer := 32
  );

  port (
    -- Global signals
    Clk : in std_logic;
    Rst : in std_logic;

    Interrupt     : out std_logic;
    Ext_BRK       : out std_logic;
    Ext_NM_BRK    : out std_logic;
    Debug_SYS_Rst : out std_logic;
    --Debug_Rst     : out std_logic;

    Read_RX_FIFO    : in  std_logic;
    Reset_RX_FIFO   : in  std_logic;
    RX_Data         : out std_logic_vector(0 to C_UART_WIDTH-1);
    RX_Data_Present : out std_logic;
    --RX_BUFFER_FULL  : out std_logic;
    
    Write_TX_FIFO   : in  std_logic;
    Reset_TX_FIFO   : in  std_logic;
    TX_Data         : in  std_logic_vector(0 to C_UART_WIDTH-1);
    --TX_Buffer_Full  : out std_logic;
    TX_Buffer_Empty : out std_logic;    

    -- JTAG signals
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
end entity MDM_Core;

library unisim;
use unisim.vcomponents.all;

architecture IMP of MDM_CORE is

  component pselect
    generic (
      C_AB   :     integer;
      C_AW   :     integer;
      C_BAR  :     std_logic_vector
    );
    port (
      A      : in  std_logic_vector(0 to C_AW-1);
      AValid : in  std_logic;
      cs     : out std_logic
    );
  end component pselect;

  -- Returns at least 1
  function MakePos (a : integer) return integer is
  begin
    if a < 1 then
      return 1;
    else
      return a;
    end if;
  end function MakePos;

  constant C_EN_WIDTH : integer := MakePos(C_MB_DBG_PORTS);

  component JTAG_CONTROL
    generic (
      C_MB_DBG_PORTS  :    integer;
      C_USE_UART      :    integer;
      C_UART_WIDTH    :    integer;
      C_USE_FSL       :    integer := 0;
      C_FSL_DATA_SIZE :    integer := 32;
      C_EN_WIDTH      :    integer := 1
    );
    port (
      -- Global signals
      Clk             : in std_logic;
      Rst             : in std_logic;

      Clear_Ext_BRK : in  std_logic;
      Ext_BRK       : out std_logic;
      Ext_NM_BRK    : out std_logic;
      Debug_SYS_Rst : out std_logic;
      Debug_Rst     : out std_logic;

      Read_RX_FIFO    : in  std_logic;
      Reset_RX_FIFO   : in  std_logic;
      RX_Data         : out std_logic_vector(0 to C_UART_WIDTH-1);
      RX_Data_Present : out std_logic;
      RX_BUFFER_FULL  : out std_logic;

      Write_TX_FIFO   : in  std_logic;
      Reset_TX_FIFO   : in  std_logic;
      TX_Data         : in  std_logic_vector(0 to C_UART_WIDTH-1);
      TX_Buffer_Full  : out std_logic;
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
      MB_Debug_Enabled : out std_logic_vector(C_EN_WIDTH-1 downto 0);
      Dbg_Clk          : out std_logic;
      Dbg_TDI          : out std_logic;
      Dbg_TDO          : in  std_logic;
      Dbg_Reg_En       : out std_logic_vector(0 to 4);
      Dbg_Capture      : out std_logic;
      Dbg_Shift        : out std_logic;
      Dbg_Update       : out std_logic;

      FSL0_S_Clk     : out std_logic;
      FSL0_S_Read    : out std_logic;
      FSL0_S_Data    : in  std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL0_S_Control : in  std_logic;
      FSL0_S_Exists  : in  std_logic;
      FSL0_M_Clk     : out std_logic;
      FSL0_M_Write   : out std_logic;
      FSL0_M_Data    : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL0_M_Control : out std_logic;
      FSL0_M_Full    : in  std_logic

    );
  end component JTAG_CONTROL;


  -- Returns the minimum value of the two parameters
  function IntMin (a, b : integer) return integer is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function IntMin;

  signal clear_Ext_BRK : std_logic;

--  signal read_RX_FIFO      : std_logic;
--  signal reset_RX_FIFO     : std_logic;

--  signal rx_Data         : std_logic_vector(0 to C_UART_WIDTH-1);
--  signal rx_Data_Present : std_logic;
--  signal rx_BUFFER_FULL  : std_logic;

--  signal write_TX_FIFO   : std_logic;
--  signal reset_TX_FIFO   : std_logic;
--  signal tx_BUFFER_FULL  : std_logic;
--  signal tx_Buffer_Empty : std_logic;

--  signal tx_Buffer_Empty_Pre : std_logic;

  
  signal valid_access           : std_logic;  -- Active during the address phase (2 clock cycles)
  signal valid_access_1         : std_logic;  -- Will be a 1 clock delayed valid_access signal
  signal valid_access_2         : std_logic;  -- Active only 1 clock cycle
  signal reading                : std_logic;  -- Valid reading access
  signal valid_access_2_reading : std_logic;  -- signal to drive out data bus on a read access
  signal sl_rdDAck_i            : std_logic;
  signal sl_wrDAck_i            : std_logic;

  signal TDO_i : std_logic;

  signal MB_Debug_Enabled : std_logic_vector(C_EN_WIDTH-1 downto 0);  -- [out]
  signal Dbg_Clk          : std_logic;                                -- [out]
  signal Dbg_TDI          : std_logic;                                -- [out]
  signal Dbg_TDO          : std_logic;                                -- [in]
  signal Dbg_Reg_En       : std_logic_vector(0 to 4);                 -- [out]
  signal Dbg_Capture      : std_logic;                                -- [out]
  signal Dbg_Shift        : std_logic;                                -- [out]
  signal Dbg_Update       : std_logic;                                -- [out]

  signal Debug_Rst_i : std_logic;

  subtype Reg_En_TYPE is std_logic_vector(0 to 4);
  type Reg_EN_ARRAY is array(0 to 7) of Reg_En_TYPE;

  signal Dbg_TDO_I    : std_logic_vector(0 to 7);
  signal Dbg_TDI_I    : std_logic_vector(0 to 7);
  signal Dbg_Reg_En_I : Reg_EN_ARRAY;
  signal Dbg_Rst_I    : std_logic_vector(0 to 7);

  signal PORT_Selector   : std_logic_vector(3 downto 0) := "0000";
  signal PORT_Selector_1 : std_logic_vector(3 downto 0) := "0000";
  signal TDI_Shifter     : std_logic_vector(3 downto 0) := "0000";
  signal Sl_rdDBus_int   : std_logic_vector(0 to 31);
  
  -----------------------------------------------------------------------------
  -- Register mapping
  -----------------------------------------------------------------------------

  -- Magic string "01000010" + "00000000" + No of Jtag peripheral units "0010"
  -- + new Version no "00000101"
  constant New_MDM_Config_Word : std_logic_vector(31 downto 0) :=
    "01000010000000000000001000000101";

  signal Config_Reg : std_logic_vector(31 downto 0) := New_MDM_Config_Word;

  signal MDM_SEL : std_logic;

  signal Old_MDM_DRCK    : std_logic;
  signal Old_MDM_TDI     : std_logic;
  signal Old_MDM_TDO     : std_logic;
  signal Old_MDM_SEL     : std_logic;
  signal Old_MDM_SHIFT   : std_logic;
  signal Old_MDM_UPDATE  : std_logic;
  signal Old_MDM_RESET   : std_logic;
  signal Old_MDM_CAPTURE : std_logic;

  signal JTAG_Dec_Sel : std_logic_vector(15 downto 0);

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- TDI Shift Register
  -----------------------------------------------------------------------------
  -- Shifts data in when PORT 0 is selected. PORT 0 does not actually
  -- exist externaly, but gets selected after asserting the SELECT signal.
  -- The first value shifted in after SELECT goes high will select the new
  -- PORT. 
  JTAG_Mux_Shifting : process (DRCK, SEL)
  begin
    if SEL = '0' then
      TDI_Shifter   <= "0000";
    elsif DRCK'event and DRCK = '1' then
      if MDM_SEL = '1' and SHIFT = '1' then
        TDI_Shifter <= TDI & TDI_Shifter(3 downto 1);
      end if;
    end if;
  end process JTAG_Mux_Shifting;

  -----------------------------------------------------------------------------
  -- PORT Selector Register
  -----------------------------------------------------------------------------
  -- Captures the shifted data when PORT 0 is selected. The data is captured at
  -- the end of the BSCAN transaction (i.e. when the update signal goes low) to
  -- prevent any other BSCAN signals to assert incorrectly.
  -- Reference : XAPP 139  
  PORT_Selector_Updating : process (UPDATE, SEL)
  begin
    if SEL = '0' then
      PORT_Selector   <= "0000";
    elsif Update'event and Update = '0' then
      PORT_Selector <= Port_Selector_1;
    end if;
  end process PORT_Selector_Updating;

  PORT_Selector_Updating_1 : process (UPDATE, SEL)
  begin
    if SEL = '0' then
      PORT_Selector_1   <= "0000";
    elsif Update'event and Update = '1' then
      if MDM_SEL = '1' then
        PORT_Selector_1 <= TDI_Shifter;
      end if;
    end if;
  end process PORT_Selector_Updating_1;

  -----------------------------------------------------------------------------
  -- Configuration register
  -----------------------------------------------------------------------------
  -- TODO Can be replaced by SRLs
  Config_Shifting : process (DRCK, SHIFT)
  begin
    if SHIFT = '0' then
      Config_Reg <= New_MDM_Config_Word;
    elsif DRCK'event and DRCK = '1' then   -- rising clock edge
      Config_Reg <= '0' & Config_Reg(31 downto 1);
    end if;
  end process Config_Shifting;

  -----------------------------------------------------------------------------
  -- Muxing and demuxing of JTAG Bscan User 1/2/3/4 signals
  --
  -- This block enables the older MDM/JTAG to co-exist with the newer
  -- JTAG multiplexer
  -- block
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- TDO Mux
  -----------------------------------------------------------------------------
  with PORT_Selector select
    TDO_i <=
    Config_Reg(0) when "0000",
    Old_MDM_TDO   when "0001",
    Ext_JTAG_TDO  when "0010",
    '1'           when others;

  TDO <= TDO_i;

  -----------------------------------------------------------------------------
  -- SELECT Decoder
  -----------------------------------------------------------------------------
  MDM_SEL      <= SEL when PORT_Selector = "0000" else '0';
  Old_MDM_SEL  <= SEL when PORT_Selector = "0001" else '0';
  Ext_JTAG_SEL <= SEL when PORT_Selector = "0010" else '0';

  -----------------------------------------------------------------------------
  -- Old MDM signals
  -----------------------------------------------------------------------------
  Old_MDM_DRCK    <= DRCK;
  Old_MDM_TDI     <= TDI;
  Old_MDM_CAPTURE <= CAPTURE;
  Old_MDM_SHIFT   <= SHIFT;
  Old_MDM_UPDATE  <= UPDATE;
  Old_MDM_RESET   <= RESET;

  -----------------------------------------------------------------------------
  -- External JTAG signals
  -----------------------------------------------------------------------------
  Ext_JTAG_DRCK    <= DRCK;
  Ext_JTAG_TDI     <= TDI;
  Ext_JTAG_CAPTURE <= CAPTURE;
  Ext_JTAG_SHIFT   <= SHIFT;
  Ext_JTAG_UPDATE  <= UPDATE;
  Ext_JTAG_RESET   <= RESET;


  JTAG_CONTROL_I : JTAG_CONTROL
    generic map (
      C_MB_DBG_PORTS  => C_MB_DBG_PORTS,
      C_USE_UART      => C_USE_UART,
      C_UART_WIDTH    => C_UART_WIDTH,
      C_USE_FSL       => C_USE_FSL,        -- [integer]
      C_FSL_DATA_SIZE => C_FSL_DATA_SIZE,  -- [integer]
      C_EN_WIDTH      => C_EN_WIDTH
      )
    port map (
      -- Global signals
      Clk             => Clk,         -- [in  std_logic]
      Rst             => Rst,         -- [in  std_logic]
      
      Clear_Ext_BRK => clear_Ext_BRK,  -- [in  std_logic]
      Ext_BRK       => Ext_BRK,        -- [out std_logic]
      Ext_NM_BRK    => Ext_NM_BRK,     -- [out std_logic]
      Debug_SYS_Rst => Debug_SYS_Rst,  -- [out std_logic]
      Debug_Rst     => Debug_Rst_i,    -- [out std_logic]

      Read_RX_FIFO    => read_RX_FIFO,     -- [in  std_logic]
      Reset_RX_FIFO   => reset_RX_FIFO,    -- [in  std_logic]
      RX_Data         => rx_Data,          -- [out std_logic_vector(0 to 7)]
      RX_Data_Present => rx_Data_Present,  -- [out std_logic]
--      RX_BUFFER_FULL  => rx_BUFFER_FULL,   -- [out std_logic]

      Write_TX_FIFO   => write_TX_FIFO,  -- [in  std_logic]
      Reset_TX_FIFO   => reset_TX_FIFO,  -- [in  std_logic]
      TX_Data         => tx_Data,  -- [in  std_logic_vector(0 to 7)]
--      TX_Buffer_Full  => tx_Buffer_Full,  -- [out std_logic]
      TX_Buffer_Empty => tx_Buffer_Empty,  -- [out std_logic]

      -- MDM signals
      TDI     => Old_MDM_TDI,         -- [in  std_logic]
      RESET   => Old_MDM_RESET,       -- [in  std_logic]
      UPDATE  => Old_MDM_UPDATE,      -- [in  std_logic]
      SHIFT   => Old_MDM_SHIFT,       -- [in  std_logic]
      CAPTURE => Old_MDM_CAPTURE,     -- [in  std_logic]
      SEL     => Old_MDM_SEL,         -- [in  std_logic]
      DRCK    => Old_MDM_DRCK,        -- [in  std_logic]
      TDO     => Old_MDM_TDO,         -- [out std_logic]

      -- MicroBlaze Debug Signals
      MB_Debug_Enabled => MB_Debug_Enabled,  -- [out std_logic_vector(7 downto 0)]
      Dbg_Clk          => Dbg_Clk,    -- [out std_logic]
      Dbg_TDI          => Dbg_TDI,    -- [in  std_logic]
      Dbg_TDO          => Dbg_TDO,    -- [out std_logic]
      Dbg_Reg_En       => Dbg_Reg_En,  -- [out std_logic_vector(0 to 4)]
      Dbg_Capture      => Dbg_Capture,  -- [out std_logic]
      Dbg_Shift        => Dbg_Shift,  -- [out std_logic]
      Dbg_Update       => Dbg_Update,  -- [out std_logic]
      
      FSL0_S_Clk     => FSL0_S_Clk,
      FSL0_S_Read    => FSL0_S_Read,
      FSL0_S_Data    => FSL0_S_Data,
      FSL0_S_Control => FSL0_S_Control,
      FSL0_S_Exists  => FSL0_S_Exists,
      FSL0_M_Clk     => FSL0_M_Clk,
      FSL0_M_Write   => FSL0_M_Write,
      FSL0_M_Data    => FSL0_M_Data,
      FSL0_M_Control => FSL0_M_Control,
      FSL0_M_Full    => FSL0_M_Full

    );


  -----------------------------------------------------------------------------
  -- Enables for each debug port
  -----------------------------------------------------------------------------
  Generate_Dbg_Port_Signals : process (MB_Debug_Enabled, Dbg_Reg_En,
                                       Dbg_TDO_I, Debug_Rst_I)

    variable dbg_tdo_or : std_logic;
  begin  -- process Generate_Dbg_Port_Signals
    dbg_tdo_or   := '0';
    for I in 0 to C_EN_WIDTH-1 loop
      if (MB_Debug_Enabled(I) = '1') then
        Dbg_Reg_En_I(I) <= Dbg_Reg_En;
        Dbg_Rst_I(I)    <= Debug_Rst_i;
      else
        Dbg_Reg_En_I(I) <= "00000";
        Dbg_Rst_I(I)    <= '0';
      end if;
      dbg_tdo_or := dbg_tdo_or or Dbg_TDO_I(I);
    end loop;  -- I
    Dbg_TDO             <= dbg_tdo_or;
  end process Generate_Dbg_Port_Signals;

  --Debug_Rst <= Debug_Rst_i;

  Dbg_Clk_0     <= Dbg_Clk;
  Dbg_TDI_0     <= Dbg_TDI;
  Dbg_Reg_En_0  <= Dbg_Reg_En_I(0);
  Dbg_Capture_0 <= Dbg_Capture;
  Dbg_Shift_0   <= Dbg_Shift;
  Dbg_Update_0  <= Dbg_Update;
  Dbg_Rst_0     <= Dbg_Rst_I(0);
  Dbg_TDO_I(0)  <= Dbg_TDO_0;

  Dbg_Clk_1     <= Dbg_Clk;
  Dbg_TDI_1     <= Dbg_TDI;
  Dbg_Reg_En_1  <= Dbg_Reg_En_I(1);
  Dbg_Capture_1 <= Dbg_Capture;
  Dbg_Shift_1   <= Dbg_Shift;
  Dbg_Update_1  <= Dbg_Update;
  Dbg_Rst_1     <= Dbg_Rst_I(1);
  Dbg_TDO_I(1)  <= Dbg_TDO_1;

  Dbg_Clk_2     <= Dbg_Clk;
  Dbg_TDI_2     <= Dbg_TDI;
  Dbg_Reg_En_2  <= Dbg_Reg_En_I(2);
  Dbg_Capture_2 <= Dbg_Capture;
  Dbg_Shift_2   <= Dbg_Shift;
  Dbg_Update_2  <= Dbg_Update;
  Dbg_Rst_2     <= Dbg_Rst_I(2);
  Dbg_TDO_I(2)  <= Dbg_TDO_2;

  Dbg_Clk_3     <= Dbg_Clk;
  Dbg_TDI_3     <= Dbg_TDI;
  Dbg_Reg_En_3  <= Dbg_Reg_En_I(3);
  Dbg_Capture_3 <= Dbg_Capture;
  Dbg_Shift_3   <= Dbg_Shift;
  Dbg_Update_3  <= Dbg_Update;
  Dbg_Rst_3     <= Dbg_Rst_I(3);
  Dbg_TDO_I(3)  <= Dbg_TDO_3;

  Dbg_Clk_4     <= Dbg_Clk;
  Dbg_TDI_4     <= Dbg_TDI;
  Dbg_Reg_En_4  <= Dbg_Reg_En_I(4);
  Dbg_Capture_4 <= Dbg_Capture;
  Dbg_Shift_4   <= Dbg_Shift;
  Dbg_Update_4  <= Dbg_Update;
  Dbg_Rst_4     <= Dbg_Rst_I(4);
  Dbg_TDO_I(4)  <= Dbg_TDO_4;

  Dbg_Clk_5     <= Dbg_Clk;
  Dbg_TDI_5     <= Dbg_TDI;
  Dbg_Reg_En_5  <= Dbg_Reg_En_I(5);
  Dbg_Capture_5 <= Dbg_Capture;
  Dbg_Shift_5   <= Dbg_Shift;
  Dbg_Update_5  <= Dbg_Update;
  Dbg_Rst_5     <= Dbg_Rst_I(5);
  Dbg_TDO_I(5)  <= Dbg_TDO_5;

  Dbg_Clk_6     <= Dbg_Clk;
  Dbg_TDI_6     <= Dbg_TDI;
  Dbg_Reg_En_6  <= Dbg_Reg_En_I(6);
  Dbg_Capture_6 <= Dbg_Capture;
  Dbg_Shift_6   <= Dbg_Shift;
  Dbg_Update_6  <= Dbg_Update;
  Dbg_Rst_6     <= Dbg_Rst_I(6);
  Dbg_TDO_I(6)  <= Dbg_TDO_6;

  Dbg_Clk_7     <= Dbg_Clk;
  Dbg_TDI_7     <= Dbg_TDI;
  Dbg_Reg_En_7  <= Dbg_Reg_En_I(7);
  Dbg_Capture_7 <= Dbg_Capture;
  Dbg_Shift_7   <= Dbg_Shift;
  Dbg_Update_7  <= Dbg_Update;
  Dbg_Rst_7     <= Dbg_Rst_I(7);
  Dbg_TDO_I(7)  <= Dbg_TDO_7;

end architecture IMP;



