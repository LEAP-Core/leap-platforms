
// ******* general-button-device *******

// A button device generalized to any bit width.
// This version is equivalent to the switches device.
// In the future a more clever interface could be used.

// *************************************


// BUTTONS_DRIVER

// The interface the rest of the FPGA uses to read the buttons

interface BUTTONS_DRIVER#(parameter numeric type n);

    method Bit#(n) getButtons();

endinterface

// BUTTONS_WIRES

// This interface is not used by the rest of the FPGA.
// Rather this represents wires which are passed to the top level and tied
// to the physical button pins by the UCF file.

interface BUTTONS_WIRES#(parameter numeric type n);

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


// mkButtonsDevice

// A button device generalized to any bit width.
// Uses a Wire to return the current value of the buttons.

module mkButtonsDevice#(Clock topLevelClock, Reset topLevelReset)
    // interface:
                 (BUTTONS_DEVICE#(number_buttons_T));

    // A wire used to communicate the switches from the outside
    // world to our BSV model
    Wire#(Bit#(number_buttons_T)) buttons_wire <- mkWire(clocked_by topLevelClock, reset_by topLevelReset);
    
    // A sync register used to synchronize the above wire with the model clock
    Reg#(Bit#(number_buttons_T)) buttons_reg <- mkSyncReg(0, topLevelClock, topLevelReset, modelClock);

    // Copy the current value on the wire into the Sync register
    rule wire_to_reg (True);
        
        buttons_reg <= buttons_wire;
        
    endrule

    // The interface used by the rest of the FPGA
  
    interface BUTTONS_DRIVER driver;

        // getButtons
        // Return the current value of the reg.

        method Bit#(number_buttons_T) getButtons();
            return buttons_reg;
        endmethod

    endinterface

    // The wires which are tied to the buttons by the UCF

    interface BUTTONS_WIRES wires;
        
        // buttons
        // Set the Wire to whatever the buttons are.
        
        method Action buttons(Bit#(number_buttons_T) bu);
            buttons_wire <= bu;
        endmethod
  
    endinterface
 
endmodule
