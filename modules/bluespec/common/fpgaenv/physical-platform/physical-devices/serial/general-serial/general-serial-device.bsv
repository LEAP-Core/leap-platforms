
// A generalized LED device, including interface 
// to the outside world and wires to tie to pins.
// Polymorphic across the number of LEDs.

import Clocks::*;

// LED_DRIVER

// The Driver interface is the interface that other Bluespec modules
// use to set the LEDs.

interface SERIAL_DRIVER;

    method  Action                 write(Bit#(32) x);
    method  ActionValue#(Bit#(32))  read();
    
endinterface



// LED_WIRES

// The Wires interface is not used by any other Bluespec module.
// It defines wires that are passed to the toplevel where the 
// UCF in the hardware-platform ties them to LED pins

interface SERIAL_WIRES;

//     (* always_ready *)
//     (* result = "LED" *)
//     method Bit#(n) leds();

endinterface


// LED_DEVICE

// By convention a Device is a combination of the Driver and the Wires.
// This interface is polymorphic in the number of LEDs available.

interface SERIAL_DEVICE;

  interface SERIAL_DRIVER driver;
  interface SERIAL_WIRES  wires;

endinterface


// mkLookbackLEDDevice

// An LED Device generalized to any bit width.

module mkSerialDevice#(Clock clk, Reset rst)
    // interface:
                 (SERIAL_DEVICE);
    
    //
    // LEDs may be outside the model clock boundary.  The led_reg_intern
    // holds the value inside the model clock domain.  led_reg_extern makes
    // the register visible in the top level clock domain.
    //
    FIFO#(Bit#(32)) dataQ <- mkFIFO();

    // Interface used by the rest of the FPGA.

    interface SERIAL_DRIVER driver;

	method Action write = dataQ.enq;
        method ActionValue#(Bit#(32)) read = pop(dataQ);
	
    endinterface

    // This interface should get tied to the LED pins.

    interface SERIAL_WIRES wires;
    endinterface

endmodule
