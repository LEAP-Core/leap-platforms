//
// Copyright (C) 2013 Intel Corporation
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

// This code wraps the unix pipe driver in the way that the LIM compiler expects.

import FIFOF::*;
import Vector::*;

`include "umf.bsh"
`include "physical_platform_utils.bsh"
`include "unix_pipe_device.bsh"

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

module mkUNIXPipeLIDevice#(SOFT_RESET_TRIGGER softResetTrigger) (UNIX_PIPE_LI_DEVICE);

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