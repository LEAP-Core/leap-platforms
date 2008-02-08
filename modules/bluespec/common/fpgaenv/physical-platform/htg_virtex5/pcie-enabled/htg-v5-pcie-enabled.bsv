import FIFO::*;
import Clocks::*;

// htg-v5-pcie-enabled

// The Physical Platform for the HTG Virtex 5 with PCI Express.

`include "led_device.bsh"
`include "switch_device.bsh"
`include "pci_express_device.bsh"

// 8 switches and leds

`define NUMBER_LEDS 8
`define NUMBER_SWITCHES 8

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;

    interface LEDS_DRIVER#(`NUMBER_LEDS)         ledsDriver;
    interface SWITCHES_DRIVER#(`NUMBER_SWITCHES) switchesDriver;
    interface PCI_EXPRESS_DRIVER                 pciExpressDriver;
        
endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;

    interface LEDS_WIRES#(`NUMBER_LEDS)          ledsWires;
    interface SWITCHES_WIRES#(`NUMBER_SWITCHES)  switchesWires;
    interface PCI_EXPRESS_WIRES                  pciExpressWires;
    
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
    PCI_EXPRESS_DEVICE                 pci_express_device  <- mkPCIExpressDevice();
    
    // Aggregate the drivers
    
    interface PHYSICAL_DRIVERS physicalDrivers;
    
        interface ledsDriver         = leds_device.driver;
        interface switchesDriver     = switches_device.driver;
        interface pciExpressDriver   = pci_express_device.driver;


    endinterface
    
    // Aggregate the wires
    
    interface TOP_LEVEL_WIRES topLevelWires;
    
        interface ledsWires        = leds_device.wires;
        interface switchesWires    = switches_device.wires;
        interface pciExpressWires  = pci_express_device.wires;

    endinterface
               
endmodule
