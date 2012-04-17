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

// Conservative Virtex 6 parameters...
// If you have a better speed grade, you might try something different.
Real fINmin  = 10;
Real fINmax  = 700;
Real fVCOmin = 600;
Real fVCOmax = 1200;
Real fPFDmin = 10;
Real fPFDmax = 450;
Real fOUTmin = 4.69;
Real fOUTmax = 700;
Integer dMax = 80;
Integer mMax = 64;
Integer outDivMax = 128;
