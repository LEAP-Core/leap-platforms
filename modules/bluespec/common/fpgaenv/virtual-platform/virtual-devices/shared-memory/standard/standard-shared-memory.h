//
// Copyright (C) 2009 Intel Corporation
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

#ifndef __SHARED_MEMORY__
#define __SHARED_MEMORY__

#include "platforms-module.h"
#include "asim/provides/low_level_platform_interface.h"

#include "asim/rrr/client_stub_SHARED_MEMORY.h"

typedef UINT64 SHARED_MEMORY_DATA;

typedef class SHARED_MEMORY_CLASS* SHARED_MEMORY;
class SHARED_MEMORY_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:

    SHARED_MEMORY_CLIENT_STUB clientStub;    

    // link to remote memory device
    REMOTE_MEMORY remoteMemory;

  public:

    SHARED_MEMORY_CLASS(PLATFORMS_MODULE p, LLPI llpi);
    ~SHARED_MEMORY_CLASS();

    // standard infrastructure methods
    void Cleanup();

    // get pointer to shared region
    SHARED_MEMORY_DATA* Allocate();
    void DeAllocate(SHARED_MEMORY_DATA* mem);
};

#endif
