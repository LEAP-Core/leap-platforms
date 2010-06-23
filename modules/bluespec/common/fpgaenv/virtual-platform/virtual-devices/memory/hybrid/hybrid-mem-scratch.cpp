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

#ifdef PSEUDO_DMA_ENABLED

static bool PseudoDMA(
    int methodID,
    int length,
    const void *msg,
    PHYSICAL_CHANNEL_CLASS::PSEUDO_DMA_READ_RESP &resp);

#endif

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

    fmt_mask = fmt_addr;

    sprintf(fmt, "0%dx", sizeof(SCRATCHPAD_MEMORY_WORD) * 2);
    fmt_data = Format("0x", fmt);

#ifdef PSEUDO_DMA_ENABLED
    PHYSICAL_CHANNEL_CLASS::RegisterPseudoDMAHandler(0,
                                                     SCRATCHPAD_MEMORY_SERVICE_ID,
                                                     &PseudoDMA);
#endif
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


inline bool
SCRATCHPAD_MEMORY_SERVER_CLASS::IsTracing(int level)
{
    return TRACING(level);
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
// GetMemPtr --
//     Return a pointer to the memory holding address.
//
void *
SCRATCHPAD_MEMORY_SERVER_CLASS::GetMemPtr(
    SCRATCHPAD_MEMORY_ADDR addr)
{
    // Burst the incoming address into a region ID and a pointer to the line.
    UINT32 region = regionID(addr);
    SCRATCHPAD_MEMORY_WORD* mem = regionBase[region] + regionOffset(addr);
    
    ASSERTX(regionBase[region] != NULL);
    ASSERTX(regionOffset(addr) < regionWords[region]);

    return mem;
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
    
    ASSERTX(regionBase[region] != NULL);
    ASSERTX(regionOffset(addr) < regionWords[region]);

    if (TRACING(1))
    {
        T1("\tSCRATCHPAD load  region " << region << ": r_addr " << fmt_addr(regionOffset(addr)));

        for (UINT32 i = 0; i < SCRATCHPAD_WORDS_PER_LINE; i++)
        {
            T1("\t\tL " << i << ":\t" << fmt_data(*(line + i)));
        }
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

// Vector type definitions...
//
// Older versions of the compiler appear to want 
// this typedef to be a signed char
#if (__GNUC__ >= 4) && (__GNUC_MINOR__ >= 3)
    typedef char V8QI __attribute__ ((vector_size (8)));
#else
    typedef signed char V8QI __attribute__ ((vector_size (8)));
#endif

typedef int V2SI __attribute__ ((vector_size (8)));


void
SCRATCHPAD_MEMORY_SERVER_CLASS::StoreLine(
    UINT64 byteMask,
    SCRATCHPAD_MEMORY_ADDR addr,
    SCRATCHPAD_MEMORY_WORD data3,
    SCRATCHPAD_MEMORY_WORD data2,
    SCRATCHPAD_MEMORY_WORD data1,
    SCRATCHPAD_MEMORY_WORD data0)
{
    // Burst the incoming address into a region ID and a pointer to the line.
    UINT32 region = regionID(addr);
    SCRATCHPAD_MEMORY_WORD *store_line = regionBase[region] + regionOffset(addr);
    
    T1("\tSCRATCHPAD store line, region " << region
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

#if defined(__MMX__) && defined(__SSE__) && defined(ENABLE_SSE_FOR_SCRATCHPAD)

    //
    // Using SSE instructions seemed like a good idea, but they appear to be
    // slower than the non-SSE version below!  For now we keep the code
    // here but predicate it with ENABLE_SSE_FOR_SCRATCHPAD, which is not
    // defined.
    //

    #if (__GNUC__ >= 4) && (__GNUC_MINOR__ >= 4)
        #define SHIFT_BY_1 V2SI(1LLU)
    #else
        #define SHIFT_BY_1 1
    #endif

    V8QI mask = V8QI(byteMask);
    __builtin_ia32_maskmovq(V8QI(data0), mask, (char *)(store_line + 0));
    if (UINT64(mask) & 0x8080808080808080)
    {
        T1("\t\tS 0:\t" << fmt_data(*(store_line + 0)));
    }

    mask = V8QI(__builtin_ia32_pslld(V2SI(mask), SHIFT_BY_1));
    __builtin_ia32_maskmovq(V8QI(data1), mask, (char *)(store_line + 1));
    if (UINT64(mask) & 0x8080808080808080)
    {
        T1("\t\tS 1:\t" << fmt_data(*(store_line + 1)));
    }

    mask = V8QI(__builtin_ia32_pslld(V2SI(mask), SHIFT_BY_1));
    __builtin_ia32_maskmovq(V8QI(data2), mask, (char *)(store_line + 2));
    if (UINT64(mask) & 0x8080808080808080)
    {
        T1("\t\tS 2:\t" << fmt_data(*(store_line + 2)));
    }

    mask = V8QI(__builtin_ia32_pslld(V2SI(mask), SHIFT_BY_1));
    __builtin_ia32_maskmovq(V8QI(data3), mask, (char *)(store_line + 3));
    if (UINT64(mask) & 0x8080808080808080)
    {
        T1("\t\tS 3:\t" << fmt_data(*(store_line + 3)));
    }

#else

    UINT64 mask = FullByteMask(byteMask);
    *(store_line + 0) = (data0 & mask) | (*(store_line + 0) & ~mask);
    if (mask)
    {
        T1("\t\tS 0:\t" << fmt_data(*(store_line + 0)));
    }

    mask = FullByteMask(byteMask << 1);
    *(store_line + 1) = (data1 & mask) | (*(store_line + 1) & ~mask);
    if (mask)
    {
        T1("\t\tS 0:\t" << fmt_data(*(store_line + 1)));
    }

    mask = FullByteMask(byteMask << 2);
    *(store_line + 2) = (data2 & mask) | (*(store_line + 2) & ~mask);
    if (mask)
    {
        T1("\t\tS 0:\t" << fmt_data(*(store_line + 2)));
    }

    mask = FullByteMask(byteMask << 3);
    *(store_line + 3) = (data3 & mask) | (*(store_line + 3) & ~mask);
    if (mask)
    {
        T1("\t\tS 0:\t" << fmt_data(*(store_line + 3)));
    }

#endif
}


void
SCRATCHPAD_MEMORY_SERVER_CLASS::StoreWord(
    UINT64 byteMask,
    SCRATCHPAD_MEMORY_ADDR addr,
    SCRATCHPAD_MEMORY_WORD data)
{
    // Burst the incoming address into a region ID and a pointer to the line.
    UINT32 region = regionID(addr);
    SCRATCHPAD_MEMORY_WORD *store_word = regionBase[region] + regionOffset(addr);
    
    T1("\tSCRATCHPAD store word, region " << region
                                          << ": r_addr " << fmt_addr(regionOffset(addr))
                                          << ", mask " << fmt_mask(byteMask));

    ASSERTX(regionBase[region] != NULL);
    ASSERTX(regionOffset(addr) < regionWords[region]);

#if defined(__MMX__) && defined(__SSE__) && defined(ENABLE_SSE_FOR_SCRATCHPAD)

    V8QI mask = V8QI(byteMask);
    __builtin_ia32_maskmovq(V8QI(data), mask, (char *)(store_word));
    if (UINT64(mask) & 0x8080808080808080)
    {
        T1("\t\tS 0:\t" << fmt_data(*store_word));
    }

#else

    UINT64 mask = FullByteMask(byteMask);
    *store_word = (data & mask) | (*store_word & ~mask);
    if (mask)
    {
        T1("\t\tS 0:\t" << fmt_data(*store_word));
    }

#endif
}


void
SCRATCHPAD_MEMORY_SERVER_CLASS::StoreLineUnmasked(
    SCRATCHPAD_MEMORY_ADDR addr,
    const SCRATCHPAD_MEMORY_WORD *data)
{
    // Burst the incoming address into a region ID and a pointer to the line.
    UINT32 region = regionID(addr);
    SCRATCHPAD_MEMORY_WORD *store_line = regionBase[region] + regionOffset(addr);
    
    ASSERTX(regionBase[region] != NULL);
    ASSERTX(regionOffset(addr) < regionWords[region]);

    memcpy(store_line, data, sizeof(SCRATCHPAD_MEMORY_WORD) * 4);

    if (TRACING(1))
    {
        T1("\tSCRATCHPAD store line, region " << region
                                              << ": r_addr " << fmt_addr(regionOffset(addr)));

        for (UINT32 i = 0; i < SCRATCHPAD_WORDS_PER_LINE; i++)
        {
            T1("\t\tS 0:\t" << fmt_data(*(store_line + i)));
        }
    }
}


//
// Convert a bit mask appropriate for maskmovq (high bit of each byte)
// to a full mask for each byte.
//
inline UINT64
SCRATCHPAD_MEMORY_SERVER_CLASS::FullByteMask(
    UINT64 in_mask)
{
    UINT64 pos_mask = in_mask & 0x8080808080808080;
    UINT64 mask = pos_mask | (pos_mask >> 7) ^ 0x0101010101010101;
    mask -= 0x0101010101010101;
    mask |= pos_mask;
    return mask;
}




// ========================================================================
//
// Some low level channel I/O drivers that do not support real DMA allow
// the scratchpad code to register a pseudo-DMA path.  (E.g. The Nallatech
// ACP driver.)  This path is significantly faster as it bypasses the
// channel I/O and RRR stacks.
//
// ========================================================================

#ifdef PSEUDO_DMA_ENABLED

static bool
PseudoDMA(
    int methodID,
    int length,
    const void *msg,
    PHYSICAL_CHANNEL_CLASS::PSEUDO_DMA_READ_RESP &resp)
{
    const UINT64 *u64msg = (const UINT64*) msg;
    const SCRATCHPAD_MEMORY_SERVER instance = &SCRATCHPAD_MEMORY_SERVER_CLASS::instance;

    resp = NULL;

    switch (methodID)
    {
      case SCRATCHPAD_MEMORY_METHOD_ID_StoreWord:
      {
        instance->StoreWord(u64msg[2], u64msg[1], u64msg[0]);
        return true;
      }
      case SCRATCHPAD_MEMORY_METHOD_ID_StoreLine:
      {
        UINT64 byteMask = u64msg[5];

        if ((byteMask & 0xf0f0f0f0f0f0f0f0) == 0xf0f0f0f0f0f0f0f0)
        {
            // All bytes written.  Use fast path.
            instance->StoreLineUnmasked(u64msg[4], u64msg);
        }
        else
        {
            // Partial (masked) write.  Slow path.
            instance->StoreLine(byteMask, u64msg[4], u64msg[3],
                                u64msg[2], u64msg[1], u64msg[0]);
        }

        return true;
      }
      case SCRATCHPAD_MEMORY_METHOD_ID_LoadLine:
      {
        static PHYSICAL_CHANNEL_CLASS::PSEUDO_DMA_READ_RESP_CLASS r;
        static bool did_init = false;
        static UMF_MESSAGE_CLASS m;

        // Initialize the constant portions of the response on the first pass
        if (! did_init)
        {
            did_init = true;

            m.Clear();
            m.SetLength(32);
            m.SetServiceID(SCRATCHPAD_MEMORY_SERVICE_ID);
            m.SetMethodID(SCRATCHPAD_MEMORY_METHOD_ID_LoadLine);

            // UMF header components
            r.header = m.EncodeHeader();
            r.msgBytes = 32;
        }

        // Pointer to the requested memory
        r.msg = instance->GetMemPtr(u64msg[0]);

        resp = &r;

        // Only handle reads here when tracing is off.  When tracing is on
        // the RRR method will be called.
        return ! instance->IsTracing(1);
        }
    }

    // Request not handled by pseudoDMA
    return false;
}

#endif
