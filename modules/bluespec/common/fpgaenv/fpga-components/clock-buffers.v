//
// Copyright (C) 2009 Intel Corporation
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

`timescale 1ns / 1ps

//
// Clock Buffer
//

module clock_buffer(CLK, CLK_GATE, RST_N,
                    CLK_IN, CLK_OUT);

    input CLK;      // ignore
    input CLK_GATE; // ignore
    input RST_N;    // ignore
   
    input CLK_IN;
   output CLK_OUT;

   BUFG CLK_BUFG_INST (.I(CLK_IN), 
                       .O(CLK_OUT));

endmodule

//
// Clock Input Buffer
//

module clock_input_buffer(CLK, CLK_GATE, RST_N,
                          CLK_IN, CLK_OUT);

    input CLK;      // ignore
    input CLK_GATE; // ignore
    input RST_N;    // ignore
   
    input CLK_IN;
   output CLK_OUT;

   IBUFG CLK_IBUFG_INST (.I(CLK_IN), 
                         .O(CLK_OUT));

endmodule
