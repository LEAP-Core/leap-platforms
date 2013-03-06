///////////////////////////////////////////////////////////////////////////////
// (c) Copyright 2008 Xilinx, Inc. All rights reserved.
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
// 
///////////////////////////////////////////////////////////////////////////////
//
//  aurora_8b10b_v5_3
//
//
//  Description: This is the top level module for a 1 4-byte lane Aurora
//               reference design module with streaming interface. 
//


`timescale 1 ns / 1 ps
(* core_generation_info = "aurora_8b10b_v5_3,aurora_8b10b_v5_3,{user_interface=Legacy_LL, backchannel_mode=Sidebands, c_aurora_lanes=1, c_column_used=left, c_gt_clock_1=GTXQ0, c_gt_clock_2=None, c_gt_loc_1=1, c_gt_loc_10=X, c_gt_loc_11=X, c_gt_loc_12=X, c_gt_loc_13=X, c_gt_loc_14=X, c_gt_loc_15=X, c_gt_loc_16=X, c_gt_loc_17=X, c_gt_loc_18=X, c_gt_loc_19=X, c_gt_loc_2=X, c_gt_loc_20=X, c_gt_loc_21=X, c_gt_loc_22=X, c_gt_loc_23=X, c_gt_loc_24=X, c_gt_loc_25=X, c_gt_loc_26=X, c_gt_loc_27=X, c_gt_loc_28=X, c_gt_loc_29=X, c_gt_loc_3=X, c_gt_loc_30=X, c_gt_loc_31=X, c_gt_loc_32=X, c_gt_loc_33=X, c_gt_loc_34=X, c_gt_loc_35=X, c_gt_loc_36=X, c_gt_loc_37=X, c_gt_loc_38=X, c_gt_loc_39=X, c_gt_loc_4=X, c_gt_loc_40=X, c_gt_loc_41=X, c_gt_loc_42=X, c_gt_loc_43=X, c_gt_loc_44=X, c_gt_loc_45=X, c_gt_loc_46=X, c_gt_loc_47=X, c_gt_loc_48=X, c_gt_loc_5=X, c_gt_loc_6=X, c_gt_loc_7=X, c_gt_loc_8=X, c_gt_loc_9=X, c_lane_width=4, c_line_rate=4.0, c_nfc=false, c_nfc_mode=IMM, c_refclk_frequency=125.0, c_simplex=false, c_simplex_mode=TX, c_stream=true, c_ufc=false, flow_mode=None, interface_mode=Streaming, dataflow_config=Duplex}" *)
module aurora_8b10b_v5_3 #
(
     parameter   SIM_GTXRESET_SPEEDUP=   0,      // Set to 1 to speed up sim reset
     parameter   RX_CLK25_DIVIDER           = 5,
     parameter   RXPLL_DIVSEL45_FB          = 5,
     parameter   TX_CLK25_DIVIDER           = 5,
     parameter   TXPLL_DIVSEL45_FB          = 5
)
(
    // TX Stream Interface
    TX_D,
    TX_SRC_RDY_N,
    TX_DST_RDY_N,

    // RX Stream Interface
    RX_D,
    RX_SRC_RDY_N,

    //Clock Correction Interface
    DO_CC,
    WARN_CC,

    //GTX Serial I/O
    RXP,
    RXN,
    TXP,
    TXN,

    //GTX Reference Clock Interface
    GTXQ0,

    //Error Detection Interface
    HARD_ERR,
    SOFT_ERR,

    //Status
    CHANNEL_UP,
    LANE_UP,
 
    //System Interface
    USER_CLK,
    SYNC_CLK,
    RESET,
    POWER_DOWN,
    LOOPBACK,
    GT_RESET,
    TX_OUT_CLK,
    RXEQMIX_IN,
    DADDR_IN,
    DCLK_IN,
    DEN_IN,
    DI_IN,
    DRDY_OUT,
    DRPDO_OUT,
    DWE_IN,
    TX_LOCK
);


`define DLY #1
    
//***********************************Port Declarations*******************************
    // TX Stream Interface
    input   [0:31]     TX_D;
    input              TX_SRC_RDY_N;
    output             TX_DST_RDY_N;

    // RX Stream Interface
    output  [0:31]     RX_D;
    output             RX_SRC_RDY_N;

    // Clock Correction Interface
    input              DO_CC;
    input              WARN_CC;
    
    //GTX Serial I/O
    input              RXP;
    input              RXN;
    output             TXP;
    output             TXN;

    //GTX Reference Clock Interface
    input              GTXQ0;

    //Error Detection Interface
    output             HARD_ERR;
    output             SOFT_ERR;

    //Status
    output             CHANNEL_UP;
    output             LANE_UP;

    //System Interface
    input              USER_CLK;
    input              SYNC_CLK;
    input              RESET;
    input              POWER_DOWN;
    input   [2:0]      LOOPBACK;
    input              GT_RESET;
    output             TX_OUT_CLK;
    input    [2:0]     RXEQMIX_IN;
//----------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------ 
    input   [7:0]     DADDR_IN;  
    input             DCLK_IN;  
    input             DEN_IN;  
    input   [15:0]    DI_IN;  
    output            DRDY_OUT;  
    output  [15:0]    DRPDO_OUT;  
    input             DWE_IN;  
    output             TX_LOCK;

//*********************************Wire Declarations**********************************

    wire               TX1N_OUT_unused;
    wire               TX1P_OUT_unused;
    wire               RX1N_IN_unused;
    wire               RX1P_IN_unused;
    wire               rx_buf_err_i_unused;
    wire    [3:0]      rx_char_is_comma_i_unused;
    wire    [3:0]      rx_char_is_k_i_unused;
    wire    [31:0]     rx_data_i_unused;
    wire    [3:0]      rx_disp_err_i_unused;
    wire    [3:0]      rx_not_in_table_i_unused;
    wire               rx_realign_i_unused;
    wire               tx_buf_err_i_unused;
    wire               ch_bond_done_i_unused;

    wire               ch_bond_done_i;
    reg                ch_bond_done_r1;
    reg                ch_bond_done_r2;
    wire    [4:0]      rx_status_float_i;    
    wire               channel_up_i;
    wire               en_chan_sync_i;
    wire               ena_comma_align_i;
    wire               gen_a_i;
    wire               gen_cc_i;
    wire               gen_ecp_i;
    wire    [0:1]      gen_ecp_striped_i;
    wire    [0:3]      gen_k_i;
    wire    [0:1]      gen_pad_i;
    wire    [0:1]      gen_pad_striped_i;
    wire    [0:3]      gen_r_i;
    wire               gen_scp_i;
    wire    [0:1]      gen_scp_striped_i;
    wire    [0:3]      gen_v_i;
    wire    [0:3]      got_a_i;
    wire               got_v_i;
    wire               hard_err_i;
    wire               lane_up_i;
    wire               pma_rx_lock_i;
    wire               raw_tx_out_clk_i;
    wire               reset_lanes_i;
    wire               rx_buf_err_i;
    wire    [3:0]      rx_char_is_comma_i;
    wire    [3:0]      rx_char_is_k_i;
    wire    [2:0]      rx_clk_cor_cnt_i;
    wire    [31:0]     rx_data_i;
    wire    [3:0]      rx_disp_err_i;
    wire    [0:1]      rx_ecp_i;
    wire    [0:1]      rx_ecp_striped_i;
    wire    [3:0]      rx_not_in_table_i;
    wire    [0:1]      rx_pad_i;
    wire    [0:1]      rx_pad_striped_i;
    wire    [0:31]     rx_pe_data_i;
    wire    [0:31]     rx_pe_data_striped_i;
    wire    [0:1]      rx_pe_data_v_i;
    wire    [0:1]      rx_pe_data_v_striped_i;
    wire               rx_polarity_i;
    wire               rx_realign_i;
    wire               rx_reset_i;
    wire    [0:1]      rx_scp_i;
    wire    [0:1]      rx_scp_striped_i;
    wire    [0:1]      soft_err_i;
    wire               all_soft_err_i;
    wire               start_rx_i;
    wire               tied_to_ground_i;
    wire    [31:0]     tied_to_ground_vec_i;
    wire               tied_to_vcc_i;
    wire               tx_buf_err_i;
    wire    [3:0]      tx_char_is_k_i;
    wire    [31:0]     tx_data_i;
    wire               tx_lock_i;
    wire               tx_out_clk_i;
    wire    [0:31]     tx_pe_data_i;
    wire    [0:31]     tx_pe_data_striped_i;
    wire    [0:1]      tx_pe_data_v_i;
    wire    [0:1]      tx_pe_data_v_striped_i;
    wire               tx_reset_i;

    wire    [1:0]      link_reset_lane0_i;
    wire    [1:0]      link_reset_i;

//*********************************Main Body of Code**********************************



    //Tie off top level constants
    assign          tied_to_ground_vec_i    = 32'd0;
    assign          tied_to_ground_i        = 1'b0;
    assign          tied_to_vcc_i           = 1'b1;

    assign          all_soft_err_i        = soft_err_i[0] | soft_err_i[1];
    assign  link_reset_i[0]   = link_reset_lane0_i[0];
    assign  link_reset_i[1]   = link_reset_lane0_i[1];
    
    //Connect top level logic
    assign          CHANNEL_UP  =   channel_up_i;

    //Connect the TXOUTCLK of lane 0 to TX_OUT_CLK
    assign  TX_OUT_CLK  =   raw_tx_out_clk_i;
    
    assign  TX_LOCK          = &tx_lock_i;

    //_________________________Instantiate Lane 0______________________________




    assign          LANE_UP =   lane_up_i;

    //Aurora lane striping rules require each 4-byte lane to carry 2 bytes from the first 
    //half of the overall word, and 2 bytes from the second half. This ensures that the 
    //data will be ordered correctly if it is send to a 2-byte lane. Here we perform the 
    //required concatenation
    
    assign  gen_scp_striped_i       =   {gen_scp_i,1'b0};
    assign  gen_ecp_striped_i       =   {1'b0,gen_ecp_i};
    assign  gen_pad_striped_i[0:1]  =  {gen_pad_i[0],gen_pad_i[1]};
    assign  tx_pe_data_striped_i[0:31]   =   {tx_pe_data_i[0:15],tx_pe_data_i[16:31]};
    assign  tx_pe_data_v_striped_i[0:1]  =   {tx_pe_data_v_i[0],tx_pe_data_v_i[1]};
    assign  {rx_pad_i[0],rx_pad_i[1]}    =   rx_pad_striped_i[0:1];
    assign  {rx_pe_data_i[0:15],rx_pe_data_i[16:31]}   =   rx_pe_data_striped_i[0:31];
    assign  {rx_pe_data_v_i[0],rx_pe_data_v_i[1]}  = rx_pe_data_v_striped_i[0:1];
    assign  {rx_scp_i[0],rx_scp_i[1]}  =   rx_scp_striped_i[0:1];
    assign  {rx_ecp_i[0],rx_ecp_i[1]}  =   rx_ecp_striped_i[0:1];
    
    
    



    aurora_8b10b_v5_3_AURORA_LANE_4BYTE aurora_8b10b_v5_3_aurora_lane_4byte_0_i
    (
        //GTX Interface
        .RX_DATA(rx_data_i[31:0]),
        .RX_NOT_IN_TABLE(rx_not_in_table_i[3:0]),
        .RX_DISP_ERR(rx_disp_err_i[3:0]),
        .RX_CHAR_IS_K(rx_char_is_k_i[3:0]),
        .RX_CHAR_IS_COMMA(rx_char_is_comma_i[3:0]),
        .RX_STATUS(tied_to_ground_vec_i[5:0]),
        .TX_BUF_ERR(tx_buf_err_i),
        .RX_BUF_ERR(rx_buf_err_i),
        .RX_REALIGN(rx_realign_i),
        .RX_POLARITY(rx_polarity_i),
        .RX_RESET(rx_reset_i),
        .TX_CHAR_IS_K(tx_char_is_k_i[3:0]),
        .TX_DATA(tx_data_i[31:0]),
        .TX_RESET(tx_reset_i),
        .LINK_RESET_OUT(link_reset_lane0_i),
        
        //Comma Detect Phase Align Interface
        .ENA_COMMA_ALIGN(ena_comma_align_i),


        //TX_LL Interface
        .GEN_SCP(gen_scp_striped_i),
        .GEN_ECP(gen_ecp_striped_i),
        .GEN_PAD(gen_pad_striped_i[0:1]),
        .TX_PE_DATA(tx_pe_data_striped_i[0:31]),
        .TX_PE_DATA_V(tx_pe_data_v_striped_i[0:1]),
        .GEN_CC(gen_cc_i),


        //RX_LL Interface
        .RX_PAD(rx_pad_striped_i[0:1]),
        .RX_PE_DATA(rx_pe_data_striped_i[0:31]),
        .RX_PE_DATA_V(rx_pe_data_v_striped_i[0:1]),
        .RX_SCP(rx_scp_striped_i[0:1]),
        .RX_ECP(rx_ecp_striped_i[0:1]),


        //Global Logic Interface
        .GEN_A(gen_a_i),
        .GEN_K(gen_k_i[0:3]),
        .GEN_R(gen_r_i[0:3]),
        .GEN_V(gen_v_i[0:3]),
        .LANE_UP(lane_up_i),
        .SOFT_ERR(soft_err_i[0:1]),
        .HARD_ERR(hard_err_i),
        .CHANNEL_BOND_LOAD(),
        .GOT_A(got_a_i[0:3]),
        .GOT_V(got_v_i),


        //System Interface
        .USER_CLK(USER_CLK),
        .RESET_SYMGEN(RESET),
        .RESET(reset_lanes_i)
    );


    
    
    

    //_________________________Instantiate GTX Wrapper ______________________________

 
    aurora_8b10b_v5_3_GTX_WRAPPER #
    (
             .SIM_GTXRESET_SPEEDUP(SIM_GTXRESET_SPEEDUP),
             .RX_CLK25_DIVIDER(RX_CLK25_DIVIDER),
             .RXPLL_DIVSEL45_FB(RXPLL_DIVSEL45_FB),
             .TX_CLK25_DIVIDER(TX_CLK25_DIVIDER),
             .TXPLL_DIVSEL45_FB(TXPLL_DIVSEL45_FB)
    )

    gtx_wrapper_i

    (
   
        //Aurora Lane Interface
        .RXPOLARITY_IN(rx_polarity_i),
        .RXRESET_IN(rx_reset_i),
        .TXCHARISK_IN(tx_char_is_k_i[3:0]),
        .TXDATA_IN(tx_data_i[31:0]),
        .TXRESET_IN(tx_reset_i),
        .RXDATA_OUT(rx_data_i[31:0]),
        .RXNOTINTABLE_OUT(rx_not_in_table_i[3:0]),
        .RXDISPERR_OUT(rx_disp_err_i[3:0]),
        .RXCHARISK_OUT(rx_char_is_k_i[3:0]),
        .RXCHARISCOMMA_OUT(rx_char_is_comma_i[3:0]),
        .RXREALIGN_OUT(rx_realign_i),
        .RXBUFERR_OUT(rx_buf_err_i),
        .TXBUFERR_OUT(tx_buf_err_i),

        // reset for hot plug
        .LINK_RESET_IN(link_reset_i),

      // Phase Align Interface
        .ENMCOMMAALIGN_IN(ena_comma_align_i),
        .ENPCOMMAALIGN_IN(ena_comma_align_i),
        .RXRECCLK1_OUT(),
        .RXRECCLK2_OUT(),
           
        //Global Logic Interface
        .ENCHANSYNC_IN(en_chan_sync_i),
        .CHBONDDONE_OUT(ch_bond_done_i),

        //Serial IO
        .RXEQMIX_IN(RXEQMIX_IN),
        .DADDR_IN  (DADDR_IN),
        .DCLK_IN   (DCLK_IN),
        .DEN_IN    (DEN_IN),
        .DI_IN     (DI_IN),
        .DRDY_OUT  (DRDY_OUT),
        .DRPDO_OUT (DRPDO_OUT),
        .DWE_IN    (DWE_IN),
        .RX1N_IN(RXN),
        .RX1P_IN(RXP),
        .TX1N_OUT(TXN),
        .TX1P_OUT(TXP),

        // Clocks and Clock Status
        .RXUSRCLK_IN(SYNC_CLK),
        .RXUSRCLK2_IN(USER_CLK),
        .TXUSRCLK_IN(SYNC_CLK),
        .TXUSRCLK2_IN(USER_CLK), 
        .REFCLK(GTXQ0),

        .TXOUTCLK1_OUT(raw_tx_out_clk_i),
        .TXOUTCLK2_OUT(),
        .PLLLKDET_OUT(tx_lock_i),

        //System Interface
        .GTXRESET_IN(GT_RESET),
        .LOOPBACK_IN(LOOPBACK),

        .POWERDOWN_IN(POWER_DOWN)
    );

    //__________Instantiate Global Logic to combine Lanes into a Channel______

    aurora_8b10b_v5_3_GLOBAL_LOGIC    aurora_8b10b_v5_3_global_logic_i
    (
        //GTX Interface
        .CH_BOND_DONE(ch_bond_done_i),
        .EN_CHAN_SYNC(en_chan_sync_i),


        //Aurora Lane Interface
        .LANE_UP(lane_up_i),
        .SOFT_ERR(soft_err_i),
        .HARD_ERR(hard_err_i),
        .CHANNEL_BOND_LOAD(ch_bond_done_i),
        .GOT_A(got_a_i),
        .GOT_V(got_v_i),
        .GEN_A(gen_a_i),
        .GEN_K(gen_k_i),
        .GEN_R(gen_r_i),
        .GEN_V(gen_v_i),
        .RESET_LANES(reset_lanes_i),


        //System Interface
        .USER_CLK(USER_CLK),
        .RESET(RESET),
        .POWER_DOWN(POWER_DOWN),
        .CHANNEL_UP(channel_up_i),
        .START_RX(start_rx_i),
        .CHANNEL_SOFT_ERR(SOFT_ERR),
        .CHANNEL_HARD_ERR(HARD_ERR)
    );



    //_____________________________Instantiate TX_STREAM___________________________

    
    aurora_8b10b_v5_3_TX_STREAM aurora_8b10b_v5_3_tx_stream_i
    (
        // Data interface
        .TX_D(TX_D),
        .TX_SRC_RDY_N(TX_SRC_RDY_N),
        .TX_DST_RDY_N(TX_DST_RDY_N),

        // Global Logic Interface
        .CHANNEL_UP(channel_up_i),

        //Clock Correction Interface
        .DO_CC(DO_CC),
        .WARN_CC(WARN_CC),
        
        // Aurora Lane Interface
        .GEN_SCP(gen_scp_i),
        .GEN_ECP(gen_ecp_i),
        .TX_PE_DATA_V(tx_pe_data_v_i),
        .GEN_PAD(gen_pad_i),
        .TX_PE_DATA(tx_pe_data_i),
        .GEN_CC(gen_cc_i),


        // System Interface
        .USER_CLK(USER_CLK)
    );


    //_____________________________ Instantiate RX_STREAM____________________________
    
    
    aurora_8b10b_v5_3_RX_STREAM aurora_8b10b_v5_3_rx_stream_i
    (
        // LocalLink PDU Interface
        .RX_D(RX_D),
        .RX_SRC_RDY_N(RX_SRC_RDY_N),
    
        // Global Logic Interface
        .START_RX(start_rx_i),
    
        // Aurora Lane Interface
        .RX_PAD(rx_pad_i),
        .RX_PE_DATA(rx_pe_data_i),
        .RX_PE_DATA_V(rx_pe_data_v_i),
        .RX_SCP(rx_scp_i),
        .RX_ECP(rx_ecp_i),
   
        // System Interface
        .USER_CLK(USER_CLK)
    );

endmodule
