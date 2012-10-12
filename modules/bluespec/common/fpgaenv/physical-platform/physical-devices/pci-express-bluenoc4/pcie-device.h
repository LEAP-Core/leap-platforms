//
// Copyright (C) 2010 MIT
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

#ifndef __PCIE__
#define __PCIE__

#include <stdio.h>

#include "platforms-module.h"
#include "asim/provides/umf.h"
#include <pthread.h>

// ============================================
//       JTAG Physical Device
// ============================================
typedef class PCIE_DEVICE_CLASS* PCIE_DEVICE;
class PCIE_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
    int intialized;

  public:
    PCIE_DEVICE_CLASS(PLATFORMS_MODULE);
    ~PCIE_DEVICE_CLASS();

    void Cleanup();                    // cleanup
    void Init();                      // uninit
    void Uninit();                     // uninit
    bool Probe();                      // probe for data
    int  Read(int*, int);    // nonblocking read
    int  Write(const char*, int);   // write
};

#endif
