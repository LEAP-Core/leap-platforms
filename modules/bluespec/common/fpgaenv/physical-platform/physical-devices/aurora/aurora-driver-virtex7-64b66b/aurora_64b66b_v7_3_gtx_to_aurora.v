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
// Width and clock rate converter
//
// Description: This module is used as a shim between the Aurora protocol and
//              the gtx in the 64B66B protocol.It is required to convert data
//              at 64 from Aurora to 32 into the gtx. Width conversion is 
//              also required since the width of the Aurora interface is 8 bytes,
//              but the Rainier gtx does not have an 8byte interface.
//
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 10 ps

module aurora_64b66b_v7_3_GTX_WIDTH_AND_CLK_CONV_RX #
(
    parameter INPUT_WIDTH =4,
    parameter OUTPUT_WIDTH=8
)
(
    //Output to the Aurora Protocol interface
    DATA_TO_AURORA,

    //Input from the GTX

    DATA_FROM_GTX,

    // Sync header from GTX Interface
    RX_HEADER_IN,
    RX_DATAVALID_IN,

    // Sync header to Aurora 
    RX_HEADER_OUT,
    RX_DATAVALID_OUT,
    
    //Clock and reset 
    ENABLE_GTX,
    ENABLE_AURORA,
    USER_CLK,
    RESET
);


`define DLY #1


//***********************************Port Declarations*******************************

    input                         RESET;
    input                         ENABLE_AURORA;
    input                         ENABLE_GTX;
    input                         USER_CLK;
    input   [INPUT_WIDTH*8-1:0]   DATA_FROM_GTX;

    output  [OUTPUT_WIDTH*8-1:0]  DATA_TO_AURORA;
    output  [1:0]                 RX_HEADER_OUT;
    output                        RX_DATAVALID_OUT;
//*****************************MGT Interface**************************
    input   [1:0]                 RX_HEADER_IN;
    input                         RX_DATAVALID_IN;
//*****************************External Register Declarations**************************
    reg     [OUTPUT_WIDTH*8-1:0]  DATA_TO_AURORA;
    reg     [1:0]                 RX_HEADER_OUT;
//*****************************Internal Register Declarations**************************
    reg     [INPUT_WIDTH*8-1:0]   data_from_gtx_i;
    reg     [INPUT_WIDTH*8-1:0]   data_from_gtx_r;
    reg     [INPUT_WIDTH*8-1:0]   data_from_gtx_r2;
    reg     [1:0]                 rx_header_r;
    reg     [1:0]                 rx_header_r2;
    reg                           rx_datavalid_i;
    reg                           rx_datavalid_neg_r;
    reg                           rx_datavalid_pos_r2;
    reg                           rx_datavalid_pos_r;
    reg                           state;
//*****************************Beginning of Code *************************


    always @ (posedge USER_CLK)
    begin
         data_from_gtx_i <= `DLY DATA_FROM_GTX;
         rx_datavalid_i  <= `DLY RX_DATAVALID_IN; 
    end

    always @(posedge USER_CLK)
    begin
           if(ENABLE_GTX) rx_header_r          <=  `DLY RX_HEADER_IN;
    end

    always @(posedge USER_CLK)
    begin
           if(ENABLE_GTX) rx_header_r2         <= `DLY rx_header_r;
    end

    always @(posedge USER_CLK)
    begin
         if(RESET)
           RX_HEADER_OUT       <= `DLY 2'b0;
         else if (ENABLE_AURORA)
           if(state)
             RX_HEADER_OUT       <= `DLY rx_header_r2;
           else if(!state)
             RX_HEADER_OUT       <= `DLY rx_header_r;
    end

    always @(posedge USER_CLK)
    begin
           if(ENABLE_GTX) data_from_gtx_r     <= `DLY  data_from_gtx_i;
    end

    always @(posedge USER_CLK)
    begin
           if(ENABLE_GTX) data_from_gtx_r2    <= `DLY  data_from_gtx_r;
    end

    always @(posedge USER_CLK)
    if(ENABLE_AURORA)
    begin
           rx_datavalid_pos_r  <= `DLY rx_datavalid_i;
           rx_datavalid_pos_r2 <= `DLY rx_datavalid_pos_r;
    end

    //Sampling wrt negedge is required to take care of odd boundary alignment
    //However negedge sampling will not effect timing because maximum frequency at which CLK_AURORA can
    //run is 104 MHz
    always @(posedge USER_CLK)
    begin
           if(!ENABLE_AURORA) rx_datavalid_neg_r  <= `DLY rx_datavalid_i;
    end

    always @(posedge USER_CLK)
    begin
         if(RESET)
                 state <= `DLY 1'b1;
         else if(ENABLE_AURORA)
            if (!rx_datavalid_neg_r)
                 state <= `DLY 1'b0;
            else if (!rx_datavalid_pos_r)
                 state <= `DLY 1'b1;
    end

    always @(posedge USER_CLK)
         if(RESET)
               DATA_TO_AURORA <= `DLY 64'b0;
         else if(ENABLE_AURORA)
             if(state)
               DATA_TO_AURORA <= `DLY {data_from_gtx_r2,data_from_gtx_r};
             else if(!state)
               DATA_TO_AURORA <= `DLY {data_from_gtx_r,data_from_gtx_i};

    assign RX_DATAVALID_OUT = rx_datavalid_pos_r2;

endmodule  
