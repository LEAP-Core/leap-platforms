//////////////////////////////////////////////////////////////////////////////
//$Date: 2009/11/26 05:47:37 $
//$Revision: 1.1 $
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /
// \   \   \/     Vendor : Xilinx
//  \   \         Version : 2.1
//  /   /         Application : Rocketio GTP Transceiver Wizard
// /___/   /\     Filename : serdes.v
// \   \  /  \
//  \___\/\___\
//
//
// Module SERDES (a GTP Wrapper)
// Generated by Xilinx Rocketio GTP Transceiver Wizard
// 
// 
// (c) Copyright 2006-2010 Xilinx, Inc. All rights reserved.
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



`timescale 1ns / 1ps


//***************************** Entity Declaration ****************************

module SERDES #
(
    // Simulation attributes
    parameter   WRAPPER_SIM_MODE                = "FAST",   // Set to Fast Functional Simulation Model    
    parameter   WRAPPER_SIM_GTPRESET_SPEEDUP    = 0,    // Set to 1 to speed up sim reset
    parameter   WRAPPER_SIM_PLL_PERDIV2         = 9'h1f4   // Set to the VCO Unit Interval time    
)
(
    
    //_________________________________________________________________________
    //_________________________________________________________________________
    //TILE0  (Location)

    //---------------------- Loopback and Powerdown Ports ----------------------
    TILE0_LOOPBACK0_IN,
    TILE0_LOOPBACK1_IN,
    //--------------------- Receive Ports - 8b10b Decoder ----------------------
    TILE0_RXCHARISK0_OUT,
    TILE0_RXCHARISK1_OUT,
    TILE0_RXDISPERR0_OUT,
    TILE0_RXDISPERR1_OUT,
    TILE0_RXNOTINTABLE0_OUT,
    TILE0_RXNOTINTABLE1_OUT,
    //------------- Receive Ports - Comma Detection and Alignment --------------
    TILE0_RXENMCOMMAALIGN0_IN,
    TILE0_RXENMCOMMAALIGN1_IN,
    TILE0_RXENPCOMMAALIGN0_IN,
    TILE0_RXENPCOMMAALIGN1_IN,
    //----------------- Receive Ports - RX Data Path interface -----------------
    TILE0_RXDATA0_OUT,
    TILE0_RXDATA1_OUT,
    TILE0_RXRECCLK0_OUT,
    TILE0_RXRECCLK1_OUT,
    TILE0_RXUSRCLK0_IN,
    TILE0_RXUSRCLK1_IN,
    TILE0_RXUSRCLK20_IN,
    TILE0_RXUSRCLK21_IN,
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    TILE0_RXN0_IN,
    TILE0_RXN1_IN,
    TILE0_RXP0_IN,
    TILE0_RXP1_IN,
    //--------------- Receive Ports - RX Polarity Control Ports ----------------
    TILE0_RXPOLARITY0_IN,
    TILE0_RXPOLARITY1_IN,
    //------------------- Shared Ports - Tile and PLL Ports --------------------
    TILE0_CLKIN_IN,
    TILE0_GTPRESET_IN,
    TILE0_PLLLKDET_OUT,
    TILE0_REFCLKOUT_OUT,
    TILE0_RESETDONE0_OUT,
    TILE0_RESETDONE1_OUT,
    //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
    TILE0_TXCHARISK0_IN,
    TILE0_TXCHARISK1_IN,
    //---------------- Transmit Ports - TX Data Path interface -----------------
    TILE0_TXDATA0_IN,
    TILE0_TXDATA1_IN,
    TILE0_TXOUTCLK0_OUT,
    TILE0_TXOUTCLK1_OUT,
    TILE0_TXUSRCLK0_IN,
    TILE0_TXUSRCLK1_IN,
    TILE0_TXUSRCLK20_IN,
    TILE0_TXUSRCLK21_IN,
    //------------- Transmit Ports - TX Driver and OOB signalling --------------
    TILE0_TXN0_OUT,
    TILE0_TXN1_OUT,
    TILE0_TXP0_OUT,
    TILE0_TXP1_OUT,
    //------------------ Transmit Ports - TX Polarity Control ------------------
    TILE0_TXPOLARITY0_IN,
    TILE0_TXPOLARITY1_IN


);

// synthesis attribute X_CORE_INFO of SERDES is "v5_gtpwizard_v2_1, Coregen v12.1";

//***************************** Port Declarations *****************************
        


    //_________________________________________________________________________
    //_________________________________________________________________________
    //TILE0  (Location)

    //---------------------- Loopback and Powerdown Ports ----------------------
    input   [2:0]   TILE0_LOOPBACK0_IN;
    input   [2:0]   TILE0_LOOPBACK1_IN;
    //--------------------- Receive Ports - 8b10b Decoder ----------------------
    output  [1:0]   TILE0_RXCHARISK0_OUT;
    output  [1:0]   TILE0_RXCHARISK1_OUT;
    output  [1:0]   TILE0_RXDISPERR0_OUT;
    output  [1:0]   TILE0_RXDISPERR1_OUT;
    output  [1:0]   TILE0_RXNOTINTABLE0_OUT;
    output  [1:0]   TILE0_RXNOTINTABLE1_OUT;
    //------------- Receive Ports - Comma Detection and Alignment --------------
    input           TILE0_RXENMCOMMAALIGN0_IN;
    input           TILE0_RXENMCOMMAALIGN1_IN;
    input           TILE0_RXENPCOMMAALIGN0_IN;
    input           TILE0_RXENPCOMMAALIGN1_IN;
    //----------------- Receive Ports - RX Data Path interface -----------------
    output  [15:0]  TILE0_RXDATA0_OUT;
    output  [15:0]  TILE0_RXDATA1_OUT;
    output          TILE0_RXRECCLK0_OUT;
    output          TILE0_RXRECCLK1_OUT;
    input           TILE0_RXUSRCLK0_IN;
    input           TILE0_RXUSRCLK1_IN;
    input           TILE0_RXUSRCLK20_IN;
    input           TILE0_RXUSRCLK21_IN;
    //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    input           TILE0_RXN0_IN;
    input           TILE0_RXN1_IN;
    input           TILE0_RXP0_IN;
    input           TILE0_RXP1_IN;
    //--------------- Receive Ports - RX Polarity Control Ports ----------------
    input           TILE0_RXPOLARITY0_IN;
    input           TILE0_RXPOLARITY1_IN;
    //------------------- Shared Ports - Tile and PLL Ports --------------------
    input           TILE0_CLKIN_IN;
    input           TILE0_GTPRESET_IN;
    output          TILE0_PLLLKDET_OUT;
    output          TILE0_REFCLKOUT_OUT;
    output          TILE0_RESETDONE0_OUT;
    output          TILE0_RESETDONE1_OUT;
    //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
    input   [1:0]   TILE0_TXCHARISK0_IN;
    input   [1:0]   TILE0_TXCHARISK1_IN;
    //---------------- Transmit Ports - TX Data Path interface -----------------
    input   [15:0]  TILE0_TXDATA0_IN;
    input   [15:0]  TILE0_TXDATA1_IN;
    output          TILE0_TXOUTCLK0_OUT;
    output          TILE0_TXOUTCLK1_OUT;
    input           TILE0_TXUSRCLK0_IN;
    input           TILE0_TXUSRCLK1_IN;
    input           TILE0_TXUSRCLK20_IN;
    input           TILE0_TXUSRCLK21_IN;
    //------------- Transmit Ports - TX Driver and OOB signalling --------------
    output          TILE0_TXN0_OUT;
    output          TILE0_TXN1_OUT;
    output          TILE0_TXP0_OUT;
    output          TILE0_TXP1_OUT;
    //------------------ Transmit Ports - TX Polarity Control ------------------
    input           TILE0_TXPOLARITY0_IN;
    input           TILE0_TXPOLARITY1_IN;





//***************************** Wire Declarations *****************************

    // Channel Bonding Signals


    // ground and vcc signals
    wire            tied_to_ground_i;
    wire    [63:0]  tied_to_ground_vec_i;
    wire            tied_to_vcc_i;
    wire    [63:0]  tied_to_vcc_vec_i;
    

//********************************* Main Body of Code**************************

    assign tied_to_ground_i             = 1'b0;
    assign tied_to_ground_vec_i         = 64'h0000000000000000;
    assign tied_to_vcc_i                = 1'b1;
    assign tied_to_vcc_vec_i            = 64'hffffffffffffffff;
    

    //------------------------- Tile Instances  -------------------------------   



    //_________________________________________________________________________
    //_________________________________________________________________________
    //TILE0  (Location)

    SERDES_TILE #
    (
        // Simulation attributes
        .TILE_SIM_MODE               (WRAPPER_SIM_MODE),
        .TILE_SIM_GTPRESET_SPEEDUP   (WRAPPER_SIM_GTPRESET_SPEEDUP),
        .TILE_SIM_PLL_PERDIV2        (WRAPPER_SIM_PLL_PERDIV2),

        // Channel bonding attributes
        .TILE_CHAN_BOND_MODE_0       ("OFF"),
        .TILE_CHAN_BOND_LEVEL_0      (0),
    
        .TILE_CHAN_BOND_MODE_1       ("OFF"),
        .TILE_CHAN_BOND_LEVEL_1      (0)          
    )
    tile0_serdes_i
    (
        //---------------------- Loopback and Powerdown Ports ----------------------
        .LOOPBACK0_IN                   (TILE0_LOOPBACK0_IN),
        .LOOPBACK1_IN                   (TILE0_LOOPBACK1_IN),
        //--------------------- Receive Ports - 8b10b Decoder ----------------------
        .RXCHARISK0_OUT                 (TILE0_RXCHARISK0_OUT),
        .RXCHARISK1_OUT                 (TILE0_RXCHARISK1_OUT),
        .RXDISPERR0_OUT                 (TILE0_RXDISPERR0_OUT),
        .RXDISPERR1_OUT                 (TILE0_RXDISPERR1_OUT),
        .RXNOTINTABLE0_OUT              (TILE0_RXNOTINTABLE0_OUT),
        .RXNOTINTABLE1_OUT              (TILE0_RXNOTINTABLE1_OUT),
        //------------- Receive Ports - Comma Detection and Alignment --------------
        .RXENMCOMMAALIGN0_IN            (TILE0_RXENMCOMMAALIGN0_IN),
        .RXENMCOMMAALIGN1_IN            (TILE0_RXENMCOMMAALIGN1_IN),
        .RXENPCOMMAALIGN0_IN            (TILE0_RXENPCOMMAALIGN0_IN),
        .RXENPCOMMAALIGN1_IN            (TILE0_RXENPCOMMAALIGN1_IN),
        //----------------- Receive Ports - RX Data Path interface -----------------
        .RXDATA0_OUT                    (TILE0_RXDATA0_OUT),
        .RXDATA1_OUT                    (TILE0_RXDATA1_OUT),
        .RXRECCLK0_OUT                  (TILE0_RXRECCLK0_OUT),
        .RXRECCLK1_OUT                  (TILE0_RXRECCLK1_OUT),
        .RXUSRCLK0_IN                   (TILE0_RXUSRCLK0_IN),
        .RXUSRCLK1_IN                   (TILE0_RXUSRCLK1_IN),
        .RXUSRCLK20_IN                  (TILE0_RXUSRCLK20_IN),
        .RXUSRCLK21_IN                  (TILE0_RXUSRCLK21_IN),
        //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        .RXN0_IN                        (TILE0_RXN0_IN),
        .RXN1_IN                        (TILE0_RXN1_IN),
        .RXP0_IN                        (TILE0_RXP0_IN),
        .RXP1_IN                        (TILE0_RXP1_IN),
        //--------------- Receive Ports - RX Polarity Control Ports ----------------
        .RXPOLARITY0_IN                 (TILE0_RXPOLARITY0_IN),
        .RXPOLARITY1_IN                 (TILE0_RXPOLARITY1_IN),
        //------------------- Shared Ports - Tile and PLL Ports --------------------
        .CLKIN_IN                       (TILE0_CLKIN_IN),
        .GTPRESET_IN                    (TILE0_GTPRESET_IN),
        .PLLLKDET_OUT                   (TILE0_PLLLKDET_OUT),
        .REFCLKOUT_OUT                  (TILE0_REFCLKOUT_OUT),
        .RESETDONE0_OUT                 (TILE0_RESETDONE0_OUT),
        .RESETDONE1_OUT                 (TILE0_RESETDONE1_OUT),
        //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
        .TXCHARISK0_IN                  (TILE0_TXCHARISK0_IN),
        .TXCHARISK1_IN                  (TILE0_TXCHARISK1_IN),
        //---------------- Transmit Ports - TX Data Path interface -----------------
        .TXDATA0_IN                     (TILE0_TXDATA0_IN),
        .TXDATA1_IN                     (TILE0_TXDATA1_IN),
        .TXOUTCLK0_OUT                  (TILE0_TXOUTCLK0_OUT),
        .TXOUTCLK1_OUT                  (TILE0_TXOUTCLK1_OUT),
        .TXUSRCLK0_IN                   (TILE0_TXUSRCLK0_IN),
        .TXUSRCLK1_IN                   (TILE0_TXUSRCLK1_IN),
        .TXUSRCLK20_IN                  (TILE0_TXUSRCLK20_IN),
        .TXUSRCLK21_IN                  (TILE0_TXUSRCLK21_IN),
        //------------- Transmit Ports - TX Driver and OOB signalling --------------
        .TXN0_OUT                       (TILE0_TXN0_OUT),
        .TXN1_OUT                       (TILE0_TXN1_OUT),
        .TXP0_OUT                       (TILE0_TXP0_OUT),
        .TXP1_OUT                       (TILE0_TXP1_OUT),
        //------------------ Transmit Ports - TX Polarity Control ------------------
        .TXPOLARITY0_IN                 (TILE0_TXPOLARITY0_IN),
        .TXPOLARITY1_IN                 (TILE0_TXPOLARITY1_IN)

    );

    
     
endmodule

