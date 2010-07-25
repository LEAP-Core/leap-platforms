/*****************************************************************************
 * arbiters.bsv
 *
 * Copyright (C) 2008 Intel Corporation
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import Vector::*;
import FIFO::*;

// Arbiters

// An arbiter takes a bit-vector of n Requests and returns a bit-vector
// of n Grant signals.

// interface
interface ARBITER#(numeric type bits_T);

    // arbitrate
    method Maybe#(UInt#(TLog#(bits_T))) arbitrate(Bit#(bits_T) request);

endinterface

// === static priority arbiter ===

module mkStaticArbiter
    // interface:
        (ARBITER#(bits_T))
    provisos (Log#(bits_T, TLog#(bits_T)));
    
    method Maybe#(UInt#(TLog#(bits_T))) arbitrate(Bit#(bits_T) request);
        
        Vector#(bits_T, Bit#(1)) req_v = unpack(request);
        return findElem(1, req_v);

    endmethod
    
endmodule

// 
// Wrapper for RR arbiter - with size 1, we can simply build a static 
// arbiter.
//
module mkRoundRobinArbiter
    // interface:
    (ARBITER#(bits_T))
    provisos (Log#(bits_T, TLog#(bits_T)),
              Add#(1, a, bits_T));
    ARBITER#(bits_T) arbiter = ?;
    if(valueof(bits_T) < 2) 
      begin
        arbiter <- mkStaticArbiter();
      end
    else
      begin 
        arbiter <- mkRoundRobinArbiterMultiBit();
      end

    return arbiter;
endmodule

//
// Round-robin arbiter
//
module mkRoundRobinArbiterMultiBit
    // interface:
    (ARBITER#(bits_T))
    provisos (Log#(bits_T, TLog#(bits_T)),
              Add#(1, a, bits_T));

    Reg#(Bit#(bits_T)) curPrioMask <- mkReg(1);
    
    (* fire_when_enabled *)
    rule rotate_priority (True);
        // Rotate priority mask every cycle
        curPrioMask <= { curPrioMask[0], curPrioMask[valueOf(bits_T)-1 : 1] };
    endrule

    //
    // Choose the request closest to the right of the choice bit
    //
    method Maybe#(UInt#(TLog#(bits_T))) arbitrate(Bit#(bits_T) request);
        // prio_mask now has bits set only to the right of choice point
        let prio_mask = curPrioMask - 1;
        let r = prio_mask & request;

        // If no requests set to the right then use the whole request mask
        if (r == 0)
        begin
            r = request;
        end

        // Pick the highest bit set
        Maybe#(UInt#(TLog#(bits_T))) pick = tagged Invalid;
        for (Integer x = 0; x < valueOf(bits_T); x = x + 1)
        begin
            if (r[x] == 1)
            begin
                pick = tagged Valid fromInteger(x);
            end
        end

        return pick;
    endmethod
endmodule
