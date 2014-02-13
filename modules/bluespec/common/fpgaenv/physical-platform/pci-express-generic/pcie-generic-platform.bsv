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
import Vector::*;
import Clocks::*;

//
// Standard physical platform for PCIe boards with on-board DDR storage
//

`include "awb/provides/pcie_device.bsh"
`include "awb/provides/clocks_device.bsh"
`include "awb/provides/ddr_sdram_device.bsh"
`include "awb/provides/physical_platform_utils.bsh"
`include "awb/provides/aurora_device.bsh"

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;
    interface CLOCKS_DRIVER                        clocksDriver;
    interface PCIE_DRIVER                          pcieDriver;
    interface Vector#(FPGA_DDR_BANKS, DDR_DRIVER)  ddrDriver;
    interface AURORA_COMPLEX_DRIVERS               auroraDriver;
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
    interface AURORA_COMPLEX_WIRES                auroraWires;
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

    AURORA_COMPLEX aurora_device <- mkAuroraDevice(clocks.driver.rawClock,
                                                   clocks.driver.rawReset,
                                                   clocked_by clk, reset_by rst);

    //
    // Aggregate the drivers
    //
    interface PHYSICAL_DRIVERS physicalDrivers;
        interface clocksDriver = clocks.driver;
        interface pcieDriver = pcie.driver;
        interface ddrDriver  = sdram.driver;
        interface auroraDriver = aurora_device.drivers;
    endinterface
    
    //
    // Aggregate the wires
    //
    interface TOP_LEVEL_WIRES topLevelWires;
        interface pcieWires   = pcie.wires;
        interface ddrWires    = sdram.wires;
        interface auroraWires = aurora_device.wires;
    endinterface
               
endmodule
