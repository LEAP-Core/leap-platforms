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
    FIFOF#(PCIE_CSR_DATA) readBuffer  <- mkFIFOF();
    FIFOF#(PCIE_CSR_DATA) writeBuffer <- mkFIFOF();

    // states
    Reg#(READ_STATE)    readState    <- mkReg(READ_STATE_ready);
    Reg#(Bit#(4))       initStage    <- mkReg(0);
    Reg#(Bit#(8))       lastIID      <- mkReg(0);
    Reg#(CHANNEL_STATE) channelState <- mkReg(CHANNEL_STATE_idle);

    // pointers
    Reg#(PCIE_CSR_INDEX) f2hHead <- mkReg(`CSR_F2H_BUF_START);
    Reg#(PCIE_CSR_INDEX) f2hTail <- mkReg(`CSR_F2H_BUF_START);
    Reg#(PCIE_CSR_INDEX) h2fHead <- mkReg(`CSR_H2F_BUF_START);
    Reg#(PCIE_CSR_INDEX) h2fTail <- mkReg(`CSR_H2F_BUF_START);

    // dirty/valid bits
    Reg#(Bool) h2fHeadDirty <- mkReg(False);
    Reg#(Bool) h2fTailValid <- mkReg(True);
    Reg#(Bool) f2hHeadValid <- mkReg(True);
    Reg#(Bool) f2hTailDirty <- mkReg(False);

    // =========== Helper Wires =========

    PCIE_CSR_INDEX f2hHeadPlusOne = (f2hHead == `CSR_F2H_BUF_END) ? `CSR_F2H_BUF_START : (f2hHead + 1);
    PCIE_CSR_INDEX f2hTailPlusOne = (f2hTail == `CSR_F2H_BUF_END) ? `CSR_F2H_BUF_START : (f2hTail + 1);
    PCIE_CSR_INDEX h2fHeadPlusOne = (h2fHead == `CSR_H2F_BUF_END) ? `CSR_H2F_BUF_START : (h2fHead + 1);
    PCIE_CSR_INDEX h2fTailPlusOne = (h2fTail == `CSR_H2F_BUF_END) ? `CSR_H2F_BUF_START : (h2fTail + 1);

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
    rule process_inst (channelState != CHANNEL_STATE_init);
        
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
            
            // nothing (FIXME)
            0: noAction;

            // write indices that we control
            1: pciExpressDriver.commonCSRs.write(`CSR_F2H_TAIL, zeroExtend(f2hTail));
            
            // write indices that we control
            2: pciExpressDriver.commonCSRs.write(`CSR_H2F_HEAD, zeroExtend(h2fHead));
            
            // give green signal to software
            3: pciExpressDriver.systemCSR <= `SIGNAL_GREEN;

            // all set, activate channel
            4: channelState <= CHANNEL_STATE_active;

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

    // send data read request
    rule make_data_read_req (channelActive && !h2fEmpty && readState == READ_STATE_ready);

        pciExpressDriver.commonCSRs.readRequest(h2fHead);
        readState <= READ_STATE_busy_data;

    endrule

    // receive read response from CSR
    rule recv_read_resp (channelActive && readState == READ_STATE_busy_data);
        
        PCIE_CSR_DATA data <- pciExpressDriver.commonCSRs.readResponse();
        readBuffer.enq(data);

        // advance head
        h2fHead <= h2fHeadPlusOne;
        h2fHeadDirty <= True;

        readState <= READ_STATE_ready;
        
    endrule

    // send data write request
    rule make_data_write_req (channelActive && !f2hFull && readState == READ_STATE_ready);
        
        PCIE_CSR_DATA data = writeBuffer.first();
        writeBuffer.deq();
        pciExpressDriver.commonCSRs.write(f2hTail, data);

        // advance tail
        f2hTail <= f2hTailPlusOne;
        f2hTailDirty <= True;
        
    endrule

    // ============= Methods =============

    // read
    method ActionValue#(UMF_CHUNK) read() if (channelActive);
        
        PCIE_CSR_DATA data = readBuffer.first();
        readBuffer.deq();
        UMF_CHUNK chunk = truncate(data);
        return chunk;
        
    endmethod

    // write
    method Action write(UMF_CHUNK chunk) if (channelActive);
        
        PCIE_CSR_DATA data = zeroExtend(chunk);
        writeBuffer.enq(data);
        
    endmethod

endmodule
