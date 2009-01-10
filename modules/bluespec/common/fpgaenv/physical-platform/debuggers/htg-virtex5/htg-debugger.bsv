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
    CSR_PORT_STATE_ready,
    CSR_PORT_STATE_busyDebugger,
    CSR_PORT_STATE_busyApp
}
CSR_PORT_STATE
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
    
    // state of application
    Reg#(APP_STATE) appState <- mkReg(APP_STATE_stopped);
    
    // state of common CSR read port
    Reg#(CSR_PORT_STATE) csrPortState <- mkReg(CSR_PORT_STATE_ready);

    Reg#(Bit#(8))  lastIID <- mkReg(0);

    Reg#(PCIE_CSR_DATA) buffer  <- mkReg(0);

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
    rule process_inst (csrPortState == CSR_PORT_STATE_ready && debug_inst);
        
        // read current instruction and decode partially
        Bit#(8) iid    = inst[31:24];
        Bit#(8) opcode = inst[23:16];
        
        // make sure this is a new instruction
        if (iid != lastIID)
        begin

            lastIID <= iid;

            case (opcode)
                
                // NOP
                'h10: noAction;
                
                // LEDs := immediate
                'h11: drivers.ledsDriver.setLEDs(inst[7:0]);
                
                // LEDs := buffer[7:0]
                'h12: drivers.ledsDriver.setLEDs(buffer[7:0]);
                
                // LEDs := status_flags[7:0]
                'h13: drivers.ledsDriver.setLEDs(status_flags[7:0]);

                // buffer[7:0] := immediate
                'h14: buffer[7:0] <= inst[7:0];
                
                // buffer := buffer << 8
                'h15: buffer <= buffer << 8;
                
                // buffer := CSR[index]
                'h16: begin
                          drivers.pciExpressDriver.commonCSRs.readRequest(inst[15:8]);
                          csrPortState <= CSR_PORT_STATE_busyDebugger;
                      end
                
                // CSR[index] := buffer
                'h17: begin
                          drivers.pciExpressDriver.commonCSRs.write(inst[15:8], buffer);
                          csrPortState <= CSR_PORT_STATE_busyDebugger;
                      end
                
                // CSR[index][7:0] := immediate
                'h18: begin
                          drivers.pciExpressDriver.commonCSRs.write(inst[15:8], zeroExtend(inst[7:0]));
                          csrPortState <= CSR_PORT_STATE_busyDebugger;
                      end
                
                // CSR[tail : tail + index-1] := sequence(imm..imm+index-1)
                'h19: noAction;
                      // begin
                      //     index <= inst[15:8];
                      //     data  <= zeroExtend(inst[7:0]);
                      //     state <= STATE_doSeqWrite;
                      // end

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
    rule read_csr_resp (csrPortState == CSR_PORT_STATE_busyDebugger);
        
        PCIE_CSR_DATA data <- drivers.pciExpressDriver.commonCSRs.readResponse();
        buffer <= data;
        csrPortState <= CSR_PORT_STATE_ready;

    endrule

    // sequentially write a given number of CSRs starting from current tail
    // rule write_seq_csr (state == STATE_doSeqWrite);
    //
    //     drivers.pciExpressDriver.csr_write(f2hTail, data);
    //     f2hTail <= f2hTailPlusOne;
    //     data    <= data + 1;
    //     index   <= index - 1;
    //     if (index == 1)
    //         state <= STATE_ready;
    // 
    // endrule

    // ============== Interface Methods ==============
    
    // Gated PCI Express interface
    
    interface PCI_EXPRESS_DRIVER pciExpressDriver;
    
        // common CSRs
        
        interface COMMON_CSR_ARRAY commonCSRs;
            
            method Action readRequest(PCIE_CSR_INDEX index) if (appState == APP_STATE_running &&
                                                                csrPortState == CSR_PORT_STATE_ready &&
                                                                !debug_inst);
                
                drivers.pciExpressDriver.commonCSRs.readRequest(index);
                csrPortState <= CSR_PORT_STATE_busyApp;
                
            endmethod

            method ActionValue#(PCIE_CSR_DATA) readResponse() if (csrPortState == CSR_PORT_STATE_busyApp);
                
                PCIE_CSR_DATA data <- drivers.pciExpressDriver.commonCSRs.readResponse();
                csrPortState <= CSR_PORT_STATE_ready;
                return data;
                
            endmethod
            
            method Action write(PCIE_CSR_INDEX index, PCIE_CSR_DATA data) if (appState == APP_STATE_running && !debug_inst);
                
                drivers.pciExpressDriver.commonCSRs.write(index, data);
                
            endmethod
            
        endinterface
        
        // system CSR
        
        interface SYSTEM_CSR systemCSR;
            
            method PCIE_CSR_DATA _read() if (appState == APP_STATE_running && !debug_inst);
                
                return inst;
                
            endmethod
            
            method Action _write(PCIE_CSR_DATA data) if (appState == APP_STATE_running && !debug_inst);
                
                drivers.pciExpressDriver.systemCSR <= data;
                
            endmethod

        endinterface
        
        // misc.
        
        method interruptHost = drivers.pciExpressDriver.interruptHost;
            
        method softReset = drivers.pciExpressDriver.softReset;
        
    endinterface
    
    // pass-through LEDs and Switches interfaces
    
    interface LEDS_DRIVER ledsDriver = drivers.ledsDriver;
        
    interface SWITCHES_DRIVER switchesDriver = drivers.switchesDriver;

    // pass-through soft reset signal
        
    method soft_reset = drivers.soft_reset;

endmodule
