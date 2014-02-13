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
