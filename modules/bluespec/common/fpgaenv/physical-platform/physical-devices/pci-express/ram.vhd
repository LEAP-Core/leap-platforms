--------------------------------------------------------------------------------
-- Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: J.39
--  \   \         Application: netgen
--  /   /         Filename: ram.vhd
-- /___/   /\     Timestamp: Fri Jan 18 16:05:17 2008
-- \   \  /  \ 
--  \___\/\___\
--             
-- Command	: -intstyle ise -w -sim -ofmt vhdl C:\lwang\Projects\HW_Channel(CSR)\HW_Channel(01.18)(50t)\tmp\_cg\ram.ngc C:\lwang\Projects\HW_Channel(CSR)\HW_Channel(01.18)(50t)\tmp\_cg\ram.vhd 
-- Device	: 5vlx50tff1136-1
-- Input file	: C:/lwang/Projects/HW_Channel(CSR)/HW_Channel(01.18)(50t)/tmp/_cg/ram.ngc
-- Output file	: C:/lwang/Projects/HW_Channel(CSR)/HW_Channel(01.18)(50t)/tmp/_cg/ram.vhd
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
      INIT_00 => X"000E000F000C000D000A000B0008000900060007000400050002000300000001",
      INIT_01 => X"001E001F001C001D001A001B0018001900160017001400150012001300100011",
      INIT_02 => X"002E002F002C002D002A002B0028002900260027002400250022002300200021",
      INIT_03 => X"0000000000000000000000000000000000000000000000000000000000300031",
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
