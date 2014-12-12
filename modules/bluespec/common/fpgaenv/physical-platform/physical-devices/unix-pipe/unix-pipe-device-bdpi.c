//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
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
#include <pthread.h>

#include "unix-pipe-device-bdpi.h"

/* global table of open channel handles */
static pthread_t initThread;
static Channel OCHT[MAX_OPEN_CHANNELS];
static Channel *freeList;
volatile static unsigned char initialized = 0;
static unsigned char initializedInFlight = 0;
static unsigned char need_reset = 0;
static unsigned char persistent = 0;
static int readOpenComplete = 0;
static char * inputFileName = NULL;
static char * outputFileName = NULL;


static int DESC_HOST_2_FPGA = -1;
static int DESC_FPGA_2_HOST = -1;


/* internal helper functions */
void cleanup()
{
}

int open_channel(const char * fileName, int * fildes, int flags) 
{
    int flagsBase;

    if (UNIX_DEVICE_DEBUG) 
    {
        printf("SIM opening input: %s\n", fileName); 
        fflush(stdout);
    }
   
    (*fildes) = open(fileName, flags | O_NONBLOCK);

    // File open was successful. Now fix blocking I/O
    if ((*fildes) >= 0) 
    {
        flagsBase = fcntl((*fildes), F_GETFL, 0);
        fcntl((*fildes), F_SETFL, flagsBase ^ O_NONBLOCK);
 
        if (UNIX_DEVICE_DEBUG) 
        {
            printf("SIM succeeded in opening file: %s\n", fileName); 
            fflush(stdout);
        }

    }
    else
    {
        if (UNIX_DEVICE_DEBUG) 
        {
            printf("SIM open failed: %s\n", fileName); 
            fflush(stdout);
        }
    }

    return (*fildes);    
}

/* initialize global data structures */
void pipe_init(unsigned char usePipes, char * platformID)
{
    char *executionDirectory = getenv("LEAP_EXECUTION_DIRECTORY");
    char *commDirectory = NULL;
    const char *toSuffix = "_TO";
    const char *fromSuffix = "_FROM";
    const char *pipes = "/pipes/"; 
    int i;

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


    if(UNIX_DEVICE_DEBUG) 
    {
        printf("Beginning pipe device initialization\n");
    }

    if (executionDirectory != NULL)
    {
        commDirectory = (char*) malloc(strlen(pipes) + strlen(executionDirectory) + 1);
        strcpy(commDirectory, executionDirectory);
        strcat(commDirectory, pipes);
    } 
    else
    {
        commDirectory = (char*) malloc(strlen(pipes) + 1);
        strcpy(commDirectory,pipes);
    }

    if (mkdir(commDirectory, S_IRWXU) != 0) 
    {
        if (errno != EEXIST)
        {
            fprintf(stderr, "Comm directory %s creation failed with %d, bailing\n", commDirectory, errno);
            perror("Error was: ");
            fflush(stderr);
            exit(1);
        }
    }

    inputFileName = (char*) malloc(strlen(commDirectory) + strlen(toSuffix) + strlen(platformID) + 1);
    strcpy(inputFileName, commDirectory);
    strcat(inputFileName, platformID);
    strcat(inputFileName, toSuffix);

    outputFileName = (char*) malloc(strlen(commDirectory) + strlen(fromSuffix) + strlen(platformID) + 1);
    strcpy(outputFileName, commDirectory);
    strcat(outputFileName, platformID);
    strcat(outputFileName, fromSuffix);

    // make a fifo.
    mkfifo(outputFileName, S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH);

    // opening the read side first, because it can be non-blocking.
    // It may fail if the fifo doesn't exist.

    // write side blocks until read side is open.
    if(UNIX_DEVICE_DEBUG) 
    {
        printf("FPGA opening output: %s\n", outputFileName);
        fflush(stdout);
    }

    // Attempt to open write side
    open_channel(outputFileName, &DESC_FPGA_2_HOST, O_WRONLY);
    open_channel(inputFileName,  &DESC_HOST_2_FPGA, O_RDONLY);

    if(UNIX_DEVICE_DEBUG) 
    {
        printf("Pipe open of %s, initialization routine complete\n", outputFileName);
    }

    // Tell the main thread we're done. 
    initialized = 1;
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

    /* try to allocate new channel from OCHT */
    if (freeList == NULL)
    {
        /* can't allocate any more channels.
         * we should return an error value to the
         * model, but for now, just crash out.. TODO */
        cleanup();
        printf("Exiting due to null free list\n");
        fflush(stderr);
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

    if (DESC_HOST_2_FPGA < 0)
    {
        if(UNIX_DEVICE_DEBUG) 
        {
            printf("pipe read attempting open\n");
        }

        // Try to open the outbound pipe
        if(open_channel(inputFileName, &DESC_HOST_2_FPGA, O_RDONLY) < 0)
        {
            // not open yet...
            resultptr[4] = PIPE_NULL;

            if(UNIX_DEVICE_DEBUG) 
            {
                printf("pipe read open attempt failed\n");
            }

            return;
        }
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
                fprintf(stderr,"Exiting simulator!\n");
                fflush(stderr);
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
                fflush(stderr);
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
                    if(UNIX_DEVICE_DEBUG)
                    {
                        printf("Exiting due to bytes read == 0\n"); 
                        fflush(stderr);
                    }

                    exit(0);
                }
            }
            else if (bytes_read == -1)
            {
                fprintf(stderr, "Error %d in unix-pipe-device-bdpi::pipe_read()\n", errno);
                fflush(stderr);
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


    if (DESC_FPGA_2_HOST < 0)
    {
        if(open_channel(outputFileName, &DESC_FPGA_2_HOST, O_WRONLY) < 0)
        {
            return 0;
        }
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
            fprintf(stderr,"Exiting simulator!\n");
            perror("select");
            fflush(stderr);
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
        fflush(stderr);
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
        fflush(stderr);
        cleanup();
        exit(1);
    }
    else if (bytes_written < BDPI_CHUNK_BYTES)
    {
        fprintf(stderr, "could not write complete chunk.\n");
        fflush(stderr);
        cleanup();
        exit(1);
    }
}
