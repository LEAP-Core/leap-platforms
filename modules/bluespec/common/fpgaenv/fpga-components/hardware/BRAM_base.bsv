
//One RAM.
interface BRAM#(type idx_type, type data_type);

  method Action read_req(idx_type idx);

  method ActionValue#(data_type) read_resp();

  method Action	write(idx_type idx, data_type data);
  
endinterface


//Two RAMs.
interface BRAM_2#(type idx_type, type data_type);

  method Action read_req1(idx_type idx);
  method Action read_req2(idx_type idx);

  method ActionValue#(data_type) read_resp1();
  method ActionValue#(data_type) read_resp2();

  method Action	write(idx_type idx, data_type data);
  
endinterface

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


