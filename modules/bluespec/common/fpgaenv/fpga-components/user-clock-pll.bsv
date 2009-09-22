//
// Copyright (C) 2008 Intel Corporation
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
// Generate clocks of requested frequency.
//

import Clocks::*;

// verilog only
import "BVI"
module mkUserClock_Ratio_PLL#(Integer inFreq,
                              Integer clockMultiplier,
                              Integer clockDivider)
    // Interface:
        (UserClock);

    default_clock (CLK);
    default_reset (RST_N);
    output_clock clk (CLK_OUT);
    output_reset rst (RST_N_OUT) clocked_by (clk);

    // Convert frequency (MHz) to period (ns)
    parameter CR_CLKIN_PERIOD = 1000 / inFreq;
    parameter CR_CLKOUT_MULTIPLY = clockMultiplier;
    parameter CR_CLKOUT_DIVIDE = clockDivider;

endmodule

//
// mkUserClock_PLL --
//   Generate a user clock based on the incoming frequency that is multiplied
//   by clockMultiplier and divided by clockDivider.
//
//   Uses a PLL instead of a DCM.
//
//   Picks the best source given a few standard ratios.
//
module mkUserClock_PLL#(Integer inFreq, Integer clockMultiplier, Integer clockDivider)
        (UserClock);

    UserClock clk = ?;

  `ifdef SYNTH

    // FPGA synthesis...

    if (clockMultiplier ==  clockDivider)
        clk <- mkUserClock_Same;
    else if (clockMultiplier == 1 && clockDivider == 2)
        clk <- mkUserClock_DivideByTwo;
    else
        clk <- mkUserClock_Ratio_PLL(inFreq, clockMultiplier, clockDivider);

  `else

    // Clock ratios make no sense in Bluesim
    clk <- mkUserClock_Same;

  `endif

    return clk;

endmodule
