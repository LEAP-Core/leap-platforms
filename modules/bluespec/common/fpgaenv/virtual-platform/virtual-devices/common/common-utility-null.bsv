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


`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/streams.bsh"

// A set of useful IO services.

interface COMMON_UTILITY_DEVICES;
    
    interface Streams streams;

endinterface

//
// mkCommonUtilityDevices --
//
// Instantiate useful IO utilities
//

module mkCommonUtilityDevices#(LowLevelPlatformInterface llpi)
    // interface:
    (COMMON_UTILITY_DEVICES);

    let str <- mkStreams(llpi);
    
    interface streams = str;

endmodule
