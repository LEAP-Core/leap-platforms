
import FIFO::*;
import RegFile::*;

//No one should call this directly

module mkBRAM_NonZero#(Integer low, Integer high, Bool loadfile, String fname, Bool bin)
  //interface:
              (BRAM#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));
  
  FIFO#(data_type) q <- mkFIFO();
  
  RegFile#(idx_type, data_type) arr <- (loadfile) ? 
                                     (bin) ? 
				         mkRegFileWCFLoadBin(fname, fromInteger(low), fromInteger(high)) :
					 mkRegFileWCFLoad(fname, fromInteger(low), fromInteger(high)) : 
				         mkRegFileWCF(fromInteger(low), fromInteger(high));
  
  Reg#(data_type) ramout <- mkRegU();
  Reg#(Bool) rd_req_made <- mkReg(False);
  
  Reg#(Bit#(2)) ctr <- mkReg(2);
  PulseWire dummy <- mkPulseWire();
  
  rule xfer (rd_req_made);
  
    q.enq(ramout);
    rd_req_made <= False;
  
  endrule

  method Action read_req(idx_type i);
     ramout <= arr.sub(i);
     rd_req_made <= True;
     dummy.send();
  endmethod

  method Action write(idx_type i, data_type d);
    arr.upd(i, d);
  endmethod

  method ActionValue#(data_type) read_resp();
    q.deq();
    return q.first();
  endmethod
  
endmodule

