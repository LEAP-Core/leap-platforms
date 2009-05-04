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
    
    /* THIS CODE IS OBSOLETE. THE TRIGGER IS NOW A TRIVIAL
       METHOD THAT ASSERTS THE RESET INTERFACE'S TRIGGER
       METHOD. THE SOFT RESET IFC IS INSTANTIATED IN THE
       CLOCKS DEVICE CODE WITH THE 128-CYCLE RESET PERIOD.

    // Timer to hold reset
    Reg#(Bool)    do_reset      <- mkReg(False);
    Reg#(Bit#(8)) reset_counter <- mkReg(0);
    
    // Hold reset for 128 cycles.  May be overkill but seems safer than 1.
    rule pull_reset (do_reset);

        // trigger!
        softReset.assertReset();
        
        reset_counter <= reset_counter + 1;
        if (reset_counter[7] == 1)
            do_reset <= False;

    endrule
    */
    
    // method called to trigger reset
    method Action reset();
    
        softReset.assertReset();
        
        /* SEE COMMENT ABOVE
        // trigger the soft reset
        do_reset <= True;
        reset_counter <= 0;
        */    
    endmethod

endmodule
