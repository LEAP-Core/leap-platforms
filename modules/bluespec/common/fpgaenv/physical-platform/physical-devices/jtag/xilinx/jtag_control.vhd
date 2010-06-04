-------------------------------------------------------------------------------
-- $Id: jtag_control.vhd,v 1.1.2.1 2008/06/26 19:59:12 tshui Exp $
-------------------------------------------------------------------------------
-- jtag_control.vhd - Entity and architecture
--
-- ***************************************************************************
-- **  Copyright(C) 2003 by Xilinx, Inc. All rights reserved.               **
-- **                                                                       **
-- **  This text contains proprietary, confidential                         **
-- **  information of Xilinx, Inc. , is distributed by                      **
-- **  under license from Xilinx, Inc., and may be used,                    **
-- **  copied and/or disclosed only pursuant to the terms                   **
-- **  of a valid license agreement with Xilinx, Inc.                       **
-- **                                                                       **
-- **  Unmodified source code is guaranteed to place and route,             **
-- **  function and run at speed according to the datasheet                 **
-- **  specification. Source code is provided "as-is", with no              **
-- **  obligation on the part of Xilinx to provide support.                 **
-- **                                                                       **
-- **  Xilinx Hotline support of source code IP shall only include          **
-- **  standard level Xilinx Hotline support, and will only address         **
-- **  issues and questions related to the standard released Netlist        **
-- **  version of the core (and thus indirectly, the original core source). **
-- **                                                                       **
-- **  The Xilinx Support Hotline does not have access to source            **
-- **  code and therefore cannot answer specific questions related          **
-- **  to source HDL. The Xilinx Support Hotline will only be able          **
-- **  to confirm the problem in the Netlist version of the core.           **
-- **                                                                       **
-- **  This copyright and support notice must be retained as part           **
-- **  of this text at all times.                                           **
-- ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        jtag_control.vhd
--
-- Description:     
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              jtag_control.vhd
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
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity JTAG_CONTROL is
  generic (
    C_MB_DBG_PORTS  : integer;
    C_USE_UART      : integer;
    C_UART_WIDTH    : integer := 8;
    C_USE_FSL       : integer := 0;
    C_FSL_DATA_SIZE : integer := 32;
    C_EN_WIDTH      : integer := 1
    );
  port (
    -- Global signals
    Clk : in std_logic;
    Rst : in std_logic;

    Clear_Ext_BRK : in  std_logic;
    Ext_BRK       : out std_logic;
    Ext_NM_BRK    : out std_logic := '0';
    Debug_SYS_Rst : out std_logic := '0';
    Debug_Rst     : out std_logic := '0';

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

end entity JTAG_CONTROL;


architecture IMP of JTAG_CONTROL is

  component SRL_FIFO is
    generic (
      C_DATA_BITS : natural;
      C_DEPTH     : natural);
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

  function log2(x : natural) return integer is
    variable i  : integer := 0;   
  begin 
    if x = 0 then return 0;
    else
      while 2**i < x loop
        i := i+1;
      end loop;
      return i;
    end if;
  end function log2;

  constant No_MicroBlazes : std_logic_vector(7 downto 0) :=
    std_logic_vector(to_unsigned(C_MB_DBG_PORTS, 8));
  constant No_HW_PORTS    : std_logic_vector(3 downto 0) := "0000";
  constant VERSION_I      : std_logic_vector(3 downto 0) := "0101";

  constant Config_Init_Word_S : std_logic_vector(15 downto 0) :=
    (No_MicroBlazes & No_HW_PORTS & VERSION_I);
  constant Config_Init_Word : bit_vector(15 downto 0) :=
    to_bitvector(Config_Init_Word_S);

  constant HAVE_UART    : std_logic_vector(0 to 0) :=
    std_logic_vector(to_unsigned(C_USE_UART, 1));
  constant UART_WIDTH   : std_logic_vector(0 to 4) :=
    std_logic_vector(to_unsigned(C_UART_WIDTH-1, 5));
  constant HAVE_FSL     : std_logic_vector(0 to 0) :=
    std_logic_vector(to_unsigned(C_USE_FSL, 1));
  constant MAGIC_STRING : std_logic_vector(0 to 7) := "01000010";
  
  constant Config_Init_Word2_S : std_logic_vector(15 downto 0) :=
    (MAGIC_STRING & HAVE_FSL & '0' & HAVE_UART & UART_WIDTH);
  constant Config_Init_Word2 : bit_vector(15 downto 0) :=
    to_bitvector(Config_Init_Word2_S);
  
  function itohex (int : natural; len : natural) return string is
    type     table is array (0 to 15) of character;
    constant LUT : table :=
      ('0', '1', '2', '3', '4', '5', '6', '7',
       '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
    variable str        : string(1 to len);
    variable rest, temp : natural;
  begin
    temp := int;
    for I in Len downto 1 loop
      rest   := temp mod 16;
      temp   := temp / 16;
      str(I) := LUT(rest);
    end loop;
    return str;
  end function itohex;

  signal config_TDO_1 : std_logic;
  signal config_TDO_2 : std_logic;
  signal config_TDO   : std_logic;

  attribute INIT : string;

  attribute INIT of SRL16E_1 : label is
    itohex(to_integer(unsigned(Config_Init_Word_S)), 4);
  attribute INIT of SRL16E_2 : label is
    itohex(to_integer(unsigned(Config_Init_Word2_S)), 4);

  -----------------------------------------------------------------------------
  -- JTAG signals
  -----------------------------------------------------------------------------
  signal tdi_reg : std_logic;
  
  signal data_cmd   : std_logic;
  signal data_cmd_n : std_logic;

  signal load_Command : std_logic;
  signal sel_n        : std_logic;

  signal command     : std_logic_vector(0 to 4);
  signal command_1   : std_logic_vector(0 to 4);
  signal tdi_shifter : std_logic_vector(0 to 7);
  
  signal Dbg_Reg_En_I  : std_logic_vector(0 to 4);

  signal shifting_Data : std_logic;
--  signal valid_reg_en : std_logic;
  
  signal   sync_word       : std_logic_vector(1 to 8);
  signal   sync_word_shift : std_logic_vector(0 to 8);
  signal   sync_detected   : std_logic;
  signal   sync            : std_logic;
  constant SYNC_CONST      : std_logic_vector(sync_word'range) := "01101001";

  signal Dbg_Update_I : std_logic;
  signal execute      : std_logic := '0';
  signal execute_1    : std_logic := '0';
  signal execute_2    : std_logic := '0';
  signal shift_Count  : std_logic_vector(4 downto 0) := (others => '0');
  
  -----------------------------------------------------------------------------
  -- Register handling
  -----------------------------------------------------------------------------
  constant MDM_DEBUG_ID          : std_logic_vector(0 to 4) := "00000";
  constant MB_WRITE_CONTROL      : std_logic_vector(0 to 4) := "00001";
  constant MB_WRITE_COMMAND      : std_logic_vector(0 to 4) := "00010";
  constant MB_READ_STATUS        : std_logic_vector(0 to 4) := "00011";
  constant MB_WRITE_INSTR        : std_logic_vector(0 to 4) := "00100";
  --constant MB_WRITE_DATA         : std_logic_vector(0 to 4) := "00101";
  constant MB_READ_DATA          : std_logic_vector(0 to 4) := "00110";
  constant MB_READ_CONFIG        : std_logic_vector(0 to 4) := "00111";
  constant MB_WRITE_BRK_RST_CTRL : std_logic_vector(0 to 4) := "01000";
  constant UART_WRITE_BYTE       : std_logic_vector(0 to 4) := "01001";
  constant UART_READ_STATUS      : std_logic_vector(0 to 4) := "01010";
  constant UART_READ_BYTE        : std_logic_vector(0 to 4) := "01011";
  constant MDM_READ_CONFIG       : std_logic_vector(0 to 4) := "01100";
  constant MDM_WRITE_WHICH_MB    : std_logic_vector(0 to 4) := "01101";
  constant MDM_READ_FROM_FSL     : std_logic_vector(0 to 4) := "01110";
  constant MDM_WRITE_TO_FSL      : std_logic_vector(0 to 4) := "01111";

  -- registers "10000" to "11111" are pc breakpoints 1-16
  
  signal uart_TDO : std_logic;
  
  signal tdo_reg    : std_logic_vector(0 to C_UART_WIDTH-1) := (others => '0');
  signal status_reg : std_logic_vector(0 to 7) := (others => '0');

  signal set_Ext_BRK : std_logic := '0';
  signal ext_BRK_i   : std_logic := '0';

  signal New_FSL_Data      : std_logic := '0';
  signal FSL_Write_OverRun : std_logic;
  signal FSL_Read_UnderRun : std_logic;
  
  -----------------------------------------------------------------------------
  -- FIFO signals
  -----------------------------------------------------------------------------
  function largest (A : integer; B : integer) return integer is
  begin
    if (A > B) then
      return A;
    else
      return B;
    end if;    
  end function largest;

  -- Sharing the shifting of data between the UART and FSL to save area
  constant Shift_Data_Size : integer := largest(C_UART_WIDTH, C_FSL_DATA_SIZE);
  
  signal fifo_Write        : std_logic := '0';
  signal fifo_Din          : std_logic_vector(0 to Shift_Data_Size-1);
  signal rx_Data_Present_I : std_logic := '0';
  signal rx_Buffer_Full_I  : std_logic := '0';

  signal fifo_Read         : std_logic := '0';
  signal fifo_DOut         : std_logic_vector(0 to C_UART_WIDTH-1);
  signal fifo_Data_Present : std_logic := '0';
  signal tx_Buffer_Full_I  : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Internal signals for debugging
  -----------------------------------------------------------------------------
  signal Ext_NM_BRK_i    : std_logic := '0';
  signal Debug_SYS_Rst_i : std_logic := '0';
  signal Debug_Rst_i     : std_logic := '0';

  signal ID_TDO : std_logic;
  signal ID_TDO_1 : std_logic;  
  signal ID_TDO_2 : std_logic;
  
  constant ID_Init_Word1 : bit_vector(15 downto 0) := x"4443"; -- Ascii
  constant ID_Init_Word2 : bit_vector(15 downto 0) := x"584D"; -- "XMDC"

begin  -- architecture IMP

--   TDI_Sampling : process (DRCK) is
--   begin  -- process TDI_Sampling
--     if DRCK'event and DRCK = '1' then   -- rising clock edge
--       tdi_reg <= TDI;
--     end if;
--   end process TDI_Sampling;

  -- JECE: Removed the input register
  tdi_reg <= TDI;
  
  -----------------------------------------------------------------------------
  -- Control logic
  -----------------------------------------------------------------------------

  -- data_cmd | meaning
  -- ======================
  --     0    | Command phase
  --     1    | Data phase    

--  FDC_I : FDC
  FDC_I : FDC_1
    port map (
      Q   => data_cmd,                  -- [out std_logic]
      C   => Update,                    -- [in  std_logic]
      D   => data_cmd_n,                -- [in  std_logic]
      CLR => sel_n);                    -- [in std_logic]

  data_cmd_n <= not data_cmd;

  load_Command <= SHIFT and not data_cmd;
  sel_n        <= not SEL;

  -----------------------------------------------------------------------------
  -- Command shifter
  -----------------------------------------------------------------------------
--   command_shift(0) <= tdi_reg;
  
--   Command_Regs : for I in 1 to No_Cmd_Bits generate

--     ShiftIn_Command_FDRE : FDRE
--       port map (
--         Q  => command_shift(I),         -- [out std_logic]
--         C  => DRCK,                     -- [in  std_logic]
--         CE => load_Command,             -- [in  std_logic]
--         D  => command_shift(I-1),       -- [in  std_logic]
--         R  => sel_n);                   -- [in std_logic]

--     Command_FDE : FDE
--       port map (
--         Q  => command(I),               -- [out std_logic]
--         C  => DRCK,                     -- [in  std_logic]
--         CE => data_cmd,                 -- [in  std_logic]
--         D  => command_shift(I)          -- [in  std_logic]
--       );
    
--   end generate Command_Regs;
    
--    Command_shifter: process (DRCK)
--    begin
--      if sel_n = '1' then
--        command_shift <= (others => '0');
--      else
--        if DRCK'event and DRCK = '1' then
--          if load_command = '1' then
--            command_shift <= tdi_reg & command_shift(0 to 3);
--          end if;
--        end if;
--      end if;
--    end process Command_shifter;
  
--    Command_update: process (UPDATE)
--    begin
--      if DRCK'event and DRCK = '1' then
--        if data_cmd = '1' then
--          command <= command_shift (0 to 4);
--        end if;
--      end if;
--    end process Command_update;
  
  Input_shifter: process (DRCK)
  begin
    if DRCK'event and DRCK = '1' then
      if SEL = '1' and SHIFT = '1' then
        tdi_shifter <= TDI & tdi_shifter(0 to 6);
      end if;
    end if;
  end process Input_shifter;

  Command_update: process (UPDATE)
  begin
    if UPDATE'event and UPDATE = '0' then
      if SEL = '1' then
        command <= command_1;
      end if;
    end if;
  end process Command_update;        

  Command_update_1: process (UPDATE)
  begin
    if UPDATE'event and UPDATE = '1' then
      if SEL = '1' and data_cmd = '0' then
        command_1 <= tdi_shifter (0 to 4);
      end if;
    end if;
  end process Command_update_1;

  Dbg_Clk      <= DRCK;   
  Dbg_Reg_En_I <= command when data_cmd = '1' else "00000";
  Dbg_Reg_En   <= Dbg_Reg_En_I;
  Dbg_TDI      <= tdi_reg;
  Dbg_Capture  <= CAPTURE;
  Dbg_Update_I <= UPDATE;
  Dbg_Update   <= Dbg_Update_I;

  -- shifting_Data <= SHIFT and sync;
  -- JECE: Removed the sync word requirement for commands other than "Write
  -- Instruction"
  shifting_Data <= (SHIFT and sync)
                   when (command = MB_WRITE_INSTR) and (data_cmd = '1')
                   else SHIFT;

  Dbg_Shift    <= shifting_Data;
  
  -----------------------------------------------------------------------------
  -- Shift in and try to detect the Sync Word
  -----------------------------------------------------------------------------
--   sync_word_shift(0) <= tdi_reg;

--   Sync_Word_Regs : for I in sync_word'range generate
--     Sync_Word_FDR : FDR
--       port map (
--         Q => sync_word_shift(I),
--         C => DRCK,              
--         D => sync_word_shift(I-1),
--         R => data_cmd_n);         
--   end generate Sync_Word_Regs;

--   sync_word <= sync_word_shift(sync_word'range);

--   sync_detected <= '1' when sync_word = SYNC_CONST else '0';

  sync_detected <= '1' when tdi_shifter(0 to 7) = SYNC_CONST and data_cmd = '1'
                   else '0';

--   SYNC_FDRE : FDRE
--     port map (
--       Q  => sync,                 
--       C  => DRCK,                 
--       CE => sync_detected,        
--       D  => '1',                  
--       R  => data_cmd_n);          

  SYNC_FDRE : FDRE_1
    port map (
      Q  => sync,                 
      C  => DRCK,                 
      CE => sync_detected,        
      D  => '1',                  
      R  => data_cmd_n);          

--    SYNC_FDCP : FDCP
--      port map (
--        Q  => sync,
--        C  => '0',
--        CLR => data_cmd_n,        
--        D  => '0',
--        PRE  => sync_detected);
  
  -----------------------------------------------------------------------------
  -- Shift Counter
  -----------------------------------------------------------------------------
  -- Keep a counter on the number of bits in the data phase after a sync has
  -- been detected
  Shift_Counter : process (DRCK, Reset) is
  begin --  process Shift_Counter
    if DRCK'event and DRCK = '1' then  -- rising clock edge
      if SHIFT = '0' then
        shift_Count <= (others => '0');
      else
        shift_Count <= std_logic_vector(unsigned(Shift_Count) + 1);
      end if;
    end if;
  end process Shift_Counter;

  -----------------------------------------------------------------------------
  -- TDI Register
  -----------------------------------------------------------------------------
  TDI_Register : process (DRCK) is
  begin  -- process TDI_Register
    if DRCK'event and DRCK = '1' then   -- rising clock edge
      if shifting_Data = '1' then
        fifo_Din(fifo_Din'left+1 to fifo_Din'right) <=
          fifo_Din(fifo_Din'left to fifo_Din'right-1);
        fifo_Din(0)      <= tdi_reg;
      end if;
    end if;
  end process TDI_Register;

  -----------------------------------------------------------------------------
  -- Config Register
  -----------------------------------------------------------------------------
  SRL16E_1 : SRL16E
    generic map (
      INIT => Config_Init_Word
      )
    port map (
      CE  => '0',                       -- [in  std_logic]
      D   => '0',                       -- [in  std_logic]
      Clk => DRCK,                      -- [in  std_logic]
      A0  => shift_Count(0),            -- [in  std_logic]
      A1  => shift_Count(1),            -- [in  std_logic]
      A2  => shift_Count(2),            -- [in  std_logic]
      A3  => shift_Count(3),            -- [in  std_logic]
      Q   => config_TDO_1);             --   [out std_logic]

  SRL16E_2 : SRL16E
    generic map (
      INIT => Config_Init_Word2
      )
    port map (
      CE  => '0',                       -- [in  std_logic]
      D   => '0',                       -- [in  std_logic]
      Clk => DRCK,                      -- [in  std_logic]
      A0  => shift_Count(0),            -- [in  std_logic]
      A1  => shift_Count(1),            -- [in  std_logic]
      A2  => shift_Count(2),            -- [in  std_logic]
      A3  => shift_Count(3),            -- [in  std_logic]
      Q   => config_TDO_2);             --   [out std_logic]

  config_TDO <= config_TDO_1 when shift_Count(4) = '0' else config_TDO_2;

  -----------------------------------------------------------------------------
  -- ID Regsiter
  -----------------------------------------------------------------------------
  SRL16E_ID_1 : SRL16E
    generic map (
      INIT => ID_Init_Word1
    )
    port map (
      CE  => '0',
      D   => '0',
      Clk => DRCK,
      A0  => shift_Count(0),
      A1  => shift_Count(1),
      A2  => shift_Count(2),
      A3  => shift_Count(3),
      Q   => ID_TDO_1);
  
  SRL16E_ID_2 : SRL16E
    generic map (
      INIT => ID_Init_Word2
    )
    port map (
      CE  => '0',
      D   => '0',
      Clk => DRCK,
      A0  => shift_Count(0),
      A1  => shift_Count(1),
      A2  => shift_Count(2),
      A3  => shift_Count(3),
      Q   => ID_TDO_2);
  
  ID_TDO <= ID_TDO_1 when shift_Count(4) = '0' else ID_TDO_2;

  -----------------------------------------------------------------------------
  -- TDO Mux
  -----------------------------------------------------------------------------
  with command select
    tdo <=
    ID_TDO     when MDM_DEBUG_ID,
    uart_TDO   when UART_READ_BYTE,
    uart_TDO   when UART_READ_STATUS,
    config_TDO when MDM_READ_CONFIG,
    Dbg_TDO    when others;

  -----------------------------------------------------------------------------
  -- Handling the Which_MB register
  -----------------------------------------------------------------------------
  More_Than_One_MB: if (C_MB_DBG_PORTS > 1) generate
    signal Which_MB_Reg_En : std_logic;
    signal Which_MB_Reg    : std_logic_vector(7 downto 0);
  begin

    Which_MB_Reg_Handle : process (UPDATE)
    begin 
      if UPDATE'event and UPDATE = '0' then
        if SEL = '1' and data_cmd = '1' and command = MDM_WRITE_WHICH_MB then
          Which_MB_Reg <= tdi_shifter(0 to 7);
        end if;
      end if;
    end process Which_MB_Reg_Handle;

    MB_Debug_Enabled(C_MB_DBG_PORTS-1 downto 0) <=
      Which_MB_Reg(C_MB_DBG_PORTS-1 downto 0);

  end generate More_Than_One_MB;

  Only_One_MB: if (C_MB_DBG_PORTS = 1) generate
    MB_Debug_Enabled(0) <= '1';
  end generate Only_One_MB;

  No_MB: if (C_MB_DBG_PORTS = 0) generate
    MB_Debug_Enabled(0) <= '0';
  end generate No_MB;

  -----------------------------------------------------------------------------
  -- Reset Control
  -----------------------------------------------------------------------------
  Reset_Control: process (UPDATE)
  begin  -- process Reset_Control
    if UPDATE'event and UPDATE = '1' then
      if command = MB_WRITE_BRK_RST_CTRL and data_cmd = '1' then
        Debug_Rst_i     <= tdi_shifter(0);
        Debug_SYS_Rst_i <= tdi_shifter(1);
        set_Ext_BRK     <= tdi_shifter(2);
        Ext_NM_BRK_i    <= tdi_shifter(3);        
      end if;
    end if;
  end process Reset_Control;

  -----------------------------------------------------------------------------
  -- Execute Commands
  -----------------------------------------------------------------------------
    Execute_UART_Command : process (UPDATE, data_cmd)
  begin  -- process Execute_UART_Command
    if data_cmd = '0' then 
      execute <= '0';
    elsif UPDATE = '1' then
      if (command = UART_READ_BYTE) or
        (command = UART_WRITE_BYTE) then
        execute <= '1';
      else
        execute <= '0';
      end if;
    end if;
  end process Execute_UART_Command;

  Execute_FIFO_Command : process (Clk)
  begin  -- process Execute_FIFO_Command
    if Clk'event and Clk = '1' then
      fifo_Write  <= '0';
      fifo_Read   <= '0';
      if (execute_2 = '0') and (execute_1 = '1') then
        if (command = UART_WRITE_BYTE) then
          fifo_Write <= '1';
        end if;
        if (command = UART_READ_BYTE) then
          fifo_Read <= '1';
        end if;
      end if;
      execute_2 <= execute_1;
      execute_1 <= execute;
    end if;
  end process Execute_FIFO_Command;

  Debug_SYS_Rst <= Debug_SYS_Rst_i;
  Debug_Rst     <= Debug_Rst_i;
  Ext_NM_BRK    <= Ext_NM_BRK_i;
  
  Ext_BRK_FDRSE : FDRSE
    port map (
      Q  => ext_BRK_i,                 --  [out std_logic]
      C  => Clk,                       --  [in  std_logic]
      CE => '0',                       --  [in  std_logic]
      D  => '0',                       --  [in  std_logic]
      R  => Clear_Ext_BRK,             --  [in  std_logic]
      S  => set_Ext_BRK);              --  [in std_logic]

  Ext_BRK <= ext_BRK_i;

  -----------------------------------------------------------------------------
  -- UART section
  -----------------------------------------------------------------------------

  -- Since only one bit can change in the status register at time
  -- we don't need to synchronize them with the DRCK clock
  status_reg(7) <= fifo_Data_Present;
  status_reg(6) <= tx_Buffer_Full_I;
  status_reg(5) <= not rx_Data_Present_I;
  status_reg(4) <= rx_Buffer_Full_I;
  status_reg(3) <= FSL0_S_Exists;
  status_reg(2) <= FSL0_M_Full;
  status_reg(1) <= FSL_Read_UnderRun;
  status_reg(0) <= FSL_Write_OverRun;

  -- Not currently used
  FSL_Read_UnderRun <= '0';
  
  No_UART_2 : if (C_USE_UART = 0) generate
    uart_TDO <= '0';
  end generate No_UART_2;

  Have_UARTs : if (C_USE_UART = 1) generate

    -- Read UART registers
    TDO_Register : process (DRCK) is
    begin  -- process TDO_Register
      if DRCK'event and DRCK = '1' then  -- rising clock edge
        if (CAPTURE = '1') then
          case Command is
            when UART_READ_STATUS =>
               tdo_reg                                                     <= (others => '0');
               tdo_reg(tdo_reg'right-status_reg'length+1 to tdo_reg'right) <= status_reg;
            when others =>
              tdo_reg <= fifo_DOut;
          end case;
        elsif SHIFT = '1' then
          tdo_reg <= '0' & tdo_reg(tdo_reg'left to tdo_reg'right-1);
        end if;
      end if;
    end process TDO_Register;
    
    uart_TDO <= tdo_reg(tdo_reg'right);

    ---------------------------------------------------------------------------
    -- FIFO
    ---------------------------------------------------------------------------
    RX_FIFO_I : SRL_FIFO
      generic map (
        C_DATA_BITS => C_UART_WIDTH,    -- [natural]
        C_DEPTH     => 16)              -- [natural]
      port map (
        Clk         => Clk,             -- [in  std_logic]
        Reset       => Reset_RX_FIFO,   -- [in  std_logic]
        FIFO_Write  => fifo_Write,      -- [in  std_logic]
        Data_In     => fifo_Din(0 to C_UART_WIDTH-1),  -- [in  std_logic_vector(0 to C_DATA_BITS-1)]
        FIFO_Read   => Read_RX_FIFO,    -- [in  std_logic]
        Data_Out    => RX_Data,  -- [out std_logic_vector(0 to C_DATA_BITS-1)]
        FIFO_Full   => rx_Buffer_Full_I,               -- [out std_logic]
        Data_Exists => rx_Data_Present_I);             -- [out std_logic]

    RX_Data_Present <= rx_Data_Present_I;
    RX_Buffer_Full  <= rx_Buffer_Full_I;

    TX_FIFO_I : SRL_FIFO
      generic map (
        C_DATA_BITS => C_UART_WIDTH,    -- [natural]
        C_DEPTH     => 16)              -- [natural]
      port map (
        Clk         => Clk,             -- [in  std_logic]
        Reset       => Reset_TX_FIFO,   -- [in  std_logic]
        FIFO_Write  => Write_TX_FIFO,   -- [in  std_logic]
        Data_In     => TX_Data,  -- [in  std_logic_vector(0 to C_DATA_BITS-1)]
        FIFO_Read   => fifo_Read,       -- [in  std_logic]
        Data_Out    => fifo_DOut,  -- [out std_logic_vector(0 to C_DATA_BITS-1)]
        FIFO_Full   => TX_Buffer_Full_I,    -- [out std_logic]
        Data_Exists => fifo_Data_Present);  -- [out std_logic]

    TX_Buffer_Full  <= TX_Buffer_Full_I;
    TX_Buffer_Empty <= not fifo_Data_Present;
  end generate Have_UARTs;

  -----------------------------------------------------------------------------
  -- FSL handling
  -----------------------------------------------------------------------------
  Use_FSL: if (C_USE_FSL /= 0) generate
    signal New_FSL_Data      : std_logic := '0';
    signal Write_to_FSL_En   : std_logic;
    signal FSL_Data_DRCK     : std_logic_vector(0 to C_FSL_DATA_SIZE-1);
    -- signal Cnt_31            : std_logic := '0';
    signal Cnt_32            : std_logic := '0';
  begin

    -- Currently no FSL slave interface
    FSL0_S_Clk     <= '0';
    FSL0_S_Read    <= '0';

--    Write_to_FSL_En <= '1' when (Command = MDM_WRITE_TO_FSL) else '0';
    Write_to_FSL_En <= '1' when (command = MDM_WRITE_TO_FSL) and data_cmd = '1'
                       else '0';

--     New_Data: process (DRCK) is
--     begin  -- process New_Data
--       if DRCK'event and DRCK = '1' then  -- rising clock edge
--         Cnt_32 <= '0';
--         New_FSL_Data <= '0';
--         if (shift_Count(4 downto 0) = "11111") then  -- Counted 31 tim
--           Cnt_32 <= Write_to_FSL_En;
--         end if;
--         if (Cnt_32 = '1') then
--           New_FSL_Data <= Write_to_FSL_En;
--           FSL_Data_DRCK <= fifo_Din(0 to C_FSL_DATA_SIZE-1);
--         end if;
--       end if;
--     end process New_Data;

    New_Data: process (DRCK) is
    begin  -- process New_Data
      if DRCK'event and DRCK = '1' then  -- rising clock edge
        Cnt_32 <= '0';
        New_FSL_Data <= '0';
        if (shift_Count(4 downto 0) = "11111") then  -- Counted 31 tim
          Cnt_32 <= Write_to_FSL_En;
        end if;
        if (Cnt_32 = '1') then
          New_FSL_Data <= Write_to_FSL_En;
          FSL_Data_DRCK <= fifo_Din(0 to C_FSL_DATA_SIZE-1);
        end if;
      end if;
    end process New_Data;

    ---------------------------------------------------------------------------
    -- Write to FSL, assumes that Clk is faster than JTAG Clock
    ---------------------------------------------------------------------------
    Write_FSL_Data: process (Clk, Rst) is
      variable prev1 : std_logic;
      variable prev2 : std_logic;
    begin  -- process Write_FSL_Data
      if Rst = '1' then               -- asynchronous reset (active high)
        FSL0_M_Write <= '0';
        prev1 := '0';
        prev2 := '0';
      elsif Clk'event and Clk = '1' then  -- rising clock edge
        FSL0_M_Write <= '0';
        if (prev2 = '0' and prev1 = '1') then
          FSL0_M_Write <= '1';
        end if;
        prev2 := prev1;
        prev1 := New_FSL_Data;
      end if;
    end process Write_FSL_Data;

    FSL0_M_Data <= FSL_Data_DRCK;       -- Will change every 32 JTAG clock so
                                        -- it safe to use it to write in the
                                        -- OPB clock domain since the write
                                        -- strobe is delayed at least one
                                        -- Clk after the data changes
    FSL0_M_Clk <= Clk;
    FSL0_M_Control <= '0';              -- No control mechanism yet

    OverRun_Register : process (DRCK) is
    begin  -- process OverRun_Register
      if DRCK'event and DRCK = '1' then  -- rising clock edge
        if (shifting_Data = '1') and ( Command = UART_READ_STATUS) then
          FSL_Write_OverRun <= '0';
        end if;
        if (New_FSL_Data = '1' and FSL0_M_Full = '1') then
          FSL_Write_OverRun <= '1';
        end if;
      end if;
    end process OverRun_Register;
    
  end generate Use_FSL;
  

  No_FSL : if (C_USE_FSL = 0) generate
    FSL0_S_Clk     <= '0';
    FSL0_S_Read    <= '0';
    FSL0_M_Clk     <= '0';
    FSL0_M_Write   <= '0';
    FSL0_M_Data    <= (others => '0');
    FSL0_M_Control <= '0';
    FSL_Write_OverRun <= '0';
  end generate No_FSL;
  
end architecture IMP;



