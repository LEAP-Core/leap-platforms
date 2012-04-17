//
// mkUserClock_PLL --
//   Generate a user clock based on the incoming frequency that is multiplied
//   by clockMultiplier and divided by clockDivider.
//
//   Uses a magic number to generate a correctly ratioed bluespec clock.
//
module mkUserClock_PLL#(Integer inFreq,
                        Integer outFreq)
    // Interface:
        (UserClock);

    UserClock clk = ?;

    // Out frequency is an _absolute_ measure
    Clock pllClock <- mkAbsoluteClock(0, `MAGIC_SIMULATION_CLOCK_FACTOR/outFreq);
    Reset pllReset <- mkInitialReset(10, clocked_by pllClock);

    clk = interface UserClock
              interface clk = pllClock;
              interface rst = pllReset;
          endinterface;

    return clk;

endmodule
