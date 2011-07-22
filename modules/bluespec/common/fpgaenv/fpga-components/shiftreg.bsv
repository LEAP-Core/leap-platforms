`include "asim/provides/librl_bsv_base.bsh"

import Vector::*;

interface SHIFT_REG#(type data_t);
  method Action write(data_t data);
  method data_t read();
endinterface

import "BVI" shiftreg = module mkUnguardedShiftRegOne#(NumTypeParam#(length) len)
    // interface:
    (SHIFT_REG#(Bit#(1)));

    parameter LENGTH = valueOf(length);

    method readData read();
    method write(writeData) enable(writeEnable);

    schedule write C write;
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


