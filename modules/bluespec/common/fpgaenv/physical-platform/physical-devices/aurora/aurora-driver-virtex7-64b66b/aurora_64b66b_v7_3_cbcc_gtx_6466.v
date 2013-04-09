///////////////////////////////////////////////////////////////////////////
// Project:  Aurora 64B/66B
// Version:  version 2.1
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

////////////////////////////////////////////////////////////////////////////
//
//  CLOCK_CORRECTION_CHANNEL_BONDING
//
//
//
//  Description: This module is used to detect Clock correction Sequence as
//               defined in Aurora Protocol Standard. If the FIFO is about to 
//               underflow or overflow due to difference in Transmit and local
//               receive clock, clock correction sequences are inserted or deleted
//               If the lanes are skewed, channel bonding logic takes care of 
//               proper data alignment by adjusting the read FIFO pointers
//
/////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/ 10 ps
`define DLY #1
module  aurora_64b66b_v7_3_CLOCK_CORRECTION_CHANNEL_BONDING #
(
   parameter CH_BOND_MAX_SKEW=2'b10 ,
   parameter CH_BOND_MODE=2'b11  
)
(   

  // Write Interface:These signals are wrt RXRECCLK(WR_CLK) of GTX
   GTX_RX_DATA_IN,
   GTX_RX_DATAVALID_IN,
   GTX_RX_HEADER_IN,
   ENCHANSYNC,
   CHAN_BOND_RESET,
   RXLOSSOFSYNC_IN,
     
     
   // Read Interface: Synchronized wrt RXUSRCLK2, FIFO output signals
   CC_RX_DATA_OUT,
   CC_RX_BUF_STATUS_OUT,
   CC_RX_DATAVALID_OUT,
   CC_RX_HEADER_OUT,
   CC_RXLOSSOFSYNC_OUT,

   // CHBONDI and CHBONDO are external signals:for Master and Slave
   CHBONDI,
   CHBONDO,
   
   // Channel Bonding Indication
   RXCHANISALIGNED,
   
   // Reset and Read and Write clock
   RESET,
   WR_ENABLE,
   USER_CLK,
   RD_CLK,
   INIT_CLK,
   LINK_RESET
);


//***************** Parameter Declarations ****************************

    parameter LOW_WATER_MARK    = 450;
    parameter HIGH_WATER_MARK   = 50;
    parameter FIFO_DEPTH_START  = 9'h5;   

    // Match character for CC 
    parameter CC_CHARACTER      = 16'h7880;
    parameter CB_CHARACTER      = 16'h7840;
    parameter IDLE_CHARACTER    = 16'h7810;
    parameter NA_CHARACTER      = 16'h7830;
                
    // Write Interface          
    input   [63:0]    GTX_RX_DATA_IN;
    input             GTX_RX_DATAVALID_IN;
    input   [1:0]     GTX_RX_HEADER_IN;
    input             ENCHANSYNC;
    input             CHAN_BOND_RESET;
    input             RXLOSSOFSYNC_IN;
    
    // Read Interface 
    output  [63:0]    CC_RX_DATA_OUT;
    output  [1:0]     CC_RX_BUF_STATUS_OUT;
    output            CC_RX_DATAVALID_OUT;
    output  [1:0]     CC_RX_HEADER_OUT;
    output  reg       CC_RXLOSSOFSYNC_OUT;
  
    output  reg       RXCHANISALIGNED;
    
    // Master Slave Connection
    input   [4:0]     CHBONDI;
    output  [4:0]     CHBONDO;

    // Clock and Reset 
    input             RESET;
    input             RD_CLK;
    input             INIT_CLK;
    input             WR_ENABLE;
    input             USER_CLK;
    output  [1:0]         LINK_RESET;
 

//********************** External Register Declarations ****************
    reg     [4:0]     CHBONDO;

//********************** Internal Register Declarations ****************

    // Status Interface
    reg                overflow_flag_sync_r;
    reg                overflow_flag_sync_r_r;
    reg     [65:0]     raw_data_r_r;
    reg                do_rd_en;
    reg                do_wr_en;
    reg     [3:0]      en_rd_counter;
    reg                CB_align_ver;
    reg                gtx_rxdatavalid_r;
    reg                rxlossofsync_r;
    reg                rxdatavalid_dlyd1_r;
    reg                CC_detect_pulse_r; 
    reg    [3:0]       cc_state_count_r;
    reg                do_cc_insert_r;
    reg                CC_detect_dlyd1;
    reg                CB_detect_dlyd1;
    reg                rxlossofsync_r1;
    reg                rxlossofsync_r2 = 1'b0;
    reg                reset_cbcc_comb_rdclk;
    reg                cc_rxlossofsync_r1;
    reg                cc_rxlossofsync_r2;
    reg                cc_rxlossofsync_r3;
    reg                reset_cbcc_comb_r;
(* ASYNC_REG = " {TRUE}" *) (* shift_extract = "{no}" *) reg  reset_cbcc_comb_rdclk_r1;
    reg                reset_cbcc_comb_rdclk_r2;
    reg                cc_datavalid_mask_r;
    reg    [19:0]      count_for_reset_r;
    reg                hold_reg; 
    reg    [3:0]       wait_for_wr_en = 4'h0;

//********************** Wire Declarations *****************************

    // Internal wire declaration
    wire               valid_btf_detect_dlyd1; 
    wire               hold_rd_ptr_i;
    wire   [8:0]       write_ptr_c;
    wire               i_am_slave;
    wire               i_am_master;
    wire               buffer_too_empty_c; 
    wire               buffer_too_full_c; 
    wire               CB_detect;
    wire               CC_detect; 
    wire    [66:0]     raw_data_c; 
    wire               do_cc_delete_c; 
    wire               do_cc_insert_i;
    wire               do_cc_insert_c; 
    wire    [71:0]     fifo_din_i;
    wire    [71:0]     fifo_dout_i;
    wire               rd_err_c;
    wire               wr_err_c;
    wire               rxchanisaligned_i;
    wire   [1:0]       ch_bond_c;
    wire   [1:0]       ch_bond_m;
    wire   [4:0]       ch_bond_comb;
    wire               underflow_flag_c;
    wire               overflow_flag_c;
    wire               reset_cbcc_comb;
    wire   [66:0]      raw_data_r;
    wire               hold_rd_en_init;
    wire               en_rd_init;
    wire               enchansync_dlyd_i;  
    reg               fifo_reset_int;
  (* KEEP = "TRUE" *)  wire               fifo_reset_i;
    reg                fifo_reset_i2;
    wire               fifo_reset_comb;
    wire               CC_detect_pulse_i; 
    wire               cc_rden_mask; 
    wire               cc_detect_mask; 
    wire               cc_datavalid_mask;
    wire               cc_datavalid_mask_i;
    wire               CC_detect_dlyd5;
    wire               buffer_too_empty_muxed;
    wire               rxdatavalid_i;
    wire               rxdatavalid_lookahead_i;
    wire               rxdatavalid_lookahead_rdfifo;
    wire               rd_en_datavalid;
    wire               do_rd_en_i;
    wire               CB_enb_stop;
    wire               CB_flag_direct;
    wire               CB_flag_dlyd1;
    wire               CC_enb_stop;
    wire               CC_flag_direct;
    wire               CC_flag_dlyd1;
    wire               valid_btf_detect;
    wire               valid_btf_detect_pulse_i;
    wire               link_reset_0;
    wire               link_reset_1;
 
    genvar             i;

    //################################# Beginning of Code ##############################
    // reset_cbcc_comb is used as an asynchronous reset in the design 
    // Double synchronize RXLOSSOFSYNC_IN to account for domain crossing.
    // Even if both clocks are from same source, double synchronization
    // is employed to account for the routing delay
    always @(posedge USER_CLK)
    if(WR_ENABLE)
    begin
        rxlossofsync_r1  <= `DLY  RXLOSSOFSYNC_IN;
        rxlossofsync_r2  <= `DLY  rxlossofsync_r1;
    end

    assign reset_cbcc_comb = RESET | !rxlossofsync_r2;

    always @(posedge RD_CLK or posedge reset_cbcc_comb)
    begin
        if(reset_cbcc_comb)
         reset_cbcc_comb_rdclk  <= `DLY  1'b1;
        else
         reset_cbcc_comb_rdclk  <= `DLY  reset_cbcc_comb;
    end

    always @(posedge RD_CLK)
     begin
       reset_cbcc_comb_r  <= `DLY  reset_cbcc_comb_rdclk;
     end

    initial
    begin
         reset_cbcc_comb_rdclk_r2 =1'b1;
    end

    always @(posedge RD_CLK or posedge reset_cbcc_comb_r)
    begin
       if(reset_cbcc_comb_r)
       begin
         reset_cbcc_comb_rdclk_r1 <= `DLY 1'b1;
         reset_cbcc_comb_rdclk_r2 <= `DLY 1'b1;
       end 
       else
       begin
         reset_cbcc_comb_rdclk_r1 <= `DLY  reset_cbcc_comb_r;
         reset_cbcc_comb_rdclk_r2 <= `DLY  reset_cbcc_comb_rdclk_r1;
       end 
    end 

    // Assign alignment status based on Master/Slave's CB detection and subsequent wait for MAX_SKEW
    always @(posedge RD_CLK or posedge reset_cbcc_comb_rdclk_r2)
    begin
          if(reset_cbcc_comb_rdclk_r2)  
                     RXCHANISALIGNED <= `DLY 1'b0;
          else if(CH_BOND_MODE==2'b00) 
                     RXCHANISALIGNED <= `DLY 1'b1;
          else                     
                     RXCHANISALIGNED <= `DLY rxchanisaligned_i;
    end
    
    // Assign Master/Slave based on CH_BOND_MODE
    assign i_am_slave  =(CH_BOND_MODE[1]) ;
    assign i_am_master =(CH_BOND_MODE[0]);

    // The following logic will ensure that the RDEN will be held until it crosses the almost empty mark.
 
    always @(posedge RD_CLK or posedge reset_cbcc_comb_rdclk_r2)
    begin
         if (reset_cbcc_comb_rdclk_r2)
                     en_rd_counter   <= `DLY 4'b0;
         else if(en_rd_counter <FIFO_DEPTH_START+3)
                     en_rd_counter   <= `DLY en_rd_counter+1;
         else
                     en_rd_counter   <= `DLY en_rd_counter;
    end

    assign   hold_rd_en_init = (en_rd_counter>=0 & en_rd_counter< FIFO_DEPTH_START)?1'b1:1'b0;

    assign   en_rd_init      = (en_rd_counter>=FIFO_DEPTH_START & en_rd_counter< FIFO_DEPTH_START+3)?1'b1:1'b0;

    SRLC32E #(
            .INIT(32'h00000000)
    ) SRLC32E_inst_0 (
            .Q(enchansync_dlyd_i),  // SRL data output
            .Q31(),                 // SRL cascade output pin
            .A(5'b10000),           // 5-bit shift depth select input
            .CE(1'b1),              // Clock enable input
            .CLK(RD_CLK),           // Clock input
            .D(ENCHANSYNC)          // SRL data input
    );

    // Detect CB or CC from the incoming data
    assign CC_detect   =   ((GTX_RX_HEADER_IN == 2'b10) && (GTX_RX_DATA_IN[63:48] == CC_CHARACTER) && GTX_RX_DATAVALID_IN); 

    always @(posedge USER_CLK or posedge reset_cbcc_comb)
    begin
          if(reset_cbcc_comb)
                     CC_detect_dlyd1   <= `DLY 1'b0;
          else if(WR_ENABLE)
                     CC_detect_dlyd1   <= `DLY CC_detect;
    end

    assign CC_detect_pulse_i = CC_detect && (!CC_detect_dlyd1); 

    always @(posedge USER_CLK)
    begin
                  if(WR_ENABLE)   CC_detect_pulse_r     <= `DLY CC_detect_pulse_i;
    end

    // Reset link if CC is not detected after 10000 clk cycles
    // This circuit for auto-recovery of the link during hot-plug scenario
    // Incoming control blocks are decoded to detmine CC reception
    // valid_btf_detect is used as the reset for the count_for_reset_r, which would reset the link
    // after the defined time. link_reset_0 is used to reset the GT & link_reset_1 is used to reset
    // the Aurora lanes inorder to reinitialize the lanes

    assign valid_btf_detect   =   ((GTX_RX_HEADER_IN == 2'b10) && 
                                  ((GTX_RX_DATA_IN[63:48] == CC_CHARACTER) || 
                                   (GTX_RX_DATA_IN[63:48] == CB_CHARACTER) || 
                                   (GTX_RX_DATA_IN[63:48] == IDLE_CHARACTER) || 
                                   (GTX_RX_DATA_IN[63:48] == NA_CHARACTER)) && GTX_RX_DATAVALID_IN); 


    assign valid_btf_detect_pulse_i = valid_btf_detect && (!valid_btf_detect_dlyd1); 


   // Clock domain crossing from USER_CLK to INIT_CLK
    aurora_64b66b_v7_3_cir_fifo valid_btf_cir_fifo_i
    (
      .reset      (RESET),
      .wr_clk     (USER_CLK),
      .din        (valid_btf_detect),
      .we         (WR_ENABLE),
      .rd_clk     (INIT_CLK),
      .dout       (valid_btf_detect_dlyd1)
    );

    always @(posedge INIT_CLK or posedge reset_cbcc_comb)
    begin
       if(reset_cbcc_comb)
               count_for_reset_r <= `DLY 20'h0;
       else if(valid_btf_detect_pulse_i)
	       count_for_reset_r <= `DLY 20'h0;
         else
              count_for_reset_r <= `DLY count_for_reset_r + 1'b1;
    end

      assign link_reset_0 =( (count_for_reset_r > 20'hFFFF0) & (count_for_reset_r < 20'hFFFFA) ) ? 1'b1 : 1'b0;
      assign link_reset_1 = 1'b0;


      assign LINK_RESET = {link_reset_1,link_reset_0};
    
    assign CB_detect   =   ((GTX_RX_HEADER_IN == 2'b10) && (GTX_RX_DATA_IN[63:48] == CB_CHARACTER) && GTX_RX_DATAVALID_IN); 

    // Register CB_detect signal to take care of the data valid arrival during 
    // ENCHANSYNC enabled
    always @(posedge USER_CLK or posedge reset_cbcc_comb)
    begin
          if(reset_cbcc_comb)
                     CB_detect_dlyd1   <= `DLY 1'b0;
          else if(WR_ENABLE)
                     CB_detect_dlyd1   <= `DLY CB_detect;
    end

    // Double synchronize RXLOSSOFSYNC_IN to account for the clock crossing
    always @(posedge RD_CLK) 
    begin
         cc_rxlossofsync_r1     <= `DLY  RXLOSSOFSYNC_IN;
         cc_rxlossofsync_r2     <= `DLY  cc_rxlossofsync_r1;
         cc_rxlossofsync_r3     <= `DLY  !cc_rxlossofsync_r2;
    end 

    always @(posedge RD_CLK) 
    begin
         if(RESET)
         CC_RXLOSSOFSYNC_OUT    <= `DLY 1'b1;
         else
         CC_RXLOSSOFSYNC_OUT    <= `DLY  cc_rxlossofsync_r3;
    end 

    // _________________ Logic for writing to the elastic buffer ______________
    // Combine incoming data into a raw data signal
    // RXLOSSOFSYNC_IN  and GTX_RX_DATAVALID_IN are generated wrt RXRECCLK. Move these siignals to RD_CLK domain through FIFO
    assign raw_data_c   =   {   
                                GTX_RX_DATAVALID_IN,
                                GTX_RX_HEADER_IN,
                                GTX_RX_DATA_IN
                             }; 
    
    // Caputure all raw data in a register
    // Delay write data to FIFO by 6 cycles allowing Channel Bonding logic 
    // to decide whether to wait on CB or not  
    generate for(i=0;i<67;i=i+1) begin:srlc32e

    SRLC32E #(
            .INIT(32'h00000000)
    ) SRLC32E_inst_1 (
            .Q(raw_data_r[i]),  // SRL data output
            .Q31(),             // SRL cascade output pin
            .A(5'b00101),       // 5-bit shift depth select input 
            .CE(WR_ENABLE),          // Clock enable input
            .CLK(USER_CLK),       // Clock input
            .D(raw_data_c[i])   // SRL data input
    );                          // End of SRLC32E_inst instantiation
    end endgenerate

    // Pipeline the raw data to give the cc matching logic enough time to search for CC 
    // sequences
    always @(posedge USER_CLK or posedge reset_cbcc_comb)
    begin
        if(reset_cbcc_comb)              
                     raw_data_r_r    <=  `DLY    66'd0;
        else if(WR_ENABLE)                  
                     raw_data_r_r    <=  `DLY    raw_data_r[65:0];
    end

    // Delay CC_detect_dlyd1 by six cycles to account datapath delay 
    SRLC32E #(
            .INIT(32'h00000000)
    ) SRLC32E_inst_2 (
            .Q(CC_detect_dlyd5),    // SRL data output
            .Q31(),                 // SRL cascade output pin
            .A(5'b00101),           // 5-bit shift depth select input 
            .CE(WR_ENABLE),              // Clock enable input
            .CLK(USER_CLK),           // Clock input
            .D(CC_detect_dlyd1)     // SRL data input
    );

    // Indicate that the current pipelined is a cc character for deletion
    assign do_cc_delete_c = (buffer_too_full_c) &&
                            (CC_detect_dlyd5)   &&
                            (!wr_err_c); 

    always @(posedge RD_CLK) 
    begin
          cc_datavalid_mask_r   <= `DLY  cc_datavalid_mask_i;
    end
     
    assign  rd_en_datavalid = i_am_slave?CHBONDI[2]:i_am_master?rxdatavalid_dlyd1_r:rxdatavalid_i;

    assign  cc_datavalid_mask = i_am_slave?CHBONDI[4]:i_am_master?cc_datavalid_mask_r :cc_datavalid_mask_i;

    assign  rxdatavalid_i                 = fifo_dout_i[68];

    assign  rxdatavalid_lookahead_rdfifo  = fifo_dout_i[66];

    // Delay GTX_RX_DATAVALID_IN by two cycles
    // to enable CB logic wait on CB
    SRLC32E #(
            .INIT(32'h00000000)
    ) SRLC32E_inst_4 (
            .Q(rxdatavalid_lookahead_i), // SRL data output
            .Q31(),                      // SRL cascade output pin
            .A(5'b00010),                // 5-bit shift depth select input
            .CE(WR_ENABLE),                   // Clock enable input
            .CLK(USER_CLK),                // Clock input
            .D(GTX_RX_DATAVALID_IN)      // SRL data input
    );
 
    initial
            do_rd_en =1'b0;

    always @(posedge RD_CLK or posedge reset_cbcc_comb_rdclk_r2)
    begin
        if(reset_cbcc_comb_rdclk_r2)
                     do_rd_en        <=  `DLY    1'b0;
        else if(hold_rd_en_init)
                     do_rd_en        <=  `DLY    1'b0;
        else if(en_rd_init)
                     do_rd_en        <=  `DLY    1'b1;
        else if(!rd_en_datavalid & !ENCHANSYNC & !cc_datavalid_mask)
                     do_rd_en        <=  `DLY    1'b0;
        else
                     do_rd_en        <=  `DLY    1'b1;
    end

    // do_rd_en is generated based on the CC reception and Channel Bonding read stop request 
    generate

    if((CH_BOND_MODE==2'b01)||(CH_BOND_MODE==2'b10))
    begin:master_slave
    assign do_rd_en_i = do_rd_en & !hold_rd_ptr_i & !do_cc_insert_c;
    end
    else
    begin:no_cb
    assign do_rd_en_i = do_rd_en & !do_cc_insert_c;
    end
    endgenerate

    initial
           do_wr_en =1'b0;


    always @(posedge USER_CLK or posedge reset_cbcc_comb)
    begin
        if(reset_cbcc_comb)
                     do_wr_en         <=  `DLY    1'b0;
        else if(WR_ENABLE)
          begin
          if(overflow_flag_c)
                     do_wr_en         <=  `DLY    1'b0;
          else if(do_cc_delete_c)
                     do_wr_en         <=  `DLY    1'b0;
          else if(!raw_data_r[66])
                     do_wr_en         <=  `DLY    1'b0;
          else
                     do_wr_en         <=  `DLY    1'b1;
          end
        else if(!WR_ENABLE) 
                     do_wr_en         <=  `DLY    1'b0;
    end

    assign CC_flag_direct = fifo_dout_i[71];
    assign CC_flag_dlyd1  = fifo_dout_i[67];

    assign CC_enb_stop=(CC_flag_direct & !rxdatavalid_i)?CC_flag_direct:CC_flag_dlyd1;

    // This CC counter counts for 3 cycles and RDEN gets deasserted for these many cycles
    always @(posedge RD_CLK or posedge reset_cbcc_comb_rdclk_r2)  
    begin
          if(reset_cbcc_comb_rdclk_r2)
                     cc_state_count_r  <=  `DLY 4'b0000;
          else if(CC_enb_stop & !cc_detect_mask & gtx_rxdatavalid_r)
                     cc_state_count_r  <=  `DLY 4'b1111;
          else if((cc_state_count_r== 14) && !rxdatavalid_lookahead_rdfifo)
                     cc_state_count_r  <=  `DLY cc_state_count_r-2;
          else if((cc_state_count_r== 15) && !gtx_rxdatavalid_r)
                     cc_state_count_r  <=  `DLY cc_state_count_r;
          else if((cc_state_count_r> 10) && rxdatavalid_i)
                     cc_state_count_r  <=  `DLY cc_state_count_r-1;
          else if((cc_state_count_r> 10) && !rxdatavalid_i)
                     cc_state_count_r  <=  `DLY cc_state_count_r-2;
          else if(cc_state_count_r> 1)
                     cc_state_count_r  <=  `DLY cc_state_count_r-1; 
          else
                     cc_state_count_r  <=  `DLY 4'b0000;  
    end

    assign cc_rden_mask      = ((cc_state_count_r > 5) && (cc_state_count_r < 9))?1'b1:1'b0;

    assign cc_detect_mask    = (cc_state_count_r > 1)?1'b1:1'b0;

    assign cc_datavalid_mask_i = ((cc_state_count_r <= 15) && (cc_state_count_r >2))?1'b1:1'b0;

    // Register buffer_too_empty_c in case it is master
    always @(posedge RD_CLK)
    begin
           do_cc_insert_r <=  `DLY do_cc_insert_i;
    end


    // Insert cc whenever the module is in buffer_too_empty mode and a cc character
    // is detected
    assign  do_cc_insert_i  =   (buffer_too_empty_c ) && 
                                (cc_rden_mask) &&
                                (!rd_err_c);  

    assign do_cc_insert_c   = i_am_master?do_cc_insert_r:i_am_slave?CHBONDI[3]:do_cc_insert_i;

    // __________________________ Memory Blocks _________________________________
    // Fetch CB_detect and CC_detect ahead of data to decide stoppage over CB 
    assign  fifo_din_i[65:0]     =   raw_data_r_r;
    assign  fifo_din_i[66]       =   rxdatavalid_lookahead_i;
    assign  fifo_din_i[67]       =   CC_detect_pulse_r;
    assign  fifo_din_i[68]       =   raw_data_r[66];
    assign  fifo_din_i[69]       =   CB_detect_dlyd1;
    assign  fifo_din_i[70]       =   CB_detect;  
    assign  fifo_din_i[71]       =   CC_detect_pulse_i;  

    always @(posedge RD_CLK)
    begin
          rxdatavalid_dlyd1_r <= `DLY rxdatavalid_i;
    end
  
    assign CB_flag_direct  = fifo_dout_i[70];
    assign CB_flag_dlyd1   = fifo_dout_i[69];

    // Muxing logic is required because data valid in between ENCHASYNC can mess 
    // timing. We adopt a strategy of sending both CB_detect and registered CB_detect
    // so that in case one is missed, other can substitute 
    assign CB_enb_stop=(CB_flag_direct & !rxdatavalid_i)?CB_flag_direct:CB_flag_dlyd1;

    always @(posedge RD_CLK or posedge reset_cbcc_comb_rdclk_r2)
    begin
        if(reset_cbcc_comb_rdclk_r2)
           CB_align_ver  <= `DLY  1'b0;
        else
           CB_align_ver  <= `DLY  (fifo_dout_i[63:48]==CB_CHARACTER) && (fifo_dout_i[65:64]==2'b10);
    end
    
    // Instantiate a FIFO    
    FIFO36_72 #(
                  .DO_REG(1'b1),                                          // Set for asynchronous FIFO operation
                  .EN_SYN("FALSE"),                                       // When FALSE, keeps RDCLK & WRCLK separate
                  .ALMOST_FULL_OFFSET(LOW_WATER_MARK),                    // sets the difference between full 
                  .ALMOST_EMPTY_OFFSET(HIGH_WATER_MARK)        
               ) data_fifo (
                  .ALMOSTEMPTY(buffer_too_empty_c ),
                  .ALMOSTFULL(buffer_too_full_c),
                  .DBITERR(),
                  .DO(fifo_dout_i[63:0]),
                  .DOP(fifo_dout_i[71:64]),
                  .ECCPARITY(),
                  .EMPTY(underflow_flag_c),
                  .FULL(overflow_flag_c),
                  .RDCOUNT(),
                  .RDERR(rd_err_c),
                  .SBITERR(),
                  .WRCOUNT(write_ptr_c),
                  .WRERR(wr_err_c),
                  .DI(fifo_din_i[63:0]),
                  .DIP(fifo_din_i[71:64]),
                  .RDCLK(RD_CLK),               
                  .RDEN(do_rd_en_i),
                  .RST(reset_cbcc_comb),
                  .WRCLK(USER_CLK),                         
                  .WREN(do_wr_en)
               );

    always @(posedge RD_CLK or posedge reset_cbcc_comb_rdclk_r2)
    begin
          if(reset_cbcc_comb_rdclk_r2)  
          begin
	             overflow_flag_sync_r   <=  `DLY 1'b0;
	             overflow_flag_sync_r_r <=  `DLY 1'b0;
          end  
          else
          begin
                     overflow_flag_sync_r   <=  `DLY overflow_flag_c;
                     overflow_flag_sync_r_r <=  `DLY overflow_flag_sync_r;
          end      
    end     
      
    always @(posedge RD_CLK or posedge reset_cbcc_comb_rdclk_r2)
    begin
          if(reset_cbcc_comb_rdclk_r2)
                     gtx_rxdatavalid_r           <= `DLY 1'b0; 
          else if(!rd_en_datavalid & !ENCHANSYNC & !cc_datavalid_mask)
                     gtx_rxdatavalid_r           <= `DLY 1'b0;
          else
                     gtx_rxdatavalid_r           <= `DLY 1'b1;
    end

    // Set status indicators
    assign  CC_RX_BUF_STATUS_OUT[1] =  wr_err_c;          // ERROR status signal for Aurora's init module  
    assign  CC_RX_BUF_STATUS_OUT[0] =  rd_err_c;          // ERROR status signal for Aurora's init module
    assign  CC_RX_DATAVALID_OUT     =  gtx_rxdatavalid_r; // RD_CLK RX_DATAVALID_OUT
    assign  CC_RX_HEADER_OUT        =  ( hold_reg == 0 ) ? 2'b00 : fifo_dout_i[65:64];// RD_CLK SH 
    assign  CC_RX_DATA_OUT          =  ( hold_reg == 0 ) ? 'h0 : fifo_dout_i[63:0]; // RD_CLK RX_DATA

    always @(posedge RD_CLK)
    begin
       if(RESET)
         hold_reg <= `DLY 1'b0;
       else if (do_rd_en)
         hold_reg <= `DLY 1'b1;
    end
    
    assign  ch_bond_comb            =  {cc_datavalid_mask_i, do_cc_insert_i, rxdatavalid_i, ch_bond_m};

    always @(posedge RD_CLK or posedge reset_cbcc_comb_rdclk_r2)
    begin
         if(reset_cbcc_comb_rdclk_r2)
                     CHBONDO       <=  `DLY 5'b0;
         else if(CH_BOND_MODE==2'b00)
                     CHBONDO       <=  `DLY 5'b0;
         else
                     CHBONDO       <=  `DLY i_am_slave ? 5'b0 : ch_bond_comb;
    end
 
    assign ch_bond_c = i_am_slave?CHBONDI[1:0]:2'b0; 

    //------------------------------channel bonding---------------------------------------            
    generate
    if(CH_BOND_MODE==2'b01)
    begin:master
                aurora_64b66b_v7_3_CH_BOND_MASTER #(
                                  .CHAN_BOND_MODE (CH_BOND_MODE),
                                  .CHAN_BOND_MAX_SKEW(CH_BOND_MAX_SKEW)
                                ) 
                master          (
                                  .enchansync  (enchansync_dlyd_i),  
                                  .CB_enb_stop (CB_enb_stop),
                                  .CB_enb_stop_dlyd (CB_flag_dlyd1),
                                  .CB_align_ver(CB_align_ver),
                                  .ch_bond_m   (ch_bond_m),
                                  .rxchanisaligned(rxchanisaligned_i),       
                                  .hold_rd_ptr (hold_rd_ptr_i),
                                  .rd_clk      (RD_CLK),
                                  .overflow_rd_clk(overflow_flag_sync_r_r),
                                  .underflow_rd_clk(underflow_flag_c),
                                  .reset       (reset_cbcc_comb_rdclk_r2),
                                  .rxdatavalid(rxdatavalid_i), 
                                  .rxdatavalid_lookahead(rxdatavalid_lookahead_rdfifo) 
                                 ); 

    end          
    else if(CH_BOND_MODE==2'b10)
    begin:slave
               aurora_64b66b_v7_3_CH_BOND_SLAVE  #(
                                 .CHAN_BOND_MODE(CH_BOND_MODE),
                                 .CHAN_BOND_MAX_SKEW(CH_BOND_MAX_SKEW)

                               )
               slave           (
                                 .ch_bond_c  (ch_bond_c),
                                 .rd_clk     (RD_CLK),
                                 .CB_enb_stop (CB_enb_stop),
                                 .CB_enb_stop_dlyd (CB_flag_dlyd1),
                                 .CB_align_ver(CB_align_ver),
                                 .enchansync(enchansync_dlyd_i), 
                                 .underflow_rd_clk(underflow_flag_c),
                                 .hold_rd_ptr(hold_rd_ptr_i),
                                 .rxchanisaligned(rxchanisaligned_i),
                                 .reset       (reset_cbcc_comb_rdclk_r2),
                                 .overflow_rd_clk(overflow_flag_sync_r_r),
                                 .rxdatavalid(rxdatavalid_i),
                                 .rxdatavalid_lookahead(rxdatavalid_lookahead_rdfifo)
                               );
    end
    endgenerate

endmodule



//################################# Module for mater GTX .these send signals to slaves through 'ch_bond_m'############################

module aurora_64b66b_v7_3_CH_BOND_MASTER #
(
  parameter CHAN_BOND_MODE=2'b01,
  parameter CHAN_BOND_MAX_SKEW=2'b10
)  
(
  enchansync,  
  CB_enb_stop,
  CB_enb_stop_dlyd,
  CB_align_ver,
  ch_bond_m,
  rxchanisaligned,
  underflow_rd_clk,
  hold_rd_ptr,
  rd_clk,
  overflow_rd_clk,
  reset,
  rxdatavalid,
  rxdatavalid_lookahead
);

    input enchansync;
    input CB_enb_stop;
    input CB_enb_stop_dlyd;
    input CB_align_ver;
    input rd_clk;
    input reset;
    input overflow_rd_clk;
    input underflow_rd_clk;
    input rxdatavalid;
    input rxdatavalid_lookahead;

    output [1:0]ch_bond_m;
    output hold_rd_ptr;
    output rxchanisaligned;

    reg rxchanisaligned;
    reg hold_rd_ptr; 
    reg alignment_done_r; 
    reg [2:0]count_maxskew_load;
    reg [2:0]cb_rxdatavalid_cnt;
 
    wire CB_enb_stop_dlyd5; 

    // Assign read pointer control based on channel bond mode and enchansync and channel bond detect
    assign i_am_master= CHAN_BOND_MODE[0];

    // Master is always aligned when it detects CB
    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                     rxchanisaligned <=  `DLY 1'b0;
          else if(overflow_rd_clk)
                     rxchanisaligned <=  `DLY 1'b0;
          else if(underflow_rd_clk)  
                     rxchanisaligned <=  `DLY 1'b0;
          else 
                     rxchanisaligned <=  `DLY 1'b1;
    end

    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                     alignment_done_r   <=  `DLY 1'b0;
          else if (count_maxskew_load ==CHAN_BOND_MAX_SKEW+2)
                     alignment_done_r   <=  `DLY 1'b1;
          else if(!enchansync)
                     alignment_done_r   <=  `DLY 1'b0;
    end

    // Delay CB_enb_stop signal by 5 cycles to account for delayed CB data 
    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                  cb_rxdatavalid_cnt <=  `DLY 3'b000;
          else if(CB_enb_stop & !rxdatavalid_lookahead & enchansync)
                  cb_rxdatavalid_cnt <=  `DLY 3'b110;
          else if(CB_enb_stop_dlyd & !rxdatavalid & enchansync)
                  cb_rxdatavalid_cnt <=  `DLY 3'b110;
          else if(CB_enb_stop & enchansync)
                  cb_rxdatavalid_cnt <=  `DLY 3'b111;
          else if((cb_rxdatavalid_cnt==7) && !rxdatavalid_lookahead)
                  cb_rxdatavalid_cnt <=  `DLY cb_rxdatavalid_cnt - 2;
          else if((cb_rxdatavalid_cnt>1) && rxdatavalid)
                  cb_rxdatavalid_cnt <=  `DLY cb_rxdatavalid_cnt - 1;
          else if((cb_rxdatavalid_cnt>4) && !rxdatavalid)
                  cb_rxdatavalid_cnt <=  `DLY cb_rxdatavalid_cnt - 2;
          else if((cb_rxdatavalid_cnt==4) && !rxdatavalid)
                  cb_rxdatavalid_cnt <=  `DLY cb_rxdatavalid_cnt - 1;
          else    
                  cb_rxdatavalid_cnt <=  `DLY 3'b000;
    end

    assign CB_enb_stop_dlyd5 = (cb_rxdatavalid_cnt==3)?1'b1:1'b0;

    // Master will wait for MAX_SKEW cycles in CB state allowing all slaves to get into sync. 
    // Slave's stoppage is dictated by master through master_align_done port 
    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                     count_maxskew_load <=  `DLY 3'b0;
          else if(CB_enb_stop_dlyd5 & enchansync & !alignment_done_r)
                     count_maxskew_load <=  `DLY CHAN_BOND_MAX_SKEW+2 ;
          else if(count_maxskew_load>0)
                     count_maxskew_load <=  `DLY count_maxskew_load -1;
          else
                     count_maxskew_load <=  `DLY 3'b0;
    end

    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                    hold_rd_ptr        <=  `DLY 1'b0;
          else if(CB_enb_stop_dlyd5 & enchansync & !alignment_done_r)
                    hold_rd_ptr        <=  `DLY 1'b1;
          else if(count_maxskew_load<=CHAN_BOND_MAX_SKEW+2 & count_maxskew_load>0)
                    hold_rd_ptr        <=  `DLY 1'b1;
          else
                    hold_rd_ptr        <=  `DLY 1'b0;
    end

    // Generate channel bonding stop enabler for slave. This accounts for one cycle latency in CHBONDO 
    // pipelining. This muxing logic indicates when slave's read pointer should stop  
    assign master_align_done = (count_maxskew_load==CHAN_BOND_MAX_SKEW)?1'b1:1'b0;

    // master_detect_cb is used for alignent verification after channel bonding
    assign master_detect_cb = CB_align_ver & !enchansync;

    // ch_bond_m decode:
    // Bit field             Inference
    // [1:0] ch_bond_m
    // 0   0                 No operation
    // 0   1                 Master detect CB:used for alignment verification
    // 1   0                 Read FIFO CB: Master
    // 1   1                 Master alignment is done
    // Based on the decoded value, slave will compare its CB_detect signal. Master will send the alignment opearation indicator 
    // to let slave know when to stop the operation. Master CB_detect will act as alignment verifier
    // Qualify CB_enb_stop wrt enchansync signal
    // finally send ch_bond_m status to slave 
    assign CB_enb_stop_i = CB_enb_stop & enchansync & !alignment_done_r;

    assign ch_bond_m = master_align_done?2'b11:master_detect_cb?2'b01:CB_enb_stop_i?2'b10:2'b00;

endmodule


//########################################Module for slave GTX .Master sends aligned status through CHBONDI port######################################


module aurora_64b66b_v7_3_CH_BOND_SLAVE #
(
  parameter CHAN_BOND_MODE =2'b10,
  parameter CHAN_BOND_MAX_SKEW=2'b10
)  
(
  ch_bond_c,
  rd_clk,
  CB_enb_stop,
  CB_enb_stop_dlyd,
  CB_align_ver,
  enchansync,
  hold_rd_ptr,
  rxchanisaligned,
  reset,
  overflow_rd_clk,
  underflow_rd_clk,
  rxdatavalid, 
  rxdatavalid_lookahead 
);
  
  
  
    input [1:0]ch_bond_c;
    input CB_enb_stop;
    input CB_enb_stop_dlyd;
    input CB_align_ver;
    input enchansync;
    input rd_clk;
    input reset;
    input overflow_rd_clk;
    input underflow_rd_clk;
    input rxdatavalid;
    input rxdatavalid_lookahead;

    output rxchanisaligned;
    output hold_rd_ptr;

    reg  rxchanisaligned;
    reg  hold_rd_ptr;

    wire master_cb_detect;
    wire master_cb_stagger;
    wire master_cb_av;
    wire CB_enb_stop_dlyd5;
    wire enb_load_stagger;
    wire master_ack_wait;

    reg  master_stop_prev_cb_r;
    reg  master_stop_next_cb_r;
    reg  slave_stop_cb_r;
    reg  CB_av_s_r;
    reg  [1:0]master_ack_cnt;
    reg  [2:0]cb_rxdatavalid_cnt;

    // Decode the ch_bond_c bus
    // [1:0]   ch_bond_c
    // 0   0   No op
    // 0   1   Master CB detect used for alignment verification
    // 1   0   Master CB for Enabling load  in slave
    // 1   1   Master CB alignement done 
    assign master_cb_detect  = (ch_bond_c==2'b01)?1'b1:1'b0;
    assign master_cb_stagger = (ch_bond_c==2'b11)?1'b1:1'b0;
    assign master_cb_av      = (ch_bond_c==2'b10)?1'b1:1'b0;

    // Register the CB detect of Slave. Since Master's chbondo is pipelined, 
    // comparison is done only after registering
    // CB_enb_stop is registered to check for Alignment Verification. 
    // Once channel is bonded, CB on read side of the FIFO should 
    // come simultaneously.  
    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                   CB_av_s_r <=  `DLY 1'b0;
          else
                   CB_av_s_r <=  `DLY (CB_align_ver & !enchansync);
    end

    // rxchanisaligned is assigned when
    // --Asserted when Channel is bonded wrt Master
    // --Deasserted when CBs don't match after bonding
    // --Deasserted when underflow or overflow
    always@(posedge rd_clk or posedge reset)
    begin
          if(reset)
                   rxchanisaligned <=  `DLY 1'b0;
          else if(underflow_rd_clk)
                   rxchanisaligned <=  `DLY 1'b0;
          else if(hold_rd_ptr)
                   rxchanisaligned <=  `DLY 1'b1;
          else if(master_cb_detect & !CB_av_s_r)
                   rxchanisaligned <=  `DLY 1'b0;
    end

    // Hold_rd_ptr will disable write to FIFO.Slave should deassert this signal 
    // synchrounously with Master. This is ensured by Master's wait window
    always@(posedge rd_clk or posedge reset)
    begin
          if(reset)
                   hold_rd_ptr     <=  `DLY 1'b0;
          else if(CB_enb_stop_dlyd5 & (master_stop_prev_cb_r | master_stop_next_cb_r) & enchansync)
                   hold_rd_ptr     <=  `DLY 1'b1;
          else if(enb_load_stagger)
                   hold_rd_ptr     <=  `DLY 1'b1;
          else
                   hold_rd_ptr     <=  `DLY 1'b0; 
    end

    // Delay CB_enb_stop signal by 5 cycles to account for delayed CB data 
    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                  cb_rxdatavalid_cnt <=  `DLY 3'b000;
          else if(CB_enb_stop & !rxdatavalid_lookahead)
                  cb_rxdatavalid_cnt <=  `DLY 3'b110;
          else if(CB_enb_stop_dlyd & !rxdatavalid & enchansync)
                  cb_rxdatavalid_cnt <=  `DLY 3'b110;
          else if(CB_enb_stop)
                  cb_rxdatavalid_cnt <=  `DLY 3'b111;
          else if((cb_rxdatavalid_cnt==7) && !rxdatavalid_lookahead)
                  cb_rxdatavalid_cnt <=  `DLY cb_rxdatavalid_cnt - 2;
          else if((cb_rxdatavalid_cnt>1) && rxdatavalid)
                  cb_rxdatavalid_cnt <=  `DLY cb_rxdatavalid_cnt - 1;
          else if((cb_rxdatavalid_cnt>4) && !rxdatavalid) 
                  cb_rxdatavalid_cnt <=  `DLY cb_rxdatavalid_cnt - 2;
          else if((cb_rxdatavalid_cnt==4) && !rxdatavalid) 
                  cb_rxdatavalid_cnt <=  `DLY cb_rxdatavalid_cnt - 1;
          else 
                  cb_rxdatavalid_cnt <=  `DLY 3'b000;
    end 

    assign CB_enb_stop_dlyd5 = (cb_rxdatavalid_cnt==3)?1'b1:1'b0;

    // Following sequential logic accounts for Master detecting channel
    // bonding sequence before slave
    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                   master_stop_prev_cb_r <=  `DLY 1'b0;
          else if(master_cb_av & enchansync)
                   master_stop_prev_cb_r <=  `DLY 1'b1;
          else if(master_cb_stagger)
                   master_stop_prev_cb_r <=  `DLY 1'b0;
    end

    // This portion of sequential logic accounts for channel bonding sequence
    // in Master appearing after slave's sequence. 
    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                   master_stop_next_cb_r <=  `DLY 1'b0;
          else if(master_cb_av & master_ack_wait & enchansync)
                   master_stop_next_cb_r <=  `DLY 1'b1;
          else if(master_cb_stagger)
                   master_stop_next_cb_r <=  `DLY 1'b0;
    end
                     
    // Increment a counter whenever CB is detected in slave
    // This counter is implemented to ensure Master's indication
    // of CB detection arrives within 3 clocks after slave's CB detection
    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                   master_ack_cnt  <=  `DLY 2'b11;
          else if(CB_enb_stop & enchansync)
                   master_ack_cnt  <=  `DLY 2'b00;
          else if(master_ack_cnt <2'b11)
                   master_ack_cnt  <=  `DLY master_ack_cnt+1;
    end
        
    assign master_ack_wait = ((master_ack_cnt>=0) && (master_ack_cnt <3)) ? 1'b1:1'b0;

    always @(posedge rd_clk or posedge reset)
    begin
          if(reset)
                   slave_stop_cb_r  <=  `DLY 1'b0;
          else if(CB_enb_stop_dlyd5 & (master_stop_prev_cb_r | master_stop_next_cb_r) & enchansync)
                   slave_stop_cb_r  <=  `DLY 1'b1;
          else if(slave_stop_cb_r & (master_stop_prev_cb_r | master_stop_next_cb_r) & enchansync)
                   slave_stop_cb_r  <=  `DLY 1'b1;
          else
                   slave_stop_cb_r  <=  `DLY 1'b0;
    end
    
    // Qualify the enchansync in the Slave Logic also. Once Channel is bonded, 
    // Deassertion of enchansync will stop overflow
    assign enb_load_stagger =  (master_stop_prev_cb_r | master_stop_next_cb_r) & slave_stop_cb_r ;

endmodule


// Circular FIFO for clock domain crossing
module aurora_64b66b_v7_3_cir_fifo (

input wire reset, 
input wire wr_clk, 
input wire din,
input wire we,
input wire rd_clk,
output reg dout
);

reg [7:0] mem;
reg [2:0] wr_ptr;
reg [2:0] rd_ptr;

always @ ( posedge wr_clk  or posedge reset )
begin
   if ( reset )
   begin
      mem    <= `DLY 8'b0;
      wr_ptr <= `DLY 3'b0;
   end
   else if(we)
   begin
      mem[wr_ptr] <= `DLY din;
      wr_ptr <= `DLY wr_ptr + 1'b1;
   end
end

always @ ( posedge rd_clk or posedge reset )
begin
   if ( reset )
   begin
      rd_ptr <= `DLY 3'b100;
      dout   <= `DLY 1'b0;
   end
   else
   begin
      rd_ptr <= `DLY rd_ptr + 1'b1;
      dout   <= `DLY mem[rd_ptr];
   end
end

endmodule


