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

#ifndef __PHYSICAL_PLATFORM_DEBUGGER__
#define __PHYSICAL_PLATFORM_DEBUGGER__

#include "asim/provides/umf.h"
#include "asim/provides/pci_express_device.h"
#include "asim/provides/physical_platform.h"

// ============================================
//       HTG v5 PCIe Platform Debugger              
// ============================================

class PHYSICAL_PLATFORM_DEBUGGER_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:

    // links to useful physical devices
    PCIE_DEVICE pciExpressDevice;
    
    // instruction ID
    CSR_DATA iid;
    
    // internal methods
    void PrintHelp_Help();
    void PrintHelp_CSR();
    void PrintHelp_Inst();
    void PrintHelp_Commands();
    void PrintStatus_Flags(unsigned int);
    void PrintStatus_Pointers(unsigned int);
    void PrintStatus_VHDL(unsigned int);
    unsigned int StoI(const char *);
    CSR_DATA GenIID();

  public:

    PHYSICAL_PLATFORM_DEBUGGER_CLASS(PLATFORMS_MODULE, PHYSICAL_DEVICES);
    ~PHYSICAL_PLATFORM_DEBUGGER_CLASS();

    void Monitor();
};

#endif
