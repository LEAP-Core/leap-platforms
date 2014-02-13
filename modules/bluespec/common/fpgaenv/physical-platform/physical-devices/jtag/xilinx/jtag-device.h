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
    void Init();                      // uninit
    void Uninit();                     // uninit
    bool Probe();                      // probe for data
    int  Read(char*, int);    // nonblocking read
    int  Write(const char*, int);   // write
};

#endif
