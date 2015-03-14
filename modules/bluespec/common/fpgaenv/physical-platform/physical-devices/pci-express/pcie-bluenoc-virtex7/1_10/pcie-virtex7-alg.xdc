##
## LEAP TIGs
##
##                            * * * * * * * * * *
## 

proc pcieControllerPARConstraints {} {
    global IS_TOP_BUILD

    # We used to annotate SyncFIFOs here.  Now that is automatic.  The
    # stub remains in case it becomes useful.
}

executePARConstraints pcieControllerPARConstraints PCIe
