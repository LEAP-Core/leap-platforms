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
// Instantiate Clock Buffers for DCM/PLL inputs and outputs
//

import Clocks::*;

//
// General interface that wraps a clock
//

interface CLOCK_WRAPPER_IFC;
    
    interface Clock clock;
    
endinterface

//
// Clock Buffer
//

// import the verilog
import "BVI"
module clock_buffer#(Clock inputClock)
    // interface:
        (CLOCK_WRAPPER_IFC);

    default_reset rst (RST_N);

    input_clock (CLK_IN) = inputClock;
    
    output_clock clock (CLK_OUT);

endmodule

// wrap it in a nicer module
module mkClockBuffer#(Clock inputClock)
    // interface:
        (Clock);
    
    let buffer <- clock_buffer(inputClock);
    
    return buffer.clock;
    
endmodule

//
// Clock Input Buffer
//

// import the verilog
import "BVI"
module clock_input_buffer#(Clock inputClock)
    // interface:
        (CLOCK_WRAPPER_IFC);

    default_reset rst (RST_N);

    input_clock (CLK_IN) = inputClock;
    
    output_clock clock (CLK_OUT);

endmodule

// wrap it in a nicer module
module mkClockInputBuffer#(Clock inputClock)
    // interface:
        (Clock);
    
    let buffer <- clock_input_buffer(inputClock);
    
    return buffer.clock;
    
endmodule
