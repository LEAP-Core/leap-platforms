import FIFOF::*;

`include "hasim_common.bsh"
`include "physical_platform.bsh"
`include "umf.bsh"

// types
typdedef enum
{
    READ_STATE_ready,
    READ_STATE_busy_data,
    READ_STATE_busy_f2hHead,
    READ_STATE_busy_h2fTail
}
READ_STATE
    deriving (Bits, Eq);

// defines
`define ARBITER_COUNTER_BITS    4

`define READ_ARBITER_F2H_HEAD   0
`define READ_ARBITER_H2F_TAIL   1
`define READ_ARBITER_MAX        15

`define WRITE_ARBITER_F2H_TAIL  0
`define WRITE_ARBITER_H2F_HEAD  1
`define WRITE_ARBITER_MAX       15

// ============== Physical Channel ===============

// interface
interface PhysicalChannel;
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
endinterface

// module
module mkPhysicalChannel
    // interface
        (PhysicalChannel);

    // ============= State ==============

    // buffers
    FIFOF#(PCIE_CSR_Data) readBuffer  <- mkFIFOF();
    FIFOF#(PCIE_CSR_Data) writeBuffer <- mkFIFOF();

    // states
    Reg#(READ_STATE)  readState <- mkReg(READ_STATE_ready);

    // pointers
    Reg#(PCIE_CSR_Index) f2hHead <- mkReg(`CSR_F2H_BUF_START);
    Reg#(PCIE_CSR_Index) f2hTail <- mkReg(`CSR_F2H_BUF_START);
    Reg#(PCIE_CSR_Index) h2fHead <- mkReg(`CSR_H2F_BUF_START);
    Reg#(PCIE_CSR_Index) h2fTail <- mkReg(`CSR_H2F_BUF_START);

    // arbiters
    Reg#(Bit#(`ARBITER_COUNTER_BITS)) readArbiter  <- mkReg(0);
    Reg#(Bit#(`ARBITER_COUNTER_BITS)) writeArbiter <- mkReg(0);

    // =========== Helper Wires =========
    PCIE_CSR_Index f2hHeadPlusOne = (f2hHead == `CSR_F2H_BUF_END) ? `CSR_F2H_BUF_START : (f2hHead + 1);
    PCIE_CSR_Index f2hTailPlusOne = (f2hTail == `CSR_F2H_BUF_END) ? `CSR_F2H_BUF_START : (f2hTail + 1);
    PCIE_CSR_Index h2fHeadPlusOne = (h2fHead == `CSR_H2F_BUF_END) ? `CSR_H2F_BUF_START : (h2fHead + 1);
    PCIE_CSR_Index h2fTailPlusOne = (h2fTail == `CSR_H2F_BUF_END) ? `CSR_H2F_BUF_START : (h2fTail + 1);

    Bool f2hEmpty = (f2hHead == f2hTail);
    Bool f2hFull  = (f2hHead == f2hTailPlusOne);
    Bool h2fEmpty = (h2fHead == h2fTail);
    Bool h2fFull  = (h2fHead == h2fTailPlusOne);

    // ============== Rules =============

    // cycle arbiters
    rule cycle_arbiters(True);
        if (readArbiter == `READ_ARBITER_MAX)
            readArbiter <= 0;
        else
            readArbiter <= readArbiter + 1;

        if (writeArbiter == `WRITE_ARBITER_MAX)
            writeArbiter <= 0;
        else
            writeArbiter <= writeArbiter + 1;
    endrule

    // === pointer updates

    // read f2hHead pointer
    rule make_f2hHead_read_req(readState == READ_STATE_ready &&
                               readArbiter == `READ_ARBITER_F2H_HEAD);
        csr_read_req(`CSR_F2H_HEAD);
        readState <= READ_STATE_busy_f2hHead;
    endrule

    // accept response for f2hHead request
    rule recv_f2hHead_read_resp(readState == READ_STATE_busy_f2hHead);
        PCIE_CSR_Data data <- csr_read_resp();
        f2hHead <= truncate(data);  // assume indexbits < databits
        readState <= READ_STATE_ready;
    endrule

    // read h2fTail pointer
    rule make_h2fTail_read_req(readState == READ_STATE_ready &&
                               readArbiter == `READ_ARBITER_H2F_TAIL);
        csr_read_req(`CSR_H2F_TAIL);
        readState <= READ_STATE_busy_h2fTail;
    endrule

    // accept response for h2fTail request
    rule recv_h2fTail_read_resp(readState == READ_STATE_busy_h2fTail);
        PCIE_CSR_Data data <- csr_read_resp();
        h2fTail <= truncate(data);
        readState <= READ_STATE_ready;
    endrule

    // write f2hTail state TODO: write only if dirty
    rule make_f2hTail_write_req(writeArbiter == `WRITE_ARBITER_F2H_TAIL);
        csr_write(`CSR_F2H_TAIL, zeroExtend(f2hTail));
    endrule

    // write h2fHead state TODO: write only if dirty
    rule make_h2fHead_write_req(writeState == WRITE_STATE_ready &&
                                writeArbiter == `WRITE_ARBITER_H2F_HEAD);
        csr_write(`CSR_H2F_HEAD, zeroExtend(h2fHead));
    endrule

    // === data

    // send data read request
    rule make_data_read_req(readState == READ_STATE_ready         &&
                            h2fEmpty == False                     &&
                            readArbiter != `READ_ARBITER_F2H_HEAD &&
                            readArbiter != `READ_ARBITER_H2F_TAIL);
        csr_read_req(h2fHead);
        h2fHead <= h2fHeadPlusOne;
        readState <= READ_STATE_busy_data;
    endrule

    // receive read response from CSR
    rule recv_read_resp(readState == READ_STATE_busy_data);
        PCIE_CSR_Data data <- csr_read_resp();
        readBuffer.enq(data);
        readState <= READ_STATE_ready;
    endrule

    // send data write request
    rule make_data_write_req(f2hFull == False                        &&
                             writeArbiter != `WRITE_ARBITER_F2H_TAIL &&
                             writeArbiter != `WRITE_ARBITER_H2F_HEAD);
        PCIE_CSR_Data data <- writeBuffer.deq();
        csr_write(f2hTail, data);
        f2hTail <= f2hTailPlusOne;
    endrule

    // ============= Methods =============

    // read
    method ActionValue#(UMF_CHUNK) read();
        PCIE_CSR_Data data <- readBuffer.deq();
        UMF_CHUNK chunk = truncate(data);
        return chunk;
    endmethod

    // write
    method Action write(UMF_CHUNK chunk);
        PCIE_CSR_Data data = zeroExtend(chunk);
        writeBuffer.enq(data);
    endrule

endmodule
