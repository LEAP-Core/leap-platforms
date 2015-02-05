
set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]

set_false_path -through [get_nets clocksWires_rst_put]
set_property PACKAGE_PIN AV40 [get_ports clocksWires_rst_put]
set_property IOSTANDARD LVCMOS18 [get_ports clocksWires_rst_put]
set_property PULLUP true [get_ports clocksWires_rst_put]

set_logic_unconnected [get_ports CLK_clocksWires_outputClocks_rawClock]


##
## Function to find clock pins.
##
proc bindClockPin {clock_pin clock_wire} {
    set_property VCCAUX_IO DONTCARE $clock_wire
    #set_property IOSTANDARD DIFF_SSTL15 $clock_wire
    set_property PACKAGE_PIN $clock_pin $clock_wire
}


if {[getAWBParams {"physical_platform" "DRAM_CLOCK_MECHANISM"}] == "ExternalDifferential"} {
    ## System clock
    bindClockPin AK34 [get_ports {clocksWires_clk_p_put}]
    bindClockPin AL34 [get_ports {clocksWires_clk_n_put}]

    create_clock -name clocksWires_clk_p_put -period 6.400 [get_ports clocksWires_clk_p_put]

    ## DDR clock
    ##   Parameters taken from memory interface generator when asking for a
    ##   differential clock.

    # PadFunction: IO_L12P_T1_MRCC_38
    bindClockPin E19 [get_ports {ddrWires_clk_p_put}]

    # PadFunction: IO_L12N_T1_MRCC_38
    bindClockPin E18 [get_ports {ddrWires_clk_n_put}]

    create_clock -name ddrWires_clk_p_put -period 5 [get_ports ddrWires_clk_p_put]
}        

if {[getAWBParams {"physical_platform" "DRAM_CLOCK_MECHANISM"}] == "InternalUnbuffered"} {
    bindClockPin E19 [get_ports {clocksWires_clk_p_put}]
    bindClockPin E18 [get_ports {clocksWires_clk_n_put}]

    create_clock -name clocksWires_clk_p_put -period 5 [get_ports clocksWires_clk_p_put]
}


