#include <iostream>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#include "asim/provides/pci_express_device.h"
#include "asim/provides/pci_express_driver_header.h"

using namespace std;

// ============================================
//              PCI Express Device
// ============================================

PCIE_DEVICE_CLASS::PCIE_DEVICE_CLASS(
    PLATFORMS_MODULE p) :
        PLATFORMS_MODULE_CLASS(p)
{
    // obtain a descriptor for the driver
    driverFD = open("/dev/pchnl", O_RDWR);
    if (driverFD < 0)
    {
        perror("pcie device: unable to open driver");
        exit(1);
    }

    // mmap the CSRs into vm space
    deviceMap = (unsigned char*) mmap(0,
                                      CSR_REGION_SIZE, 
                                      PROT_READ | PROT_WRITE,
                                      MAP_SHARED,
                                      driverFD,
                                      0);
    if (deviceMap < 0)
    {
        perror("pcie device: unable to map CSRs into memory");
        exit(1);
    }

    // setup pointers
    systemCSR_Write = (CSR_DATA*) (deviceMap + SYS_CSR_BASE_OFFSET);
    systemCSR_Read  = (CSR_DATA*) (deviceMap + SYS_CSR_BASE_OFFSET + sizeof(CSR_DATA));
    commonCSRs      = (CSR_DATA*) (deviceMap + COMM_CSR_BASE_OFFSET);

    // reset hardware
    ResetFPGA();
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
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
PCIE_DEVICE_CLASS::Cleanup()
{
    // unmap devices
    munmap(0, CSR_REGION_SIZE);

    // close driver
    close(driverFD);
}

// reset FPGA
void
PCIE_DEVICE_CLASS::ResetFPGA()
{
    ioctl(driverFD, PCHNL_RESET, NULL);

    // TEMPORARY: add a small delay
    for (int i = 0; i < 1000000; i++);
}

// read system CSR
CSR_DATA
PCIE_DEVICE_CLASS::ReadSystemCSR()
{
    return *systemCSR_Read;
}

// write system CSR
void
PCIE_DEVICE_CLASS::WriteSystemCSR(
    CSR_DATA data)
{
    *systemCSR_Write = data;
}

// read common CSR
CSR_DATA
PCIE_DEVICE_CLASS::ReadCommonCSR(
    CSR_INDEX index)
{
    return commonCSRs[index];
}

// write common CSR
void
PCIE_DEVICE_CLASS::WriteCommonCSR(
    CSR_INDEX index,
    CSR_DATA data)
{
    commonCSRs[index] = data;
}

// swap endianness
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

// translate a virtual address to a physical address
UINT64
PCIE_DEVICE_CLASS::TranslateV2P(
    UINT64 virtual_address)
{
    pchnl_req req;
    UINT64    physical_address;

//    req.u.tranx_translate_v2p.va = &virtual_address;
//    req.u.tranx_translate_v2p.pa = &physical_address;

//    ioctl(driverFD, PCHNL_TRANSLATE_V2P, &req);

    return physical_address;
}
