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


// LEAP Modificiation:
//
// This module was ported from the VC707/Aurora7.3 code.  There were a couple of differences. 
// 1) Many of the reset/clocking modules are instantiated one level below this code. 
// 2) The core introduced AXI streaming, which is a little different than the protocol  
//    that was used before.  The control logic was actually simplified, since the 
//    AXI protocol is quite close to what bluespec expected. 
// 3) Several of the top-level wires are unused, which bothers me a little. Chiefly, pma_init 
//    needs to be examined. According to the manual, pma_init should be used to reset the 
//    GTH, as part of some vaguely complex initialization protocol. I think the main value 
//    has to do with hot plug, so I have ignored pma for now.  PMA wasn't handled in the 
//    previous driver set either. 


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

    // Dummy signals 
    rx_n_en,
    rx_p_en,
 
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

    // Dummy Bluespec Signals
    input rx_p_en;
    input rx_n_en;

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
    wire      [0:127]    s_axi_tx_tdata_i;
    wire                 s_axi_tx_tvalid_i;        
    wire                 s_axi_tx_tready_i;        

    //RX Interface
    wire      [0:127]    m_axi_rx_tdata_i; 
    wire                 m_axi_rx_tvalid_i;        



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
    (* DONT_TOUCH = "TRUE" *) wire               user_clk_i;
    (* DONT_TOUCH = "TRUE" *) wire               sync_clk_i;
    (* DONT_TOUCH = "TRUE" *) wire               shim_clk_i;
    (* DONT_TOUCH = "TRUE" *) wire               GTXQ0_left_i;
    (* DONT_TOUCH = "TRUE" *) wire               INIT_CLK_i  /* synthesis syn_keep = 1 */;
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

    assign RESET = ~RESET_N;
    assign GT_RESET_IN = ~RESET_N;
    assign USER_CLK = user_clk_i;
    assign USER_RST_N = (!system_reset_i);
    assign USER_RST = (!system_reset_i);
   
    assign INIT_CLK_i = INIT_CLK;
   

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

  aurora_64b66b_1_support   aurora_64b66b_v9_3_block_i
  (
     .s_axi_tx_tdata(s_axi_tx_tdata), 
     // this new protocol is different.  old one will not work.
     .s_axi_tx_tvalid(s_axi_tx_tvalid),
     .s_axi_tx_tready(s_axi_tx_tready), 
     .do_cc(do_cc_i), 
     .m_axi_rx_tdata(m_axi_rx_tdata), 
     .m_axi_rx_tvalid(m_axi_rx_tvalid), 

     .rxp(RXP), 
     .rxn(RXN), 
 
     .txp(TXP), 
     .txn(TXN),

     // Error Detection Interface
     .hard_err(hard_err_i), 
     .soft_err(soft_err_i), 
 
     // Status
     .channel_up(channel_up_i), 
     .lane_up(lane_up_i),
     // System Interface
     .init_clk_out(), 
     .user_clk_out(user_clk_i), 
     .sync_clk_out(sync_clk_i), 
     .reset(reset_i), 
     .reset_pb(reset_i), // need to handle this? 
     .gt_rxcdrovrden_in(1'b0), // undocumented. 
     .power_down(power_down_i), 
     .loopback(loopback_i),
     .pma_init(1'b0),  // TODO: Documentation suggests a complex reset dance is needed here.  
     .drp_clk_in(drp_clk_in),

     .drpdo_out(drpdo_out_i), 
     .drprdy_out(drprdy_out_i), 
     .drpdo_out_lane1(drpdo_out_lane1_i), 
     .drprdy_out_lane1(drprdy_out_lane1_i), 
 
    //---------------------- GT DRP Ports ----------------------
     .drpaddr_in(drpaddr_in_i),
     .drpdi_in(drpdi_in_i),
     .drpen_in(drpen_in_i), 
     .drpwe_in(drpwe_in_i), 
     .drpen_in_lane1(drpen_in_lane1_i), 
     .drpwe_in_lane1(drpwe_in_lane1_i), 
    //---------------------- GTXE2 COMMON DRP Ports ----------------------
     .qpll_drpaddr_in(qpll_drpaddr_in_i),
     .qpll_drpdi_in(qpll_drpdi_in_i),
     .qpll_drpen_in(qpll_drpen_in_i), 
     .qpll_drpwe_in(qpll_drpwe_in_i), 
     .qpll_drpdo_out(qpll_drpdo_out_i), 
     .qpll_drprdy_out(qpll_drprdy_out_i), 
     .init_clk(INIT_CLK_i),
     .link_reset_out(link_reset_i), 
     .gt_pll_lock(pll_lock_i), 
     .sys_reset_out(system_reset_i), // user reset
     .gt_reset_out(),

     // GTX Reference Clock Interface
     .refclk1_in(GTXQ0_left_i), 

     .gt_refclk1_out(),
 
//--- assigning output values {
     .gt_qpllclk_quad10_out()  ,
     .gt_qpllrefclk_quad10_out()  ,

     .gt_qpllrefclklost_out() ,
     .gt_qplllock_out() ,
//--- assigning output values }
     .mmcm_not_locked_out(pll_not_locked_i),  // XXX need to invert this?
     .tx_out_clk(tx_out_clk_i)
 
 );

   // Standard CC Module
   aurora_64b66b_v7_3_STANDARD_CC_MODULE standard_cc_module_i
   (
      .DO_CC(do_cc_i),
      .USER_CLK(user_clk_i),
      .CHANNEL_UP(channel_up_i) 
   );



    //RX Interface
    wire      [0:127]    m_axi_rx_tdata_i; 


    assign s_axi_tx_tdata_i = TX_DATA_OUT;
    assign RX_DATA_IN = RX_DATA_IN_delay;
    assign rx_rdy = rx_rdy_delay;
   
    assign s_axi_tx_tvalid_i = (tx_en);
    assign tx_rdy = s_axi_tx_tready_i && (!do_cc_i);
    wire   rx_reset_c;
    wire   rx_data_valid_c;
    assign rx_reset_c = system_reset_i || !channel_up_i;
    assign  rx_data_valid_c    =  m_axi_rx_tvalid_i;

    reg [127:0] RX_DATA_IN_delay;
    reg        rx_rdy_delay;

    // Pipeline rx_rdy to improve pipeline performance
    // we get away without having defaults due to the high
    // level properties of the driver (it waits for man do_CC before data may be received)
    always@(posedge user_clk_i)
    begin
        rx_rdy_delay <= rx_data_valid_c && !rx_reset_c;
        RX_DATA_IN_delay <= m_axi_rx_tdata_i;
    end

generate
if (USE_CHIPSCOPE==1)
begin : chipscope1
   
reg [63:0] sync_reg;
wire [63:0] sync_in_i;

    reg tick_user_clock;
    reg tick_init_clock;

    reg  [31:0] rx_count_next;
    reg  [31:0] tx_count_next;
    reg  [31:0] error_count_next;

    always @(posedge INIT_CLK)
    begin
        tick_init_clock <= ~tick_init_clock;  
    end

    always @(posedge USER_CLK)
    begin
	rx_count_next = RX_COUNT;
        tx_count_next = TX_COUNT;
        error_count_next = ERROR_COUNT;
        tick_user_clock <= ~tick_user_clock;  

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
        assign  sync_in_i[15:0]         =  s_axi_tx_tdata_i[48:63];
        assign  sync_in_i[31:16]        =  m_axi_rx_tdata_i[48:63];
        assign  sync_in_i[32]           =  RESET;  
        assign  sync_in_i[33]           =  system_reset_i;  
//        assign  sync_in_i[34]           =  FLITCOUNT[0];  
//        assign  sync_in_i[35]           =  FLITCOUNT[1];  
        assign  sync_in_i[34]           =  tick_user_clock;  
        assign  sync_in_i[35]           =  tick_init_clock;  
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

