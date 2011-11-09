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
//  SYM_GEN
//
//
//  Description: The SYM_GEN module is a symbol generator for 2-byte Aurora Lanes.
//               Its inputs request the transmission of specific symbols, and its
//               outputs drive the GTP interface to fulfil those requests.
//
//               All generation request inputs must be asserted exclusively
//               except for the GEN_K, GEN_R and GEN_A signals from the Global
//               Logic, and the GEN_PAD and TX_PE_DATA_V signals from TX_LL.
//
//               GEN_K, GEN_R and GEN_A can be asserted anytime, but they are
//               ignored when other signals are being asserted.  This allows the
//               idle generator in the Global Logic to run continuosly without
//               feedback, but requires the TX_LL and Lane Init SM modules to
//               be quiescent during Channel Bonding and Verification.
//
//               The GEN_PAD signal is only valid while the TX_PE_DATA_V signal
//               is asserted.  This allows padding to be specified for the LSB of
//               the data transmission.  GEN_PAD must not be asserted when
//               TX_PE_DATA_V is not asserted - this will generate errors.
//
//

`timescale 1 ns / 1 ps

module aurora_8b10b_v5_2_SYM_GEN
(
    // TX_LL Interface
    GEN_SCP,
    GEN_ECP,
    GEN_PAD,
    TX_PE_DATA,
    TX_PE_DATA_V,
    GEN_CC,


    // Global Logic Interface
    GEN_A,
    GEN_K,
    GEN_R,
    GEN_V,


    // Lane Init SM Interface
    GEN_K_FSM,
    GEN_SP_DATA,
    GEN_SPA_DATA,


    // GTP Interface
    TX_CHAR_IS_K,
    TX_DATA,


    // System Interface
    USER_CLK,
    RESET
);
`define DLY #1

//***********************************Port Declarations*******************************


    // TX_LL Interface              // See description for info about GEN_PAD and TX_PE_DATA_V.
    input           GEN_SCP;        // Generate SCP.
    input           GEN_ECP;        // Generate ECP.
    input           GEN_PAD;        // Replace LSB with Pad character.
    input   [0:15]  TX_PE_DATA;     // Data.  Transmitted when TX_PE_DATA_V is asserted.
    input           TX_PE_DATA_V;   // Transmit data.
    input           GEN_CC;         // Generate Clock Correction symbols.


    // Global Logic Interface       // See description for info about GEN_K,GEN_R and GEN_A.
    input           GEN_A;          // Generate A character for MSBYTE
    input   [0:1]   GEN_K;          // Generate K character for selected bytes.
    input   [0:1]   GEN_R;          // Generate R character for selected bytes.
    input   [0:1]   GEN_V;          // Generate Ver data character on selected bytes.


    // Lane Init SM Interface
    input           GEN_K_FSM;      // Generate K character on byte 0.
    input   [0:1]   GEN_SP_DATA;    // Generate SP data character on selected bytes.
    input   [0:1]   GEN_SPA_DATA;   // Generate SPA data character on selected bytes.


    // GTP Interface
    output  [1:0]   TX_CHAR_IS_K;   // Transmit TX_DATA as a control character.
    output  [15:0]  TX_DATA;        // Data to GTP for transmission to channel partner.


    // System Interface
    input           USER_CLK;       // Clock for all non-GTP Aurora Logic.
    input           RESET;          // RESET signal to drive TX_CHAR_IS_K to known value 


//**************************External Register Declarations****************************

    reg     [15:0]  TX_DATA;
    reg     [1:0]   TX_CHAR_IS_K;


//**************************Internal Register Declarations****************************

    // Slack registers.  Allow slack for routing delay and automatic retiming.
    reg             gen_scp_r;
    reg             gen_ecp_r;
    reg             gen_pad_r;
    reg     [0:15]  tx_pe_data_r;
    reg             tx_pe_data_v_r;
    reg             gen_cc_r;
    reg             gen_a_r;
    reg     [0:1]   gen_k_r;
    reg     [0:1]   gen_r_r;
    reg     [0:1]   gen_v_r;
    reg             gen_k_fsm_r;
    reg     [0:1]   gen_sp_data_r;
    reg     [0:1]   gen_spa_data_r;


//*********************************Wire Declarations**********************************

    wire    [0:1]   idle_c;

//*********************************Main Body of Code**********************************


    // Register all inputs with the slack registers.
    always @(posedge USER_CLK)
    begin
        gen_scp_r       <=  `DLY    GEN_SCP;
        gen_ecp_r       <=  `DLY    GEN_ECP;
        gen_pad_r       <=  `DLY    GEN_PAD;
        tx_pe_data_r    <=  `DLY    TX_PE_DATA;
        tx_pe_data_v_r  <=  `DLY    TX_PE_DATA_V;
        gen_cc_r        <=  `DLY    GEN_CC;
        gen_a_r         <=  `DLY    GEN_A;
        gen_k_r         <=  `DLY    GEN_K;
        gen_r_r         <=  `DLY    GEN_R;
        gen_v_r         <=  `DLY    GEN_V;
        gen_k_fsm_r     <=  `DLY    GEN_K_FSM;
        gen_sp_data_r   <=  `DLY    GEN_SP_DATA;
        gen_spa_data_r  <=  `DLY    GEN_SPA_DATA;
    end


    // When none of the msb non_idle inputs are asserted, allow idle characters.
    assign  idle_c[0]   =   !(  gen_scp_r           |
                                gen_ecp_r           |
                                tx_pe_data_v_r      |
                                gen_cc_r            |
                                gen_k_fsm_r         |
                                gen_sp_data_r[0]    |
                                gen_spa_data_r[0]   |
                                gen_v_r[0]
                            );



    // Generate data for MSB.  Note that all inputs must be asserted exclusively, except
    // for the GEN_A, GEN_K and GEN_R inputs which are ignored when other characters
    // are asserted.
    always @ (posedge USER_CLK)
    begin
        if(gen_scp_r)               TX_DATA[15:8] <= `DLY  8'h5c;             // K28.2(SCP)
        if(gen_ecp_r)               TX_DATA[15:8] <= `DLY  8'hfd;             // K29.7(ECP)
        if(tx_pe_data_v_r)          TX_DATA[15:8] <= `DLY  tx_pe_data_r[0:7]; // DATA
        if(gen_cc_r)                TX_DATA[15:8] <= `DLY  8'hf7;             // K23.7(CC)
        if(idle_c[0] & gen_a_r)     TX_DATA[15:8] <= `DLY  8'h7c;             // K28.3(A)
        if(idle_c[0] & gen_k_r[0])  TX_DATA[15:8] <= `DLY  8'hbc;             // K28.5(K)
        if(idle_c[0] & gen_r_r[0])  TX_DATA[15:8] <= `DLY  8'h1c;             // K28.0(R)
        if(gen_k_fsm_r)             TX_DATA[15:8] <= `DLY  8'hbc;             // K28.5(K)
        if(gen_sp_data_r[0])        TX_DATA[15:8] <= `DLY  8'h4a;             // D10.2(SP data)
        if(gen_spa_data_r[0])       TX_DATA[15:8] <= `DLY  8'h2c;             // D12.1(SPA data)
        if(gen_v_r[0])              TX_DATA[15:8] <= `DLY  8'he8;             // D8.7(Ver data)
    end



    // Generate control signal for MSB.
    always @(posedge USER_CLK)
    begin
      if(RESET)
        TX_CHAR_IS_K[1] <=  `DLY  1'b0;
      else
        TX_CHAR_IS_K[1] <=  `DLY    !(  tx_pe_data_v_r      |
                                        gen_sp_data_r[0]    |
                                        gen_spa_data_r[0]   |
                                        gen_v_r[0]
                                    );
      end



    // When none of the msb non_idle inputs are asserted, allow idle characters.  Note that
    // because gen_pad is only valid with the data valid signal, we only look at the data
    // valid signal.
    assign  idle_c[1]   =   !(  gen_scp_r           |
                                gen_ecp_r           |
                                tx_pe_data_v_r      |
                                gen_cc_r            |
                                gen_sp_data_r[1]    |
                                gen_spa_data_r[1]   |
                                gen_v_r[1]
                            );



    // Generate data for LSB. Note that all inputs must be asserted exclusively except for
    // the GEN_PAD signal and the GEN_K and GEN_R set. GEN_PAD can be asserted
    // at the same time as TX_DATA_VALID.  This will override TX_DATA and replace the
    // lsb user data with a PAD character.  The GEN_K and GEN_R inputs are ignored
    // if any other input is asserted.
    always @ (posedge USER_CLK)
    begin
        if(gen_scp_r)                   TX_DATA[7:0]    <= `DLY  8'hfb;              // K27.7(SCP)
        if(gen_ecp_r)                   TX_DATA[7:0]    <= `DLY  8'hfe;              // K30.7(ECP)
        if(tx_pe_data_v_r & gen_pad_r)  TX_DATA[7:0]    <= `DLY  8'h9c;              // K28.4(PAD)
        if(tx_pe_data_v_r & !gen_pad_r) TX_DATA[7:0]    <= `DLY  tx_pe_data_r[8:15]; // DATA
        if(gen_cc_r)                    TX_DATA[7:0]    <= `DLY  8'hf7;              // K23.7(CC)
        if(idle_c[1] & gen_k_r[1])      TX_DATA[7:0]    <= `DLY  8'hbc;              // K28.5(K)
        if(idle_c[1] & gen_r_r[1])      TX_DATA[7:0]    <= `DLY  8'h1c;              // K28.0(R)
        if(gen_sp_data_r[1])            TX_DATA[7:0]    <= `DLY  8'h4a;              // D10.2(SP data)
        if(gen_spa_data_r[1])           TX_DATA[7:0]    <= `DLY  8'h2c;              // D12.1(SPA data)
        if(gen_v_r[1])                  TX_DATA[7:0]    <= `DLY  8'he8;              // D8.7(Ver data)
    end



    // Generate control signal for LSB.
    always @(posedge USER_CLK)
    begin
      if(RESET)
        TX_CHAR_IS_K[0] <= `DLY 1'b0;
      else 
        TX_CHAR_IS_K[0] <= `DLY !(  tx_pe_data_v_r & !gen_pad_r      |
                                    gen_sp_data_r[1]    |
                                    gen_spa_data_r[1]   |
                                    gen_v_r[1]
                                );
      end

endmodule
