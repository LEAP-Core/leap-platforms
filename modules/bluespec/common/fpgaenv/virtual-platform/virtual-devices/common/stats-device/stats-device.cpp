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

#include "asim/syntax.h"
#include "asim/config.h"

#include "asim/rrr/service_ids.h"
#include "asim/provides/command_switches.h"

#include "asim/provides/stats_device.h"

using namespace std;


// ===== service instantiation =====
STATS_DEVICE_SERVER_CLASS STATS_DEVICE_SERVER_CLASS::instance;

// ===== registered stats emitters =====
static list<STATS_EMITTER> statsEmitters;

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
        statArrayLength[x] = 0;
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
    // for every array stat.
    clientStub->GetVectorLengths(0);

    // Allocate array stats
    for (unsigned int x = 0; x < STATS_DICT_ENTRIES; x++)
    {
        if (statArrayLength[x] != 0)
        {
            statValues[x] = new STAT_VECTOR_CLASS(x, statArrayLength[x]);
        }
    }

    // This initialization pass will be used to allocate storage for non-array
    // statistics.  It will also be used to confirm that a statistics ID is
    // used at most once.
    clientStub->DumpStats(0);

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
    UINT32 pos,
    UINT32 value)
{
    // If no length set for statistic assume length 1.
    if (statValues[statID] == NULL)
    {
        // Statistic must be non-vector or it would have been initialized by
        // getVectorLengths.
        VERIFY(pos == 0, "stats device: " << STATS_DICT::Name(statID) << " -- reference to uninitialized vector stat");
        // Must be in initialization phase
        VERIFY(! statsInited, "stats device: " << STATS_DICT::Name(statID) << " -- reference to uninitialized stat");

        statValues[statID] = new STAT_VECTOR_CLASS(statID, 1);
    }

    if (! statsInited)
    {
        // Initialization pass.  Mark the bucket seen.
        statValues[statID]->InitPosition(pos);
    }

    statValues[statID]->AddStatValue(value, pos);
}

// Instantitate a new stat vector of the given length.
void
STATS_DEVICE_SERVER_CLASS::SetVectorLength(
    UINT32 statID,
    UINT32 len,
    UINT8 buildArray)
{
    //
    // There are two possible ways to build an array.  One is a vector coming
    // directly from the hardware (buildArray == false).  The other is a set
    // of independent entries with unique IDs, coming from separate collectors
    // in the hardware (buildArray == true).  For the latter we set the array
    // size to the maximum length.  This avoids forcing the hardware nodes
    // to communicate with each other to find the true size.
    //
    if (! buildArray)
    {
        VERIFY(statArrayLength[statID] == 0, "stats device: vector length set twice for stat: " << STATS_DICT::Name(statID));
    }

    if (len > statArrayLength[statID])
    {
        statArrayLength[statID] = len;
    }
}


// DumpStats
void
STATS_DEVICE_SERVER_CLASS::DumpStats()
{
    clientStub->DumpStats(0);
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

    statsFile.precision(10);

    for (unsigned int i = 0; i < STATS_DICT_ENTRIES; i++)
    {
        // lookup event name from dictionary
        const char *statName = STATS_DICT::Name(i);
        const char *statStr  = STATS_DICT::Str(i);

        if ((i != STATS_NULL) && (statName != NULL) && statValues[i] != NULL)
        {
            statsFile << statName << ",\"" << statStr << "\"";
            for (UINT32 x = 0; x < statValues[i]->GetLength(); x++)
            {
                statsFile << "," << statValues[i]->GetStatValue(x);
            }
            statsFile << endl;
        }
    }

    // Hack: instantiate the simulator configuration here to be able to emit
    // all the model parameters.
    ASIM_CONFIG sim_config = new ASIM_CONFIG_CLASS();
    sim_config->RegisterSimulatorConfiguration();
    sim_config->EmitStats(statsFile);

    // Call other emitters.  Clearly this needs to be improved with some
    // structured data.
    for (list<STATS_EMITTER>::iterator i = statsEmitters.begin();
         i != statsEmitters.end();
         i++)
    {
        (*i)->EmitStats(statsFile);
    }

    statsFile.close();
}


void
StatsEmitFile()
{
    STATS_DEVICE_SERVER_CLASS::GetInstance()->EmitFile();
}



// ========================================================================
//
// Storage for statistics vectors.
//
// ========================================================================

STAT_VECTOR_CLASS::STAT_VECTOR_CLASS(UINT32 id, UINT32 l) : 
    myID(id),
    length(l),
    curValues(new UINT64[l]),
    positionInitialized(new bool[l])
{
    for (int x = 0; x < l; x++)
    {
        curValues[x] = 0;
        positionInitialized[x] = false;
    }
}

STAT_VECTOR_CLASS::~STAT_VECTOR_CLASS() 
{ 
    delete [] curValues; 
    delete [] positionInitialized; 
}

void
STAT_VECTOR_CLASS::AddStatValue(UINT32 val, UINT32 pos) 
{ 
    VERIFY(pos < length, "stats device: stat " << STATS_DICT::Name(myID) << " position out of bounds. Given: " << pos << " Max: " << length); 
    VERIFY(positionInitialized[pos],  "stats device: stat " << STATS_DICT::Name(myID) << ", position " << pos << " -- reference to uninitialized entry");

    curValues[pos] += val; 
}

UINT64
STAT_VECTOR_CLASS::GetStatValue(UINT32 pos)  
{ 
    VERIFY(pos < length, "stats device: stat " << STATS_DICT::Name(myID) << " position out of bounds. Given: " << pos << " Max: " << length); 
    VERIFY(positionInitialized[pos],  "stats device: stat " << STATS_DICT::Name(myID) << ", position " << pos << " -- reference to uninitialized entry");

    return curValues[pos]; 
}

void
STAT_VECTOR_CLASS::InitPosition(UINT32 pos)  
{ 
    VERIFY(pos < length, "stats device: stat " << STATS_DICT::Name(myID) << " position out of bounds. Given: " << pos << " Max: " << length); 
    VERIFY(! positionInitialized[pos], "stats device: Duplicate entry " << STATS_DICT::Name(myID) << ", postion " << pos);

    positionInitialized[pos] = true;
}




// ========================================================================
//
//   HACK!  Clients may "register" as stats emitters by allocating an
//   instance of the following class.  They may then write whatever
//   they wish to the stats file.  Clearly this should be improved with
//   some structure, perhaps by switching to statistics code from
//   Asim.
//
// ========================================================================

STATS_EMITTER_CLASS::STATS_EMITTER_CLASS()
{
    statsEmitters.push_front(this);
}

STATS_EMITTER_CLASS::~STATS_EMITTER_CLASS()
{
    //
    // Drop me from the global list of emitters.
    //
    for (list<STATS_EMITTER>::iterator i = statsEmitters.begin();
         i != statsEmitters.end();
         i++)
    {
        if (*i == this)
        {
            statsEmitters.erase(i);
            break;
        }
    }
}
