/*****************************************************************************
 * std-virtual-platform.h
 *
 * Copyright (C) 2008 Intel Corporation
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/**
 * @file std-virtual-platform.bsv
 * @author Michael Pellauer
 * @brief Standard virtual platform interface
 */

`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/virtual_devices.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/clocks_device.bsh"

interface VIRTUAL_PLATFORM;

    interface LowLevelPlatformInterface llpint;
    interface VIRTUAL_DEVICES virtualDevices;

endinterface

module mkVirtualPlatform
    // interface:
        (VIRTUAL_PLATFORM);

    let llpi <- mkLowLevelPlatformInterface();

    Clock clk = llpi.physicalDrivers.clocksDriver.clock;
    Reset rst = llpi.physicalDrivers.clocksDriver.reset;

    let vdevs  <- mkVirtualDevices(llpi, clocked_by clk, reset_by rst);
    
    interface llpint = llpi;
    interface virtualDevices = vdevs;

endmodule
