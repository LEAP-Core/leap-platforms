module BSCAN(CAPTURE,
	     DRCK,
	     RESET,
	     SEL,
	     SHIFT,
             TDI,
             UPDATE,
             TDO);
   output CAPTURE;
   output DRCK;
   output RESET;
   output SEL;  
   output SHIFT;
   input  TDI;
   output UPDATE;
   output TDO;
   
  
  // BSCAN_VIRETX5: Boundary Scan primitive for connecting internal
  // logic to JTAG interface.
  // Virtex-5
  // Xilinx HDL Libraries Guide, version 9.1i
  BSCAN_VIRTEX5 #(
		  .JTAG_CHAIN(2) // This 2 was the default...
		  ) BSCAN_VIRTEX5_inst (
					.CAPTURE(CAPTURE), // CAPTURE output from TAP controller
					.DRCK(DRCK), // Data register output for USER function
					.RESET(RESET), // Reset output from TAP controller
					.SEL(SEL), // USER active output
					.SHIFT(SHIFT), // SHIFT output from TAP controller
					.TDI(TDI), // TDI output from TAP controller
					.UPDATE(UPDATE), // UPDATE output from TAP controller
		                        .TDO(TDO)			
					);
endmodule