#ifndef __PHYSICAL_CHANNEL__
#define __PHYSICAL_CHANNEL__

#include <sys/select.h>

/* pipe I/O happens at the granularity of "chunks",
 * but to reduce overheads we physically do selects, reads
 * and writes at the granularity of "blocks" */
#define BDPI_CHUNK_BYTES     4

#define BLOCK_SIZE          4
#define SELECT_TIMEOUT      1000
#define PCH_NULL            0xFFFFFFFF00000000
#define MAX_OPEN_CHANNELS   32

#define STDIN                   0
#define STDOUT                  1
#define PCH_HOST_2_FPGA   100
#define PCH_FPGA_2_HOST   101

typedef struct _Channel
{
    int     open;
    fd_set  readfds;
    int     tableIndex;

    /* input buffer */
    unsigned char   inputBuffer[BLOCK_SIZE];
    int     ibHead;
    int     ibTail;

    struct _Channel *prev;
    struct _Channel *next;

} Channel;

/* interface methods */
unsigned char pch_open(unsigned char programID);
unsigned long long pch_read(unsigned char handle);
void pch_write(unsigned char handle, unsigned int data);

#endif
