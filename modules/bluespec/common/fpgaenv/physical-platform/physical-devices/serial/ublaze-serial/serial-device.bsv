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
    method Action serial_rx((* port="pci_exp_rxn" *) Bit#(1) rx);

    (* always_ready *)
    (* result="serial_tx" *)
    method Bit#(1) serial_tx();

endinterface

// SERIAL_DEVICE

// By convention a Device is a Driver and a Wires

interface SERIAL_DEVICE;

    interface SERIAL_DRIVER driver;
    interface SERIAL_WIRES  wires;

endinterface

// Primitive interface for importing the device 

interface PRIMITIVE_SERIAL_INTERFACE;

    method Action send(SerialWord word);

    method ActionValue#(SerialWord) receive();

    // (* always_enabled *) // , always_ready *)
    method Action serial_rx((* port="pci_exp_rxn" *) Bit#(1) rx);

    (* always_ready *)
    (* result="serial_tx" *)
    method Bit#(1) serial_tx();

endinterface

import "BVI" Channel_top = module mkPrimitiveSerialDevice
    // interface:
                 (PRIMITIVE_SERIAL_DEVICE);

    // Clocks and reset are handled by the UCF for now
    default_clock sys_clk_pin;
    default_reset sys_rst_pin;

    output_clock pcie_clk(clk);

    output_reset pcie_rst(rst_n) clocked_by(pcie_clk);


    method send(bramfeeder_0_ppcMessageInput_put_pin)
                      ready(bramfeeder_0_RDY_ppcMessageInput_put_pin)
                      enable(bramfeeder_0_EN_ppcMessageInput_put_pin);
    
    method bramfeeder_0_ppcMessageOutput_get_pin receive()
                      ready(bramfeeder_0_RDY_ppcMessageOutput_get_pin)
                      enable(bramfeeder_0_EN_ppcMessageOutput_get_pin);
   
    method serial_rx(fpga_0_RS232_Uart_1_RX_pin);

    method serial_tx(fpga_0_RS232_Uart_1_TX_pin);
 
    schedule send SBR     (send);
    schedule send CF      (receive,serial_rx,serial_tx);
   
    schedule receive SBR     (receive);
    schedule receive CF      (send,serial_rx,serial_tx);

    schedule serial_tx SBR     (serial_tx);
    schedule serial_tx CF      (receive,send,serial_rx);

    schedule serial_rx SBR     (serial_rx);
    schedule serial_rx CF      (receive,send,serial_tx);

endmodule

module mkSerialDevice#(Clock rawClock, Reset rawReset) (SERIAL_DEVICE);

    PRIMITIVE_SERIAL_DEVICE primitiveSerialDevice <- mkPrimitiveSerialDevice(clocked_by rawClock, 
                                                                             reset_by rawReset);
  
    //Create the syncfifos
    SyncFIFOIfc#(SerialWord) sendfifo <- mkSyncFIFOFromCC(16,rawClock);
    SyncFIFOIfc#(SerialWord) receivefifo <- mkSyncFIFOToCC(16,rawClock,rawReset);

    rule sendConnect;
        primitiveSerialDevice.send(sendfifo.first);
        sendfifo.deq;
    endrule
    
    rule receiveConnect;
        let data <- primitiveSerialDevice.receive();
        receivefifo.enq(data);
    endrule

    interface SERIAL_DRIVER driver;

        method Action send(SerialWord data);
            sendfifo.enq(data);
        endmethod

        method ActionValue#(SerialDat) receive();
            receivefifo.deq;
            return receivefifo.first;
        endmethod

    endinterface

    interface SERIAL_WIRES  wires;
        method serial_rx = primitiveSerialDevice.serial_rx;
        method serial_tx = primitiveSerialDevice.serial_tx;
    endinterface

endmodule
