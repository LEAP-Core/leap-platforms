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

(* keep_hierarchy="true" *)
module aurora_8b10b_v5_3_example_design #
(
     parameter   USE_CHIPSCOPE        = 0,
     parameter   SIM_GTXRESET_SPEEDUP = 1      
)
(

// wjun ///////////////////////////////
    RX_DATA_IN,
    rx_en,
    rx_rdy,

    TX_DATA_OUT,
    tx_en,
    tx_rdy,
    RESET_N,

    UNDERFLOW,
    FLITCOUNT,
    RXCREDIT,
    TXCREDIT,
    // User IO
//    RESET,
/////////////////////////////////////////
    cc_do_i,
    HARD_ERR,
    SOFT_ERR,
    LANE_UP,
    CHANNEL_UP,
        RX_COUNT,
    TX_COUNT,
    ERROR_COUNT,

// wjun ///////////////////////////////

    INIT_CLK,

/////////////////////////////////////////

    GTX_CLK,
    // GT I/O
    RXP,
    RXN,
    TXP,
    TXN,
		
// wjun ///////////////////////////////
    USER_CLK,
    USER_RST,
    USER_RST_N
/////////////////////////////////////////
);


    output [15:0] RX_DATA_IN;
    input rx_en;
    output rx_rdy;

    input [15:0] TX_DATA_OUT;
    input tx_en;
    output tx_rdy;
//***********************************Port Declarations*******************************
    // User I/O
//    input              RESET;
//    input              INIT_CLK_P;
//    input              INIT_CLK_N;
//    input              GT_RESET_IN;

    input INIT_CLK;
    input RESET_N;
    input UNDERFLOW;
    input [1:0] FLITCOUNT;
    input [7:0] RXCREDIT;
    input [7:0] TXCREDIT;   
		// wjun 

    // Other control signals
    output cc_do_i;
   
   
    output             HARD_ERR;
    output             SOFT_ERR;
//    output  [0:7]      ERR_COUNT; // wjun
    output             LANE_UP;
    output             CHANNEL_UP;
    output [31:0]       RX_COUNT;
   
    output [31:0] 	TX_COUNT;
   
    output [31:0] 	ERROR_COUNT;
   
    // Clocks
    input              GTX_CLK;

    // GT Serial I/O
    input              RXP;
    input              RXN;
    output             TXP;
    output             TXN;

    // wjun
    output             USER_CLK;
    output             USER_RST_N;
    output             USER_RST;
    wire               RESET;
    wire               GT_RESET_IN;

//**************************External Register Declarations****************************
    reg                HARD_ERR;
    reg                SOFT_ERR;
    reg     [0:7]      ERR_COUNT;    
    reg                LANE_UP;
    reg                CHANNEL_UP;
    reg     [31:0]     RX_COUNT;
    reg     [31:0]     TX_COUNT;
    reg     [31:0]     ERROR_COUNT;
//********************************Wire Declarations**********************************
    // Stream TX Interface
    wire    [0:15]     tx_d_i;
    wire               tx_src_rdy_n_i;
    wire               tx_dst_rdy_n_i;
    // Stream RX Interface
    wire    [0:15]     rx_d_i;
    wire               rx_src_rdy_n_i;
    // V5 Reference Clock Interface
    wire               GTXQ0_left_i;

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
    wire               tx_lock_i;
    wire    [2:0]     rxeqmix_in_i;
    wire    [7:0]     daddr_in_i;
    wire              dclk_in_i;
    wire              den_in_i;
    wire    [15:0]    di_in_i;
    wire              drdy_out_unused_i;
    wire    [15:0]    drpdo_out_unused_i;
    wire              dwe_in_i;

    wire               tx_out_clk_i;

    wire               gt_reset_i; 
    wire               system_reset_i;
    //Frame check signals
    wire    [0:7]      err_count_i;

    wire [35:0] icon_to_vio_i;
    wire [63:0] sync_in_i;
    wire [15:0] sync_out_i;

    wire        lane_up_i_i;
    wire        tx_lock_i_i;
    wire        lane_up_reduce_i;
    wire        rst_cc_module_i;

    wire    [0:15]     tied_to_gnd_vec_i;

//*********************************Main Body of Code**********************************
    assign GTXQ0_left_i = GTX_CLK; 
    assign cc_do_i = do_cc_i;
	// wjun
    assign RESET = RESET_N;
    assign GT_RESET_IN = ~RESET_N;
    assign USER_CLK = user_clk_i;
    assign USER_RST_N = (!system_reset_i);//system_reset_i;
    assign USER_RST = (!system_reset_i);//system_reset_i;

    assign lane_up_reduce_i  = &lane_up_i;
    assign rst_cc_module_i   = !lane_up_reduce_i;


    // Instantiate a clock module for clock division.
    aurora_8b10b_v5_3_CLOCK_MODULE clock_module_i
    (
        .GT_CLK(tx_out_clk_i),
        .GT_CLK_LOCKED(tx_lock_i),
        .USER_CLK(user_clk_i),
        .SYNC_CLK(sync_clk_i),
        .PLL_NOT_LOCKED(pll_not_locked_i)
    );

//____________________________Register User I/O___________________________________
// Register User Outputs from core.

    always @(posedge user_clk_i)
    begin
        HARD_ERR      <=  hard_err_i;
        SOFT_ERR      <=  soft_err_i;
        ERR_COUNT       <=  err_count_i;
        LANE_UP         <=  lane_up_i;
        CHANNEL_UP      <=  channel_up_i;
    end

    reg  [31:0] rx_count_next;
    reg  [31:0] tx_count_next;
    reg  [31:0] error_count_next;



//____________________________Tie off unused signals_______________________________

    // System Interface
    assign  tied_to_gnd_vec_i   =   16'd0;
    assign  power_down_i        =   1'b0;
    assign  loopback_i          =   3'b000;

//____________________________GT Ports_______________________________

    assign  rxeqmix_in_i  =  3'b111;
    assign  daddr_in_i  =  8'h0;
    assign  dclk_in_i   =  1'b0;
    assign  den_in_i    =  1'b0;
    assign  di_in_i     =  16'h0;
    assign  dwe_in_i    =  1'b0;
//___________________________Module Instantiations_________________________________
    (*keep_hierarchy="true"*)
    aurora_8b10b_v5_3 #
    (
        .SIM_GTXRESET_SPEEDUP(SIM_GTXRESET_SPEEDUP)
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
        .GTXQ0(GTXQ0_left_i),
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
        .RXEQMIX_IN(rxeqmix_in_i),
        .DADDR_IN  (daddr_in_i),
        .DCLK_IN   (dclk_in_i),
        .DEN_IN    (den_in_i),
        .DI_IN     (di_in_i),
        .DRDY_OUT  (drdy_out_unused_i),
        .DRPDO_OUT (drpdo_out_unused_i),
        .DWE_IN    (dwe_in_i),
        .TX_OUT_CLK(tx_out_clk_i)
    );

    aurora_8b10b_v5_3_STANDARD_CC_MODULE standard_cc_module_i
    (
        .RESET(rst_cc_module_i),
        // Clock Compensation Control Interface
        .WARN_CC(warn_cc_i),
        .DO_CC(do_cc_i),
        // System Interface
        .PLL_NOT_LOCKED(pll_not_locked_i),
        .USER_CLK(user_clk_i)
    );

    aurora_8b10b_v5_3_RESET_LOGIC reset_logic_i
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

    reg [15:0] RX_DATA_IN_delay;
    reg        rx_rdy_delay;



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

    // Pipeline rx_rdy to improve pipeline performance
    // we get away without having defaults due to the high
    // level properties of the driver (it waits for man do_CC before data may be received)
    always@(posedge user_clk_i)
    begin
        rx_rdy_delay <= rx_data_valid_c && !rx_reset_c;
        RX_DATA_IN_delay <= rx_d_i;
    end
   
/*
    //Connect a frame generator to the TX User interface
    aurora_8b10b_v5_3_FRAME_GEN frame_gen_i
    (
        // User Interface
        .TX_D(tx_d_i),  
        .TX_SRC_RDY_N(tx_src_rdy_n_i),
        .TX_DST_RDY_N(tx_dst_rdy_n_i),


        // System Interface
        .USER_CLK(user_clk_i),       
        .RESET(reset_i),
        .CHANNEL_UP(channel_up_i)
    );

    aurora_8b10b_v5_3_FRAME_CHECK frame_check_i
    (
        // User Interface
        .RX_D(rx_d_i),  
        .RX_SRC_RDY_N(rx_src_rdy_n_i),
 
        // System Interface
        .USER_CLK(user_clk_i),       
        .RESET(reset_i),
        .CHANNEL_UP(channel_up_i),
        .ERR_COUNT(err_count_i)
    );    
*/


generate
if (USE_CHIPSCOPE==1)
begin : chipscope1


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
            if(tx_en && !tx_rdy) 
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

   
   
reg [63:0] sync_reg;

always@(posedge user_clk_i)
begin
   sync_reg <= sync_in_i;
end   
   
assign lane_up_i_i = &lane_up_i;
assign tx_lock_i_i = tx_lock_i;

    // Shared VIO Inputs
        assign  sync_in_i[15:0]         =  tx_d_i;
        assign  sync_in_i[31:16]        =  rx_d_i;
        assign  sync_in_i[34]           =  FLITCOUNT[0];  
        assign  sync_in_i[35]           =  FLITCOUNT[1];  
        assign  sync_in_i[36]           =  UNDERFLOW;  
        assign  sync_in_i[37]           =  rx_rdy;
        assign  sync_in_i[38]           =  warn_cc_i;
        assign  sync_in_i[39]           =  do_cc_i;
        assign  sync_in_i[40]           =  soft_err_i;
        assign  sync_in_i[41]           =  hard_err_i;
        assign  sync_in_i[42]           =  tx_lock_i_i;
        assign  sync_in_i[43]           =  pll_not_locked_i;
        assign  sync_in_i[44]           =  channel_up_i;
        assign  sync_in_i[45]           =  lane_up_i_i;
        assign  sync_in_i[46]           =  tx_en;
        assign  sync_in_i[47]           =  tx_rdy;
        assign  sync_in_i[55:48]        =  RXCREDIT;
        assign  sync_in_i[63:56]        =  TXCREDIT;
   
   
   v6_ila ILA_inst
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
  v6_icon i_icon
  
    (
      .CONTROL0(icon_to_vio_i)
    );
  
                                                                                                                                                                       
end //end USE_CHIPSCOPE=1 generate section
else
begin : no_chipscope1
                                                                                                                                                                       
    // Shared VIO Inputs
        assign  sync_in_i         =  64'h0;

end

 if (USE_CHIPSCOPE==1)
 begin : chipscope2
     // Shared VIO Outputs
 assign  reset_i =   system_reset_i | sync_out_i[0];
 end //end USE_CHIPSCOPE=1 block
 else
 begin: no_chipscope2
     assign  reset_i =   system_reset_i;
 end //end USE_CHIPSCOPE=0 block
 
endgenerate //End generate for USE_CHIPSCOPE

endmodule
