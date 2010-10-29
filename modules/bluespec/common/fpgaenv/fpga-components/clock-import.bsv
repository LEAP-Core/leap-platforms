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

interface CLOCK_IMPORTER;

    // Wires to be sent to the top level

    //(* always_ready *)

    method Action clock_wire();

    // Drivers exposed to the model
        
    interface Clock clock;
endinterface

import "BVI" clock_import = module mkClockImporter
    // interface:
                 (CLOCK_IMPORTER);

    default_clock no_clock;
    default_reset no_reset;
  
    output_clock clock(clk_out);
  
    method clock_wire() enable(clk_in);

    schedule clock_wire CF clock_wire;

endmodule
