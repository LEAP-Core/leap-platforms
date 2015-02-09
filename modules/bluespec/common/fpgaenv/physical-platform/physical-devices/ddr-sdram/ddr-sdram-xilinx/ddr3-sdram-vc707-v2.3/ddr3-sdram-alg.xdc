
# The reset synchronizer of the high-level timing driver has some
# timing paths that extend to the low-level driver.  Declare the synchronizer source cells here. 

annotateClockCrossing $XILINX_DDR_RESET_SYNCHRONIZER_DRIVER $XILINX_DDR_RESET_SYNCHRONIZER_MODEL
annotateClockCrossing $XILINX_DDR_RESET_SYNCHRONIZER_MODEL [get_cells -hier -filter "NAME =~ */u_ddr3_v2_3/u_ddr3_infrastructure/rstdiv*"]
annotateClockCrossing $XILINX_DDR_RESET_SYNCHRONIZER_MODEL [get_cells -hier -filter "NAME =~ */u_ddr3_v2_3/u_iodelay_ctrl/rst*"]
