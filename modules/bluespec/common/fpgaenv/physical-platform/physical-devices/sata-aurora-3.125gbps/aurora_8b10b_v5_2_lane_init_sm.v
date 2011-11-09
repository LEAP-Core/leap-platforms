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
//  LANE_INIT_SM
//
//
//  Description: This logic manages the initialization of the GTP in 2-byte mode.
//               It consists of a small state machine, a set of counters for
//               tracking the progress of initializtion and detecting problems,
//               and some additional support logic.
//

`timescale 1 ns / 1 ps

module aurora_8b10b_v5_2_LANE_INIT_SM
(
   RESET_DONE, //Fix for CR519148
   RESET_LISM,

    // GTP Interface
    RX_NOT_IN_TABLE,
    RX_DISP_ERR,
    RX_CHAR_IS_COMMA,
    RX_REALIGN,

    RX_RESET,
    TX_RESET,
    RX_POLARITY,


    // Comma Detect Phase Alignment Interface
    ENA_COMMA_ALIGN,


    // Symbol Generator Interface
    GEN_K,
    GEN_SP_DATA,
    GEN_SPA_DATA,


    // Symbol Decoder Interface
    RX_SP,
    RX_SPA,
    RX_NEG,

    DO_WORD_ALIGN,


    // Error Detection Logic Interface
    ENABLE_ERR_DETECT,
    HARD_ERR_RESET,


    // Global Logic Interface
    LANE_UP,


    // System Interface
    USER_CLK,
    RESET

);
`define DLY #1


//***********************************Port Declarations*******************************
    (* ASYNC_REG = "TRUE" *)
    input              RESET_DONE;//Fix for CR519148
    (* ASYNC_REG = "TRUE" *)
    input              RESET_LISM;

    // GTP Interface
    input   [1:0]   RX_NOT_IN_TABLE;     // GTP received invalid 10b code.
    input   [1:0]   RX_DISP_ERR;         // GTP received 10b code w/ wrong disparity.
    input   [1:0]   RX_CHAR_IS_COMMA;    // GTP received a Comma.
    input           RX_REALIGN;          // GTP had to change alignment due to new comma.

    output          RX_RESET;            // Reset the RX side of the GTP.
    output          TX_RESET;            // Reset the TX side of the GTP.
    output          RX_POLARITY;         // Sets polarity used to interpet rx'ed symbols.


    // Comma Detect Phase Alignment Interface
    output          ENA_COMMA_ALIGN;     // Turn on SERDES Alignment in GTP.


    // Symbol Generator Interface
    output          GEN_K;               // Generate a comma on the MSByte of the Lane.
    output  [0:1]   GEN_SP_DATA;         // Generate SP data symbol on selected byte(s).
    output  [0:1]   GEN_SPA_DATA;        // Generate SPA data symbol on selected byte(s).


    // Symbol Decoder Interface
    input           RX_SP;               // Lane rx'ed SP sequence w/ + or - data.
    input           RX_SPA;              // Lane rx'ed SPA sequence.
    input           RX_NEG;              // Lane rx'ed inverted SP or SPA data.

    output          DO_WORD_ALIGN;       // Enable word alignment.


    // Error Detection Logic Interface
    input           HARD_ERR_RESET;    // Reset lane due to hard error.

    output          ENABLE_ERR_DETECT; // Turn on Soft Error detection.



    // Global Logic Interface
    output          LANE_UP;             // Lane is initialized.


    // System Interface
    input           USER_CLK;            // Clock for all non-GTP Aurora logic.
    input           RESET;               // Reset Aurora Lane.


//**************************External Register Declarations****************************

    reg             ENABLE_ERR_DETECT;
    reg   [1:0]     RX_CHAR_IS_COMMA_R;    // Register Comma.


//**************************Internal Register Declarations****************************



    reg             odd_word_r;
    reg     [0:7]   counter1_r;
    reg     [0:15]  counter2_r;
    reg     [0:3]   counter3_r;
    reg     [0:15]  counter4_r;
    reg     [0:15]  counter5_r;
    reg             rx_polarity_r;
    reg             prev_char_was_comma_r;
    reg             comma_over_two_cycles_r;
    reg             prev_count_128d_done_r;
    reg             do_watchdog_count_r;
    reg             reset_count_r;



    // FSM states, encoded for one-hot implementation
    reg             begin_r;        //Begin initialization
    reg             rst_r;          //Reset GTPs
    reg             align_r;        //Align SERDES
    reg             realign_r;      //Verify no spurious realignment
    reg             polarity_r;     //Verify polarity of rx'ed symbols
    reg             ack_r;          //Ack initialization with partner
    reg             ready_r;        //Lane ready for Bonding/Verification



//*********************************Wire Declarations**********************************

    wire            send_sp_c;
    wire            send_spa_r;
    wire            count_8d_done_r;
    wire            count_32d_done_r;
    wire            count_128d_done_r;
    wire            symbol_err_c;
    wire            txack_16d_done_r;
    wire            rxack_4d_done_r;
    wire            sp_polarity_c;
    wire            inc_count_c;
    wire            change_in_state_c;
    wire            watchdog_done_r;
    wire            remote_reset_watchdog_done_r;

    wire            next_begin_c;
    wire            next_rst_c;
    wire            next_align_c;
    wire            next_realign_c;
    wire            next_polarity_c;
    wire            next_ack_c;
    wire            next_ready_c;

    reg            reset_lism_r1;
    reg            reset_lism_r2;
    reg            rx_reset_r; //Fix for CR519148
    reg            tx_reset_r; //Fix for CR519148


//*********************************Main Body of Code**********************************

always @(posedge USER_CLK  or posedge RESET_LISM)
        begin
        if (RESET_LISM)
          begin
          reset_lism_r1 <= 1'b1;
          reset_lism_r2 <= 1'b1;
          end
        else
         begin
         reset_lism_r1 <= RESET_LISM ;
         reset_lism_r2 <= reset_lism_r1 ;
         end
        end

    //________________Main state machine for managing initialization________________

    // State registers
    always @(posedge USER_CLK)
        if(reset_lism_r2 | RESET | HARD_ERR_RESET)
            {begin_r,rst_r,align_r,realign_r,polarity_r,ack_r,ready_r}  <=  `DLY    7'b1000000;
        else
        begin
            begin_r     <=  `DLY    next_begin_c;
            rst_r       <=  `DLY    next_rst_c;
            align_r     <=  `DLY    next_align_c;
            realign_r   <=  `DLY    next_realign_c;
            polarity_r  <=  `DLY    next_polarity_c;
            ack_r       <=  `DLY    next_ack_c;
            ready_r     <=  `DLY    next_ready_c;
        end



    // Next state logic
    assign  next_begin_c    =   (realign_r & RX_REALIGN)  |
                                (polarity_r & !sp_polarity_c)|
                                (ack_r & watchdog_done_r)|
                                (ready_r & remote_reset_watchdog_done_r);

    assign  next_rst_c      =   begin_r |
                                (rst_r & !count_8d_done_r);



    assign  next_align_c    =   (rst_r & count_8d_done_r)|
                                (align_r & !count_128d_done_r);


    assign  next_realign_c  =   (align_r & count_128d_done_r)|
                                (realign_r & !count_32d_done_r & !RX_REALIGN);

    assign  next_polarity_c =   (realign_r & count_32d_done_r & !RX_REALIGN)|
                                (polarity_r & sp_polarity_c & odd_word_r);


    assign  next_ack_c      =   (polarity_r & sp_polarity_c & !odd_word_r)|
                                (ack_r & (!txack_16d_done_r|!rxack_4d_done_r) & !watchdog_done_r);


    assign  next_ready_c    =   (ack_r & txack_16d_done_r & rxack_4d_done_r & !watchdog_done_r)|
                                (ready_r & !remote_reset_watchdog_done_r);


    // Output Logic

    // Enable comma align when in the ALIGN state.
    assign  ENA_COMMA_ALIGN =   align_r;


    // Hold RX_RESET when in the RST state.
    always @(posedge USER_CLK)
    begin
    if (RESET_DONE)
      rx_reset_r        <=   rst_r; 
    else
      rx_reset_r       <=   1'b0; 
    end

    assign  RX_RESET        =   rx_reset_r;

    // Hold TX_RESET when in the RST state.
    always @(posedge USER_CLK)
    begin
    if (RESET_DONE)
    tx_reset_r        <=   rst_r;
    else
    tx_reset_r       <=   1'b0; 
    end

    assign  TX_RESET        =   tx_reset_r;


    // LANE_UP is asserted when in the READY state.
    FDR lane_up_flop_i
    (
        .D(ready_r),
        .C(USER_CLK),
        .R(RESET),
        .Q(LANE_UP)
    );


    // ENABLE_ERR_DETECT is asserted when in the ACK or READY states.  Asserting
    // it earlier will result in too many false errors.  After it is asserted,
    // higher level modules can respond to Hard Errors by resetting the Aurora Lane.
    // We register the signal before it leaves the lane_init_sm submodule.
    always @(posedge USER_CLK)
        ENABLE_ERR_DETECT <=  `DLY    ack_r | ready_r;



    // The Aurora Lane should transmit SP sequences when not ACKing or Ready.
    assign  send_sp_c   =   !(ack_r | ready_r);



    // The Aurora Lane transmits SPA sequences while in the ACK state.
    assign  send_spa_r  =   ack_r;


    // Do word alignment when in the ALIGN state.
    assign  DO_WORD_ALIGN   =   align_r | ready_r;

    //_______________________Transmission Logic for SP and SPA sequences_______________


    // Select either the even or the odd word of the current sequence for transmission.
    // There is no reset for odd word.  It is initialized when the FPGA is configured.
    // The variable, odd_word_r, is initialized for simulation (See SIGNAL declarations).
    initial
        odd_word_r  =   1'b1;

    always @(posedge USER_CLK)
        odd_word_r  <=  `DLY    ~odd_word_r;


    // Request transmission of the commas needed for the SP and SPA sequences.
    // These commas are sent on the MSByte of the lane on all odd bytes.
    assign  GEN_K           =   odd_word_r & (send_sp_c|send_spa_r);


    // Request transmission of the SP_DATA sequence.
    assign  GEN_SP_DATA[0]  =   !odd_word_r & send_sp_c;
    assign  GEN_SP_DATA[1]  =   send_sp_c;


    // Request transmission of the SPA_DATA sequence.
    assign  GEN_SPA_DATA[0] =   !odd_word_r & send_spa_r;
    assign  GEN_SPA_DATA[1] =   send_spa_r;



    //_________Counter 1, for reset cycles, align cycles and realign cycles____________

    // The initial statement is to ensure that the counter comes up at some value other than X.
    // We have tried different initial values and it does not matter what the value is, as long
    // as it is not X since X breaks the state machine
    initial
        counter1_r = 8'h01;

    //Core of the counter
    always @(posedge USER_CLK)
        if(reset_count_r)           counter1_r   <=  `DLY    8'd1;
        else if(inc_count_c)        counter1_r   <=  `DLY    counter1_r + 8'd1;


    // Assert count_8d_done_r when bit 4 in the register first goes high.
    assign  count_8d_done_r     =   counter1_r[4];


    // Assert count_32d_done_r when bit 2 in the register first goes high.
    assign  count_32d_done_r    =   counter1_r[2];


    // Assert count_128d_done_r when bit 0 in the register first goes high.
    assign  count_128d_done_r   =   counter1_r[0];


    // The counter resets any time the RESET signal is asserted, there is a change in
    // state, there is a symbol error, or commas are not consecutive in the align state.
    always @(posedge USER_CLK)
        reset_count_r <= `DLY  RESET | change_in_state_c | (!rst_r & (symbol_err_c |!comma_over_two_cycles_r));



    // The counter should be reset when entering and leaving the reset state.
    assign  change_in_state_c   =   rst_r != next_rst_c;



    // Symbol error is asserted whenever there is a disparity error or an invalid
    // 10b code.
    assign  symbol_err_c  =   (RX_DISP_ERR != 2'b00) | (RX_NOT_IN_TABLE != 2'b00);

    // Pipeline stage to meet timing
    always @(posedge USER_CLK)
        RX_CHAR_IS_COMMA_R <=  `DLY    RX_CHAR_IS_COMMA;

    // Previous cycle comma is used to check for consecutive commas.
    always @(posedge USER_CLK)
        prev_char_was_comma_r <=  `DLY    (RX_CHAR_IS_COMMA_R[1] | RX_CHAR_IS_COMMA_R[0]);


    // Check to see that commas are consecutive in the align state.
    always @(posedge USER_CLK)
        comma_over_two_cycles_r <= `DLY   (prev_char_was_comma_r ^
                                          (RX_CHAR_IS_COMMA_R[1] | RX_CHAR_IS_COMMA_R[0])) | 
					  !align_r;


    // Increment count is always asserted, except in the ALIGN state when it is asserted
    // only upon the arrival of a comma character.

    assign  inc_count_c =   !align_r | (align_r & (RX_CHAR_IS_COMMA_R[1] | RX_CHAR_IS_COMMA_R[0]));

    //__________________________Counter 2, for counting tx_acks _______________________


    // This counter is implemented as a shift register.  It is constantly shifting.  As a
    // result, when the state machine is not in the ack state, the register clears out.
    // When the state machine goes into the ack state, the count is incremented every
    // cycle.  The txack_16d_done signal goes high and stays high after 16 cycles in the
    // ack state.  The signal deasserts only after it has had enough time for all the ones
    // to clear out after the machine leaves the ack state, but this is tolerable because
    // the machine will spend at least 8 cycles in reset, 256 in ALIGN and 32 in REALIGN.
    //
    // The counter is implemented seperately from the main counter because it is required
    // to stop counting when it reaches the end of its count. Adding this functionality
    // to the main counter is more expensive and more complex than implementing it seperately.

    // Counter Logic
    always @(posedge USER_CLK)
        counter2_r  <=  `DLY    {ack_r,counter2_r[0:14]};



    // The counter is done when bit 15 of the shift register goes high.
    assign txack_16d_done_r = counter2_r[15];



    //__________________________Counter 3, for counting rx_acks _______________________


    // This counter is also implemented as a shift register. It is always shifting when
    // the state machine is not in the ack state to clear it out. When the state machine
    // goes into the ack state, the register shifts only when a SPA is received. When
    // 4 SPAs have been received in the ACK state, the rxack_4d_done_r signal is triggered.
    //
    // This counter is implemented seperately from the main counter because it is required
    // to increment only when ACKs are received, and then hold its count. Adding this
    // functionality to the main counter is more expensive than creating a second counter,
    // and more complex.

    // Counter Logic
    always @(posedge USER_CLK)
        if(RX_SPA|!ack_r)   counter3_r  <=  `DLY    {ack_r,counter3_r[0:2]};



    // The counter is done when bit 3 of the shift register goes high.
    assign rxack_4d_done_r = counter3_r[3];



    //_____________________Counter 4, remote reset watchdog timer __________________


    // Another counter implemented as a shift register.  This counter puts an upper limit on
    // the number of SPs that can be received in the Ready state.  If the number of SPs
    // exceeds the limit, the Aurora Lane resets itself.  The Global logic module will reset
    // all the lanes if this occurs while they are all in the lane ready state (i.e. lane_up
    // is asserted for all.



    // Counter logic
    always @(posedge USER_CLK)
        if(RX_SP|!ready_r)  counter4_r  <=  `DLY    {ready_r,counter4_r[0:14]};



    // The counter is done when bit 15 of the shift register goes high.
    assign remote_reset_watchdog_done_r = counter4_r[15];



    //__________________________Counter 5, internal watchdog timer __________________


    // This counter puts an upper limit on the number of cycles the state machine can
    // spend in the ack state before it gives up and resets.
    //
    // The counter is implemented as a shift register extending counter 1.  The counter
    // clears out in all non-ack cycles by keeping CE asserted.  When it gets into the
    // ack state, CE is asserted only when there is a transition on the most
    // significant bit of counter 1.  This happens every 128 cycles.  We count out 32
    // of these transitions to get a count of approximately 4096 cycles.  The actual
    // number of cycles is less than this because we don't reset counter1, so it starts
    // off about 34 cycles into its count.



    // Counter logic
    always @(posedge USER_CLK)
        if(do_watchdog_count_r|!ack_r)  counter5_r  <=  `DLY    {ack_r,counter5_r[0:14]};



    // Store the count_128d_done_r result from the previous cycle.
    always @(posedge USER_CLK)
        prev_count_128d_done_r  <=  `DLY    count_128d_done_r;



    // Trigger CE only when the previous 128d_done is not the same as the
    // current one, and the current value is high.
    always @(posedge USER_CLK)
        do_watchdog_count_r <=  `DLY    count_128d_done_r & !prev_count_128d_done_r;



    // The counter is done when bit 15 of the shift register goes high.
    assign watchdog_done_r = counter5_r[15];



    //___________________________Polarity Control_____________________________


    // sp_polarity_c, is low if neg symbols received, otherwise high.
    assign  sp_polarity_c   =   !RX_NEG;



    // The Polarity flop drives the polarity setting of the GTP.  We initialize it for the
    // sake of simulation. In hardware, it is initialized after configuration.
    initial
        rx_polarity_r <=  1'b0;

    always @(posedge USER_CLK)
        if(polarity_r & !sp_polarity_c)  rx_polarity_r <=  `DLY    ~rx_polarity_r;



    // Drive the rx_polarity register value on the interface.
    assign  RX_POLARITY =   rx_polarity_r;

endmodule
