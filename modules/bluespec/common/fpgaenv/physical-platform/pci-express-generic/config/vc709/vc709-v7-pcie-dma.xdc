##
## VC707 with PCIe constraints    
##

proc pcieConstraints { } {

    puts "Executing PCIE constraints"

    global IS_AREA_GROUP_BUILD
    global IS_TOP_BUILD

    ######################################################################################################
    # PIN ASSIGNMENTS
    ######################################################################################################

    # PCIe clock is connected automatically by the tool.  Specifying pins just
    # confuses it and can cause IBUFs to be inserted where they shouldn't.
    #set_property LOC AB8  [get_ports { pcieWires_clk_p_put }]
    #set_property LOC AB7  [get_ports { pcieWires_clk_n_put }]

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


    ######################################################################################################
    # CELL LOCATIONS
    ######################################################################################################

    #
    # Transceiver instance placement.  This constraint selects the
    # transceivers to be used, which also dictates the pinout for the
    # transmit and receive differential pairs.  Please refer to the
    # Virtex-7 GT Transceiver User Guide (UG) for more information.
    #

    # PCIe Lane 0
    set_property LOC GTHE2_CHANNEL_X1Y23 [get_cells -hierarchical -regexp {.*pipe_lane\[0\].gt_wrapper_i/gth_channel.gthe2_channel_i}]
    # PCIe Lane 1
    set_property LOC GTHE2_CHANNEL_X1Y22 [get_cells -hierarchical -regexp {.*pipe_lane\[1\].gt_wrapper_i/gth_channel.gthe2_channel_i}]
    # PCIe Lane 2
    set_property LOC GTHE2_CHANNEL_X1Y21 [get_cells -hierarchical -regexp {.*pipe_lane\[2\].gt_wrapper_i/gth_channel.gthe2_channel_i}]
    # PCIe Lane 3
    set_property LOC GTHE2_CHANNEL_X1Y20 [get_cells -hierarchical -regexp {.*pipe_lane\[3\].gt_wrapper_i/gth_channel.gthe2_channel_i}]
    # PCIe Lane 4
    set_property LOC GTHE2_CHANNEL_X1Y19 [get_cells -hierarchical -regexp {.*pipe_lane\[4\].gt_wrapper_i/gth_channel.gthe2_channel_i}]
    # PCIe Lane 5
    set_property LOC GTHE2_CHANNEL_X1Y18 [get_cells -hierarchical -regexp {.*pipe_lane\[5\].gt_wrapper_i/gth_channel.gthe2_channel_i}]
    # PCIe Lane 6
    set_property LOC GTHE2_CHANNEL_X1Y17 [get_cells -hierarchical -regexp {.*pipe_lane\[6\].gt_wrapper_i/gth_channel.gthe2_channel_i}]
    # PCIe Lane 7
    set_property LOC GTHE2_CHANNEL_X1Y16 [get_cells -hierarchical -regexp {.*pipe_lane\[7\].gt_wrapper_i/gth_channel.gthe2_channel_i}]

    #
    # PCI Express Block placement. This constraint selects the PCI Express
    # Block to be used.
    #
    set_property LOC PCIE3_X0Y1 [get_cells -hierarchical -regexp {.*pcie_7vx_i/PCIE_3_0_i}]


    #
    # BlockRAM placement
    #                                          
    # Replay Buffer RAMB Placement
    set_property LOC RAMB36_X12Y53 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/replay_buffer/U0/RAMB36E1[0].u_buffer}]
    set_property LOC RAMB36_X12Y54 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/replay_buffer/U0/RAMB36E1[1].u_buffer}]
    # Non-Posted Request Buffer RAMB Placement
    set_property LOC RAMB18_X12Y90 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[0].u_fifo}]
    set_property LOC RAMB18_X12Y91 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[1].u_fifo}]
    set_property LOC RAMB18_X12Y92 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[2].u_fifo}]
    set_property LOC RAMB18_X12Y93 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/req_fifo/U0/RAMB18E1[3].u_fifo}]
    # Completion Buffer RAMB Placement
    set_property LOC RAMB36_X12Y48 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_250MHz.RAMB36E1[0].u_fifo}]
    set_property LOC RAMB36_X12Y49 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_250MHz.RAMB36E1[1].u_fifo}]
    set_property LOC RAMB36_X12Y50 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_250MHz.RAMB36E1[2].u_fifo}]
    set_property LOC RAMB36_X12Y51 [get_cells -hier -filter {NAME =~ */pcie_top_i/pcie_7vx_i/pcie_bram_7vx_i/cpl_fifo/genblk1.CPL_FIFO_16KB.U0/SPEED_250MHz.RAMB36E1[3].u_fifo}]


    ######################################################################################################
    # AREA GROUPS
    ######################################################################################################

    # Synplify and Vivado produce differently sized area groups 
    if {[getAWBParams {"area_group_tool" "AREA_GROUPS_PAR_DEVICE_AG"}] != "1"} {
        startgroup
        create_pblock pblock_pcie0
        resize_pblock pblock_pcie0 -add {SLICE_X156Y200:SLICE_X221Y299 DSP48_X13Y80:DSP48_X17Y119 RAMB18_X10Y80:RAMB18_X14Y119 RAMB36_X10Y40:RAMB36_X14Y59}
        add_cells_to_pblock pblock_pcie0 [get_cells -hier -filter {NAME =~ *_pcieLLDev_deviceClocked/*}]
        endgroup   
    }        


    ######################################################################################################
    # TIMING CONSTRAINTS
    ######################################################################################################

    if {$IS_TOP_BUILD} {
        set_property LOC IBUFDS_GTE2_X1Y11 [get_cells -hier -filter { NAME =~ *_pcieLLDev_pcieSysClkBuf }]
    } else {
        ## Area group build.  Give hints for clock BUFG placement since
        ## the remote connection points aren't known.
        #set_property -quiet HD.CLK_SRC IBUFDS_GTE2_X1Y5 [get_ports CLK_pcieClock]
        #set_property -quiet HD.CLK_SRC IBUFDS_GTE2_X1Y5 [get_ports CLK_rawClock]

        #set_property LOC BUFGCTRL_X0Y7   [get_cells -hier -filter { NAME =~ */ep_clkgen_pll_clkfbbuf }]
        #set_property LOC BUFGCTRL_X0Y9   [get_cells -hier -filter { NAME =~ */ep_clkgen_clkout0buffer }]
        #set_property LOC BUFGCTRL_X0Y2   [get_cells -hier -filter { NAME =~ */ep_pcie_ep/ext_clk.pipe_clock_i/userclk2_i1.usrclk2_i1 }]
        #set_property LOC BUFGCTRL_X0Y8   [get_cells -hier -filter { NAME =~ */ep_pcie_ep/ext_clk.pipe_clock_i/userclk1_i1.usrclk1_i1 }]
        #set_property LOC BUFGCTRL_X0Y3   [get_cells -hier -filter { NAME =~ */ep_pcie_ep/ext_clk.pipe_clock_i/dclk_i_bufg.dclk_i }]
        #set_property LOC BUFGCTRL_X0Y6   [get_cells -hier -filter { NAME =~ */ep_clkgen_pll_clkfbbuf }]
        #set_property LOC BUFGCTRL_X0Y0   [get_cells -hier -filter { NAME =~ */ep_clkgen_clkout0buffer }]
    }

    # The PLL inside the endpoint
    set_property LOC MMCME2_ADV_X1Y5 [get_cells -hier -filter { NAME =~ */pipe_clock_int.pipe_clock_i/mmcm_i }]

    # The PLL that divides the user clock from the endpoint to make the half clock that we actually use
    set_property LOC MMCME2_ADV_X1Y6 [get_cells -hier -filter { NAME =~ */ep_clkgen_pll }]

    # clocks
    if {$IS_TOP_BUILD} {
        create_clock -name pci_refclk -period 10 [get_nets -hier -filter {NAME =~ pcieWires_clk_n_put}]
    } else {
        create_clock -name pci_refclk -period 10 [get_ports  CLK_pcieClock]
    }
     
    set txoutclk_pins [get_pins -hier -filter { NAME =~ *pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i/TXOUTCLK }]
    create_clock -name txoutclk -period 10 ${txoutclk_pins}

    create_clock -name noc_clk -period 8 [get_pins -hier -filter { NAME =~ */ep_clkgen_pll/CLKOUT0 }] 
    set_max_delay -from [get_clocks userclk1] -to [get_clocks noc_clk] 8.000 -datapath_only
    set_max_delay -from [get_clocks noc_clk] -to [get_clocks userclk1] 8.000 -datapath_only

    # Vivado seems to require this.
    if {!$IS_TOP_BUILD} {
        create_clock -name board_clk -period 5.000 [get_ports CLK_rawClock]
    }
  
    # False Paths
    if {$IS_TOP_BUILD} {
        set_false_path -from [get_ports { pcieWires_rst_put }]
        set_property LOC AV35 [get_ports { pcieWires_rst_put }]       
        set_property IOSTANDARD LVCMOS15 [get_ports { pcieWires_rst_put }]
        set_property PULLUP     true     [get_ports { pcieWires_rst_put }]
    }

    set_case_analysis 1 [get_pins -hierarchical -filter {NAME =~ */pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0}]
    set_case_analysis 0 [get_pins -hierarchical -filter {NAME =~ */pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1}]
}


executePARConstraints  pcieConstraints pcie_ep


set MODEL_CLK_BUFG "BUFGCTRL_X0Y15"

##
## Create the model clock source and check that the crystal frequency
## matches the AWB configuration.
##
proc createModelClock {clock_period} {
    # Convert ns to MHz
    set clock_freq [expr 1000 / $clock_period]

    # AWB clock specification currently accepts only integers.  We expect
    # configurations to round to the nearest integer.
    set awb_clock_freq [getAWBParams {"clocks_device" "CRYSTAL_CLOCK_FREQ"}]
    if {$awb_clock_freq != round($clock_freq)} {
        error "AWB parameter clocks_device:CRYSTAL_CLOCK_FREQ (${awb_clock_freq}) should be ${clock_freq}"
    }

    create_clock -name clocksWires_clk_p_put -period $clock_period [get_ports clocksWires_clk_p_put]
}


##
## Bluespec leaves us with a lot of unconnected "wires" at the top because
## it exposes what it thinks are ready, enable and reset signals as well as
## some fictitious clocks.  
##
## At some point we may remove this method and write code to wrap and clean
## up the generated Bluespec interface.
##
proc deleteDummyTopLevelWires {} {
    set dummy_wires [list \
        CLK_clocksWires_outputClocks_rawClock \
        CLK_clocksWires_outputClocks_clock \
        ]        

    set dummy_ports [list \
        RDY_clocksWires_clk_p_put \
        RDY_clocksWires_clk_n_put \
        RDY_clocksWires_rst_put \
        RDY_pcieWires_clk_p_put \
        RDY_pcieWires_clk_n_put \
        RST_N_clocksWires_outputClocks_baseReset \
        RST_N_clocksWires_outputClocks_reset \
        RST_N_clocksWires_outputClocks_rawReset \
        CLK_GATE_clocksWires_outputClocks_rawClock \
        CLK_clocksWires_outputClocks_rawClock \
        CLK_GATE_clocksWires_outputClocks_clock \
        RDY_pcieWires_rst_put \
        ]        
        
    foreach w $dummy_wires {
        puts "Removing top-level wire ${w}"
        remove_cell ${w}*
    }
    foreach w $dummy_ports {
        puts "Removing top-level wire ${w}"
        remove_net ${w}
        remove_port ${w}
    }
}


if {$IS_TOP_BUILD} {
    set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]
    set_property CFGBVS GND [current_design]
    set_property CONFIG_VOLTAGE 1.8 [current_design]
    set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]

    set_false_path -through [get_nets clocksWires_rst_put]
    set_property PACKAGE_PIN AV40 [get_ports clocksWires_rst_put]
    set_property IOSTANDARD LVCMOS18 [get_ports clocksWires_rst_put]
    set_property PULLUP true [get_ports clocksWires_rst_put]

    deleteDummyTopLevelWires
        
    if {[getAWBParams {"physical_platform" "DRAM_CLOCK_MECHANISM"}] == "InternalBuffered"} {
        bindClockPin H19 [get_ports {clocksWires_clk_p_put}]
        set_property IOSTANDARD DIFF_SSTL15 [get_ports {clocksWires_clk_p_put}]
        bindClockPin G18 [get_ports {clocksWires_clk_n_put}]
        set_property IOSTANDARD DIFF_SSTL15 [get_ports {clocksWires_clk_n_put}]

        createModelClock 5
    } else {
        error "Unsupported clock type!"
    }        

    # Bind user clock bufg.  This is necessary for area group builds.
    # Fix me -- location not yet known for VC709
    #set_property LOC MMCME2_ADV_X0Y1 [get_cells -hier -filter {NAME =~ */llpi_phys_plat_clocks_userClockPackage_m_clk_clk_clks/x/mmcm_adv_inst}]
    #set_property LOC $MODEL_CLK_BUFG [get_cells -hier -filter {NAME =~ */llpi_phys_plat_clocks_userClockPackage_m_clk_clk_clks/x/clkout0_buf}]
    #set_property LOC BUFGCTRL_X0Y14 [get_cells -hier -filter {NAME =~ */llpi_phys_plat_clocks_userClockPackage_m_clk_clk_clks/x/clkf_buf}]

    ##
    ## Put the main reset in the center of the chip.
    ##
    # Find all registers in the primary reset chain.
    set main_reset [get_cells -hier -filter {NAME =~ */llpi_phys_plat_clocks_finalReset_rst/reset_hold_reg[*]}]
    # Sort them and get the terminal register
    set main_reset_last [lrange [lsort -decreasing ${main_reset}] 0 0]
    # Put it in the middle
    set_property LOC SLICE_X111Y249 ${main_reset_last}
}



######################################################################################################
# SYNTHESIS TIMING CONSTRAINTS
######################################################################################################

proc platformSynthConstraints {} {
    if { [llength [get_cells -hier -filter "NAME =~ *_pcieLLDev*"] ] } {
        if { [llength [get_nets -hier -filter {NAME =~ pcieWires_clk_n_put}]] } {
            create_clock -name pci_refclk -period 10 [get_nets -hier -filter {NAME =~ pcieWires_clk_n_put}]
        }

        if { [llength [get_pins -hier -filter { NAME =~ *pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i/TXOUTCLK }]] } {
            create_clock -name txoutclk -period 10 [get_pins -hier -filter { NAME =~ *pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i/TXOUTCLK }]
        }

        if { [llength [get_pins -hier -filter { NAME =~ *clkgen_pll/CLKOUT0 }]] } {
            create_clock -name noc_clk -period 8 [get_pins -hier -filter { NAME =~ *clkgen_pll/CLKOUT0 }]
        }
    }
}


proc pcieSynthConstraints {} {
    create_clock -name pci_refclk -period 10 [get_ports  CLK_pcieClock]
    create_clock -name noc_clk -period 8 [get_pins -hier -filter { NAME =~ *clkgen_pll/CLKOUT0 }]
    create_clock -name txoutclk -period 10 [get_pins -hier -filter { NAME =~ *pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i/TXOUTCLK }]
}


if {!$IS_TOP_BUILD} {
    platformSynthConstraints
}

executeSynthConstraints pcieSynthConstraints pcie_ep


if {!$IS_TOP_BUILD} {
    if { [llength [get_ports clocksWires_clk_p_put]] } {
        create_clock -period 5 -name device_topLevelWires_clocksWires_clk_p_put [get_ports clocksWires_clk_p_put]
    }

    if { [llength [get_ports device_topLevelWires_clocksWires_clk_p_put]] } {
        create_clock -period 5 -name device_topLevelWires_clocksWires_clk_p_put [get_ports device_topLevelWires_clocksWires_clk_p_put]
    }
}

proc modelSynthConstraints {} {
    puts "Annotating model clocks\n"
    annotateModelClockHelper CLK_clocksWires_outputClocks_clock
}

executeSynthConstraints modelSynthConstraints model
