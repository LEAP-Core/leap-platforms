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
        (ARBITER#(bits_T));
    
    method Maybe#(UInt#(TLog#(bits_T))) arbitrate(Bit#(bits_T) request);
        
        Maybe#(UInt#(TLog#(bits_T))) grant;
        Bit#(bits_T) higher_priority_request;
        
        for (Integer i = 0; i < valueOf(bits_T); i = i + 1)
        begin

            if (i == 0)
            begin
                if (request[i] == 1)
                    grant = tagged Valid 0;
                else
                    grant = tagged Invalid;
                higher_priority_request[i] = request[i];
            end
            else
            begin
                if ((~higher_priority_request[i-1] & request[i]) == 1)
                    grant = tagged Valid fromInteger(i);

                higher_priority_request[i] = higher_priority_request[i-1] | request[i];
            end
        
        end
        
        return grant;

    endmethod
    
endmodule

// === round-robin arbiter ===

// Arbitration Logic (example shown for n = 4):
//
// g0 =   r0        . (!r1 + p00) . (!r2 + p01) . (!r3 + p02)
// g1 = (!r0 + p10) .   r1        . (!r2 + p11) . (!r3 + p12)
// g2 = (!r0 + p20) . (!r1 + p21) .   r2        . (!r3 + p22)
// g3 = (!r0 + p30) . (!r1 + p31) . (!r2 + p32) .   r3
//
// where
//
// p is a priority matrix at any instant
//
// e.g.,
// p0 =  111 (lsb -> msb)
// p1 = 0 11
// p2 = 00 1
// p3 = 000 
//
// will give the priority ordering p0 > p1 > p2 > p3
//
// This matrix can be manipulated each cycle to shuffle priorities.
// For round-robin scheduling, move each row down and move the bottom
// row to the top.

module mkRoundRobinArbiter
    // interface:
    (ARBITER#(bits_T))
    provisos (Log#(bits_T, TLog#(bits_T)));
    
    // create the n x (n-1) priority matrix
    Vector#(bits_T, Reg#(Bit#(TSub#(bits_T, 1)))) prioMatrix = newVector();
    
    Bit#(TSub#(bits_T, 1)) mask = '1;
    for (Integer i = 0; i < valueOf(bits_T); i = i + 1)
    begin        
        prioMatrix[i] <- mkReg(mask);
        mask = mask << 1;    // note: example above showed lsb -> msb
    end

    // rotate priority matrix every cycle
    rule rotate_matrix (True);
        
        prioMatrix[0] <= prioMatrix[valueOf(bits_T) - 1];
        for (Integer i = 1; i < valueOf(bits_T); i = i + 1)
        begin
            prioMatrix[i] <= prioMatrix[i-1];
        end
    
    endrule

    // arbitrate
    method Maybe#(UInt#(TLog#(bits_T))) arbitrate(Bit#(bits_T) request);
        
        Vector#(bits_T, Bit#(1)) grant = replicate(0);
        
        for (Integer row = 0; row < valueOf(bits_T); row = row + 1)
        begin
        
            grant[row] = request[row];
            
            for (Integer col = 0; col < valueOf(bits_T) - 1; col = col + 1)
            begin

                if (row < col)
                begin
                    grant[row] = grant[row] & (~request[col] | prioMatrix[row][col]);
                end
                else
                begin
                    grant[row] = grant[row] & (~request[col+1] | prioMatrix[row][col]);
                end
        
            end
        
        end
        
        //
        // Find the unique grant bit.
        //
        return findElem(1, grant);

    endmethod
    
endmodule
