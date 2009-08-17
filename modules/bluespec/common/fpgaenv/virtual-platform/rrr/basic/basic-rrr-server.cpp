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
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <iostream>

#include "asim/provides/rrr.h"

using namespace std;

#define CHANNEL_ID    0

// instantiate global service table; this table will be
// populated by the individual services (also statically
// instantiated) before main().
RRR_SERVER_STUB RRR_SERVER_MONITOR_CLASS::ServerMap[MAX_SERVICES];
UINT64          RRR_SERVER_MONITOR_CLASS::RegistrationMask = 0;

// =============================
// Server Monitor static methods    
// =============================

// register a service
void
RRR_SERVER_MONITOR_CLASS::RegisterServer(
    int             serviceid,
    RRR_SERVER_STUB server)
{
    if (isServerRegistered(serviceid))
    {
        fprintf(stderr,
            "software server: duplicate serviceID registration: %d\n");
        exit(1);
    }

    // set link in map table
    ServerMap[serviceid] = server;
    setServerRegistered(serviceid);
}

bool
RRR_SERVER_MONITOR_CLASS::isServerRegistered(
    int serviceid)
{
    UINT64 mask = UINT64(0x01) << serviceid;
    return ((RegistrationMask & mask) > 0 ? true : false);
}

void
RRR_SERVER_MONITOR_CLASS::setServerRegistered(
    int serviceid)
{
    UINT64 mask = UINT64(0x01) << serviceid;
    RegistrationMask |= mask;
}

void
RRR_SERVER_MONITOR_CLASS::unsetServerRegistered(
    int serviceid)
{
    UINT64 mask = UINT64(0x01) << serviceid;
    RegistrationMask &= (~mask);
}

// ===========================
//       regular methods
// ===========================

// constructor
RRR_SERVER_MONITOR_CLASS::RRR_SERVER_MONITOR_CLASS(
    PLATFORMS_MODULE p,
    CHANNELIO        cio) :
        PLATFORMS_MODULE_CLASS(p)
{
    channelio = cio;
    // Init();
}

// destructor
RRR_SERVER_MONITOR_CLASS::~RRR_SERVER_MONITOR_CLASS()
{
}

// init: all services MUST have registered when this
// method is called
void
RRR_SERVER_MONITOR_CLASS::Init()
{
    // initialize services
    for (int i = 0; i < MAX_SERVICES; i++)
    {
        if (isServerRegistered(i))
        {
            // set myself as the PLATFORMS_MODULE parent
            // for all services so that I can chain
            // uninit()s to them
            ServerMap[i]->Init(this);
        }
    }

    // register with channelio for message delivery
    channelio->RegisterForDelivery(CHANNEL_ID, this);
    
    PLATFORMS_MODULE_CLASS::Init();
}

// uninit: override
void
RRR_SERVER_MONITOR_CLASS::Uninit()
{
    // reset service map
    for (int i = 0; i < MAX_SERVICES; i++)
    {
        if (isServerRegistered(i))
        {
            // no need to explicitly call Uninit() on
            // services, this will happen automatically
            // when we chain the call
            ServerMap[i] = NULL;
        }
    }
    RegistrationMask = 0;

    // chain
    PLATFORMS_MODULE_CLASS::Uninit();
}

// accept a delivered message from channelio
void
RRR_SERVER_MONITOR_CLASS::DeliverMessage(
    UMF_MESSAGE message)
{
    // record channelID for backwards compatibility
    int channelID = message->GetChannelID();
    int serviceID = message->GetServiceID();

    // validate serviceID
    if (isServerRegistered(serviceID) == false)
    {
        fprintf(stderr, "software server: invalid serviceID: %u\n", serviceID);
        parent->CallbackExit(1);
    }

    // call service and obtain result
    UMF_MESSAGE result = ServerMap[serviceID]->Request(message);

    // see if we need to respond
    if (result)
    {
        // set serviceID
        result->SetServiceID(serviceID);

        // send to channelio... send on original virtual channel (BC)
        channelio->Write(channelID, result);
    }
}

// poll
void
RRR_SERVER_MONITOR_CLASS::Poll()
{
    // poll each service module
    for (int i = 0; i < MAX_SERVICES; i++)
    {
        if (isServerRegistered(i))
        {
            ServerMap[i]->Poll();
        }
    }
}
