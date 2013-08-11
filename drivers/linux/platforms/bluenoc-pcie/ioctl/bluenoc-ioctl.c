//
// Copyright (C) 2013 Intel Corporation
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

void main(int argc, char *argv[]) {

    int pcieDev;                      // Device file descriptor                                                                                                                                                                            
    int bpb;                          // Bytes per beat 
    

    if(argc < 3) 
    {
        fprintf (stderr, "Not enough arguments to bluenoc-ioctl. Expected: bluenoc-ioctl device command\n");
	exit(EXIT_FAILURE);
    }


    const char *dev_file = argv[1];
    pcieDev = open(dev_file, O_RDWR);
    if (pcieDev < 0) 
    {
        fprintf (stderr, "PCIe Device Error: Failed to open %s: %s\n", dev_file, strerror(errno));
        exit(EXIT_FAILURE);
    }

    //
    // Reset the FPGA -- allows running without reprogramming
    //
    int res = -1;

    if(!strcmp(argv[2],"DEACTIVATE")) 
    {
        res = ioctl(pcieDev, BNOC_DEACTIVATE);        

	tBoardInfo board_info;
	ioctl(pcieDev, BNOC_IDENTIFY, &board_info);
	assert(!board_info.is_active);

    } 

    if(!strcmp(argv[2],"REACTIVATE")) 
    {
        res = ioctl(pcieDev, BNOC_REACTIVATE);        

	tBoardInfo board_info;
	ioctl(pcieDev, BNOC_IDENTIFY, &board_info);
	assert(board_info.is_active);

        if (Probe(pcieDev))
        {
            printf( "*** Warning:  PCIe BlueNoC channel isn't empty on startup ***\n" );
        }

    } 

    if (res < 0)
    {
        fprintf (stderr, "Error: Failed operation %s on %s: %s\n", argv[2], dev_file, strerror(errno));
        exit(EXIT_FAILURE);
    }


}
