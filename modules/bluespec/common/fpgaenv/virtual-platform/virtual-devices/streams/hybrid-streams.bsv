`include "rrr.bsh"
`include "low_level_platform_interface.bsh"

`include "asim/rrr/rrr_service_ids.bsh"
`include "streams-common.bsh"

`define SERVICE_ID  `STREAMS_SERVICE_ID

// Streams
interface Streams;
    method Action   makeRequest( STREAMID_DICT_TYPE streamID,
                                 STREAMS_DICT_TYPE  stringID,
                                 Bit#(32) payload0,
                                 Bit#(32) payload1);
endinterface

// mkStreams
module mkStreams#(LowLevelPlatformInterface llpi)
    // interface
                          (Streams);

    // ------------ methods ------------

    // accept request
    method Action   makeRequest( STREAMID_DICT_TYPE streamID,
                                 STREAMS_DICT_TYPE stringID,
                                 Bit#(32) payload0,
                                 Bit#(32) payload1);

        // make RRR request
        llpi.rrrClient.makeRequest(RRR_Request {
                                       serviceID   : `SERVICE_ID,
                                       param0      : zeroExtend(pack(streamID)),
                                       param1      : zeroExtend(pack(stringID)),
                                       param2      : payload0,
                                       param3      : payload1,
                                       needResponse: False
                                   });

    endmethod

endmodule

