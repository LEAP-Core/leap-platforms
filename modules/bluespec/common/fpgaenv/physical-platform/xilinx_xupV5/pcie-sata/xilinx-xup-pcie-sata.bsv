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
import Vector::*;
import Clocks::*;

// The Physical Platform for the XUP Virtex 5 with PCIE

`include "pcie_device.bsh"
`include "sata_device.bsh"
`include "clocks_device.bsh"
`include "physical_platform_utils.bsh"

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;
    
    interface CLOCKS_DRIVER                        clocksDriver;
    interface XUPV5_SERDES_DRIVER                  sataDriver;
    interface PCIE_DRIVER                          pcieDriver;
        
endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;

    // wires from devices
    (* prefix = "" *)
    interface CLOCKS_WIRES                        clocksWires;
    (* prefix = "" *)
    interface XUPV5_SERDES_WIRES                  sataWires;
    interface PCIE_WIRES                          pcieWires;

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

    // Next, create the physical device that can trigger a soft reset. Pass along the
    // interface to the trigger module that the clocks device has given us.

   XUPV5_SERDES_BYTE comma  = serdesControl(60);
   XUPV5_SERDES_WORD commas = serdesWord(comma, comma); 
   XUPV5_SERDES_BYTE idle  = serdesControl(0);
   XUPV5_SERDES_WORD idles = serdesWord(idle, idle); 
   XUPV5_SERDES_BYTE eop    = serdesControl(28);
   XUPV5_SERDES_WORD eops   = serdesWord(eop, eop); 
   
   let sata_device <- mkXUPV5_SERDES_DEVICE(comma, 65535, 16);


   PCIE_DEVICE pcie_device <- mkPCIEDevice(clocks_device.driver.rawClock,
                                           clocks_device.driver.rawReset,
                                           clocked_by clk,
                                           reset_by rst);

    // Aggregate the drivers
    
    interface PHYSICAL_DRIVERS physicalDrivers;
    
        interface clocksDriver     = clocks_device.driver;
        interface sataDriver       = sata_device.driver;
        interface pcieDriver       = pcie_device.driver;

    endinterface
    
    // Aggregate the wires
    
    interface TOP_LEVEL_WIRES topLevelWires;

        interface clocksWires      = clocks_device.wires;
        interface sataWires        = sata_device.wires;
        interface pcieWires        = pcie_device.wires;

    endinterface
               
endmodule
