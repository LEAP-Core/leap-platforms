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
#include "asim/provides/pcie_device.h"

// ============================================
//           Serial Physical Device
// ============================================
// constructor: set up hardware partition
PCIE_DEVICE_CLASS::PCIE_DEVICE_CLASS(
    PLATFORMS_MODULE p) :
        PLATFORMS_MODULE_CLASS(p)
{
  // nothing to do here
}

void
PCIE_DEVICE_CLASS::Init()
{
    serverStart();
}

// destructor
PCIE_DEVICE_CLASS::~PCIE_DEVICE_CLASS()
{
    // cleanup
    Cleanup();
}

// override default chain-uninit method because
// we need to do something special
void
PCIE_DEVICE_CLASS::Uninit()
{
    // do basic cleanup
    Cleanup();

    // call default uninit so that we can continue
    // chain if necessary
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup: close the pipe.  The other side will exit.
void
PCIE_DEVICE_CLASS::Cleanup()
{
    serverFinish();
}

// probe pipe to look for fresh data
bool
PCIE_DEVICE_CLASS::Probe()
{
  return serverTestSys();
}

// blocking read
int
PCIE_DEVICE_CLASS::Read(
    char* buf,
    int bytes_requested)
{
  for(int i = 0; i < bytes_requested; i++) {
    serverRecvSys(buf+i);
  }

  return bytes_requested;  
}

// write
int
PCIE_DEVICE_CLASS::Write(
    const char* buf,
    int bytes_requested)
{
  //  fprintf (stderr, "PCIE_DEVICE_CLASS Write\n");
  fflush(stderr);
  for(int i = 0; i < bytes_requested; i++) {
    serverSendSys(buf+i);
  }

  return bytes_requested;
}



