#include <iostream>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "asim/provides/pci_express_device.h"
#include "asim/provides/pci_express_driver_header.h"

using namespace std;

#define SLEEP for (unsigned long i = 0; i < 0; i++)

// ============================================
//              PCI Express Device
// ============================================

PCIE_DEVICE_CLASS::PCIE_DEVICE_CLASS()
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
}

PCIE_DEVICE_CLASS::~PCIE_DEVICE_CLASS()
{
    Uninit();
}

void
PCIE_DEVICE_CLASS::Uninit()
{
    // unmap devices
    munmap(0, CSR_REGION_SIZE);

    // close driver
    close(driverFD);
}

CSR_DATA
PCIE_DEVICE_CLASS::ReadSystemCSR()
{
    SLEEP;
    return swapEndian(*systemCSR_Read);
}

void
PCIE_DEVICE_CLASS::WriteSystemCSR(
    CSR_DATA data)
{
    SLEEP;
    *systemCSR_Write = swapEndian(data);
}

CSR_DATA
PCIE_DEVICE_CLASS::ReadCommonCSR(
    CSR_INDEX index)
{
    SLEEP;
    return swapEndian(commonCSRs[index]);
}

void
PCIE_DEVICE_CLASS::WriteCommonCSR(
    CSR_INDEX index,
    CSR_DATA data)
{
    SLEEP;
    commonCSRs[index] = swapEndian(data);
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
