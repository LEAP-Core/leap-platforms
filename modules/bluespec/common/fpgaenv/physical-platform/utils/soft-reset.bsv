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

// Soft Reset Utilities

// Provides logic for triggering a soft reset when requested

import Clocks::*;

// SOFT_RESET_TRIGGER

// triggers a soft reset

interface SOFT_RESET_TRIGGER;
    method Action reset();
endinterface


// mkSoftResetTrigger

module mkSoftResetTrigger#(MakeResetIfc softReset)
    // interface:
    (SOFT_RESET_TRIGGER);
    
    // Timer to hold reset
    Reg#(Bool)    doReset      <- mkReg(False);
    Reg#(Bit#(8)) resetCounter <- mkReg(0);
    
    // Hold reset for 128 cycles.  May be overkill but seems safer than 1.
    rule pullReset (doReset);
        // trigger!
        softReset.assertReset();
        
        resetCounter <= resetCounter + 1;
        if (resetCounter[7] == 1)
            doReset <= False;
    endrule
    
    // method called to trigger reset
    method Action reset() if (! doReset);
        // trigger the soft reset
        doReset <= True;
        resetCounter <= 0;
    endmethod
endmodule
