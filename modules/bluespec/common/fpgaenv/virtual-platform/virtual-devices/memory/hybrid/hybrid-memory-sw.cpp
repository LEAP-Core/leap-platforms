#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "hybrid-memory-sw.h"
#include "main.h"
#include "vmh-utils.h"
#include "basic-rrr-client.h"

#include "asim/rrr/rrr_service_ids.h"

#define SERVICE_ID  MEMORY_SERVICE_ID

// DEBUG: temporary link to RRR client
extern RRR_CLIENT globalRRRClient;

// service instantiations
MEMORY_CLASS        MEMORY_CLASS::instance;

// constructor
MEMORY_CLASS::MEMORY_CLASS()
{
    // register with server's map table
    RRR_SERVER_CLASS::RegisterService(SERVICE_ID, &instance);
}

// destructor
MEMORY_CLASS::~MEMORY_CLASS()
{
    Uninit();
}

// init
void
MEMORY_CLASS::Init(
    HASIM_MODULE     p)
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

// uninit
void
MEMORY_CLASS::Uninit()
{
    if (M)
    {
        delete [] M;
        M = NULL;
    }
}

// poll
void
MEMORY_CLASS::Poll()
{
    // do nothing
}

// request
bool
MEMORY_CLASS::Request(
    UINT32 arg0,
    UINT32 arg1,
    UINT32 arg2,
    UINT32 *result)
{
    // check to see if our image is ready
    if (vmhLoaded == false)
    {
        vmh_load_image(globalArgs.benchmark, M, MEM_SIZE);
        vmhLoaded = true;
    }

    // only word-aligned accesses are allowed in our current implementation
    UINT32 addr = arg1 >> 2;
    if (addr >= MEM_SIZE)
    {
        fprintf(stderr, "memory: address out of bounds: 0x%8x\n", arg1);
        parent->CallbackExit(1);
    }

    // decode command
    if (arg0 == CMD_LOAD)
    {
        *result = M[addr];
        return true;
    }
    else if (arg0 == CMD_STORE)
    {
        M[addr] = arg2;
        return false;
    }
    else
    {
        fprintf(stderr, "memory: invalid command\n");
        parent->CallbackExit(1);
    }

    return false;
}
