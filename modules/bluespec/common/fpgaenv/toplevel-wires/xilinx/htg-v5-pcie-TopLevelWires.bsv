// Top Level Wires for a physical HiTech Global PCIe board

typedef Bit#(8) TOPWIRES_LEDS;
typedef Bit#(8) TOPWIRES_SWITCHES;

interface TopLevelWires;
    // magic wires that tie to UCF
    (* always_ready *)
    (* result = "LED" *)
    method TOPWIRES_LEDS leds();
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  switches((* port = "SWITCH" *) TOPWIRES_SWITCHES sw);
endinterface

interface TopLevelWiresDriver;

    // wires from/to FPGA model; each of these wires correspond to one
    // of the above magic UCF wires. For now, we do now connect the
    // model wires to the UCF wires directly but use an intermediate latch.
    method  Action      setLEDs(TOPWIRES_LEDS leds_in);
    method  TOPWIRES_SWITCHES     getSwitches();
    interface TopLevelWires wires_out;

endinterface

module mkTopLevelWiresDriver (TopLevelWiresDriver);

    Reg#(TOPWIRES_LEDS) led_reg <- mkReg(0);
    Reg#(TOPWIRES_SWITCHES) switch_reg <- mkReg(0);
  
    interface TopLevelWires wires_out;

        method TOPWIRES_LEDS leds();
            return led_reg;
        endmethod

        method Action switches(TOPWIRES_SWITCHES sw);
            switch_reg <= sw;
        endmethod
  
    endinterface
 

    // interfaces to FPGA model
    method  Action setLEDs(TOPWIRES_LEDS leds_in);
        led_reg <= leds_in;
    endmethod

    method  TOPWIRES_SWITCHES getSwitches();
        return switch_reg;
    endmethod

endmodule

