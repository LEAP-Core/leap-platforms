import Vector::*;
import Clocks::*;
import LevelFIFO::*;

`include "physical_platform_utils.bsh"
`include "asim/provides/rrr.bsh"

typedef Bit#(32) ChannelIOWord;
typedef Bit#(32) AvalonWord;
typedef Bit#(8) JTAGWord;
        
interface JTAG_DRIVER;
    method Action send(ChannelIOWord word);
    method ActionValue#(ChannelIOWord) receive();
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

// Primitive interface for importing the device 

interface PRIMITIVE_JTAG_DEVICE;

endinterface

typedef enum{
  Reset,
  

}

module mkJTAGDevice#(Clock rawClock, Reset rawReset) (JTAG_DEVICE);

    PRIMITIVE_JTAG_DEVICE primitiveJTAGDevice <- mkPrimitiveJTAGDevice(clocked_by rawClock, 
                                                                             reset_by rawReset);
  
    Reg#(Bool) initialized <- mkReg(False);

    //Create the syncfifos
    SyncFIFOIfc#(AvalonWord) sendfifo    <- mkSyncFIFOFromCC(8,primitiveJTAGDevice.serial_clk);
    SyncFIFOIfc#(AvalonWord) receivefifo <- mkSyncFIFOToCC(8,primitiveJTAGDevice.serial_clk,
                                                             primitiveJTAGDevice.serial_rst);

    DEMARSHALLER#(JTAGWord,ChannelIOWord) jtagIncoming  <- mkDeMarshaller;
    MARSHALLER#(ChannelIOWord, JTAGWord)  jtagOutgoing  <- mkMarshaller;

    
    rule initialize(!initialized);
        demarshaller.start(valueof(SizeOf#(ChannelIOWord)/SizeOf#(JTAGWord)));
        intialized <= True;
    endrule


    interface JTAG_DRIVER driver;

        method Action send(ChannelIOWord data) (initialized);
            jtagOutgoing.enq(data);
        endmethod

        method ActionValue#(ChannelIOWord) receive() (initialized;
            jtag.deq;
            return receivefifo.first;
        endmethod

    endinterface

    interface wires = ?;

endmodule
