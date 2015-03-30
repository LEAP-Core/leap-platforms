##
## LEAP TIGs
##
##                            * * * * * * * * * *
## 
## The SDRAM must be instantiated by a parent into a variable named "sdram".
## 
## 
##                            * * * * * * * * * *



set ddrControllerPathPrefix ""
if {$IS_TOP_BUILD} {
    set ddrControllerPathPrefix "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/"
}



proc ddrControllerPARConstraints {} {
    global IS_TOP_BUILD

    set pathPrefix ""

    if {$IS_TOP_BUILD} {
        set pathPrefix "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram*"

        # dramReady CrossingReg.  We could detect this automatically, but
        # don't yet.
        if {[getAWBParams {"synthesis_tool" "PLATFORM_BUILDER"}] == "functools.partial(buildSynplifyEDF, resourceCollector = RESOURCE_COLLECTOR)"} {
            annotateClockCrossing [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReady"] [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReady_Model*"]
            annotateClockCrossing [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReady_replica*"] [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReady_Model*"]

            annotateClockCrossing [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReadyDDR"] [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReady_ddrClock*"]
            annotateClockCrossing [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReadyDDR_replica*"] [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReady_ddrClock*"]
        } else {
            annotateClockCrossing [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReady_reg"] [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReady_Model_reg"]

            annotateClockCrossing [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReadyDDR_reg"] [get_cells -hier -filter "NAME =~ ${pathPrefix}/dramReady_ddrClock_reg"]
        }
        
        #
        # Timing of the incoming raw DDR reset is flexible.
        #
        set ddr_reset [get_cells -hier -filter "NAME =~ ${pathPrefix}ddrReset*/reset_hold*"]
        set_false_path -through ${ddr_reset}
    }
}

executePARConstraints ddrControllerPARConstraints ddr3
