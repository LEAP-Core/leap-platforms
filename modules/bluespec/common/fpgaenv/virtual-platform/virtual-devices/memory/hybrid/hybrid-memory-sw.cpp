#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "software-rrr-server.h"
#include "vmh-utils.h"

/* our memory, for now, is a UINT32 aligned array */

#define MEM_SIZE    262144 /* 256K * 4 = 1MB memory size */
#define CMD_LOAD    0
#define CMD_STORE   1

#define MY_STRING_ID    "MEMORY"

typedef unsigned int UINT32;

static int serviceID;

static UINT32   M[MEM_SIZE];

/* internal methods */
void memory_init(int ID, char *stringID)
{
    /* set service ID */
    serviceID = ID;

    /* zero out memory */
    bzero(M, MEM_SIZE * sizeof(UINT32));

    /* set string ID */
    sprintf(stringID, "%s", MY_STRING_ID);

    /* load memory image */
    vmh_load_image(globalArgs.benchmark, M, MEM_SIZE);
}

/* main exported interface method */
bool
memory_request(
    UINT32 arg0,
    UINT32 arg1,
    UINT32 arg2,
    UINT32 *result)
{
    /* only word-aligned accesses are allowed in our
     * current implementation */
    UINT32 addr = arg1 >> 2;
    if (addr >= MEM_SIZE)
    {
        fprintf(stderr, "memory: address out of bounds: 0x%8x\n", arg1);
        server_callback_exit(serviceID, 1);
    }

    /* decode command */
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
        server_callback_exit(serviceID, 1);
    }

    return false;
}

/* uninit */
void memory_uninit()
{
}
