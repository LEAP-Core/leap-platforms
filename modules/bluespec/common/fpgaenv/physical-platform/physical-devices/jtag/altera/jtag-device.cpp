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
#include <fcntl.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#include <iostream>

#include "platforms-module.h"

#include "asim/provides/command_switches.h"
#include "asim/provides/jtag_device.h"

void forkJTAGCommunication() {
    execlp("nios2-terminal", "nios2-terminal", NULL);
}

void establishJTAGConnection(int inpipe, int outpipe) {
  // This serves to flush out any spurious data
  int i = 0;
  char temp;
  int returnVal;
  while(i < UMF_CHUNK_BYTES*2) {
     while((returnVal = read(inpipe, &temp,sizeof(char))) < 1) {}
     i = (temp == i + 65) ? i+1 : 0;
  }
  

}

