// unguard interface
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
   method Bool     cc;

   interface Clock aurora_clk;
   interface Reset aurora_rst;

endinterface

import "BVI" aurora_8b10b_v5_2_example_design = 
module mkXUPV5_AURORA_SINGLE_UG (AURORA_SINGLE_DEVICE_UG);
   
   default_clock clk(INIT_CLK);
   default_reset rst(RESET_N); // Assert high....

   output_clock aurora_clk(USER_CLK);
   output_reset aurora_rst(USER_RESET);

   method rxn_in(RXN) enable((*inhigh*) rxn_en) reset_by(no_reset) clocked_by(no_clock);
   method rxp_in(RXP) enable((*inhigh*) rxp_en) reset_by(no_reset) clocked_by(no_clock);
   method TXN txn_out reset_by(no_reset) clocked_by(no_clock); 
   method TXP txp_out reset_by(no_reset) clocked_by(no_clock);
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

   schedule (stats, rx_count, tx_count, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err, status) CF
            (stats, rx_count, tx_count, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err, status);
   schedule (send) CF (stats, rx_count, tx_count, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err, status, receive);
   schedule (receive) CF (stats, rx_count, tx_count, txn_out, txp_out, channel_up, lane_up, hard_err, soft_err, status, send);
   schedule (send) C (send);   
   schedule (receive) C (receive);   
endmodule
