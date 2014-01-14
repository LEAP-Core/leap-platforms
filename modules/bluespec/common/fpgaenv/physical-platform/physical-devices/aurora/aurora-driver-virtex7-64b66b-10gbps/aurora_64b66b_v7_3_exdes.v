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
//  EXAMPLE_DESIGN
//
//
//  Description:  This wrapper instantiates Single lane Aurora Module. 
//                The User Interface is a Data Generator and Checker.   
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 10 ps
(* keep_hierarchy="true" *)
module aurora_64b66b_v7_3_exdes  #
(
     parameter   WIDTH                = 128,
     parameter   USE_CHIPSCOPE        = 0,
     parameter   SIM_GTXRESET_SPEEDUP=   "TRUE"      // Set to 1 to speed up sim reset
     
     
)
(
    RX_DATA_IN,
    rx_en,
    rx_rdy,

    TX_DATA_OUT,
    tx_en,
    tx_rdy,
    RESET_N,

    cc_do_i,

    HARD_ERR,
    SOFT_ERR,
    ERR_COUNT,

    LANE_UP,
    CHANNEL_UP,


    GTX_CLK,

    INIT_CLK,

    USER_CLK,
    USER_RST,
    USER_RST_N,

    // GT I/O
    RXP,
    RXN,
    TXP,
    TXN,
    // Debug
    RX_COUNT,
    TX_COUNT,
    ERROR_COUNT,
    UNDERFLOW,
    FLITCOUNT,
    RXCREDIT,
    TXCREDIT

);


//***********************************Port Declarations*******************************

    // User I/O

    output [0:127] RX_DATA_IN;
    input rx_en;
    output rx_rdy;

    input [0:127] TX_DATA_OUT;
    input tx_en;
    output tx_rdy;

    input              RESET_N;
    input              INIT_CLK;

    output             HARD_ERR;
    output             SOFT_ERR;
    output  [0:7]      ERR_COUNT;


    output  [0:1]      LANE_UP;
    output             CHANNEL_UP;
    output cc_do_i;
    // Clocks
    input              GTX_CLK;

    output             USER_CLK;
    output             USER_RST_N;
    output             USER_RST;

    // GT Serial I/O
    input   [0:1]      RXP;
    input   [0:1]      RXN;
    output  [0:1]      TXP;
    output  [0:1]      TXN;

    // Debug
    input UNDERFLOW;
    input [1:0] FLITCOUNT;
    input [7:0] RXCREDIT;
    input [7:0] TXCREDIT;   

    output [31:0]       RX_COUNT;   
    output [31:0] 	TX_COUNT;   
    output [31:0] 	ERROR_COUNT;



//************************External Register Declarations*****************************

    //Error reporting signals
    reg                  HARD_ERR;
    reg                  SOFT_ERR;
    reg       [0:7]      DATA_ERR_COUNT;
    reg     [31:0]     RX_COUNT;
    reg     [31:0]     TX_COUNT;
    reg     [31:0]     ERROR_COUNT;

    //Global signals
    reg       [0:1]      LANE_UP;
    reg                  CHANNEL_UP;

//********************************Wire Declarations**********************************
    
    //Dut1
    //TX Interface
    wire      [0:127]    tx_tdata_i;
    wire                 tx_tvalid_i;        
    wire                 tx_tready_i;        

    //RX Interface
    wire      [0:127]     rx_tdata_i; 
    wire                 rx_tvalid_i;        





    //TX Interface
    wire      [0:127]    tx_d_i;
    wire                 tx_src_rdy_n_i;        
    wire                 tx_dst_rdy_n_i;        

    //RX Interface
    wire      [0:127]     rx_d_i; 
    wire                 rx_src_rdy_n_i;        




    //Error Detection Interface
    wire                 hard_err_i;        
    wire                 soft_err_i;        

    //Status
    wire                 channel_up_i;        
    wire      [0:1]      lane_up_i;

    //Clock Compensation Control Interface
    wire                 do_cc_i;        

    //System Interface
    wire                 pll_not_locked_i ;
    wire                 reset_i ;
    wire                 powerdown_i ;
    wire      [2:0]      loopback_i ;
    wire                 pll_lock_i ;
    wire                 tx_out_clk_i ;

    // Error signals from the Local Link packet checker
    wire      [0:7]       data_err_count_o; 

    wire                  init_clk_i;
    wire                  pma_init_i;

 
    //V5 clock
    (* KEEP = "TRUE" *) wire               user_clk_i;
    (* KEEP = "TRUE" *) wire               sync_clk_i;
    (* KEEP = "TRUE" *) wire               shim_clk_i;
    (* KEEP = "TRUE" *) wire               GTXQ0_left_i;
    (* KEEP = "TRUE" *) wire               INIT_CLK_i  /* synthesis syn_keep = 1 */;
    wire    [8:0] drpaddr_in_i;
    wire    [15:0]     drpdi_in_i;
    wire               drp_clk_i;
    wire    [15:0]     drpdo_out_i;
    wire               drprdy_out_i;
    wire               drpen_in_i;
    wire               drpwe_in_i;
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
//*********************************Main Body of Code**********************************

    //_______________________________Clock Buffers_________________________________

    assign GTXQ0_left_i = GTX_CLK; 
    assign cc_do_i = do_cc_i;
    // wjun
    assign RESET = ~RESET_N;
    assign GT_RESET_IN = ~RESET_N;
    assign USER_CLK = user_clk_i;
    assign USER_RST_N = (!system_reset_i);
    assign USER_RST = (!system_reset_i);
   
    // Instantiate a clock module for clock division.
    aurora_64b66b_v7_3_CLOCK_MODULE #
    (
        .SIMULATION_P(SIM_GTXRESET_SPEEDUP)
    )
    clock_module_i
    (
        .CLK(tx_out_clk_i),
        .CLK_LOCKED(pll_lock_i),
        .USER_CLK(user_clk_i),
        .SYNC_CLK(sync_clk_i),
        .SHIM_CLK(shim_clk_i),
        .MMCM_NOT_LOCKED(pll_not_locked_i)
    );


    assign INIT_CLK_i = INIT_CLK;
   
    // Instantiate reset module to generate system reset
    aurora_64b66b_v7_3_RESET_LOGIC reset_logic_i
    (
        .RESET(RESET),
        .USER_CLK(user_clk_i),
        .INIT_CLK(INIT_CLK_i),
        .GT_RESET_IN(PMA_INIT),
        .TX_LOCK_IN(pll_lock_i),
        .PLL_NOT_LOCKED(pll_not_locked_i),
        .LINK_RESET_IN(link_reset_i),

        .SYSTEM_RESET(system_reset_i),
        .INIT_CLK_OUT(drp_clk_i),
        .GT_RESET_OUT(pma_init_i)
    );

    //____________________________Register User I/O___________________________________

    // Register User Outputs from core.
    always @(posedge user_clk_i)
    begin
        HARD_ERR       <=  hard_err_i;
        SOFT_ERR       <=  soft_err_i;
        LANE_UP          <=  lane_up_i;
        CHANNEL_UP       <=  channel_up_i;
        DATA_ERR_COUNT <=  data_err_count_o;
    end

    //____________________________Register User I/O___________________________________

    // System Interface
    assign  power_down_i        =   1'b0;
    assign  loopback_i          =   3'b000;
   // Native DRP Interface
    assign  drpaddr_in_i    =  8'h0;
    assign  drpdi_in_i     =  16'h0;
    assign  drpwe_in_i   =  1'b0;
    assign  drpen_in_i    =  1'b0;
    assign  drpwe_in_lane1_i   =  1'b0;
    assign  drpen_in_lane1_i    =  1'b0;
    assign  qpll_drpaddr_in_i   =  8'h0;
    assign  qpll_drpdi_in_i     =  16'h0;
    assign  qpll_drpen_in_i    =  1'b0;
    assign  qpll_drpwe_in_i    =  1'b0;

    assign  reset_i  =   system_reset_i;

    //___________________________Module Instantiations_________________________________

    aurora_64b66b_v7_3 #
    (
        .SIM_GTXRESET_SPEEDUP(SIM_GTXRESET_SPEEDUP)
    )
    aurora_64b66b_v7_3_block_i
    (
        // Stream TX Interface
        .TX_D(tx_d_i),
        .TX_SRC_RDY_N(tx_src_rdy_n_i),
        .TX_DST_RDY_N(tx_dst_rdy_n_i),
        // Stream RX Interface
        .RX_D(rx_d_i),
        .RX_SRC_RDY_N(rx_src_rdy_n_i),
     
        .DO_CC(do_cc_i),


        // GTX Serial I/O
        .RXP(RXP),
        .RXN(RXN),

        .TXP(TXP),
        .TXN(TXN),


        //GTX Reference Clock Interface
        .GTXQ0(GTXQ0_left_i),
        // Error Detection Interface
        .HARD_ERR(hard_err_i),
        .SOFT_ERR(soft_err_i),

        // Status
        .CHANNEL_UP(channel_up_i),
        .LANE_UP(lane_up_i),

        // System Interface
        .MMCM_NOT_LOCKED(pll_not_locked_i),
        .USER_CLK(user_clk_i),
        .SYNC_CLK(sync_clk_i),
        .SHIM_CLK(shim_clk_i),
        .RESET(reset_i),
        .POWER_DOWN(power_down_i),
        .LOOPBACK(loopback_i),
        .PMA_INIT(pma_init_i),
        .MMCM_LOCK(pll_lock_i),
        .DRP_CLK_IN(drp_clk_i),
   //---------------------- GT DRP Ports ----------------------
        .DRPADDR_IN(drpaddr_in_i),
        .DRPDI_IN(drpdi_in_i),
        .DRPDO_OUT(drpdo_out_i),
        .DRPRDY_OUT(drprdy_out_i),
        .DRPEN_IN(drpen_in_i),
        .DRPWE_IN(drpwe_in_i),
        .DRPDO_OUT_LANE1(drpdo_out_lane1_i),
        .DRPRDY_OUT_LANE1(drprdy_out_lane1_i),
        .DRPEN_IN_LANE1(drpen_in_lane1_i),
        .DRPWE_IN_LANE1(drpwe_in_lane1_i),
        //---------------------- GTXE2 COMMON DRP Ports ----------------------
        .QPLL_DRPADDR_IN(qpll_drpaddr_in_i),
        .QPLL_DRPDI_IN(qpll_drpdi_in_i),
        .QPLL_DRPDO_OUT(qpll_drpdo_out_i),
        .QPLL_DRPRDY_OUT(qpll_drprdy_out_i),
        .QPLL_DRPEN_IN(qpll_drpen_in_i),
        .QPLL_DRPWE_IN(qpll_drpwe_in_i),
     
        .INIT_CLK(INIT_CLK_i),
        .LINK_RESET_OUT(link_reset_i),
        .TX_OUT_CLK(tx_out_clk_i)
    );

   // Standard CC Module
   aurora_64b66b_v7_3_STANDARD_CC_MODULE standard_cc_module_i
   (
      .DO_CC(do_cc_i),
      .USER_CLK(user_clk_i),
      .CHANNEL_UP(channel_up_i) 
   );


    // wjun
    assign tx_d_i = TX_DATA_OUT;
    assign RX_DATA_IN = RX_DATA_IN_delay;
    assign rx_rdy = rx_rdy_delay;
   
    assign tx_src_rdy_n_i = !(tx_en);
    assign tx_rdy = (!tx_dst_rdy_n_i) && (!do_cc_i);
    wire   rx_reset_c;
    wire   rx_data_valid_c;
    assign rx_reset_c = system_reset_i || !channel_up_i;
    assign  rx_data_valid_c    =   !rx_src_rdy_n_i;

    reg [127:0] RX_DATA_IN_delay;
    reg        rx_rdy_delay;

    // Pipeline rx_rdy to improve pipeline performance
    // we get away without having defaults due to the high
    // level properties of the driver (it waits for man do_CC before data may be received)
    always@(posedge user_clk_i)
    begin
        rx_rdy_delay <= rx_data_valid_c && !rx_reset_c;
        RX_DATA_IN_delay <= rx_d_i;
    end

generate
if (USE_CHIPSCOPE==1)
begin : chipscope1
   
reg [63:0] sync_reg;
wire [63:0] sync_in_i;


    reg  [31:0] rx_count_next;
    reg  [31:0] tx_count_next;
    reg  [31:0] error_count_next;

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


always@(posedge user_clk_i)
begin
   sync_reg <= sync_in_i;
end   
   wire               tx_lock_i;   
assign lane_up_i_i = &lane_up_i;
assign tx_lock_i_i = tx_lock_i;
    wire [35:0] icon_to_vio_i;
    // Shared VIO Inputs
        assign  sync_in_i[15:0]         =  tx_d_i[48:63];
        assign  sync_in_i[31:16]        =  rx_d_i[48:63];
        assign  sync_in_i[32]           =  RESET;  
        assign  sync_in_i[33]           =  system_reset_i;  
        assign  sync_in_i[34]           =  FLITCOUNT[0];  
        assign  sync_in_i[35]           =  FLITCOUNT[1];  
        assign  sync_in_i[36]           =  UNDERFLOW;  
        assign  sync_in_i[37]           =  rx_rdy;
        assign  sync_in_i[38]           =  tx_en;
        assign  sync_in_i[39]           =  tx_rdy;
        assign  sync_in_i[40]           =  soft_err_i;
        assign  sync_in_i[41]           =  hard_err_i;
        assign  sync_in_i[42]           =  tx_lock_i_i;
        assign  sync_in_i[43]           =  pll_not_locked_i;
        assign  sync_in_i[44]           =  lane_up_i_i;
        assign  sync_in_i[45]           =  channel_up_i;
        
        assign  sync_in_i[47]           =  do_cc_i;
        assign  sync_in_i[55:48]        =  RXCREDIT;
        assign  sync_in_i[63:56]        =  TXCREDIT;
   
   
   v7_ila ILA_inst
           (
	          .CONTROL(icon_to_vio_i), // INOUT BUS [35:0]
	          .CLK(user_clk_i), // IN
	          .TRIG0(sync_reg[7:0]), // IN BUS [7:0]
	          .TRIG1(sync_reg[15:8]), // IN BUS [7:0]
	          .TRIG2(sync_reg[23:16]), // IN BUS [7:0]
	          .TRIG3(sync_reg[31:24]), // IN BUS [7:0]
	          .TRIG4(sync_reg[39:32]), // IN BUS [7:0]
	          .TRIG5(sync_reg[47:40]),
   	          .TRIG6(sync_reg[55:48]),
   	          .TRIG7(sync_reg[63:56]));

  //-----------------------------------------------------------------
  //  ICON core instance
  //-----------------------------------------------------------------
  v7_icon i_icon
  
    (
      .CONTROL0(icon_to_vio_i)
    );
  
                                                                                                                                                                       
end //end USE_CHIPSCOPE=1 generate section
else
begin : no_chipscope1
                                                                                                                                                                       
    // Shared VIO Inputs
        assign  sync_in_i         =  128'h0;

end

 if (USE_CHIPSCOPE==1)
 begin : chipscope2
     // Shared VIO Outputs
 assign  reset_i =   system_reset_i ;
 end //end USE_CHIPSCOPE=1 block
 else
 begin: no_chipscope2
     assign  reset_i =   system_reset_i;
 end //end USE_CHIPSCOPE=0 block
 
endgenerate //End generate for USE_CHIPSCOPE


endmodule

