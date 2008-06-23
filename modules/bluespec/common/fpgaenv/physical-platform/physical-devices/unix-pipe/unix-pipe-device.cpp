#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <fcntl.h>
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

    //
    // Usuall this code forks the FPGA simulator.  If the environment variable
    // HASIM_NAMED_PIPES exists then the simulator is persistent and was
    // started manually.
    //
    bool forkSimulator = (getenv("HASIM_NAMED_PIPES") == NULL);

    // create I/O pipes
    if (! forkSimulator)
    {
        outpipe[1] = open("pipes/TO_FPGA", O_WRONLY);
        if (ParentWrite() < 0)
        {
            perror("output pipe (pipes/TO_FPGA)");
            exit(1);
        }
    }
    else
    {
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
            close(ParentRead());
            close(ParentWrite());

            dup2(ChildRead(), DESC_HOST_2_FPGA);
            dup2(ChildWrite(), DESC_FPGA_2_HOST);

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
            char **argv = new char *[globalArgs->BluesimArgc() + 3];

            // Pointer to exe is argv[0]
            argv[0] = new char[hw_exe.length() + 1];
            strcpy(argv[0], hw_exe.c_str());

            // Wait for Bluesim license
            argv[1] = "-w";

            // Copy remaining argv pointers, including trailing NULL
            for (int i = 1; i < globalArgs->BluesimArgc() + 1; i++)
            {
                argv[i + 1] = globalArgs->BluesimArgv()[i];
            }

            execvp(argv[0], argv);

            // error
            cerr << "Error attempting to invoke " << hw_exe << endl;
            exit(1);
        }
        else
        {
            // PARENT: setup pipes for software side
            close(ChildRead());
            close(ChildWrite());
        }
    }

    // make sure channel is working by exchanging message with FPGA
    char buf[32] = "NULL";
        
    if (write(ParentWrite(), "SYN", 4) == -1)
    {
        perror("host/init/write");
        exit(1);
    }

    //
    // Had to delay opening named input pipe to here for accurate sync with
    // the FPGA side.
    //
    if (! forkSimulator)
    {
        inpipe[0] =  open("pipes/FROM_FPGA", O_RDONLY);
        if (ParentRead() < 0)
        {
            perror("input pipe (pipes/FROM_FPGA)");
            exit(1);
        }
    }

    if (read(ParentRead(), buf, 4) == -1)
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
        close(ParentRead());
        close(ParentWrite());
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
    FD_SET(ParentRead(), &readfds);

    timeout.tv_sec  = 0;
    timeout.tv_usec = SELECT_TIMEOUT;

    data_available = select(ParentRead() + 1, &readfds, NULL, NULL, &timeout);

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
        if (data_available != 1 || FD_ISSET(ParentRead(), &readfds) == 0)
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
    int bytes_read = read(ParentRead(), buf, bytes_requested);

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
    int bytes_written = write(ParentWrite(), buf, bytes_requested);

    if (bytes_written < bytes_requested)
    {
        cerr << "unix-pipe: could not write requested bytes in one shot" << endl;
        CallbackExit(1);
    }
}
