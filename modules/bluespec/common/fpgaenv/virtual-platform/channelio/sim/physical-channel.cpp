#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <iostream>

#include "physical-channel.h"

using namespace std;


// ============================================
//               Physical Channel              
// ============================================

// constructor: set up hardware partition
PHYSICAL_CHANNEL_CLASS::PHYSICAL_CHANNEL_CLASS()
{
    // create I/O pipes
    if (pipe(inpipe) < 0 || pipe(outpipe) < 0)
    {
        perror("pipe");
        exit(1);
    }

    // create target process
    childpid = fork();
    if (childpid < 0)
    {
        perror("fork");
        exit(1);
    }

    if (childpid == 0)
    {
        char hardware_exe[256];

        // CHILD: setup pipes for hardware side
        close(PARENT_READ);
        close(PARENT_WRITE);

        dup2(CHILD_READ, CHANNELIO_HOST_2_FPGA);
        dup2(CHILD_WRITE, CHANNELIO_FPGA_2_HOST);

        // launch hardware executable/download bitfile
        sprintf(hardware_exe, "./%s_hw.exe", APM_NAME);
        execlp(hardware_exe, hardware_exe, NULL);

        // error
        perror("execlp");
        exit(1);
    }
    else
    {
        // PARENT: setup pipes for software side
        close(CHILD_READ);
        close(CHILD_WRITE);

        // make sure channel is working by exchanging message with FPGA
        char buf[32] = "NULL";
        
        if (write(PARENT_WRITE, "SYN", 4) == -1)
        {
            perror("host/init/write");
            exit(1);
        }

        if (read(PARENT_READ, buf, 4) == -1)
        {
            perror("host/init/read");
            exit(1);
        }

        if (strcmp(buf, "ACK") != 0)
        {
            fprintf(stderr, "host: incorrect ack message from FPGA: %s\n", buf);
            exit(1);
        }

        // more parent initialization
        incomingMessage = NULL;
    }
}

// destructor: uninitialize hardware partition
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
    // kill child process
    kill(childpid, SIGTERM);
}

// blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::Read()
{
    // blocking loop
    while (true)
    {
        // check if message is ready
        if (incomingMessage != NULL && incomingMessage->BytesRemaining() == 0)
        {
            // message is ready!
            UMF_MESSAGE msg = incomingMessage;
            incomingMessage = NULL;
            return msg;
        }

        // block-read data from pipe
        readPipe();
    }

    // shouldn't be here
    return NULL;
}

// non-blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::TryRead()
{
    // if there's fresh data on the pipe, update
    if (dataAvailableOnPipe())
    {
        readPipe();
    }

    // now see if we have a complete message
    if (incomingMessage && incomingMessage->BytesRemaining() == 0)
    {
        UMF_MESSAGE msg = incomingMessage;
        incomingMessage = NULL;
        return msg;
    }

    // message not yet ready
    return NULL;
}

// write
void
PHYSICAL_CHANNEL_CLASS::Write(
    UMF_MESSAGE message)
{
    // construct header
    unsigned char header[UMF_CHUNK_BYTES];
    message->ConstructHeader(header);

    // write header to physical channel
    int nbytes = write(PARENT_WRITE, header, UMF_CHUNK_BYTES);
    assert(nbytes == UMF_CHUNK_BYTES);    // ugh

    // write message data to physical channel
    nbytes = write(PARENT_WRITE, message->GetMessage(), message->GetLength());
    assert (nbytes == message->GetLength());

    // de-allocate message
    delete message;
}

// probe (via select) pipe to look for fresh data
bool
PHYSICAL_CHANNEL_CLASS::dataAvailableOnPipe()
{
    // test for incoming data on physical channel
    struct timeval  timeout;
    int             data_available;
    fd_set          readfds;

    FD_ZERO(&readfds);
    FD_SET(PARENT_READ, &readfds);

    timeout.tv_sec  = 0;
    timeout.tv_usec = SELECT_TIMEOUT;

    data_available = select(PARENT_READ + 1, &readfds, NULL, NULL, &timeout);

    if (data_available == -1)
    {
        perror("select");
        exit(1);
    }

    if (data_available != 0)
    {
        // incoming! sanity check
        if (data_available != 1 || FD_ISSET(PARENT_READ, &readfds) == 0)
        {
            cerr << "channelio-sw: activity detected on unknown descriptor" << endl;
            exit(1);
        }

        // yes, data is available
        return true;
    }

    // no fresh data
    return false;
}

// read un-processed data on the pipe
void
PHYSICAL_CHANNEL_CLASS::readPipe()
{
    // determine if we are starting a new message
    if (incomingMessage == NULL)
    {
        // new message: we assume we can read in the entire
        // header chunk in one shot
        unsigned char header[UMF_CHUNK_BYTES];

        int bytes_requested = UMF_CHUNK_BYTES;
        int bytes_read = read(PARENT_READ, header, bytes_requested);

        if (bytes_read == 0)
        {
            // pipe read returned 0 => hardware process has terminated, so exit
            exit(0);
        }

        if (bytes_read < bytes_requested)
        {
            cerr << "channelio-sw: could not read header chunk in one read" << endl;
            exit(1);
        }

        // create a new message
        incomingMessage = new UMF_MESSAGE_CLASS(header);
    }
    else if (incomingMessage->BytesRemaining() == 0)
    {
        // uh-oh.. we already have a full message, but it hasn't been
        // asked for yet. We will simply not read the pipe, but in
        // future, we might want to include a read buffer.
    }
    else
    {
        // read in some more bytes for the current message
        unsigned char buf[BLOCK_SIZE];
        int bytes_requested = BLOCK_SIZE;

        if (incomingMessage->BytesRemaining() < BLOCK_SIZE)
        {
            bytes_requested = incomingMessage->BytesRemaining();
        }

        int bytes_read = read(PARENT_READ, buf, bytes_requested);

        if (bytes_read == 0)
        {
            // pipe read returned 0 => hardware process has terminated, so exit
            exit(0);
        }

        if (bytes_read == -1)
        {
            perror("read");
            exit(1);
        }

        // append read bytes into message
        incomingMessage->AppendBytes(bytes_read, buf);
    }
}
