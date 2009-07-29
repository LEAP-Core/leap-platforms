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

#include "asim/provides/physical_channel.h"

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

  // get serial_fd attribute and set effective i/o speed
  tcgetattr(serial_fd, &attrib);
  
  cfsetospeed(&attrib, B115200); //YYY ndave: this may be too fast. 
  cfsetispeed(&attrib, B115200); 

  // Things should be set now. 
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
  // ndave: We should probably kill the serial fd, but termination should do this for us. 
}

// blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::Read()
{
  //blocking loop
  while(true){
    //do we have a complete message
    if (incomingMessage != NULL && !incomingMessage->CanAppend()){
      // message is ready!
      UMF_MESSAGE msg = incomingMessage;
      incomingMessage = NULL;
      return msg;
    }
    //if not, do a step of reading
    attemptRead();
  }

  // shouldn't be here
  return NULL;
}

// non-blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::TryRead()
{
  // now see if we have a complete message
  if (incomingMessage && !incomingMessage->CanAppend()){
    UMF_MESSAGE msg = incomingMessage;
    incomingMessage = NULL;
    return msg;
  }
  // message not yet ready... see if we can grab more. 
  attemptRead();
  return NULL;
}

// write
void
PHYSICAL_CHANNEL_CLASS::Write(
    UMF_MESSAGE message)
{
  int msglength = message -> GetLength();
  unsigned char data[1024];

  while (msglength > 0){
    // we're just going to dump the data through the serial line. 
    message -> StartExtract();
    int chunklength = (msglength < 1024) ? msglength : 1024;
    message -> ExtractBytes(chunklength, data);
    int x = 0; 
    while (x < chunklength){
      int length =  write(serial_fd, message -> GetMessage(), chunklength - x);
      if (length == -1){
	// error
      }
      x += length;
    } // passed the chunk
    msglength -= chunklength; // reduce amount left to send. 
  }

    message->Delete();
}

void
PHYSICAL_CHANNEL_CLASS::attemptRead(){

  if (incomingMessage != NULL){
    //partial message
    unsigned char chunk[1024]; 
    int readAmount = (message->BytesUnwritten() > 1024) ? message->BytesUnwritten() : 1024;
    int length     = read(serial_fd, &chunk, readAmount);
    message->AppendBytes(length, chunk);
  } else { // no current message
      //try an initial read, to get the initial block  
      UINT32 chunk; 
      int length = read(serial_fd, &chunk, sizeof(UINT32));
      if (length == 0){
	return NULL; // there's not enoguh to make progress. don't bother making a new message
      }
      else if (length == sizeof(UINT32)){
        //got enough to make progress
	incomingMessage = UMF_MESSAGE_CLASS::New();
	incomingMessage->DecodeHeader(data);
      }
      else { 
        // we appear to have read a partial value. Bad. 
      }
  }



  csr_data = pciExpressDevice->ReadCommonCSR(f2hHead);
  chunk = UMF_CHUNK(csr_data);
  

}
