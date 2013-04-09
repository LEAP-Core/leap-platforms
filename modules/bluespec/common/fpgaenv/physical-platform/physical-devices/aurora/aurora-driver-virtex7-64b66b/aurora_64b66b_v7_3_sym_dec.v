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
//  SYM_DEC
//
//
//  Description: The SYM_DEC module is a symbol decoder for the 8-byte
//               Aurora Lane.  Its inputs are the raw data from the MGT.
//               It decodes all of the Aurora control symbols.  Its outputs 
//               are the signals indicating the arrival of specific
//               control characters.
//
//               * Supports Virtex 5
//
///////////////////////////////////////////////////////////////////////////////


`timescale 1 ns / 10 ps

module aurora_64b66b_v7_3_SYM_DEC
(
    // TX Streaming Interface

    RX_PE_DATA,
    RX_PE_DATA_V,




    //Error Detect Interface
    ILLEGAL_BTF,

    // Lane Init SM Interface
    LANE_UP,
    
    RX_NA_IDLE,
    RX_CC,
    REMOTE_READY,
    RX_CB,
    RX_IDLE,

    // MGT Interface
    RX_RUN_DISP,
    RX_CHAR_IS_K,
    RX_DATA,
    RXDATAVALID_IN,

    // System Interface
    USER_CLK
);
`define DLY #1

//***********************************Parameter Declarations**************************

    parameter           CC_BTF_SA0              =   16'h7890; 
    parameter           CC_BTF_SA1              =   16'h7880; 
    parameter           NA_IDLE_BTF             =   16'h7830; 
    parameter           CHANNEL_BOND_BTF        =   16'h7840; 
    parameter           IDLE_BTF                =   16'h7810; 
//***********************************Port Declarations*******************************

    // TX Streaming Interface
    output    [0:63]     RX_PE_DATA;     // Word aligned data from channel partner
    output               RX_PE_DATA_V;    // Data is valid data and not a control character


    // Lane Init SM Interface
    input               LANE_UP;
   
    output              RX_NA_IDLE;       // Received Not-Aligned Idle.
    output              RX_CC;            // Received CC.
    output              REMOTE_READY;     // Remote Ready.
    output              RX_CB;            // Received CB.
    output              RX_IDLE;          // Received Aligned Idle.
    
    //Error Detect Interface
    output              ILLEGAL_BTF;      // Received Symbol's BTF is invalid.

    // MGT Interface
    input               RX_RUN_DISP;      // bit 1 of sync header.
    input               RX_CHAR_IS_K;     // bit 0 of sync header.
    input    [63:0]     RX_DATA;         // Data to MGT for transmission to channel partner.
    input               RXDATAVALID_IN;   // Data valid wrt Gearbox pause

    // System Interface
    input               USER_CLK;         // Clock for all non-MGT Aurora Logic.

//**************************External Register Declarations****************************

    reg      [0:63]     RX_PE_DATA;    

    reg                 RX_PE_DATA_V;  


    reg      [0:1]      sync_header_r;  




    reg                 RX_NA_IDLE;
    reg                 RX_IDLE;
    reg                 RX_CC;
    reg                 REMOTE_READY;
    reg                 RX_CB;
    reg                 ILLEGAL_BTF;

    reg                 rxdatavalid_r;

//**************************External Wire Declarations****************************

    wire     [0:1]      sync_header_c;  

//*********************************Main Body of Code**********************************

    always @(posedge USER_CLK)
    begin
        rxdatavalid_r   <=  `DLY  RXDATAVALID_IN;
    end

    // All decodes are pipelined to keep the number of logic levels to a minimum.
    assign   sync_header_c  =  {RX_RUN_DISP,RX_CHAR_IS_K};

    always @(posedge USER_CLK)
      if(RXDATAVALID_IN)
        sync_header_r  <=  `DLY  sync_header_c;



    always @(posedge USER_CLK)
      if(sync_header_c  ==2'b01  & RXDATAVALID_IN)
              RX_PE_DATA_V   <= `DLY  2'b1;
      else
              RX_PE_DATA_V   <= `DLY  2'b0;
 

    // Decode Non-Aligned Idle Block Code
    always @(posedge USER_CLK)
        RX_NA_IDLE     <= `DLY   ((sync_header_c == 2'b10) & (RX_DATA[63:48] == NA_IDLE_BTF) & RXDATAVALID_IN);  

    //For Idle Decoding, RXDATAVALID_IN is not considered because it is invalid data is anyway going to  be ignored
    always @(posedge USER_CLK)
        RX_IDLE        <=  `DLY  ((sync_header_c == 2'b10) & (RX_DATA[63:48] == IDLE_BTF));

    always @(posedge USER_CLK)
        RX_CC          <= `DLY   ((sync_header_c == 2'b10) & (RX_DATA[63:48] == CC_BTF_SA0) & RXDATAVALID_IN) | ((sync_header_c == 2'b10) & (RX_DATA[63:48] == CC_BTF_SA1) & RXDATAVALID_IN);  

    always @(posedge USER_CLK)
        RX_CB          <= `DLY   ((sync_header_c == 2'b10) & (RX_DATA[63:48] == CHANNEL_BOND_BTF) & RXDATAVALID_IN);  

    always @(posedge USER_CLK)
        ILLEGAL_BTF  <= LANE_UP & (sync_header_c==2'b10)& RXDATAVALID_IN & 
                        !((RX_DATA[63:48] == NA_IDLE_BTF) || 
                        (RX_DATA[63:48] == IDLE_BTF) || 
                        (RX_DATA[63:48] == CHANNEL_BOND_BTF) || 
                        (RX_DATA[63:48] == CC_BTF_SA0) || 
                        (RX_DATA[63:48] == CC_BTF_SA1) 
 
                        
                        );


    always @(posedge USER_CLK)
        REMOTE_READY  <= LANE_UP & (((sync_header_c==2'b10)& RXDATAVALID_IN &
                        ((RX_DATA[63:48] == IDLE_BTF))));


    //---------------------------Decoder Control Symbols------------------------------------
    always @(posedge USER_CLK)
    begin
        if((sync_header_c == 2'b01) & RXDATAVALID_IN)
            RX_PE_DATA     <=  `DLY {RX_DATA[7:0], RX_DATA[15:8], RX_DATA[23:16], RX_DATA[31:24], RX_DATA[39:32], RX_DATA[47:40],RX_DATA[55:48],RX_DATA[63:56]};
    end

   
   

   
   
   
endmodule
