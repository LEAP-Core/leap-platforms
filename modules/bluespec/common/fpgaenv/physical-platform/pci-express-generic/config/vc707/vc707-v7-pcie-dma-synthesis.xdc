if { [llength [get_ports clocksWires_clk_p_put]] } {
    create_clock -period 6.400 -name device_topLevelWires_clocksWires_clk_p_put [get_ports clocksWires_clk_p_put]
}


if { [llength [get_ports device_topLevelWires_clocksWires_clk_p_put]] } {
    create_clock -period 6.400 -name device_topLevelWires_clocksWires_clk_p_put [get_ports device_topLevelWires_clocksWires_clk_p_put]
}

#if { [llength [get_ports device_topLevelWires_ddrWires_clk_n_put]] } {
#    create_clock -period 5.0 -name device_topLevelWires_ddrWires_clk_n_put [get_ports device_topLevelWires_ddrWires_clk_n_put]
#}


proc modelSynthConstraints {} {
    puts "ANNOTATING MODEL CLOCKS\n"
    annotateModelClockHelper CLK_clocksWires_outputClocks_clock
     
}

executeSynthConstraints modelSynthConstraints model




