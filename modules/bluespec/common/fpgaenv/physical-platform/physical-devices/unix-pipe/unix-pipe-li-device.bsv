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

// This code wraps the unix pipe driver in the way that the LIM compiler expects.

import FIFOF::*;
import Vector::*;

`include "awb/provides/umf.bsh"
`include "awb/provides/physical_platform_utils.bsh"
`include "awb/provides/unix_pipe_device.bsh"

`include "awb/provides/soft_connections.bsh"
`include "awb/provides/soft_services.bsh"
`include "awb/provides/soft_services_lib.bsh"
`include "awb/provides/soft_services_deps.bsh"


interface UNIX_PIPE_LI_DRIVER;

    method Action                           deq();
    method Bit#(SizeOf#(UMF_CHUNK))         first();
    method Action                           write(Bit#(SizeOf#(UMF_CHUNK)) chunk);
    method Bool                             write_ready();

endinterface

interface UNIX_PIPE_LI_WIRES;

endinterface

interface UNIX_PIPE_LI_DEVICE;
    interface UNIX_PIPE_LI_DRIVER driver; 
    interface UNIX_PIPE_LI_WIRES  wires;
endinterface

module [CONNECTED_MODULE] mkUNIXPipeLIDevice#(SOFT_RESET_TRIGGER softResetTrigger) (UNIX_PIPE_LI_DEVICE);

    let unixPipe <- mkUNIXPipeDevice(softResetTrigger); 

    FIFOF#(UMF_CHUNK) readFIFO <- mkFIFOF;
    FIFOF#(UMF_CHUNK) writeFIFO <- mkFIFOF;  

    rule transferRead;
        let data <- unixPipe.driver.read();
        readFIFO.enq(data);
    endrule

    rule transferWrite;  
        writeFIFO.deq;
        unixPipe.driver.write(writeFIFO.first);
    endrule

    interface UNIX_PIPE_LI_DRIVER driver;
        method deq = readFIFO.deq;
        method first = readFIFO.first;
        method write = writeFIFO.enq;
        method write_ready = writeFIFO.notFull();
    endinterface

    interface UNIX_PIPE_LI_WIRES wires;
            
    endinterface

endmodule
