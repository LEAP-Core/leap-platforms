// Top Level Wires for a physical XUP board

interface TopLevelWires;
    // magic wires that tie to UCF
    (* always_ready *)
    (* result = "LED" *)
    method Bit#(4) leds();
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  switches((* port = "SWITCH" *) Bit#(4) sw);
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  button_left((* port = "BUTTON_LEFT" *) Bit#(1) bl);
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  button_right((* port = "BUTTON_RIGHT" *) Bit#(1) br);
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  button_up((* port = "BUTTON_UP" *) Bit#(1) bu);
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  button_down((* port = "BUTTON_DOWN" *) Bit#(1) bd);
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  button_center((* port = "BUTTON_CENTER" *) Bit#(1) bc);
endinterface

interface TopLevelWiresDriver;

    // wires from/to FPGA model; each of these wires correspond to one
    // of the above magic UCF wires. For now, we do now connect the
    // model wires to the UCF wires directly but use an intermediate latch.
    method  Action      setLEDs(Bit#(4) leds_in);
    method  Bit#(4)     getSwitches();
    method  Bit#(1)     getButtonLeft();
    method  Bit#(1)     getButtonRight();
    method  Bit#(1)     getButtonUp();
    method  Bit#(1)     getButtonDown();
    method  Bit#(1)     getButtonCenter();
    interface TopLevelWires wires_out;

endinterface

module mkTopLevelWiresDriver (TopLevelWiresDriver);

    // all XUP board signals are active low
    Reg#(Bit#(4)) led_reg <- mkReg(4'b1111);
    Reg#(Bit#(4)) switch_reg <- mkReg(4'b1111);
    Reg#(Bit#(1)) bu_reg <- mkReg(1);
    Reg#(Bit#(1)) bd_reg <- mkReg(1);
    Reg#(Bit#(1)) bl_reg <- mkReg(1);
    Reg#(Bit#(1)) br_reg <- mkReg(1);
    Reg#(Bit#(1)) bc_reg <- mkReg(1);
  
    interface TopLevelWires wires_out;

        method Bit#(4) leds();
            return led_reg;
        endmethod

        method Action switches(Bit#(4) sw);
            switch_reg <= ~sw;
        endmethod
  
        method Action  button_left(Bit#(1) bl);
            bl_reg <= ~bl;
        endmethod

        method Action  button_right(Bit#(1) br);
            br_reg <= ~br;
        endmethod
  
        method Action  button_up(Bit#(1) bu);
            bu_reg <= ~bu;
        endmethod
  
        method Action  button_down(Bit#(1) bd);
            bd_reg <= ~bd;
        endmethod

        method Action  button_center(Bit#(1) bc);
            bc_reg <= ~bc;
        endmethod
 
    endinterface
 

    // interfaces to FPGA model
    method  Action setLEDs(Bit#(4) leds_in);
        led_reg <= ~leds_in;
    endmethod

    method  Bit#(4) getSwitches();
        return switch_reg;
    endmethod

    method  Bit#(1) getButtonLeft();
        return bl_reg;
    endmethod

    method  Bit#(1) getButtonRight();
        return br_reg;
    endmethod

    method  Bit#(1) getButtonUp();
        return bu_reg;
    endmethod

    method  Bit#(1) getButtonDown();
        return bd_reg;
    endmethod

    method  Bit#(1) getButtonCenter();
        return bc_reg;
    endmethod

endmodule

