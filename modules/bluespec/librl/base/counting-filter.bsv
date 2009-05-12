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

// Library imports.

import Vector::*;
import RWire::*;

//
// Counting filters can be used to determine whether an entry is present in
// a set.  All counting filters have both insert() and remove() methods.
// This module provides multiple implementations for sets of varying sizes.
// Smaller sets can use direct decode filters.  Larger sets can use Bloom
// filters, which have more logic to deal with hashes but have good false
// positive rates with relatively small filter vector sizes.
//
// For automatic selection of a reasonable filter, use the mkCountingFilter
// module.  It picks decode filters for smaller sets and Bloom filters for
// larger sets.
//


// ========================================================================

// COUNTING_FILTER
//
//   All counting filters provide this basic interface.
//
// ========================================================================

interface COUNTING_FILTER#(type t_ENTRY);
    // Clear filter
    method Action reset();

    // Attempt to insert a new entry.  Returns true on success.  If the filter
    // already has the entry or a counter would overflow returns false.
    method ActionValue#(Bool) insert(t_ENTRY newEntry);

    method Action remove(t_ENTRY oldEntry);

    // Test whether entry is busy
    method Bool notSet(t_ENTRY entry);
endinterface


//
// mkCountingFilter --
//   Pick a reasonable filter based on the entry set size.  Uses a Bloom filter
//   for large sets and a simple decode filter for smaller sets.
//
//   If allowComplexFilters is true then larger filters, such as Bloom filters,
//   may be allocated.  If allowComplexFilters is false then only decode filters
//   will be allocated.
//
module mkCountingFilter#(Bool allowComplexFilters, DEBUG_FILE debugLog)
    // interface:
    (COUNTING_FILTER#(t_ENTRY))
    provisos (Bits#(t_ENTRY, t_ENTRY_SZ));

    let filter = ?;

    if ((valueOf(t_ENTRY_SZ) > 10) && allowComplexFilters)
    begin
        // Large sets use Bloom filters
        COUNTING_BLOOM_FILTER#(t_ENTRY, 128, 2) bloomFilter <- mkCountingBloomFilter(debugLog);
        filter = bloomFilter.countingFilterIfc;
    end
    else if (valueOf(t_ENTRY_SZ) > 7)
    begin
        // Medium sized sets share 2 bits per entry
        DECODE_FILTER#(t_ENTRY, TDiv#(TExp#(t_ENTRY_SZ), 2)) decodeFilterL <- mkSizedDecodeFilter(debugLog);
        filter = decodeFilterL.countingFilterIfc;
    end
    else
    begin
        // Small sets get unique bit per entry
        DECODE_FILTER#(t_ENTRY, TExp#(t_ENTRY_SZ)) decodeFilterS <- mkSizedDecodeFilter(debugLog);
        filter = decodeFilterS.countingFilterIfc;
    end

    return filter;
endmodule


// ========================================================================
//
// Decode Filter
//
// ========================================================================

//
// nFilterBits should be a power of 2!  Decode filter exposes
// a counting filter interface for compatibility with the Bloom
// filter.
//
interface DECODE_FILTER#(type t_ENTRY, numeric type nFilterBits);
    interface COUNTING_FILTER#(t_ENTRY) countingFilterIfc;
endinterface

//
// Decode filter with one bit corresponding to one or more entries.
// Insert and remove methods may both be called in the same cycle.
//
module mkSizedDecodeFilter#(DEBUG_FILE debugLog)
    // interface:
    (DECODE_FILTER#(t_ENTRY, nFilterBits))
    provisos (Bits#(t_ENTRY, t_ENTRY_SZ),
       
              Alias#(Bit#(TLog#(nFilterBits)), t_FILTER_IDX));

    Reg#(Bit#(nFilterBits)) fv <- mkReg(0);

    RWire#(t_FILTER_IDX) insertId <- mkRWire();
    RWire#(t_FILTER_IDX) removeId <- mkRWire();

    Reg#(Maybe#(t_ENTRY)) lastFailMsg <- mkReg(tagged Invalid);

    function t_FILTER_IDX filterIdx(t_ENTRY e);
        return truncateNP(pack(e));
    endfunction

    (* fire_when_enabled *)
    rule updateFilter (True);
        let fv_new = fv;
        
        if (insertId.wget() matches tagged Valid .id)
            fv_new[id] = 1;

        if (removeId.wget() matches tagged Valid .id)
            fv_new[id] = 0;
        
        fv <= fv_new;
    endrule

    interface COUNTING_FILTER countingFilterIfc;
        method Action reset();
            fv <= 0;
        endmethod

        method ActionValue#(Bool) insert(t_ENTRY newEntry);
            let id = filterIdx(newEntry);

            if (fv[id] == 0)
            begin
                insertId.wset(id);
                lastFailMsg <= tagged Invalid;
                debugLog.record($format("    Decode filter INSERT %0d OK, idx=%0d", newEntry, id));
                return True;
            end
            else
            begin
                // Only print insert FAIL message once
                if (! isValid(lastFailMsg) || (pack(newEntry) != pack(validValue(lastFailMsg))))
                begin
                    lastFailMsg <= tagged Valid newEntry;
                    debugLog.record($format("    Decode filter INSERT %0d FAIL, idx=%0d", newEntry, id));
                end

                return False;
            end
        endmethod

        method Action remove(t_ENTRY oldEntry);
            let id = filterIdx(oldEntry);
            removeId.wset(id);
            debugLog.record($format("    Decode filter REMOVE %0d, idx=%0d", oldEntry, id));
        endmethod

        method Bool notSet(t_ENTRY entry);
            let id = filterIdx(entry);
            return (fv[id] == 0);
        endmethod
    endinterface
endmodule



// ========================================================================
//
// Counting Bloom Filter
//
// ========================================================================


interface COUNTING_BLOOM_FILTER#(type t_ENTRY,
                                 numeric type nFilterBits,
                                 numeric type nCounterBits);
    interface COUNTING_FILTER#(t_ENTRY) countingFilterIfc;
endinterface


typedef Vector#(nHashes, Bit#(nHashIndexBits))
    BLOOM_FILTER_HASH_VEC#(numeric type nHashes, numeric type nHashIndexBits);

//
// Optimal number of hashes is probably 5 or 6, but that takes too much FPGA
// space.
//
typedef 4 BLOOM_COUNTING_HASHES;

//
// Counting Bloom filter up to 256 bits.
//
module mkCountingBloomFilter#(DEBUG_FILE debugLog)
    // interface:
    (COUNTING_BLOOM_FILTER#(t_ENTRY, nFilterBits, nCounterBits))
    provisos (Bits#(t_ENTRY, t_ENTRY_SZ),

              // nFilterBits must be <= 256 and a power of 2.
              Add#(TLog#(nFilterBits), a__, 8),
              Add#(nFilterBits, 0, TExp#(TLog#(nFilterBits))),

              Alias#(BLOOM_FILTER_HASH_VEC#(BLOOM_COUNTING_HASHES, TLog#(nFilterBits)), t_HASH_VEC));
    
    // Filter bits (counters)
    Reg#(Vector#(nFilterBits, Bit#(nCounterBits))) bf <- mkReg(replicate(0));

    // Insert and remove requests are passed on wires to a single rule so
    // both methods may be called in the same cycle.
    RWire#(t_HASH_VEC) insertVec <- mkRWire();
    RWire#(t_ENTRY) removeId <- mkRWire();
    RWire#(Tuple2#(Bit#(nFilterBits), Bit#(nFilterBits))) updateBits <- mkRWire();

    Reg#(Maybe#(t_ENTRY)) lastFailMsg <- mkReg(tagged Invalid);

    //
    // computeHashes --
    //     Calculate the set of hashes for an entry id.
    //
    function t_HASH_VEC computeHashes(t_ENTRY entryId);
        //
        // Map however many entry bits there are to 32 bits.  This hash function
        // is a compromise for FPGA area.  It works well for current functional
        // memory set sizes.  We may need to revisit it later.
        //
        Bit#(32) idx32;
        Bit#(t_ENTRY_SZ) idx_orig = pack(entryId);
        Integer b = 0;
        for (Integer i = 0; i < 32; i = i + 1)
        begin
            idx32[i] = idx_orig[b];

            b = b + 1;
            if (b == valueOf(t_ENTRY_SZ))
                b = 0;
        end

        // Get four 8 bit hashes
        t_HASH_VEC hash = newVector();

        hash[0] = truncate(hash8(idx32[7:0]));
        hash[1] = truncate(hash8a(idx32[15:8]));
        hash[2] = truncate(hash8b(idx32[23:16]));
        hash[3] = truncate(hash8c(idx32[31:24]));
    
        return hash;
    endfunction


    //
    // updateFilter --
    //
    //     Two part, single cycle rule to update the Bloom filter.  The
    //     first rule consumes this cycle's insert and remove calls and constructs
    //     a pair of vectors of filter positions that will change.  The second
    //     rule consumes those vectors as wires and updates the Bloom filter.
    //
    //     While these rules are logically a single rule, combining them causes
    //     the Bluespec optimizer to attempt to figure out exactly which bits
    //     changed and the combinatorics grow quite large.
    //

    (* fire_when_enabled *)
    rule updateFilter1 (True);
        //
        // Construct a vector of filter positions to increment.
        //
        Bit#(nFilterBits) bf_up = 0;

        if (insertVec.wget() matches tagged Valid .hash)
        begin
            for (Integer i = 0; i < valueOf(BLOOM_COUNTING_HASHES); i = i + 1)
            begin
                bf_up[hash[i]] = 1;
            end
        end

        //
        // Construct a vector of filter positions to decrement.
        //
        Bit#(nFilterBits) bf_down = 0;

        //
        // Removal request comes in as the index to the filter instead of a
        // set of hash buckets.  This puts the computation of hashes in a single
        // rule.  We would do this for the insert request, too, except that
        // the insert method returns a response that is a function of the hashes.
        //
        if (removeId.wget() matches tagged Valid .remId)
        begin
            let hash = computeHashes(remId);
            for (Integer i = 0; i < valueOf(BLOOM_COUNTING_HASHES); i = i + 1)
            begin
                bf_down[hash[i]] = 1;
            end

            debugLog.record($format("    Bloom filter REMOVE input state, id=0x%x: %0d (%0d), %0d (%0d), %0d (%0d), %0d (%0d)",
                                    remId,
                                    hash[0], bf[hash[0]],
                                    hash[1], bf[hash[1]],
                                    hash[2], bf[hash[2]],
                                    hash[3], bf[hash[3]]));
        end

        // Pass the update vectors to the next rule (same cycle)
        updateBits.wset(tuple2(bf_up, bf_down));
    endrule


    (* fire_when_enabled *)
    rule updateFilter2 (True);
        //
        // Consume the result of updateFilter1 and update the Bloom filter.
        //

        if (updateBits.wget() matches tagged Valid {.bf_up, .bf_down})
        begin
            Vector#(nFilterBits, Bit#(nCounterBits)) bf_new;

            // A filter slot changes if only one of up and down is requested
            let bf_changes = bf_up ^ bf_down;

            for (Integer i = 0; i < valueOf(nFilterBits); i = i + 1)
            begin
                if (bf_changes[i] == 1)
                    // Position gets new value
                    bf_new[i] = bf[i] + ((bf_up[i] == 1) ? 1 : -1);
                else
                    // Position unchanged
                    bf_new[i] = bf[i];
            end
        
            bf <= bf_new;
        end
    endrule


    interface COUNTING_FILTER countingFilterIfc;
        method Action reset();
            bf <= replicate(0);
        endmethod


        method ActionValue#(Bool) insert(t_ENTRY newEntry);
            let hash = computeHashes(newEntry);

            //
            // Update counters for the hashes.  Compute two properties:
            //   all_set --  True iff all hashes were already set in the filter,
            //               indicating the index is already present.
            //   overflow -- True iff any counter would overflow.
            //

            Bool all_set = True;
            Bool overflow = False;

            debugLog.record($format("    Bloom filter INSERT input state, id=0x%x: %0d (%0d), %0d (%0d), %0d (%0d), %0d (%0d)",
                                    newEntry,
                                    hash[0], bf[hash[0]],
                                    hash[1], bf[hash[1]],
                                    hash[2], bf[hash[2]],
                                    hash[3], bf[hash[3]]));

            for (Integer i = 0; i < valueOf(BLOOM_COUNTING_HASHES); i = i + 1)
            begin
                let bucket = hash[i];

                all_set = all_set && (bf[bucket] != 0);

                let new_count = bf[bucket] + 1;
                overflow = overflow || (new_count == 0);

                if (new_count == 0)
                    debugLog.record($format("    Bloom filter bucket %0d overflow", bucket));
            end

            if (all_set || overflow)
            begin
                // Can't insert.  Only print insert FAIL message once.
                if (! isValid(lastFailMsg) || (pack(newEntry) != pack(validValue(lastFailMsg))))
                begin
                    lastFailMsg <= tagged Valid newEntry;
                    debugLog.record($format("    Bloom filter INSERT FAIL"));
                end

                return False;
            end
            else
            begin
                debugLog.record($format("    Bloom filter INSERT OK"));
                lastFailMsg <= tagged Invalid;
                insertVec.wset(hash);
                return True;
            end
        endmethod


        method Action remove(t_ENTRY oldEntry);
            removeId.wset(oldEntry);
        endmethod


        method Bool notSet(t_ENTRY entry);
            let hash = computeHashes(entry);

            Bool all_set = True;
            for (Integer i = 0; i < valueOf(BLOOM_COUNTING_HASHES); i = i + 1)
            begin
                let bucket = hash[i];
                all_set = all_set && (bf[bucket] != 0);
            end

            // Entry is busy iff all hash bits are set
            return ! all_set;
        endmethod
    endinterface
endmodule
