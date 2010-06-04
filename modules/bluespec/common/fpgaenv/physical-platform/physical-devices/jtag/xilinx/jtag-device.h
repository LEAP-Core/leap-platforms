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

#ifndef __JTAG__
#define __JTAG__

#include "platforms-module.h"
#include "asim/provides/umf.h"


// ============================================
//       JTAG Physical Device
// ============================================
typedef class JTAG_DEVICE_CLASS* JTAG_DEVICE;
class JTAG_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:

  public:
    JTAG_DEVICE_CLASS(PLATFORMS_MODULE);
    ~JTAG_DEVICE_CLASS();

    void Cleanup();                    // cleanup
    void Uninit();                     // uninit
    bool Probe();                      // probe for data
    void Read(unsigned char*, int);    // blocking read
    void Write(unsigned char*, int);   // write
};

#endif
