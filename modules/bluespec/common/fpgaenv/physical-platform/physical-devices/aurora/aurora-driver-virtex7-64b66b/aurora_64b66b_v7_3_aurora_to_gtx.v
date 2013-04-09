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
//  Width and clock rate converter
//
//  Description: This module is used as a shim between the Aurora protocol and
//              the gtx in the 64B66B protocol.It is required to convert data
//              at 64 bit clock from Aurora to 32/16 bit GTX. Width conversion is 
//              also required since the width of the Aurora interface is 8 bytes
//              but the Rainier gtx does not have an 8byte interface.
//
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 10 ps

module aurora_64b66b_v7_3_GTX_WIDTH_AND_CLK_CONV_TX #
(
    parameter INPUT_WIDTH=8,
    parameter OUTPUT_WIDTH=4
)
(
    //Output to the GTX interface
    DATA_TO_GTX,

    //Input from the Aurora

    DATA_FROM_AURORA,

    // Sync header from Aurora Interface
    TX_HEADER_IN,

    // Sync header to GTX 
    TX_HEADER_OUT,

    //Clock and reset 
    CLK_GTX,
    RESET
);


`define DLY #1


//***********************************Port Declarations*******************************

    input                         RESET;
    input                         CLK_GTX;
    input   [INPUT_WIDTH*8-1:0]   DATA_FROM_AURORA;

    output  [OUTPUT_WIDTH*8-1:0]  DATA_TO_GTX;
    output  [1:0]                 TX_HEADER_OUT;

//*****************************GTX Interface**************************
    input   [1:0]                 TX_HEADER_IN;

//*****************************Internal Register Declarations**************************
    reg     [OUTPUT_WIDTH*8-1:0]  DATA_TO_GTX;
    reg     [1:0]                 TX_HEADER_OUT;

//*****************************Internal Register Declarations**************************
    reg                           sel_mux;

//*****************************Wire Declarations**************************
    wire     [31:0]               data_to_aurora_c;

//*****************************Beginning of Code *************************

    always @(posedge CLK_GTX)
    begin
          if(RESET)
                sel_mux   <= `DLY 1'b1;
          else if(sel_mux==1'b1)
                sel_mux   <= `DLY sel_mux +1;
          else
                sel_mux   <= `DLY 1'b1;
    end

    //Split data into 32 bit blocks, required for 32 bit GTX interface
    assign data_to_aurora_c = (sel_mux)?DATA_FROM_AURORA[63:32]:DATA_FROM_AURORA[31:0];

    //Assign output
    always @(posedge CLK_GTX)
    begin
         if(RESET)
             DATA_TO_GTX    <= `DLY  32'b0;
         else
             DATA_TO_GTX    <= `DLY  data_to_aurora_c;
    end

    always @(posedge CLK_GTX)
    begin
         if(RESET)
             TX_HEADER_OUT  <= `DLY  2'b0;
         else
             TX_HEADER_OUT  <= `DLY  TX_HEADER_IN;
    end

endmodule
  
