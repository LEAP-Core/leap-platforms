import Clocks::*;

interface UserClock;
    interface Clock clk;
    interface Reset rst;
endinterface

// bluesim as well as verilog
module mkUserClock_Same
        (UserClock);

    let clock <- exposeCurrentClock;
    let reset <- exposeCurrentReset;

    interface Clock clk = clock;
    interface Reset rst = reset;

endmodule

// bluesim as well as verilog
module mkUserClock_DivideByTwo
        (UserClock);

    let divider <- mkClockDivider(2);
    let usr_reset <- mkAsyncResetFromCR(0, divider.slowClock);

    interface clk = divider.slowClock;
    interface rst = usr_reset;

endmodule

// verilog only
import "BVI"
module mkUserClock_50_to_100
        (UserClock);
    default_clock (CLK);
    default_reset (RST_N);
    output_clock clk (CLK_OUT);
    output_reset rst (RST_N_OUT) clocked_by (clk);
endmodule

module mkUserClock#(Integer inFreq, Integer outFreq)
        (UserClock);

    Integer i = inFreq;
    Integer o = outFreq;

    UserClock _x = ?;

    if (i == 50 && o == 100)
        _x <- mkUserClock_50_to_100;
    else if (i == 2 * o)
        _x <- mkUserClock_DivideByTwo;
    else if (i == o)
        _x <- mkUserClock_Same;
    else
        error("UserClock: don't know how to generate a " + integerToString(o) + " MHz clock from a " + integerToString(i) + " MHz clock.");

    return _x;

endmodule

module mkUserClockFromCrystal#(Integer outFreq)
        (UserClock);
    let _x <- mkUserClock(`CRYSTAL_CLOCK_FREQ, outFreq);
    return _x;
endmodule
