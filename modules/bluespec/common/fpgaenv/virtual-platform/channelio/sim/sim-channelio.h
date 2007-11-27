#ifndef __CHANNELIO__
#define __CHANNELIO__

#include <sys/select.h>

/* virtualized I/O happens at the granularity of "packets",
 * but to reduce overheads we physically do selects, reads
 * and writes at the granularity of "blocks" */
#define PACKET_SIZE         4
#define BLOCK_SIZE          4
#define SELECT_TIMEOUT      100
#define CIO_NULL            0xFFFFFFFF00000000
#define MAX_OPEN_CHANNELS   32

#define STDIN                   0
#define STDOUT                  1
#define CHANNELIO_HOST_2_FPGA   100
#define CHANNELIO_FPGA_2_HOST   101

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
unsigned char cio_open(unsigned char programID);
unsigned long long cio_read(unsigned char handle);
void cio_write(unsigned char handle, unsigned int data);

#endif
