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
	method Action tx_data_out(Bit#(16) tx);
	method ActionValue#(Bit#(16)) rx_data_in();

    method Action rxn_in(Bit#(1) i);
    method Action rxp_in(Bit#(1) i);
    (* always_ready *)
    method Bit#(1) txn_out();
    (* always_ready *)
    method Bit#(1) txp_out();
//	method Action init_clk_p();
//	method Action init_clk_n();
(* always_enabled, always_ready *)
	method Action gtxq_p(Bit#(1) d);
	(* always_enabled, always_ready *)
	method Action gtxq_n(Bit#(1) d);
    
		method Bit#(1) channel_up;
    method Bit#(1) lane_up;
    method Bit#(1) hard_err;
    method Bit#(1) soft_err;
		/*
    method Bit#(32) status;
    method Bit#(32) rx_count;
    method Bit#(32) tx_count;
    method Bit#(32) error_count;
		*/
		interface Clock aurora_clk;
		interface Reset aurora_rst;
endinterface

import "BVI" aurora_8b10b_v5_3_example_design = 
module mkAURORA_SINGLE_UG (AURORA_SINGLE_DEVICE_UG);

	default_clock input_clk(INIT_CLK);
	default_reset input_rst(RESET_N);

	output_clock aurora_clk(USER_CLK);
	output_reset aurora_rst(USER_RST) clocked_by (aurora_clk);

	method gtxq_p(GTXQ0_P) enable((*inhigh*) gtxq_p_en) reset_by(no_reset) clocked_by(no_clock);
	method gtxq_n(GTXQ0_N) enable((*inhigh*) gtxq_n_en) reset_by(no_reset) clocked_by(no_clock);
	method rxn_in(RXN) enable((*inhigh*) rx_n_en) reset_by(no_reset) clocked_by(no_clock);
	method rxp_in(RXP) enable((*inhigh*) rx_p_en) reset_by(no_reset) clocked_by(no_clock);
	method TXN txn_out() reset_by(no_reset) clocked_by(no_clock);
	method TXP txp_out() reset_by(no_reset) clocked_by(no_clock);

	method CHANNEL_UP channel_up;
	method LANE_UP lane_up;
	method HARD_ERR hard_err;
	method SOFT_ERR soft_err;

	method tx_data_out(TX_DATA_OUT) enable((*inhigh*) tx_d_en) ready(tx_rdy) clocked_by(aurora_clk) reset_by(aurora_rst); 
	method RX_DATA_IN rx_data_in() enable((*inhigh*) rx_en) ready(rx_rdy) clocked_by(aurora_clk) reset_by(aurora_rst);
/*
	schedule (rxn_in, rxp_in, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err) CF 
		(rxn_in, rxp_in, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err);
	schedule (rx_data_in) CF (rxn_in, rxp_in, txn_out, txp_out, tx_data_out, channel_up, lane_up, hard_err, soft_err);
	schedule (tx_data_out) CF (rxn_in, rxp_in, txn_out, txp_out, rx_data_in, channel_up, lane_up, hard_err, soft_err);
	*/
	schedule (gtxq_p, gtxq_n, rxn_in, rxp_in, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err) CF 
		(gtxq_p, gtxq_n, rxn_in, rxp_in, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err);
	schedule (rx_data_in) CF (gtxq_p, gtxq_n, rxn_in, rxp_in, txn_out, txp_out, tx_data_out, channel_up, lane_up, hard_err, soft_err);
	schedule (tx_data_out) CF (gtxq_p, gtxq_n, rxn_in, rxp_in, txn_out, txp_out, rx_data_in, channel_up, lane_up, hard_err, soft_err);
	schedule (tx_data_out) C (tx_data_out);
	schedule (rx_data_in) C (rx_data_in);

endmodule
