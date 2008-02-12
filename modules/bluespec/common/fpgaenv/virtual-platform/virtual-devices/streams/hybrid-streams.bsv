`include "hasim_common.bsh"
`include "rrr.bsh"
`include "soft_connections.bsh"
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

        // start creating a new RRR request packet
        RRR_Request req;

        // pack serviceID and streamID
        req.serviceID = `SERVICE_ID;
        req.param0    = zeroExtend(pack(srq.streamID));

        // pack stringID
        req.param1    = case (srq.stringID) matches
                            tagged STRINGID_message .x: zeroExtend(pack(x));
                            tagged STRINGID_event   .x: zeroExtend(pack(x));
                            tagged STRINGID_stat    .x: zeroExtend(pack(x));
                            tagged STRINGID_assert  .x: zeroExtend(pack(x));
                            tagged STRINGID_memtest .x: zeroExtend(pack(x));
                        endcase;

        req.param2    = srq.payload0;
        req.param3    = srq.payload1;

        // make RRR request
        llpi.rrrClient.makeRequest(req);

    endmethod

endmodule

