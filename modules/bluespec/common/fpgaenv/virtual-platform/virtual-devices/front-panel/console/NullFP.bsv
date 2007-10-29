import toplevel_wires::*;
import low_level_platform_interface::*;

typedef Bit#(4) FRONTP_LEDS;
typedef SizeOf#(FRONTP_LEDS) FRONTP_NUM_LEDS;

typedef Bit#(4) FRONTP_SWITCHES;
typedef SizeOf#(FRONTP_SWITCHES) FRONTP_NUM_SWITCHES;

typedef Bit#(5) FRONTP_BUTTONS;
typedef SizeOf#(FRONTP_BUTTONS) FRONTP_NUM_BUTTONS;

interface FrontPanel;
    method FRONTP_SWITCHES readSwitches();
    method FRONTP_BUTTONS  readButtons();
    method Action          writeLEDs(FRONTP_LEDS data);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface pint) (FrontPanel);

    method FRONTP_SWITCHES readSwitches();
        return 0;
    endmethod

    method FRONTP_BUTTONS readButtons();
        return 0;
    endmethod

    method Action writeLEDs(FRONTP_LEDS data);
        noAction;
    endmethod

endmodule
