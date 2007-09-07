#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

/* our memory, for now, is a UINT32 aligned array */

#define MEM_SIZE    256 /* 256 * 4 = 1KB memory size */
#define CMD_LOAD    0
#define CMD_STORE   1

#define MY_STRING_ID    "MEMORY"

typedef unsigned int UINT32;

static UINT32   M[MEM_SIZE];

/* internal methods */
void memory_init(char *stringID)
{
    /* zero out memory */
    bzero(M, MEM_SIZE * sizeof(UINT32));

    /* set string ID */
    sprintf(stringID, "%s", MY_STRING_ID);

    /* optionally load data into memory array */
    memcpy(M, "H   e   l   l   o   ,       W   o   r   l   d   !", 49);
}

/* main exported interface method */
UINT32 memory_request(UINT32 arg0, UINT32 arg1, UINT32 arg2)
{
    /* decode */
    if (arg0 == CMD_LOAD)
    {
        return M[arg1];
    }
    else if (arg0 == CMD_STORE)
    {
        M[arg1] = arg2;
        return 0;
    }
    else
    {
        fprintf(stderr, "memory: invalid command\n");
        exit(1);
    }

    return 0;
}
