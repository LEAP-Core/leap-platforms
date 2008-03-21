import FIFOF::*;

`include "hasim_common.bsh"
`include "physical_platform.bsh"
`include "pci_express_device.bsh"
`include "led_device.bsh"
`include "umf.bsh"

// === DEBUG machine state ===
typedef enum
{
    STATE_ready,
    STATE_doRead,
    STATE_getResponse, 
    STATE_doWrite,
    STATE_doSysWrite,
    STATE_doSeqWrite
}
STATE
    deriving (Bits, Eq);

typedef Bit#(`PCIE_CSR_DATA_SIZE) CSR_DATA;
typedef Bit#(`PCIE_CSR_IDX_SIZE)  CSR_INDEX;

// ============== Physical Channel ===============

// interface
interface PhysicalChannel;
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
endinterface

// module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
        (PhysicalChannel);

    // ============= State ==============

    // states
    Reg#(STATE) state <- mkReg(STATE_ready);

    // pointers
    Reg#(CSR_INDEX) f2hHead <- mkReg(`CSR_F2H_BUF_START);
    Reg#(CSR_INDEX) f2hTail <- mkReg(`CSR_F2H_BUF_START);
    Reg#(CSR_INDEX) h2fHead <- mkReg(`CSR_H2F_BUF_START);
    Reg#(CSR_INDEX) h2fTail <- mkReg(`CSR_H2F_BUF_START);

    // dirty/valid bits
    Reg#(Bool) h2fHeadDirty <- mkReg(False);
    Reg#(Bool) h2fTailValid <- mkReg(True);
    Reg#(Bool) f2hHeadValid <- mkReg(True);
    Reg#(Bool) f2hTailDirty <- mkReg(False);

    // other state
    Reg#(Bit#(8))  lastIID <- mkReg(0);
    Reg#(Bit#(8))  leds    <- mkReg(0);
    Reg#(Bit#(8))  index   <- mkReg(0);
    Reg#(Bit#(32)) data    <- mkReg(0);
    Reg#(Bit#(32)) buffer  <- mkReg(0);

    // =========== Helper Wires =========

    CSR_INDEX f2hHeadPlusOne = (f2hHead == `CSR_F2H_BUF_END) ? `CSR_F2H_BUF_START : (f2hHead + 1);
    CSR_INDEX f2hTailPlusOne = (f2hTail == `CSR_F2H_BUF_END) ? `CSR_F2H_BUF_START : (f2hTail + 1);
    CSR_INDEX h2fHeadPlusOne = (h2fHead == `CSR_H2F_BUF_END) ? `CSR_H2F_BUF_START : (h2fHead + 1);
    CSR_INDEX h2fTailPlusOne = (h2fTail == `CSR_H2F_BUF_END) ? `CSR_H2F_BUF_START : (h2fTail + 1);

    Bool f2hEmpty = (f2hHead == f2hTail);
    Bool f2hFull  = (f2hHead == f2hTailPlusOne);
    Bool h2fEmpty = (h2fHead == h2fTail);
    Bool h2fFull  = (h2fHead == h2fTailPlusOne);

    Bit#(32) status_flags;
    Bit#(32) status_pointers;
    Bit#(32) status_vhdl;

    // status flags
    status_flags[0]  = h2fEmpty ? 1 : 0;
    status_flags[1]  = h2fFull  ? 1 : 0;
    status_flags[2]  = f2hEmpty ? 1 : 0;
    status_flags[3]  = f2hFull  ? 1 : 0;

    status_flags[4]  = h2fHeadDirty ? 1 : 0;
    status_flags[5]  = h2fTailValid ? 1 : 0;
    status_flags[6]  = f2hHeadValid ? 1 : 0;
    status_flags[7]  = f2hTailDirty ? 1 : 0;

    status_flags[8]  = 0; // readState == READ_STATE_ready        ? 1 : 0;
    status_flags[9]  = 0; // readState == READ_STATE_busy_h2fTail ? 1 : 0;
    status_flags[10] = 0; // readState == READ_STATE_busy_f2hHead ? 1 : 0;
    status_flags[11] = 0; // readState == READ_STATE_busy_data    ? 1 : 0;

    status_flags[12] = 0; // initStage[0];
    status_flags[13] = 0; // initStage[1];
    status_flags[14] = 0; // initStage[2];
    status_flags[15] = 0; // initStage[3];

    // status pointers
    status_pointers[7:0]   = f2hTail;
    status_pointers[15:8]  = f2hHead;
    status_pointers[23:16] = h2fTail;
    status_pointers[31:24] = h2fHead;

    // vhdl/synchronizer status
    status_vhdl[15:0] = drivers.pciExpressDriver.read_data()[15:0];

    status_vhdl[16] = drivers.pciExpressDriver.read_req_ready();
    status_vhdl[17] = drivers.pciExpressDriver.read_resp_ready();
    status_vhdl[18] = drivers.pciExpressDriver.write_ready();
    status_vhdl[19] = 0;

    status_vhdl[21:20] = drivers.pciExpressDriver.write_sync_depth_bsv();
    status_vhdl[23:22] = '0; // drivers.pciExpressDriver.write_sync_depth_vhdl();
    status_vhdl[27:24] = '0; // drivers.pciExpressDriver.write_sync_enq_count();
    status_vhdl[31:28] = '0; // drivers.pciExpressDriver.write_sync_deq_count();

    // 32-bit debug instruction format:
    //
    // field:   [IID]  [OPCODE]  [INDEX] [IMMEDIATE]
    // bits :   31-24   23-16     15-8      7-0

    // ============== Rules =============

    // process a new instruction
    rule process_inst (state == STATE_ready);

        // read instruction
        PCIE_CSR_Data inst = drivers.pciExpressDriver.csr_h2f_reg0_read();

        // decode partially
        Bit#(8) iid    = inst[31:24];
        Bit#(8) opcode = inst[23:16];

        // make sure this is a new instruction
        if (iid != lastIID)
        begin

            lastIID <= iid;

            case (opcode)
                
                // NOP
                'h00: noAction;
                
                // LEDs := immediate
                'h01: leds <= inst[7:0];
                
                // LEDs := buffer[7:0]
                'h02: leds <= buffer[7:0];
                
                // LEDs := status_flags[7:0]
                'h03: leds <= status_flags[7:0];

                // buffer[7:0] := immediate
                'h04: buffer[7:0] <= inst[7:0]; // buffer := (buffer & 'hFFFFFF00) | zeroExtend(immediate);
                
                // buffer := buffer << 8
                'h05: buffer <= buffer << 8;
                
                // buffer := CSR[index]
                'h06: begin
                          index <= inst[15:8];
                          state <= STATE_doRead;
                      end
                
                // CSR[index] := buffer
                'h07: begin
                          index <= inst[15:8];
                          data  <= buffer;
                          state <= STATE_doWrite;
                      end
                
                // CSR[index][7:0] := immediate
                'h08: begin
                          index <= inst[15:8];
                          data  <= zeroExtend(inst[7:0]);
                          state <= STATE_doWrite;
                      end
                
                // CSR[tail : tail + index-1] := sequence(imm..imm+index-1)
                'h09: begin
                          index <= inst[15:8];
                          data  <= zeroExtend(inst[7:0]);
                          state <= STATE_doSeqWrite;
                      end

                // CSR[sys] := buffer
                'h0A: begin
                          data <= buffer;
                          state <= STATE_doSysWrite;
                      end
                
                // CSR[sys] := status (flags)
                'h0B: begin
                          data <= status_flags;
                          state <= STATE_doSysWrite;
                      end
                          
                // CSR[sys] := status (pointers)
                'h0C: begin
                          data <= status_pointers;
                          state <= STATE_doSysWrite;
                      end
                          
                // CSR[sys] := status (VHDL)
                'h0D: begin
                          data <= status_vhdl;
                          state <= STATE_doSysWrite;
                      end
                
                // ignore invalid instructions
                default: noAction;
            endcase

        end

    endrule

    // read common CSR and place result in buffer
    rule read_csr_req (state == STATE_doRead);
        drivers.pciExpressDriver.csr_read_req(index);
        state <= STATE_getResponse;
    endrule

    rule read_csr_resp (state == STATE_getResponse);
        PCIE_CSR_Data d <- drivers.pciExpressDriver.csr_read_resp();
        buffer <= truncate(d);
        state <= STATE_ready;
    endrule

    // write common CSR
    rule write_csr (state == STATE_doWrite);
        drivers.pciExpressDriver.csr_write(index, data);
        state <= STATE_ready;
    endrule
    
    // sequentially write a given number of CSRs starting from current tail
    rule write_seq_csr (state == STATE_doSeqWrite);
        drivers.pciExpressDriver.csr_write(f2hTail, data);
        f2hTail <= f2hTailPlusOne;
        data    <= data + 1;
        index   <= index - 1;
        if (index == 1)
            state <= STATE_ready;
    endrule

    // write system CSR
    rule write_sys_csr (state == STATE_doSysWrite);
        drivers.pciExpressDriver.csr_f2h_reg0_write(data);
        state <= STATE_ready;
    endrule

    // update leds
    rule set_leds (True);
        drivers.ledsDriver.setLEDs(leds);
    endrule

    // ============= Methods =============

    // read
    method ActionValue#(UMF_CHUNK) read() if (False);
        noAction;
        return '0;
    endmethod

    // write
    method Action write(UMF_CHUNK chunk) if (False);
        noAction;
    endmethod

endmodule
