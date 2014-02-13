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

function Integer gcd(Integer a, Integer b);
    // Sanity check args
    Integer result = 0;
    if(a < 0 || b < 0)
    begin
        let err = error("Illegal arguments to GCD");
    end 
    else if(b == 0)
    begin 
        result = a;
    end
    else if(a == 0)
    begin
        result = b;
    end  
    else if(a > b)
    begin
        result = gcd(b,a-b);
    end
    else
    begin
        result = gcd(a,b-a);
    end

  return result;
endfunction


function Integer lcm(Integer a, Integer b);
  return (a*b)/gcd(a,b);
endfunction


interface UserClock;
    interface Clock clk;
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
module mkUserClock_DivideByTwo
    // Interface:
        (UserClock);
    let clk <- mkUserClock_Divider(2);
    return clk;

endmodule

// bluesim as well as verilog
module mkUserClock_Divider#(Integer divisor)
    // Interface:
        (UserClock);

    let divider <- mkClockDivider(divisor);
    let usr_reset <- mkAsyncResetFromCR(0, divider.slowClock);

    interface clk = divider.slowClock;
    interface rst = usr_reset;

endmodule

module mkUserClockFromFrequency#(Integer inFreq,
                                 Integer outFreq)
    // Interface:
        (UserClock);
   let lcmValue = lcm(inFreq,outFreq);

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
        (UserClock);

    UserClock clk = ?;

    // let's deal with relative primes...
    let mult = clockMultiplier/gcd(clockMultiplier,clockDivider); 
    let div  = clockDivider/gcd(clockMultiplier,clockDivider); 

    clk <- mkUserClock_Ratio(inFreq, mult, div);
    return clk;

endmodule




