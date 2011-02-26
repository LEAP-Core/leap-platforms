interface VIO;
   (* always_ready *)
   method Bit#(32) async_out;
   (* always_enabled, always_ready *)
   method Action   async_in(Bit#(32) data);
endinterface

interface ILA;
   (* always_enabled, always_ready *)
   method Action trig_in(Bit#(48) trig);
endinterface

interface XUPV5_CHIPSCOPES;
   interface VIO tx_vio0;
   interface VIO rx_vio0;
   interface ILA rx_data_ila0;
   interface ILA rx_err_ila0;
   interface ILA rx_cnt_ila0;
   interface VIO tx_vio1;
   interface VIO rx_vio1;
   interface ILA rx_data_ila1;
   interface ILA rx_err_ila1;
   interface ILA rx_cnt_ila1;
endinterface     

import "BVI" chipscope_ip =
module mkXUPV5_CHIPSCOPES#(Clock txclk, Clock rxclk0, Clock rxclk1) (XUPV5_CHIPSCOPES);
   
   default_clock no_clock;
   default_reset no_reset;
   
   input_clock (txclk) = txclk; 
   input_clock (rxclk0) = rxclk0;
   input_clock (rxclk1) = rxclk1;
   
   interface VIO tx_vio0;
      method tx_vio_out0_i async_out reset_by(no_reset) clocked_by(txclk);
      method async_in(tx_vio_in0_i) enable((*inhigh*)tx_vio_in0_en) reset_by(no_reset) clocked_by(txclk);
   endinterface

   interface VIO rx_vio0;
      method rx_vio_out0_i async_out reset_by(no_reset) clocked_by(rxclk0);
      method async_in(rx_vio_in0_i) enable((*inhigh*)rx_vio_in0_en) reset_by(no_reset) clocked_by(rxclk0);
   endinterface
   
   interface ILA rx_data_ila0;
      method trig_in(rx_data_ila_in0_i) enable((*inhigh*)rx_data_ila_in0_en) reset_by(no_reset) clocked_by(rxclk0);
   endinterface

   interface ILA rx_err_ila0;
      method trig_in(rx_err_ila_in0_i) enable((*inhigh*)rx_err_ila_in0_en) reset_by(no_reset) clocked_by(rxclk0);
   endinterface

   interface ILA rx_cnt_ila0;
      method trig_in(rx_cnt_ila_in0_i) enable((*inhigh*)rx_data_cnt_in0_en) reset_by(no_reset) clocked_by(rxclk0);
   endinterface

   interface VIO tx_vio1;
      method tx_vio_out1_i async_out reset_by(no_reset) clocked_by(txclk);
      method async_in(tx_vio_in1_i) enable((*inhigh*)tx_vio_in1_en) reset_by(no_reset) clocked_by(txclk);
   endinterface

   interface VIO rx_vio1;
      method rx_vio_out1_i async_out reset_by(no_reset) clocked_by(rxclk1);
      method async_in(rx_vio_in1_i) enable((*inhigh*)rx_vio_in1_en) reset_by(no_reset) clocked_by(rxclk1);
   endinterface
   
   interface ILA rx_data_ila1;
      method trig_in(rx_data_ila_in1_i) enable((*inhigh*)rx_data_ila_in1_en) reset_by(no_reset) clocked_by(rxclk1);
   endinterface

   interface ILA rx_err_ila1;
      method trig_in(rx_err_ila_in1_i) enable((*inhigh*)rx_err_ila_in1_en) reset_by(no_reset) clocked_by(rxclk1);
   endinterface

   interface ILA rx_cnt_ila1;
      method trig_in(rx_cnt_ila_in1_i) enable((*inhigh*)rx_data_cnt_in1_en) reset_by(no_reset) clocked_by(rxclk1);
   endinterface
   
      
   schedule (tx_vio0.async_out, tx_vio0.async_in, rx_vio0.async_out, rx_vio0.async_in,
             rx_data_ila0.trig_in, rx_err_ila0.trig_in, rx_cnt_ila0.trig_in,
             tx_vio1.async_out, tx_vio1.async_in, rx_vio1.async_out, rx_vio1.async_in,
             rx_data_ila1.trig_in, rx_err_ila1.trig_in, rx_cnt_ila1.trig_in ) CF
            (tx_vio0.async_out, tx_vio0.async_in, rx_vio0.async_out, rx_vio0.async_in,
             rx_data_ila1.trig_in, rx_err_ila0.trig_in, rx_cnt_ila0.trig_in,
             tx_vio1.async_out, tx_vio1.async_in, rx_vio1.async_out, rx_vio1.async_in,
             rx_data_ila1.trig_in, rx_err_ila1.trig_in, rx_cnt_ila1.trig_in );
endmodule
   