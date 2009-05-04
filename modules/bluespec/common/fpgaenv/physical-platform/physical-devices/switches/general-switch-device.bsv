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

// ******* general-switch-device *******

// A switch device generalized to any bit width

// *************************************

import Clocks::*;

// SWITCHES_DRIVER

// The interface the rest of the FPGA uses to read the switches

interface SWITCHES_DRIVER#(parameter numeric type n);

    method Bit#(n) getSwitches();

endinterface

// SWITCHES_WIRES

// This interface is not used by the rest of the FPGA.
// Rather this represents wires which are passed to the top level and tied
// to the physical switch pins by the UCF file.

interface SWITCHES_WIRES#(parameter numeric type n);

    (* prefix = "" *)
    method Action switches_wire((* port = "SWITCH" *) Bit#(n) sw);

endinterface


// SWITCHES_DEVICE

// By convention a Device is a combination of a Wires and a Driver.

interface SWITCHES_DEVICE#(parameter numeric type n);

    interface SWITCHES_DRIVER#(n) driver;
    interface SWITCHES_WIRES#(n)  wires;

endinterface


// mkSwitchesDevice

// A switch device generalized to any bit width.
// Uses a Wire to return the current value of the switches.

module mkSwitchesDevice
    // interface:
                 (SWITCHES_DEVICE#(number_switches_T));

    // Create a primitive device
    
    PRIMITIVE_SWITCHES_DEVICE#(number_switches_T) primSwitches <- mkPrimitiveSwitchesDevice();


    // The interface used by the rest of the FPGA
  
    interface SWITCHES_DRIVER driver;

        method getSwitches = primSwitches.getSwitches;
            
    endinterface

    // The wires which are tied to the switches by the UCF

    interface SWITCHES_WIRES wires;
        
        method switches_wire = primSwitches.switches_wire;
  
    endinterface
 
endmodule
