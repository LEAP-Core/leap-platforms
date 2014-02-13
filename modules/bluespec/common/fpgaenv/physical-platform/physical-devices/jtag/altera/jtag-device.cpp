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
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 
#include <termios.h>
#include <pty.h>
#include <utmp.h>
#include <pthread.h>

#include "platforms-module.h"

#include "asim/provides/command_switches.h"
#include "asim/provides/jtag_device.h"

// ============================================
//           Serial Physical Device
// ============================================

// constructor: set up hardware partition
JTAG_DEVICE_CLASS::JTAG_DEVICE_CLASS(
    PLATFORMS_MODULE p) :
        PLATFORMS_MODULE_CLASS(p)
{

  // have a physical connection
  errfd = fopen("./error_messages_jtag_device", "w");
  niosfd = fopen("./error_messages_xmd", "w");

  //spawn a process
  if ((pipe(parent_to_nios) < 0) || (pipe(nios_to_parent) < 0))
  {
      parent->CallbackExit(1);
  }

  
  pid_NIOS = fork();
  if (pid_NIOS == 0)
  {
        // child
        close(parent_to_nios[1]);
        close(nios_to_parent[0]);

        dup2(parent_to_nios[0], fileno(stdin));
        dup2(nios_to_parent[1], fileno(stdout));  // dump output to log
        dup2(fileno(niosfd), fileno(stderr));  // dump output to log

        // make incoming fd non-blocking

        fprintf(errfd, "Launching nios2-terminal\n");
        fprintf(errfd, "stdin is a tty %d\n", isatty(fileno(stdin)));
        fflush(errfd);  
        // Each jtag channel will need some special sauce from 
        // a particular vendor...
        execlp("nios2-terminal", "nios2-terminal", NULL);
  }

  // parent
  close(parent_to_nios[0]);
  close(nios_to_parent[1]);


  input = nios_to_parent[0];
  output = parent_to_nios[1]; 

  fprintf(errfd, "Device intiailization complete...\n");
  fflush(errfd);
}

// destructor
JTAG_DEVICE_CLASS::~JTAG_DEVICE_CLASS()
{
    // cleanup
    Cleanup();
}

// override default chain-uninit method because
// we need to do something special
void
JTAG_DEVICE_CLASS::Uninit()
{
    // do basic cleanup
    Cleanup();

    // call default uninit so that we can continue
    // chain if necessary
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup: close the pipe.  The other side will exit.
void
JTAG_DEVICE_CLASS::Cleanup()
{
  // Tear down threads, XMD, and open pipes
  kill(pid_NIOS,SIGTERM);
  close(parent_to_nios[1]);
  close(nios_to_parent[0]);
}

// probe pipe to look for fresh data
bool
JTAG_DEVICE_CLASS::Probe()
{
  fd_set readFile;
  struct timeval time = {0,0};  
  FD_ZERO(&readFile);
  FD_SET(input, &readFile); 
  
  select(input+1,&readFile,NULL,NULL, &time);

  //select says we're okay ?
  if(FD_ISSET(input,&readFile)) {
    return 1;
  } else {
    return 0;
  }
}

// blocking read
int
JTAG_DEVICE_CLASS::Read(
    char* buf,
    int bytes_requested)
{
  fprintf(errfd,"trying to read %d bytes\n", bytes_requested);
  int i = 0, error = 0;
  fflush(errfd);
  return read(input,buf,bytes_requested);  
}

// write
int
JTAG_DEVICE_CLASS::Write(
    const char* buf,
    int bytes_requested)
{
  fprintf(errfd,"trying to write %d bytes\n", bytes_requested);
  fflush(errfd);
  int retval = write(output, buf, bytes_requested);
  fprintf(errfd,"Write complete\n");
  fflush(errfd);
  // flush request;
  return retval;
}



