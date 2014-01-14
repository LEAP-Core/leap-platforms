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
    input        [0:1]      CH_BOND_DONE;
    output                  EN_CHAN_SYNC;
    output                  CHAN_BOND_RESET;
    
    // Aurora Lane Interface
    output                  GEN_NA_IDLES;
    output                  RESET_LANES;
    input        [0:1]      RX_NA_IDLES;
    input        [0:1]      RX_CC;
    input        [0:1]      REMOTE_READY;
    input        [0:1]      RX_CB;
    input        [0:1]      RX_IDLES;
    
    // System Interface
    input                   USER_CLK;
    input                   RESET;
    input        [0:1]      LANE_UP;
    output                  CHANNEL_UP;

    // Channel Init State Machine Interface
    input                   RESET_CHANNEL;


//***************************External Register Declarations***************************

    reg                       CHANNEL_UP;
    reg                       CHAN_BOND_RESET;

//***************************Internal Register Declarations***************************
    // State registers
    reg                      wait_for_lane_up_r;
    reg                      channel_bond_r;
    reg                      bond_passed_r;
    reg                      rx_cb_r;
    reg                      chan_bond_timeout_r;
    reg           [0:2]      watchdog_count_r;
    reg                      wait_for_remote_r;
    reg                      ready_r;
    reg                      any_na_idles_r;
    reg                      any_idles_r;
    reg                      rx_cc_r;
    reg                      remote_ready_r;

//*********************************Wire Declarations**********************************

    wire                     reset_lanes_c;
    wire                     all_ch_bond_done_c;
    wire                     en_chan_sync_dlyd_i;
    wire                     chan_bond_timeout_i;
    wire                     en_chan_sync_done_i;
    wire                     bonding_watchdog_done_i;
    wire                     chan_bond_reset_i;
    wire                     reset_watchdog;
    wire                     channel_up_c;

    // Next state signals
    wire                     next_channel_bond_c;
    wire                     next_wait_for_remote_c;
    wire                     next_ready_c;
                

//*********************************Main Body of Code**********************************


    //________________Main state machine for bonding and verification________________


    // State registers
    always @(posedge USER_CLK)
    begin 
        if(RESET|RESET_CHANNEL|!(|LANE_UP)|chan_bond_reset_i)
        begin
            wait_for_lane_up_r <=  `DLY    1'b1;
            channel_bond_r     <=  `DLY    1'b0;
            wait_for_remote_r  <=  `DLY    1'b0;
            ready_r            <=  `DLY    1'b0;
        end
        else
        begin
            wait_for_lane_up_r <=  `DLY    1'b0;
            channel_bond_r     <=  `DLY    next_channel_bond_c;
            wait_for_remote_r  <=  `DLY    next_wait_for_remote_c;
            ready_r            <=  `DLY    next_ready_c;
        end
    end


    // Next state logic
    assign  next_channel_bond_c      =   (wait_for_lane_up_r) |
                                         (channel_bond_r & !bond_passed_r) |
                                         (ready_r & !bond_passed_r) |
                                         (wait_for_remote_r & !bond_passed_r) |
                                         (!bond_passed_r);

    assign  next_wait_for_remote_c   =   (channel_bond_r & bond_passed_r )|
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

    //_____________________________Channel Bonding_______________________________

    FD #(
        .INIT(1'b0)
    ) en_chan_sync_flop_i (
        .D(channel_bond_r),
        .C(USER_CLK),
        .Q(EN_CHAN_SYNC)
    );

    // This logic takes care of channel bonding timeout. The idea here is to reset the
    // channel bonding logic if bonding does not happen within the timeout period. We take 64
    // cycles as time out for channel bonding reset.    
    SRLC32E #(
            .INIT(32'h00000000)
    ) SRLC32E_inst_0 (
            .Q(en_chan_sync_dlyd_i),// SRL data output
            .Q31(),                 // SRL cascade output pin
            .A(5'b11111),           // 5-bit shift depth select input 
            .CE(1'b1),              // Clock enable input
            .CLK(USER_CLK),         // Clock input
            .D(channel_bond_r)      // SRL data input
    );

    SRLC32E #(
            .INIT(32'h00000000)
    ) SRLC32E_inst_1 (
            .Q(en_chan_sync_done_i),// SRL data output
            .Q31(),                 // SRL cascade output pin
            .A(5'b11111),           // 5-bit shift depth select input 
            .CE(1'b1),              // Clock enable input
            .CLK(USER_CLK),         // Clock input
            .D(en_chan_sync_dlyd_i) // SRL data input
    );

    // Generate the watchdog done signal
    assign chan_bond_timeout_i = en_chan_sync_done_i & !bond_passed_r;

    always @(posedge USER_CLK)
    begin
         chan_bond_timeout_r  <=  `DLY    chan_bond_timeout_i;
    end

    assign reset_watchdog = chan_bond_timeout_i & !chan_bond_timeout_r;

    always @(posedge USER_CLK)
    begin
         if(RESET)
                watchdog_count_r <=  `DLY 3'b000;
         else if(reset_watchdog) 
                watchdog_count_r <=  `DLY 3'b111;
         else if(watchdog_count_r>0) 
                watchdog_count_r <=  `DLY watchdog_count_r-1;
    end

    assign chan_bond_reset_i       = (watchdog_count_r>0)?1'b1:1'b0;

    always @(posedge USER_CLK)
    begin
         CHAN_BOND_RESET  <=  `DLY    chan_bond_reset_i;
    end

    // This wide AND gate collects the CH_BOND_DONE signals.  We register the
    // output of the AND gate.  Note that register is a one shot that is reset
    // only when the state changes.
    assign all_ch_bond_done_c = &(CH_BOND_DONE);
                                
    always @(posedge USER_CLK)
    begin
        if( all_ch_bond_done_c )
                bond_passed_r  <=  `DLY    1'b1;
        else
                bond_passed_r  <=  `DLY    1'b0;
    end

    //_____________________________Idle Pattern Generation and Reception_______________________________

    // Generate NA idles when until channel bonding is complete
    assign GEN_NA_IDLES   = wait_for_lane_up_r|channel_bond_r ;

    // The NA IDles will be coming in on all the lanes. OR them to decide when to go into and out of
    // wait_for_remote_r state. This OR gate may need to be pipelined for greater number of lanes
    always @(posedge USER_CLK)
    begin
        rx_cc_r        <= `DLY |( RX_CC);
        remote_ready_r <= `DLY |( REMOTE_READY);
        rx_cb_r        <= `DLY &( RX_CB);        
        any_na_idles_r <= `DLY |( RX_NA_IDLES);
        any_idles_r    <= `DLY |( RX_IDLES);
    end

endmodule
