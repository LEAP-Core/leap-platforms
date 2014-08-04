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
// VC707. However only certain of the generated verilog and ucf files
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
import DefaultValue::*;

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
    interface Vector#(`NUM_AURORA_IFCS, Put#(Bit#(1))) hpc_clk_p;
    interface Vector#(`NUM_AURORA_IFCS, Put#(Bit#(1))) hpc_clk_n;
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

    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();

    //
    // Trigger reset with either raw or model resets.
    //
    Reset modelResetInRaw <- mkAsyncReset(4, modelReset, rawClock);
    Reset modelOrRawReset <- mkResetEither(modelResetInRaw, rawReset,
                                           clocked_by rawClock);

    Vector#(`NUM_AURORA_IFCS,AURORA_COMPLEX_DRIVER) ifcDrivers = newVector();
    Vector#(`NUM_AURORA_IFCS,AURORA_WIRES)                                                   ifcWires = newVector();
    Vector#(`NUM_AURORA_IFCS,AuroraGTXClockSpec)                                             ifcClocks = newVector();
    Vector#(`NUM_AURORA_IFCS,CLOCK_FROM_PUT)                                                 ifcClkN = newVector();
    Vector#(`NUM_AURORA_IFCS,CLOCK_FROM_PUT)                                                 ifcClkP = newVector();
    Vector#(`NUM_AURORA_IFCS,Clock)                                                          ifcClkInst = newVector();
    Vector#(`NUM_AURORA_IFCS,Put#(Bit#(1)))                                                  ifcClkWireN = newVector();
    Vector#(`NUM_AURORA_IFCS,Put#(Bit#(1)))                                                  ifcClkWireP = newVector();

    // HPC Clock

    // Now we can instantiate the aurora devices enblock
    for(Integer i = 0; i < `NUM_AURORA_IFCS; i = i + 1)
    begin
        CLOCK_FROM_PUT hpcClockN <- mkClockFromPut(clocked_by rawClock);
        CLOCK_FROM_PUT hpcClockP <- mkClockFromPut(clocked_by rawClock);
 
        let hpcClock <- mkClockIBUFDS_GTE2(defaultValue, True, hpcClockP.clock, hpcClockN.clock);

        // We scrub these values from coregen. HPC clock is 156.25 MHz.
        ifcClocks[i] = AuroraGTXClockSpec{pll_divsel45_fb: 4, clk25_divider: 7, clock: hpcClock, use_chipscope: 0};

        // Instantiate the driver and flowcontrol
        AURORA_SINGLE_DEVICE_UG#(InterfaceWidth) ug_device <-
            mkAURORA_SINGLE_UG(ifcClocks[i], rawClock, modelOrRawReset);

        NumTypeParam#(InterfaceWords) interfaceWidth = ?;
        let auroraFlowcontrol <- mkAURORA_FLOWCONTROL(ug_device, interfaceWidth);
        let auroraWires <- mkAuroraIOBUF(auroraFlowcontrol.wires, clocked_by rawClock, reset_by rawReset);

        // Place IBUF on clock lines.
        Wire#(Bit#(1)) hpcN <- mkIBUF(defaultValue, clocked_by rawClock, reset_by rawReset);
        Wire#(Bit#(1)) hpcP <- mkIBUF(defaultValue, clocked_by rawClock, reset_by rawReset);

        rule driveHPCN;
            hpcClockN.clock_wire.put(hpcN);
        endrule

        rule driveHPCP;
            hpcClockP.clock_wire.put(hpcP);
        endrule
 
        ifcDrivers[i] = auroraFlowcontrol.driver;
        ifcWires[i]   = auroraWires;
        ifcClkN[i] = hpcClockN;
        ifcClkP[i] = hpcClockP;
        ifcClkInst[i] = hpcClock;
        ifcClkWireP[i] = interface Put;
                             method Action put(Bit#(1) clk);
                                 hpcP <= clk;
                             endmethod
                         endinterface;

        ifcClkWireN[i] = interface Put;
                             method Action put(Bit#(1) clk);
                                 hpcN <= clk;
                             endmethod
                         endinterface;
    end


    interface AURORA_COMPLEX_WIRES wires;

        interface hpc_clk_p = ifcClkWireP;
        interface hpc_clk_n = ifcClkWireN;
	interface wires = ifcWires;

    endinterface

    interface drivers = ifcDrivers;

endmodule
