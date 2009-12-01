#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/select.h>
#include <sys/types.h>
#include <signal.h>

#include "asim/rrr/service_ids.h"
#include "asim/provides/rrr.h"

#include "asim/provides/shared_memory.h"

// service instantiation
SHARED_MEMORY_SERVER_CLASS SHARED_MEMORY_SERVER_CLASS::instance;

// constructor
SHARED_MEMORY_SERVER_CLASS::SHARED_MEMORY_SERVER_CLASS()
{
    // instantiate stubs
    serverStub = new SHARED_MEMORY_SERVER_STUB_CLASS(this);
}

// destructor
SHARED_MEMORY_SERVER_CLASS::~SHARED_MEMORY_SERVER_CLASS()
{
    Cleanup();
}

// init
void
SHARED_MEMORY_SERVER_CLASS::Init(
    PLATFORMS_MODULE p)
{
    // set parent pointer
    parent = p;
}

// uninit: override
void
SHARED_MEMORY_SERVER_CLASS::Uninit()
{
    // cleanup
    Cleanup();

    // chain
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup: kill panel process
void
SHARED_MEMORY_SERVER_CLASS::Cleanup()
{
    // destroy stubs
    delete serverStub;
}

// update a translation in the page table (called by SW client)
void
SHARED_MEMORY_SERVER_CLASS::UpdateTranslation(
    UINT64 va,
    UINT64 pa)
{
    // pageTable[va] = pa;
    theOnlyPhysicalAddress = pa;
}

// invalidate a translation in the page table (called by SW client)
void
SHARED_MEMORY_SERVER_CLASS::InvalidateTranslation(
    UINT64 va)
{
    theOnlyPhysicalAddress = 0; // ugh, but debugging anyway
    // pageTable.erase(va);
}

// RRR method: read a translation
UINT64
SHARED_MEMORY_SERVER_CLASS::GetTranslation(
    UINT8 dummy)
{
    return theOnlyPhysicalAddress;
}
