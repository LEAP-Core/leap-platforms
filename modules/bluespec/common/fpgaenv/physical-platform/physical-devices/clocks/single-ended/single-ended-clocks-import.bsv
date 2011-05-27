//
// Copyright (C) 2008 Intel Corporation
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

interface PRIMITIVE_CLOCKS_DEVICE;

    // Wires to be sent to the top level

    method Action clock_wire();
    method Action reset_n_wire();

    // Drivers exposed to the model

    interface Clock clock;
    interface Reset reset;

endinterface

import "BVI" single_ended_clocks_device = module mkPrimitiveClocksDevice
    // interface:
                 (PRIMITIVE_CLOCKS_DEVICE);

    parameter RESET_ACTIVE_HIGH = `RESET_ACTIVE_HIGH;

    default_clock no_clock;
    default_reset no_reset;

    output_clock clock(clk_out);
    output_reset reset(rst_n_out) clocked_by(clock);

    method clock_wire() enable(clk);
    method reset_n_wire() enable(rst_n);

    schedule (clock_wire, reset_n_wire) CF (clock_wire, reset_n_wire);    

endmodule
