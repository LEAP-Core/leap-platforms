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

// Simulation Clocks Device

import Clocks::*;

`include "asim/provides/physical_platform_utils.bsh"
`include "asim/provides/fpga_components.bsh"

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
// CLOCKS_WIRES: wires to be sent to the top level (none)
//

interface CLOCKS_WIRES;
    
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
    interface SOFT_RESET_TRIGGER softResetTrigger;
        
endinterface

//
// mkClocksDevice
//

module mkClocksDevice
    // interface:
    (CLOCKS_DEVICE);
    
    //
    // STAGE 1: create a simulated oscillator and a reset
    //
    
    Clock rawClock <- mkAbsoluteClock(0, `MAGIC_SIMULATION_CLOCK_FACTOR/`CRYSTAL_CLOCK_FREQ);
    Reset rawReset <- mkInitialReset(10, clocked_by rawClock);

    //
    // STAGE 2: no DCM/PLL clock transformations for simulated clocks
    //
    
    let pllClock <-  mkUserClock_PLL(`CRYSTAL_CLOCK_FREQ, `MODEL_CLOCK_FREQ);

    Clock userClock = pllClock.clk;
    Reset userReset = pllClock.rst;
    
    //
    // STAGE 3: soft reset
    //
    
    // Next, we'll create a new soft reset interface. We'll instantiate it with the
    // startInRst flag set to true, which will cause it to automatically trigger when
    // the hard reset is triggered.
    
    MakeResetIfc soft_reset_wrapper <- mkResetSync(0, True, userClock,
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
    
    // bind the wires
    
    interface CLOCKS_WIRES wires;
        
    endinterface
    
    // soft reset trigger
    
    interface softResetTrigger = trigger;
            
endmodule
