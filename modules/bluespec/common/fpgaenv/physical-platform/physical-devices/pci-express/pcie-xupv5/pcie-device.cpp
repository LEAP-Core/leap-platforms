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



