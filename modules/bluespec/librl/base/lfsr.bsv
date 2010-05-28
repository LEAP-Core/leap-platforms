//
// Copyright (C) 2010 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

//
// Support functions for using LFSRs.
//

//
// lfsr32FeedPolynomials --
//     Provide a set of optimal polynomials for generating random values using
//     an LFSR.  Each polynomial generates a different sequence.
//
//     These feedback terms were taken from the table at:
//         http://www.ece.cmu.edu/~koopman/lfsr/index.html
//
function Bit#(32) lfsr32FeedPolynomials(Integer n);
        Bit#(32) feed = case (n % 32)
                            0 : return 32'h80000057;
                            1 : return 32'h80000062;
                            2 : return 32'h8000007A;
                            3 : return 32'h80000092;
                            4 : return 32'h800000B9;
                            5 : return 32'h800000BA;
                            6 : return 32'h80000106;
                            7 : return 32'h80000114;
                            8 : return 32'h8000012D;
                            9 : return 32'h8000014E;
                           10 : return 32'h8000016C;
                           11 : return 32'h8000019F;
                           12 : return 32'h800001A6;
                           13 : return 32'h800001F3;
                           14 : return 32'h8000020F;
                           15 : return 32'h800002CC;
                           16 : return 32'h80000349;
                           17 : return 32'h80000370;
                           18 : return 32'h80000375;
                           19 : return 32'h80000392;
                           20 : return 32'h80000398;
                           21 : return 32'h800003BF;
                           22 : return 32'h800003D6;
                           23 : return 32'h800003DF;
                           24 : return 32'h800003E9;
                           25 : return 32'h80000412;
                           26 : return 32'h80000414;
                           27 : return 32'h80000417;
                           28 : return 32'h80000465;
                           29 : return 32'h8000046A;
                           30 : return 32'h80000478;
                           31 : return 32'h800004D4;
                        endcase;

    return feed;
endfunction
