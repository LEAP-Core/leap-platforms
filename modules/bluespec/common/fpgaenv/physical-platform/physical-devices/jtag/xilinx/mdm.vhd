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
    -- Global signals
    SPLB_Clk : in std_logic;
    SPLB_Rst : in std_logic;

    OPB_Clk : in std_logic;
    OPB_Rst : in std_logic;

    Interrupt     : out std_logic;
    Ext_BRK       : out std_logic;
    Ext_NM_BRK    : out std_logic;
    Debug_SYS_Rst : out std_logic;

    -- PLBv46 signals
    PLB_ABus       : in std_logic_vector(0 to 31);
    PLB_UABus      : in std_logic_vector(0 to 31);
    PLB_PAValid    : in std_logic;
    PLB_SAValid    : in std_logic;
    PLB_rdPrim     : in std_logic;
    PLB_wrPrim     : in std_logic;
    PLB_masterID   : in std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_abort      : in std_logic;
    PLB_busLock    : in std_logic;
    PLB_RNW        : in std_logic;
    PLB_BE         : in std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1);
    PLB_MSize      : in std_logic_vector(0 to 1);
    PLB_size       : in std_logic_vector(0 to 3);
    PLB_type       : in std_logic_vector(0 to 2);
    PLB_lockErr    : in std_logic;
    PLB_wrDBus     : in std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst    : in std_logic;
    PLB_rdBurst    : in std_logic;
    PLB_wrPendReq  : in std_logic;
    PLB_rdPendReq  : in std_logic;
    PLB_wrPendPri  : in std_logic_vector(0 to 1);
    PLB_rdPendPri  : in std_logic_vector(0 to 1);
    PLB_reqPri     : in std_logic_vector(0 to 1);
    PLB_TAttribute : in std_logic_vector(0 to 15);

    Sl_addrAck     : out std_logic;
    Sl_SSize       : out std_logic_vector(0 to 1);
    Sl_wait        : out std_logic;
    Sl_rearbitrate : out std_logic;
    Sl_wrDAck      : out std_logic;
    Sl_wrComp      : out std_logic;
    Sl_wrBTerm     : out std_logic;
    Sl_rdDBus      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr    : out std_logic_vector(0 to 3);
    Sl_rdDAck      : out std_logic;
    Sl_rdComp      : out std_logic;
    Sl_rdBTerm     : out std_logic;
    Sl_MBusy       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MIRQ        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

    -- OPB signals
    OPB_ABus    : in std_logic_vector(0 to 31);
    OPB_BE      : in std_logic_vector(0 to 3);
    OPB_RNW     : in std_logic;
    OPB_select  : in std_logic;
    OPB_seqAddr : in std_logic;
    OPB_DBus    : in std_logic_vector(0 to 31);

    MDM_DBus    : out std_logic_vector(0 to 31);
    MDM_errAck  : out std_logic;
    MDM_retry   : out std_logic;
    MDM_toutSup : out std_logic;
    MDM_xferAck : out std_logic;

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

-- Connect the BSCAN's USER1 + common signals to the external pins
-- These signals can be connected to an ICON core instantiated by the user
-- Will not be used if the ICON is inserted within the mdm

    bscan_tdi     : out std_logic;
    bscan_reset   : out std_logic;
    bscan_shift   : out std_logic;
    bscan_update  : out std_logic;
    bscan_capture : out std_logic;
    bscan_sel1    : out std_logic;
    bscan_drck1   : out std_logic;
    bscan_tdo1    : in  std_logic;

    ---------------------------------------------------------------------------
    -- FSL ports
    ---------------------------------------------------------------------------

    FSL0_S_Clk     : out std_logic;
    FSL0_S_Read    : out std_logic;
    FSL0_S_Data    : in  std_logic_vector(0 to 31);
    FSL0_S_Control : in  std_logic;
    FSL0_S_Exists  : in  std_logic;

    FSL0_M_Clk     : out std_logic;
    FSL0_M_Write   : out std_logic;
    FSL0_M_Data    : out std_logic_vector(0 to 31);
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

end entity MDM;

library unisim;
use unisim.vcomponents.all;

library mdm_v1_00_d;
use mdm_v1_00_d.all;

library proc_common_v1_00_c;
use proc_common_v1_00_c.family.all;

architecture IMP of MDM is

  constant C_FSL_DATA_SIZE : integer := 32;

  component MDM_Core
    generic (
      C_BASEADDR            : std_logic_vector(0 to 31);
      C_HIGHADDR            : std_logic_vector(0 to 31);
      C_INTERCONNECT        : integer := 0;
      C_SPLB_AWIDTH         : integer := 32;
      C_SPLB_DWIDTH         : integer := 32;
      C_SPLB_P2P            : integer := 0;
      C_SPLB_MID_WIDTH      : integer := 3;
      C_SPLB_NUM_MASTERS    : integer := 8;
      C_SPLB_NATIVE_DWIDTH  : integer := 32;
      C_SPLB_SUPPORT_BURSTS : integer := 0;
      C_MB_DBG_PORTS        : integer;
      C_USE_UART            : integer;
      C_UART_WIDTH          : integer := 8;
      C_USE_FSL             : integer;
      C_FSL_DATA_SIZE       : integer);

    port (
      -- Global signals
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;

      OPB_Clk : in std_logic;
      OPB_Rst : in std_logic;

      Interrupt     : out std_logic;
      Ext_BRK       : out std_logic;
      Ext_NM_BRK    : out std_logic;
      Debug_SYS_Rst : out std_logic;

      -- PLBv46 signals
      PLB_ABus       : in std_logic_vector(0 to 31);
      PLB_UABus      : in std_logic_vector(0 to 31);
      PLB_PAValid    : in std_logic;
      PLB_SAValid    : in std_logic;
      PLB_rdPrim     : in std_logic;
      PLB_wrPrim     : in std_logic;
      PLB_masterID   : in std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      PLB_abort      : in std_logic;
      PLB_busLock    : in std_logic;
      PLB_RNW        : in std_logic;
      PLB_BE         : in std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1);
      PLB_MSize      : in std_logic_vector(0 to 1);
      PLB_size       : in std_logic_vector(0 to 3);
      PLB_type       : in std_logic_vector(0 to 2);
      PLB_lockErr    : in std_logic;
      PLB_wrDBus     : in std_logic_vector(0 to C_SPLB_DWIDTH-1);
      PLB_wrBurst    : in std_logic;
      PLB_rdBurst    : in std_logic;
      PLB_wrPendReq  : in std_logic;
      PLB_rdPendReq  : in std_logic;
      PLB_wrPendPri  : in std_logic_vector(0 to 1);
      PLB_rdPendPri  : in std_logic_vector(0 to 1);
      PLB_reqPri     : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);

      Sl_addrAck     : out std_logic;
      Sl_SSize       : out std_logic_vector(0 to 1);
      Sl_wait        : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck      : out std_logic;
      Sl_wrComp      : out std_logic;
      Sl_wrBTerm     : out std_logic;
      Sl_rdDBus      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
      Sl_rdWdAddr    : out std_logic_vector(0 to 3);
      Sl_rdDAck      : out std_logic;
      Sl_rdComp      : out std_logic;
      Sl_rdBTerm     : out std_logic;
      Sl_MBusy       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
      Sl_MWrErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
      Sl_MRdErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
      Sl_MIRQ        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

      -- OPB signals
      OPB_ABus    : in std_logic_vector(0 to 31);
      OPB_BE      : in std_logic_vector(0 to 3);
      OPB_RNW     : in std_logic;
      OPB_select  : in std_logic;
      OPB_seqAddr : in std_logic;
      OPB_DBus    : in std_logic_vector(0 to 31);

      MDM_DBus    : out std_logic_vector(0 to 31);
      MDM_errAck  : out std_logic;
      MDM_retry   : out std_logic;
      MDM_toutSup : out std_logic;
      MDM_xferAck : out std_logic;

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
  end component MDM_Core;

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

  attribute period           : string;
  attribute period of update : signal is "200 ns";

  attribute buffer_type                : string;
  attribute buffer_type of update_i    : signal is "none";
  attribute buffer_type of update      : signal is "none";
  attribute buffer_type of MDM_Core_I1 : label is "none";

begin  -- architecture IMP

  -- Connect USER1 signal to external ports
  tdo1 <= bscan_tdo1;

  bscan_drck1   <= drck1;
  bscan_sel1    <= sel1;
  bscan_tdi     <= tdi;
  bscan_reset   <= reset;
  bscan_shift   <= shift;
  bscan_update  <= update;
  bscan_capture <= capture;

  Use_Spartan3 : if (Spartan3_Based or Spartan3E_Based) generate
    BSCAN_SPARTAN3_I : BSCAN_SPARTAN3
      port map (
        UPDATE  => update_i,            -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        SEL1    => sel1,                -- [out std_logic]
        DRCK1   => drck1_i,             -- [out std_logic]
        SEL2    => sel,                 -- [out std_logic]
        DRCK2   => drck_i,              -- [out std_logic]
        CAPTURE => capture,             -- [out std_logic]
        TDO1    => tdo1,                -- [in  std_logic]
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
        SEL1    => sel1,                -- [out std_logic]
        SEL2    => sel,                 -- [out std_logic]
        DRCK1   => drck1_i,             -- [out std_logic]
        DRCK2   => drck_i,              -- [out std_logic]
        TDO1    => tdo1,                -- [in  std_logic]
        TDO2    => tdo                  -- [in  std_logic]
      );
  end generate Use_Spartan3A;

  Use_Virtex2 : if (Virtex2P_Based) generate
    BSCAN_Virtex2_I : BSCAN_VIRTEX2
      port map (
        CAPTURE => capture,             -- [out std_logic]
        DRCK1   => drck1_i,             -- [out std_logic]
        DRCK2   => drck_i,              -- [out std_logic]
        RESET   => reset,               -- [out std_logic]
        SEL1    => sel1,                -- [out std_logic]
        SEL2    => sel,                 -- [out std_logic]
        SHIFT   => shift,               -- [out std_logic]
        TDI     => tdi,                 -- [out std_logic]
        UPDATE  => update_i,            -- [out std_logic]
        TDO1    => tdo1,                -- [in  std_logic]
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
    sel1    <= '0';
    drck1_i <= '0';

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
    sel1    <= '0';
    drck1_i <= '0';

    -- tdo1 is unused

  end generate Use_Virtex5;

  BUFG_DRCK1 : BUFG
    port map (
      O => drck1,
      I => drck1_i
    );

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

  MDM_Core_I1 : MDM_Core
    generic map (
      C_BASEADDR            => C_BASEADDR,  -- [std_logic_vector(0 to 31)]
      C_HIGHADDR            => C_HIGHADDR,  -- [std_logic_vector(0 to 31)]
      C_INTERCONNECT        => C_INTERCONNECT,
      C_SPLB_AWIDTH         => C_SPLB_AWIDTH,          -- [integer = 32]
      C_SPLB_DWIDTH         => C_SPLB_DWIDTH,          -- [integer = 32]
      C_SPLB_P2P            => C_SPLB_P2P,  -- [integer = 0]
      C_SPLB_MID_WIDTH      => C_SPLB_MID_WIDTH,       -- [integer = 3]
      C_SPLB_NUM_MASTERS    => C_SPLB_NUM_MASTERS,     -- [integer = 8]
      C_SPLB_NATIVE_DWIDTH  => C_SPLB_NATIVE_DWIDTH,   -- [integer = 32]
      C_SPLB_SUPPORT_BURSTS => C_SPLB_SUPPORT_BURSTS,  -- [integer = 0]
      C_MB_DBG_PORTS        => C_MB_DBG_PORTS,         -- [integer]
      C_USE_UART            => C_USE_UART,  -- [integer]
      C_UART_WIDTH          => C_UART_WIDTH,           -- [integer]
      C_USE_FSL             => C_WRITE_FSL_PORTS,      -- [integer]
      C_FSL_DATA_SIZE       => C_FSL_DATA_SIZE         -- [integer]
    )

    port map (
      -- Global signals
      SPLB_Clk => SPLB_Clk,             -- [in  std_logic]
      SPLB_Rst => SPLB_Rst,             -- [in  std_logic]

      OPB_Clk => OPB_Clk,               -- [in  std_logic]
      OPB_Rst => OPB_Rst,               -- [in  std_logic]

      Interrupt     => Interrupt,       -- [out std_logic]
      Ext_BRK       => Ext_BRK,         -- [out std_logic]
      Ext_NM_BRK    => Ext_NM_BRK,      -- [out std_logic]
      Debug_SYS_Rst => Debug_SYS_Rst,   -- [out std_logic]

      -- PLBv46 signals
      PLB_ABus       => PLB_ABus,       -- [in  std_logic_vector(0 to 31)]
      PLB_UABus      => PLB_UABus,      -- [in  std_logic_vector(0 to 31)]
      PLB_PAValid    => PLB_PAValid,    -- [in  std_logic]
      PLB_SAValid    => PLB_SAValid,    -- [in  std_logic]
      PLB_rdPrim     => PLB_rdPrim,     -- [in  std_logic]
      PLB_wrPrim     => PLB_wrPrim,     -- [in  std_logic]
      PLB_masterID   => PLB_masterID,  -- [in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1)]
      PLB_abort      => PLB_abort,      -- [in  std_logic]
      PLB_busLock    => PLB_busLock,    -- [in  std_logic]
      PLB_RNW        => PLB_RNW,        -- [in  std_logic]
      PLB_BE         => PLB_BE,  -- [in  std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1)]
      PLB_MSize      => PLB_MSize,      -- [in  std_logic_vector(0 to 1)]
      PLB_size       => PLB_size,       -- [in  std_logic_vector(0 to 3)]
      PLB_type       => PLB_type,       -- [in  std_logic_vector(0 to 2)]
      PLB_lockErr    => PLB_lockErr,    -- [in  std_logic]
      PLB_wrDBus     => PLB_wrDBus,  -- [in  std_logic_vector(0 to C_SPLB_DWIDTH-1)]
      PLB_wrBurst    => PLB_wrBurst,    -- [in  std_logic]
      PLB_rdBurst    => PLB_rdBurst,    -- [in  std_logic]
      PLB_wrPendReq  => PLB_wrPendReq,  -- [in  std_logic]
      PLB_rdPendReq  => PLB_rdPendReq,  -- [in  std_logic]
      PLB_wrPendPri  => PLB_wrPendPri,  -- [in  std_logic_vector(0 to 1)]
      PLB_rdPendPri  => PLB_rdPendPri,  -- [in  std_logic_vector(0 to 1)]
      PLB_reqPri     => PLB_reqPri,     -- [in  std_logic_vector(0 to 1)]
      PLB_TAttribute => PLB_TAttribute,  -- [in  std_logic_vector(0 to 15)]

      Sl_addrAck     => Sl_addrAck,     -- [out std_logic]
      Sl_SSize       => Sl_SSize,       -- [out std_logic_vector(0 to 1)]
      Sl_wait        => Sl_wait,        -- [out std_logic]
      Sl_rearbitrate => Sl_rearbitrate,  -- [out std_logic]
      Sl_wrDAck      => Sl_wrDAck,      -- [out std_logic]
      Sl_wrComp      => Sl_wrComp,      -- [out std_logic]
      Sl_wrBTerm     => Sl_wrBTerm,     -- [out std_logic]
      Sl_rdDBus      => Sl_rdDBus,  -- [out std_logic_vector(0 to C_SPLB_DWIDTH-1)]
      Sl_rdWdAddr    => Sl_rdWdAddr,    -- [out std_logic_vector(0 to 3)]
      Sl_rdDAck      => Sl_rdDAck,      -- [out std_logic]
      Sl_rdComp      => Sl_rdComp,      -- [out std_logic]
      Sl_rdBTerm     => Sl_rdBTerm,     -- [out std_logic]
      Sl_MBusy       => Sl_MBusy,  -- [out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)]
      Sl_MWrErr      => Sl_MWrErr,  -- [out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)]
      Sl_MRdErr      => Sl_MRdErr,  -- [out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)]
      Sl_MIRQ        => Sl_MIRQ,  -- [out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)]

      -- OPB signals
      OPB_ABus    => OPB_ABus,          -- [in  std_logic_vector(0 to 31)]
      OPB_BE      => OPB_BE,            -- [in  std_logic_vector(0 to 3)]
      OPB_RNW     => OPB_RNW,           -- [in  std_logic]
      OPB_select  => OPB_select,        -- [in  std_logic]
      OPB_seqAddr => OPB_seqAddr,       -- [in  std_logic]
      OPB_DBus    => OPB_DBus,          -- [in  std_logic_vector(0 to 31)]

      MDM_DBus    => MDM_DBus,          -- [out std_logic_vector(0 to 31)]
      MDM_errAck  => MDM_errAck,        -- [out std_logic]
      MDM_retry   => MDM_retry,         -- [out std_logic]
      MDM_toutSup => MDM_toutSup,       -- [out std_logic]
      MDM_xferAck => MDM_xferAck,       -- [out std_logic] 

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
      Dbg_Clk_0     => Dbg_Clk_0,       -- [out std_logic]
      Dbg_TDI_0     => Dbg_TDI_0,       -- [out std_logic]
      Dbg_TDO_0     => Dbg_TDO_0,       -- [in  std_logic]
      Dbg_Reg_En_0  => Dbg_Reg_En_0,    -- [out std_logic_vector(0 to 4)]
      Dbg_Capture_0 => Dbg_Capture_0,   -- [out std_logic]
      Dbg_Shift_0   => Dbg_Shift_0,     -- [out std_logic]
      Dbg_Update_0  => Dbg_Update_0,    -- [out std_logic]
      Dbg_Rst_0     => Dbg_Rst_0,       -- [out std_logic]

      Dbg_Clk_1     => Dbg_Clk_1,       -- [out std_logic]
      Dbg_TDI_1     => Dbg_TDI_1,       -- [out std_logic]
      Dbg_TDO_1     => Dbg_TDO_1,       -- [in  std_logic]
      Dbg_Reg_En_1  => Dbg_Reg_En_1,    -- [out std_logic_vector(0 to 4)]
      Dbg_Capture_1 => Dbg_Capture_1,   -- [out std_logic]
      Dbg_Shift_1   => Dbg_Shift_1,     -- [out std_logic]
      Dbg_Update_1  => Dbg_Update_1,    -- [out std_logic]
      Dbg_Rst_1     => Dbg_Rst_1,       -- [out std_logic]

      Dbg_Clk_2     => Dbg_Clk_2,       -- [out std_logic]
      Dbg_TDI_2     => Dbg_TDI_2,       -- [out std_logic]
      Dbg_TDO_2     => Dbg_TDO_2,       -- [in  std_logic]
      Dbg_Reg_En_2  => Dbg_Reg_En_2,    -- [out std_logic_vector(0 to 4)]
      Dbg_Capture_2 => Dbg_Capture_2,   -- [out std_logic]
      Dbg_Shift_2   => Dbg_Shift_2,     -- [out std_logic]
      Dbg_Update_2  => Dbg_Update_2,    -- [out std_logic]
      Dbg_Rst_2     => Dbg_Rst_2,       -- [out std_logic]

      Dbg_Clk_3     => Dbg_Clk_3,       -- [out std_logic]
      Dbg_TDI_3     => Dbg_TDI_3,       -- [out std_logic]
      Dbg_TDO_3     => Dbg_TDO_3,       -- [in  std_logic]
      Dbg_Reg_En_3  => Dbg_Reg_En_3,    -- [out std_logic_vector(0 to 4)]
      Dbg_Capture_3 => Dbg_Capture_3,   -- [out std_logic]
      Dbg_Shift_3   => Dbg_Shift_3,     -- [out std_logic]
      Dbg_Update_3  => Dbg_Update_3,    -- [out std_logic]
      Dbg_Rst_3     => Dbg_Rst_3,       -- [out std_logic]

      Dbg_Clk_4     => Dbg_Clk_4,       -- [out std_logic]
      Dbg_TDI_4     => Dbg_TDI_4,       -- [out std_logic]
      Dbg_TDO_4     => Dbg_TDO_4,       -- [in  std_logic]
      Dbg_Reg_En_4  => Dbg_Reg_En_4,    -- [out std_logic_vector(0 to 4)]
      Dbg_Capture_4 => Dbg_Capture_4,   -- [out std_logic]
      Dbg_Shift_4   => Dbg_Shift_4,     -- [out std_logic]
      Dbg_Update_4  => Dbg_Update_4,    -- [out std_logic]
      Dbg_Rst_4     => Dbg_Rst_4,       -- [out std_logic]

      Dbg_Clk_5     => Dbg_Clk_5,       -- [out std_logic]
      Dbg_TDI_5     => Dbg_TDI_5,       -- [out std_logic]
      Dbg_TDO_5     => Dbg_TDO_5,       -- [in  std_logic]
      Dbg_Reg_En_5  => Dbg_Reg_En_5,    -- [out std_logic_vector(0 to 4)]
      Dbg_Capture_5 => Dbg_Capture_5,   -- [out std_logic]
      Dbg_Shift_5   => Dbg_Shift_5,     -- [out std_logic]
      Dbg_Update_5  => Dbg_Update_5,    -- [out std_logic]
      Dbg_Rst_5     => Dbg_Rst_5,       -- [out std_logic]

      Dbg_Clk_6     => Dbg_Clk_6,       -- [out std_logic]
      Dbg_TDI_6     => Dbg_TDI_6,       -- [out std_logic]
      Dbg_TDO_6     => Dbg_TDO_6,       -- [in  std_logic]
      Dbg_Reg_En_6  => Dbg_Reg_En_6,    -- [out std_logic_vector(0 to 4)]
      Dbg_Capture_6 => Dbg_Capture_6,   -- [out std_logic]
      Dbg_Shift_6   => Dbg_Shift_6,     -- [out std_logic]
      Dbg_Update_6  => Dbg_Update_6,    -- [out std_logic]
      Dbg_Rst_6     => Dbg_Rst_6,       -- [out std_logic]

      Dbg_Clk_7     => Dbg_Clk_7,       -- [out std_logic]
      Dbg_TDI_7     => Dbg_TDI_7,       -- [out std_logic]
      Dbg_TDO_7     => Dbg_TDO_7,       -- [in  std_logic]
      Dbg_Reg_En_7  => Dbg_Reg_En_7,    -- [out std_logic_vector(0 to 4)]
      Dbg_Capture_7 => Dbg_Capture_7,   -- [out std_logic]
      Dbg_Shift_7   => Dbg_Shift_7,     -- [out std_logic]
      Dbg_Update_7  => Dbg_Update_7,    -- [out std_logic]
      Dbg_Rst_7     => Dbg_Rst_7,       -- [out std_logic]

      FSL0_S_Clk     => FSL0_S_Clk,     -- [out std_logic]
      FSL0_S_Read    => FSL0_S_Read,    -- [out std_logic]
      FSL0_S_Data    => FSL0_S_Data,  -- [in  std_logic_vector(0 to C_FSL_DATA_SIZE-1)]
      FSL0_S_Control => FSL0_S_Control,  -- [in  std_logic]
      FSL0_S_Exists  => FSL0_S_Exists,  -- [in  std_logic]
      FSL0_M_Clk     => FSL0_M_Clk,     -- [out std_logic]
      FSL0_M_Write   => FSL0_M_Write,   -- [out std_logic]
      FSL0_M_Data    => FSL0_M_Data,  -- [out std_logic_vector(0 to C_FSL_DATA_SIZE-1)]
      FSL0_M_Control => FSL0_M_Control,  -- [out std_logic]
      FSL0_M_Full    => FSL0_M_Full,    -- [in  std_logic]

      Ext_JTAG_DRCK    => Ext_JTAG_DRCK,
      Ext_JTAG_RESET   => Ext_JTAG_RESET,
      Ext_JTAG_SEL     => Ext_JTAG_SEL,
      Ext_JTAG_CAPTURE => Ext_JTAG_CAPTURE,
      Ext_JTAG_SHIFT   => Ext_JTAG_SHIFT,
      Ext_JTAG_UPDATE  => Ext_JTAG_UPDATE,
      Ext_JTAG_TDI     => Ext_JTAG_TDI,
      Ext_JTAG_TDO     => Ext_JTAG_TDO);

end architecture IMP;



