import Clocks       :: *;
import Vector       :: *;
import GetPut       :: *;
import Connectable  :: *;
import FIFO         :: *;
import DefaultValue :: *;
import TieOff       :: *;
import XilinxCells  :: *;
import XilinxPCIE   :: *;
import StmtFSM      :: *;
import DReg         :: *;

`include "awb/provides/bluenoc_core.bsh"

//import MsgFormat        :: *;
//import PCIEtoBNoCBridge :: *;

interface BLUENOCIfc;
		method Action send(Bit#(8) word);
    method ActionValue#(Bit#(8)) receive();

		method Bit#(8) leds;
   interface PCIE_EXP#(8) pcie;
	 interface Clock clock;
	 interface Reset reset;
endinterface
//(* synthesize *)
module mkBridge_4#( Bit#(64)  board_content_id
                  , PciId     my_id
                  , UInt#(13) max_read_req_bytes
                  , UInt#(13) max_payload_bytes
                  , Bit#(7)   rcb_mask
                  , Bool      msix_enabled
                  , Bool      msix_mask_all_intr
                  )
                  (PCIEtoBNoC#(4));
   let _bridge <- mkPCIEtoBNoC( board_content_id
                              , my_id
                              , max_read_req_bytes
                              , max_payload_bytes
                              , rcb_mask
                              , msix_enabled
                              , msix_mask_all_intr
                              );
   return _bridge;
endmodule: mkBridge_4

module mkBlueNoCCore#(Clock sys_clk_buf, Reset pci_sys_rstn)
                 (BLUENOCIfc);
   // access clock and reset
   Clock fpga_clk  <- exposeCurrentClock();
   Reset fpga_rst  <- exposeCurrentReset();


   // instantiate a PCIE endpoint
   PCIEParams pcie_params = defaultValue();
   PCIExpressV6#(8) ep <- mkPCIExpressEndpointV6(pcie_params, clocked_by sys_clk_buf, reset_by pci_sys_rstn);

   // extract the clocks and resets from the endpoint
   Clock epClock250  = ep.trn.clk;
   Reset epReset250 <- mkAsyncReset(4, ep.trn.reset_n, epClock250);
   Clock epClock125  = ep.trn.clk2;
   Reset epReset125 <- mkAsyncReset(4, ep.trn.reset_n, epClock125);

   // tie off some portions of the endpoint interface
   mkTieOff(ep.cfg);
   mkTieOff(ep.cfg_err);
   mkTieOff(ep.pl);

   // note our PCI ID
   PciId my_id = PciId { bus:  ep.cfg.bus_number()
                       , dev:  ep.cfg.device_number()
                       , func: ep.cfg.function_number()
                       };

   // instantiate controllers for the interactive elements on the board


   //
   // main body of design
   //

   // initialization of LCD and LED controllers

   // extract some status info from the PCIE endpoint these values are
   // all in the epClock250 domain, so we have to cross them into the
   // epClock125 domain
   UInt#(13) max_read_req_bytes_250       = 128 << ep.cfg.dcommand[14:12];
   UInt#(13) max_payload_bytes_250        = 128 << ep.cfg.dcommand[7:5];
   UInt#(8)  read_completion_boundary_250 = 64 << ep.cfg.lcommand[3];
   Bool      msix_enable_250              = (ep.cfg_interrupt.msixenable() == 1);
   Bool      msix_masked_250              = (ep.cfg_interrupt.msixfm()     == 1);

   CrossingReg#(UInt#(13)) max_rd_req_cr  <- mkNullCrossingReg(epClock125, 128,   clocked_by epClock250, reset_by epReset250);
   CrossingReg#(UInt#(13)) max_payload_cr <- mkNullCrossingReg(epClock125, 128,   clocked_by epClock250, reset_by epReset250);
   CrossingReg#(UInt#(8))  rcb_cr         <- mkNullCrossingReg(epClock125, 128,   clocked_by epClock250, reset_by epReset250);
   CrossingReg#(Bool)      msix_enable_cr <- mkNullCrossingReg(epClock125, False, clocked_by epClock250, reset_by epReset250);
   CrossingReg#(Bool)      msix_masked_cr <- mkNullCrossingReg(epClock125, True,  clocked_by epClock250, reset_by epReset250);

   Reg#(UInt#(13)) max_read_req_bytes <- mkReg(128,   clocked_by epClock125, reset_by epReset125);
   Reg#(UInt#(13)) max_payload_bytes  <- mkReg(128,   clocked_by epClock125, reset_by epReset125);
   Reg#(Bit#(7))   rcb_mask           <- mkReg(7'h3f, clocked_by epClock125, reset_by epReset125);
   Reg#(Bool)      msix_enable        <- mkReg(False, clocked_by epClock125, reset_by epReset125);
   Reg#(Bool)      msix_masked        <- mkReg(True,  clocked_by epClock125, reset_by epReset125);

   (* fire_when_enabled, no_implicit_conditions *)
   rule cross_config_values;
      max_rd_req_cr  <= max_read_req_bytes_250;
      max_payload_cr <= max_payload_bytes_250;
      rcb_cr         <= read_completion_boundary_250;
      msix_enable_cr <= msix_enable_250;
      msix_masked_cr <= msix_masked_250;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule register_config_values;
      max_read_req_bytes <= max_rd_req_cr.crossed();
      max_payload_bytes  <= max_payload_cr.crossed();
      rcb_mask           <= (rcb_cr.crossed() == 64) ? 7'h3f : 7'h7f;
      msix_enable        <= msix_enable_cr.crossed();
      msix_masked        <= msix_masked_cr.crossed();
   endrule

   // monitor PCIe interrupt status (MSI-X only)
   CrossingReg#(Bool) intr_on <- mkNullCrossingReg( epClock125
                                                  , False
                                                  , clocked_by epClock250
                                                  , reset_by epReset250
                                                  );

   // this rule executes in the epClock250 domain
   (* fire_when_enabled, no_implicit_conditions *)
   rule intr_ifc_ctl;
      ep.cfg_interrupt.di('0);        // tied off for MSI-X
      ep.cfg_interrupt.assert_n('1);  // tied off for MSI-X
      ep.cfg_interrupt.req_n(1);      // tied off for MSI-X
      intr_on <= (ep.cfg_interrupt.msienable()  == 0)
              && (ep.cfg_interrupt.msixenable() == 1)
              && (ep.cfg_interrupt.msixfm()     == 0);
//              && (ep.cfg.command[2]             == 1); // bus master enable required for MSI
   endrule: intr_ifc_ctl

   // this value is in the epClock125 domain and indicates that the
   // interrupt interface is properly configured to send interrupts
   Bool intr_ok = intr_on.crossed();

   // instantiate the TLP-to-BNoC bridge and connect the PCIe endpoint
   // to it
   PCIEtoBNoC#(4) bridge <- mkBridge_4( 64'hc001_cafe_f00d_d00d
                                      , my_id
                                      , max_read_req_bytes
                                      , max_payload_bytes
                                      , rcb_mask
                                      , msix_enable
                                      , msix_masked
                                      , clocked_by epClock125, reset_by epReset125
                                      );
   mkConnectionWithClocks(ep.trn_rx, tpl_2(bridge.tlps), epClock250, epReset250, epClock125, epReset125);
   mkConnectionWithClocks(ep.trn_tx, tpl_1(bridge.tlps), epClock250, epReset250, epClock125, epReset125);
   // Instantiate some targets
   // Connect the bridge and targets to the switch and tie off unused ports
	   FifoMsgSink#(4)   beats_in  <- mkFifoMsgSink(clocked_by epClock125, reset_by epReset125);
	   FifoMsgSource#(4) beats_out <- mkFifoMsgSource(clocked_by epClock125, reset_by epReset125);
	//let nocport = as_port(beats_out.source, beats_in.sink);
	//mkConnection(bridge.noc, nocport);
	mkConnection(bridge.noc, as_port(beats_out.source, beats_in.sink));
	


	FIFO#(Bit#(6)) beat <- mkFIFO(clocked_by epClock125, reset_by epReset125);
	Reg#(Bit#(6)) rxFromFPGAClk <- mkReg(0, clocked_by epClock125, reset_by epReset125);
	Reg#(Bit#(6)) epoch_send <- mkReg(0, clocked_by epClock125, reset_by epReset125);
	Reg#(Bit#(6)) epoch_peek <- mkReg(0, clocked_by epClock125, reset_by epReset125);
	

        let rstPCIE <- mkAsyncReset(2,epReset125,fpga_clk);
        let rstEither <- mkResetEither(fpga_rst,rstPCIE);

        SyncFIFOIfc#(Bit#(8)) inQ              <- mkSyncFIFO(32, epClock125, epReset125,fpga_clk);
        SyncFIFOIfc#(Bit#(8)) outQ             <- mkSyncFIFO(32, fpga_clk, rstEither, epClock125);
    



	Reg#(Bit#(8)) inQtotal <- mkReg(0,clocked_by epClock125, reset_by epReset125);
	Reg#(Bit#(8)) outQtotal <- mkReg(0,clocked_by epClock125, reset_by epReset125);
	Reg#(Bit#(16)) timeout <- mkReg(0,clocked_by epClock125, reset_by epReset125);


	rule tickTO(timeout != 0);
	   timeout <= timeout + 1;
        endrule
/*
	rule echo;
		//syncFromIn.deq();
		//let data = syncFromIn.first();
		//syncToOut.enq(8'h99);
		inQ.deq();
		let data = inQ.first();
		outQ.enq(data);
		inQcount <= inQcount - 1;
	endrule
	*/

	rule streamOutDebug (timeout == 0);
	        timeout <= 1;
		outQtotal <= outQtotal + 1;
		Bit#(8) debug = zeroExtend({pack(outQ.notEmpty), pack(inQ.notFull)}); 
		beats_out.enq({8'b101,8'h0,debug,outQtotal});
	endrule

	rule streamOut (timeout != 0);
		//syncToOut.deq();
		//let data = syncToOut.first();
		outQ.deq();
		//tempdat.deq();
		let data = outQ.first();
		outQtotal <= outQtotal + 1;
		beats_out.enq({8'b01,8'h0,data,outQtotal});
	endrule
	
	Reg#(Bit#(6)) idx_rcv <- mkReg(0, clocked_by epClock125, reset_by epReset125);
	rule streamIn;//(inQcount < 128);
 	 //       beat.enq(0);
		beats_in.deq();
		//syncFromIn.enq({beats_in.first()[15:8]});
		let data = beats_in.first()[15:8];
		let idx = beats_in.first()[31:26];
		let flags = beats_in.first()[0];
		if ( flags != 0 ) begin
			idx_rcv <= 0;
		end
		else if ( idx != idx_rcv ) begin
			idx_rcv <= idx;
			inQ.enq(data);
       	                inQtotal <= inQtotal + 1;				
		end

	endrule

   // FPGA pin interface
   interface PCIE_EXP pcie			= ep.pcie;
	 interface Clock clock 				= fpga_clk;
	 interface Reset reset 				= rstEither;
	method Action send(Bit#(8) data);
		outQ.enq(data);
	endmethod
	method Bit#(8) leds();
		return inQtotal;
	endmethod

	method ActionValue#(Bit#(8)) receive();// if ( inQcount > 0 );
//		inQcount <= inQcount - 1;
		inQ.deq();
		return inQ.first();
	endmethod
      
endmodule: mkBlueNoCCore
