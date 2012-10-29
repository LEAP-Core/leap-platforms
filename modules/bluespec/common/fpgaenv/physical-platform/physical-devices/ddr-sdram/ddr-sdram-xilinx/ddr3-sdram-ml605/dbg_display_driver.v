//*****************************************************************************
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
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
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version:
//  \   \         Application: MIG
//  /   /         Filename: led_display_driver
// /___/   /\     Date Last Modified: $Date: 2009/07/23 21:44:35 $
// \   \  /  \    Date Created:
//  \___\/\___\
//
//Device: Virtex-6
//Design Name: DDR3 SDRAM
//Purpose: Drives discrete LEDs and 7-segment LED on ML660 board to indicate
//         current status of core. Discrete LEDs used to indicate status of
//         calibration, whether an error detected. 7-segment LED does the
//         same, but also increments based on number of data word checks
//         successfully executed (you'll need to fine tune this based on your
//         own application to get a reasonable, and observable, increment
//         rate). Assumes the following LED configuration:
//          1. One 7-segment LED available (7 segments + dec pt) (active low)
//          2. 4 discrete LEDs available (active high)
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ps / 1ps


`define SEVEN_SEG_0     7'b1000000
`define SEVEN_SEG_1     7'b1111001
`define SEVEN_SEG_2     7'b0100100
`define SEVEN_SEG_3     7'b0110000
`define SEVEN_SEG_4     7'b0011001
`define SEVEN_SEG_5     7'b0010010
`define SEVEN_SEG_6     7'b0000010
`define SEVEN_SEG_7     7'b1111000
`define SEVEN_SEG_8     7'b0000000
`define SEVEN_SEG_9     7'b0011000
`define SEVEN_SEG_A     7'b0001000  // "A"
`define SEVEN_SEG_B     7'b0000011  // "b"
`define SEVEN_SEG_C     7'b0100111  // "c"
`define SEVEN_SEG_D     7'b0100001  // "d"
`define SEVEN_SEG_E     7'b0000110  // "E"
`define SEVEN_SEG_F     7'b0001110  // "F"
`define SEVEN_SEG_CAL   7'b1000110  // "C"
`define SEVEN_SEG_ERROR 7'b0111111  // "-"

module led_display_driver #
  (
   parameter TCQ = 100
  )
  (
   rst,         // global (system) reset
   clk,         // system clock
   clkdiv,      // system clock divided by 2
   init_done_i, // initialization done
   error_i,     // data check fail
   valid_i,     //data read valid
  // seven_seg_n,
  // seven_seg_dp_n,
   led,
   cmp_cnt
   );

  input        rst;
  input        clk;
  input        clkdiv;
  input        init_done_i;
  input        error_i;
  input        valid_i;
  //output [6:0] seven_seg_n;
  //output       seven_seg_dp_n;
  output [3:0] led;
  output [3:0] cmp_cnt;

  localparam   SEVEN_SEG_0    = 7'b1000000;
  localparam   SEVEN_SEG_1    = 7'b1111001;
  localparam   SEVEN_SEG_2    = 7'b0100100;
  localparam   SEVEN_SEG_3    = 7'b0110000;
  localparam   SEVEN_SEG_4    = 7'b0011001;
  localparam   SEVEN_SEG_5    = 7'b0010010;
  localparam   SEVEN_SEG_6    = 7'b0000010;
  localparam   SEVEN_SEG_7    = 7'b1111000;
  localparam   SEVEN_SEG_8    = 7'b0000000;
  localparam   SEVEN_SEG_9    = 7'b0011000;
  localparam   SEVEN_SEG_A    = 7'b0001000;    // "A"
  localparam   SEVEN_SEG_B    = 7'b0000011;    // "b"
  localparam   SEVEN_SEG_C    = 7'b0100111;    // "c"
  localparam   SEVEN_SEG_D    = 7'b0100001;    // "d"
  localparam   SEVEN_SEG_E    = 7'b0000110;    // "E"
  localparam   SEVEN_SEG_F    = 7'b0001110;    // "F"
  localparam   SEVEN_SEG_CAL  = 7'b1000110;    // "C"
  localparam   SEVEN_SEG_ERROR = 7'b0111111;   // "-"

  localparam   CLK_DIV_CNT_WIDTH = 26;
  localparam   READ_DIV_CNT_WIDTH = 28;

  reg [6:0]    seven_seg_n;
  reg          error_reg;
  reg          memtest_start;
  reg          init_done_r;

  // These counters might be too large for the higher (300MHz+)
  // memory interfaces. If so, then need to generate divided down
  // local clock to use here
  reg [CLK_DIV_CNT_WIDTH-1:0]  clk_div_cnt = 'b0;
  reg [READ_DIV_CNT_WIDTH-1:0] read_div_cnt;
  wire [3:0]                   seven_seg_sel;
  reg              valid_div;
  reg                          valid_pulse;
  reg                          valid_pulse_r;
  reg                          valid_toggle;
  reg                          valid_toggle_r;

///////////////////////////////////////////////////////////////////////////////

  /////////////////////////////////////////////////////////////////////////////
  // Discrete LEDs:
  //  led(0) = data check pass
  //  led(1) = divided down system clock
  //  led(2) = data check fail
  //  led(3) = initialization (calibration) done
  /////////////////////////////////////////////////////////////////////////////

  // Divide down fast clock to generate slower clock for display
  always @(posedge clkdiv)
    clk_div_cnt <= #TCQ clk_div_cnt + 1;

  // error flag from memory controller stays high as long as phy initialization
  // is in progress. Once phy init complete, then can toggle high and low as
  // bits are compared. We want LED to stay lit once a single error is
  // encountered

  always @(posedge clkdiv or posedge rst)
    if (rst)
      memtest_start <= #TCQ 1'b0;
    else if (!memtest_start)
      // wait for ERROR = 0 to tell we've started the memory test (can't
      // look at INIT_DONE_I, it comes slightly earlier than when memory
      // test starts)
      memtest_start <= #TCQ ~error_i;

  always @(posedge clkdiv or posedge rst)
    if (rst)
      error_reg <= #TCQ 1'b0;
    else if (memtest_start)
      if (!error_reg && error_i)
        error_reg <= #TCQ 1'b1;

  always @(posedge clkdiv)
    init_done_r <= #TCQ init_done_i;

  assign led[0] = memtest_start & (~error_reg);
  assign led[1] = clk_div_cnt[CLK_DIV_CNT_WIDTH-1];
  assign led[2] = error_reg;
  assign led[3] = init_done_r;

  /////////////////////////////////////////////////////////////////////////////
  // 7-segment LEDs:
  //  0-F: Used to indicate progress of data checking
  //  U:   Indicates still in initialization/calibration
  //  -:   Indicates error found
  /////////////////////////////////////////////////////////////////////////////

  // translate VALID_I from CLK to CLKDIV domain
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      valid_toggle <= #TCQ 1'b0;
    end else if (valid_i)
      valid_toggle <= #TCQ ~valid_toggle;
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      valid_toggle_r <= #TCQ 1'b0;
    end else if (valid_i)
      valid_toggle_r <= #TCQ valid_toggle;
  end

  always @(posedge clk or posedge rst) begin
    if (rst)
      valid_pulse <= #TCQ 1'b0;
    else
      valid_pulse <= #TCQ valid_toggle & ~valid_toggle_r;
  end

  always @(posedge clk or posedge rst) begin
    if (rst)
      valid_pulse_r <= #TCQ 1'b0;
    else
      valid_pulse_r <= #TCQ valid_pulse;
  end

  always @(posedge clkdiv or posedge rst) begin
    if (rst)
      valid_div <= #TCQ 1'b0;
    else
      valid_div <= #TCQ valid_pulse | valid_pulse_r;
  end

  // Divide down read
  always @(posedge clkdiv or posedge rst) begin
    if (rst)
      read_div_cnt <= #TCQ 0;
    else
      if (valid_div)
        read_div_cnt <= #TCQ read_div_cnt + 1;
  end

  assign seven_seg_sel = read_div_cnt[READ_DIV_CNT_WIDTH-1:
                                      READ_DIV_CNT_WIDTH-4];

  // Generate 7-segment LED outptus
  always @(error_i or init_done_i or seven_seg_sel) begin
    if (~init_done_i)
      seven_seg_n <= SEVEN_SEG_CAL;
    else if (error_i)
      seven_seg_n <= SEVEN_SEG_ERROR;
    else
      case (seven_seg_sel)
        4'h0: seven_seg_n <= SEVEN_SEG_0;
        4'h1: seven_seg_n <= SEVEN_SEG_1;
        4'h2: seven_seg_n <= SEVEN_SEG_2;
        4'h3: seven_seg_n <= SEVEN_SEG_3;
        4'h4: seven_seg_n <= SEVEN_SEG_4;
        4'h5: seven_seg_n <= SEVEN_SEG_5;
        4'h6: seven_seg_n <= SEVEN_SEG_6;
        4'h7: seven_seg_n <= SEVEN_SEG_7;
        4'h8: seven_seg_n <= SEVEN_SEG_8;
        4'h9: seven_seg_n <= SEVEN_SEG_9;
        4'hA: seven_seg_n <= SEVEN_SEG_A;
        4'hB: seven_seg_n <= SEVEN_SEG_B;
        4'hC: seven_seg_n <= SEVEN_SEG_C;
        4'hD: seven_seg_n <= SEVEN_SEG_D;
        4'hE: seven_seg_n <= SEVEN_SEG_E;
        4'hF: seven_seg_n <= SEVEN_SEG_F;
      endcase
  end

  // Keep decimal point inactive for now
  assign seven_seg_dp_n = 1'b1;

  // Generate simple 1 digit output for systems that don't have
  // seven segment LED (i.e. connect to Chipscope VIO to show
  // incrementing value) 
  assign cmp_cnt = seven_seg_sel;
  
endmodule
