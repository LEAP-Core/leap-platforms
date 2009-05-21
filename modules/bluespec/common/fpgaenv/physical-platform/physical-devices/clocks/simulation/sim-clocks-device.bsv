//
// Copyright (C) 2008 Intel Corporation
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

// Simulation Clocks Device

import Clocks::*;

`include "physical_platform_utils.bsh"

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
    // STAGE 1: create a simulated oscillator and a NULL reset
    //
    
    Clock rawClock <- mkAbsoluteClock(0, 1);
    Reset rawReset = noReset();

    //
    // STAGE 2: no DCM/PLL clock transformations for simulated clocks
    //
    
    Clock userClock = rawClock;
    Reset userReset = rawReset;
    
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
