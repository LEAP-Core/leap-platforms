#include <iostream>
#include <unistd.h>
#include "driver-interface.h"

using namespace std;

// ============================================
//               Driver Interface
// ============================================

// takes care of talking to driver and resolving
// endianness issues

DRIVER_INTERFACE_CLASS::DRIVER_INTERFACE_CLASS()
{
    if (pchnl_open_channel(&pchannel) < 0)
    {
        cerr << "driver interface: unable to open driver"
             << endl;
        exit(1);
    }
    cout << "driver interface: channel opened" << endl;
}

DRIVER_INTERFACE_CLASS::~DRIVER_INTERFACE_CLASS()
{
    Uninit();
}

void
DRIVER_INTERFACE_CLASS::Uninit()
{
    pchnl_close_channel(&pchannel);
    cout << "driver interface: channel closed" << endl;
}

CSR_DATA
DRIVER_INTERFACE_CLASS::ReadSystemCSR()
{
    CSR_DATA data = 0;
    if (pchnl_read_csr_sys(&pchannel, &data) < 0)
    {
        cerr << "driver interface: ERROR: ReadSystemCSR() failed" << endl;
        Uninit();
        exit(1);
    }
    return swapEndian(data);
}

void
DRIVER_INTERFACE_CLASS::WriteSystemCSR(
    CSR_DATA data)
{
    if (pchnl_write_csr_sys(&pchannel, swapEndian(data)) < 0)
    {
        cerr << "driver interface: ERROR: WriteSystemCSR() failed" << endl;
        Uninit();
        exit(1);
    }
}

CSR_DATA
DRIVER_INTERFACE_CLASS::ReadCommonCSR(
    CSR_INDEX index)
{
    CSR_DATA data = 0;
    if (pchnl_read_csr_comm(&pchannel, index, &data) < 0)
    {
        cerr << "driver interface: ERROR: ReadCommonCSR() failed" << endl;
        Uninit();
        exit(1);
    }
    return swapEndian(data);
}

void
DRIVER_INTERFACE_CLASS::WriteCommonCSR(
    CSR_INDEX index,
    CSR_DATA data)
{
    if (pchnl_write_csr_comm(&pchannel, index, swapEndian(data)) < 0)
    {
        cerr << "driver interface: ERROR: WriteCommonCSR() failed" << endl;
        Uninit();
        exit(1);
    }
}

CSR_DATA
DRIVER_INTERFACE_CLASS::swapEndian(
    CSR_DATA data)
{
    // this code is only valid for a particular CSR_DATA size
    CSR_DATA retval = ((data & 0x000000FF) << 24) |
                      ((data & 0x0000FF00) << 8)  |
                      ((data & 0x00FF0000) >> 8)  |
                      ((data & 0xFF000000) >> 24);
    return retval;
}
