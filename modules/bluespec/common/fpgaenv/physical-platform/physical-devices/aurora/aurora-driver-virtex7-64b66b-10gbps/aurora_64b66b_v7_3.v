 
///////////////////////////////////////////////////////////////////////////////
//
// Project:  Aurora 64B/66B 
// Version:  version 7.3
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
//  aurora_64b66b_v7_3
//
//
//
//  Description: This is the top level module for a 1 8-byte lane Aurora
//               reference design module. This module is a prototype and only
//               performs the lane and channel initialization
//
//               * Supports Virtex 5
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 10 ps

(* core_generation_info = "aurora_64b66b_v7_3,aurora_64b66b_v7_3,{c_aurora_lanes=1, c_column_used=right, c_gt_clock_1=GTXQ0, c_gt_clock_2=None, c_gt_loc_1=1, c_gt_loc_10=X, c_gt_loc_11=X, c_gt_loc_12=X, c_gt_loc_13=X, c_gt_loc_14=X, c_gt_loc_15=X, c_gt_loc_16=X, c_gt_loc_17=X, c_gt_loc_18=X, c_gt_loc_19=X, c_gt_loc_2=X, c_gt_loc_20=X, c_gt_loc_21=X, c_gt_loc_22=X, c_gt_loc_23=X, c_gt_loc_24=X, c_gt_loc_25=X, c_gt_loc_26=X, c_gt_loc_27=X, c_gt_loc_28=X, c_gt_loc_29=X, c_gt_loc_3=X, c_gt_loc_30=X, c_gt_loc_31=X, c_gt_loc_32=X, c_gt_loc_33=X, c_gt_loc_34=X, c_gt_loc_35=X, c_gt_loc_36=X, c_gt_loc_37=X, c_gt_loc_38=X, c_gt_loc_39=X, c_gt_loc_4=X, c_gt_loc_40=X, c_gt_loc_41=X, c_gt_loc_42=X, c_gt_loc_43=X, c_gt_loc_44=X, c_gt_loc_45=X, c_gt_loc_46=X, c_gt_loc_47=X, c_gt_loc_48=X, c_gt_loc_5=X, c_gt_loc_6=X, c_gt_loc_7=X, c_gt_loc_8=X, c_gt_loc_9=X, c_lane_width=4, c_line_rate=5.0, c_gt_type=gtx, c_qpll=false, c_nfc=false, c_nfc_mode=IMM, c_refclk_frequency=156.25, c_simplex=false, c_simplex_mode=TX, c_stream=true, c_ufc=false, c_user_k=false,flow_mode=None, interface_mode=Streaming, dataflow_config=Duplex,}" *)

module aurora_64b66b_v7_3 #
(
     parameter   SIM_GTXRESET_SPEEDUP=   "FALSE"      // Set to 1 to speed up sim reset
)
(
    // TX Stream Interface
    TX_D,
    TX_SRC_RDY_N,
    TX_DST_RDY_N,

    // RX Stream Interface
    RX_D,
    RX_SRC_RDY_N,

    DO_CC,

    // GTX Serial I/O
    RXP,
    RXN,
    TXP,
    TXN,

   // GTX Reference Clock Interface
    GTXQ0,
                                                                                   // Error Detection Interface
    HARD_ERR,
    SOFT_ERR,

    // Status
    CHANNEL_UP,
    LANE_UP,
 
    // System Interface
    MMCM_NOT_LOCKED,
    USER_CLK,
    SYNC_CLK,
    SHIM_CLK,
    RESET,
    POWER_DOWN,
    LOOPBACK,
    PMA_INIT,
    DRP_CLK_IN,
   // GT DRP Ports 
    DRPADDR_IN,
    DRPDI_IN,
    DRPDO_OUT,
    DRPRDY_OUT,
    DRPEN_IN,
    DRPWE_IN,

   QPLL_DRPADDR_IN,
   QPLL_DRPDI_IN,
   QPLL_DRPDO_OUT,
   QPLL_DRPRDY_OUT,
   QPLL_DRPEN_IN,
   QPLL_DRPWE_IN,
 
    INIT_CLK,
    LINK_RESET_OUT,
    MMCM_LOCK,
    TX_OUT_CLK
);

`define DLY #1
// synthesis attribute X_CORE_INFO of aurora_64b66b_v7_3 is "aurora_64b66b_v7_3, Coregen v14.3_ip3, Number of lanes = 1, Line rate is 5.0Gbps, Reference Clock is 156.25MHz, Interface is Streaming, Flow Control is None and is operating in DUPLEX configuration";

//***********************************Port Declarations*******************************

    // TX Stream Interface
    input   [0:63]     TX_D;
    input              TX_SRC_RDY_N;
    output             TX_DST_RDY_N;

    // RX Stream Interface
    output  [0:63]     RX_D;
    output             RX_SRC_RDY_N;
   
    input             DO_CC;


    // GTX Serial I/O
    input             RXP;
    input             RXN;

    output             TXP;
    output             TXN;

    // GTX Reference Clock Interface
    input              GTXQ0;

    // Error Detection Interface
    output            HARD_ERR;
    output            SOFT_ERR;

    // Status
    output             CHANNEL_UP;
    output             LANE_UP;

     
    // System Interface
    input               MMCM_NOT_LOCKED;
    input               USER_CLK;
    input               SYNC_CLK;
    input               SHIM_CLK;
    input               RESET;
    input               POWER_DOWN;
    input    [2:0]      LOOPBACK;
    input               PMA_INIT;
    input    DRP_CLK_IN;
   //---------------------- GT DRP Ports ----------------------
    input   [8:0]   DRPADDR_IN;
    input   [15:0]  DRPDI_IN;
    output  [15:0]  DRPDO_OUT;
    output          DRPRDY_OUT;
    input           DRPEN_IN;
    input           DRPWE_IN;

    input   [7:0]   QPLL_DRPADDR_IN;
    input   [15:0]  QPLL_DRPDI_IN;
    output  [15:0]  QPLL_DRPDO_OUT;
    output          QPLL_DRPRDY_OUT;
    input           QPLL_DRPEN_IN;
    input           QPLL_DRPWE_IN;
   
    output              MMCM_LOCK;
    output              TX_OUT_CLK;
    input              INIT_CLK;
    output             LINK_RESET_OUT;

//*********************************Wire Declarations**********************************

    wire    [0:63]     tx_d_i2;
    wire               tx_src_rdy_n_i2;
    wire               tx_dst_rdy_n_i2;
    wire    [0:2]      tx_rem_i2;
    wire    [0:2]      tx_rem_i3;
    wire               tx_sof_n_i2;
    wire               tx_eof_n_i2;
    wire    [0:63]     rx_d_i2;
    wire               rx_src_rdy_n_i2;
    wire    [0:2]      rx_rem_i2;
    wire    [0:2]      rx_rem_i3;
    wire               rx_sof_n_i2;
    wire               rx_eof_n_i2;
    

    wire    [0:63]     tx_d_i;
    wire               tx_src_rdy_n_i;
    wire               tx_dst_rdy_n_i;
    


    wire    [0:63]     rx_d_i;
    wire               rx_src_rdy_n_i;
    


    wire               ch_bond_done_i;
    wire               en_chan_sync_i;
    wire               chan_bond_reset_i;
    wire    [0:63]     tx_data_i;
    wire    [0:63]     rx_data_i;
    wire    [0:63]     tx_pe_data_i;
    wire               tx_pe_data_v_i;
    wire    [0:63]     rx_pe_data_i;
    wire               rx_pe_data_v_i;
    wire               channel_up_i;
    wire                system_reset_c;
    wire               tx_buf_err_i;
    wire               rx_lossofsync_i;
    wire               check_polarity_i;
    wire               rx_neg_i;
    wire               rx_polarity_i;
    wire               tx_char_disp_val_i;
    wire               tx_char_disp_mode_i;
    wire               pll_lock_i;
    wire               tx_reset_i;
    wire               hard_err_i;
    wire               soft_err_i;
    wire               lane_up_i;
    wire               raw_tx_out_clk_i;
    wire               reset_lanes_i;
    wire               rx_buf_err_i;
    wire               rx_run_disp_i;
    wire               rx_char_is_k_i;
    wire               rx_reset_i;
    wire               gen_na_idles_i;




    wire               gen_ch_bond_i;
    wire               got_na_idles_i;
    wire               got_idles_i;
    wire               got_cc_i;
    wire               rxdatavalid_to_ll_i;
    wire               remote_ready_i;
    wire               got_cb_i;
    wire               gen_cc_i;




    
    //Datavalid signal is routed to Local Link
    wire               rxdatavalid_i;
    wire               rxdatavalid_to_lanes_i;
    wire               txdatavalid_i;
    wire               txdatavalid_to_ll_i;
    wire               txdatavalid_symgen_i;
    wire               txclk_locked_c;

    wire    [8:0] drpaddr_in_i;
    wire    [15:0]     drpdi_in_i;
    wire               drp_clk_i;
    wire    [15:0]     drpdo_out_i;
    wire               drprdy_out_i;
    wire               drpen_in_i;
    wire               drpwe_in_i;

    reg                SOFT_ERR;

//*********************************Main Body of Code**********************************

    // Connect top level logic
    assign          CHANNEL_UP  =   channel_up_i;
    assign          system_reset_c = RESET || MMCM_NOT_LOCKED || !pll_lock_i ;
    assign          txclk_locked_c = !MMCM_NOT_LOCKED ;

    always @(posedge USER_CLK)
      if(RESET)
          SOFT_ERR  <= `DLY 1'b0;
      else 
          SOFT_ERR  <= `DLY (|soft_err_i) & channel_up_i;


    // Connect the TXOUTCLK of lane 0 to TX_OUT_CLK
    assign  TX_OUT_CLK  =   raw_tx_out_clk_i;


    assign  MMCM_LOCK =   pll_lock_i;
    assign  rxdatavalid_to_lanes_i = |rxdatavalid_i;



    //_________________________Instantiate Lane 0______________________________

    assign         LANE_UP =   lane_up_i;

aurora_64b66b_v7_3_AURORA_LANE aurora_lane_0_i
    (
        // TX STREAM
        .TX_PE_DATA(tx_pe_data_i[0:63]),
        .TX_PE_DATA_V(tx_pe_data_v_i),



        .CHANNEL_UP(channel_up_i),
        .GEN_CC(gen_cc_i),

        // RX STREAM
        .RX_PE_DATA(rx_pe_data_i[0:63]),
        .RX_PE_DATA_V(rx_pe_data_v_i),




        // GTX Interface
        .RX_DATA(rx_data_i[0:63]),
        .RX_RUN_DISP(rx_run_disp_i),
        .RX_CHAR_IS_K(rx_char_is_k_i),
        .TX_BUF_ERR(|tx_buf_err_i),
        .RX_BUF_ERR(|rx_buf_err_i),
        .CHECK_POLARITY(check_polarity_i),
        .RX_NEG(rx_neg_i),
        .RX_POLARITY(rx_polarity_i),
        .RX_RESET(rx_reset_i),
        .TX_CHAR_DISP_VAL(tx_char_disp_val_i),
        .TX_CHAR_DISP_MODE(tx_char_disp_mode_i),
        .TX_DATA(tx_data_i[0:63]),
        .TX_RESET(tx_reset_i),
        .RX_LOSSOFSYNC(rx_lossofsync_i),
        
        // Global Logic Interface
        .GEN_NA_IDLE(gen_na_idles_i),
        .GEN_CH_BOND(gen_ch_bond_i),
        .LANE_UP(lane_up_i),
        .HARD_ERR(hard_err_i),
        .SOFT_ERR(soft_err_i),
        .GOT_NA_IDLE(got_na_idles_i),
        .GOT_CC(got_cc_i),
        .REMOTE_READY(remote_ready_i),
        .GOT_CB(got_cb_i),
        .GOT_IDLE(got_idles_i),

        // System Interface
        .USER_CLK(USER_CLK),
        .RESET_LANES(reset_lanes_i),
        .RESET(system_reset_c),
        .RXDATAVALID_IN(rxdatavalid_to_lanes_i),
        .TXDATAVALID_SYMGEN_IN(txdatavalid_symgen_i)
    );



    //_________________________Instantiate GTX Wrapper ______________________________

    aurora_64b66b_v7_3_WRAPPER  #
    (
         .SIM_GTXRESET_SPEEDUP(SIM_GTXRESET_SPEEDUP)
    )
    aurora_64b66b_v7_3_wrapper_i
    (
 
        // Aurora Lane Interface
        .CHECK_POLARITY_IN(check_polarity_i),
        .RX_NEG_OUT(rx_neg_i),
        .RXPOLARITY_IN(rx_polarity_i),
        .RXRESET_IN(rx_reset_i),
        .TXDATA_IN(tx_data_i[0:63]), 
        .TXRESET_IN(tx_reset_i),        
        .RXDATA_OUT(rx_data_i[0:63]),        
        .RXBUFERR_OUT(rx_buf_err_i),        
        .TXBUFERR_OUT(tx_buf_err_i),              
        
        // Global Logic Interface
        .CHBONDDONE_OUT(ch_bond_done_i),
        .ENCHANSYNC_IN(en_chan_sync_i), 
        // Serial IO
        .RX1N_IN(RXN),      
        .RX1P_IN(RXP),     
        .TX1N_OUT(TXN),       
        .TX1P_OUT(TXP),

        // Clocks and Clock Status
        .TXUSRCLK_IN(SYNC_CLK),
        .TXUSRCLK2_IN(USER_CLK),
        .RXUSRCLK2_IN(USER_CLK),
        .RXLOSSOFSYNC_OUT(rx_lossofsync_i),        
        .TXOUTCLK1_OUT(raw_tx_out_clk_i),       
        .PLLLKDET_OUT(pll_lock_i),

        // System Interface
        .GTXRESET_IN(PMA_INIT),
        .CHAN_BOND_RESET(chan_bond_reset_i), 
        .LOOPBACK_IN(LOOPBACK),
        .POWERDOWN_IN(POWER_DOWN),
        .REFCLK1_IN(GTXQ0),
        .TXHEADER_IN({tx_char_disp_val_i,tx_char_disp_mode_i}),
        .RXHEADER_OUT({rx_run_disp_i,rx_char_is_k_i}),
        .RESET(system_reset_c),
        .RXDATAVALID_OUT(rxdatavalid_i),
        .TXDATAVALID_OUT(txdatavalid_i),
        .TXCLK_LOCK(txclk_locked_c),

   //---------------------- GT DRP Ports ----------------------
        .DRPADDR_IN(DRPADDR_IN),
        .DRP_CLK_IN(DRP_CLK_IN),
        .DRPDI_IN(DRPDI_IN),
        .DRPDO_OUT(DRPDO_OUT),
        .DRPRDY_OUT(DRPRDY_OUT),
        .DRPEN_IN(DRPEN_IN),
        .DRPWE_IN(DRPWE_IN),

   //---------------------- GTXE2 COMMON DRP Ports ----------------------
        .QPLL_DRPADDR_IN(QPLL_DRPADDR_IN),
        .QPLL_DRPDI_IN(QPLL_DRPDI_IN),
        .QPLL_DRPDO_OUT(QPLL_DRPDO_OUT),
        .QPLL_DRPRDY_OUT(QPLL_DRPRDY_OUT),
        .QPLL_DRPEN_IN(QPLL_DRPEN_IN),
        .QPLL_DRPWE_IN(QPLL_DRPWE_IN),
        .INIT_CLK(INIT_CLK),
        .LINK_RESET_OUT(LINK_RESET_OUT),

        .TXDATAVALID_SYMGEN_OUT(txdatavalid_symgen_i)

    );



    //__________Instantiate Global Logic to combine Lanes into a Channel______

    aurora_64b66b_v7_3_GLOBAL_LOGIC    global_logic_i
    (
        //GTX Interface
        .CH_BOND_DONE(ch_bond_done_i),
        .EN_CHAN_SYNC(en_chan_sync_i),
        .CHAN_BOND_RESET(chan_bond_reset_i),

        // Aurora Lane Interface
        .LANE_UP(lane_up_i),
        .HARD_ERR(hard_err_i),
        .GEN_NA_IDLES(gen_na_idles_i),
        .GEN_CH_BOND(gen_ch_bond_i),
        .RESET_LANES(reset_lanes_i),
        .GOT_NA_IDLES(got_na_idles_i),
        .GOT_CCS(got_cc_i),
        .REMOTE_READY(remote_ready_i),
        .GOT_CBS(got_cb_i),
        .GOT_IDLES(got_idles_i),

        // System Interface
        .USER_CLK(USER_CLK),
        .RESET(system_reset_c),
        .POWER_DOWN(POWER_DOWN),
        .CHANNEL_UP(channel_up_i),
        .CHANNEL_HARD_ERR(HARD_ERR),
        .TXDATAVALID_IN(txdatavalid_i)
    );

    //_____________________________ TX AXI SHIM _______________________________
    // Converts input AXI4-Stream signals to LocalLink

    
   // TX STREAM
   aurora_64b66b_v7_3_TX_STREAM tx_stream_i
   (
        // AXI PDU Interface
        .TX_D(TX_D),
        .TX_SRC_RDY_N(TX_SRC_RDY_N),
        .TX_DST_RDY_N(TX_DST_RDY_N),

        .TX_PE_DATA(tx_pe_data_i),
        .TX_PE_DATA_V(tx_pe_data_v_i),


        .CHANNEL_UP(channel_up_i),
        .DO_CC(DO_CC),
        .GEN_CC(gen_cc_i),
        .USER_CLK(USER_CLK),
        .TXDATAVALID_IN(txdatavalid_i)
   );
                                                                                
   // RX STREAM
   aurora_64b66b_v7_3_RX_STREAM rx_stream_i
   (
        // AXI PDU Interface
        .RX_D(RX_D),
        .RX_SRC_RDY_N(RX_SRC_RDY_N),
        .RX_PE_DATA(rx_pe_data_i),
        .RX_PE_DATA_V(rx_pe_data_v_i),

        .CHANNEL_UP(channel_up_i),
        .USER_CLK(USER_CLK),
        .RESET(reset_lanes_i)

   );

endmodule
