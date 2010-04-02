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
// Local memory using DDR2.
//
// DDR memory has a fundamental word from the requested local memory word.
// It has a minimum access size that is larger than a word both by
// transmitting words on both edges of the clock.  Furthermore, some controllers
// send a multi-cycle burst of messages in response to a single request.
// The code here maps DDR physical sizes to the requested sizes for local
// memory words and lines.
//

import FIFO::*;
import SpecialFIFOs::*;
import Vector::*;

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/ddr2_device.bsh"

// ========================================================================
//
// Derive standard local memory properties from the device properties
//
// ========================================================================

// How many FPGA DDR words in a local memory word?
typedef TDiv#(LOCAL_MEM_WORD_SZ, FPGA_DDR_WORD_SZ) DDR_WORDS_PER_LOCAL_WORD;

// Compute the address space size available to local memory:  total FPGA
// words across all DDR banks, referenced as local words.
typedef TSub#(TAdd#(FPGA_DDR_ADDRESS_SZ, TLog#(FPGA_DDR_BANKS)),
              TLog#(DDR_WORDS_PER_LOCAL_WORD)) LOCAL_MEM_ADDR_SZ;


// ========================================================================
//
// Construct a LOCAL_MEM_LINE from FPGA DDR banks, bursts and words.
//
// ========================================================================

// *****
// For now we assume that all banks are combined to form a line.  A line
// may require more than one request of all banks.
// *****

// The DRAM driver breaks reads and writes into multi-cycle bursts.
typedef TMul#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_DATA_SZ) DDR_BURST_DATA_SZ;
typedef TDiv#(DDR_BURST_DATA_SZ, LOCAL_MEM_WORD_SZ) LOCAL_MEM_WORDS_PER_BURST;
typedef Vector#(LOCAL_MEM_WORDS_PER_BURST, LOCAL_MEM_WORD) DDR_BURST_DATA;
typedef Vector#(LOCAL_MEM_WORDS_PER_BURST, LOCAL_MEM_WORD_MASK) DDR_BURST_DATA_MASK;

// Combine banks into a unified line
typedef TMul#(FPGA_DDR_BANKS, DDR_BURST_DATA_SZ) DDR_BANKS_LINE_SZ;

// More than one DDR line access may be required to complete a LOCAL_MEM_LINE.
// We assume that LOCAL_MEM_LINE_SZ >= DDR_BANKS_LINE_SZ and that both are
// powers of 2.
typedef TDiv#(LOCAL_MEM_LINE_SZ, DDR_BANKS_LINE_SZ) DDR_BURSTS_PER_LOCAL_LINE;
typedef Vector#(DDR_BURSTS_PER_LOCAL_LINE, DDR_BURST_DATA) DDR_BURSTS_LINE;
typedef Vector#(DDR_BURSTS_PER_LOCAL_LINE, DDR_BURST_DATA_MASK) DDR_BURSTS_LINE_MASK;

// Full line after combining banks
typedef Vector#(FPGA_DDR_BANKS, DDR_BURSTS_LINE) DDR_FULL_LINE;
typedef Vector#(FPGA_DDR_BANKS, DDR_BURSTS_LINE_MASK) DDR_FULL_LINE_MASK;


//
// DDR_WORD_IDX uniquely identifies a word in DDR memory within a LOCAL_MEM_LINE.
// It must be the same size as a LOCAL_MEM_WORD_IDX.
//
typedef struct
{
    Bit#(TLog#(FPGA_DDR_BANKS)) bankIdx;
    Bit#(TLog#(DDR_BURSTS_PER_LOCAL_LINE)) burstIdx;
    Bit#(TLog#(LOCAL_MEM_WORDS_PER_BURST)) wordIdx;
}
DDR_WORD_IDX
    deriving (Bits, Eq);


//
// Read or write request address.  Requests are either for full lines or for
// words.
//
typedef union tagged
{
    LOCAL_MEM_ADDR MEM_REQ_LINE;
    LOCAL_MEM_ADDR MEM_REQ_WORD;
}
LOCAL_MEM_REQ
    deriving (Bits, Eq);


typedef union tagged
{
    Tuple2#(DDR_BURSTS_LINE, DDR_BURSTS_LINE_MASK)             WRITE_LINE;
    Tuple3#(LOCAL_MEM_WORD, LOCAL_MEM_WORD_MASK, DDR_WORD_IDX) WRITE_WORD;
}
LOCAL_MEM_BANK_WRITE_REQ
    deriving (Bits, Eq);


module mkLocalMem#(PHYSICAL_DRIVERS drivers)
    // interface:
    (LOCAL_MEM)
    provisos (Alias#(Bit#(TLog#(DDR_BURSTS_PER_LOCAL_LINE)), t_BURST_IDX),
              NumAlias#(TSub#(DDR_BURSTS_PER_LOCAL_LINE, 1), n_LAST_BURST_IDX),

              Alias#(Bit#(TLog#(LOCAL_MEM_WORDS_PER_BURST)), t_WORD_IDX),

              // Bluespec doesn't deal well with size-0 comparisons.  Define
              // safe versions of the counters that are guaranteed 1 bit or
              // larger.
              Max#(TLog#(DDR_BURSTS_PER_LOCAL_LINE), 1, t_SAFE_BURST_IDX_SZ),
              Alias#(Bit#(t_SAFE_BURST_IDX_SZ), t_SAFE_BURST_IDX),

              Max#(TLog#(FPGA_DDR_BANKS), 1, t_SAFE_BANK_IDX_SZ),
              Alias#(Bit#(t_SAFE_BANK_IDX_SZ), t_SAFE_BANK_IDX),

              Max#(TLog#(LOCAL_MEM_WORDS_PER_BURST), 1, t_SAFE_WORD_IDX_SZ),
              Alias#(Bit#(t_SAFE_WORD_IDX_SZ), t_SAFE_WORD_IDX));

    if (valueOf(FPGA_DDR_DUALEDGE_DATA_SZ) * valueOf(FPGA_DDR_BANKS) >
        valueOf(LOCAL_MEM_LINE_SZ))
    begin
        error("Expected LOCAL_MEM_LINE size >= one access across the width of all banks combined");
    end

    if (valueOf(SizeOf#(DDR_WORD_IDX)) != valueOf(LOCAL_MEM_WORD_IDX_SZ))
    begin
        error("DDR_WORD_IDX (" + integerToString(valueOf(SizeOf#(DDR_WORD_IDX))) +
              ") must be the same size as LOCAL_MEM_WORD_IDX (" +
              integerToString(valueOf(LOCAL_MEM_WORD_IDX_SZ)) + ")");
    end


    //
    // genBankAddr --
    //     Convert a local memory address (line address and components of the
    //     DDR_WORD_IDX) to an FPGA DDR device address.
    //
    function FPGA_DDR_ADDRESS genBankAddr(LOCAL_MEM_LINE_ADDR lineAddr,
                                          t_BURST_IDX burstIdx,
                                          t_WORD_IDX wordIdx);
        Bit#(TLog#(DDR_WORDS_PER_LOCAL_WORD)) ddrWordIdx = 0;
        return unpack({lineAddr, burstIdx, wordIdx, ddrWordIdx});
    endfunction


    // Get a handle to the DDR2 DRAM Controller
    Vector#(FPGA_DDR_BANKS, DDR2_DRIVER) dramDriver = drivers.ddr2Driver;

    // Merge read and write requests into a single FIFO to preserve order.
    // The DDR controller does this anyway, so we lose no performance.
    MERGE_FIFOF#(2, LOCAL_MEM_REQ) mergeReqQ <- mkMergeBypassFIFOF();

    // Control the source of the next read response.  Invalid is a full line
    // from all banks.
    FIFO#(Maybe#(t_SAFE_BANK_IDX)) readCtrlQ <- mkSizedFIFO(valueOf(TMul#(2, FPGA_DDR_MAX_OUTSTANDING_READS)));

    // Record read requests.  For word-sized reads, pass the bank and word
    // index.  For a full line, pass "Invalid"
    Vector#(FPGA_DDR_BANKS,
            FIFO#(Maybe#(DDR_WORD_IDX))) readReqQ <- replicateM(mkSizedFIFO(valueOf(TMul#(2, FPGA_DDR_MAX_OUTSTANDING_READS))));


    // ====================================================================
    //
    // Requests (read or write) to the DDR controller.  (Write data is
    // sent separately.)
    //
    // ====================================================================

    //
    // doWordReq --
    //     For word-sized requests, compute the address of the DDR burst
    //     holding the word and request an operation in the approriate bank.
    //
    rule doWordReq (mergeReqQ.first() matches tagged MEM_REQ_WORD .addr);
        Bool isWrite = (mergeReqQ.firstPortID() == 1);
        mergeReqQ.deq();

        // Compute the address of the appropriate DDR burst
        match {.line_addr, .w_offset} = localMemSeparateAddr(addr);

        // Convert the word offset to DDR indexing fields
        DDR_WORD_IDX w_idx = unpack(pack(w_offset));

        // Compute the address of the DDR burst holding the word.
        let dev_addr = genBankAddr(line_addr, w_idx.burstIdx, 0);

        if (isWrite)
        begin
            dramDriver[w_idx.bankIdx].writeReq(dev_addr);
        end
        else
        begin
            dramDriver[w_idx.bankIdx].readReq(dev_addr);
            readReqQ[w_idx.bankIdx].enq(tagged Valid w_idx);
        end
    endrule


    //
    // doLineReq --
    //     Iterate over a request for a line, requesting as many device bursts
    //     from all memory banks as needed to complete a LOCAL_MEM_LINE.
    //
    Reg#(t_SAFE_BURST_IDX) lineReqBurstIdx <- mkReg(0);

    rule doLineReq (mergeReqQ.first() matches tagged MEM_REQ_LINE .addr);
        Bool isWrite = (mergeReqQ.firstPortID() == 1);

        // Compute the address of the next burst for this request
        let line_addr = tpl_1(localMemSeparateAddr(addr));
        let dev_addr = genBankAddr(line_addr, truncate(lineReqBurstIdx), 0);

        // Request the burst from all memory banks.  For now this code only
        // works when LOCAL_MEM_LINE >= DDR_BANKS_LINE.
        for (Integer b = 0; b < valueOf(FPGA_DDR_BANKS); b = b + 1)
        begin
            if (isWrite)
            begin
                dramDriver[b].writeReq(dev_addr);
            end
            else
            begin
                dramDriver[b].readReq(dev_addr);
                readReqQ[b].enq(tagged Invalid);
            end
        end

        if (lineReqBurstIdx == fromInteger(valueOf(n_LAST_BURST_IDX)))
        begin
            mergeReqQ.deq();
            lineReqBurstIdx <= 0;
        end
        else
        begin
            lineReqBurstIdx <= lineReqBurstIdx + 1;
        end
    endrule


    // ====================================================================
    //
    // Reads
    //
    // ====================================================================

    //
    // collectReadDDRBurstRsp --
    //     For each bank, collect all responses for a single DDR read request.
    //     Some controllers return a "burst" of multiple responses to a single
    //     read.
    //
    Vector#(FPGA_DDR_BANKS, FIFO#(DDR_BURST_DATA)) readDDRBurstRspQ <- replicateM(mkFIFO());
    Vector#(FPGA_DDR_BANKS,
            Reg#(Vector#(FPGA_DDR_BURST_LENGTH,
                         FPGA_DDR_DUALEDGE_DATA))) readDDRBurstBuf <- replicateM(mkRegU());
    Vector#(FPGA_DDR_BANKS,
            Reg#(Bit#(TLog#(FPGA_DDR_BURST_LENGTH)))) readDDRBurstIdx <- replicateM(mkReg(0));

    for (Integer b = 0; b < valueOf(FPGA_DDR_BANKS); b = b + 1)
    begin
        rule collectReadDDRBurstRsp (True);
            let d <- dramDriver[b].readRsp();

            // Collect the burst in readDDRBurstBuf
            let burst = readDDRBurstBuf[b];
            burst[readDDRBurstIdx[b]] = d;
            readDDRBurstBuf[b] <= burst;

            if (readDDRBurstIdx[b] == fromInteger(valueOf(TSub#(FPGA_DDR_BURST_LENGTH, 1))))
            begin
                // Last stage in the burst.  Collect and forward the DDR burst.
                readDDRBurstRspQ[b].enq(unpack(pack(burst)));
                readDDRBurstIdx[b] <= 0;
            end
            else
            begin
                // Not the last stage.  Accumulate data.
                readDDRBurstIdx[b] <= readDDRBurstIdx[b] + 1;
            end
        endrule
    end


    //
    // collectReadLineBurstsRsp --
    //     A LOCAL_MEM_LINE may be a collection of multiple requests to the
    //     memory.  At the bank level, this rule collects responses to
    //     individual read requests until all data has been received.
    //
    Vector#(FPGA_DDR_BANKS, FIFO#(DDR_BURSTS_LINE)) readLineRspQ <- replicateM(mkBypassFIFO());
    Vector#(FPGA_DDR_BANKS, Reg#(DDR_BURSTS_LINE)) readLineRspBuf <- replicateM(mkRegU());
    Vector#(FPGA_DDR_BANKS, Reg#(t_SAFE_BURST_IDX)) readLineRspBurstIdx <- replicateM(mkReg(0));

    for (Integer b = 0; b < valueOf(FPGA_DDR_BANKS); b = b + 1)
    begin
        rule collectReadLineBurstsRsp (! isValid(readReqQ[b].first()));
            readReqQ[b].deq();

            // Get one burst from the memory
            DDR_BURST_DATA d = readDDRBurstRspQ[b].first();
            readDDRBurstRspQ[b].deq();

            // Collect the bank's portion of the line in readLineRspBuf
            let line = readLineRspBuf[b];
            line[readLineRspBurstIdx[b]] = d;
            readLineRspBuf[b] <= line;

            if (readLineRspBurstIdx[b] == fromInteger(valueOf(n_LAST_BURST_IDX)))
            begin
                // Done
                readLineRspQ[b].enq(line);
                readLineRspBurstIdx[b] <= 0;
            end
            else
            begin
                readLineRspBurstIdx[b] <= readLineRspBurstIdx[b] + 1;
            end
        endrule
    end


    // ====================================================================
    //
    // Writes
    //
    // ====================================================================

    //
    // forwardWriteLineData --
    //     Writes are bursts of data and an address.  Process a request until
    //     all data is passed to the driver and then dequeue the request.
    //
    Vector#(FPGA_DDR_BANKS, FIFO#(LOCAL_MEM_BANK_WRITE_REQ)) writeDataQ <- replicateM(mkBypassFIFO());
    Vector#(FPGA_DDR_BANKS,
            Reg#(t_SAFE_BURST_IDX)) writeLineDataBurstIdx <- replicateM(mkReg(0));
    Vector#(FPGA_DDR_BANKS,
            Reg#(Bit#(TLog#(FPGA_DDR_BURST_LENGTH)))) writeDDRBurstIdx <- replicateM(mkReg(0));

    for (Integer b = 0; b < valueOf(FPGA_DDR_BANKS); b = b + 1)
    begin
        rule forwardWriteLineData (writeDataQ[b].first() matches tagged WRITE_LINE {.w_data, .w_mask});
            // Data for this stage in the burst
            Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_DATA) burst;
            burst = unpack(pack(w_data[writeLineDataBurstIdx[b]]));
            let val = burst[writeDDRBurstIdx[b]];
       
            Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_DATA_MASK) burst_mask;
            burst_mask = unpack(pack(w_mask[writeLineDataBurstIdx[b]]));
            let mask = burst_mask[writeDDRBurstIdx[b]];

            dramDriver[b].writeData(val, mask);

            // Last stage in the DDR burst?
            if (writeDDRBurstIdx[b] == fromInteger(valueOf(TSub#(FPGA_DDR_BURST_LENGTH, 1))))
            begin
                writeDDRBurstIdx[b] <= 0;

                // Last burst?
                if (writeLineDataBurstIdx[b] == fromInteger(valueOf(n_LAST_BURST_IDX)))
                begin
                    writeDataQ[b].deq();
                    writeLineDataBurstIdx[b] <= 0;
                end
                else
                begin
                    writeLineDataBurstIdx[b] <= writeLineDataBurstIdx[b] + 1;
                end
            end
            else
            begin
                writeDDRBurstIdx[b] <= writeDDRBurstIdx[b] + 1;
            end
        endrule
    end


    //
    // forwardWriteWordData --
    //     Word-sized writes are one DDR burst to a specific bank.  A DDR burst
    //     may be multiple messages, depending on the controller.
    //
    for (Integer b = 0; b < valueOf(FPGA_DDR_BANKS); b = b + 1)
    begin
        rule forwardWriteWordData (writeDataQ[b].first() matches tagged WRITE_WORD {.w_data, .w_mask, .w_idx});
            // Replicate the word throughout the burst to save a MUX.  The mask
            // will pick out the right word.
            DDR_BURST_DATA d = replicate(w_data);
            
            // Construct a mask that writes only the requested word.  1 means
            // don't write.
            DDR_BURST_DATA_MASK m = replicate(replicate(True));
            m[w_idx.wordIdx] = w_mask;

            // Convert to DDR types
            Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_DATA) burst;
            burst = unpack(pack(d));
            let val = burst[writeDDRBurstIdx[b]];
       
            Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_DATA_MASK) burst_mask;
            burst_mask = unpack(pack(m));
            let mask = burst_mask[writeDDRBurstIdx[b]];

            // Write the next part of the burst
            dramDriver[b].writeData(val, mask);

            // Last stage in the DDR burst?
            if (writeDDRBurstIdx[b] == fromInteger(valueOf(TSub#(FPGA_DDR_BURST_LENGTH, 1))))
            begin
                writeDataQ[b].deq();
                writeDDRBurstIdx[b] <= 0;
            end
            else
            begin
                writeDDRBurstIdx[b] <= writeDDRBurstIdx[b] + 1;
            end
        endrule
    end


    // ====================================================================
    //
    // Methods
    //
    // ====================================================================

    //
    // Read and write request methods are predicated
    // to ensure synchronization with writes.
    //

    method Action readWordReq(LOCAL_MEM_ADDR addr);
        mergeReqQ.ports[0].enq(tagged MEM_REQ_WORD addr);

        // From which bank should the word be read?  Break the word index
        // portion of the address into its component parts to find out.
        DDR_WORD_IDX w_idx = unpack(pack(tpl_2(localMemSeparateAddr(addr))));

        // Note the bank that will return the word
        readCtrlQ.enq(tagged Valid zeroExtend(w_idx.bankIdx));
    endmethod

    method ActionValue#(LOCAL_MEM_WORD) readWordRsp() if (readCtrlQ.first() matches tagged Valid .bank &&&
                                                          readReqQ[bank].first() matches tagged Valid .w_idx);
        readCtrlQ.deq();
        readReqQ[bank].deq();
    
        DDR_BURST_DATA d = readDDRBurstRspQ[bank].first();
        readDDRBurstRspQ[bank].deq();

        LOCAL_MEM_WORD val = d[w_idx.wordIdx];
        return val;
    endmethod


    method Action readLineReq(LOCAL_MEM_ADDR addr);
        mergeReqQ.ports[0].enq(tagged MEM_REQ_LINE addr);

        // Invalid on the control queue means reading the entire line (all banks)
        readCtrlQ.enq(tagged Invalid);
    endmethod

    method ActionValue#(LOCAL_MEM_LINE) readLineRsp() if (! isValid(readCtrlQ.first()));
        readCtrlQ.deq();

        // Merge responses from all banks to form the line
        DDR_FULL_LINE line = ?;
        for (Integer b = 0; b < valueOf(FPGA_DDR_BANKS); b = b + 1)
        begin
            line[b] = readLineRspQ[b].first();
            readLineRspQ[b].deq();
        end

        return unpack(pack(line));
    endmethod


    method Action writeWord(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data);
        mergeReqQ.ports[1].enq(tagged MEM_REQ_WORD addr);

        // To which bank should the word be written?  Break the word index
        // portion of the address into its component parts to find out.
        DDR_WORD_IDX w_idx = unpack(pack(tpl_2(localMemSeparateAddr(addr))));

        // Write word to the proper bank
        writeDataQ[w_idx.bankIdx].enq(tagged WRITE_WORD tuple3(data, unpack(0), w_idx));
    endmethod

    method Action writeLine(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data);
        mergeReqQ.ports[1].enq(tagged MEM_REQ_LINE addr);

        DDR_FULL_LINE d = unpack(pack(data));

        // DRAM mask writes on 0, ignores on 1!
        DDR_FULL_LINE_MASK m = unpack(0);

        // Spread the write request across all banks
        for (Integer b = 0; b < valueOf(FPGA_DDR_BANKS); b = b + 1)
        begin
            writeDataQ[b].enq(tagged WRITE_LINE tuple2(d[b], m[b]));
        end
    endmethod

    method Action writeWordMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data, LOCAL_MEM_WORD_MASK mask);
        mergeReqQ.ports[1].enq(tagged MEM_REQ_WORD addr);

        // To which bank should the word be written?  Break the word index
        // portion of the address into its component parts to find out.
        DDR_WORD_IDX w_idx = unpack(pack(tpl_2(localMemSeparateAddr(addr))));

        // DRAM mask writes on 0, ignores on 1!
        let m = unpack(~pack(mask));

        // Write word to the proper bank
        writeDataQ[w_idx.bankIdx].enq(tagged WRITE_WORD tuple3(data, m, w_idx));
    endmethod

    method Action writeLineMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data, LOCAL_MEM_LINE_MASK mask);
        mergeReqQ.ports[1].enq(tagged MEM_REQ_LINE addr);

        DDR_FULL_LINE d = unpack(pack(data));

        // DRAM mask writes on 0, ignores on 1!  This code depends on the DDR
        // mask being 1 bit per byte.
        DDR_FULL_LINE_MASK m = unpack(~pack(mask));

        // Spread the write request across all banks
        for (Integer b = 0; b < valueOf(FPGA_DDR_BANKS); b = b + 1)
        begin
            writeDataQ[b].enq(tagged WRITE_LINE tuple2(d[b], m[b]));
        end
    endmethod
endmodule
