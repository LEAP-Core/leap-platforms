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

// Primitive Single-Ended Clock: Simply convert the top-level wires
// into a clock and reset signal

import Clocks::*;
import GetPut::*;

// ========================================================================
//
//   Clock imported using a Put interface.
//
//   The advantage of this method over mkClockImporter below is that it
//   cleanly imports a clock signal without exposing a ready wire.
//
//   The disadvantage of this method is the put() method must be
//   clocked in order for Bluespec to accept the always enabled condition.
//   This input clock is completely ignored, so "clocking" it with
//   any clock that is exposed at the top level is fine.
//
// ========================================================================

interface CLOCK_FROM_PUT;
    // Incoming clock
    interface Put#(Bit#(1)) clock_wire;

    // Clock exposed to the model
    interface Clock clock;
endinterface


import "BVI" clock_import = module mkClockFromPut
    // Interface:
    (CLOCK_FROM_PUT);

    default_reset no_reset;
  
    output_clock clock(clk_out);
  
    interface Put clock_wire;
        method put(clk_in) enable((*inhigh*) en0);
    endinterface

    schedule clock_wire_put CF clock_wire_put;
endmodule


// ========================================================================
//
//   Clock imported using the enable wire of clock_wire() method.
//
//   The disadvantage of this mechanism over mkClockFromPut is that
//   it exposes a ready wire all the way to the top level, because
//   without a default clock the clock_wire() method appears never
//   ready.
//
//   The advantage of this method over mkClockPut() is that it doesn't
//   need a pseudo-clock.
//
// ========================================================================

interface CLOCK_IMPORTER;
    // Wires to be sent to the top level
    method Action clock_wire();

    // Drivers exposed to the model
    interface Clock clock;
endinterface

import "BVI" clock_import = module mkClockImporter
    // Interface:
    (CLOCK_IMPORTER);

    default_clock no_clock;
    default_reset no_reset;
  
    output_clock clock(clk_out);
  
    method clock_wire() enable(clk_in);

    schedule clock_wire CF clock_wire;
endmodule
