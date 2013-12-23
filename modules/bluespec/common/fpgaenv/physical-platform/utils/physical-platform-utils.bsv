//
// Copyright (C) 2011 Intel Corporation
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

`include "awb/provides/physical_platform_utils.bsh"

//
// Convert preprocessor parameters to functions so they are included as part
// of the physical platform.
//
function Integer fpgaPlatformID()   = `FPGA_PLATFORM_ID;
function String  fpgaPlatformName() = `FPGA_PLATFORM_NAME;

function Integer fpgaNumPlatforms() = `FPGA_NUM_PLATFORMS;

//
// FPGA_PLATFORM_IDX is a container for FPGA_PLATFORM_ID.  Must be at least
// one bit.
//
typedef UInt#(TMax#(1, TLog#(TAdd#(1,`FPGA_NUM_PLATFORMS)))) FPGA_PLATFORM_ID;
