--------------------------------------------------------------------------------
-- Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: J.39
--  \   \         Application: netgen
--  /   /         Filename: ram.vhd
-- /___/   /\     Timestamp: Wed Jan 23 14:21:25 2008
-- \   \  /  \ 
--  \___\/\___\
--             
-- Command	: -intstyle ise -w -sim -ofmt vhdl C:\lwang\Projects\HW_Channel\HW_Channel(01.23)\tmp\_cg\ram.ngc C:\lwang\Projects\HW_Channel\HW_Channel(01.23)\tmp\_cg\ram.vhd 
-- Device	: 5vlx110tff1136-1
-- Input file	: C:/lwang/Projects/HW_Channel/HW_Channel(01.23)/tmp/_cg/ram.ngc
-- Output file	: C:/lwang/Projects/HW_Channel/HW_Channel(01.23)/tmp/_cg/ram.vhd
-- # of Entities	: 1
-- Design Name	: ram
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

entity ram is
  port (
    ena : in STD_LOGIC := 'X'; 
    enb : in STD_LOGIC := 'X'; 
    clka : in STD_LOGIC := 'X'; 
    clkb : in STD_LOGIC := 'X'; 
    wea : in STD_LOGIC_VECTOR ( 0 downto 0 ); 
    addra : in STD_LOGIC_VECTOR ( 10 downto 0 ); 
    addrb : in STD_LOGIC_VECTOR ( 10 downto 0 ); 
    doutb : out STD_LOGIC_VECTOR ( 63 downto 0 ); 
    dina : in STD_LOGIC_VECTOR ( 63 downto 0 ) 
  );
end ram;

architecture STRUCTURE of ram is
  signal BU2_N2 : STD_LOGIC; 
  signal NLW_VCC_P_UNCONNECTED : STD_LOGIC; 
  signal NLW_GND_G_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATA_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATB_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGA_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGB_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_31_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_30_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_29_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_28_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_27_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_26_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_25_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_24_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_23_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_22_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_21_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_20_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_19_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_18_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_17_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_16_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_15_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_14_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_13_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_12_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_11_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_10_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_9_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_8_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_31_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_30_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_29_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_28_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_27_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_26_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_25_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_24_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_23_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_22_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_21_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_20_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_19_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_18_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_17_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_16_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATA_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATB_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGA_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGB_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_31_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_30_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_29_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_28_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_27_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_26_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_25_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_24_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_23_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_22_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_21_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_20_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_19_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_18_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_17_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_16_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_15_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_14_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_13_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_12_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_11_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_10_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_9_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_8_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_31_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_30_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_29_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_28_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_27_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_26_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_25_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_24_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_23_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_22_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_21_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_20_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_19_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_18_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_17_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_16_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATA_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATB_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGA_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGB_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_31_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_30_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_29_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_28_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_27_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_26_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_25_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_24_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_23_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_22_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_21_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_20_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_19_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_18_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_17_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_16_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_15_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_14_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_13_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_12_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_11_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_10_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_9_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_8_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_31_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_30_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_29_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_28_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_27_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_26_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_25_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_24_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_23_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_22_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_21_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_20_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_19_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_18_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_17_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_16_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATA_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATB_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGA_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGB_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_31_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_30_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_29_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_28_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_27_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_26_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_25_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_24_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_23_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_22_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_21_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_20_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_19_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_18_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_17_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_16_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_15_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_14_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_13_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_12_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_11_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_10_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_9_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_8_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_4_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_0_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_31_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_30_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_29_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_28_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_27_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_26_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_25_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_24_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_23_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_22_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_21_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_20_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_19_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_18_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_17_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_16_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_15_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_14_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_13_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_7_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_6_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_5_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_0_UNCONNECTED : STD_LOGIC; 
  signal dina_2 : STD_LOGIC_VECTOR ( 63 downto 0 ); 
  signal addra_3 : STD_LOGIC_VECTOR ( 10 downto 0 ); 
  signal wea_4 : STD_LOGIC_VECTOR ( 0 downto 0 ); 
  signal addrb_5 : STD_LOGIC_VECTOR ( 10 downto 0 ); 
  signal doutb_6 : STD_LOGIC_VECTOR ( 63 downto 0 ); 
  signal BU2_douta : STD_LOGIC_VECTOR ( 0 downto 0 ); 
begin
  wea_4(0) <= wea(0);
  addra_3(10) <= addra(10);
  addra_3(9) <= addra(9);
  addra_3(8) <= addra(8);
  addra_3(7) <= addra(7);
  addra_3(6) <= addra(6);
  addra_3(5) <= addra(5);
  addra_3(4) <= addra(4);
  addra_3(3) <= addra(3);
  addra_3(2) <= addra(2);
  addra_3(1) <= addra(1);
  addra_3(0) <= addra(0);
  addrb_5(10) <= addrb(10);
  addrb_5(9) <= addrb(9);
  addrb_5(8) <= addrb(8);
  addrb_5(7) <= addrb(7);
  addrb_5(6) <= addrb(6);
  addrb_5(5) <= addrb(5);
  addrb_5(4) <= addrb(4);
  addrb_5(3) <= addrb(3);
  addrb_5(2) <= addrb(2);
  addrb_5(1) <= addrb(1);
  addrb_5(0) <= addrb(0);
  doutb(63) <= doutb_6(63);
  doutb(62) <= doutb_6(62);
  doutb(61) <= doutb_6(61);
  doutb(60) <= doutb_6(60);
  doutb(59) <= doutb_6(59);
  doutb(58) <= doutb_6(58);
  doutb(57) <= doutb_6(57);
  doutb(56) <= doutb_6(56);
  doutb(55) <= doutb_6(55);
  doutb(54) <= doutb_6(54);
  doutb(53) <= doutb_6(53);
  doutb(52) <= doutb_6(52);
  doutb(51) <= doutb_6(51);
  doutb(50) <= doutb_6(50);
  doutb(49) <= doutb_6(49);
  doutb(48) <= doutb_6(48);
  doutb(47) <= doutb_6(47);
  doutb(46) <= doutb_6(46);
  doutb(45) <= doutb_6(45);
  doutb(44) <= doutb_6(44);
  doutb(43) <= doutb_6(43);
  doutb(42) <= doutb_6(42);
  doutb(41) <= doutb_6(41);
  doutb(40) <= doutb_6(40);
  doutb(39) <= doutb_6(39);
  doutb(38) <= doutb_6(38);
  doutb(37) <= doutb_6(37);
  doutb(36) <= doutb_6(36);
  doutb(35) <= doutb_6(35);
  doutb(34) <= doutb_6(34);
  doutb(33) <= doutb_6(33);
  doutb(32) <= doutb_6(32);
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
  dina_2(63) <= dina(63);
  dina_2(62) <= dina(62);
  dina_2(61) <= dina(61);
  dina_2(60) <= dina(60);
  dina_2(59) <= dina(59);
  dina_2(58) <= dina(58);
  dina_2(57) <= dina(57);
  dina_2(56) <= dina(56);
  dina_2(55) <= dina(55);
  dina_2(54) <= dina(54);
  dina_2(53) <= dina(53);
  dina_2(52) <= dina(52);
  dina_2(51) <= dina(51);
  dina_2(50) <= dina(50);
  dina_2(49) <= dina(49);
  dina_2(48) <= dina(48);
  dina_2(47) <= dina(47);
  dina_2(46) <= dina(46);
  dina_2(45) <= dina(45);
  dina_2(44) <= dina(44);
  dina_2(43) <= dina(43);
  dina_2(42) <= dina(42);
  dina_2(41) <= dina(41);
  dina_2(40) <= dina(40);
  dina_2(39) <= dina(39);
  dina_2(38) <= dina(38);
  dina_2(37) <= dina(37);
  dina_2(36) <= dina(36);
  dina_2(35) <= dina(35);
  dina_2(34) <= dina(34);
  dina_2(33) <= dina(33);
  dina_2(32) <= dina(32);
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
  BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP : RAMB36_EXP
    generic map(
      DOA_REG => 0,
      DOB_REG => 0,
      SRVAL_A => X"000000000",
      SRVAL_B => X"000000000",
      INIT_00 => X"001E001C001A00180016001400120010000E000C000A00080006000400020000",
      INIT_01 => X"003E003C003A00380036003400320030002E002C002A00280026002400220020",
      INIT_02 => X"005E005C005A00580056005400520050004E004C004A00480046004400420040",
      INIT_03 => X"007E007C007A00780076007400720070006E006C006A00680066006400620060",
      INIT_04 => X"009E009C009A00980096009400920090008E008C008A00880086008400820080",
      INIT_05 => X"00BE00BC00BA00B800B600B400B200B000AE00AC00AA00A800A600A400A200A0",
      INIT_06 => X"00DE00DC00DA00D800D600D400D200D000CE00CC00CA00C800C600C400C200C0",
      INIT_07 => X"00FE00FC00FA00F800F600F400F200F000EE00EC00EA00E800E600E400E200E0",
      INIT_08 => X"001E001C001A00180016001400120010000E000C000A00080006000400020000",
      INIT_09 => X"003E003C003A00380036003400320030002E002C002A00280026002400220020",
      INIT_0A => X"005E005C005A00580056005400520050004E004C004A00480046004400420040",
      INIT_0B => X"007E007C007A00780076007400720070006E006C006A00680066006400620060",
      INIT_0C => X"009E009C009A00980096009400920090008E008C008A00880086008400820080",
      INIT_0D => X"00BE00BC00BA00B800B600B400B200B000AE00AC00AA00A800A600A400A200A0",
      INIT_0E => X"00DE00DC00DA00D800D600D400D200D000CE00CC00CA00C800C600C400C200C0",
      INIT_0F => X"00FE00FC00FA00F800F600F400F200F000EE00EC00EA00E800E600E400E200E0",
      INIT_10 => X"011E011C011A01180116011401120110010E010C010A01080106010401020100",
      INIT_11 => X"013E013C013A01380136013401320130012E012C012A01280126012401220120",
      INIT_12 => X"015E015C015A01580156015401520150014E014C014A01480146014401420140",
      INIT_13 => X"017E017C017A01780176017401720170016E016C016A01680166016401620160",
      INIT_14 => X"019E019C019A01980196019401920190018E018C018A01880186018401820180",
      INIT_15 => X"01BE01BC01BA01B801B601B401B201B001AE01AC01AA01A801A601A401A201A0",
      INIT_16 => X"01DE01DC01DA01D801D601D401D201D001CE01CC01CA01C801C601C401C201C0",
      INIT_17 => X"01FE01FC01FA01F801F601F401F201F001EE01EC01EA01E801E601E401E201E0",
      INIT_18 => X"011E011C011A01180116011401120110010E010C010A01080106010401020100",
      INIT_19 => X"013E013C013A01380136013401320130012E012C012A01280126012401220120",
      INIT_1A => X"015E015C015A01580156015401520150014E014C014A01480146014401420140",
      INIT_1B => X"017E017C017A01780176017401720170016E016C016A01680166016401620160",
      INIT_1C => X"019E019C019A01980196019401920190018E018C018A01880186018401820180",
      INIT_1D => X"01BE01BC01BA01B801B601B401B201B001AE01AC01AA01A801A601A401A201A0",
      INIT_1E => X"01DE01DC01DA01D801D601D401D201D001CE01CC01CA01C801C601C401C201C0",
      INIT_1F => X"01FE01FC01FA01F801F601F401F201F001EE01EC01EA01E801E601E401E201E0",
      INIT_20 => X"021E021C021A02180216021402120210020E020C020A02080206020402020200",
      INIT_21 => X"023E023C023A02380236023402320230022E022C022A02280226022402220220",
      INIT_22 => X"025E025C025A02580256025402520250024E024C024A02480246024402420240",
      INIT_23 => X"027E027C027A02780276027402720270026E026C026A02680266026402620260",
      INIT_24 => X"029E029C029A02980296029402920290028E028C028A02880286028402820280",
      INIT_25 => X"02BE02BC02BA02B802B602B402B202B002AE02AC02AA02A802A602A402A202A0",
      INIT_26 => X"02DE02DC02DA02D802D602D402D202D002CE02CC02CA02C802C602C402C202C0",
      INIT_27 => X"02FE02FC02FA02F802F602F402F202F002EE02EC02EA02E802E602E402E202E0",
      INIT_28 => X"021E021C021A02180216021402120210020E020C020A02080206020402020200",
      INIT_29 => X"023E023C023A02380236023402320230022E022C022A02280226022402220220",
      INIT_2A => X"025E025C025A02580256025402520250024E024C024A02480246024402420240",
      INIT_2B => X"027E027C027A02780276027402720270026E026C026A02680266026402620260",
      INIT_2C => X"029E029C029A02980296029402920290028E028C028A02880286028402820280",
      INIT_2D => X"02BE02BC02BA02B802B602B402B202B002AE02AC02AA02A802A602A402A202A0",
      INIT_2E => X"02DE02DC02DA02D802D602D402D202D002CE02CC02CA02C802C602C402C202C0",
      INIT_2F => X"02FE02FC02FA02F802F602F402F202F002EE02EC02EA02E802E602E402E202E0",
      INIT_30 => X"031E031C031A03180316031403120310030E030C030A03080306030403020300",
      INIT_31 => X"033E033C033A03380336033403320330032E032C032A03280326032403220320",
      INIT_32 => X"035E035C035A03580356035403520350034E034C034A03480346034403420340",
      INIT_33 => X"037E037C037A03780376037403720370036E036C036A03680366036403620360",
      INIT_34 => X"039E039C039A03980396039403920390038E038C038A03880386038403820380",
      INIT_35 => X"03BE03BC03BA03B803B603B403B203B003AE03AC03AA03A803A603A403A203A0",
      INIT_36 => X"03DE03DC03DA03D803D603D403D203D003CE03CC03CA03C803C603C403C203C0",
      INIT_37 => X"03FE03FC03FA03F803F603F403F203F003EE03EC03EA03E803E603E403E203E0",
      INIT_38 => X"031E031C031A03180316031403120310030E030C030A03080306030403020300",
      INIT_39 => X"033E033C033A03380336033403320330032E032C032A03280326032403220320",
      INIT_3A => X"035E035C035A03580356035403520350034E034C034A03480346034403420340",
      INIT_3B => X"037E037C037A03780376037403720370036E036C036A03680366036403620360",
      INIT_3C => X"039E039C039A03980396039403920390038E038C038A03880386038403820380",
      INIT_3D => X"03BE03BC03BA03B803B603B403B203B003AE03AC03AA03A803A603A403A203A0",
      INIT_3E => X"03DE03DC03DA03D803D603D403D203D003CE03CC03CA03C803C603C403C203C0",
      INIT_3F => X"03FE03FC03FA03F803F603F403F203F003EE03EC03EA03E803E603E403E203E0",
      INIT_40 => X"041E041C041A04180416041404120410040E040C040A04080406040404020400",
      INIT_41 => X"043E043C043A04380436043404320430042E042C042A04280426042404220420",
      INIT_42 => X"045E045C045A04580456045404520450044E044C044A04480446044404420440",
      INIT_43 => X"047E047C047A04780476047404720470046E046C046A04680466046404620460",
      INIT_44 => X"049E049C049A04980496049404920490048E048C048A04880486048404820480",
      INIT_45 => X"04BE04BC04BA04B804B604B404B204B004AE04AC04AA04A804A604A404A204A0",
      INIT_46 => X"04DE04DC04DA04D804D604D404D204D004CE04CC04CA04C804C604C404C204C0",
      INIT_47 => X"04FE04FC04FA04F804F604F404F204F004EE04EC04EA04E804E604E404E204E0",
      INIT_48 => X"041E041C041A04180416041404120410040E040C040A04080406040404020400",
      INIT_49 => X"043E043C043A04380436043404320430042E042C042A04280426042404220420",
      INIT_4A => X"045E045C045A04580456045404520450044E044C044A04480446044404420440",
      INIT_4B => X"047E047C047A04780476047404720470046E046C046A04680466046404620460",
      INIT_4C => X"049E049C049A04980496049404920490048E048C048A04880486048404820480",
      INIT_4D => X"04BE04BC04BA04B804B604B404B204B004AE04AC04AA04A804A604A404A204A0",
      INIT_4E => X"04DE04DC04DA04D804D604D404D204D004CE04CC04CA04C804C604C404C204C0",
      INIT_4F => X"04FE04FC04FA04F804F604F404F204F004EE04EC04EA04E804E604E404E204E0",
      INIT_50 => X"051E051C051A05180516051405120510050E050C050A05080506050405020500",
      INIT_51 => X"053E053C053A05380536053405320530052E052C052A05280526052405220520",
      INIT_52 => X"055E055C055A05580556055405520550054E054C054A05480546054405420540",
      INIT_53 => X"057E057C057A05780576057405720570056E056C056A05680566056405620560",
      INIT_54 => X"059E059C059A05980596059405920590058E058C058A05880586058405820580",
      INIT_55 => X"05BE05BC05BA05B805B605B405B205B005AE05AC05AA05A805A605A405A205A0",
      INIT_56 => X"05DE05DC05DA05D805D605D405D205D005CE05CC05CA05C805C605C405C205C0",
      INIT_57 => X"05FE05FC05FA05F805F605F405F205F005EE05EC05EA05E805E605E405E205E0",
      INIT_58 => X"051E051C051A05180516051405120510050E050C050A05080506050405020500",
      INIT_59 => X"053E053C053A05380536053405320530052E052C052A05280526052405220520",
      INIT_5A => X"055E055C055A05580556055405520550054E054C054A05480546054405420540",
      INIT_5B => X"057E057C057A05780576057405720570056E056C056A05680566056405620560",
      INIT_5C => X"059E059C059A05980596059405920590058E058C058A05880586058405820580",
      INIT_5D => X"05BE05BC05BA05B805B605B405B205B005AE05AC05AA05A805A605A405A205A0",
      INIT_5E => X"05DE05DC05DA05D805D605D405D205D005CE05CC05CA05C805C605C405C205C0",
      INIT_5F => X"05FE05FC05FA05F805F605F405F205F005EE05EC05EA05E805E605E405E205E0",
      INIT_60 => X"061E061C061A06180616061406120610060E060C060A06080606060406020600",
      INIT_61 => X"063E063C063A06380636063406320630062E062C062A06280626062406220620",
      INIT_62 => X"065E065C065A06580656065406520650064E064C064A06480646064406420640",
      INIT_63 => X"067E067C067A06780676067406720670066E066C066A06680666066406620660",
      INIT_64 => X"069E069C069A06980696069406920690068E068C068A06880686068406820680",
      INIT_65 => X"06BE06BC06BA06B806B606B406B206B006AE06AC06AA06A806A606A406A206A0",
      INIT_66 => X"06DE06DC06DA06D806D606D406D206D006CE06CC06CA06C806C606C406C206C0",
      INIT_67 => X"06FE06FC06FA06F806F606F406F206F006EE06EC06EA06E806E606E406E206E0",
      INIT_68 => X"061E061C061A06180616061406120610060E060C060A06080606060406020600",
      INIT_69 => X"063E063C063A06380636063406320630062E062C062A06280626062406220620",
      INIT_6A => X"065E065C065A06580656065406520650064E064C064A06480646064406420640",
      INIT_6B => X"067E067C067A06780676067406720670066E066C066A06680666066406620660",
      INIT_6C => X"069E069C069A06980696069406920690068E068C068A06880686068406820680",
      INIT_6D => X"06BE06BC06BA06B806B606B406B206B006AE06AC06AA06A806A606A406A206A0",
      INIT_6E => X"06DE06DC06DA06D806D606D406D206D006CE06CC06CA06C806C606C406C206C0",
      INIT_6F => X"06FE06FC06FA06F806F606F406F206F006EE06EC06EA06E806E606E406E206E0",
      INIT_70 => X"071E071C071A07180716071407120710070E070C070A07080706070407020700",
      INIT_71 => X"073E073C073A07380736073407320730072E072C072A07280726072407220720",
      INIT_72 => X"075E075C075A07580756075407520750074E074C074A07480746074407420740",
      INIT_73 => X"077E077C077A07780776077407720770076E076C076A07680766076407620760",
      INIT_74 => X"079E079C079A07980796079407920790078E078C078A07880786078407820780",
      INIT_75 => X"07BE07BC07BA07B807B607B407B207B007AE07AC07AA07A807A607A407A207A0",
      INIT_76 => X"07DE07DC07DA07D807D607D407D207D007CE07CC07CA07C807C607C407C207C0",
      INIT_77 => X"07FE07FC07FA07F807F607F407F207F007EE07EC07EA07E807E607E407E207E0",
      INIT_78 => X"071E071C071A07180716071407120710070E070C070A07080706070407020700",
      INIT_79 => X"073E073C073A07380736073407320730072E072C072A07280726072407220720",
      INIT_7A => X"075E075C075A07580756075407520750074E074C074A07480746074407420740",
      INIT_7B => X"077E077C077A07780776077407720770076E076C076A07680766076407620760",
      INIT_7C => X"079E079C079A07980796079407920790078E078C078A07880786078407820780",
      INIT_7D => X"07BE07BC07BA07B807B607B407B207B007AE07AC07AA07A807A607A407A207A0",
      INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_FILE => "NONE",
      INIT_7E => X"07DE07DC07DA07D807D607D407D207D007CE07CC07CA07C807C607C407C207C0",
      INIT_7F => X"07FE07FC07FA07F807F607F407F207F007EE07EC07EA07E807E607E407E207E0",
      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_01 => X"5555555555555555555555555555555555555555555555555555555555555555",
      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_03 => X"5555555555555555555555555555555555555555555555555555555555555555",
      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_05 => X"5555555555555555555555555555555555555555555555555555555555555555",
      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_07 => X"5555555555555555555555555555555555555555555555555555555555555555",
      INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_09 => X"5555555555555555555555555555555555555555555555555555555555555555",
      INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0B => X"5555555555555555555555555555555555555555555555555555555555555555",
      INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0D => X"5555555555555555555555555555555555555555555555555555555555555555",
      RAM_EXTENSION_A => "NONE",
      RAM_EXTENSION_B => "NONE",
      READ_WIDTH_A => 18,
      READ_WIDTH_B => 18,
      SIM_COLLISION_CHECK => "ALL",
      INIT_A => X"000000000",
      INIT_B => X"000000000",
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
      WRITE_WIDTH_A => 18,
      WRITE_WIDTH_B => 18,
      INITP_0F => X"5555555555555555555555555555555555555555555555555555555555555555"
    )
    port map (
      ENAU => ena,
      ENAL => ena,
      ENBU => enb,
      ENBL => enb,
      SSRAU => BU2_douta(0),
      SSRAL => BU2_douta(0),
      SSRBU => BU2_douta(0),
      SSRBL => BU2_douta(0),
      CLKAU => clka,
      CLKAL => clka,
      CLKBU => clkb,
      CLKBL => clkb,
      REGCLKAU => clka,
      REGCLKAL => clka,
      REGCLKBU => clkb,
      REGCLKBL => clkb,
      REGCEAU => BU2_douta(0),
      REGCEAL => BU2_douta(0),
      REGCEBU => BU2_douta(0),
      REGCEBL => BU2_douta(0),
      CASCADEINLATA => BU2_douta(0),
      CASCADEINLATB => BU2_douta(0),
      CASCADEINREGA => BU2_douta(0),
      CASCADEINREGB => BU2_douta(0),
      CASCADEOUTLATA => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATA_UNCONNECTED,
      CASCADEOUTLATB => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATB_UNCONNECTED,
      CASCADEOUTREGA => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGA_UNCONNECTED,
      CASCADEOUTREGB => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGB_UNCONNECTED,
      DIA(31) => BU2_douta(0),
      DIA(30) => BU2_douta(0),
      DIA(29) => BU2_douta(0),
      DIA(28) => BU2_douta(0),
      DIA(27) => BU2_douta(0),
      DIA(26) => BU2_douta(0),
      DIA(25) => BU2_douta(0),
      DIA(24) => BU2_douta(0),
      DIA(23) => BU2_douta(0),
      DIA(22) => BU2_douta(0),
      DIA(21) => BU2_douta(0),
      DIA(20) => BU2_douta(0),
      DIA(19) => BU2_douta(0),
      DIA(18) => BU2_douta(0),
      DIA(17) => BU2_douta(0),
      DIA(16) => BU2_douta(0),
      DIA(15) => dina_2(16),
      DIA(14) => dina_2(15),
      DIA(13) => dina_2(14),
      DIA(12) => dina_2(13),
      DIA(11) => dina_2(12),
      DIA(10) => dina_2(11),
      DIA(9) => dina_2(10),
      DIA(8) => dina_2(9),
      DIA(7) => dina_2(7),
      DIA(6) => dina_2(6),
      DIA(5) => dina_2(5),
      DIA(4) => dina_2(4),
      DIA(3) => dina_2(3),
      DIA(2) => dina_2(2),
      DIA(1) => dina_2(1),
      DIA(0) => dina_2(0),
      DIPA(3) => BU2_douta(0),
      DIPA(2) => BU2_douta(0),
      DIPA(1) => dina_2(17),
      DIPA(0) => dina_2(8),
      DIB(31) => BU2_douta(0),
      DIB(30) => BU2_douta(0),
      DIB(29) => BU2_douta(0),
      DIB(28) => BU2_douta(0),
      DIB(27) => BU2_douta(0),
      DIB(26) => BU2_douta(0),
      DIB(25) => BU2_douta(0),
      DIB(24) => BU2_douta(0),
      DIB(23) => BU2_douta(0),
      DIB(22) => BU2_douta(0),
      DIB(21) => BU2_douta(0),
      DIB(20) => BU2_douta(0),
      DIB(19) => BU2_douta(0),
      DIB(18) => BU2_douta(0),
      DIB(17) => BU2_douta(0),
      DIB(16) => BU2_douta(0),
      DIB(15) => BU2_douta(0),
      DIB(14) => BU2_douta(0),
      DIB(13) => BU2_douta(0),
      DIB(12) => BU2_douta(0),
      DIB(11) => BU2_douta(0),
      DIB(10) => BU2_douta(0),
      DIB(9) => BU2_douta(0),
      DIB(8) => BU2_douta(0),
      DIB(7) => BU2_douta(0),
      DIB(6) => BU2_douta(0),
      DIB(5) => BU2_douta(0),
      DIB(4) => BU2_douta(0),
      DIB(3) => BU2_douta(0),
      DIB(2) => BU2_douta(0),
      DIB(1) => BU2_douta(0),
      DIB(0) => BU2_douta(0),
      DIPB(3) => BU2_douta(0),
      DIPB(2) => BU2_douta(0),
      DIPB(1) => BU2_douta(0),
      DIPB(0) => BU2_douta(0),
      ADDRAL(15) => BU2_douta(0),
      ADDRAL(14) => addra_3(10),
      ADDRAL(13) => addra_3(9),
      ADDRAL(12) => addra_3(8),
      ADDRAL(11) => addra_3(7),
      ADDRAL(10) => addra_3(6),
      ADDRAL(9) => addra_3(5),
      ADDRAL(8) => addra_3(4),
      ADDRAL(7) => addra_3(3),
      ADDRAL(6) => addra_3(2),
      ADDRAL(5) => addra_3(1),
      ADDRAL(4) => addra_3(0),
      ADDRAL(3) => BU2_douta(0),
      ADDRAL(2) => BU2_douta(0),
      ADDRAL(1) => BU2_douta(0),
      ADDRAL(0) => BU2_douta(0),
      ADDRAU(14) => addra_3(10),
      ADDRAU(13) => addra_3(9),
      ADDRAU(12) => addra_3(8),
      ADDRAU(11) => addra_3(7),
      ADDRAU(10) => addra_3(6),
      ADDRAU(9) => addra_3(5),
      ADDRAU(8) => addra_3(4),
      ADDRAU(7) => addra_3(3),
      ADDRAU(6) => addra_3(2),
      ADDRAU(5) => addra_3(1),
      ADDRAU(4) => addra_3(0),
      ADDRAU(3) => BU2_douta(0),
      ADDRAU(2) => BU2_douta(0),
      ADDRAU(1) => BU2_douta(0),
      ADDRAU(0) => BU2_douta(0),
      ADDRBL(15) => BU2_douta(0),
      ADDRBL(14) => addrb_5(10),
      ADDRBL(13) => addrb_5(9),
      ADDRBL(12) => addrb_5(8),
      ADDRBL(11) => addrb_5(7),
      ADDRBL(10) => addrb_5(6),
      ADDRBL(9) => addrb_5(5),
      ADDRBL(8) => addrb_5(4),
      ADDRBL(7) => addrb_5(3),
      ADDRBL(6) => addrb_5(2),
      ADDRBL(5) => addrb_5(1),
      ADDRBL(4) => addrb_5(0),
      ADDRBL(3) => BU2_douta(0),
      ADDRBL(2) => BU2_douta(0),
      ADDRBL(1) => BU2_douta(0),
      ADDRBL(0) => BU2_douta(0),
      ADDRBU(14) => addrb_5(10),
      ADDRBU(13) => addrb_5(9),
      ADDRBU(12) => addrb_5(8),
      ADDRBU(11) => addrb_5(7),
      ADDRBU(10) => addrb_5(6),
      ADDRBU(9) => addrb_5(5),
      ADDRBU(8) => addrb_5(4),
      ADDRBU(7) => addrb_5(3),
      ADDRBU(6) => addrb_5(2),
      ADDRBU(5) => addrb_5(1),
      ADDRBU(4) => addrb_5(0),
      ADDRBU(3) => BU2_douta(0),
      ADDRBU(2) => BU2_douta(0),
      ADDRBU(1) => BU2_douta(0),
      ADDRBU(0) => BU2_douta(0),
      WEAU(3) => wea_4(0),
      WEAU(2) => wea_4(0),
      WEAU(1) => wea_4(0),
      WEAU(0) => wea_4(0),
      WEAL(3) => wea_4(0),
      WEAL(2) => wea_4(0),
      WEAL(1) => wea_4(0),
      WEAL(0) => wea_4(0),
      WEBU(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_7_UNCONNECTED,
      WEBU(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_6_UNCONNECTED,
      WEBU(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_5_UNCONNECTED,
      WEBU(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_4_UNCONNECTED,
      WEBU(3) => BU2_douta(0),
      WEBU(2) => BU2_douta(0),
      WEBU(1) => BU2_douta(0),
      WEBU(0) => BU2_douta(0),
      WEBL(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_7_UNCONNECTED,
      WEBL(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_6_UNCONNECTED,
      WEBL(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_5_UNCONNECTED,
      WEBL(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_4_UNCONNECTED,
      WEBL(3) => BU2_douta(0),
      WEBL(2) => BU2_douta(0),
      WEBL(1) => BU2_douta(0),
      WEBL(0) => BU2_douta(0),
      DOA(31) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_31_UNCONNECTED,
      DOA(30) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_30_UNCONNECTED,
      DOA(29) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_29_UNCONNECTED,
      DOA(28) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_28_UNCONNECTED,
      DOA(27) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_27_UNCONNECTED,
      DOA(26) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_26_UNCONNECTED,
      DOA(25) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_25_UNCONNECTED,
      DOA(24) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_24_UNCONNECTED,
      DOA(23) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_23_UNCONNECTED,
      DOA(22) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_22_UNCONNECTED,
      DOA(21) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_21_UNCONNECTED,
      DOA(20) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_20_UNCONNECTED,
      DOA(19) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_19_UNCONNECTED,
      DOA(18) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_18_UNCONNECTED,
      DOA(17) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_17_UNCONNECTED,
      DOA(16) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_16_UNCONNECTED,
      DOA(15) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_15_UNCONNECTED,
      DOA(14) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_14_UNCONNECTED,
      DOA(13) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_13_UNCONNECTED,
      DOA(12) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_12_UNCONNECTED,
      DOA(11) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_11_UNCONNECTED,
      DOA(10) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_10_UNCONNECTED,
      DOA(9) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_9_UNCONNECTED,
      DOA(8) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_8_UNCONNECTED,
      DOA(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_7_UNCONNECTED,
      DOA(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_6_UNCONNECTED,
      DOA(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_5_UNCONNECTED,
      DOA(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_4_UNCONNECTED,
      DOA(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_3_UNCONNECTED,
      DOA(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_2_UNCONNECTED,
      DOA(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_1_UNCONNECTED,
      DOA(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_0_UNCONNECTED,
      DOPA(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_3_UNCONNECTED,
      DOPA(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_2_UNCONNECTED,
      DOPA(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_1_UNCONNECTED,
      DOPA(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_0_UNCONNECTED,
      DOB(31) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_31_UNCONNECTED,
      DOB(30) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_30_UNCONNECTED,
      DOB(29) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_29_UNCONNECTED,
      DOB(28) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_28_UNCONNECTED,
      DOB(27) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_27_UNCONNECTED,
      DOB(26) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_26_UNCONNECTED,
      DOB(25) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_25_UNCONNECTED,
      DOB(24) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_24_UNCONNECTED,
      DOB(23) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_23_UNCONNECTED,
      DOB(22) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_22_UNCONNECTED,
      DOB(21) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_21_UNCONNECTED,
      DOB(20) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_20_UNCONNECTED,
      DOB(19) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_19_UNCONNECTED,
      DOB(18) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_18_UNCONNECTED,
      DOB(17) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_17_UNCONNECTED,
      DOB(16) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_16_UNCONNECTED,
      DOB(15) => doutb_6(16),
      DOB(14) => doutb_6(15),
      DOB(13) => doutb_6(14),
      DOB(12) => doutb_6(13),
      DOB(11) => doutb_6(12),
      DOB(10) => doutb_6(11),
      DOB(9) => doutb_6(10),
      DOB(8) => doutb_6(9),
      DOB(7) => doutb_6(7),
      DOB(6) => doutb_6(6),
      DOB(5) => doutb_6(5),
      DOB(4) => doutb_6(4),
      DOB(3) => doutb_6(3),
      DOB(2) => doutb_6(2),
      DOB(1) => doutb_6(1),
      DOB(0) => doutb_6(0),
      DOPB(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_3_UNCONNECTED,
      DOPB(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_2_UNCONNECTED,
      DOPB(1) => doutb_6(17),
      DOPB(0) => doutb_6(8)
    );
  BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP : RAMB36_EXP
    generic map(
      DOA_REG => 0,
      DOB_REG => 0,
      SRVAL_A => X"000000000",
      SRVAL_B => X"000000000",
      INIT_00 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_01 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_02 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_03 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_04 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_05 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_06 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_07 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_08 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_09 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_0A => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_0B => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_0C => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_0D => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_0E => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_0F => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_10 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_11 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_12 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_13 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_14 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_15 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_16 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_17 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_18 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_19 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_1A => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_1B => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_1C => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_1D => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_1E => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_1F => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_20 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_21 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_22 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_23 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_24 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_25 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_26 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_27 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_28 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_29 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_2A => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_2B => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_2C => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_2D => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_2E => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_2F => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_30 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_31 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_32 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_33 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_34 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_35 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_36 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_37 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_38 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_39 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_3A => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_3B => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_3C => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_3D => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_3E => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_3F => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_40 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_41 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_42 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_43 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_44 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_45 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_46 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_47 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_48 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_49 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_4A => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_4B => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_4C => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_4D => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_4E => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_4F => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_50 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_51 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_52 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_53 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_54 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_55 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_56 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_57 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_58 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_59 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_5A => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_5B => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_5C => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_5D => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_5E => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_5F => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_60 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_61 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_62 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_63 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_64 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_65 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_66 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_67 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_68 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_69 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_6A => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_6B => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_6C => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_6D => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_6E => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_6F => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_70 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_71 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_72 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_73 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_74 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_75 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_76 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_77 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_78 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_79 => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_7A => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_7B => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_7C => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_7D => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INITP_0E => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INIT_FILE => "NONE",
      INIT_7E => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INIT_7F => X"E000A00060002000E000A00060002000E000A00060002000E000A00060002000",
      INITP_00 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_01 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_02 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_03 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_04 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_05 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_06 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_07 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_08 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_09 => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_0A => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_0B => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_0C => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      INITP_0D => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00",
      RAM_EXTENSION_A => "NONE",
      RAM_EXTENSION_B => "NONE",
      READ_WIDTH_A => 18,
      READ_WIDTH_B => 18,
      SIM_COLLISION_CHECK => "ALL",
      INIT_A => X"000000000",
      INIT_B => X"000000000",
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
      WRITE_WIDTH_A => 18,
      WRITE_WIDTH_B => 18,
      INITP_0F => X"AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00AA00"
    )
    port map (
      ENAU => ena,
      ENAL => ena,
      ENBU => enb,
      ENBL => enb,
      SSRAU => BU2_douta(0),
      SSRAL => BU2_douta(0),
      SSRBU => BU2_douta(0),
      SSRBL => BU2_douta(0),
      CLKAU => clka,
      CLKAL => clka,
      CLKBU => clkb,
      CLKBL => clkb,
      REGCLKAU => clka,
      REGCLKAL => clka,
      REGCLKBU => clkb,
      REGCLKBL => clkb,
      REGCEAU => BU2_douta(0),
      REGCEAL => BU2_douta(0),
      REGCEBU => BU2_douta(0),
      REGCEBL => BU2_douta(0),
      CASCADEINLATA => BU2_douta(0),
      CASCADEINLATB => BU2_douta(0),
      CASCADEINREGA => BU2_douta(0),
      CASCADEINREGB => BU2_douta(0),
      CASCADEOUTLATA => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATA_UNCONNECTED,
      CASCADEOUTLATB => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATB_UNCONNECTED,
      CASCADEOUTREGA => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGA_UNCONNECTED,
      CASCADEOUTREGB => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGB_UNCONNECTED,
      DIA(31) => BU2_douta(0),
      DIA(30) => BU2_douta(0),
      DIA(29) => BU2_douta(0),
      DIA(28) => BU2_douta(0),
      DIA(27) => BU2_douta(0),
      DIA(26) => BU2_douta(0),
      DIA(25) => BU2_douta(0),
      DIA(24) => BU2_douta(0),
      DIA(23) => BU2_douta(0),
      DIA(22) => BU2_douta(0),
      DIA(21) => BU2_douta(0),
      DIA(20) => BU2_douta(0),
      DIA(19) => BU2_douta(0),
      DIA(18) => BU2_douta(0),
      DIA(17) => BU2_douta(0),
      DIA(16) => BU2_douta(0),
      DIA(15) => dina_2(34),
      DIA(14) => dina_2(33),
      DIA(13) => dina_2(32),
      DIA(12) => dina_2(31),
      DIA(11) => dina_2(30),
      DIA(10) => dina_2(29),
      DIA(9) => dina_2(28),
      DIA(8) => dina_2(27),
      DIA(7) => dina_2(25),
      DIA(6) => dina_2(24),
      DIA(5) => dina_2(23),
      DIA(4) => dina_2(22),
      DIA(3) => dina_2(21),
      DIA(2) => dina_2(20),
      DIA(1) => dina_2(19),
      DIA(0) => dina_2(18),
      DIPA(3) => BU2_douta(0),
      DIPA(2) => BU2_douta(0),
      DIPA(1) => dina_2(35),
      DIPA(0) => dina_2(26),
      DIB(31) => BU2_douta(0),
      DIB(30) => BU2_douta(0),
      DIB(29) => BU2_douta(0),
      DIB(28) => BU2_douta(0),
      DIB(27) => BU2_douta(0),
      DIB(26) => BU2_douta(0),
      DIB(25) => BU2_douta(0),
      DIB(24) => BU2_douta(0),
      DIB(23) => BU2_douta(0),
      DIB(22) => BU2_douta(0),
      DIB(21) => BU2_douta(0),
      DIB(20) => BU2_douta(0),
      DIB(19) => BU2_douta(0),
      DIB(18) => BU2_douta(0),
      DIB(17) => BU2_douta(0),
      DIB(16) => BU2_douta(0),
      DIB(15) => BU2_douta(0),
      DIB(14) => BU2_douta(0),
      DIB(13) => BU2_douta(0),
      DIB(12) => BU2_douta(0),
      DIB(11) => BU2_douta(0),
      DIB(10) => BU2_douta(0),
      DIB(9) => BU2_douta(0),
      DIB(8) => BU2_douta(0),
      DIB(7) => BU2_douta(0),
      DIB(6) => BU2_douta(0),
      DIB(5) => BU2_douta(0),
      DIB(4) => BU2_douta(0),
      DIB(3) => BU2_douta(0),
      DIB(2) => BU2_douta(0),
      DIB(1) => BU2_douta(0),
      DIB(0) => BU2_douta(0),
      DIPB(3) => BU2_douta(0),
      DIPB(2) => BU2_douta(0),
      DIPB(1) => BU2_douta(0),
      DIPB(0) => BU2_douta(0),
      ADDRAL(15) => BU2_douta(0),
      ADDRAL(14) => addra_3(10),
      ADDRAL(13) => addra_3(9),
      ADDRAL(12) => addra_3(8),
      ADDRAL(11) => addra_3(7),
      ADDRAL(10) => addra_3(6),
      ADDRAL(9) => addra_3(5),
      ADDRAL(8) => addra_3(4),
      ADDRAL(7) => addra_3(3),
      ADDRAL(6) => addra_3(2),
      ADDRAL(5) => addra_3(1),
      ADDRAL(4) => addra_3(0),
      ADDRAL(3) => BU2_douta(0),
      ADDRAL(2) => BU2_douta(0),
      ADDRAL(1) => BU2_douta(0),
      ADDRAL(0) => BU2_douta(0),
      ADDRAU(14) => addra_3(10),
      ADDRAU(13) => addra_3(9),
      ADDRAU(12) => addra_3(8),
      ADDRAU(11) => addra_3(7),
      ADDRAU(10) => addra_3(6),
      ADDRAU(9) => addra_3(5),
      ADDRAU(8) => addra_3(4),
      ADDRAU(7) => addra_3(3),
      ADDRAU(6) => addra_3(2),
      ADDRAU(5) => addra_3(1),
      ADDRAU(4) => addra_3(0),
      ADDRAU(3) => BU2_douta(0),
      ADDRAU(2) => BU2_douta(0),
      ADDRAU(1) => BU2_douta(0),
      ADDRAU(0) => BU2_douta(0),
      ADDRBL(15) => BU2_douta(0),
      ADDRBL(14) => addrb_5(10),
      ADDRBL(13) => addrb_5(9),
      ADDRBL(12) => addrb_5(8),
      ADDRBL(11) => addrb_5(7),
      ADDRBL(10) => addrb_5(6),
      ADDRBL(9) => addrb_5(5),
      ADDRBL(8) => addrb_5(4),
      ADDRBL(7) => addrb_5(3),
      ADDRBL(6) => addrb_5(2),
      ADDRBL(5) => addrb_5(1),
      ADDRBL(4) => addrb_5(0),
      ADDRBL(3) => BU2_douta(0),
      ADDRBL(2) => BU2_douta(0),
      ADDRBL(1) => BU2_douta(0),
      ADDRBL(0) => BU2_douta(0),
      ADDRBU(14) => addrb_5(10),
      ADDRBU(13) => addrb_5(9),
      ADDRBU(12) => addrb_5(8),
      ADDRBU(11) => addrb_5(7),
      ADDRBU(10) => addrb_5(6),
      ADDRBU(9) => addrb_5(5),
      ADDRBU(8) => addrb_5(4),
      ADDRBU(7) => addrb_5(3),
      ADDRBU(6) => addrb_5(2),
      ADDRBU(5) => addrb_5(1),
      ADDRBU(4) => addrb_5(0),
      ADDRBU(3) => BU2_douta(0),
      ADDRBU(2) => BU2_douta(0),
      ADDRBU(1) => BU2_douta(0),
      ADDRBU(0) => BU2_douta(0),
      WEAU(3) => wea_4(0),
      WEAU(2) => wea_4(0),
      WEAU(1) => wea_4(0),
      WEAU(0) => wea_4(0),
      WEAL(3) => wea_4(0),
      WEAL(2) => wea_4(0),
      WEAL(1) => wea_4(0),
      WEAL(0) => wea_4(0),
      WEBU(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_7_UNCONNECTED,
      WEBU(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_6_UNCONNECTED,
      WEBU(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_5_UNCONNECTED,
      WEBU(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_4_UNCONNECTED,
      WEBU(3) => BU2_douta(0),
      WEBU(2) => BU2_douta(0),
      WEBU(1) => BU2_douta(0),
      WEBU(0) => BU2_douta(0),
      WEBL(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_7_UNCONNECTED,
      WEBL(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_6_UNCONNECTED,
      WEBL(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_5_UNCONNECTED,
      WEBL(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_4_UNCONNECTED,
      WEBL(3) => BU2_douta(0),
      WEBL(2) => BU2_douta(0),
      WEBL(1) => BU2_douta(0),
      WEBL(0) => BU2_douta(0),
      DOA(31) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_31_UNCONNECTED,
      DOA(30) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_30_UNCONNECTED,
      DOA(29) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_29_UNCONNECTED,
      DOA(28) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_28_UNCONNECTED,
      DOA(27) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_27_UNCONNECTED,
      DOA(26) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_26_UNCONNECTED,
      DOA(25) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_25_UNCONNECTED,
      DOA(24) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_24_UNCONNECTED,
      DOA(23) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_23_UNCONNECTED,
      DOA(22) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_22_UNCONNECTED,
      DOA(21) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_21_UNCONNECTED,
      DOA(20) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_20_UNCONNECTED,
      DOA(19) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_19_UNCONNECTED,
      DOA(18) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_18_UNCONNECTED,
      DOA(17) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_17_UNCONNECTED,
      DOA(16) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_16_UNCONNECTED,
      DOA(15) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_15_UNCONNECTED,
      DOA(14) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_14_UNCONNECTED,
      DOA(13) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_13_UNCONNECTED,
      DOA(12) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_12_UNCONNECTED,
      DOA(11) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_11_UNCONNECTED,
      DOA(10) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_10_UNCONNECTED,
      DOA(9) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_9_UNCONNECTED,
      DOA(8) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_8_UNCONNECTED,
      DOA(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_7_UNCONNECTED,
      DOA(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_6_UNCONNECTED,
      DOA(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_5_UNCONNECTED,
      DOA(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_4_UNCONNECTED,
      DOA(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_3_UNCONNECTED,
      DOA(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_2_UNCONNECTED,
      DOA(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_1_UNCONNECTED,
      DOA(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_0_UNCONNECTED,
      DOPA(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_3_UNCONNECTED,
      DOPA(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_2_UNCONNECTED,
      DOPA(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_1_UNCONNECTED,
      DOPA(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_0_UNCONNECTED,
      DOB(31) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_31_UNCONNECTED,
      DOB(30) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_30_UNCONNECTED,
      DOB(29) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_29_UNCONNECTED,
      DOB(28) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_28_UNCONNECTED,
      DOB(27) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_27_UNCONNECTED,
      DOB(26) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_26_UNCONNECTED,
      DOB(25) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_25_UNCONNECTED,
      DOB(24) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_24_UNCONNECTED,
      DOB(23) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_23_UNCONNECTED,
      DOB(22) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_22_UNCONNECTED,
      DOB(21) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_21_UNCONNECTED,
      DOB(20) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_20_UNCONNECTED,
      DOB(19) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_19_UNCONNECTED,
      DOB(18) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_18_UNCONNECTED,
      DOB(17) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_17_UNCONNECTED,
      DOB(16) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_16_UNCONNECTED,
      DOB(15) => doutb_6(34),
      DOB(14) => doutb_6(33),
      DOB(13) => doutb_6(32),
      DOB(12) => doutb_6(31),
      DOB(11) => doutb_6(30),
      DOB(10) => doutb_6(29),
      DOB(9) => doutb_6(28),
      DOB(8) => doutb_6(27),
      DOB(7) => doutb_6(25),
      DOB(6) => doutb_6(24),
      DOB(5) => doutb_6(23),
      DOB(4) => doutb_6(22),
      DOB(3) => doutb_6(21),
      DOB(2) => doutb_6(20),
      DOB(1) => doutb_6(19),
      DOB(0) => doutb_6(18),
      DOPB(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_3_UNCONNECTED,
      DOPB(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_1_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_2_UNCONNECTED,
      DOPB(1) => doutb_6(35),
      DOPB(0) => doutb_6(26)
    );
  BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP : RAMB36_EXP
    generic map(
      DOA_REG => 0,
      DOB_REG => 0,
      SRVAL_A => X"000000000",
      SRVAL_B => X"000000000",
      INIT_00 => X"0001000100010001000100010001000100000000000000000000000000000000",
      INIT_01 => X"0003000300030003000300030003000300020002000200020002000200020002",
      INIT_02 => X"0005000500050005000500050005000500040004000400040004000400040004",
      INIT_03 => X"0007000700070007000700070007000700060006000600060006000600060006",
      INIT_04 => X"0009000900090009000900090009000900080008000800080008000800080008",
      INIT_05 => X"000B000B000B000B000B000B000B000B000A000A000A000A000A000A000A000A",
      INIT_06 => X"000D000D000D000D000D000D000D000D000C000C000C000C000C000C000C000C",
      INIT_07 => X"000F000F000F000F000F000F000F000F000E000E000E000E000E000E000E000E",
      INIT_08 => X"0011001100110011001100110011001100100010001000100010001000100010",
      INIT_09 => X"0013001300130013001300130013001300120012001200120012001200120012",
      INIT_0A => X"0015001500150015001500150015001500140014001400140014001400140014",
      INIT_0B => X"0017001700170017001700170017001700160016001600160016001600160016",
      INIT_0C => X"0019001900190019001900190019001900180018001800180018001800180018",
      INIT_0D => X"001B001B001B001B001B001B001B001B001A001A001A001A001A001A001A001A",
      INIT_0E => X"001D001D001D001D001D001D001D001D001C001C001C001C001C001C001C001C",
      INIT_0F => X"001F001F001F001F001F001F001F001F001E001E001E001E001E001E001E001E",
      INIT_10 => X"0021002100210021002100210021002100200020002000200020002000200020",
      INIT_11 => X"0023002300230023002300230023002300220022002200220022002200220022",
      INIT_12 => X"0025002500250025002500250025002500240024002400240024002400240024",
      INIT_13 => X"0027002700270027002700270027002700260026002600260026002600260026",
      INIT_14 => X"0029002900290029002900290029002900280028002800280028002800280028",
      INIT_15 => X"002B002B002B002B002B002B002B002B002A002A002A002A002A002A002A002A",
      INIT_16 => X"002D002D002D002D002D002D002D002D002C002C002C002C002C002C002C002C",
      INIT_17 => X"002F002F002F002F002F002F002F002F002E002E002E002E002E002E002E002E",
      INIT_18 => X"0031003100310031003100310031003100300030003000300030003000300030",
      INIT_19 => X"0033003300330033003300330033003300320032003200320032003200320032",
      INIT_1A => X"0035003500350035003500350035003500340034003400340034003400340034",
      INIT_1B => X"0037003700370037003700370037003700360036003600360036003600360036",
      INIT_1C => X"0039003900390039003900390039003900380038003800380038003800380038",
      INIT_1D => X"003B003B003B003B003B003B003B003B003A003A003A003A003A003A003A003A",
      INIT_1E => X"003D003D003D003D003D003D003D003D003C003C003C003C003C003C003C003C",
      INIT_1F => X"003F003F003F003F003F003F003F003F003E003E003E003E003E003E003E003E",
      INIT_20 => X"0041004100410041004100410041004100400040004000400040004000400040",
      INIT_21 => X"0043004300430043004300430043004300420042004200420042004200420042",
      INIT_22 => X"0045004500450045004500450045004500440044004400440044004400440044",
      INIT_23 => X"0047004700470047004700470047004700460046004600460046004600460046",
      INIT_24 => X"0049004900490049004900490049004900480048004800480048004800480048",
      INIT_25 => X"004B004B004B004B004B004B004B004B004A004A004A004A004A004A004A004A",
      INIT_26 => X"004D004D004D004D004D004D004D004D004C004C004C004C004C004C004C004C",
      INIT_27 => X"004F004F004F004F004F004F004F004F004E004E004E004E004E004E004E004E",
      INIT_28 => X"0051005100510051005100510051005100500050005000500050005000500050",
      INIT_29 => X"0053005300530053005300530053005300520052005200520052005200520052",
      INIT_2A => X"0055005500550055005500550055005500540054005400540054005400540054",
      INIT_2B => X"0057005700570057005700570057005700560056005600560056005600560056",
      INIT_2C => X"0059005900590059005900590059005900580058005800580058005800580058",
      INIT_2D => X"005B005B005B005B005B005B005B005B005A005A005A005A005A005A005A005A",
      INIT_2E => X"005D005D005D005D005D005D005D005D005C005C005C005C005C005C005C005C",
      INIT_2F => X"005F005F005F005F005F005F005F005F005E005E005E005E005E005E005E005E",
      INIT_30 => X"0061006100610061006100610061006100600060006000600060006000600060",
      INIT_31 => X"0063006300630063006300630063006300620062006200620062006200620062",
      INIT_32 => X"0065006500650065006500650065006500640064006400640064006400640064",
      INIT_33 => X"0067006700670067006700670067006700660066006600660066006600660066",
      INIT_34 => X"0069006900690069006900690069006900680068006800680068006800680068",
      INIT_35 => X"006B006B006B006B006B006B006B006B006A006A006A006A006A006A006A006A",
      INIT_36 => X"006D006D006D006D006D006D006D006D006C006C006C006C006C006C006C006C",
      INIT_37 => X"006F006F006F006F006F006F006F006F006E006E006E006E006E006E006E006E",
      INIT_38 => X"0071007100710071007100710071007100700070007000700070007000700070",
      INIT_39 => X"0073007300730073007300730073007300720072007200720072007200720072",
      INIT_3A => X"0075007500750075007500750075007500740074007400740074007400740074",
      INIT_3B => X"0077007700770077007700770077007700760076007600760076007600760076",
      INIT_3C => X"0079007900790079007900790079007900780078007800780078007800780078",
      INIT_3D => X"007B007B007B007B007B007B007B007B007A007A007A007A007A007A007A007A",
      INIT_3E => X"007D007D007D007D007D007D007D007D007C007C007C007C007C007C007C007C",
      INIT_3F => X"007F007F007F007F007F007F007F007F007E007E007E007E007E007E007E007E",
      INIT_40 => X"0081008100810081008100810081008100800080008000800080008000800080",
      INIT_41 => X"0083008300830083008300830083008300820082008200820082008200820082",
      INIT_42 => X"0085008500850085008500850085008500840084008400840084008400840084",
      INIT_43 => X"0087008700870087008700870087008700860086008600860086008600860086",
      INIT_44 => X"0089008900890089008900890089008900880088008800880088008800880088",
      INIT_45 => X"008B008B008B008B008B008B008B008B008A008A008A008A008A008A008A008A",
      INIT_46 => X"008D008D008D008D008D008D008D008D008C008C008C008C008C008C008C008C",
      INIT_47 => X"008F008F008F008F008F008F008F008F008E008E008E008E008E008E008E008E",
      INIT_48 => X"0091009100910091009100910091009100900090009000900090009000900090",
      INIT_49 => X"0093009300930093009300930093009300920092009200920092009200920092",
      INIT_4A => X"0095009500950095009500950095009500940094009400940094009400940094",
      INIT_4B => X"0097009700970097009700970097009700960096009600960096009600960096",
      INIT_4C => X"0099009900990099009900990099009900980098009800980098009800980098",
      INIT_4D => X"009B009B009B009B009B009B009B009B009A009A009A009A009A009A009A009A",
      INIT_4E => X"009D009D009D009D009D009D009D009D009C009C009C009C009C009C009C009C",
      INIT_4F => X"009F009F009F009F009F009F009F009F009E009E009E009E009E009E009E009E",
      INIT_50 => X"00A100A100A100A100A100A100A100A100A000A000A000A000A000A000A000A0",
      INIT_51 => X"00A300A300A300A300A300A300A300A300A200A200A200A200A200A200A200A2",
      INIT_52 => X"00A500A500A500A500A500A500A500A500A400A400A400A400A400A400A400A4",
      INIT_53 => X"00A700A700A700A700A700A700A700A700A600A600A600A600A600A600A600A6",
      INIT_54 => X"00A900A900A900A900A900A900A900A900A800A800A800A800A800A800A800A8",
      INIT_55 => X"00AB00AB00AB00AB00AB00AB00AB00AB00AA00AA00AA00AA00AA00AA00AA00AA",
      INIT_56 => X"00AD00AD00AD00AD00AD00AD00AD00AD00AC00AC00AC00AC00AC00AC00AC00AC",
      INIT_57 => X"00AF00AF00AF00AF00AF00AF00AF00AF00AE00AE00AE00AE00AE00AE00AE00AE",
      INIT_58 => X"00B100B100B100B100B100B100B100B100B000B000B000B000B000B000B000B0",
      INIT_59 => X"00B300B300B300B300B300B300B300B300B200B200B200B200B200B200B200B2",
      INIT_5A => X"00B500B500B500B500B500B500B500B500B400B400B400B400B400B400B400B4",
      INIT_5B => X"00B700B700B700B700B700B700B700B700B600B600B600B600B600B600B600B6",
      INIT_5C => X"00B900B900B900B900B900B900B900B900B800B800B800B800B800B800B800B8",
      INIT_5D => X"00BB00BB00BB00BB00BB00BB00BB00BB00BA00BA00BA00BA00BA00BA00BA00BA",
      INIT_5E => X"00BD00BD00BD00BD00BD00BD00BD00BD00BC00BC00BC00BC00BC00BC00BC00BC",
      INIT_5F => X"00BF00BF00BF00BF00BF00BF00BF00BF00BE00BE00BE00BE00BE00BE00BE00BE",
      INIT_60 => X"00C100C100C100C100C100C100C100C100C000C000C000C000C000C000C000C0",
      INIT_61 => X"00C300C300C300C300C300C300C300C300C200C200C200C200C200C200C200C2",
      INIT_62 => X"00C500C500C500C500C500C500C500C500C400C400C400C400C400C400C400C4",
      INIT_63 => X"00C700C700C700C700C700C700C700C700C600C600C600C600C600C600C600C6",
      INIT_64 => X"00C900C900C900C900C900C900C900C900C800C800C800C800C800C800C800C8",
      INIT_65 => X"00CB00CB00CB00CB00CB00CB00CB00CB00CA00CA00CA00CA00CA00CA00CA00CA",
      INIT_66 => X"00CD00CD00CD00CD00CD00CD00CD00CD00CC00CC00CC00CC00CC00CC00CC00CC",
      INIT_67 => X"00CF00CF00CF00CF00CF00CF00CF00CF00CE00CE00CE00CE00CE00CE00CE00CE",
      INIT_68 => X"00D100D100D100D100D100D100D100D100D000D000D000D000D000D000D000D0",
      INIT_69 => X"00D300D300D300D300D300D300D300D300D200D200D200D200D200D200D200D2",
      INIT_6A => X"00D500D500D500D500D500D500D500D500D400D400D400D400D400D400D400D4",
      INIT_6B => X"00D700D700D700D700D700D700D700D700D600D600D600D600D600D600D600D6",
      INIT_6C => X"00D900D900D900D900D900D900D900D900D800D800D800D800D800D800D800D8",
      INIT_6D => X"00DB00DB00DB00DB00DB00DB00DB00DB00DA00DA00DA00DA00DA00DA00DA00DA",
      INIT_6E => X"00DD00DD00DD00DD00DD00DD00DD00DD00DC00DC00DC00DC00DC00DC00DC00DC",
      INIT_6F => X"00DF00DF00DF00DF00DF00DF00DF00DF00DE00DE00DE00DE00DE00DE00DE00DE",
      INIT_70 => X"00E100E100E100E100E100E100E100E100E000E000E000E000E000E000E000E0",
      INIT_71 => X"00E300E300E300E300E300E300E300E300E200E200E200E200E200E200E200E2",
      INIT_72 => X"00E500E500E500E500E500E500E500E500E400E400E400E400E400E400E400E4",
      INIT_73 => X"00E700E700E700E700E700E700E700E700E600E600E600E600E600E600E600E6",
      INIT_74 => X"00E900E900E900E900E900E900E900E900E800E800E800E800E800E800E800E8",
      INIT_75 => X"00EB00EB00EB00EB00EB00EB00EB00EB00EA00EA00EA00EA00EA00EA00EA00EA",
      INIT_76 => X"00ED00ED00ED00ED00ED00ED00ED00ED00EC00EC00EC00EC00EC00EC00EC00EC",
      INIT_77 => X"00EF00EF00EF00EF00EF00EF00EF00EF00EE00EE00EE00EE00EE00EE00EE00EE",
      INIT_78 => X"00F100F100F100F100F100F100F100F100F000F000F000F000F000F000F000F0",
      INIT_79 => X"00F300F300F300F300F300F300F300F300F200F200F200F200F200F200F200F2",
      INIT_7A => X"00F500F500F500F500F500F500F500F500F400F400F400F400F400F400F400F4",
      INIT_7B => X"00F700F700F700F700F700F700F700F700F600F600F600F600F600F600F600F6",
      INIT_7C => X"00F900F900F900F900F900F900F900F900F800F800F800F800F800F800F800F8",
      INIT_7D => X"00FB00FB00FB00FB00FB00FB00FB00FB00FA00FA00FA00FA00FA00FA00FA00FA",
      INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_FILE => "NONE",
      INIT_7E => X"00FD00FD00FD00FD00FD00FD00FD00FD00FC00FC00FC00FC00FC00FC00FC00FC",
      INIT_7F => X"00FF00FF00FF00FF00FF00FF00FF00FF00FE00FE00FE00FE00FE00FE00FE00FE",
      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
      RAM_EXTENSION_A => "NONE",
      RAM_EXTENSION_B => "NONE",
      READ_WIDTH_A => 18,
      READ_WIDTH_B => 18,
      SIM_COLLISION_CHECK => "ALL",
      INIT_A => X"000000000",
      INIT_B => X"000000000",
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
      WRITE_WIDTH_A => 18,
      WRITE_WIDTH_B => 18,
      INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000"
    )
    port map (
      ENAU => ena,
      ENAL => ena,
      ENBU => enb,
      ENBL => enb,
      SSRAU => BU2_douta(0),
      SSRAL => BU2_douta(0),
      SSRBU => BU2_douta(0),
      SSRBL => BU2_douta(0),
      CLKAU => clka,
      CLKAL => clka,
      CLKBU => clkb,
      CLKBL => clkb,
      REGCLKAU => clka,
      REGCLKAL => clka,
      REGCLKBU => clkb,
      REGCLKBL => clkb,
      REGCEAU => BU2_douta(0),
      REGCEAL => BU2_douta(0),
      REGCEBU => BU2_douta(0),
      REGCEBL => BU2_douta(0),
      CASCADEINLATA => BU2_douta(0),
      CASCADEINLATB => BU2_douta(0),
      CASCADEINREGA => BU2_douta(0),
      CASCADEINREGB => BU2_douta(0),
      CASCADEOUTLATA => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATA_UNCONNECTED,
      CASCADEOUTLATB => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATB_UNCONNECTED,
      CASCADEOUTREGA => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGA_UNCONNECTED,
      CASCADEOUTREGB => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGB_UNCONNECTED,
      DIA(31) => BU2_douta(0),
      DIA(30) => BU2_douta(0),
      DIA(29) => BU2_douta(0),
      DIA(28) => BU2_douta(0),
      DIA(27) => BU2_douta(0),
      DIA(26) => BU2_douta(0),
      DIA(25) => BU2_douta(0),
      DIA(24) => BU2_douta(0),
      DIA(23) => BU2_douta(0),
      DIA(22) => BU2_douta(0),
      DIA(21) => BU2_douta(0),
      DIA(20) => BU2_douta(0),
      DIA(19) => BU2_douta(0),
      DIA(18) => BU2_douta(0),
      DIA(17) => BU2_douta(0),
      DIA(16) => BU2_douta(0),
      DIA(15) => dina_2(52),
      DIA(14) => dina_2(51),
      DIA(13) => dina_2(50),
      DIA(12) => dina_2(49),
      DIA(11) => dina_2(48),
      DIA(10) => dina_2(47),
      DIA(9) => dina_2(46),
      DIA(8) => dina_2(45),
      DIA(7) => dina_2(43),
      DIA(6) => dina_2(42),
      DIA(5) => dina_2(41),
      DIA(4) => dina_2(40),
      DIA(3) => dina_2(39),
      DIA(2) => dina_2(38),
      DIA(1) => dina_2(37),
      DIA(0) => dina_2(36),
      DIPA(3) => BU2_douta(0),
      DIPA(2) => BU2_douta(0),
      DIPA(1) => dina_2(53),
      DIPA(0) => dina_2(44),
      DIB(31) => BU2_douta(0),
      DIB(30) => BU2_douta(0),
      DIB(29) => BU2_douta(0),
      DIB(28) => BU2_douta(0),
      DIB(27) => BU2_douta(0),
      DIB(26) => BU2_douta(0),
      DIB(25) => BU2_douta(0),
      DIB(24) => BU2_douta(0),
      DIB(23) => BU2_douta(0),
      DIB(22) => BU2_douta(0),
      DIB(21) => BU2_douta(0),
      DIB(20) => BU2_douta(0),
      DIB(19) => BU2_douta(0),
      DIB(18) => BU2_douta(0),
      DIB(17) => BU2_douta(0),
      DIB(16) => BU2_douta(0),
      DIB(15) => BU2_douta(0),
      DIB(14) => BU2_douta(0),
      DIB(13) => BU2_douta(0),
      DIB(12) => BU2_douta(0),
      DIB(11) => BU2_douta(0),
      DIB(10) => BU2_douta(0),
      DIB(9) => BU2_douta(0),
      DIB(8) => BU2_douta(0),
      DIB(7) => BU2_douta(0),
      DIB(6) => BU2_douta(0),
      DIB(5) => BU2_douta(0),
      DIB(4) => BU2_douta(0),
      DIB(3) => BU2_douta(0),
      DIB(2) => BU2_douta(0),
      DIB(1) => BU2_douta(0),
      DIB(0) => BU2_douta(0),
      DIPB(3) => BU2_douta(0),
      DIPB(2) => BU2_douta(0),
      DIPB(1) => BU2_douta(0),
      DIPB(0) => BU2_douta(0),
      ADDRAL(15) => BU2_douta(0),
      ADDRAL(14) => addra_3(10),
      ADDRAL(13) => addra_3(9),
      ADDRAL(12) => addra_3(8),
      ADDRAL(11) => addra_3(7),
      ADDRAL(10) => addra_3(6),
      ADDRAL(9) => addra_3(5),
      ADDRAL(8) => addra_3(4),
      ADDRAL(7) => addra_3(3),
      ADDRAL(6) => addra_3(2),
      ADDRAL(5) => addra_3(1),
      ADDRAL(4) => addra_3(0),
      ADDRAL(3) => BU2_douta(0),
      ADDRAL(2) => BU2_douta(0),
      ADDRAL(1) => BU2_douta(0),
      ADDRAL(0) => BU2_douta(0),
      ADDRAU(14) => addra_3(10),
      ADDRAU(13) => addra_3(9),
      ADDRAU(12) => addra_3(8),
      ADDRAU(11) => addra_3(7),
      ADDRAU(10) => addra_3(6),
      ADDRAU(9) => addra_3(5),
      ADDRAU(8) => addra_3(4),
      ADDRAU(7) => addra_3(3),
      ADDRAU(6) => addra_3(2),
      ADDRAU(5) => addra_3(1),
      ADDRAU(4) => addra_3(0),
      ADDRAU(3) => BU2_douta(0),
      ADDRAU(2) => BU2_douta(0),
      ADDRAU(1) => BU2_douta(0),
      ADDRAU(0) => BU2_douta(0),
      ADDRBL(15) => BU2_douta(0),
      ADDRBL(14) => addrb_5(10),
      ADDRBL(13) => addrb_5(9),
      ADDRBL(12) => addrb_5(8),
      ADDRBL(11) => addrb_5(7),
      ADDRBL(10) => addrb_5(6),
      ADDRBL(9) => addrb_5(5),
      ADDRBL(8) => addrb_5(4),
      ADDRBL(7) => addrb_5(3),
      ADDRBL(6) => addrb_5(2),
      ADDRBL(5) => addrb_5(1),
      ADDRBL(4) => addrb_5(0),
      ADDRBL(3) => BU2_douta(0),
      ADDRBL(2) => BU2_douta(0),
      ADDRBL(1) => BU2_douta(0),
      ADDRBL(0) => BU2_douta(0),
      ADDRBU(14) => addrb_5(10),
      ADDRBU(13) => addrb_5(9),
      ADDRBU(12) => addrb_5(8),
      ADDRBU(11) => addrb_5(7),
      ADDRBU(10) => addrb_5(6),
      ADDRBU(9) => addrb_5(5),
      ADDRBU(8) => addrb_5(4),
      ADDRBU(7) => addrb_5(3),
      ADDRBU(6) => addrb_5(2),
      ADDRBU(5) => addrb_5(1),
      ADDRBU(4) => addrb_5(0),
      ADDRBU(3) => BU2_douta(0),
      ADDRBU(2) => BU2_douta(0),
      ADDRBU(1) => BU2_douta(0),
      ADDRBU(0) => BU2_douta(0),
      WEAU(3) => wea_4(0),
      WEAU(2) => wea_4(0),
      WEAU(1) => wea_4(0),
      WEAU(0) => wea_4(0),
      WEAL(3) => wea_4(0),
      WEAL(2) => wea_4(0),
      WEAL(1) => wea_4(0),
      WEAL(0) => wea_4(0),
      WEBU(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_7_UNCONNECTED,
      WEBU(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_6_UNCONNECTED,
      WEBU(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_5_UNCONNECTED,
      WEBU(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_4_UNCONNECTED,
      WEBU(3) => BU2_douta(0),
      WEBU(2) => BU2_douta(0),
      WEBU(1) => BU2_douta(0),
      WEBU(0) => BU2_douta(0),
      WEBL(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_7_UNCONNECTED,
      WEBL(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_6_UNCONNECTED,
      WEBL(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_5_UNCONNECTED,
      WEBL(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_4_UNCONNECTED,
      WEBL(3) => BU2_douta(0),
      WEBL(2) => BU2_douta(0),
      WEBL(1) => BU2_douta(0),
      WEBL(0) => BU2_douta(0),
      DOA(31) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_31_UNCONNECTED,
      DOA(30) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_30_UNCONNECTED,
      DOA(29) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_29_UNCONNECTED,
      DOA(28) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_28_UNCONNECTED,
      DOA(27) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_27_UNCONNECTED,
      DOA(26) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_26_UNCONNECTED,
      DOA(25) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_25_UNCONNECTED,
      DOA(24) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_24_UNCONNECTED,
      DOA(23) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_23_UNCONNECTED,
      DOA(22) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_22_UNCONNECTED,
      DOA(21) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_21_UNCONNECTED,
      DOA(20) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_20_UNCONNECTED,
      DOA(19) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_19_UNCONNECTED,
      DOA(18) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_18_UNCONNECTED,
      DOA(17) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_17_UNCONNECTED,
      DOA(16) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_16_UNCONNECTED,
      DOA(15) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_15_UNCONNECTED,
      DOA(14) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_14_UNCONNECTED,
      DOA(13) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_13_UNCONNECTED,
      DOA(12) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_12_UNCONNECTED,
      DOA(11) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_11_UNCONNECTED,
      DOA(10) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_10_UNCONNECTED,
      DOA(9) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_9_UNCONNECTED,
      DOA(8) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_8_UNCONNECTED,
      DOA(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_7_UNCONNECTED,
      DOA(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_6_UNCONNECTED,
      DOA(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_5_UNCONNECTED,
      DOA(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_4_UNCONNECTED,
      DOA(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_3_UNCONNECTED,
      DOA(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_2_UNCONNECTED,
      DOA(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_1_UNCONNECTED,
      DOA(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_0_UNCONNECTED,
      DOPA(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_3_UNCONNECTED,
      DOPA(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_2_UNCONNECTED,
      DOPA(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_1_UNCONNECTED,
      DOPA(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_0_UNCONNECTED,
      DOB(31) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_31_UNCONNECTED,
      DOB(30) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_30_UNCONNECTED,
      DOB(29) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_29_UNCONNECTED,
      DOB(28) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_28_UNCONNECTED,
      DOB(27) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_27_UNCONNECTED,
      DOB(26) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_26_UNCONNECTED,
      DOB(25) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_25_UNCONNECTED,
      DOB(24) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_24_UNCONNECTED,
      DOB(23) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_23_UNCONNECTED,
      DOB(22) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_22_UNCONNECTED,
      DOB(21) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_21_UNCONNECTED,
      DOB(20) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_20_UNCONNECTED,
      DOB(19) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_19_UNCONNECTED,
      DOB(18) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_18_UNCONNECTED,
      DOB(17) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_17_UNCONNECTED,
      DOB(16) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_16_UNCONNECTED,
      DOB(15) => doutb_6(52),
      DOB(14) => doutb_6(51),
      DOB(13) => doutb_6(50),
      DOB(12) => doutb_6(49),
      DOB(11) => doutb_6(48),
      DOB(10) => doutb_6(47),
      DOB(9) => doutb_6(46),
      DOB(8) => doutb_6(45),
      DOB(7) => doutb_6(43),
      DOB(6) => doutb_6(42),
      DOB(5) => doutb_6(41),
      DOB(4) => doutb_6(40),
      DOB(3) => doutb_6(39),
      DOB(2) => doutb_6(38),
      DOB(1) => doutb_6(37),
      DOB(0) => doutb_6(36),
      DOPB(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_3_UNCONNECTED,
      DOPB(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_2_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_2_UNCONNECTED,
      DOPB(1) => doutb_6(53),
      DOPB(0) => doutb_6(44)
    );
  BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP : RAMB36_EXP
    generic map(
      DOA_REG => 0,
      DOB_REG => 0,
      SRVAL_A => X"000000000",
      SRVAL_B => X"000000000",
      INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
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
      INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_40 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_41 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_43 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_50 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_51 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_54 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_58 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_FILE => "NONE",
      INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
      RAM_EXTENSION_A => "NONE",
      RAM_EXTENSION_B => "NONE",
      READ_WIDTH_A => 18,
      READ_WIDTH_B => 18,
      SIM_COLLISION_CHECK => "ALL",
      INIT_A => X"000000000",
      INIT_B => X"000000000",
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
      WRITE_WIDTH_A => 18,
      WRITE_WIDTH_B => 18,
      INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000"
    )
    port map (
      ENAU => ena,
      ENAL => ena,
      ENBU => enb,
      ENBL => enb,
      SSRAU => BU2_douta(0),
      SSRAL => BU2_douta(0),
      SSRBU => BU2_douta(0),
      SSRBL => BU2_douta(0),
      CLKAU => clka,
      CLKAL => clka,
      CLKBU => clkb,
      CLKBL => clkb,
      REGCLKAU => clka,
      REGCLKAL => clka,
      REGCLKBU => clkb,
      REGCLKBL => clkb,
      REGCEAU => BU2_douta(0),
      REGCEAL => BU2_douta(0),
      REGCEBU => BU2_douta(0),
      REGCEBL => BU2_douta(0),
      CASCADEINLATA => BU2_douta(0),
      CASCADEINLATB => BU2_douta(0),
      CASCADEINREGA => BU2_douta(0),
      CASCADEINREGB => BU2_douta(0),
      CASCADEOUTLATA => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATA_UNCONNECTED,
      CASCADEOUTLATB => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTLATB_UNCONNECTED,
      CASCADEOUTREGA => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGA_UNCONNECTED,
      CASCADEOUTREGB => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_CASCADEOUTREGB_UNCONNECTED,
      DIA(31) => BU2_douta(0),
      DIA(30) => BU2_douta(0),
      DIA(29) => BU2_douta(0),
      DIA(28) => BU2_douta(0),
      DIA(27) => BU2_douta(0),
      DIA(26) => BU2_douta(0),
      DIA(25) => BU2_douta(0),
      DIA(24) => BU2_douta(0),
      DIA(23) => BU2_douta(0),
      DIA(22) => BU2_douta(0),
      DIA(21) => BU2_douta(0),
      DIA(20) => BU2_douta(0),
      DIA(19) => BU2_douta(0),
      DIA(18) => BU2_douta(0),
      DIA(17) => BU2_douta(0),
      DIA(16) => BU2_douta(0),
      DIA(15) => BU2_douta(0),
      DIA(14) => BU2_douta(0),
      DIA(13) => BU2_douta(0),
      DIA(12) => dina_2(63),
      DIA(11) => dina_2(62),
      DIA(10) => dina_2(61),
      DIA(9) => dina_2(60),
      DIA(8) => dina_2(59),
      DIA(7) => BU2_douta(0),
      DIA(6) => BU2_douta(0),
      DIA(5) => BU2_douta(0),
      DIA(4) => dina_2(58),
      DIA(3) => dina_2(57),
      DIA(2) => dina_2(56),
      DIA(1) => dina_2(55),
      DIA(0) => dina_2(54),
      DIPA(3) => BU2_douta(0),
      DIPA(2) => BU2_douta(0),
      DIPA(1) => BU2_douta(0),
      DIPA(0) => BU2_douta(0),
      DIB(31) => BU2_douta(0),
      DIB(30) => BU2_douta(0),
      DIB(29) => BU2_douta(0),
      DIB(28) => BU2_douta(0),
      DIB(27) => BU2_douta(0),
      DIB(26) => BU2_douta(0),
      DIB(25) => BU2_douta(0),
      DIB(24) => BU2_douta(0),
      DIB(23) => BU2_douta(0),
      DIB(22) => BU2_douta(0),
      DIB(21) => BU2_douta(0),
      DIB(20) => BU2_douta(0),
      DIB(19) => BU2_douta(0),
      DIB(18) => BU2_douta(0),
      DIB(17) => BU2_douta(0),
      DIB(16) => BU2_douta(0),
      DIB(15) => BU2_douta(0),
      DIB(14) => BU2_douta(0),
      DIB(13) => BU2_douta(0),
      DIB(12) => BU2_douta(0),
      DIB(11) => BU2_douta(0),
      DIB(10) => BU2_douta(0),
      DIB(9) => BU2_douta(0),
      DIB(8) => BU2_douta(0),
      DIB(7) => BU2_douta(0),
      DIB(6) => BU2_douta(0),
      DIB(5) => BU2_douta(0),
      DIB(4) => BU2_douta(0),
      DIB(3) => BU2_douta(0),
      DIB(2) => BU2_douta(0),
      DIB(1) => BU2_douta(0),
      DIB(0) => BU2_douta(0),
      DIPB(3) => BU2_douta(0),
      DIPB(2) => BU2_douta(0),
      DIPB(1) => BU2_douta(0),
      DIPB(0) => BU2_douta(0),
      ADDRAL(15) => BU2_douta(0),
      ADDRAL(14) => addra_3(10),
      ADDRAL(13) => addra_3(9),
      ADDRAL(12) => addra_3(8),
      ADDRAL(11) => addra_3(7),
      ADDRAL(10) => addra_3(6),
      ADDRAL(9) => addra_3(5),
      ADDRAL(8) => addra_3(4),
      ADDRAL(7) => addra_3(3),
      ADDRAL(6) => addra_3(2),
      ADDRAL(5) => addra_3(1),
      ADDRAL(4) => addra_3(0),
      ADDRAL(3) => BU2_douta(0),
      ADDRAL(2) => BU2_douta(0),
      ADDRAL(1) => BU2_douta(0),
      ADDRAL(0) => BU2_douta(0),
      ADDRAU(14) => addra_3(10),
      ADDRAU(13) => addra_3(9),
      ADDRAU(12) => addra_3(8),
      ADDRAU(11) => addra_3(7),
      ADDRAU(10) => addra_3(6),
      ADDRAU(9) => addra_3(5),
      ADDRAU(8) => addra_3(4),
      ADDRAU(7) => addra_3(3),
      ADDRAU(6) => addra_3(2),
      ADDRAU(5) => addra_3(1),
      ADDRAU(4) => addra_3(0),
      ADDRAU(3) => BU2_douta(0),
      ADDRAU(2) => BU2_douta(0),
      ADDRAU(1) => BU2_douta(0),
      ADDRAU(0) => BU2_douta(0),
      ADDRBL(15) => BU2_douta(0),
      ADDRBL(14) => addrb_5(10),
      ADDRBL(13) => addrb_5(9),
      ADDRBL(12) => addrb_5(8),
      ADDRBL(11) => addrb_5(7),
      ADDRBL(10) => addrb_5(6),
      ADDRBL(9) => addrb_5(5),
      ADDRBL(8) => addrb_5(4),
      ADDRBL(7) => addrb_5(3),
      ADDRBL(6) => addrb_5(2),
      ADDRBL(5) => addrb_5(1),
      ADDRBL(4) => addrb_5(0),
      ADDRBL(3) => BU2_douta(0),
      ADDRBL(2) => BU2_douta(0),
      ADDRBL(1) => BU2_douta(0),
      ADDRBL(0) => BU2_douta(0),
      ADDRBU(14) => addrb_5(10),
      ADDRBU(13) => addrb_5(9),
      ADDRBU(12) => addrb_5(8),
      ADDRBU(11) => addrb_5(7),
      ADDRBU(10) => addrb_5(6),
      ADDRBU(9) => addrb_5(5),
      ADDRBU(8) => addrb_5(4),
      ADDRBU(7) => addrb_5(3),
      ADDRBU(6) => addrb_5(2),
      ADDRBU(5) => addrb_5(1),
      ADDRBU(4) => addrb_5(0),
      ADDRBU(3) => BU2_douta(0),
      ADDRBU(2) => BU2_douta(0),
      ADDRBU(1) => BU2_douta(0),
      ADDRBU(0) => BU2_douta(0),
      WEAU(3) => wea_4(0),
      WEAU(2) => wea_4(0),
      WEAU(1) => wea_4(0),
      WEAU(0) => wea_4(0),
      WEAL(3) => wea_4(0),
      WEAL(2) => wea_4(0),
      WEAL(1) => wea_4(0),
      WEAL(0) => wea_4(0),
      WEBU(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_7_UNCONNECTED,
      WEBU(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_6_UNCONNECTED,
      WEBU(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_5_UNCONNECTED,
      WEBU(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBU_4_UNCONNECTED,
      WEBU(3) => BU2_douta(0),
      WEBU(2) => BU2_douta(0),
      WEBU(1) => BU2_douta(0),
      WEBU(0) => BU2_douta(0),
      WEBL(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_7_UNCONNECTED,
      WEBL(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_6_UNCONNECTED,
      WEBL(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_5_UNCONNECTED,
      WEBL(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_WEBL_4_UNCONNECTED,
      WEBL(3) => BU2_douta(0),
      WEBL(2) => BU2_douta(0),
      WEBL(1) => BU2_douta(0),
      WEBL(0) => BU2_douta(0),
      DOA(31) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_31_UNCONNECTED,
      DOA(30) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_30_UNCONNECTED,
      DOA(29) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_29_UNCONNECTED,
      DOA(28) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_28_UNCONNECTED,
      DOA(27) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_27_UNCONNECTED,
      DOA(26) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_26_UNCONNECTED,
      DOA(25) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_25_UNCONNECTED,
      DOA(24) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_24_UNCONNECTED,
      DOA(23) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_23_UNCONNECTED,
      DOA(22) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_22_UNCONNECTED,
      DOA(21) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_21_UNCONNECTED,
      DOA(20) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_20_UNCONNECTED,
      DOA(19) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_19_UNCONNECTED,
      DOA(18) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_18_UNCONNECTED,
      DOA(17) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_17_UNCONNECTED,
      DOA(16) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_16_UNCONNECTED,
      DOA(15) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_15_UNCONNECTED,
      DOA(14) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_14_UNCONNECTED,
      DOA(13) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_13_UNCONNECTED,
      DOA(12) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_12_UNCONNECTED,
      DOA(11) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_11_UNCONNECTED,
      DOA(10) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_10_UNCONNECTED,
      DOA(9) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_9_UNCONNECTED,
      DOA(8) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_8_UNCONNECTED,
      DOA(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_7_UNCONNECTED,
      DOA(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_6_UNCONNECTED,
      DOA(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_5_UNCONNECTED,
      DOA(4) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_4_UNCONNECTED,
      DOA(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_3_UNCONNECTED,
      DOA(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_2_UNCONNECTED,
      DOA(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_1_UNCONNECTED,
      DOA(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOA_0_UNCONNECTED,
      DOPA(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_3_UNCONNECTED,
      DOPA(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_2_UNCONNECTED,
      DOPA(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_1_UNCONNECTED,
      DOPA(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPA_0_UNCONNECTED,
      DOB(31) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_31_UNCONNECTED,
      DOB(30) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_30_UNCONNECTED,
      DOB(29) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_29_UNCONNECTED,
      DOB(28) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_28_UNCONNECTED,
      DOB(27) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_27_UNCONNECTED,
      DOB(26) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_26_UNCONNECTED,
      DOB(25) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_25_UNCONNECTED,
      DOB(24) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_24_UNCONNECTED,
      DOB(23) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_23_UNCONNECTED,
      DOB(22) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_22_UNCONNECTED,
      DOB(21) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_21_UNCONNECTED,
      DOB(20) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_20_UNCONNECTED,
      DOB(19) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_19_UNCONNECTED,
      DOB(18) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_18_UNCONNECTED,
      DOB(17) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_17_UNCONNECTED,
      DOB(16) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_16_UNCONNECTED,
      DOB(15) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_15_UNCONNECTED,
      DOB(14) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_14_UNCONNECTED,
      DOB(13) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_13_UNCONNECTED,
      DOB(12) => doutb_6(63),
      DOB(11) => doutb_6(62),
      DOB(10) => doutb_6(61),
      DOB(9) => doutb_6(60),
      DOB(8) => doutb_6(59),
      DOB(7) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_7_UNCONNECTED,
      DOB(6) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_6_UNCONNECTED,
      DOB(5) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOB_5_UNCONNECTED,
      DOB(4) => doutb_6(58),
      DOB(3) => doutb_6(57),
      DOB(2) => doutb_6(56),
      DOB(1) => doutb_6(55),
      DOB(0) => doutb_6(54),
      DOPB(3) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_3_UNCONNECTED,
      DOPB(2) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_2_UNCONNECTED,
      DOPB(1) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_1_UNCONNECTED,
      DOPB(0) => NLW_BU2_U0_blk_mem_generator_valid_cstr_ramloop_3_ram_r_v5_init_ram_SDP_SINGLE_PRIM36_TDP_DOPB_0_UNCONNECTED
    );
  BU2_XST_GND : GND
    port map (
      G => BU2_douta(0)
    );

end STRUCTURE;

-- synopsys translate_on
