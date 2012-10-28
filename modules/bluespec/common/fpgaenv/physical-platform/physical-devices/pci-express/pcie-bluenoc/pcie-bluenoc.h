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

#include "platforms-module.h"
#include "awb/provides/umf.h"
#include "awb/provides/command_switches.h"


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
class PCIE_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
    bool initialized;
    PCIE_DEVICE_COMMAND_SWITCHES_CLASS switches;

    int pcieDev;                      // Device file descriptor
    int bpb;                          // Bytes per beat

    unsigned char* outBuf;
    unsigned char* inBuf;

  public:
    PCIE_DEVICE_CLASS(PLATFORMS_MODULE);
    ~PCIE_DEVICE_CLASS();

    void Cleanup();                    // cleanup
    void Init();                       // uninit
    void Uninit();                     // uninit
    bool Probe();                      // probe for data
    UMF_CHUNK Read();                  // nonblocking read
    void Write(UMF_CHUNK chunk);       // write
};

#endif
