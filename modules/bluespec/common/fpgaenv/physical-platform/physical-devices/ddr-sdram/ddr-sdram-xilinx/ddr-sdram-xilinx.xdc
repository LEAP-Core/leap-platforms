##
## LEAP TIGs
##
##                            * * * * * * * * * *
## 
## The SDRAM must be instantiated by a parent into a variable named "sdram".
## 
## These clock domains have meaning only when the device-specific UCF file
## declares a DATAPATHONLY TIMESPEC between them.
## 
##                            * * * * * * * * * *

## m_llpi_phys_plat_sdram_b_0_ddrSynth/dramCtrl_ddr3ctrl
#INST "*_clocks_*/*/reset_hold_*"                TNM=TG_model_clk;



annotateClockCrossing [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_reg"] [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_Model_reg"]

#annotateClockCrossing [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_reg"] [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_Model_reg"]


annotateSyncFIFO "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/syncRequestQ"
annotateSyncFIFO "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/syncWriteDataQ"
annotateSyncFIFO "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/syncReadDataQ"


