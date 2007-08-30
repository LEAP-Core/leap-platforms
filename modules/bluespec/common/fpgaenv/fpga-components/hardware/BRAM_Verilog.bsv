
import "BVI" BRAM = module mkBRAM_NonZero#(Integer low, Integer high, Bool load, String fname, Bool bin) 
  //interface:
              (BRAM#(idx_type, data_type)) 
  provisos
          (Bits#(idx_type, idx), 
	   Bits#(data_type, data),
	   Literal#(idx_type));

  default_clock clk(CLK);

  parameter addr_width = valueof(idx);
  parameter data_width = valueof(data);
  parameter lo = low;
  parameter hi = high;
  parameter loadfile = pack(load);
  parameter filename = fname;
  parameter binary = pack(bin);

  method DOUT read_resp() ready(DOUT_RDY) enable(DOUT_EN);
  
  method read_req(RD_ADDR) ready(RD_RDY) enable(RD_EN);
  method write(WR_ADDR, WR_VAL) enable(WR_EN);

  schedule read_req  CF (read_resp, write);
  schedule read_resp CF (read_req, write);
  schedule write     CF (read_req, read_resp);
  
  schedule read_req  C read_req;
  schedule read_resp C read_resp;
  schedule write     C write;

endmodule
