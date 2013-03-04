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
//  ERR_DETECT_4BYTE_GTX
//
//
//  Description : The ERR_DETECT module monitors the GTX to detect hard errors.
//                It accumulates the Soft errors according to the leaky bucket
//                algorithm described in the Aurora Specification to detect Hard
//                errors.  All errors are reported to the Global Logic Interface.
//

`timescale 1 ns / 1 ps

module aurora_8b10b_v5_3_ERR_DETECT_4BYTE
(
    // Lane Init SM Interface
    ENABLE_ERR_DETECT,

    HARD_ERR_RESET,


    // Global Logic Interface
    SOFT_ERR,
    HARD_ERR,


    // MGT Interface
    RX_BUF_ERR,
    RX_DISP_ERR,
    RX_NOT_IN_TABLE,
    TX_BUF_ERR,
    RX_REALIGN,

    // System Interface
    USER_CLK

);

`define DLY #1

//***********************************Port Declarations*******************************

    // Lane Init SM Interface
    input           ENABLE_ERR_DETECT;

    output          HARD_ERR_RESET;


    // Global Logic Interface
    output  [0:1]   SOFT_ERR;
    output          HARD_ERR;


    // MGT Interface
    input           RX_BUF_ERR;
    input   [3:0]   RX_DISP_ERR;
    input   [3:0]   RX_NOT_IN_TABLE;
    input           TX_BUF_ERR;
    input           RX_REALIGN;

    // System Interface
    input           USER_CLK;

//**************************External Register Declarations****************************

    reg     [0:1]   SOFT_ERR;
    reg             hard_err_gt;


    reg     [2:0]   err_cnt_r;
    reg     [3:0]   good_cnt_r;

    // FSM registers
    reg             start_r;     
    reg             cnt_soft_err_r;
    reg             cnt_good_code_r;    

    wire            next_start_c;  
    wire            next_soft_err_c;
    wire            next_good_code_c;

//**************************Internal Register Declarations****************************

    reg     [0:3]   soft_err_r;
    reg             hard_err_frm_soft_err;
    
//*********************************Main Body of Code**********************************


    //____________________________ Error Processing _________________________________



    // Detect Soft Errors.  The lane is divided into 2 2-byte sublanes for this purpose.
    always @(posedge USER_CLK)
    begin
        soft_err_r[0] <=  `DLY   ENABLE_ERR_DETECT & (RX_DISP_ERR[3]|RX_NOT_IN_TABLE[3]);
        soft_err_r[1] <=  `DLY   ENABLE_ERR_DETECT & (RX_DISP_ERR[2]|RX_NOT_IN_TABLE[2]);
        soft_err_r[2] <=  `DLY   ENABLE_ERR_DETECT & (RX_DISP_ERR[1]|RX_NOT_IN_TABLE[1]);
        soft_err_r[3] <=  `DLY   ENABLE_ERR_DETECT & (RX_DISP_ERR[0]|RX_NOT_IN_TABLE[0]);
    end


    always @(posedge USER_CLK)
    begin
        // Sublane 0
        SOFT_ERR[0]  <=  `DLY    |soft_err_r[0:1];

        // Sublane 1
        SOFT_ERR[1]  <=  `DLY    |soft_err_r[2:3];
    end
    

    // Detect Hard Errors
    always @(posedge USER_CLK)
        if(ENABLE_ERR_DETECT)
            hard_err_gt  <=  `DLY    (RX_BUF_ERR | TX_BUF_ERR | RX_REALIGN);
        else
            hard_err_gt  <=  `DLY    1'b0;

    assign HARD_ERR        = hard_err_gt || (err_cnt_r[2] && !hard_err_frm_soft_err);
    assign HARD_ERR_RESET  = HARD_ERR;


    always @ (posedge USER_CLK)
      if(!ENABLE_ERR_DETECT)
        hard_err_frm_soft_err  <=  `DLY  1'b0;
      else 
        hard_err_frm_soft_err  <=  `DLY  err_cnt_r[2];


    always @ (posedge USER_CLK)
      if(!ENABLE_ERR_DETECT) 
        begin
          start_r          <=  `DLY  1'b1;
          cnt_soft_err_r   <=  `DLY  1'b0;
	  cnt_good_code_r  <=  `DLY  1'b0;
        end
      else
        begin
          start_r          <=  `DLY  next_start_c;
          cnt_soft_err_r   <=  `DLY  next_soft_err_c;
	  cnt_good_code_r  <=  `DLY  next_good_code_c;
        end  		

  assign  next_start_c      =  start_r && !(|soft_err_r) ||
	                       cnt_good_code_r && !(|soft_err_r) && (&good_cnt_r);	

  assign  next_soft_err_c   =  start_r && |soft_err_r ||
	                       cnt_soft_err_r && |soft_err_r ||
			       cnt_good_code_r && |soft_err_r ; 

  assign  next_good_code_c  =  cnt_good_code_r && !(|soft_err_r) && !(&good_cnt_r) ||
	                       cnt_soft_err_r && !(|soft_err_r) ; 


  always @ (posedge USER_CLK)
    if(!ENABLE_ERR_DETECT)	  
      err_cnt_r  <=  `DLY  3'b000;
    else if(err_cnt_r[2] || (((good_cnt_r==4'b0100) || (good_cnt_r==4'b1000) || (good_cnt_r==4'b1100)) && (cnt_soft_err_r)))
      err_cnt_r  <=  `DLY  err_cnt_r;
    else if((|err_cnt_r) && ((good_cnt_r==4'b0100) || (good_cnt_r==4'b1000) || (good_cnt_r==4'b1100))) 
      err_cnt_r  <=  `DLY  err_cnt_r - 1'b1;
    else if(cnt_soft_err_r)
      err_cnt_r  <=  `DLY  err_cnt_r + 1'b1;

  always @ (posedge USER_CLK)
    if(!ENABLE_ERR_DETECT || cnt_soft_err_r || start_r)	  
      good_cnt_r  <=  `DLY  4'b0000;
    else if(cnt_good_code_r)
      good_cnt_r  <=  `DLY  good_cnt_r + 1'b1;
    else 
      good_cnt_r  <=  `DLY  4'b0000;

endmodule
