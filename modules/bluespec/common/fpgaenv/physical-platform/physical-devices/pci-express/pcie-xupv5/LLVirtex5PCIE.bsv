import Clocks::*;
import Vector::*;
import List::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import TieOff::*;
import ModuleContext::*;
import DefaultValue::*;
import XilinxPCIE::*;
import XilinxCells::*;
import DiniPCIE::*;
import RegFile::*;
import DReg::*;
import BUtils::*;

import PioFifo::*;

// Interface wrapper for PCIE
interface LLV5PCIEIfc#(numeric type lanes);
   interface PCIE_EXP#(lanes) pcie;
   (* always_ready *)
   method Bool isLinkUp();
   (* always_ready *)
   method Bool isOutOfReset();
   (* always_ready *)
   method Bool isClockAdvancing();
   method Action req(Bit#(8) r);
   method ActionValue#(Bit#(8)) resp;
   method Action dispReq(Bit#(8) r);
   method ActionValue#(Bit#(8)) dispResp;
endinterface

// Interface from the port logic facing the PCIE bus
interface SCEMI_to_PCIE_Ifc;
   interface Get#(TLPData#(16)) getTLPWord;
   interface Put#(TLPData#(16)) putTLPWord;
   interface PCIE_PIO_Ifc       pio;
endinterface

// This module builds the transactor hierarchy, the clock
// generation logic and the PCIE-to-port logic.
module [Module] buildPCIEV5#( Clock pci_sys_clk
				            , Reset pci_sys_reset
				            , Clock ref_clk
                            )
                            (LLV5PCIEIfc#(lanes))
   provisos(Add#(1,_,lanes), SelectVirtex5PCIE#(lanes));


   // Instantiate the PCIE endpoint
   PCIExpress#(lanes) _ep <- mkPCIExpressEndpoint( defaultValue
                                                 , clocked_by pci_sys_clk
                                                 , reset_by pci_sys_reset
                                                 );
   mkTieOff(_ep.cfg);
   mkTieOff(_ep.cfg_irq);
   mkTieOff(_ep.cfg_err);
   
   // The reference clock is the basis of the SCE-MI uncontrolled clock
   Clock uClock = ref_clk;
   Reset protoReset <- mkAsyncReset(6, _ep.trn.reset_n, uClock);

   PCIE_PIO_Ifc pio = ?;
   if (valueOf(lanes) == 1) begin
      // The PCIE endpoint is processing TLPWord#(8)s at 62.5MHz.  The
      // PCIE_to_PIO converter works with TLPWord#(16)s at 62.5MHz
      // on one side and presents a PIO interface at uClock speeds on
      // the other.  The connection between the endpoint and the
      // converter is simple in this case and does not require a
      // GearBox, only a TLPData#(16) <--> TLPData#(8) conversion.
      
      // The PCIe endpoint exports the full (62.5MHz) clock, and clk2 is unconnected.
      Clock epClock62 = _ep.trn.clk;
      Reset epReset62 <- mkAsyncReset(4, _ep.trn.reset_n, epClock62);
      
      // Convert the PCIE interface to PIO
      SCEMI_to_PCIE_Ifc _pio_conv <- conv_PCIE_to_PIO( _ep.cfg.bus_number
							, _ep.cfg.device_number
							, _ep.cfg.function_number
							, epClock62
							, epReset62
							, clocked_by uClock
							, reset_by protoReset
							);
      
      // Connect port connections to the endpoint
      mkConnection(_pio_conv.putTLPWord, _ep.trn_rx, clocked_by epClock62, reset_by epReset62);
      mkConnection(_ep.trn_tx, _pio_conv.getTLPWord, clocked_by epClock62, reset_by epReset62);
      
      pio = _pio_conv.pio;
   end
   else begin
      // The PCIE endpoint is processing TLPWord#(8)s at 250MHz.  The
      // PCIE_to_PIO converter works with TLPWord#(16)s at 125MHz on
      // one side and presents a PIO interface at uClock speeds on the
      // other.  The connection between the endpoint and the converter
      // contains GearBox instances for the TLPWord#(8)@250 <-->
      // TLPWord#(16)@125 conversion.
      
      // The PCIe endpoint exports full (250MHz) and half-speed (125MHz) clocks
      Clock epClock250 = _ep.trn.clk;
      Reset epReset250 <- mkAsyncReset(4, _ep.trn.reset_n, epClock250);
      Clock epClock125 = _ep.trn.clk2;
      Reset epReset125 <- mkAsyncReset(4, _ep.trn.reset_n, epClock125);
      
      // Convert the PCIE interface to PIO
      SCEMI_to_PCIE_Ifc _pio_conv <- conv_PCIE_to_PIO( _ep.cfg.bus_number
							, _ep.cfg.device_number
							, _ep.cfg.function_number
							, epClock125
							, epReset125
							, clocked_by uClock
							, reset_by protoReset
							);
      
      // Connect port connections to the endpoint
      mkConnectionWithClocks(_pio_conv.putTLPWord, _ep.trn_rx, epClock250, epReset250, epClock125, epReset125);
      mkConnectionWithClocks(_ep.trn_tx, _pio_conv.getTLPWord, epClock250, epReset250, epClock125, epReset125);
      
      pio = _pio_conv.pio;
   end
   
   PioFifo conv <- mkPioFifo( pio
                            , clocked_by uClock
                            , reset_by protoReset );

   // Pass along the required interface elements
   interface pcie               = _ep.pcie;
   method Bool isLinkUp         = _ep.trn.link_up;
   method Bool isOutOfReset     = True;
   method Bool isClockAdvancing = True;
   method req                   = conv.req;
   method resp                  = conv.resp;
   method dispReq               = conv.dispReq;
   method dispResp              = conv.dispResp;
endmodule

typedef struct {
   PciId           reqID;
   DWAddress       addr;
   TLPFirstDWBE    firstBE;
   TLPLastDWBE     lastBE;
   TLPTag          tag;
   TLPTrafficClass tc;
   TLPPoison       poisoned;
   TLPAttrNoSnoop  snoop;
   TLPAttrRelaxedOrdering relaxed;
   Bit#(7)         bar;
   Bool            read;
   Bool            dw3;
   Bool            sof;
   Bool            eof;
} PIOInfo deriving (Bits);

module conv_PCIE_to_PIO#( BusNumber        bus_number
                        , DevNumber        device_number
            			, FuncNumber       function_number
			            , Clock            ep_clk
			            , Reset            ep_rstn
			            )
                        (SCEMI_to_PCIE_Ifc);

   PciId myReqId = PciId { bus: bus_number, dev: device_number, func: function_number };

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   SyncFIFOIfc#(TLPData#(16)) fifoRx              <- mkSyncFIFOToCC(32, ep_clk, ep_rstn);
   SyncFIFOIfc#(TLPData#(16)) fifoTx              <- mkSyncFIFOFromCC(32, ep_clk);

   Wire#(Bool)                wReadAccept         <- mkDWire(False);
   Wire#(Bool)                wWriteAccept        <- mkDWire(False);

   Reg#(Bool)                 rReadEnable         <- mkReg(False);
   Reg#(Bool)                 rWriteEnable        <- mkReg(False);
   Reg#(Bool)                 rInWritePhase4DW    <- mkReg(False);
   Reg#(Maybe#(UInt#(32)))    rAddress            <- mkDReg(Invalid);
   Reg#(Bit#(32))             rWriteData          <- mkReg(0);
   Reg#(Bit#(4))              rWriteBe            <- mkReg(0);
   Reg#(Bit#(3))              rBar                <- mkReg(0);
   Reg#(Bit#(4))              rTag                <- mkReg(0);

   PulseWire                  pwReadResponse      <- mkPulseWire;
   Reg#(Bit#(4))              wTagResponse        <- mkWire;
   Reg#(Bit#(64))             wDataResponse       <- mkWire;

   Reg#(Bit#(4))              rTagCounter         <- mkReg(0);
   RegFile#(Bit#(4), PIOInfo) rfScoreBoard        <- mkRegFileFull;

   ////////////////////////////////////////////////////////////////////////////////
   /// Functions
   ////////////////////////////////////////////////////////////////////////////////
   function Bit#(32) byteSwap(Bit#(32) w);
      Vector#(4, Bit#(8)) bytes = unpack(w);
      return pack(reverse(bytes));
   endfunction

   function TLPData#(16) completeRead(PIOInfo rinfo, Maybe#(Bit#(32)) mdata);
      Bool isPoisoned  = (rinfo.poisoned == POISONED) || !isValid(mdata);
      TLPCompletionHeader hdr = defaultValue;
      hdr.reqid     = rinfo.reqID;
      hdr.cmplid    = myReqId;
      hdr.tag       = rinfo.tag;
      hdr.tclass    = rinfo.tc;
      hdr.length    = 1;
      hdr.poison    = (isPoisoned) ? POISONED : NOT_POISONED;
      hdr.nosnoop   = rinfo.snoop;
      hdr.relaxed   = rinfo.relaxed;
      hdr.loweraddr = getLowerAddr(rinfo.addr, rinfo.firstBE);
      hdr.bytecount = computeByteCount(1, rinfo.firstBE, rinfo.lastBE);
      hdr.data      = byteSwap(validValue(mdata));
      Bit#(128) pkt = pack(hdr);
      TLPData#(16) pw = TLPData { data: pkt
                                , be:   '1
                                , hit:  ?
                                , sof:  True
                                , eof:  True
                                };
      return pw;
   endfunction

   function PIOInfo saveInfo(TLPData#(16) data);
      TLPMemoryIO3DWHeader header3 = unpack(data.data);
      TLPMemory4DWHeader   header4 = unpack(data.data);
      PIOInfo rinfo = ?;

      rinfo.bar  = data.hit;
      rinfo.read = (header3.format == MEM_READ_3DW_NO_DATA || header4.format == MEM_READ_4DW_NO_DATA);
      rinfo.dw3  = (header3.format == MEM_READ_3DW_NO_DATA || header3.format == MEM_WRITE_3DW_DATA);
      rinfo.sof  = data.sof;
      rinfo.eof  = data.eof;

      case(header3.format)
         MEM_WRITE_3DW_DATA,
         MEM_READ_3DW_NO_DATA:
         begin
            rinfo.reqID    = header3.reqid;
            rinfo.addr     = header3.addr;
            rinfo.firstBE  = header3.firstbe;
            rinfo.lastBE   = header3.lastbe;
            rinfo.tag      = header3.tag;
            rinfo.tc       = header3.tclass;
            rinfo.snoop    = header3.nosnoop;
            rinfo.relaxed  = header3.relaxed;
            rinfo.poisoned = header3.poison;
         end
         MEM_WRITE_4DW_DATA,
         MEM_READ_4DW_NO_DATA:
         begin
            rinfo.reqID    = header4.reqid;
            rinfo.addr     = truncate(header4.addr);
            rinfo.firstBE  = header4.firstbe;
            rinfo.lastBE   = header4.lastbe;
            rinfo.tag      = header4.tag;
            rinfo.tc       = header4.tclass;
            rinfo.snoop    = header4.nosnoop;
            rinfo.relaxed  = header4.relaxed;
            rinfo.poisoned = header4.poison;
         end
      endcase

      return rinfo;
   endfunction

   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   (* no_implicit_conditions, fire_when_enabled *)
   rule reset_write_enables(rWriteEnable && wWriteAccept);
      rWriteEnable <= False;
   endrule

   (* no_implicit_conditions, fire_when_enabled *)
   rule reset_read_enables(rReadEnable && wReadAccept);
      rReadEnable <= False;
   endrule

   PIOInfo rinfo = saveInfo(fifoRx.first);

   (* descending_urgency = "process_next_read, process_next_3DW_write_a, process_next_4DW_write_d" *)
   rule process_next_read(rinfo.sof && rinfo.read && !rWriteEnable && !rReadEnable);
      let packet    = fifoRx.first; fifoRx.deq;

      rfScoreBoard.upd(rTagCounter, rinfo);
      rTagCounter <= rTagCounter + 1;

      rAddress          <= Valid(unpack({ rinfo.addr, 2'b00 }));
      rBar              <= { rinfo.bar[4], rinfo.bar[2], rinfo.bar[1] };
      rTag              <= rTagCounter;
      rReadEnable       <= True;
   endrule

   rule process_next_3DW_write_a(rinfo.sof && !rinfo.read && rinfo.dw3 && !rWriteEnable && !rReadEnable);
      let packet    = fifoRx.first; fifoRx.deq;
      TLPMemoryIO3DWHeader header = unpack(packet.data);

      rfScoreBoard.upd(rTagCounter, rinfo);
      rTagCounter <= rTagCounter + 1;

      rAddress          <= Valid(unpack({ rinfo.addr, 2'b00 }));
      rBar              <= { rinfo.bar[4], rinfo.bar[2], rinfo.bar[1] };
      rTag              <= rTagCounter;
      rWriteEnable      <= True;
      rWriteData        <= byteSwap(header.data);
      rWriteBe          <= rinfo.firstBE;
   endrule

   rule process_next_4DW_write_a(rinfo.sof && !rinfo.read && !rinfo.dw3 && !rWriteEnable && !rReadEnable && !rInWritePhase4DW);
      let packet    = fifoRx.first; fifoRx.deq;
      TLPMemory4DWHeader header = unpack(packet.data);

      rfScoreBoard.upd(rTagCounter, rinfo);
      rTagCounter <= rTagCounter + 1;

      rAddress          <= Valid(unpack({ rinfo.addr, 2'b00 }));
      rBar              <= { rinfo.bar[4], rinfo.bar[2], rinfo.bar[1] };
      rTag              <= rTagCounter;
      rWriteBe          <= rinfo.firstBE;
      rInWritePhase4DW  <= True;
   endrule

   rule process_next_4DW_write_d(rInWritePhase4DW && !rWriteEnable);
      let packet    = fifoRx.first; fifoRx.deq;

      rWriteEnable      <= True;
      rWriteData        <= byteSwap(packet.data[127:96]);
      rInWritePhase4DW  <= False;
   endrule

   rule process_read_response(pwReadResponse);
      PIOInfo      info   = rfScoreBoard.sub(wTagResponse);
      Bit#(32)     addr   = pack({ info.addr, 2'b00 });
      Bit#(32)     datahi;
      Bit#(32)     datalo;
      { datahi, datalo } = split(wDataResponse);
      Bit#(32)     data   = (addr[2] == 1) ? datahi : datalo;
      TLPData#(16) packet = completeRead(info, Valid(data));
      fifoTx.enq(packet);
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface getTLPWord = toGet(fifoTx);
   interface putTLPWord = toPut(fifoRx);
   interface PCIE_PIO_Ifc pio;
      method accept_read   = wReadAccept._write(True);
      method accept_write  = wWriteAccept._write(True);
      method address_valid = isValid(rAddress);
      method bar           = rBar;
      method addr          = validValue(rAddress);

      method Bit#(64) write_data() if (rWriteEnable);
         return zeroExtend(rWriteData);
      endmethod

      method Bit#(8) byte_enables() if (rWriteEnable);
         return zeroExtend(rWriteBe);
      endmethod

      method Bit#(4) tag() if (rReadEnable);
         return rTag;
      endmethod

      method Action fulfill_read(data, rtag);
         pwReadResponse.send;
         wTagResponse  <= rtag;
         wDataResponse <= data;
      endmethod
   endinterface
endmodule

