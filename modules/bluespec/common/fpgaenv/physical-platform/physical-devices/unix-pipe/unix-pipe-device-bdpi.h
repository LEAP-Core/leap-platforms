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

#ifndef __UNIX_PIPE_BDPI__
#define __UNIX_PIPE_BDPI__

#include <sys/select.h>

/* pipe I/O happens at the granularity of "chunks",
 * but to reduce overheads we physically do selects, reads
 * and writes at the granularity of "blocks" */
#define BDPI_CHUNK_BYTES    4

#define PIPE_NULL           0xFFFFFFFF00000000
#define MAX_OPEN_CHANNELS   32

#define STDIN             0
#define STDOUT            1
#define DESC_HOST_2_FPGA  100
#define DESC_FPGA_2_HOST  101
#define BLOCK_SIZE        4
#define SELECT_TIMEOUT    0

typedef struct _Channel
{
    int     open;
    fd_set  readfds;
    int     tableIndex;

    /* input buffer */
    unsigned char   inputBuffer[BLOCK_SIZE];
    int     ibHead;
    int     ibTail;

    struct _Channel *prev;
    struct _Channel *next;

} Channel;

/* interface methods */
unsigned char pipe_open(unsigned char programID);
unsigned long long pipe_read(unsigned char handle);
void pipe_write(unsigned char handle, unsigned int data);

#endif
