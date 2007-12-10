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

#include "sim-channelio-sw.h"

using namespace std;

// ========================================================
//                      Channel I/O
// ========================================================

// constructor
CHANNELIO_CLASS::CHANNELIO_CLASS(
    HASIM_SW_MODULE p)
{
    parent = p;
    Init();
}

// destructor
CHANNELIO_CLASS::~CHANNELIO_CLASS()
{
    Uninit();
}

// init: set up hardware partition
void
CHANNELIO_CLASS::Init()
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
            Uninit();
            exit(1);
        }

        if (read(PARENT_READ, buf, 4) == -1)
        {
            perror("host/init/read");
            Uninit();
            exit(1);
        }

        if (strcmp(buf, "ACK") != 0)
        {
            fprintf(stderr, "host: incorrect ack message from FPGA: %s\n", buf);
            Uninit();
            exit(1);
        }

        // more parent initialization
        currentMessage = NULL;
    }
}

// uninit: uninitialize hardware partition
void
CHANNELIO_CLASS::Uninit()
{
    // kill child process
    kill(childpid, SIGTERM);
}

// read
UMF_MESSAGE
CHANNELIO_CLASS::Read(
    int channel)
{
    if (readBuffer[channel].empty())
    {
        return NULL;
    }

    UMF_MESSAGE msg = readBuffer[channel].front();
    readBuffer[channel].pop();

    return msg;
}

// write
void
CHANNELIO_CLASS::Write(
    int channel,
    UMF_MESSAGE message)
{
    writeBuffer[channel].push(message);
    flushWriteBuffer(channel);
}

// sync all read buffers
void
CHANNELIO_CLASS::syncReadBuffers()
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
        parent->CallbackExit(1);
    }

    if (data_available != 0)
    {
        // incoming!
        int bytes_requested;
        int bytes_read;

        // sanity check
        if (data_available != 1 || FD_ISSET(PARENT_READ, &readfds) == 0)
        {
            cerr << "channelio-sw: activity detected on unknown descriptor" << endl;
            parent->CallbackExit(1);
        }

        // determine if we are starting a new message
        if (currentMessage == NULL)
        {
            // new message: we assume we can read in the entire
            // header chunk in one shot
            unsigned char header[CIO_CHUNK_BYTES];

            bytes_requested = CIO_CHUNK_BYTES;
            bytes_read = read(PARENT_READ, header, bytes_requested);

            if (bytes_read == 0)
            {
                // pipe read returned 0 => hardware process has terminated, so exit
                parent->CallbackExit(0);
            }

            if (bytes_read < bytes_requested)
            {
                cerr << "channelio-sw: could not read header chunk in one read" << endl;
                parent->CallbackExit(1);
            }

            // create a new message
            currentMessage = new UMF_MESSAGE_CLASS(header);
        }
        else
        {
            // continue to build message
            assert(currentMessage);

            // read in some more bytes for the current message
            unsigned char buf[BLOCK_SIZE];
            bytes_requested = BLOCK_SIZE;

            if (currentMessage->BytesRemaining() < BLOCK_SIZE)
            {
                bytes_requested = currentMessage->BytesRemaining();
            }

            bytes_read = read(PARENT_READ, buf, bytes_requested);

            if (bytes_read == 0)
            {
                // pipe read returned 0 => hardware process has terminated, so exit
                parent->CallbackExit(0);
            }

            if (bytes_read == -1)
            {
                perror("read");
                parent->CallbackExit(1);
            }

            // append read bytes into message
            currentMessage->Append(bytes_read, buf);

            // check is message is now complete
            if (currentMessage->BytesRemaining() == 0)
            {
                // complete, enqueue message into appropriate virtual channel
                readBuffer[currentMessage->GetChannelID()].push(currentMessage);
                currentMessage = NULL;
            }
        }
    }
}

// flush a given write buffer into the physical channel
void
CHANNELIO_CLASS::flushWriteBuffer(
    int channel)
{
    while (!writeBuffer[channel].empty())
    {
        UMF_MESSAGE message = writeBuffer[channel].front();
        writeBuffer[channel].pop();

        // construct header
        unsigned char header[CIO_CHUNK_BYTES];
        message->ConstructHeader(header);

        // write header to physical channel
        int nbytes = write(PARENT_WRITE, header, CIO_CHUNK_BYTES);
        assert(nbytes == CIO_CHUNK_BYTES);    // ugh

        // write message data to physical channel
        nbytes = write(PARENT_WRITE, message->GetMessage(), message->GetLength());
        assert (nbytes == message->GetLength());

        // de-allocate message
        delete message;
    }
}

// poll
void
CHANNELIO_CLASS::Poll()
{
    // sync all read buffers
    syncReadBuffers();
}


// ========================================================
//                  Unified Message Format
// ========================================================

// constructors
UMF_MESSAGE_CLASS::UMF_MESSAGE_CLASS(
    unsigned char header[])
{
    // the following code assumes a 32-bit header
    // and a particular header organization
    channelID =  header[3] >> 4;
    serviceID = (header[3] << 4) | (header[2] >> 4);
    methodID  =  header[2] & 0x0F;
    length    = (int(header[1]) << 8) + header[0];

    // allocate space for message
    message = new unsigned char[length];

    // init
    readIndex = 0;
    writeIndex = 0;
}

UMF_MESSAGE_CLASS::UMF_MESSAGE_CLASS(
    int cid,
    int sid,
    int mid,
    int len)
{
    channelID = cid;
    serviceID = sid;
    methodID  = mid;
    length    = len;

    // allocate space for message
    message = new unsigned char[length];

    // init
    readIndex = 0;
    writeIndex = 0;
}

// destructor
UMF_MESSAGE_CLASS::~UMF_MESSAGE_CLASS()
{
    if (message)
    {
        delete [] message;
    }
}

// construct a header string
void
UMF_MESSAGE_CLASS::ConstructHeader(
    unsigned char buf[])
{
    buf[0] = (unsigned char) (length & 0x000000FF);
    buf[1] = (unsigned char) (length >> 8);
    buf[2] = (unsigned char) (serviceID << 4) |
             (unsigned char) (methodID);
    buf[3] = (unsigned char) (channelID << 4) |
             (unsigned char) (serviceID >> 4);
}

// message modifiers/extractors
void
UMF_MESSAGE_CLASS::Append(
    int nbytes,
    unsigned char data[])
{
    assert(message);
    
    if ((writeIndex + nbytes) > length)
    {
        cerr << "channelio-sw: messsage write overflow" << endl;
        exit(1);
    }

    memcpy(&message[writeIndex], data, nbytes);
    writeIndex += nbytes;
}

void
UMF_MESSAGE_CLASS::Extract(
    int nbytes,
    unsigned char data[])
{
    assert(message);

    if ((readIndex + nbytes) > writeIndex)
    {
        cerr << "channelio-sw: message read underflow: readIndex = "
             << readIndex << " writeIndex = " << writeIndex
             << " nbytes = " << nbytes << endl;
        exit(1);
    }

    if (writeIndex != length)
    {
        cerr << "channelio-sw: [WARNING] attempt to read from incomplete "
             << "message, are you sure you want to do this?" << endl;
        // do not exit
    }

    memcpy(data, &message[readIndex], nbytes);
    readIndex += nbytes;
}
