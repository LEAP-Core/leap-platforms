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

//
// Two methods of importing reset.  Both accomplish the same thing, but
// use different interfaces.  The "put" version is newer and has the
// advantage of being always enabled, which eliminates the exposed
// ready wire at the top level.
//

interface RESET_FROM_PUT;
    // Incoming reset
    interface Put#(Bit#(1)) reset_wire;

    // Reset exposed to the model
    interface Reset reset;
endinterface

//
// mkResetFromPut --
//   Construct a reset using a put interface.  The interface also provides
//   a fictitious clock crossing, since that is typically needed to
//   convince Bluespec that the reset is in the domain of a generated
//   clock.
//
import "BVI" reset_import = module mkResetFromPut#(Clock dClock)
    // Interface:
    (RESET_FROM_PUT);

    default_reset no_reset;
    input_clock ddClock() = dClock;

    output_reset reset(reset_out) clocked_by(ddClock);

    interface Put reset_wire;
        method put(reset_in) enable((*inhigh*) en0);
    endinterface

    schedule reset_wire_put CF reset_wire_put;
endmodule



interface RESET_IMPORTER;
    method Action reset_wire();
        
    interface Reset reset;
endinterface

import "BVI" reset_import = module mkResetImporter
    // Interface:
    (RESET_IMPORTER);

    default_reset no_reset;

    output_reset reset(reset_out);

    method reset_wire() enable(reset_in) clocked_by(no_clock);

    schedule reset_wire CF reset_wire;
endmodule
