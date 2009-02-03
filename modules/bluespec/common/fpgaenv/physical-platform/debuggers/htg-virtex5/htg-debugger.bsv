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
`include "led_device.bsh"
`include "switch_device.bsh"
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
    DEBUGGER_STATE_seqWrite
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
    
    // update LEDs
    rule update_leds (True);
        
        drivers.ledsDriver.setLEDs(leds);
        
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
            
        method softReset = drivers.pciExpressDriver.softReset;
        
    endinterface
    
    // pass-through LEDs and Switches interfaces
    
    interface LEDS_DRIVER ledsDriver = drivers.ledsDriver;
        
    interface SWITCHES_DRIVER switchesDriver = drivers.switchesDriver;

    // pass-through soft reset signal
        
    method soft_reset = drivers.soft_reset;

endmodule
