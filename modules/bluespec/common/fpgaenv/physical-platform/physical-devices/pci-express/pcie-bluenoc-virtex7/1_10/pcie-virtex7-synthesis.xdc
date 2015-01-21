
######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################
set_hierarchy_separator /

# clocks
create_clock -period 10.000 -name pci_refclk [get_ports pcieWires_clk_n_put]

# Note use of {} below -- TCL interpret [] as a command evaluation
#create_clock -name txoutclk -period 10 [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[0]\.gt_wrapper_i/gtx_channel\.gtxe2_channel_i/TXOUTCLK}]
#create_clock -name txoutclk -period 10 [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/ext_clk\.pipe_clock_i/refclk}]

#create_clock -name txoutclk -period 10  [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/PIPE_TXOUTCLK_OUT}]
current_instance m_sys_sys_vp_m_mod
create_clock -period 10.000 -name txoutclk [get_nets llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/PIPE_TXOUTCLK_OUT]

create_clock -period 8.000 -name noc_clk [get_pins llpi_phys_plat_pcie_pcie_dev/ep_clkgen_pll/CLKOUT0]

set_case_analysis 0 [get_pins -hier -filter { NAME =~ */ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1}]




current_instance -quiet
set_max_delay -datapath_only -from [get_clocks userclk2] -to [get_clocks noc_clk] 4.000
set_max_delay -datapath_only -from [get_clocks noc_clk] -to [get_clocks userclk2] 8.000


