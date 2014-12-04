
# The reset synchronizer of the high-level timing driver has some
# timing paths that extend to the low-level driver.  Declare the synchronizer source cells here. 

set DESTS [get_cells -hier -filter "NAME =~ m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramCtrl_ddr3ctrl/u_ddr3_v1_7/u_ddr3_infrastructure/rstdiv*"]
                   
annotateClockCrossing $XILINX_DDR_RESET_SYNCHRONIZER $DESTS

