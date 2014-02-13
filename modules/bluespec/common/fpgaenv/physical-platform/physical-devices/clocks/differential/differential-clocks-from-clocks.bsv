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

//
// Differential Clocks Device (from Clocks)
//

import Vector::*;
import Clocks::*;
import XilinxCells::*;

`include "physical_platform_utils.bsh"
`include "fpga_components.bsh"

//
// CLOCKS_DRIVER: clocks exported to the model
//

interface CLOCKS_DRIVER;
    
    interface Clock clock;        
    interface Reset reset;
    
    interface Clock rawClock;
    interface Reset rawReset;
        
endinterface

//
// CLOCKS_DEVICE: By convention, a device is a collection of
//                drivers and wires. The clocks device also
//                needs to export an interface to a trigger
//                for the soft-reset mechanism.
//

interface CLOCKS_DEVICE;

    interface CLOCKS_DRIVER      driver;
    interface SOFT_RESET_TRIGGER softResetTrigger;
        
endinterface

//
// mkClocksDevice
//

module mkClocksDevice#(Vector#(2, Clock) crystalClocks, Reset resetWire)
    // interface:
    (CLOCKS_DEVICE);
    
    //
    // STAGE 1: Convert to a single clock and buffer clock and reset.
    //
    
    Clock rawClock <- mkClockIBUFDS(crystalClocks[0], crystalClocks[1]);
    
    Reset rawReset <- mkResetIBUF(reset_by resetWire);
    if (`RESET_ACTIVE_HIGH > 0)
    begin     
        rawReset <- mkResetInverter(rawReset, clocked_by rawClock);
    end


    //
    // STAGE 2: transform the clock using a DCM or PLL as requested by the user
    //

    let userClockPackage <- mkUserClockFromFrequency(`CRYSTAL_CLOCK_FREQ,
                                                     `MODEL_CLOCK_FREQ,
                                                     clocked_by rawClock,
                                                     reset_by   rawReset);
    
    Clock userClock = userClockPackage.clk;
    Reset userReset = userClockPackage.rst;

    //
    // STAGE 3: soft reset
    //
    
    // Next, we'll create a new soft reset interface. We'll instantiate it with the
    // startInRst flag set to true, which will cause it to automatically trigger when
    // the hard reset is triggered.
    
    MakeResetIfc soft_reset_wrapper <- mkReset(64, True, userClock,
                                               clocked_by userClock,
                                               reset_by   userReset);
    
    Reset softReset = soft_reset_wrapper.new_rst;

    // Now, we create a special trigger module that has the logic for triggering the
    // soft reset when a request arrives from the physical device. The trigger module
    // needs to be reset by the HARD reset.
    
    SOFT_RESET_TRIGGER trigger <- mkSoftResetTrigger(soft_reset_wrapper,
                                                     clocked_by userClock,
                                                     reset_by   userReset);
    
    Clock finalClock = userClock;
    Reset finalReset = softReset;
    
    // bind the driver interfaces
    
    interface CLOCKS_DRIVER driver;
        
        interface clock = finalClock;
        interface reset = finalReset;
            
        interface rawClock = rawClock;
        interface rawReset = rawReset;
                
    endinterface
    
    // soft reset trigger
    
    interface softResetTrigger = trigger;
            
endmodule
