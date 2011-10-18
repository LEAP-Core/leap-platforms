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

function Maybe#(t) extractData(XUPV5_SERDES_WORD word)
   provisos (Bits#(t,16));
   let retval = tagged Invalid;
   if(!word.msb.isK && !word.lsb.isK) 
     begin
       retval = tagged Valid (unpack({word.msb.data, word.lsb.data}));
     end
   return retval;
endfunction

function Tuple2#(Bit#(2), Bit#(16)) packTxWord (XUPV5_SERDES_WORD tx_word);
   Bit#(2)  txcharisk = {pack(tx_word.msb.isK), pack(tx_word.lsb.isK)};
   Bit#(16) txdata = {tx_word.msb.data, tx_word.lsb.data};
   return tuple2(txcharisk, txdata);
endfunction

function XUPV5_SERDES_WORD unpackRxWord (Bit#(2) is_error, Bit#(2) is_k, Bit#(16) rx_data, XUPV5_SERDES_BYTE comma);
   XUPV5_SERDES_BYTE rx0;
   XUPV5_SERDES_BYTE rx1;
   rx0 = XUPV5_SERDES_BYTE{isK: unpack(is_k[0]), data: rx_data[7:0]};
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
   method Bit#(16) total_reset_out(); // total_reset_out
   method Bit#(32) realignment0(); // realignment0
   method Bit#(32) errors0(); // realignment0
   method Bit#(32) realignment1(); // realignment0
   method Bit#(32) errors1(); // realignment0
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

   XUPV5_SERDES_WORD commas = serdesWord(comma, comma); 
   let idle = 28;
   XUPV5_SERDES_WORD idles = serdesWord(serdesControl(idle), serdesControl(idle)); 
   
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
   Reg#(Bit#(32)) rx0_realignment  <- mkReg(0, reset_by rxusrrst0, clocked_by rxusrclk0); 
   Reg#(Bit#(32)) rx0_errors  <- mkReg(0, reset_by rxusrrst0, clocked_by rxusrclk0); 
   Reg#(XUPV5_SERDES_WORD) last_rx0 <- mkReg(commas, reset_by rxusrrst0, clocked_by rxusrclk0);   
   Reg#(Bool)     rx1_odd_aligned  <- mkReg(False, reset_by rxusrrst1, clocked_by rxusrclk1); 
   Reg#(Bit#(32)) rx1_realignment  <- mkReg(0, reset_by rxusrrst1, clocked_by rxusrclk1); 
   Reg#(Bit#(32)) rx1_errors  <- mkReg(0, reset_by rxusrrst1, clocked_by rxusrclk1); 
   Reg#(XUPV5_SERDES_WORD) last_rx1 <- mkReg(commas, reset_by rxusrrst1, clocked_by rxusrclk1);   


   
   // should use bram fifos when put on awb
   FIFOF#(XUPV5_SERDES_WORD) send_data0     <- mkSizedFIFOF(10, reset_by txusrrst, clocked_by txusrclk);
   FIFOF#(XUPV5_SERDES_WORD) send_data1     <- mkSizedFIFOF(10, reset_by txusrrst, clocked_by txusrclk);
   FIFOF#(XUPV5_SERDES_WORD) recv_data0     <- mkSizedFIFOF(10, reset_by rxusrrst0, clocked_by rxusrclk0);
   FIFOF#(XUPV5_SERDES_WORD) recv_data1     <- mkSizedFIFOF(10, reset_by rxusrrst1, clocked_by rxusrclk1);

            
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
      else if(send_comma)
         begin
            tx_word = packTxWord(commas);
         end            
      else
         begin
            tx_word = packTxWord(idles);
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
      else if(send_comma)
         begin
            tx_word = packTxWord(commas);
         end            
      else
         begin
            tx_word = packTxWord(idles);
         end            

      match {.txcharisk, .txdata} = tx_word;
      ug_device.txdata1_in(txdata);
      ug_device.txcharisk1_in(txcharisk);
   endrule
      
//    rule xfer_recv_data0 (True);
//       let rx_word = unpackRxWord(ug_device.rxdisperr0_out, ug_device.rxcharisk0_out, ug_device.rxdata0_out);
//       recv_data0_lsb.enq(rx_word.lsb);
//       recv_data0_msb.enq(rx_word.msb);
//    endrule
   

   rule xfer_recv_data0 (True);
      let rx_word = unpackRxWord(ug_device.rxdisperr0_out, ug_device.rxcharisk0_out, ug_device.rxdata0_out, comma);
      last_rx0 <= rx_word;
      let lsb_not_comma = rx_word.lsb != comma;
      let msb_not_comma = rx_word.msb != comma;
      let lsb_comma = rx_word.lsb == comma;
      let msb_comma = rx_word.msb == comma;
      // Fix me

      XUPV5_SERDES_WORD candidate = (rx0_odd_aligned)?XUPV5_SERDES_WORD{msb: rx_word.lsb, lsb: last_rx0.msb}:   // Odd aligned case      
                                                      rx_word;            //           even aligned case

      rx0_errors <= rx0_errors + zeroExtend(ug_device.rxdisperr0_out[0]) + zeroExtend(ug_device.rxdisperr0_out[1]);

      if (candidate.msb != comma && candidate.lsb != comma) 
         begin
            recv_data0.enq(candidate);
         end
 
      // maybe we should consider something as radical as 
      // clearing the fifos?
      if (unpack(pack(lsb_not_comma)^pack(msb_not_comma)) && (ug_device.rxdisperr0_out[0] == 0) && (ug_device.rxdisperr0_out[1] == 0))
         begin
            rx0_odd_aligned <= True;
            if(!rx0_odd_aligned)
              begin
	        rx0_realignment <= rx0_realignment + 1;
	      end
         end
      else if((lsb_comma && msb_comma) && (ug_device.rxdisperr0_out[0] == 0) && (ug_device.rxdisperr0_out[1] == 0))  // Both commas == not odd aligned
        begin
          rx0_odd_aligned <= False;
           if(rx0_odd_aligned)
             begin
	       rx0_realignment <= rx0_realignment + 1;
	     end
        end
   endrule


   rule xfer_recv_data1 (True);
      let rx_word = unpackRxWord(ug_device.rxdisperr1_out, ug_device.rxcharisk1_out, ug_device.rxdata1_out, comma);
      last_rx1 <= rx_word;
      let lsb_not_comma = rx_word.lsb != comma;
      let msb_not_comma = rx_word.msb != comma;
      let lsb_comma = rx_word.lsb == comma;
      let msb_comma = rx_word.msb == comma;
      // Fix me

      XUPV5_SERDES_WORD candidate = (rx1_odd_aligned)?XUPV5_SERDES_WORD{msb: rx_word.lsb, lsb: last_rx1.msb}:   // Odd aligned case
                                                      rx_word;            //           even aligned case

      rx1_errors <= rx1_errors + zeroExtend(ug_device.rxdisperr1_out[0]) + zeroExtend(ug_device.rxdisperr1_out[1]);

      if (candidate.msb != comma && candidate.lsb != comma)
         begin
            recv_data1.enq(candidate);
         end

      // maybe we should consider something as radical as
      // clearing the fifos?
      if (unpack(pack(lsb_not_comma)^pack(msb_not_comma)) && (ug_device.rxdisperr1_out[0] == 0) && (ug_device.rxdisperr1_out[1] == 0))
         begin
            rx1_odd_aligned <= True;
            if(!rx1_odd_aligned)
              begin
                rx1_realignment <= rx1_realignment + 1;
              end
         end
      else if((lsb_comma && msb_comma) && (ug_device.rxdisperr1_out[0] == 0) && (ug_device.rxdisperr1_out[1] == 0))  // Both commas == not odd aligned
        begin
          rx1_odd_aligned <= False;
           if(rx1_odd_aligned)
             begin
               rx1_realignment <= rx1_realignment + 1;
             end
        end
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
         recv_data0.deq();
         return recv_data0.first();
      endmethod

      method ActionValue#(XUPV5_SERDES_WORD) receive1;
         recv_data1.deq();
         return recv_data1.first();
      endmethod
      
      method Bool plllkdet_out();
         return ug_device.plllkdet_out();
      endmethod

      method total_reset_out = ug_device.total_reset_out;
      method realignment0 = rx0_realignment._read;
      method errors0()= rx0_errors._read; // realignment0	
      method realignment1 = rx1_realignment._read;
      method errors1()= rx1_errors._read; // realignment0	
      interface txusrclk  = txusrclk;
      interface txusrrst  = txusrrst;
      interface rxusrclk0 = rxusrclk0;
      interface rxusrrst0 = rxusrrst0;
      interface rxusrclk1 = rxusrclk1;
      interface rxusrrst1 = rxusrrst1;
   endinterface      
   
endmodule
