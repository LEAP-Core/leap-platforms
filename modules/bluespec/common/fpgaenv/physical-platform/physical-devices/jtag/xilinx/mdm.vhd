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
    C_MB_DBG_PORTS        : integer                   := 1;
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
    RX_BUFFER_FULL  : out std_logic;
    
    Write_TX_FIFO   : in  std_logic;
    Reset_TX_FIFO   : in  std_logic;
    TX_Data         : in  std_logic_vector(0 to C_UART_WIDTH-1);
    TX_Buffer_Full  : out std_logic;
    TX_Buffer_Empty : out std_logic;
        
  );

end entity MDM;

architecture IMP of MDM is

  constant C_FSL_DATA_SIZE : integer := 32;

  component JTAG_CONTROL
    generic (
      C_MB_DBG_PORTS  :    integer := 0;
      C_USE_UART      :    integer := 1;
      C_UART_WIDTH    :    integer := 8;
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
      RX_Data         : out std_logic_vector(0 to 7);
      RX_Data_Present : out std_logic;
      RX_BUFFER_FULL  : out std_logic;

      Write_TX_FIFO   : in  std_logic;
      Reset_TX_FIFO   : in  std_logic;
      TX_Data         : in  std_logic_vector(0 to 7);
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
  
  constant Virtex2P_Based : boolean := equalIgnoreCase(C_FAMILY, "virtex2p");
  constant Virtex4_Based : boolean := equalIgnoreCase(C_FAMILY, "virtex4") or  equalIgnoreCase(C_FAMILY, "qvirtex4") or equalIgnoreCase(C_FAMILY, "qrvirtex4");
  constant Virtex5_Based : boolean := equalIgnoreCase(C_FAMILY, "virtex5") or equalIgnoreCase(C_FAMILY, "qrvirtex5");

  constant Spartan3_Based     : boolean := equalIgnoreCase(C_FAMILY, "spartan3") or equalIgnoreCase(C_FAMILY, "aspartan3");
  constant Spartan3E_Based    : boolean := equalIgnoreCase(C_FAMILY, "spartan3e") or equalIgnoreCase(C_FAMILY, "aspartan3e");
  constant Spartan3A_Based    : boolean := equalIgnoreCase(C_FAMILY, "spartan3a") or equalIgnoreCase(C_FAMILY, "aspartan3a");
  constant Spartan3ADSP_Based : boolean := equalIgnoreCase(C_FAMILY, "spartan3adsp") or equalIgnoreCase(C_FAMILY, "aspartan3adsp");
                                                           
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

  signal read_RX_FIFO      : std_logic;
  signal reset_RX_FIFO     : std_logic;

  signal rx_Data         : std_logic_vector(0 to 7);
  signal rx_Data_Present : std_logic;
  signal rx_BUFFER_FULL  : std_logic;

  signal write_TX_FIFO   : std_logic;
  signal reset_TX_FIFO   : std_logic;
  signal tx_BUFFER_FULL  : std_logic;
  signal tx_Buffer_Empty : std_logic;


  attribute period           : string;
  attribute period of update : signal is "200 ns";

  attribute buffer_type                : string;
  attribute buffer_type of update_i    : signal is "none";
  attribute buffer_type of update      : signal is "none";
  attribute buffer_type of MDM_Core_I1 : label is "none";

begin  -- architecture IMP

  read_RX_FIFO <= Read_RX_FIFO ;
  reset_RX_FIFO <= Reset_RX_FIFO; 
  RX_Data         <= rx_Data;
  RX_Data_Present <= rx_Data_Present; 
  RX_BUFFER_FULL <= rx_BUFFER_FULL;
  
  write_TX_FIFO <= Write_TX_FIFO;
  reset_TX_FIFO <= Reset_TX_FIFO;
  TX_Data         <= tx_Data;
  TX_Buffer_Full  <= tx_Buffer_Full;
  TX_Buffer_Empty <= tx_Buffer_Empty;
  
  Use_Spartan3 : if (Spartan3_Based or Spartan3E_Based) generate
    BSCAN_SPARTAN3_I : BSCAN_SPARTAN3
      port map (
        UPDATE  => update_i,            -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        SEL1    => open,                -- [out std_logic]
        DRCK1   => open,             -- [out std_logic]
        SEL2    => sel,                 -- [out std_logic]
        DRCK2   => drck_i,              -- [out std_logic]
        CAPTURE => capture,             -- [out std_logic]
        TDO1    => '0',                -- [in  std_logic]
        TDO2    => tdo                  -- [in  std_logic]
      );
  end generate Use_Spartan3;

  Use_Spartan3A : if (Spartan3A_Based or Spartan3ADSP_Based) generate
    BSCAN_SPARTAN3A_I : BSCAN_SPARTAN3A
      port map (
        TCK     => open,                -- [out std_logic]
        TMS     => open,                -- [out std_logic]
        CAPTURE => capture,             -- [out std_logic]
        UPDATE  => update_i,            -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        SEL1    => open,                -- [out std_logic]
        SEL2    => sel,                 -- [out std_logic]
        DRCK1   => open,             -- [out std_logic]
        DRCK2   => drck_i,              -- [out std_logic]
        TDO1    => '0',                -- [in  std_logic]
        TDO2    => tdo                  -- [in  std_logic]
      );
  end generate Use_Spartan3A;

  Use_Virtex2 : if (Virtex2P_Based) generate
    BSCAN_Virtex2_I : BSCAN_VIRTEX2
      port map (
        CAPTURE => capture,             -- [out std_logic]
        DRCK1   => open,             -- [out std_logic]
        DRCK2   => drck_i,              -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        SEL1    => open,                -- [out std_logic]
        SEL2    => sel,                 -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        UPDATE  => update_i,            -- [out std_logic]
        TDO1    => '0',                -- [in  std_logic]
        TDO2    => tdo                  -- [in  std_logic]
      );
  end generate Use_Virtex2;
  
  Use_Virtex4 : if (Virtex4_Based) generate
    BSCAN_VIRTEX4_I : BSCAN_VIRTEX4
      generic map (
        JTAG_CHAIN => C_JTAG_CHAIN)
      port map (
        TDO     => tdo,                 -- [in  std_logic]
        UPDATE  => update_i,            -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        SEL     => sel,                 -- [out std_logic]
        DRCK    => drck_i,              -- [out std_logic]
        CAPTURE => capture);            -- [out std_logic]

    -- Ground signals pretending to be CHAIN 1
    -- This does not actually use CHAIN 1
   
    -- tdo1 is unused

  end generate Use_Virtex4;

  Use_Virtex5 : if (Virtex5_Based) generate
    BSCAN_VIRTEX5_I : BSCAN_VIRTEX5
      generic map (
        JTAG_CHAIN => C_JTAG_CHAIN)
      port map (
        TDO     => tdo,                 -- [in  std_logic]
        UPDATE  => update_i,            -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        SEL     => sel,                 -- [out std_logic]
        DRCK    => drck_i,              -- [out std_logic]
        CAPTURE => capture);            -- [out std_logic]

    -- Ground signals pretending to be CHAIN 1
    -- This does not actually use CHAIN 1
   
    -- tdo1 is unused

  end generate Use_Virtex5;

--  drck1 <= drck1_i;
  
  BUFG_DRCK : BUFG
    port map (
      O => drck,
      I => drck_i
    );

--  drck <= drck_i;

--  BUFG_UPDATE : BUFG
--    port map (
--      O => update,
--      I => update_i
--    );

  update <= update_i;



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
        Rst             => ~Rst,         -- [in  std_logic] BSV is negative edge


        Clear_Ext_BRK => '0',  -- [in  std_logic]
        Ext_BRK       => open,        -- [out std_logic]
        Ext_NM_BRK    => open,     -- [out std_logic]
        Debug_SYS_Rst => open,  -- [out std_logic]
        Debug_Rst     => open,    -- [out std_logic]

        Read_RX_FIFO    => read_RX_FIFO,     -- [in  std_logic]
        Reset_RX_FIFO   => reset_RX_FIFO,    -- [in  std_logic]
        RX_Data         => rx_Data,          -- [out std_logic_vector(0 to 7)]
        RX_Data_Present => rx_Data_Present,  -- [out std_logic]
        RX_BUFFER_FULL  => rx_BUFFER_FULL,   -- [out std_logic]

        Write_TX_FIFO   => write_TX_FIFO,  -- [in  std_logic]
        Reset_TX_FIFO   => reset_TX_FIFO,  -- [in  std_logic]
        TX_Data         => tx_Buffer_Data,  -- [in  std_logic_vector(0 to 7)]
        TX_Buffer_Full  => tx_Buffer_Full,  -- [out std_logic]
        TX_Buffer_Empty => tx_Buffer_Empty,  -- [out std_logic]

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
        MB_Debug_Enabled => open,  -- [out std_logic_vector(7 downto 0)]
        Dbg_Clk          => open,    -- [out std_logic]
        Dbg_TDI          => '0',    -- [in  std_logic]
        Dbg_TDO          => open,    -- [out std_logic]
        Dbg_Reg_En       => open,  -- [out std_logic_vector(0 to 4)]
        Dbg_Capture      => open,  -- [out std_logic]
        Dbg_Shift        => open,  -- [out std_logic]
        Dbg_Update       => open,  -- [out std_logic]

        FSL0_S_Clk     => open,
        FSL0_S_Read    => open,
        FSL0_S_Data    => '0',
        FSL0_S_Control => '0',
        FSL0_S_Exists  => '0',
        FSL0_M_Clk     => open,
        FSL0_M_Write   => open,
        FSL0_M_Data    => open,
        FSL0_M_Control => open,
        FSL0_M_Full    => '0'

      );        

end architecture IMP;



