import low_level_platform_interface::*;

typedef Bit#(4) FRONTP_LEDS;
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


typedef Bit#(4) FRONTP_SWITCHES;
typedef SizeOf#(FRONTP_SWITCHES) FRONTP_NUM_SWITCHES;

typedef Bit#(5) FRONTP_BUTTONS;
typedef SizeOf#(FRONTP_BUTTONS) FRONTP_NUM_BUTTONS;

interface FrontPanel;
    method FRONTP_SWITCHES readSwitches();
    method FRONTP_BUTTONS  readButtons();
    method Action          writeLEDs(FRONTP_LEDS state, FRONTP_LEDS mask);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface pint) (FrontPanel);

    method FRONTP_SWITCHES readSwitches();
        return 0;
    endmethod

    method FRONTP_BUTTONS readButtons();
        return 0;
    endmethod

    method Action writeLEDs(FRONTP_LEDS state, FRONTP_LEDS mask);
        noAction;
    endmethod

endmodule
