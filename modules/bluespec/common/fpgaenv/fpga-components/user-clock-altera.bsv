//
// Generate clocks of requested frequency.
//

import Clocks::*;

// verilog only
import "BVI"
module mkUserClock_Ratio#(Integer inFreq,
                          Integer clockMultiplier,
                          Integer clockDivider)
    // Interface:
        (UserClock);

    default_clock (inclk0);
    default_reset (areset_n);
    output_clock clk (c0);
    output_reset rst (locked) clocked_by (clk);

    // Convert frequency (MHz) to period (ns)
    parameter CR_CLKIN_PERIOD = 1000000 / inFreq;
    parameter CR_CLKFX_MULTIPLY = clockMultiplier;
    parameter CR_CLKFX_DIVIDE = clockDivider;

endmodule


module mkUserClock_PLL#(Integer inFreq,
                        Integer outFreq)
    // Interface:
        (UserClock);
   let lcmValue = lcm(inFreq,outFreq);

   mkUserClock_Ratio(inFreq, lcmValue/inFreq, lcmValue/outFreq);

endmodule