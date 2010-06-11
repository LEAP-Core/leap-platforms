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

#ifndef __JTAG__
#define __JTAG__

#include <stdio.h>

#include "platforms-module.h"
#include "asim/provides/umf.h"
#include <pthread.h>

// ============================================
//       JTAG Physical Device
// ============================================
typedef class JTAG_DEVICE_CLASS* JTAG_DEVICE;
class JTAG_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
    int pid_XMD;
    int sockfd;
    int xmdReader; 
    int input;
    int output;
    int parent_to_XMD[2];
    int jtag_to_blank[2];
    FILE* errfd;
    FILE* xmdfd;
    int killThreads;
    pthread_t pollThread;
    pthread_t blankRemoveThread;
    pthread_t XMDWriterThread;

  public:
    JTAG_DEVICE_CLASS(PLATFORMS_MODULE);
    ~JTAG_DEVICE_CLASS();

    void Cleanup();                    // cleanup
    void Uninit();                     // uninit
    bool Probe();                      // probe for data
    int  Read(char*, int);    // nonblocking read
    int  Write(const char*, int);   // write
};

#endif
