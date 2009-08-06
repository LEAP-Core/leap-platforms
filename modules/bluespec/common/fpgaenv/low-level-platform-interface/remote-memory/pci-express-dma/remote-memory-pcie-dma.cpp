#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <signal.h>
#include <string.h>
#include <iostream>

#include "asim/provides/remote_memory.h"

using namespace std;

// ============================================
//               Remote Memory
// ============================================

// constructor: set up hardware partition
REMOTE_MEMORY_CLASS::REMOTE_MEMORY_CLASS(
    PLATFORMS_MODULE p,
    PHYSICAL_DEVICES d) :
        PLATFORMS_MODULE_CLASS(p)
{
    // cache links to useful physical devices
    pciExpressDevice = d->GetPCIExpressDevice();
}

// destructor
REMOTE_MEMORY_CLASS::~REMOTE_MEMORY_CLASS()
{
    Cleanup();
}

// uninit
void
REMOTE_MEMORY_CLASS::Uninit()
{
    Cleanup();
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
REMOTE_MEMORY_CLASS::Cleanup()
{
}

// get physical addresses for a virtual region, and lock region in physical memory
UINT64
REMOTE_MEMORY_CLASS::TranslateAndLock(
    unsigned char* region,
    int size)
{
    // FIXME: add support for multiple pages
    UINT64 pa = pciExpressDevice->TranslateV2P(UINT64(region));

    return pa;
    // pa_vec->push_back(REMOTE_MEMORY_PHYSICAL_ADDRESS(pa));
}

// unlock a previously-locked region
void
REMOTE_MEMORY_CLASS::Unlock(
    UINT64 pa)
{
    cout << "remote memory: Unlock() not implemented" << endl << flush;

    // FIXME: implemement driver functionality
}
