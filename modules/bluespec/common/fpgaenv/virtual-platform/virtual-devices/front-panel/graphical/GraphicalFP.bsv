`include "low_level_platform_interface.bsh"
`include "channelio.bsh"

typedef Bit#(8) FRONTP_LEDS;
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

module mkFrontPanel#(LowLevelPlatformInterface llpi) (FrontPanel);
    // maintain input and output caches
    Reg#(Bit#(32)) inputCache  <- mkReg(0);
    Reg#(FRONTP_LEDS) led_state <- mkReg(0);

    // we want readSwitches() to be a pure value method (to provide
    // the illusion of a wire coming from a physical switch.
    // Therefore we cannot probe the channel and update our
    // internal cache in this method; we do this in a separate
    // rule
    rule updateInputCache (True);
        Maybe#(Bit#(32)) data <- llpi.channelIO.read();
        inputCache <= fromMaybe(inputCache, data);
    endrule

    // check if our UNIX channel was forcibly closed, and if so,
    // terminate simulation
    rule detectTermination (True);
        Bool wire_out <- llpi.channelIO.isDestroyed();
        if (wire_out == True)
            $finish(0);
    endrule

    // return switch state from input cache
    method FRONTP_SWITCHES readSwitches();
        return inputCache[3:0];
    endmethod

    // return switch state from input cache
    method FRONTP_BUTTONS readButtons();
        return inputCache[8:4];
    endmethod

    // write to LEDs
    method Action writeLEDs(FRONTP_LEDS state, FRONTP_LEDS mask);
        // write to channel only if state has changed
        FRONTP_LEDS s = (led_state & ~mask) | (state & mask);
        if (s != led_state)
        begin
            led_state <= s;
            Bit#(32) ext = zeroExtend(s);
            llpi.channelIO.write(ext);
        end
    endmethod

endmodule
