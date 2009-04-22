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

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;

`include "asim/provides/physical_platform.bsh"
`include "asim/provides/ddr2_sdram_device.bsh"


//
// The DRAM driver breaks reads and writes into multi-cycle bursts.
// DRAM_FULL_LINE is the full data packet and should correspond exactly
// to a LOCAL_MEM_LINE.
//
typedef Vector#(FPGA_DRAM_BURST_LENGTH, FPGA_DRAM_DUALEDGE_DATA) DRAM_FULL_LINE;
typedef Vector#(FPGA_DRAM_BURST_LENGTH, FPGA_DRAM_DUALEDGE_DATA_MASK) DRAM_FULL_LINE_MASK;


typedef struct
{
    DRAM_FULL_LINE data;
    DRAM_FULL_LINE_MASK mask;
}
LOCAL_MEM_WRITE_REQ
    deriving (Bits, Eq);


module mkLocalMem#(PHYSICAL_DRIVERS drivers)
    // interface:
    (LOCAL_MEM);

    // Get a handle to the DDR2 DRAM Controller
    DDR2_SDRAM_DRIVER dramDriver = drivers.ddr2SDRAMDriver;

    // Record read requests (either full line or a word index)
    FIFOF#(Maybe#(LOCAL_MEM_WORD_IDX)) readReqQ <- mkSizedFIFOF(16);

    //
    // Reads
    //

    FIFO#(LOCAL_MEM_LINE) readQ <- mkFIFO();
    Reg#(DRAM_FULL_LINE) nextReadLine <- mkRegU();
    Reg#(Bit#(TLog#(TAdd#(FPGA_DRAM_BURST_LENGTH, 1)))) readStage <- mkReg(0);

    //
    // doReads --
    //     Reads arrive as a burst of data over multiple cycles.  Collect them
    //     until a full line arrives and then pass the line along.
    //
    rule doReads (True);
        let d <- dramDriver.readRsp();
       
        if (readStage != fromInteger(valueOf(TSub#(FPGA_DRAM_BURST_LENGTH, 1))))
        begin
            // Not the last stage.  Accumulate data.
            nextReadLine[readStage] <= d;
            readStage <= readStage + 1;
        end
        else
        begin
            // Last stage in the burst.  Collect and forward the line's data.
            DRAM_FULL_LINE line = nextReadLine;
            line[readStage] = d;
            
            readQ.enq(pack(line));
            readStage <= 0;
        end
    endrule


    //
    // Writes
    //

    FIFOF#(LOCAL_MEM_WRITE_REQ) writeDataQ <- mkBypassFIFOF();
    Reg#(Bit#(TLog#(TAdd#(FPGA_DRAM_BURST_LENGTH, 1)))) writeStage <- mkReg(0);

    //
    // forwardWriteData --
    //     Writes are bursts of data and an address.  Process a request until
    //     all data is passed to the driver and then dequeue the request.
    //
    rule forwardWriteData (True);
        let req = writeDataQ.first();
        
        // Data for this stage in the burst
        dramDriver.writeData(req.data[writeStage], req.mask[writeStage]);

        // Last stage in the burst?
        if (writeStage == fromInteger(valueOf(TSub#(FPGA_DRAM_BURST_LENGTH, 1))))
        begin
            writeDataQ.deq();
            writeStage <= 0;
        end
        else
        begin
            writeStage <= writeStage + 1;
        end
    endrule


    //
    // Methods
    //

    //
    // Read request methods are predicated by writeDataQ.notFull()
    // to ensure synchronization with writes.
    //

    method Action readWordReq(LOCAL_MEM_ADDR addr) if (writeDataQ.notFull());
        match {.l_addr, .w_idx} = localMemBurstAddr(addr);
        dramDriver.readReq(localMemLineAddrToAddr(l_addr));

        // Note word read.
        readReqQ.enq(tagged Valid w_idx);
    endmethod

    method ActionValue#(LOCAL_MEM_WORD) readWordRsp() if (readReqQ.first() matches tagged Valid .w_idx);
        Vector#(LOCAL_MEM_WORDS_PER_LINE, LOCAL_MEM_WORD) d = unpack(readQ.first());
        readQ.deq();
        readReqQ.deq();

        return d[w_idx];
    endmethod


    method Action readLineReq(LOCAL_MEM_ADDR addr) if (writeDataQ.notFull());
        dramDriver.readReq(addr);

        // Note full line read.
        readReqQ.enq(tagged Invalid);
    endmethod

    method ActionValue#(LOCAL_MEM_LINE) readLineRsp() if (readReqQ.first() matches tagged Invalid);
        let d = readQ.first();
        readQ.deq();
        readReqQ.deq();
    
        return d;
    endmethod

    //
    // Read request methods are predicated by readReqQ.notFull()
    // to ensure synchronization with writes.
    //

    method Action writeWord(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data) if (readReqQ.notFull());
        match {.l_addr, .w_idx} = localMemBurstAddr(addr);
    
        // Build a mask to enable writing just the requested word.
        // There may be more than one mask bit per word, hence this vector:
        Vector#(LOCAL_MEM_WORDS_PER_LINE, Bit#(TDiv#(SizeOf#(DRAM_FULL_LINE_MASK), LOCAL_MEM_WORDS_PER_LINE))) mask = newVector();
        Vector#(LOCAL_MEM_WORDS_PER_LINE, LOCAL_MEM_WORD) line_data = newVector();
        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            // 0 means write the data!
            mask[w] = (fromInteger(w) == w_idx) ? 0 : -1;

            // Just replicate the word through the line.  Only one
            // will be written.
            line_data[w] = data;
        end

        dramDriver.writeReq(localMemLineAddrToAddr(l_addr));
        writeDataQ.enq(LOCAL_MEM_WRITE_REQ { data: unpack(pack(line_data)), mask: unpack(pack(mask)) });
    endmethod

    method Action writeLine(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data) if (readReqQ.notFull());
        dramDriver.writeReq(addr);
        writeDataQ.enq(LOCAL_MEM_WRITE_REQ { data: unpack(data), mask: unpack(0) });
    endmethod

    method Action writeLineMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data, LOCAL_MEM_LINE_MASK mask) if (readReqQ.notFull());
        dramDriver.writeReq(addr);

        // Convert incoming mask with 1 bit per word to DRAM mask.  Incoming
        // mask indicates write with 1.  Outgoing mask indicates write with 0.
        Vector#(LOCAL_MEM_WORDS_PER_LINE, Bit#(TDiv#(SizeOf#(DRAM_FULL_LINE_MASK), LOCAL_MEM_WORDS_PER_LINE))) ddr_mask = newVector();
        for (Integer w = 0; w < valueOf(LOCAL_MEM_WORDS_PER_LINE); w = w + 1)
        begin
            // 0 means write the data!
            ddr_mask[w] = mask[w] ? 0 : -1;
        end

        writeDataQ.enq(LOCAL_MEM_WRITE_REQ { data: unpack(data), mask: unpack(pack(ddr_mask)) });
    endmethod
endmodule