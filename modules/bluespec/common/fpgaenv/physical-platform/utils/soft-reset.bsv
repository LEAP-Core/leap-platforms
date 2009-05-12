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
