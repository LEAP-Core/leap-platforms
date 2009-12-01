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

#ifndef __SHARED_MEMORY_SERVER__
#define __SHARED_MEMORY_SERVER__

#include <map>

#include "asim/provides/rrr.h"

// Page Table entry

typedef map <UINT64, UINT64> PAGE_TABLE;

// Shared Memory software server

typedef class SHARED_MEMORY_SERVER_CLASS* SHARED_MEMORY_SERVER;
class SHARED_MEMORY_SERVER_CLASS: public RRR_SERVER_CLASS,
                                  public PLATFORMS_MODULE_CLASS
{
  private:

    // self-instantiation
    static SHARED_MEMORY_SERVER_CLASS instance;
    
    // stubs
    RRR_SERVER_STUB serverStub;

    // page table
    // PAGE_TABLE pageTable;
    UINT64 theOnlyPhysicalAddress;

  public:

    SHARED_MEMORY_SERVER_CLASS();
    ~SHARED_MEMORY_SERVER_CLASS();
    
    static SHARED_MEMORY_SERVER GetInstance() { return &instance; }

    // methods exposed to software client

    void UpdateTranslation(UINT64 va, UINT64 pa);
    void InvalidateTranslation(UINT64 va);

    // standard infrastructure methods

    void Init(PLATFORMS_MODULE);
    void Uninit();
    void Cleanup();

    // RRR methods

    UINT64 GetTranslation(UINT8 dummy);
};

#include "asim/rrr/server_stub_SHARED_MEMORY.h"

#endif
