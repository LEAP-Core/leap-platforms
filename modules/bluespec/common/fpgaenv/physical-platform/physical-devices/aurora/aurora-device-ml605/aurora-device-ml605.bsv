//
// Copyright (C) 2011 Massachusetts Institute of Technology
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
`include "awb/provides/aurora_driver.bsh"

typedef Vector#(`NUM_AURORA_IFCS,AURORA_DRIVER) AURORA_COMPLEX_DRIVERS;

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

module mkAURORA_DEVICE (AURORA_COMPLEX);

    Vector#(`NUM_AURORA_IFCS,AURORA_DRIVER) ifcDrivers = newVector();
    Vector#(`NUM_AURORA_IFCS,AURORA_WIRES)  ifcWires = newVector();
    Vector#(`NUM_AURORA_IFCS,Clock)         ifcClocks = newVector();

    let clk <- exposeCurrentClock();
    let rst <- exposeCurrentReset();

    // HPC Clock
    CLOCK_FROM_PUT hpcClockN <- mkClockFromPut(clocked_by clk);
    CLOCK_FROM_PUT hpcClockP <- mkClockFromPut(clocked_by clk);

    let hpcClock <- mkClockIBUFDS_GTXE1(True, hpcClockP.clock, hpcClockN.clock);
    
    ifcClocks = replicate(hpcClock); 


    // SMA Clock
    CLOCK_FROM_PUT smaClockN <- mkClockFromPut(clocked_by clk);
    CLOCK_FROM_PUT smaClockP <- mkClockFromPut(clocked_by clk);

    let smaClock <- mkClockIBUFDS_GTXE1(True, smaClockP.clock, smaClockN.clock);

    ifcClocks[0] = smaClock; // fix clock 0

    
    // Now we can instantiate the aurora devices enblock 

    for(Integer i = 0; i < `NUM_AURORA_IFCS; i = i + 1)
    begin
        // Instantiate the driver and flowcontrol
        let ug_device <- mkAURORA_SINGLE_UG(ifcClocks[i], clk, rst);
        let auroraFlowcontrol <- mkAURORA_FLOWCONTROL(ug_device);

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
