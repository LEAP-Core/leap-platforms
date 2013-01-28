///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2013 Xilinx, Inc.
// All Rights Reserved
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor     : Xilinx
// \   \   \/     Version    : 14.3
//  \   \         Application: Xilinx CORE Generator
//  /   /         Filename   : v6_ila.v
// /___/   /\     Timestamp  : Fri Jan 25 19:18:04 EST 2013
// \   \  /  \
//  \___\/\___\
//
// Design Name: Verilog Synthesis Wrapper
///////////////////////////////////////////////////////////////////////////////
// This wrapper is used to integrate with Project Navigator and PlanAhead

`timescale 1ns/1ps

module v6_ila(
    CONTROL,
    CLK,
    TRIG0,
    TRIG1,
    TRIG2,
    TRIG3,
    TRIG4,
    TRIG5,
    TRIG6,
    TRIG7) /* synthesis syn_black_box syn_noprune=1 */;


inout [35 : 0] CONTROL;
input CLK;
input [7 : 0] TRIG0;
input [7 : 0] TRIG1;
input [7 : 0] TRIG2;
input [7 : 0] TRIG3;
input [7 : 0] TRIG4;
input [7 : 0] TRIG5;
input [7 : 0] TRIG6;
input [7 : 0] TRIG7;

endmodule
