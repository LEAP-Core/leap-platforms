/**
 *
 * Copyright (c) 2006-2008 The University of Texas All Rights Reserved.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 * 
 * The GNU Public License is available in the file LICENSE, or you can
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA, or you can find it on the World Wide Web at
 * http://www.fsf.org.
 * 
 * Authors: Eric Johnson
 * 
 * The authors are with the Department of Electrical and Computer Engineering,
 * The University of Texas at Austin, Austin, TX 78712 USA.
 * 
 * They can be reached at: dejohnso@ece.utexas.edu
 * 
 * More information about related work can be found at
 * http://users.ece.utexas.edu/~derek/FAST.html
 * 
 **/

import RegFile::*;
import RegFileCF::*;

interface FAST_BRAM#(type data_t, type index_t);
   method Action write(index_t a, data_t d);
   method Action read(index_t a);
   method data_t readval();
   method Action write2(index_t a, data_t d);
   method Action read2(index_t a);
   method data_t readval2();
   method Bool   init_p();
endinterface: FAST_BRAM

module mkFAST_BRAMU_sim#(Integer depth)
        (FAST_BRAM#(data_t, index_t))
            provisos (Bits#(index_t, bits_index_t),
                      Bits#(data_t, bits_data_t));

    RegFile#(index_t, data_t) mem <- mkRegFileCF(depth);
    Reg#(data_t) data  <- mkReg(?);
    Reg#(data_t) data2 <- mkReg(?);

    // These wires are used to force a conflict between write & read, and
    // write2 & read2. In addition, they can be used for asserting that write
    // and write2 don't happen in the same cycle. Even if you remove the rule,
    // please don't remove the wires.
    Wire#(Maybe#(index_t)) conflict  <- mkWire;
    Wire#(Maybe#(index_t)) conflict2 <- mkWire;

    rule check_conflict (isValid(conflict) && pack(conflict) == pack(conflict2));
        $display("Error: FAST_BRAM: write & write2 must write to different addresses.");
    endrule

    method Action write(index_t a, data_t d);
        mem.upd(a,d);
        data <= mem.sub(a);
        conflict <= Valid(a);
    endmethod
    method Action read(index_t a);
        data <= mem.sub(a);
        conflict <= Invalid;
    endmethod
    method data_t readval() = data;

    method Action write2(index_t a, data_t d);
        mem.upd(a,d);
        data2 <= mem.sub(a);
        conflict2 <= Valid(a);
    endmethod
    method Action read2(index_t a);
        data2 <= mem.sub(a);
        conflict2 <= Invalid;
    endmethod
    method data_t readval2() = data2;

    method Bool init_p = True;
endmodule

import "BVI" FAST_BRAM =
module mkFAST_BRAMU_verilog#(Integer depth)
        (FAST_BRAM#(data_t, index_t))
           provisos(Bits#(index_t, bits_index_t),
                    Bits#(data_t, bits_data_t));
   
   parameter DATA_WIDTH = valueOf(bits_data_t);
   parameter ADDR_WIDTH = valueOf(bits_index_t);
   parameter DEPTH = depth;
   
   //        R1  W1  Rv1   R2  W2  Rv2   INI
   //      -------------  ------------  -----
   // R1  |  C
   // W1  |  C   C
   // Rv1 |  SB  SB  CF
   //
   // R2  |  CF  CF* CF    C
   // W2  |  CF* CF* CF    C   C
   // Rv2 |  CF  CF  CF    SB  SB  CF
   //
   // INI |  CF  CF  CF    CF  CF  CF    CF
   //
   // * = assuming addresses are not equal

   default_clock (CLK);

   schedule (readval,readval2) CF (readval,readval2);
   schedule readval SB (read,write);
   schedule readval2 SB (read2,write2);
   schedule (read,write,readval) CF (read2,write2,readval2);
   schedule (read) C (write);
   schedule (read2) C (write2);
   schedule (read) C (read);
   schedule (read2) C (read2);
   schedule (write) C (write);
   schedule (write2) C (write2);
   schedule init_p CF (read,write,readval,read2,write2,readval2,init_p);
   
   method write (WR_ADDRA, DIA) enable(WEA);
   method write2 (WR_ADDRB, DIB) enable(WEB);
   method read (RD_ADDRA) enable(REA);
   method read2 (RD_ADDRB) enable(REB);
   method DOA readval;
   method DOB readval2;

   method INIT init_p; // must be 1
   
endmodule: mkFAST_BRAMU_verilog

module mkFAST_BRAMU_w0
        (FAST_BRAM#(data_t, index_t));

   method Action write(index_t a, data_t d) = noAction;
   method Action read(index_t a) = noAction;
   method data_t readval() = ?;

   method Action write2(index_t a, data_t d) = noAction;
   method Action read2(index_t a) = noAction;
   method data_t readval2() = ?;

   method Bool init_p() = True;
endmodule

// A two-write-ported blockram with depth one does not make much sense. Since
// the address must always be zero, the two ports always conflict on the
// address.
module mkFAST_BRAMU_d1
        (FAST_BRAM#(data_t, index_t))
            provisos (Bits#(data_t, width));

   Reg#(data_t) mem <- mkRegU;

   method Action write(index_t a, data_t d);
       mem <= d;
   endmethod
   method Action read(index_t a) = noAction;
   method data_t readval() = mem;

   method Action write2(index_t a, data_t d);
       mem <= d;
   endmethod
   method Action read2(index_t a) = noAction;
   method data_t readval2() = mem;

   method Bool init_p() = True;
endmodule

module mkFAST_BRAMU#(Integer depth)
        (FAST_BRAM#(data_t, index_t))
            provisos (Bits#(data_t, width_t),
                      Bits#(index_t, si));

    if (depth == 0)
        error("cannot instantiate FAST_BRAM of depth 0");

    Integer width = valueof(width_t);

    FAST_BRAM#(data_t, index_t) _x;

    if (width == 0)
        _x <- mkFAST_BRAMU_w0;
    else if (depth == 1)
        _x <- mkFAST_BRAMU_d1;
    else if (genVerilog)
        _x <- mkFAST_BRAMU_verilog(depth);
    else
        _x <- mkFAST_BRAMU_sim(depth);
    return _x;

endmodule

module mkFAST_BRAM#(Integer depth, data_t init_val)
        (FAST_BRAM#(data_t, index_t))
           provisos (Bits#(data_t, bits_data_t),
                     Bits#(index_t, bits_index_t));

   Reg#(Bool) init <- mkReg(False);
   Reg#(Bit#(bits_index_t)) init_index <- mkReg(unpack(0));
   
   FAST_BRAM#(data_t, index_t) _x <- mkFAST_BRAMU (depth);

   rule do_init (!init);
      _x.write(unpack(init_index), init_val);
      if (init_index == fromInteger(depth - 1))
         init <= True;
      init_index <= init_index+1;
   endrule: do_init

   method Action write(index_t a, data_t d) if (init) = _x.write(a,d);
   method Action read(index_t a) if (init) = _x.read(a);
   method data_t readval() if (init) = _x.readval();
   method Action write2(index_t a, data_t d) if (init) = _x.write2(a,d);
   method Action read2(index_t a) if (init) = _x.read2(a);
   method data_t readval2() if (init) = _x.readval2();
   method Bool init_p() = init;

endmodule: mkFAST_BRAM

module mkFAST_BRAMFull#(data_t init_val)
        (FAST_BRAM#(data_t, index_t))
           provisos (Bits#(data_t, bits_data_t),
                     Bits#(index_t, bits_index_t));

    Integer depth = valueof(TExp#(bits_index_t));
    let _x <- mkFAST_BRAM(depth, init_val);
    return _x;

endmodule
