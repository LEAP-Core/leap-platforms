////////////////////////////////////////////////////////////////////////////////
// Filename      : pcie_dma_device.v
// Brief         : pcie wrapper of xilinx ip core for ml605 board with dma support
// Author        : rfadeev
// Mail to       : roman.fadeev@intel.com
//
// Copyright (C) 2011 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
////////////////////////////////////////////////////////////////////////////////

// This is top module of pcie physical device. It connects Xilinx Virtex-6 core
// for PCI Express (pcie_core) and application design (pcie_dma_app).
// For additional information about Xilinx Virtex-6 core please refer to
// Virtex-6 FPGA Integrated Block for PCI Express User Guide (http://www.xilinx.com/support/documentation/user_guides/v6_pcie_ug517.pdf)

module pcie_dma_device
(
    // Bluespec interface

    input             EN_read,
    output            RDY_read,
    output [ 63 : 0 ] DATA_read,

    input             EN_write,
    output            RDY_write,
    input  [ 63 : 0 ] DATA_write,

    output            SOFT_reset,

    // PCI Express interface
    input             pcie_clk_p,
    input             pcie_clk_n,
    input             pcie_reset_n,

    input  [ 7 : 0 ]  rx_p,
    input  [ 7 : 0 ]  rx_n,

    output [ 7 : 0 ]  tx_p,
    output [ 7 : 0 ]  tx_n,

    output            pcie_fake_clk,

    input	      model_clk,
    input	      model_rst_n,

    output	      pcie_clk,
    output	      pcie_rst_n

);

// Clock and Reset
wire		ref_clk;
wire		pcie_reset_n_c;


//PCIe transaction layer signals
// Common Transaction Interface
wire            trn_clk;
wire            trn_reset_n;
wire            trn_lnk_up_n;
wire            trn_reset_n_c;
wire            trn_lnk_up_n_c;

// Common Transaction Interface: Flow Control Interface
wire [  7 : 0 ] trn_fc_ph;
wire [ 11 : 0 ] trn_fc_pd;
wire [  7 : 0 ] trn_fc_nph;
wire [ 11 : 0 ] trn_fc_npd;
wire [  7 : 0 ] trn_fc_cplh;
wire [ 11 : 0 ] trn_fc_cpld;
wire [  2 : 0 ] trn_fc_sel;

// Transaction Transmit Interface
wire            trn_tsof_n_c;
wire            trn_teof_n_c;
wire [ 63 : 0 ] trn_td_c;
wire            trn_trem_n_c;
wire            trn_tsrc_rdy_n_c;
wire            trn_tdst_rdy_n_c;
wire            trn_tsrc_dsc_n_c;
wire [  5 : 0 ] trn_tbuf_av_c;
wire            trn_terrfwd_n_c;

// Transaction Receive Interface
wire            trn_rsof_n_c;
wire            trn_reof_n_c;
wire [ 63 : 0 ] trn_rd_c;
wire            trn_rrem_n_c;
wire            trn_rerrfwd_n_c;
wire            trn_rsrc_rdy_n_c;
wire            trn_rdst_rdy_n_c;
wire            trn_rsrc_dsc_n_c;
wire            trn_rnp_ok_n_c;
wire [  6 : 0 ] trn_rbar_hit_n_c;

// Physical Layer Interface
wire [  2 : 0 ] pl_initial_link_width;
wire [  1 : 0 ] pl_lane_reversal_mode;
wire            pl_link_gen2_capable;
wire            pl_link_partner_gen2_supported;
wire            pl_link_upcfg_capable;
wire            pl_sel_link_rate;
wire [  1 : 0 ] pl_sel_link_width;
wire [  5 : 0 ] pl_ltssm_state;
wire            pl_upstream_prefer_deemph;
wire            pl_received_hot_rst;

// Configuration Interface
wire [ 15 : 0 ] cfg_status;
wire [ 15 : 0 ] cfg_command;
wire [ 15 : 0 ] cfg_dstatus;
wire [ 15 : 0 ] cfg_dcommand;
wire [ 15 : 0 ] cfg_dcommand2;
wire [ 15 : 0 ] cfg_lstatus;
wire [ 15 : 0 ] cfg_lcommand;
wire [  2 : 0 ] cfg_pcie_link_state_n;
wire            cfg_trn_pending_n;
wire [  7 : 0 ] cfg_bus_number;
wire [  4 : 0 ] cfg_device_number;
wire [  2 : 0 ] cfg_function_number;
wire            cfg_to_turnoff_n;
wire            cfg_turnoff_ok_n;
wire            cfg_pm_wake_n;

// Configuration Interface: Interrupt Interface
wire            cfg_interrupt_n;
wire            cfg_interrupt_rdy_n;
wire            cfg_interrupt_assert_n;
wire [  7 : 0 ] cfg_interrupt_di;
wire [  7 : 0 ] cfg_interrupt_do;
wire            cfg_interrupt_msienable;

// Configuration Interface: User Application Error-Reporting Interface
wire            cfg_err_cpl_timeout_n;
wire            cfg_err_cpl_unexpect_n;
wire            cfg_err_posted_n;

// PCIe Reference Clock Input buffer
IBUFDS_GTXE1 pcie_refclk_ibuf
(
    .I(pcie_clk_p),
    .IB(pcie_clk_n),
    .O(ref_clk),
    .CEB(1'b0),
    .ODIV2()
);

// PCIe PERST# input buffer
IBUF pcie_reset_n_ibuf
(
    .I(pcie_reset_n),
    .O(pcie_reset_n_c)
);

// Register to improve timing
FDCP #(.INIT(1'b1)) trn_lnk_up_n_int_i
(
    .Q(trn_lnk_up_n),
    .D(trn_lnk_up_n_c),
    .C(trn_clk),
    .CLR(1'b0),
    .PRE(1'b0)
);

// Register to improve timing
FDCP #(.INIT(1'b1)) trn_reset_n_i
(
    .Q(trn_reset_n),
    .D(trn_reset_n_c),
    .C(trn_clk),
    .CLR(1'b0),
    .PRE(1'b0)
);


assign pcie_rst_n  = trn_reset_n; // in BVI Reset should be active low
assign pcie_clk = trn_clk;



//assign cfg_pm_wake_n = 1'b1;

// -------------------------
// PCI Express Core Instance
pcie_core core
(
    // System Interface
    .sys_clk(ref_clk),
    .sys_reset_n(pcie_reset_n_c),

    // PCI Express Interface
    .pci_exp_txp(tx_p),
    .pci_exp_txn(tx_n),
    .pci_exp_rxp(rx_p),
    .pci_exp_rxn(rx_n),

    // Common Transaction Interface
    .trn_clk(trn_clk),
    .trn_reset_n(trn_reset_n_c),
    .trn_lnk_up_n(trn_lnk_up_n_c),

    // Common Transaction Interface: Flow Control Interface
    .trn_fc_ph(trn_fc_ph),
    .trn_fc_pd(trn_fc_pd),
    .trn_fc_nph(trn_fc_nph),
    .trn_fc_npd(trn_fc_npd),
    .trn_fc_cplh(trn_fc_cplh),
    .trn_fc_cpld(trn_fc_cpld),
    .trn_fc_sel(trn_fc_sel),

    // Transaction Transmit Interface
    .trn_tsof_n(trn_tsof_n_c),
    .trn_teof_n(trn_teof_n_c),
    .trn_td(trn_td_c),
    .trn_trem_n(trn_trem_n_c),
    .trn_tsrc_rdy_n(trn_tsrc_rdy_n_c),
    .trn_tdst_rdy_n(trn_tdst_rdy_n_c),
    .trn_tsrc_dsc_n(trn_tsrc_dsc_n_c),
    .trn_tbuf_av(trn_tbuf_av_c),
    .trn_terr_drop_n(),
    .trn_tstr_n(1'b0),
    .trn_tcfg_req_n(),
    .trn_tcfg_gnt_n(1'b0),
    .trn_terrfwd_n(trn_terrfwd_n_c),

    // Transaction Receive Interface
    .trn_rsof_n(trn_rsof_n_c),
    .trn_reof_n(trn_reof_n_c),
    .trn_rd(trn_rd_c),
    .trn_rrem_n(trn_rrem_n_c),
    .trn_rerrfwd_n(trn_rerrfwd_n_c),
    .trn_rsrc_rdy_n(trn_rsrc_rdy_n_c),
    .trn_rdst_rdy_n(trn_rdst_rdy_n_c),
    .trn_rsrc_dsc_n(trn_rsrc_dsc_n_c),
    .trn_rnp_ok_n(trn_rnp_ok_n_c),
    .trn_rbar_hit_n(trn_rbar_hit_n_c),

    // Physical Layer Interface
    .pl_initial_link_width(pl_initial_link_width),
    .pl_lane_reversal_mode(pl_lane_reversal_mode),
    .pl_link_gen2_capable(pl_link_gen2_capable),
    .pl_link_partner_gen2_supported(pl_link_partner_gen2_supported),
    .pl_link_upcfg_capable(pl_link_upcfg_capable),
    .pl_sel_link_rate(pl_sel_link_rate),
    .pl_sel_link_width(pl_sel_link_width),
    .pl_ltssm_state(pl_ltssm_state),
    .pl_directed_link_auton(1'b0),
    .pl_directed_link_change(2'b00),
    .pl_directed_link_speed(1'b0),
    .pl_directed_link_width(2'b00),
    .pl_upstream_prefer_deemph(1'b1),
    .pl_received_hot_rst(pl_received_hot_rst),

    // Configuration Interface
    .cfg_do(),
    .cfg_rd_wr_done_n(),
    .cfg_di(32'h0),
    .cfg_dwaddr(10'h0),
    .cfg_byte_en_n(4'hF),
    .cfg_wr_en_n(1'b1),
    .cfg_rd_en_n(1'b1),
    .cfg_status(cfg_status),
    .cfg_command(cfg_command),
    .cfg_dstatus(cfg_dstatus),
    .cfg_dcommand(cfg_dcommand),
    .cfg_dcommand2(cfg_dcommand2),
    .cfg_lstatus(cfg_lstatus),
    .cfg_lcommand(cfg_lcommand),
    .cfg_pcie_link_state_n(cfg_pcie_link_state_n),
    .cfg_trn_pending_n(cfg_trn_pending_n),
    .cfg_dsn(64'd0),
    .cfg_pmcsr_pme_en(),
    .cfg_pmcsr_pme_status(),
    .cfg_pmcsr_powerstate(),
    .cfg_bus_number(cfg_bus_number),
    .cfg_device_number(cfg_device_number),
    .cfg_function_number(cfg_function_number),
    .cfg_to_turnoff_n(cfg_to_turnoff_n),
    .cfg_turnoff_ok_n(cfg_turnoff_ok_n),
    .cfg_pm_wake_n(cfg_pm_wake_n),

    // Configuration Interface: Interrupt Interface
    .cfg_interrupt_n(cfg_interrupt_n),
    .cfg_interrupt_rdy_n(cfg_interrupt_rdy_n),
    .cfg_interrupt_assert_n(cfg_interrupt_assert_n),
    .cfg_interrupt_di(cfg_interrupt_di),
    .cfg_interrupt_do(cfg_interrupt_do),
    .cfg_interrupt_mmenable(),
    .cfg_interrupt_msienable(cfg_interrupt_msienable),
    .cfg_interrupt_msixenable(),
    .cfg_interrupt_msixfm(),

    // Configuration Interface: User Application Error-Reporting Interface
    .cfg_err_ecrc_n(1'b1),
    .cfg_err_ur_n(1'b1),
    .cfg_err_cpl_timeout_n(cfg_err_cpl_timeout_n),
    .cfg_err_cpl_unexpect_n(cfg_err_cpl_unexpect_n),
    .cfg_err_cpl_abort_n(1'b1),
    .cfg_err_posted_n(cfg_err_posted_n),
    .cfg_err_cor_n(1'b1),
    .cfg_err_tlp_cpl_header(48'd0),
    .cfg_err_cpl_rdy_n(),
    .cfg_err_locked_n(1'b1)
);

// Application Instance
pcie_dma_app dma_app
(
    // Bluespec Interface
    .model_clk(model_clk),
    .model_rst_n(model_rst_n),

    .EN_read(EN_read),
    .RDY_read(RDY_read),
    .DATA_read(DATA_read),

    .EN_write(EN_write),
    .RDY_write(RDY_write),
    .DATA_write(DATA_write),

    .SOFT_reset(SOFT_reset),

    // Common Transaction Interface
    .trn_clk(trn_clk),
    .trn_reset_n(trn_reset_n),
    .trn_lnk_up_n(trn_lnk_up_n_c),

    // Common Transaction Interface: Flow Control Interface
    .trn_fc_ph(trn_fc_ph),
    .trn_fc_pd(trn_fc_pd),
    .trn_fc_nph(trn_fc_nph),
    .trn_fc_npd(trn_fc_npd),
    .trn_fc_cplh(trn_fc_cplh),
    .trn_fc_cpld(trn_fc_cpld),
    .trn_fc_sel(trn_fc_sel),

    // Transaction Transmit Interface
    .trn_tsof_n(trn_tsof_n_c),
    .trn_teof_n(trn_teof_n_c),
    .trn_td(trn_td_c),
    .trn_trem_n(trn_trem_n_c),
    .trn_tsrc_rdy_n(trn_tsrc_rdy_n_c),
    .trn_tdst_rdy_n(trn_tdst_rdy_n_c),
    .trn_tsrc_dsc_n(trn_tsrc_dsc_n_c),
    .trn_tbuf_av(trn_tbuf_av_c),
    .trn_terr_drop_n(trn_terr_drop_n),
    .trn_tstr_n(trn_tstr_n),
    .trn_tcfg_req_n(trn_tcfg_req_n),
    .trn_tcfg_gnt_n(trn_tcfg_gnt_n),
    .trn_terrfwd_n(trn_terrfwd_n_c),

    // Transaction Receive Interface
    .trn_rsof_n_i(trn_rsof_n_c),
    .trn_reof_n_i(trn_reof_n_c),
    .trn_rd_i(trn_rd_c),
    .trn_rrem_n_i(trn_rrem_n_c),
    .trn_rerrfwd_n_i(trn_rerrfwd_n_c),
    .trn_rsrc_rdy_n_i(trn_rsrc_rdy_n_c),
    .trn_rdst_rdy_n(trn_rdst_rdy_n_c),
    .trn_rsrc_dsc_n_i(trn_rsrc_dsc_n_c),
    .trn_rnp_ok_n(trn_rnp_ok_n_c),
    .trn_rbar_hit_n_i(trn_rbar_hit_n_c),

    // Physical Layer Interface
    .pl_initial_link_width(pl_initial_link_width),
    .pl_lane_reversal_mode(pl_lane_reversal_mode),
    .pl_link_gen2_capable(pl_link_gen2_capable),
    .pl_link_partner_gen2_supported(pl_link_partner_gen2_supported),
    .pl_link_upcfg_capable(pl_link_upcfg_capable),
    .pl_sel_link_rate(pl_sel_link_rate),
    .pl_sel_link_width(pl_sel_link_width),
    .pl_ltssm_state(pl_ltssm_state),
    .pl_directed_link_auton(pl_directed_link_auton),
    .pl_directed_link_change(pl_directed_link_change),
    .pl_directed_link_speed(pl_directed_link_speed),
    .pl_directed_link_width(pl_directed_link_width),
    .pl_upstream_prefer_deemph(pl_upstream_prefer_deemph),
    .pl_received_hot_rst(pl_received_hot_rst),

    // Configuration Interface
    .cfg_do(cfg_do),
    .cfg_rd_wr_done_n(cfg_rd_wr_done_n),
    .cfg_di(cfg_di),
    .cfg_dwaddr(cfg_dwaddr),
    .cfg_byte_en_n(cfg_byte_en_n),
    .cfg_wr_en_n(cfg_wr_en_n),
    .cfg_rd_en_n(cfg_rd_en_n),
    .cfg_status(cfg_status),
    .cfg_command(cfg_command),
    .cfg_dstatus(cfg_dstatus),
    .cfg_dcommand(cfg_dcommand),
    .cfg_dcommand2(cfg_dcommand2),
    .cfg_lstatus(cfg_lstatus),
    .cfg_lcommand(cfg_lcommand),
    .cfg_pcie_link_state_n(cfg_pcie_link_state_n),
    .cfg_trn_pending_n(cfg_trn_pending_n),
    .cfg_dsn(cfg_dsn),
    .cfg_bus_number(cfg_bus_number),
    .cfg_device_number(cfg_device_number),
    .cfg_function_number(cfg_function_number),
    .cfg_to_turnoff_n(cfg_to_turnoff_n),
    .cfg_turnoff_ok_n(cfg_turnoff_ok_n),
    .cfg_pm_wake_n(cfg_pm_wake_n),

    // Configuration Interface: Interrupt Interface
    .cfg_interrupt_n(cfg_interrupt_n),
    .cfg_interrupt_rdy_n(cfg_interrupt_rdy_n),
    .cfg_interrupt_assert_n(cfg_interrupt_assert_n),
    .cfg_interrupt_di(cfg_interrupt_di),
    .cfg_interrupt_do(cfg_interrupt_do),
    .cfg_interrupt_mmenable(cfg_interrupt_mmenable),
    .cfg_interrupt_msienable(cfg_interrupt_msienable),
    .cfg_interrupt_msixenable(cfg_interrupt_msixenable),
    .cfg_interrupt_msixfm(cfg_interrupt_msixfm),

    // Configuration Interface: User Application Error-Reporting Interface
    .cfg_err_ecrc_n(cfg_err_ecrc_n),
    .cfg_err_ur_n(cfg_err_ur_n),
    .cfg_err_cpl_timeout_n(cfg_err_cpl_timeout_n),
    .cfg_err_cpl_unexpect_n(cfg_err_cpl_unexpect_n),
    .cfg_err_cpl_abort_n(cfg_err_cpl_abort_n),
    .cfg_err_posted_n(cfg_err_posted_n),
    .cfg_err_cor_n(cfg_err_cor_n),
    .cfg_err_tlp_cpl_header(cfg_err_tlp_cpl_header),
    .cfg_err_cpl_rdy_n(cfg_err_cpl_rdy_n),
    .cfg_err_locked_n(cfg_err_locked_n)
);

endmodule
