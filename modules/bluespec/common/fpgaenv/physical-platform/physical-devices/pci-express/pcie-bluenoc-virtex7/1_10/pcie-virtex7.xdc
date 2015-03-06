######################################################################################################
# PIN ASSIGNMENTS
######################################################################################################
if {$IS_TOP_BUILD} {
    set_property LOC AD8  [get_ports { pcieWires_clk_p_put }]
    set_property LOC AD7  [get_ports { pcieWires_clk_n_put }]


    set_property LOC Y4   [get_ports { pcieWires_pcie_exp_rxp_i[0] }]
    set_property LOC AA6  [get_ports { pcieWires_pcie_exp_rxp_i[1] }]
    set_property LOC AB4  [get_ports { pcieWires_pcie_exp_rxp_i[2] }]
    set_property LOC AC6  [get_ports { pcieWires_pcie_exp_rxp_i[3] }]
    set_property LOC AD4  [get_ports { pcieWires_pcie_exp_rxp_i[4] }]
    set_property LOC AE6  [get_ports { pcieWires_pcie_exp_rxp_i[5] }]
    set_property LOC AF4  [get_ports { pcieWires_pcie_exp_rxp_i[6] }]
    set_property LOC AG6  [get_ports { pcieWires_pcie_exp_rxp_i[7] }]

    set_property LOC Y3   [get_ports { pcieWires_pcie_exp_rxn_i[0] }]
    set_property LOC AA5  [get_ports { pcieWires_pcie_exp_rxn_i[1] }]
    set_property LOC AB3  [get_ports { pcieWires_pcie_exp_rxn_i[2] }]
    set_property LOC AC5  [get_ports { pcieWires_pcie_exp_rxn_i[3] }]
    set_property LOC AD3  [get_ports { pcieWires_pcie_exp_rxn_i[4] }]
    set_property LOC AE5  [get_ports { pcieWires_pcie_exp_rxn_i[5] }]
    set_property LOC AF3  [get_ports { pcieWires_pcie_exp_rxn_i[6] }]
    set_property LOC AG5  [get_ports { pcieWires_pcie_exp_rxn_i[7] }]

    set_property LOC W2   [get_ports { pcieWires_pcie_exp_txp[0] }]
    set_property LOC AA2  [get_ports { pcieWires_pcie_exp_txp[1] }]
    set_property LOC AC2  [get_ports { pcieWires_pcie_exp_txp[2] }]
    set_property LOC AE2  [get_ports { pcieWires_pcie_exp_txp[3] }]
    set_property LOC AG2  [get_ports { pcieWires_pcie_exp_txp[4] }]
    set_property LOC AH4  [get_ports { pcieWires_pcie_exp_txp[5] }]
    set_property LOC AJ2  [get_ports { pcieWires_pcie_exp_txp[6] }]
    set_property LOC AK4  [get_ports { pcieWires_pcie_exp_txp[7] }]

    set_property LOC W1   [get_ports { pcieWires_pcie_exp_txn[0] }]
    set_property LOC AA1  [get_ports { pcieWires_pcie_exp_txn[1] }]
    set_property LOC AC1  [get_ports { pcieWires_pcie_exp_txn[2] }]
    set_property LOC AE1  [get_ports { pcieWires_pcie_exp_txn[3] }]
    set_property LOC AG1  [get_ports { pcieWires_pcie_exp_txn[4] }]
    set_property LOC AH3  [get_ports { pcieWires_pcie_exp_txn[5] }]
    set_property LOC AJ1  [get_ports { pcieWires_pcie_exp_txn[6] }]
    set_property LOC AK3  [get_ports { pcieWires_pcie_exp_txn[7] }]


    set_property LOC IBUFDS_GTE2_X1Y5  [get_cells -hier -filter { NAME =~ *_pcieLLDev_pcieSysClkBuf }]
}

proc pcieConstraints { } {

    puts "Executing PCIE constraints"

    global IS_AREA_GROUP_BUILD
    global IS_TOP_BUILD

    ######################################################################################################
    # CELL LOCATIONS
    ######################################################################################################
    #
    #
    # SYS clock 100 MHz (input) signal. The sys_clk_p and sys_clk_n
    # signals are the PCI Express reference clock. Virtex-7 GT
    # Transceiver architecture requires the use of a dedicated clock
    # resources (FPGA input pins) associated with each GT Transceiver.
    # To use these pins an IBUFDS primitive (refclk_ibuf) is
    # instantiated in user's design.
    # Please refer to the Virtex-7 GT Transceiver User Guide
    # (UG) for guidelines regarding clock resource selection.
    #

    set_property LOC MMCME2_ADV_X1Y2 [get_cells -hier -filter { NAME =~ */ext_clk.pipe_clock_i/mmcm_i }]
    set_property LOC MMCME2_ADV_X1Y1 [get_cells -hier -filter { NAME =~ *clkgen_pll }]
    #set_property LOC BUFGCTRL_X0Y1   [get_cells -hier -filter { NAME =~ *ep_clkgen_clkout0buffer }]
    #set_property LOC MMCME2_ADV_X1Y5 [get_cells -hier -filter { NAME =~ *clk_gen_pll }]

    #set_property DONT_TOUCH true [get_cells -hierarchical -filter { PRIMITIVE_TYPE == IO.ibuf.IBUF } ]

    #
    # Transceiver instance placement.  This constraint selects the
    # transceivers to be used, which also dictates the pinout for the
    # transmit and receive differential pairs.  Please refer to the
    # Virtex-7 GT Transceiver User Guide (UG) for more information.
    #

    # PCIe Lane 0
    set_property LOC GTXE2_CHANNEL_X1Y11 [get_cells -hierarchical -regexp {.*pipe_lane\[0\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
    # PCIe Lane 1
    set_property LOC GTXE2_CHANNEL_X1Y10 [get_cells -hierarchical -regexp {.*pipe_lane\[1\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
    # PCIe Lane 2
    set_property LOC GTXE2_CHANNEL_X1Y9 [get_cells -hierarchical -regexp {.*pipe_lane\[2\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
    # PCIe Lane 3
    set_property LOC GTXE2_CHANNEL_X1Y8 [get_cells -hierarchical -regexp {.*pipe_lane\[3\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
    # PCIe Lane 4
    set_property LOC GTXE2_CHANNEL_X1Y7 [get_cells -hierarchical -regexp {.*pipe_lane\[4\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
    # PCIe Lane 5
    set_property LOC GTXE2_CHANNEL_X1Y6 [get_cells -hierarchical -regexp {.*pipe_lane\[5\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
    # PCIe Lane 6
    set_property LOC GTXE2_CHANNEL_X1Y5 [get_cells -hierarchical -regexp {.*pipe_lane\[6\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
    # PCIe Lane 7
    set_property LOC GTXE2_CHANNEL_X1Y4 [get_cells -hierarchical -regexp {.*pipe_lane\[7\].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]

    #
    # PCI Express Block placement. This constraint selects the PCI Express
    # Block to be used.
    #
    set_property LOC PCIE_X1Y0 [get_cells -hierarchical -regexp {.*pcie_7x_i/pcie_block_i}]

    #
    # BlockRAM placement
    #                                          

    set_property LOC RAMB36_X13Y25 [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    set_property LOC RAMB36_X13Y24 [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    set_property LOC RAMB36_X13Y23 [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    set_property LOC RAMB36_X13Y22 [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    set_property LOC RAMB36_X13Y21 [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[0].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    set_property LOC RAMB36_X13Y20 [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[1].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    set_property LOC RAMB36_X13Y19 [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[2].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    set_property LOC RAMB36_X13Y18 [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[3].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    #set_property LOC RAMB36_X13Y17 [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[4].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    #set_property LOC RAMB36_X14Y17 [get_cells {*/pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[5].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    #set_property LOC RAMB36_X14Y18 [get_cells {*/pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[6].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]
    #set_property LOC RAMB36_X14Y19 [get_cells {*/pcie_7x_v1_10_i/pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[7].ram/use_tdp.ramb36/genblk*.bram36_tdp_bl.bram36_tdp_bl}]

    ######################################################################################################
    # AREA GROUPS
    ######################################################################################################

    # Synplify and Vivado produce differently sized area groups 
    if {[getAWBParams {"area_group_tool" "AREA_GROUPS_PAR_DEVICE_AG"}] != "1"} {
        startgroup
        create_pblock pblock_pcie0
        if {[getAWBParams {"synthesis_tool" "PLATFORM_BUILDER"}] == "functools.partial(buildSynplifyEDF, resourceCollector = RESOURCE_COLLECTOR)"} {
            resize_pblock pblock_pcie0 -add {SLICE_X183Y51:SLICE_X221Y149 DSP48_X16Y22:DSP48_X19Y59 RAMB18_X11Y22:RAMB18_X14Y59 RAMB36_X11Y11:RAMB36_X14Y29}
        } else {
            resize_pblock pblock_pcie0 -add {SLICE_X166Y51:SLICE_X221Y149 DSP48_X16Y22:DSP48_X19Y59 RAMB18_X11Y22:RAMB18_X14Y59 RAMB36_X11Y11:RAMB36_X14Y29}
        }
        add_cells_to_pblock pblock_pcie0 [get_cells -hier -filter {NAME =~ *_pcieLLDev_deviceClocked/*}]
        endgroup   
    }        



    ######################################################################################################
    # TIMING CONSTRAINTS
    ######################################################################################################

    # clocks
    if {$IS_TOP_BUILD} {
        create_clock -name pci_refclk -period 10 [get_nets -hier -filter {NAME =~ pcieWires_clk_n_put}]
    } else {
         create_clock -name pci_refclk -period 10 [get_ports  CLK_pcieClock]
         #set_property LOC AD8  [get_ports { wires_clk_p_put }]
         #set_property LOC AD7  [get_ports { wires_clk_n_put }]
    }
     
    create_clock -name txoutclk -period 10 [get_pins -hier -filter { NAME =~ *pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK }]

    create_clock -name noc_clk -period 8 [get_pins -hier -filter { NAME =~ *clkgen_pll/CLKOUT0 }]

    # This code is fairly specific to the VC707, since it assumes knowledge of the physical clocking. The clock information is not
    # necessary. However, Vivado seems to require it.  

    if {$IS_TOP_BUILD} {
        create_clock -name board_clk -period 5.000 [get_ports clocksWires_clk_p_put]
    } else {
        create_clock -name board_clk -period 5.000 [get_ports CLK_rawClock]
    }
  
    if {$IS_TOP_BUILD} {
        set_property LOC IBUFDS_GTE2_X1Y5  [get_cells -hier -filter { NAME =~ *_pcieLLDev_pcieSysClkBuf }]
    } else {
        set_property -quiet HD.CLK_SRC IBUFDS_GTE2_X1Y5 [get_ports CLK_pcieClock]
        set_property -quiet HD.CLK_SRC IBUFDS_GTE2_X1Y5 [get_ports CLK_rawClock]
        set_property LOC MMCME2_ADV_X1Y1 [get_cells -hier -filter { NAME =~ */ep_clkgen_pll}]
        set_property LOC BUFGCTRL_X0Y7   [get_cells -hier -filter { NAME =~ */ep_clkgen_pll_clkfbbuf }]
        set_property LOC BUFGCTRL_X0Y9   [get_cells -hier -filter { NAME =~ */ep_clkgen_clkout0buffer }]
        set_property LOC BUFGCTRL_X0Y2   [get_cells -hier -filter { NAME =~ */ep_pcie_ep/ext_clk.pipe_clock_i/userclk2_i1.usrclk2_i1 }]
        set_property LOC BUFGCTRL_X0Y8   [get_cells -hier -filter { NAME =~ */ep_pcie_ep/ext_clk.pipe_clock_i/userclk1_i1.usrclk1_i1 }]
        set_property LOC BUFGCTRL_X0Y3   [get_cells -hier -filter { NAME =~ */ep_pcie_ep/ext_clk.pipe_clock_i/dclk_i_bufg.dclk_i }]
        set_property LOC BUFGCTRL_X0Y6   [get_cells -hier -filter { NAME =~ */ep_clkgen_pll_clkfbbuf }]
        set_property LOC BUFGCTRL_X0Y0   [get_cells -hier -filter { NAME =~ */ep_clkgen_clkout0buffer }]
    }

    # False Paths
    if {$IS_TOP_BUILD} {
        set_false_path -from [get_ports { pcieWires_rst_put }]
        set_property LOC AV35  [get_ports { pcieWires_rst_put }]       
        set_property IOSTANDARD LVCMOS15    [get_ports { pcieWires_rst_put }]
        set_property PULLUP     true        [get_ports { pcieWires_rst_put }]
    }

    set_false_path -through [get_pins -hierarchical {*pcie_block_i/PLPHYLNKUPN*}]
    set_false_path -through [get_pins -hierarchical {*pcie_block_i/PLRECEIVEDHOTRST*}]

    # This constraint is generating a critical warning. 
    set_false_path -through [get_nets -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/user_resetdone*}]
    set_false_path -through [get_nets -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[0].pipe_rate.pipe_rate_i/*}]
    set_false_path -through [get_nets -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[1].pipe_rate.pipe_rate_i/*}]
    set_false_path -through [get_nets -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[2].pipe_rate.pipe_rate_i/*}]
    set_false_path -through [get_nets -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[3].pipe_rate.pipe_rate_i/*}]
    set_false_path -through [get_nets -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[4].pipe_rate.pipe_rate_i/*}]
    set_false_path -through [get_nets -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[5].pipe_rate.pipe_rate_i/*}]
    set_false_path -through [get_nets -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[6].pipe_rate.pipe_rate_i/*}]
    set_false_path -through [get_nets -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_lane[7].pipe_rate.pipe_rate_i/*}]

    set_false_path -through [get_cells -hier -filter { NAME =~ */pcie_7x_v1_10_i/gt_top_i/pipe_wrapper_i/pipe_reset.pipe_reset_i/cpllreset*}]

    set_false_path -through [get_nets -hier -filter { NAME =~ */ext_clk.pipe_clock_i/pclk_sel*}]

    set_case_analysis 1 [get_pins  -hier -filter { NAME =~ */ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0}]
    set_case_analysis 0 [get_pins -hier -filter { NAME =~ */ext_clk.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1}]

    set_clock_groups -name async_sysclk_coreclk -asynchronous -group [get_clocks -include_generated_clocks board_clk] -group [get_clocks -include_generated_clocks pci_refclk]

    set_clock_groups -name async_nocclk_coreclk -asynchronous -group { noc_clk } -group [ get_clocks -include_generated_clocks board_clk ]

    set_max_delay -from [get_clocks -include_generated_clocks board_clk] -to [get_clocks noc_clk] 8.000 -datapath_only
    set_max_delay -from [get_clocks noc_clk] -to [get_clocks -include_generated_clocks board_clk] 8.000 -datapath_only

    set_max_delay -from [get_clocks userclk2] -to [get_clocks noc_clk] 8.000 -datapath_only
    set_max_delay -from [get_clocks noc_clk] -to [get_clocks userclk2] 8.000 -datapath_only
}


executePARConstraints  pcieConstraints pcie_ep
