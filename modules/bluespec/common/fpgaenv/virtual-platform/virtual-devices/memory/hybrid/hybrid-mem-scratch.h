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

#ifndef __HYBRID_SCRATCHPAD_MEMORY__
#define __HYBRID_SCRATCHPAD_MEMORY__

#include "asim/syntax.h"
#include "asim/mesg.h"
#include "asim/trace.h"

#include "asim/provides/physical_channel.h"
#include "asim/provides/rrr.h"
#include "asim/dict/VDEV.h"

#include "asim/rrr/client_stub_SCRATCHPAD_MEMORY.h"

// Get the data types from the scratchpad RRR definition
#define TYPES_ONLY
#include "asim/rrr/server_stub_SCRATCHPAD_MEMORY.h"
#undef TYPES_ONLY

// This hack deals with the case that no scratchpad regions are defined...
#ifndef __VDEV_SCRATCH_DICT_H__
#define VDEV_SCRATCH__NENTRIES 0
#endif

#define SCRATCHPAD_WORDS_PER_LINE 4

typedef UINT64 SCRATCHPAD_MEMORY_ADDR;
typedef UINT64 SCRATCHPAD_MEMORY_WORD;

typedef class SCRATCHPAD_MEMORY_SERVER_CLASS* SCRATCHPAD_MEMORY_SERVER;

class SCRATCHPAD_MEMORY_SERVER_CLASS: public RRR_SERVER_CLASS,
                                      public PLATFORMS_MODULE_CLASS,
                                      public TRACEABLE_CLASS
{
  public:

    // self-instantiation
    static SCRATCHPAD_MEMORY_SERVER_CLASS instance;

  private:

    // stubs
    RRR_SERVER_STUB serverStub;

    // internal data
    SCRATCHPAD_MEMORY_WORD *regionBase[VDEV_SCRATCH__NENTRIES + 1];
    SCRATCHPAD_MEMORY_ADDR regionWords[VDEV_SCRATCH__NENTRIES + 1];
    size_t regionSize[VDEV_SCRATCH__NENTRIES + 1];

    Format fmt_addr;
    Format fmt_mask;
    Format fmt_data;

    // internal methods
    UINT32 nRegions() const { return VDEV_SCRATCH__NENTRIES; };

    // Compute region ID given an incoming address
    UINT32 regionID(UINT64 addr) const { return addr >> SCRATCHPAD_MEMORY_ADDR_BITS; };

    // Compute region word offset given an incoming address
    SCRATCHPAD_MEMORY_ADDR regionOffset(UINT64 addr)
    {
        // Get just the region address bits (drop the region ID)
        return addr & ((SCRATCHPAD_MEMORY_ADDR(1) << SCRATCHPAD_MEMORY_ADDR_BITS) - 1);
    };

    UINT64 FullByteMask(UINT64 mask);

  public:

    SCRATCHPAD_MEMORY_SERVER_CLASS();
    ~SCRATCHPAD_MEMORY_SERVER_CLASS();

    // generic RRR methods
    void   Init(PLATFORMS_MODULE);
    void   Uninit();
    void   Cleanup();

    bool   IsTracing(int level);

    // RRR request methods
    void InitRegion(UINT32 regionID, UINT32 regionEndIdx);

    void *GetMemPtr(SCRATCHPAD_MEMORY_ADDR addr);

    OUT_TYPE_LoadLine LoadLine(SCRATCHPAD_MEMORY_ADDR addr);

    void StoreLine(UINT64 byteMask,
                   SCRATCHPAD_MEMORY_ADDR addr,
                   SCRATCHPAD_MEMORY_WORD data3,
                   SCRATCHPAD_MEMORY_WORD data2,
                   SCRATCHPAD_MEMORY_WORD data1,
                   SCRATCHPAD_MEMORY_WORD data0);

    void StoreWord(UINT64 byteMask,
                   SCRATCHPAD_MEMORY_ADDR addr,
                   SCRATCHPAD_MEMORY_WORD data);

    void StoreLineUnmasked(SCRATCHPAD_MEMORY_ADDR addr,
                           const SCRATCHPAD_MEMORY_WORD *data);
};

// Now that the server class is defined the RRR wrapper can be loaded.
#include "asim/rrr/server_stub_SCRATCHPAD_MEMORY.h"

#endif
