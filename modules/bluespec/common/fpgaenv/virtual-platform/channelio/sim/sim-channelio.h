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
#define MAX_SERVICES        32

typedef struct _Channel
{
    int     open;
    int     terminated;
    int     inPipe[2], outPipe[2];
    fd_set  readfds;
    int     childpid;
    int     tableIndex;

    /* input buffer */
    unsigned char   inputBuffer[BLOCK_SIZE];
    int     ibHead;
    int     ibTail;

    struct _Channel *prev;
    struct _Channel *next;

} Channel;

#define PARENT_READ     inPipe[0]
#define CHILD_WRITE     inPipe[1]
#define CHILD_READ      outPipe[0]
#define PARENT_WRITE    outPipe[1]

/* interface methods */
unsigned char cio_open(unsigned char programID);
unsigned int cio_read(unsigned char handle);
void cio_write(unsigned char handle, unsigned int data);
unsigned char cio_isdestroyed(unsigned char handle);

/* service method stubs */
void FrontPanel();
void Memory();

typedef void (*ServiceFunction) (void);

#endif
