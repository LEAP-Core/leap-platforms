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

//
// Integrity / bandwidth tests of PCIe BlueNoC connection.
//

#ifndef __PCIE_TESTS__
#define __PCIE_TESTS__

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


typedef class PCIE_DEVICE_TESTS_CLASS* PCIE_DEVICE_TESTS;
class PCIE_DEVICE_TESTS_CLASS
{
  private:
    int pcieDev;                      // Device file descriptor
    int bpb;                          // Bytes per beat

    unsigned char* outBuf;
    unsigned char* inBuf;

    void doWrite(int fd, const unsigned char *buf, size_t count);
    UINT32 checkReadValues(size_t count, UINT32 beatsToSend);

    UINT32 checkValue(UINT64 val, UINT64 expect);

  public:
    PCIE_DEVICE_TESTS_CLASS(int fd);
    ~PCIE_DEVICE_TESTS_CLASS() {};
    
    bool Test();
};

#endif
