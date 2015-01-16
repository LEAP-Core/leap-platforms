
set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]

set_false_path -through [get_nets clocksWires_rst_put]
set_property PACKAGE_PIN AV40 [get_ports clocksWires_rst_put]
set_property IOSTANDARD LVCMOS18 [get_ports clocksWires_rst_put]
set_property PULLUP true [get_ports clocksWires_rst_put]

if {[getAWBParams {"physical_platform" "DRAM_CLOCK_MECHANISM"}] == "ExternalDifferential"} {
    set_property LOC AK34  [get_ports { clocksWires_clk_p_put }]
    set_property LOC AL34  [get_ports { clocksWires_clk_n_put }]
    set_property IOSTANDARD DIFF_SSTL15 [get_ports { clocksWires_clk_p_put clocksWires_clk_n_put }]


    create_clock -name clocksWires_clk_p_put -period 6.400 [get_ports clocksWires_clk_p_put]
}        

if {[getAWBParams {"physical_platform" "DRAM_CLOCK_MECHANISM"}] == "InternalUnbuffered"} {
    set_property LOC E19  [get_ports { clocksWires_clk_p_put }]
    set_property LOC E18  [get_ports { clocksWires_clk_n_put }]
    set_property IOSTANDARD DIFF_SSTL15 [get_ports { clocksWires_clk_p_put clocksWires_clk_n_put }]


    create_clock -name clocksWires_clk_p_put -period 5 [get_ports clocksWires_clk_p_put]
}


