`include "hasim_common.bsh"
`include "rrr.bsh"
`include "soft_connections.bsh"
`include "low_level_platform_interface.bsh"

`include "streams-common.bsh"

`include "asim/dict/STREAMS.bsh"
`include "asim/dict/STREAMID.bsh"

// Streams
interface Streams;
    method Action   makeRequest(STREAMS_REQUEST srq);
endinterface

// mkStreams
module [HASim_Module] mkStreams#(LowLevelPlatformInterface llpi)
                      // interface
                          (Streams);
 
    Reg#(File) event_log  <- mkReg(InvalidFile);
    Reg#(File) stat_log   <- mkReg(InvalidFile);
    Reg#(File) assert_log <- mkReg(InvalidFile);

    rule open_events (event_log == InvalidFile);
    
      let fd <- $fopen("stream_events.out");
      
      if (fd == InvalidFile)
      begin
      
        $display("ERROR: STREAMS: Could not open file stream_events.out");
        $finish(1);
      
      end
      
      event_log <= fd;
    
    endrule

    rule open_stats (stat_log == InvalidFile);
    
      let fd <- $fopen("stream_stats.out");
      
      if (fd == InvalidFile)
      begin
      
        $display("ERROR: STREAMS: Could not open file stream_stats.out");
        $finish(1);
      
      end
      
      stat_log <= fd;
    
    endrule

    rule open_asserts (assert_log == InvalidFile);
    
      let fd <- $fopen("stream_asserts.out");
      
      if (fd == InvalidFile)
      begin
      
        $display("ERROR: STREAMS: Could not open file stream_assserts.out");
        $finish(1);
      
      end
      
      assert_log <= fd;
    
    endrule
    // ------------ methods ------------

    // accept request

    method Action   makeRequest(STREAMS_REQUEST srq);

        String msg = showSTREAMS_DICT(srq.stringID);
        
        case (srq.streamID)

    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //
    // NOTE:  The code below should really be distributed to different
    //        managers to handle individual flavors of stream ids.
    //        It should be legal to build a model with just a NULL
    //        streamID.  For now we use a hack and add special case
    //        code for certain well known stream IDs, but this should
    //        be fixed.
    //
    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


`ifdef STREAMID_ASSERT
            `STREAMID_ASSERT:
            begin
              case (srq.payload0)
                0:
                begin
                  $fdisplay(assert_log, "MESSAGE: %s", msg); //Message
                end
                1: 
                begin
                  $fdisplay(assert_log, "WARNING: %s", msg);
                  $display("ASSERTION FAILURE: WARNING: %s", msg);
                end
                2:
                begin
                  $fdisplay(assert_log, "ERROR: %s", msg);
                  $display("ASSERTION FAILURE: ERRROR: %s", msg);
                  $finish(1);
                end
                
              endcase
            end
`endif              

`ifdef STREAMID_EVENT
            `STREAMID_EVENT:
            begin
              $fdisplay(event_log, msg, srq.payload0, srq.payload1);
            end
`endif              

`ifdef STREAMID_HEARTBEAT
            `STREAMID_HEARTBEAT:
            begin
              $display("Heartbeat: FPGA Cycle: %0d, Model Cycle: %0d", srq.payload0, srq.payload1); 
            end
`endif              

`ifdef STREAMID_STAT
            `STREAMID_STAT:
            begin
              $fdisplay(stat_log, msg, srq.payload0);
            end
`endif              

            `STREAMID_NULL:
            begin
              noAction;
            end

        endcase

    endmethod

endmodule

