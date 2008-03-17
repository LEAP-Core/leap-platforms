#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "unix-pipe-device-bdpi.h"

/* global table of open channel handles */
Channel OCHT[MAX_OPEN_CHANNELS];
Channel *freeList;
unsigned char initialized = 0;

/* internal helper functions */
void cleanup()
{
}

/* initialize global data structures */
void pipe_init(void)
{
    int i;
    char buf[32];

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

    /* flags */
    initialized = 1;

    /* make sure channel is working by exchanging
     * message with software */
    if (read(DESC_HOST_2_FPGA, buf, 4) == -1)
    {
        perror("FPGA/pipe_init/read");
        exit(1);
    }

    if (strcmp(buf, "SYN") != 0)
    {
        fprintf(stderr, "FPGA: incorrect sync message from host: %s\n", buf);
        exit(1);
    }

    if (write(DESC_FPGA_2_HOST, "ACK", 4) == -1)
    {
        perror("FPGA/pipe_init/write");
        exit(1);
    }
}

/* create process and initialize data structures */
unsigned char pipe_open(unsigned char serviceID)
{
    int i;
    Channel *channel;

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

    /* initialize channel */
    channel->open = 1;
    channel->ibHead = 0;
    channel->ibTail = 0;

    /* return handle */
    return channel->tableIndex;
}

/* read one chunk of data */
unsigned long long pipe_read(unsigned char handle)
{
    struct timeval timeout;
    int done;
    Channel *channel;

    assert(initialized == 1);

    /* lookup OCHT */
    assert(handle < MAX_OPEN_CHANNELS);
    channel = &OCHT[handle];
    assert(channel->open);

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
        FD_SET(DESC_HOST_2_FPGA, &readfds);

        timeout.tv_sec  = 0;
        timeout.tv_usec = SELECT_TIMEOUT;

        data_available = select(DESC_HOST_2_FPGA + 1, &readfds,
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
            if (data_available != 1 || FD_ISSET(DESC_HOST_2_FPGA, &readfds) == 0)
            {
                fprintf(stderr, "activity detected on unknown descriptor\n");
                exit(1);
            }

            /* read in data, keep it aligned */
            bytes_requested = BLOCK_SIZE - channel->ibTail;

            bytes_read = read(DESC_HOST_2_FPGA,
                              &channel->inputBuffer[channel->ibTail],
                              bytes_requested);

            channel->ibTail += bytes_read;
        }
    }

    /* see if we have sufficient data to complete a chunk */
    if ((channel->ibTail - channel->ibHead) >= BDPI_CHUNK_BYTES)
    {
        /* pack chunk into a UINT32 */
        int i;
        unsigned long long retval = 0;

        /* the following code is endian-agnostic */
        for (i = 0; i < BDPI_CHUNK_BYTES; i++)
        {
            unsigned int byte = (unsigned int)channel->inputBuffer[channel->ibHead];
            retval |= (byte << (i * 8));
            channel->ibHead = channel->ibHead + 1;
        }

        /* sanity checks */
        assert(channel->ibHead <= channel->ibTail);
        assert(retval != PIPE_NULL);

        /* now that we have a full chunk, see if head and tail are
         * aligned, and if so, reset both pointers */
        if (channel->ibHead == channel->ibTail)
        {
            channel->ibHead = 0;
            channel->ibTail = 0;
        }

        /* chunk ready, return */
        return retval;
    }

    /* if we're here, then there's no data on the incoming channel */
    return PIPE_NULL;
}

/* write one chunk of data */
void pipe_write(unsigned char handle, unsigned int data)
{   
    int bytes_written;
    unsigned char databuf[BDPI_CHUNK_BYTES];
    unsigned int mask;
    int i;
    Channel *channel;

    assert(initialized == 1);

    /* lookup OCHT */
    assert(handle < MAX_OPEN_CHANNELS);
    channel = &OCHT[handle];
    assert(channel->open);

    /* unpack UINT32 into byte sequence */
    mask = 0xFF;
    for (i = 0; i < BDPI_CHUNK_BYTES; i++)
    {
        unsigned char byte = (mask & data) >> (i * 8);
        databuf[i] = (unsigned char)byte;
        mask = mask << 8;
    }

    /* send message on pipe */
    bytes_written = write(DESC_FPGA_2_HOST, databuf, BDPI_CHUNK_BYTES);
    if (bytes_written == -1)
    {
        perror("FPGA/pipe_write/write");
        cleanup();
        exit(1);
    }
    else if (bytes_written < BDPI_CHUNK_BYTES)
    {
        fprintf(stderr, "could not write complete chunk.\n");
        cleanup();
        exit(1);
    }
}
