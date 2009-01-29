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

#ifndef __PHYSICAL_PLATFORM_DEBUGGER__
#define __PHYSICAL_PLATFORM_DEBUGGER__

#include "asim/provides/umf.h"
#include "asim/provides/pci_express_device.h"
#include "asim/provides/physical_platform.h"

// ============================================
//       HTG v5 PCIe Platform Debugger              
// ============================================

class PHYSICAL_PLATFORM_DEBUGGER_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:

    // links to useful physical devices
    PCIE_DEVICE pciExpressDevice;
    
    // instruction ID
    CSR_DATA iid;
    
    // internal methods
    void PrintHelp_Help();
    void PrintHelp_CSR();
    void PrintHelp_Inst();
    void PrintHelp_Commands();
    void PrintStatus_Flags(unsigned int);
    void PrintStatus_Pointers(unsigned int);
    void PrintStatus_VHDL(unsigned int);
    unsigned int StoI(const char *);
    CSR_DATA GenIID();

  public:

    PHYSICAL_PLATFORM_DEBUGGER_CLASS(PLATFORMS_MODULE, PHYSICAL_DEVICES);
    ~PHYSICAL_PLATFORM_DEBUGGER_CLASS();

    void Monitor();
};

#endif
