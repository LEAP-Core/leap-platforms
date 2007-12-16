`include "low_level_platform_interface.bsh"
`include "rrr.bsh"
`include "physical_platform.bsh"

`include "rrr_service_ids.bsh"

`define FP_POLL_INTERVAL    1000

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
    method Action          writeLEDs(FRONTP_MASKED_LEDS data);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface llpint) (FrontPanel);
    // maintain input and output caches
    Reg#(Bit#(32))  inputCache  <- mkReg(0);
    Reg#(Bit#(8))   state       <- mkReg(0);
    Reg#(Bit#(16))  pollCounter <- mkReg(0);
    Reg#(FRONTP_LEDS) led_state <- mkReg(0);

    // ugly: constantly keep sending RRR requests to sync up
    // state of both inputs and outputs
    rule sendRRRRequest (state == 0 && pollCounter == 0);
        RRR_Request req;
        req.serviceID       = `FRONT_PANEL_SERVICE_ID;
        req.param0          = zeroExtend(led_state);
        req.param1          = 0;
        req.param2          = 0;
        req.needResponse    = True;
        llpint.rrrClient.makeRequest(req);
        state <= 1;
    endrule

    rule cyclePollCounter (True);
        if (pollCounter == `FP_POLL_INTERVAL - 1)
            pollCounter <= 0;
        else
            pollCounter <= pollCounter + 1;
    endrule

    // read RRR response and update input cache... note that
    // we do not need any internal state machine to determine
    // when we can perform a valid read
    rule readRRRResponse (state == 1);
        Bit#(32) data <- llpint.rrrClient.getResponse();
        inputCache <= data;
        state <= 0;
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
    method Action writeLEDs(FRONTP_MASKED_LEDS data);
        led_state <= (led_state & ~data.mask) | (data.state & data.mask);
    endmethod

endmodule
