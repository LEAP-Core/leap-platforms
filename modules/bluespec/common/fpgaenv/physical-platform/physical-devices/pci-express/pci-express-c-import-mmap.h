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

#include "platforms-module.h"

// ===============================================
//               PCI-Express Device
// ===============================================

// types for CSR indices and data
#if    (PCIE_CSR_DATA_SIZE == 8)
typedef unsigned char      CSR_DATA;
#elif (PCIE_CSR_DATA_SIZE == 32)
typedef unsigned int       CSR_DATA;
#elif (PCIE_CSR_DATA_SIZE == 64)
typedef unsigned long long CSR_DATA;
#else
#error "invalid PCIE_CSR_DATA_SIZE"
#endif

#if    (PCIE_CSR_IDX_SIZE == 8)
typedef unsigned char      CSR_INDEX;
#elif (PCIE_CSR_IDX_SIZE == 32)
typedef unsigned int       CSR_INDEX;
#elif (PCIE_CSR_IDX_SIZE == 64)
typedef unsigned long long CSR_INDEX;
#else
#error "invalid PCIE_CSR_IDX_SIZE"
#endif    

// =========== The actual Device Class ===========
typedef class PCIE_DEVICE_CLASS* PCIE_DEVICE;
class PCIE_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
    // driver descriptor
    int driverFD;
    
    // device mmap
    unsigned char *deviceMap;
    
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
    void     ResetFPGA();
    CSR_DATA ReadSystemCSR();
    void     WriteSystemCSR(CSR_DATA);
    CSR_DATA ReadCommonCSR(CSR_INDEX);
    void     WriteCommonCSR(CSR_INDEX, CSR_DATA);
};

#endif
