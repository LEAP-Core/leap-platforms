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

interface AURORA_SINGLE_DEVICE_UG;

    // These are the wires
    method Action rxn_in(Bit#(1) rxn);
    method Action rxp_in(Bit#(1) rxp);
    (* always_ready *)
    method Bit#(1) txn_out();
    (* always_ready *)
    method Bit#(1) txp_out();

    (* always_enabled, always_ready *)
    method Action clk_n_in(Bit#(1) clk);
    (* always_enabled, always_ready *)
    method Action clk_p_in(Bit#(1) clk);      

    // Dummy GTP wires
    method Action rxn_in_dummy0(Bit#(1) rxn);
    method Action rxp_in_dummy0(Bit#(1) rxp);
    (* always_ready *)
    method Bit#(1) txn_out_dummy0();
    (* always_ready *)
    method Bit#(1) txp_out_dummy0();

    method Action rxn_in_dummy1(Bit#(1) rxn);
    method Action rxp_in_dummy1(Bit#(1) rxp);
    (* always_ready *)
    method Bit#(1) txn_out_dummy1();
    (* always_ready *)
    method Bit#(1) txp_out_dummy1();

    method Action rxn_in_dummy2(Bit#(1) rxn);
    method Action rxp_in_dummy2(Bit#(1) rxp);
    (* always_ready *)
    method Bit#(1) txn_out_dummy2();
    (* always_ready *)
    method Bit#(1) txp_out_dummy2();


    // Data interface 
    method ActionValue#(Bit#(16)) receive();
    method Action send(Bit#(16) data);
    method Action stats(UInt#(5) txCount, Bool txEmpty_n, Bool txFull_n, UInt#(5) rxCount, Bool rxEmpty_n, Bool rxFull_n);
    method Bit#(1) channel_up;
    method Bit#(1) lane_up;
    method Bit#(1) hard_err;
    method Bit#(1) soft_err;
    method Bit#(32) status;
    method Bit#(32) rx_count;
    method Bit#(32) tx_count;
    method Bit#(32) error_count;
    method Bool     cc;

    interface Clock aurora_clk;
    interface Reset aurora_rst;

endinterface

import "BVI" aurora_8b10b_v5_2_example_design = 
module mkAURORA_SINGLE_UG (AURORA_SINGLE_DEVICE_UG);
   
    default_clock clk(INIT_CLK);
    default_reset rst(RESET_N); 

    output_clock aurora_clk(USER_CLK);
    output_reset aurora_rst(USER_RESET);

    method rxn_in(RXN) enable((*inhigh*) rxn_en) reset_by(no_reset) clocked_by(no_clock);
    method rxp_in(RXP) enable((*inhigh*) rxp_en) reset_by(no_reset) clocked_by(no_clock);
    method TXN txn_out reset_by(no_reset) clocked_by(no_clock); 
    method TXP txp_out reset_by(no_reset) clocked_by(no_clock);

    method rxn_in_dummy0(RXN_dummy_0) enable((*inhigh*) rxn_en_dummy0) reset_by(no_reset) clocked_by(no_clock);
    method rxp_in_dummy0(RXP_dummy_0) enable((*inhigh*) rxp_en_dummy0) reset_by(no_reset) clocked_by(no_clock);
    method TXN_dummy_0 txn_out_dummy0 reset_by(no_reset) clocked_by(no_clock); 
    method TXP_dummy_0 txp_out_dummy0 reset_by(no_reset) clocked_by(no_clock); 

    method rxn_in_dummy1(RXN_dummy_1) enable((*inhigh*) rxn_en_dummy1) reset_by(no_reset) clocked_by(no_clock);
    method rxp_in_dummy1(RXP_dummy_1) enable((*inhigh*) rxp_en_dummy1) reset_by(no_reset) clocked_by(no_clock);
    method TXN_dummy_1 txn_out_dummy1 reset_by(no_reset) clocked_by(no_clock); 
    method TXP_dummy_1 txp_out_dummy1 reset_by(no_reset) clocked_by(no_clock); 

    method rxn_in_dummy2(RXN_dummy_2) enable((*inhigh*) rxn_en_dummy2) reset_by(no_reset) clocked_by(no_clock); 
    method rxp_in_dummy2(RXP_dummy_2) enable((*inhigh*) rxp_en_dummy2) reset_by(no_reset) clocked_by(no_clock);
    method TXN_dummy_2 txn_out_dummy2 reset_by(no_reset) clocked_by(no_clock); 
    method TXP_dummy_2 txp_out_dummy2 reset_by(no_reset) clocked_by(no_clock); 

    method clk_n_in(GTPD0_N) enable((*inhigh*)clk_n_in_en) reset_by(no_reset) clocked_by(no_clock);
    method clk_p_in(GTPD0_P) enable((*inhigh*)clk_p_in_en) reset_by(no_reset) clocked_by(no_clock);

    method send(tx_d_i) enable(tx_en) ready(tx_rdy) reset_by(aurora_rst) clocked_by(aurora_clk);
    method stats(tx_fifo_count, tx_fifo_empty_n, tx_fifo_full_n, rx_fifo_count, rx_fifo_full_n,rx_fifo_empty_n) enable((*inhigh*)stats_en) reset_by(aurora_rst) clocked_by(aurora_clk); 
    method rx_d_i receive() enable(rx_en) ready(rx_rdy) reset_by(aurora_rst) clocked_by(aurora_clk);
    method cc_d_i cc() reset_by(aurora_rst) clocked_by(aurora_clk);
   
    // Although these guys are clocked by aurora clock (probably)
    // they are low-importance signals.
    method CHANNEL_UP channel_up;
    method LANE_UP lane_up;
    method HARD_ERR hard_err;
    method SOFT_ERR soft_err;
    method STATUS status;
    method RX_COUNT rx_count;
    method TX_COUNT tx_count;
    method ERROR_COUNT error_count;

    schedule (cc,stats, error_count, rx_count, tx_count, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err, status) CF
             (cc,stats, error_count, rx_count, tx_count, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err, status);
    schedule (send) CF (cc,stats, error_count, rx_count, tx_count, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err, status, receive);
    schedule (receive) CF (cc,stats, error_count, rx_count, tx_count, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err, status, send);
    schedule (send) C (send);   
    schedule (receive) C (receive);   
endmodule
