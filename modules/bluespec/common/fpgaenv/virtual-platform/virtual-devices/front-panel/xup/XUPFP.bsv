import low_level_platform_interface::*;
import toplevel_wires::*;

typedef TOPWIRES_LEDS FRONTP_LEDS;
typedef SizeOf#(FRONTP_LEDS) FRONTP_NUM_LEDS;

//
// Data structure for updating specific LEDs and leaving others unchanged.
//
typedef struct
{
    FRONTP_LEDS state;
    FRONTP_LEDS mask;
}
FRONTP_MASKED_LEDS deriving (Eq, Bits);


typedef TOPWIRES_SWITCHES FRONTP_SWITCHES;
typedef SizeOf#(FRONTP_SWITCHES) FRONTP_NUM_SWITCHES;

typedef Bit#(5) FRONTP_BUTTONS;
typedef SizeOf#(FRONTP_BUTTONS) FRONTP_NUM_BUTTONS;

interface FrontPanel;
    method FRONTP_SWITCHES readSwitches();
    method FRONTP_BUTTONS  readButtons();
    method Action          writeLEDs(FRONTP_MASKED_LEDS data);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface llpi) (FrontPanel);

    Reg#(FRONTP_LEDS) led_state <- mkReg(0);

    method FRONTP_SWITCHES readSwitches();
        // read from toplevel wires
        return (llpi.topLevelWires.getSwitches());
    endmethod

    method FRONTP_BUTTONS readButtons();
        // read from toplevel wires
        FRONTP_BUTTONS all_inputs;

        all_inputs[0]   = llpi.topLevelWires.getButtonUp();
        all_inputs[1]   = llpi.topLevelWires.getButtonLeft();
        all_inputs[2]   = llpi.topLevelWires.getButtonCenter();
        all_inputs[3]   = llpi.topLevelWires.getButtonRight();
        all_inputs[4]   = llpi.topLevelWires.getButtonDown();

        return all_inputs;
    endmethod

    method Action writeLEDs(FRONTP_MASKED_LEDS data);
        FRONTP_LEDS s = (led_state & ~data.mask) | (data.state & data.mask);
        led_state <= s;
        llpi.topLevelWires.setLEDs(s);
    endmethod

endmodule
