// Top Level Wires for a physical XUP board

interface TopLevelWires;
    // magic wires that tie to UCF
    (* always_ready *)
    (* result = "LED" *)
    method Bit#(4) leds();
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  switches((* port = "SWITCH" *) Bit#(4) sw);
endinterface

interface TopLevelWiresDriver;

    // wires from/to FPGA model; each of these wires correspond to one
    // of the above magic UCF wires. For now, we do now connect the
    // model wires to the UCF wires directly but use an intermediate latch.
    method  Action      setLEDs(Bit#(4) leds_in);
    method  Bit#(4)     getSwitches();
    interface TopLevelWires wires_out;

endinterface

module mkTopLevelWiresDriver (TopLevelWiresDriver);

    // all XUP board signals are active low
    Reg#(Bit#(4)) led_reg <- mkReg(4'b1111);
    Reg#(Bit#(4)) switch_reg <- mkReg(4'b1111);
  
    interface TopLevelWires wires_out;

        method Bit#(4) leds();
            return led_reg;
        endmethod

        method Action switches(Bit#(4) sw);
            switch_reg <= ~sw;
        endmethod
  
    endinterface
 

    // interfaces to FPGA model
    method  Action setLEDs(Bit#(4) leds_in);
        led_reg <= ~leds_in;
    endmethod

    method  Bit#(4) getSwitches();
        return switch_reg;
    endmethod

endmodule

