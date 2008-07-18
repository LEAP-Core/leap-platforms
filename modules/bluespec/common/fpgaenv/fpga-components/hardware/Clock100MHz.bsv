interface Clock100MHzIfc;
    interface Clock clk;
    interface Reset rst;
endinterface

import "BVI" vClock100MHz =
module mkClock100MHz
        (Clock100MHzIfc out);
    default_clock (CLK);
    default_reset (RST_N);
    output_clock clk (CLK_OUT);
    output_reset rst (RST_N_OUT) clocked_by (clk);
endmodule
