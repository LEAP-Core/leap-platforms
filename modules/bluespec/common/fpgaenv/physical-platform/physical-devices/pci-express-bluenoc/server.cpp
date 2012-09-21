#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdio.h>
#include <stropts.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

#include <poll.h>

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

unsigned int testcount = 0;

static pthread_mutex_t dev_mutex;

bool initd = false;

void serverStart()
{
	pthread_mutex_init(&dev_mutex, NULL);
//	pthread_mutex_lock(&dev_mutex);

	srand(time(0));
	epoch_send = epoch_peek = epoch_recv = 32; // both are init'd to 0 at serverside. should be diffent
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
	msg_buf[3] = 1; // don't wait
	write(pcie_dev, msg_buf, 4);
	write(pcie_dev, msg_buf, 4);

	printf( "** Server started!\n" );
	initd = true;
//	pthread_mutex_unlock(&dev_mutex);
}

void serverFinish()
{
    close(pcie_dev);
    exit(0);
}

void serverSendSys(const char* byte)
{
	while (!initd);
	printf( "** Sending %x\n", *byte);
//	pthread_mutex_lock(&dev_mutex);
	printf( "** Sending Start %x\n", *byte);
	
	struct pollfd p;
	p.fd = pcie_dev;
	p.events = POLLOUT;
	int pres = poll(&p, 1, 0);
	if ( !(p.revents & POLLOUT) )
		printf ( "Write blocked!\n" );

	int result = 0;
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
//	pthread_mutex_unlock(&dev_mutex);
	printf( "** Msg Sent\n" );
}

unsigned char peekedVal = 0;
unsigned char peeked = 0;
unsigned int peekcount = 0;
bool serverTestSys() {
	while (!initd);
//	printf( "** Testing\n" );
//	pthread_mutex_lock(&dev_mutex);
	bool retVal = false;


	struct pollfd p;
	p.fd = pcie_dev;
	p.events = POLLIN;// | POLLPRI;
	p.revents = 0;
	int pres = poll(&p, 1, 0);
	if ( pres > 0 && (p.revents & POLLIN))
		retVal = true;

	printf( "** Testing Start %d, %x\n", retVal, p.revents );

	int result = 0;
	if ( retVal ) {
		unsigned char peekres = 0;
		unsigned char epoch = epoch_recv;
		unsigned char magic = 0xcc;
		result = read(pcie_dev, msg_buf, 4);
		magic = msg_buf[0];

		epoch = (msg_buf[3]>>2);
		if ( epoch_recv == epoch || magic == 0xcc || result != 4 ) {
			peeked = 0;
			retVal = false;
		} else if (magic == 0x97){
			peeked = 1;
			peekedVal = msg_buf[1];
			retVal = true;
		}
	}
//	pthread_mutex_unlock(&dev_mutex);
	if (retVal == true ) {
		printf( "** Tested true @ %d, %x\n", peekcount, p.revents);
		peekcount = 0;
	} else {
		peekcount++;
	}
	printf( "** Tested Results %d\n", result );
//	printf( "** Tested %d\n", peeked );
	return retVal;
}

void serverRecvSys(char* byte)
{
	while (!initd);
	printf( "** Msg Receive requesting\n" );
//	pthread_mutex_lock(&dev_mutex);
	printf( "** Msg Receive Start\n" );
	
	struct pollfd p;
	p.fd = pcie_dev;
	p.events = POLLIN;
	int pres = poll(&p, 1, 0);
	if ( pres <= 0 || !(p.revents & (POLLIN|POLLRDNORM)) )
		printf( "Read not ready?\n" );

	unsigned char peekres = 0;
	unsigned char epoch = epoch_recv;
	unsigned char magic = 0xcc;
	int result = 0;
	if (peeked) {
		*byte = peekedVal;
	} else {
		do {
			printf( "** Msg Reading\n" );
			result = read(pcie_dev, msg_buf, 4);
			magic = msg_buf[0];
			epoch = (msg_buf[3]>>2);
			*byte = msg_buf[1];
		} while ( epoch == epoch_recv || magic != 0x97 || result != 4 );
		epoch_recv = epoch;
	}
//	pthread_mutex_unlock(&dev_mutex);
	printf( "** Msg Received %x\n", poppedData );
	testcount = 0;
}
/*
// Try to pop some data - this is needed for non-blocking writes
bool serverTestSys() {
	while (!initd);
//	printf( "** Testing\n" );
	pthread_mutex_lock(&dev_mutex);
//	printf( "** Testing Start\n" );

	msg_buf[0] = 0xbc; // recv node
	msg_buf[1] = 0;
	msg_buf[2] = 0; // msg length
	msg_buf[3] = 1 + (epoch_send << 2); // don't wait
	int result = write(pcie_dev, msg_buf, 4);
	if ( result != 4 ) {
		fprintf(stderr, "Error: wrote %d bytes to bluenoc_1\n", result );
	}
	epoch_send += 1;
	
//	printf( "** Sent Test Req\n" );
  
	unsigned char peekres = 0;
	unsigned char epoch = epoch_peek;
	do {
		result = read(pcie_dev, msg_buf, 4);
		peekres = msg_buf[1];
		epoch = (msg_buf[3]>>2);
		if ( result == 4 && epoch == epoch_peek )
			printf( "Duplicate peek?\n" );
	} while (result != 4 || msg_buf[0] != 0x98 || epoch == epoch_peek);
	epoch_peek = epoch;
	
	pthread_mutex_unlock(&dev_mutex);
//	printf( "** Tested %d(size %d, data %x @@ %x,%x)\n", dataPopped, result, poppedData, epoch, msg_buf[0] );
	testcount += 1;
	if ( testcount%1024 == 0 ) {
		printf( "%d tests!\n", testcount );
	}
	return peekres;
}
*/
/*
void serverRecvSys(char* byte)
{
	while (!initd);
	printf( "** Msg Receive requesting\n" );
	pthread_mutex_lock(&dev_mutex);
	printf( "** Msg Receive Start\n" );
	msg_buf[0] = 0xbd; // recv node
	msg_buf[1] = 0;
	msg_buf[2] = 0; // msg length
	msg_buf[3] = 1 + (epoch_send << 2); // don't wait
	int result = write(pcie_dev, msg_buf, 4);
	if ( result != 4 ) {
		fprintf(stderr, "Error: wrote %d bytes to bluenoc_1\n", result );
	}
	epoch_send += 1;

	printf( "** Msg Receiving\n" );
	unsigned char epoch = epoch_recv;
	do {
		result = read(pcie_dev, msg_buf, 4);
		poppedData = msg_buf[1];
		epoch = (msg_buf[3]>>2);
		if ( result == 4 && epoch == epoch_recv )
			printf( "Duplicate read?\n" );
		if ( msg_buf[0] != 0x97 )
			printf( "Not read result?! %x %x %x %x\n", msg_buf[0], msg_buf[1], msg_buf[2], msg_buf[3] );

	} while (result != 4 || msg_buf[0] != 0x97 || epoch == epoch_recv); 
	//FIXME : magic num(0x98) in blunoc_core/bluenoc-top.bsv
	epoch_recv = epoch;
	*byte = (char) poppedData;
	pthread_mutex_unlock(&dev_mutex);
	printf( "** Msg Received %x\n", poppedData );
	testcount = 0;
}
*/
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
