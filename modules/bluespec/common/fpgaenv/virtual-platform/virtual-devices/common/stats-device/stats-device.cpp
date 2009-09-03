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
#include <limits.h>
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
    statsInited(false),
    // instantiate stubs
    clientStub(new STATS_CLIENT_STUB_CLASS(this)),
    serverStub(new STATS_SERVER_STUB_CLASS(this))
{

    for (int x = 0; x < STATS_DICT_ENTRIES; x++)
    {
        statValues[x] = NULL;
    }
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
}



// init
void
STATS_DEVICE_SERVER_CLASS::SetupStats()
{
    // This call will cause the hardware to invoke SetStatVectorLength
    // for every stat. This will in turn instantiate the stats themselves.
    int ack = clientStub->GetVectorLengths(0);
    statsInited = true;
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
    delete clientStub;

    if (statsInited)
    {
        for (int x = 0; x < STATS_DICT_ENTRIES; x++)
        {
            if (statValues[x] != NULL)
            {
                delete statValues[x];
            }
        }
    }
}

//
// RRR request methods
//

// Send
void
STATS_DEVICE_SERVER_CLASS::ReportStat(
    UINT32 statID,
    UINT8 pos,
    UINT32 value)
{
    //
    // Add new value to running total
    //
    VERIFY(statValues[statID] != NULL, "stats device: got reported value for unknown stat ID: " << statID << ", Value: " << value);
    statValues[statID]->AddStatValue(value, pos);
}

// StatOverflow
void
STATS_DEVICE_SERVER_CLASS::StatOverflow(
    UINT32 statID,
    UINT8 pos)
{
    //
    // Add UINT32 MAX_INT to running total
    //
    
    VERIFY(statValues[statID] != NULL, "stats device: got overflow for unknown stat ID: " << statID);
    UINT32 mi = UINT_MAX;
    statValues[statID]->AddStatValue(mi, pos);
}
// Done
void
STATS_DEVICE_SERVER_CLASS::SetVectorLength(
    UINT32 statID,
    UINT8 len)
{

    // Instantitate a new stat vector of the given length.
    statValues[statID] = new STAT_VECTOR_CLASS(statID, len);
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
    
    for (int x = 0; x < STATS_DICT_ENTRIES; x++)
    {
        if (statValues[x] != NULL)
        {
            statValues[x]->DumpFinished();
        }
    }
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

        if ((i != STATS_NULL) && (statName != NULL) && statValues[i] != NULL)
        {
            statsFile << "\"" << statStr << "\"," << statName;
            for (UINT8 x = 0; x < statValues[i]->GetLength(); x++)
            {
                if (statValues[i]->EverSawPosition(x))
                {
                    statsFile << "," << statValues[i]->GetStatValue(x);
                }
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
