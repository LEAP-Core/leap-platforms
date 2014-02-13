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


// A thin software interface for the bluenoc ioctls.

#include "bluenoc.h"


#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <poll.h>
#include <pthread.h>
#include <error.h>
#include <string.h>
#include <errno.h>
#include <assert.h>


int Probe(int pcieDev)
{
    int block = 0;
    struct pollfd pcie_poll;
    pcie_poll.fd = pcieDev;
    pcie_poll.events = POLLIN | POLLPRI;

    int result = poll(&pcie_poll, 1, block ? -1 : 0);
    return (result > 0);
}


void Usage()
{
    fprintf(stderr, "Usage: bluenoc-ioctl <device> [activate | deactivate]\n");
}


void main(int argc, char *argv[]) {

    int pcieDev;                      // Device file descriptor                                                                                                                                                                            
    int bpb;                          // Bytes per beat 
    

    if (argc < 3) 
    {
        Usage();
        exit(EXIT_FAILURE);
    }


    const char *dev_file = argv[1];
    pcieDev = open(dev_file, O_RDWR);
    if (pcieDev < 0) 
    {
        fprintf(stderr, "PCIe Device Error: Failed to open %s: %s\n", dev_file, strerror(errno));
        exit(EXIT_FAILURE);
    }

    //
    // Reset the FPGA -- allows running without reprogramming
    //
    int res = -1;

    if (!strcmp(argv[2], "deactivate")) 
    {
        res = ioctl(pcieDev, BNOC_DEACTIVATE);        

        tBoardInfo board_info;
        ioctl(pcieDev, BNOC_IDENTIFY, &board_info);
        assert(!board_info.is_active);

    } 
    else if (!strcmp(argv[2], "activate")) 
    {
        res = ioctl(pcieDev, BNOC_REACTIVATE);        

        tBoardInfo board_info;
        ioctl(pcieDev, BNOC_IDENTIFY, &board_info);
        assert(board_info.is_active);

        if (Probe(pcieDev))
        {
            fprintf(stderr, "*** Warning:  PCIe BlueNoC channel isn't empty on startup ***\n" );
        }

    } 
    else
    {
        fprintf(stderr, "Unknown command: %s\n", argv[2]);
        Usage();
        exit(EXIT_FAILURE);
    }

    if (res < 0)
    {
        fprintf(stderr, "Error: Failed operation %s on %s: %s\n", argv[2], dev_file, strerror(errno));
        exit(EXIT_FAILURE);
    }
}
