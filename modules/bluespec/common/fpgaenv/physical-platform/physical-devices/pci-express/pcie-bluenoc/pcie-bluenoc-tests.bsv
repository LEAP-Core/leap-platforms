import FIFO::*;
import Vector::*;
import BlueNoC::*;
import Connectable::*;
import TieOff::*;

`include "awb/provides/librl_bsv_base.bsh"


// ========================================================================
//
//   Test engines that are connected to the local switch.  Derived from
//   tests written by Bluespec.
//
// ========================================================================

//
// mkSwitchWithTests --
//   Insert a switch with a few test ports between the NOC connected to the
//   host and the primary design.  Destination 2 is a sink.  Destination
//   3 is a flooder.  Destination 1 is returned as the first port in
//   the return vector and may be used by the caller or tied off.  All other
//   messages are routed to the port returned as the 2nd element in the
//   returned vector.
//
module mkSwitchWithTests#(MsgPort#(n_BPB) hostPort)
    // Interface:
    (Vector#(2, MsgPort#(n_BPB)))
    provisos (Add#(_a, 32, TMul#(8, n_BPB)),
              // Isn't the above enough?
              Add#(_b, 8, TMul#(8, n_BPB)));

    //
    // Insert a test switch here, usefull for verifying PCIe integrity and
    // testing performance.  Clients of this device driver thus have
    // destination addresses 4 and above.
    //
    SIMPLE_SWITCH#(4, n_BPB) switch <-
        mkSimpleSwitch(mkFifoMsgSink, mkFifoMsgSource);
    
    // Connection to host
    mkConnection(switch.primary, hostPort);

//    Port 0 returned for use by the caller instead of reflector...
//
//    MsgPort#(n_BPB) reflector <- mkReflectorTest();
//    mkConnection(reflector, switch.ports[0]);

    MsgPort#(n_BPB) sink <- mkSinkTest();
    mkConnection(sink, switch.ports[1]);

    MsgPort#(n_BPB) flooder <- mkFloodTest();
    mkConnection(flooder, switch.ports[2]);

    Vector#(2, MsgPort#(n_BPB)) ports = newVector();
    ports[0] = switch.ports[0];   // Test port (network destination 1)
    ports[1] = switch.ports[3];   // Design port (network destinations 4+)

    return ports;
endmodule


//
// mkReflectorTest --
//   Route incoming messages back to sender.
//
module mkReflectorTest
    // Interface:
    (MsgPort#(n_BPB))
    provisos (Add#(_a, 8, TMul#(8, n_BPB)));

    if (valueOf(n_BPB) < 4)
    begin
        error("mkReflectorTest assumes bytes per byte >= 4");
    end

    FifoMsgSink#(n_BPB) beats_in  <- mkFifoMsgSink();
    FIFO#(MsgBeat#(n_BPB)) refl_fifo <- mkSizedFIFO(256 / valueOf(n_BPB));
    FifoMsgSource#(n_BPB)  beats_out <- mkFifoMsgSource();

    UInt#(8) bpb = fromInteger(valueOf(n_BPB));
    Reg#(UInt#(8)) remainingBytesIn <- mkReg(0);

    rule xfer1 if (! beats_in.empty());
        let beat = beats_in.first();
        beats_in.deq();

        refl_fifo.enq(beat);
    endrule

    rule xfer2Header (remainingBytesIn == 0);
        let beat = refl_fifo.first();
        refl_fifo.deq();

        // Swap routing info to reflect the message
        let new_src = beat[7:0];
        let new_dst = beat[15:8];
        beat[7:0] = new_dst;
        beat[15:8] = new_src;

        beats_out.enq(beat);

        UInt#(8) remaining_bytes_in = unpack(beat[23:16]);
        UInt#(8) data_space_in_first_beat = bpb - 4;
        if (remaining_bytes_in > data_space_in_first_beat)
        begin
            remainingBytesIn <= remaining_bytes_in - data_space_in_first_beat;
        end
    endrule

    rule xfer2Body (remainingBytesIn != 0);
        let beat = refl_fifo.first();
        refl_fifo.deq();

        beats_out.enq(beat);

        if (remainingBytesIn <= bpb)
            remainingBytesIn <= 0;
        else
            remainingBytesIn <= remainingBytesIn - bpb;
    endrule

   return as_port(beats_out.source,beats_in.sink);

endmodule


//
// mkSinkTest --
//   Sink incoming messages.
//
module mkSinkTest
    // Interface:
    (MsgPort#(n_BPB));

    interface MsgSource out;
        method Bool src_rdy = False; // never ready
        method Action dst_rdy(Bool b);
            // do nothing
        endmethod
        method MsgBeat#(n_BPB) beat = ?;
    endinterface

    interface MsgSink in;
        method Bool dst_rdy = True; // always ready
        method Action src_rdy(Bool b);
            // do nothing
        endmethod
        method Action beat(MsgBeat#(n_BPB) v);
            // do nothing
        endmethod
    endinterface

endmodule


//
// mkFloodTest --
//   Flood output with requested number of messages.
//
module mkFloodTest
    // Interface:
    (MsgPort#(n_BPB))
    provisos (Add#(_a, 32, TMul#(8, n_BPB)));

    // Proviso forces n_BPB to be >= 4.  Also confirm that it is a power of 2.
    check_bytes_per_beat("mkFloodTest", valueOf(n_BPB));

    FifoMsgSink#(n_BPB)   beats_in  <- mkFifoMsgSink();
    FifoMsgSource#(n_BPB) beats_out <- mkFifoMsgSource();

    Reg#(UInt#(1)) beatInIdx <- mkReg(0);

    Reg#(NodeID)    sendFromNode  <- mkReg(0);
    Reg#(NodeID)    sendToNode    <- mkReg(0);
    Reg#(UInt#(32)) beatsToSend   <- mkReg(0);
    Reg#(UInt#(8))  pos           <- mkReg(0);

    //
    // parseIncoming --
    //     Handle incoming requests to generate a flood of outbound data.
    //     This parser is very simple.  The message body size must be 4 bytes.
    //     (There is also a 4 byte header.)
    //
    rule parseIncoming if (! beats_in.empty() && beatsToSend == 0);
        let beat = beats_in.first();
        beats_in.deq();

        if (beatInIdx == 0)
        begin
            sendFromNode <= unpack(beat[7:0]);
            sendToNode   <= unpack(beat[15:8]);
        end

        if (valueOf(n_BPB) > 4)
        begin
            // Send length fits in the first beat
            beatsToSend <= unpack(beat[63:32]);
        end
        else if (beatInIdx == 1)
        begin
            // 4 byte beats, 2nd beat has the length
            beatsToSend <= unpack(beat[31:0]);
            beatInIdx <= 0;
        end
        else
        begin
            // Move on to 2nd beat of 4 byte beats
            beatInIdx <= 1;
        end
    endrule

    rule sendOutbound if (beatsToSend != 0);
        UInt#(32) max_beats_per_msg = 256 / fromInteger(valueOf(n_BPB));

        if (pos == 0)
        begin
            // New message
            UInt#(8) len = (beatsToSend > max_beats_per_msg) ?
                               252 :
                               truncate(beatsToSend * fromInteger(valueOf(n_BPB)) - 4);
            Bool dw = (beatsToSend > max_beats_per_msg) ? False : True;
            beats_out.enq(zeroExtend({7'd0, pack(dw),pack(len),pack(sendFromNode),pack(sendToNode)}));
            pos <= pos + 1;
        end
        else
        begin
            beats_out.enq(resize({pack(beatsToSend << 1),
                                  pack(beatsToSend)}));

            if ((pos == truncate(max_beats_per_msg - 1)) || (beatsToSend == 1))
                pos <= 0;
            else
                pos <= pos + 1;
        end

        beatsToSend <= beatsToSend - 1;
    endrule

    return as_port(beats_out.source,beats_in.sink);

endmodule
