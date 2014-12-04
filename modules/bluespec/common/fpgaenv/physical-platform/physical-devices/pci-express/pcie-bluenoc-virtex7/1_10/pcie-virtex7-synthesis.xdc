
######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################
set_hierarchy_separator {/}

# clocks
create_clock -name pci_refclk -period 10 [get_ports device_topLevelWires_pcieWires_clk_n_put]
puts [get_ports device_topLevelWires_pcieWires_clk_n_put]
puts [get_ports {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i.GT_TXOUTCLK}]
puts [get_ports {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/GT_TXOUTCLK}]
puts [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/PIPE_TXOUTCLK_OUT}]
puts [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/PIPE_TXOUTCLK_OUT}]
puts [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK}]
puts [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/}]
puts [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/PIPE_TXOUTCLK_OUT}]

# Note use of {} below -- TCL interpret [] as a command evaluation
#create_clock -name txoutclk -period 10 [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[0]\.gt_wrapper_i/gtx_channel\.gtxe2_channel_i/TXOUTCLK}]
#create_clock -name txoutclk -period 10 [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/ext_clk\.pipe_clock_i/refclk}]

#create_clock -name txoutclk -period 10  [get_nets {llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/PIPE_TXOUTCLK_OUT}]
create_clock -name txoutclk -period 10  [get_nets llpi_phys_plat_pcie_pcie_dev/ep_pcie_ep/PIPE_TXOUTCLK_OUT]

create_clock -name noc_clk -period 8 [get_pins "llpi_phys_plat_pcie_pcie_dev/ep_clkgen_pll/CLKOUT0"]

set_case_analysis 0 [get_pins -hier -filter { NAME =~ */ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1}]

set_clock_groups -name async_sysclk_coreclk -asynchronous -group [get_clocks -include_generated_clocks board_clk] -group [get_clocks -include_generated_clocks pci_refclk]

set_clock_groups -name async_nocclk_coreclk -asynchronous -group { noc_clk } -group [ get_clocks -include_generated_clocks board_clk ]

set_max_delay -from [get_clocks -include_generated_clocks board_clk] -to [get_clocks noc_clk] 8.000 -datapath_only
set_max_delay -from [get_clocks noc_clk] -to [get_clocks -include_generated_clocks board_clk] 8.000 -datapath_only

set_max_delay -from [get_clocks userclk2] -to [get_clocks noc_clk] 8.000 -datapath_only
set_max_delay -from [get_clocks noc_clk] -to [get_clocks userclk2] 8.000 -datapath_only

