//
// Copyright (C) 2012 Intel Corporation
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

import FIFO::*;
import FIFOF::*;
import Vector::*;
import List::*;


`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/ddr_sdram_device.bsh"
`include "awb/provides/fpga_components.bsh"
`include "awb/provides/physical_platform_utils.bsh"

//
// Data sizes are fixed by the VHDL DRAM controller and the hardware and are
// not flexible.
//

typedef `DRAM_NUM_BANKS FPGA_DDR_BANKS;
typedef `DRAM_MAX_OUTSTANDING_READS FPGA_DDR_MAX_OUTSTANDING_READS;

// The smallest addressable word:
typedef `DRAM_WORD_WIDTH FPGA_DDR_WORD_SZ;
typedef Bit#(FPGA_DDR_WORD_SZ) FPGA_DDR_WORD;

// The DRAM controller uses both clock edges to pass data, which appears to
// be 2 words per cycle.  Addresses are little endian, so the low address
// goes in the low bits.  Most of the interfaces in this module pass:
typedef `DRAM_BEAT_WIDTH FPGA_DDR_DUALEDGE_BEAT_SZ;
typedef Bit#(FPGA_DDR_DUALEDGE_BEAT_SZ) FPGA_DDR_DUALEDGE_BEAT;

typedef TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, FPGA_DDR_WORD_SZ) FPGA_DDR_WORDS_PER_BEAT;
typedef TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, 8) FPGA_DDR_BYTES_PER_BEAT;
typedef TDiv#(FPGA_DDR_WORD_SZ, 8) FPGA_DDR_BYTES_PER_WORD;

// The DRAM controller reads and writes multiple dual-edge data values for
// a single request.  The number of dual-edge data values per request is:
typedef `DRAM_MIN_BURST FPGA_DDR_BURST_LENGTH;

// Each byte in a write may be disabled for writes using a bit mask.
// !!! NOTE: to conform to the controller, a mask bit is 0 to request a write !!!
typedef Bit#(FPGA_DDR_BYTES_PER_WORD) FPGA_DDR_WORD_MASK;
typedef Bit#(FPGA_DDR_BYTES_PER_BEAT) FPGA_DDR_DUALEDGE_BEAT_MASK;

// Capacity of the memory (addressing FPGA_DDR_WORDs):
typedef `DRAM_ADDR_BITS FPGA_DDR_ADDRESS_SZ;
typedef Bit#(FPGA_DDR_ADDRESS_SZ) FPGA_DDR_ADDRESS;


//
// DDR_DRIVER
//
// The driver interface could be expressed as a simple BRAM style interface
// with write, readReq and readResp.  It is not.  Instead, the driver interface
// corresponds to the DDR controller interface, passing dual-edge data
// sized objects.  For some designs this will make the logic smaller without
// a performance penalty.
//
interface DDR_DRIVER;
    // Read request/response pair.  NOTE: every read request generates
    // FPGA_DDR_BURST_LENGTH responses.  If the address is not aligned to
    // the full response the DRAM controller rotates the response so the
    // requested address is returned in the low bits of the first response.
    method Action readReq(FPGA_DDR_ADDRESS addr);
    method ActionValue#(FPGA_DDR_DUALEDGE_BEAT) readRsp();

    // Write requests and data are separate since the data will ultimately
    // be streamed to the DDR controller.
    method Action writeReq(FPGA_DDR_ADDRESS addr);

    // Write data corresponding to a write request.  Call writeData
    // FPGA_DDR_BURST_LENGTH times for every write request.  The order of
    // writeReq() and writeData() calls are not important.
    method Action writeData(FPGA_DDR_DUALEDGE_BEAT data, FPGA_DDR_DUALEDGE_BEAT_MASK mask);

    method List#(Tuple2#(String, Bool)) debugScanState();

`ifndef DRAM_DEBUG_Z
    // Methods enabled only for debugging the controller:

    // Get status.  Should never block.
    method Bit#(64) statusCheck();
    // Set the maximum number of outstanding reads permitted.  Useful for
    // calibrating sync buffer sizes.
    method Action setMaxReads(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) maxReads);
`endif
endinterface


//
// DDR_WIRES interface is empty when using BRAM.  There is nothing to connect.
//
interface DDR_WIRES;
endinterface


//
// DDR_DEVICE --
//     By convention a device is both a driver and a wires interface.
//
interface DDR_DEVICE;
    interface Vector#(FPGA_DDR_BANKS, DDR_DRIVER) driver;
    interface DDR_WIRES  wires;
endinterface


//
// A DRAM Request is either a read or write with an address
//
typedef union tagged
{
    FPGA_DDR_ADDRESS DRAM_READ;
    FPGA_DDR_ADDRESS DRAM_WRITE;
}
FPGA_DDR_REQUEST
    deriving (Bits, Eq);


//
// mkDDRDevice
//
module mkDDRDevice
    // interface:
    (DDR_DEVICE);

    Vector#(FPGA_DDR_BANKS, DDR_DRIVER) banks <- replicateM(mkDDRBank);

    interface driver = banks;

    interface DDR_WIRES wires;
        // Empty
    endinterface
endmodule
    

//
// mkDDRBank --
//   One simulated DDR bank.  This code does more than is required to be
//   accurate.  It seeks to emulate some of the behavior and timing of
//   a real DDR memory.
//
module mkDDRBank
    // Interface:
    (DDR_DRIVER)
    provisos (Alias#(t_BURST_IDX, Bit#(TLog#(TAdd#(FPGA_DDR_BURST_LENGTH, 1)))),
              // Index of a word within a beat aligned address
              Alias#(t_WORD_IDX, Bit#(TLog#(FPGA_DDR_WORDS_PER_BEAT))),

              Bits#(t_BURST_IDX, t_BURST_IDX_SZ),
              Bits#(t_WORD_IDX, t_WORD_IDX_SZ),

              // Address of a beat-aligned address
              Alias#(t_BEAT_ADDR, Bit#(TSub#(FPGA_DDR_ADDRESS_SZ,
                                             t_WORD_IDX_SZ))));

    //
    // The memory is organized as a vector of byte-sized RAMs in order to
    // support byte-granularity write masks without having to do a read-modify-
    // write.
    //
    Vector#(FPGA_DDR_BYTES_PER_BEAT, MEMORY_IFC#(t_BEAT_ADDR, Bit#(8))) memory <-
        replicateM(mkBRAM());

    t_BURST_IDX burst_idx_last = fromInteger(valueOf(TSub#(FPGA_DDR_BURST_LENGTH, 1)));

    // Incoming requests
    MERGE_FIFOF#(2, FPGA_DDR_REQUEST) mergeReqQ <- mkMergeFIFOF();
    FIFOF#(Tuple2#(FPGA_DDR_DUALEDGE_BEAT, FPGA_DDR_DUALEDGE_BEAT_MASK)) writeDataQ <-
        mkFIFOF();
    
    // Keep track of the number of reads in flight
    COUNTER#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) nInflightReads <- mkLCounter(0);


    //
    // Break an address into a beat address and word index.
    //
    function t_BEAT_ADDR beatAddr(FPGA_DDR_ADDRESS addr);
        Tuple2#(t_BEAT_ADDR, t_WORD_IDX) a = unpack(addr);
        return tpl_1(a);
    endfunction

    function t_WORD_IDX wordIdx(FPGA_DDR_ADDRESS addr);
        Tuple2#(t_BEAT_ADDR, t_WORD_IDX) a = unpack(addr);
        return tpl_2(a);
    endfunction


    // ====================================================================
    //
    // Rules
    //
    // ====================================================================

    Reg#(t_BURST_IDX) writeBurstCnt <- mkReg(0);

    rule doWrite (mergeReqQ.first() matches tagged DRAM_WRITE .addr);
        match {.data, .mask} = writeDataQ.first();
        writeDataQ.deq();

        let beat_addr = beatAddr(addr) + zeroExtend(writeBurstCnt);
        let word_idx = wordIdx(addr);
        
        // Represent the beat as a vector of bytes.
        Vector#(FPGA_DDR_BYTES_PER_BEAT, Bit#(8)) data_b = unpack(data);

        // Rotate write into position based on word index as I think
        // DDR controllers do.  Word indexing is not well tested!
        // Hack to avoid overflow:
        Integer bytes_per_word =
            (valueOf(FPGA_DDR_BYTES_PER_BEAT) == valueOf(FPGA_DDR_BYTES_PER_WORD)) ?
                 0 : valueOf(FPGA_DDR_BYTES_PER_WORD);
        UInt#(TLog#(FPGA_DDR_BYTES_PER_BEAT)) rot_amt =
           zeroExtend(unpack(word_idx)) * fromInteger(bytes_per_word);
        data_b = rotateBy(data_b, rot_amt);
        mask = rotateBitsBy(mask, rot_amt);

        // Track write burst count
        if (writeBurstCnt == burst_idx_last)
        begin
            // Done with this request
            writeBurstCnt <= 0;
            mergeReqQ.deq();
        end
        else
        begin
            writeBurstCnt <= writeBurstCnt + 1;
        end

        for (Integer b = 0; b < valueOf(FPGA_DDR_BYTES_PER_BEAT); b = b + 1)
        begin
            // Like DRAM, the write-enable mask is active low.
            if (mask[b] == 0)
            begin
                memory[b].write(beat_addr, data_b[b]);
            end
        end
    endrule


    Reg#(t_BURST_IDX) readBurstCnt <- mkReg(0);
    FIFO#(Tuple2#(t_WORD_IDX, Bool)) inflightReadQ <- mkFIFO();


    //
    // readRespQ is the FIFO between BRAM reads and the response.  Under normal
    // circumstances it is a standard FIFO with one cycle latency and enough
    // buffering to hold all responses allowed to be in flight.  When
    // DRAM_READ_LATENCY is non-zero it is a delay FIFO, forcing clients to
    // wait longer for responses.  This may be useful for simulating true
    // DDR SDRAM behavior in Bluesim.
    //

    NumTypeParam#(`DRAM_READ_LATENCY) extraLatency = ?;

    FIFOF#(Tuple2#(FPGA_DDR_DUALEDGE_BEAT, Bool)) readRespQ <-
        ((`DRAM_READ_LATENCY == 0) ?
         mkSizedFIFOF(valueOf(TMul#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_MAX_OUTSTANDING_READS))) :
         mkDelayFIFOF(extraLatency));


    rule doReadReq (mergeReqQ.first() matches tagged DRAM_READ .addr);
        let beat_addr = beatAddr(addr) + zeroExtend(readBurstCnt);
        let word_idx = wordIdx(addr);
        
        for (Integer b = 0; b < valueOf(FPGA_DDR_BYTES_PER_BEAT); b = b + 1)
        begin
            // Like DRAM, the write-enable mask is active low.
            memory[b].readReq(beat_addr);
        end

        // Track read burst count
        Bool is_last_in_burst = (readBurstCnt == burst_idx_last);
        if (is_last_in_burst)
        begin
            // Done with this request
            readBurstCnt <= 0;
            mergeReqQ.deq();
        end
        else
        begin
            readBurstCnt <= readBurstCnt + 1;
        end

        inflightReadQ.enq(tuple2(word_idx, is_last_in_burst));
    endrule


    rule doReadResp (True);
        match {.word_idx, .is_last_in_burst} = inflightReadQ.first();
        inflightReadQ.deq();

        // Represent the beat as a vector of bytes.
        Vector#(FPGA_DDR_BYTES_PER_BEAT, Bit#(8)) data_b = newVector();
        for (Integer b = 0; b < valueOf(FPGA_DDR_BYTES_PER_BEAT); b = b + 1)
        begin
            data_b[b] <- memory[b].readRsp();
        end

        // Rotate read into position based on word index as I think
        // DDR controllers do.  Word indexing is not well tested!
        // Rotate is the oposite directino of write rotation.
        Integer bytes_per_word =
            (valueOf(FPGA_DDR_BYTES_PER_BEAT) == valueOf(FPGA_DDR_BYTES_PER_WORD)) ?
                 0 : valueOf(FPGA_DDR_BYTES_PER_WORD);
        UInt#(TLog#(FPGA_DDR_BYTES_PER_BEAT)) rot_amt =
           zeroExtend(unpack(word_idx)) * fromInteger(bytes_per_word);
        data_b = reverse(rotateBy(reverse(data_b), rot_amt));

        readRespQ.enq(tuple2(unpack(pack(data_b)), is_last_in_burst));
    endrule


`ifndef DRAM_DEBUG_Z
    // Useful for calibrating the optimal size of DRAM_MAX_OUTSTANDING_READS
    Reg#(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1)))) calibrateMaxReads <-
        mkReg(`DRAM_MAX_OUTSTANDING_READS);
`endif

`ifndef DRAM_DEBUG_Z

    // statusCheck unimplemented...
    method Bit#(64) statusCheck();
        return 0;
    endmethod

    //
    // setMaxReads --
    //     Set a maximum number of outstanding reads that may be lower than
    //     the available buffer size.  Useful for building one time and
    //     finding the optimal buffer size.
    //
    method Action setMaxReads(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) maxReads);
        calibrateMaxReads <= maxReads;
    endmethod
`endif

    method Action readReq(FPGA_DDR_ADDRESS addr) if (
`ifndef DRAM_DEBUG_Z
                                                     (nInflightReads.value() < calibrateMaxReads) &&
`endif
                                                     (nInflightReads.value() < `DRAM_MAX_OUTSTANDING_READS));
        mergeReqQ.ports[0].enq(tagged DRAM_READ addr);
        nInflightReads.up();
    endmethod

    method ActionValue#(FPGA_DDR_DUALEDGE_BEAT) readRsp();
        match {.data, .is_last_in_burst} = readRespQ.first();
        readRespQ.deq();

        if (is_last_in_burst)
        begin
            nInflightReads.down();
        end

        return data;
    endmethod


    method Action writeReq(FPGA_DDR_ADDRESS addr);
        mergeReqQ.ports[1].enq(tagged DRAM_WRITE addr);
    endmethod

    method Action writeData(FPGA_DDR_DUALEDGE_BEAT data, FPGA_DDR_DUALEDGE_BEAT_MASK mask);
        writeDataQ.enq(tuple2(data, mask));
    endmethod

    method List#(Tuple2#(String, Bool)) debugScanState();
        return List::nil;
    endmethod
endmodule
