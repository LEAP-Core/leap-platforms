////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2009 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: L.70
//  \   \         Application: netgen
//  /   /         Filename: fp_cvt_d_to_s.v
// /___/   /\     Timestamp: Tue Jun 29 14:38:00 2010
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -intstyle ise -w -sim -ofmt verilog ./tmp/_cg/fp_cvt_d_to_s.ngc ./tmp/_cg/fp_cvt_d_to_s.v 
// Device	: 5vlx330tff1738-2
// Input file	: ./tmp/_cg/fp_cvt_d_to_s.ngc
// Output file	: ./tmp/_cg/fp_cvt_d_to_s.v
// # of Modules	: 1
// Design Name	: fp_cvt_d_to_s
// Xilinx        : /usr/local/Xilinx/11.1/ISE
//             
// Purpose:    
//     This verilog netlist is a verification model and uses simulation 
//     primitives which may not represent the true implementation of the 
//     device, however the netlist is functionally correct and should not 
//     be modified. This file cannot be synthesized and should only be used 
//     with supported simulation tools.
//             
// Reference:  
//     Command Line Tools User Guide, Chapter 23 and Synthesis and Simulation Design Guide, Chapter 6
//             
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ps

module fp_cvt_d_to_s (
  rdy, overflow, operation_nd, clk, operation_rfd, underflow, a, result
)/* synthesis syn_black_box syn_noprune=1 */;
  output rdy;
  output overflow;
  input operation_nd;
  input clk;
  output operation_rfd;
  output underflow;
  input [63 : 0] a;
  output [31 : 0] result;
  
  // synthesis translate_off
  
  wire NlwRenamedSig_OI_operation_rfd;
  wire \blk00000003/sig0000015f ;
  wire \blk00000003/sig0000015e ;
  wire \blk00000003/sig0000015d ;
  wire \blk00000003/sig0000015c ;
  wire \blk00000003/sig0000015b ;
  wire \blk00000003/sig0000015a ;
  wire \blk00000003/sig00000159 ;
  wire \blk00000003/sig00000158 ;
  wire \blk00000003/sig00000157 ;
  wire \blk00000003/sig00000156 ;
  wire \blk00000003/sig00000155 ;
  wire \blk00000003/sig00000154 ;
  wire \blk00000003/sig00000153 ;
  wire \blk00000003/sig00000152 ;
  wire \blk00000003/sig00000151 ;
  wire \blk00000003/sig00000150 ;
  wire \blk00000003/sig0000014f ;
  wire \blk00000003/sig0000014e ;
  wire \blk00000003/sig0000014d ;
  wire \blk00000003/sig0000014c ;
  wire \blk00000003/sig0000014b ;
  wire \blk00000003/sig0000014a ;
  wire \blk00000003/sig00000149 ;
  wire \blk00000003/sig00000148 ;
  wire \blk00000003/sig00000147 ;
  wire \blk00000003/sig00000146 ;
  wire \blk00000003/sig00000145 ;
  wire \blk00000003/sig00000144 ;
  wire \blk00000003/sig00000143 ;
  wire \blk00000003/sig00000142 ;
  wire \blk00000003/sig00000141 ;
  wire \blk00000003/sig00000140 ;
  wire \blk00000003/sig0000013f ;
  wire \blk00000003/sig0000013e ;
  wire \blk00000003/sig0000013d ;
  wire \blk00000003/sig0000013c ;
  wire \blk00000003/sig0000013b ;
  wire \blk00000003/sig0000013a ;
  wire \blk00000003/sig00000139 ;
  wire \blk00000003/sig00000138 ;
  wire \blk00000003/sig00000137 ;
  wire \blk00000003/sig00000136 ;
  wire \blk00000003/sig00000135 ;
  wire \blk00000003/sig00000134 ;
  wire \blk00000003/sig00000133 ;
  wire \blk00000003/sig00000132 ;
  wire \blk00000003/sig00000131 ;
  wire \blk00000003/sig00000130 ;
  wire \blk00000003/sig0000012f ;
  wire \blk00000003/sig0000012e ;
  wire \blk00000003/sig0000012d ;
  wire \blk00000003/sig0000012c ;
  wire \blk00000003/sig0000012b ;
  wire \blk00000003/sig0000012a ;
  wire \blk00000003/sig00000129 ;
  wire \blk00000003/sig00000128 ;
  wire \blk00000003/sig00000127 ;
  wire \blk00000003/sig00000126 ;
  wire \blk00000003/sig00000125 ;
  wire \blk00000003/sig00000124 ;
  wire \blk00000003/sig00000123 ;
  wire \blk00000003/sig00000122 ;
  wire \blk00000003/sig00000121 ;
  wire \blk00000003/sig00000120 ;
  wire \blk00000003/sig0000011f ;
  wire \blk00000003/sig0000011e ;
  wire \blk00000003/sig0000011d ;
  wire \blk00000003/sig0000011c ;
  wire \blk00000003/sig0000011b ;
  wire \blk00000003/sig0000011a ;
  wire \blk00000003/sig00000119 ;
  wire \blk00000003/sig00000118 ;
  wire \blk00000003/sig00000117 ;
  wire \blk00000003/sig00000116 ;
  wire \blk00000003/sig00000115 ;
  wire \blk00000003/sig00000114 ;
  wire \blk00000003/sig00000113 ;
  wire \blk00000003/sig00000112 ;
  wire \blk00000003/sig00000111 ;
  wire \blk00000003/sig00000110 ;
  wire \blk00000003/sig0000010f ;
  wire \blk00000003/sig0000010e ;
  wire \blk00000003/sig0000010d ;
  wire \blk00000003/sig0000010c ;
  wire \blk00000003/sig0000010b ;
  wire \blk00000003/sig0000010a ;
  wire \blk00000003/sig00000109 ;
  wire \blk00000003/sig00000108 ;
  wire \blk00000003/sig00000107 ;
  wire \blk00000003/sig00000106 ;
  wire \blk00000003/sig00000105 ;
  wire \blk00000003/sig00000104 ;
  wire \blk00000003/sig00000103 ;
  wire \blk00000003/sig00000102 ;
  wire \blk00000003/sig00000101 ;
  wire \blk00000003/sig00000100 ;
  wire \blk00000003/sig000000ff ;
  wire \blk00000003/sig000000fe ;
  wire \blk00000003/sig000000fd ;
  wire \blk00000003/sig000000fc ;
  wire \blk00000003/sig000000fb ;
  wire \blk00000003/sig000000fa ;
  wire \blk00000003/sig000000f9 ;
  wire \blk00000003/sig000000f8 ;
  wire \blk00000003/sig000000f7 ;
  wire \blk00000003/sig000000f6 ;
  wire \blk00000003/sig000000f5 ;
  wire \blk00000003/sig000000f4 ;
  wire \blk00000003/sig000000f3 ;
  wire \blk00000003/sig000000f2 ;
  wire \blk00000003/sig000000f1 ;
  wire \blk00000003/sig000000f0 ;
  wire \blk00000003/sig000000ef ;
  wire \blk00000003/sig000000ee ;
  wire \blk00000003/sig000000ed ;
  wire \blk00000003/sig000000ec ;
  wire \blk00000003/sig000000eb ;
  wire \blk00000003/sig000000ea ;
  wire \blk00000003/sig000000e9 ;
  wire \blk00000003/sig000000e8 ;
  wire \blk00000003/sig000000e7 ;
  wire \blk00000003/sig000000e6 ;
  wire \blk00000003/sig000000e5 ;
  wire \blk00000003/sig000000e4 ;
  wire \blk00000003/sig000000e3 ;
  wire \blk00000003/sig000000e2 ;
  wire \blk00000003/sig000000e1 ;
  wire \blk00000003/sig000000e0 ;
  wire \blk00000003/sig000000df ;
  wire \blk00000003/sig000000de ;
  wire \blk00000003/sig000000dd ;
  wire \blk00000003/sig000000dc ;
  wire \blk00000003/sig000000db ;
  wire \blk00000003/sig000000da ;
  wire \blk00000003/sig000000d9 ;
  wire \blk00000003/sig000000d8 ;
  wire \blk00000003/sig000000d7 ;
  wire \blk00000003/sig000000d6 ;
  wire \blk00000003/sig000000d5 ;
  wire \blk00000003/sig000000d4 ;
  wire \blk00000003/sig000000d3 ;
  wire \blk00000003/sig000000d2 ;
  wire \blk00000003/sig000000d1 ;
  wire \blk00000003/sig000000d0 ;
  wire \blk00000003/sig000000cf ;
  wire \blk00000003/sig000000ce ;
  wire \blk00000003/sig000000cd ;
  wire \blk00000003/sig000000cc ;
  wire \blk00000003/sig000000cb ;
  wire \blk00000003/sig000000ca ;
  wire \blk00000003/sig000000c9 ;
  wire \blk00000003/sig000000c8 ;
  wire \blk00000003/sig000000c7 ;
  wire \blk00000003/sig000000c6 ;
  wire \blk00000003/sig000000c5 ;
  wire \blk00000003/sig000000c4 ;
  wire \blk00000003/sig000000c3 ;
  wire \blk00000003/sig000000c2 ;
  wire \blk00000003/sig000000c1 ;
  wire \blk00000003/sig000000c0 ;
  wire \blk00000003/sig000000bf ;
  wire \blk00000003/sig000000be ;
  wire \blk00000003/sig000000bd ;
  wire \blk00000003/sig000000bc ;
  wire \blk00000003/sig000000bb ;
  wire \blk00000003/sig000000ba ;
  wire \blk00000003/sig000000b9 ;
  wire \blk00000003/sig000000b8 ;
  wire \blk00000003/sig000000b7 ;
  wire \blk00000003/sig000000b6 ;
  wire \blk00000003/sig000000b5 ;
  wire \blk00000003/sig000000b4 ;
  wire \blk00000003/sig000000b3 ;
  wire \blk00000003/sig000000b2 ;
  wire \blk00000003/sig000000b1 ;
  wire \blk00000003/sig000000b0 ;
  wire \blk00000003/sig000000af ;
  wire \blk00000003/sig000000ae ;
  wire \blk00000003/sig000000ad ;
  wire \blk00000003/sig000000ac ;
  wire \blk00000003/sig000000ab ;
  wire \blk00000003/sig000000aa ;
  wire \blk00000003/sig000000a9 ;
  wire \blk00000003/sig000000a8 ;
  wire \blk00000003/sig000000a7 ;
  wire \blk00000003/sig000000a6 ;
  wire \blk00000003/sig000000a5 ;
  wire \blk00000003/sig000000a4 ;
  wire \blk00000003/sig000000a3 ;
  wire \blk00000003/sig000000a2 ;
  wire \blk00000003/sig000000a1 ;
  wire \blk00000003/sig000000a0 ;
  wire \blk00000003/sig0000009f ;
  wire \blk00000003/sig0000009e ;
  wire \blk00000003/sig0000009d ;
  wire \blk00000003/sig0000009c ;
  wire \blk00000003/sig0000009b ;
  wire \blk00000003/sig0000009a ;
  wire \blk00000003/sig00000099 ;
  wire \blk00000003/sig00000098 ;
  wire \blk00000003/sig00000097 ;
  wire \blk00000003/sig00000096 ;
  wire \blk00000003/sig00000095 ;
  wire \blk00000003/sig00000094 ;
  wire \blk00000003/sig00000093 ;
  wire \blk00000003/sig00000092 ;
  wire \blk00000003/sig00000091 ;
  wire \blk00000003/sig00000090 ;
  wire \blk00000003/sig0000008f ;
  wire \blk00000003/sig0000008e ;
  wire \blk00000003/sig0000008d ;
  wire \blk00000003/sig0000008c ;
  wire \blk00000003/sig0000008b ;
  wire \blk00000003/sig0000008a ;
  wire \blk00000003/sig00000089 ;
  wire \blk00000003/sig00000088 ;
  wire \blk00000003/sig00000087 ;
  wire \blk00000003/sig00000086 ;
  wire \blk00000003/sig00000085 ;
  wire \blk00000003/sig00000084 ;
  wire \blk00000003/sig00000083 ;
  wire \blk00000003/sig00000082 ;
  wire \blk00000003/sig00000081 ;
  wire \blk00000003/sig00000080 ;
  wire \blk00000003/sig0000007f ;
  wire \blk00000003/sig0000007e ;
  wire \blk00000003/sig0000007d ;
  wire \blk00000003/sig0000007c ;
  wire \blk00000003/sig0000007b ;
  wire \blk00000003/sig0000007a ;
  wire \blk00000003/sig00000079 ;
  wire \blk00000003/sig00000078 ;
  wire \blk00000003/sig00000077 ;
  wire \blk00000003/sig00000076 ;
  wire \blk00000003/sig00000075 ;
  wire \blk00000003/sig00000074 ;
  wire \blk00000003/sig00000073 ;
  wire \blk00000003/sig00000072 ;
  wire \blk00000003/sig00000071 ;
  wire \blk00000003/sig00000070 ;
  wire \blk00000003/sig0000006f ;
  wire \blk00000003/sig0000006e ;
  wire \blk00000003/sig0000006d ;
  wire \blk00000003/sig0000006c ;
  wire \blk00000003/sig0000006b ;
  wire \blk00000003/sig0000006a ;
  wire \blk00000003/sig00000069 ;
  wire \blk00000003/sig00000068 ;
  wire \blk00000003/sig00000002 ;
  wire NLW_blk00000001_P_UNCONNECTED;
  wire NLW_blk00000002_G_UNCONNECTED;
  wire \NLW_blk00000003/blk0000011f_Q15_UNCONNECTED ;
  wire \NLW_blk00000003/blk0000011d_Q15_UNCONNECTED ;
  wire \NLW_blk00000003/blk0000011b_Q15_UNCONNECTED ;
  wire \NLW_blk00000003/blk00000119_Q15_UNCONNECTED ;
  wire \NLW_blk00000003/blk00000117_Q15_UNCONNECTED ;
  wire \NLW_blk00000003/blk00000115_Q15_UNCONNECTED ;
  wire \NLW_blk00000003/blk00000113_Q15_UNCONNECTED ;
  wire \NLW_blk00000003/blk00000111_Q15_UNCONNECTED ;
  wire \NLW_blk00000003/blk0000010f_Q15_UNCONNECTED ;
  wire [63 : 0] a_0;
  wire [31 : 0] result_1;
  assign
    a_0[63] = a[63],
    a_0[62] = a[62],
    a_0[61] = a[61],
    a_0[60] = a[60],
    a_0[59] = a[59],
    a_0[58] = a[58],
    a_0[57] = a[57],
    a_0[56] = a[56],
    a_0[55] = a[55],
    a_0[54] = a[54],
    a_0[53] = a[53],
    a_0[52] = a[52],
    a_0[51] = a[51],
    a_0[50] = a[50],
    a_0[49] = a[49],
    a_0[48] = a[48],
    a_0[47] = a[47],
    a_0[46] = a[46],
    a_0[45] = a[45],
    a_0[44] = a[44],
    a_0[43] = a[43],
    a_0[42] = a[42],
    a_0[41] = a[41],
    a_0[40] = a[40],
    a_0[39] = a[39],
    a_0[38] = a[38],
    a_0[37] = a[37],
    a_0[36] = a[36],
    a_0[35] = a[35],
    a_0[34] = a[34],
    a_0[33] = a[33],
    a_0[32] = a[32],
    a_0[31] = a[31],
    a_0[30] = a[30],
    a_0[29] = a[29],
    a_0[28] = a[28],
    a_0[27] = a[27],
    a_0[26] = a[26],
    a_0[25] = a[25],
    a_0[24] = a[24],
    a_0[23] = a[23],
    a_0[22] = a[22],
    a_0[21] = a[21],
    a_0[20] = a[20],
    a_0[19] = a[19],
    a_0[18] = a[18],
    a_0[17] = a[17],
    a_0[16] = a[16],
    a_0[15] = a[15],
    a_0[14] = a[14],
    a_0[13] = a[13],
    a_0[12] = a[12],
    a_0[11] = a[11],
    a_0[10] = a[10],
    a_0[9] = a[9],
    a_0[8] = a[8],
    a_0[7] = a[7],
    a_0[6] = a[6],
    a_0[5] = a[5],
    a_0[4] = a[4],
    a_0[3] = a[3],
    a_0[2] = a[2],
    a_0[1] = a[1],
    a_0[0] = a[0],
    result[31] = result_1[31],
    result[30] = result_1[30],
    result[29] = result_1[29],
    result[28] = result_1[28],
    result[27] = result_1[27],
    result[26] = result_1[26],
    result[25] = result_1[25],
    result[24] = result_1[24],
    result[23] = result_1[23],
    result[22] = result_1[22],
    result[21] = result_1[21],
    result[20] = result_1[20],
    result[19] = result_1[19],
    result[18] = result_1[18],
    result[17] = result_1[17],
    result[16] = result_1[16],
    result[15] = result_1[15],
    result[14] = result_1[14],
    result[13] = result_1[13],
    result[12] = result_1[12],
    result[11] = result_1[11],
    result[10] = result_1[10],
    result[9] = result_1[9],
    result[8] = result_1[8],
    result[7] = result_1[7],
    result[6] = result_1[6],
    result[5] = result_1[5],
    result[4] = result_1[4],
    result[3] = result_1[3],
    result[2] = result_1[2],
    result[1] = result_1[1],
    result[0] = result_1[0],
    operation_rfd = NlwRenamedSig_OI_operation_rfd;
  VCC   blk00000001 (
    .P(NLW_blk00000001_P_UNCONNECTED)
  );
  GND   blk00000002 (
    .G(NLW_blk00000002_G_UNCONNECTED)
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000120  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000015f ),
    .Q(\blk00000003/sig0000008f )
  );
  SRLC16E #(
    .INIT ( 16'h0000 ))
  \blk00000003/blk0000011f  (
    .A0(\blk00000003/sig00000002 ),
    .A1(\blk00000003/sig00000002 ),
    .A2(\blk00000003/sig00000002 ),
    .A3(\blk00000003/sig00000002 ),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .CLK(clk),
    .D(a_0[62]),
    .Q(\blk00000003/sig0000015f ),
    .Q15(\NLW_blk00000003/blk0000011f_Q15_UNCONNECTED )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000011e  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000015e ),
    .Q(\blk00000003/sig00000150 )
  );
  SRLC16E #(
    .INIT ( 16'h0000 ))
  \blk00000003/blk0000011d  (
    .A0(\blk00000003/sig00000002 ),
    .A1(\blk00000003/sig00000002 ),
    .A2(\blk00000003/sig00000002 ),
    .A3(\blk00000003/sig00000002 ),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .CLK(clk),
    .D(a_0[58]),
    .Q(\blk00000003/sig0000015e ),
    .Q15(\NLW_blk00000003/blk0000011d_Q15_UNCONNECTED )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000011c  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000015d ),
    .Q(\blk00000003/sig00000151 )
  );
  SRLC16E #(
    .INIT ( 16'h0000 ))
  \blk00000003/blk0000011b  (
    .A0(\blk00000003/sig00000002 ),
    .A1(\blk00000003/sig00000002 ),
    .A2(\blk00000003/sig00000002 ),
    .A3(\blk00000003/sig00000002 ),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .CLK(clk),
    .D(a_0[57]),
    .Q(\blk00000003/sig0000015d ),
    .Q15(\NLW_blk00000003/blk0000011b_Q15_UNCONNECTED )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000011a  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000015c ),
    .Q(\blk00000003/sig00000152 )
  );
  SRLC16E #(
    .INIT ( 16'h0000 ))
  \blk00000003/blk00000119  (
    .A0(\blk00000003/sig00000002 ),
    .A1(\blk00000003/sig00000002 ),
    .A2(\blk00000003/sig00000002 ),
    .A3(\blk00000003/sig00000002 ),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .CLK(clk),
    .D(a_0[56]),
    .Q(\blk00000003/sig0000015c ),
    .Q15(\NLW_blk00000003/blk00000119_Q15_UNCONNECTED )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000118  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000015b ),
    .Q(\blk00000003/sig00000153 )
  );
  SRLC16E #(
    .INIT ( 16'h0000 ))
  \blk00000003/blk00000117  (
    .A0(\blk00000003/sig00000002 ),
    .A1(\blk00000003/sig00000002 ),
    .A2(\blk00000003/sig00000002 ),
    .A3(\blk00000003/sig00000002 ),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .CLK(clk),
    .D(a_0[55]),
    .Q(\blk00000003/sig0000015b ),
    .Q15(\NLW_blk00000003/blk00000117_Q15_UNCONNECTED )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000116  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000015a ),
    .Q(\blk00000003/sig00000154 )
  );
  SRLC16E #(
    .INIT ( 16'h0000 ))
  \blk00000003/blk00000115  (
    .A0(\blk00000003/sig00000002 ),
    .A1(\blk00000003/sig00000002 ),
    .A2(\blk00000003/sig00000002 ),
    .A3(\blk00000003/sig00000002 ),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .CLK(clk),
    .D(a_0[54]),
    .Q(\blk00000003/sig0000015a ),
    .Q15(\NLW_blk00000003/blk00000115_Q15_UNCONNECTED )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000114  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000159 ),
    .Q(\blk00000003/sig00000156 )
  );
  SRLC16E #(
    .INIT ( 16'h0000 ))
  \blk00000003/blk00000113  (
    .A0(\blk00000003/sig00000002 ),
    .A1(\blk00000003/sig00000002 ),
    .A2(\blk00000003/sig00000002 ),
    .A3(\blk00000003/sig00000002 ),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .CLK(clk),
    .D(a_0[52]),
    .Q(\blk00000003/sig00000159 ),
    .Q15(\NLW_blk00000003/blk00000113_Q15_UNCONNECTED )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000112  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000158 ),
    .Q(rdy)
  );
  SRLC16E #(
    .INIT ( 16'h0000 ))
  \blk00000003/blk00000111  (
    .A0(NlwRenamedSig_OI_operation_rfd),
    .A1(\blk00000003/sig00000002 ),
    .A2(\blk00000003/sig00000002 ),
    .A3(\blk00000003/sig00000002 ),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .CLK(clk),
    .D(operation_nd),
    .Q(\blk00000003/sig00000158 ),
    .Q15(\NLW_blk00000003/blk00000111_Q15_UNCONNECTED )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000110  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000157 ),
    .Q(\blk00000003/sig00000155 )
  );
  SRLC16E #(
    .INIT ( 16'h0000 ))
  \blk00000003/blk0000010f  (
    .A0(\blk00000003/sig00000002 ),
    .A1(\blk00000003/sig00000002 ),
    .A2(\blk00000003/sig00000002 ),
    .A3(\blk00000003/sig00000002 ),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .CLK(clk),
    .D(a_0[53]),
    .Q(\blk00000003/sig00000157 ),
    .Q15(\NLW_blk00000003/blk0000010f_Q15_UNCONNECTED )
  );
  LUT4 #(
    .INIT ( 16'h8000 ))
  \blk00000003/blk0000010e  (
    .I0(a_0[52]),
    .I1(a_0[55]),
    .I2(a_0[54]),
    .I3(a_0[53]),
    .O(\blk00000003/sig0000012d )
  );
  LUT4 #(
    .INIT ( 16'h8000 ))
  \blk00000003/blk0000010d  (
    .I0(a_0[59]),
    .I1(a_0[58]),
    .I2(a_0[57]),
    .I3(a_0[56]),
    .O(\blk00000003/sig0000012f )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk0000010c  (
    .I0(\blk00000003/sig00000080 ),
    .O(\blk00000003/sig00000109 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk0000010b  (
    .I0(\blk00000003/sig0000007f ),
    .O(\blk00000003/sig00000107 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk0000010a  (
    .I0(\blk00000003/sig0000007e ),
    .O(\blk00000003/sig00000104 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000109  (
    .I0(\blk00000003/sig0000007d ),
    .O(\blk00000003/sig00000101 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000108  (
    .I0(\blk00000003/sig0000007c ),
    .O(\blk00000003/sig000000fe )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000107  (
    .I0(\blk00000003/sig0000007b ),
    .O(\blk00000003/sig000000fb )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000106  (
    .I0(\blk00000003/sig0000007a ),
    .O(\blk00000003/sig000000f8 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000105  (
    .I0(\blk00000003/sig00000079 ),
    .O(\blk00000003/sig000000f5 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000104  (
    .I0(\blk00000003/sig00000078 ),
    .O(\blk00000003/sig000000f2 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000103  (
    .I0(\blk00000003/sig00000077 ),
    .O(\blk00000003/sig000000ef )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000102  (
    .I0(\blk00000003/sig00000076 ),
    .O(\blk00000003/sig000000ec )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000101  (
    .I0(\blk00000003/sig0000008c ),
    .O(\blk00000003/sig000000e5 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk00000100  (
    .I0(\blk00000003/sig0000008b ),
    .O(\blk00000003/sig000000e3 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000ff  (
    .I0(\blk00000003/sig0000008a ),
    .O(\blk00000003/sig000000e0 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000fe  (
    .I0(\blk00000003/sig00000089 ),
    .O(\blk00000003/sig000000dd )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000fd  (
    .I0(\blk00000003/sig00000088 ),
    .O(\blk00000003/sig000000da )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000fc  (
    .I0(\blk00000003/sig00000087 ),
    .O(\blk00000003/sig000000d7 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000fb  (
    .I0(\blk00000003/sig00000086 ),
    .O(\blk00000003/sig000000d4 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000fa  (
    .I0(\blk00000003/sig00000085 ),
    .O(\blk00000003/sig000000d1 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f9  (
    .I0(\blk00000003/sig00000084 ),
    .O(\blk00000003/sig000000ce )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f8  (
    .I0(\blk00000003/sig00000083 ),
    .O(\blk00000003/sig000000cb )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f7  (
    .I0(\blk00000003/sig00000082 ),
    .O(\blk00000003/sig000000c8 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f6  (
    .I0(\blk00000003/sig00000081 ),
    .O(\blk00000003/sig000000c4 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f5  (
    .I0(\blk00000003/sig00000156 ),
    .O(\blk00000003/sig000000a4 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f4  (
    .I0(\blk00000003/sig00000155 ),
    .O(\blk00000003/sig000000a1 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f3  (
    .I0(\blk00000003/sig00000154 ),
    .O(\blk00000003/sig0000009e )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f2  (
    .I0(\blk00000003/sig00000153 ),
    .O(\blk00000003/sig0000009b )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f1  (
    .I0(\blk00000003/sig00000152 ),
    .O(\blk00000003/sig00000098 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000f0  (
    .I0(\blk00000003/sig00000151 ),
    .O(\blk00000003/sig00000095 )
  );
  LUT1 #(
    .INIT ( 2'h2 ))
  \blk00000003/blk000000ef  (
    .I0(\blk00000003/sig00000150 ),
    .O(\blk00000003/sig00000092 )
  );
  LUT3 #(
    .INIT ( 8'h02 ))
  \blk00000003/blk000000ee  (
    .I0(\blk00000003/sig0000013b ),
    .I1(\blk00000003/sig0000013d ),
    .I2(\blk00000003/sig00000141 ),
    .O(\blk00000003/sig0000014f )
  );
  FDS #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000ed  (
    .C(clk),
    .D(\blk00000003/sig0000014f ),
    .S(\blk00000003/sig00000134 ),
    .Q(\blk00000003/sig000000c2 )
  );
  LUT2 #(
    .INIT ( 4'h8 ))
  \blk00000003/blk000000ec  (
    .I0(\blk00000003/sig00000148 ),
    .I1(\blk00000003/sig0000010b ),
    .O(\blk00000003/sig0000014e )
  );
  FDS #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000eb  (
    .C(clk),
    .D(\blk00000003/sig0000014e ),
    .S(\blk00000003/sig00000145 ),
    .Q(underflow)
  );
  LUT2 #(
    .INIT ( 4'h2 ))
  \blk00000003/blk000000ea  (
    .I0(\blk00000003/sig00000147 ),
    .I1(\blk00000003/sig0000010b ),
    .O(\blk00000003/sig0000014d )
  );
  FDS #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000e9  (
    .C(clk),
    .D(\blk00000003/sig0000014d ),
    .S(\blk00000003/sig00000143 ),
    .Q(overflow)
  );
  LUT2 #(
    .INIT ( 4'h2 ))
  \blk00000003/blk000000e8  (
    .I0(\blk00000003/sig0000008d ),
    .I1(\blk00000003/sig0000008c ),
    .O(\blk00000003/sig00000074 )
  );
  LUT2 #(
    .INIT ( 4'h8 ))
  \blk00000003/blk000000e7  (
    .I0(\blk00000003/sig0000008c ),
    .I1(\blk00000003/sig0000008d ),
    .O(\blk00000003/sig00000073 )
  );
  LUT6 #(
    .INIT ( 64'h0000000000004000 ))
  \blk00000003/blk000000e6  (
    .I0(a_0[62]),
    .I1(a_0[61]),
    .I2(a_0[60]),
    .I3(a_0[59]),
    .I4(a_0[58]),
    .I5(\blk00000003/sig0000014c ),
    .O(\blk00000003/sig00000140 )
  );
  LUT6 #(
    .INIT ( 64'hFFFFFFFFFFFFFFFE ))
  \blk00000003/blk000000e5  (
    .I0(a_0[57]),
    .I1(a_0[56]),
    .I2(a_0[55]),
    .I3(a_0[54]),
    .I4(a_0[53]),
    .I5(a_0[52]),
    .O(\blk00000003/sig0000014c )
  );
  LUT3 #(
    .INIT ( 8'h02 ))
  \blk00000003/blk000000e4  (
    .I0(\blk00000003/sig000000b7 ),
    .I1(\blk00000003/sig00000136 ),
    .I2(\blk00000003/sig000000c2 ),
    .O(\blk00000003/sig000000c1 )
  );
  LUT2 #(
    .INIT ( 4'hE ))
  \blk00000003/blk000000e3  (
    .I0(\blk00000003/sig000000b7 ),
    .I1(\blk00000003/sig000000c2 ),
    .O(\blk00000003/sig000000a7 )
  );
  LUT2 #(
    .INIT ( 4'h4 ))
  \blk00000003/blk000000e2  (
    .I0(\blk00000003/sig000000b7 ),
    .I1(\blk00000003/sig000000c2 ),
    .O(\blk00000003/sig000000b8 )
  );
  LUT3 #(
    .INIT ( 8'h80 ))
  \blk00000003/blk000000e1  (
    .I0(a_0[55]),
    .I1(a_0[54]),
    .I2(a_0[53]),
    .O(\blk00000003/sig0000014b )
  );
  LUT3 #(
    .INIT ( 8'h80 ))
  \blk00000003/blk000000e0  (
    .I0(a_0[58]),
    .I1(a_0[57]),
    .I2(a_0[56]),
    .O(\blk00000003/sig0000014a )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000df  (
    .I0(a_0[0]),
    .I1(a_0[1]),
    .I2(a_0[2]),
    .I3(a_0[3]),
    .O(\blk00000003/sig00000125 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000de  (
    .I0(a_0[4]),
    .I1(a_0[5]),
    .I2(a_0[6]),
    .I3(a_0[7]),
    .O(\blk00000003/sig00000124 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000dd  (
    .I0(a_0[8]),
    .I1(a_0[9]),
    .I2(a_0[10]),
    .I3(a_0[11]),
    .O(\blk00000003/sig00000122 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000dc  (
    .I0(a_0[12]),
    .I1(a_0[13]),
    .I2(a_0[14]),
    .I3(a_0[15]),
    .O(\blk00000003/sig00000120 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000db  (
    .I0(a_0[16]),
    .I1(a_0[17]),
    .I2(a_0[18]),
    .I3(a_0[19]),
    .O(\blk00000003/sig0000011e )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000da  (
    .I0(a_0[20]),
    .I1(a_0[21]),
    .I2(a_0[22]),
    .I3(a_0[23]),
    .O(\blk00000003/sig0000011c )
  );
  LUT5 #(
    .INIT ( 32'hAAAA8000 ))
  \blk00000003/blk000000d9  (
    .I0(a_0[62]),
    .I1(a_0[52]),
    .I2(\blk00000003/sig0000014a ),
    .I3(\blk00000003/sig0000014b ),
    .I4(\blk00000003/sig00000149 ),
    .O(\blk00000003/sig0000013a )
  );
  LUT5 #(
    .INIT ( 32'h02000000 ))
  \blk00000003/blk000000d8  (
    .I0(a_0[62]),
    .I1(\blk00000003/sig00000149 ),
    .I2(a_0[52]),
    .I3(\blk00000003/sig0000014a ),
    .I4(\blk00000003/sig0000014b ),
    .O(\blk00000003/sig0000013e )
  );
  LUT3 #(
    .INIT ( 8'hFE ))
  \blk00000003/blk000000d7  (
    .I0(a_0[61]),
    .I1(a_0[59]),
    .I2(a_0[60]),
    .O(\blk00000003/sig00000149 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000d6  (
    .I0(a_0[24]),
    .I1(a_0[25]),
    .I2(a_0[26]),
    .I3(a_0[27]),
    .O(\blk00000003/sig0000011a )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000d5  (
    .I0(a_0[28]),
    .I1(a_0[29]),
    .I2(a_0[30]),
    .I3(a_0[31]),
    .O(\blk00000003/sig00000118 )
  );
  LUT6 #(
    .INIT ( 64'h0000000000000001 ))
  \blk00000003/blk000000d4  (
    .I0(a_0[0]),
    .I1(a_0[1]),
    .I2(a_0[2]),
    .I3(a_0[3]),
    .I4(a_0[4]),
    .I5(a_0[5]),
    .O(\blk00000003/sig0000006a )
  );
  LUT5 #(
    .INIT ( 32'hFFFE5554 ))
  \blk00000003/blk000000d3  (
    .I0(\blk00000003/sig00000134 ),
    .I1(\blk00000003/sig0000013b ),
    .I2(\blk00000003/sig0000013d ),
    .I3(\blk00000003/sig00000141 ),
    .I4(\blk00000003/sig00000126 ),
    .O(\blk00000003/sig00000137 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000d2  (
    .I0(a_0[32]),
    .I1(a_0[33]),
    .I2(a_0[34]),
    .I3(a_0[35]),
    .O(\blk00000003/sig00000116 )
  );
  LUT4 #(
    .INIT ( 16'h0444 ))
  \blk00000003/blk000000d1  (
    .I0(\blk00000003/sig00000134 ),
    .I1(\blk00000003/sig0000013b ),
    .I2(\blk00000003/sig00000133 ),
    .I3(\blk00000003/sig0000013d ),
    .O(\blk00000003/sig00000142 )
  );
  LUT4 #(
    .INIT ( 16'h0444 ))
  \blk00000003/blk000000d0  (
    .I0(\blk00000003/sig00000134 ),
    .I1(\blk00000003/sig0000013f ),
    .I2(\blk00000003/sig00000133 ),
    .I3(\blk00000003/sig0000013d ),
    .O(\blk00000003/sig00000146 )
  );
  LUT4 #(
    .INIT ( 16'h0444 ))
  \blk00000003/blk000000cf  (
    .I0(\blk00000003/sig00000134 ),
    .I1(\blk00000003/sig00000141 ),
    .I2(\blk00000003/sig00000133 ),
    .I3(\blk00000003/sig0000013d ),
    .O(\blk00000003/sig00000135 )
  );
  LUT3 #(
    .INIT ( 8'h02 ))
  \blk00000003/blk000000ce  (
    .I0(\blk00000003/sig0000013d ),
    .I1(\blk00000003/sig00000133 ),
    .I2(\blk00000003/sig00000134 ),
    .O(\blk00000003/sig00000144 )
  );
  LUT3 #(
    .INIT ( 8'h8C ))
  \blk00000003/blk000000cd  (
    .I0(\blk00000003/sig00000126 ),
    .I1(\blk00000003/sig00000138 ),
    .I2(\blk00000003/sig00000134 ),
    .O(\blk00000003/sig00000139 )
  );
  LUT6 #(
    .INIT ( 64'h0000000000000001 ))
  \blk00000003/blk000000cc  (
    .I0(a_0[6]),
    .I1(a_0[7]),
    .I2(a_0[8]),
    .I3(a_0[9]),
    .I4(a_0[10]),
    .I5(a_0[11]),
    .O(\blk00000003/sig0000006c )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000cb  (
    .I0(a_0[36]),
    .I1(a_0[37]),
    .I2(a_0[38]),
    .I3(a_0[39]),
    .O(\blk00000003/sig00000114 )
  );
  LUT6 #(
    .INIT ( 64'h0000000000000001 ))
  \blk00000003/blk000000ca  (
    .I0(a_0[12]),
    .I1(a_0[13]),
    .I2(a_0[14]),
    .I3(a_0[15]),
    .I4(a_0[16]),
    .I5(a_0[17]),
    .O(\blk00000003/sig0000006e )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000c9  (
    .I0(a_0[52]),
    .I1(a_0[53]),
    .I2(a_0[54]),
    .I3(a_0[55]),
    .O(\blk00000003/sig00000127 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000c8  (
    .I0(a_0[40]),
    .I1(a_0[41]),
    .I2(a_0[42]),
    .I3(a_0[43]),
    .O(\blk00000003/sig00000112 )
  );
  LUT6 #(
    .INIT ( 64'h0000000000000001 ))
  \blk00000003/blk000000c7  (
    .I0(a_0[18]),
    .I1(a_0[19]),
    .I2(a_0[20]),
    .I3(a_0[21]),
    .I4(a_0[22]),
    .I5(a_0[23]),
    .O(\blk00000003/sig00000070 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000c6  (
    .I0(a_0[56]),
    .I1(a_0[57]),
    .I2(a_0[58]),
    .I3(a_0[59]),
    .O(\blk00000003/sig00000129 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000c5  (
    .I0(a_0[44]),
    .I1(a_0[45]),
    .I2(a_0[46]),
    .I3(a_0[47]),
    .O(\blk00000003/sig00000110 )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000c4  (
    .I0(a_0[48]),
    .I1(a_0[49]),
    .I2(a_0[50]),
    .I3(a_0[51]),
    .O(\blk00000003/sig0000010d )
  );
  LUT4 #(
    .INIT ( 16'h0001 ))
  \blk00000003/blk000000c3  (
    .I0(a_0[24]),
    .I1(a_0[25]),
    .I2(a_0[26]),
    .I3(a_0[27]),
    .O(\blk00000003/sig00000072 )
  );
  LUT3 #(
    .INIT ( 8'h80 ))
  \blk00000003/blk000000c2  (
    .I0(a_0[60]),
    .I1(a_0[61]),
    .I2(a_0[62]),
    .O(\blk00000003/sig00000131 )
  );
  LUT3 #(
    .INIT ( 8'h01 ))
  \blk00000003/blk000000c1  (
    .I0(a_0[60]),
    .I1(a_0[61]),
    .I2(a_0[62]),
    .O(\blk00000003/sig0000012b )
  );
  LUT4 #(
    .INIT ( 16'h1555 ))
  \blk00000003/blk000000c0  (
    .I0(a_0[62]),
    .I1(a_0[59]),
    .I2(a_0[60]),
    .I3(a_0[61]),
    .O(\blk00000003/sig0000013c )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000bf  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000135 ),
    .Q(\blk00000003/sig00000148 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000be  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000146 ),
    .Q(\blk00000003/sig00000147 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000bd  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000144 ),
    .Q(\blk00000003/sig00000145 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000bc  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000142 ),
    .Q(\blk00000003/sig00000143 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000bb  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000140 ),
    .Q(\blk00000003/sig00000141 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000ba  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000013e ),
    .Q(\blk00000003/sig0000013f )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000b9  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000013c ),
    .Q(\blk00000003/sig0000013d )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000b8  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000013a ),
    .Q(\blk00000003/sig0000013b )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000b7  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000139 ),
    .Q(\blk00000003/sig000000a9 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000b6  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(a_0[63]),
    .Q(\blk00000003/sig00000138 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000b5  (
    .C(clk),
    .D(\blk00000003/sig00000137 ),
    .Q(\blk00000003/sig000000b7 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000b4  (
    .C(clk),
    .D(\blk00000003/sig00000135 ),
    .Q(\blk00000003/sig00000136 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000b3  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000132 ),
    .Q(\blk00000003/sig00000134 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000b2  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000012c ),
    .Q(\blk00000003/sig00000133 )
  );
  MUXCY   \blk00000003/blk000000b1  (
    .CI(\blk00000003/sig00000130 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000131 ),
    .O(\blk00000003/sig00000132 )
  );
  MUXCY   \blk00000003/blk000000b0  (
    .CI(\blk00000003/sig0000012e ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig0000012f ),
    .O(\blk00000003/sig00000130 )
  );
  MUXCY   \blk00000003/blk000000af  (
    .CI(NlwRenamedSig_OI_operation_rfd),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig0000012d ),
    .O(\blk00000003/sig0000012e )
  );
  MUXCY   \blk00000003/blk000000ae  (
    .CI(\blk00000003/sig0000012a ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig0000012b ),
    .O(\blk00000003/sig0000012c )
  );
  MUXCY   \blk00000003/blk000000ad  (
    .CI(\blk00000003/sig00000128 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000129 ),
    .O(\blk00000003/sig0000012a )
  );
  MUXCY   \blk00000003/blk000000ac  (
    .CI(NlwRenamedSig_OI_operation_rfd),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000127 ),
    .O(\blk00000003/sig00000128 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk000000ab  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000010e ),
    .Q(\blk00000003/sig00000126 )
  );
  MUXCY   \blk00000003/blk000000aa  (
    .CI(NlwRenamedSig_OI_operation_rfd),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000125 ),
    .O(\blk00000003/sig00000123 )
  );
  MUXCY   \blk00000003/blk000000a9  (
    .CI(\blk00000003/sig00000123 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000124 ),
    .O(\blk00000003/sig00000121 )
  );
  MUXCY   \blk00000003/blk000000a8  (
    .CI(\blk00000003/sig00000121 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000122 ),
    .O(\blk00000003/sig0000011f )
  );
  MUXCY   \blk00000003/blk000000a7  (
    .CI(\blk00000003/sig0000011f ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000120 ),
    .O(\blk00000003/sig0000011d )
  );
  MUXCY   \blk00000003/blk000000a6  (
    .CI(\blk00000003/sig0000011d ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig0000011e ),
    .O(\blk00000003/sig0000011b )
  );
  MUXCY   \blk00000003/blk000000a5  (
    .CI(\blk00000003/sig0000011b ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig0000011c ),
    .O(\blk00000003/sig00000119 )
  );
  MUXCY   \blk00000003/blk000000a4  (
    .CI(\blk00000003/sig00000119 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig0000011a ),
    .O(\blk00000003/sig00000117 )
  );
  MUXCY   \blk00000003/blk000000a3  (
    .CI(\blk00000003/sig00000117 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000118 ),
    .O(\blk00000003/sig00000115 )
  );
  MUXCY   \blk00000003/blk000000a2  (
    .CI(\blk00000003/sig00000115 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000116 ),
    .O(\blk00000003/sig00000113 )
  );
  MUXCY   \blk00000003/blk000000a1  (
    .CI(\blk00000003/sig00000113 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000114 ),
    .O(\blk00000003/sig00000111 )
  );
  MUXCY   \blk00000003/blk000000a0  (
    .CI(\blk00000003/sig00000111 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000112 ),
    .O(\blk00000003/sig0000010f )
  );
  MUXCY   \blk00000003/blk0000009f  (
    .CI(\blk00000003/sig0000010f ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000110 ),
    .O(\blk00000003/sig0000010c )
  );
  MUXCY   \blk00000003/blk0000009e  (
    .CI(\blk00000003/sig0000010c ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig0000010d ),
    .O(\blk00000003/sig0000010e )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000009d  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000e8 ),
    .Q(\blk00000003/sig000000a3 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000009c  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000ea ),
    .Q(\blk00000003/sig0000010b )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000009b  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000ed ),
    .Q(\blk00000003/sig000000b6 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000009a  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000f0 ),
    .Q(\blk00000003/sig000000b9 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000099  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000f3 ),
    .Q(\blk00000003/sig000000bb )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000098  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000f6 ),
    .Q(\blk00000003/sig000000b2 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000097  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000f9 ),
    .Q(\blk00000003/sig000000b3 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000096  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000fc ),
    .Q(\blk00000003/sig000000b4 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000095  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000ff ),
    .Q(\blk00000003/sig000000b5 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000094  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000102 ),
    .Q(\blk00000003/sig000000ba )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000093  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000105 ),
    .Q(\blk00000003/sig000000bc )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000092  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000108 ),
    .Q(\blk00000003/sig000000be )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000091  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig0000010a ),
    .Q(\blk00000003/sig000000bd )
  );
  MUXCY   \blk00000003/blk00000090  (
    .CI(\blk00000003/sig000000c6 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000109 ),
    .O(\blk00000003/sig00000106 )
  );
  XORCY   \blk00000003/blk0000008f  (
    .CI(\blk00000003/sig000000c6 ),
    .LI(\blk00000003/sig00000109 ),
    .O(\blk00000003/sig0000010a )
  );
  MUXCY   \blk00000003/blk0000008e  (
    .CI(\blk00000003/sig00000106 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000107 ),
    .O(\blk00000003/sig00000103 )
  );
  XORCY   \blk00000003/blk0000008d  (
    .CI(\blk00000003/sig00000106 ),
    .LI(\blk00000003/sig00000107 ),
    .O(\blk00000003/sig00000108 )
  );
  MUXCY   \blk00000003/blk0000008c  (
    .CI(\blk00000003/sig00000103 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000104 ),
    .O(\blk00000003/sig00000100 )
  );
  XORCY   \blk00000003/blk0000008b  (
    .CI(\blk00000003/sig00000103 ),
    .LI(\blk00000003/sig00000104 ),
    .O(\blk00000003/sig00000105 )
  );
  MUXCY   \blk00000003/blk0000008a  (
    .CI(\blk00000003/sig00000100 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000101 ),
    .O(\blk00000003/sig000000fd )
  );
  XORCY   \blk00000003/blk00000089  (
    .CI(\blk00000003/sig00000100 ),
    .LI(\blk00000003/sig00000101 ),
    .O(\blk00000003/sig00000102 )
  );
  MUXCY   \blk00000003/blk00000088  (
    .CI(\blk00000003/sig000000fd ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000fe ),
    .O(\blk00000003/sig000000fa )
  );
  XORCY   \blk00000003/blk00000087  (
    .CI(\blk00000003/sig000000fd ),
    .LI(\blk00000003/sig000000fe ),
    .O(\blk00000003/sig000000ff )
  );
  MUXCY   \blk00000003/blk00000086  (
    .CI(\blk00000003/sig000000fa ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000fb ),
    .O(\blk00000003/sig000000f7 )
  );
  XORCY   \blk00000003/blk00000085  (
    .CI(\blk00000003/sig000000fa ),
    .LI(\blk00000003/sig000000fb ),
    .O(\blk00000003/sig000000fc )
  );
  MUXCY   \blk00000003/blk00000084  (
    .CI(\blk00000003/sig000000f7 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000f8 ),
    .O(\blk00000003/sig000000f4 )
  );
  XORCY   \blk00000003/blk00000083  (
    .CI(\blk00000003/sig000000f7 ),
    .LI(\blk00000003/sig000000f8 ),
    .O(\blk00000003/sig000000f9 )
  );
  MUXCY   \blk00000003/blk00000082  (
    .CI(\blk00000003/sig000000f4 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000f5 ),
    .O(\blk00000003/sig000000f1 )
  );
  XORCY   \blk00000003/blk00000081  (
    .CI(\blk00000003/sig000000f4 ),
    .LI(\blk00000003/sig000000f5 ),
    .O(\blk00000003/sig000000f6 )
  );
  MUXCY   \blk00000003/blk00000080  (
    .CI(\blk00000003/sig000000f1 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000f2 ),
    .O(\blk00000003/sig000000ee )
  );
  XORCY   \blk00000003/blk0000007f  (
    .CI(\blk00000003/sig000000f1 ),
    .LI(\blk00000003/sig000000f2 ),
    .O(\blk00000003/sig000000f3 )
  );
  MUXCY   \blk00000003/blk0000007e  (
    .CI(\blk00000003/sig000000ee ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000ef ),
    .O(\blk00000003/sig000000eb )
  );
  XORCY   \blk00000003/blk0000007d  (
    .CI(\blk00000003/sig000000ee ),
    .LI(\blk00000003/sig000000ef ),
    .O(\blk00000003/sig000000f0 )
  );
  MUXCY   \blk00000003/blk0000007c  (
    .CI(\blk00000003/sig000000eb ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000ec ),
    .O(\blk00000003/sig000000e9 )
  );
  XORCY   \blk00000003/blk0000007b  (
    .CI(\blk00000003/sig000000eb ),
    .LI(\blk00000003/sig000000ec ),
    .O(\blk00000003/sig000000ed )
  );
  MUXCY   \blk00000003/blk0000007a  (
    .CI(\blk00000003/sig000000e9 ),
    .DI(NlwRenamedSig_OI_operation_rfd),
    .S(NlwRenamedSig_OI_operation_rfd),
    .O(\blk00000003/sig000000e7 )
  );
  XORCY   \blk00000003/blk00000079  (
    .CI(\blk00000003/sig000000e9 ),
    .LI(NlwRenamedSig_OI_operation_rfd),
    .O(\blk00000003/sig000000ea )
  );
  XORCY   \blk00000003/blk00000078  (
    .CI(\blk00000003/sig000000e7 ),
    .LI(\blk00000003/sig00000002 ),
    .O(\blk00000003/sig000000e8 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000077  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000c5 ),
    .Q(\blk00000003/sig000000bf )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000076  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000c9 ),
    .Q(\blk00000003/sig000000c0 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000075  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000cc ),
    .Q(\blk00000003/sig000000a6 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000074  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000cf ),
    .Q(\blk00000003/sig000000a8 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000073  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000d2 ),
    .Q(\blk00000003/sig000000aa )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000072  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000d5 ),
    .Q(\blk00000003/sig000000ab )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000071  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000d8 ),
    .Q(\blk00000003/sig000000ac )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000070  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000db ),
    .Q(\blk00000003/sig000000ad )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000006f  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000de ),
    .Q(\blk00000003/sig000000b0 )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000006e  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000e1 ),
    .Q(\blk00000003/sig000000ae )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000006d  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000e4 ),
    .Q(\blk00000003/sig000000af )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000006c  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig000000e6 ),
    .Q(\blk00000003/sig000000b1 )
  );
  MUXCY   \blk00000003/blk0000006b  (
    .CI(\blk00000003/sig00000075 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000e5 ),
    .O(\blk00000003/sig000000e2 )
  );
  XORCY   \blk00000003/blk0000006a  (
    .CI(\blk00000003/sig00000075 ),
    .LI(\blk00000003/sig000000e5 ),
    .O(\blk00000003/sig000000e6 )
  );
  MUXCY   \blk00000003/blk00000069  (
    .CI(\blk00000003/sig000000e2 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000e3 ),
    .O(\blk00000003/sig000000df )
  );
  XORCY   \blk00000003/blk00000068  (
    .CI(\blk00000003/sig000000e2 ),
    .LI(\blk00000003/sig000000e3 ),
    .O(\blk00000003/sig000000e4 )
  );
  MUXCY   \blk00000003/blk00000067  (
    .CI(\blk00000003/sig000000df ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000e0 ),
    .O(\blk00000003/sig000000dc )
  );
  XORCY   \blk00000003/blk00000066  (
    .CI(\blk00000003/sig000000df ),
    .LI(\blk00000003/sig000000e0 ),
    .O(\blk00000003/sig000000e1 )
  );
  MUXCY   \blk00000003/blk00000065  (
    .CI(\blk00000003/sig000000dc ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000dd ),
    .O(\blk00000003/sig000000d9 )
  );
  XORCY   \blk00000003/blk00000064  (
    .CI(\blk00000003/sig000000dc ),
    .LI(\blk00000003/sig000000dd ),
    .O(\blk00000003/sig000000de )
  );
  MUXCY   \blk00000003/blk00000063  (
    .CI(\blk00000003/sig000000d9 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000da ),
    .O(\blk00000003/sig000000d6 )
  );
  XORCY   \blk00000003/blk00000062  (
    .CI(\blk00000003/sig000000d9 ),
    .LI(\blk00000003/sig000000da ),
    .O(\blk00000003/sig000000db )
  );
  MUXCY   \blk00000003/blk00000061  (
    .CI(\blk00000003/sig000000d6 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000d7 ),
    .O(\blk00000003/sig000000d3 )
  );
  XORCY   \blk00000003/blk00000060  (
    .CI(\blk00000003/sig000000d6 ),
    .LI(\blk00000003/sig000000d7 ),
    .O(\blk00000003/sig000000d8 )
  );
  MUXCY   \blk00000003/blk0000005f  (
    .CI(\blk00000003/sig000000d3 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000d4 ),
    .O(\blk00000003/sig000000d0 )
  );
  XORCY   \blk00000003/blk0000005e  (
    .CI(\blk00000003/sig000000d3 ),
    .LI(\blk00000003/sig000000d4 ),
    .O(\blk00000003/sig000000d5 )
  );
  MUXCY   \blk00000003/blk0000005d  (
    .CI(\blk00000003/sig000000d0 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000d1 ),
    .O(\blk00000003/sig000000cd )
  );
  XORCY   \blk00000003/blk0000005c  (
    .CI(\blk00000003/sig000000d0 ),
    .LI(\blk00000003/sig000000d1 ),
    .O(\blk00000003/sig000000d2 )
  );
  MUXCY   \blk00000003/blk0000005b  (
    .CI(\blk00000003/sig000000cd ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000ce ),
    .O(\blk00000003/sig000000ca )
  );
  XORCY   \blk00000003/blk0000005a  (
    .CI(\blk00000003/sig000000cd ),
    .LI(\blk00000003/sig000000ce ),
    .O(\blk00000003/sig000000cf )
  );
  MUXCY   \blk00000003/blk00000059  (
    .CI(\blk00000003/sig000000ca ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000cb ),
    .O(\blk00000003/sig000000c7 )
  );
  XORCY   \blk00000003/blk00000058  (
    .CI(\blk00000003/sig000000ca ),
    .LI(\blk00000003/sig000000cb ),
    .O(\blk00000003/sig000000cc )
  );
  MUXCY   \blk00000003/blk00000057  (
    .CI(\blk00000003/sig000000c7 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000c8 ),
    .O(\blk00000003/sig000000c3 )
  );
  XORCY   \blk00000003/blk00000056  (
    .CI(\blk00000003/sig000000c7 ),
    .LI(\blk00000003/sig000000c8 ),
    .O(\blk00000003/sig000000c9 )
  );
  MUXCY   \blk00000003/blk00000055  (
    .CI(\blk00000003/sig000000c3 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000c4 ),
    .O(\blk00000003/sig000000c6 )
  );
  XORCY   \blk00000003/blk00000054  (
    .CI(\blk00000003/sig000000c3 ),
    .LI(\blk00000003/sig000000c4 ),
    .O(\blk00000003/sig000000c5 )
  );
  FDRS   \blk00000003/blk00000053  (
    .C(clk),
    .D(\blk00000003/sig000000a5 ),
    .R(\blk00000003/sig000000c1 ),
    .S(\blk00000003/sig000000c2 ),
    .Q(result_1[23])
  );
  FDRS   \blk00000003/blk00000052  (
    .C(clk),
    .D(\blk00000003/sig000000a2 ),
    .R(\blk00000003/sig000000c1 ),
    .S(\blk00000003/sig000000c2 ),
    .Q(result_1[24])
  );
  FDRS   \blk00000003/blk00000051  (
    .C(clk),
    .D(\blk00000003/sig0000009f ),
    .R(\blk00000003/sig000000c1 ),
    .S(\blk00000003/sig000000c2 ),
    .Q(result_1[25])
  );
  FDRS   \blk00000003/blk00000050  (
    .C(clk),
    .D(\blk00000003/sig0000009c ),
    .R(\blk00000003/sig000000c1 ),
    .S(\blk00000003/sig000000c2 ),
    .Q(result_1[26])
  );
  FDRS   \blk00000003/blk0000004f  (
    .C(clk),
    .D(\blk00000003/sig00000099 ),
    .R(\blk00000003/sig000000c1 ),
    .S(\blk00000003/sig000000c2 ),
    .Q(result_1[27])
  );
  FDRS   \blk00000003/blk0000004e  (
    .C(clk),
    .D(\blk00000003/sig00000096 ),
    .R(\blk00000003/sig000000c1 ),
    .S(\blk00000003/sig000000c2 ),
    .Q(result_1[28])
  );
  FDRS   \blk00000003/blk0000004d  (
    .C(clk),
    .D(\blk00000003/sig00000093 ),
    .R(\blk00000003/sig000000c1 ),
    .S(\blk00000003/sig000000c2 ),
    .Q(result_1[29])
  );
  FDRS   \blk00000003/blk0000004c  (
    .C(clk),
    .D(\blk00000003/sig00000090 ),
    .R(\blk00000003/sig000000c1 ),
    .S(\blk00000003/sig000000c2 ),
    .Q(result_1[30])
  );
  FDRS   \blk00000003/blk0000004b  (
    .C(clk),
    .D(\blk00000003/sig000000c0 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[10])
  );
  FDRS   \blk00000003/blk0000004a  (
    .C(clk),
    .D(\blk00000003/sig000000bf ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[11])
  );
  FDRS   \blk00000003/blk00000049  (
    .C(clk),
    .D(\blk00000003/sig000000be ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[13])
  );
  FDRS   \blk00000003/blk00000048  (
    .C(clk),
    .D(\blk00000003/sig000000bd ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[12])
  );
  FDRS   \blk00000003/blk00000047  (
    .C(clk),
    .D(\blk00000003/sig000000bc ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[14])
  );
  FDRS   \blk00000003/blk00000046  (
    .C(clk),
    .D(\blk00000003/sig000000bb ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[20])
  );
  FDRS   \blk00000003/blk00000045  (
    .C(clk),
    .D(\blk00000003/sig000000ba ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[15])
  );
  FDRS   \blk00000003/blk00000044  (
    .C(clk),
    .D(\blk00000003/sig000000b9 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[21])
  );
  FDRS   \blk00000003/blk00000043  (
    .C(clk),
    .D(\blk00000003/sig000000b6 ),
    .R(\blk00000003/sig000000b7 ),
    .S(\blk00000003/sig000000b8 ),
    .Q(result_1[22])
  );
  FDRS   \blk00000003/blk00000042  (
    .C(clk),
    .D(\blk00000003/sig000000b5 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[16])
  );
  FDRS   \blk00000003/blk00000041  (
    .C(clk),
    .D(\blk00000003/sig000000b4 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[17])
  );
  FDRS   \blk00000003/blk00000040  (
    .C(clk),
    .D(\blk00000003/sig000000b3 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[18])
  );
  FDRS   \blk00000003/blk0000003f  (
    .C(clk),
    .D(\blk00000003/sig000000b2 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[19])
  );
  FDRS   \blk00000003/blk0000003e  (
    .C(clk),
    .D(\blk00000003/sig000000b1 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[0])
  );
  FDRS   \blk00000003/blk0000003d  (
    .C(clk),
    .D(\blk00000003/sig000000b0 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[3])
  );
  FDRS   \blk00000003/blk0000003c  (
    .C(clk),
    .D(\blk00000003/sig000000af ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[1])
  );
  FDRS   \blk00000003/blk0000003b  (
    .C(clk),
    .D(\blk00000003/sig000000ae ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[2])
  );
  FDRS   \blk00000003/blk0000003a  (
    .C(clk),
    .D(\blk00000003/sig000000ad ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[4])
  );
  FDRS   \blk00000003/blk00000039  (
    .C(clk),
    .D(\blk00000003/sig000000ac ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[5])
  );
  FDRS   \blk00000003/blk00000038  (
    .C(clk),
    .D(\blk00000003/sig000000ab ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[6])
  );
  FDRS   \blk00000003/blk00000037  (
    .C(clk),
    .D(\blk00000003/sig000000aa ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[7])
  );
  FDRS   \blk00000003/blk00000036  (
    .C(clk),
    .D(\blk00000003/sig000000a9 ),
    .R(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[31])
  );
  FDRS   \blk00000003/blk00000035  (
    .C(clk),
    .D(\blk00000003/sig000000a8 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[8])
  );
  FDRS   \blk00000003/blk00000034  (
    .C(clk),
    .D(\blk00000003/sig000000a6 ),
    .R(\blk00000003/sig000000a7 ),
    .S(\blk00000003/sig00000002 ),
    .Q(result_1[9])
  );
  MUXCY   \blk00000003/blk00000033  (
    .CI(\blk00000003/sig000000a3 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000a4 ),
    .O(\blk00000003/sig000000a0 )
  );
  XORCY   \blk00000003/blk00000032  (
    .CI(\blk00000003/sig000000a3 ),
    .LI(\blk00000003/sig000000a4 ),
    .O(\blk00000003/sig000000a5 )
  );
  MUXCY   \blk00000003/blk00000031  (
    .CI(\blk00000003/sig000000a0 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig000000a1 ),
    .O(\blk00000003/sig0000009d )
  );
  XORCY   \blk00000003/blk00000030  (
    .CI(\blk00000003/sig000000a0 ),
    .LI(\blk00000003/sig000000a1 ),
    .O(\blk00000003/sig000000a2 )
  );
  MUXCY   \blk00000003/blk0000002f  (
    .CI(\blk00000003/sig0000009d ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig0000009e ),
    .O(\blk00000003/sig0000009a )
  );
  XORCY   \blk00000003/blk0000002e  (
    .CI(\blk00000003/sig0000009d ),
    .LI(\blk00000003/sig0000009e ),
    .O(\blk00000003/sig0000009f )
  );
  MUXCY   \blk00000003/blk0000002d  (
    .CI(\blk00000003/sig0000009a ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig0000009b ),
    .O(\blk00000003/sig00000097 )
  );
  XORCY   \blk00000003/blk0000002c  (
    .CI(\blk00000003/sig0000009a ),
    .LI(\blk00000003/sig0000009b ),
    .O(\blk00000003/sig0000009c )
  );
  MUXCY   \blk00000003/blk0000002b  (
    .CI(\blk00000003/sig00000097 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000098 ),
    .O(\blk00000003/sig00000094 )
  );
  XORCY   \blk00000003/blk0000002a  (
    .CI(\blk00000003/sig00000097 ),
    .LI(\blk00000003/sig00000098 ),
    .O(\blk00000003/sig00000099 )
  );
  MUXCY   \blk00000003/blk00000029  (
    .CI(\blk00000003/sig00000094 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000095 ),
    .O(\blk00000003/sig00000091 )
  );
  XORCY   \blk00000003/blk00000028  (
    .CI(\blk00000003/sig00000094 ),
    .LI(\blk00000003/sig00000095 ),
    .O(\blk00000003/sig00000096 )
  );
  MUXCY   \blk00000003/blk00000027  (
    .CI(\blk00000003/sig00000091 ),
    .DI(\blk00000003/sig00000002 ),
    .S(\blk00000003/sig00000092 ),
    .O(\blk00000003/sig0000008e )
  );
  XORCY   \blk00000003/blk00000026  (
    .CI(\blk00000003/sig00000091 ),
    .LI(\blk00000003/sig00000092 ),
    .O(\blk00000003/sig00000093 )
  );
  XORCY   \blk00000003/blk00000025  (
    .CI(\blk00000003/sig0000008e ),
    .LI(\blk00000003/sig0000008f ),
    .O(\blk00000003/sig00000090 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000024  (
    .C(clk),
    .D(a_0[28]),
    .Q(\blk00000003/sig0000008d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000023  (
    .C(clk),
    .D(a_0[29]),
    .Q(\blk00000003/sig0000008c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000022  (
    .C(clk),
    .D(a_0[30]),
    .Q(\blk00000003/sig0000008b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000021  (
    .C(clk),
    .D(a_0[31]),
    .Q(\blk00000003/sig0000008a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000020  (
    .C(clk),
    .D(a_0[32]),
    .Q(\blk00000003/sig00000089 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000001f  (
    .C(clk),
    .D(a_0[33]),
    .Q(\blk00000003/sig00000088 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000001e  (
    .C(clk),
    .D(a_0[34]),
    .Q(\blk00000003/sig00000087 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000001d  (
    .C(clk),
    .D(a_0[35]),
    .Q(\blk00000003/sig00000086 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000001c  (
    .C(clk),
    .D(a_0[36]),
    .Q(\blk00000003/sig00000085 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000001b  (
    .C(clk),
    .D(a_0[37]),
    .Q(\blk00000003/sig00000084 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000001a  (
    .C(clk),
    .D(a_0[38]),
    .Q(\blk00000003/sig00000083 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000019  (
    .C(clk),
    .D(a_0[39]),
    .Q(\blk00000003/sig00000082 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000018  (
    .C(clk),
    .D(a_0[40]),
    .Q(\blk00000003/sig00000081 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000017  (
    .C(clk),
    .D(a_0[41]),
    .Q(\blk00000003/sig00000080 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000016  (
    .C(clk),
    .D(a_0[42]),
    .Q(\blk00000003/sig0000007f )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000015  (
    .C(clk),
    .D(a_0[43]),
    .Q(\blk00000003/sig0000007e )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000014  (
    .C(clk),
    .D(a_0[44]),
    .Q(\blk00000003/sig0000007d )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000013  (
    .C(clk),
    .D(a_0[45]),
    .Q(\blk00000003/sig0000007c )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000012  (
    .C(clk),
    .D(a_0[46]),
    .Q(\blk00000003/sig0000007b )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000011  (
    .C(clk),
    .D(a_0[47]),
    .Q(\blk00000003/sig0000007a )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000010  (
    .C(clk),
    .D(a_0[48]),
    .Q(\blk00000003/sig00000079 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000000f  (
    .C(clk),
    .D(a_0[49]),
    .Q(\blk00000003/sig00000078 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000000e  (
    .C(clk),
    .D(a_0[50]),
    .Q(\blk00000003/sig00000077 )
  );
  FD #(
    .INIT ( 1'b0 ))
  \blk00000003/blk0000000d  (
    .C(clk),
    .D(a_0[51]),
    .Q(\blk00000003/sig00000076 )
  );
  MUXCY   \blk00000003/blk0000000c  (
    .CI(\blk00000003/sig00000069 ),
    .DI(\blk00000003/sig00000073 ),
    .S(\blk00000003/sig00000074 ),
    .O(\blk00000003/sig00000075 )
  );
  MUXCY   \blk00000003/blk0000000b  (
    .CI(\blk00000003/sig00000071 ),
    .DI(NlwRenamedSig_OI_operation_rfd),
    .S(\blk00000003/sig00000072 ),
    .O(\blk00000003/sig00000068 )
  );
  MUXCY   \blk00000003/blk0000000a  (
    .CI(\blk00000003/sig0000006f ),
    .DI(NlwRenamedSig_OI_operation_rfd),
    .S(\blk00000003/sig00000070 ),
    .O(\blk00000003/sig00000071 )
  );
  MUXCY   \blk00000003/blk00000009  (
    .CI(\blk00000003/sig0000006d ),
    .DI(NlwRenamedSig_OI_operation_rfd),
    .S(\blk00000003/sig0000006e ),
    .O(\blk00000003/sig0000006f )
  );
  MUXCY   \blk00000003/blk00000008  (
    .CI(\blk00000003/sig0000006b ),
    .DI(NlwRenamedSig_OI_operation_rfd),
    .S(\blk00000003/sig0000006c ),
    .O(\blk00000003/sig0000006d )
  );
  MUXCY   \blk00000003/blk00000007  (
    .CI(\blk00000003/sig00000002 ),
    .DI(NlwRenamedSig_OI_operation_rfd),
    .S(\blk00000003/sig0000006a ),
    .O(\blk00000003/sig0000006b )
  );
  FDE #(
    .INIT ( 1'b0 ))
  \blk00000003/blk00000006  (
    .C(clk),
    .CE(NlwRenamedSig_OI_operation_rfd),
    .D(\blk00000003/sig00000068 ),
    .Q(\blk00000003/sig00000069 )
  );
  VCC   \blk00000003/blk00000005  (
    .P(NlwRenamedSig_OI_operation_rfd)
  );
  GND   \blk00000003/blk00000004  (
    .G(\blk00000003/sig00000002 )
  );

// synthesis translate_on

endmodule

// synthesis translate_off

`ifndef GLBL
`define GLBL

`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

    wire GSR;
    wire GTS;
    wire PRLD;

    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (weak1, weak0) GSR = GSR_int;
    assign (weak1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule

`endif

// synthesis translate_on
