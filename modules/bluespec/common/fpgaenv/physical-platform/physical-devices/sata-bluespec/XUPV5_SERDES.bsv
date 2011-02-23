import Clocks::*;
import DiffClock::*;
import FIFOF::*;
import XUPV5_SERDES_UG::*;

typedef struct {
   Bool    isK;  // is Control
   Bit#(8) data; //                     
} XUPV5_SERDES_BYTE deriving(Bits, Eq);

// only 12 control are valid: 28, 60(comma), 92, 124, 156, 188(alternate comma), 220, 252, 247, 251, 253, 254
// 0 or 255 will be used to represent error
function XUPV5_SERDES_BYTE serdesControl(Bit#(8) ctrl_val);
   return XUPV5_SERDES_BYTE {isK: True, data: ctrl_val};
endfunction

function XUPV5_SERDES_BYTE serdesData(Bit#(8) data_val);
   return XUPV5_SERDES_BYTE {isK: False, data: data_val};
endfunction

typedef struct {
   XUPV5_SERDES_BYTE msb;
   XUPV5_SERDES_BYTE lsb;
} XUPV5_SERDES_WORD deriving (Bits, Eq);

function XUPV5_SERDES_WORD serdesWord(XUPV5_SERDES_BYTE msb, XUPV5_SERDES_BYTE lsb);
   return XUPV5_SERDES_WORD {msb: msb, lsb: lsb};
endfunction

function Tuple2#(Bit#(2), Bit#(16)) packTxWord (XUPV5_SERDES_WORD tx_word);
   Bit#(2)  txcharisk = {pack(tx_word.msb.isK), pack(tx_word.lsb.isK)};
   Bit#(16) txdata = {tx_word.msb.data, tx_word.lsb.data};
   return tuple2(txcharisk, txdata);
endfunction

function XUPV5_SERDES_WORD unpackRxWord (Bit#(2) is_error, Bit#(2) is_k, Bit#(16) rx_data);
   XUPV5_SERDES_BYTE rx0;
   XUPV5_SERDES_BYTE rx1;
   if (is_error[0] == 1)
      rx0 = serdesControl(0);
   else
      rx0 = XUPV5_SERDES_BYTE{isK: unpack(is_k[0]), data: rx_data[7:0]};
   if (is_error[1] == 1)
      rx1 = serdesControl(0);
   else
      rx1 = XUPV5_SERDES_BYTE{isK: unpack(is_k[1]), data: rx_data[15:8]};
   return serdesWord(rx1, rx0);
endfunction

interface XUPV5_SERDES_WIRES;
//   (* always_enabled, always_ready *)
   (* prefix = "" *)
   method Action serdes_clk_n((* port="GREFCLK_N_IN" *) Bit#(1) clk_n);

//   (* always_enabled, always_ready *)
   (* prefix = "" *)      
   method Action serdes_clk_p((* port="GREFCLK_P_IN" *) Bit#(1) clk_p);
   
//   (* always_enabled, always_ready *)
   (* prefix = "" *)      
   method Action rst_in((* port="GTPRESET_IN" *) Bit#(1) rst);      
      
   (* always_enabled, always_ready *)   
   (* prefix = "" *)      
   method Action rxn_in((* port="RXN_IN" *) Bit#(2) rxn);

   (* always_enabled, always_ready *)
   (* prefix = "" *)      
   method Action rxp_in((* port="RXP_IN" *) Bit#(2) rxp);

   (* always_ready *)
   (* result = "TXN_OUT" *)
   method Bit#(2) txn_out();

   (* always_ready *)
   (* result = "TXP_OUT" *)
   method Bit#(2) txp_out();
      
   // expose clock (not tied to any pin) just to make bluespec compiled
   interface Clock txusrclk;
   interface Reset txusrrst;
   interface Clock rxusrclk0;
   interface Reset rxusrrst0;
   interface Clock rxusrclk1;
   interface Reset rxusrrst1;
endinterface

// guard interface
interface XUPV5_SERDES_DRIVER;
   method Action send0(XUPV5_SERDES_WORD tx_word); // txusrclk 
   method Action send1(XUPV5_SERDES_WORD tx_word); // txusrclk
   method ActionValue#(XUPV5_SERDES_WORD) receive0(); // rxusrclk0     
   method ActionValue#(XUPV5_SERDES_WORD) receive1(); // rxusrclk1
   (* always_ready *)
   method Bool plllkdet_out();
   interface Clock txusrclk;
   interface Reset txusrrst;
   interface Clock rxusrclk0;
   interface Reset rxusrrst0;
   interface Clock rxusrclk1;
   interface Reset rxusrrst1;
endinterface

interface XUPV5_SERDES_DEVICE;
   (* prefix = "" *)      
   interface XUPV5_SERDES_WIRES wires;
   interface XUPV5_SERDES_DRIVER driver;
endinterface      

(* no_default_clock, no_default_reset *)
module mkXUPV5_SERDES_DEVICE#(XUPV5_SERDES_BYTE comma, // comma definition
                              Integer comma_period,    // how many cycles between commas?
                              Integer comma_length     // how many commas to send each time
                              ) 
   (XUPV5_SERDES_DEVICE);
   
   let diff_clk_device <- mkDiffClockWithReset();
   let fast_clk = diff_clk_device.clk_out;
   let fast_rst = diff_clk_device.rst_out;      
   let ug_device <- mkXUPV5_SERDES_DEVICE_UG(reset_by fast_rst, clocked_by fast_clk);
   Clock txusrclk  = ug_device.txusrclk;
   Clock rxusrclk0 = ug_device.rxusrclk0;
   Clock rxusrclk1 = ug_device.rxusrclk1;
   Reset reset0    = ug_device.reset0;
   Reset reset1    = ug_device.reset1;
   Reset txusrrst0 <- mkAsyncReset(10, reset0, txusrclk);
   Reset txusrrst1 <- mkAsyncReset(10, reset1, txusrclk);
   Reset txusrrst  <- mkResetEither(txusrrst0, txusrrst1, clocked_by txusrclk);
   Reset rxusrrst0 <- mkAsyncReset(10, reset0, rxusrclk0); 
   Reset rxusrrst1 <- mkAsyncReset(10, reset1, rxusrclk1);
   Reg#(Bool)     send_comma       <- mkReg(True, reset_by txusrrst, clocked_by txusrclk);
   Reg#(Bit#(16)) comma_cnt_down   <- mkReg(fromInteger(comma_length), reset_by txusrrst, clocked_by txusrclk);
   Reg#(Bool)     rx0_odd_aligned  <- mkReg(False, reset_by rxusrrst0, clocked_by rxusrclk0); 
   Reg#(Bool)     rx1_odd_aligned  <- mkReg(False, reset_by rxusrrst1, clocked_by rxusrclk1); 

   XUPV5_SERDES_WORD commas = serdesWord(comma, comma); 
   
   // should use bram fifos when put on awb
   FIFOF#(XUPV5_SERDES_WORD) send_data0     <- mkSizedFIFOF(10, reset_by txusrrst, clocked_by txusrclk);
   FIFOF#(XUPV5_SERDES_WORD) send_data1     <- mkSizedFIFOF(10, reset_by txusrrst, clocked_by txusrclk);
   FIFOF#(XUPV5_SERDES_BYTE) recv_data0_lsb <- mkSizedFIFOF(10, reset_by rxusrrst0, clocked_by rxusrclk0);
   FIFOF#(XUPV5_SERDES_BYTE) recv_data0_msb <- mkSizedFIFOF(10, reset_by rxusrrst0, clocked_by rxusrclk0);
   FIFOF#(XUPV5_SERDES_BYTE) recv_data1_lsb <- mkSizedFIFOF(10, reset_by rxusrrst1, clocked_by rxusrclk1);
   FIFOF#(XUPV5_SERDES_BYTE) recv_data1_msb <- mkSizedFIFOF(10, reset_by rxusrrst1, clocked_by rxusrclk1);
            
   rule update_counter (True);
      if (comma_cnt_down > 1)
         begin
            comma_cnt_down <= comma_cnt_down - 1;
         end
      else
         begin
            send_comma <= !send_comma;
            comma_cnt_down <= send_comma ? fromInteger(comma_period) : fromInteger(comma_length);
         end
   endrule
      
   rule xfer_send_data0 (True);
      Tuple2#(Bit#(2),Bit#(16)) tx_word;
      if (!send_comma && send_data0.notEmpty())
         begin
            tx_word = packTxWord(send_data0.first());
            send_data0.deq();
         end
      else
         begin
            tx_word = packTxWord(commas);
         end            
      match {.txcharisk, .txdata} = tx_word;
      ug_device.txdata0_in(txdata);
      ug_device.txcharisk0_in(txcharisk);
   endrule
   
   rule xfer_send_data1 (True);
      Tuple2#(Bit#(2),Bit#(16)) tx_word;
      if (!send_comma && send_data1.notEmpty())
         begin
            tx_word = packTxWord(send_data1.first());
            send_data1.deq();
         end
      else
         begin
            tx_word = packTxWord(commas);
         end            
      match {.txcharisk, .txdata} = tx_word;
      ug_device.txdata1_in(txdata);
      ug_device.txcharisk1_in(txcharisk);
   endrule
      
   rule xfer_recv_data0_odd (rx0_odd_aligned);
      let rx_word = unpackRxWord(ug_device.rxdisperr0_out, ug_device.rxcharisk0_out, ug_device.rxdata0_out);
      // swap q for odd aligned
      let lsb_q = recv_data0_msb;
      let msb_q = recv_data0_lsb;
      let lsb_not_comma = rx_word.lsb != comma;
      let msb_not_comma = rx_word.msb != comma;
      if (lsb_not_comma) // if first is comma, assume the 2nd will be too and don't enq anything (skip commas)
         begin
            lsb_q.enq(rx_word.lsb);
         end
      if (lsb_not_comma && msb_not_comma) 
         begin
            msb_q.enq(rx_word.msb);
         end
      rx0_odd_aligned <= !lsb_not_comma || msb_not_comma;
   endrule

   rule xfer_recv_data0_not_odd (!rx0_odd_aligned);
      let rx_word = unpackRxWord(ug_device.rxdisperr0_out, ug_device.rxcharisk0_out, ug_device.rxdata0_out);
      let lsb_not_comma = rx_word.lsb != comma;
      let msb_not_comma = rx_word.msb != comma;
      let new_rx0_odd_aligned = !lsb_not_comma && msb_not_comma; // odd aligned
      let msb_q = new_rx0_odd_aligned ? recv_data0_lsb : recv_data0_msb;
      let lsb_q = new_rx0_odd_aligned ? recv_data0_msb : recv_data0_lsb;
      if (lsb_not_comma && msb_not_comma) // only enq lsb if both not commas
         begin
            lsb_q.enq(rx_word.lsb);
         end
      if (msb_not_comma)
         begin
            msb_q.enq(rx_word.msb);
         end
      rx0_odd_aligned <= new_rx0_odd_aligned;
   endrule


   rule xfer_recv_data1_odd (rx1_odd_aligned);
      let rx_word = unpackRxWord(ug_device.rxdisperr1_out, ug_device.rxcharisk1_out, ug_device.rxdata1_out);
      // swap q for odd aligned
      let lsb_q = recv_data1_msb;
      let msb_q = recv_data1_lsb;
      let lsb_not_comma = rx_word.lsb != comma;
      let msb_not_comma = rx_word.msb != comma;
      if (lsb_not_comma) // if first is comma, assume the 2nd will be too and don't enq anything (skip commas)
         begin
            lsb_q.enq(rx_word.lsb);
         end
      if (lsb_not_comma && msb_not_comma) 
         begin
            msb_q.enq(rx_word.msb);
         end
      rx1_odd_aligned <= !lsb_not_comma || msb_not_comma;
   endrule

   rule xfer_recv_data1_not_odd (!rx1_odd_aligned);
      let rx_word = unpackRxWord(ug_device.rxdisperr1_out, ug_device.rxcharisk1_out, ug_device.rxdata1_out);
      let lsb_not_comma = rx_word.lsb != comma;
      let msb_not_comma = rx_word.msb != comma;
      let new_rx1_odd_aligned = !lsb_not_comma && msb_not_comma; // odd aligned
      let msb_q = new_rx1_odd_aligned ? recv_data1_lsb : recv_data1_msb;
      let lsb_q = new_rx1_odd_aligned ? recv_data1_msb : recv_data1_lsb;
      if (lsb_not_comma && msb_not_comma) // only enq lsb if both not commas
         begin
            lsb_q.enq(rx_word.lsb);
         end
      if (msb_not_comma)
         begin
            msb_q.enq(rx_word.msb);
         end
      rx1_odd_aligned <= new_rx1_odd_aligned;
   endrule   

   interface XUPV5_SERDES_WIRES wires;
      method serdes_clk_n = diff_clk_device.clk_n_in;
      method serdes_clk_p = diff_clk_device.clk_p_in;
      method rst_in = diff_clk_device.rst_in;
      method rxn_in = ug_device.rxn_in;
      method rxp_in = ug_device.rxp_in;
      method txn_out = ug_device.txn_out;
      method txp_out = ug_device.txp_out;
      interface txusrclk  = txusrclk;
      interface txusrrst  = txusrrst;
      interface rxusrclk0 = rxusrclk0;
      interface rxusrrst0 = rxusrrst0;
      interface rxusrclk1 = rxusrclk1;
      interface rxusrrst1 = rxusrrst1;
   endinterface
   
   interface XUPV5_SERDES_DRIVER driver;
      method Action send0(XUPV5_SERDES_WORD send_data);
         send_data0.enq(send_data);
      endmethod      

      method Action send1(XUPV5_SERDES_WORD send_data);
         send_data1.enq(send_data);
      endmethod 

      method ActionValue#(XUPV5_SERDES_WORD) receive0;
         recv_data0_lsb.deq();
         recv_data0_msb.deq();
         return serdesWord(recv_data0_msb.first(), recv_data0_lsb.first());
      endmethod

      method ActionValue#(XUPV5_SERDES_WORD) receive1;
         recv_data1_lsb.deq();
         recv_data1_msb.deq();
         return serdesWord(recv_data1_msb.first(), recv_data1_lsb.first());
      endmethod
      
      method Bool plllkdet_out();
         return ug_device.plllkdet_out();
      endmethod
      
      interface txusrclk  = txusrclk;
      interface txusrrst  = txusrrst;
      interface rxusrclk0 = rxusrclk0;
      interface rxusrrst0 = rxusrrst0;
      interface rxusrclk1 = rxusrclk1;
      interface rxusrrst1 = rxusrrst1;
   endinterface      
   
endmodule
