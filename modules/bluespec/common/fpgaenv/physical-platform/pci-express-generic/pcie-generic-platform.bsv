//
// Copyright (C) 2012 Intel Corporation
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

//
// Standard physical platform for PCIe boards with on-board DDR storage
//

`include "awb/provides/pcie_device.bsh"
`include "awb/provides/clocks_device.bsh"
`include "awb/provides/ddr_sdram_device.bsh"
`include "awb/provides/physical_platform_utils.bsh"

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;
    interface CLOCKS_DRIVER                        clocksDriver;
    interface PCIE_DRIVER                          pcieDriver;
    interface Vector#(FPGA_DDR_BANKS, DDR_DRIVER)  ddrDriver;
endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;
    // wires from devices
    interface PCIE_WIRES                          pcieWires;
    interface DDR_WIRES                           ddrWires;
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

module mkPhysicalPlatform#(Vector#(`N_TOP_LEVEL_CLOCKS, Clock) topClocks, Reset topReset)
    //interface: 
    (PHYSICAL_PLATFORM);
    
    // The Platform is instantiated inside a NULL clock domain. Our first course of
    // action should be to instantiate the Clocks Physical Device and obtain interfaces
    // to clock and reset the other devices with.
    
    CLOCKS_DEVICE clocks <- mkClocksDevice(topClocks, topReset);
    
    Clock clk = clocks.driver.clock;
    Reset rst = clocks.driver.reset;

    // There is a strong assumption that the clock for this module is the 200MHz
    // differential clock.
    DDR_DEVICE sdram <- mkDDRDevice(clocks.driver.rawClock,
                                    clocks.driver.rawReset, 
                                    clocked_by clocks.driver.clock,
                                    reset_by clocks.driver.reset);

    // Next, create the physical device that can trigger a soft reset. Pass along the
    // interface to the trigger module that the clocks device has given us.

    PCIE_DEVICE pcie <- mkPCIEDevice(clocks.driver.rawClock,
                                     clocks.driver.rawReset);

    //
    // Pass reset from PCIe to the model.  The host holds reset long enough that
    // a crossing wire to the model clock domain is sufficient.
    //
    Reg#(Bool) pcieInReset <- mkReg(True,
                                    clocked_by pcie.driver.clock,
                                    reset_by pcie.driver.reset);
    ReadOnly#(Bool) assertModelReset <-
        mkNullCrossingWire(clocks.driver.clock,
                           pcieInReset,
                           clocked_by pcie.driver.clock,
                           reset_by pcie.driver.reset);
    
    (* fire_when_enabled, no_implicit_conditions *)
    rule exitResetPCIe (pcieInReset);
        pcieInReset <= False;
    endrule

    (* fire_when_enabled *)
    rule triggerModelReset (assertModelReset);
        clocks.softResetTrigger.reset();
    endrule


    //
    // Aggregate the drivers
    //
    interface PHYSICAL_DRIVERS physicalDrivers;
        interface CLOCKS_DRIVER clocksDriver;
            interface Clock clock = clocks.driver.clock;
            interface Reset reset = clocks.driver.reset;

            interface Clock rawClock = clocks.driver.rawClock;
            interface Reset rawReset = clocks.driver.rawReset;
        endinterface //= clocks.driver;

        interface pcieDriver = pcie.driver;
        interface ddrDriver  = sdram.driver;
    endinterface
    
    //
    // Aggregate the wires
    //
    interface TOP_LEVEL_WIRES topLevelWires;
        interface pcieWires   = pcie.wires;
        interface ddrWires    = sdram.wires;
    endinterface
               
endmodule
