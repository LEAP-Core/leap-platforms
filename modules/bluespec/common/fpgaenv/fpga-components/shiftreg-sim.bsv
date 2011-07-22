`include "asim/provides/librl_bsv_base.bsh"

import Vector::*;

interface SHIFT_REG#(type data_t);
  method Action write(data_t data);
  method data_t read();
endinterface

module mkUnguardedShiftRegOne#(NumTypeParam#(length) len)
    // interface:
    (SHIFT_REG#(Bit#(1)));
//    provisos(Add#(1,length_extra,length));

    Reg#(Bit#(length)) shiftreg <- mkReg(0); 

    method Bit#(1) read();
      return truncateLSB({shiftreg,1'b0});
    endmethod

    method Action write(Bit#(1) writeData);
      shiftreg <= truncate({shiftreg,writeData});
    endmethod
endmodule

module mkUnguardedShiftReg#(NumTypeParam#(length) len) (SHIFT_REG#(data_t))
  provisos(Bits#(data_t, data_SZ));

  Vector#(data_SZ, SHIFT_REG#(Bit#(1))) regs <- replicateM(mkUnguardedShiftRegOne(len));

  function Action doWrite(SHIFT_REG#(Bit#(1)) shiftreg, Bit#(1) data);
    action
      shiftreg.write(data);
    endaction
  endfunction

  function Bit#(1) doRead(SHIFT_REG#(Bit#(1)) shiftreg);
    return shiftreg.read;
  endfunction

  method Action write(data_t data);
    Bit#(data_SZ) dataBits = pack(data);
    joinActions(zipWith(doWrite,regs,unpack(dataBits)));
  endmethod

  method data_t read();
    return unpack(pack(map(doRead,regs))); 
  endmethod
endmodule

