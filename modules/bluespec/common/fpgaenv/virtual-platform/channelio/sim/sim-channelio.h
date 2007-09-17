#ifndef __CHANNELIO__
#define __CHANNELIO__

#include <sys/select.h>

/* virtualized I/O happens at the granularity of "packets",
 * but to reduce overheads we physically do selects, reads
 * and writes at the granularity of "blocks" */
#define PACKET_SIZE         4
#define BLOCK_SIZE          4
#define SELECT_TIMEOUT      1000
#define CIO_NULL            0xFFFFFFFF
#define MAX_OPEN_CHANNELS   32

#define STDIN               0
#define STDOUT              1

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
unsigned int cio_read(unsigned char handle);
void cio_write(unsigned char handle, unsigned int data);

#endif
