//
// Copyright (C) 2012 Intel Corporation
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

#include "platforms-module.h"

#include "awb/provides/command_switches.h"
#include "awb/provides/pcie_device.h"


#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <poll.h>
#include <pthread.h>
#include <error.h>
#include <assert.h>

#include "asim/syntax.h"

#include "asim/provides/umf.h"
#include "asim/provides/pcie_device.h"


PCIE_DEVICE_CLASS::PCIE_DEVICE_CLASS(PLATFORMS_MODULE p) :
    PLATFORMS_MODULE_CLASS(p),
    initialized(false)
{
  // nothing to do here
}

void
PCIE_DEVICE_CLASS::Init()
{
    if (initialized) return;
    initialized = true;

	const char *dev_file = "/dev/bluenoc_1";
	pcieDev = open(dev_file, O_RDWR);
	if (pcieDev < 0) {
		fprintf (stderr, "PCIe Device Error: Failed to open %s: %s\n", dev_file, strerror(errno));
		exit(EXIT_FAILURE);
	}

    //
    // Reset the FPGA -- allows running without reprogramming
    //
    int res = ioctl(pcieDev, BNOC_DEACTIVATE);
    res = ioctl(pcieDev, BNOC_REACTIVATE);
    res = ioctl(pcieDev, BNOC_SOFT_RESET);
    if (res < 0)
    {
        fprintf (stderr, "Error: Failed to reset %s: %s\n", dev_file, strerror(errno));
        exit(EXIT_FAILURE);
    }

    //
    // Get board info
    //
	tBoardInfo board_info;
	ioctl(pcieDev, BNOC_IDENTIFY, &board_info);
    assert(board_info.is_active);
    bpb = board_info.bytes_per_beat;

    if (Probe())
    {
        cerr << "*** Warning:  PCIe BlueNoC channel isn't empty on startup ***" << endl;
    }

    if (switches.RunTests())
    {
        // Just run link integrity and performance tests
        PCIE_DEVICE_TESTS tests = new PCIE_DEVICE_TESTS_CLASS(pcieDev);
        tests->Test();
        delete tests;
        exit(0);
    }
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
    close(pcieDev);
    initialized = false;
}


bool
PCIE_DEVICE_CLASS::Probe(bool block)
{
    struct pollfd pcie_poll;
    pcie_poll.fd = pcieDev;
    pcie_poll.events = POLLIN | POLLPRI;

    int result = poll(&pcie_poll, 1, block ? -1 : 0);
    return (result > 0);
}


// blocking read
ssize_t
PCIE_DEVICE_CLASS::Read(void *buf, size_t count)
{
    return read(pcieDev, buf, count);
}


// write
void
PCIE_DEVICE_CLASS::Write(const void *buf, size_t count)
{
    VERIFY(write(pcieDev, buf, count) == count);
}
