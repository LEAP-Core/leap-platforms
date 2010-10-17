import Dini::*;
import Vector::*;
import FIFOF::*;

typedef UInt#(12) Addr;

Addr idAndVersionBaseAddr = addr64('h0000);  // BAR1
Addr scemiConfigBaseAddr  = addr64('h0100);  // BAR1
Addr controlBaseAddr      = addr64('h0200);  // BAR1
Addr statusBaseAddr       = addr64('h0300);  // BAR1

// BAR1 fixed addresses
Addr bluespecIdRegAddr         = idAndVersionBaseAddr + addr64('h0000);
Addr addressMapVersionRegAddr  = idAndVersionBaseAddr + addr64('h0008);
Addr scemiVersionRegAddr       = idAndVersionBaseAddr + addr64('h0010);
Addr buildRevisionRegAddr      = idAndVersionBaseAddr + addr64('h0018);
Addr buildTimeStampRegAddr     = idAndVersionBaseAddr + addr64('h0020);

Addr systemCommandRegAddr      = controlBaseAddr      + addr64('h0000);

Addr bar1RPacketCountRegAddr   = statusBaseAddr       + addr64('h0008);
Addr bar2RPacketCountRegAddr   = statusBaseAddr       + addr64('h0010);
Addr errorRPacketCountRegAddr  = statusBaseAddr       + addr64('h0018);
Addr bar1WPacketCountRegAddr   = statusBaseAddr       + addr64('h0020);
Addr bar2WPacketCountRegAddr   = statusBaseAddr       + addr64('h0028);
Addr errorWPacketCountRegAddr  = statusBaseAddr       + addr64('h0030);

// BAR2 fixed addresses
Addr sysAddr                   = addr64('h0000);
Addr dispAddr                  = addr64('h0008);

function Addr addr64(UInt#(32) n);
   return truncate(n >> 3);
endfunction: addr64

interface PioFifo;
    method Action req(Bit#(8) r);
    method ActionValue#(Bit#(8)) resp;
    method Action dispReq(Bit#(8) r);
    method ActionValue#(Bit#(8)) dispResp;
endinterface

module mkPioFifo#(PCIE_PIO_Ifc pio) (PioFifo);
   // Config & Status registers
   UInt#(8) addr_map_version = 2;

   UInt#(8) scemi_major_version = 1;
   UInt#(8) scemi_minor_version = 0;

   Reg#(UInt#(32)) bar1RPacketCount  <- mkReg(0);
   Reg#(UInt#(32)) bar2RPacketCount  <- mkReg(0);
   Reg#(UInt#(32)) errorRPacketCount <- mkReg(0);
   Reg#(UInt#(32)) bar1WPacketCount  <- mkReg(0);
   Reg#(UInt#(32)) bar2WPacketCount  <- mkReg(0);
   Reg#(UInt#(32)) errorWPacketCount <- mkReg(0);

   // PCIE read/write pipeline state
   Reg#(Maybe#(Addr)) stored_addr <- mkReg(tagged Invalid);
   RWire#(Addr)            addr_w <- mkRWire();

   Reg#(Bit#(64)) loopBackData <- mkReg(64'hbead_ebad_deab_abed);

   FIFOF#(Bit#(8))      reqQ <- mkUGFIFOF;
   FIFOF#(Bit#(8))     respQ <- mkUGFIFOF;
   FIFOF#(Bit#(8))  dispReqQ <- mkUGFIFOF;
   FIFOF#(Bit#(8)) dispRespQ <- mkUGFIFOF;

   // Address handling rules
   (* fire_when_enabled, no_implicit_conditions *)
   rule capture_new_address if (pio.address_valid());
      let addr = truncate(pio.addr() >> 3);
      stored_addr <= tagged Valid addr;
      addr_w.wset(addr);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule use_stored_address if (!pio.address_valid() &&& stored_addr matches tagged Valid .addr);
      addr_w.wset(addr);
   endrule

   // Always accept both reads and writes
   (* fire_when_enabled, no_implicit_conditions *)
   rule always_accept;
      pio.accept_read();
      pio.accept_write();
   endrule

   // Write pipeline implementation
   (* fire_when_enabled *)
   rule initiate_write if (addr_w.wget() matches tagged Valid .addr);
      if (pio.bar[0]==1) begin // bar1 write
         bar1WPacketCount <= bar1WPacketCount + 1;
	     loopBackData <= {pio.byte_enables[3:0]!=0 ? pio.write_data[31:0] : loopBackData[31:0],
		                  pio.byte_enables[7:4]!=0 ? pio.write_data[63:32] : loopBackData[63:32]};
      end
      else if (pio.bar[1]==1 && addr==sysAddr && respQ.notFull) begin // bar2 write
         respQ.enq(pio.write_data[7:0]);
         bar2WPacketCount <= bar2WPacketCount + 1;
      end
      else if (pio.bar[1]==1 && addr==dispAddr && dispRespQ.notFull) begin // bar2 write
         dispRespQ.enq(pio.write_data[7:0]);
         bar2WPacketCount <= bar2WPacketCount + 1;
      end
      else begin
         errorWPacketCount <= errorWPacketCount + 1;
      end
   endrule

   // Read pipeline implementation
   (* fire_when_enabled, mutually_exclusive = "initiate_read, initiate_write" *)
   rule initiate_read if (addr_w.wget() matches tagged Valid .addr);
      Bit#(64) data = ?;
      if (pio.bar[0]==1) begin // bar1 read
         case (addr)
            bluespecIdRegAddr:         data = 64'h42_6c_75_65_73_70_65_63; // Bluespec
            addressMapVersionRegAddr:  data = zeroExtend(pack(addr_map_version));
            scemiVersionRegAddr:       data = zeroExtend({ pack(scemi_major_version), pack(scemi_minor_version) });
            buildRevisionRegAddr:      data = zeroExtend(pack(buildVersion));
            buildTimeStampRegAddr:     data = zeroExtend(pack(epochTime));
            systemCommandRegAddr:      data = loopBackData;
            bar1RPacketCountRegAddr:   data = zeroExtend(pack(bar1RPacketCount));
            bar2RPacketCountRegAddr:   data = zeroExtend(pack(bar2RPacketCount));
            errorRPacketCountRegAddr:  data = zeroExtend(pack(errorRPacketCount));
            bar1WPacketCountRegAddr:   data = zeroExtend(pack(bar1WPacketCount));
            bar2WPacketCountRegAddr:   data = zeroExtend(pack(bar2WPacketCount));
            errorWPacketCountRegAddr:  data = zeroExtend(pack(errorWPacketCount));
            default:                   begin
                                          data = 64'h0bad_0bad_0bad_0bad;
                                       end
         endcase
         bar1RPacketCount <= bar1RPacketCount + 1;
      end
      else if (pio.bar[1]==1 && addr==sysAddr && reqQ.notEmpty) begin // bar2 read
		 reqQ.deq;
		 data = zeroExtend(reqQ.first);
	     bar2RPacketCount <= bar2RPacketCount + 1;
 	  end
      else if (pio.bar[1]==1 && addr==dispAddr && dispReqQ.notEmpty) begin // bar2 read
		 dispReqQ.deq;
		 data = zeroExtend(dispReqQ.first);
	     bar2RPacketCount <= bar2RPacketCount + 1;
 	  end
      else begin
         data = 64'hdead_dead_dead_dead;
         errorRPacketCount <= errorRPacketCount + 1;
      end
      pio.fulfill_read(data, pio.tag);
   endrule

    method Action req(Bit#(8) r) if(reqQ.notFull);
        reqQ.enq(r);
    endmethod

    method ActionValue#(Bit#(8)) resp if(respQ.notEmpty);
        respQ.deq;
        return respQ.first;
    endmethod

    method Action dispReq(Bit#(8) r) if(dispReqQ.notFull);
        dispReqQ.enq(r);
    endmethod

    method ActionValue#(Bit#(8)) dispResp if(dispRespQ.notEmpty);
        dispRespQ.deq;
        return dispRespQ.first;
    endmethod
endmodule

