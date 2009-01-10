//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#ifndef __PHYSICAL_PLATFORM__
#define __PHYSICAL_PLATFORM__

#include "asim/provides/pci_express_device.h"

// ====================================================
// HiTech Global v5 PCI-Express Based Physical Platform
// ====================================================

// This class is a collection of all physical devices
// present on the HTG v5 Physical Platform
typedef class PHYSICAL_DEVICES_CLASS* PHYSICAL_DEVICES;
class PHYSICAL_DEVICES_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:

    // PCI Express Device
    PCIE_DEVICE_CLASS pciExpressDevice;

  public:

    // constructor-destructor
    PHYSICAL_DEVICES_CLASS(PLATFORMS_MODULE);
    ~PHYSICAL_DEVICES_CLASS();

    // accessors to individual devices
    PCIE_DEVICE GetPCIExpressDevice() { return &pciExpressDevice; }
};

#endif
