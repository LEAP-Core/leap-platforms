import FIFO::*;

//Three RAMs.
interface BRAM_3#(type idx_type, type data_type);

  method Action read_req1(idx_type idx);
  method Action read_req2(idx_type idx);
  method Action read_req3(idx_type idx);

  method ActionValue#(data_type) read_resp1();
  method ActionValue#(data_type) read_resp2();
  method ActionValue#(data_type) read_resp3();

  method Action	write(idx_type idx, data_type data);
  
endinterface


//Standard Triple BRAM
module mkBRAM_3#(Integer low, Integer high) 
  //interface:
              (BRAM_3#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));
	   
  BRAM_3#(idx_type, data_type) m <- mkBRAM_3_Optimal(low, high, False, "", False);

  return m;

endmodule

//BRAM which loads a file in simulation
module mkBRAM_3_Load#(Integer low, Integer high, String fname) 
  //interface:
              (BRAM_3#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));
	   
  BRAM_3#(idx_type, data_type) m <- mkBRAM_3_Optimal(low, high, True, fname, False);

  return m;

endmodule

//BRAM which loads a binary file in simulation
module mkBRAM_3_LoadBin#(Integer low, Integer high, String fname) 
  //interface:
              (BRAM_3#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
       Literal#(data_type),
	   Literal#(idx_type));
	   
  BRAM_3#(idx_type, data_type) m <- mkBRAM_3_Optimal(low, high, True, fname, True);

  return m;

endmodule

module mkBRAM_3_Full 
  //interface:
              (BRAM_3#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));


  BRAM_3#(idx_type, data_type) br <- mkBRAM_3(0, valueof(TExp#(idx)) - 1);

  return br;

endmodule

module mkBRAM_3_Full_Load#(String fname)
  //interface:
              (BRAM_3#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));


  BRAM_3#(idx_type, data_type) br <- mkBRAM_3_Load(0, valueof(TExp#(idx)) - 1, fname);

  return br;

endmodule

module mkBRAM_3_Full_LoadBin#(String fname)
  //interface:
              (BRAM_3#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
       Literal#(data_type),
	   Literal#(idx_type));


  BRAM_3#(idx_type, data_type) br <- mkBRAM_3_LoadBin(0, valueof(TExp#(idx)) - 1, fname);

  return br;

endmodule

//The rest should not be called directly by the outside world


module mkBRAM_3_Optimal#(Integer low, Integer high, Bool loadfile, String fname, Bool bin) 
  //interface:
              (BRAM_3#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));
	   
  BRAM#(idx_type, data_type) br1 <- mkBRAM_Optimal(low, high, loadfile, fname, bin);
  BRAM#(idx_type, data_type) br2 <- mkBRAM_Optimal(low, high, loadfile, fname, bin);
  BRAM#(idx_type, data_type) br3 <- mkBRAM_Optimal(low, high, loadfile, fname, bin);
  
  method read_req1(idx) = br1.read_req(idx);
  method read_req2(idx) = br2.read_req(idx);
  method read_req3(idx) = br3.read_req(idx);

  method read_resp1() = br1.read_resp();
  method read_resp2() = br2.read_resp();
  method read_resp3() = br3.read_resp();

  method Action	write(idx_type idx, data_type data);
  
    br1.write(idx, data);
    br2.write(idx, data);
    br3.write(idx, data);
  
  endmethod
  
endmodule


