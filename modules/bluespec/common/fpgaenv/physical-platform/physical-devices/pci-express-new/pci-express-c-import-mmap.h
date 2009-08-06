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
