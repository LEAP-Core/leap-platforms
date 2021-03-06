///////////////////////////////////////////////////////////////////////////////
//$Date: 2009/05/15 09:10:49 $
//$Revision: 1.1.2.3 $
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /
// \   \   \/     Vendor : Xilinx 
//  \   \         Version : 1.10
//  /   /         Application : RocketIO GTP Transceiver Wizard
// /___/   /\     Filename : serdes_top.v
// \   \  /  \
//  \___\/\___\
//
//
// Module SERDES_TOP
// Generated by Xilinx RocketIO GTP Transceiver Wizard
// 
// 
// (c) Copyright 2006-2009 Xilinx, Inc. All rights reserved.
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
// including negligence, or under any other theory of,
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


`timescale 1ns / 1ps
`define DLY #1


//***********************************Entity Declaration************************

module serdes_ip #
(
    parameter WRAPPER_SIM_MODE                          =   "FAST",  // Set to Fast Functional Simulation Model   
    parameter WRAPPER_SIM_GTPRESET_SPEEDUP              =   1,   // simulation setting for MGT smartmodel
    parameter WRAPPER_SIM_PLL_PERDIV2                   =   9'h1f4 // simulation setting for MGT smartmodel
)
(
    grefclk_i,
    gtpreset_n_in,
    PLLLKDET_OUT,
    RXN_IN,
    RXP_IN,
    TXN_OUT,
    TXP_OUT,
    rxcharisk0_out, // rxusrclk0 
    rxdisperr0_out, // rxusrclk0
    rxdata0_out, // rxusrclk0
    rxcharisk1_out, // rxusrclk1 
    rxdisperr1_out, // rxusrclk1
    rxdata1_out, // rxusrclk1
    txcharisk0_in, // txusrclk
    txdata0_in,  // txusrclk
    txcharisk1_in, // txusrclk
    txdata1_in,  // txusrclk
    txusrclk_out, // txusrclk
    rxusrclk0_out, // rxusrclk0
    rxusrclk1_out, // rxusrclk1
    resetdone0_out,
    resetdone1_out,
    total_reset_out
);

// synthesis attribute X_CORE_INFO of SERDES_TOP is "gtpwizard_v1_10, Coregen v11.2";

//***********************************Ports Declaration*******************************

    input           grefclk_i;
    input           gtpreset_n_in;
    output          PLLLKDET_OUT;
    input   [1:0]   RXN_IN;
    input   [1:0]   RXP_IN;
    output  [1:0]   TXN_OUT;
    output  [1:0]   TXP_OUT;

    // fpga interface
    output  [1:0]   rxcharisk0_out; // rxusrclk0 
    output  [1:0]   rxdisperr0_out; // rxusrclk0
    output [15:0]   rxdata0_out; // rxusrclk0
    output  [1:0]   rxcharisk1_out; // rxusrclk1 
    output  [1:0]   rxdisperr1_out; // rxusrclk1
    output [15:0]   rxdata1_out; // rxusrclk1
    input   [1:0]   txcharisk0_in; // txusrclk
    input  [15:0]   txdata0_in;  // txusrclk
    input   [1:0]   txcharisk1_in; // txusrclk
    input  [15:0]   txdata1_in;  // txusrclk
    output	    txusrclk_out; // txusrclk
    output          rxusrclk0_out; // rxusrclk0
    output          rxusrclk1_out; // rxusrclk1
    output          resetdone0_out;
    output          resetdone1_out;
    output [15:0]   total_reset_out;
     

//**************************** Wire Declarations ******************************

    //------------------------ MGT Wrapper Wires ------------------------------
    
    //________________________________________________________________________
    //________________________________________________________________________
    //TILE0   (X0Y3)

    //---------------------- Loopback and Powerdown Ports ----------------------
    wire    [2:0]   tile0_loopback0_i;
    wire    [2:0]   tile0_loopback1_i;
    //--------------------- Receive Ports - 8b10b Decoder ----------------------
    wire    [1:0]   tile0_rxcharisk0_i;
    wire    [1:0]   tile0_rxcharisk1_i;
    wire    [1:0]   tile0_rxdisperr0_i;
    wire    [1:0]   tile0_rxdisperr1_i;
    wire    [1:0]   tile0_rxnotintable0_i;
    wire    [1:0]   tile0_rxnotintable1_i;
    //------------- Receive Ports - Comma Detection and Alignment --------------
    wire            tile0_rxenmcommaalign0_i;
    wire            tile0_rxenmcommaalign1_i;
    wire            tile0_rxenpcommaalign0_i;
    wire            tile0_rxenpcommaalign1_i;
    //----------------- Receive Ports - RX Data Path interface -----------------
    wire    [15:0]  tile0_rxdata0_i;
    wire    [15:0]  tile0_rxdata1_i;
    wire            tile0_rxrecclk0_i;
    wire            tile0_rxrecclk1_i;
    //--------------- Receive Ports - RX Polarity Control Ports ----------------
    wire            tile0_rxpolarity0_i;
    wire            tile0_rxpolarity1_i;
    //------------------- Shared Ports - Tile and PLL Ports --------------------
    wire            tile0_plllkdet_i;
    wire            tile0_refclkout_i;
    wire            tile0_resetdone0_i;
    wire            tile0_resetdone1_i;
    //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
    wire    [1:0]   tile0_txcharisk0_i;
    wire    [1:0]   tile0_txcharisk1_i;
    //---------------- Transmit Ports - TX Data Path interface -----------------
    wire    [15:0]  tile0_txdata0_i;
    wire    [15:0]  tile0_txdata1_i;
    wire            tile0_txoutclk0_i;
    wire            tile0_txoutclk1_i;
    //------------------ Transmit Ports - TX Polarity Control ------------------
    wire            tile0_txpolarity0_i;
    wire            tile0_txpolarity1_i;

    
    //--------------------------- User Clocks ---------------------------------
    wire            tile0_txusrclk0_i;
    wire            tile0_txusrclk20_i;
    wire            tile0_rxusrclk0_i;
    wire            tile0_rxusrclk20_i;
    wire            tile0_rxusrclk1_i;
    wire            tile0_rxusrclk21_i;
    wire            txoutclk_dcm0_locked_i;
    wire            txoutclk_dcm0_reset_i;
    wire            tile0_txoutclk0_to_dcm_i;
    wire            rxrecclk_dcm1_locked_i;
    wire            rxrecclk_dcm1_reset_i;
    wire            tile0_rxrecclk0_to_dcm_i;
    wire            rxrecclk_dcm2_locked_i;
    wire            rxrecclk_dcm2_reset_i;
    wire            tile0_rxrecclk1_to_dcm_i;

    //--------------------------- Register Declarations  ---------------------------------

    reg [19:0]       rst_cnt;
    reg             rst_state; 
           
    //--------------------------------- User Clocks ---------------------------
    
    // The clock resources in this section were added based on userclk source selections on
    // the Latency, Buffering, and Clocking page of the GUI. A few notes about user clocks:
    // * The userclk and userclk2 for each GTP datapath (TX and RX) must be phase aligned to 
    //   avoid data errors in the fabric interface whenever the datapath is wider than 10 bits
    // * To minimize clock resources, you can share clocks between GTPs. GTPs using the same frequency
    //   or multiples of the same frequency can be accomadated using DCMs and PLLs. Use caution when
    //   using RXRECCLK as a clock source, however - these clocks can typically only be shared if all
    //   the channels using the clock are receiving data from TX channels that share a reference clock 
    //   source with each other.

    BUFG txoutclk_dcm0_bufg_i
    (
        .I                              (tile0_txoutclk0_i),
        .O                              (tile0_txoutclk0_to_dcm_i)
    );

    assign  txoutclk_dcm0_reset_i           =  !tile0_plllkdet_i;
    MGT_USRCLK_SOURCE #
    (
        .FREQUENCY_MODE                 ("HIGH"),
        .PERFORMANCE_MODE               ("MAX_SPEED")
    )
    txoutclk_dcm0_i
    (
        .DIV1_OUT                       (tile0_txusrclk0_i),
        .DIV2_OUT                       (tile0_txusrclk20_i),
        .DCM_LOCKED_OUT                 (txoutclk_dcm0_locked_i),
        .CLK_IN                         (tile0_txoutclk0_to_dcm_i),
        .DCM_RESET_IN                   (txoutclk_dcm0_reset_i)
    );


    BUFG rxrecclk_dcm1_bufg_i
    (
        .I                              (tile0_rxrecclk0_i),
        .O                              (tile0_rxrecclk0_to_dcm_i)
    );

    assign  rxrecclk_dcm1_reset_i           =  !tile0_plllkdet_i;
    MGT_USRCLK_SOURCE #
    (
        .FREQUENCY_MODE                 ("HIGH"),
        .PERFORMANCE_MODE               ("MAX_SPEED")
    )
    rxrecclk_dcm1_i
    (
        .DIV1_OUT                       (tile0_rxusrclk0_i),
        .DIV2_OUT                       (tile0_rxusrclk20_i),
        .DCM_LOCKED_OUT                 (rxrecclk_dcm1_locked_i),
        .CLK_IN                         (tile0_rxrecclk0_to_dcm_i),
        .DCM_RESET_IN                   (rxrecclk_dcm1_reset_i)
    );


    BUFG rxrecclk_dcm2_bufg_i
    (
        .I                              (tile0_rxrecclk1_i),
        .O                              (tile0_rxrecclk1_to_dcm_i)
    );

    assign  rxrecclk_dcm2_reset_i           =  !tile0_plllkdet_i;
    MGT_USRCLK_SOURCE #
    (
        .FREQUENCY_MODE                 ("HIGH"),
        .PERFORMANCE_MODE               ("MAX_SPEED")
    )
    rxrecclk_dcm2_i
    (
        .DIV1_OUT                       (tile0_rxusrclk1_i),
        .DIV2_OUT                       (tile0_rxusrclk21_i),
        .DCM_LOCKED_OUT                 (rxrecclk_dcm2_locked_i),
        .CLK_IN                         (tile0_rxrecclk1_to_dcm_i),
        .DCM_RESET_IN                   (rxrecclk_dcm2_reset_i)
    );


    //--------------------------- The GTP Wrapper -----------------------------
    
    // Use the instantiation template in the project directory to add the GTP wrapper to your design.
    // In this example, the wrapper is wired up for basic operation with a frame generator and frame 
    // checker. The GTPs will reset, then attempt to align and transmit data. If channel bonding is 
    // enabled, bonding should occur after alignment.


    // Wire all PLLLKDET signals to the top level as output ports
   assign  PLLLKDET_OUT = tile0_plllkdet_i;
   assign  tile0_gtpreset_i = rst_state;
   
   assign  rxcharisk0_out = tile0_rxcharisk0_i;
   assign  rxdisperr0_out = tile0_rxdisperr0_i;
   assign  rxdata0_out = tile0_rxdata0_i;
   assign  rxusrclk0_out = tile0_rxusrclk20_i;

   assign  rxcharisk1_out = tile0_rxcharisk1_i;
   assign  rxdisperr1_out = tile0_rxdisperr1_i;
   assign  rxdata1_out = tile0_rxdata1_i;
   assign  rxusrclk1_out = tile0_rxusrclk21_i;

   assign  tile0_txdata0_i = txdata0_in;
   assign  tile0_txcharisk0_i = txcharisk0_in;

   assign  tile0_txdata1_i = txdata1_in;
   assign  tile0_txcharisk1_i = txcharisk1_in;
   assign  txusrclk_out = tile0_txusrclk20_i;

   assign  resetdone0_out = tile0_resetdone0_i;
   assign  resetdone1_out = tile0_resetdone1_i;

   // constant values;
    assign  tile0_loopback0_i = 3'b000; // no loopback
    assign  tile0_loopback1_i = 3'b000;
    assign  tile0_rxenmcommaalign0_i = 1'b1;
    assign  tile0_rxenmcommaalign1_i = 1'b1;
    assign  tile0_rxenpcommaalign0_i = 1'b1;
    assign  tile0_rxenpcommaalign1_i = 1'b1;
    assign  tile0_rxpolarity0_i = 1'b1;
    assign  tile0_rxpolarity1_i = 1'b1;
    assign  tile0_txpolarity0_i = 1'b1;
    assign  tile0_txpolarity1_i = 1'b1;
   
    SERDES #
    (
        .WRAPPER_SIM_MODE                       (WRAPPER_SIM_MODE),
        .WRAPPER_SIM_GTPRESET_SPEEDUP           (WRAPPER_SIM_GTPRESET_SPEEDUP),
        .WRAPPER_SIM_PLL_PERDIV2                (WRAPPER_SIM_PLL_PERDIV2)
    )
    serdes_i
    (
        //_____________________________________________________________________
        //_____________________________________________________________________
        //TILE0  (X0Y3)

        //---------------------- Loopback and Powerdown Ports ----------------------
        .TILE0_LOOPBACK0_IN             (tile0_loopback0_i),
        .TILE0_LOOPBACK1_IN             (tile0_loopback1_i),
        //--------------------- Receive Ports - 8b10b Decoder ----------------------
        .TILE0_RXCHARISK0_OUT           (tile0_rxcharisk0_i),
        .TILE0_RXCHARISK1_OUT           (tile0_rxcharisk1_i),
        .TILE0_RXDISPERR0_OUT           (tile0_rxdisperr0_i),
        .TILE0_RXDISPERR1_OUT           (tile0_rxdisperr1_i),
        .TILE0_RXNOTINTABLE0_OUT        (tile0_rxnotintable0_i),
        .TILE0_RXNOTINTABLE1_OUT        (tile0_rxnotintable1_i),
        //------------- Receive Ports - Comma Detection and Alignment --------------
        .TILE0_RXENMCOMMAALIGN0_IN      (tile0_rxenmcommaalign0_i),
        .TILE0_RXENMCOMMAALIGN1_IN      (tile0_rxenmcommaalign1_i),
        .TILE0_RXENPCOMMAALIGN0_IN      (tile0_rxenpcommaalign0_i),
        .TILE0_RXENPCOMMAALIGN1_IN      (tile0_rxenpcommaalign1_i),
        //----------------- Receive Ports - RX Data Path interface -----------------
        .TILE0_RXDATA0_OUT              (tile0_rxdata0_i),
        .TILE0_RXDATA1_OUT              (tile0_rxdata1_i),
        .TILE0_RXRECCLK0_OUT            (tile0_rxrecclk0_i),
        .TILE0_RXRECCLK1_OUT            (tile0_rxrecclk1_i),
        .TILE0_RXUSRCLK0_IN             (tile0_rxusrclk0_i),
        .TILE0_RXUSRCLK1_IN             (tile0_rxusrclk1_i),
        .TILE0_RXUSRCLK20_IN            (tile0_rxusrclk20_i),
        .TILE0_RXUSRCLK21_IN            (tile0_rxusrclk21_i),
        //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        .TILE0_RXN0_IN                  (RXN_IN[0]),
        .TILE0_RXN1_IN                  (RXN_IN[1]),
        .TILE0_RXP0_IN                  (RXP_IN[0]),
        .TILE0_RXP1_IN                  (RXP_IN[1]),
        //--------------- Receive Ports - RX Polarity Control Ports ----------------
        .TILE0_RXPOLARITY0_IN           (tile0_rxpolarity0_i),
        .TILE0_RXPOLARITY1_IN           (tile0_rxpolarity1_i),
        //------------------- Shared Ports - Tile and PLL Ports --------------------
        .TILE0_CLKIN_IN                 (grefclk_i),
        .TILE0_GTPRESET_IN              (tile0_gtpreset_i),
        .TILE0_PLLLKDET_OUT             (tile0_plllkdet_i),
        .TILE0_REFCLKOUT_OUT            (tile0_refclkout_i),
        .TILE0_RESETDONE0_OUT           (tile0_resetdone0_i),
        .TILE0_RESETDONE1_OUT           (tile0_resetdone1_i),
        //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        .TILE0_TXCHARISK0_IN            (tile0_txcharisk0_i),
        .TILE0_TXCHARISK1_IN            (tile0_txcharisk1_i),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .TILE0_TXDATA0_IN               (tile0_txdata0_i),
        .TILE0_TXDATA1_IN               (tile0_txdata1_i),
        .TILE0_TXOUTCLK0_OUT            (tile0_txoutclk0_i),
        .TILE0_TXOUTCLK1_OUT            (tile0_txoutclk1_i),
        .TILE0_TXUSRCLK0_IN             (tile0_txusrclk0_i),
        .TILE0_TXUSRCLK1_IN             (tile0_txusrclk0_i),
        .TILE0_TXUSRCLK20_IN            (tile0_txusrclk20_i),
        .TILE0_TXUSRCLK21_IN            (tile0_txusrclk20_i),
        //------------- Transmit Ports - TX Driver and OOB signalling --------------
        .TILE0_TXN0_OUT                 (TXN_OUT[0]),
        .TILE0_TXN1_OUT                 (TXN_OUT[1]),
        .TILE0_TXP0_OUT                 (TXP_OUT[0]),
        .TILE0_TXP1_OUT                 (TXP_OUT[1]),
        //------------------ Transmit Ports - TX Polarity Control ------------------
        .TILE0_TXPOLARITY0_IN           (tile0_txpolarity0_i),
        .TILE0_TXPOLARITY1_IN           (tile0_txpolarity1_i)
    );

   reg [15:0] 	    total_reset;
   
   assign total_reset_out = total_reset;
   
   always @(posedge grefclk_i)
     begin
        if (!gtpreset_n_in)
          begin
             rst_cnt <= 20'h000; // rst for 256 cycles
             rst_state <= 1'b0; // rst
	     total_reset <= 0;	     
          end	
        else
          begin
             if (!tile0_plllkdet_i || rst_state) // count up if during reset of pll not detected
               begin
                  rst_cnt <= rst_cnt + 1;
               end
             else // reset counter if pll detected
               begin
                  rst_cnt <= 20'h00;
               end
             if (rst_cnt == 20'h3ff)
               begin
                  rst_state <= !rst_state;
		  total_reset <= total_reset + 1;		 
               end
             else
	       begin
                  rst_state <= rst_state;
               end
          end // else: !if(!gtpreset_n_in)
     end // always @ (posedge grefclk_i)   

endmodule


