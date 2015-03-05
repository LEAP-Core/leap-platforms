
######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################


proc platformSynthConstraints {} {

    if { [llength [get_cells -hier -filter "NAME =~ *_pcieLLDev*"] ] } {
        #set_hierarchy_separator /

        # Note use of {} below -- TCL interpret [] as a command evaluation

        #current_instance m_sys_sys_vp_m_mod
        if { [llength [get_nets *_pcieLLDev/dev/ep_pcie_ep/PIPE_TXOUTCLK_OUT] ] } {
            create_clock -period 10.000 -name txoutclk [get_nets *_pcieLLDev/dev/ep_pcie_ep/PIPE_TXOUTCLK_OUT]
        }

        if { [llength [get_pins *_pcieLLDev/dev/ep_clkgen_pll/CLKOUT0] ] } {
            create_clock -period 8.000 -name noc_clk [get_pins *_pcieLLDev/dev/ep_clkgen_pll/CLKOUT0]
        }
    }                
}


proc pcieSynthConstraints {} {
   
    create_clock -period 10.000 -name txoutclk [get_nets dev/ep_pcie_ep/PIPE_TXOUTCLK_OUT]
    create_clock -period 8.000 -name noc_clk   [get_pins dev/ep_clkgen_pll/CLKOUT0]

}


platformSynthConstraints

executeSynthConstraints pcieSynthConstraints pcie_ep
