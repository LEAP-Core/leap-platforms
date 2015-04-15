// Copyright (c) 2014  Bluespec, Inc.  ALL RIGHTS RESERVED

`ifdef BSV_ASSIGNMENT_DELAY
`else
 `define BSV_ASSIGNMENT_DELAY
`endif

module xilinx_v7_pcie3_wrapper
(
 // Tx
 output [7:0]                                pci_exp_txn,
 output [7:0]                                pci_exp_txp,

 // Rx
 input  [7:0]                                pci_exp_rxn,
 input  [7:0]                                pci_exp_rxp,
 
 // Common
 output                                     user_clk,
 output wire                                user_reset,
 output wire                                user_lnk_up,
 output wire                                user_app_rdy,

 input wire                                 s_axis_rq_tlast,
 input wire [63 : 0]                        s_axis_rq_tdata,
 input wire [59 : 0]                        s_axis_rq_tuser,
 input wire [1 : 0]                         s_axis_rq_tkeep,
 output wire [3 : 0]                        s_axis_rq_tready,
 input wire                                 s_axis_rq_tvalid,       
 
 output wire [63 : 0]                       m_axis_rc_tdata,
 output wire [74 : 0]                       m_axis_rc_tuser,
 output wire                                m_axis_rc_tlast, 
 output wire [1 : 0]                        m_axis_rc_tkeep,
 output wire                                m_axis_rc_tvalid,
 input wire [21 : 0]                        m_axis_rc_tready,     
 
 output wire [63 : 0]                       m_axis_cq_tdata,
 output wire [84 : 0]                       m_axis_cq_tuser,
 output wire                                m_axis_cq_tlast,
 output wire [1 : 0]                        m_axis_cq_tkeep,
 output wire                                m_axis_cq_tvalid,
 input wire [21 : 0]                        m_axis_cq_tready,     

 input wire [63 : 0]                        s_axis_cc_tdata,
 input wire [32 : 0]                        s_axis_cc_tuser,
 input wire                                 s_axis_cc_tlast,
 input wire [1 : 0]                         s_axis_cc_tkeep,
 input wire                                 s_axis_cc_tvalid,
 output wire [3 : 0]                        s_axis_cc_tready,       
 
 input wire [3 : 0]                         cfg_interrupt_int,
 input wire [1 : 0]                         cfg_interrupt_pending,
 output wire                                cfg_interrupt_sent,
 output wire [1 : 0]                        cfg_interrupt_msix_enable,
 output wire [1 : 0]                        cfg_interrupt_msix_mask,
 output wire [5 : 0]                        cfg_interrupt_msix_vf_enable,
 output wire [5 : 0]                        cfg_interrupt_msix_vf_mask,
 input wire [31 : 0]                        cfg_interrupt_msix_data,
 input wire [63 : 0]                        cfg_interrupt_msix_address,
 input wire                                 cfg_interrupt_msix_int,
 output wire                                cfg_interrupt_msix_sent,
 output wire                                cfg_interrupt_msix_fail,

 output wire [2 : 0]                        cfg_max_payload,
 output wire [2 : 0]                        cfg_max_read_req,
 output wire [1 : 0]                        cfg_rcb_status,
 output wire [7 : 0]                        cfg_function_status,
 
 input wire                                 sys_clk,
 input wire                                 sys_reset
 );

pcie3_7x_v3_0 pcie3_7x_v3_0_i (
  .pci_exp_txn(pci_exp_txn),                                              // output wire [7 : 0] pci_exp_txn
  .pci_exp_txp(pci_exp_txp),                                              // output wire [7 : 0] pci_exp_txp
  .pci_exp_rxn(pci_exp_rxn),                                              // input wire [7 : 0] pci_exp_rxn
  .pci_exp_rxp(pci_exp_rxp),                                              // input wire [7 : 0] pci_exp_rxp
  .user_clk(user_clk),                                                    // output wire user_clk
  .user_reset(user_reset),                                                // output wire user_reset
  .user_lnk_up(user_lnk_up),                                              // output wire user_lnk_up
  .user_app_rdy(user_app_rdy),                                            // output wire user_app_rdy
  .s_axis_rq_tlast(s_axis_rq_tlast),                                      // input wire s_axis_rq_tlast
  .s_axis_rq_tdata(s_axis_rq_tdata),                                      // input wire [63 : 0] s_axis_rq_tdata
  .s_axis_rq_tuser(s_axis_rq_tuser),                                      // input wire [59 : 0] s_axis_rq_tuser
  .s_axis_rq_tkeep(s_axis_rq_tkeep),                                      // input wire [1 : 0] s_axis_rq_tkeep
  .s_axis_rq_tready(s_axis_rq_tready),                                    // output wire [3 : 0] s_axis_rq_tready
  .s_axis_rq_tvalid(s_axis_rq_tvalid),                                    // input wire s_axis_rq_tvalid
  .m_axis_rc_tdata(m_axis_rc_tdata),                                      // output wire [63 : 0] m_axis_rc_tdata
  .m_axis_rc_tuser(m_axis_rc_tuser),                                      // output wire [74 : 0] m_axis_rc_tuser
  .m_axis_rc_tlast(m_axis_rc_tlast),                                      // output wire m_axis_rc_tlast
  .m_axis_rc_tkeep(m_axis_rc_tkeep),                                      // output wire [1 : 0] m_axis_rc_tkeep
  .m_axis_rc_tvalid(m_axis_rc_tvalid),                                    // output wire m_axis_rc_tvalid
  .m_axis_rc_tready(m_axis_rc_tready),                                    // input wire [21 : 0] m_axis_rc_tready
  .m_axis_cq_tdata(m_axis_cq_tdata),                                      // output wire [63 : 0] m_axis_cq_tdata
  .m_axis_cq_tuser(m_axis_cq_tuser),                                      // output wire [84 : 0] m_axis_cq_tuser
  .m_axis_cq_tlast(m_axis_cq_tlast),                                      // output wire m_axis_cq_tlast
  .m_axis_cq_tkeep(m_axis_cq_tkeep),                                      // output wire [1 : 0] m_axis_cq_tkeep
  .m_axis_cq_tvalid(m_axis_cq_tvalid),                                    // output wire m_axis_cq_tvalid
  .m_axis_cq_tready(m_axis_cq_tready),                                    // input wire [21 : 0] m_axis_cq_tready
  .s_axis_cc_tdata(s_axis_cc_tdata),                                      // input wire [63 : 0] s_axis_cc_tdata
  .s_axis_cc_tuser(s_axis_cc_tuser),                                      // input wire [32 : 0] s_axis_cc_tuser
  .s_axis_cc_tlast(s_axis_cc_tlast),                                      // input wire s_axis_cc_tlast
  .s_axis_cc_tkeep(s_axis_cc_tkeep),                                      // input wire [1 : 0] s_axis_cc_tkeep
  .s_axis_cc_tvalid(s_axis_cc_tvalid),                                    // input wire s_axis_cc_tvalid
  .s_axis_cc_tready(s_axis_cc_tready),                                    // output wire [3 : 0] s_axis_cc_tready
  .cfg_max_payload(cfg_max_payload),                                      // output wire [2 : 0] cfg_max_payload
  .cfg_max_read_req(cfg_max_read_req),                                    // output wire [2 : 0] cfg_max_read_req
  .cfg_rcb_status(cfg_rcb_status),                                        // output wire [1 : 0] cfg_rcb_status
  .cfg_function_status(cfg_function_status),                              // output wire [7 : 0] cfg_function_stat
                               
  .pcie_rq_seq_num(),                                      // output wire [3 : 0] pcie_rq_seq_num
  .pcie_rq_seq_num_vld(),                              // output wire pcie_rq_seq_num_vld
  .pcie_rq_tag(),                                              // output wire [5 : 0] pcie_rq_tag
  .pcie_rq_tag_vld(),                                      // output wire pcie_rq_tag_vld
  .pcie_cq_np_req(1'b1),                                        // input wire pcie_cq_np_req
  .pcie_cq_np_req_count(),                            // output wire [5 : 0] pcie_cq_np_req_count
  .cfg_phy_link_down(),                                  // output wire cfg_phy_link_down
  .cfg_phy_link_status(),                              // output wire [1 : 0] cfg_phy_link_status
  .cfg_negotiated_width(),                            // output wire [3 : 0] cfg_negotiated_width
  .cfg_current_speed(),                                  // output wire [2 : 0] cfg_current_speed

  .cfg_function_power_state(),                    // output wire [5 : 0] cfg_function_power_state
  .cfg_vf_status(),                                          // output wire [11 : 0] cfg_vf_status
  .cfg_vf_power_state(),                                // output wire [17 : 0] cfg_vf_power_state
  .cfg_link_power_state(),                            // output wire [1 : 0] cfg_link_power_state
  .cfg_err_cor_out(),                                      // output wire cfg_err_cor_out
  .cfg_err_nonfatal_out(),                            // output wire cfg_err_nonfatal_out
  .cfg_err_fatal_out(),                                  // output wire cfg_err_fatal_out
  .cfg_ltr_enable(),                                        // output wire cfg_ltr_enable
  .cfg_ltssm_state(),                                      // output wire [5 : 0] cfg_ltssm_state
  .cfg_dpa_substate_change(),                      // output wire [1 : 0] cfg_dpa_substate_change
  .cfg_obff_enable(),                                      // output wire [1 : 0] cfg_obff_enable
  .cfg_pl_status_change(),                            // output wire cfg_pl_status_change
  .cfg_tph_requester_enable(),                    // output wire [1 : 0] cfg_tph_requester_enable
  .cfg_tph_st_mode(),                                      // output wire [5 : 0] cfg_tph_st_mode
  .cfg_vf_tph_requester_enable(),              // output wire [5 : 0] cfg_vf_tph_requester_enable
  .cfg_vf_tph_st_mode(),                                // output wire [17 : 0] cfg_vf_tph_st_mode

  .cfg_interrupt_int(cfg_interrupt_int),                                  // input wire [3 : 0] cfg_interrupt_int
  .cfg_interrupt_pending(cfg_interrupt_pending),                          // input wire [1 : 0] cfg_interrupt_pending
  .cfg_interrupt_sent(cfg_interrupt_sent),                                // output wire cfg_interrupt_sent

  .cfg_interrupt_msix_enable(cfg_interrupt_msix_enable),                  // output wire [1 : 0] cfg_interrupt_msix_enable
  .cfg_interrupt_msix_mask(cfg_interrupt_msix_mask),                      // output wire [1 : 0] cfg_interrupt_msix_mask
  .cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable),            // output wire [5 : 0] cfg_interrupt_msix_vf_enable
  .cfg_interrupt_msix_vf_mask(cfg_interrupt_msix_vf_mask),                // output wire [5 : 0] cfg_interrupt_msix_vf_mask
  .cfg_interrupt_msix_data(cfg_interrupt_msix_data),                      // input wire [31 : 0] cfg_interrupt_msix_data
  .cfg_interrupt_msix_address(cfg_interrupt_msix_address),                // input wire [63 : 0] cfg_interrupt_msix_address
  .cfg_interrupt_msix_int(cfg_interrupt_msix_int),                        // input wire cfg_interrupt_msix_int
  .cfg_interrupt_msix_sent(cfg_interrupt_msix_sent),                      // output wire cfg_interrupt_msix_sent
  .cfg_interrupt_msix_fail(cfg_interrupt_msix_fail),                      // output wire cfg_interrupt_msix_fail

  .sys_clk(sys_clk),                                                      // input wire sys_clk
  .sys_reset(sys_reset)                                                  // input wire sys_reset
);

endmodule // xilinx_v7_pcie3_wrapper
