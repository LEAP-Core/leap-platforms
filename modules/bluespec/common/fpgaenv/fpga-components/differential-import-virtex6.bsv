import XilinxCells::*;
import Clocks::*;


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

    CLOCK_IMPORTER pcieClockN <- mkClockImporter();

    CLOCK_IMPORTER pcieClockP <- mkClockImporter();
     
    // Buffer clocks and reset before they are used
    Clock sysClkBuf <- mkClockIBUFDS(pcieClockP.clock, pcieClockN.clock);

    // And now a bufg 
    Clock sysClkBufG <- mkClockBUFG(clocked_by sysClkBuf);

    RESET_IMPORTER resetIn <- mkResetImporter(clocked_by sysClkBuf);  

    method clock_n_wire = pcieClockN.clock_wire;
    method clock_p_wire = pcieClockP.clock_wire;
    method reset_n_wire = resetIn.reset_wire;

    interface clock = sysClkBufG;
    interface reset = resetIn.reset;

endmodule
