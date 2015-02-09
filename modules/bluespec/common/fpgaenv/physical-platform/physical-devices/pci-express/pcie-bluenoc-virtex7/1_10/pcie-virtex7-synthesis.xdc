
######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################
if {$IS_TOP_BUILD} {

    set_hierarchy_separator /

    # Note use of {} below -- TCL interpret [] as a command evaluation
    #create_clock -name txoutclk -period 10 [get_nets {*_pcieLLDev/dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[0]\.gt_wrapper_i/gtx_channel\.gtxe2_channel_i/TXOUTCLK}]
    #create_clock -name txoutclk -period 10 [get_nets {*_pcieLLDev/dev/ep_pcie_ep/ext_clk\.pipe_clock_i/refclk}]

    #create_clock -name txoutclk -period 10  [get_nets {*_pcieLLDev/dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/PIPE_TXOUTCLK_OUT}]
    current_instance m_sys_sys_vp_m_mod
    create_clock -period 10.000 -name txoutclk [get_nets *_pcieLLDev/dev/ep_pcie_ep/PIPE_TXOUTCLK_OUT]

    create_clock -period 8.000 -name noc_clk [get_pins *_pcieLLDev/dev/ep_clkgen_pll/CLKOUT0]
        

}
        
