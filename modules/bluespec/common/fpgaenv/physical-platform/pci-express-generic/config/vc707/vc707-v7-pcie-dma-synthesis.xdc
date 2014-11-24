
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]

set_false_path -through [get_nets clocksWires_rst_put]

create_clock -name clocksWires_clk_p_put -period 5.000 [get_ports clocksWires_clk_p_put]




