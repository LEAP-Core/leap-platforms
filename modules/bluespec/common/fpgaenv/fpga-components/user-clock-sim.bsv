//
// mkUserClock_Ratio --
//  A ratioed clock based on the simulation factor.  
//  We need this in simulation because of users instantiating it directly in 
//  MCD codes.  
//
module mkUserClock_Ratio#(Integer inFreq, Integer clockMultiplier, Integer clockDivider) (UserClock); 

    Clock rawClock <- mkAbsoluteClock(0, 
        `MAGIC_SIMULATION_CLOCK_FACTOR/inFreq*clockDivider/clockMultiplier);
    let usr_reset <- mkAsyncResetFromCR(0, rawClock);

    interface clk = rawClock;
    interface rst = usr_reset;
endmodule