##
## VC709 Aurora SERDES constraints    
##

proc auroraConstraints { } {

    puts "Executing Aurora place and route constraints"

    global IS_AREA_GROUP_BUILD
    global IS_TOP_BUILD

    #######################################################################
    # PIN ASSIGNMENTS
    #######################################################################

    ############################### GT Location ###########################
    # HPC1
    # DP0 is X1Y36 (XM104 - SMA)
    # DP1 is X1Y37 (XM104 - SMA)
    # DP2 is X1Y38 (XM104 - SATA)
    # DP3 is X1Y39 (XM104 - SATA)
    # DP4 is X1Y32 (XM104 - CX4)
    # DP5 is X1Y33 (XM104 - CX4)
    # DP6 is X1Y34 (XM104 - CX4)
    # DP7 is X1Y35 (XM104 - CX4)

    # Schematic of VC707.
    #  |------|CX4  32-35 GBTCLK0 pA10/nA9 |-----|
    #  |       SMA  36-37 GBTCLK1 pE10/nE9 <-use |
    #  |       SATA 38-39 GBTCLK0                |
    #  |ETH    FMC1/HPC1                         |
    #  |                                         |
    #  |                                         |
    #  |-----| PCIE |----------------------------|
    #


    # HPC1 -- GBTCLK0 on XM104
    set_property LOC E9   [get_ports { auroraWires_hpc_clk_n_put }]
    set_property LOC E10  [get_ports { auroraWires_hpc_clk_p_put }]

     # xm104 SATA cables
     set_property LOC GTHE2_CHANNEL_X1Y38 [get_cells -hierarchical -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_1_block_i/aurora_64b66b_1_i/inst/aurora_64b66b_1_wrapper_i/aurora_64b66b_1_multi_gt_i/aurora_64b66b_1_gt_inst/gthe2_i }]
     set_property LOC GTHE2_CHANNEL_X1Y39 [get_cells -hierarchical -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_1_block_i/aurora_64b66b_1_i/inst/aurora_64b66b_1_wrapper_i/aurora_64b66b_1_multi_gt_i/aurora_64b66b_1_gt_inst_lane1/gthe2_i }]


    #######################################################################
    # TIMING CONSTRAINTS
    #######################################################################


    # FMC SATA base clock is 156.25MHz
    create_clock -period 6.4  [get_ports { auroraWires_hpc_clk_n_put }]
    set user_clk0 [create_clock -period 6.4  [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/user_clk_i }]]
    create_clock -period 3.2  [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_1_block_i/sync_clk_i }]
    create_clock -period 3.2  [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_1_block_i/aurora_64b66b_1_i/inst/aurora_64b66b_1_wrapper_i/rxrecclk_to_fabric_i }]
    create_clock -period 3.2  [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_1_block_i/aurora_64b66b_1_i/inst/aurora_64b66b_1_wrapper_i/aurora_64b66b_1_multi_gt_i/aurora_64b66b_1_gt_inst/gthe2_i/RXOUTCLK}]
    create_clock -period 3.2  [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_1_block_i/aurora_64b66b_1_i/inst/aurora_64b66b_1_wrapper_i/aurora_64b66b_1_multi_gt_i/aurora_64b66b_1_gt_inst/gthe2_i/TXOUTCLK}]


    # Separate clock domains
    set init_clk [get_clocks -of_objects [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/INIT_CLK_i }]]
    set_clock_groups -asynchronous -group $user_clk0 -group $init_clk    

    set_false_path -to [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_*/*/data_fifo*/RST }]
    set_false_path -to [get_pins -hier *aurora_64b66b_1_cdc_to*/D]
    set_false_path -to [get_pins -hier *rxrecclk_bufg_i*/CE]


    #######################################################################
    # AREA GROUPS
    #######################################################################

    if {[getAWBParams {"area_group_tool" "AREA_GROUPS_PAR_DEVICE_AG"}] != "1"} {
        startgroup
        create_pblock pblock_aurora0
        resize_pblock pblock_aurora0 -add {SLICE_X170Y450:SLICE_X221Y499}
        set_property   gridtypes {RAMB36 RAMB18 DSP48 SLICE} [get_pblocks  pblock_aurora0]
        add_cells_to_pblock pblock_aurora0 [get_cells -hier -filter {NAME =~ *aurora_device/ug_device_0/*}]
        add_cells_to_pblock pblock_aurora0 [get_cells -hier -filter {NAME =~ *aurora_device/*auroraFlowcontrol_0*}]
        endgroup       
    }        

}

executePARConstraints auroraConstraints pcie_ep


proc auroraSynthConstraints {} {
    puts "Executing Aurora synthesis constraints"

    # FMC SATA base clock is 156.25MHz
    create_clock -period 6.400 [get_ports { device_topLevelWires_auroraWires_hpc_clk_n_put }]

    # Create clock constraint for RXOUTCLK from GT
    create_clock -period 3.2  [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_1_block_i/aurora_64b66b_1_i/inst/aurora_64b66b_1_wrapper_i/aurora_64b66b_1_multi_gt_i/aurora_64b66b_1_gt_inst/gthe2_i/RXOUTCLK}]
    create_clock -period 3.2  [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_1_block_i/aurora_64b66b_1_i/inst/aurora_64b66b_1_wrapper_i/aurora_64b66b_1_multi_gt_i/aurora_64b66b_1_gt_inst_lane1/gthe2_i/TXOUTCLK }]

}

if {! $IS_TOP_BUILD} {
    if ([llength [get_ports { device_topLevelWires_auroraWires_hpc_clk_n_put }]]) {
        auroraSynthConstraints
    }
}
