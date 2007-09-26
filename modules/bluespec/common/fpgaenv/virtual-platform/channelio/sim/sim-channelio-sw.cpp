#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>

#include "sim-channelio-sw.h"

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
void
CHANNELIO_CLASS::Read(
    unsigned char buf[])
{
    // block-read input pipe TODO change to non-blocking read
    int nbytes;

    if ((nbytes = read(PARENT_READ, buf, CHANNELIO_PACKET_SIZE)) != 0)
    {
        // trap errors
        if (nbytes == -1)
        {
            perror("read");
            parent->CallbackExit(1);
        }

        // make sure we've read the full packet... if not, for now, we'll
        // just crash, but later add a loop to complete the read TODO
        if (nbytes != CHANNELIO_PACKET_SIZE)
        {
            fprintf(stderr, "channelio-sw: incomplete packet\n");
            parent->CallbackExit(1);
        }
    }
    else
    {
        // pipe read returned 0 => hardware process has terminated, so exit
        parent->CallbackExit(0);
    }
}

// write
void
CHANNELIO_CLASS::Write(
    unsigned char buf[])
{
    // write to channel
    int nbytes = write(PARENT_WRITE, buf, CHANNELIO_PACKET_SIZE);
    assert(nbytes == CHANNELIO_PACKET_SIZE);    // ugh
}

// clock
void
CHANNELIO_CLASS::Poll()
{
}
