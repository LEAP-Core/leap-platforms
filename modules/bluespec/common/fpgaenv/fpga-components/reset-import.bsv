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

interface RESET_IMPORTER;
 
    method Action reset_wire();
        
    interface Reset reset;
endinterface

import "BVI" reset_import = module mkResetImporter
    // interface:
                 (RESET_IMPORTER);

//    default_clock no_clock;
    default_reset no_reset;
  
//    input_clock clock(clk_in) = inputClock;

    output_reset reset(reset_out);

    method reset_wire() enable(reset_in) clocked_by(no_clock);

    schedule reset_wire CF reset_wire;

endmodule
