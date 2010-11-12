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
  int     child_to_parent[2];
  int     parent_to_child[2];

  incomingMessage = NULL;

  // open serial device. As it's non-blocking we should hold until we
  // have a physical connection
  errfd = fopen("./error_messages", "w");


  //spawn a process
  if (pipe(child_to_parent) < 0 || pipe(parent_to_child) < 0)
  {
      parent->CallbackExit(1);
  }

  pid = fork();
  if (pid == 0)
  {
        // child
        close(child_to_parent[0]);
        close(parent_to_child[1]);

        dup2(parent_to_child[0], fileno(stdin));
        dup2(child_to_parent[1], fileno(stdout));

        fprintf(errfd, "Lunaching nios2-terminal\n"); 
        execlp("nios2-terminal", "nios2-terminal", NULL);
    }
    else
    {
        // parent
        close(child_to_parent[1]);
        close(parent_to_child[0]);
        input = child_to_parent[0];
        output = parent_to_child[1];

    }

  int i = 0;
  char temp;
  int returnVal;
  while(i < UMF_CHUNK_BYTES*2) {
     while((returnVal = read(input, &temp,sizeof(char))) < 1) {}
     i = (temp == i + 65) ? i+1 : 0;
  }
  
  fprintf(errfd, "get starting sequence\n");
  
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
  // we should probably trap the signal as well to gracefully kill our child
   kill(pid,SIGTERM);
   close(input);
   close(output);
}

// blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::Read(){
  // blocking loop
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
  fd_set readFile;
  struct timeval time = {0,0};  

  FD_ZERO(&readFile);
  FD_SET(input, &readFile); 
  
  select(input+1,&readFile,NULL,NULL, &time);

  //select says we're okay
  if(FD_ISSET(input,&readFile)) {
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
  write(output,(const char *)mod_header, UMF_CHUNK_BYTES*2);

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
    write(output,(const char*)mod_chunk, UMF_CHUNK_BYTES*2);
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
      while((returnVal = read(input,&temp,sizeof(char))) < 1) {} // Block :(
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
      while((returnVal = read(input,&temp,sizeof(char))) < 1) {} // Block :(
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


