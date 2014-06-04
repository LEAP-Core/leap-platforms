//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

// Provides a BSV wrapper around the Xilinx OBUF component. 

// Notice that it is safe to include this code in software FPGA
// components, so long as it is not actually instantiated. 

import "BVI" IBUFDS =
module vMkClockIBUFDS_NP#(Clock clk_p, Clock clk_n)(ClockGenIfc);
   default_clock no_clock;
   default_reset no_reset;

   input_clock clk_p(I)  = clk_p;
   input_clock clk_n(IB) = clk_n;

   output_clock gen_clk(O);

//   parameter DIFF_TERM = "TRUE";

   path(I,  O);
   path(IB, O);

   same_family(clk_p, gen_clk);
endmodule: vMkClockIBUFDS_NP

module mkClockIBUFDS_NP#(Clock clk_p, Clock clk_n)(Clock);
   let _m <- vMkClockIBUFDS_NP(clk_p, clk_n);
   return _m.gen_clk;
endmodule: mkClockIBUFDS_NP


import "BVI" OBUF =
module vMkOBUF(Wire#(one_bit))
   provisos(Bits#(one_bit, 1));

   default_clock clk();
   default_reset rstn();

   method      _write(I) enable((*inhigh*)en);
   method O    _read;

   path(I, O);

   schedule _write SB _read;
   schedule _write C  _write;
   schedule _read  CF _read;
endmodule: vMkOBUF

module mkOBUF(Wire#(a))
   provisos(Bits#(a, sa));

   Vector#(sa, Wire#(Bit#(1))) _bufg <- replicateM(vMkOBUF);

   method a _read;
      return unpack(pack(readVReg(_bufg)));
   endmethod

   method Action _write(a x);
      writeVReg(_bufg, unpack(pack(x)));
   endmethod
endmodule: mkOBUF

