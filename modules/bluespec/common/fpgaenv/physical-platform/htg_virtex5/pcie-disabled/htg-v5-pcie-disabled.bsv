//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
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
