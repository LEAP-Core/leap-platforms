#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

/* virtualized I/O happens at the granularity of "packets",
 * but to reduce overheads we physically do selects, reads
 * and writes at the granularity of "blocks" */
#define PACKET_SIZE     32
#define BLOCK_SIZE      32
#define SELECT_TIMEOUT  1000
#define CIO_NULL        0xFFFFFFFF

static int      terminated = 0;
static int      initialized = 0;

static int      inPipe[2],
                outPipe[2];

static fd_set   readfds;
static int      childpid;

/* unprocessed input: use pair of buffers for speed */
static char             inputBuffer[BLOCK_SIZE];
static int              ibHead = 0;
static int              ibTail = 0;

#define PARENT_READ     inPipe[0]
#define CHILD_WRITE     inPipe[1]
#define CHILD_READ      outPipe[0]
#define PARENT_WRITE    outPipe[1]

/* create process and initialize data structures */
unsigned char cio_open(unsigned char programID)
{
    int i;

    if (initialized == 1)
    {
        /* already initialized */
        return 0;
    }

    initialized = 1;

    /* create I/O pipes */
    if (pipe(inPipe) < 0 || pipe(outPipe) < 0)
    {
        /* TODO: insert exception handler */
        return 0;
    }

    /* fork off to create dialog box */
    childpid = fork();
    if (childpid < 0)
    {
        /* TODO: insert exception handler */
        return 0;
    }

    if (childpid == 0)
    {
        /* CHILD: setup pipes for dialog box side */
        close(PARENT_READ);
        close(PARENT_WRITE);

        dup2(CHILD_READ, 0);
        dup2(CHILD_WRITE, 1);

        /* exec */
        execlp("hasim-front-panel", "hasim-front-panel", NULL);
    }
    else
    {
        /* PARENT: setup pipes for model side */
        close(CHILD_READ);
        close(CHILD_WRITE);

        /* flags */
        terminated = 0;
    }

    /* for now, only allow 1 instance, return handle = 1 for this */
    return 1;
}

/* check if dialog box has quit */
int termCheck()
{
    /* sanity check */
    if (initialized == 0)
    {
        /* invalid call */
        fprintf(stderr, "termCheck called without initialization\n");
        exit(1);
    }

    /* find out if child has exited */
    if (terminated == 0)
    {
        if (waitpid(childpid, NULL, WNOHANG|WUNTRACED) == childpid)
        {
            /* uh-oh... child has exited... what to do?
             * for now, lets use this code as a sink and
             * allow the BSV model to continue */
            terminated = 1;

            /* close pipes */
            close(PARENT_READ);
            close(PARENT_WRITE);

            return 1;
        }
    }
    else
    {
        /* terminated earlier */
        return 1;
    }

    return 0;
}

/* read one packet of data */
unsigned int cio_read(unsigned char handle)
{
    struct timeval timeout;
    unsigned int retval;
    int done;

    /* this code needs to be present at the beginning of
     * all interface methods visible to the BSV model */
    if (initialized == 0)
    {
        return CIO_NULL;
    }

    if (termCheck())
    {
        return CIO_NULL;
    }

    /* check if we have an empty or incomplete input buffer
     * If so, scan the pipe once for incoming data */
    if (ibTail < BLOCK_SIZE)
    {
        /* insufficient data in buffers; attempt to read a block's
         * worth of data from the pipe. If we already have an incomplete
         * block in our buffer, then only attempt to read enough
         * data to complete the block */
        int data_available;

        FD_ZERO(&readfds);
        FD_SET(PARENT_READ, &readfds);

        timeout.tv_sec  = 0;
        timeout.tv_usec = SELECT_TIMEOUT;

        data_available = select(PARENT_READ + 1, &readfds,
                                NULL, NULL, &timeout);

        if (data_available == -1)
        {
            perror("select");
            exit(1);
        }

        if (data_available != 0)
        {
            /* incoming! */
            int bytes_requested;
            int bytes_read;

            /* sanity check */
            if (data_available != 1 || FD_ISSET(PARENT_READ, &readfds) == 0)
            {
                fprintf(stderr, "activity detected on unknown descriptor\n");
                exit(1);
            }

            /* read in data, keep it aligned */
            bytes_requested = BLOCK_SIZE - ibTail;

            bytes_read = read(PARENT_READ,
                              &inputBuffer[ibTail],
                              bytes_requested);

            ibTail += bytes_read;
        }
    }

    /* see if we have sufficient data to complete a packet */
    if ((ibTail - ibHead) >= PACKET_SIZE)
    {
        /* incoming data is text bit stream, convert to int */
        int i;
        unsigned int retval = 0;
        unsigned int mask = 1;
        for (i = 0; i < PACKET_SIZE; i++)
        {
            if (inputBuffer[ibHead] == '1')
            {
                retval += mask;
            }
            mask = mask << 1;
            ibHead = ibHead + 1;
        }

        /* sanity checks */
        assert(ibHead <= ibTail);
        assert(retval != CIO_NULL);

        /* now that we have a full packet, see if head and tail are
         * aligned, and if so, reset both pointers */
        if (ibHead == ibTail)
        {
            ibHead = 0;
            ibTail = 0;
        }

        /* packet ready, return */
        return retval;
    }

    /* if we're here, then there's no data on the incoming channel */
    return CIO_NULL;
}

/* write one LED */
void cio_write(unsigned char handle, unsigned int data)
{   
    int bytes_written;
    char databuf[PACKET_SIZE];
    int i, mask;

    /* this code needs to be present at the beginning of
     * all interface methods visible to the BSV model */
    if (initialized == 0)
    {
        return;
    }

    if (termCheck())
    {
        return;
    }

    /* Perl doesn't seem to play nice with binary data, so convert
     * the data into an ASCII text bit stream (ugh) */
    mask = 1;
    for (i = 0; i < PACKET_SIZE; i++)
    {
        char bit = (mask & data) ? '1' : '0';
        databuf[i] = bit;
        mask = mask << 1;
    }

    /* send message on pipe */
    bytes_written = write(PARENT_WRITE, databuf, PACKET_SIZE);
    if (bytes_written == -1)
    {
        perror("write");
        exit(1);
    }
    else if (bytes_written < PACKET_SIZE)
    {
        fprintf(stderr, "could not write complete packet.\n");
        exit(1);
    }
}

/* The BSV model can probe this flag to figure out if the *
 * user has exited from the dialog box, and, if it so     *
 * chooses, terminate simulation                          */
unsigned char cio_isdestroyed(unsigned char handle)
{
    /* this code needs to be present at the beginning of
     * all interface methods visible to the BSV model */
    if (initialized == 0)
    {
        return 0;
    }

    if (termCheck())
    {
        return 1;
    }
    else
    {
        return 0;
    }
}
