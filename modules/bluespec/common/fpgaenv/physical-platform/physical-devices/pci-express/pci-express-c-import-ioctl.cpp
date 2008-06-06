#include <iostream>
#include <unistd.h>

extern "C"
{
#include "libpchnl.h"
}

#include "asim/provides/pci_express_device.h"

using namespace std;

// ============================================
//              PCI Express Device
// ============================================

// takes care of talking to driver and resolving
// endianness issues

PCIE_DEVICE_CLASS::PCIE_DEVICE_CLASS(
    HASIM_MODULE p) :
        HASIM_MODULE_CLASS(p)
{
    if (pchnl_open_channel(&pchannel) < 0)
    {
        cerr << "pcie device: unable to open driver" << endl;
        exit(1);
    }
}

PCIE_DEVICE_CLASS::~PCIE_DEVICE_CLASS()
{
    Cleanup();
}

// override default chain-uninit method because
// we need to do something special
void
PCIE_DEVICE_CLASS::Uninit()
{
    Cleanup();

    // call default uninit so that we can continue
    // chain if necessary
    HASIM_MODULE_CLASS::Uninit();
}

void
PCIE_DEVICE_CLASS::Cleanup()
{
    pchnl_close_channel(&pchannel);
}

CSR_DATA
PCIE_DEVICE_CLASS::ReadSystemCSR()
{
    CSR_DATA data = 0;
    if (pchnl_read_csr_sys(&pchannel, &data) < 0)
    {
        cerr << "pcie device: ERROR: ReadSystemCSR() failed" << endl;
        Uninit();
        exit(1);
    }
    return data;
}

void
PCIE_DEVICE_CLASS::WriteSystemCSR(
    CSR_DATA data)
{
    if (pchnl_write_csr_sys(&pchannel, data) < 0)
    {
        cerr << "pcie device: ERROR: WriteSystemCSR() failed" << endl;
        Uninit();
        exit(1);
    }
}

CSR_DATA
PCIE_DEVICE_CLASS::ReadCommonCSR(
    CSR_INDEX index)
{
    CSR_DATA data = 0;
    if (pchnl_read_csr_comm(&pchannel, index, &data) < 0)
    {
        cerr << "pcie device: ERROR: ReadCommonCSR() failed" << endl;
        Uninit();
        exit(1);
    }
    return data;
}

void
PCIE_DEVICE_CLASS::WriteCommonCSR(
    CSR_INDEX index,
    CSR_DATA data)
{
    if (pchnl_write_csr_comm(&pchannel, index, data) < 0)
    {
        cerr << "pcie device: ERROR: WriteCommonCSR() failed" << endl;
        Uninit();
        exit(1);
    }
}

CSR_DATA
PCIE_DEVICE_CLASS::swapEndian(
    CSR_DATA data)
{
    // this code is only valid for a particular CSR_DATA size
    CSR_DATA retval = ((data & 0x000000FF) << 24) |
                      ((data & 0x0000FF00) << 8)  |
                      ((data & 0x00FF0000) >> 8)  |
                      ((data & 0xFF000000) >> 24);
    return retval;
}
