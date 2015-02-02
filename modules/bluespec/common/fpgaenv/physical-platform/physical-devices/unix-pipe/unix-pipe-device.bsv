//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

import FIFOF::*;
import Vector::*;

`include "awb/provides/soft_connections.bsh"
`include "awb/provides/soft_services.bsh"
`include "awb/provides/soft_services_lib.bsh"
`include "awb/provides/soft_services_deps.bsh"

`include "awb/provides/umf.bsh"
`include "awb/provides/physical_platform_utils.bsh"

`define PIPE_NULL       1
`define POLL_INTERVAL   0

// BDPI imports
import "BDPI" function Action                  pipe_init(Bit#(8) usePipes, String platformID);
import "BDPI" function ActionValue#(Bit#(8))   pipe_open(Bit#(8) programID);
import "BDPI" function ActionValue#(Bit#(129)) pipe_read(Bit#(8) handle);
import "BDPI" function ActionValue#(Bit#(1))   pipe_can_write(Bit#(8) handle);
import "BDPI" function Action   pipe_write(Bit#(8) handle, Bit#(128) data);
                  
import "BDPI" function Bool                   pipe_receive_reset();
import "BDPI" function Action                 pipe_clear_reset();

// types
typedef enum
{
    STATE_init0,
    STATE_init1,
    STATE_ready 
}
STATE
    deriving (Bits, Eq);

// UNIX_PIPE_DRIVER
interface UNIX_PIPE_DRIVER;

    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
        
endinterface

// UNIX_PIPE_WIRES
interface UNIX_PIPE_WIRES;

endinterface

// UNIX_PIPE_DEVICE
// By convention a Device is a Driver and a Wires
interface UNIX_PIPE_DEVICE;

  interface UNIX_PIPE_DRIVER driver;
  interface UNIX_PIPE_WIRES  wires;

endinterface
                  
// Only the USE_PIPES option will work, so define it here.
`define USE_PIPES 1

// UNIX pipe module
module [CONNECTED_MODULE] mkUNIXPipeDevice#(SOFT_RESET_TRIGGER softResetTrigger)
    // interface
                  (UNIX_PIPE_DEVICE);
    
    // state
    Reg#(Bit#(8))  handle      <- mkReg(0);
    Reg#(Bit#(32)) pollCounter <- mkReg(0);
    Reg#(STATE)    state       <- mkReg(STATE_init0);
    
    // buffers
    FIFOF#(UMF_CHUNK) readBuffer  <- mkFIFOF();
    FIFOF#(UMF_CHUNK) writeBuffer <- mkFIFOF();

    // Name
    let platformName <- getSynthesisBoundaryPlatform();

    // ==============================================================
    //                            Rules
    // ==============================================================

    // poll cycle
    rule cycle_poll_counter(state == STATE_ready && pollCounter != 0);
        pollCounter <= pollCounter - 1;
    endrule

    // initialize C code
    rule initialize(state == STATE_init0);
        pipe_init(`USE_PIPES, platformName);
        state <= STATE_init1;
    endrule

    // another rule needed to initialize C code
    rule open_C_channel(state == STATE_init1);
        Bit#(8) wire_out <- pipe_open(0);
        handle <= wire_out;
        state  <= STATE_ready;
    endrule

    // probe C code for incoming chunk
    rule read_bdpi (state == STATE_ready && pollCounter == 0);
        let msg <- pipe_read(handle);
        Bit#(1) flag = msg[128];

        if (flag != `PIPE_NULL)
        begin
            UMF_CHUNK chunk = truncate(msg);
            if(`UNIX_DEVICE_DEBUG == 1)
            begin 
                $display("Driver read %h", chunk);
            end

            readBuffer.enq(chunk);
        end
        pollCounter <= `POLL_INTERVAL;
    endrule

    // write chunk from write buffer into C code
    rule write_bdpi (state == STATE_ready && writeBuffer.notEmpty());
        UMF_CHUNK chunk = writeBuffer.first();

        let can_write <- pipe_can_write(handle);
        if (can_write == 1)
        begin
            writeBuffer.deq();
            if(`UNIX_DEVICE_DEBUG == 1)
            begin
                $display("Driver wrote %h", chunk);
            end

            pipe_write(handle, zeroExtend(chunk));
        end
    endrule

    // trigger soft reset
    rule trigger_soft_reset (pipe_receive_reset());
        pipe_clear_reset();
        softResetTrigger.reset();
    endrule

    // ==============================================================
    //                          Methods
    // ==============================================================
    
    // driver interface
    interface UNIX_PIPE_DRIVER driver;
        
        // read
        method ActionValue#(UMF_CHUNK) read();
            UMF_CHUNK chunk = readBuffer.first();
            readBuffer.deq();
            return chunk;
        endmethod

        // write
        method Action write(UMF_CHUNK chunk);
            if(`UNIX_DEVICE_DEBUG == 1)
            begin
                $display("Writing Chunk %h", chunk);
            end

            writeBuffer.enq(chunk);
        endmethod
        
    endinterface
    
    // wires interface
    interface UNIX_PIPE_WIRES wires;
        
    endinterface

endmodule
