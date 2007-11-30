// Top Level Wires for a physical HiTech Global PCIe board

`include "pci_hardware_platform.bsh"

typedef Bit#(8) TOPWIRES_LEDS;
typedef Bit#(8) TOPWIRES_SWITCHES;

interface TopLevelWires;

    interface LEDs_Wires leds_wires;

    interface Switches_Wires switches_wires;

    interface PCIE_Wires pcie_wires;
    
endinterface

interface LEDs_Wires;

    // magic wires that tie to UCF
    (* always_ready *)
    (* result = "LED" *)
    method TOPWIRES_LEDS leds();

endinterface

interface Switches_Wires;

    (* always_ready, always_enabled *)
    (* prefix = "" *)
    method Action  switches((* port = "SWITCH" *) TOPWIRES_SWITCHES sw);

endinterface
    
interface Hardware_Device#(parameter type driver_T, parameter type wires_T);

    interface driver_T driver;
    interface wires_T wires;

endinterface



interface Switches_Driver;

    // wires from/to FPGA model; each of these wires correspond to one
    // of the above magic UCF wires. For now, we do now connect the
    // model wires to the UCF wires directly but use an intermediate latch.
    method  TOPWIRES_SWITCHES     getSwitches();

endinterface

interface LEDs_Driver;

    method  Action      setLEDs(TOPWIRES_LEDS leds_in);
    
endinterface

typedef Hardware_Device#(Switches_Driver, Switches_Wires) Switches_Device;

module mkSwitchesDevice (Switches_Device);

    Reg#(TOPWIRES_SWITCHES) switch_reg <- mkReg(0);
  
    interface Switches_Wires wires;

        method Action switches(TOPWIRES_SWITCHES sw);
            switch_reg <= sw;
        endmethod
  
    endinterface
 
    interface Switches_Driver driver;

        method  TOPWIRES_SWITCHES getSwitches();
            return switch_reg;
        endmethod

    endinterface

endmodule

typedef Hardware_Device#(LEDs_Driver, LEDs_Wires) LEDs_Device;

module mkLEDsDevice (LEDs_Device);

    Reg#(TOPWIRES_LEDS) led_reg <- mkReg(0);
    
    // interfaces to FPGA model

    interface LEDs_Driver driver;

	method  Action setLEDs(TOPWIRES_LEDS leds_in);
            led_reg <= leds_in;
	endmethod
	
    endinterface

    interface LEDs_Wires wires;

        method TOPWIRES_LEDS leds();
            return led_reg;
        endmethod

    endinterface

endmodule
