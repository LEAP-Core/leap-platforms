
// A generalized LED device, including interface 
// to the outside world and wires to tie to pins.
// Polymorphic across the number of LEDs.

import Clocks::*;

// LED_DRIVER

// The Driver interface is the interface that other Bluespec modules
// use to set the LEDs.

interface LEDS_DRIVER#(parameter numeric type n);

    method  Action      setLEDs(Bit#(n) leds_in);
    
endinterface



// LED_WIRES

// The Wires interface is not used by any other Bluespec module.
// It defines wires that are passed to the toplevel where the 
// UCF in the hardware-platform ties them to LED pins

interface LEDS_WIRES#(parameter numeric type n);

    (* always_ready *)
    (* result = "LED" *)
    method Bit#(n) leds();

endinterface


// LED_DEVICE

// By convention a Device is a combination of the Driver and the Wires.
// This interface is polymorphic in the number of LEDs available.

interface LEDS_DEVICE#(parameter numeric type n);

  interface LEDS_DRIVER#(n) driver;
  interface LEDS_WIRES#(n)  wires;

endinterface


// mkGeneralLEDDevice

// An LED Device generalized to any bit width.

module mkLEDsDevice#(Clock topLevelClock, Reset topLevelReset)
    // interface:
                 (LEDS_DEVICE#(number_leds_T));
    
    // Model clock and reset
    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();
    
    // A register to hold the LEDs at the current value, 
    // until the next time someone changes them.
    // This is a sync register because the reader (outside world)
    // and writer (BSV model) are potentially in different clock
    // domains
   
    Reg#(Bit#(number_leds_T)) led_reg <- mkSyncReg(0, modelClock, modelReset, topLevelClock);
    
    // Interface used by the rest of the FPGA.

    interface LEDS_DRIVER driver;

        // setLEDs
        // Just set the register.

	method  Action setLEDs(Bit#(number_leds_T) leds_in);
            led_reg <= leds_in;
	endmethod
	
    endinterface

    // This interface should get tied to the LED pins.

    interface LEDS_WIRES wires;

        // leds

        // Just tie the register to the leds

        method Bit#(number_leds_T) leds();
            return led_reg;
        endmethod

    endinterface

endmodule
