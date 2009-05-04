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
#include "asim/provides/umf.h"

#define STDIN             0
#define STDOUT            1
#define DESC_HOST_2_FPGA  100
#define DESC_FPGA_2_HOST  101
#define BLOCK_SIZE        4
#define SELECT_TIMEOUT    1000

// ============================================
//           UNIX Pipe Physical Device
// ============================================
typedef class UNIX_PIPE_DEVICE_CLASS* UNIX_PIPE_DEVICE;
class UNIX_PIPE_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
    // process/pipe state (physical channel)
    int  inpipe[2], outpipe[2];
    int  childpid;
    bool childAlive;

    int ParentRead() const { return inpipe[0]; };
    int ParentWrite() const { return outpipe[1]; };
    int ChildRead() const { return outpipe[0]; };
    int ChildWrite() const { return inpipe[1]; };

  public:
    UNIX_PIPE_DEVICE_CLASS(PLATFORMS_MODULE);
    ~UNIX_PIPE_DEVICE_CLASS();

    void Cleanup();                    // cleanup
    void Uninit();                     // uninit
    bool Probe();                      // probe for data
    void Read(unsigned char*, int);    // blocking read
    void Write(unsigned char*, int);   // write
};

#endif
