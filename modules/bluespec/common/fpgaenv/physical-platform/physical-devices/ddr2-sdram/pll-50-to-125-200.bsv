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

interface PLL_50_TO_125_200;

    interface Clock clk_125;
    interface Clock clk_200;
    interface Reset rst;

endinterface

import "BVI"
module mkPLL_50_to_125_200
    // Interface:
        (PLL_50_TO_125_200);

    default_clock (CLK);
    default_reset (RST_N);
    
    output_clock clk_125 (CLK_125_OUT);
    output_clock clk_200 (CLK_200_OUT);

    output_reset rst (RST_N_OUT) clocked_by (clk_125);

endmodule
