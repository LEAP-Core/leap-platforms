//
// Copyright (C) 2012 Intel Corporation
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

//
// Integrity / bandwidth tests of PCIe BlueNoC connection.
//

#include <stdio.h>
#include <error.h>
#include <sys/ioctl.h>

#include "asim/syntax.h"
#include "awb/provides/pcie_device.h"


PCIE_DEVICE_TESTS_CLASS::PCIE_DEVICE_TESTS_CLASS(int fd) :
    pcieDev(fd),
    bpb(0)
{
    //
    // Get board info
    //
	tBoardInfo board_info;
	ioctl(pcieDev, BNOC_IDENTIFY, &board_info);

    printf("Board number:     %d\n", board_info.board_number);
	if (board_info.is_active)
    {
        bpb = board_info.bytes_per_beat;

        printf("BlueNoC revision: %d.%d\n", board_info.major_rev, board_info.minor_rev);
        printf("Build number:     %d\n", board_info.build);
        time_t t = board_info.timestamp;
        printf("Timestamp:        %s", ctime(&t));
        printf("Network width:    %d bytes per beat\n", board_info.bytes_per_beat);
        printf("Content ID:       0x%016llx\n", board_info.content_id);
    }
}


bool
PCIE_DEVICE_TESTS_CLASS::Test()
{
    printf("Running PCIe Tests\n\n");

    if (posix_memalign((void**)&outBuf, 128, 256 * 4096) != 0 ||
		posix_memalign((void**)&inBuf, 128, 256 * 4096) != 0)
    {
		fprintf (stderr, "PCIe Device Tests: Failed to memalign I/O buffers: %s\n", strerror(errno));
		exit(EXIT_FAILURE);
	}
	
    // Reset the design outside of the PCIe root complex
    assert(ioctl(pcieDev, BNOC_SOFT_RESET) >= 0);

    // Write a message to the sink
    outBuf[0] = 2;   /* dst node */
    outBuf[1] = 0;   /* src node */
    outBuf[2] = 12;  /* msg length */
    outBuf[3] = 1;   /* don't wait */
    ssize_t result = write(pcieDev, outBuf, max(16, bpb));
    assert(result > 0);
    if (result == 16)
        printf("Success: sent all %0d bytes to the sink\n", result);
    else
        printf("Failure: sent only %0d bytes to the sink\n", result);

    //
    // Bandwidth test: write a block of messages to the sink.
    //
    int num_msgs = 4096; /* 4096 * 256B = 1MB */
    int idx = 0;
    for (int n = 0; n < num_msgs; ++n) {
        outBuf[idx++] = 2;   /* dst node */
        outBuf[idx++] = 0;   /* src node */
        outBuf[idx++] = 252; /* msg length */
        outBuf[idx++] = 0;   /* don't wait */
        for (int i = 0; i < 252; ++i)
        {
            outBuf[idx++] = i;
        }
    }

    idx = 0;
    struct timeval start;
    struct timeval finish;
    gettimeofday(&start, NULL);

    // 1024 iterations = 1 GB
    for (int n = 0; n < 1024; ++n)
    {
        doWrite(pcieDev, outBuf, num_msgs * 256);
        idx += num_msgs * 256;
    }

    gettimeofday(&finish, NULL);
    if (idx == (1024 * num_msgs * 256))
    {
        struct timeval elapsed;
        double sz = 1024.0 * (num_msgs * 256);
        printf("Success: sent all %0d bytes to the sink\n", idx);
        timersub(&finish, &start, &elapsed);
        double t = (1.0 * elapsed.tv_sec) + (0.000001 * elapsed.tv_usec);
        printf(" *** Sent %.1f MB of data in %.2f seconds (%.1f MB/s) \n",
               sz / (1024.0 * 1024.0),
               t,
               sz / (1000000.0 * t));
    }


    //
    // Set the flooder to send messages back, then measure throughput.
    //
    outBuf[0] = 3;    /* dst node */
    outBuf[1] = 0;    /* src node */
    outBuf[2] = 4;    /* msg length */
    outBuf[3] = 1;    /* don't wait */

    // Request 1GB
    UINT64 req_bytes = 1024 * 1024 * 1024;
    UINT64 req_beats = req_bytes / bpb;
    outBuf[4] = req_beats;
    outBuf[5] = req_beats >> 8;
    outBuf[6] = req_beats >> 16;
    outBuf[7] = req_beats >> 24;

    result = write(pcieDev, outBuf, max(8, bpb));
    if (result == -1) {
        perror("PCIe Tests (sending msg)");
        exit(EXIT_FAILURE);
    }
    if (result != max(8, bpb))
    {
        printf("Failure: sent only %0d bytes to the flooder\n", result);
        exit(EXIT_FAILURE);
    }

    UINT64 read_bytes = 0;
    UINT32 errors = 0;

    gettimeofday(&start, NULL);
    while (read_bytes < req_bytes)
    {
        result = read(pcieDev, inBuf, 65536);
        if (result == -1) {
            perror("PCIe Tests (receiving msg)");
            exit(EXIT_FAILURE);
        }

        if (result != 65536)
        {
            printf("Failure: read only %d of %d bytes from the flooder\n",
                   result, 65536);
            exit(EXIT_FAILURE);
        }

        // Validate read data in the first chunk.
        if (read_bytes == 0)
        {
            errors += checkReadValues(4096, req_beats);
        }

        read_bytes += result;
    }
    gettimeofday(&finish, NULL);

    struct timeval elapsed;
    double sz = req_bytes;
    printf("Read all %lld bytes from the flooder (%d errors)\n", read_bytes, errors);
    timersub(&finish,&start,&elapsed);
    double t = (1.0 * elapsed.tv_sec) + (0.000001 * elapsed.tv_usec);
    printf(" *** Received %.1f MB of data in %.2f seconds (%.1f MB/s) \n",
           sz / (1024.0 * 1024.0), t, sz / (1000000.0 * t));

    return true;
}


//
// doWrite --
//     Write buffer in chunks.  The PCIe driver seems to fail when write
//     requests are too large.
//
void
PCIE_DEVICE_TESTS_CLASS::doWrite(
    int fd,
    const unsigned char *buf,
    size_t count)
{
    do
    {
        size_t this_cnt = (count > 65536) ? 65536 : count;
        ssize_t n_written = write(fd, buf, this_cnt);
        if (n_written == -1)
        {
            error(1, errno, "Failed to write to PCIe device");
        }

        if (n_written != this_cnt)
        {
            fprintf(stderr, "Only wrote %d of %d bytes\n", n_written, this_cnt);
            exit(EXIT_FAILURE);
        }

        buf += n_written;
        count -= n_written;
    }
    while (count != 0);
}


//
// Confirm that a read buffer has reasonable values.  Assume the buffer begins
// with a header beat.
//
UINT32
PCIE_DEVICE_TESTS_CLASS::checkReadValues(size_t count, UINT32 beatsToSend)
{
    UINT64 errCnt = 0;

    if ((bpb == 8) || (bpb == 16))
    {
        const UINT64 *beat = (const UINT64*) inBuf;
        const bool bpb16 = (bpb == 16);

        while (count > 0)
        {
            // Header beat encodes length, source and destination
            errCnt += checkValue(*beat++, 0xfc0300);
            if (bpb16)
            {
                errCnt += checkValue(*beat++, 0);
            }

            beatsToSend -= 1;
            count -= bpb;

            for (int i = 0; i < (256 / bpb) - 1; i++)
            {
                UINT64 val = beatsToSend;
                val = (val << 33) | val;
                errCnt += checkValue(*beat++, val);

                if (bpb16)
                {
                    errCnt += checkValue(*beat++, 0);
                }

                beatsToSend -= 1;
                count -= bpb;
            }
        }
    }
    else
    {
        printf("checkReadValues doesn't support %d bytes per beat.  Skipping check.\n", bpb);
    }

    return errCnt;
}


UINT32
PCIE_DEVICE_TESTS_CLASS::checkValue(UINT64 val, UINT64 expect)
{
    if (val != expect)
    {
        fprintf(stderr, " --- read error: expected 0x%llx, found 0x%llx\n", val, expect);
        return 1;
    }

    return 0;
}
