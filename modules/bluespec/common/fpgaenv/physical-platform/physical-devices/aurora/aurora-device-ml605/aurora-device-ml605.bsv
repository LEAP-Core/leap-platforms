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
`include "awb/provides/librl_bsv_base.bsh"

typedef 3 InterfaceWords;
typedef `AURORA_INTERFACE_WIDTH InterfaceWidth;

typedef AURORA_DRIVER#(TSub#(TMul#(InterfaceWords, InterfaceWidth),1)) AURORA_COMPLEX_DRIVER;
typedef Vector#(`NUM_AURORA_IFCS,AURORA_DRIVER#(TSub#(TMul#(InterfaceWords, InterfaceWidth),1))) AURORA_COMPLEX_DRIVERS;

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

    Vector#(`NUM_AURORA_IFCS,AURORA_DRIVER#(TSub#(TMul#(InterfaceWords, InterfaceWidth),1))) ifcDrivers = newVector();
    Vector#(`NUM_AURORA_IFCS,AURORA_WIRES)                                                   ifcWires = newVector();
    Vector#(`NUM_AURORA_IFCS,AuroraGTXClockSpec)                                             ifcClocks = newVector();


    let clk <- exposeCurrentClock();
    let rst <- exposeCurrentReset();

    // HPC Clock
    CLOCK_FROM_PUT hpcClockN <- mkClockFromPut(clocked_by clk);
    CLOCK_FROM_PUT hpcClockP <- mkClockFromPut(clocked_by clk);

    let hpcClock <- mkClockIBUFDS_GTXE1(True, hpcClockP.clock, hpcClockN.clock);
    
    ifcClocks = replicate(AuroraGTXClockSpec{pll_divsel45_fb: 4, clk25_divider: 7, clock: hpcClock, use_chipscope: 0}); // We scrub these values from coregen. HPC clock is 156.25 MHz.

    // SMA Clock
    CLOCK_FROM_PUT smaClockN <- mkClockFromPut(clocked_by clk);
    CLOCK_FROM_PUT smaClockP <- mkClockFromPut(clocked_by clk);

    let smaClock <- mkClockIBUFDS_GTXE1(True, smaClockP.clock, smaClockN.clock);

    ifcClocks[0] = AuroraGTXClockSpec{pll_divsel45_fb: 5, clk25_divider: 5, clock: smaClock, use_chipscope: 0}; // We scrub these values from coregen. SMA clock is 125 MHz. 

    
    // Now we can instantiate the aurora devices enblock 

    for(Integer i = 0; i < `NUM_AURORA_IFCS; i = i + 1)
    begin
        // Instantiate the driver and flowcontrol
        AURORA_SINGLE_DEVICE_UG#(InterfaceWidth) ug_device <- mkAURORA_SINGLE_UG(ifcClocks[i], clk, rst);
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
