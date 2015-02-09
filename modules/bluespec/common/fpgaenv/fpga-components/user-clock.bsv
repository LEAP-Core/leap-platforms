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
// Generate clocks of requested frequency.
//

import Clocks::*;
import Vector::*;

typedef enum
{
    CLOCK_INTERNAL_UNBUFFERED,    // Controller will instantiate an additional buffer on the clock
    CLOCK_INTERNAL_BUFFERED,      // Controller will use the clock directly
    CLOCK_EXTERNAL_SINGLE_ENDED,  // Controller will instantiate incoming single ended clock buffer
    CLOCK_EXTERNAL_DIFFERENTIAL   // Controller will instantiate incoming differential clock buffer
}
CLOCK_DESCRIPTOR
    deriving (Bits, Eq);

function Integer gcd(Integer a, Integer b);
    // Sanity check args
    Integer result = 0;
    if (a < 0 || b < 0)
    begin
        let err = error("Illegal arguments to GCD");
    end 
    else if (b == 0)
    begin 
        result = a;
    end
    else if (a == 0)
    begin
        result = b;
    end  
    else if (a > b)
    begin
        result = gcd(b, a - b);
    end
    else
    begin
        result = gcd(a, b - a);
    end

    return result;
endfunction


function Integer lcm(Integer a, Integer b);
    return (a * b) / gcd(a, b);
endfunction


interface UserClock;
    interface Clock clk;
    interface Reset rst;
endinterface

interface UserClockDivider;
    interface ClockDividerIfc clk;
    interface Reset rst;
endinterface


//
// USER_CLOCK_VEC --
//     Designed to map to the output of a PLL, defines multiple output clocks
//     and a clock locked output.
//
interface USER_CLOCK_VEC#(type nClocks);
    interface Vector#(nClocks, Clock) clks;
    interface Reset rst;
    method Bool locked();
endinterface


// bluesim as well as verilog
module mkUserClock_Same
    // Interface:
    (UserClock);

    let clock <- exposeCurrentClock;
    let reset <- exposeCurrentReset;

    interface Clock clk = clock;
    interface Reset rst = reset;
endmodule

// bluesim as well as verilog

(*synthesize*)
module mkUserClock_DivideByTwo
    // Interface:
    (ClockDividerIfc);

    let divider <- mkClockDivider(2);
    return divider;
endmodule

(*synthesize*)
module mkUserClock_DivideByThree
    // Interface:
        (ClockDividerIfc);

    let divider <- mkClockDivider(3);
    return divider;
endmodule


(*synthesize*)
module mkUserClock_DivideByFour
    // Interface:
    (ClockDividerIfc);

    let divider <- mkClockDivider(4);
    return divider;
endmodule


// bluesim as well as verilog
module mkUserClock_Divider#(Integer divisor)
    // Interface:
    (UserClockDivider);

    let fast_clk <- exposeCurrentClock();
    let slow_clk <- exposeCurrentClock();
    let clock_ready = True;
    let usr_rst <- exposeCurrentReset();

    if(divisor == 2) 
    begin
        let divider <- mkUserClock_DivideByTwo();
        slow_clk = divider.slowClock;
        clock_ready = divider.clockReady; 
        usr_rst <- mkAsyncResetFromCR(0, divider.slowClock);
    end

    if(divisor == 3) 
    begin
        let divider <- mkUserClock_DivideByThree();
        slow_clk = divider.slowClock;
        clock_ready = divider.clockReady; 
        usr_rst <- mkAsyncResetFromCR(0, divider.slowClock);
    end

    if(divisor == 4) 
    begin
        let divider <- mkUserClock_DivideByFour();
        slow_clk = divider.slowClock;
        clock_ready = divider.clockReady; 
        usr_rst <- mkAsyncResetFromCR(0, divider.slowClock);
    end

    if(divisor > 4) 
        errorM("Clock divider larger than four not currently supported");

    // bind the driver interfaces
    ClockDividerIfc clkBinding = interface ClockDividerIfc;

                                     interface fastClock  = fast_clk;
                                     interface slowClock  = slow_clk;
                                     interface clockReady = clock_ready;    

                                 endinterface;

    // bind the wires
    interface clk = clkBinding;

    interface rst = usr_rst;
endmodule


module mkUserClockFromFrequency#(Integer inFreq,
                                 Integer outFreq)
    // Interface:
    (UserClock);

    let lcmValue = lcm(inFreq, outFreq);
    let m <- mkUserClock(inFreq, lcmValue/inFreq, lcmValue/outFreq);
    return m;
endmodule


//
// mkUserClock --
//   Generate a user clock based on the incoming frequency that is multiplied
//   by clockMultiplier and divided by clockDivider.
//
//   Picks the best source given a few standard ratios.
//
module mkUserClock#(Integer inFreq, Integer clockMultiplier, Integer clockDivider)
    // Interface:
    (UserClock);

    UserClock clk = ?;

    // let's deal with relative primes...
    let mult = clockMultiplier / gcd(clockMultiplier,clockDivider); 
    let div  = clockDivider / gcd(clockMultiplier,clockDivider); 

    clk <- mkUserClock_Ratio(inFreq, mult, div);
    return clk;
endmodule
