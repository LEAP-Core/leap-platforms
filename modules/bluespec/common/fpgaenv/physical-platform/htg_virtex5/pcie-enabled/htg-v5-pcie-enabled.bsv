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

// htg-v5-pcie-enabled

// The Physical Platform for the HTG Virtex 5 with PCI Express.

`include "led_device.bsh"
`include "switch_device.bsh"
`include "pci_express_device.bsh"
`include "ddr2_sdram_device.bsh"

// 8 switches and leds

`define NUMBER_LEDS 8
`define NUMBER_SWITCHES 8

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;

    interface LEDS_DRIVER#(`NUMBER_LEDS)         ledsDriver;
    interface SWITCHES_DRIVER#(`NUMBER_SWITCHES) switchesDriver;
    interface PCI_EXPRESS_DRIVER                 pciExpressDriver;
    interface DDR2_SDRAM_DRIVER                  ddr2SDRAMDriver;
        
    // each set of physical drivers must support a soft reset method
    method Action soft_reset();
        
endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;

    interface LEDS_WIRES#(`NUMBER_LEDS)          ledsWires;
    interface SWITCHES_WIRES#(`NUMBER_SWITCHES)  switchesWires;
    interface PCI_EXPRESS_WIRES                  pciExpressWires;
    interface DDR2_SDRAM_WIRES                   ddr2SDRAMWires;
    
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

module mkPhysicalPlatform#(Clock topLevelClock, Reset topLevelReset)
       //interface: 
                    (PHYSICAL_PLATFORM);
    
    // Submodules
    
    LEDS_DEVICE#(`NUMBER_LEDS)         leds_device         <- mkLEDsDevice(topLevelClock, topLevelReset);
    SWITCHES_DEVICE#(`NUMBER_SWITCHES) switches_device     <- mkSwitchesDevice(topLevelClock, topLevelReset);
    PCI_EXPRESS_DEVICE                 pci_express_device  <- mkPCIExpressDevice();
    DDR2_SDRAM_DEVICE                  ddr2_sdram_device   <- mkDDR2SDRAMDevice(topLevelClock, topLevelReset);

    // Aggregate the drivers
    
    interface PHYSICAL_DRIVERS physicalDrivers;
    
        interface ledsDriver       = leds_device.driver;
        interface switchesDriver   = switches_device.driver;
        interface pciExpressDriver = pci_express_device.driver;
        interface ddr2SDRAMDriver  = ddr2_sdram_device.driver;
    
        // Soft Reset method
        method soft_reset = pci_express_device.driver.softReset;
    
    endinterface
    
    // Aggregate the wires
    
    interface TOP_LEVEL_WIRES topLevelWires;
    
        interface ledsWires        = leds_device.wires;
        interface switchesWires    = switches_device.wires;
        interface pciExpressWires  = pci_express_device.wires;
        interface ddr2SDRAMWires   = ddr2_sdram_device.wires;

    endinterface
               
endmodule
