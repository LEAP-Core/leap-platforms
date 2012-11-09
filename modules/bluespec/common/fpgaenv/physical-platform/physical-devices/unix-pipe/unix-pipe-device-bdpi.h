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

// Hack to get UMF_CHUNK_BYTES.  Can't use normal search hierarchy since the
// BDPI module is compiled by Bluespec.
#define AWB_DEFS_ONLY
#include "../../sw/include/asim/provides/umf.h"
#undef AWB_DEFS_ONLY

/* pipe I/O happens at the granularity of "chunks",
 * but to reduce overheads we physically do selects, reads
 * and writes at the granularity of "blocks" */
#define BDPI_CHUNK_BYTES    UMF_CHUNK_BYTES

#define PIPE_NULL           1

#define MAX_OPEN_CHANNELS   32

#define STDIN             0
#define STDOUT            1
#define DESC_HOST_2_FPGA  100
#define DESC_FPGA_2_HOST  101
#define BLOCK_SIZE        UMF_CHUNK_BYTES
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

// Returns 129 useful bits.  The first 128 bits are data.  The next
// bit is set for PIPE_NULL (no new data).
void pipe_read(unsigned int* resultptr, unsigned char handle);

// Return 1 if can write, 0 if can not.
unsigned char pipe_can_write(unsigned char handle);
void pipe_write(unsigned char handle, unsigned int* data);

#endif
