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

#ifndef __UNIX_PIPE__
#define __UNIX_PIPE__

#include "platforms-module.h"
#include "command-switches.h"
#include "asim/provides/umf.h"
#include "tbb/atomic.h"

#define STDIN             0
#define STDOUT            1
#define DESC_HOST_2_FPGA  100
#define DESC_FPGA_2_HOST  101
#define BLOCK_SIZE        UMF_CHUNK_BYTES 
#define SELECT_TIMEOUT    1000


// Command-line switches for Bluesim.
class BLUESIM_SWITCH_CLASS : public COMMAND_SWITCH_LIST_CLASS
{
    public:
        BLUESIM_SWITCH_CLASS();
        ~BLUESIM_SWITCH_CLASS() {}
        int BluesimArgc() { return bluesimArgc; }
        char** BluesimArgv() { return bluesimArgv; }
        
        void ProcessSwitchList(int argv, char** argc);
        void ShowSwitch(std::ostream& ostr, const string& prefix);

    private:
        int bluesimArgc;
        char** bluesimArgv;
};

// ============================================
//           UNIX Pipe Physical Device
// ============================================
typedef class UNIX_PIPE_DEVICE_CLASS* UNIX_PIPE_DEVICE;
class UNIX_PIPE_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
    // switches for bluesim
    BLUESIM_SWITCH_CLASS bluesimSwitches;

    // switches for acquiring device uniquifier
    BASIC_COMMAND_SWITCH_STRING deviceSwitch;
  
    // process/pipe state (physical channel)
    int                       inpipe[2], outpipe[2];
    int                       childpid;
    class tbb::atomic<bool>   childAlive;
    std::string               ioFile; 
    std::string               *logicalName; 
    pthread_t                 ReaderThreads[1];
    pthread_t                 WriterThreads[1];

    int ParentRead() const { return inpipe[0]; };
    int ParentWrite() const { return outpipe[1]; };
    int ChildRead() const { return outpipe[0]; };
    int ChildWrite() const { return inpipe[1]; };

    class tbb::atomic<UINT64> initReadComplete;
    class tbb::atomic<UINT64> initWriteComplete;

  public:
    UNIX_PIPE_DEVICE_CLASS(PLATFORMS_MODULE);
    ~UNIX_PIPE_DEVICE_CLASS();

    static void * openReadThread(void *argv);
    static void * openWriteThread(void *argv);

    void Init();
    void Cleanup();                    // cleanup
    void Uninit();                     // uninit
    bool Probe();                      // probe for data
    void Read(unsigned char*, int);    // blocking read
    void Write(unsigned char*, int);   // write
    void RegisterLogicalDeviceName(string name);
};

#endif
