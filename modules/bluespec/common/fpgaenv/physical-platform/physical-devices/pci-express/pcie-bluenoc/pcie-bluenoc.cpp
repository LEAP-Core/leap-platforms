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

#include "awb/provides/umf.h"
#include "awb/provides/pcie_device.h"
#include "awb/provides/physical_platform_utils.h"


PCIE_DEVICE_CLASS::PCIE_DEVICE_CLASS(PLATFORMS_MODULE p):
    initialized()
{
    initialized = false;
    logicalName = NULL;
    pcieDev = -1;
}

bool
PCIE_DEVICE_CLASS::Init()
{

    const char *dev_file = NULL;

    if (initialized) 
    {
        return true;
    }

    
    //Did we get a registration switch initialized?  

    if ((deviceSwitch != NULL) && (deviceSwitch->SwitchValue() != NULL))
    {
        dev_file = (deviceSwitch->SwitchValue())->c_str();
    }
    else // Use the old initialization variable.
    { 
        dev_file = FPGA_DEV_PATH.c_str();

        // Some PCIE drivers may be declared, but not used, especially
        // in multiple FPGA builds.  We detect this by comparing
        // against the dynamic default for FPGA path.  If DYNDEFAULT
        // is not provided, it means we have a new-style build and we
        // should not expect this device to ever be used. So we note
        // that we don't expect it to be used and future calls to the
        // device will result in failure. 

        if (FPGA_DEV_PATH_DYNDEFAULT == FPGA_DEV_PATH) 
        {
            return false;
	}
    }

    pcieDev = open(dev_file, O_RDWR);
    if (pcieDev < 0) {
        fprintf (stderr, "PCIe Device Error: Failed to open %s: %s\n", dev_file, strerror(errno));
        exit(EXIT_FAILURE);
    }

    //
    // Reset the FPGA -- allows running without reprogramming
    //
    if (DO_SOFT_RESET)
    {
        int res = ioctl(pcieDev, BNOC_DEACTIVATE);
        res = ioctl(pcieDev, BNOC_REACTIVATE);
        res = ioctl(pcieDev, BNOC_SOFT_RESET);
        if (res < 0)
        {
            fprintf (stderr, "Error: Failed to reset %s: %s\n", dev_file, strerror(errno));
            exit(EXIT_FAILURE);
        }
    }

    //
    // Get board info
    //
    tBoardInfo board_info;
    ioctl(pcieDev, BNOC_IDENTIFY, &board_info);
    assert(board_info.is_active);
    bpb = board_info.bytes_per_beat;

    //
    // Enable driver debugging
    //
//    tDebugLevel dbg_lvl = DEBUG_DATA | DEBUG_INTR; // | DEBUG_DMA;
//    ioctl(pcieDev, BNOC_SET_DEBUG_LEVEL, &dbg_lvl);

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

    initialized = true;
    return true;
}


// destructor
PCIE_DEVICE_CLASS::~PCIE_DEVICE_CLASS()
{ 
    if (logicalName != NULL)
    {
        delete logicalName;
    }

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

}


// cleanup: close the pipe.  The other side will exit.
void
PCIE_DEVICE_CLASS::Cleanup()
{
    initialized = false;
    if(pcieDev >= 0)
    { 
        close(pcieDev);
        pcieDev = 0;
    }
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
    ssize_t rc = read(pcieDev, buf, count);
    if (rc <= 0)
    {
        if (! initialized)
	{
	  return 0;
	}

        fprintf(stderr, "PCIe read error:  ret=%d, errno=%d\n", rc, errno);
        exit(1);
    }

    return rc;
}


// write
void
PCIE_DEVICE_CLASS::Write(const void *buf, size_t count)
{
    // This code appears to be totally broken.  If write is called on
    // an uninitialized channel, the caller has no way of knowing that
    // the call failed.
   
    ssize_t wc = write(pcieDev, buf, count);
    if (wc < 0)
    {
        if (! initialized)
	{
	    return;
	}

        fprintf(stderr, "PCIe write error:  ret=%d, errno=%d\n", wc, errno);
        exit(1);
    }
    else if (wc != count)
    {
        if (! initialized)
	{
            return;
	}

        fprintf(stderr, "PCIe write error:  only wrote %d of %d bytes\n", wc, count);
        exit(1);
    }
}

void 
PCIE_DEVICE_CLASS::RegisterLogicalDeviceName(string name)
{
    logicalName = new string(name);
    
    deviceSwitch = new BASIC_COMMAND_SWITCH_STRING_CLASS(logicalName->c_str());
}
