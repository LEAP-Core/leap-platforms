
set_property BITSTREAM.GENERAL.COMPRESS FALSE [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]

set_false_path -through [get_nets clocksWires_rst_put]
set_property PACKAGE_PIN AV40 [get_ports clocksWires_rst_put]
set_property IOSTANDARD LVCMOS18 [get_ports clocksWires_rst_put]
set_property PULLUP true [get_ports clocksWires_rst_put]

set_property LOC E19  [get_ports { clocksWires_clk_p_put }]
set_property LOC E18  [get_ports { clocksWires_clk_n_put }]
set_property IOSTANDARD DIFF_SSTL15 [get_ports { clocksWires_clk_p_put clocksWires_clk_n_put }]


create_clock -name clocksWires_clk_p_put -period 5.000 [get_ports clocksWires_clk_p_put]


#What is this doing?
#set_clock_groups -name async_sysclk_coreclk -asynchronous -group [get_clocks -include_generated_clocks sys_clk] -group [get_clocks -include_generated_clocks pci_refclk]

#proc annotateSyncFIFO {sync_object} {
#   set sync_cell [get_cells -hier -filter "NAME =~ $sync_object"]
#   if {[get_property ORIG_REF_NAME $sync_cell] == "SyncFIFO"} {
#       set path               [get_property NAME $sync_cell]      
#       set clocks             [get_clocks -of_objects $sync_cell]
#
#       set dst_clock          [get_clocks -of_objects [get_cells -hier -filter "NAME =~ $sync_cell/dDoutReg*"]]
#
#       set src_clock          [get_clocks -of_objects [get_cells -hier -filter "NAME =~ $sync_cell/sGEnqPtr*"]]
 
#       lappend src_cells      [get_cells -hier -filter "NAME =~ $sync_cell/*fifoMem*"]       
#       lappend src_cells      [get_cells -hier -filter "NAME =~ $sync_cell/sSyncReg1*"]       
#       lappend src_cells      [get_cells -hier -filter "NAME =~ $sync_cell/sNotFullReg*"]       

#       set dst_cells          [get_cells -hier -filter "NAME =~ $sync_cell/dDoutReg*"]       
#       lappend dst_cells      [get_cells -hier -filter "NAME =~ $sync_cell/dGDeqPtr*"]       
#       lappend dst_cells      [get_cells -hier -filter "NAME =~ $sync_cell/dSyncReg1*"] 

#       set_max_delay -from $src_cells -to $dst_cells -datapath_only [get_property -min PERIOD $src_clock]
#       set_max_delay -from $dst_cells -to $src_cells -datapath_only [get_property -min PERIOD $dst_clock]

#   }
#}

#annotateSyncFIFO "m_sys_sys_vp_m_mod/llpi_phys_plat_sdram_b_ddrSynth/syncRequestQ"



