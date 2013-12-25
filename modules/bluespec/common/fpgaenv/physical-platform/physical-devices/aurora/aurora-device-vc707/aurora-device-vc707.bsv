//
// Copyright (C) 2013 Massachusetts Institute of Technology
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

// This module interfaces to the SMA cables on the
// XUPV5. However only certain of the generated verilog and ucf files
// are needed to characterize this interface, and it can be used a model 
// for high-speed board to board serial on other development boards. The 
// device interface consists of a simple FIFO with guaranteed transport to
// the other device. This module is slightly complicated by the need to 
// instantiate dummy serial modules to route clock to the SMA GTP.


import Clocks::*;
import FIFOF::*;
import FIFO::*;
import FIFOLevel::*;
import Connectable::*;
import GetPut::*;
import Vector::*;
import XilinxCells::*;

`include "awb/provides/fpga_components.bsh"
`include "awb/provides/aurora_flowcontrol.bsh"
`include "awb/provides/aurora_common.bsh"
`include "awb/provides/aurora_driver.bsh"
`include "awb/provides/clocks_device.bsh"
`include "awb/provides/librl_bsv_base.bsh"

`ifdef AURORA_IFC_WORDS_Z
// Calculate the optimal interface width for a given user clock and
// serdes clock.
typedef TMax#(1,TDiv#(`AURORA_INTERFACE_FREQ, `MODEL_CLOCK_FREQ)) InterfaceWords;
`else
// Fixed width.
typedef `AURORA_IFC_WORDS InterfaceWords;
`endif

typedef `AURORA_INTERFACE_WIDTH InterfaceWidth;

typedef AURORA_DRIVER#(AURORA_INTERFACE_WIDTH#(InterfaceWords, InterfaceWidth)) AURORA_COMPLEX_DRIVER;
typedef Vector#(`NUM_AURORA_IFCS, AURORA_COMPLEX_DRIVER) AURORA_COMPLEX_DRIVERS;

interface AURORA_COMPLEX_WIRES;
    (* always_ready, always_enabled *)
    interface Put#(Bit#(1)) sma_clk_p;
    (* always_ready, always_enabled *)
    interface Put#(Bit#(1)) sma_clk_n;

    (* always_ready, always_enabled *)
    interface Put#(Bit#(1)) hpc_clk_p;
    (* always_ready, always_enabled *)
    interface Put#(Bit#(1)) hpc_clk_n;

    interface Vector#(`NUM_AURORA_IFCS,AURORA_WIRES) wires;
endinterface

interface AURORA_COMPLEX;
   interface AURORA_COMPLEX_DRIVERS drivers;
   interface AURORA_COMPLEX_WIRES  wires;
endinterface

(*synthesize*)
module mkAuroraDevice#(Clock rawClock, Reset rawReset)
    // Interface:
    (AURORA_COMPLEX);

    Vector#(`NUM_AURORA_IFCS,AURORA_COMPLEX_DRIVER) ifcDrivers = newVector();
    Vector#(`NUM_AURORA_IFCS,AURORA_WIRES)                                                   ifcWires = newVector();
    Vector#(`NUM_AURORA_IFCS,AuroraGTXClockSpec)                                             ifcClocks = newVector();

    // HPC Clock
    CLOCK_FROM_PUT hpcClockN <- mkClockFromPut(clocked_by rawClock);
    CLOCK_FROM_PUT hpcClockP <- mkClockFromPut(clocked_by rawClock);

    let hpcClock <- mkClockIBUFDS_GTE2(True, hpcClockP.clock, hpcClockN.clock);

    ifcClocks = replicate(AuroraGTXClockSpec{pll_divsel45_fb: 4, clk25_divider: 7, clock: hpcClock, use_chipscope: 0}); // We scrub these values from coregen. HPC clock is 156.25 MHz.

    ifcClocks[1] = AuroraGTXClockSpec{pll_divsel45_fb: 4, clk25_divider: 7, clock: hpcClock, use_chipscope: 0};

    // SMA Clock
    CLOCK_FROM_PUT smaClockN <- mkClockFromPut(clocked_by rawClock);
    CLOCK_FROM_PUT smaClockP <- mkClockFromPut(clocked_by rawClock);

    let smaClock <- mkClockIBUFDS_GTE2(True, smaClockP.clock, smaClockN.clock);

    ifcClocks[0] = AuroraGTXClockSpec{pll_divsel45_fb: 5, clk25_divider: 5, clock: smaClock, use_chipscope: 0}; // We scrub these values from coregen. SMA clock is 125 MHz.


    // Now we can instantiate the aurora devices enblock
    // XXX fix me

    for(Integer i = 0; i < `NUM_AURORA_IFCS; i = i + 1)
    begin
        // Instantiate the driver and flowcontrol
        AURORA_SINGLE_DEVICE_UG#(InterfaceWidth) ug_device <- mkAURORA_SINGLE_UG(ifcClocks[i], rawClock, rawReset);
        NumTypeParam#(InterfaceWords) interfaceWidth = ?;
        let auroraFlowcontrol <- mkAURORA_FLOWCONTROL(ug_device, interfaceWidth);

        ifcDrivers[i] = auroraFlowcontrol.driver;
        ifcWires[i]   = auroraFlowcontrol.wires;
    end

    interface AURORA_COMPLEX_WIRES wires;

        interface Put sma_clk_p;
            method Action put(Bit#(1) clk);
                smaClockP.clock_wire.put(clk);
            endmethod
        endinterface

        interface Put sma_clk_n;
            method Action put(Bit#(1) clk);
                smaClockN.clock_wire.put(clk);
            endmethod
        endinterface
        interface Put hpc_clk_p;
            method Action put(Bit#(1) clk);
                hpcClockP.clock_wire.put(clk);
            endmethod
        endinterface

        interface Put hpc_clk_n;
            method Action put(Bit#(1) clk);
                hpcClockN.clock_wire.put(clk);
            endmethod
        endinterface

	interface wires = ifcWires;
    endinterface

    interface drivers = ifcDrivers;

endmodule
