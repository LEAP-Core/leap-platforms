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

#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <sys/mman.h>

#include "asim/rrr/service_ids.h"
#include "asim/provides/command_switches.h"
#include "asim/ioformat.h"

#include "asim/provides/shared_memory.h"

using namespace std;

#define PAGE_OFFSET_BITS 12

// constructor
SHARED_MEMORY_CLASS::SHARED_MEMORY_CLASS(
    PLATFORMS_MODULE p,
    LLPI             llpi) :
        PLATFORMS_MODULE_CLASS(p)
{
    // instantiate stubs
    clientStub = new SHARED_MEMORY_CLIENT_STUB_CLASS(this);

    // store useful links from LLPI
    remoteMemory = llpi->GetRemoteMemory();
}

// destructor
SHARED_MEMORY_CLASS::~SHARED_MEMORY_CLASS()
{
    Cleanup();
}

// cleanup
void
SHARED_MEMORY_CLASS::Cleanup()
{
    delete clientStub;
}

// allocate a new shared memory region
SHARED_MEMORY_DATA*
SHARED_MEMORY_CLASS::Allocate()
{
    // allocate a page-sized, page-aligned region
    SHARED_MEMORY_DATA* mem;

    // find out system's page size
    UINT32 page_size = getpagesize();

    // sanity check for page size
    if (page_size != (UINT32(0x01) << PAGE_OFFSET_BITS))
    {
        ASIMERROR("page size mismatch");
        CallbackExit(1);
    }
 
    if (posix_memalign((void **)&mem, page_size, page_size) != 0)
    {
        perror("posix_memalign");
        CallbackExit(1);
    }

    // zero it out
    bzero((void *)mem, page_size);    

    // lock it down and get its physical address
    UINT64 pa = remoteMemory->TranslateAndLock((unsigned char *)mem, page_size);

    // update translation table that lives in software-side server
    SHARED_MEMORY_SERVER_CLASS::GetInstance()->UpdateTranslation(UINT64(mem), pa);

    // update translation in hardware
    UINT8 ack = clientStub->UpdateTranslation(pa);

    // TODO: we probably need more book-keeping

    return mem;
}

// de-allocate a previously-allocated region
void
SHARED_MEMORY_CLASS::DeAllocate(
    SHARED_MEMORY_DATA* mem)
{
    // TODO: book-keeping

/*    
    // ask server if this page is mapped

    // ask remote memory to unlock pages
    vector <REMOTE_MEMORY_PHYSICAL_ADDRESS> pa_vec;
    pa_vec[0] = REMOTE_MEMORY_PHYSICAL_ADDRESS(pa);
    remoteMemory->Unlock(&pa_vec);
*/

    // invalidate translation table (that lives in software-side server)
    SHARED_MEMORY_SERVER_CLASS::GetInstance()->InvalidateTranslation(UINT64(mem));

    // TODO: add RRR call to hardware to invalidate translation

    // free
    free(mem);
}
