`include "low_level_platform_interface.bsh"
`include "rrr.bsh"
`include "physical_platform.bsh"

`include "asim/rrr/service_ids.bsh"
`include "asim/rrr/server_stub_FRONT_PANEL.bsh"
`include "asim/rrr/client_stub_FRONT_PANEL.bsh"

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

typedef Bit#(32) FRONTP_INPUT_STATE;

interface FrontPanel;
    method FRONTP_SWITCHES readSwitches();
    method FRONTP_BUTTONS  readButtons();
    method Action          writeLEDs(FRONTP_LEDS state, FRONTP_LEDS mask);
endinterface

module mkFrontPanel#(LowLevelPlatformInterface llpi) (FrontPanel);

    // state
    Reg#(FRONTP_INPUT_STATE)    inputCache  <- mkReg(0);
    Reg#(FRONTP_LEDS)           ledState    <- mkReg(0);
    Reg#(Bool)                  outputDirty <- mkReg(False);

    // stubs
    ServerStub_FRONT_PANEL server_stub <- mkServerStub_FRONT_PANEL(llpi.rrrServer);
    ClientStub_FRONT_PANEL client_stub <- mkClientStub_FRONT_PANEL(llpi.rrrClient);

    // sync LED state
    rule send_RRR_request (outputDirty == True);
        client_stub.makeRequest_UpdateLEDs(ledState);
        outputDirty <= False;
    endrule

    // read incoming updates for switch/button state
    rule probe_updates (True);
        FRONTP_INPUT_STATE data <- server_stub.acceptRequest_UpdateSwitchesButtons();
        inputCache <= data;
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
        FRONTP_LEDS new_state = (ledState & ~mask) | (state & mask);
        if (new_state != ledState)
        begin
            ledState <= new_state;
            outputDirty <= True;
        end
    endmethod

endmodule