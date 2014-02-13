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

// ******* general-switch-device *******

// A switch device generalized to any bit width

// *************************************

import Clocks::*;

// SWITCHES_DRIVER

// The interface the rest of the FPGA uses to read the switches

interface SWITCHES_DRIVER#(parameter numeric type n);

    method Bit#(n) getSwitches();

endinterface

// SWITCHES_WIRES

// This interface is not used by the rest of the FPGA.
// Rather this represents wires which are passed to the top level and tied
// to the physical switch pins by the UCF file.

interface SWITCHES_WIRES#(parameter numeric type n);

    (* prefix = "" *)
    method Action switches_wire((* port = "SWITCH" *) Bit#(n) sw);

endinterface


// SWITCHES_DEVICE

// By convention a Device is a combination of a Wires and a Driver.

interface SWITCHES_DEVICE#(parameter numeric type n);

    interface SWITCHES_DRIVER#(n) driver;
    interface SWITCHES_WIRES#(n)  wires;

endinterface


// mkSwitchesDevice

// A switch device generalized to any bit width.
// Uses a Wire to return the current value of the switches.

module mkSwitchesDevice
    // interface:
                 (SWITCHES_DEVICE#(number_switches_T));

    // Create a primitive device
    
    PRIMITIVE_SWITCHES_DEVICE#(number_switches_T) primSwitches <- mkPrimitiveSwitchesDevice();


    // The interface used by the rest of the FPGA
  
    interface SWITCHES_DRIVER driver;

        method getSwitches = primSwitches.getSwitches;
            
    endinterface

    // The wires which are tied to the switches by the UCF

    interface SWITCHES_WIRES wires;
        
        method switches_wire = primSwitches.switches_wire;
  
    endinterface
 
endmodule
