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
    (* prefix = "", enable = `PLAT_IFC_CLOCK_CLK *)
    method Action plat_ifc_clock_wire();

    (* prefix = "", enable = `PLAT_IFC_CLOCK_RST *)
    method Action plat_ifc_reset_wire();


    (* prefix = "", enable = `USER_CLOCK_CLK *)
    method Action user_clock_wire();

    (* prefix = "", enable = `USER_CLOCK_RST *)
    method Action user_reset_wire();
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
    // STAGE 1: get the crystal clock by instantiating the primitive clocks device
    //
    
    PRIMITIVE_CLOCKS_DEVICE crystalClocks <- mkPrimitiveClocksDevice();
    
    Clock rawClock = crystalClocks.clock;
    Reset rawReset = crystalClocks.reset;
    
    //
    // STAGE 2: get the user clock from the incoming wires
    //

    let userClockPackage <- mkPrimitiveClocksDevice();
    
    Clock userClock = userClockPackage.clock;
    Reset userReset = userClockPackage.reset;

    //
    // STAGE 3: soft reset
    //
    
    // Next, we'll create a new soft reset interface. We'll instantiate it with the
    // startInRst flag set to true, which will cause it to automatically trigger when
    // the hard reset is triggered.
    
    MakeResetIfc soft_reset_wrapper <- mkReset(10, True, userClock,
                                               clocked_by userClock,
                                               reset_by   userReset);
    
    Reset softReset = soft_reset_wrapper.new_rst;

    // Now, we create a special trigger module that has the logic for triggering the
    // soft reset when a request arrives from the physical device. The trigger module
    // needs to be reset by the HARD reset.
    
    SOFT_RESET_TRIGGER trigger <- mkSoftResetTrigger(soft_reset_wrapper,
                                                     clocked_by userClock,
                                                     reset_by   userReset);
    
    // Return one reset, mustly used by legacy code that doesn't use
    // the reset fan-out interface.
    let finalReset <- mkResetFanout(softReset, clocked_by userClock);
    
    // bind the driver interfaces
    interface CLOCKS_DRIVER driver;
        interface clock = userClock;
        interface reset = finalReset;
            
        // Fan-out not yet implemented in this clock
        interface baseReset = softReset;

        interface rawClock = rawClock;
        interface rawReset = rawReset;
    endinterface
    
    // bind the wires
    
    interface CLOCKS_WIRES wires;
        method plat_ifc_clock_wire = crystalClocks.clock_wire;
        method plat_ifc_reset_wire = crystalClocks.reset_wire;
        method user_clock_wire = userClockPackage.clock_wire;
        method user_reset_wire = userClockPackage.reset_wire;
    endinterface
    
    // soft reset trigger
    
    interface softResetTrigger = trigger;
endmodule


//
// mkResetFanout --
//   Fan out reset from a base reset signal, always exiting reset in the same
//   cycle.
//
module mkResetFanout#(Reset baseReset)
    // Interface:
    (Reset);

    let clk <- exposeCurrentClock();

    //
    // Build a chain so it can propagate across the FPGA.  The chain is
    // synchronous since the clock is unchanged and all resets must arrive
    // at the same time.
    //
    Reset rst = baseReset;

    for (Integer i = 0; i < 4; i = i + 1) 
    begin
        rst <- mkSyncReset(3, rst, clk, reset_by baseReset);
    end 

    return rst;
endmodule
