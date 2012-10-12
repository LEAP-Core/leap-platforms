// This is a FIFO-like utility that allows a variable number of bytes
// to be enqueued at once and a variable number to be dequeued.

// The input bytes don't need to be compact, but the output
// bytes will be compact.

// This implementation is functionally correct and meets timing.  It
// is capable of sustained throughput of about 4 bytes every 2 cycles.
// Attempts to improve the latency/throughput any more cause the area
// to inflate a bit too much for comfort. The evaluator also has some
// performance issues with the conditionals inside loops over vectors
// if you push it too far.

import Vector :: *;

interface ByteCompactor#( numeric type width_in
                        , numeric type width_out
                        , numeric type buf_sz
                        );

   // Is it allowed to add bytes to the buffer?
   (* always_ready *)
   method Bool can_enq();

   // Add bytes to the buffer
   method Action enq(Vector#(width_in,Maybe#(Bit#(8))) data);

   // The bytes available to take from the buffer
   (* always_ready *)
   method Vector#(width_out,Maybe#(Bit#(8))) first();

   // The number of bytes available to deq
   (* always_ready *)
   method UInt#(TLog#(TAdd#(width_out,1))) bytes_available();

   // Retire up to width_out bytes from the buffer
   (* always_ready *)
   method Action deq(UInt#(TLog#(TAdd#(width_out,1))) count);

endinterface: ByteCompactor

module mkByteCompactor(ByteCompactor#(width_in,width_out,buf_sz))
   provisos( Log#(TAdd#(width_out,1),count_out)
           , Add#(width_in,width_out,smallest_buf_sz)
           , Add#(smallest_buf_sz,excess,buf_sz)
           // why can't the compiler figure this out?!?
           , Add#(width_out, _v0, buf_sz)
           , Add#(width_in,  _v1, buf_sz)
           , Add#(buf_sz, _v2, TMul#(TDiv#(TMul#(buf_sz,9),36),4))
           , Log#(TAdd#(1,width_out),count_out)
           , Add#(1,_v3,TDiv#(width_out,4))
           );

   // This is the byte buffer
   Reg#(Vector#(buf_sz,Maybe#(Bit#(8)))) vec <- mkReg(replicate(tagged Invalid));

   // It is divided into width_in bytes at the high end for adding bytes
   // and width_out bytes at the low end for removing bytes, with some
   // optional bytes in between
   Vector#(width_in,Maybe#(Bit#(8)))  input_area  = drop(vec);
   Vector#(width_out,Maybe#(Bit#(8))) output_area = take(vec);

   // the user can add and remove bytes
   RWire#(Vector#(width_in,Maybe#(Bit#(8)))) new_data <- mkRWire();
   Wire#(UInt#(count_out))                   removed  <- mkDWire(0);

   // bubble data down using a stage of neighbor transpositions
   function Vector#(n,Maybe#(t)) bubble(Vector#(n,Maybe#(t)) vin, Integer start);
      Vector#(n,Maybe#(t)) vout = ?;
      vout[0] = vin[0];
      vout[valueOf(n)-1] = vin[valueOf(n)-1];
      for (Integer i = start; i < valueOf(n)-1; i = i + 2) begin
         if (!isValid(vin[i]) && isValid(vin[i+1])) begin
            // swap
            vout[i]   = vin[i+1];
            vout[i+1] = vin[i];
         end
         else begin
            // don't swap
            vout[i]   = vin[i];
            vout[i+1] = vin[i+1];
         end
      end // for
      return vout;
   endfunction

   // on each cycle:
   //   1. shift bytes down into empty spaces
   //   2. remove bytes taken by the user from the bottom of the
   //      output area
   //   3. add any user data in the input area
   (* fire_when_enabled, no_implicit_conditions *)
   rule update_vec;
      Vector#(buf_sz,Maybe#(Bit#(8))) vec0 = vec;

      // shift bytes down into empty spaces
      Vector#(buf_sz,Maybe#(Bit#(8))) vec1a = bubble(vec0,0);
      Vector#(buf_sz,Maybe#(Bit#(8))) vec1b = bubble(vec1a,1);
      Vector#(buf_sz,Maybe#(Bit#(8))) vec1c = bubble(vec1b,0);
      Vector#(buf_sz,Maybe#(Bit#(8))) vec1d = bubble(vec1c,1);
      Vector#(buf_sz,Maybe#(Bit#(8))) vec1e = bubble(vec1d,0);
      Vector#(buf_sz,Maybe#(Bit#(8))) vec1f = bubble(vec1e,1);

      Vector#(buf_sz,Maybe#(Bit#(8))) vec2a = vec1f;

      // invalidate bytes taken by the user
      for (Integer i = 0; i < valueOf(width_out); i = i + 1) begin
         if (fromInteger(i) < removed)
            vec2a[i] = tagged Invalid;
      end

      // add new bytes from the user
      for (Integer i = 0; i < valueOf(width_in); i = i + 1) begin
         Integer idx = valueOf(buf_sz) - valueOf(width_in) + i;
         if (new_data.wget() matches tagged Valid .vin)
            vec2a[idx] = vin[i];
      end

      // do another round of shifting
      Vector#(buf_sz,Maybe#(Bit#(8))) vec2b = bubble(vec2a,0);
      Vector#(buf_sz,Maybe#(Bit#(8))) vec2c = bubble(vec2b,1);

      Vector#(buf_sz,Maybe#(Bit#(8))) vec3 = vec2c;

/*
      $write("%0t: vec =", $time());
      for (Integer i = 0; i < valueOf(buf_sz); i = i + 1) begin
         if (isValid(vec3[i])) $write(" %x", validValue(vec3[i]));
         else                  $write(" ??");
      end
      $display();
*/

      // write the modified contents back into the buffer
      vec <= vec3;

   endrule

   Bool input_area_is_clear = !any(isValid,input_area);

   method Bool can_enq = input_area_is_clear;

   method Action enq(Vector#(width_in,Maybe#(Bit#(8))) data) if (input_area_is_clear);
      new_data.wset(data);
   endmethod

   method first = output_area;

   method bytes_available = countZerosLSB(~pack(map(isValid,output_area)));

   method Action deq(UInt#(count_out) count);
      removed <= count;
   endmethod

endmodule: mkByteCompactor
