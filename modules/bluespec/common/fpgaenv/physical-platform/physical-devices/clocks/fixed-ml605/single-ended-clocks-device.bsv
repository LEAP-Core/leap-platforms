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

// Single-Ended Clocks Device

import Clocks::*;

`include "physical_platform_utils.bsh"
`include "fpga_components.bsh"

//
// CLOCKS_DRIVER: clocks exported to the model
//

interface CLOCKS_DRIVER;
    interface Clock clock;        
    interface Reset reset;
    
    // This is the reset to pass into mkResetFanout().  Any reset derived
    // from mkResetFanout(baseReset) will complete in the same cycle as
    // the above reset signal.
    interface Reset baseReset;
    
    interface Clock rawClock;
    interface Reset rawReset;
endinterface

//
// CLOCKS_WIRES: wires to be sent to the top level, where
//               the UCF file ties them to pins.
//

interface CLOCKS_WIRES;
    
    (* prefix = "", enable = "CLK" *)
    method Action clock_wire();

    (* prefix = "", enable = "RST_N" *)
    method Action reset_n_wire();
     
endinterface

//
// CLOCKS_DEVICE: By convention, a device is a collection of
//                drivers and wires. The clocks device also
//                needs to export an interface to a trigger
//                for the soft-reset mechanism.
//

interface CLOCKS_DEVICE;
    interface CLOCKS_DRIVER      driver;
    interface CLOCKS_WIRES       wires;
endinterface

//
// mkClocksDevice
//

module mkClocksDevice
    // interface:
    (CLOCKS_DEVICE);
    
    //
    // STAGE 1: get the crystal clock by instantiating the primitive clocks device
    //
    
    PRIMITIVE_CLOCKS_DEVICE crystalClocks <- mkPrimitiveClocksDevice();
    
    Clock rawClock = crystalClocks.clock;
    Reset rawReset = crystalClocks.reset;
    
    //
    // STAGE 2: transform the clock using a DCM or PLL as requested by the user
    //

    let userClockPackage <- mkUserClockFromFrequency(`CRYSTAL_CLOCK_FREQ,
                                                     `MODEL_CLOCK_FREQ,
                                                     clocked_by rawClock,
                                                     reset_by   rawReset);
    
    Clock userClock = userClockPackage.clk;
    Reset userReset = userClockPackage.rst;

    Clock finalClock = userClock;
    Reset finalReset = userReset;
    
    // bind the driver interfaces
    
    interface CLOCKS_DRIVER driver;
        interface clock = finalClock;
        interface reset = finalReset;
            
        // Fan-out not yet implemented in this clock
        interface baseReset = finalReset;
            
        interface rawClock = rawClock;
        interface rawReset = rawReset;
    endinterface
    
    // bind the wires
    
    interface CLOCKS_WIRES wires;
        method clock_wire   = crystalClocks.clock_wire;
        method reset_n_wire = crystalClocks.reset_n_wire;
    endinterface
endmodule


//
// mkResetFanout --
//   Fan out reset from a base reset signal, always exiting reset in the same
//   cycle.
//
module mkResetFanout#(Reset baseReset)
    // Interface:
    (Reset);

    // Fan-out not yet implemented in this clock
    return baseReset;
endmodule
