#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdio.h>
#include <stropts.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <bluenoc.h>
#include <poll.h>
#include <pthread.h>

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
static unsigned char* read_buf = NULL;

static pthread_mutex_t dev_mutex;
pthread_t readthread;
bool readthread_do;
bool initd = false;

bool dataPopped = false;
unsigned char poppedData;

unsigned int send_idx = 0;

void *readThread(void *param) {
        char sequenceNumber = 0; 

	while (readthread_do) {
		while (dataPopped) sleep(0);
		//printf( "** Attempting Read %x!\n", poppedData );

		int result = read(pcie_dev, read_buf, 4);
		//printf( "** Read len %d!\n", result );
		if ( result != 4 ) {
		  printf("Read result was %d", result);
		  continue;
		}

		if((read_buf[0] & 0xff) != (sequenceNumber&0xff)) {
 		    printf( "** Bad sequence %x Read %x %x %x %x!\n", sequenceNumber, read_buf[0], read_buf[1], read_buf[2], read_buf[3]);	 
		    continue;
		}
		
		sequenceNumber = (sequenceNumber + 1) & 0xff;

	        //printf( "** Read %x %x %x %x!\n", read_buf[0], read_buf[1], read_buf[2], read_buf[3]);

		if(read_buf[3] != 1) {continue;} // flush out debug...

		pthread_mutex_lock(&dev_mutex);
		dataPopped = true;
		poppedData = read_buf[1];
		
		pthread_mutex_unlock(&dev_mutex);
	}
}

void printBoardInfo() {
    tBoardInfo board_info;
    ioctl(pcie_dev,BNOC_IDENTIFY,&board_info);

        printf("  Board number:     %d\n", board_info.board_number);
        if (board_info.is_active) {
	  time_t t = board_info.timestamp;
	  printf("  BlueNoC revision: %d.%d\n", board_info.major_rev, board_info.minor_rev);
	  printf("  Build number:     %d\n", board_info.build);
	  printf("  Timestamp:        %s", ctime(&t));
	  printf("  Network width:    %d bytes per beat\n", board_info.bytes_per_beat);
	  printf("  Content ID:       %llx\n", board_info.content_id);
	}
}

void serverStart()
{

        int res;
	pthread_mutex_init(&dev_mutex, NULL);

	dataPopped = false;
	char *dev_file = "/dev/bluenoc_1";
	pcie_dev = open(dev_file, O_RDWR);
	if (pcie_dev < 0) {
		fprintf (stderr, "Error: Failed to open %s: %s\n", dev_file, strerror(errno));
		exit(EXIT_FAILURE);
	}
	
	res = ioctl(pcie_dev,BNOC_DEACTIVATE);
	if(res < 0) {
	    	fprintf (stderr, "Error: Failed to deactivate %s: %s\n", dev_file, strerror(errno));
		exit(EXIT_FAILURE);
	}

	res = ioctl(pcie_dev,BNOC_REACTIVATE);
	if(res < 0) {
	    	fprintf (stderr, "Error: Failed to reactivate %s: %s\n", dev_file, strerror(errno));
		exit(EXIT_FAILURE);
	}


      	if (posix_memalign((void**)&msg_buf, 128, 4096) != 0
		||posix_memalign((void**)&read_buf, 128, 4096) != 0) {
		fprintf (stderr, "Error: Failed to memalign msg_buf : %s\n", strerror(errno));
		exit(EXIT_FAILURE);
	}
	
	msg_buf[0] = 0x01; // init
	msg_buf[1] = 0;
	msg_buf[2] = 0; // msg length
	msg_buf[3] = 1; // don't wait
	int wres = write(pcie_dev, msg_buf, 4);
	send_idx = 3;

	printf( "** Server started!\n" );
	initd = true;
	readthread_do = true;
	int rc = pthread_create(&readthread, NULL, readThread, NULL);
}

void serverFinish()
{
	readthread_do = false;
	pthread_join(readthread, NULL);
	close(pcie_dev);
	free(msg_buf);
	free(read_buf);
	exit(0);
}


void serverSendSys(const char* byte)
{
	while (!initd);
	
	//pthread_mutex_lock(&dev_mutex);
	
	int result = 0;
	msg_buf[0] = 0x0; // recv node
	msg_buf[1] = *byte;
	msg_buf[2] = 0; // msg length
	msg_buf[3] = 1 + (send_idx << 2); // don't wait
	result = write(pcie_dev, msg_buf, 4);
	//printf( "Send %x %x\n", *byte, send_idx );

	if ( result != 4 ) {
		fprintf(stderr, "Error: wrote %d bytes to bluenoc_1\n", result );
	}
	send_idx += 1;
	if ( send_idx >= (1<<6) ) send_idx = 1;
	//pthread_mutex_unlock(&dev_mutex);
}

bool serverTestSys() {
	while (!initd);
	if ( dataPopped ) return true;
	else return false;
}

void serverRecvSys(char* byte)
{
	while (!initd);

	//printf( "Attempting Rd %x\n", *byte );
	while (!dataPopped) sleep(0);

	unsigned char ret = 0;
	pthread_mutex_lock(&dev_mutex);
	dataPopped = false;
	*byte = poppedData;
	//	printf( "Rd %x\n", *byte );
	pthread_mutex_unlock(&dev_mutex);
}
