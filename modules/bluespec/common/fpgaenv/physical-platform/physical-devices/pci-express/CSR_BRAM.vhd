--------------------------------------------------------------------------------
-- Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: J.39
--  \   \         Application: netgen
--  /   /         Filename: CSR_BRAM.vhd
-- /___/   /\     Timestamp: Fri Jan 18 15:52:05 2008
-- \   \  /  \ 
--  \___\/\___\
--             
-- Command	: -intstyle ise -w -sim -ofmt vhdl C:\lwang\Projects\HW_Channel(CSR)\HW_Channel(01.18)(50t)\tmp\_cg\CSR_BRAM.ngc C:\lwang\Projects\HW_Channel(CSR)\HW_Channel(01.18)(50t)\tmp\_cg\CSR_BRAM.vhd 
-- Device	: 5vlx50tff1136-1
-- Input file	: C:/lwang/Projects/HW_Channel(CSR)/HW_Channel(01.18)(50t)/tmp/_cg/CSR_BRAM.ngc
-- Output file	: C:/lwang/Projects/HW_Channel(CSR)/HW_Channel(01.18)(50t)/tmp/_cg/CSR_BRAM.vhd
-- # of Entities	: 1
-- Design Name	: CSR_BRAM
-- Xilinx	: C:\Xilinx92i
--             
-- Purpose:    
--     This VHDL netlist is a verification model and uses simulation 
--     primitives which may not represent the true implementation of the 
--     device, however the netlist is functionally correct and should not 
--     be modified. This file cannot be synthesized and should only be used 
--     with supported simulation tools.
--             
-- Reference:  
--     Development System Reference Guide, Chapter 23
--     Synthesis and Simulation Design Guide, Chapter 6
--             
--------------------------------------------------------------------------------


-- synopsys translate_off
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
use UNISIM.VPKG.ALL;

entity CSR_BRAM is
  port (
    ena : in STD_LOGIC := 'X'; 
    enb : in STD_LOGIC := 'X'; 
    clka : in STD_LOGIC := 'X'; 
    clkb : in STD_LOGIC := 'X'; 
    wea : in STD_LOGIC_VECTOR ( 0 downto 0 ); 
    addra : in STD_LOGIC_VECTOR ( 7 downto 0 ); 
    addrb : in STD_LOGIC_VECTOR ( 7 downto 0 ); 
    doutb : out STD_LOGIC_VECTOR ( 31 downto 0 ); 
    dina : in STD_LOGIC_VECTOR ( 31 downto 0 ) 
  );
end CSR_BRAM;

architecture STRUCTURE of CSR_BRAM is
  signal BU2_N2 : STD_LOGIC; 
  signal NLW_VCC_P_UNCONNECTED : STD_LOGIC; 
  signal NLW_GND_G_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_WIDE_PRIM18_TDP_DOP_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_WIDE_PRIM18_TDP_DOP_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_WIDE_PRIM18_TDP_DOP_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_WIDE_PRIM18_TDP_DOP_0_UNCONNECTED : STD_LOGIC; 
  signal dina_2 : STD_LOGIC_VECTOR ( 31 downto 0 ); 
  signal addra_3 : STD_LOGIC_VECTOR ( 7 downto 0 ); 
  signal wea_4 : STD_LOGIC_VECTOR ( 0 downto 0 ); 
  signal addrb_5 : STD_LOGIC_VECTOR ( 7 downto 0 ); 
  signal doutb_6 : STD_LOGIC_VECTOR ( 31 downto 0 ); 
  signal BU2_douta : STD_LOGIC_VECTOR ( 0 downto 0 ); 
begin
  wea_4(0) <= wea(0);
  addra_3(7) <= addra(7);
  addra_3(6) <= addra(6);
  addra_3(5) <= addra(5);
  addra_3(4) <= addra(4);
  addra_3(3) <= addra(3);
  addra_3(2) <= addra(2);
  addra_3(1) <= addra(1);
  addra_3(0) <= addra(0);
  addrb_5(7) <= addrb(7);
  addrb_5(6) <= addrb(6);
  addrb_5(5) <= addrb(5);
  addrb_5(4) <= addrb(4);
  addrb_5(3) <= addrb(3);
  addrb_5(2) <= addrb(2);
  addrb_5(1) <= addrb(1);
  addrb_5(0) <= addrb(0);
  doutb(31) <= doutb_6(31);
  doutb(30) <= doutb_6(30);
  doutb(29) <= doutb_6(29);
  doutb(28) <= doutb_6(28);
  doutb(27) <= doutb_6(27);
  doutb(26) <= doutb_6(26);
  doutb(25) <= doutb_6(25);
  doutb(24) <= doutb_6(24);
  doutb(23) <= doutb_6(23);
  doutb(22) <= doutb_6(22);
  doutb(21) <= doutb_6(21);
  doutb(20) <= doutb_6(20);
  doutb(19) <= doutb_6(19);
  doutb(18) <= doutb_6(18);
  doutb(17) <= doutb_6(17);
  doutb(16) <= doutb_6(16);
  doutb(15) <= doutb_6(15);
  doutb(14) <= doutb_6(14);
  doutb(13) <= doutb_6(13);
  doutb(12) <= doutb_6(12);
  doutb(11) <= doutb_6(11);
  doutb(10) <= doutb_6(10);
  doutb(9) <= doutb_6(9);
  doutb(8) <= doutb_6(8);
  doutb(7) <= doutb_6(7);
  doutb(6) <= doutb_6(6);
  doutb(5) <= doutb_6(5);
  doutb(4) <= doutb_6(4);
  doutb(3) <= doutb_6(3);
  doutb(2) <= doutb_6(2);
  doutb(1) <= doutb_6(1);
  doutb(0) <= doutb_6(0);
  dina_2(31) <= dina(31);
  dina_2(30) <= dina(30);
  dina_2(29) <= dina(29);
  dina_2(28) <= dina(28);
  dina_2(27) <= dina(27);
  dina_2(26) <= dina(26);
  dina_2(25) <= dina(25);
  dina_2(24) <= dina(24);
  dina_2(23) <= dina(23);
  dina_2(22) <= dina(22);
  dina_2(21) <= dina(21);
  dina_2(20) <= dina(20);
  dina_2(19) <= dina(19);
  dina_2(18) <= dina(18);
  dina_2(17) <= dina(17);
  dina_2(16) <= dina(16);
  dina_2(15) <= dina(15);
  dina_2(14) <= dina(14);
  dina_2(13) <= dina(13);
  dina_2(12) <= dina(12);
  dina_2(11) <= dina(11);
  dina_2(10) <= dina(10);
  dina_2(9) <= dina(9);
  dina_2(8) <= dina(8);
  dina_2(7) <= dina(7);
  dina_2(6) <= dina(6);
  dina_2(5) <= dina(5);
  dina_2(4) <= dina(4);
  dina_2(3) <= dina(3);
  dina_2(2) <= dina(2);
  dina_2(1) <= dina(1);
  dina_2(0) <= dina(0);
  VCC_0 : VCC
    port map (
      P => NLW_VCC_P_UNCONNECTED
    );
  GND_1 : GND
    port map (
      G => NLW_GND_G_UNCONNECTED
    );
  BU2_XST_VCC : VCC
    port map (
      P => BU2_N2
    );
  BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_WIDE_PRIM18_TDP : RAMB18SDP
    generic map(
      DO_REG => 0,
      INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_00 => X"0000000600000007000000040000000500000002000000030000000000000001",
      INIT_01 => X"0000000E0000000F0000000C0000000D0000000A0000000B0000000800000009",
      INIT_02 => X"0000001600000017000000140000001500000012000000130000001000000011",
      INIT_03 => X"0000001E0000001F0000001C0000001D0000001A0000001B0000001800000019",
      INIT_04 => X"0000002600000027000000240000002500000022000000230000002000000021",
      INIT_05 => X"0000002E0000002F0000002C0000002D0000002A0000002B0000002800000029",
      INIT_06 => X"0000000000000000000000000000000000000000000000000000003000000031",
      INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_FILE => "NONE",
      INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT => X"000000000",
      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      SIM_COLLISION_CHECK => "ALL",
      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      SRVAL => X"000000000"
    )
    port map (
      RDCLK => clkb,
      WRCLK => clka,
      RDEN => enb,
      WREN => ena,
      REGCE => BU2_douta(0),
      SSR => BU2_douta(0),
      RDADDR(8) => BU2_douta(0),
      RDADDR(7) => addrb_5(7),
      RDADDR(6) => addrb_5(6),
      RDADDR(5) => addrb_5(5),
      RDADDR(4) => addrb_5(4),
      RDADDR(3) => addrb_5(3),
      RDADDR(2) => addrb_5(2),
      RDADDR(1) => addrb_5(1),
      RDADDR(0) => addrb_5(0),
      WRADDR(8) => BU2_douta(0),
      WRADDR(7) => addra_3(7),
      WRADDR(6) => addra_3(6),
      WRADDR(5) => addra_3(5),
      WRADDR(4) => addra_3(4),
      WRADDR(3) => addra_3(3),
      WRADDR(2) => addra_3(2),
      WRADDR(1) => addra_3(1),
      WRADDR(0) => addra_3(0),
      DI(31) => dina_2(31),
      DI(30) => dina_2(30),
      DI(29) => dina_2(29),
      DI(28) => dina_2(28),
      DI(27) => dina_2(27),
      DI(26) => dina_2(26),
      DI(25) => dina_2(25),
      DI(24) => dina_2(24),
      DI(23) => dina_2(23),
      DI(22) => dina_2(22),
      DI(21) => dina_2(21),
      DI(20) => dina_2(20),
      DI(19) => dina_2(19),
      DI(18) => dina_2(18),
      DI(17) => dina_2(17),
      DI(16) => dina_2(16),
      DI(15) => dina_2(15),
      DI(14) => dina_2(14),
      DI(13) => dina_2(13),
      DI(12) => dina_2(12),
      DI(11) => dina_2(11),
      DI(10) => dina_2(10),
      DI(9) => dina_2(9),
      DI(8) => dina_2(8),
      DI(7) => dina_2(7),
      DI(6) => dina_2(6),
      DI(5) => dina_2(5),
      DI(4) => dina_2(4),
      DI(3) => dina_2(3),
      DI(2) => dina_2(2),
      DI(1) => dina_2(1),
      DI(0) => dina_2(0),
      DIP(3) => BU2_douta(0),
      DIP(2) => BU2_douta(0),
      DIP(1) => BU2_douta(0),
      DIP(0) => BU2_douta(0),
      DO(31) => doutb_6(31),
      DO(30) => doutb_6(30),
      DO(29) => doutb_6(29),
      DO(28) => doutb_6(28),
      DO(27) => doutb_6(27),
      DO(26) => doutb_6(26),
      DO(25) => doutb_6(25),
      DO(24) => doutb_6(24),
      DO(23) => doutb_6(23),
      DO(22) => doutb_6(22),
      DO(21) => doutb_6(21),
      DO(20) => doutb_6(20),
      DO(19) => doutb_6(19),
      DO(18) => doutb_6(18),
      DO(17) => doutb_6(17),
      DO(16) => doutb_6(16),
      DO(15) => doutb_6(15),
      DO(14) => doutb_6(14),
      DO(13) => doutb_6(13),
      DO(12) => doutb_6(12),
      DO(11) => doutb_6(11),
      DO(10) => doutb_6(10),
      DO(9) => doutb_6(9),
      DO(8) => doutb_6(8),
      DO(7) => doutb_6(7),
      DO(6) => doutb_6(6),
      DO(5) => doutb_6(5),
      DO(4) => doutb_6(4),
      DO(3) => doutb_6(3),
      DO(2) => doutb_6(2),
      DO(1) => doutb_6(1),
      DO(0) => doutb_6(0),
      DOP(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_WIDE_PRIM18_TDP_DOP_3_UNCONNECTED,
      DOP(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_WIDE_PRIM18_TDP_DOP_2_UNCONNECTED,
      DOP(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_WIDE_PRIM18_TDP_DOP_1_UNCONNECTED,
      DOP(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_WIDE_PRIM18_TDP_DOP_0_UNCONNECTED,
      WE(3) => wea_4(0),
      WE(2) => wea_4(0),
      WE(1) => wea_4(0),
      WE(0) => wea_4(0)
    );
  BU2_XST_GND : GND
    port map (
      G => BU2_douta(0)
    );

end STRUCTURE;

-- synopsys translate_on
