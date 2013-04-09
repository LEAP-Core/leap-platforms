
interface ILA;
     method Action trig0(Bit#(8) trig);
     method Action trig1(Bit#(8) trig);
     method Action trig2(Bit#(8) trig);
     method Action trig3(Bit#(8) trig);
     method Action trig4(Bit#(8) trig);
     method Action trig5(Bit#(8) trig);
     method Action trig6(Bit#(8) trig);
     method Action trig7(Bit#(8) trig);

     (* always_ready, always_enabled *)
     interface Inout#(Bit#(36)) control;
endinterface

import "BVI" v7_ila =
module mkILA(ILA);

    default_clock clk(CLK);
    no_reset;

    method trig0(TRIG0) enable((*inhigh*) TRIG0_EN);
    method trig1(TRIG1) enable((*inhigh*) TRIG1_EN);
    method trig2(TRIG2) enable((*inhigh*) TRIG2_EN);
    method trig3(TRIG3) enable((*inhigh*) TRIG3_EN);
    method trig4(TRIG4) enable((*inhigh*) TRIG4_EN);
    method trig5(TRIG5) enable((*inhigh*) TRIG5_EN);
    method trig6(TRIG6) enable((*inhigh*) TRIG6_EN);
    method trig7(TRIG7) enable((*inhigh*) TRIG7_EN);

    ifc_inout   control(CONTROL);

    schedule (trig0,trig1,trig2,trig3,trig4,trig5,trig6,trig7) CF (trig0,trig1,trig2,trig3,trig4,trig5,trig6,trig7);

endmodule