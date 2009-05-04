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

import FIFO::*;
import Clocks::*;

// htg-v5-pcie-disabled

// The Physical Platform for the HTG Virtex 5 in independent mode 
// without PCI Express.

`include "led-device.bsh"
`include "switch-device.bsh"
`include "ddr2_sdram_device.bsh"
`include "clocks_driver.bsh"
`include "physical_platform_utils.bsh"

// 8 switches and leds

`define NUMBER_LEDS 8;
`define NUMBER_SWITCHES 8;

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;

    interface CLOCKS_DRIVER                      clocksDriver;
    interface LEDS_DRIVER#(`NUMBER_LEDS)         ledsDriver;
    interface SWITCHES_DRIVER#(`NUMBER_SWITCHES) switchesDriver;
    interface DDR2_SDRAM_DRIVER                  ddr2SDRAMDriver;
        
endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;

    (* prefix = "" *)
    interface CLOCKS_WIRES                      clocksWires;
    interface LEDS_WIRES#(`NUMBER_LEDS)         ledsWires;
    interface SWITCHES_WIRES#(`NUMBER_SWITCHES) switchesWires;
    interface DDR2_SDRAM_WIRES                  ddr2SDRAMWires;
    
endinterface

// PHYSICAL_PLATFORM

// The platform is the aggregation of wires and drivers.

interface PHYSICAL_PLATFORM;

    interface PHYSICAL_DRIVERS physicalDrivers;
    interface TOP_LEVEL_WIRES  topLevelWires;

endinterface

// mkPhysicalPlatform

// This is a convenient way for the outside world to instantiate all the devices
// and an aggregation of all the wires.

module mkPhysicalPlatform
       //interface: 
                    (PHYSICAL_PLATFORM);
    
    // The Platform is instantiated inside a NULL clock domain. Our first course of
    // action should be to instantiate the Clocks Physical Device and obtain interfaces
    // to clock and reset the other devices with.
    
    CLOCKS_DEVICE clocks_device <- mkClocksDevice();
    
    Clock clk = clocks_device.driver.clock;
    Reset rst = clocks_device.driver.reset;

    // No soft reset mechanism is available without the PCI-Express device
    // TODO: wire up a switch to act as soft-reset, perhaps?

    // Finally, instantiate all other physical devices
    
    LEDS_DEVICE#(`NUMBER_LEDS)         leds_device       <- mkLEDsDevice(clocked_by clk, reset_by rst);
    SWITCHES_DEVICE#(`NUMBER_SWITCHES) switches_device   <- mkSwitchesDevice(clocked_by clk, reset_by rst);
    DDR2_SDRAM_DEVICE                  ddr2_sdram_device <- mkDDR2SDRAMDevice(clocks_device.driver.rawClock,
                                                                              clocks_device.driver.rawReset,
                                                                              clocked_by clk,
                                                                              reset_by   rst);

    // Aggregate the drivers
    
    interface PHYSICAL_DRIVERS physicalDrivers;
    
        interface clocksDriver     = clocks_device.driver;
        interface ledsDriver       = leds_device.driver;
        interface switchesDriver   = switches_device.driver;
        interface ddr2SDRAMDriver  = ddr2_sdram_device.driver;
    
    endinterface
    
    // Aggregate the wires
    
    interface TOP_LEVEL_WIRES topLevelWires;
    
        interface clocksWires      = clocks_device.wires;
        interface ledsWires        = leds_device.wires;
        interface switchesWires    = switches_device.wires;
        interface ddr2SDRAMWires   = ddr2_sdram_device.wires;

    endinterface
               
endmodule
