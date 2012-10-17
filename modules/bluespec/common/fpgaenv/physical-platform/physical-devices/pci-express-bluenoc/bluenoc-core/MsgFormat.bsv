/*****************************************************************
 *          DEFINITION OF THE ROUTING LAYER PROTOCOL             *
 *****************************************************************/

/* This is a message format suitable for data exchange in an FPGA or
 * board-level network.  The goal is to be simple and efficient.
 *
 * This format attempts to abstract away from the peculiarities and
 * restrictions of any particular bus or network protocol and to avoid
 * dictating a particular choice of network topology, switch type
 * or application layer protocol.
 */

import Vector       :: *;
import Connectable  :: *;
import GetPut       :: *;
import FIFO         :: *;
import FIFOF        :: *;
import SpecialFIFOs :: *;
import TieOff       :: *;

/* The network consists of a collection of up to 256 nodes, each
 * given a unique 8-bit identifier.  The structure of the identifier
 * is unspecified to allow flexibility in the choice of network
 * structure.
 */

typedef Bit#(8) NodeID;

/* All messages use a little-endian byte order.
 *
 * A message consists of a 4-byte header followed by
 * 0 to 255 bytes of payload data.
 *
 * The 4-byte header comprises a destination NodeID in
 * the first byte, a source NodeID in the second byte,
 * the payload size in the third byte, and some metadata
 * in the last byte.
 *
 *     Byte 3  | Byte 2 | Byte 1 | Byte 0
 *   +------+--+--------+--------+--------+
 *   |  OP  |DP| LENGTH |  SRC   |   DST  |
 *   +------+--+--------+--------+--------+
 *    31  26    23    16 15     8 7      0
 *
 * The contents of Byte 3 are divided into:
 *
 *   - 2 bits that specify delivery properties for the
 *     message at the routing layer
 *   - 6 bits of opcode that convey information about the
 *     format and meaning of the payload data at the
 *     application layer
 *
 * Therefore, this byte can be said to span the transition from
 * pure message routing information to application-level data.
 *
 * Of the two delivery property bits, bit 24 is used to mark a
 * message "do not wait", so that it will be delivered immediately
 * instead of waiting for a buffer to fill. This allows finer
 * control over the throughput/latency trade-off based on the
 * message source's expected traffic pattern. Bit 25 is reserved
 * for future use.
 *
 * The 6 bits of opcode occupy bits 26 through 31 and are
 * determined by the application layer. They allow the
 * application layer to communicate information about the
 * intent of the message and the format of the payload data,
 * if any.
 *
 * The header will be followed by LENGTH bytes of payload data.
 *
 * Messages are assumed to be transmitted between network nodes as
 * a series of beats.  Beats can be 2^n bytes wide for n=0,1,2,...
 * and are assumed to be transmitted back-to-back on the inter-node
 * channel.  The channel is allowed to stall, but it should not
 * intermix beats from different messages.
 *
 * For channels with multi-byte beats the bytes of the message fill
 * the beat from least-significant to most-significant byte.
 *
 * Messages always begin on the least-significant byte of a beat
 * and if the message does not completely fill the last beat, the
 * upper bytes of the last beat will be padded with zeros.
 *
 * This ensures that the very first byte in any message contains
 * the destination NodeID so that the routing of the message can
 * be fully determined by the first beat even for a channel only
 * one byte wide.
 *
 * Therefore the most general format for a message segmented
 * into beats is: 4 bytes of message header, followed by 0 to
 * 255 bytes of payload data, followed by 0 to bytes_per_beat-1
 * bytes of padding.
 */

/* The MsgBeat type is parameterized by the number of bytes per
 * beat, allowing the compiler to check that both participants in
 * a message exchange are using the same beat size. It does not,
 * however, check that they are using compatible application-level
 * protocols.
 */

typedef Bit#(TMul#(8,bytes_per_beat)) MsgBeat#(numeric type bytes_per_beat);

/* MsgSource and MsgSink together form two endpoints of a message
 * channel. The message is considered transfered when both the source
 * and the sink assert their ready signals during the same cycle.
 */

// Message source, parameterized by the beat size and address size.
interface MsgSource#(numeric type bytes_per_beat);
   (* always_ready *)
   method Bool src_rdy();
   (* always_ready, always_enabled *)
   method Action dst_rdy(Bool b);
   (* always_ready *)
   method MsgBeat#(bytes_per_beat) beat();
endinterface

// Message sink, parameterized by the beat size and address size
interface MsgSink#(numeric type bytes_per_beat);
   (* always_ready *)
   method Bool dst_rdy();
   (* always_ready, always_enabled *)
   method Action src_rdy(Bool b);
   (* always_ready, always_enabled *)
   method Action beat(MsgBeat#(bytes_per_beat) v);
endinterface

// MsgSource and MsgSink are connectable if the beat sizes match.

instance Connectable#(MsgSource#(bpb),MsgSink#(bpb));
   module mkConnection#(MsgSource#(bpb) source, MsgSink#(bpb) sink)();
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_src_rdy;
         sink.src_rdy(source.src_rdy());
      endrule
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_dst_rdy;
         source.dst_rdy(sink.dst_rdy());
      endrule
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_data;
         sink.beat(source.beat());
      endrule
   endmodule
endinstance

instance Connectable#(MsgSink#(bpb),MsgSource#(bpb));
   module mkConnection#(MsgSink#(bpb) sink, MsgSource#(bpb) source)();
      let _m <- mkConnection(source,sink);
      return _m;
   endmodule
endinstance

/* It is often required to tie-off unused message sources or sinks
 * For MsgSource, this will accept messages and discard them.
 * For MsgSink, this will never send a message.
 */

instance TieOff#(MsgSource#(bpb));
   module mkTieOff#(MsgSource#(bpb) ifc)();
      // always be ready but don't look at the data
      (* fire_when_enabled, no_implicit_conditions *)
      rule always_accept_beat;
         ifc.dst_rdy(True);
      endrule
   endmodule
endinstance

instance TieOff#(MsgSink#(bpb));
   module mkTieOff#(MsgSink#(bpb) ifc)();
      // never be ready
      (* fire_when_enabled, no_implicit_conditions *)
      rule never_be_ready;
         ifc.src_rdy(False);
      endrule
      // the beat data doesn't matter
      (* fire_when_enabled, no_implicit_conditions *)
      rule send_whatever;
         ifc.beat(?);
      endrule
   endmodule
endinstance

/* FIFO versions of the source and sink expose a FIFO-like half and
 * MsgSource/MsgSink half
 */

interface FifoMsgSource#(numeric type bpb);
   method Bool   full();
   method Action enq(MsgBeat#(bpb) v);
   method Action clear();
   interface MsgSource#(bpb) source;
endinterface: FifoMsgSource

interface FifoMsgSink#(numeric type bpb);
   method Bool          empty();
   method MsgBeat#(bpb) first();
   method Action        deq();
   method Action        clear();
   interface MsgSink#(bpb) sink;
endinterface: FifoMsgSink

// Create a FIFO and expose its destination half as a MsgSource
module mkFifoMsgSource(FifoMsgSource#(bpb));

   // The FIFO for storing message beats
   FIFOF#(MsgBeat#(bpb)) f <- mkUGFIFOF();

   // The MsgSource beat is valid if the FIFO is not empty
   Bool src_ok = f.notEmpty();

   Wire#(Bool) dst_ok <- mkBypassWire();

   // The beat transfers when both src and dst assert ready
   (* fire_when_enabled, no_implicit_conditions *)
   rule update if (src_ok && dst_ok);
      f.deq();
   endrule

   // Expose the FIFO's full condition
   method Bool full();
      return !f.notFull();
   endmethod

   // Allow beats to be added to the FIFO
   method Action enq(MsgBeat#(bpb) v) if (f.notFull());
      f.enq(v);
   endmethod

   // Clear the FIFO
   method Action clear();
      f.clear();
   endmethod

   // The MsgSource view of the FIFO destination side
   interface MsgSource source;
      method src_rdy = src_ok;        // FIFO is not empty
      method dst_rdy = dst_ok._write; // destination is ready
      method beat    = f.first();     // next FIFO value
   endinterface

endmodule: mkFifoMsgSource

// Create a FIFO and expose its source half as a MsgSink
module mkFifoMsgSink(FifoMsgSink#(bpb));

   // The FIFO for storing message beats
   FIFOF#(MsgBeat#(bpb)) f <- mkUGFIFOF();

   Wire#(Bool) src_ok <- mkBypassWire();

   // The sink is ready when the FIFO has space
   Bool dst_ok = f.notFull();

   Wire#(MsgBeat#(bpb)) val <- mkBypassWire();

   // The beat transfers when both src and dst assert ready
   (* fire_when_enabled, no_implicit_conditions *)
   rule update if (src_ok && dst_ok);
      f.enq(val);
   endrule

   // Expose the FIFO's empty condition
   method Bool empty();
      return !f.notEmpty();
   endmethod

   // Expose the FIFO's next data value (unguarded)
   method MsgBeat#(bpb) first();
      return f.first();
   endmethod

   // Allow data to be removed from the FIFO (unguarded)
   method Action deq();
      f.deq();
   endmethod

   // Clear the FIFO
   method Action clear();
      f.clear();
   endmethod

   // The MsgSink view of the FIFO source side
   interface MsgSink sink;
      method dst_rdy = dst_ok;        // FIFO is not full
      method src_rdy = src_ok._write; // source data is valid
      method beat    = val._write;    // data from source
   endinterface

endmodule: mkFifoMsgSink

// Functions used to extract source and sink interfaces

function MsgSource#(bpb) get_source_ifc(FifoMsgSource#(bpb) fsource);
   return fsource.source;
endfunction

function MsgSink#(bpb) get_sink_ifc(FifoMsgSink#(bpb) fsink);
   return fsink.sink;
endfunction

/* Standard definition of a bidirectional port for
 * building switches and connecting nodes to the NoC.
 */

interface MsgPort#(numeric type bpb);
   interface MsgSink#(bpb)   in;
   interface MsgSource#(bpb) out;
endinterface: MsgPort

instance Connectable#(MsgPort#(bpb), MsgPort#(bpb));
   module mkConnection#(MsgPort#(bpb) p1, MsgPort#(bpb) p2)();
      mkConnection(p1.in,  p2.out);
      mkConnection(p1.out, p2.in);
   endmodule
endinstance

instance TieOff#(MsgPort#(bpb));
   module mkTieOff#(MsgPort#(bpb) p)();
      mkTieOff(p.in);
      mkTieOff(p.out);
   endmodule
endinstance

function MsgPort#(bpb) as_port( MsgSource#(bpb) src
                              , MsgSink#(bpb)   snk
                              );
   return (interface MsgPort;
              interface MsgSink   in  = snk;
              interface MsgSource out = src;
           endinterface);
endfunction: as_port

// This function is useful for creating routing predicates
function Bool hasNodeID(NodeID target, NodeID n);
   return (n == target);
endfunction: hasNodeID

// This utility module checks that the bytes_per_beat value is legal.
module check_bytes_per_beat#(String prefix, Integer bytes_per_beat)();
   if (bytes_per_beat < 1)
      errorM(prefix + ": Invalid beat size (" + integerToString(bytes_per_beat) + ") should be > 1");
   Bool is_power_of_two = False;
   Integer n = bytes_per_beat;
   while (n != 0) begin
      if (n % 2 == 1) begin
         if (is_power_of_two) begin
            is_power_of_two = False;
            n = 0;
         end
         else
            is_power_of_two = True;
      end
      n = n / 2;
   end
   if (!is_power_of_two)
      errorM(prefix + ": Invalid beat size (" + integerToString(bytes_per_beat) + ") should be a power of 2");
endmodule

/* This is a minimal utility for extracting routing information from
 * a stream of beats.
 */

interface MsgRoute#(numeric type bpb);

   // provide the next beat
   (* always_ready *)
   method Action beat(MsgBeat#(bpb) v);

   // commit the state updates for this beat
   (* always_ready *)
   method Action advance();

   // read the routing information from the beat
   method NodeID   dst();
   method NodeID   src();
   method UInt#(8) length();
   method Bool     dont_wait();
   method Bit#(6)  opcode();

   // beat framing signals
   (* always_ready *)
   method Bool first_beat();
   (* always_ready *)
   method Bool last_beat();
   (* always_ready *)
   method UInt#(9) remaining_bytes();

   // discard current message status
   (* always_ready *)
   method Action clear();

endinterface: MsgRoute

module mkMsgRoute(MsgRoute#(bpb));

   Integer bytes_per_beat = valueOf(bpb);

   check_bytes_per_beat("mkMsgRoute", bytes_per_beat);

   // the incoming beat
   Wire#(Vector#(bpb,Bit#(8))) the_beat <- mkWire();

   // wires to report what was learned from the beat
   Wire#(NodeID)    dst_w         <- mkWire();
   Wire#(NodeID)    src_w         <- mkWire();
   Wire#(UInt#(8))  len_w         <- mkWire();
   Wire#(Bool)      dont_wait_w   <- mkWire();
   Wire#(Bit#(6))   opcode_w      <- mkWire();
   RWire#(UInt#(9)) new_remaining <- mkRWire();
   PulseWire        first_beat_pw <- mkPulseWire();
   PulseWire        last_beat_pw  <- mkPulseWire();

   // message decoding state
   Reg#(UInt#(3)) header_pos <- mkReg(0);
   Reg#(UInt#(9)) remaining  <- mkReg(0);

   // decode the incoming beat
   rule decode_beat;
      // extract destination and mark beginning of msg
      if (header_pos == 0) begin
         dst_w <= unpack(the_beat[0]);
         first_beat_pw.send();
      end

      // extract source
      if (bytes_per_beat == 1) begin
         if (header_pos == 1) src_w <= unpack(the_beat[0]);
      end
      else begin
         if (header_pos == 0) src_w <= unpack(the_beat[1]);
      end

      // extract the length
      if (bytes_per_beat == 1) begin
         if (header_pos == 2) begin
            UInt#(8) len = unpack(the_beat[0]);
            UInt#(9) bytes_after = 1 + zeroExtend(len);
            len_w <= len;
            new_remaining.wset(bytes_after);
         end
      end
      else if (bytes_per_beat == 2) begin
         if (header_pos == 2) begin
            UInt#(8) len = unpack(the_beat[0]);
            UInt#(9) bytes_after = zeroExtend(len);
            len_w <= len;
            new_remaining.wset(bytes_after);
         end
      end
      else if (header_pos == 0) begin
         UInt#(8) len = unpack(the_beat[2]);
         UInt#(8) space_in_beat = fromInteger(bytes_per_beat - 4);
         UInt#(9) bytes_after = (space_in_beat >= len) ? 0 : (zeroExtend(len - space_in_beat));
         len_w <= len;
         new_remaining.wset(bytes_after);
      end

      // extract the dont_wait bit and opcode
      if (bytes_per_beat == 1) begin
         if (header_pos == 3) begin
            dont_wait_w <= unpack(the_beat[0][0]);
            opcode_w    <= unpack(the_beat[0][7:2]);
            new_remaining.wset(remaining - 1);
         end
      end
      else if (bytes_per_beat == 2) begin
         if (header_pos == 2) begin
            dont_wait_w <= unpack(the_beat[1][0]);
            opcode_w    <= unpack(the_beat[1][7:2]);
         end
      end
      else if (header_pos == 0) begin
         dont_wait_w <= unpack(the_beat[3][0]);
         opcode_w    <= unpack(the_beat[3][7:2]);
      end

      // beyond the header, we just need to count down the number
      // of bytes to locate the end of the message
      if (header_pos == 4) begin
         if (remaining <= fromInteger(bytes_per_beat))
            new_remaining.wset(0);
         else
            new_remaining.wset(remaining - fromInteger(bytes_per_beat));
      end
   endrule

   // Set the last_beat_pw from a rule, to avoid conflicts if
   // the user calls advance and last_beat methods inside a single
   // rule, and to provide last_beat notification independently from
   // the advance method call.
   (* fire_when_enabled, no_implicit_conditions *)
   rule detect_last_beat if (new_remaining.wget() == tagged Valid 0);
      last_beat_pw.send();
   endrule

   // interface definition

   // provide the next beat
   method Action beat(MsgBeat#(bpb) v);
      the_beat <= unpack(pack(v));
   endmethod

   // Commit the state updates from the current beat.
   // This is written without an implicit condition so that
   // it can be combined in rules without aggressive conditions.
   method Action advance();
      if (new_remaining.wget() matches tagged Valid ._remaining)
         remaining <= _remaining;
      if (last_beat_pw)
         header_pos <= 0;
      else if (header_pos != 4) begin
         if (bytes_per_beat < 4)
            header_pos <= header_pos + fromInteger(bytes_per_beat);
         else
            header_pos <= 4;
      end
   endmethod

   // read the routing information from the beat
   method NodeID   dst       = dst_w;
   method NodeID   src       = src_w;
   method UInt#(8) length    = len_w;
   method Bool     dont_wait = dont_wait_w;
   method Bit#(6)  opcode    = opcode_w;

   // message framing signals
   method Bool first_beat = first_beat_pw;
   method Bool last_beat  = last_beat_pw;

   method UInt#(9) remaining_bytes = remaining;

   // discard current message status
   method Action clear();
      header_pos <= 0;
      remaining  <= 0;
   endmethod

endmodule: mkMsgRoute

// This is a miminal utility for generating a stream of beats that
// conforms to the required message format.

interface MsgBuild#(numeric type bpb);

   // provide message information
   method Action dst(NodeID node);
   method Action src(NodeID node);
   method Action length(UInt#(8) l);
   method Action dont_wait(Bool dw);
   method Action opcode(Bit#(6) op);
   interface Put#(Tuple2#(Vector#(bpb,Bool),Vector#(bpb,Bit#(8)))) payload;

   // the MsgSource gives a stream of beats
   interface MsgSource#(bpb) source;

   // message framing signals for convenience
   method Bool start_of_message();
   method Bool end_of_message();

   // convenience signal for the builder
   method UInt#(8) remaining_bytes();

   // discard current message status
   (* always_ready *)
   method Action clear();

endinterface

module mkMsgBuild(MsgBuild#(bpb))
   provisos ( Add#(_v1, TLog#(TAdd#(1,bpb)), 8)
            , Add#(1, _v2, TLog#(TAdd#(1,bpb)))
            // The compiler should be able to figure these out
            , Add#(TAdd#(bpb,bpb), _v6, TMul#(4,bpb))
            , Add#(TMul#(4,bpb), _v3, TMul#(TDiv#(TMul#(TMul#(4,bpb),9),36),4))
            , Log#(TAdd#(1,bpb), TLog#(TAdd#(bpb,1)))
            , Add#(1, _v4, TDiv#(bpb,4))
            , Add#(bpb, _v5, TMul#(4,bpb))
            , Add#(_v1, TLog#(TAdd#(bpb,1)), 8)
            , Add#(1, _v2, TLog#(TAdd#(bpb,1)))
            );

   Integer bytes_per_beat = valueOf(bpb);

   check_bytes_per_beat("mkMsgBuild", bytes_per_beat);

   FifoMsgSource#(bpb) beat_fifo    <- mkFifoMsgSource();
   FIFOF#(NodeID)      new_dst      <- mkPipelineFIFOF();
   FIFOF#(NodeID)      new_src      <- mkPipelineFIFOF();
   FIFOF#(UInt#(8))    new_len      <- mkPipelineFIFOF();
   FIFOF#(Bool)        new_dw       <- mkPipelineFIFOF();
   FIFOF#(Bit#(6))     new_op       <- mkPipelineFIFOF();
   Reg#(UInt#(3))      bytes_used   <- mkReg(0);
   Reg#(UInt#(8))      bytes_left   <- mkReg(0);
   Reg#(UInt#(8))      padding      <- mkReg(0);
   Reg#(UInt#(9))      bytes_taken  <- mkReg(0);
   Reg#(UInt#(9))      total_bytes  <- mkReg(0);
   PulseWire           som          <- mkPulseWire();
   PulseWire           eom          <- mkPulseWire();
   PulseWire           dst_rdy_pw   <- mkPulseWire();

   ByteCompactor#(bpb,bpb,TMul#(4,bpb)) beat_data <- mkByteCompactor();

   if (bytes_per_beat == 1) begin
      rule do_dst if (bytes_used == 0);
         NodeID dst = new_dst.first();
         new_dst.deq();
         Vector#(bpb,Maybe#(Bit#(8))) vin;
         vin[0] = tagged Valid pack(dst);
         beat_data.enq(vin);
         bytes_used <= 1;
      endrule

      rule do_src if (bytes_used == 1);
         NodeID src = new_src.first();
         new_src.deq();
         Vector#(bpb,Maybe#(Bit#(8))) vin;
         vin[0] = tagged Valid pack(src);
         beat_data.enq(vin);
         bytes_used <= 2;
      endrule

      rule do_len if (bytes_used == 2);
         UInt#(8) len = new_len.first();
         new_len.deq();
         Vector#(bpb,Maybe#(Bit#(8))) vin;
         vin[0] = tagged Valid pack(len);
         beat_data.enq(vin);
         bytes_used   <= 3;
         bytes_left   <= len;
         padding      <= 0;
      endrule

      rule do_dw_and_op if (bytes_used == 3);
         Bool dw = new_dw.first();
         new_dw.deq();
         Bit#(6) op = new_op.first();
         new_op.deq();
         Vector#(bpb,Maybe#(Bit#(8))) vin;
         vin[0] = tagged Valid pack({op,1'b0,pack(dw)});
         beat_data.enq(vin);
         if (bytes_left == 0)
            bytes_used <= 0;
         else
            bytes_used <= 4;
      endrule
   end
   else if (bytes_per_beat == 2) begin
      rule do_dst_and_src if (bytes_used == 0);
         NodeID dst = new_dst.first();
         new_dst.deq();
         NodeID src = new_src.first();
         new_src.deq();
         Vector#(bpb,Maybe#(Bit#(8))) vin;
         vin[0] = tagged Valid pack(dst);
         vin[1] = tagged Valid pack(src);
         beat_data.enq(vin);
         bytes_used <= 2;
      endrule

      rule do_len_and_dw_and_op if (bytes_used == 2);
         UInt#(8) len = new_len.first();
         new_len.deq();
         Bool dw = new_dw.first();
         new_dw.deq();
         Bit#(6) op = new_op.first();
         new_op.deq();
         Vector#(bpb,Maybe#(Bit#(8))) vin;
         vin[0] = tagged Valid pack(len);
         vin[1] = tagged Valid pack({op,1'b0,pack(dw)});
         beat_data.enq(vin);
         bytes_left <= len;
         padding    <= truncate(len % 2);
         if (len == 0)
            bytes_used <= 0;
         else
            bytes_used <= 4;
      endrule
   end
   else begin
      rule do_whole_header if (bytes_used == 0);
         NodeID dst = new_dst.first();
         new_dst.deq();
         NodeID src = new_src.first();
         new_src.deq();
         UInt#(8) len = new_len.first();
         new_len.deq();
         Bool dw = new_dw.first();
         new_dw.deq();
         Bit#(6) op = new_op.first();
         new_op.deq();
         Vector#(bpb,Maybe#(Bit#(8))) vin = replicate(tagged Invalid);
         vin[0] = tagged Valid pack(dst);
         vin[1] = tagged Valid pack(src);
         vin[2] = tagged Valid pack(len);
         vin[3] = tagged Valid pack({op,1'b0,pack(dw)});
         beat_data.enq(vin);
         bytes_left <= len;
         UInt#(8) bytes_in_last_beat = truncate((9'd4 + zeroExtend(len)) % fromInteger(bytes_per_beat));
         padding    <= (bytes_in_last_beat == 0) ? 0 : (fromInteger(bytes_per_beat) - bytes_in_last_beat);
         if (len == 0 && bytes_in_last_beat == 0)
            bytes_used <= 0;
         else
            bytes_used <= 4;
      endrule
   end

   rule pad_final_beat if (bytes_used == 4 && bytes_left == 0 && padding != 0);
      Vector#(bpb,Maybe#(Bit#(8))) vin;
      for (Integer i = 0; i < bytes_per_beat; i = i + 1) begin
         if (fromInteger(i) < padding)
            vin[i] = tagged Valid 0;
         else
            vin[i] = tagged Invalid;
      end
      beat_data.enq(vin);
      padding    <= 0;
      bytes_used <= 0;
   endrule

   (* fire_when_enabled *)
   rule beat_is_ready if (beat_data.bytes_available() >= fromInteger(bytes_per_beat));
      beat_fifo.enq(pack(map(validValue,beat_data.first())));
      beat_data.deq(fromInteger(bytes_per_beat));
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule track_beats;
      // signal start of message
      if (bytes_taken == 0) som.send();
      // get the message length
      Bool     new_msg_len = False;
      UInt#(9) msg_len = total_bytes;
      if (bytes_per_beat < 4) begin
         if ((bytes_taken == 2) && beat_fifo.source.src_rdy()) begin
            msg_len = 4 + zeroExtend(unpack(beat_fifo.source.beat()[7:0]));
            new_msg_len = True;
         end
      end
      else begin
         if ((bytes_taken == 0) && beat_fifo.source.src_rdy()) begin
            msg_len = 4 + zeroExtend(unpack(beat_fifo.source.beat()[23:16]));
            new_msg_len = True;
         end
      end
      // determine if this the last beat in the message
      Bool is_eom = (msg_len != 0) && ((bytes_taken + fromInteger(bytes_per_beat)) >= msg_len);
      // signal end of message
      if (is_eom) eom.send();
      // track the progress as beats are transferred
      if (dst_rdy_pw && beat_fifo.source.src_rdy()) begin
         if (is_eom) begin
            bytes_taken <= 0;
            total_bytes <= 0;
         end
         else begin
            bytes_taken <= bytes_taken + fromInteger(bytes_per_beat);
            if (new_msg_len)
               total_bytes <= msg_len;
         end
      end
   endrule

   method Action dst(NodeID node);
      new_dst.enq(node);
   endmethod

   method Action src(NodeID node);
      new_src.enq(node);
   endmethod

   method Action length(UInt#(8) l);
      new_len.enq(l);
   endmethod

   method Action dont_wait(Bool dw);
      new_dw.enq(dw);
   endmethod

   method Action opcode(Bit#(6) op);
      new_op.enq(op);
   endmethod

   interface Put payload;
      method Action put(Tuple2#(Vector#(bpb,Bool),Vector#(bpb,Bit#(8))) mbytes) if (bytes_used == 4 && bytes_left > 0);
         Vector#(bpb,Maybe#(Bit#(8))) vin;
         Vector#(bpb,Bool)    mask = tpl_1(mbytes);
         Vector#(bpb,Bit#(8)) vals = tpl_2(mbytes);
         for (Integer i = 0; i < bytes_per_beat; i = i + 1) begin
            if (mask[i])
               vin[i] = tagged Valid vals[i];
            else
               vin[i] = tagged Invalid;
         end
         UInt#(8) nbytes = zeroExtend(countOnes(pack(mask)));
         if (nbytes >= bytes_left) begin
            bytes_left <= 0;
            if (padding == 0)
               bytes_used <= 0;
         end
         else
            bytes_left <= bytes_left - nbytes;
         beat_data.enq(vin);
      endmethod
   endinterface

   interface MsgSource source;
      method src_rdy = beat_fifo.source.src_rdy;
      method Action dst_rdy(Bool b);
         beat_fifo.source.dst_rdy(b);
         if (b) dst_rdy_pw.send();
      endmethod
      method beat = beat_fifo.source.beat;
   endinterface

   method Bool start_of_message();
      return som && beat_fifo.source.src_rdy();
   endmethod

   method Bool end_of_message();
      return eom && beat_fifo.source.src_rdy();
   endmethod

   method UInt#(8) remaining_bytes();
      return bytes_left;
   endmethod

   // discard current message status
   method Action clear();
      beat_fifo.clear();
      new_dst.clear();
      new_src.clear();
      new_len.clear();
      new_dw.clear();
      new_op.clear();
      bytes_used   <= 0;
      bytes_left   <= 0;
      padding      <= 0;
      bytes_taken  <= 0;
      total_bytes  <= 0;
      beat_data.clear();
   endmethod

endmodule
