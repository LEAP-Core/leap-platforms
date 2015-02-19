
proc ddr3SynthConstraints { } {
    global IS_AREA_GROUP_BUILD
    global IS_TOP_BUILD

    if { $IS_AREA_GROUP_BUILD } {
        create_clock -name ddrWires_rawClock  -period 5.000 [get_ports CLK_rawClock]
    }
}



executeSynthConstraints ddr3SynthConstraints ddr3

