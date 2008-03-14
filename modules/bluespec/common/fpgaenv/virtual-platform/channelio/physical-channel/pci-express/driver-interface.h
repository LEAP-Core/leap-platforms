#ifndef __DRIVER_INTERFACE__
#define __DRIVER_INTERFACE__

extern "C"
{
#include "libpchnl.h"
}

typedef unsigned int    CSR_DATA;
typedef CSR_DATA        CSR_INDEX;

// ============================================
//               Driver Interface
// ============================================

class DRIVER_INTERFACE_CLASS
{
    private:
        // driver handle
        struct hw_channel pchannel;

        // internal methods
        inline CSR_DATA swapEndian(CSR_DATA);

    public:
        DRIVER_INTERFACE_CLASS();
        ~DRIVER_INTERFACE_CLASS();

        void     Uninit();
        CSR_DATA ReadSystemCSR();
        void     WriteSystemCSR(CSR_DATA);
        CSR_DATA ReadCommonCSR(CSR_INDEX);
        void     WriteCommonCSR(CSR_INDEX, CSR_DATA);
};

#endif
