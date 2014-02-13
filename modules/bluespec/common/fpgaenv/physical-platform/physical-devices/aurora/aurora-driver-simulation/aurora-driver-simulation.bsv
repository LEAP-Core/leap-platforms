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

// This module interfaces to the SMA cables on the
// XUPV5. However only certain of the generated verilog and ucf files
// are needed to characterize this interface, and it can be used a model 
// for high-speed board to board serial on other development boards. The 
// device interface consists of a simple FIFO with guaranteed transport to
// the other device. This module is slightly complicated by the need to 
// instantiate dummy serial modules to route clock to the SMA GTP.
// unguarded interface

import FIFOF::*;

`include "awb/provides/unix_comm_device.bsh"

interface AURORA_SINGLE_DEVICE_UG#(numeric type width);
	method Action send(Bit#(width) tx);
	method ActionValue#(Bit#(width)) receive();

    method Action rxn_in(Bit#(1) i);
    method Action rxp_in(Bit#(1) i);
    (* always_ready *)
    method Bit#(1) txn_out();
    (* always_ready *)
    method Bit#(1) txp_out();
    
    method Bit#(1) channel_up;
    method Bit#(1) lane_up;
    method Bit#(1) hard_err;
    method Bit#(1) soft_err;
    method Bool    cc;
    method Bool    receive_rdy;
    method Bool    transmit_rdy;
    method Action   underflow(Bool underflow, Bit#(2) flitcount, Bit#(8) txcredits, Bit#(8) rxcredits);		

    method Bit#(32) rx_count;
    method Bit#(32) tx_count;
    method Bit#(32) error_count;

		
    interface Clock aurora_clk;
    interface Reset aurora_rst;
    interface Reset aurora_rst_n;
endinterface


module mkAURORA_SINGLE_UG#(String outgoing, String incoming) (AURORA_SINGLE_DEVICE_UG#(width))
    provisos(Add#(width_extra, width, TMul#(`UNIX_COMM_NUM_WORDS, `UNIX_COMM_WORD_WIDTH))); // this is the size of the physical unix device.

    let clk <- exposeCurrentClock;
    let rst <- exposeCurrentReset;

    let commDevice <-  mkUNIXCommDevice(outgoing, incoming);

    Reg#(Bit#(8)) ccAdjust <- mkReg(0);
    FIFOF#(Bit#(width)) rxFIFO <- mkFIFOF();
    Reg#(Bit#(32)) rxCount <- mkReg(0);
    Reg#(Bit#(32)) txCount <- mkReg(0);

    Bool adjustTime = ccAdjust < 32; 

    rule countAdjust;
        ccAdjust <= ccAdjust + 1;
    endrule

    rule rxTransfer;
        let data = truncate(commDevice.driver.first);
        commDevice.driver.deq;
        rxFIFO.enq(data);
    endrule

    method Action send(Bit#(width) tx) if(commDevice.driver.write_ready && !adjustTime);
        commDevice.driver.write(zeroExtend(tx));
        txCount <= txCount + 1;
    endmethod

    method ActionValue#(Bit#(width)) receive() if(!adjustTime);
        rxFIFO.deq();
        rxCount <= rxCount + 1;
        return rxFIFO.first;
    endmethod

    method Bit#(1) channel_up = 1;
    method Bit#(1) lane_up = 1;
    method Bit#(1) hard_err = 0;
    method Bit#(1) soft_err = 0;
    method Bool    cc = adjustTime;
    method Bool    receive_rdy = rxFIFO.notEmpty() && !adjustTime;
    method Bool    transmit_rdy = commDevice.driver.write_ready && !adjustTime;
		

    method Bit#(32) rx_count = rxCount;
    method Bit#(32) tx_count = txCount;
    method Bit#(32) error_count = 0;

		
    interface Clock aurora_clk = clk;
    interface Reset aurora_rst = rst;
    
endmodule
