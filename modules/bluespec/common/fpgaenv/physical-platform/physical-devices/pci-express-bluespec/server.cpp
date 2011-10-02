#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdio.h>
#include <stropts.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

#include "asim/syntax.h"
#include "asim/freelist.h"

#include "asim/provides/umf.h"
#include "asim/provides/pcie_device.h"
#include "bsv_scemi.h"

#define MAXNUM_PCI_BAR 6

typedef struct _BSEMU_bar_type {
  unsigned long long log_addr;
  unsigned long long size;
} BSEMU_bar_type;

typedef struct _BSEMU_SharedData {
  u16 vid; /* vendor id */
  u16 did; /* device id */
  BSEMU_bar_type bar[MAXNUM_PCI_BAR];
} BSEMU_SharedData;

#define BSEMU_IOC_MAGIC  'B'
#define BSEMU_IOC_GETDEVICE _IOWR(BSEMU_IOC_MAGIC, 1, BSEMU_SharedData)
#define MY_VENDOR_ID 0xb100
#define MY_DEVICE_ID 0xb5ce

typedef struct {
  /* Identification and Version Info */
  /* 0x0000 */ UInt32 bluespec_id_lo;
               UInt32 bluespec_id_hi;
  /* 0x0008 */ UInt32 address_map_version;
               UInt32 _padding0;
  /* 0x0010 */ UInt32 scemi_version;
               UInt32 _padding1;
  /* 0x0018 */ UInt32 build_revision;
               UInt32 _padding2;
  /* 0x0020 */ UInt32 build_timestamp;
               UInt32 _padding3[119];
  /* Control */
  /* 0x0200 */ volatile UInt32 command_lo;
               volatile UInt32 command_hi;
               UInt32 _padding4[62];
  /* Status */
  /* 0x0300 */ UInt32 _padding5;
               UInt32 _padding6;
  /* 0x0308 */ volatile UInt32 bar1_rpkt_count;
               UInt32 _padding7;
  /* 0x0310 */ volatile UInt32 bar2_rpkt_count;
               UInt32 _padding8;
  /* 0x0318 */ volatile UInt32 error_rpkt_count;
               UInt32 _padding9;
  /* 0x0320 */ volatile UInt32 bar1_wpkt_count;
               UInt32 _padding10;
  /* 0x0328 */ volatile UInt32 bar2_wpkt_count;
               UInt32 _padding11;
  /* 0x0330 */ volatile UInt32 error_wpkt_count;
               UInt32 _padding12;
} tBar1;

typedef struct {
  /* 0x0000 */ volatile UInt32 sys_lo;
               volatile UInt32 sys_hi;
  /* 0x0008 */ volatile UInt32 disp_lo;
               volatile UInt32 disp_hi;
} tBar2;

int pcie_dev;

tBar1* pBar1;
tBar2* pBar2;

bool   dataPopped;
UInt32 poppedData;

void serverStart()
{
    dataPopped = 0;
    //fprintf (stderr, "Hello from sever start\n");
    char *dev_file = "/dev/bsemu0";
	pcie_dev = open(dev_file, O_RDWR);
	if (pcie_dev < 0) {
		fprintf (stderr, "Error: Failed to open %s: %s\n", dev_file, strerror(errno));
		exit(EXIT_FAILURE);
	}

	BSEMU_SharedData drv_data;
	if (ioctl(pcie_dev,BSEMU_IOC_GETDEVICE,&drv_data) != 0)
	{
		fprintf (stderr, "Error: ioctl: %s\n", strerror(errno));
		close(pcie_dev);
		exit(EXIT_FAILURE);
	}

	if (drv_data.vid != MY_VENDOR_ID || drv_data.did != MY_DEVICE_ID)
	{
		fprintf (stderr, "Error: device has Vendor:Device ID of %x:%x but expected %x:%x\n",
		drv_data.vid, drv_data.did, MY_VENDOR_ID, MY_DEVICE_ID);
		close(pcie_dev);
		exit(EXIT_FAILURE);
	}

	if (drv_data.bar[1].log_addr == 0l || drv_data.bar[2].log_addr == 0l)
	{
		fprintf (stderr, "Error: no BAR1 or BAR2 found on device\n");
		close(pcie_dev);
		exit(EXIT_FAILURE);
	}

	pBar1 = (tBar1*) mmap(NULL, drv_data.bar[1].size, PROT_READ | PROT_WRITE, MAP_SHARED, pcie_dev, getpagesize());
	if (pBar1 == MAP_FAILED)
	{
		fprintf (stderr, "Error: mmap of BAR1: %s\n", strerror(errno));
		close(pcie_dev);
		exit(EXIT_FAILURE);
	}

	pBar2 = (tBar2*) mmap(NULL, drv_data.bar[2].size, PROT_READ | PROT_WRITE, MAP_SHARED, pcie_dev, 2*getpagesize());
	if (pBar2 == MAP_FAILED)
	{
		fprintf (stderr, "Error: mmap of BAR2: %s\n", strerror(errno));
		close(pcie_dev);
		exit(EXIT_FAILURE);
	}

	pBar1->command_lo = 0xdeadbeef;
	pBar1->command_hi = 0xdeadbeef;
        if(DEBUG_PCIE) {
	    printf("id = %llx\n",(((UInt64) pBar1->bluespec_id_hi) << 32) | ((UInt64) pBar1->bluespec_id_lo));
	    printf("version = %lx\n",pBar1->scemi_version);
	    printf("loopback = %llx\n",(((UInt64) pBar1->command_hi) << 32) | ((UInt64) pBar1->command_lo));
	    printf("bar1rpkt = %lu\n",pBar1->bar1_rpkt_count);
	    printf("bar1wpkt = %lu\n\n",pBar1->bar1_wpkt_count);
	   
	}
}

void serverFinish()
{
    close(pcie_dev);
    exit(0);
}



void serverSendSys(const char* byte)
{
  //   fprintf (stderr, "serverSendSys\n");
    fflush(stderr);
    UInt32 extendedByte = (UInt32) (*byte);
    UInt32 wCount;
    UInt32 newWCount;
    do {
        wCount = pBar1->bar2_wpkt_count;
        pBar2->sys_lo = extendedByte;
        //fprintf (stderr, "sent data %x\n", extendedByte);
        newWCount = pBar1->bar2_wpkt_count;
    } while(newWCount == wCount);
}


// Try to pop some data - this is needed for non-blocking writes
bool serverTestSys() {
  if(!dataPopped) {
    poppedData = pBar2->sys_lo;
    dataPopped = (poppedData != 0xdeaddead);
    if(dataPopped) {
      //fprintf (stderr, "test got data %x\n", poppedData);
      //      for(int i = 0; i < 32; i++) {
      //	fprintf (stderr, "pBar2[%d] %x\n", i, *(((UInt32*)pBar2)+i));
      //}
    }
  }

  return dataPopped;
}

void serverRecvSys(char* byte)
{
    if(!dataPopped) {
      do {
        poppedData = pBar2->sys_lo;
      } while (poppedData == 0xdeaddead);
      //fprintf (stderr, "got recv data %x\n", poppedData);
      //for(int i = 0; i < 32; i++) {
      //	fprintf (stderr, "pBar2[%d] %x\n", i, *(((UInt32*)pBar2)+i));
      //}
    }

    dataPopped = 0;
    *byte = (char) poppedData;
}

void serverSendDisp(char byte)
{
    UInt32 extendedByte = (UInt32) byte;
    UInt32 wCount;
    UInt32 newWCount;
    do {
        wCount = pBar1->bar2_wpkt_count;
        pBar2->disp_lo = extendedByte;
        newWCount = pBar1->bar2_wpkt_count;
    } while(newWCount == wCount);
}

void serverRecvDisp()
{
    UInt32 data;
    char* byte;
    do {
        data = pBar2->disp_lo;
    } while (data == 0xdeaddead);

    *byte = (char) data;
    printf("%c",*byte);
}

