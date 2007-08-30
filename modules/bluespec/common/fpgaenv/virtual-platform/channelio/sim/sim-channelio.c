#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "sim-channelio.h"

/* global table of open channel handles */
Channel OCHT[MAX_OPEN_CHANNELS];
Channel *freeList;
unsigned char initialized = 0;

/* global service map table */
// ServiceFunction ServiceMap[MAX_SERVICES];

/* internal helper functions */
void cleanup()
{
}

/* initialize global data structures */
void cio_init(void)
{
    int i;

    assert(initialized == 0);
    assert(MAX_OPEN_CHANNELS >= 2);

    /* initialize free list, we'll maintain it as
     * a circular doubly linked list */
    bzero(OCHT, sizeof(Channel) * MAX_OPEN_CHANNELS);

    freeList = &OCHT[0];
    OCHT[0].prev = &OCHT[MAX_OPEN_CHANNELS - 1];
    OCHT[0].next = &OCHT[1];
    for (i = 1; i < MAX_OPEN_CHANNELS - 1; i++)
    {
        OCHT[i].tableIndex = i;
        OCHT[i].prev = &OCHT[i-1];
        OCHT[i].next = &OCHT[i+1];
    }
    OCHT[MAX_OPEN_CHANNELS - 1].prev = &OCHT[MAX_OPEN_CHANNELS - 2];
    OCHT[MAX_OPEN_CHANNELS - 1].next = &OCHT[0];

    /* setup service map table
    ServiceMap[0] = PipedFrontPanel;
    ServiceMap[1] = MemoryMappedFrontPanel;
    ServiceMap[2] = Memory; */

    /* flags */
    initialized = 1;
}

/* create process and initialize data structures */
unsigned char cio_open(unsigned char serviceID)
{
    int i;
    Channel *channel;
    int temp_child_read_desc;
    int temp_child_write_desc;
    int temp_parent_read_desc;
    int temp_parent_write_desc;

    assert(initialized == 1);

    /* try to allocate new channel from OCHT */
    if (freeList == NULL)
    {
        /* can't allocate any more channels.
         * we should return an error value to the
         * model, but for now, just crash out.. TODO */
        cleanup();
        exit(1);
    }

    /* eject one channel from free list */
    channel = freeList;
    if (channel->next == channel)
    {
        /* this was the last free channel */
        assert(channel->prev == channel);
        freeList = NULL;
    }
    else
    {
        /* update links */
        freeList->prev->next = freeList->next;
        freeList->next->prev = freeList->prev;
        freeList = freeList->next;
    }

    /* setup channel */
    assert(channel->open == 0);

    /* create I/O pipes */
    if (pipe(channel->inPipe) < 0 || pipe(channel->outPipe) < 0)
    {
        /* TODO: insert exception handler */
        exit(1);
    }

    /* create target process */
    channel->childpid = fork();
    if (channel->childpid < 0)
    {
        /* TODO: insert exception handler */
        exit(1);
    }

    /* store descriptor IDs so that child process can access them */
    temp_child_read_desc    = channel->CHILD_READ;
    temp_child_write_desc   = channel->CHILD_WRITE;
    temp_parent_read_desc   = channel->PARENT_READ;
    temp_parent_write_desc  = channel->PARENT_WRITE;

    if (channel->childpid == 0)
    {
        char software_exe[256];

        /* CHILD: setup pipes for software side */
        close(temp_parent_read_desc);
        close(temp_parent_write_desc);

        dup2(temp_child_read_desc, 0);
        dup2(temp_child_write_desc, 1);

        /* call local function stub for the requested service
         * NOTE: the current protocol is that the service method
         * never return; it should instead terminate the process
        ServiceMap[serviceID](); */

        /* start software-side RRR server */
        sprintf(software_exe, "./%s_sw.exe", APM_NAME);
        execlp(software_exe, software_exe, NULL);

        /* error */
        exit(1);
    }
    else
    {
        /* PARENT: setup pipes for FPGA side */
        close(channel->CHILD_READ);
        close(channel->CHILD_WRITE);

        /* initialize channel */
        channel->open = 1;
        channel->terminated = 0;
        channel->ibHead = 0;
        channel->ibTail = 0;
    }

    /* return handle */
    return channel->tableIndex;
}

/* internal function: check if process connected to channel has quit */
int termCheck(Channel* channel)
{
    /* sanity check */
    if (initialized == 0)
    {
        /* invalid call */
        fprintf(stderr, "termCheck called without initialization\n");
        exit(1);
    }

    /* find out if child has exited */
    if (channel->terminated == 0)
    {
        if (waitpid(channel->childpid, NULL, WNOHANG|WUNTRACED) ==
                channel->childpid)
        {
            /* uh-oh... child has exited... what to do?
             * for now, lets use this code as a sink and
             * allow the BSV model to continue */
            channel->terminated = 1;

            /* close pipes */
            close(channel->PARENT_READ);
            close(channel->PARENT_WRITE);

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
    Channel *channel;

    assert(initialized == 1);

    /* lookup OCHT */
    assert(handle < MAX_OPEN_CHANNELS);
    channel = &OCHT[handle];
    assert(channel->open);

    if (termCheck(channel))
    {
        return CIO_NULL;
    }

    /* check if we have an empty or incomplete input buffer
     * If so, scan the pipe once for incoming data */
    if (channel->ibTail < BLOCK_SIZE)
    {
        /* insufficient data in buffers; attempt to read a block's
         * worth of data from the pipe. If we already have an incomplete
         * block in our buffer, then only attempt to read enough
         * data to complete the block */
        int     data_available;
        fd_set  readfds;

        FD_ZERO(&readfds);
        FD_SET(channel->PARENT_READ, &readfds);

        timeout.tv_sec  = 0;
        timeout.tv_usec = SELECT_TIMEOUT;

        data_available = select(channel->PARENT_READ + 1, &readfds,
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
            if (data_available != 1 || FD_ISSET(channel->PARENT_READ, &readfds) == 0)
            {
                fprintf(stderr, "activity detected on unknown descriptor\n");
                exit(1);
            }

            /* read in data, keep it aligned */
            bytes_requested = BLOCK_SIZE - channel->ibTail;

            bytes_read = read(channel->PARENT_READ,
                              &channel->inputBuffer[channel->ibTail],
                              bytes_requested);

            channel->ibTail += bytes_read;
        }
    }

    /* see if we have sufficient data to complete a packet */
    if ((channel->ibTail - channel->ibHead) >= PACKET_SIZE)
    {
        /* pack packet into a UINT32 */
        int i;
        unsigned int retval = 0;

        /* this code is endian-agnostic */
        for (i = 0; i < PACKET_SIZE; i++)
        {
            unsigned int byte = (unsigned int)channel->inputBuffer[channel->ibHead];
            retval |= (byte << (i * 8));
            channel->ibHead = channel->ibHead + 1;
        }

        /* sanity checks */
        assert(channel->ibHead <= channel->ibTail);
        assert(retval != CIO_NULL);

        /* now that we have a full packet, see if head and tail are
         * aligned, and if so, reset both pointers */
        if (channel->ibHead == channel->ibTail)
        {
            channel->ibHead = 0;
            channel->ibTail = 0;
        }

        /* packet ready, return */
        return retval;
    }

    /* if we're here, then there's no data on the incoming channel */
    return CIO_NULL;
}

/* write one packet of data */
void cio_write(unsigned char handle, unsigned int data)
{   
    int bytes_written;
    unsigned char databuf[PACKET_SIZE];
    unsigned int mask;
    int i;
    Channel *channel;

    assert(initialized == 1);

    /* lookup OCHT */
    assert(handle < MAX_OPEN_CHANNELS);
    channel = &OCHT[handle];
    assert(channel->open);

    if (termCheck(channel))
    {
        return;
    }

    /* unpack UINT32 into byte sequence */
    mask = 0xFF;
    for (i = 0; i < PACKET_SIZE; i++)
    {
        unsigned char byte = (mask & data) >> (i * 8);
        databuf[i] = (unsigned char)byte;
        mask = mask << 8;
    }

    /* send message on pipe */
    bytes_written = write(channel->PARENT_WRITE, databuf, PACKET_SIZE);
    if (bytes_written == -1)
    {
        perror("write");
        cleanup();
        exit(1);
    }
    else if (bytes_written < PACKET_SIZE)
    {
        fprintf(stderr, "could not write complete packet.\n");
        cleanup();
        exit(1);
    }
}

/* The BSV model can probe this flag to figure out if the *
 * user has exited from the dialog box, and, if it so     *
 * chooses, terminate simulation                          */
unsigned char cio_isdestroyed(unsigned char handle)
{
    Channel *channel;

    assert(initialized == 1);

    /* lookup OCHT */
    assert(handle < MAX_OPEN_CHANNELS);
    channel = &OCHT[handle];
    assert(channel->open);

    if (termCheck(channel))
    {
        return 1;
    }
    else
    {
        return 0;
    }
}
