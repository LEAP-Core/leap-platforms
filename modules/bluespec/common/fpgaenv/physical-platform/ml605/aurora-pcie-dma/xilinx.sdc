# Synopsys, Inc. constraint file
# /users/mylopare/hasim/hasim-vip/build/default/test_rrr_605d_syn/pm/hw/model/pci-express-dma.sdc
# Written on Tue Jun 28 14:44:22 2011
# by Synplify Pro, E-2011.03 Scope Editor

#
# Collections
#
define_scope_collection  syncfifo_mem {find -hier -inst {*.fifoMem*}}

#
# Clocks
#
define_clock   {p:CLK} -name {USER_CLK}  -period 15.151 -clockgroup default_clkgroup_0
define_clock   {n:m_vp_llpi_phys_plat_pcie_device_v_pcie_dma_dev.pcie_clk} -name {PCIE_CLK}  -period 4 -clockgroup default_clkgroup_1

#
# Clock to Clock
#

#
# Inputs/Outputs
#

#
# Registers
#

#
# Delay Paths
#

#
# Attributes
#
define_attribute {$syncfifo_mem} {syn_ramstyle} {select_ram}

#
# I/O Standards
#

#
# Compile Points
#

#
# Other
#
# Synopsys, Inc. constraint file
# /users/mylopare/hasim/hasim-vip/build/default/test_rrr_605d_syn/pm/hw/model/pci-express-dma.sdc
# Written on Tue Jun 28 14:44:22 2011
# by Synplify Pro, E-2011.03 Scope Editor

#
# Collections
#
define_scope_collection  syncfifo_mem {find -hier -inst {*.fifoMem*}}

#
# Clocks
#
define_clock   {p:CLK} -name {USER_CLK}  -period 15.151 -clockgroup default_clkgroup_0
define_clock   {n:m_vp_llpi_phys_plat_pcie_device_v_pcie_dma_dev.pcie_clk} -name {PCIE_CLK}  -period 4 -clockgroup default_clkgroup_1

#
# Clock to Clock
#

#
# Inputs/Outputs
#

#
# Registers
#

#
# Delay Paths
#

#
# Attributes
#
define_attribute {$syncfifo_mem} {syn_ramstyle} {select_ram}

#
# I/O Standards
#

#
# Compile Points
#

#
# Other
#
