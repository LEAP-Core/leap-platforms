#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#include <iostream>

#include "platforms-module.h"

#include "asim/provides/command_switches.h"
#include "asim/provides/unix_pipe_device.h"


using namespace std;

// ============================================
//           UNIX Pipe Physical Device
// ============================================

// constructor: set up hardware partition
UNIX_PIPE_DEVICE_CLASS::UNIX_PIPE_DEVICE_CLASS(
    PLATFORMS_MODULE p) :
        PLATFORMS_MODULE_CLASS(p)
{
    childAlive = false;

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
        // CHILD: setup pipes for hardware side
        close(PARENT_READ);
        close(PARENT_WRITE);

        dup2(CHILD_READ, DESC_HOST_2_FPGA);
        dup2(CHILD_WRITE, DESC_FPGA_2_HOST);

        // launch hardware executable/download bitfile
        string hw_bluesim = string(globalArgs->ModelDir()) + "/" + APM_NAME + "_hw.exe";
        string hw_verilog = string(globalArgs->ModelDir()) + "/" + APM_NAME + "_hw.vexe";

        struct stat buf;
        string hw_exe;
        if (! stat(hw_bluesim.c_str(), &buf))
        {
            hw_exe = hw_bluesim;
        }
        else if (! stat(hw_verilog.c_str(), &buf))
        {
            hw_exe = hw_verilog;
        }
        else
        {
            cerr << "Can't find either Bluesim or Verilog HW simulator." << endl;
            cerr << "  Looked for Bluesim: " << hw_bluesim << endl;
            cerr << "             Verilog: " << hw_verilog << endl;
            exit(1);
        }

        // Make a copy of the argument vector so we can put the file name
        // as argv[0]
        char **argv = new char *[globalArgs->BluesimArgc() + 2];

        // Pointer to exe is argv[0]
        argv[0] = new char[hw_exe.length() + 1];
        strcpy(argv[0], hw_exe.c_str());

        // Copy remaining argv pointers, including trailing NULL
        for (int i = 1; i < globalArgs->BluesimArgc() + 1; i++)
        {
            argv[i] = globalArgs->BluesimArgv()[i];
        }
        
        execvp(argv[0], argv);

        // error
        cerr << "Error attempting to invoke " << hw_exe << endl;
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

        childAlive = true;
    }
}

// destructor
UNIX_PIPE_DEVICE_CLASS::~UNIX_PIPE_DEVICE_CLASS()
{
    // cleanup
    Cleanup();
}

// override default chain-uninit method because
// we need to do something special
void
UNIX_PIPE_DEVICE_CLASS::Uninit()
{
    // do basic cleanup
    Cleanup();

    // call default uninit so that we can continue
    // chain if necessary
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup: close the pipe.  The other side will exit.
void
UNIX_PIPE_DEVICE_CLASS::Cleanup()
{
    if (childAlive)
    {
        close(PARENT_READ);
        close(PARENT_WRITE);
        childAlive = false;
    }
}

// probe pipe to look for fresh data
bool
UNIX_PIPE_DEVICE_CLASS::Probe()
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
        if (errno == EINTR)
        {
            data_available = 0;
        }
        else
        {
            perror("unix-pipe-device select");
            exit(1);
        }
    }

    if (data_available != 0)
    {
        // incoming! sanity check
        if (data_available != 1 || FD_ISSET(PARENT_READ, &readfds) == 0)
        {
            cerr << "unix-pipe: activity detected on unknown descriptor" << endl;
            exit(1);
        }

        // yes, data is available
        return true;
    }

    // no fresh data
    return false;
}

// blocking read
void
UNIX_PIPE_DEVICE_CLASS::Read(
    unsigned char* buf,
    int bytes_requested)
{
    // assume we can read data in one shot
    int bytes_read = read(PARENT_READ, buf, bytes_requested);

    if (bytes_read == 0)
    {
        // pipe read returned 0 => hardware process has terminated, so exit
        childAlive = false;
        CallbackExit(0);
    }

    if (bytes_read < bytes_requested)
    {
        cerr << "unix-pipe: could not read requested bytes in one shot" << endl;
        CallbackExit(1);
    }
}

// write
void
UNIX_PIPE_DEVICE_CLASS::Write(
    unsigned char* buf,
    int bytes_requested)
{
    // assume we can write data in one shot
    int bytes_written = write(PARENT_WRITE, buf, bytes_requested);

    if (bytes_written < bytes_requested)
    {
        cerr << "unix-pipe: could not write requested bytes in one shot" << endl;
        CallbackExit(1);
    }
}
