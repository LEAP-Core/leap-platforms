//
// Copyright (C) 2010 MIT
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

#ifndef __PCIE__
#define __PCIE__

#include <unistd.h>

#include "platforms-module.h"
#include "awb/provides/umf.h"
#include "awb/provides/command_switches.h"
#include "tbb/atomic.h"

typedef class PCIE_DEVICE_COMMAND_SWITCHES_CLASS* PCIE_DEVICE_COMMAND_SWITCHES;
class PCIE_DEVICE_COMMAND_SWITCHES_CLASS : COMMAND_SWITCH_VOID_CLASS
{
  private:
    bool runTests;

  public:
    PCIE_DEVICE_COMMAND_SWITCHES_CLASS() :
        COMMAND_SWITCH_VOID_CLASS("pcie-tests"),
        runTests(false)
    {};

    ~PCIE_DEVICE_COMMAND_SWITCHES_CLASS() {};
    
    void ProcessSwitchVoid() { runTests = true; };
    void ShowSwitch(std::ostream& ostr, const string& prefix)
    {
        ostr << prefix << "[--pcie-tests]          Run PCIe tests" << endl;
    }

    bool RunTests() { return runTests; }
};


typedef class PCIE_DEVICE_CLASS* PCIE_DEVICE;
class PCIE_DEVICE_CLASS
{
  private:
    class tbb::atomic<bool> initialized;
    PCIE_DEVICE_COMMAND_SWITCHES_CLASS switches;

    // Switches for acquiring device uniquifier. 
    // Likely that there is a refactoring here.
    BASIC_COMMAND_SWITCH_STRING deviceSwitch;

    int pcieDev;                      // Device file descriptor
    int bpb;                          // Bytes per beat

    string *logicalName;

  public:
    PCIE_DEVICE_CLASS(PLATFORMS_MODULE);
    ~PCIE_DEVICE_CLASS();

    void Cleanup();                    // cleanup
    bool Init();                       // uninit
    void Uninit();                     // uninit
    bool Probe(bool block = false);    // probe for data

    // Read up to count bytes into buffer.  The buffer must be 128-byte aligned
    // for use with the PCIe driver.  The actual number of bytes read is
    // returned.
    ssize_t Read(void *buf, size_t count);

    // Write count bytes to the PCIe device.  Like Read(), buf must be
    // 128-byte aligned.
    void Write(const void *buf, size_t count);

    // Number of bytes per beat in the FPGA-side BlueNoC driver.
    UINT32 BytesPerBeat() const { return bpb; }
    void RegisterLogicalDeviceName(string name);
};

#endif
