//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#include <iostream>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 
#include <termios.h>
#include <pty.h>
#include <utmp.h>
#include <pthread.h>

#include "platforms-module.h"

#include "asim/provides/command_switches.h"
#include "asim/provides/jtag_device.h"

// ============================================
//           Serial Physical Device
// ============================================

void * ProbeHW(void *args) {
  int output = *(((int**)args)[0]);
  int *killThreads = ((int**)args)[1];
  while(!(*killThreads)) {
    char *eol = "\r\n";
    write(output, eol, 2); 
    usleep(100000); // every 100ms
  }
  return NULL;
}

void * RemoveBlanks(void *args) {
  int output = *(((int**)args)[0]);
  int input = *(((int**)args)[1]);
  int *killThreads = ((int**)args)[2];
  FILE *errfd = ((FILE**)args)[3];
  char buf;
  fprintf(errfd,"Blank thread alive %d %d %p %p %p\n", output,input,killThreads,errfd,args);
  fflush(errfd);
  while(!(*killThreads)) {
     read(input, &buf, 1);
     if(buf > 40) {
       write(output,&buf,1);
     } else {
       fprintf(errfd,"got junk byte %d \n", buf);
       fflush(errfd);
     }
  }
  return NULL;
}

void * XMDWriter(void *args) {
  int output = *(((int**)args)[0]);
  int *killThreads = ((int**)args)[1];
  FILE *errfd = ((FILE**)args)[2];
  // Now, write terminal command to XMD
  const char termCmd[] = "xclean\n\r\nverbose 3\r\nterminal -jtag_uart_server 4444\n\r\n";       
  const char termCmd2[] = "\r\n";       
  fprintf(errfd, "Try to write xmd cmd %d...\n", sizeof(termCmd));
    
  write(output, termCmd, sizeof(termCmd));

  while(!(*killThreads)) {
    write(output, termCmd2, sizeof(termCmd2));
    usleep(1000);
  }

}




// constructor: set up hardware partition
JTAG_DEVICE_CLASS::JTAG_DEVICE_CLASS(
    PLATFORMS_MODULE p) :
        PLATFORMS_MODULE_CLASS(p)
{
  // nothing to do here
}

void
JTAG_DEVICE_CLASS::Init()
{

  killThreads = 0;

  // kickoff xmd

  // open serial device. As it's non-blocking we should hold until we
  // have a physical connection
  errfd = fopen("./error_messages_jtag_device", "w");
  xmdfd = fopen("./error_messages_xmd", "w");

  //spawn a process
  if (pipe(parent_to_XMD) < 0)
  {
      parent->CallbackExit(1);
  }

  
  pid_XMD = fork();
  if (pid_XMD == 0)
  {
        // child
        close(parent_to_XMD[1]);

        dup2(parent_to_XMD[0], fileno(stdin));
        dup2(fileno(xmdfd), fileno(stdout));  // dump output to log
        dup2(fileno(xmdfd), fileno(stderr));  // dump output to log

        // make incoming fd non-blocking

        fprintf(errfd, "Launching nios2-terminal\n");
        fprintf(errfd, "stdin is a tty %d\n", isatty(fileno(stdin)));
        fflush(errfd);  
        // Each jtag channel will need some special sauce from 
        // a particular vendor...
        execlp("xmd", "xmd", NULL);
  }

  // parent
  close(parent_to_XMD[0]);


  // Kick off threads to service XMD.  It needs a reader and a writer

  void **argsXMDWriter = (void **)malloc(3*sizeof(void*));    
  argsXMDWriter[0] = (void*)(parent_to_XMD+1);
  argsXMDWriter[1] = (void*)(&killThreads);
  argsXMDWriter[2] = (void*)errfd;    

  pthread_create(&XMDWriterThread, NULL, &XMDWriter, argsXMDWriter);
  

  fprintf(errfd, "Started xmd...\n");
  fflush(errfd);

  // Open a socket to the xmd
  
  int portno, n;
  struct sockaddr_in serv_addr;
  struct hostent *server;
  
  
  portno = 4444; // Magic port number
  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0) {
    fprintf(errfd,"ERROR opening socket");
  }
  server = gethostbyname("localhost");
  if (server == NULL) {
    fprintf(errfd,"ERROR, no such host\n");
    parent->CallbackExit(1);
  }
  bzero((char *) &serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  bcopy((char *)server->h_addr, 
	(char *)&serv_addr.sin_addr.s_addr,
	server->h_length);
  serv_addr.sin_port = htons(portno);
  // May need to spin for a while until xmd wakes up
  int retry = 0;
  
  while (connect(sockfd,(sockaddr*)&serv_addr,sizeof(sockaddr)) < 0) {
    sleep(2);
    fprintf(errfd,"ERROR connecting, retry %d\n", retry);
    if(retry > 10) {
      parent->CallbackExit(1);
    }
    retry++; 
  }

  // Create thread to poll XMD
  void **args = (void **)malloc(2*sizeof(void*));    
  args[0] = (void*)(&sockfd);
  args[1] = (void*)(&killThreads);
  
  pthread_create(&pollThread, NULL, &ProbeHW, args);
    

  if(pipe(jtag_to_blank) < 0) {
    fprintf(errfd,"failed to create blank cleaner pipe\n");
    fflush(errfd);
    parent->CallbackExit(1);
  }


  void **argsBlankRemove = (void**)malloc(4*sizeof(void*));    
  argsBlankRemove[0] = (void*)(jtag_to_blank+1);
  argsBlankRemove[1] = (void*)&sockfd;
  argsBlankRemove[2] = (void*)&killThreads;
  argsBlankRemove[3] = (void*)errfd;    
  
  pthread_create(&blankRemoveThread, NULL, &RemoveBlanks, argsBlankRemove);
    
  input = jtag_to_blank[0];
  output = sockfd; 

  fprintf(errfd, "Device intiailization complete...\n");
  fflush(errfd);
}

// destructor
JTAG_DEVICE_CLASS::~JTAG_DEVICE_CLASS()
{
    // cleanup
    Cleanup();
}

// override default chain-uninit method because
// we need to do something special
void
JTAG_DEVICE_CLASS::Uninit()
{
    // do basic cleanup
    Cleanup();

    // call default uninit so that we can continue
    // chain if necessary
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup: close the pipe.  The other side will exit.
void
JTAG_DEVICE_CLASS::Cleanup()
{
  // Tear down threads, XMD, and open pipes
  killThreads = 1; // kill all threads
  pthread_join(pollThread, NULL);
  pthread_join(XMDWriterThread, NULL);
  pthread_join(blankRemoveThread, NULL);
  close(sockfd);
  fclose(errfd);
  fclose(xmdfd);
  kill(pid_XMD,SIGTERM);
  close(parent_to_XMD[1]);
}

// probe pipe to look for fresh data
bool
JTAG_DEVICE_CLASS::Probe()
{
  fd_set readFile;
  struct timeval time = {0,0};  
  FD_ZERO(&readFile);
  FD_SET(input, &readFile); 
  
  select(input+1,&readFile,NULL,NULL, &time);

  //select says we're okay ?
  if(FD_ISSET(input,&readFile)) {
    return 1;
  } else {
    return 0;
  }
}

// blocking read
int
JTAG_DEVICE_CLASS::Read(
    char* buf,
    int bytes_requested)
{
  fprintf(errfd,"trying to read %d bytes\n", bytes_requested);
  int i = 0, error = 0;
  char *eol = "\r\n";
  //write(output, &eol, 2);
  fflush(errfd);
  return read(input,buf,bytes_requested);  
}

// write
int
JTAG_DEVICE_CLASS::Write(
    const char* buf,
    int bytes_requested)
{
  fprintf(errfd,"trying to write %d bytes\n", bytes_requested);
  fflush(errfd);
  int retval = write(output, buf, bytes_requested);
  char *eol = "\r\n";
  write(output, eol, 2);
  fprintf(errfd,"Write complete\n");
  fflush(errfd);
  // flush request;
  return retval;
}



