////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2009 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: L.57
//  \   \         Application: netgen
//  /   /         Filename: pcie_endpoint.v
// /___/   /\     Timestamp: Mon Feb  8 15:28:15 2010
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -intstyle ise -w -sim -ofmt verilog ./tmp/_cg/pcie_endpoint.ngc ./tmp/_cg/pcie_endpoint.v 
// Device	: 5vlx110tff1136-1
// Input file	: ./tmp/_cg/pcie_endpoint.ngc
// Output file	: ./tmp/_cg/pcie_endpoint.v
// # of Modules	: 1
// Design Name	: pcie_endpoint
// Xilinx        : /raid/tools/xilinx/11.1/ISE
//             
// Purpose:    
//     This verilog netlist is a verification model and uses simulation 
//     primitives which may not represent the true implementation of the 
//     device, however the netlist is functionally correct and should not 
//     be modified. This file cannot be synthesized and should only be used 
//     with supported simulation tools.
//             
// Reference:  
//     Command Line Tools User Guide, Chapter 23 and Synthesis and Simulation Design Guide, Chapter 6
//             
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ps

module pcie_endpoint (
  cfg_pm_wake_n, cfg_err_cpl_abort_n, trn_tsrc_rdy_n, trn_terrfwd_n, cfg_to_turnoff_n, refclkout, trn_tdst_rdy_n, trn_rsrc_dsc_n, trn_rnp_ok_n, 
trn_tsrc_dsc_n, cfg_err_cpl_unexpect_n, cfg_err_cor_n, cfg_wr_en_n, trn_rsrc_rdy_n, cfg_err_locked_n, trn_tdst_dsc_n, trn_reset_n, cfg_err_ur_n, 
trn_rcpl_streaming_n, cfg_interrupt_n, cfg_err_cpl_timeout_n, trn_clk, cfg_trn_pending_n, fast_train_simulation_only, cfg_interrupt_msienable, 
trn_lnk_up_n, trn_tsof_n, trn_reof_n, cfg_rd_wr_done_n, cfg_rd_en_n, sys_clk, trn_rdst_rdy_n, trn_rerrfwd_n, cfg_interrupt_rdy_n, 
cfg_interrupt_assert_n, trn_teof_n, trn_rsof_n, cfg_err_posted_n, sys_reset_n, cfg_err_cpl_rdy_n, cfg_err_ecrc_n, pci_exp_txn, cfg_interrupt_do, 
pci_exp_txp, trn_rbar_hit_n, cfg_dstatus, cfg_function_number, trn_rd, trn_td, cfg_dsn, cfg_interrupt_mmenable, cfg_dcommand, trn_rfc_ph_av, 
trn_rfc_npd_av, cfg_bus_number, trn_rrem_n, cfg_di, cfg_dwaddr, cfg_byte_en_n, cfg_do, cfg_device_number, cfg_lstatus, cfg_err_tlp_cpl_header, 
cfg_command, cfg_pcie_link_state_n, trn_tbuf_av, pci_exp_rxn, pci_exp_rxp, cfg_lcommand, cfg_status, trn_rfc_nph_av, trn_trem_n, trn_rfc_pd_av, 
cfg_interrupt_di
)/* synthesis syn_black_box syn_noprune=1 */;
  input cfg_pm_wake_n;
  input cfg_err_cpl_abort_n;
  input trn_tsrc_rdy_n;
  input trn_terrfwd_n;
  output cfg_to_turnoff_n;
  output refclkout;
  output trn_tdst_rdy_n;
  output trn_rsrc_dsc_n;
  input trn_rnp_ok_n;
  input trn_tsrc_dsc_n;
  input cfg_err_cpl_unexpect_n;
  input cfg_err_cor_n;
  input cfg_wr_en_n;
  output trn_rsrc_rdy_n;
  input cfg_err_locked_n;
  output trn_tdst_dsc_n;
  output trn_reset_n;
  input cfg_err_ur_n;
  input trn_rcpl_streaming_n;
  input cfg_interrupt_n;
  input cfg_err_cpl_timeout_n;
  output trn_clk;
  input cfg_trn_pending_n;
  input fast_train_simulation_only;
  output cfg_interrupt_msienable;
  output trn_lnk_up_n;
  input trn_tsof_n;
  output trn_reof_n;
  output cfg_rd_wr_done_n;
  input cfg_rd_en_n;
  input sys_clk;
  input trn_rdst_rdy_n;
  output trn_rerrfwd_n;
  output cfg_interrupt_rdy_n;
  input cfg_interrupt_assert_n;
  input trn_teof_n;
  output trn_rsof_n;
  input cfg_err_posted_n;
  input sys_reset_n;
  output cfg_err_cpl_rdy_n;
  input cfg_err_ecrc_n;
  output [0 : 0] pci_exp_txn;
  output [7 : 0] cfg_interrupt_do;
  output [0 : 0] pci_exp_txp;
  output [6 : 0] trn_rbar_hit_n;
  output [15 : 0] cfg_dstatus;
  output [2 : 0] cfg_function_number;
  output [63 : 0] trn_rd;
  input [63 : 0] trn_td;
  input [63 : 0] cfg_dsn;
  output [2 : 0] cfg_interrupt_mmenable;
  output [15 : 0] cfg_dcommand;
  output [7 : 0] trn_rfc_ph_av;
  output [11 : 0] trn_rfc_npd_av;
  output [7 : 0] cfg_bus_number;
  output [7 : 0] trn_rrem_n;
  input [31 : 0] cfg_di;
  input [9 : 0] cfg_dwaddr;
  input [3 : 0] cfg_byte_en_n;
  output [31 : 0] cfg_do;
  output [4 : 0] cfg_device_number;
  output [15 : 0] cfg_lstatus;
  input [47 : 0] cfg_err_tlp_cpl_header;
  output [15 : 0] cfg_command;
  output [2 : 0] cfg_pcie_link_state_n;
  output [3 : 0] trn_tbuf_av;
  input [0 : 0] pci_exp_rxn;
  input [0 : 0] pci_exp_rxp;
  output [15 : 0] cfg_lcommand;
  output [15 : 0] cfg_status;
  output [7 : 0] trn_rfc_nph_av;
  input [7 : 0] trn_trem_n;
  output [11 : 0] trn_rfc_pd_av;
  input [7 : 0] cfg_interrupt_di;

endmodule