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

 //
 ///////////////////////////////////////////////////////////////////////////////
 //
 //  aurora_64b66b_1
 //
 //
 //
 //  Description: This is the top level module for Aurora 64B66B design
 //
 //
 ///////////////////////////////////////////////////////////////////////////////

 `timescale 1 ns / 10 ps

   (* core_generation_info = "aurora_64b66b_1,aurora_64b66b_v9_3,{c_aurora_lanes=2,c_column_used=right,c_gt_clock_1=GTHQ9,c_gt_clock_2=None,c_gt_loc_1=X,c_gt_loc_10=X,c_gt_loc_11=X,c_gt_loc_12=X,c_gt_loc_13=X,c_gt_loc_14=X,c_gt_loc_15=X,c_gt_loc_16=X,c_gt_loc_17=X,c_gt_loc_18=X,c_gt_loc_19=X,c_gt_loc_2=X,c_gt_loc_20=X,c_gt_loc_21=X,c_gt_loc_22=X,c_gt_loc_23=X,c_gt_loc_24=X,c_gt_loc_25=X,c_gt_loc_26=X,c_gt_loc_27=X,c_gt_loc_28=X,c_gt_loc_29=X,c_gt_loc_3=X,c_gt_loc_30=X,c_gt_loc_31=X,c_gt_loc_32=X,c_gt_loc_33=X,c_gt_loc_34=X,c_gt_loc_35=X,c_gt_loc_36=X,c_gt_loc_37=2,c_gt_loc_38=X,c_gt_loc_39=1,c_gt_loc_4=X,c_gt_loc_40=X,c_gt_loc_41=X,c_gt_loc_42=X,c_gt_loc_43=X,c_gt_loc_44=X,c_gt_loc_45=X,c_gt_loc_46=X,c_gt_loc_47=X,c_gt_loc_48=X,c_gt_loc_5=X,c_gt_loc_6=X,c_gt_loc_7=X,c_gt_loc_8=X,c_gt_loc_9=X,c_lane_width=4,c_line_rate=10.0,c_gt_type=v7gth,c_qpll=true,c_nfc=false,c_nfc_mode=IMM,c_refclk_frequency=156.25,c_simplex=false,c_simplex_mode=TX,c_stream=true,c_ufc=false,c_user_k=false,flow_mode=None,interface_mode=Streaming,dataflow_config=Duplex}" *)
(* DowngradeIPIdentifiedWarnings="yes" *)
 module aurora_64b66b_1
 (
        // TX AXI4-S Interface
         s_axi_tx_tdata,
         s_axi_tx_tvalid,
         s_axi_tx_tready,


         do_cc,
        // RX AXI4-S Interface
         m_axi_rx_tdata,
         m_axi_rx_tvalid,





        // GTX Serial I/O
         rxp,
         rxn,
         txp,
         txn,

        //GTX Reference Clock Interface
         gt_refclk1_p,
         gt_refclk1_n,
         gt_refclk1_out,
         hard_err,
         soft_err,
        // Status
         channel_up,
         lane_up,


        // System Interface
         user_clk_out,
         init_clk_out,
         mmcm_not_locked_out,

         sync_clk_out,


         reset,
         reset_pb,
         gt_rxcdrovrden_in,
         power_down,
         loopback,
         pma_init,
         gt_pll_lock,
         drp_clk_in,
//---{
//---}
        //---------------------- GT DRP Ports ----------------------
         drpaddr_in,
         drpdi_in,
         drpdo_out,
         drprdy_out,
         drpen_in,
         drpwe_in,
         drpdo_out_lane1,
         drprdy_out_lane1,
         drpen_in_lane1,
         drpwe_in_lane1,


        //---------------------- GTXE2 COMMON DRP Ports ----------------------
         qpll_drpaddr_in,
         qpll_drpdi_in,
         qpll_drpdo_out,
         qpll_drprdy_out,
         qpll_drpen_in,
         qpll_drpwe_in,
         init_clk_p,
         init_clk_n,
         link_reset_out,
        // shared mode 7 series GT quad port placements starts









        gt_qpllclk_quad10_out  ,
        gt_qpllrefclk_quad10_out  ,


        // shared mode 7 series GT quad port placements ends


        gt_qpllrefclklost_out ,
        gt_qplllock_out ,

         sys_reset_out,
         gt_reset_out,
         tx_out_clk
 );

 `define DLY #1
 // synthesis attribute X_CORE_INFO of aurora_64b66b_1 is "aurora_64b66b_v9_3, Coregen v14.3_ip3, Number of lanes = 2, Line rate is double10.0Gbps, Reference Clock is double156.25MHz, Interface is Streaming, Flow Control is None and is operating in DUPLEX configuration";

 //***********************************Port Declarations*******************************

     // TX AXI Interface
       input  [0:127]    s_axi_tx_tdata; 
       input             s_axi_tx_tvalid;
       output            s_axi_tx_tready;
       input             do_cc;
     // RX AXI Interface
       output [0:127]    m_axi_rx_tdata; 
       output            m_axi_rx_tvalid;




     // GTX Serial I/O
       input   [0:1]      rxp;
       input   [0:1]      rxn;

       output  [0:1]      txp;
       output  [0:1]      txn;

     // GTX Reference Clock Interface
        input              gt_refclk1_p;
        input              gt_refclk1_n;
        output             gt_refclk1_out;

     // Error Detection Interface
       output             hard_err;
       output             soft_err;

     // Status
       output             channel_up;
       output  [0:1]      lane_up;
     // System Interface
       output             user_clk_out;
       output             init_clk_out;
       output             mmcm_not_locked_out;
       output  sync_clk_out;
       input              reset;
       input              reset_pb;
       input              gt_rxcdrovrden_in;
       input              power_down;
       input   [2:0]      loopback;
       input              pma_init;
       input    drp_clk_in;


//---{
//---}

       output  [15:0]  drpdo_out;
       output          drprdy_out;
       output  [15:0]  drpdo_out_lane1;
       output          drprdy_out_lane1;

    //---------------------- GT DRP Ports ----------------------
       input   [8:0]   drpaddr_in;
       input   [15:0]  drpdi_in;
       input           drpen_in;
       input           drpwe_in;
       input           drpen_in_lane1;
       input           drpwe_in_lane1;


    //---------------------- GTXE2 COMMON DRP Ports ----------------------
       input   [7:0]   qpll_drpaddr_in;
       input   [15:0]  qpll_drpdi_in;
       input           qpll_drpen_in;
       input           qpll_drpwe_in;
       output  [15:0]  qpll_drpdo_out;
       output          qpll_drprdy_out;
       input              init_clk_p;
       input              init_clk_n;
       output              link_reset_out;
       output              gt_pll_lock;
       output              sys_reset_out;
       output              gt_reset_out;
       output              tx_out_clk;

        // shared mode 7 series GT quad port placements starts
        output  gt_qpllclk_quad10_out;
        output  gt_qpllrefclk_quad10_out;
        // shared mode 7 series GT quad port placements ends


        output  gt_qpllrefclklost_out ;
        output  gt_qplllock_out ;

       wire    [0:63]    tied_to_ground_vec;
       wire              tied_to_ground;

 //*********************************Main Body of Code**********************************

      assign tied_to_ground_vec = 64'd0;
      assign tied_to_ground     = 1'd0;

aurora_64b66b_1_support inst
// this is support instance in the aurora_64b66b.v file
     (
     // TX AXI Interface
       .s_axi_tx_tdata      (s_axi_tx_tdata),
       .s_axi_tx_tvalid     (s_axi_tx_tvalid),
       .s_axi_tx_tready     (s_axi_tx_tready),
       .do_cc               (do_cc),
     // RX AXI Interface
       .m_axi_rx_tdata      (m_axi_rx_tdata),
       .m_axi_rx_tvalid     (m_axi_rx_tvalid),




     // GTX Serial I/O
       .rxp      (rxp),
       .rxn      (rxn),
       .txp      (txp),
       .txn      (txn),


     // Error Detection Interface
       .hard_err      (hard_err),
       .soft_err      (soft_err),

     // Status
       .channel_up    (channel_up),
       .lane_up       (lane_up),
     // System Interface
       .user_clk_out      (user_clk_out),
       .init_clk_out      (init_clk_out),
       .sync_clk_out      (sync_clk_out),
       .reset      (reset),
       .reset_pb   (reset_pb),
       .gt_rxcdrovrden_in      (gt_rxcdrovrden_in),
       .power_down      (power_down),
       .loopback      (loopback),
       .pma_init      (pma_init),
       .drp_clk_in    (drp_clk_in),

       .drpdo_out    (drpdo_out),
       .drprdy_out    (drprdy_out),
       .drpdo_out_lane1    (drpdo_out_lane1),
       .drprdy_out_lane1    (drprdy_out_lane1),

    //---------------------- GT DRP Ports ----------------------
       .drpaddr_in(drpaddr_in),
       .drpdi_in(drpdi_in),
       .drpen_in    (drpen_in),
       .drpwe_in    (drpwe_in),
       .drpen_in_lane1    (drpen_in_lane1),
       .drpwe_in_lane1    (drpwe_in_lane1),


    //---------------------- GTXE2 COMMON DRP Ports ----------------------
       .qpll_drpaddr_in(qpll_drpaddr_in),
       .qpll_drpdi_in(qpll_drpdi_in),
       .qpll_drpen_in    (qpll_drpen_in),
       .qpll_drpwe_in    (qpll_drpwe_in),
       .qpll_drpdo_out    (qpll_drpdo_out),
       .qpll_drprdy_out    (qpll_drprdy_out),
       .init_clk_p                   (init_clk_p),
       .init_clk_n                   (init_clk_n),
       .link_reset_out               (link_reset_out),
       .gt_pll_lock      (gt_pll_lock),

     // GTX Reference Clock Interface
       .gt_refclk1_p(gt_refclk1_p),
       .gt_refclk1_n(gt_refclk1_n),
       .gt_refclk1_out(gt_refclk1_out),

//----{
        // shared mode 7 series GT quad port placements starts
        .gt_qpllclk_quad10_out     (gt_qpllclk_quad10_out   ),
        .gt_qpllrefclk_quad10_out  (gt_qpllrefclk_quad10_out),
        // shared mode 7 series GT quad port placements ends


	//--
        .gt_qpllrefclklost_out	(gt_qpllrefclklost_out  ),
        .gt_qplllock_out		(gt_qplllock_out         ),
        //--
//----}
       .sys_reset_out			(sys_reset_out),
       .mmcm_not_locked_out 	(mmcm_not_locked_out),
       .gt_reset_out			(gt_reset_out),
       .tx_out_clk			(tx_out_clk)
     );


 endmodule
