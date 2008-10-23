#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "asim/provides/scratchpad_memory.h"
#include "asim/provides/command_switches.h"
#include "asim/rrr/service_ids.h"

#include "vmh-utils.h"

// service instantiation
SCRATCHPAD_MEMORY_SERVER_CLASS SCRATCHPAD_MEMORY_SERVER_CLASS::instance;

// constructor
SCRATCHPAD_MEMORY_SERVER_CLASS::SCRATCHPAD_MEMORY_SERVER_CLASS()
{
    // instantiate stubs
    clientStub = new SCRATCHPAD_MEMORY_CLIENT_STUB_CLASS(this);
    serverStub = new SCRATCHPAD_MEMORY_SERVER_STUB_CLASS(this);
}

// destructor
SCRATCHPAD_MEMORY_SERVER_CLASS::~SCRATCHPAD_MEMORY_SERVER_CLASS()
{
    Cleanup();
}

// init
void
SCRATCHPAD_MEMORY_SERVER_CLASS::Init(
    PLATFORMS_MODULE p)
{
    // set parent pointer
    parent = p;

    // allocate and zero out memory
    M = new UINT32[MEM_SIZE];
    bzero(M, MEM_SIZE * sizeof(UINT32));

    // don't load memory image now; load it
    // only when we actually receive a request
    vmhLoaded = false;
}

// uninit: override
void
SCRATCHPAD_MEMORY_SERVER_CLASS::Uninit()
{
    // cleanup
    Cleanup();
    
    // chain
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
SCRATCHPAD_MEMORY_SERVER_CLASS::Cleanup()
{
    if (M)
    {
        delete [] M;
        M = NULL;
    }
}

// poll
void
SCRATCHPAD_MEMORY_SERVER_CLASS::Poll()
{
    // do nothing
}

//
// Internal Methods
//

// load VMH image
void
SCRATCHPAD_MEMORY_SERVER_CLASS::LoadVMH()
{
    char *benchmark = "program.vmh";
    if (globalArgs->FuncPlatformArgc() > 1)
    {
        benchmark = globalArgs->FuncPlatformArgv()[1];
    }
    if (vmh_load_image(benchmark, M, MEM_SIZE) == -1)
    {
        parent->CallbackExit(1);
    }
}

// align address
UINT32
SCRATCHPAD_MEMORY_SERVER_CLASS::AlignAddress(
    UINT32 addr)
{
    // only word-aligned accesses are allowed in our current implementation
    UINT32 aligned_addr = addr >> 2;
    if (aligned_addr >= MEM_SIZE)
    {
        fprintf(stderr, "scratchpad_memory: address out of bounds: 0x%8x\n", addr);
        parent->CallbackExit(1);
    }
    return aligned_addr;
}

//
// RRR requests
//

// Load
UINT32
SCRATCHPAD_MEMORY_SERVER_CLASS::Load(
    UINT32 addr)
{
    // check to see if our image is ready
    if (vmhLoaded == false)
    {
        LoadVMH();
        vmhLoaded = true;
    }

    // align address
    UINT32 aligned_addr = AlignAddress(addr);

    // all OK, lookup memory and return value
    return M[aligned_addr];
}

void
SCRATCHPAD_MEMORY_SERVER_CLASS::Store(
    UINT32 addr,
    UINT32 val)
{
    // check to see if our image is ready
    if (vmhLoaded == false)
    {
        LoadVMH();
        vmhLoaded = true;
    }

    // align address
    UINT32 aligned_addr = AlignAddress(addr);

    // all OK, update memory with Store
    M[aligned_addr] = val;
}
