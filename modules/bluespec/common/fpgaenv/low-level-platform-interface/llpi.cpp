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

#include <signal.h>

#include "asim/provides/low_level_platform_interface.h"
#include "asim/provides/umf.h"

//
// FIXME: Applications in which the client thread forces the monitor
//        thread to exit at the end of execution (WAIT_FOR_HW == 0)
//        segfault at the end, possibly because LLPI's submodules'
//        destructors are called before LLPI's destructor (which
//        cancels the Monitor thread). This means the Monitor thread
//        is still alive for a short duration after the submodules
//        cease to exist.
//
//        The problem has been patched locally in some implementations
//        of lower-level modules, but we need a more general solution.
//

// UGLY: maintain a global pointer to LLPI's instance
//       so that the signal handler can get access to it
static LLPI llpi_instance = NULL;

// *** trampolene function for LLPI's Main() ***
void * LLPI_Main(void *argv)
{
    LLPI instance = LLPI(argv);
    instance->Main();
    return NULL;
}

// *** signal handler for Ctrl-C ***
void LLPISignalHandler(int arg)
{
    llpi_instance->KillMonitorThread();
    llpi_instance->CallbackExit(0);
}

LLPI_CLASS::LLPI_CLASS() :
        PLATFORMS_MODULE_CLASS(NULL),
        physicalDevices(this),
        debugger(this, &physicalDevices),
        remoteMemory(this, &physicalDevices),
        channelio(this, &physicalDevices),
        rrrClient(this, &channelio),
        rrrServer(this, &channelio),
        monitorAlive(false)
{
    // set global link to RRR client
    // the service modules need this link since they
    // are statically instantiated
    RRRClient = &rrrClient;

    llpi_instance = this;
}

LLPI_CLASS::~LLPI_CLASS()
{
    KillMonitorThread();
}

void
LLPI_CLASS::Init()
{

    PLATFORMS_MODULE_CLASS::Init();

    // setup signal handler to catch SIGINT
    if (signal(SIGINT, LLPISignalHandler) == SIG_ERR)
    {
        perror("signal");
        CallbackExit(1);
    }

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
    monitorAlive = true;
    rrrClient.SetMonitorThreadID(monitorThreadID);

    // initialize UMF_ALLOCATOR (FIXME: could do this cleaner)
    UMF_ALLOCATOR_CLASS::GetInstance()->Init(this);
    
}


void
LLPI_CLASS::Uninit()
{
    //
    // This path is called only during an unexpected exit sequence, with
    // the normal destructor not being called.  Make sure the physical
    // channel is cleaned up properly.  Some hardware (e.g. ACP) needs
    // to be power cycled if not closed cleanly.
    //
    channelio.~CHANNELIO_CLASS();
    physicalDevices.~PHYSICAL_DEVICES_CLASS();
}


// cleanup
void LLPI_CLASS::KillMonitorThread()
{
    if (pthread_self() == monitorThreadID)
    {
        ASIMERROR("llpi: Monitor thread trying to cancel itself!\n");
    }
    else if (monitorAlive)
    {
        pthread_cancel(monitorThreadID);
        pthread_join(monitorThreadID, NULL);
        monitorAlive = false;
    }
}

// main
void
LLPI_CLASS::Main()
{
    // infinite scheduler loop
    while (true)
    {
        pthread_testcancel(); // set cancelation point
        Poll();
    }
}

inline void
LLPI_CLASS::Poll()
{
    // Poll channelio and RRR server.  Favor channelio over other polling loops,
    // since it tends to have much more activity.
    static int m = 0;

    channelio.Poll();

    if ((++m & 15) == 0)
    {
        rrrServer.Poll();
        rrrClient.Poll();
    }
}
