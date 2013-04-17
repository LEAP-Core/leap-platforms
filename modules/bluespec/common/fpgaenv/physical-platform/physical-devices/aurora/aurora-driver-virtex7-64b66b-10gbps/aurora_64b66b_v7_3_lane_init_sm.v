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
//  LANE_INIT_SM
//
//

//  Description: This logic manages the initialization of the GTX for 64B66B.
//               It uses the Block Sync Module to detect whether  
//               alignement has been achieved.
///////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 10 ps

module aurora_64b66b_v7_3_LANE_INIT_SM
(
    // GTX Interface
    RX_LOSSOFSYNC,
    
    RX_RESET,
    TX_RESET,
    RX_POLARITY,

    // Symbol Decoder Interface
    RX_NEG,
    CHECK_POLARITY,

    // Error Detection Logic Interface
    ENABLE_ERR_DETECT,
    HARD_ERR_RESET,


    // Global Logic Interface
    LANE_UP,


    // System Interface
    USER_CLK,
    RESET_LANES,
    RESET

);
`define DLY #1
//***********************************Port Declarations*******************************

    // GTX Interface
    input              RX_LOSSOFSYNC;    // Input from GTX which indicates status of alignment.
    output             RX_RESET ;       // Reset the RX side of the GTX.
    output             TX_RESET;        // Reset the TX side of the GTX.
    output             RX_POLARITY;      // Sets polarity used to interpet rx'ed symbols.


    // Symbol Decoder Interface
    input               RX_NEG;              // Lane rx'ed inverted data.
    output              CHECK_POLARITY;


    // Error Detection Logic Interface
    input                HARD_ERR_RESET;    // Reset lane due to hard error.

    output               ENABLE_ERR_DETECT; // Turn on Soft Error detection.



    // Global Logic Interface
    output               LANE_UP;             // Lane is initialized.


    // System Interface
    input                USER_CLK;            // Clock for all non-GTX Aurora logic.
    input                RESET_LANES;         // Reset Aurora Lane.
    input                RESET;               // Global Lane.


//**************************External Register Declarations****************************

    reg                  ENABLE_ERR_DETECT;


//**************************Internal Register Declarations****************************

    reg      [0:3]      counter1_r;
    reg                 rx_polarity_r;

    // FSM states, encoded for one-hot implementation
    reg                 begin_r;        //Begin initialization
    reg                 rst_r;          //Reset GTXs
    reg                 align_r;        //Align SERDES
    reg                 polarity_r;     //Verify polarity of rx'ed symbols
    reg                 ready_r;        //Lane ready  
    reg                 reset_count_r;
    reg                 rx_neg_r;
    reg                 rx_neg_r2;
    reg                 check_polarity_r;   

//*********************************Wire Declarations**********************************

    wire                count_8d_done_r;

    wire                next_begin_c;
    wire                next_rst_c;
    wire                next_align_c;
    wire                next_polarity_c;
    wire                next_ready_c;
    wire                rx_polarity_dlyd_i;


//*********************************Main Body of Code**********************************



    //________________Main state machine for managing initialization________________


    // State registers
    always @(posedge USER_CLK)
        if(RESET|RESET_LANES|HARD_ERR_RESET)
            {begin_r,rst_r,align_r,polarity_r,ready_r}  <=  `DLY    5'b10000;
        else
        begin
            begin_r     <=  `DLY    next_begin_c;
            rst_r       <=  `DLY    next_rst_c;
            align_r     <=  `DLY    next_align_c;
            polarity_r  <=  `DLY    next_polarity_c;
            ready_r     <=  `DLY    next_ready_c;
        end

    // Next state logic
    assign  next_begin_c    =   (ready_r & RX_LOSSOFSYNC)|
                                (rx_polarity_dlyd_i & rx_neg_r2);


    assign  next_rst_c      =   (begin_r) |
                                (rst_r & !count_8d_done_r);


    assign  next_align_c    =   (rst_r & count_8d_done_r)|
                                (align_r & RX_LOSSOFSYNC);


    assign  next_polarity_c =   (align_r & !RX_LOSSOFSYNC);
                         

    assign  next_ready_c    =   (rx_polarity_dlyd_i & !rx_neg_r2) |
                                (ready_r & !RX_LOSSOFSYNC);

    // Generated a delayed version of polarity_r so that sampling
    // of CHECK_POLARITY is guranteed in RXRECCLK clock domain
    SRLC32E #(
            .INIT(32'h00000000)
    ) SRLC32E_inst_0 (
            .Q(rx_polarity_dlyd_i), // SRL data output
            .Q31(),                 // SRL cascade output pin
            .A(5'b00100),           // 5-bit shift depth select input
            .CE(1'b1),              // Clock enable input
            .CLK(USER_CLK),         // Clock input
            .D(polarity_r)          // SRL data input
    );
    
    // Generate check_polarity_r signal which is an enabler for 
    // polarity control logic
    always @(posedge USER_CLK)
    begin
      if(RESET)
           check_polarity_r  <= `DLY 1'b0;
      else if(polarity_r)
           check_polarity_r  <= `DLY 1'b1;
      else if(rx_polarity_dlyd_i)
           check_polarity_r  <= `DLY 1'b0;
    end

    // Output Logic
    assign RX_RESET           =  rst_r ;

    assign TX_RESET           =  rst_r ;

    assign CHECK_POLARITY     =  check_polarity_r;
    
    // LANE_UP is asserted when in the READY state.
    FDR lane_up_flop_i
    (
        .D(ready_r),
        .C(USER_CLK),
        .R(RESET),
        .Q(LANE_UP)
    );

    // ENABLE_ERR_DETECT is asserted when in the READY states.  Asserting
    // it earlier will result in too many false errors.  After it is asserted,
    // higher level modules can respond to Hard Errors by resetting the Aurora Lane.
    // We register the signal before it leaves the lane_init_sm submodule.
    always @(posedge USER_CLK)
        ENABLE_ERR_DETECT <=  `DLY    ready_r;

    //_________Counter 1, for reset cycles, align cycles and realign cycles____________

    // The initial statement is to ensure that the counter comes up at some value other than X.
    // We have tried different initial values and it does not matter what the value is, as long
    // as it is not X since X breaks the state machine
    initial
        counter1_r = 4'h1;

    // Core of the counter.
    always @(posedge USER_CLK)
        if(reset_count_r)           counter1_r   <=  `DLY    4'd1;
        else                        counter1_r   <=  `DLY    counter1_r + 4'd1;


    // Assert count_8d_done_r when the 2^3 flop in the register first goes high.
    assign  count_8d_done_r     =   counter1_r[0];


    // The counter counts only in the rst_r state for 8 cycles 
    always @(posedge USER_CLK)
      reset_count_r <= `DLY   RESET | !rst_r;


    //___________________________Polarity Control_____________________________


    // Double synchronize the RX_NEG signal since the signal is sampled in RXRECCLK
    // clock domain
    always @(posedge USER_CLK)
    begin
            rx_neg_r   <= `DLY RX_NEG;
            rx_neg_r2  <= `DLY rx_neg_r;
    end

    // The Polarity flop drives the polarity setting of the GTX. We initialize it for the
    // sake of simulation.  We Initialize it after configuration for the hardware version.
    initial
        rx_polarity_r <=  1'b0;

    always @(posedge USER_CLK)
    begin
        if(RESET)
              rx_polarity_r <=  `DLY    1'b0;
        else if(rx_neg_r2)
              rx_polarity_r <=  `DLY    1'b1;
    end

    // Drive the rx_polarity register value on the interface.
    assign  RX_POLARITY =   rx_polarity_r;

endmodule
