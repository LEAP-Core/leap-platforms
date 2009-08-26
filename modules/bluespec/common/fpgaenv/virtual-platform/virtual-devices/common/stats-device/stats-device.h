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

#include <bitset>

#include "platforms-module.h"
#include "asim/provides/rrr.h"

#include "asim/dict/STATS.h"

// this module handles gathering statistics. 
// Eventually this will interact with standard tools.

typedef class STATS_DEVICE_SERVER_CLASS* STATS_DEVICE_SERVER;
typedef class STATS_DEVICE_SERVER_CLASS* STATS_SERVER;

class STATS_DEVICE_SERVER_CLASS: public RRR_SERVER_CLASS,
                              public PLATFORMS_MODULE_CLASS
{
  private:
    // self-instantiation
    static STATS_DEVICE_SERVER_CLASS instance;

    // stubs
    RRR_SERVER_STUB serverStub;

    // Running total of statistics per context as they are dumped incrementally.
    UINT64 **statValues;

    // Check that each stat appears at most once per context.
    bitset<STATS_DICT_ENTRIES> *sawStat;

  public:
    STATS_DEVICE_SERVER_CLASS();
    ~STATS_DEVICE_SERVER_CLASS();

    void EmitFile();

    // static methods
    static STATS_DEVICE_SERVER GetInstance() { return &instance; }

    // required RRR methods
    void Init(PLATFORMS_MODULE);
    void Uninit();
    void Cleanup();
    void Poll();

    // RRR service methods
    void  Send(UINT32 statID, UINT32 value);
    UINT8 Done(UINT8 syn);
};

// server stub
#include "asim/rrr/server_stub_STATS.h"

// all functionalities of the stats controller are completely implemented
// by the STATS_DEVICE_SERVER class
typedef STATS_DEVICE_SERVER_CLASS STATS_DEVICE_CLASS;

void StatsEmitFile();
