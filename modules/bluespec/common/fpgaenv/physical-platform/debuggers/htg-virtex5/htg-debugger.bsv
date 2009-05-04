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

`include "pci_express_device.bsh"
`include "clocks_device.bsh"
`include "led_device.bsh"
`include "switch_device.bsh"
`include "ddr2_sdram_device.bsh"
`include "physical_platform.bsh"

// === machine states ===

typedef enum
{
    APP_STATE_stopped,
    APP_STATE_running
}
APP_STATE
    deriving (Bits, Eq);

typedef enum
{
    DEBUGGER_STATE_ready,
    DEBUGGER_STATE_readingCSR,
    DEBUGGER_STATE_appReadingCSR,
    DEBUGGER_STATE_seqWrite,
    DEBUGGER_STATE_readingDRAM_0,
    DEBUGGER_STATE_readingDRAM_1,
    DEBUGGER_STATE_writingDRAM
}
DEBUGGER_STATE
    deriving (Bits, Eq);


// ============== Physical Platform Debugger ==============

// the debugger accepts a set of physical drivers as
// constructor input (along with some status bits), and
// returns exactly the same set of physical drivers as its
// interface, but with the methods within the interface
// gated to prevent access unless the debugger allows it

// module
module mkPhysicalPlatformDebugger#(PHYSICAL_DRIVERS drivers)
    // interface
        (PHYSICAL_DRIVERS);

    // ============= State ==============
    
    Reg#(APP_STATE)          appState <- mkReg(APP_STATE_stopped);
    Reg#(DEBUGGER_STATE)     debuggerState <- mkReg(DEBUGGER_STATE_ready);
    Reg#(Bit#(8))            lastIID <- mkReg(0);
    Reg#(PCIE_CSR_DATA)      buffer  <- mkReg(0);
    Reg#(Bit#(8))            leds    <- mkReg(0);
    
    Reg#(FPGA_DRAM_DUALEDGE_DATA) dramBuffer <- mkReg(0);
    Reg#(Bit#(4))                 dramCount  <- mkReg(0);

    Reg#(Bit#(`PCIE_CSR_IDX_SIZE)) seqWriteIndex <- mkReg(0);
    Reg#(Bit#(`PCIE_CSR_IDX_SIZE)) seqWriteCount <- mkReg(0);
    
    // useless flags. FIXME.
    Bit#(32) status_flags = 0;
    Bit#(32) status_pointers = 0;
    Bit#(32) status_vhdl = 0;

    // ============== Rules =============

    // 32-bit debug instruction format:
    //
    // field:   [IID]  [OPCODE]  [INDEX] [IMMEDIATE]
    // bits :   31-24   23-16     15-8      7-0

    // read current instruction
    PCIE_CSR_DATA inst = drivers.pciExpressDriver.systemCSR;
    
    // gate application if there is a debugger instruction
    Bool debug_inst = (inst[23:20] != 'b0000);
        
    // process a new instruction
    rule process_inst (debuggerState == DEBUGGER_STATE_ready && debug_inst);
        
        // read current instruction and decode
        Bit#(8) inst_iid    = inst[31:24];
        Bit#(8) inst_opcode = inst[23:16];
        Bit#(8) inst_index  = inst[15:8];
        Bit#(8) inst_imm    = inst[7:0];
        
        // make sure this is a new instruction
        if (inst_iid != lastIID)
        begin

            lastIID <= inst_iid;

            case (inst_opcode)
                
                // NOP
                'h10: noAction;
                
                // LEDs := immediate
                'h11: drivers.ledsDriver.setLEDs(inst_imm);
                
                // LEDs := buffer[7:0]
                'h12: drivers.ledsDriver.setLEDs(buffer[7:0]);
                
                // LEDs := status_flags[7:0]
                'h13: drivers.ledsDriver.setLEDs(status_flags[7:0]);

                // buffer[7:0] := immediate
                'h14: buffer[7:0] <= inst_imm;
                
                // buffer := buffer << 8
                'h15: buffer <= buffer << 8;
                
                // buffer := CSR[index]
                'h16: begin
                          drivers.pciExpressDriver.commonCSRs.readRequest(inst_index);
                          debuggerState <= DEBUGGER_STATE_readingCSR;
                      end
                
                // CSR[index] := buffer
                'h17: drivers.pciExpressDriver.commonCSRs.write(inst_index, buffer);
                
                // CSR[index][7:0] := immediate
                'h18: begin
                          drivers.pciExpressDriver.commonCSRs.write(inst_index, zeroExtend(inst_imm));
                          leds <= (leds << 1) | ('h01);
                      end
                
                // CSR[index : index+imm-1] := buffer : buffer+index-1
                'h19: begin
                          seqWriteIndex <= inst_index;
                          seqWriteCount <= inst_imm;
                          debuggerState <= DEBUGGER_STATE_seqWrite;
                      end

                // CSR[sys] := buffer
                'h1A: drivers.pciExpressDriver.systemCSR <= buffer;
                
                // CSR[sys] := status (flags)
                'h1B: drivers.pciExpressDriver.systemCSR <= status_flags;
                          
                // CSR[sys] := status (pointers)
                'h1C: drivers.pciExpressDriver.systemCSR <= status_pointers;
                          
                // CSR[sys] := status (VHDL)
                'h1D: drivers.pciExpressDriver.systemCSR <= status_vhdl;
                
                // start application
                'h1E: appState <= APP_STATE_running;
                
                // stop application
                'h1F: appState <= APP_STATE_stopped;
                
                // CSR[7:0] := DRAM[index]
                'h20: begin
                          drivers.ddr2SDRAMDriver.readReq(zeroExtend(inst_index));
                          dramBuffer <= 0;
                          dramCount <= 0;
                          debuggerState <= DEBUGGER_STATE_readingDRAM_0;
                      end
                
                // DRAM[index] := CSR[7:0]
                'h21: begin
                          drivers.ddr2SDRAMDriver.writeReq(zeroExtend(inst_index));
                          dramBuffer <= 0;
                          dramCount <= 0;
                          debuggerState <= DEBUGGER_STATE_writingDRAM;
                      end
                
                // ignore invalid instructions
                default: noAction;

            endcase

        end

    endrule

    // read common CSR and place result in buffer
    rule read_csr_resp (debuggerState == DEBUGGER_STATE_readingCSR);
        
        PCIE_CSR_DATA data <- drivers.pciExpressDriver.commonCSRs.readResponse();
        buffer <= data;
        debuggerState <= DEBUGGER_STATE_ready;

    endrule

    // sequentially write a given number of CSRs
    rule write_seq_csr (debuggerState == DEBUGGER_STATE_seqWrite);
    
        drivers.pciExpressDriver.commonCSRs.write(seqWriteIndex, buffer);

        seqWriteIndex <= (seqWriteIndex == '1) ? 0 : (seqWriteIndex + 1);
        buffer <= buffer + 1;
        seqWriteCount <= seqWriteCount - 1;
        if (seqWriteCount == 1)
            debuggerState <= DEBUGGER_STATE_ready;
    
        leds <= (leds << 1) | ('h01);

    endrule
    
    // read first dword of DRAM data into buffer
    rule read_dram_data_0 (debuggerState == DEBUGGER_STATE_readingDRAM_0);
        
        FPGA_DRAM_DUALEDGE_DATA data <- drivers.ddr2SDRAMDriver.readRsp();
        dramBuffer <= data;
        dramCount <= 0;
        debuggerState <= DEBUGGER_STATE_readingDRAM_1;
        
    endrule
    
    // read DRAM data into CSRs
    rule read_dram_data_1 (debuggerState == DEBUGGER_STATE_readingDRAM_1);
        
        case (dramCount)
            
            0: drivers.pciExpressDriver.commonCSRs.write(0, dramBuffer[31:0]);
            
            1: drivers.pciExpressDriver.commonCSRs.write(1, dramBuffer[63:32]);
            
            2: drivers.pciExpressDriver.commonCSRs.write(2, dramBuffer[95:64]);
            
            3: begin
                   drivers.pciExpressDriver.commonCSRs.write(3, dramBuffer[127:96]);
                   FPGA_DRAM_DUALEDGE_DATA data <- drivers.ddr2SDRAMDriver.readRsp();
                   dramBuffer <= data;
               end
            
            4: drivers.pciExpressDriver.commonCSRs.write(4, dramBuffer[31:0]);
            
            5: drivers.pciExpressDriver.commonCSRs.write(5, dramBuffer[63:32]);
            
            6: drivers.pciExpressDriver.commonCSRs.write(6, dramBuffer[95:64]);
            
            7: begin
                   drivers.pciExpressDriver.commonCSRs.write(7, dramBuffer[127:96]);
                   debuggerState <= DEBUGGER_STATE_ready;
               end
            
        endcase
                   
        dramCount <= dramCount + 1;
        
    endrule
        
    // accumulate write data into CSRs and write to DRAM
    rule write_dram_data (debuggerState == DEBUGGER_STATE_writingDRAM);
        
        case (dramCount)
            
            0: drivers.pciExpressDriver.commonCSRs.readRequest(0);
            
            1: begin
                   PCIE_CSR_DATA csr_data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                   dramBuffer[31:0] <= csr_data;
               end
            
            2: drivers.pciExpressDriver.commonCSRs.readRequest(1);
            
            3: begin
                   PCIE_CSR_DATA csr_data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                   dramBuffer[63:32] <= csr_data;
               end
            
            4: drivers.pciExpressDriver.commonCSRs.readRequest(2);
            
            5: begin
                   PCIE_CSR_DATA csr_data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                   dramBuffer[95:64] <= csr_data;
               end
            
            6: drivers.pciExpressDriver.commonCSRs.readRequest(3);
            
            7: begin

                   PCIE_CSR_DATA csr_data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                   
                   FPGA_DRAM_DUALEDGE_DATA data = 0;
                   
                   data[127:96] = csr_data;
                   data[95:0]   = dramBuffer[95:0];

                   drivers.ddr2SDRAMDriver.writeData(data, '0);

               end

            8: drivers.pciExpressDriver.commonCSRs.readRequest(4);
            
            9: begin
                   PCIE_CSR_DATA csr_data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                   dramBuffer[31:0] <= csr_data;
               end
            
           10: drivers.pciExpressDriver.commonCSRs.readRequest(5);
            
           11: begin
                   PCIE_CSR_DATA csr_data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                   dramBuffer[63:32] <= csr_data;
               end
            
           12: drivers.pciExpressDriver.commonCSRs.readRequest(6);
            
           13: begin
                   PCIE_CSR_DATA csr_data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                   dramBuffer[95:64] <= csr_data;
               end
            
           14: drivers.pciExpressDriver.commonCSRs.readRequest(7);
            
           15: begin
                    
                   PCIE_CSR_DATA csr_data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                   
                   FPGA_DRAM_DUALEDGE_DATA data = 0;
                   
                   data[95:0]   = dramBuffer[95:0];
                   data[127:96] = csr_data;

                   drivers.ddr2SDRAMDriver.writeData(data, '0);
                   
                   debuggerState <= DEBUGGER_STATE_ready;
                   
               end
            
        endcase
                   
        dramCount <= dramCount + 1;
        
    endrule    
    
    // update LEDs
    rule update_leds (True);
        
        drivers.ledsDriver.setLEDs(truncate(dramBuffer)); // -- DEBUG -- leds);
        
    endrule
    
    // ============== Interface Methods ==============
    
    // Gated PCI Express interface
    
    interface PCI_EXPRESS_DRIVER pciExpressDriver;
    
        //
        // common CSRs
        //
        
        interface COMMON_CSR_ARRAY commonCSRs;
            
            method Action readRequest(PCIE_CSR_INDEX index) if (appState == APP_STATE_running &&
                                                                debuggerState == DEBUGGER_STATE_ready &&
                                                                !debug_inst);
                
                drivers.pciExpressDriver.commonCSRs.readRequest(index);
                debuggerState <= DEBUGGER_STATE_appReadingCSR;
                
            endmethod

            method ActionValue#(PCIE_CSR_DATA) readResponse() if (debuggerState == DEBUGGER_STATE_appReadingCSR);
                
                PCIE_CSR_DATA data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                debuggerState <= DEBUGGER_STATE_ready;
                return data;
                
            endmethod
            
            method Action write(PCIE_CSR_INDEX index, PCIE_CSR_DATA data) if (appState == APP_STATE_running &&
                                                                              debuggerState == DEBUGGER_STATE_ready &&
                                                                              !debug_inst);
                
                drivers.pciExpressDriver.commonCSRs.write(index, data);
                leds <= (leds << 1) | ('h01);
                
            endmethod
            
        endinterface
        
        //
        // system CSR
        //
        
        interface SYSTEM_CSR systemCSR;
            
            method PCIE_CSR_DATA _read() if (appState == APP_STATE_running && !debug_inst);
                
                return inst;
                
            endmethod
            
            method Action _write(PCIE_CSR_DATA data) if (appState == APP_STATE_running && !debug_inst);
                
                drivers.pciExpressDriver.systemCSR <= data;
                
            endmethod

        endinterface
        
        //
        // DMA
        //
        
        interface DMA_DRIVER dmaDriver = drivers.pciExpressDriver.dmaDriver;
    
        //
        // misc.
        //
        
        method interruptHost = drivers.pciExpressDriver.interruptHost;
        
    endinterface
    
    //
    // DDR2 SDRAM: TEMPORARY HACK: completely disable these methods
    //
    
    interface DDR2_SDRAM_DRIVER ddr2SDRAMDriver;
        
        method Action readReq(FPGA_DRAM_ADDRESS addr);
            
            noAction;
                
        endmethod

        method ActionValue#(FPGA_DRAM_DUALEDGE_DATA) readRsp();
            
            noAction;
            return 0;
            
        endmethod

        method Action writeReq(FPGA_DRAM_ADDRESS addr);
            
            noAction;
            
        endmethod

        method Action writeData(FPGA_DRAM_DUALEDGE_DATA data, FPGA_DRAM_DUALEDGE_DATA_MASK mask);
            
            noAction;
            
        endmethod
    
    endinterface
    
    //
    // pass-through all other interfaces
    //
    
    interface CLOCKS_DRIVER   clocksDriver   = drivers.clocksDriver;
    interface LEDS_DRIVER     ledsDriver     = drivers.ledsDriver;
    interface SWITCHES_DRIVER switchesDriver = drivers.switchesDriver;

endmodule
