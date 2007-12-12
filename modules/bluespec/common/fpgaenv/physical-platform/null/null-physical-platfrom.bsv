
// null-physical-platform

// The Null Physical Platform for simulations

// PHYSICAL_DRIVERS

// We have no devices for people to drive.

interface PHYSICAL_DRIVERS;

endinterface

// TOP_LEVEL_WIRES

// We have no wires out the top (which keeps Bluesim happy).

interface TOP_LEVEL_WIRES;

endinterface

// PHYSICAL_PLATFORM

// The platform is the aggregation of wires and drivers.

interface PHYSICAL_PLATFORM;

    interface PHYSICAL_DRIVERS physicalDrivers;
    interface TOP_LEVEL_WIRES  topLevelWires;

endinterface

// mkPhysicalPlatform

// Do nothing.

module mkPhysicalPlatform
       //interface: 
                    (PHYSICAL_PLATFORM);
    
    interface PHYSICAL_DRIVERS physicalDrivers;
   
    endinterface
        
    interface TOP_LEVEL_WIRES topLevelWires;

    endinterface
               
endmodule
