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

import Clocks::*;

interface PRIMITIVE_SWITCHES_DEVICE#(parameter numeric type n);

    // Wires to be sent to the top level

    method Action switches_wire(Bit#(n) sw);
    
    // Drivers exposed to the model
        
    method Bit#(n) getSwitches();
        
endinterface

import "BVI" switches_device = module mkPrimitiveSwitchesDevice
    // interface:
                 (PRIMITIVE_SWITCHES_DEVICE#(number_switches_T));

    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();                                   
                                       
    default_clock no_clock;
    default_reset no_reset;
                                       
    input_clock (clk)   = modelClock;
    input_reset (rst_n) = modelReset;                               

    method switches_wire(switches_in) enable((* inhigh *) EN);
                                           
    method switches_out getSwitches() clocked_by (modelClock) reset_by (modelReset);

    schedule (switches_wire, getSwitches) CF (switches_wire, getSwitches);    
        
    parameter SWITCHES_WIDTH = valueof(number_switches_T);
        
endmodule
