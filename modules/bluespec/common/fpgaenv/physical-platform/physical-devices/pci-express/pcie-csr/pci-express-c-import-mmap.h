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

#ifndef __PCI_EXPRESS_DEVICE__
#define __PCI_EXPRESS_DEVICE__

#include <asim/syntax.h>
#include "platforms-module.h"

// ===============================================
//               PCI-Express Device
// ===============================================

// types
#if   (PCIE_CSR_DATA_SIZE == 8)
typedef unsigned char      CSR_DATA;
#elif (PCIE_CSR_DATA_SIZE == 32)
typedef unsigned int       CSR_DATA;
#elif (PCIE_CSR_DATA_SIZE == 64)
typedef unsigned long long CSR_DATA;
#else
#error "invalid PCIE_CSR_DATA_SIZE"
#endif

#if   (PCIE_CSR_IDX_SIZE == 8)
typedef unsigned char      CSR_INDEX;
#elif (PCIE_CSR_IDX_SIZE == 32)
typedef unsigned int       CSR_INDEX;
#elif (PCIE_CSR_IDX_SIZE == 64)
typedef unsigned long long CSR_INDEX;
#else
#error "invalid PCIE_CSR_IDX_SIZE"
#endif    

#if (PCIE_PHYS_ADDR_SIZE == 32)
typedef unsigned int       PCIE_PHYSICAL_ADDRESS;
#elif (PCIE_PHYS_ADDR_SIZE == 64)
typedef unsigned long long PCIE_PHYSICAL_ADDRESS;
#else
#error "invalid PCIE_PHYSICAL_ADDRESS_SIZE"
#endif

// =========== The Device Class ===========

typedef class PCIE_DEVICE_CLASS* PCIE_DEVICE;
class PCIE_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
    // driver descriptor
    int driverFD;
    
    // device mmap
    unsigned char *deviceMap;
    
    // DMA buffer pointers
    unsigned char *dmaBuffer_H2F;
    unsigned char *dmaBuffer_F2H;

    // helper pointers
    CSR_DATA* systemCSR_Read;
    CSR_DATA* systemCSR_Write;
    CSR_DATA* commonCSRs;
    
    // internal methods
    inline CSR_DATA swapEndian(CSR_DATA);
    
  public:
    PCIE_DEVICE_CLASS(PLATFORMS_MODULE);
    ~PCIE_DEVICE_CLASS();
    
    void     Cleanup();
    void     Init();
    void     Uninit();

    // CSR interface
    CSR_DATA ReadSystemCSR();
    void     WriteSystemCSR(CSR_DATA);
    CSR_DATA ReadCommonCSR(CSR_INDEX);
    void     WriteCommonCSR(CSR_INDEX, CSR_DATA);

    // DMA buffers
    unsigned char* GetDMABuffer_H2F()   { return dmaBuffer_H2F; }
    unsigned char* GetDMABuffer_F2H()   { return dmaBuffer_F2H; }
    UINT64         GetDMABufferPA_H2F();
    UINT64         GetDMABufferPA_F2H();

    // Memory translation
    // TODO: make this more general
    UINT64   TranslateV2P(UINT64);

    // Other interfaces
    void     ResetFPGA();
};

#endif
