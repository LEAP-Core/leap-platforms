--------------------------------------------------------------------------------
-- Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: J.39
--  \   \         Application: netgen
--  /   /         Filename: h2f_data_fifo.vhd
-- /___/   /\     Timestamp: Fri Jan 18 15:55:06 2008
-- \   \  /  \ 
--  \___\/\___\
--             
-- Command	: -intstyle ise -w -sim -ofmt vhdl C:\lwang\Projects\HW_Channel(CSR)\HW_Channel(01.18)(50t)\tmp\_cg\h2f_data_fifo.ngc C:\lwang\Projects\HW_Channel(CSR)\HW_Channel(01.18)(50t)\tmp\_cg\h2f_data_fifo.vhd 
-- Device	: 5vlx50tff1136-1
-- Input file	: C:/lwang/Projects/HW_Channel(CSR)/HW_Channel(01.18)(50t)/tmp/_cg/h2f_data_fifo.ngc
-- Output file	: C:/lwang/Projects/HW_Channel(CSR)/HW_Channel(01.18)(50t)/tmp/_cg/h2f_data_fifo.vhd
-- # of Entities	: 1
-- Design Name	: h2f_data_fifo
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

entity h2f_data_fifo is
  port (
    valid : out STD_LOGIC; 
    rd_en : in STD_LOGIC := 'X'; 
    wr_en : in STD_LOGIC := 'X'; 
    full : out STD_LOGIC; 
    empty : out STD_LOGIC; 
    wr_clk : in STD_LOGIC := 'X'; 
    rst : in STD_LOGIC := 'X'; 
    almost_full : out STD_LOGIC; 
    rd_clk : in STD_LOGIC := 'X'; 
    dout : out STD_LOGIC_VECTOR ( 63 downto 0 ); 
    din : in STD_LOGIC_VECTOR ( 63 downto 0 ) 
  );
end h2f_data_fifo;

architecture STRUCTURE of h2f_data_fifo is
  signal NlwRenamedSig_OI_empty : STD_LOGIC; 
  signal BU2_U0_grf_rf_mem_tmp_ram_rd_en : STD_LOGIC; 
  signal BU2_N436 : STD_LOGIC; 
  signal BU2_N434 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000_map11 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000_map28 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000_map11 : STD_LOGIC; 
  signal BU2_N336 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000_map28 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map11 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map57 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map40 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map28 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count6 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count3 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count9 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count12 : STD_LOGIC; 
  signal BU2_U0_grf_rf_ram_wr_en : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0003 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0002 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0001 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0000 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0003 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0002 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0001 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0000 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0003 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0002 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0001 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0000 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0003 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0002 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0001 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0000 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count12 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count9 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count6 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count3 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_fb_i_2 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_not0001 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_wr_gwas_wsts_wr_rst_d1_3 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_grhf_rhf_ram_valid_d1_and0000 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_4 : STD_LOGIC; 
  signal BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000 : STD_LOGIC; 
  signal BU2_U0_grf_rf_rstblk_wr_rst_comb : STD_LOGIC; 
  signal BU2_U0_grf_rf_rstblk_rd_rst_comb : STD_LOGIC; 
  signal BU2_U0_grf_rf_rstblk_wr_rst_asreg_5 : STD_LOGIC; 
  signal BU2_U0_grf_rf_rstblk_rd_rst_asreg_6 : STD_LOGIC; 
  signal BU2_U0_grf_rf_rstblk_wr_rst_asreg_d2_7 : STD_LOGIC; 
  signal BU2_U0_grf_rf_rstblk_wr_rst_asreg_d1_8 : STD_LOGIC; 
  signal BU2_U0_grf_rf_rstblk_rd_rst_asreg_d2_9 : STD_LOGIC; 
  signal BU2_U0_grf_rf_rstblk_rd_rst_asreg_d1_10 : STD_LOGIC; 
  signal BU2_N1 : STD_LOGIC; 
  signal NLW_VCC_P_UNCONNECTED : STD_LOGIC; 
  signal NLW_GND_G_UNCONNECTED : STD_LOGIC; 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_SBITERR_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DBITERR_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_15_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_5_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_4_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_3_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_2_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_1_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_0_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_5_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_4_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_3_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_2_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_1_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_0_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_15_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_5_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_4_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_3_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_2_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_1_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_0_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_5_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_4_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_3_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_2_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_1_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_0_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_7_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_6_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_5_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_4_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_3_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_2_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_1_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_0_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_7_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_6_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_5_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_4_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_3_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_2_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_1_UNCONNECTED : STD_LOGIC;
 
  signal NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_0_UNCONNECTED : STD_LOGIC;
 
  signal din_11 : STD_LOGIC_VECTOR ( 63 downto 0 ); 
  signal dout_12 : STD_LOGIC_VECTOR ( 63 downto 0 ); 
  signal BU2_U0_grf_rf_gl0_wr_wpntr_count_d3 : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gl0_wr_wpntr_count_d2 : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gl0_wr_wpntr_count_d1 : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gl0_wr_wpntr_count : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1 : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1 : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gl0_rd_rpntr_count_d1 : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_gl0_rd_rpntr_count : STD_LOGIC_VECTOR ( 4 downto 0 ); 
  signal BU2_U0_grf_rf_rstblk_wr_rst_reg : STD_LOGIC_VECTOR ( 1 downto 0 ); 
  signal BU2_U0_grf_rf_rstblk_rd_rst_reg : STD_LOGIC_VECTOR ( 2 downto 0 ); 
  signal BU2_rd_data_count : STD_LOGIC_VECTOR ( 0 downto 0 ); 
begin
  empty <= NlwRenamedSig_OI_empty;
  dout(63) <= dout_12(63);
  dout(62) <= dout_12(62);
  dout(61) <= dout_12(61);
  dout(60) <= dout_12(60);
  dout(59) <= dout_12(59);
  dout(58) <= dout_12(58);
  dout(57) <= dout_12(57);
  dout(56) <= dout_12(56);
  dout(55) <= dout_12(55);
  dout(54) <= dout_12(54);
  dout(53) <= dout_12(53);
  dout(52) <= dout_12(52);
  dout(51) <= dout_12(51);
  dout(50) <= dout_12(50);
  dout(49) <= dout_12(49);
  dout(48) <= dout_12(48);
  dout(47) <= dout_12(47);
  dout(46) <= dout_12(46);
  dout(45) <= dout_12(45);
  dout(44) <= dout_12(44);
  dout(43) <= dout_12(43);
  dout(42) <= dout_12(42);
  dout(41) <= dout_12(41);
  dout(40) <= dout_12(40);
  dout(39) <= dout_12(39);
  dout(38) <= dout_12(38);
  dout(37) <= dout_12(37);
  dout(36) <= dout_12(36);
  dout(35) <= dout_12(35);
  dout(34) <= dout_12(34);
  dout(33) <= dout_12(33);
  dout(32) <= dout_12(32);
  dout(31) <= dout_12(31);
  dout(30) <= dout_12(30);
  dout(29) <= dout_12(29);
  dout(28) <= dout_12(28);
  dout(27) <= dout_12(27);
  dout(26) <= dout_12(26);
  dout(25) <= dout_12(25);
  dout(24) <= dout_12(24);
  dout(23) <= dout_12(23);
  dout(22) <= dout_12(22);
  dout(21) <= dout_12(21);
  dout(20) <= dout_12(20);
  dout(19) <= dout_12(19);
  dout(18) <= dout_12(18);
  dout(17) <= dout_12(17);
  dout(16) <= dout_12(16);
  dout(15) <= dout_12(15);
  dout(14) <= dout_12(14);
  dout(13) <= dout_12(13);
  dout(12) <= dout_12(12);
  dout(11) <= dout_12(11);
  dout(10) <= dout_12(10);
  dout(9) <= dout_12(9);
  dout(8) <= dout_12(8);
  dout(7) <= dout_12(7);
  dout(6) <= dout_12(6);
  dout(5) <= dout_12(5);
  dout(4) <= dout_12(4);
  dout(3) <= dout_12(3);
  dout(2) <= dout_12(2);
  dout(1) <= dout_12(1);
  dout(0) <= dout_12(0);
  din_11(63) <= din(63);
  din_11(62) <= din(62);
  din_11(61) <= din(61);
  din_11(60) <= din(60);
  din_11(59) <= din(59);
  din_11(58) <= din(58);
  din_11(57) <= din(57);
  din_11(56) <= din(56);
  din_11(55) <= din(55);
  din_11(54) <= din(54);
  din_11(53) <= din(53);
  din_11(52) <= din(52);
  din_11(51) <= din(51);
  din_11(50) <= din(50);
  din_11(49) <= din(49);
  din_11(48) <= din(48);
  din_11(47) <= din(47);
  din_11(46) <= din(46);
  din_11(45) <= din(45);
  din_11(44) <= din(44);
  din_11(43) <= din(43);
  din_11(42) <= din(42);
  din_11(41) <= din(41);
  din_11(40) <= din(40);
  din_11(39) <= din(39);
  din_11(38) <= din(38);
  din_11(37) <= din(37);
  din_11(36) <= din(36);
  din_11(35) <= din(35);
  din_11(34) <= din(34);
  din_11(33) <= din(33);
  din_11(32) <= din(32);
  din_11(31) <= din(31);
  din_11(30) <= din(30);
  din_11(29) <= din(29);
  din_11(28) <= din(28);
  din_11(27) <= din(27);
  din_11(26) <= din(26);
  din_11(25) <= din(25);
  din_11(24) <= din(24);
  din_11(23) <= din(23);
  din_11(22) <= din(22);
  din_11(21) <= din(21);
  din_11(20) <= din(20);
  din_11(19) <= din(19);
  din_11(18) <= din(18);
  din_11(17) <= din(17);
  din_11(16) <= din(16);
  din_11(15) <= din(15);
  din_11(14) <= din(14);
  din_11(13) <= din(13);
  din_11(12) <= din(12);
  din_11(11) <= din(11);
  din_11(10) <= din(10);
  din_11(9) <= din(9);
  din_11(8) <= din(8);
  din_11(7) <= din(7);
  din_11(6) <= din(6);
  din_11(5) <= din(5);
  din_11(4) <= din(4);
  din_11(3) <= din(3);
  din_11(2) <= din(2);
  din_11(1) <= din(1);
  din_11(0) <= din(0);
  VCC_0 : VCC
    port map (
      P => NLW_VCC_P_UNCONNECTED
    );
  GND_1 : GND
    port map (
      G => NLW_GND_G_UNCONNECTED
    );
  BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP : RAMB36SDP_EXP
    generic map(
      DO_REG => 0,
      EN_ECC_READ => FALSE,
      EN_ECC_SCRUB => FALSE,
      EN_ECC_WRITE => FALSE,
      INIT => X"000000000000000000",
      SRVAL => X"000000000000000000",
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
      SIM_COLLISION_CHECK => "NONE",
      INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000"
    )
    port map (
      RDENU => BU2_U0_grf_rf_mem_tmp_ram_rd_en,
      RDENL => BU2_U0_grf_rf_mem_tmp_ram_rd_en,
      WRENU => BU2_N1,
      WRENL => BU2_N1,
      SSRU => BU2_U0_grf_rf_rstblk_rd_rst_reg(0),
      SSRL => BU2_U0_grf_rf_rstblk_rd_rst_reg(0),
      RDCLKU => rd_clk,
      RDCLKL => rd_clk,
      WRCLKU => wr_clk,
      WRCLKL => wr_clk,
      RDRCLKU => rd_clk,
      RDRCLKL => rd_clk,
      REGCEU => BU2_rd_data_count(0),
      REGCEL => BU2_rd_data_count(0),
      SBITERR => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_SBITERR_UNCONNECTED,
      DBITERR => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DBITERR_UNCONNECTED,
      DI(63) => din_11(63),
      DI(62) => din_11(62),
      DI(61) => din_11(61),
      DI(60) => din_11(60),
      DI(59) => din_11(59),
      DI(58) => din_11(58),
      DI(57) => din_11(57),
      DI(56) => din_11(56),
      DI(55) => din_11(55),
      DI(54) => din_11(54),
      DI(53) => din_11(53),
      DI(52) => din_11(52),
      DI(51) => din_11(51),
      DI(50) => din_11(50),
      DI(49) => din_11(49),
      DI(48) => din_11(48),
      DI(47) => din_11(47),
      DI(46) => din_11(46),
      DI(45) => din_11(45),
      DI(44) => din_11(44),
      DI(43) => din_11(43),
      DI(42) => din_11(42),
      DI(41) => din_11(41),
      DI(40) => din_11(40),
      DI(39) => din_11(39),
      DI(38) => din_11(38),
      DI(37) => din_11(37),
      DI(36) => din_11(36),
      DI(35) => din_11(35),
      DI(34) => din_11(34),
      DI(33) => din_11(33),
      DI(32) => din_11(32),
      DI(31) => din_11(31),
      DI(30) => din_11(30),
      DI(29) => din_11(29),
      DI(28) => din_11(28),
      DI(27) => din_11(27),
      DI(26) => din_11(26),
      DI(25) => din_11(25),
      DI(24) => din_11(24),
      DI(23) => din_11(23),
      DI(22) => din_11(22),
      DI(21) => din_11(21),
      DI(20) => din_11(20),
      DI(19) => din_11(19),
      DI(18) => din_11(18),
      DI(17) => din_11(17),
      DI(16) => din_11(16),
      DI(15) => din_11(15),
      DI(14) => din_11(14),
      DI(13) => din_11(13),
      DI(12) => din_11(12),
      DI(11) => din_11(11),
      DI(10) => din_11(10),
      DI(9) => din_11(9),
      DI(8) => din_11(8),
      DI(7) => din_11(7),
      DI(6) => din_11(6),
      DI(5) => din_11(5),
      DI(4) => din_11(4),
      DI(3) => din_11(3),
      DI(2) => din_11(2),
      DI(1) => din_11(1),
      DI(0) => din_11(0),
      DIP(7) => BU2_rd_data_count(0),
      DIP(6) => BU2_rd_data_count(0),
      DIP(5) => BU2_rd_data_count(0),
      DIP(4) => BU2_rd_data_count(0),
      DIP(3) => BU2_rd_data_count(0),
      DIP(2) => BU2_rd_data_count(0),
      DIP(1) => BU2_rd_data_count(0),
      DIP(0) => BU2_rd_data_count(0),
      RDADDRL(15) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_15_UNCONNECTED
,
      RDADDRL(14) => BU2_rd_data_count(0),
      RDADDRL(13) => BU2_rd_data_count(0),
      RDADDRL(12) => BU2_rd_data_count(0),
      RDADDRL(11) => BU2_rd_data_count(0),
      RDADDRL(10) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(4),
      RDADDRL(9) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(3),
      RDADDRL(8) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(2),
      RDADDRL(7) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(1),
      RDADDRL(6) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(0),
      RDADDRL(5) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_5_UNCONNECTED,
      RDADDRL(4) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_4_UNCONNECTED,
      RDADDRL(3) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_3_UNCONNECTED,
      RDADDRL(2) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_2_UNCONNECTED,
      RDADDRL(1) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_1_UNCONNECTED,
      RDADDRL(0) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRL_0_UNCONNECTED,
      RDADDRU(14) => BU2_rd_data_count(0),
      RDADDRU(13) => BU2_rd_data_count(0),
      RDADDRU(12) => BU2_rd_data_count(0),
      RDADDRU(11) => BU2_rd_data_count(0),
      RDADDRU(10) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(4),
      RDADDRU(9) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(3),
      RDADDRU(8) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(2),
      RDADDRU(7) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(1),
      RDADDRU(6) => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(0),
      RDADDRU(5) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_5_UNCONNECTED,
      RDADDRU(4) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_4_UNCONNECTED,
      RDADDRU(3) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_3_UNCONNECTED,
      RDADDRU(2) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_2_UNCONNECTED,
      RDADDRU(1) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_1_UNCONNECTED,
      RDADDRU(0) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_RDADDRU_0_UNCONNECTED,
      WRADDRL(15) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_15_UNCONNECTED
,
      WRADDRL(14) => BU2_rd_data_count(0),
      WRADDRL(13) => BU2_rd_data_count(0),
      WRADDRL(12) => BU2_rd_data_count(0),
      WRADDRL(11) => BU2_rd_data_count(0),
      WRADDRL(10) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(4),
      WRADDRL(9) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(3),
      WRADDRL(8) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(2),
      WRADDRL(7) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(1),
      WRADDRL(6) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(0),
      WRADDRL(5) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_5_UNCONNECTED,
      WRADDRL(4) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_4_UNCONNECTED,
      WRADDRL(3) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_3_UNCONNECTED,
      WRADDRL(2) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_2_UNCONNECTED,
      WRADDRL(1) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_1_UNCONNECTED,
      WRADDRL(0) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRL_0_UNCONNECTED,
      WRADDRU(14) => BU2_rd_data_count(0),
      WRADDRU(13) => BU2_rd_data_count(0),
      WRADDRU(12) => BU2_rd_data_count(0),
      WRADDRU(11) => BU2_rd_data_count(0),
      WRADDRU(10) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(4),
      WRADDRU(9) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(3),
      WRADDRU(8) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(2),
      WRADDRU(7) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(1),
      WRADDRU(6) => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(0),
      WRADDRU(5) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_5_UNCONNECTED,
      WRADDRU(4) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_4_UNCONNECTED,
      WRADDRU(3) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_3_UNCONNECTED,
      WRADDRU(2) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_2_UNCONNECTED,
      WRADDRU(1) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_1_UNCONNECTED,
      WRADDRU(0) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_WRADDRU_0_UNCONNECTED,
      WEU(7) => BU2_U0_grf_rf_ram_wr_en,
      WEU(6) => BU2_U0_grf_rf_ram_wr_en,
      WEU(5) => BU2_U0_grf_rf_ram_wr_en,
      WEU(4) => BU2_U0_grf_rf_ram_wr_en,
      WEU(3) => BU2_U0_grf_rf_ram_wr_en,
      WEU(2) => BU2_U0_grf_rf_ram_wr_en,
      WEU(1) => BU2_U0_grf_rf_ram_wr_en,
      WEU(0) => BU2_U0_grf_rf_ram_wr_en,
      WEL(7) => BU2_U0_grf_rf_ram_wr_en,
      WEL(6) => BU2_U0_grf_rf_ram_wr_en,
      WEL(5) => BU2_U0_grf_rf_ram_wr_en,
      WEL(4) => BU2_U0_grf_rf_ram_wr_en,
      WEL(3) => BU2_U0_grf_rf_ram_wr_en,
      WEL(2) => BU2_U0_grf_rf_ram_wr_en,
      WEL(1) => BU2_U0_grf_rf_ram_wr_en,
      WEL(0) => BU2_U0_grf_rf_ram_wr_en,
      DO(63) => dout_12(63),
      DO(62) => dout_12(62),
      DO(61) => dout_12(61),
      DO(60) => dout_12(60),
      DO(59) => dout_12(59),
      DO(58) => dout_12(58),
      DO(57) => dout_12(57),
      DO(56) => dout_12(56),
      DO(55) => dout_12(55),
      DO(54) => dout_12(54),
      DO(53) => dout_12(53),
      DO(52) => dout_12(52),
      DO(51) => dout_12(51),
      DO(50) => dout_12(50),
      DO(49) => dout_12(49),
      DO(48) => dout_12(48),
      DO(47) => dout_12(47),
      DO(46) => dout_12(46),
      DO(45) => dout_12(45),
      DO(44) => dout_12(44),
      DO(43) => dout_12(43),
      DO(42) => dout_12(42),
      DO(41) => dout_12(41),
      DO(40) => dout_12(40),
      DO(39) => dout_12(39),
      DO(38) => dout_12(38),
      DO(37) => dout_12(37),
      DO(36) => dout_12(36),
      DO(35) => dout_12(35),
      DO(34) => dout_12(34),
      DO(33) => dout_12(33),
      DO(32) => dout_12(32),
      DO(31) => dout_12(31),
      DO(30) => dout_12(30),
      DO(29) => dout_12(29),
      DO(28) => dout_12(28),
      DO(27) => dout_12(27),
      DO(26) => dout_12(26),
      DO(25) => dout_12(25),
      DO(24) => dout_12(24),
      DO(23) => dout_12(23),
      DO(22) => dout_12(22),
      DO(21) => dout_12(21),
      DO(20) => dout_12(20),
      DO(19) => dout_12(19),
      DO(18) => dout_12(18),
      DO(17) => dout_12(17),
      DO(16) => dout_12(16),
      DO(15) => dout_12(15),
      DO(14) => dout_12(14),
      DO(13) => dout_12(13),
      DO(12) => dout_12(12),
      DO(11) => dout_12(11),
      DO(10) => dout_12(10),
      DO(9) => dout_12(9),
      DO(8) => dout_12(8),
      DO(7) => dout_12(7),
      DO(6) => dout_12(6),
      DO(5) => dout_12(5),
      DO(4) => dout_12(4),
      DO(3) => dout_12(3),
      DO(2) => dout_12(2),
      DO(1) => dout_12(1),
      DO(0) => dout_12(0),
      DOP(7) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_7_UNCONNECTED,
      DOP(6) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_6_UNCONNECTED,
      DOP(5) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_5_UNCONNECTED,
      DOP(4) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_4_UNCONNECTED,
      DOP(3) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_3_UNCONNECTED,
      DOP(2) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_2_UNCONNECTED,
      DOP(1) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_1_UNCONNECTED,
      DOP(0) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_DOP_0_UNCONNECTED,
      ECCPARITY(7) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_7_UNCONNECTED
,
      ECCPARITY(6) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_6_UNCONNECTED
,
      ECCPARITY(5) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_5_UNCONNECTED
,
      ECCPARITY(4) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_4_UNCONNECTED
,
      ECCPARITY(3) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_3_UNCONNECTED
,
      ECCPARITY(2) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_2_UNCONNECTED
,
      ECCPARITY(1) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_1_UNCONNECTED
,
      ECCPARITY(0) => 
NLW_BU2_U0_grf_rf_mem_gbm_gbmg_gbmga_ngecc_bmg_blk_mem_generator_valid_cstr_ramloop_0_ram_r_v5_ram_SDP_WIDE_PRIM36_noeccerr_SDP_ECCPARITY_0_UNCONNECTED

    );
  BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count_xor_0_11_INV_0 : INV
    port map (
      I => BU2_U0_grf_rf_gl0_rd_rpntr_count(0),
      O => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count_xor_0_11_INV_0 : INV
    port map (
      I => BU2_U0_grf_rf_gl0_wr_wpntr_count(0),
      O => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_rd_pntr_bin_xor0003_Result1 : LUT5
    generic map(
      INIT => X"96696996"
    )
    port map (
      I0 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(4),
      I2 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(2),
      I3 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(1),
      I4 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(0),
      O => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0003
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_wr_pntr_bin_xor0003_Result1 : LUT5
    generic map(
      INIT => X"96696996"
    )
    port map (
      I0 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(4),
      I2 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(2),
      I3 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(1),
      I4 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(0),
      O => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0003
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_rd_pntr_bin_xor0002_Result1 : LUT4
    generic map(
      INIT => X"6996"
    )
    port map (
      I0 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(4),
      I2 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(2),
      I3 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(1),
      O => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0002
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_wr_pntr_bin_xor0002_Result1 : LUT4
    generic map(
      INIT => X"6996"
    )
    port map (
      I0 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(4),
      I2 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(2),
      I3 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(1),
      O => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0002
    );
  BU2_U0_grf_rf_mem_tmp_ram_rd_en1 : LUT3
    generic map(
      INIT => X"BA"
    )
    port map (
      I0 => BU2_U0_grf_rf_rstblk_rd_rst_reg(0),
      I1 => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_4,
      I2 => rd_en,
      O => BU2_U0_grf_rf_mem_tmp_ram_rd_en
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000117 : LUT5
    generic map(
      INIT => X"50510011"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_wr_rst_d1_3,
      I1 => BU2_N436,
      I2 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000_map11,
      I3 => BU2_N336,
      I4 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000_map28,
      O => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_c2_dout_i_SW1 : LUT4
    generic map(
      INIT => X"6FF6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(2),
      I1 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(2),
      I2 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(4),
      I3 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(4),
      O => BU2_N436
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or000093 : LUT6
    generic map(
      INIT => X"F0F00000F2F02200"
    )
    port map (
      I0 => wr_en,
      I1 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_fb_i_2,
      I2 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000_map11,
      I3 => BU2_N434,
      I4 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000_map28,
      I5 => BU2_N336,
      O => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or000093_SW0 : LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(4),
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(4),
      I2 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(2),
      I3 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(2),
      O => BU2_N434
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux000036 : LUT6
    generic map(
      INIT => X"0080000800200002"
    )
    port map (
      I0 => wr_en,
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(0),
      I2 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(1),
      I3 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_fb_i_2,
      I4 => BU2_U0_grf_rf_gl0_wr_wpntr_count(1),
      I5 => BU2_U0_grf_rf_gl0_wr_wpntr_count(0),
      O => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000_map11
    );
  BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or000036 : LUT6
    generic map(
      INIT => X"0080002000080002"
    )
    port map (
      I0 => rd_en,
      I1 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(1),
      I2 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(0),
      I3 => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_4,
      I4 => BU2_U0_grf_rf_gl0_rd_rpntr_count(1),
      I5 => BU2_U0_grf_rf_gl0_rd_rpntr_count(0),
      O => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map11
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_rd_pntr_bin_xor0001_Result1 : LUT3
    generic map(
      INIT => X"96"
    )
    port map (
      I0 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(4),
      I2 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(2),
      O => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0001
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_wr_pntr_bin_xor0001_Result1 : LUT3
    generic map(
      INIT => X"96"
    )
    port map (
      I0 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(4),
      I2 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(2),
      O => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0001
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or000077 : LUT6
    generic map(
      INIT => X"9009000000009009"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(3),
      I2 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(2),
      I3 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(2),
      I4 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(1),
      I5 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(1),
      O => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000_map28
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or000027 : LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(0),
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(0),
      I2 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(4),
      I3 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(4),
      O => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000_map11
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_rd_pntr_bin_xor0000_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(4),
      O => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0000
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_wr_pntr_bin_xor0000_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(4),
      O => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0000
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_c2_dout_i_SW0 : LUT6
    generic map(
      INIT => X"6FF6FFFFFFFF6FF6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(3),
      I2 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(0),
      I3 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(0),
      I4 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(1),
      I5 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(1),
      O => BU2_N336
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux000086 : LUT6
    generic map(
      INIT => X"9009000000009009"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(3),
      I2 => BU2_U0_grf_rf_gl0_wr_wpntr_count(4),
      I3 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(4),
      I4 => BU2_U0_grf_rf_gl0_wr_wpntr_count(2),
      I5 => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(2),
      O => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000_map28
    );
  BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000192 : LUT4
    generic map(
      INIT => X"EAC0"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map40,
      I1 => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map11,
      I2 => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map28,
      I3 => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map57,
      O => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000
    );
  BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000176 : LUT6
    generic map(
      INIT => X"9009000000009009"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(1),
      I1 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(1),
      I2 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(4),
      I3 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(4),
      I4 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(3),
      I5 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(3),
      O => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map57
    );
  BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000126 : LUT4
    generic map(
      INIT => X"9009"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(0),
      I1 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(0),
      I2 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(2),
      I3 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(2),
      O => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map40
    );
  BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or000086 : LUT6
    generic map(
      INIT => X"9009000000009009"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count(3),
      I1 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(3),
      I2 => BU2_U0_grf_rf_gl0_rd_rpntr_count(4),
      I3 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(4),
      I4 => BU2_U0_grf_rf_gl0_rd_rpntr_count(2),
      I5 => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(2),
      O => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000_map28
    );
  BU2_U0_grf_rf_gl0_wr_ram_wr_en_i1 : LUT2
    generic map(
      INIT => X"4"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_fb_i_2,
      I1 => wr_en,
      O => BU2_U0_grf_rf_ram_wr_en
    );
  BU2_U0_grf_rf_gl0_rd_ram_rd_en_i1 : LUT2
    generic map(
      INIT => X"4"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_4,
      I1 => rd_en,
      O => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_not00011 : LUT2
    generic map(
      INIT => X"B"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_wr_rst_d1_3,
      I1 => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_fb_i_2,
      O => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_not0001
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count_xor_4_11 : LUT5
    generic map(
      INIT => X"6CCCCCCC"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count(0),
      I1 => BU2_U0_grf_rf_gl0_rd_rpntr_count(4),
      I2 => BU2_U0_grf_rf_gl0_rd_rpntr_count(1),
      I3 => BU2_U0_grf_rf_gl0_rd_rpntr_count(2),
      I4 => BU2_U0_grf_rf_gl0_rd_rpntr_count(3),
      O => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count12
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count_xor_4_11 : LUT5
    generic map(
      INIT => X"6CCCCCCC"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count(0),
      I1 => BU2_U0_grf_rf_gl0_wr_wpntr_count(4),
      I2 => BU2_U0_grf_rf_gl0_wr_wpntr_count(3),
      I3 => BU2_U0_grf_rf_gl0_wr_wpntr_count(1),
      I4 => BU2_U0_grf_rf_gl0_wr_wpntr_count(2),
      O => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count12
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count_xor_3_11 : LUT4
    generic map(
      INIT => X"6CCC"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count(0),
      I1 => BU2_U0_grf_rf_gl0_rd_rpntr_count(3),
      I2 => BU2_U0_grf_rf_gl0_rd_rpntr_count(1),
      I3 => BU2_U0_grf_rf_gl0_rd_rpntr_count(2),
      O => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count9
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count_xor_3_11 : LUT4
    generic map(
      INIT => X"6CCC"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count(0),
      I1 => BU2_U0_grf_rf_gl0_wr_wpntr_count(3),
      I2 => BU2_U0_grf_rf_gl0_wr_wpntr_count(1),
      I3 => BU2_U0_grf_rf_gl0_wr_wpntr_count(2),
      O => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count9
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count_xor_2_11 : LUT3
    generic map(
      INIT => X"6C"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count(0),
      I1 => BU2_U0_grf_rf_gl0_rd_rpntr_count(2),
      I2 => BU2_U0_grf_rf_gl0_rd_rpntr_count(1),
      O => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count6
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count_xor_2_11 : LUT3
    generic map(
      INIT => X"6C"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count(0),
      I1 => BU2_U0_grf_rf_gl0_wr_wpntr_count(2),
      I2 => BU2_U0_grf_rf_gl0_wr_wpntr_count(1),
      O => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count6
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_rd_pntr_gc_xor0000_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(4),
      I1 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(3),
      O => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0000
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_rd_pntr_gc_xor0001_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(3),
      I1 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(2),
      O => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0001
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_rd_pntr_gc_xor0002_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(2),
      I1 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(1),
      O => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0002
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_rd_pntr_gc_xor0003_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(1),
      I1 => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(0),
      O => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0003
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_wr_pntr_gc_xor0000_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(4),
      I1 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(3),
      O => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0000
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_wr_pntr_gc_xor0001_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(3),
      I1 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(2),
      O => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0001
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_wr_pntr_gc_xor0002_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(2),
      I1 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(1),
      O => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0002
    );
  BU2_U0_grf_rf_gcx_clkx_Mxor_wr_pntr_gc_xor0003_Result1 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(1),
      I1 => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(0),
      O => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0003
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count_xor_1_11 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_rd_rpntr_count(1),
      I1 => BU2_U0_grf_rf_gl0_rd_rpntr_count(0),
      O => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count3
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count_xor_1_11 : LUT2
    generic map(
      INIT => X"6"
    )
    port map (
      I0 => BU2_U0_grf_rf_gl0_wr_wpntr_count(1),
      I1 => BU2_U0_grf_rf_gl0_wr_wpntr_count(0),
      O => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count3
    );
  BU2_U0_grf_rf_gl0_rd_grhf_rhf_ram_valid_d1_and00001 : LUT2
    generic map(
      INIT => X"4"
    )
    port map (
      I0 => NlwRenamedSig_OI_empty,
      I1 => rd_en,
      O => BU2_U0_grf_rf_gl0_rd_grhf_rhf_ram_valid_d1_and0000
    );
  BU2_U0_grf_rf_rstblk_rd_rst_comb1 : LUT2
    generic map(
      INIT => X"4"
    )
    port map (
      I0 => BU2_U0_grf_rf_rstblk_rd_rst_asreg_d2_9,
      I1 => BU2_U0_grf_rf_rstblk_rd_rst_asreg_6,
      O => BU2_U0_grf_rf_rstblk_rd_rst_comb
    );
  BU2_U0_grf_rf_rstblk_wr_rst_comb1 : LUT2
    generic map(
      INIT => X"4"
    )
    port map (
      I0 => BU2_U0_grf_rf_rstblk_wr_rst_asreg_d2_7,
      I1 => BU2_U0_grf_rf_rstblk_wr_rst_asreg_5,
      O => BU2_U0_grf_rf_rstblk_wr_rst_comb
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d3_0 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(0),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(0)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d3_1 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(1),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(1)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d3_2 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(2),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(2)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d3_3 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(3),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(3)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d3_4 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(4),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(4)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d2_4 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(4),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(4)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d2_3 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(3),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(3)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d2_1 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(1),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(1)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d2_0 : FDPE
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(0),
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(0)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d2_2 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(2),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d2(2)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d1_4 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count(4),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(4)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d1_3 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count(3),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(3)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d1_1 : FDPE
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count(1),
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(1)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d1_0 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count(0),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(0)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_d1_2 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count(2),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count_d1(2)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_2 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count6,
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count(2)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_0 : FDPE
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      D => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count,
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count(0)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_1 : FDPE
    generic map(
      INIT => '1'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      D => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count3,
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count(1)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_3 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count9,
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count(3)
    );
  BU2_U0_grf_rf_gl0_wr_wpntr_count_4 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_ram_wr_en,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_Mcount_count12,
      Q => BU2_U0_grf_rf_gl0_wr_wpntr_count(4)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_0 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0003,
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(0)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_1 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0002,
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(1)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_2 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0001,
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(2)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_3 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_xor0000,
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(3)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_4 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gl0_wr_wpntr_count_d3(4),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(4)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_0 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0003,
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(0)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_1 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0002,
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(1)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_2 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0001,
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(2)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_3 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_xor0000,
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(3)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_4 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(4),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(4)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_0 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(0),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(0)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_1 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(1),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(1)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_2 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(2),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(2)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_3 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(3),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(3)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_4 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc(4),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(4)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_0 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(0),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(0)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_1 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(1),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(1)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_2 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(2),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(2)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_3 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(3),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(3)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_4 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc(4),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(4)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1_0 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(0),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(0)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1_1 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(1),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(1)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1_2 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(2),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(2)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1_3 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(3),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(3)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1_4 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg(4),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(4)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1_0 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(0),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(0)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1_1 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(1),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(1)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1_2 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(2),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(2)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1_3 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(3),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(3)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1_4 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg(4),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(4)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_0 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0003,
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(0)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_1 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0002,
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(1)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_2 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0001,
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(2)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_3 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_xor0000,
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(3)
    );
  BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin_4 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(1),
      D => BU2_U0_grf_rf_gcx_clkx_wr_pntr_gc_asreg_d1(4),
      Q => BU2_U0_grf_rf_gcx_clkx_wr_pntr_bin(4)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_0 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0003,
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(0)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_1 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0002,
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(1)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_2 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0001,
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(2)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_3 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_xor0000,
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(3)
    );
  BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin_4 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CLR => BU2_U0_grf_rf_rstblk_wr_rst_reg(0),
      D => BU2_U0_grf_rf_gcx_clkx_rd_pntr_gc_asreg_d1(4),
      Q => BU2_U0_grf_rf_gcx_clkx_rd_pntr_bin(4)
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_4 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count12,
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count(4)
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_3 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count9,
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count(3)
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_2 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count6,
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count(2)
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_1 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count3,
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count(1)
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_0 : FDPE
    generic map(
      INIT => '1'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      D => BU2_U0_grf_rf_gl0_rd_rpntr_Mcount_count,
      PRE => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count(0)
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_fb_i : FDP
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      D => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000,
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      Q => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_fb_i_2
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i : FDP
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      D => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_full_i_or0000,
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      Q => full
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i : FDPE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_not0001,
      D => BU2_U0_grf_rf_gl0_wr_gwas_wsts_ram_almost_full_i_mux0000,
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      Q => almost_full
    );
  BU2_U0_grf_rf_gl0_wr_gwas_wsts_wr_rst_d1 : FDP
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      D => BU2_rd_data_count(0),
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_reg(1),
      Q => BU2_U0_grf_rf_gl0_wr_gwas_wsts_wr_rst_d1_3
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_d1_4 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_count(4),
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(4)
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_d1_3 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_count(3),
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(3)
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_d1_2 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_count(2),
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(2)
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_d1_1 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_count(1),
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(1)
    );
  BU2_U0_grf_rf_gl0_rd_rpntr_count_d1_0 : FDCE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_gl0_rd_rpntr_count_not0001,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_rpntr_count(0),
      Q => BU2_U0_grf_rf_gl0_rd_rpntr_count_d1(0)
    );
  BU2_U0_grf_rf_gl0_rd_grhf_rhf_ram_valid_d1 : FDC
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CLR => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      D => BU2_U0_grf_rf_gl0_rd_grhf_rhf_ram_valid_d1_and0000,
      Q => valid
    );
  BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_i : FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => rd_clk,
      D => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000,
      PRE => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      Q => NlwRenamedSig_OI_empty
    );
  BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i : FDP
    generic map(
      INIT => '1'
    )
    port map (
      C => rd_clk,
      D => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_or0000,
      PRE => BU2_U0_grf_rf_rstblk_rd_rst_reg(2),
      Q => BU2_U0_grf_rf_gl0_rd_gras_rsts_ram_empty_fb_i_4
    );
  BU2_U0_grf_rf_rstblk_wr_rst_reg_0 : FDP
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      D => BU2_rd_data_count(0),
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_comb,
      Q => BU2_U0_grf_rf_rstblk_wr_rst_reg(0)
    );
  BU2_U0_grf_rf_rstblk_wr_rst_reg_1 : FDP
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      D => BU2_rd_data_count(0),
      PRE => BU2_U0_grf_rf_rstblk_wr_rst_comb,
      Q => BU2_U0_grf_rf_rstblk_wr_rst_reg(1)
    );
  BU2_U0_grf_rf_rstblk_rd_rst_reg_0 : FDP
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      D => BU2_rd_data_count(0),
      PRE => BU2_U0_grf_rf_rstblk_rd_rst_comb,
      Q => BU2_U0_grf_rf_rstblk_rd_rst_reg(0)
    );
  BU2_U0_grf_rf_rstblk_rd_rst_reg_1 : FDP
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      D => BU2_rd_data_count(0),
      PRE => BU2_U0_grf_rf_rstblk_rd_rst_comb,
      Q => BU2_U0_grf_rf_rstblk_rd_rst_reg(1)
    );
  BU2_U0_grf_rf_rstblk_rd_rst_reg_2 : FDP
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      D => BU2_rd_data_count(0),
      PRE => BU2_U0_grf_rf_rstblk_rd_rst_comb,
      Q => BU2_U0_grf_rf_rstblk_rd_rst_reg(2)
    );
  BU2_U0_grf_rf_rstblk_rd_rst_asreg : FDPE
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      CE => BU2_U0_grf_rf_rstblk_rd_rst_asreg_d1_10,
      D => BU2_rd_data_count(0),
      PRE => rst,
      Q => BU2_U0_grf_rf_rstblk_rd_rst_asreg_6
    );
  BU2_U0_grf_rf_rstblk_wr_rst_asreg_d1 : FD
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      D => BU2_U0_grf_rf_rstblk_wr_rst_asreg_5,
      Q => BU2_U0_grf_rf_rstblk_wr_rst_asreg_d1_8
    );
  BU2_U0_grf_rf_rstblk_wr_rst_asreg : FDPE
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      CE => BU2_U0_grf_rf_rstblk_wr_rst_asreg_d1_8,
      D => BU2_rd_data_count(0),
      PRE => rst,
      Q => BU2_U0_grf_rf_rstblk_wr_rst_asreg_5
    );
  BU2_U0_grf_rf_rstblk_rd_rst_asreg_d1 : FD
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      D => BU2_U0_grf_rf_rstblk_rd_rst_asreg_6,
      Q => BU2_U0_grf_rf_rstblk_rd_rst_asreg_d1_10
    );
  BU2_U0_grf_rf_rstblk_wr_rst_asreg_d2 : FD
    generic map(
      INIT => '0'
    )
    port map (
      C => wr_clk,
      D => BU2_U0_grf_rf_rstblk_wr_rst_asreg_d1_8,
      Q => BU2_U0_grf_rf_rstblk_wr_rst_asreg_d2_7
    );
  BU2_U0_grf_rf_rstblk_rd_rst_asreg_d2 : FD
    generic map(
      INIT => '0'
    )
    port map (
      C => rd_clk,
      D => BU2_U0_grf_rf_rstblk_rd_rst_asreg_d1_10,
      Q => BU2_U0_grf_rf_rstblk_rd_rst_asreg_d2_9
    );
  BU2_XST_VCC : VCC
    port map (
      P => BU2_N1
    );
  BU2_XST_GND : GND
    port map (
      G => BU2_rd_data_count(0)
    );

end STRUCTURE;

-- synopsys translate_on
