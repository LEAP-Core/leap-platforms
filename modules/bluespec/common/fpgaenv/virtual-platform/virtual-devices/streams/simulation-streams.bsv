`include "hasim_common.bsh"
`include "rrr.bsh"
`include "soft_connections.bsh"
`include "low_level_platform_interface.bsh"

`include "streams-common.bsh"

// Streams
interface Streams;
    method Action   makeRequest(STREAMS_REQUEST srq);
endinterface

// mkStreams
module [HASim_Module] mkStreams#(LowLevelPlatformInterface llpi)
                      // interface
                          (Streams);

    // ------------ methods ------------

    // accept request
    method Action   makeRequest(STREAMS_REQUEST srq);

        // TODO: use dictionaries to display string messages instead of IDs
        // once dictionaries are updated to include strings for BSV
        $write("streams: ");

        // streamID
        $write("");

        // stringID
        case (srq.stringID) matches
            tagged STRINGID_message .x: $write("message stringID = %u ", pack(x));
            tagged STRINGID_event   .x: $write("event   stringID = %u ", pack(x));
            tagged STRINGID_stat    .x: $write("stat    stringID = %u ", pack(x));
            tagged STRINGID_assert  .x: $write("assert  stringID = %u ", pack(x));
            tagged STRINGID_memtest .x: $write("memtest stringID = %u ", pack(x));
        endcase

        // payloads
        $write("payload = 0x%X", srq.payload0);

        // newline
        $display("");

    endmethod

endmodule

