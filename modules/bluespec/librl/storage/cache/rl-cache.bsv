//
// Copyright (C) 2009 Intel Corporation
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
// Statistics object for caches so individual caches can log hit rates.
// A null module providing this interface is defined below for cache clients
// that don't need statistics.
//
interface RL_CACHE_STATS;
    method Action readHit();
    method Action readMiss();
    method Action writeHit();
    method Action writeMiss();
    method Action invalEntry();            // Invalidate due to capacity
    method Action dirtyEntryFlush();
    method Action forceInvalLine();        // Invalidate forced by external request
endinterface: RL_CACHE_STATS



//
// mkNullRLCacheStats --
//     Null version of RL_CACHE_STATS interface for clients not interested in
//     statistics.
//
module mkNullRLCacheStats
    // interface:
    (RL_CACHE_STATS);
    
    method Action readHit();
    endmethod

    method Action readMiss();
    endmethod

    method Action writeHit();
    endmethod

    method Action writeMiss();
    endmethod

    method Action invalEntry();
    endmethod

    method Action dirtyEntryFlush();
    endmethod

    method Action forceInvalLine();
    endmethod
endmodule
