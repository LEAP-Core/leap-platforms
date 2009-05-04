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

import Clocks::*;

interface PRIMITIVE_SWITCHES_DEVICE#(parameter numeric type n);

    // Wires to be sent to the top level

    method Action switches_wire(Bit#(n) sw);
    
    // Drivers exposed to the model
        
    method Bit#(n) getSwitches();
        
endinterface

import "BVI" switches_device = module mkPrimitiveSwitchesDevice
    // interface:
                 (PRIMITIVE_SWITCHES_DEVICE#(number_switches_T));

    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();                                   
                                       
    default_clock no_clock;
    default_reset no_reset;
                                       
    input_clock (clk)   = modelClock;
    input_reset (rst_n) = modelReset;                               

    method switches_wire(switches_in) enable((* inhigh *) EN);
                                           
    method switches_out getSwitches() clocked_by (modelClock) reset_by (modelReset);

    schedule (switches_wire, getSwitches) CF (switches_wire, getSwitches);    
        
    parameter SWITCHES_WIDTH = valueof(number_switches_T);
        
endmodule
