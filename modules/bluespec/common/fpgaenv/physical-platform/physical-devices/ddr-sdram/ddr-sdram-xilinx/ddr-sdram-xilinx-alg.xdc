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

set plat [getAWBParams {"synthesis_tool" "PLATFORM_BUILDER"}]

if {[getAWBParams {"synthesis_tool" "PLATFORM_BUILDER"}] == "functools.partial(buildSynplifyEDF, resourceCollector = RESOURCE_COLLECTOR)"} {
    puts "Using Synplify constraints"
    annotateClockCrossing [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady"] [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_Model*"]
    annotateClockCrossing [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_Model*"] [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/modelResetInRaw/reset_hold*"]
    annotateClockCrossing [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_replica*"] [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_Model*"]
} else {
    puts "Using Non-synplify constraints"
    annotateClockCrossing [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_reg"] [get_cells "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/dramReady_Model_reg"]
}

annotateSyncFIFO "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/syncRequestQ"
annotateSyncFIFO "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/syncWriteDataQ"
annotateSyncFIFO "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/syncReadDataQ"


annotateClockCrossing $XILINX_DDR_RESET_SYNCHRONIZER_MODEL $XILINX_DDR_RESET_SYNCHRONIZER_DRIVER

