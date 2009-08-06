/*****************************************************************************
 * Copyright (C) 2008 Intel Corporation
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#ifndef __REMOTE_MEMORY__
#define __REMOTE_MEMORY__

#include "asim/provides/pci_express_device.h"
#include "asim/provides/physical_platform.h"

#include <vector>

using namespace std;

typedef PCIE_PHYSICAL_ADDRESS REMOTE_MEMORY_PHYSICAL_ADDRESS;

// ============================================
//               Remote Memory              
// ============================================

// Provides methods to setup a user page for FPGA access,
// and to obtain the physical address of a user page.

typedef class REMOTE_MEMORY_CLASS* REMOTE_MEMORY;
class REMOTE_MEMORY_CLASS: public PLATFORMS_MODULE_CLASS
{

  private:

    // links to useful remote devices
    PCIE_DEVICE pciExpressDevice;
    
    void Cleanup();
    
  public:

    REMOTE_MEMORY_CLASS(PLATFORMS_MODULE, PHYSICAL_DEVICES);
    ~REMOTE_MEMORY_CLASS();

    void Uninit();
    
    UINT64 TranslateAndLock(unsigned char* region, int size);
    void Unlock(UINT64 pa);
};

#endif
