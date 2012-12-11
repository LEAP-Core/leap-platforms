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
import Real::*;

//
// Conservative Virtex 7 parameters...
// If you have a better speed grade, you might try something different.
//
// *** These are MMCM parameters taken from UG472 (MMCM Attributes) and
// *** DS182 (MMCM Switching Characteristics).  In spite of the module
// *** interface names saying PLL, we use MMCM's on Virtex 7.
//
Real fINmin  = 10;
Real fINmax  = 800;
Real fVCOmin = 600;
Real fVCOmax = 1200;
Real fPFDmin = 10;
Real fPFDmax = 450;
Real fOUTmin = 4.69;
Real fOUTmax = 800;
Integer dMax = 106;
Integer mMax = 64;
Integer outDivMax = 128;

//
// mkUserClock_Ratio converts the requested multiplier and divisor into
// a target frequency and then uses the general code to compute parameters
// appropriate to the hardware.  This allows us to use old code with
// ratios that may be invalid on current hardware.
//
module mkUserClock_Ratio#(Integer inFreq,
                          Integer clockMultiplier,
                          Integer clockDivider)  
    (UserClock);

    let clk <- mkUserClock_PLL(inFreq,
                               inFreq*clockMultiplier/clockDivider);

    return clk;
endmodule