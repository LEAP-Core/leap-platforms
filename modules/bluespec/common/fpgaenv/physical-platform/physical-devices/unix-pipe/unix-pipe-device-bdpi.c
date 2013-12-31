//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

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
#include <errno.h>

#include "unix-pipe-device-bdpi.h"

/* global table of open channel handles */
static Channel OCHT[MAX_OPEN_CHANNELS];
static Channel *freeList;
static unsigned char initialized = 0;
static unsigned char need_reset = 1;
static unsigned char persistent = 0;

int DESC_HOST_2_FPGA;
int DESC_FPGA_2_HOST;


/* internal helper functions */
void cleanup()
{
}

/* initialize global data structures */
void pipe_init(unsigned char usePipes, char * platformID)
{
  int i, read_bytes, retries = 0, flags;
    char buf[32];

    if (initialized) return;

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

    if (usePipes > 0)
    {
        //
        // Start by opening only the input named pipe.  That way we can read
        // the initial SYN message to see whether the connection is really from
        // the software model.  It allows someone to force this side to exit
        // by sending anything other than "SYN" on the incoming pipe.
        //
        // XXX we may need to multithread this initialization.

        const char *commDirectory = "pipes/";
        const char *toSuffix = "_TO";
        const char *fromSuffix = "_FROM";
        char * inputFileName = NULL;
        char * outputFileName = NULL;

        if(mkdir(commDirectory, S_IRWXU) != 0) 
        {
            if(errno != EEXIST)
            {
	        fprintf(stderr, "Comm directory creation failed, bailing\n");
	        exit(1);
            }
        }

        inputFileName = (char*) malloc(strlen(commDirectory) + strlen(toSuffix) + strlen(platformID));
        strcpy(inputFileName, commDirectory);
        strcat(inputFileName, platformID);
        strcat(inputFileName, toSuffix);

        printf("Input file is %s", inputFileName);

        outputFileName = (char*) malloc(strlen(commDirectory) + strlen(toSuffix) + strlen(platformID));
        strcpy(outputFileName, commDirectory);
        strcat(outputFileName, platformID);
        strcat(outputFileName, fromSuffix);
        // make a fifo.

        printf("Output file is %s", outputFileName);

        mkfifo(outputFileName, S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH);


        // opening the read side first, because it can be non-blocking.
        // It may fail if the fifo doesn't exist.

        // write side blocks until read side is open.
        DESC_FPGA_2_HOST = open(outputFileName, O_WRONLY);	
        if (DESC_FPGA_2_HOST < 0)
        {
            perror("FPGA0 named outgoing pipe (pipes/FROM_FPGA)");
            exit(1);
        }


        flags = fcntl(DESC_FPGA_2_HOST, F_GETFL, 0);
        if(UNIX_DEVICE_DEBUG)
	{
            printf("Flags DESC_FPGA_2_HOST: %x\n", flags);
	}

        do
    	{ 
	    DESC_HOST_2_FPGA = open(inputFileName, O_RDONLY);
            retries++;
	    sleep(1);
        } while (DESC_HOST_2_FPGA < 0 && retries < 120);

        if (DESC_HOST_2_FPGA < 0)
        {
            perror("named incoming pipe (pipes/TO_FPGA)");
            exit(1);
        }


    }

    /* make sure channel is working by exchanging
     * message with software */
    if(UNIX_DEVICE_DEBUG)
    {
        printf("FPGA: Initialization complete\n");
    }
}

/* trigger FPGA reset */
unsigned char pipe_receive_reset(void)
{
    return need_reset;
}


/* ack for FPGA reset request */
void pipe_clear_reset(void)
{
    need_reset = 0;
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
void pipe_read(unsigned int* resultptr, unsigned char handle)
{
    struct timeval timeout;
    int done;
    Channel *channel;

    if (! initialized)
    {
        resultptr[4] = PIPE_NULL;
        return;
    }

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
            if (errno == EINTR)
            {
                data_available = 0;
            }
            else
            {
                perror("select");
                exit(1);
            }
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

            if (bytes_read == 0)
            {
                // DO WE NEED THIS STATUS MESSAGE?
                // fprintf(stderr, "EOF in unix-pipe-device-bdpi::pipe_read()\n");
                if (persistent)
                {
                    close(DESC_HOST_2_FPGA);
                    close(DESC_FPGA_2_HOST);
                    initialized = 0;
                    need_reset = 1;
                }
                else
                {
                    exit(0);
                }
            }
            else if (bytes_read == -1)
            {
                fprintf(stderr, "Error %d in unix-pipe-device-bdpi::pipe_read()\n", errno);
                exit(1);
            }

            channel->ibTail += bytes_read;
        }
    }

    /* see if we have sufficient data to complete a chunk */
    if ((channel->ibTail - channel->ibHead) >= BDPI_CHUNK_BYTES)
    {
        memcpy(resultptr, &channel->inputBuffer[channel->ibHead], BDPI_CHUNK_BYTES);
        channel->ibHead = channel->ibHead + BDPI_CHUNK_BYTES;

        /* now that we have a full chunk, see if head and tail are
         * aligned, and if so, reset both pointers */
        if (channel->ibHead == channel->ibTail)
        {
            channel->ibHead = 0;
            channel->ibTail = 0;
        }

        resultptr[4] = 0;
        return;
    }

    /* if we're here, then there's no data on the incoming channel */
    resultptr[4] = PIPE_NULL;
    return;
}


// Return 1 if can write, 0 if can not.
unsigned char pipe_can_write(unsigned char handle)
{
    Channel *channel;

    int    space_available;
    fd_set writefds;
    struct timeval timeout;

    if (! initialized)
    {
        return 0;
    }

    assert(handle < MAX_OPEN_CHANNELS);
    channel = &OCHT[handle];
    if (! channel->open)
    {
        return 0;
    }

    FD_ZERO(&writefds);
    FD_SET(DESC_FPGA_2_HOST, &writefds);

    timeout.tv_sec  = 0;
    timeout.tv_usec = 0;

    space_available = select(DESC_FPGA_2_HOST + 1, NULL, &writefds, NULL, &timeout);
    if (space_available == -1)
    {
        if (errno == EINTR)
        {
            space_available = 0;
        }
        else
        {
            perror("select");
            exit(1);
        }
    }

    return (space_available == 0 ? 0 : 1);
}


/* write one chunk of data */
void pipe_write(unsigned char handle, unsigned int* data)
{   
  int bytes_written,i;
    Channel *channel;

    if (! initialized)
    {
        fprintf(stderr, "unix-pipe-device-bdpi.c: Write is called while uninitialized\n");
        exit(1);
    }

    /* lookup OCHT */
    assert(handle < MAX_OPEN_CHANNELS);
    channel = &OCHT[handle];
    assert(channel->open);

    /* send message on pipe */

    if(UNIX_DEVICE_DEBUG)
    {
        printf("Writing % d bytes to host %d\n",  BDPI_CHUNK_BYTES, DESC_FPGA_2_HOST);
    }

    bytes_written = write(DESC_FPGA_2_HOST, data, BDPI_CHUNK_BYTES);

    if(UNIX_DEVICE_DEBUG)
    {
        printf("Write of %d bytes complete\n",  BDPI_CHUNK_BYTES);
    }

    if (bytes_written == -1)
    {
        fprintf(stderr, "         HW side exiting (pipe closed)\n");
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
