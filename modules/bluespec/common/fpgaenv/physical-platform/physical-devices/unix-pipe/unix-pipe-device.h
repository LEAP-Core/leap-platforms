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
  
    // process/pipe state (physical channel)
    int             inpipe[2], outpipe[2];
    int             childpid;
    volatile bool   childAlive;
    std::string     readFile, writeFile; 
    pthread_t       ReaderThreads[1];
    pthread_t       WriterThreads[1];

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
};

#endif
