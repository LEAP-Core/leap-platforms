
// htg-v5-pcie-enabled

// The Physical Platform for the HTG Virtex 5 in independent mode 
// without PCI Express.

`include "led-device.bsh"
`include "switch-device.bsh"
`include "ddr2_sdram_device.bsh"

// 8 switches and leds

`define NUMBER_LEDS 8;
`define NUMBER_SWITCHES 8;

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;

    interface LEDS_DRIVER#(`NUMBER_LEDS)         ledDriver;
    interface SWITCHES_DRIVER#(`NUMBER_SWITCHES) switchDriver;
    interface DDR2_SDRAM_DRIVER                  ddr2SDRAMDriver;

    // each set of physical drivers must support a soft reset method
    method Action soft_reset();
        
endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;

    interface LEDS_WIRES#(`NUMBER_LEDS)         ledWires;
    interface SWITCHES_WIRES#(`NUMBER_SWITCHES) switchWires;
    interface DDR2_SDRAM_WIRES                  ddr2SDRAMWires;
    
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

module mkPhysicalPlatform#(Clock topLevelClock, Reset topLevelReset)
       //interface: 
                    (PHYSICAL_PLATFORM);
    
    // Submodules
    
    LEDS_DEVICE#(`NUMBER_LEDS)         led_device    <- mkGeneralLEDDevice(topLevelClock, topLevelReset);
    SWITCHES_DEVICE#(`NUMBER_SWITCHES) switch_device <- mkGeneralSwitchDevice(topLevelClock, topLevelReset);
    DDR2_SDRAM_DEVICE                  ddr2_sdram_device <- mkDDR2SDRAMDevice(topLevelClock, topLevelReset);

    // Aggregate the drivers
    
    interface PHYSICAL_DRIVERS physicalDrivers;
    
        interface ledDriver        = led_device.driver;
        interface switchDriver     = switch_device.driver;
        interface ddr2SDRAMDriver  = ddr2_sdram_device.driver;
    
        // Soft Reset
        method Action soft_reset();            
            noAction;
        endmethod
    
    endinterface
    
    // Aggregate the wires
    
    interface TOP_LEVEL_WIRES topLevelWires;
    
        interface ledWires        = led_device.wires;
        interface switchWires     = switch_wires.wires;
        interface ddr2SDRAMWires   = ddr2_sdram_device.wires;

    endinterface
               
endmodule
