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

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/select.h>
#include <sys/types.h>
#include <signal.h>
#include <strings.h>
#include <string>
#include <iostream>
#include <cmath>

#include "asim/rrr/service_ids.h"
#include "asim/provides/command_switches.h"

#include "asim/provides/stats_device.h"

using namespace std;


// ===== service instantiation =====
STATS_DEVICE_SERVER_CLASS STATS_DEVICE_SERVER_CLASS::instance;

// ===== methods =====

// constructor
STATS_DEVICE_SERVER_CLASS::STATS_DEVICE_SERVER_CLASS() :
    // instantiate stubs
    statValues(NULL),
    clientStub(new STATS_CLIENT_STUB_CLASS(this)),
    serverStub(new STATS_SERVER_STUB_CLASS(this))
{
}


// destructor
STATS_DEVICE_SERVER_CLASS::~STATS_DEVICE_SERVER_CLASS()
{
    Cleanup();
}


// init
void
STATS_DEVICE_SERVER_CLASS::Init(
    PLATFORMS_MODULE     p)
{
    // set parent pointer
    parent = p;
    // Instantiate stats for each context.
    statValues = new UINT64* [globalArgs->NumContexts()];
    // statValues = (UINT64**) malloc(sizeof(UINT64*) * globalArgs->NumContexts());
    sawStat = new bitset<STATS_DICT_ENTRIES>[globalArgs->NumContexts()];
    for (int x = 0; x < globalArgs->NumContexts(); x++)
    {
        statValues[x] = new UINT64[STATS_DICT_ENTRIES];
        bzero(statValues[x], STATS_DICT_ENTRIES * sizeof(UINT64));
    }
}


// uninit: we have to write this explicitly
void
STATS_DEVICE_SERVER_CLASS::Uninit()
{
    Cleanup();

    // chain
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
STATS_DEVICE_SERVER_CLASS::Cleanup()
{
    // kill stubs
    delete serverStub;
    
    // Free stats
    delete sawStat;

    if (statValues != NULL && globalArgs != NULL)
    {
        for (int x = 0; x < globalArgs->NumContexts(); x++)
        {
            delete statValues[x];
        }
    }

    delete [] statValues;
}

//
// RRR request methods
//

// Send
void
STATS_DEVICE_SERVER_CLASS::Send(
    UINT32 statID,
    UINT32 value)
{
    // If the counter is greater than the number of active contexts, then the
    // hardware is sending us the value of a stat from an inactive context.
    // So we'll just drop it.

    //
    // Add new value to running total
    //
    
    VERIFY(statID < STATS_DICT_ENTRIES, "stats device:  Invalid stat id");
    int currentContext = -1;
    for (int x = 0; x < globalArgs->NumContexts(); x++)
    {
        if (!sawStat[x].test(statID) && currentContext == -1)
        {
            currentContext = x;
        }
    }
    if (currentContext != -1)
    {

        WARN(! sawStat[currentContext].test(statID), "stats device: stat " << STATS_DICT::Name(statID) << " appears more than once in Context " << currentContext);
        sawStat[currentContext].set(statID);

        statValues[currentContext][statID] += value;
    }
    // Otherwise it's a stat from an inactive context, so drop it.
}

// Done
UINT8
STATS_DEVICE_SERVER_CLASS::Done(
    UINT8 syn)
{

    for (int x = 0; x < globalArgs->NumContexts(); x++)
    {
        sawStat[x].reset();
    }
    // send ack
    return 0;
}


// poll
void
STATS_DEVICE_SERVER_CLASS::Poll()
{
}

// DumpStats
void
STATS_DEVICE_SERVER_CLASS::DumpStats()
{
    UINT8 ack = clientStub->DumpStats(0);
}


//
// EmitStatsFile --
//    Dump the in-memory statistics to a file.
//
void
STATS_DEVICE_SERVER_CLASS::EmitFile()
{
    // Open the output file
    string statsFileName = string(globalArgs->Workload()) + ".stats";
    ofstream statsFile(statsFileName.c_str());

    if (! statsFile.is_open())
    {
        cerr << "Failed to open stats file: " << statsFile << endl;
        ASIMERROR("Can't dump statistics");
    }

    for (unsigned int i = 0; i < STATS_DICT_ENTRIES; i++)
    {
        // lookup event name from dictionary
        const char *statName = STATS_DICT::Name(i);
        const char *statStr  = STATS_DICT::Str(i);

        if ((i != STATS_NULL) && (statName != NULL))
        {
            statsFile << "\"" << statStr << "\"," << statName;
            for (int x = 0; x < globalArgs->NumContexts(); x++)
            {
                statsFile << "," << statValues[x][i];
            }
            statsFile << endl;
        }
    }
    statsFile.close();
}


void
StatsEmitFile()
{
    STATS_DEVICE_SERVER_CLASS::GetInstance()->EmitFile();
}
