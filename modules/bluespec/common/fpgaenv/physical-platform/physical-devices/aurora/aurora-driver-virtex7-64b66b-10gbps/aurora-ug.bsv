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

`include "awb/provides/aurora_common.bsh"

interface AURORA_SINGLE_DEVICE_UG#(numeric type width);
    method Action send(Bit#(width) tx);
    method ActionValue#(Bit#(width)) receive();

    (* always_enabled, always_ready *)
    method Action rxn_in(Bit#(1) i);
    (* always_enabled, always_ready *)
    method Action rxp_in(Bit#(1) i);
    (* always_enabled, always_ready *)
    method Bit#(1) txn_out();
    (* always_enabled, always_ready *)
    method Bit#(1) txp_out();
    
    method Bit#(1) channel_up;
    method Bit#(1) lane_up;
    method Bit#(1) hard_err;
    method Bit#(1) soft_err;
    method Bool    cc;
    method Bool    transmit_rdy;
    method Bool    receive_rdy;
    method Action   underflow(Bool underflow, Bit#(2) flitcount, Bit#(8) txcredits, Bit#(8) rxcredits);

    method Bit#(32) rx_count;
    method Bit#(32) tx_count;
    method Bit#(32) error_count;

    interface Clock aurora_clk;
    interface Reset aurora_rst;
    interface Reset aurora_rst_n;
endinterface

import "BVI" aurora_64b66b_v7_3_exdes = 
module mkAURORA_SINGLE_UG#(AuroraGTXClockSpec pllClockSpec, Clock rawClock, Reset rawReset) 
    (AURORA_SINGLE_DEVICE_UG#(`AURORA_INTERFACE_WIDTH));

    parameter USE_CHIPSCOPE = pllClockSpec.use_chipscope;

    input_clock (INIT_CLK) = rawClock;
    input_clock (GTX_CLK) = pllClockSpec.clock;
    input_reset (RESET_N) clocked_by(rawClock) = rawReset;

    default_clock no_clock;
    default_reset no_reset;

    output_clock aurora_clk(USER_CLK);
    output_reset aurora_rst(USER_RST_N) clocked_by (aurora_clk);
    output_reset aurora_rst_n(USER_RST) clocked_by (aurora_clk);

    method rxn_in(RXN) enable((*inhigh*) rx_n_en) reset_by(no_reset) clocked_by(rawClock);
    method rxp_in(RXP) enable((*inhigh*) rx_p_en) reset_by(no_reset) clocked_by(rawClock);
    method TXN txn_out() reset_by(no_reset) clocked_by(rawClock);
    method TXP txp_out() reset_by(no_reset) clocked_by(rawClock);

    method CHANNEL_UP channel_up;
    method LANE_UP lane_up;
    method HARD_ERR hard_err;
    method SOFT_ERR soft_err;
    method cc_do_i cc;
    method RX_COUNT rx_count;
    method TX_COUNT tx_count;
    method ERROR_COUNT error_count;
    method rx_rdy receive_rdy();
    method tx_rdy transmit_rdy();

    method underflow(UNDERFLOW,FLITCOUNT,TXCREDIT,RXCREDIT) enable((*inhigh*) underflow_en) clocked_by(aurora_clk) reset_by(aurora_rst);

    method send(TX_DATA_OUT) enable(tx_en) ready(tx_rdy) clocked_by(aurora_clk) reset_by(aurora_rst); 
    method RX_DATA_IN receive() enable((*inhigh*) rx_en) ready(rx_rdy) clocked_by(aurora_clk) reset_by(aurora_rst);


    schedule (rxn_in, rxp_in, txn_out, txp_out, transmit_rdy, receive_rdy, channel_up, lane_up, hard_err, soft_err, cc, rx_count, tx_count, error_count, underflow) CF 
             (rxn_in, rxp_in, txn_out, txp_out, transmit_rdy, receive_rdy, channel_up, lane_up, hard_err, soft_err, cc, rx_count, tx_count, error_count, underflow);

    schedule (receive) CF (rxn_in, rxp_in, txn_out, txp_out, send, channel_up, lane_up, hard_err, soft_err, cc, rx_count, tx_count, error_count, underflow);
    
    schedule (send) CF (rxn_in, rxp_in, txn_out, txp_out, receive, channel_up, lane_up, hard_err, soft_err, cc, rx_count, tx_count, error_count, underflow);

    schedule (send) C (send);

    schedule (receive) C (receive);

endmodule
