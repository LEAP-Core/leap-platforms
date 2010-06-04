import Vector::*;
import Clocks::*;
import LevelFIFO::*;

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

module mkJTAGDevice#(Clock raw_clock, Reset raw_reset) (JTAG_DEVICE);

    PRIMITIVE_JTAG_DEVICE primitiveJTAGDevice <- mkPrimitiveJTAGDevice();
  
    interface JTAG_DRIVER driver;

        method Action send(JTAGWord data);
            primitiveJTAGDevice.send(data);
        endmethod

        method ActionValue#(JTAGWord) receive();
           let data <- primitiveJTAGDevice.receive();
           return data;
        endmethod

        method notFull = primitiveJTAGDevice.notFull;
        method notEmpty = primitiveJTAGDevice.notEmpty;

    endinterface

    interface JTAG_WIRES  wires;

    endinterface

endmodule

