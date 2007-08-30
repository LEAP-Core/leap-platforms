import FIFOF::*;

// Top Level Wires for a FSB AFU

interface TopLevelWires;
    (* always_ready *)
    (* result = "Data_rd" *)
    method Bool data_rd();
    (* always_ready *)
    (* result = "Wrd_wr" *)
    method Bool wrd_wr();
    (* always_ready *)
    (* result = "Wrd_din" *)
    method Bit#(256) wrd_din();
    
    
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action chipscope((* port = "afu_ctrl" *) Bit#(36) ctrl);

    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action inp((* port = "Data_q" *) Bit#(256) data_q,
                      (* port = "Data_vld" *) Bool data_vld,
		      (* port = "Ci_begin" *) Bool ci_begin,
		      (* port = "Wrd_empty" *) Bool wrd_empty,
		      (* port = "Wrd_full" *)  Bool wrd_afull);
 
endinterface

interface TopLevelWiresDriver;
  
  interface TopLevelWires wires_out;
  method Action makeResponse(Bit#(256) data);
  method ActionValue#(Bit#(256)) getRequest();

endinterface

module mkTopLevelWiresDriver (TopLevelWiresDriver);

  Reg#(Bool) wr_en <- mkReg(False);
  Reg#(Bool) wr_en_delay <- mkReg(False);
  Reg#(Bool) rd_en <- mkReg(False);
  
  FIFOF#(Bit#(256)) inQ <- mkUGSizedFIFOF(32);
  FIFOF#(Bit#(256)) outQ <- mkUGFIFOF();
 
  RWire#(Bool) data_vld_wire <- mkRWire();
 
    interface TopLevelWires wires_out;

      method Action inp(Bit#(256) data_q, Bool data_vld, Bool ci_begin, Bool wrd_empty, Bool wrd_afull);

	//ci_begin:  intentionally unused
	//wrd_empty: intentionally unused

	rd_en <=outQ.notEmpty() && !wrd_afull;
	wr_en <= data_vld;
	wr_en_delay <= wr_en && data_vld;

	if (wr_en_delay)
	  inQ.enq(data_q); //TBD: the queue's FULL is not currently checked

	if (rd_en)
	  outQ.deq();

	data_vld_wire.wset(data_vld);

      endmethod

      method Action chipscope(Bit#(36) ctrl) = noAction;

      method data_rd = wr_en && validValue(data_vld_wire.wget());
      method wrd_wr = rd_en && outQ.notEmpty();
      method wrd_din = outQ.first();
 
    endinterface
 

    // interfaces to FPGA model
    //note: addition of guards below smoothly transition us to BSV world

    method Action makeResponse(Bit#(256) data) if (outQ.notFull());

      outQ.enq(data);

    endmethod

    method ActionValue#(Bit#(256)) getRequest() if (inQ.notEmpty()); 
      
      inQ.deq();
      return inQ.first();

    endmethod

endmodule

