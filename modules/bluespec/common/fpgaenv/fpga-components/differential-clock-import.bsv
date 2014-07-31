import XilinxCells::*;
import Clocks::*;
import DefaultValue::*;


interface PRIMITIVE_DIFFERENTIAL_CLOCKS_DEVICE;

    // Wires to be sent to the top level

    method Action clock_p_wire();
    method Action clock_n_wire();
    method Action reset_n_wire();
    
    // Drivers exposed to the model
        
    interface Clock clock;
    interface Reset reset;
        
endinterface


module mkPrimitiveDifferentialClock (PRIMITIVE_DIFFERENTIAL_CLOCKS_DEVICE);

    CLOCK_IMPORTER sysClockN <- mkClockImporter();

    CLOCK_IMPORTER sysClockP <- mkClockImporter();
     
    // Buffer clocks and reset before they are used
    Clock sysClkBuf <- mkClockIBUFDS(defaultValue, sysClockP.clock, sysClockN.clock);

    // And now a bufg 
    Clock sysClkBufG <- mkClockBUFG(clocked_by sysClkBuf);

    RESET_IMPORTER resetIn <- mkResetImporter(clocked_by sysClkBuf);  

    method clock_n_wire = sysClockN.clock_wire;
    method clock_p_wire = sysClockP.clock_wire;
    method reset_n_wire = resetIn.reset_wire;

    interface clock = sysClkBufG;
    interface reset = resetIn.reset;

endmodule
