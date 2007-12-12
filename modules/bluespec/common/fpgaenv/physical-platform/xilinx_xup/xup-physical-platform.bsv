// xup-physical-platform

// Physical Platform for an XUP board

`include "led_device.bsh"
`include "switch_device.bsh"
`include "button_device.bsh"

// 8 switches and leds

`define NUMBER_LEDS 4
`define NUMBER_SWITCHES 4
`define NUMBER_BUTTONS 5

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;

    interface LEDS_DRIVER#(`NUMBER_LEDS)         ledsDriver;
    interface SWITCHES_DRIVER#(`NUMBER_SWITCHES) switchesDriver;
    interface BUTTONS_DRIVER#(`NUMBER_BUTTONS)   buttonsDriver;
        
endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;

    interface LEDS_WIRES#(`NUMBER_LEDS)          ledsWires;
    interface SWITCHES_WIRES#(`NUMBER_SWITCHES)  switchesWires;
    interface BUTTONS_WIRES#(`NUMBER_BUTTONS)    buttonsWires;
    
endinterface

// PHYSICAL_PLATFORM

// The platform is the aggregation of wires and drivers.

interface PHYSICAL_PLATFORM;

    interface PHYSICAL_DRIVERS physicalDrivers;
    interface TOP_LEVEL_WIRES  topLevelWires;

endinterface

// mkPhysicalPlatform

// This is a convenient way for the outside world to instantiate all the devices
// and an aggregation of all the wires.

module mkPhysicalPlatform
       //interface: 
                    (PHYSICAL_PLATFORM);
    
    // Submodules
    
    LEDS_DEVICE#(`NUMBER_LEDS)         leds_device         <- mkLEDsDevice();
    SWITCHES_DEVICE#(`NUMBER_SWITCHES) switches_device     <- mkSwitchesDevice();
    BUTTONS_DEVICE#(`NUMBER_BUTTONS)   buttons_device      <- mkButtonsDevice();
    
    // Aggregate the drivers
    
    interface PHYSICAL_DRIVERS physicalDrivers;
    
        interface ledsDriver         = leds_device.driver;
        interface switchesDriver     = switches_device.driver;
        interface buttonsDriver      = buttons_device.driver;
    
    endinterface
    
    // Aggregate the wires
    
    interface TOP_LEVEL_WIRES topLevelWires;
    
        interface ledsWires        = leds_device.wires;
        interface switchesWires    = switches_device.wires;
        interface buttonsWires     = buttons_device.wires;

    endinterface
               
endmodule
