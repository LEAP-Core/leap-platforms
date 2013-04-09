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
// 
///////////////////////////////////////////////////////////////////////////////
//
//
//
//
//  Description: Clock Enable Generator
//
//         
`timescale 1 ns / 1 ps
module aurora_64b66b_v7_3_clock_enable_generator
(
    // User IO
    RESET,
    USER_CLK,
    ENABLE_32,
    ENABLE_64
);

`define DLY #1

//***********************************Port Declarations*******************************
    // User I/O
    input              RESET;
    input              USER_CLK;
   
    output             ENABLE_64;
    output             ENABLE_32;

//**************************External Register Declarations****************************

    reg             ENABLE_64;
    reg             ENABLE_32;
//**************************Internal Register Declarations****************************
    reg        [1:0]     count;

//*********************************Main Body of Code**********************************


    always @(posedge USER_CLK,negedge RESET)
        if(!RESET)
            count    <=  `DLY 2'b00;    
        else
            count    <=  `DLY count +1'b1;

    always @ (posedge USER_CLK)
      if(!RESET)
	      ENABLE_32 <=  `DLY 1'b0;
      else if(count == 2'b00 || count == 2'b10)
              ENABLE_32 <=  `DLY 1'b1;       
      else    
	      ENABLE_32 <=  `DLY 1'b0;

   always @ (posedge USER_CLK)
      if(!RESET)
	      ENABLE_64 <=  `DLY 1'b0;
      else if(count == 2'b00)
              ENABLE_64 <=  `DLY 1'b1;       
      else    
	      ENABLE_64 <=  `DLY 1'b0;  

endmodule
