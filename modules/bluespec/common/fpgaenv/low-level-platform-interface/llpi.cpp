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

#include "asim/provides/low_level_platform_interface.h"

// *** trampolene function for LLPI's Main() ***
void * LLPI_Main(void *argv)
{
    LLPI instance = LLPI(argv);
    instance->Main();
    return NULL;
}

LLPI_CLASS::LLPI_CLASS() :
        PLATFORMS_MODULE_CLASS(NULL),
        physicalDevices(this),
        debugger(this, &physicalDevices),
        remoteMemory(this, &physicalDevices),
        channelio(this, &physicalDevices),
        rrrClient(this, &channelio),
        rrrServer(this, &channelio)
{
    // set global link to RRR client
    // the service modules need this link since they
    // are statically instantiated
    RRRClient = &rrrClient;
}

LLPI_CLASS::~LLPI_CLASS()
{
}

void
LLPI_CLASS::Init()
{

    // spawn off Monitor/Service thread which calls LLPI's Main()
    if (pthread_create(&monitorThreadID,
                       NULL,
                       LLPI_Main,
                       (void *)this) != 0)
    {
        perror("pthread_create");
        exit(1);
    }
    
    // RRR needs to know the monitor thread ID
    rrrClient.SetMonitorThreadID(monitorThreadID);
    
}
void
LLPI_CLASS::Main()
{
    // infinite scheduler loop
    while (true)
    {
        Poll();
    }
}


void
LLPI_CLASS::Poll()
{
    // poll channelio and RRR server
    channelio.Poll();
    rrrServer.Poll();
    rrrClient.Poll();
}
