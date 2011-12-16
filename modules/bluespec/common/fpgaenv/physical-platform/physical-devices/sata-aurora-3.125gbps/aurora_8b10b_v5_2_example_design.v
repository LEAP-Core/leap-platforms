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
//  AURORA_EXAMPLE
//
//  Aurora Generator
//
//
//  Description: Sample Instantiation of a 1 2-byte lane module.
//               Only tests initialization in hardware.
//
//         
`timescale 1 ns / 1 ps
(* core_generation_info = "aurora_8b10b_v5_2,aurora_8b10b_v5_2,{backchannel_mode=Sidebands, c_aurora_lanes=1, c_column_used=left, c_gt_clock_1=GTPD0, c_gt_clock_2=None, c_gt_loc_1=X, c_gt_loc_10=X, c_gt_loc_11=X, c_gt_loc_12=X, c_gt_loc_13=X, c_gt_loc_14=X, c_gt_loc_15=X, c_gt_loc_16=X, c_gt_loc_17=X, c_gt_loc_18=X, c_gt_loc_19=X, c_gt_loc_2=1, c_gt_loc_20=X, c_gt_loc_21=X, c_gt_loc_22=X, c_gt_loc_23=X, c_gt_loc_24=X, c_gt_loc_25=X, c_gt_loc_26=X, c_gt_loc_27=X, c_gt_loc_28=X, c_gt_loc_29=X, c_gt_loc_3=X, c_gt_loc_30=X, c_gt_loc_31=X, c_gt_loc_32=X, c_gt_loc_33=X, c_gt_loc_34=X, c_gt_loc_35=X, c_gt_loc_36=X, c_gt_loc_37=X, c_gt_loc_38=X, c_gt_loc_39=X, c_gt_loc_4=X, c_gt_loc_40=X, c_gt_loc_41=X, c_gt_loc_42=X, c_gt_loc_43=X, c_gt_loc_44=X, c_gt_loc_45=X, c_gt_loc_46=X, c_gt_loc_47=X, c_gt_loc_48=X, c_gt_loc_5=X, c_gt_loc_6=X, c_gt_loc_7=X, c_gt_loc_8=X, c_gt_loc_9=X, c_lane_width=2, c_line_rate=2.0, c_nfc=false, c_nfc_mode=IMM, c_refclk_frequency=200.0, c_simplex=false, c_simplex_mode=TX, c_stream=true, c_ufc=false, flow_mode=None, interface_mode=Streaming, dataflow_config=Duplex}" *)
module aurora_8b10b_v5_2_example_design #
(
     parameter   USE_CHIPSCOPE        = 0,
     parameter   SIM_GTPRESET_SPEEDUP = 1      // Set to 1 to speed up sim reset
)
(
    // User IO
    RESET_N,
    INIT_CLK,
    HARD_ERR,
    SOFT_ERR,
    STATUS,
    LANE_UP,
    CHANNEL_UP,
    RX_COUNT,
    TX_COUNT,
    ERROR_COUNT,
    //GT_RESET_IN_N, // User reset.  Syspops claim this is uneeded.  We get a reset on reprogram...  Might want to tie to 0...

 
    GTPD0_P,
    GTPD0_N,

    // Comm interface
    tx_d_i,
    tx_en,
    tx_rdy,
 
    // Stream RX Interface
    rx_d_i,
    rx_rdy,
    rx_en, // This is a dummy... We don't have a choice on this one.  It's ready or die.  We might need flow control at some point.  We have it at the high level, but that may not be enough if the clock differentials are big.    
    // FIFO stats

    cc_d_i,

    rx_fifo_count,
    rx_fifo_full_n,
    rx_fifo_empty_n,

    tx_fifo_count,
    tx_fifo_empty_n,
    tx_fifo_full_n,
 
    // Clock/Reset out
    USER_CLK,  // This guy is an output...
    USER_RESET,
 
    // V5 I/O
    RXP,
    RXN,
    TXP,
    TXN,
    RXP_dummy_0,
    RXN_dummy_0,
    TXP_dummy_0,
    TXN_dummy_0,
    RXP_dummy_1,
    RXN_dummy_1,
    TXP_dummy_1,
    TXN_dummy_1,
    RXP_dummy_2,
    RXN_dummy_2,
    TXP_dummy_2,
    TXN_dummy_2
);


//***********************************Port Declarations*******************************
    // User I/O
    input              RESET_N;
    input              INIT_CLK;

    output             HARD_ERR;
    output             SOFT_ERR;
    output  [31:0]     STATUS;
    output             LANE_UP;
    output             CHANNEL_UP;
    output  [31:0]     RX_COUNT;
    output  [31:0]     TX_COUNT;
    output  [31:0]     ERROR_COUNT;
   
    // Clocks
    input              GTPD0_P;
    input              GTPD0_N;


    input    [0:15]    tx_d_i;
    input              tx_en;
    output             tx_rdy;
    // Stream RX Interface
    output   [0:15]     rx_d_i;
    output              rx_rdy;
    input               rx_en; // DUMM  VALUE

    output 		cc_d_i;
   
    // BSC side stats
    input [4:0] 	rx_fifo_count;
   
    input 		rx_fifo_full_n;
    input 		rx_fifo_empty_n;
   

    input [4:0]		tx_fifo_count;
    input 		tx_fifo_empty_n;
    input 		tx_fifo_full_n;

    output             USER_CLK;
    output             USER_RESET;   

    // V5 I/O
    input              RXP;
    input              RXN;
    output             TXP;
    output             TXN;

    // Dummy I/O (sprinkle as needed to satisfy clock routing constraints: AR#33473 
    input              RXP_dummy_0;
    input              RXN_dummy_0;
    output             TXP_dummy_0;
    output             TXN_dummy_0;
    input              RXP_dummy_1;
    input              RXN_dummy_1;
    output             TXP_dummy_1;
    output             TXN_dummy_1;
    input              RXP_dummy_2;
    input              RXN_dummy_2;
    output             TXP_dummy_2;
    output             TXN_dummy_2;
   
//**************************External Register Declarations****************************
    reg                HARD_ERR;
    reg                SOFT_ERR;
    reg     [31:0]     STATUS;    
    reg                LANE_UP;
    reg                CHANNEL_UP;
    reg     [31:0]     RX_COUNT;
    reg     [31:0]     TX_COUNT;
    reg     [31:0]     ERROR_COUNT;
//********************************Wire Declarations**********************************
    // Stream TX Interface

    // V5 Reference Clock Interface
    wire               GTPD0_left_i;

    // Error Detection Interface
    wire               hard_err_i;
    wire               soft_err_i;
    // Status
    wire               channel_up_i;
    wire               lane_up_i;
    // Clock Compensation Control Interface
    wire               warn_cc_i;
    wire               do_cc_i;
    // System Interface
    wire               pll_not_locked_i;
    wire               user_clk_i;
    wire               sync_clk_i;
    wire               reset_i;
    wire               power_down_i;
    wire    [2:0]      loopback_i;
    (* ASYNC_REG = "TRUE" *)
    wire               tx_lock_i;

    wire               tx_out_clk_i;
    wire               buf_tx_out_clk_i;

    wire               gt_reset_i; 
    wire               system_reset_i;
    //Frame check signals
    wire    [0:7]      err_count_i;

    wire [35:0] icon_to_vio_i;
    wire [63:0] sync_in_i;
    wire [15:0] sync_out_i;
    reg  [31:0] rx_count_next;
    reg  [31:0] tx_count_next;
    reg  [31:0] error_count_next;
   
   
    wire        lane_up_i_i;
    wire        tx_lock_i_i;
    wire        lane_up_reduce_i;
    wire 	tx_dst_rdy_n_i;
    wire        tx_src_rdy_n_i;
    wire 	RESET;
    wire 	GT_RESET_IN;
    wire 	rx_src_rdy_n_i;
   
	
//*********************************Main Body of Code**********************************

    assign lane_up_reduce_i  = !(&lane_up_i);

    assign RESET = RESET_N;  // This is active low.
    assign tx_src_rdy_n_i = !(tx_en && channel_up_i && (!system_reset_i));
    assign tx_rdy = (!tx_dst_rdy_n_i) && channel_up_i && (!system_reset_i) && !do_cc_i;
    assign USER_RESET = (!system_reset_i) && RESET;
    assign GT_RESET_IN = !RESET_N; // this one is active high...
    assign USER_CLK = user_clk_i;
    assign rx_rdy = (!rx_src_rdy_n_i) && channel_up_i && (!system_reset_i);
    assign cc_d_i = do_cc_i;
    
//_______________________________Clock Buffers_________________________________
    wire 	GTPD0_left_i_n;
   

    IBUFDS IBUFDS
    (
        .I(GTPD0_P),
        .IB(GTPD0_N),
        .O(GTPD0_left_i)
    );

    BUFG BUFG
    (
        .I(tx_out_clk_i),
        .O(buf_tx_out_clk_i)
    );

    // Instantiate a clock module for clock division.
    aurora_8b10b_v5_2_CLOCK_MODULE clock_module_i
    (
        .GT_CLK(buf_tx_out_clk_i),
        .GT_CLK_LOCKED(tx_lock_i),
        .USER_CLK(user_clk_i),
        .SYNC_CLK(sync_clk_i),
        .PLL_NOT_LOCKED(pll_not_locked_i)
    );

//____________________________Register User I/O___________________________________
// Register User Outputs from core.

    always @(posedge INIT_CLK)
    begin
        HARD_ERR        <=  hard_err_i;
        SOFT_ERR        <=  soft_err_i;
        STATUS       <=  {8'b0,tx_fifo_full_n,tx_fifo_empty_n,1'b0,tx_fifo_count,
                          rx_fifo_full_n,rx_fifo_empty_n,1'b0,rx_fifo_count,
			  // 8 bits here
                          ~rx_src_rdy_n_i,~tx_dst_rdy_n_i,tx_en,rx_rdy,tx_lock_i,tx_rdy,gt_reset_i,USER_RESET};
        LANE_UP         <=  lane_up_i;
        CHANNEL_UP      <=  channel_up_i;
    end

    always @(posedge USER_CLK)
    begin
	rx_count_next = RX_COUNT;
        tx_count_next = TX_COUNT;
        error_count_next = ERROR_COUNT;
 
	if(system_reset_i)
	begin
             rx_count_next = 0;
	     tx_count_next = 0;
             error_count_next = 0;
	end
	else
	begin
            if(soft_err_i) 
            begin
               error_count_next = ERROR_COUNT + 1;	       
            end	
     
            if(tx_en && tx_rdy)
	    begin
                tx_count_next = TX_COUNT + 1; 
	    end
	   
	    if(rx_rdy)
	    begin
                rx_count_next = RX_COUNT + 1; 
	    end
	end // else: !if(system_reset_i)
       
	RX_COUNT <= rx_count_next;
	TX_COUNT <= tx_count_next;
        ERROR_COUNT <= error_count_next;

    end

//____________________________Tie off unused signals_______________________________

    // System Interface
    assign  power_down_i        =   1'b0;
    assign  loopback_i          =   3'b000; //XXXX

//___________________________Module Instantiations_________________________________
    aurora_8b10b_v5_2 #
    (
        .SIM_GTPRESET_SPEEDUP(SIM_GTPRESET_SPEEDUP)
    )
    aurora_module_i
    (
        // Stream TX Interface
        .TX_D(tx_d_i),
        .TX_SRC_RDY_N(tx_src_rdy_n_i),
        .TX_DST_RDY_N(tx_dst_rdy_n_i),
        // Stream RX Interface
        .RX_D(rx_d_i),
        .RX_SRC_RDY_N(rx_src_rdy_n_i),
        // V5 Serial I/O
        .RXP(RXP),
        .RXN(RXN),
        .TXP(TXP),
        .TXN(TXN),
        // V5 Reference Clock Interface
        .GTPD3(GTPD0_left_i),
        // Error Detection Interface
        .HARD_ERR(hard_err_i),
        .SOFT_ERR(soft_err_i),
        // Status
        .CHANNEL_UP(channel_up_i),
        .LANE_UP(lane_up_i),
        // Clock Compensation Control Interface
        .WARN_CC(warn_cc_i),
        .DO_CC(do_cc_i),
        // System Interface
        .USER_CLK(user_clk_i),
        .SYNC_CLK(sync_clk_i),
        .RESET(reset_i),
        .POWER_DOWN(power_down_i),
        .LOOPBACK(loopback_i),
        .GT_RESET(gt_reset_i),
        .TX_LOCK(tx_lock_i),
        .TX_OUT_CLK(tx_out_clk_i)
    );

    aurora_8b10b_v5_2_STANDARD_CC_MODULE standard_cc_module_i
    (
        .RESET(lane_up_reduce_i),
        // Clock Compensation Control Interface
        .WARN_CC(warn_cc_i),
        .DO_CC(do_cc_i),
        // System Interface
        .PLL_NOT_LOCKED(pll_not_locked_i),
        .USER_CLK(user_clk_i)
    );

    aurora_8b10b_v5_2_RESET_LOGIC reset_logic_i
    (
        .RESET(RESET),
        .USER_CLK(user_clk_i),
        .INIT_CLK(INIT_CLK),
        .GT_RESET_IN(GT_RESET_IN),
        .TX_LOCK_IN(tx_lock_i),
        .PLL_NOT_LOCKED(pll_not_locked_i),

        .SYSTEM_RESET(system_reset_i),
        .GT_RESET_OUT(gt_reset_i)
    );

    assign  sync_in_i         =  64'h0;
    assign  reset_i =   system_reset_i;


    // We need these guys to feed the clock to the SMA link
    dummy_gtp gtp_GTP_DUAL_X0Y5
    (
        .RXN0_IN(RXN_dummy_0),
	.RXN1_IN(),
	.RXP0_IN(RXP_dummy_0),
	.RXP1_IN(),
	.CLKIN_IN(GTPD0_left_i),
	.TXN0_OUT(TXN_dummy_0),
	.TXN1_OUT(),
	.TXP0_OUT(TXP_dummy_0),
	.TXP1_OUT()
   );

   dummy_gtp gtp_GTP_DUAL_X0Y6
   (
	.RXN0_IN(RXN_dummy_1),
	.RXN1_IN(),
	.RXP0_IN(RXP_dummy_1),
	.RXP1_IN(),
	.CLKIN_IN(GTPD0_left_i),
	.TXN0_OUT(TXN_dummy_1),
	.TXN1_OUT(),
	.TXP0_OUT(TXP_dummy_1),
	.TXP1_OUT()
   );

   dummy_gtp gtp_GTP_DUAL_X0Y7
   (
	.RXN0_IN(RXN_dummy_2),
	.RXN1_IN(),
	.RXP0_IN(RXP_dummy_2),
	.RXP1_IN(),
	.CLKIN_IN(GTPD0_left_i),
	.TXN0_OUT(TXN_dummy_2),
	.TXN1_OUT(),
	.TXP0_OUT(TXP_dummy_2),
	.TXP1_OUT()
    );

endmodule

