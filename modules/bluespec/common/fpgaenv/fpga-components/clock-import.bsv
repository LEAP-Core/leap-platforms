//
// Copyright (C) 2010 MIT
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
