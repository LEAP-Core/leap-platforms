// unguard interface
interface XUPV5_SERDES_DEVICE_UG;
   (* always_enabled, always_ready *)   
   method Action rxn_in(Bit#(2) rxn);
   (* always_enabled, always_ready *)
   method Action rxp_in(Bit#(2) rxp);
   (* always_ready *)
   method Bit#(2) txn_out();
   (* always_ready *)
   method Bit#(2) txp_out();
   (* always_ready *)
   method Bool plllkdet_out();
   (* always_ready *)
   method Bit#(2) rxcharisk0_out();
   (* always_ready *)
   method Bit#(2) rxdisperr0_out();
   (* always_ready *)
   method Bit#(16) rxdata0_out();
   (* always_ready *)
   method Bit#(16) total_reset_out();
   (* always_ready *)
   method Bit#(2) rxcharisk1_out();
   (* always_ready *)
   method Bit#(2) rxdisperr1_out();
   (* always_ready *)
   method Bit#(16) rxdata1_out();
   (* always_enabled, always_ready *)
   method Action txcharisk0_in(Bit#(2) k);
   (* always_enabled, always_ready *)
   method Action txdata0_in(Bit#(16) data);
   (* always_enabled, always_ready *)
   method Action txcharisk1_in(Bit#(2) k);
   (* always_enabled, always_ready *)
   method Action txdata1_in(Bit#(16) data);
   interface Clock txusrclk;
   interface Clock rxusrclk0;
   interface Clock rxusrclk1;
   interface Reset reset0;
   interface Reset reset1;
endinterface

import "BVI" serdes_ip = 
module mkXUPV5_SERDES_DEVICE_UG (XUPV5_SERDES_DEVICE_UG);
   
   default_clock clk(grefclk_i);
   default_reset rst(gtpreset_n_in);
   
   output_clock txusrclk(txusrclk_out);
   output_clock rxusrclk0(rxusrclk0_out);
   output_clock rxusrclk1(rxusrclk1_out);
   output_reset reset0(resetdone0_out);
   output_reset reset1(resetdone1_out);
   
   method rxn_in(RXN_IN) enable((*inhigh*) rxn_en) reset_by(no_reset) clocked_by(txusrclk);
   method rxp_in(RXP_IN) enable((*inhigh*) rxp_en) reset_by(no_reset) clocked_by(txusrclk);
   method TXN_OUT txn_out reset_by(no_reset) clocked_by(no_clock); 
   method TXP_OUT txp_out reset_by(no_reset) clocked_by(no_clock);
   method PLLLKDET_OUT plllkdet_out reset_by(no_reset) clocked_by(no_clock);
   method rxcharisk0_out rxcharisk0_out reset_by(no_reset) clocked_by(rxusrclk0);
   method rxdisperr0_out rxdisperr0_out reset_by(no_reset) clocked_by(rxusrclk0);
   method rxdata0_out rxdata0_out reset_by(no_reset) clocked_by(rxusrclk0);
   method total_reset_out total_reset_out reset_by(no_reset) clocked_by(rxusrclk0);
   method rxcharisk1_out rxcharisk1_out reset_by(no_reset) clocked_by(rxusrclk1);
   method rxdisperr1_out rxdisperr1_out reset_by(no_reset) clocked_by(rxusrclk1);
   method rxdata1_out rxdata1_out reset_by(no_reset) clocked_by(rxusrclk1);
   method txcharisk0_in(txcharisk0_in) enable((*inhigh*)txcharisk0_en) reset_by(no_reset) clocked_by(txusrclk);
   method txdata0_in(txdata0_in) enable((*inhigh*)txdata0_en) reset_by(no_reset) clocked_by(txusrclk);
   method txcharisk1_in(txcharisk1_in) enable((*inhigh*)txcharisk1_en) reset_by(no_reset) clocked_by(txusrclk);
   method txdata1_in(txdata1_in) enable((*inhigh*)txdata1_en) reset_by(no_reset) clocked_by(txusrclk);
   
   schedule (rxn_in, rxp_in, 
             txn_out, txp_out, rxcharisk0_out, rxdisperr0_out,
             rxdata0_out, rxcharisk1_out, rxdisperr1_out, rxdata1_out,
             plllkdet_out, txcharisk0_in, txdata0_in,
             txcharisk1_in, txdata1_in, total_reset_out) CF
            (rxn_in, rxp_in, 
             txn_out, txp_out, rxcharisk0_out, rxdisperr0_out,
             rxdata0_out, rxcharisk1_out, rxdisperr1_out, rxdata1_out,
             plllkdet_out, txcharisk0_in, txdata0_in, 
             txcharisk1_in, txdata1_in, total_reset_out);   
endmodule
