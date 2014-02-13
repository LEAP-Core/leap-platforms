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
import PCIE::*;
import XilinxCells::*;
import BlueNoC::*;
import Connectable::*;
import TieOff::*;
import GetPut::*;

`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/physical_platform_config.bsh"
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
    (* always_ready, always_enabled *)
    interface Put#(Bit#(1)) clk_p;
    (* always_ready, always_enabled *)
    interface Put#(Bit#(1)) clk_n;

    (* always_ready, always_enabled *)
    interface Put#(Bit#(1)) rst;

    (* always_ready, always_enabled *)
    method Bit#(8) leds();

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
    // The "clocked_by" is pure fiction.  By providing a top-level
    // Clock type Bluespec is convinced that the put method is clocked
    // and allows it to be tagged always_enabled.  Without a pseudo-clock,
    // Bluespec believes the put method is never enabled.
    CLOCK_FROM_PUT pcieClockN <- mkClockFromPut(clocked_by rawClock);
    CLOCK_FROM_PUT pcieClockP <- mkClockFromPut(clocked_by rawClock);
    
    // Buffer clocks and reset before they are used
    Clock pcieSysClkBuf;
    if (`FPGA_TECHNOLOGY == "Virtex6")
        pcieSysClkBuf <- mkClockIBUFDS_GTXE1(True, pcieClockP.clock, pcieClockN.clock);
    else
        pcieSysClkBuf <- mkClockIBUFDS_GTE2(True, pcieClockP.clock, pcieClockN.clock);

    // Construct reset.  The incoming reset wire must be "crossed"
    // to the pcieSysClkBuf clock domain from the rawClock domain.  Like
    // the clock crossing above, this crossing is fictitious and exists
    // solely to keep the compiler from complaining about the module
    // being clocked by a clock not exposed at the top.
    RESET_FROM_PUT pcieReset <- mkResetFromPut(pcieSysClkBuf,
                                               clocked_by rawClock);


    // Instantiate a PCIe endpoint
    BNOC_PCIE_DEV#(PCIE_BYTES_PER_BEAT) dev <-
        mkPCIEBlueNoCDevice(pcieSysClkBuf, pcieReset.reset);

    // Connect PCIe transmit and receive wires, not handled in Bluespec.
    // Yet another fictitious clock domain crossing that reduces to wires.
    PCIE_BURY pcieBury <- mkPCIE_BURY(rawClock, pcieSysClkBuf);

    (* fire_when_enabled, no_implicit_conditions *) 
    rule drivePCIE;
        pcieBury.txn_dev(dev.pcie_exp.txn);
        pcieBury.txp_dev(dev.pcie_exp.txp);
        dev.pcie_exp.rxp(pcieBury.rxp_dev);
        dev.pcie_exp.rxn(pcieBury.rxn_dev);
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

    interface PCIE_WIRES wires;
        interface Put clk_p;
           method Action put(Bit#(1) clk) = pcieClockP.clock_wire.put(clk);
        endinterface
        interface Put clk_n;
           method Action put(Bit#(1) clk) = pcieClockN.clock_wire.put(clk);
        endinterface

        interface Put rst;
           method Action put(Bit#(1) rst) = pcieReset.reset_wire.put(rst);
        endinterface

        method leds = ?; // dev.leds();

        interface PCIE_EXP pcie_exp;
            method rxp = pcieBury.rxp_wire;
            method rxn = pcieBury.rxn_wire;
            method txp = pcieBury.txp_wire;
            method txn = pcieBury.txn_wire;
        endinterface
    endinterface

endmodule
