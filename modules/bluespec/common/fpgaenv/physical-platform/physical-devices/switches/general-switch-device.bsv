
// ******* general-switch-device *******

// A switch device generalized to any bit width

// *************************************


// SWITCH_DRIVER

// The interface the rest of the FPGA uses to read the switches

interface SWITCH_DRIVER#(parameter numeric type n);

    method Bit#(n) getSwitches();

endinterface

// SWITCH_WIRES

// This interface is not used by the rest of the FPGA.
// Rather this represents wires which are passed to the top level and tied
// to the physical switch pins by the UCF file.

interface SWITCH_WIRES#(parameter numeric type n);

    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  switches((* port = "SWITCH" *) Bit#(n) sw);

endinterface


// SWITCHES_DEVICE

// By convention a Device is a combination of a Wires and a Driver.

interface SWITCHES_DEVICE#(parameter numeric type n);


    interface SWITCHES_DRIVER#(n) driver;
    interface SWITCHES_WIRES#(n)  wires;

endinterface


// mkGeneralSwitchDevice

// A switch device generalized to any bit width.
// Uses a Wire to return the current value of the switches.

module mkGeneralSwitchDevice
    // interface:
                 (SWITCHES_DEVICE#(number_switches_T));

    // A Wire used to communicate the switches to the rest of the world.

    Wire#(Bit#(number_switches_T)) switch_wire <- mkWire();
  
    // The interface used by the rest of the FPGA
  
    interface SWITCHES_DRIVER#(number_switches_T) driver;

        // getSwitches
        // Return the current value of the wire.

        method  Bit#(number_switches_T) getSwitches();
            return switch_wire;
        endmethod

    endinterface

    // The wires which are tied to the switches by the UCF

    interface SWITCHES_WIRES#(number_switches_T) wires;
        
        // switches
        // Set the Wire to whatever the switches are.
        
        method Action switches(Bit#(number_switches_T) sw);
            switch_wire <= sw;
        endmethod
  
    endinterface
 
endmodule
