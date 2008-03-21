#ifndef __PHYSICAL_CHANNEL__
#define __PHYSICAL_CHANNEL__

#include "asim/provides/umf.h"
#include "asim/provides/pci_express_device.h"
#include "asim/provides/physical_platform.h"

// ============================================
//     PCI-Express Debugger Physical Channel              
// ============================================

class PHYSICAL_CHANNEL_CLASS: public HASIM_MODULE_CLASS
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
        void Main();

    public:
        PHYSICAL_CHANNEL_CLASS(HASIM_MODULE, PHYSICAL_DEVICES);
        ~PHYSICAL_CHANNEL_CLASS();
        void        Uninit();

        UMF_MESSAGE Read();             // blocking read
        UMF_MESSAGE TryRead();          // non-blocking read
        void        Write(UMF_MESSAGE); // write
};

#endif
