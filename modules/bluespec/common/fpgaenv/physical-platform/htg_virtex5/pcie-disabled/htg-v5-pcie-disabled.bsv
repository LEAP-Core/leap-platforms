
// htg-v5-pcie-enabled

// The Physical Platform for the HTG Virtex 5 in independent mode 
// without PCI Express.

`include "led-device.bsh"
`include "switch-device.bsh"

// 8 switches and leds

`define NUMBER_LEDS 8;
`define NUMBER_SWITCHES 8;

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;

    interface LED_DRIVER#(`NUMBER_LEDS)        ledDriver;
    interface SWITCH_DRIVER#(`NUMBER_SWITCHES) switchDriver;
        
endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;

    interface LED_WIRES#(`NUMBER_LEDS)        ledWires;
    interface SWITCH_WIRES#(`NUMBER_SWITCHES) switchWires;
    
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
    
    LED_DEVICE#(`NUMBER_LEDS)        led_device         <- mkGeneralLEDDevice();
    SWITCH_DEVICE#(`NUMBER_SWITCHES) switch_device      <- mkGeneralSwitchDevice();
    
    // Aggregate the drivers
    
    interface PHYSICAL_DRIVERS physicalDrivers;
    
        interface ledDriver        = led_device.driver;
        interface switchDriver     = switch_device.driver;
    
    endinterface
    
    // Aggregate the wires
    
    interface TOP_LEVEL_WIRES topLevelWires;
    
        interface ledWires        = led_device.wires;
        interface switchWires     = switch_wires.wires;

    endinterface
               
endmodule
