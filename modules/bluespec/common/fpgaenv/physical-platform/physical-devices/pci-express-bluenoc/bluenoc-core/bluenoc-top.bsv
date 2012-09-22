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

   // invert reset to active low
   Reset fpga_rstn <- mkResetInverter(fpga_rst);

   // put the clock through a PLL and synchronize the reset
   ClockGeneratorParams clk_params = defaultValue();
   clk_params.feedback_mul = 12;
   clk_params.clk0_div = 12;
   clk_params.clkin_buffer = False;
   ClockGenerator clk_gen <- mkClockGenerator(clk_params, reset_by fpga_rstn);
   Clock clk = clk_gen.clkout0;
   Reset rstn <- mkAsyncReset(4,fpga_rstn,clk);

   // combine LVDS clocks from FPGA boundary
//   Clock sys_clk_buf <- mkClockIBUFDS_GTXE1(True, pci_sys_clk_p, pci_sys_clk_n);

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
	
	let syncToOut <- mkSyncFIFO(32, fpga_clk, fpga_rst, epClock125);
	let syncFromIn <- mkSyncFIFO(32, epClock125, epReset125, fpga_clk);
	
	Reg#(Bit#(6)) epoch_send <- mkReg(0, clocked_by epClock125, reset_by epReset125);
	Reg#(Bit#(6)) epoch_rcv <- mkReg(0, clocked_by epClock125, reset_by epReset125);
	Reg#(Bit#(6)) epoch_peek <- mkReg(0, clocked_by epClock125, reset_by epReset125);
	
	Reg#(Bit#(8)) count_out <- mkReg(32);//, clocked_by epClock125, reset_by epReset125);
//	Reg#(Bool) flushing <- mkReg(False, clocked_by epClock125, reset_by epReset125);
//	Reg#(Bool) flushing_c <- mkReg(False);

/*
	rule echo;
		beats_in.deq();
		beats_out.enq(beats_in.first());
	endrule
	*/

	Reg#(Bit#(16)) led_count <- mkReg(0);
	rule echo(count_out > 0);
	/*
		count_out <= count_out - 1;
		syncToOut.enq(count_out);
		*/
		led_count <= led_count + 1;
		syncFromIn.deq();
		let data = syncFromIn.first();
		syncToOut.enq(data);
	endrule

	rule streamOut;
		syncToOut.deq();
		let data = syncToOut.first();
		beats_out.enq({8'h01, 8'h0, data, 8'h97});
	endrule

	rule streamIm;
		beats_in.deq();
		syncFromIn.enq({beats_in.first()[15:8]});
	endrule
/*
	rule streamOut;
		syncToOut.deq();
		let data = syncToOut.first();
		epoch_send <= epoch_send + 1;
		beats_out.enq({epoch_send, 2'b1, 8'h0, data, 8'h97});
	endrule

	rule streamIm;
		beats_in.deq();
		let epoch = beats_in.first()[31:26];
		let magic = beats_in.first()[7:0];
		if ( magic == 8'hbb ) begin
			epoch_rcv <= 0;
			epoch_send <= 0;
//			beats_out.enq({0, 2'b1, 8'h0, 8'h0, 8'hcc});
		end 
		else
		if ( epoch != epoch_rcv ) begin
			epoch_rcv <= epoch;
			syncFromIn.enq({beats_in.first()[15:8]}); // FIXME
		end
	endrule
*/
/*
	rule streamIn;//(!flushing);
		beats_in.deq();
		//syncFromIn.enq({beats_in.first()[15:8]}); // FIXME
		
		let epoch = beats_in.first()[31:26];
		let magic = beats_in.first()[7:0];
		if ( epoch != epoch_rcv ) begin
			if (magic == 8'hbe) begin // write
				epoch_rcv <= epoch;
				syncFromIn.enq({beats_in.first()[15:8]}); // FIXME
			end
			else if (magic == 8'hbd) begin // read
				epoch_rcv <= epoch;
				syncToOut.deq();
				let data = syncToOut.first();
				beats_out.enq({epoch_send, 2'b1,8'h0,data,8'h97}); //FIXME
				epoch_send <= epoch_send + 1;
//				beats_out.enq(data);
			end
			else if (magic == 8'hbc) begin // peek
				epoch_rcv <= epoch;
				//epoch_send <= epoch_send + 1;
				let peekres = 0;
				if ( syncToOut.notEmpty ) begin
					peekres = 1;
				end
				beats_out.enq({epoch_peek, 2'b1, 8'h0, peekres,8'h98});
				epoch_peek <= epoch_peek + 1;
			end
			else if (magic == 8'hbb) begin //init
				epoch_send <= 0;
				epoch_rcv <= 0;
				epoch_peek <= 0;
				//flushing <= True;
//				flushstart.enq(1);
			end
		end
		
	endrule
*/


   // FPGA pin interface
   interface PCIE_EXP pcie			= ep.pcie;
	 interface Clock clock 				= clk;
	method Action send(Bit#(8) data);
		//syncToOut.enq(data);
	endmethod
	method Bit#(8) leds();
		return led_count[7:0];
	endmethod

	method ActionValue#(Bit#(8)) receive();
		return 0;
		//syncFromIn.deq();
		//return syncFromIn.first();
	endmethod
      
endmodule: mkBlueNoCCore
