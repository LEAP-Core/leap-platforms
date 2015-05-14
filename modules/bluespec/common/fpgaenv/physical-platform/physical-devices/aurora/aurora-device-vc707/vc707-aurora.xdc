##
## VC707 Aurora SERDES constraints    
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
    # DP0 is X1Y24 (XM104 - SMA)
    # DP1 is X1Y25 (XM104 - SMA)
    # DP2 is X1Y26 (XM104 - SATA)
    # DP3 is X1Y27 (XM104 - SATA)
    # DP4 is X1Y20 (XM104 - CX4)
    # DP5 is X1Y21 (XM104 - CX4)
    # DP6 is X1Y22 (XM104 - CX4)
    # DP7 is X1Y23 (XM104 - CX4)

    # Schematic of VC707.
    #  |------|CX4  20-23 GBTCLK1 pA10/nA9 |-----|CX4  12-15 GBTCLK1 pT8/nT7 |----|
    #  |       SMA  24-25 GBTCLK0 pE10/nE9        SMA  16-17 GBTCLK0 pK8/nK7      |
    #  |       SATA 26-27 GBTCLK0                 SATA 18-19 GBTCLK0              |
    #  |ETH    FMC1/HPC1                          FMC2/HPC2                       |
    #  |                                                                          |
    #  |                                                                          |
    #  |-----| PCIE |-------------------------------------------------------------|
    #

    # SMA 
    set_property LOC AH7  [get_ports { auroraWires_sma_clk_n_put }]
    set_property LOC AH8  [get_ports { auroraWires_sma_clk_p_put }]

    # HPC1 -- GBTCLK0 on XM104
    set_property LOC E9   [get_ports { auroraWires_hpc_clk_n_put }]
    set_property LOC E10  [get_ports { auroraWires_hpc_clk_p_put }]

    # On-board SMA cables
    set_property LOC GTXE2_CHANNEL_X1Y0 [get_cells -hierarchical -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i }]
    set_property LOC GTXE2_CHANNEL_X1Y1 [get_cells -hierarchical -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST_LANE1/gtxe2_i }]

    # xm104 SMA cables
    #set_property LOC GTXE2_CHANNEL_X1Y16 [get_cells -hierarchical -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i }]
    #set_property LOC GTXE2_CHANNEL_X1Y17 [get_cells -hierarchical -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST_LANE1/gtxe2_i }]

     # xm104 SATA cables
     #set_property LOC GTXE2_CHANNEL_X1Y18 [get_cells -hierarchical -filter { NAME =~ *aurora_device/ug_device_1/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i }]
     #set_property LOC GTXE2_CHANNEL_X1Y19 [get_cells -hierarchical -filter { NAME =~ *aurora_device/ug_device_1/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST_LANE1/gtxe2_i }]


    #######################################################################
    # TIMING CONSTRAINTS
    #######################################################################

    # SMA base clock is 125MHz
    create_clock -period 8    [get_ports { auroraWires_sma_clk_n_put }]
    set user_clk0 [create_clock -period 16   [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/user_clk_i }]]
    create_clock -period 8    [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/sync_clk_i }]
    create_clock -period 8    [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/rxrecclk_to_pll_i }]
    create_clock -period 4   [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i/TXOUTCLK }]
    create_clock -period 4   [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i/RXOUTCLK }]

    #set_max_delay -through [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/enable_32_i }] 16


    # FMC SATA base clock is 156.25MHz
    #create_clock -period 6.4  [get_ports { auroraWires_hpc_clk_n_put }]
    #set user_clk0 [create_clock -period 6.4  [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/user_clk_i }]]
    #create_clock -period 3.2  [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/sync_clk_i }]
    #create_clock -period 3.2  [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/rxrecclk_to_pll_i }]
    #create_clock -period 6.4  [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i/TXOUTCLK }]
    #create_clock -period 6.4  [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i/RXOUTCLK }]

    #set_max_delay -through [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/enable_32_i }] 6.4


    # Separate clock domains
    set init_clk [get_clocks -of_objects [get_nets -hier -filter { NAME =~ *aurora_device/ug_device_0/INIT_CLK_i }]]
    set_clock_groups -asynchronous -group $user_clk0 -group $init_clk
    #set_clock_groups -asynchronous -group $user_clk1 -group $init_clk

    # we have a clock crossing between the raw initialization clock and our internal clock, which 
    annotateSafeClockCrossing [get_cells -hier -filter {NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/rxdata_to_fifo_i5_reg*}] [get_cells -hier -filter {NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/cbcc_gtx0_i/count_for_reset_r_reg*}]  

    set_false_path -through [get_nets -hier -filter { NAME=~ *aurora_device/ug_device_*/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/cbcc_gtx0*/fifo_reset_i }]
    set_false_path -to [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_*/*/data_fifo*/RST }]

    #set_false_path -to [get_pins -hier *rxrecclk_bufg_i*/CE]

    # Constraints for RX Recovered clocks
    foreach ifc [list 0 ] {
        set fds  [get_cells -filter {REF_NAME =~ FD*}  -of [get_pins -leaf -of [get_nets -hier -filter "NAME =~ *aurora_device/ug_device_${ifc}/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/enable_32_i"]]]
        set srls [get_cells -filter {REF_NAME =~ SRL*} -of [get_pins -leaf -of [get_nets -hier -filter "NAME =~ *aurora_device/ug_device_${ifc}/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/enable_32_i"]]]

        set_multicycle_path -from $fds -to $fds -setup 2
        set_multicycle_path -from $fds -to $fds -hold  1

        set_multicycle_path -from $srls -to $fds -setup 2
        set_multicycle_path -from $srls -to $fds -hold  1

        set_multicycle_path -from $fds -to $srls -setup 2
        set_multicycle_path -from $fds -to $srls -hold  1
    }


    #######################################################################
    # AREA GROUPS
    #######################################################################


    startgroup
    create_pblock pblock_aurora0
    #resize_pblock pblock_aurora0 -add {SLICE_X190Y0:SLICE_X221Y49 RAMB36_X14Y6:RAMB36_X14Y7 RAMB36_X13Y5:RAMB36_X13Y8}
    resize_pblock pblock_aurora0 -add {SLICE_X180Y0:SLICE_X221Y49}
    set_property   gridtypes {RAMB36 RAMB18 DSP48 SLICE} [get_pblocks  pblock_aurora0]
    add_cells_to_pblock pblock_aurora0 [get_cells -hier -filter {NAME =~ *aurora_device/ug_device_0/*}]
    add_cells_to_pblock pblock_aurora0 [get_cells -hier -filter {NAME =~ *aurora_device/*auroraFlowcontrol_0*}]
    endgroup   

#    if {[getAWBParams {"area_group_tool" "AREA_GROUPS_PAR_DEVICE_AG"}] == "1"} {
#        startgroup
#        create_pblock pblock_aurora0
#        resize_pblock pblock_aurora1 -add {SLICE_X190Y200:SLICE_X221Y249 RAMB36_X14Y43:RAMB36_X14Y44 RAMB36_X13Y42:RAMB36_X13Y45}
#        resize_pblock pblock_aurora0 -add {SLICE_X190Y0:SLICE_X221Y49 RAMB36_X14Y6:RAMB36_X14Y7 RAMB36_X13Y5:RAMB36_X13Y8}
#        add_cells_to_pblock pblock_aurora0 [get_cells -hier -filter {NAME =~ *aurora_device/ug_device_0/*}]
#        add_cells_to_pblock pblock_aurora0 [get_cells -hier -filter {NAME =~ *aurora_device/*auroraFlowcontrol_0*}]
#        endgroup       
#
#        startgroup
#        create_pblock pblock_aurora1
#        resize_pblock pblock_aurora1 -add {SLICE_X190Y200:SLICE_X221Y249 RAMB36_X14Y43:RAMB36_X14Y44 RAMB36_X13Y42:RAMB36_X13Y45}
#        add_cells_to_pblock pblock_aurora1 [get_cells -hier -filter {NAME =~ *aurora_device/ug_device_1/*}]
#        add_cells_to_pblock pblock_aurora1 [get_cells -hier -filter {NAME =~ *aurora_device/*auroraFlowcontrol_1*}]
#        endgroup   
#    }        
}

executePARConstraints auroraConstraints pcie_ep


proc auroraSynthConstraints {} {
    puts "Executing Aurora synthesis constraints"

    create_clock -period 8.000 [get_ports { device_topLevelWires_auroraWires_sma_clk_n_put }]

    # Create clock constraint for TXOUTCLK from GT
    create_clock -period 4 [get_pins -hier -filter { NAME=~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i/TXOUTCLK }]
    #create_clock -period 4 [get_pins -hier -filter { NAME=~ *aurora_device/ug_device_1/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i/TXOUTCLK }]

    # FMC SATA base clock is 156.25MHz
    create_clock -period 6.400 [get_ports { device_topLevelWires_auroraWires_hpc_clk_n_put }]

    # Create clock constraint for RXOUTCLK from GT
    create_clock -period 3.200 [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_0/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i/RXOUTCLK }]
    #create_clock -period 3.200 [get_pins -hier -filter { NAME =~ *aurora_device/ug_device_1/aurora_64b66b_v7_3_block_i/aurora_64b66b_v7_3_wrapper_i/aurora_64b66b_v7_3_multi_gt_i/AURORA_64B66B_V7_3_GTX_INST/gtxe2_i/RXOUTCLK }]
}

if {! $IS_TOP_BUILD} {
    if ([llength [get_ports { device_topLevelWires_auroraWires_sma_clk_n_put }]]) {
        auroraSynthConstraints
    }
}
