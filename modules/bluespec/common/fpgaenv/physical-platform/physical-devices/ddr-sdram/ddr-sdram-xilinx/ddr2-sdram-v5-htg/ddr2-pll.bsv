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

interface DDR2_PLL;

    interface Clock clk_150;
    interface Clock clk_200;
    interface Reset rst;

endinterface

import "BVI"
module mkDDR2PLL
    // Interface:
        (DDR2_PLL);

    default_clock (CLK);
    default_reset (RST_N);
    
    output_clock clk_150 (CLK_150_OUT);
    output_clock clk_200 (CLK_200_OUT);

    output_reset rst (RST_N_OUT) clocked_by (clk_150);

endmodule
