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
import BRAMFIFO     :: *;

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
module mkBridge_8#( Bit#(64)  board_content_id
                  , PciId     my_id
                  , UInt#(13) max_read_req_bytes
                  , UInt#(13) max_payload_bytes
                  , Bit#(7)   rcb_mask
                  , Bool      msix_enabled
                  , Bool      msix_mask_all_intr
                  )
                  (PCIEtoBNoC#(8));
   let _bridge <- mkPCIEtoBNoC( board_content_id
                              , my_id
                              , max_read_req_bytes
                              , max_payload_bytes
                              , rcb_mask
                              , msix_enabled
                              , msix_mask_all_intr
															, False
                              );
   return _bridge;
endmodule: mkBridge_8

typedef enum
{
    STATE_NEED_CMD,
    STATE_SEND_TO_HOST
}
CORE_STATE
    deriving (Eq, Bits);

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

   // Is the PCIe device ready for I/O?
   Reg#(Bool) initialized <- mkReg(False, clocked_by epClock125, reset_by epReset125);
   function Bool linkIsReady() = initialized;

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
   PCIEtoBNoC#(8) bridge <- mkBridge_8( 64'hc001_cafe_f00d_d00d
                                      , my_id
                                      , max_read_req_bytes
                                      , max_payload_bytes
                                      , rcb_mask
                                      , msix_enable
                                      , msix_masked
                                      , clocked_by epClock125, reset_by epReset125
                                      );
   mkConnectionWithClocks(ep.trn_rx, tpl_2(bridge.tlps), epClock250, epReset250, epClock125, epReset125);
   mkConnectionWithClocks(tpl_1(bridge.tlps), ep.trn_tx, epClock250, epReset250, epClock125, epReset125);
   // Instantiate some targets
   // Connect the bridge and targets to the switch and tie off unused ports
	   FifoMsgSink#(8)   beats_in  <- mkFifoMsgSink(clocked_by epClock125, reset_by epReset125);
	   FifoMsgSource#(8) beats_out <- mkFifoMsgSource(clocked_by epClock125, reset_by epReset125);
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


    Reg#(Bit#(4)) initState <- mkReg(0, clocked_by epClock125, reset_by epReset125);

    rule init0 (ep.trn.link_up && ! initialized && initState == 0 && ! beats_in.empty);
        beats_in.deq();
        initState <= 1;
    endrule

    rule init1 (! initialized && initState == 1);
	beats_out.enq({32'h0, 8'h1, 8'h0, 3'h0, pack(max_read_req_bytes)});
        initState <= 2;
    endrule

    rule init2 (! initialized && initState == 2);
	beats_out.enq({32'h0, 8'h1, 8'h0, 3'h0, pack(max_payload_bytes)});
        initState <= 3;
    endrule

    rule init3 (! initialized && initState == 3);
	beats_out.enq({32'h0, 8'h1, 8'h0, 6'h0, pack(msix_enable), pack(msix_masked), 1'h0, rcb_mask});
        initialized <= True;
    endrule

    Reg#(Bit#(6)) idx_rcv <- mkReg(0, clocked_by epClock125, reset_by epReset125);

    FIFO#(Bit#(32)) buffer <- mkSizedBRAMFIFO(8192, clocked_by epClock125, reset_by epReset125);

    Reg#(Bit#(28)) sendToHost <- mkReg(0, clocked_by epClock125, reset_by epReset125);
    Reg#(Bit#(8)) sendBodyBytes <- mkReg(0, clocked_by epClock125, reset_by epReset125);

    Reg#(Bit#(8)) remainingBytesIn <- mkReg(0, clocked_by epClock125, reset_by epReset125);

    // Get header packet
    rule headerIn (linkIsReady && (remainingBytesIn == 0) && ! beats_in.empty);
        let header = beats_in.first();
        beats_in.deq();

        let cmd = header[31:26];
        if (cmd == 1)
        begin
            // Start sending to host test.  The number of packets to send is
            // set by the combination of the source and destination node fields.
            sendToHost <= {header[15:0], 12'h0};
        end

        let remaining_bytes_in = header[23:16];
        if (remaining_bytes_in > 4)
        begin
            remainingBytesIn <= header[23:16] - 4;
        end
    endrule

    rule sinkBytesIn ((remainingBytesIn != 0) && ! beats_in.empty);
        beats_in.deq();

        if (remainingBytesIn <= 8)
            remainingBytesIn <= 0;
        else
            remainingBytesIn <= remainingBytesIn - 8;
    endrule

    (* descending_urgency = "headerIn, sendHeaderOut" *)
    rule sendHeaderOut (linkIsReady && (sendToHost != 0) && (sendBodyBytes == 0));
        let now = (sendToHost == 1) ? 8'h1 : 8'h0;
	beats_out.enq({8'hfc, 8'hfd, 8'hfe, 8'hff, now, 8'hfc, 8'h0, 8'h0});

        sendToHost <= sendToHost - 1;
        sendBodyBytes <= 8'hf8;
    endrule

    rule sendBodyOut (linkIsReady && (sendBodyBytes != 0));
	beats_out.enq({sendBodyBytes - 4,
                       sendBodyBytes - 3,
                       sendBodyBytes - 2,
                       sendBodyBytes - 1,
                       sendBodyBytes,
                       sendBodyBytes + 1,
                       sendBodyBytes + 2,
                       sendBodyBytes + 3});

        if (sendBodyBytes <= 8)
            sendBodyBytes <= 0;
        else
            sendBodyBytes <= sendBodyBytes - 8;
    endrule

`ifdef FOOBAR
    rule streamIn (linkIsReady && ! beats_in.empty);
        buffer.enq(beats_in.first);
        beats_in.deq();
    endrule

    rule streamOut (linkIsReady);
        beats_out.enq(buffer.first);
        buffer.deq();
    endrule
`endif

    rule keepQueuesActive (True);
        inQ.enq(outQ.first);
        outQ.deq();
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
