#ifndef __PHYSICAL_PLATFORM__
#define __PHYSICAL_PLATFORM__

#include "asim/provides/pci_express_device.h"
#include "main.h"

// ====================================================
// HiTech Global v5 PCI-Express Based Physical Platform
// ====================================================

// This class is a collection of all physical devices
// present on the HTG v5 Physical Platform
typedef class PHYSICAL_DEVICES_CLASS* PHYSICAL_DEVICES;
class PHYSICAL_DEVICES_CLASS: public HASIM_MODULE_CLASS
{
    private:
        PCIE_DEVICE_CLASS pciExpressDevice;

    public:
        // constructor-destructor
        PHYSICAL_DEVICES_CLASS::PHYSICAL_DEVICES_CLASS(HASIM_MODULE);
        PHYSICAL_DEVICES_CLASS::~PHYSICAL_DEVICES_CLASS();

        // accessors to individual devices
        PCIE_DEVICE GetPCIExpressDevice() { return &pciExpressDevice; }
};

#endif
