//
// Copyright (C) 2008 Intel Corporation
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

import FIFOF::*;

`include "physical_platform.bsh"
`include "pci_express_device.bsh"
`include "led_device.bsh"
`include "umf.bsh"

// types
typedef enum
{
    CHANNEL_STATE_idle,
    CHANNEL_STATE_init,
    CHANNEL_STATE_active
}
CHANNEL_STATE
    deriving (Bits, Eq);

typedef enum
{
    READ_STATE_ready,
    READ_STATE_busy_data,
    READ_STATE_busy_f2hHead,
    READ_STATE_busy_h2fTail
}
READ_STATE
    deriving (Bits, Eq);

typedef Bit#(TSub#(`PAGE_OFFSET_BITS, `PCIE_LOG_DMA_DATA_BYTES)) DMA_LINE_INDEX;
typedef Bit#(TSub#(`PCIE_PHYS_ADDR_SIZE, `PAGE_OFFSET_BITS))     DMA_PAGE_INDEX;
typedef Bit#(`PCIE_LOG_DMA_DATA_BYTES)                           DMA_LINE_OFFSET;

// ============== Physical Channel ===============

// interface
interface PHYSICAL_CHANNEL;
    
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
        
endinterface

// module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
        (PHYSICAL_CHANNEL);
    
    // ============= State ==============

    // buffers
    FIFOF#(UMF_CHUNK) readBuffer  <- mkFIFOF();
    FIFOF#(UMF_CHUNK) writeBuffer <- mkFIFOF();

    // states
    Reg#(READ_STATE)    readState    <- mkReg(READ_STATE_ready);
    Reg#(Bit#(4))       initStage    <- mkReg(0);
    Reg#(Bit#(8))       lastIID      <- mkReg(0);
    Reg#(CHANNEL_STATE) channelState <- mkReg(CHANNEL_STATE_idle);

    // pointers: note that these are UMF_CHUNK indices into the buffer
    Reg#(DMA_LINE_INDEX) f2hHead <- mkReg(0);
    Reg#(DMA_LINE_INDEX) f2hTail <- mkReg(0);
    Reg#(DMA_LINE_INDEX) h2fHead <- mkReg(0);
    Reg#(DMA_LINE_INDEX) h2fTail <- mkReg(0);
    
    Reg#(DMA_LINE_INDEX) readChunksRemaining <- mkReg(0);
    Reg#(DMA_LINE_INDEX) writeChunksRemaining <- mkReg(0);
    
    // DMA info
    Reg#(PCIE_PHYSICAL_ADDRESS) f2hBufferBase <- mkReg(0);
    Reg#(PCIE_PHYSICAL_ADDRESS) h2fBufferBase <- mkReg(0);
    
    // dirty/valid bits
    Reg#(Bool) h2fHeadDirty <- mkReg(False);
    Reg#(Bool) h2fTailValid <- mkReg(True);
    Reg#(Bool) f2hHeadValid <- mkReg(True);
    Reg#(Bool) f2hTailDirty <- mkReg(False);

    // =========== Helper Wires =========
    
    DMA_LINE_OFFSET zeroOffset = '0;

    DMA_PAGE_INDEX f2hPageIndex = f2hBufferBase[`PCIE_PHYS_ADDR_SIZE-1 : `PAGE_OFFSET_BITS];
    DMA_PAGE_INDEX h2fPageIndex = h2fBufferBase[`PCIE_PHYS_ADDR_SIZE-1 : `PAGE_OFFSET_BITS];
    
    PCIE_PHYSICAL_ADDRESS f2hHeadAddr = { f2hPageIndex, f2hHead, zeroOffset };
    PCIE_PHYSICAL_ADDRESS f2hTailAddr = { f2hPageIndex, f2hTail, zeroOffset };
    PCIE_PHYSICAL_ADDRESS h2fHeadAddr = { h2fPageIndex, h2fHead, zeroOffset };
    PCIE_PHYSICAL_ADDRESS h2fTailAddr = { h2fPageIndex, h2fTail, zeroOffset };

    DMA_LINE_INDEX f2hHeadPlusOne = (f2hHead == '1) ? 0 : (f2hHead + 1);
    DMA_LINE_INDEX f2hTailPlusOne = (f2hTail == '1) ? 0 : (f2hTail + 1);
    DMA_LINE_INDEX h2fHeadPlusOne = (h2fHead == '1) ? 0 : (h2fHead + 1);
    DMA_LINE_INDEX h2fTailPlusOne = (h2fTail == '1) ? 0 : (h2fTail + 1);

    Bool f2hEmpty = (f2hHead == f2hTail);
    Bool f2hFull  = (f2hHead == f2hTailPlusOne);
    Bool h2fEmpty = (h2fHead == h2fTail);
    Bool h2fFull  = (h2fHead == h2fTailPlusOne);

    Bool channelActive = (channelState == CHANNEL_STATE_active);
    
    // shortcut to drivers
    PCI_EXPRESS_DRIVER pciExpressDriver = drivers.pciExpressDriver;

    // ============== Rules =============
    
    // Control state machine

    // 32-bit control instruction format:
    //
    // field:   [IID]  [RESERVED] [OPCODE]  [INDEX] [IMMEDIATE]
    // bits :   31-24    23-20     19-16     15-8      7-0

    // process a new instruction
    rule process_inst (True);
        
        // read current instruction and decode partially
        Bit#(8) iid    = pciExpressDriver.systemCSR[31:24];
        Bit#(4) opcode = pciExpressDriver.systemCSR[19:16];

        // make sure this is a new instruction
        if (iid != lastIID)
        begin

            lastIID <= iid;

            case (opcode)
                
                // NOP
                `OP_NOP           : noAction;
                
                // start
                `OP_START         : if (channelState == CHANNEL_STATE_idle)
                                        channelState <= CHANNEL_STATE_init;
                
                // invalidate H2F tail
                `OP_INVAL_H2FTAIL : if (channelState == CHANNEL_STATE_active)
                                        h2fTailValid <= False;
                
                // invalidate F2H head
                `OP_INVAL_F2HHEAD : if (channelState == CHANNEL_STATE_active)
                                        f2hHeadValid <= False;

                default: noAction;

            endcase

        end

    endrule

    // === initialization sequence ===

    rule do_channel_init (channelState == CHANNEL_STATE_init);

        case (initStage)
            
            // read in F2H buffer base address (LO)
            0 : pciExpressDriver.commonCSRs.readRequest(`CSR_F2H_ADDR_LO);
        
            // get resp
            1 : begin
                    let resp <- pciExpressDriver.commonCSRs.readResponse();
                    f2hBufferBase[`PCIE_CSR_DATA_SIZE-1 : 0] <= resp;
                end

            // read in F2H buffer base address (HI)
            2 : pciExpressDriver.commonCSRs.readRequest(`CSR_F2H_ADDR_HI);

            // get resp
            3 : begin
                    let resp <- pciExpressDriver.commonCSRs.readResponse();
                    f2hBufferBase[`PCIE_PHYS_ADDR_SIZE-1 : `PCIE_CSR_DATA_SIZE] <= resp;
                end
        
            // read in H2F buffer base address (LO)
            4 : pciExpressDriver.commonCSRs.readRequest(`CSR_H2F_ADDR_LO);
    
            // get resp
            5 : begin
                    let resp <- pciExpressDriver.commonCSRs.readResponse();
                    h2fBufferBase[`PCIE_CSR_DATA_SIZE-1 : 0] <= resp;
                end
    
            // read in H2F buffer base address (HI)
            6 : pciExpressDriver.commonCSRs.readRequest(`CSR_H2F_ADDR_HI);
    
            // get resp
            7 : begin
                    let resp <- pciExpressDriver.commonCSRs.readResponse();
                    h2fBufferBase[`PCIE_PHYS_ADDR_SIZE-1 : `PCIE_CSR_DATA_SIZE] <= resp;
                end
    
            // write indices that we control
            8 : pciExpressDriver.commonCSRs.write(`CSR_F2H_TAIL, zeroExtend(f2hTail));

            // write indices that we control
            9 : pciExpressDriver.commonCSRs.write(`CSR_H2F_HEAD, zeroExtend(h2fHead));

            // give green signal to software
            10: pciExpressDriver.systemCSR <= `SIGNAL_GREEN;
            
            // all set, activate channel
            11: channelState <= CHANNEL_STATE_active;

        endcase
        
        initStage <= initStage + 1;
        
    endrule

    // === pointer updates: READ ===

    // read f2hHead pointer
    rule make_f2hHead_read_req (channelActive && !f2hHeadValid && readState == READ_STATE_ready);

        pciExpressDriver.commonCSRs.readRequest(`CSR_F2H_HEAD);
        readState <= READ_STATE_busy_f2hHead;
        f2hHeadValid <= True; // need this here, not at resp

    endrule

    // accept response for f2hHead request
    rule recv_f2hHead_read_resp (channelActive && readState == READ_STATE_busy_f2hHead);
        
        PCIE_CSR_DATA data <- pciExpressDriver.commonCSRs.readResponse();
        f2hHead <= truncate(data);
        readState <= READ_STATE_ready;
        
    endrule

    // read h2fTail pointer
    rule make_h2fTail_read_req (channelActive && !h2fTailValid && readState == READ_STATE_ready);

        pciExpressDriver.commonCSRs.readRequest(`CSR_H2F_TAIL);
        readState <= READ_STATE_busy_h2fTail;
        h2fTailValid <= True; // need this here, not at resp

    endrule

    // accept response for h2fTail request
    rule recv_h2fTail_read_resp (channelActive && readState == READ_STATE_busy_h2fTail);

        PCIE_CSR_DATA data <- pciExpressDriver.commonCSRs.readResponse();
        h2fTail <= truncate(data);
        readState <= READ_STATE_ready;

    endrule

    // === pointer updates: WRITE ===

    // NOTE: all write rules are gated by READ_STATE_ready (obsolete. debug only. FIXME)

    // write f2hTail state
    rule make_f2hTail_write_req (channelActive && f2hTailDirty && readState == READ_STATE_ready);

        pciExpressDriver.commonCSRs.write(`CSR_F2H_TAIL, zeroExtend(f2hTail));
        f2hTailDirty <= False;

    endrule

    // write h2fHead state
    rule make_h2fHead_write_req (channelActive && h2fHeadDirty && readState == READ_STATE_ready);
        
        pciExpressDriver.commonCSRs.write(`CSR_H2F_HEAD, zeroExtend(h2fHead));
        h2fHeadDirty <= False;
        
    endrule

    // === data ===
    
    //
    // start DMA read request. If the H2F buffer's head <= tail, then we initiate a
    // transfer for (tail - head) bytes. If head > tail, then we read from head till
    // the end of the H2F buffer (since DMA only works in contiguous segments). Note
    // that our internal read FIFO may or may not have enough space to hold the entire
    // DMA segment. This should be okay because there's FIFO-style flow control
    // everywhere, so the upstream buffers (in the VHDL code) will simply block until
    // our FIFO clears. We could, however, have a deadlock. Ignore this for now.
    //

    // send data read request
    rule make_data_read_req (channelActive && !h2fEmpty && readChunksRemaining == 0);
        
        // how many chunks should I read?
        DMA_LINE_INDEX data_chunks;
        if (h2fHead < h2fTail)
        begin
            data_chunks = h2fHead - h2fTail;
        end
        else
        begin
            data_chunks = ('1 - h2fHead) + 1;
        end
        
        // each chunk is placed uniquely inside one DMA word
        PCIE_LENGTH data_bytes = zeroExtend(data_chunks) << `PCIE_LOG_DMA_DATA_BYTES;
        
        pciExpressDriver.dmaDriver.startRead(h2fHeadAddr, data_bytes);
        
        readChunksRemaining <= data_chunks;
        
    endrule

    // suck in DMA read data
    rule recv_read_resp (channelActive && readChunksRemaining != 0);
        
        PCIE_DMA_DATA data <- pciExpressDriver.dmaDriver.readData();
        
        // chop off MSBits and place data in read buffer
        readBuffer.enq(truncate(data));        

        // advance head
        h2fHead <= h2fHeadPlusOne;
        h2fHeadDirty <= True;
        
        readChunksRemaining <= readChunksRemaining - 1;
                
    endrule

    //
    // writes are handled very differently from reads. We start a DMA write transaction
    // everytime the F2H tail pointer is 0 (i.e., the beginning of the page in
    // memory). Then, we actually send data as and when it becomes available in
    // our internal buffer, subject to availability of slots in the virtual
    // circular FIFO (i.e. by looking at the head and tail pointers). I'm not 100%
    // sure how the DMA controller works, but this protocol relies on the assumption
    // that the controller doesn't lock down the PCIe bus once a transaction is
    // initiated.
    //

    // initiate DMA write transaction
    rule start_data_write (channelActive && f2hTail == 0 && writeChunksRemaining == 0);
        
        // I intend to send one full page of data (over time)
        PCIE_LENGTH data_bytes = '0;
        data_bytes[`PAGE_OFFSET_BITS] = 1;
        
        pciExpressDriver.dmaDriver.startWrite(f2hTailAddr, data_bytes);
 
        // setup internal state for the remainder of the transfer
        writeChunksRemaining <= truncate(data_bytes >> `PCIE_LOG_DMA_DATA_BYTES);

    endrule
    
    // send out DMA write data
    rule do_data_write(channelActive && !f2hFull && writeChunksRemaining != 0);
        
        UMF_CHUNK data = writeBuffer.first();
        writeBuffer.deq();
        
        pciExpressDriver.dmaDriver.writeData(zeroExtend(data));

        f2hTail <= f2hTailPlusOne;
        f2hTailDirty <= True;
        
        writeChunksRemaining <= writeChunksRemaining - 1;
        
    endrule
    
    // ============= Methods =============

    // read
    method ActionValue#(UMF_CHUNK) read() if (channelActive);
        
        UMF_CHUNK data = readBuffer.first();
        readBuffer.deq();
        return data;
        
    endmethod

    // write
    method Action write(UMF_CHUNK data) if (channelActive);
        
        writeBuffer.enq(data);
        
    endmethod

endmodule
