import Vector::*;
import Clocks::*;
import LevelFIFO::*;

`include "physical_platform_utils.bsh"

typedef Bit#(8) SerialWord;
        
// SERIAL_DRIVER

// The serial driver support sending and receiving 32-bit words across a serial
// line.

interface SERIAL_DRIVER;
    method Action send(SerialWord word);
    method ActionValue#(SerialWord) receive();
endinterface

// SERIAL_WIRES

// These are wires which are simply passed up to the toplevel,
// where the UCF file ties them to pins.

interface SERIAL_WIRES;

    // (* always_enabled *) // , always_ready *)
    method Action serial_rx((* port="serial_rx" *) Bit#(1) rx);

    method Action serial_cts((* port="serial_cts" *) Bit#(1) cts);

    (* always_ready *)
    (* result="serial_tx" *)
    method Bit#(1) serial_tx();

    (* always_ready *)
    (* result="serial_rts" *)
    method Bit#(1) serial_rts();

    (* always_ready *)
    (* result="serial_dtr" *)
    method Bit#(1) serial_dtr();
endinterface

// SERIAL_DEVICE

// By convention a Device is a Driver and a Wires

interface SERIAL_DEVICE;

    interface SERIAL_DRIVER driver;
    interface SERIAL_WIRES  wires;

endinterface


interface PRIMITIVE_SERIAL_DEVICE;

      // (* always_enabled *) // , always_ready *)
    method Action serial_rx((* port="serial_rx" *) Bit#(1) rx);

    method Action serial_cts((* port="serial_cts" *) Bit#(1) cts);

    (* always_ready *)
    (* result="serial_tx" *)
    method Bit#(1) serial_tx();

    (* always_ready *)
    (* result="serial_rts" *)
    method Bit#(1) serial_rts();

    (* always_ready *)
    (* result="serial_dtr" *)
    method Bit#(1) serial_dtr();

    method Action send(SerialWord word);

    method ActionValue#(SerialWord) receive();

    method Action clearRXFIFO();
    method Action clearTXFIFO();

endinterface

// Deal with reset polarity
import "BVI" OPB_UARTLITE_Core = module mkPrimitiveSerialDevice#(Integer clk_rate)
    // interface:
                 (PRIMITIVE_SERIAL_DEVICE);
    parameter C_CLK_FREQ = clk_rate;

    // Clocks and reset are handled by the UCF for now
    default_clock clk(Clk);
    default_reset rst(Reset);


    method send(TX_Data)
                      ready(TX_Buffer_Empty)
                      enable(Write_TX_FIFO) 
                      clocked_by (clk) reset_by (rst);
    
    method RX_Data receive()
                   ready(RX_Data_Present)
                   enable(Read_RX_FIFO)
                   clocked_by (clk) reset_by (rst);
   
    method clearRXFIFO() enable(Reset_RX_FIFO)  clocked_by (clk) reset_by (rst);
   
    method clearTXFIFO() enable(Reset_TX_FIFO)  clocked_by (clk) reset_by (rst);

    method serial_rx(RX) enable(dummy_enable_rx) clocked_by(no_clock) reset_by(no_reset);

    method TX serial_tx() clocked_by(no_clock) reset_by(no_reset); 

    method serial_cts(CTS) enable(dummy_enable_rts) clocked_by(no_clock) reset_by(no_reset);

    method RTS serial_rts() clocked_by(no_clock) reset_by(no_reset); 

    method DTR serial_dtr() clocked_by(no_clock) reset_by(no_reset);  

    schedule send C       (send);
    schedule send CF      (receive,serial_rx,serial_tx,serial_rts,serial_dtr,serial_cts,clearRXFIFO,clearTXFIFO);
   
    schedule receive C       (receive);
    schedule receive CF      (send,serial_rx,serial_tx,serial_rts,serial_dtr,serial_cts,clearRXFIFO,clearTXFIFO);

    schedule clearRXFIFO CF      (receive,send,serial_rx,serial_tx,serial_rts,serial_dtr,serial_cts,clearRXFIFO,clearTXFIFO);

    schedule clearTXFIFO CF      (receive,send,serial_rx,serial_tx,serial_rts,serial_dtr,serial_cts,clearRXFIFO,clearTXFIFO);

    schedule serial_rx CF      (receive,send,serial_tx,serial_rx,serial_rts,serial_dtr,serial_cts,clearRXFIFO,clearTXFIFO);

    schedule serial_rts CF      (receive,send,serial_tx,serial_rx,serial_rts,serial_dtr,serial_cts,clearRXFIFO,clearTXFIFO);

    schedule serial_cts CF      (receive,send,serial_tx,serial_rx,serial_rts,serial_dtr,serial_cts,clearRXFIFO,clearTXFIFO);
    schedule serial_cts CF      (receive,send,serial_tx,serial_rx,serial_rts,serial_dtr,serial_cts,clearRXFIFO,clearTXFIFO);

endmodule



module mkSerialDevice#(Clock raw_clock, Reset raw_reset) (SERIAL_DEVICE);

    // Need a real clock rate 
    PRIMITIVE_SERIAL_DEVICE primitiveSerialDevice <- mkPrimitiveSerialDevice(100 * 1000000);
  
    //Create the syncfifos

    interface SERIAL_DRIVER driver;

        method Action send(SerialWord data);
            primitiveSerialDevice.send(data);
        endmethod

        method ActionValue#(SerialWord) receive();
           let data <- primitiveSerialDevice.receive();
           return data;
        endmethod

    endinterface

    interface SERIAL_WIRES  wires;
        method serial_rx = primitiveSerialDevice.serial_rx;
        method serial_tx = primitiveSerialDevice.serial_tx;
        method serial_rts = primitiveSerialDevice.serial_rts;
        method serial_cts = primitiveSerialDevice.serial_cts;
        method serial_dtr = primitiveSerialDevice.serial_dtr;
    endinterface

endmodule

