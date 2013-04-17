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
//  CHANNEL_INIT_SM
//
//
//  Description: the CHANNEL_INIT_SM module is a state machine for managing channel
//               bonding.
//
//               The channel init state machine is reset until the lane up signals
//               of all the lanes that constitute the channel are asserted.  It then
//               requests channel bonding until the lanes have been bonded.Channel 

//               bonding is skipped if there is only one lane in the channel.  
//               If bonding is unsuccessful, the lanes are reset.
//
//               After CHANNEL_UP goes high, the state machine is quiescent, and will
//               reset only if one of the lanes goes down, a hard error is detected, or
//               a general reset is requested.
//
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 10 ps

module aurora_64b66b_v7_3_CHANNEL_INIT_SM
(
    // MGT Interface
    CH_BOND_DONE,
    EN_CHAN_SYNC,
    CHAN_BOND_RESET,

    // Aurora Lane Interface
    GEN_NA_IDLES,
    RESET_LANES,
    RX_NA_IDLES,
    RX_CC,
    REMOTE_READY,
    RX_CB,    
    RX_IDLES,
    
    // System Interface
    USER_CLK,
    RESET,
    LANE_UP,
    CHANNEL_UP,

    // Channel Error Management Interface
    RESET_CHANNEL

);

`define DLY #1



//***********************************Port Declarations*******************************

    // MGT Interface
    input                   CH_BOND_DONE;
    output                  EN_CHAN_SYNC;
    output                  CHAN_BOND_RESET;
    
    // Aurora Lane Interface
    output                  GEN_NA_IDLES;
    output                  RESET_LANES;
    input                   RX_NA_IDLES;
    input                   RX_CC;
    input                   REMOTE_READY;
    input                   RX_CB;
    input                   RX_IDLES;
    
    // System Interface
    input                   USER_CLK;
    input                   RESET;
    input                   LANE_UP;
    output                  CHANNEL_UP;

    // Channel Init State Machine Interface
    input                   RESET_CHANNEL;


//***************************External Register Declarations***************************

    reg                       CHANNEL_UP;

//***************************Internal Register Declarations***************************
    // State registers
    reg                      wait_for_lane_up_r;
    reg                      wait_for_remote_r;
    reg                      ready_r;
    reg                      any_na_idles_r;
    reg                      any_idles_r;
    reg                      rx_cc_r;
    reg                      remote_ready_r;

//*********************************Wire Declarations**********************************

    wire                     reset_lanes_c;
    wire                     channel_up_c;

    // Next state signals
    wire                     next_wait_for_remote_c;
    wire                     next_ready_c;
                

//*********************************Main Body of Code**********************************


    //________________Main state machine for bonding and verification________________


    // State registers
    always @(posedge USER_CLK)
    begin 
        if(RESET|RESET_CHANNEL|!(|LANE_UP))
        begin
            wait_for_lane_up_r <=  `DLY    1'b1;
            wait_for_remote_r  <=  `DLY    1'b0;
            ready_r            <=  `DLY    1'b0;
        end
        else
        begin
            wait_for_lane_up_r <=  `DLY    1'b0;
            wait_for_remote_r  <=  `DLY    next_wait_for_remote_c;
            ready_r            <=  `DLY    next_ready_c;
        end
    end


    // Next state logic
    assign  next_wait_for_remote_c   =   (wait_for_lane_up_r) |
                                         (wait_for_remote_r & (any_na_idles_r | rx_cc_r)) |
                                         (wait_for_remote_r & !remote_ready_r) |
                                         (ready_r & any_na_idles_r);

    assign  next_ready_c             =   (wait_for_remote_r & remote_ready_r)|
                                         (ready_r & !any_na_idles_r) ; 


    // Output Logic Channel up is high as long as the Global Logic is in the ready state.
    assign  channel_up_c             =   ready_r & !next_wait_for_remote_c ;

 
    always @(posedge USER_CLK)
    begin
         if(RESET)
                  CHANNEL_UP   <=  `DLY  1'b0;
         else
                  CHANNEL_UP   <=  `DLY  channel_up_c;
    end



    //__________________________Channel Reset _________________________________

    // Some problems during channel bonding and verification require the lanes to
    // be reset.  When this happens, we assert the Reset Lanes signal, which gets
    // sent to all Aurora Lanes.  When the Aurora Lanes reset, their LANE_UP signals
    // go down.  This causes the Channel Error Detector to assert the Reset Channel
    // signal.
    assign reset_lanes_c = (RESET_CHANNEL & !wait_for_lane_up_r)|
                            RESET;


    FD #(
        .INIT(1'b1)
    ) reset_lanes_flop_0_i (
        .D(reset_lanes_c),
        .C(USER_CLK),
        .Q(RESET_LANES)

    );

    assign EN_CHAN_SYNC     = 1'b0;

    assign CHAN_BOND_RESET  = 1'b0;


    //_____________________________Idle Pattern Generation and Reception_______________________________

    // Generate NA idles when until channel bonding is complete
    assign GEN_NA_IDLES   = wait_for_lane_up_r;

    // The NA IDles will be coming in on all the lanes. OR them to decide when to go into and out of
    // wait_for_remote_r state. This OR gate may need to be pipelined for greater number of lanes
    always @(posedge USER_CLK)
    begin
        rx_cc_r        <= `DLY |( RX_CC);
        remote_ready_r <= `DLY |( REMOTE_READY);
        any_na_idles_r <= `DLY |( RX_NA_IDLES);
        any_idles_r    <= `DLY |( RX_IDLES);
    end

endmodule
