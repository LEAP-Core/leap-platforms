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

// Primitive Differential Clock: Drive the differential signals into
// a buffer and get an output single-ended clock. Reset can be passed-thru
// or be driven through a buffer.

import Clocks::*;

interface PRIMITIVE_CLOCKS_DEVICE;

    // Wires to be sent to the top level

    method Action clock_p_wire();
    method Action clock_n_wire();
    method Action reset_n_wire();
    
    // Drivers exposed to the model
        
    interface Clock clock;
    interface Reset reset;
        
endinterface

import "BVI" differential_clocks_device = module mkPrimitiveClocksDevice
    // interface:
                 (PRIMITIVE_CLOCKS_DEVICE);

    default_clock no_clock;
    default_reset no_reset;
  
    output_clock clock(clk_out);
    output_reset reset(rst_n_out) clocked_by(clock);
  
    method clock_p_wire() enable(clk_p);
    method clock_n_wire() enable(clk_n);
    method reset_n_wire() enable(rst_n);

    schedule (clock_p_wire, clock_n_wire, reset_n_wire) CF (clock_p_wire, clock_n_wire, reset_n_wire);
        
endmodule
