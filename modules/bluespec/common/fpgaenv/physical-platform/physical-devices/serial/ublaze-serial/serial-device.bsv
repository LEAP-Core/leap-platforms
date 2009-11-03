import Vector::*;
import Clocks::*;
import LevelFIFO::*;

`include "physical_platform_utils.bsh"

typedef Bit#(32) SerialWord;
        
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

// Primitive interface for importing the device 

interface PRIMITIVE_SERIAL_DEVICE;

    method Action send(SerialWord word);

    method ActionValue#(SerialWord) receive();

    // (* always_enabled *) // , always_ready *)
    method Action serial_rx(Bit#(1) rx);

    method Action serial_cts(Bit#(1) cts);

    (* always_ready *)
    method Bit#(1) serial_tx();

    (* always_ready *)
    method Bit#(1) serial_rts();

    (* always_ready *)
    method Bit#(1) serial_dtr();

    interface Clock serial_clk;
    interface Reset serial_rst;
endinterface

// Deal with reset polarity
import "BVI" serial = module mkPrimitiveSerialDevice
    // interface:
                 (PRIMITIVE_SERIAL_DEVICE);
    
    // Clocks and reset are handled by the UCF for now
    default_clock clk(sys_clk_pin);
    default_reset rst(sys_rst_pin);

    output_clock serial_clk(serial_clk_pin);
    output_reset serial_rst(serial_rst_pin) clocked_by (serial_clk);

    method send(bramfeeder_0_ppcMessageInput_put_pin)
                      ready(bramfeeder_0_RDY_ppcMessageInput_put_pin)
                      enable(bramfeeder_0_EN_ppcMessageInput_put_pin) 
                      clocked_by (serial_clk) reset_by (serial_rst);
    
    method bramfeeder_0_ppcMessageOutput_get_pin receive()
                      ready(bramfeeder_0_RDY_ppcMessageOutput_get_pin)
                      enable(bramfeeder_0_EN_ppcMessageOutput_get_pin)
                      clocked_by (serial_clk) reset_by (serial_rst);
   
    method serial_rx(fpga_0_RS232_Uart_1_sin) enable(dummy_enable_rx) clocked_by(no_clock) reset_by(no_reset);

    method fpga_0_RS232_Uart_1_sout serial_tx() clocked_by(no_clock) reset_by(no_reset); 

    method serial_cts(fpga_0_RS232_Uart_1_ctsN) enable(dummy_enable_rts) clocked_by(no_clock) reset_by(no_reset);

    method fpga_0_RS232_Uart_1_rtsN serial_rts() clocked_by(no_clock) reset_by(no_reset); 

    method fpga_0_RS232_Uart_1_dtrN serial_dtr() clocked_by(no_clock) reset_by(no_reset);  

    schedule send C       (send);
    schedule send CF      (receive,serial_rx,serial_tx,serial_rts,serial_dtr,serial_cts);
   
    schedule receive C       (receive);
    schedule receive CF      (send,serial_rx,serial_tx,serial_rts,serial_dtr,serial_cts);

    schedule serial_tx CF      (receive,send,serial_rx,serial_tx,serial_rts,serial_dtr,serial_cts);

    schedule serial_rx CF      (receive,send,serial_tx,serial_rx,serial_rts,serial_dtr,serial_cts);

    schedule serial_rts CF      (receive,send,serial_tx,serial_rx,serial_rts,serial_dtr,serial_cts);

    schedule serial_cts CF      (receive,send,serial_tx,serial_rx,serial_rts,serial_dtr,serial_cts);

endmodule

module mkSerialDevice#(Clock rawClock, Reset rawReset) (SERIAL_DEVICE);

    PRIMITIVE_SERIAL_DEVICE primitiveSerialDevice <- mkPrimitiveSerialDevice(clocked_by rawClock, 
                                                                             reset_by rawReset);
  
    //Create the syncfifos
    SyncFIFOIfc#(SerialWord) sendfifo <- mkSyncFIFOFromCC(8,primitiveSerialDevice.serial_clk);
    SyncFIFOIfc#(SerialWord) receivefifo <- mkSyncFIFOToCC(8,primitiveSerialDevice.serial_clk,primitiveSerialDevice.serial_rst);

    Reg#(Bool) synchronized <- mkReg(False);

    rule sync(!synchronized);
      receivefifo.deq;  
      if(receivefifo.first == 32'hdeadbeef) 
        begin
          synchronized <= True;
        end
    endrule

    rule sendConnect;
        primitiveSerialDevice.send(sendfifo.first);
        sendfifo.deq;
    endrule
    
    rule receiveConnect;
        let data <- primitiveSerialDevice.receive();
        receivefifo.enq(data);
    endrule

    interface SERIAL_DRIVER driver;

        method Action send(SerialWord data) if(synchronized);
            sendfifo.enq(data);
        endmethod

        method ActionValue#(SerialWord) receive() if(synchronized);
            receivefifo.deq;
            return receivefifo.first;
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
