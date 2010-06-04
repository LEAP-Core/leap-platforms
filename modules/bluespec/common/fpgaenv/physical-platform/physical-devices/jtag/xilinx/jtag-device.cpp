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

#include "platforms-module.h"

#include "asim/provides/command_switches.h"
#include "asim/provides/jtag_device.h"


using namespace std;

// ============================================
//           Serial Physical Device
// ============================================

// constructor: set up hardware partition
JTAG_DEVICE_CLASS::JTAG_DEVICE_CLASS(
    PLATFORMS_MODULE p) :
        PLATFORMS_MODULE_CLASS(p)
{

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

}

// probe pipe to look for fresh data
bool
JTAG_DEVICE_CLASS::Probe()
{

}

// blocking read
void
JTAG_DEVICE_CLASS::Read(
    unsigned char* buf,
    int bytes_requested)
{

}

// write
void
JTAG_DEVICE_CLASS::Write(
    unsigned char* buf,
    int bytes_requested)
{

}
