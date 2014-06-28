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

// This module interfaces to the SMA cables on the
// XUPV5. However only certain of the generated verilog and ucf files
// are needed to characterize this interface, and it can be used a model 
// for high-speed board to board serial on other development boards. The 
// device interface consists of a simple FIFO with guaranteed transport to
// the other device. This module is slightly complicated by the need to 
// instantiate dummy serial modules to route clock to the SMA GTP.

import XilinxCells::*;

// we provide our own OBUF for now.
`include "awb/provides/fpga_components.bsh"

typedef struct {

    Integer pll_divsel45_fb;
    Integer clk25_divider;
    Integer use_chipscope;
    Clock   clock;

} AuroraGTXClockSpec deriving (Eq);

interface AURORA_WIRES;

    method Action rxp_in(Bit#(1) i);

    method Action rxn_in(Bit#(1) i);

    method Bit#(1) txp_out();

    method Bit#(1) txn_out();

endinterface

module mkAuroraIOBUF#(AURORA_WIRES wiresIn) (AURORA_WIRES);

    Wire#(Bit#(1)) buffRXN <- mkIBUF();
    Wire#(Bit#(1)) buffRXP <- mkIBUF();

    Wire#(Bit#(1)) buffTXN <- mkOBUF();
    Wire#(Bit#(1)) buffTXP <- mkOBUF();
 
    rule transferRXN;
        wiresIn.rxn_in(buffRXN);
    endrule

    rule transferRXP;
        wiresIn.rxp_in(buffRXP);
    endrule

    rule transferTXN;
        buffTXN._write(wiresIn.txn_out);
    endrule

    rule transferTXP;
        buffTXP._write(wiresIn.txp_out);
    endrule

    method rxn_in = buffRXN._write;
    method rxp_in = buffRXP._write;

    method txn_out = buffTXN._read;
    method txp_out = buffTXP._read;

endmodule

