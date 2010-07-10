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

//
// Generate clocks of requested frequency.
//

import Clocks::*;


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

    let divider <- mkClockDivider(2);
    let usr_reset <- mkAsyncResetFromCR(0, divider.slowClock);

    interface clk = divider.slowClock;
    interface rst = usr_reset;

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

  `ifdef SYNTH

    // FPGA synthesis...

    if (clockMultiplier ==  clockDivider)
        clk <- mkUserClock_Same;
    else if (clockMultiplier == 2 && clockDivider == 1)
        clk <- mkUserClock_Ratio(inFreq, clockMultiplier*2, clockDivider*2);
    else if (clockMultiplier == 1 && clockDivider == 2)
        clk <- mkUserClock_DivideByTwo;
    else
        clk <- mkUserClock_Ratio(inFreq, clockMultiplier, clockDivider);

  `else

    // Clock ratios make no sense in Bluesim

    clk <- mkUserClock_Ratio(inFreq, clockMultiplier, clockDivider);

  `endif

    return clk;

endmodule

//
// mkUserClockFromCrystal --
//   Generate a user clock based on the on-board crystal that is multiplied
//   by clockMultiplier and divided by clockDivider.
//
// module mkUserClockFromCrystal#(Integer clockMultiplier, Integer clockDivider)
//         (UserClock);

//     let clk <- mkUserClock(`CRYSTAL_CLOCK_FREQ, clockMultiplier, clockDivider);
//     return clk;

// endmodule


