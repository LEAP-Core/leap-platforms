#ifndef __PCI_EXPRESS_DEVICE__
#define __PCI_EXPRESS_DEVICE__

#include "hasim-module.h"

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
class PCIE_DEVICE_CLASS: public HASIM_MODULE_CLASS
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
        PCIE_DEVICE_CLASS(HASIM_MODULE);
        ~PCIE_DEVICE_CLASS();

        void     Cleanup();
        void     Uninit();
        CSR_DATA ReadSystemCSR();
        void     WriteSystemCSR(CSR_DATA);
        CSR_DATA ReadCommonCSR(CSR_INDEX);
        void     WriteCommonCSR(CSR_INDEX, CSR_DATA);
};

#endif
