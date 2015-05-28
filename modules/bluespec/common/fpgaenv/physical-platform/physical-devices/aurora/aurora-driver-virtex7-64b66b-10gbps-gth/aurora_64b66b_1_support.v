
 ///////////////////////////////////////////////////////////////////////////////
 //
 // Project:  Aurora 64B/66B
 // Company:  Xilinx
 //
 //
 //
 // (c) Copyright 2008 - 2009 Xilinx, Inc. All rights reserved.
 //
 // This file contains confidential and proprietary information
 // of Xilinx, Inc. and is protected under U.S. and
 // international copyright and other intellectual property
 // laws.
 //
 // DISCLAIMER
 // This disclaimer is not a license and does not grant any
 // rights to the materials distributed herewith. Except as
 // otherwise provided in a valid license issued to you by
 // Xilinx, and to the maximum extent permitted by applicable
 // law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
 // WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
 // AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
 // BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
 // INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
 // (2) Xilinx shall not be liable (whether in contract or tort,
 // including negligence, or under any other theory of
 // liability) for any loss or damage of any kind or nature
 // related to, arising under or in connection with these
 // materials, including for any direct, or any indirect,
 // special, incidental, or consequential loss or damage
 // (including loss of data, profits, goodwill, or any type of
 // loss or damage suffered as a result of any action brought
 // by a third party) even if such damage or loss was
 // reasonably foreseeable or Xilinx had been advised of the
 // possibility of the same.
 //
 // CRITICAL APPLICATIONS
 // Xilinx products are not designed or intended to be fail-
 // safe, or for use in any application requiring fail-safe
 // performance, such as life-support or safety devices or
 // systems, Class III medical devices, nuclear facilities,
 // applications related to the deployment of airbags, or any
 // other applications that could lead to death, personal
 // injury, or severe property or environmental damage
 // (individually and collectively, "Critical
 // Applications"). Customer assumes the sole risk and
 // liability of any use of Xilinx products in Critical
 // Applications, subject only to applicable laws and
 // regulations governing limitations on product liability.
 //
 // THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
 // PART OF THIS FILE AT ALL TIMES.
 
// LEAP Modification:
// 
// Removed clock buffering from this module.  LEAP buffers the clocks externally. This changed the 
// port interface, since we no longer need to use differential clocks. 
//


 `timescale 1 ns / 10 ps

   (* core_generation_info = "aurora_64b66b_1,aurora_64b66b_v9_3,{c_aurora_lanes=2,c_column_used=right,c_gt_clock_1=GTHQ9,c_gt_clock_2=None,c_gt_loc_1=X,c_gt_loc_10=X,c_gt_loc_11=X,c_gt_loc_12=X,c_gt_loc_13=X,c_gt_loc_14=X,c_gt_loc_15=X,c_gt_loc_16=X,c_gt_loc_17=X,c_gt_loc_18=X,c_gt_loc_19=X,c_gt_loc_2=X,c_gt_loc_20=X,c_gt_loc_21=X,c_gt_loc_22=X,c_gt_loc_23=X,c_gt_loc_24=X,c_gt_loc_25=X,c_gt_loc_26=X,c_gt_loc_27=X,c_gt_loc_28=X,c_gt_loc_29=X,c_gt_loc_3=X,c_gt_loc_30=X,c_gt_loc_31=X,c_gt_loc_32=X,c_gt_loc_33=X,c_gt_loc_34=X,c_gt_loc_35=X,c_gt_loc_36=X,c_gt_loc_37=2,c_gt_loc_38=X,c_gt_loc_39=1,c_gt_loc_4=X,c_gt_loc_40=X,c_gt_loc_41=X,c_gt_loc_42=X,c_gt_loc_43=X,c_gt_loc_44=X,c_gt_loc_45=X,c_gt_loc_46=X,c_gt_loc_47=X,c_gt_loc_48=X,c_gt_loc_5=X,c_gt_loc_6=X,c_gt_loc_7=X,c_gt_loc_8=X,c_gt_loc_9=X,c_lane_width=4,c_line_rate=10.0,c_gt_type=v7gth,c_qpll=true,c_nfc=false,c_nfc_mode=IMM,c_refclk_frequency=156.25,c_simplex=false,c_simplex_mode=TX,c_stream=true,c_ufc=false,c_user_k=false,flow_mode=None,interface_mode=Streaming,dataflow_config=Duplex}" *) 
(* DowngradeIPIdentifiedWarnings="yes" *)
 module aurora_64b66b_1_support 
  (
     // TX AXI Interface 
       input  [0:127]    s_axi_tx_tdata, 
       input             s_axi_tx_tvalid,
       output            s_axi_tx_tready, 
       input             do_cc, 
     // RX AXI Interface 
       output [0:127]    m_axi_rx_tdata, 
       output            m_axi_rx_tvalid, 


 
 
     // GTX Serial I/O
       input   [0:1]      rxp, 
       input   [0:1]      rxn, 
 
       output  [0:1]      txp, 
       output  [0:1]      txn,
 
     // Error Detection Interface
       output             hard_err, 
       output             soft_err, 
 
     // Status
       output             channel_up, 
       output  [0:1]      lane_up,
     // System Interface
       output              init_clk_out, 
       output              user_clk_out, 
       output              sync_clk_out, 
       input              reset, 
       input              reset_pb, 
       input              gt_rxcdrovrden_in, 
       input              power_down, 
       input   [2:0]      loopback,
       input              pma_init, 
       input    drp_clk_in,
 
       output  [15:0]  drpdo_out, 
       output          drprdy_out, 
       output  [15:0]  drpdo_out_lane1, 
       output          drprdy_out_lane1, 
 
    //---------------------- GT DRP Ports ----------------------
       input   [8:0]   drpaddr_in,
       input   [15:0]  drpdi_in,
       input           drpen_in, 
       input           drpwe_in, 
       input           drpen_in_lane1, 
       input           drpwe_in_lane1, 
    //---------------------- GTXE2 COMMON DRP Ports ----------------------
       input   [7:0]   qpll_drpaddr_in,
       input   [15:0]  qpll_drpdi_in,
       input           qpll_drpen_in, 
       input           qpll_drpwe_in, 
       output  [15:0]  qpll_drpdo_out, 
       output          qpll_drprdy_out, 
       input               init_clk,
       output              link_reset_out, 
       output              gt_pll_lock, 
       output              sys_reset_out,
       output   gt_reset_out,

     // GTX Reference Clock Interface
       input              refclk1_in, 

       output             gt_refclk1_out,
 

//--- assigning output values {
    output                    gt_qpllclk_quad10_out  ,
    output                    gt_qpllrefclk_quad10_out  ,

    output                    gt_qpllrefclklost_out ,
    output                    gt_qplllock_out ,
//--- assigning output values }
       output                 mmcm_not_locked_out,
       output              tx_out_clk
 
 );
 
 
 //***********************************Port Declarations*******************************
 
 
 //************************External Register Declarations*****************************
 
 
 //********************************Wire Declarations**********************************
 
     //System Interface
       wire                 mmcm_not_locked_i ; 
       wire                 powerdown_i ; 
 
       wire                  pma_init_i; 
 
  
     // clock
       (* KEEP = "TRUE" *) wire               user_clk_i; 
       (* KEEP = "TRUE" *) wire               sync_clk_i; 
       (* KEEP = "TRUE" *) wire               GTHQ9_left_i; 
       (* KEEP = "TRUE" *) wire               INIT_CLK_i  /* synthesis syn_keep = 1 */; 
       wire               drp_clk_i;
       wire    [8:0] drpaddr_in_i;
       wire    [15:0]     drpdi_in_i;
       wire    [15:0]     drpdo_out_i; 
       wire               drprdy_out_i; 
       wire               drpen_in_i; 
       wire               drpwe_in_i; 
       wire    [8:0] drpaddr_in_lane1_i;
       wire    [15:0]     drpdi_in_lane1_i;
       wire    [15:0]     drpdo_out_lane1_i; 
       wire               drprdy_out_lane1_i; 
       wire               drpen_in_lane1_i; 
       wire               drpwe_in_lane1_i; 
       wire    [7:0]      qpll_drpaddr_in_i;
       wire    [15:0]     qpll_drpdi_in_i;
       wire    [15:0]     qpll_drpdo_out_i; 
       wire               qpll_drprdy_out_i; 
       wire               qpll_drpen_in_i; 
       wire               qpll_drpwe_in_i; 
       wire               link_reset_i;
       wire               sysreset_from_vio_i;
       wire               gtreset_from_vio_i;
       wire               rx_cdrovrden_i;
       wire               gt_reset_i;
       wire               gt_reset_i_tmp;

//---{
    wire                     gt_qpllclk_quad10_i;
    wire                     gt_qpllrefclk_quad10_i;
    wire                     gt_to_common_qpllreset_i;
    wire                     gt_qpllrefclklost_i; 
    wire                     gt_qplllock_i; 
//---}
    wire                     refclk1_in;
    wire                     refclk2_in;
    wire                     sysreset_from_support;


//--- assigning output values {
    assign                     gt_qpllclk_quad10_out  = gt_qpllclk_quad10_i    ;
    assign                     gt_qpllrefclk_quad10_out  = gt_qpllrefclk_quad10_i ;

    assign                     gt_qpllrefclklost_out =  gt_qpllrefclklost_i ;
    assign                     gt_qplllock_out =  gt_qplllock_i; 

//--- assigning output values }


 //*********************************Main Body of Code**********************************
 
 
 
 
     //____________________________Register User I/O___________________________________
 
     // System Interface
     assign  power_down_i      =   1'b0;
    // Native DRP Interface
     assign  drpaddr_in_i                     =  8'h0;
     assign  drpdi_in_i                       =  16'h0;
     assign  drpwe_in_i     =  1'b0; 
     assign  drpen_in_i     =  1'b0; 
     assign  drpaddr_in_lane1_i                     =  8'h0;
     assign  drpdi_in_lane1_i                       =  16'h0;
     assign  drpwe_in_lane1_i     =  1'b0; 
     assign  drpen_in_lane1_i     =  1'b0; 
     assign  qpll_drpaddr_in_i   =  8'h0;
     assign  qpll_drpdi_in_i     =  16'h0;
     assign  qpll_drpen_in_i    =  1'b0; 
     assign  qpll_drpwe_in_i    =  1'b0; 
 
 
     //___________________________Module Instantiations_________________________________

aurora_64b66b_1_gt_common_wrapper gt_common_support
(
    .gt_qpllclk_quad10_out   (gt_qpllclk_quad10_i      ),
    .gt_qpllrefclk_quad10_out(gt_qpllrefclk_quad10_i   ),

         .GT0_GTREFCLK0_COMMON_IN             (refclk1_in), 

    //----------------------- Common Block - QPLL Ports ------------------------

    .GT0_QPLLLOCK_OUT (gt_qplllock_i),
    .GT0_QPLLRESET_IN (gt_to_common_qpllreset_i),

    .GT0_QPLLLOCKDETCLK_IN (INIT_CLK_i),

    .GT0_QPLLREFCLKLOST_OUT (gt_qpllrefclklost_i),


    //---------------------- Common DRP Ports ----------------------
         .qpll_drpaddr_in (qpll_drpaddr_in),
         .qpll_drpdi_in   (qpll_drpdi_in),
         .qpll_drpclk_in  (drp_clk_in),
         .qpll_drpdo_out (qpll_drpdo_out), 
         .qpll_drprdy_out(qpll_drprdy_out), 
         .qpll_drpen_in  (qpll_drpen_in), 
         .qpll_drpwe_in  (qpll_drpwe_in)
);
     

//--- Instance of GT differential buffer ---------//

     // Instantiate a clock module for clock division.
     aurora_64b66b_1_CLOCK_MODULE clock_module_i
     (
         .INIT_CLK(init_clk),
         .INIT_CLK_O(INIT_CLK_i),
         .CLK(tx_out_clk),
         .CLK_LOCKED(gt_pll_lock),
         .USER_CLK(user_clk_i),
         .SYNC_CLK(sync_clk_i),
         .MMCM_NOT_LOCKED(mmcm_not_locked_i)
     );

  //  outputs
  assign gt_reset_out          =  pma_init_i;
  assign gt_refclk1_out        =  refclk1_in;
  assign init_clk_out          =  INIT_CLK_i;
  assign user_clk_out          =  user_clk_i;
  assign sync_clk_out          =  sync_clk_i;
  assign mmcm_not_locked_out   =  mmcm_not_locked_i;
  assign tx_lock               =  gt_pll_lock;


 

 
 
     // Instantiate reset module to generate system reset
     aurora_64b66b_1_SUPPORT_RESET_LOGIC support_reset_logic_i
     (
         .RESET(reset_pb),
         .USER_CLK(user_clk_i),
         .INIT_CLK(INIT_CLK_i),
         .GT_RESET_IN(pma_init),
         .SYSTEM_RESET(sysreset_from_support),
         .GT_RESET_OUT(pma_init_i)
     );

//----- Instance of core -----[
aurora_64b66b_1_core aurora_64b66b_1_core_i
     (
        // TX AXI4-S Interface
         .s_axi_tx_tdata(s_axi_tx_tdata),
         .s_axi_tx_tvalid(s_axi_tx_tvalid),
         .s_axi_tx_tready(s_axi_tx_tready),

 
         .do_cc(do_cc),
        // RX AXI4-S Interface
         .m_axi_rx_tdata(m_axi_rx_tdata),
         .m_axi_rx_tvalid(m_axi_rx_tvalid),
  
       

 
 
         // GTX Serial I/O
         .rxp(rxp),
         .rxn(rxn),
         .txp(txp),
         .txn(txn),
 
         //GTX Reference Clock Interface
         .gt_refclk1(refclk1_in),
         .hard_err(hard_err),
         .soft_err(soft_err),


         // Status
         .channel_up(channel_up),
         .lane_up(lane_up),

 
         // System Interface
         .mmcm_not_locked(mmcm_not_locked_i),
         .user_clk(user_clk_i),
         .sync_clk(sync_clk_i),
         .reset(reset),
         .sysreset_to_core(sysreset_from_support),
         .gt_rxcdrovrden_in(gt_rxcdrovrden_in),
         .power_down(power_down),
         .loopback(loopback),
         .pma_init(pma_init_i),
         .rst_drp_strt(pma_init),
         .gt_pll_lock(gt_pll_lock),
         .drp_clk_in(drp_clk_in),
//---{
       .gt_qpllclk_quad10_in       (gt_qpllclk_quad10_i        ), 
       .gt_qpllrefclk_quad10_in    (gt_qpllrefclk_quad10_i     ),    

       .gt_to_common_qpllreset_out  (gt_to_common_qpllreset_i    ),
       .gt_qplllock_in       (gt_qplllock_i        ), 
       .gt_qpllrefclklost_in (gt_qpllrefclklost_i  ),       
//---}
    //---------------------- GT DRP Ports ----------------------
         .drpaddr_in(drpaddr_in),
         .drpdi_in(drpdi_in),
         .drpdo_out(drpdo_out), 
         .drprdy_out(drprdy_out), 
         .drpen_in(drpen_in), 
         .drpwe_in(drpwe_in), 
         .drpdo_out_lane1(drpdo_out_lane1), 
         .drprdy_out_lane1(drprdy_out_lane1), 
         .drpen_in_lane1(drpen_in_lane1), 
         .drpwe_in_lane1(drpwe_in_lane1), 
         .init_clk(INIT_CLK_i),
         .link_reset_out(link_reset_out),
        .sys_reset_out(sys_reset_out),
        .tx_out_clk(tx_out_clk)
     );

//----- Instance of core -----]


 endmodule
