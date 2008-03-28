import low_level_platform_interface::*;
import physical_platform::*;
import led_device::*;
import switch_device::*;
import button_device::*;

typedef 4 FRONTP_NUM_LEDS;
typedef 4 FRONTP_NUM_SWITCHES;
typedef 5 FRONTP_NUM_BUTTONS;

typedef Bit#(FRONTP_NUM_LEDS) FRONTP_LEDS;
typedef Bit#(FRONTP_NUM_SWITCHES) FRONTP_SWITCHES;
typedef Bit#(FRONTP_NUM_BUTTONS) FRONTP_BUTTONS;

//
// Data structure for updating specific LEDs and leaving others unchanged.
//
typedef struct
{
    FRONTP_LEDS state;
    FRONTP_LEDS mask;
}
FRONTP_MASKED_LEDS deriving (Eq, Bits);

interface FrontPanel;
    method FRONTP_SWITCHES readSwitches();
    method FRONTP_BUTTONS  readButtons();
    method Action          writeLEDs(FRONTP_LEDS state, FRONTP_LEDS mask);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface llpi) (FrontPanel);

    Reg#(FRONTP_LEDS) led_state <- mkReg(0);

    method FRONTP_SWITCHES readSwitches();
        // read from toplevel wires
        return (llpi.physicalDrivers.switchesDriver.getSwitches());
    endmethod

    method FRONTP_BUTTONS readButtons();
        // read from toplevel wires
        FRONTP_BUTTONS all_inputs = llpi.physicalDrivers.buttonsDriver.getButtons();

        return all_inputs;
    endmethod

    method Action writeLEDs(FRONTP_LEDS state, FRONTP_LEDS mask);
        FRONTP_LEDS s = (led_state & ~mask) | (state & mask);
        led_state <= s;
        llpi.physicalDrivers.ledsDriver.setLEDs(s);
    endmethod

endmodule
