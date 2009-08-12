//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <iostream>
#include <termios.h>
#include <errno.h>
#include <fcntl.h>

#include "asim/provides/physical_channel.h"
#include "asim/provides/umf.h"

using namespace std;

// ==============================================
//            WARNING WARNING WARNING
// This code is swarming with potential deadlocks
// ==============================================

// ============================================
//               Physical Channel              
// ============================================

// constructor: set up hardware partition
PHYSICAL_CHANNEL_CLASS::PHYSICAL_CHANNEL_CLASS(
    PLATFORMS_MODULE p,
    PHYSICAL_DEVICES d) :
        PLATFORMS_MODULE_CLASS(p)
{
  incomingMessage = NULL;

  // open serial device. As it's non-blocking we should hold until we
  // have a physical connection

  serial_fd = open( "/dev/ttyS0", O_RDWR | O_NOCTTY | O_NDELAY); 
    
  if (serial_fd != 0){
    
  }
  struct termios attrib;

  // get serial_fd attribute and set effective i/o speed
  tcgetattr(serial_fd, &attrib);
  
  cfsetospeed(&attrib, B115200); //YYY ndave: this may be too fast. 
  cfsetispeed(&attrib, B115200); 

  //Okay now. we're setup. We need to actually sync with the hardware
  
  fprintf(stderr,"Synchronizing with the hardware\n");
  int pos = 0; UMF_CHUNK v; int i =0 ;
  unsigned char* vptr = (unsigned char *) &v;

  //scheme is pos 0 0xDEADBEEFF0 HW -> SW
  //          pos 1 0x0505CAFE SW -> HW
  //          pos 2 0x08675309 HW -> SW
  while(1){
    if (pos == 0){
      serial_read(vptr,4);
      if(v == 0xDEADBEEF){pos = 1;} else {pos = 0;}// success
    } // end pos == 0
    else if(pos == 1){
      v = 0x0505CAFE;
      serial_write(vptr, 4); // send data
      serial_read(vptr, 4);  // read data
      if(v == 0x08675309){ // handle result
	break;
      } else if (v == 0xDEADBEEF){
	pos = 1;
      } else {
	fprintf(stderr,"NOT GOOD. Received unexpected signal from HW on serial channel");
	pos = 0;
      } // we failed. Retry
    } // end pos == 1
  } // end while

  fprintf(stderr,"Synced");

}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
  // XXX ndave: We should probably kill the serial fd, but termination should do this for us. 
}

// blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::Read(){
  // blocking loop
  while (true){
    // check if message is ready
    if (incomingMessage && !incomingMessage->CanAppend()) {
      // message is ready!
      UMF_MESSAGE msg = incomingMessage;
      incomingMessage = NULL;
      return msg;
    }
    // block-read data from pipe
    readPipe();
  }

  // shouldn't be here
  return NULL;
}

// non-blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::TryRead(){   
 // We must check if there's new data. This will give us more and stop if we're full.
  if(serial_hasdata()){
    readPipe();
  }
  // now see if we have a complete message
  if (incomingMessage && !incomingMessage->CanAppend()){
    UMF_MESSAGE msg = incomingMessage;
    incomingMessage = NULL;
    return msg;
  }
  
  // message not yet ready
  return NULL;
}

// write
void
PHYSICAL_CHANNEL_CLASS::Write(UMF_MESSAGE message){
  // construct header
  unsigned char header[UMF_CHUNK_BYTES];
  message->EncodeHeader(header);

  // write header to pipe
  serial_write(header, UMF_CHUNK_BYTES);

  // write message data to pipe
  // NOTE: hardware demarshaller expects chunk pattern to start from most
  //       significant chunk and end at least significant chunk, so we will
  //       send chunks in reverse order
  message->StartReverseExtract();
  while (message->CanReverseExtract()){
    UMF_CHUNK chunk = message->ReverseExtractChunk();
    serial_write((unsigned char*)&chunk, sizeof(UMF_CHUNK));
  }

  // de-allocate message
  message->Delete();

}

//=========================================================================================

void
PHYSICAL_CHANNEL_CLASS::readPipe(){
  // determine if we are starting a new message
  fprintf(stderr, "entering readPipe\n");
  if (incomingMessage == NULL)    {
    // new message: read header
    unsigned char header[UMF_CHUNK_BYTES];
    serial_read(header, UMF_CHUNK_BYTES);

    // create a new message
    incomingMessage = UMF_MESSAGE_CLASS::New();
    incomingMessage->DecodeHeader(header);
  }
  else if (!incomingMessage->CanAppend()){
    // uh-oh.. we already have a full message, but it hasn't been
    // asked for yet. We will simply not read the pipe, but in
    // future, we might want to include a read buffer.
  }
  else {
    // read in some more bytes for the current message
    unsigned int BLOCK_SIZE = 4; //XXX check me
    unsigned char buf[BLOCK_SIZE];
    int bytes_requested = BLOCK_SIZE;
    if (incomingMessage->BytesUnwritten() < BLOCK_SIZE){
      bytes_requested = incomingMessage->BytesUnwritten();
    }

    if (serial_hasdata()){
      serial_read(buf, bytes_requested);
    }

    // append read bytes into message
    incomingMessage->AppendBytes(bytes_requested, buf);
  }
  fprintf(stderr,"exiting readPipe\n");
}

void PHYSICAL_CHANNEL_CLASS::serial_read(unsigned char *v, unsigned int numBytes){
  int bytes_read = 0; size_t rv =0; int i;
  while(bytes_read < numBytes){
    fprintf(stderr, "starting serial_read");
    rv = read(serial_fd,(void *)(v[bytes_read]), numBytes - bytes_read);
    fprintf(stderr, "read rv: %u", rv);

    if (rv != -1){
      bytes_read += rv;
      for (i=0;i<100000;i++);
    }
    else {
      fprintf(stderr, "NOO!!!! read has a problem");
    }
  }
  fprintf(stderr,"serial_read: ");
    for(int i=0;i<numBytes;i++){
      fprintf(stderr,"%02x", v[i]);
    }
    fprintf(stderr, "\n");
    fprintf(stderr, "exiting serial_read");
}

void PHYSICAL_CHANNEL_CLASS::serial_write(unsigned char *v, unsigned int numBytes){
    // assume we can write data in one shot
    fprintf(stderr,"serial_write: ");
    for(int i=0;i<numBytes;i++){
      fprintf(stderr,"%2x", v[i]);
    }
    fprintf(stderr, "\n");

    int bytes_written = write(serial_fd, (void *) v, numBytes);
    if (bytes_written < numBytes){
      //badness!
      fprintf(stderr, "NOO!!!! we didn't fully write");
    }
}

bool
PHYSICAL_CHANNEL_CLASS::serial_hasdata()
{
    // test for incoming data on physical channel
    struct timeval  timeout;
    int             data_available;
    fd_set          readfds;

    FD_ZERO(&readfds);
    FD_SET(serial_fd, &readfds);

    timeout.tv_sec  = 0;
    timeout.tv_usec = 1;//SELECT_TIMEOUT

    data_available = select(serial_fd + 1, &readfds, NULL, NULL, &timeout);

    if (data_available == -1)
    {
        if (errno == EINTR)
        {
            data_available = 0;
        }
        else
        {
            perror("serial-pipe-device select");
            exit(1);
        }
    }

    if (data_available != 0)
    {
        // incoming! sanity check
        if (data_available != 1 || FD_ISSET(serial_fd, &readfds) == 0)
        {
            cerr << "serial-pipe: activity detected on unknown descriptor" << endl;
            exit(1);
        }

        // yes, data is available
        return true;
    }

    // no fresh data
    return false;
}
