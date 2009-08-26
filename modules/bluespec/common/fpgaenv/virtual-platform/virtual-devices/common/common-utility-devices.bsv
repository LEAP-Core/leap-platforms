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

`include "asim/provides/streams_device.bsh"
`include "asim/provides/dynamic_parameters_device.bsh"
`include "asim/provides/debug_scan_device.bsh"
`include "asim/provides/assertions_device.bsh"
`include "asim/provides/stats_device.bsh"

// A set of useful IO services.

interface COMMON_UTILITY_DEVICES;

    interface STREAMS streams;
    interface DYNAMIC_PARAMETERS dynamicParameters;
    interface DEBUG_SCAN_DEVICE debugScan;
    interface ASSERTIONS assertions;
    interface STATS stats;

endinterface

//
// mkCommonUtilityDevices --
//
// Instantiate useful IO utilities
//

module mkCommonUtilityDevices#(LowLevelPlatformInterface llpi)
    // interface:
    (COMMON_UTILITY_DEVICES);

    let str <- mkStreamsDevice(llpi);
    let dp  <- mkDynamicParametersDevice(llpi);
    let db  <- mkDebugScanDevice(llpi);
    let as  <- mkAssertionsDevice(llpi);
    let st  <- mkStatsDevice(llpi);

    interface streams = str;
    interface dynamicParameters = dp;
    interface debugScan = db;
    interface assertions = as;
    interface stats = st;

endmodule
