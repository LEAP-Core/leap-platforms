import ClientServer::*;
import Clocks::*;
import Connectable::*;
import FIFOF::*;
import GetPut::*;

`include "asim/provides/avalon.bsh"
`include "asim/provides/register_mapper.bsh"

typedef Bit#(8) JTAGWord;

typedef struct {
   Bit#(16) ravail; 
   Bool rvalid; 
   JTAGWord data;
   } JtagData;

typedef struct {
   Bit#(16) wspace;
   } JtagControl;

instance Bits#(JtagData, 32);
   
   function Bit#(32) pack(JtagData data);
      return {data.ravail, pack(data.rvalid), 0, data.data};
   endfunction
                
   function JtagData unpack(Bit#(32) data);
      return JtagData {ravail: data[31:16], rvalid: unpack(data[15]), data: data[7:0]};
   endfunction
   
endinstance

instance Bits#(JtagControl, 32);
   
   function Bit#(32) pack(JtagControl data);
      return {data.wspace, 16'h0000};
   endfunction
                
   function JtagControl unpack(Bit#(32) data);
      return JtagControl {wspace: data[31:16]};
   endfunction
   
endinstance

typedef enum 
{
 ReadData,
 WritePoll 
} JtagAvalonRequest deriving (Bits, Eq);

interface JTAG_DRIVER;
   method Action send(JTAGWord word);
   method ActionValue#(JTAGWord) receive();
endinterface

interface JTAG_WIRES;
   method Bit#(1) dummy_wire;
endinterface

interface JTAG_DEVICE;
   interface JTAG_DRIVER driver;
   interface JTAG_WIRES  wires;
endinterface  

module mkAvalonJtagDriver#(Clock rawClock, Reset rawReset) (JTAG_DEVICE);
   
   Clock sysClock <- exposeCurrentClock();
   Reset sysReset <- exposeCurrentReset();
   
   AvalonMasterInverseWires#(32,32)  drivers   <- mkAvalonMasterDriver(clocked_by rawClock, reset_by rawReset);
   AvalonMaster#(32, 32)             master    <- mkAvalonMasterDualDomain(sysClock, sysReset, clocked_by rawClock, reset_by rawReset);
   FIFOF#(JTAGWord)                  inQ       <- mkFIFOF();
   FIFOF#(JTAGWord)                  outQ      <- mkFIFOF();
   FIFOF#(JtagAvalonRequest)         reqQ      <- mkFIFOF();
   Reg#(Bool)                        isRead    <- mkReg(True); 
   Reg#(Bit#(16))                    wrSpace   <- mkReg(0);
   Reg#(Bool)                        waitRdRsp <- mkReg(False);
   Reg#(Bool)                        waitWrRsp <- mkReg(False);
   let  out_wire <- mkNullCrossingWire(noClock(), drivers.readdatavalid, clocked_by rawClock);
   
   mkConnection(drivers, master.masterWires);
   
   rule toggleIsRead;
      isRead <= !isRead;
   endrule
   
   // may run out of write space, poll it to see whether extra space is available
   rule writePollReq (!isRead && inQ.notEmpty() && wrSpace == 0 && !waitWrRsp);
      master.busServer.request.put(AvalonRequest {addr: `JTAG_BASE_ADDR+4, data:?, command: Read});
      reqQ.enq(WritePoll);
      waitWrRsp <= True;
   endrule
   
   // write space available, send data
   rule writeReq (!isRead && inQ.notEmpty() && wrSpace > 0);
      let reqData = JtagData {ravail: ?, rvalid: ?, data: inQ.first()};
      inQ.deq();
      master.busServer.request.put(AvalonRequest {addr: `JTAG_BASE_ADDR, data: pack(reqData), command: Write});
      wrSpace <= wrSpace - 1; // decrement write space
   endrule
   
   // read poll to see whether read data is available
   rule readPollReq (isRead && !waitRdRsp);
      master.busServer.request.put(AvalonRequest {addr: `JTAG_BASE_ADDR, data: ?, command: Read});
      reqQ.enq(ReadData);
      waitRdRsp <= True;
   endrule

   // handle response
   rule getMasterResp;
      let resp <- master.busServer.response.get();
      let reqType = reqQ.first();
      reqQ.deq();
      
      // need to interpret data differently according to request type
      if (reqType == ReadData)
         begin
            JtagData jtagData = unpack(resp);
            waitRdRsp <= False;
            if (jtagData.rvalid) // is valid data
               begin
                  outQ.enq(jtagData.data);
               end
         end
      else
         begin
            JtagControl jtagControl = unpack(resp);
            wrSpace <= jtagControl.wspace;
            waitWrRsp <= False;
         end
   endrule
   
   interface JTAG_DRIVER driver;
      method Action send(JTAGWord word);
         inQ.enq(word);
      endmethod
      
      method ActionValue#(JTAGWord) receive();
         outQ.deq();
         return outQ.first();
      endmethod
   endinterface
   
   interface JTAG_WIRES wires;
      method Bit#(1) dummy_wire;
         return out_wire;
      endmethod
   endinterface
      
endmodule

module mkJtagDevice#(Clock rawClock, Reset rawReset) (JTAG_DEVICE);
   
   let jtagDriver <- mkAvalonJtagDriver(rawClock, rawReset);
   
   interface driver = jtagDriver.driver;
   interface wires  = jtagDriver.wires;
   
endmodule
