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
// Local memory using block RAM.
//
// Local memory is broken into words and lines.  The code here allocates
// a separate BRAM for each word position in a line and conforms to the
// local memory interface by providing methods to read/write either words
// or entire lines.
//
// The LOCAL_MEM_ADD_LATENCY parameter can be used for debugging to increase
// the read latency.  The parameter can be used to make this BRAM act more
// like longer latency memory, such as DDR2.  Note that the timing of the
// BRAM with latency isn't quite like DDR due to the short pipelines in
// the BRAM compared to DDR.  Attempts to work around the pipelines
// could affect load/store ordering, so the code has been kept simple.
//
// NOTE: if reads are allowed to back up due to long latency it is possible
// that the order of reads and writes will be affected by the latency!
//

import FIFO::*;
import FIFOF::*;
import Vector::*;

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/fpga_components.bsh"

// Cycle counter for calculating delays
typedef UInt#(16) REQ_CYCLE;

typedef struct
{
    // Reading a full line or a word?
    Bool fullLine;
 
    // Word index when not a full line
    LOCAL_MEM_WORD_IDX wordIdx;
 
    // Request cycle of load.  This field is used only when a delay is imposed
    // on read responses.  The delay is most likely used only when a block RAM
    // is being used in Bluesim in place of longer latency memory (e.g. DDR)
    // on the hardware.  This field should be optimized away when no delay is
    // requested.
    REQ_CYCLE reqCycle;
}
READ_REQ
    deriving (Bits, Eq);


module mkLocalMem#(PHYSICAL_DRIVERS drivers)
    // interface:
    (LOCAL_MEM);

    //
    // Store each word in a separate block RAM.
    //
    Vector#(LOCAL_MEM_WORDS_PER_LINE, BRAM#(LOCAL_MEM_LINE_ADDR, LOCAL_MEM_WORD)) mem <- replicateM(mkBRAM());

    // Record read requests (either full line or a word index)
    FIFOF#(READ_REQ) readReqQ <- mkSizedFIFOF(4);

    //
    // Count cycle for imposing delay
    //
    Reg#(REQ_CYCLE) cycle <- mkReg(0);

    (* fire_when_enabled *)
    rule countCycle (True);
        cycle <= cycle + 1;
    endrule


    //
    // checkLatency --
    //     Validate that enough time has passed before permitting a read response.
    //     This is typically used for debugging to match hardware memory latencies.
    //     The relatively small counter may wrap, which will cause slightly
    //     unpredictable latencies, but won't cause long delays.
    //
    function Bool checkLatency(READ_REQ req);
        if (`LOCAL_MEM_ADD_LATENCY == 0)
            return True;
        else
            return ((cycle - req.reqCycle) > `LOCAL_MEM_ADD_LATENCY);
    endfunction


    method Action readWordReq(LOCAL_MEM_ADDR addr);
        match {.l_addr, .w_idx} = localMemBurstAddr(addr);
        mem[w_idx].readReq(l_addr);

        // Note word read.
        readReqQ.enq(READ_REQ { fullLine: False, wordIdx: w_idx, reqCycle: cycle });
    endmethod

    method ActionValue#(LOCAL_MEM_WORD) readWordRsp() if (! readReqQ.first().fullLine &&
                                                          checkLatency(readReqQ.first()));
        let req = readReqQ.first();
        readReqQ.deq();

        let d <- mem[req.wordIdx].readRsp();
        return d;
    endmethod


    method Action readLineReq(LOCAL_MEM_ADDR addr);
        match {.l_addr, .w_idx} = localMemBurstAddr(addr);

        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            mem[w].readReq(l_addr);
        end

        // Note full line read.
        readReqQ.enq(READ_REQ { fullLine: True, wordIdx: ?, reqCycle: cycle });
    endmethod

    method ActionValue#(LOCAL_MEM_LINE) readLineRsp() if (readReqQ.first().fullLine &&
                                                          checkLatency(readReqQ.first()));
        readReqQ.deq();

        Vector#(LOCAL_MEM_WORDS_PER_LINE, LOCAL_MEM_WORD) line = newVector();
        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            line[w] <- mem[w].readRsp();
        end

        return pack(line);
    endmethod


    //
    // write methods are predicated with readReqQ.notFull() to ensure
    // synchronization of read and write requests.
    //

    method Action writeWord(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data) if (readReqQ.notFull());
        match {.l_addr, .w_idx} = localMemBurstAddr(addr);
        mem[w_idx].write(l_addr, data);
    endmethod

    method Action writeLine(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data) if (readReqQ.notFull());
        match {.l_addr, .w_idx} = localMemBurstAddr(addr);

        Vector#(LOCAL_MEM_WORDS_PER_LINE, LOCAL_MEM_WORD) l_data = unpack(data);
        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            mem[w].write(l_addr, l_data[w]);
        end
    endmethod
endmodule
