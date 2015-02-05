
# The reset synchronizer of the high-level timing driver has some
# timing paths that extend to the low-level driver.  Declare the synchronizer source cells here. 

set XILINX_DDR_RESET_SYNCHRONIZER_MODEL  [get_cells -hier -filter "NAME =~ m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/modelResetInRaw/*"]
set XILINX_DDR_RESET_SYNCHRONIZER_DRIVER [get_cells -hier -filter "NAME =~ m_sys_sys_vp_m_mod/llpi_phys_plat_clocks_currentReset_1_2/asyncReset/*"]
