//
// Copyright XXX
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
#include <sys/signal.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <signal.h>
#include <string.h>
#include <iostream>
#include <termios.h>
#include <errno.h>
#include <fcntl.h>

#include "asim/provides/physical_channel.h"
#include "asim/provides/umf.h"
#include "asim/provides/jtag_device.h"

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
  jtagDevice = new JTAG_DEVICE_CLASS(p);
  initialized = 0;
}

// only initialize the physical channel after enough of the infrastructure has
// been pulled up to ensure that the FPGA got programmed.

void
PHYSICAL_CHANNEL_CLASS::InitLocal() {

  errfd = fopen("./error_messages_phy_channel", "w");
  incomingMessage = NULL;

  // suck starting sequence out of jtag
  int handshakeStage = 0;
  char temp;
  int returnVal;
  int probes = 0;
  int reset = 0;
  char password[8] = {'a','b','c','d','e','f','g','h'};
  char counterword[9] = {'A','B','C','D','E','F','G','H','I'};
  // Reset the handshake
  jtagDevice->Write(counterword+8,sizeof(char));

  while(handshakeStage < UMF_CHUNK_BYTES*2) {
    probes = 0;
     // Probe for data        
    while(!jtagDevice->Probe() && !reset) {
      sleep(1); // 1ms is long enough
      fprintf(errfd, "probing\n");
      fflush(errfd);
      probes++;
      if(probes == 10) {
        probes = 0;
        fprintf(errfd, "reset handshake\n");
        jtagDevice->Write(counterword+8,sizeof(char));
      }
    }
    

     jtagDevice->Read(&temp,sizeof(char));

 
     if(temp == 'a' && !reset) {
       reset = 1;
       jtagDevice->Write(counterword+8,sizeof(char));
     }
     else if(temp == password[handshakeStage]) {
       jtagDevice->Write(counterword+handshakeStage,sizeof(char));
       handshakeStage++;             
     } else if (temp == 'a'){
       // drain them
     } else {
       jtagDevice->Write(counterword+8,sizeof(char));
       handshakeStage = 0;    
       fprintf(errfd, "reset handshake\n");
     }
     fprintf(errfd, "got init char %d\n", temp);
     fflush(errfd);
  }

  fprintf(errfd, "got starting sequence\n");
  fflush(errfd);
  initialized = 1;
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
  // we should probably trap the signal as well to gracefully kill our child
}

// blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::Read(){
  // blocking loop
  if(!initialized) {
    InitLocal();
  }

  fprintf(errfd,"In read\n");    
  fflush(errfd);
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

  if(!initialized) {
    InitLocal();
  }

    
  fflush(errfd);    
  if(jtagDevice->Probe()) {
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
  if(!initialized) {
    InitLocal();
  }

  // construct header
  unsigned char header[UMF_CHUNK_BYTES];
  unsigned char mod_header[UMF_CHUNK_BYTES*2];
  message->EncodeHeader(header);

  msg_count_out++;
  fprintf(errfd,"attempting to write msg %d of length %d: %x\n", msg_count_out,message->GetLength(),*header);    
  
  for (int i = 0; i < UMF_CHUNK_BYTES*2; i++) {
     if (i % 2 == 0) {
        mod_header[i] = (header[i/2] & 15) + 64 ;
     } else {
        mod_header[i] = ((header[i/2] >> 4) & 15) + 64;
     }
  }        

  //write header to pipe
  jtagDevice->Write((const char *)mod_header, UMF_CHUNK_BYTES*2);

  // write message data to pipe
  // NOTE: hardware demarshaller expects chunk pattern to start from most
  //       significant chunk and end at least significant chunk, so we will
  //       send chunks in reverse order
  message->StartReverseExtract();
  while (message->CanReverseExtract()){
    UMF_CHUNK chunk = message->ReverseExtractChunk();
    unsigned char* chunk_bytes;;
    unsigned char mod_chunk[UMF_CHUNK_BYTES*2];
    chunk_bytes = (unsigned char*) &chunk;
    fprintf(errfd,"attempting to write %x\n",chunk);    
    for (int i = 0; i < UMF_CHUNK_BYTES*2; i++) {
       if (i % 2 == 0) {
          mod_chunk[i] = (chunk_bytes[i/2] & 15) + 64 ;
       } else {
          mod_chunk[i] = ((chunk_bytes[i/2] >> 4) & 15) + 64;
       }
    }        
    jtagDevice->Write((const char*)mod_chunk, UMF_CHUNK_BYTES*2);
  }

  // de-allocate message
  delete message;
  fflush(errfd);
}

//=========================================================================================

void
PHYSICAL_CHANNEL_CLASS::readPipe(){
  // determine if we are starting a new message
  fprintf(errfd, "entering readPipe\n");
  fflush(errfd);
  if (incomingMessage == NULL)    {
    // new message: read header
    unsigned char header[UMF_CHUNK_BYTES];
    // If we have no data to beginwith, bail.

    msg_count_in++;
    fprintf(errfd, "readPipe forming header: %d\n", msg_count_in);

    for(int i = 0; i <  UMF_CHUNK_BYTES*2; i++) {
        char temp;
      int returnVal;
      while((returnVal = jtagDevice->Read(&temp,sizeof(char))) < 1) {} // Block :(
      header[i/2] = ((temp%16)*16)+(header[i/2]/16);
    }

    // create a new message
    incomingMessage = new UMF_MESSAGE_CLASS;
    incomingMessage->DecodeHeader(header);
  }
  else if (!incomingMessage->CanAppend()){
    // uh-oh.. we already have a full message, but it hasn't been
    // asked for yet. We will simply not read the pipe, but in
    // future, we might want to include a read buffer.
  }
  else {
    // read in some more bytes for the current message
    // we will read exactly one chunk
    unsigned char buf[UMF_CHUNK_BYTES]; 
    int bytes_requested = UMF_CHUNK_BYTES;
    for(int i = 0; i <  UMF_CHUNK_BYTES*2; i++) {
      char temp;
      int returnVal;
      while((returnVal = jtagDevice->Read(&temp,sizeof(char))) < 1) {} // Block :(
      buf[i/2] = (buf[i/2]/16) + ((temp%16)*16);
    }

    fprintf(errfd, "readPipe chunk: %x\n",*((int*)buf));
    

    // This is not correct, perhaps
    if (incomingMessage->BytesUnwritten() < UMF_CHUNK_BYTES){
      bytes_requested = incomingMessage->BytesUnwritten();
    }

    // append read bytes into message
    incomingMessage->AppendBytes(bytes_requested, buf);
  }
  fprintf(errfd,"exiting readPipe\n");
  fflush(errfd);
}


