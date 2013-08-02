//
// Copyright (C) 2011 Massachusetts Institute of Technology
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
    provisos(Add#(width_extra, width, 256));

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
