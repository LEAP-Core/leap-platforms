
// null-physical-platform

// The Null Physical Platform for simulations

// PHYSICAL_DRIVERS

// We have no devices for people to drive.

interface PHYSICAL_DRIVERS;
    
    // each set of physical drivers must support a soft reset method
    method Action soft_reset();

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

module mkPhysicalPlatform#(Clock topLevelClock, Reset topLevelReset)
       //interface: 
                    (PHYSICAL_PLATFORM);
    
    interface PHYSICAL_DRIVERS physicalDrivers;
   
        // Soft Reset
        method Action soft_reset();            
            noAction;
        endmethod

    endinterface
        
    interface TOP_LEVEL_WIRES topLevelWires;

    endinterface
               
endmodule
