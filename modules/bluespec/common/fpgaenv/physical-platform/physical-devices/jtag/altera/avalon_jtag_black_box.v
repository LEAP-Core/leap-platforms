//megafunction wizard: %Altera SOPC Builder%
//GENERATION: STANDARD
//VERSION: WM1.0


//Legal Notice: (C)2010 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module avalon_jtag (
                     // 1) global signals:
                      clk_0,
                      reset_n,

                     // the_mkAvalonWrapperInstance_0
                      masterInverseWires_address_to_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_read_to_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_write_to_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_writedata_to_the_mkAvalonWrapperInstance_0
                   )
;

  output  [ 31: 0] masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0;
  output           masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0;
  output           masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0;
  input            clk_0;
  input   [ 31: 0] masterInverseWires_address_to_the_mkAvalonWrapperInstance_0;
  input            masterInverseWires_read_to_the_mkAvalonWrapperInstance_0;
  input            masterInverseWires_write_to_the_mkAvalonWrapperInstance_0;
  input   [ 31: 0] masterInverseWires_writedata_to_the_mkAvalonWrapperInstance_0;
  input            reset_n;


endmodule


