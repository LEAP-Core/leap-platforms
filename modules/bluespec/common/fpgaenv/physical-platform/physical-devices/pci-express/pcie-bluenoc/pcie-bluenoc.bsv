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
import PCIE::*;
import XilinxCells::*;
import BlueNoC::*;
import Connectable::*;
import TieOff::*;

`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/physical_platform_utils.bsh"
`include "awb/provides/fpga_components.bsh"
`include "awb/provides/pcie_device.bsh"
`include "awb/provides/pcie_bluenoc_device.bsh"


//
// PCIE_WIRES --
//   These are wires that are simply passed up to the top level, where the UCF file
//   ties them to pins.
//
interface PCIE_WIRES;
    method Action pcie_clk_n();  
    method Action pcie_clk_p();  
    method Action pcie_reset_wire();
    method Bit#(8) leds();

    interface Clock clockPCIE;
    interface PCIE_EXP#(PCIE_LANES) pcie_exp;
endinterface


//
// PCIE_DEVICE --
//
//   By convention a Device is a driver and a wires.
//
interface PCIE_DEVICE;
    interface PCIE_DRIVER driver;
    interface PCIE_WIRES  wires;
endinterface


//
// mkPCIEDevice --
//   Wrap the PCIe core device in a generic interface.
//
module mkPCIEDevice#(Clock rawClock, Reset rawReset)
    // Interface:
    (PCIE_DEVICE);

    // PCIe is driven by a different clock than the raw clock.
    CLOCK_IMPORTER pcieClockN <- mkClockImporter();
    CLOCK_IMPORTER pcieClockP <- mkClockImporter();
    
    // Buffer clocks and reset before they are used
    Clock pcieSysClkBuf <- mkClockIBUFDS_GTXE1(True, pcieClockP.clock, pcieClockN.clock);
    RESET_IMPORTER pcieReset <- mkResetImporter(clocked_by pcieSysClkBuf);  

    // Instantiate a PCIe endpoint
    BNOC_PCIE_DEV#(PCIE_BYTES_PER_BEAT) dev <-
        mkPCIEBlueNoCDevice(pcieSysClkBuf, pcieReset.reset,
                            clocked_by rawClock,
                            reset_by rawReset);

    // Connect PCIe transmit and receive wires, not handled in Bluespec
    PCIE_BURY pcieBury <- mkPCIE_BURY(clocked_by pcieSysClkBuf,
                                      reset_by pcieReset.reset);

    (* fire_when_enabled, no_implicit_conditions *) 
    rule drivePCIE;
        pcieBury.txn_bsv(dev.pcie_exp.txn);
        pcieBury.txp_bsv(dev.pcie_exp.txp);
        dev.pcie_exp.rxp(pcieBury.rxp_bsv);
        dev.pcie_exp.rxn(pcieBury.rxn_bsv);
    endrule
    

    //
    // Insert a simple network with some test ports, useful for debugging and
    // characterizing the PCIe link.  The returned port will be the exposed
    // NOC interface for the rest of the system.  All destination nodes 4
    // and above will be routed to the returned port.  All messages sent
    // from the FPGA to the returned port will be forwarded to the host.
    //
    Vector#(2, MsgPort#(PCIE_BYTES_PER_BEAT)) extPorts <-
        mkSwitchWithTests(dev.driver.noc,
                          clocked_by dev.driver.clock,
                          reset_by dev.driver.reset);

    //
    // extPorts[0] is available as a debug port (network destination 1).
    //
    mkTieOff(extPorts[0]);


    interface PCIE_DRIVER driver;
        interface MsgPort noc = extPorts[1];

        interface Clock clock = dev.driver.clock;
        interface Reset reset = dev.driver.reset;
    endinterface

    interface PCIE_WIRES  wires;
        method pcie_clk_n = pcieClockN.clock_wire;  
        method pcie_clk_p = pcieClockP.clock_wire;  
        method pcie_reset_wire = pcieReset.reset_wire;
        method leds = ?; // dev.leds();

        interface clockPCIE = pcieBury.clock;
        interface PCIE_EXP pcie_exp;
            method rxp = pcieBury.rxp_wire;
            method rxn = pcieBury.rxn_wire;
            method txp = pcieBury.txp_wire;
            method txn = pcieBury.txn_wire;
        endinterface
    endinterface

endmodule
