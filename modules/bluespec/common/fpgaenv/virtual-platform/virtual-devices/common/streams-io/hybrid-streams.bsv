`include "rrr.bsh"
`include "low_level_platform_interface.bsh"

`include "asim/rrr/service_ids.bsh"
`include "asim/rrr/client_stub_STREAMS_IO.bsh"

`include "streams-common.bsh"

`define SERVICE_ID  `STREAMS_SERVICE_ID

// Streams
interface STREAMS_IO;
    method Action   makeRequest(STREAMID_DICT_TYPE streamID,
                                STREAMS_DICT_TYPE  stringID,
                                Bit#(32) payload0,
                                Bit#(32) payload1);
endinterface

// mkStreams
module mkStreamsIO#(LowLevelPlatformInterface llpi)
    // interface
                          (STREAMS_IO);
    
    // stubs
    ClientStub_STREAMS_IO clientStub <- mkClientStub_STREAMS_IO(llpi.rrrClient);
    
    // ------------ methods ------------

    // accept request
    method Action   makeRequest(STREAMID_DICT_TYPE streamID,
                                STREAMS_DICT_TYPE stringID,
                                Bit#(32) payload0,
                                Bit#(32) payload1);

        // make RRR request
        clientStub.makeRequest_Print(zeroExtend(pack(streamID)),
                                     zeroExtend(pack(stringID)),
                                     payload0,
                                     payload1);

    endmethod

endmodule
