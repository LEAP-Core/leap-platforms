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

//
// Scratchpad memory.
//
// This service manages multiple, independent, scratchpad memory regions.
// All storage is accessed as fixed-size chunks.  The clients are responsible
// for mapping the fixed-size chunks to their own data structures.
//

#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>

#include "asim/provides/model.h"
#include "asim/provides/scratchpad_memory.h"
#include "asim/rrr/service_ids.h"


// service instantiation
SCRATCHPAD_MEMORY_SERVER_CLASS SCRATCHPAD_MEMORY_SERVER_CLASS::instance;

// constructor
SCRATCHPAD_MEMORY_SERVER_CLASS::SCRATCHPAD_MEMORY_SERVER_CLASS()
{
    SetTraceableName("scratchpad_memory");

    // instantiate stubs
    serverStub = new SCRATCHPAD_MEMORY_SERVER_STUB_CLASS(this);

    for (UINT32 r = 0; r < nRegions(); r++)
    {
        regionBase[r] = NULL;
        regionWords[r] = 0;
        regionSize[r] = 0;
    }

    char fmt[16];

    sprintf(fmt, "0%dx", sizeof(SCRATCHPAD_MEMORY_ADDR) * 2);
    fmt_addr = Format("0x", fmt);

    sprintf(fmt, "0%dx", sizeof(UINT32) * 2);
    fmt_mask = Format("0x", fmt);

    sprintf(fmt, "0%dx", sizeof(SCRATCHPAD_MEMORY_WORD) * 2);
    fmt_data = Format("0x", fmt);
}

// destructor
SCRATCHPAD_MEMORY_SERVER_CLASS::~SCRATCHPAD_MEMORY_SERVER_CLASS()
{
    //
    // Unmap all the scratchpad regions.
    //
    for (UINT32 r = 0; r < nRegions(); r++)
    {
        if (regionBase[r] != NULL)
        {
            munmap(regionBase[r], regionSize[r]);
        }
    }

    Cleanup();
}


void
SCRATCHPAD_MEMORY_SERVER_CLASS::Init(PLATFORMS_MODULE p)
{
    // chain
    PLATFORMS_MODULE_CLASS::Init(p);
}

// uninit: override
void
SCRATCHPAD_MEMORY_SERVER_CLASS::Uninit()
{
    // cleanup
    Cleanup();
    
    // chain
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
SCRATCHPAD_MEMORY_SERVER_CLASS::Cleanup()
{
}


//
// RRR requests
//

//
// InitRegion --
//
void SCRATCHPAD_MEMORY_SERVER_CLASS::InitRegion(
    UINT32 regionID,
    UINT32 regionEndIdx)
{
    UINT64 nWords = UINT64(regionEndIdx) + 1;

    T1("\tSCRATCHPAD init region " << regionID << ": " << nWords << " words");
    ASSERT(regionBase[regionID] == NULL, "Scratchpad region " << regionID << " already initialized");

    regionWords[regionID] = nWords;
    // Size must be multiple of a page for mmap.
    regionSize[regionID] = (nWords * sizeof(SCRATCHPAD_MEMORY_WORD) + getpagesize() - 1) &
                           ~(getpagesize() - 1);
    
    regionBase[regionID] = (SCRATCHPAD_MEMORY_WORD*) mmap(NULL,
                                                          regionSize[regionID],
                                                          PROT_WRITE | PROT_READ,
                                                          MAP_ANONYMOUS | MAP_PRIVATE,
                                                          -1, 0);
    ASSERT(regionBase[regionID] != MAP_FAILED, "Scratchpad mmap failed: region " << regionID << " nWords " << nWords << " (errno " << errno << ")");
}

//
// Load --
//
OUT_TYPE_LoadLine
SCRATCHPAD_MEMORY_SERVER_CLASS::LoadLine(
    SCRATCHPAD_MEMORY_ADDR addr)
{
    // Burst the incoming address into a region ID and a pointer to the line.
    UINT32 region = regionID(addr);
    SCRATCHPAD_MEMORY_WORD* line = regionBase[region] + regionOffset(addr);
    
    T1("\tSCRATCHPAD load  region " << region << ": r_addr " << fmt_addr(regionOffset(addr)));

    ASSERTX(regionBase[region] != NULL);
    ASSERTX(regionOffset(addr) < regionWords[region]);

    for (UINT32 i = 0; i < SCRATCHPAD_WORDS_PER_LINE; i++)
    {
        T1("\t\tL " << i << ":\t" << fmt_data(*(line + i)));
    }

    OUT_TYPE_LoadLine v;
    v.data0 = *(line + 0);
    v.data1 = *(line + 1);
    v.data2 = *(line + 2);
    v.data3 = *(line + 3);
    return v;
}

//
// Store --
//
void
SCRATCHPAD_MEMORY_SERVER_CLASS::StoreLine(
    UINT64 byteMask,
    SCRATCHPAD_MEMORY_ADDR addr,
    SCRATCHPAD_MEMORY_WORD data0,
    SCRATCHPAD_MEMORY_WORD data1,
    SCRATCHPAD_MEMORY_WORD data2,
    SCRATCHPAD_MEMORY_WORD data3)
{
    typedef signed char V8QI __attribute__ ((vector_size (8)));
    typedef int V2SI __attribute__ ((vector_size (8)));

    // Burst the incoming address into a region ID and a pointer to the line.
    UINT32 region = regionID(addr);
    SCRATCHPAD_MEMORY_WORD *store_line = regionBase[region] + regionOffset(addr);
    
    T1("\tSCRATCHPAD store region " << region
                                    << ": r_addr " << fmt_addr(regionOffset(addr))
                                    << ", mask " << fmt_mask(byteMask));

    ASSERTX(regionBase[region] != NULL);
    ASSERTX(regionOffset(addr) < regionWords[region]);

    //
    // The mask has been arranged so it works well with the maskmovq instruction.
    // Masks for data0 are in the high bits of each byte.  Masks for data1
    // are 1 bit lower, so the mask is shifted left 1 bit for each word using
    // pslld.
    //

    V8QI mask = V8QI(byteMask);
    __builtin_ia32_maskmovq(V8QI(data0), mask, (char *)(store_line + 0));
    if (UINT64(mask) & 0x8080808080808080)
    {
        T1("\t\tS 0:\t" << fmt_data(*(store_line + 0)));
    }

    mask = V8QI(__builtin_ia32_pslld(V2SI(mask), 1));
    __builtin_ia32_maskmovq(V8QI(data1), mask, (char *)(store_line + 1));
    if (UINT64(mask) & 0x8080808080808080)
    {
        T1("\t\tS 1:\t" << fmt_data(*(store_line + 1)));
    }

    mask = V8QI(__builtin_ia32_pslld(V2SI(mask), 1));
    __builtin_ia32_maskmovq(V8QI(data2), mask, (char *)(store_line + 2));
    if (UINT64(mask) & 0x8080808080808080)
    {
        T1("\t\tS 2:\t" << fmt_data(*(store_line + 2)));
    }

    mask = V8QI(__builtin_ia32_pslld(V2SI(mask), 1));
    __builtin_ia32_maskmovq(V8QI(data3), mask, (char *)(store_line + 3));
    if (UINT64(mask) & 0x8080808080808080)
    {
        T1("\t\tS 3:\t" << fmt_data(*(store_line + 3)));
    }
}
