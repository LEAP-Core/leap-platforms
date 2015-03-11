
######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################


proc platformSynthConstraints {} {

    if { [llength [get_cells -hier -filter "NAME =~ *_pcieLLDev*"] ] } {
        #set_hierarchy_separator /

        # Note use of {} below -- TCL interpret [] as a command evaluation
        if { [llength [get_nets -hier -filter {NAME =~ pcieWires_clk_n_put}] } {
            create_clock -name pci_refclk -period 10 [get_nets -hier -filter {NAME =~ pcieWires_clk_n_put}]
        }

        #current_instance m_sys_sys_vp_m_mod
        if { [llength [get_pins -hier -filter { NAME =~ *pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK }] } {
            create_clock -name txoutclk -period 10 [get_pins -hier -filter { NAME =~ *pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK }]

        }

        if { [llength [get_pins -hier -filter { NAME =~ *clkgen_pll/CLKOUT0 }] } {
            create_clock -name noc_clk -period 8 [get_pins -hier -filter { NAME =~ *clkgen_pll/CLKOUT0 }]
        }
    }                
}


proc pcieSynthConstraints {} {

    create_clock -name pci_refclk -period 10 [get_ports  CLK_pcieClock]   
    create_clock -name noc_clk -period 8 [get_pins -hier -filter { NAME =~ *clkgen_pll/CLKOUT0 }]
    create_clock -name txoutclk -period 10 [get_pins -hier -filter { NAME =~ *pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK }]

}


platformSynthConstraints

executeSynthConstraints pcieSynthConstraints pcie_ep
