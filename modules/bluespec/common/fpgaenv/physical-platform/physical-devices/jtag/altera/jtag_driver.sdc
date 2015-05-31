###
#
# JTAG driver constraints - 
#   We have two crossings to annotate. First, the raw clock (there's a strong assumption that this is 50MHz) and the jtag clock. This is in the driver code. 
#   Second we have the raw to user crossing. 
#


annotateSafeClockCrossing [get_clocks altera_reserved_tck] [get_clocks clocksWires_CLK]

annotateSafeClockCrossing [get_clocks clocksWires_CLK] [get_clocks "m_sys_sys_vp_m_mod|llpi_phys_plat_clocks_device_userClockPackage_m_clk|altpll_component|auto_generated|pll1|clk[0]"]

