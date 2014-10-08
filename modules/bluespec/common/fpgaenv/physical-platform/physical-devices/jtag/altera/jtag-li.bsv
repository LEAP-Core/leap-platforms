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


`include "awb/provides/umf.bsh"

// interface
interface JTAG_DRIVER;
    
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);

    // this interface needed for LIM compiler.
    method UMF_CHUNK first();
    method Action    deq();
    method Bool      write_ready();
        
endinterface

interface JTAG_DEVICE;
   interface JTAG_DRIVER driver;
   interface JTAG_WIRES  wires;
endinterface  

typedef Bit#(TLog#(TAdd#(TDiv#(SizeOf#(UMF_CHUNK),4),1))) UMF_COUNTER;

// module
module mkJtagDevice#(Clock rawClock, Reset rawReset) 
    // interface
        (JTAG_DEVICE);
   
    let jtagDriver <- mkAvalonJtagDriver(rawClock, rawReset);

    // no. jtag words to assemble a umf chunk
    UMF_COUNTER no_jtag_words = fromInteger(valueof(SizeOf#(UMF_CHUNK))/4);

    Reg#(UMF_CHUNK)      jtagIncoming      <- mkReg(0);
    Reg#(UMF_COUNTER)    jtagIncomingCount <- mkReg(0); 
    Reg#(UMF_CHUNK)      jtagOutgoing      <- mkReg(0);
    Reg#(UMF_COUNTER)    jtagOutgoingCount <- mkReg(0);       
    Reg#(Bool)           init              <- mkReg(False);

    // send the first character
    rule sendInit (!init);
        jtagDriver.driver.send(zeroExtend(jtagOutgoingCount) + 65);
        jtagOutgoingCount <= jtagOutgoingCount + 1;
        if (jtagOutgoingCount == no_jtag_words - 1)
        begin
            init <= True;
        end
    endrule

    rule sendToJtag (init && jtagOutgoingCount != no_jtag_words);
        Bit#(4) x = truncate(jtagOutgoing);
        jtagOutgoing <= jtagOutgoing >> 4;
        JTAGWord jtag_x = zeroExtend(x) ^ 64;
        jtagDriver.driver.send(jtag_x);
        jtagOutgoingCount <= jtagOutgoingCount + 1;
    endrule

    rule recvFromJtag (jtagIncomingCount != no_jtag_words);
        JTAGWord x <- jtagDriver.driver.receive();
        Bit#(4) truncated_x = truncate(x);
        jtagIncoming <= (jtagIncoming >> 4) ^ {truncated_x,0};
        jtagIncomingCount <= jtagIncomingCount + 1;
    endrule

    interface JTAG_DRIVER driver;

        method Action write(UMF_CHUNK data) if (jtagOutgoingCount == no_jtag_words && init);
            jtagOutgoing <= data;
            jtagOutgoingCount <= 0;
        endmethod

        method ActionValue#(UMF_CHUNK) read() if (jtagIncomingCount == no_jtag_words);
            jtagIncomingCount <= 0;
            return jtagIncoming;
        endmethod

        // this interface needed for LIM compiler.
        method UMF_CHUNK first() if (jtagIncomingCount == no_jtag_words);
            return jtagIncoming;
        endmethod

        method Action    deq() if (jtagIncomingCount == no_jtag_words);
            jtagIncomingCount <= 0;
        endmethod      

        method write_ready = (jtagOutgoingCount == no_jtag_words && init);

    endinterface
        
    interface wires = jtagDriver.wires;

endmodule
