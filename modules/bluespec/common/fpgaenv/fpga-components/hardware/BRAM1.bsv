import FIFO::*;

//These are the functions people should use

//One RAM.
interface BRAM#(type idx_type, type data_type);

  method Action read_req(idx_type idx);

  method ActionValue#(data_type) read_resp();

  method Action	write(idx_type idx, data_type data);
  
endinterface


//Standard BRAM
module mkBRAM#(Integer low, Integer high) 
  //interface:
              (BRAM#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));
	   
  BRAM#(idx_type, data_type) m <- mkBRAM_Optimal(low, high, False, "", False);

  return m;

endmodule

//BRAM which loads a file in simulation
module mkBRAM_Load#(Integer low, Integer high, String fname) 
  //interface:
              (BRAM#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));
	   
  BRAM#(idx_type, data_type) m <- mkBRAM_Optimal(low, high, True, fname, False);

  return m;

endmodule

//BRAM which loads a binary file in simulation
module mkBRAM_LoadBin#(Integer low, Integer high, String fname) 
  //interface:
              (BRAM#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));
	   
  BRAM#(idx_type, data_type) m <- mkBRAM_Optimal(low, high, True, fname, True);

  return m;

endmodule

module mkBRAM_Full 
  //interface:
              (BRAM#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));


  BRAM#(idx_type, data_type) br <- mkBRAM(0, valueof(TExp#(idx)) - 1);

  return br;

endmodule

module mkInitializedBRAM_Full#(data_type init)(BRAM#(idx_type, data_type))
    provisos(Bits#(idx_type, idx),
             Add#(idx, 1, idx_1),
             Bits#(data_type, dSz),
             Literal#(idx_type));

    BRAM#(idx_type, data_type) br <- mkBRAM(0, valueOf(TExp#(idx)) - 1);
    Reg#(Bit#(idx_1)) initialize <- mkReg(0);

    Bool initialized = initialize[valueOf(idx)] == 1;

    rule initializing(!initialized);
        initialize <= initialize + 1;
        br.write(unpack(truncate(initialize)), init);
    endrule

    method Action read_req(idx_type idx) if(initialized);
        br.read_req(idx);
    endmethod

    method ActionValue#(data_type) read_resp() if(initialized);
        let d <- br.read_resp();
        return d;
    endmethod

    method Action	write(idx_type idx, data_type data) if(initialized);
        br.write(idx, data);
    endmethod
endmodule

module mkBRAM_Full_Load#(String fname) 
  //interface:
              (BRAM#(idx_type, data_type))
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));


  BRAM#(idx_type, data_type) br <- mkBRAM_Load(0, valueof(TExp#(idx)) - 1, fname);

  return br;

endmodule

module mkBRAM_Full_LoadBin#(String fname) 
  //interface:
              (BRAM#(idx_type, data_type))
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));


  BRAM#(idx_type, data_type) br <- mkBRAM_LoadBin(0, valueof(TExp#(idx)) - 1, fname);

  return br;

endmodule

//The rest should not be called directly by the outside world


module mkBRAM_Optimal#(Integer low, Integer high, Bool loadfile, String fname, Bool bin) 
  //interface:
              (BRAM#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
           Add#(idx, 1, idx_1),
	   Bits#(data_type, data),
	   Literal#(idx_type));
	   
  BRAM#(idx_type, data_type) m <- (valueof(data) == 0) ? 
                                  mkBRAM_Zero() :
				  mkBRAM_NonZero(low, high, loadfile, fname, bin);

    Reg#(Bit#(idx_1)) initialize <- mkReg(fromInteger(low));

    Bool initialized = initialize == fromInteger(high + 1);

    rule initializing(!initialized);
        initialize <= initialize + 1;
        m.write(unpack(truncate(initialize)), unpack(zeroExtend('b0)));
    endrule

  method Action read_req(idx_type i) if(initialized);
      m.read_req(i);
  endmethod

  method Action write(idx_type i, data_type d) if(initialized);
      m.write(i, d);
  endmethod

  method ActionValue#(data_type) read_resp() if(initialized);
      let d <- m.read_resp();
      return d;
  endmethod

endmodule

module mkBRAM_Zero
  //interface:
              (BRAM#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx),
	   Bits#(data_type, data),
	   Literal#(idx_type));
  
  FIFO#(data_type) q <- mkFIFO();

  method Action read_req(idx_type i);
     q.enq(?);
  endmethod

  method Action write(idx_type i, data_type d);
    noAction;
  endmethod

  method ActionValue#(data_type) read_resp();
    q.deq();
    return q.first();
  endmethod

endmodule


