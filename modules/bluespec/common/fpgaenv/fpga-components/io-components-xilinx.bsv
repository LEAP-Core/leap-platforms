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

// This code is intended to provide thin wrappers around the I/O
// primitive required for the different vendors. 


import XilinxCells::*;


module mkDifferentialClock#(Clock clk_p, Clock clk_n)(Clock);
    let _m <- mkClockIBUFDS(defaultValue, clk_p, clk_n);
    return _m;
endmodule

module mkInputBuffer (Wire#(Bit#(n)));
    Wire#(Bit#(n)) _m <- mkIBUF(defaultValue);
    return _m;
endmodule 

module mkInputClockBuffer (Wire#(Bit#(n)));
    Wire#(Bit#(n)) _m <- mkIBUFG(defaultValue);
    return _m;
endmodule 

module mkClockBuffer (Clock);
    let clock <- exposeCurrentClock();
    let bufferedClock <- mkClockBUFG(clocked_by clock);
    return bufferedClock;
endmodule 

module mkInputResetBuffer (Reset);
    let reset <- exposeCurrentReset();
    let bufferedReset <- mkResetIBUF(defaultValue, reset_by reset);
    return bufferedReset;
endmodule 

module mkResetBuffer (Reset);
    let reset <- exposeCurrentReset();
    let bufferedReset <- mkResetBUFG(reset_by reset);
    return bufferedReset;
endmodule 





