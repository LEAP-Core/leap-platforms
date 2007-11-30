
// ******* general-button-device *******

// A button device generalized to any bit width.
// This version is equivalent to the switches device.
// In the future a more clever interface could be used.

// *************************************


// BUTTON_DRIVER

// The interface the rest of the FPGA uses to read the buttons

interface BUTTON_DRIVER#(parameter numeric type n);

    method Bit#(n) getButtons();

endinterface

// BUTTON_WIRES

// This interface is not used by the rest of the FPGA.
// Rather this represents wires which are passed to the top level and tied
// to the physical button pins by the UCF file.

interface BUTTON_WIRES#(parameter numeric type n);

    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  buttons((* port = "BUTTON" *) Bit#(n) bu);

endinterface


// BUTTONS_DEVICE

// By convention a Device is a combination of a Wires and a Driver.

interface BUTTONS_DEVICE#(parameter numeric type n);


    interface BUTTONS_DRIVER#(n) driver;
    interface BUTTONS_WIRES#(n)  wires;

endinterface


// mkGeneralButtonDevice

// A button device generalized to any bit width.
// Uses a Wire to return the current value of the buttons.

module mkGeneralButtonDevice
    // interface:
                 (BUTTONS_DEVICE#(number_buttons_T));

    // A Wire used to communicate the buttons to the rest of the world.

    Wire#(Bit#(number_buttons_T)) button_wire <- mkWire();
  
    // The interface used by the rest of the FPGA
  
    interface BUTTONS_DRIVER#(number_buttons_T) driver;

        // getButtons
        // Return the current value of the wire.

        method Bit#(number_buttons_T) getButtons();
            return button_wire;
        endmethod

    endinterface

    // The wires which are tied to the buttons by the UCF

    interface BUTTONS_WIRES#(number_buttons_T) wires;
        
        // buttons
        // Set the Wire to whatever the buttons are.
        
        method Action buttons(Bit#(number_buttons_T) bu);
            button_wire <= bu;
        endmethod
  
    endinterface
 
endmodule
