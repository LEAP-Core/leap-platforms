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
//#include "bsv_scemi.h"
/*
#define MAXNUM_PCI_BAR 6

#define BSEMU_IOC_MAGIC  'B'
#define BSEMU_IOC_GETDEVICE _IOWR(BSEMU_IOC_MAGIC, 1, BSEMU_SharedData)
#define MY_VENDOR_ID 0xb100
#define MY_DEVICE_ID 0xb5ce
//TODO: ioctl to reset...?
*/
int pcie_dev;
static unsigned char* msg_buf = NULL;

bool   dataPopped;
unsigned char poppedData;
unsigned char epoch_send;
unsigned char epoch_recv;
unsigned char epoch_peek;

static pthread_mutex_t dev_mutex;

bool initd = false;

void serverStart()
{
	pthread_mutex_init(&dev_mutex, NULL);
	pthread_mutex_lock(&dev_mutex);

	srand(time(0));
	epoch_send = epoch_peek = epoch_recv = rand()%64; // both are init'd to 0 at serverside. should be diffent
    dataPopped = 0;
    //fprintf (stderr, "Hello from sever start\n");
    char *dev_file = "/dev/bluenoc_1";
	pcie_dev = open(dev_file, O_RDWR);
	if (pcie_dev < 0) {
		fprintf (stderr, "Error: Failed to open %s: %s\n", dev_file, strerror(errno));
		dev_file = "/dev/bluenoc0";
		pcie_dev = open(dev_file, O_RDWR);
		if (pcie_dev < 0) {
			fprintf (stderr, "Error: Failed to open %s: %s\n", dev_file, strerror(errno));
			exit(EXIT_FAILURE);
		}
	}
	if (posix_memalign((void**)&msg_buf, 128, 4096) != 0) {
		fprintf (stderr, "Error: Failed to memalign msg_buf : %s\n", strerror(errno));
		exit(EXIT_FAILURE);
	}
	
	msg_buf[0] = 0xbb; // init
	msg_buf[1] = 0;
	msg_buf[2] = 0; // msg length
	msg_buf[3] = 1 + (3<<2); // don't wait
//	write(pcie_dev, msg_buf, 4);
//	write(pcie_dev, msg_buf, 4);

	printf( "** Server started!\n" );
	initd = true;
	pthread_mutex_unlock(&dev_mutex);
}

void serverFinish()
{
    close(pcie_dev);
    exit(0);
}

void serverSendSys(const char* byte)
{
	while (!initd);
	pthread_mutex_lock(&dev_mutex);
	int result = 0;
	printf( "** Sending %x\n", *byte);
  //   fprintf (stderr, "serverSendSys\n");
    //fflush(stderr);
		msg_buf[0] = 0xbe; // recv node
		msg_buf[1] = *byte;
		msg_buf[2] = 0; // msg length
		msg_buf[3] = 1 + (epoch_send << 2); // don't wait
		result = write(pcie_dev, msg_buf, 4);
		if ( result != 4 ) {
			fprintf(stderr, "Error: wrote %d bytes to bluenoc_1\n", result );
		}
		epoch_send += 1;
		if ( epoch_send >= (1<<6) ) epoch_send = 0;
		//printf( "** Msg Sent\n" );
	pthread_mutex_unlock(&dev_mutex);
}


// Try to pop some data - this is needed for non-blocking writes
bool serverTestSys() {
	while (!initd);
	pthread_mutex_lock(&dev_mutex);

//	printf( "** Testing\n" );
	msg_buf[0] = 0xbc; // recv node
	msg_buf[1] = 0;
	msg_buf[2] = 0; // msg length
	msg_buf[3] = 1 + (epoch_send << 2); // don't wait
	int result = write(pcie_dev, msg_buf, 4);
	if ( result != 4 ) {
		fprintf(stderr, "Error: wrote %d bytes to bluenoc_1\n", result );
	}
	epoch_send += 1;
  
	unsigned char peekres = 0;
	unsigned char epoch = epoch_peek;
	do {
		result = read(pcie_dev, msg_buf, 4);
		peekres = msg_buf[1];
		epoch = (msg_buf[3]>>2);
		if ( result >= 4 && epoch == epoch_peek )
			printf( "Duplicate read?\n" );
	} while ( result < 4 || epoch == epoch_peek);
//	(result != 4 || msg_buf[0] != 0x98 || epoch == epoch_recv);
	if (result != 4/* || msg_buf[0] != 0x98*/) {
		peekres = 0;
	}
	epoch_peek = epoch;
	
	pthread_mutex_unlock(&dev_mutex);
//	printf( "** Tested %d(size %d, data %x @@ %x,%x)\n", dataPopped, result, poppedData, epoch, msg_buf[0] );
	return peekres;
}

void serverRecvSys(char* byte)
{
	while (!initd);
//	printf( "** Msg Receive requesting\n" );
	pthread_mutex_lock(&dev_mutex);
	msg_buf[0] = 0xbd; // recv node
	msg_buf[1] = 0;
	msg_buf[2] = 0; // msg length
	msg_buf[3] = 1 + (epoch_send << 2); // don't wait
	int result = write(pcie_dev, msg_buf, 4);
	if ( result != 4 ) {
		fprintf(stderr, "Error: wrote %d bytes to bluenoc_1\n", result );
	}
	epoch_send += 1;

//	printf( "** Msg Receiving\n" );
	unsigned char epoch = epoch_recv;
	do {
		result = read(pcie_dev, msg_buf, 4);
		poppedData = msg_buf[1];
		epoch = (msg_buf[3]>>2);
		if ( result == 4 && epoch == epoch_recv )
			printf( "Duplicate read?\n" );
	} while (result != 4 || msg_buf[0] != 0x98 || epoch == epoch_recv); 
	//FIXME : magic num(0x98) in blunoc_core/bluenoc-top.bsv
	epoch_recv = epoch;
	*byte = (char) poppedData;
	printf( "** Msg Received %x\n", poppedData );
	pthread_mutex_unlock(&dev_mutex);
}
/*
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
*/
