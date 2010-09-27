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
// Statistics wires for caches so individual caches can have their hit rates logged.
// When a line becomes true the coresponding statistic should be incremented.
//
interface RL_CACHE_STATS;
    method Bool readHit();
    method Bool readMiss();
    method Bool readRecentLineHit();     // Caches may have internal recent line
                                         // caches to optimize repeat accesses
                                         // to the same line.
    method Bool writeHit();
    method Bool writeMiss();
    method Bool invalEntry();            // Invalidate due to capacity
    method Bool dirtyEntryFlush();
    method Bool forceInvalLine();        // Invalidate forced by external request
endinterface: RL_CACHE_STATS

module mkNullRLCacheStats (RL_CACHE_STATS);
  return ?;
endmodule

