`include "hasim_common.bsh"
`include "rrr.bsh"
`include "soft_connections.bsh"
`include "low_level_platform_interface.bsh"
`include "asim/rrr/rrr_service_ids.bsh"

// TODO: replicate the exact same messages as in the hybrid version

`define REQ_PRINT_MSG       0
`define REQ_PRINT_EVENT     1
`define REQ_PRINT_STAT      2
`define REQ_PRINT_ASSERT    3

`define EVENT_STRING_DEC_NEWLINE    5

// request types
typedef union tagged
{
    // 1-parameter message
    struct
    {
        Bit#(8) msgclass;
        Bit#(32) payload;
    }
    STREAM_REQUEST_message1p;
    
    // 2-parameter message
    struct
    {
        Bit#(8) msgclass;
        Bit#(32) payload0;
        Bit#(32) payload1;
    }
    STREAM_REQUEST_message2p;

    // event
    struct
    {
        Bit#(8) stringID;
        Bit#(64) modelcycle;
        Bit#(32) payload;
    }
    STREAM_REQUEST_event;

    // stat
    struct
    {
        Bit#(8) stringID;
        Bit#(32) value;
    }
    STREAM_REQUEST_stat;

    // assertion
    struct
    {
        Bit#(8) stringID;
        Bit#(8) severity;
    }
    STREAM_REQUEST_assertion;
}
STREAM_REQUEST
    deriving (Bits, Eq);

// interface
interface Streams;
    method Action   makeRequest(STREAM_REQUEST srq);
endinterface

// mkStreams
module [HASim_Module] mkStreams#(LowLevelPlatformInterface llpi)
                      // interface
                          (Streams);

    // ----------- state -----------
    Reg#(Bool)      pendingReq      <- mkReg(False);
    Reg#(Bit#(32))  pendingReqType  <- mkReg(0);
    Reg#(Bit#(32))  pendingMsgClass <- mkReg(0);
    Reg#(Bit#(32))  pendingPayload  <- mkReg(0);
   
    // ----------- rules ------------

    // send pending message/event/stat, if any
    rule send_pending_req (pendingReq == True);
        $display("%d %d %d", pendingReqType, pendingMsgClass, pendingPayload);
        pendingReq <= False;
    endrule

    // ------------ methods ------------

    // accept request
    method Action makeRequest(STREAM_REQUEST srq) if (pendingReq == False);

        // determine type of message
        case (srq) matches

            // message with 1 payload
            tagged STREAM_REQUEST_message1p .m:
                $display("%d %d %d", `REQ_PRINT_MSG, m.msgclass, m.payload);

            // message with 2 payloads
            tagged STREAM_REQUEST_message2p .m:
            begin
                $write("%d %d %d ", `REQ_PRINT_MSG, m.msgclass, m.payload0);

                // buffer second payload, we will send it next cycle
                pendingReqType  <= `REQ_PRINT_MSG;
                pendingMsgClass <= zeroExtend(m.msgclass + 1);
                pendingPayload  <= m.payload1;
                pendingReq      <= True;
            end

            // event
            tagged STREAM_REQUEST_event .e:
            begin
                $write("%d %d %d ", `REQ_PRINT_EVENT, e.stringID, e.modelcycle);

                // buffer second payload, we will send it next cycle
                pendingReqType  <= `REQ_PRINT_EVENT;
                pendingMsgClass <= `EVENT_STRING_DEC_NEWLINE;
                pendingPayload  <= e.payload;
                pendingReq      <= True;
            end

            // stat
            tagged STREAM_REQUEST_stat .s:
                $display("%d %d %d", `REQ_PRINT_STAT, s.stringID, s.value);

            // assert
            tagged STREAM_REQUEST_assertion .a:
                $display("%d %d %d", `REQ_PRINT_ASSERT, a.stringID, a.severity);

        endcase

    endmethod

endmodule

