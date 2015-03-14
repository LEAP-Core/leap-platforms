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

proc ddrControllerPARConstraints {} {
    global IS_TOP_BUILD

    set pathPrefix ""

    if {$IS_TOP_BUILD} {
        set pathPrefix "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/"
        if {[getAWBParams {"synthesis_tool" "PLATFORM_BUILDER"}] == "functools.partial(buildSynplifyEDF, resourceCollector = RESOURCE_COLLECTOR)"} {
            annotateClockCrossing [get_cells "${pathPrefix}dramReady"] [get_cells "${pathPrefix}dramReady_Model*"]
            annotateClockCrossing [get_cells "${pathPrefix}dramReady_Model*"] [get_cells "${pathPrefix}modelResetInRaw/reset_hold*"]
            annotateClockCrossing [get_cells "${pathPrefix}dramReady_replica*"] [get_cells "${pathPrefix}dramReady_Model*"]
        } else {
            annotateClockCrossing [get_cells "${pathPrefix}dramReady_reg"] [get_cells "${pathPrefix}dramReady_Model_reg"]
        }
        
    }
}

executePARConstraints ddrControllerPARConstraints ddr3

if {$IS_TOP_BUILD} {
    annotateClockCrossing $XILINX_DDR_RESET_SYNCHRONIZER_MODEL $XILINX_DDR_RESET_SYNCHRONIZER_DRIVER       
}
