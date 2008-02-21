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
        $write("streamID = %u ", pack(srq.streamID));

        // stringID
        $write("stringID = %u ", pack(srq.stringID));

        // payloads
        $write("payload0 = 0x%X ", srq.payload0);
        $write("payload1 = 0x%X ", srq.payload1);

        // newline
        $display("");

    endmethod

endmodule

