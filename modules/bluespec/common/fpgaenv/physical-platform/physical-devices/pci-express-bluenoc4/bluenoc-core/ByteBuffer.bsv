import Vector :: *;

interface ByteBuffer#(numeric type n);

   interface Vector#(n,Reg#(Bit#(8))) bytes;

   method Vector#(n,Bool) valid_mask();

   method Action clear();

endinterface

module mkByteBuffer(ByteBuffer#(n));

   Integer num_bytes    = valueOf(n);

   Vector#(n,Reg#(Bit#(8))) values <- replicateM(mkRegU);
   Vector#(n,Reg#(Bool))    valids <- replicateM(mkReg(False));

   PulseWire                  clear_called <- mkPulseWire();
   Vector#(n,RWire#(Bit#(8))) new_value    <- replicateM(mkRWire);

   function Reg#(Bit#(8)) redirect_write(Integer i);
      return (interface Reg;
                 method Action _write(Bit#(8) b);
                    new_value[i].wset(b);
                 endmethod
                 method Bit#(8) _read();
                    return values[i];
                 endmethod
              endinterface);
   endfunction

   (* fire_when_enabled, no_implicit_conditions *)
   rule update_vec;
      for (Integer i = 0; i < num_bytes; i = i + 1) begin
         if (new_value[i].wget() matches tagged Valid .b) begin
            values[i] <= b;
            valids[i] <= True;
         end
         else if (clear_called)
            valids[i] <= False;
      end
   endrule

   interface bytes = genWith(redirect_write);

   method valid_mask = readVReg(valids);

   method Action clear();
      clear_called.send();
   endmethod

endmodule: mkByteBuffer
