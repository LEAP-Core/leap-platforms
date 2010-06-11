import Vector::*;
import Clocks::*;
import LevelFIFO::*;
import FIFOF::*;

`include "physical_platform_utils.bsh"
`include "fpga_components.bsh"

typedef Bit#(8) JTAGWord;
        
// JTAG_DRIVER

// The serial driver support sending and receiving 32-bit words across a serial
// line.

interface JTAG_DRIVER;
    method Action send(JTAGWord word);
    method Bool notFull(); 
    method ActionValue#(JTAGWord) receive();
    method Bool notEmpty(); 
endinterface

// JTAG_WIRES

// These are wires which are simply passed up to the toplevel,
// where the UCF file ties them to pins.

interface JTAG_WIRES;

endinterface

// JTAG_DEVICE

// By convention a Device is a Driver and a Wires

interface JTAG_DEVICE;

    interface JTAG_DRIVER driver;
    interface JTAG_WIRES  wires;

endinterface


interface PRIMITIVE_JTAG_DEVICE;

    method Action send(JTAGWord word);
    method Bool notFull(); 

    method ActionValue#(JTAGWord) receive();
    method Bool notEmpty();

    method Action clearRXFIFO();
    method Action clearTXFIFO();

endinterface

// Deal with reset polarity
import "BVI" MDM = module mkPrimitiveJTAGDevice
    // interface:
                 (PRIMITIVE_JTAG_DEVICE);
    // Clocks and reset are handled by the UCF for now
    default_clock clk(Clk);
    default_reset rst(Rst);


    method send(TX_Data)
                      ready(TX_Buffer_Empty) 
                      enable(Write_TX_FIFO) 
                      clocked_by (clk) reset_by (rst);

    method TX_Buffer_Empty notFull(); 

    method RX_Data receive()
                   ready(RX_Data_Present)
                   enable(Read_RX_FIFO)
                   clocked_by (clk) reset_by (rst);

    method RX_Data_Present notEmpty();
   
    method clearRXFIFO() enable(Reset_RX_FIFO)  clocked_by (clk) reset_by (rst);
   
    method clearTXFIFO() enable(Reset_TX_FIFO)  clocked_by (clk) reset_by (rst);

    schedule send C       (send);
    schedule send CF      (receive,clearRXFIFO,clearTXFIFO,notEmpty,notFull);
   
    schedule receive C       (receive);
    schedule receive CF      (send,clearRXFIFO,clearTXFIFO,notEmpty,notFull);

    schedule (clearTXFIFO,clearRXFIFO,notEmpty,notFull) CF  (receive,send,clearRXFIFO,clearTXFIFO,notEmpty,notFull);

    

endmodule


module mkJTAGDevice#(SOFT_RESET_TRIGGER soft_reset, Clock rawClock, Reset rawReset) (JTAG_DEVICE);
    
    FIFOF#(JTAGWord) sendfifo <- mkSizedFIFOF(16);
    FIFOF#(JTAGWord) receivefifo <- mkSizedFIFOF(16);

    // Periodically send out some garbage data to flush out xilinx
    Reg#(Bit#(10)) counter <- mkReg(0);
    Reg#(Bool) flushing <- mkReg(False);
    Reg#(Bit#(6)) numberToFlush <- mkReg(32); // some magic number from XMD
    Reg#(Bool) needToFlush <- mkReg(False);

    PRIMITIVE_JTAG_DEVICE primitiveJTAGDevice <- mkPrimitiveJTAGDevice();
  
    rule sendConnect(!flushing);
        primitiveJTAGDevice.send(sendfifo.first);
        sendfifo.deq;
        if(numberToFlush - 1 != 0) // complete frame...
          begin
            numberToFlush <= numberToFlush - 1;
            needToFlush <= True;
          end
        else
          begin
            numberToFlush <= 32;
            needToFlush <= False;
          end

        counter <= 0;
    endrule
 
    rule flushingFrame(flushing);
      if(numberToFlush - 1 != 0) 
        begin
          numberToFlush <= numberToFlush - 1;
        end
      else
        begin 
          numberToFlush <= 32;
          flushing <= False;
          needToFlush <= False;
        end
      primitiveJTAGDevice.send(10);
    endrule

    // we trigger a soft reset if we ever see a 'z', ascii 122    
    rule receiveConnect;
        let data <- primitiveJTAGDevice.receive();
        receivefifo.enq(data);
    endrule

    rule countUp(!sendfifo.notEmpty && needToFlush && !flushing); // If there is data waiting, it doesn't count
      counter <= counter + 1;
      if(counter + 1 == 0) 
        begin
          flushing <= True;
        end 
    endrule

    interface JTAG_DRIVER driver;

        
        method Action send(JTAGWord data);
            sendfifo.enq(data);
        endmethod

        method ActionValue#(JTAGWord) receive();
            receivefifo.deq;
            if(receivefifo.first == 122) 
              begin
                soft_reset.reset();		
              end
            return receivefifo.first;
        endmethod

        method notFull = sendfifo.notFull;
        method notEmpty = receivefifo.notEmpty;

    endinterface

    interface JTAG_WIRES  wires;

    endinterface

endmodule

