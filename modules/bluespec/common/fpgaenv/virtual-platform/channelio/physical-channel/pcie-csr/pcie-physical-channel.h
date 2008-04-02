#ifndef __PHYSICAL_CHANNEL__
#define __PHYSICAL_CHANNEL__

#include "asim/provides/umf.h"
#include "asim/provides/pci_express_device.h"
#include "asim/provides/physical_platform.h"

// ============================================
//               Physical Channel              
// ============================================

class PHYSICAL_CHANNEL_CLASS: public HASIM_MODULE_CLASS
{
    private:
        // links to useful physical devices
        PCIE_DEVICE pciExpressDevice;

        // physical channel state
        CSR_INDEX f2hHead;
        CSR_INDEX f2hTailCache;
        CSR_INDEX h2fHeadCache;
        CSR_INDEX h2fTail;

        // incomplete incoming read message
        UMF_MESSAGE incomingMessage;

        // instruction ID
        CSR_DATA iid;

        // internal methods
        void     readCSR();
        CSR_DATA genIID();

    public:
        PHYSICAL_CHANNEL_CLASS(HASIM_MODULE, PHYSICAL_DEVICES);
        ~PHYSICAL_CHANNEL_CLASS();

        UMF_MESSAGE Read();             // blocking read
        UMF_MESSAGE TryRead();          // non-blocking read
        void        Write(UMF_MESSAGE); // write
};

#endif
