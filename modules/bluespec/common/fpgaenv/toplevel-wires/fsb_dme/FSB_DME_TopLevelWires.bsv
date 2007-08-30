import FIFOF::*;

// Top Level Wires for FSB DME

interface TopLevelWires;

    //All output signals:
    
    //Command Headers from DME to FSB
    (* result = "Ld2f_cmdhdr", ready = "Ld2f_cmdPush" *)
    method Bit#(75) cmd_to_fsb();
    //Data from DME to FSB
    (* result = "Ld2f_daQueData", ready = "Ld2f_daQuePush" *)
    method Bit#(256) data_to_fsb();
    (* always_ready *)
    (* result = "Ld2f_daQuePushBgn" *)
    method Bool data_xfer_begin();
    (* always_ready *)
    (* result = "Ld2f_daQuePushEnd" *)
    method Bool data_xfer_end();
    //Command Headers from FSB to DME
    (* always_ready *)
    (* result = "Ld2f_Rsp_almf" *)
    method Bool cmd_from_fsb_almost_full();
    //Data from FSB to DME
    (* always_ready *)
    (* result = "Ld2f_data_almf" *)
    method Bool data_from_fsb_almost_full();
    
    //All input signals: 
    
    //Chipscope
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action chipscope((* port = "dme_cs_control0" *) Bit#(36) dme_cs_control0, (* port = "dme_cs_control1" *) Bit#(36) dme_cs_control1);

    //All other input
    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action inp((* port = "Lf2d_Data" *)        Bit#(256) data_from_fsb,
                      (* port = "Lf2d_Rsphdr" *)      Bit#(75) cmd_from_fsb,
                      (* port = "Lf2d_cmdQue_almf" *) Bool cmd_to_fsb_almost_full,
		      (* port = "Lf2d_daQue_almf" *)  Bool data_to_fsb_almost_full,
		      (* port = "Lf2d_RspPush" *)     Bool cmd_from_fsb_ready,
		      (* port = "Lf2d_dataPush" *)    Bool data_from_fsb_ready,
		      (* port = "Lf2d_dataPushBgn" *)    Bool data_from_fsb_xfer_begin,
		      (* port = "Lf2d_dataPushEnd" *)    Bool data_from_fsb_xfer_end);
 
endinterface

interface TopLevelWiresDriver;
  
  interface TopLevelWires wires_out;
  method Action putData(Bit#(256) data, Bool begin_xfer, Bool end_xfer);
  method ActionValue#(Tuple3#(Bit#(256), Bool, Bool)) getData();
  method Action putCmd(Bit#(75) cmd);
  method ActionValue#(Bit#(75)) getCmd();

endinterface

module mkTopLevelWiresDriver (TopLevelWiresDriver);

  Reg#(Bool) fsb_cmd_was_almost_full  <- mkReg(False);
  Reg#(Bool) fsb_data_was_almost_full <- mkReg(False);

  FIFOF#(Tuple3#(Bit#(256), Bool, Bool)) data_inQ  <- mkUGFIFOF();
  Wire#(Bit#(256))  data_outW <- mkWire();
  PulseWire data_xfer_beginW <- mkPulseWire();
  PulseWire data_xfer_endW   <- mkPulseWire();
 
  FIFOF#(Bit#(75)) cmd_inQ  <- mkUGFIFOF();
  Wire#(Bit#(75))  cmd_outW <- mkWire();

  //Extra buffering to translate "full" to "almost full"
  FIFOF#(Tuple3#(Bit#(256), Bool, Bool)) data_inQ_backup  <- mkUGFIFOF1();
  FIFOF#(Bit#(75)) cmd_inQ_backup  <- mkUGFIFOF1();
  
 
    interface TopLevelWires wires_out;

      method Action inp(Bit#(256) data_from_fsb, Bit#(75) cmd_from_fsb, Bool cmd_to_fsb_almost_full, Bool data_to_fsb_almost_full, Bool cmd_from_fsb_ready, Bool data_from_fsb_ready, Bool data_from_fsb_xfer_begin, Bool data_from_fsb_xfer_end);

        if (data_from_fsb_ready)
	  if (data_inQ.notFull())
	    data_inQ.enq(tuple3(data_from_fsb, data_from_fsb_xfer_begin, data_from_fsb_xfer_end));
	  else
	    data_inQ_backup.enq(tuple3(data_from_fsb, data_from_fsb_xfer_begin, data_from_fsb_xfer_end));
	else if (data_inQ_backup.notEmpty())
	  begin
	    data_inQ.enq(data_inQ_backup.first());
	    data_inQ_backup.deq();
	  end
	
	if (cmd_from_fsb_ready)
	  if (cmd_inQ.notFull())
	    cmd_inQ.enq(cmd_from_fsb);
	  else
	    cmd_inQ_backup.enq(cmd_from_fsb);
	else if (cmd_inQ_backup.notEmpty())
	  begin
	    cmd_inQ.enq(cmd_inQ_backup.first());
	    cmd_inQ_backup.deq();
	  end

        fsb_cmd_was_almost_full  <= cmd_to_fsb_almost_full;
	fsb_data_was_almost_full <= data_to_fsb_almost_full;
	
      endmethod

      method Action chipscope(Bit#(36) ctrl1, Bit#(36) ctrl2) = noAction;

      method Bit#(75)  cmd_to_fsb() = cmd_outW;
      method Bit#(256) data_to_fsb() = data_outW;
      method Bool data_xfer_begin() = data_xfer_beginW;
      method Bool data_xfer_end() = data_xfer_endW;
      method Bool cmd_from_fsb_almost_full() = !cmd_inQ.notFull() || !cmd_inQ_backup.notFull();
      method Bool data_from_fsb_almost_full() = !data_inQ.notFull() || !cmd_inQ_backup.notFull();
      
    endinterface
 

    // interfaces to FPGA model
    //note: addition of guards below smoothly transition us to BSV world
    
    method Action putData(Bit#(256) data, Bool begin_xfer, Bool end_xfer) if (!fsb_data_was_almost_full);

      data_outW <= data;
      
      if (begin_xfer)
        data_xfer_beginW.send();

      if (end_xfer)
        data_xfer_endW.send();

    endmethod

    method Action putCmd(Bit#(75) cmd) if (!fsb_cmd_was_almost_full);

      cmd_outW <= cmd;

    endmethod
    
    method ActionValue#(Tuple3#(Bit#(256), Bool, Bool)) getData() if (data_inQ.notEmpty()); 
      
      data_inQ.deq();
      return data_inQ.first();

    endmethod

    method ActionValue#(Bit#(75)) getCmd() if (cmd_inQ.notEmpty()); 
      
      cmd_inQ.deq();
      return cmd_inQ.first();

    endmethod

endmodule

