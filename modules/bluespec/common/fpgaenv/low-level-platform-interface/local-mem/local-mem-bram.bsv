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
// The LOCAL_MEM_READ/WRITE_LATENCY parameters can be used for debugging to
// increase the read and write latencies.  The parameters can be used to make
// this BRAM act more like longer latency memory, such as DDR2.  Note that the
// timing of the BRAM with latency isn't quite like DDR due to the short
// pipelines in the BRAM compared to DDR.  Attempts to work around the pipelines
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

typedef `LOCAL_MEM_ADDR_BITS LOCAL_MEM_ADDR_SZ;

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
    Vector#(LOCAL_MEM_WORDS_PER_LINE,
            Vector#(LOCAL_MEM_BYTES_PER_WORD,
                    BRAM#(LOCAL_MEM_LINE_ADDR, Bit#(8)))) mem <- replicateM(replicateM(mkBRAM()));

    //
    // FIFOs added between incoming requests and the BRAM because reqeusts
    // from the central cache and this local memory wind up on the critical
    // path if the BRAM is exposed in methods.
    //
    Vector#(LOCAL_MEM_WORDS_PER_LINE,
            FIFO#(LOCAL_MEM_LINE_ADDR)) memReadReq <- replicateM(mkFIFO());
    Vector#(LOCAL_MEM_WORDS_PER_LINE,
            FIFO#(Tuple3#(LOCAL_MEM_LINE_ADDR,
                          LOCAL_MEM_WORD,
                          LOCAL_MEM_WORD_MASK))) memWriteReq <- replicateM(mkFIFO());

    // Record read requests (either full line or a word index).  If simulating
    // latency then only permit one operation at a time.
    FIFOF#(READ_REQ) readReqQ <- mkFIFOF();

    //
    // Count cycle for imposing delay
    //
    Reg#(REQ_CYCLE) cycle <- mkReg(0);

    (* fire_when_enabled *)
    rule countCycle (True);
        cycle <= cycle + 1;
    endrule

    //
    // Busy count for limiting write bandwidth
    //
    Reg#(Bit#(TLog#(TAdd#(1, `LOCAL_MEM_WRITE_LATENCY)))) writeBusyCnt <- mkReg(0);

    (* fire_when_enabled *)
    rule busyCount (writeBusyCnt != 0);
        writeBusyCnt <= writeBusyCnt - 1;
    endrule

    //
    // Forward incoming read and write requests to the BRAM.  This FIFO and
    // extra stage break a critical path between the central cache and
    // local memory.  The stage is added here to mirror stages already
    // present (and required) in DRAM-based local memory.
    //
    for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
    begin
        rule forwardReadReq (True);
            let addr = memReadReq[w].first();
            memReadReq[w].deq();

            for (Integer b = 0; b < valueOf(LOCAL_MEM_BYTES_PER_WORD); b = b + 1)
            begin
                mem[w][b].readReq(addr);
            end
        endrule

        rule forwardWriteReq (True);
            match {.addr, .data, .byteMask} = memWriteReq[w].first();
            memWriteReq[w].deq();

            Vector#(LOCAL_MEM_BYTES_PER_WORD, Bit#(8)) bytes = unpack(data);
            for (Integer b = 0; b < valueOf(LOCAL_MEM_BYTES_PER_WORD); b = b + 1)
            begin
                if (byteMask[b])
                begin
                    mem[w][b].write(addr, bytes[b]);
                end
            end
        endrule
    end

    //
    // checkLatency --
    //     Validate that enough time has passed before permitting a read response.
    //     This is typically used for debugging to match hardware memory latencies.
    //     The relatively small counter may wrap, which will cause slightly
    //     unpredictable latencies, but won't cause long delays.
    //
    function Bool checkLatency(READ_REQ req);
        if (`LOCAL_MEM_READ_LATENCY == 0)
            return True;
        else
            return ((cycle - req.reqCycle) > `LOCAL_MEM_READ_LATENCY);
    endfunction

    //
    // notBusy --
    //     Validate that simulated memory bus is available.  notBusy may return
    //     False due to an in-flight memory write when LOCAL_MEM_WRITE_LATENCY
    //     is non-zero.
    //
    function Bool notBusy();
        // readReqQ check is always required for correctness in order to keep
        // reads and writes ordered.
        return readReqQ.notFull() &&
               ((`LOCAL_MEM_WRITE_LATENCY == 0) || (writeBusyCnt == 0));
    endfunction


    method Action readWordReq(LOCAL_MEM_ADDR addr) if (notBusy());
        match {.l_addr, .w_idx} = localMemSeparateAddr(addr);
        memReadReq[w_idx].enq(l_addr);

        // Note word read.
        readReqQ.enq(READ_REQ { fullLine: False, wordIdx: w_idx, reqCycle: cycle });
    endmethod

    method ActionValue#(LOCAL_MEM_WORD) readWordRsp() if (! readReqQ.first().fullLine &&
                                                          checkLatency(readReqQ.first()));
        let req = readReqQ.first();
        readReqQ.deq();

        Vector#(LOCAL_MEM_BYTES_PER_WORD, Bit#(8)) bytes = newVector();
        for (Integer b = 0; b < valueOf(LOCAL_MEM_BYTES_PER_WORD); b = b + 1)
        begin
            bytes[b] <- mem[req.wordIdx][b].readRsp();
        end

        return pack(bytes);
    endmethod


    method Action readLineReq(LOCAL_MEM_ADDR addr) if (notBusy());
        match {.l_addr, .w_idx} = localMemSeparateAddr(addr);

        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            memReadReq[w].enq(l_addr);
        end

        // Note full line read.
        readReqQ.enq(READ_REQ { fullLine: True, wordIdx: ?, reqCycle: cycle });
    endmethod

    method ActionValue#(LOCAL_MEM_LINE) readLineRsp() if (readReqQ.first().fullLine &&
                                                          checkLatency(readReqQ.first()));
        readReqQ.deq();

        Vector#(LOCAL_MEM_WORDS_PER_LINE,
                Vector#(LOCAL_MEM_BYTES_PER_WORD, Bit#(8))) bytes = newVector();
        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            for (Integer b = 0; b < valueOf(LOCAL_MEM_BYTES_PER_WORD); b = b + 1)
            begin
                bytes[w][b] <- mem[w][b].readRsp();
            end
        end

        return pack(bytes);
    endmethod


    //
    // write methods are predicated with readReqQ.notFull() to ensure
    // synchronization of read and write requests.
    //

    method Action writeWord(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data) if (notBusy());
        match {.l_addr, .w_idx} = localMemSeparateAddr(addr);
        memWriteReq[w_idx].enq(tuple3(l_addr, data, replicate(True)));

        writeBusyCnt <= `LOCAL_MEM_WRITE_LATENCY;
    endmethod

    method Action writeLine(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data) if (notBusy());
        match {.l_addr, .w_idx} = localMemSeparateAddr(addr);

        Vector#(LOCAL_MEM_WORDS_PER_LINE, LOCAL_MEM_WORD) l_data = unpack(data);
        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            memWriteReq[w].enq(tuple3(l_addr, l_data[w], replicate(True)));
        end

        writeBusyCnt <= `LOCAL_MEM_WRITE_LATENCY;
    endmethod

    method Action writeWordMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data, LOCAL_MEM_WORD_MASK mask) if (notBusy());
        match {.l_addr, .w_idx} = localMemSeparateAddr(addr);
        if (pack(mask) != 0)
        begin
            memWriteReq[w_idx].enq(tuple3(l_addr, data, mask));
        end

        writeBusyCnt <= `LOCAL_MEM_WRITE_LATENCY;
    endmethod

    method Action writeLineMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data, LOCAL_MEM_LINE_MASK mask) if (notBusy());
        match {.l_addr, .w_idx} = localMemSeparateAddr(addr);

        Vector#(LOCAL_MEM_WORDS_PER_LINE, LOCAL_MEM_WORD) l_data = unpack(data);
        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            if (pack(mask[w]) != 0)
            begin
                memWriteReq[w].enq(tuple3(l_addr, l_data[w], mask[w]));
            end
        end

        writeBusyCnt <= `LOCAL_MEM_WRITE_LATENCY;
    endmethod
endmodule
