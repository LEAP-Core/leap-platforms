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

#include <list>

#include "platforms-module.h"
#include "asim/provides/rrr.h"

#include "asim/rrr/client_stub_STATS.h"

#include "asim/dict/STATS.h"

// A class which represents a stat. Stats can actually be vectors.
// We represent these vectors as linked lists since the HW may
// not be using all of the vector for a particular run.
// Each spot in the list is marked as unseen to begin with.

typedef class STAT_VECTOR_CLASS* STAT_VECTOR;

class STAT_VECTOR_CLASS
{

  private:
    // Identifying information for error messages.
    UINT32  myID;
    UINT32  length;
    // The actual value.
    UINT64* curValues;

    // Have we seen ID?  Used to check for duplicates.
    bool*   positionInitialized;

  public:
    STAT_VECTOR_CLASS(UINT32 id, UINT32 l);
    ~STAT_VECTOR_CLASS();

    void InitPosition(UINT32 pos);
    void AddStatValue(UINT32 val, UINT32 pos);

    UINT64 GetStatValue(UINT32 pos);
    UINT32 GetLength() const { return length; };
};

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
    STATS_CLIENT_STUB clientStub;

    // Have we initialized the stats yet?
    bool statsInited;

    // Running total of statistic vectors as they are dumped incrementally.
    STAT_VECTOR statValues[STATS_DICT_ENTRIES];
    UINT32 statArrayLength[STATS_DICT_ENTRIES];

  public:
    STATS_DEVICE_SERVER_CLASS();
    ~STATS_DEVICE_SERVER_CLASS();

    // Methods other people call to control stats.
    void SetupStats();
    void ToggleEnabled();
    void ResetStatValues();
    void DumpStats();
    void EmitFile();

    // static methods
    static STATS_DEVICE_SERVER GetInstance() { return &instance; }

    // required RRR methods
    void Init(PLATFORMS_MODULE);
    void Uninit();
    void Cleanup();

    // RRR server methods
    void ReportStat(UINT32 statID, UINT32 pos, UINT32 value);
    void SetVectorLength(UINT32 statID, UINT32 length, UINT8 buildArray);
};

// server stub
#include "asim/rrr/server_stub_STATS.h"

// all functionalities of the stats controller are completely implemented
// by the STATS_DEVICE_SERVER class
typedef STATS_DEVICE_SERVER_CLASS STATS_DEVICE_CLASS;

void StatsEmitFile();


// ========================================================================
//
//   HACK!  Clients may "register" as stats emitters by allocating an
//   instance of the following class.  They may then write whatever
//   they wish to the stats file.  Clearly this should be improved with
//   some structure, perhaps by switching to statistics code from
//   Asim.
//
// ========================================================================

typedef class STATS_EMITTER_CLASS *STATS_EMITTER;

class STATS_EMITTER_CLASS
{
  public:
    STATS_EMITTER_CLASS();
    ~STATS_EMITTER_CLASS();

    virtual void EmitStats(ofstream &statsFile) = 0;
};
