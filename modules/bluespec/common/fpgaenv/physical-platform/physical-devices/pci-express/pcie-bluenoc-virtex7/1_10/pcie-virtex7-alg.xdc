##
## LEAP TIGs
##
##                            * * * * * * * * * *
## 

proc pcieControllerPARConstraints {} {
    global IS_TOP_BUILD

    set pathPrefix ""

    if {$IS_TOP_BUILD} {
        set pathPrefix "m_sys_sys_vp_m_mod/llpi_phys_plat_pcie_"
    }

    annotateSyncFIFO "${pathPrefix}toHostSyncQ"
    annotateSyncFIFO "${pathPrefix}fromHostSyncQ"
}

executePARConstraints pcieControllerPARConstraints PCIe
