
// ******* general-switch-device *******

// A switch device generalized to any bit width

// *************************************

import Clocks::*;

// SWITCHES_DRIVER

// The interface the rest of the FPGA uses to read the switches

interface SWITCHES_DRIVER#(parameter numeric type n);

    method Bit#(n) getSwitches();

endinterface

// SWITCHES_WIRES

// This interface is not used by the rest of the FPGA.
// Rather this represents wires which are passed to the top level and tied
// to the physical switch pins by the UCF file.

interface SWITCHES_WIRES#(parameter numeric type n);

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


// mkSwitchesDevice

// A switch device generalized to any bit width.
// Uses a Wire to return the current value of the switches.

module mkSwitchesDevice#(Clock topLevelClock, Reset topLevelReset)
    // interface:
                 (SWITCHES_DEVICE#(number_switches_T));

    // Model clock and reset
    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();
    
    // A wire used to communicate the switches from the outside
    // world to our BSV model
    Wire#(Bit#(number_switches_T)) switch_wire <- mkWire(clocked_by topLevelClock, reset_by topLevelReset);
    
    // A sync register used to synchronize the above wire with the model clock
    Reg#(Bit#(number_switches_T)) switch_reg <- mkSyncReg(0, topLevelClock, topLevelReset, modelClock);

    // Copy the current value on the wire into the Sync register
    rule wire_to_reg (True);
        
        switch_reg <= switch_wire;
        
    endrule

    // The interface used by the rest of the FPGA
  
    interface SWITCHES_DRIVER driver;

        // getSwitches
        // Return the current value of the reg.

        method  Bit#(number_switches_T) getSwitches();
            return switch_reg;
        endmethod

    endinterface

    // The wires which are tied to the switches by the UCF

    interface SWITCHES_WIRES wires;
        
        // switches
        // Set the wire to whatever the switches are.
        
        method Action switches(Bit#(number_switches_T) sw);
            switch_wire <= sw;
        endmethod
  
    endinterface
 
endmodule
