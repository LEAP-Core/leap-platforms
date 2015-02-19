
set MODEL_CLK_BUFG "BUFGCTRL_X0Y15"

##
## Function to find clock pins.
##
proc bindClockPin {clock_pin clock_wire} {
    set_property VCCAUX_IO DONTCARE $clock_wire
    #set_property IOSTANDARD DIFF_SSTL15 $clock_wire
    set_property PACKAGE_PIN $clock_pin $clock_wire
}

##
## Create the model clock source and check that the crystal frequency
## matches the AWB configuration.
##
proc createModelClock {clock_period} {
    # Convert ns to MHz
    set clock_freq [expr 1000 / $clock_period]

    # AWB clock specification currently accepts only integers.  We expect
    # configurations to round to the nearest integer.
    set awb_clock_freq [getAWBParams {"clocks_device" "CRYSTAL_CLOCK_FREQ"}]
    if {$awb_clock_freq != round($clock_freq)} {
        error "AWB parameter clocks_device:CRYSTAL_CLOCK_FREQ (${awb_clock_freq}) should be ${clock_freq}"
    }

    create_clock -name clocksWires_clk_p_put -period $clock_period [get_ports clocksWires_clk_p_put]
}


if {$IS_TOP_BUILD} {

    set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]
    set_property CFGBVS GND [current_design]
    set_property CONFIG_VOLTAGE 1.8 [current_design]
    set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]

    set_false_path -through [get_nets clocksWires_rst_put]
    set_property PACKAGE_PIN AV40 [get_ports clocksWires_rst_put]
    set_property IOSTANDARD LVCMOS18 [get_ports clocksWires_rst_put]
    set_property PULLUP true [get_ports clocksWires_rst_put]

    set_logic_unconnected [get_ports CLK_clocksWires_outputClocks_rawClock]
        
    if {[getAWBParams {"physical_platform" "DRAM_CLOCK_MECHANISM"}] == "ExternalDifferential"} {
        ## System clock
        bindClockPin AK34 [get_ports {clocksWires_clk_p_put}]
        bindClockPin AL34 [get_ports {clocksWires_clk_n_put}]

        createModelClock 6.400

        ## DDR clock
        ##   Parameters taken from memory interface generator when asking for a
        ##   differential clock.

        # PadFunction: IO_L12P_T1_MRCC_38
        bindClockPin E19 [get_ports {ddrWires_clk_p_put}]

        # PadFunction: IO_L12N_T1_MRCC_38
        bindClockPin E18 [get_ports {ddrWires_clk_n_put}]

        create_clock -name ddrWires_clk_p_put -period 5 [get_ports ddrWires_clk_p_put]

        # Bind user clock bufg.  This is necessary for area group builds.
        puts "Top bufg is $MODEL_CLK_BUFG" 

        set_property LOC MMCME2_ADV_X0Y1 [get_cells -hier -filter {NAME =~ */llpi_phys_plat_clocks_userClockPackage_m_clk_clk_clks/x/mmcm_adv_inst}]
        set_property LOC $MODEL_CLK_BUFG [get_cells -hier -filter {NAME =~ */llpi_phys_plat_clocks_userClockPackage_m_clk_clk_clks/x/clkout0_buf}]
        set_property LOC BUFGCTRL_X0Y14 [get_cells -hier -filter {NAME =~ */llpi_phys_plat_clocks_userClockPackage_m_clk_clk_clks/x/clkf_buf}]


    }        

    if {[getAWBParams {"physical_platform" "DRAM_CLOCK_MECHANISM"}] == "InternalUnbuffered"} {
        bindClockPin E19 [get_ports {clocksWires_clk_p_put}]
        bindClockPin E18 [get_ports {clocksWires_clk_n_put}]

        createModelClock 5

        # If we ever use this in lim builds, we'll need to loc down bufg/mmcm as above.
    } 
                                
}


