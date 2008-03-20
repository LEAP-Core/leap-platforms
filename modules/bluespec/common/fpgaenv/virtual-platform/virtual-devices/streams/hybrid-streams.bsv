`include "hasim_common.bsh"
`include "rrr.bsh"
`include "low_level_platform_interface.bsh"

`include "asim/rrr/rrr_service_ids.bsh"
`include "streams-common.bsh"

`define SERVICE_ID  `STREAMS_SERVICE_ID

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

        // make RRR request
        llpi.rrrClient.makeRequest(RRR_Request {
                                       serviceID   : `SERVICE_ID,
                                       param0      : zeroExtend(pack(srq.streamID)),
                                       param1      : zeroExtend(pack(srq.stringID)),
                                       param2      : srq.payload0,
                                       param3      : srq.payload1,
                                       needResponse: False
                                   });

    endmethod

endmodule

