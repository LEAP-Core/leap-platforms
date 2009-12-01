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
    // cache links to useful physical devices
    pciExpressDevice = d->GetPCIExpressDevice();

    // initialize pointers
    f2hHead      = CSR_F2H_BUF_START;
    f2hTailCache = CSR_F2H_BUF_START;
    h2fHeadCache = CSR_H2F_BUF_START;
    h2fTail      = CSR_H2F_BUF_START;

    CSR_DATA data;
    do
    {
        // other initialization
        iid = 0;

        // give green signal to FPGA
        pciExpressDevice->WriteSystemCSR(genIID() | (OP_START << 16));

        // wait for green signal from FPGA
        UINT32 trips = 0;
        do
        {
            data = pciExpressDevice->ReadSystemCSR();
            trips = trips + 1;
        }
        while ((data != SIGNAL_GREEN) && (trips < 1000000));

        if (data != SIGNAL_GREEN)
        {
            // Gave up on green.  Reset again and restart the sequence.
            pciExpressDevice->ResetFPGA();
        }
    }
    while (data != SIGNAL_GREEN);

    // update pointers
    pciExpressDevice->WriteSystemCSR(genIID() | (OP_UPDATE_F2HHEAD << 16) | (f2hHead << 8));
    pciExpressDevice->WriteSystemCSR(genIID() | (OP_UPDATE_H2FTAIL << 16) | (h2fTail << 8));

    pthread_mutex_init(&channelLock, NULL);
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
}

// blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::Read()
{
    // blocking loop
    pthread_mutex_lock(&channelLock);
    while (true)
    {
        // check if message is ready
        if (incomingMessage && !incomingMessage->CanAppend())
        {
            // message is ready!
            UMF_MESSAGE msg = incomingMessage;
            incomingMessage = NULL;
            pthread_mutex_unlock(&channelLock);
            return msg;
        }

        // if CSRs are empty, then poll pointers till some data is available
        while (f2hHead == f2hTailCache)
        {
            f2hTailCache = pciExpressDevice->ReadCommonCSR(CSR_F2H_TAIL);
        }

        // read some data from CSRs
        readCSR();
    }

    // shouldn't be here
    return NULL;
}

// non-blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::TryRead()
{
    pthread_mutex_lock(&channelLock);

    // if CSRs are empty, then poll pointers (OPTIONAL)
    if (f2hHead == f2hTailCache)
    {
        f2hTailCache = pciExpressDevice->ReadCommonCSR(CSR_F2H_TAIL);
    }

    // now attempt read 
    readCSR();

    // now see if we have a complete message
    if (incomingMessage && !incomingMessage->CanAppend())
    {
        UMF_MESSAGE msg = incomingMessage;
        incomingMessage = NULL;
        pthread_mutex_unlock(&channelLock);
        return msg;
    }

    // message not yet ready
    pthread_mutex_unlock(&channelLock);
    return NULL;
}

// write
void
PHYSICAL_CHANNEL_CLASS::Write(
    UMF_MESSAGE message)
{
    pthread_mutex_lock(&channelLock);

    // block until buffer has sufficient space
    CSR_INDEX h2fTailPlusOne = (h2fTail == CSR_H2F_BUF_END) ? CSR_H2F_BUF_START : (h2fTail + 1);
    while (h2fTailPlusOne == h2fHeadCache)
    {
        h2fHeadCache = pciExpressDevice->ReadCommonCSR(CSR_H2F_HEAD);
    }

    // construct header
    UMF_CHUNK header = message->EncodeHeader();
    CSR_DATA csr_data = CSR_DATA(header);

    // write header to physical channel
    pciExpressDevice->WriteCommonCSR(h2fTail, csr_data);
    h2fTail = h2fTailPlusOne;
    h2fTailPlusOne = (h2fTail == CSR_H2F_BUF_END) ? CSR_H2F_BUF_START : (h2fTail + 1);

    // write message data to physical channel
    // NOTE: hardware demarshaller expects chunk pattern to start from most
    //       significant chunk and end at least significant chunk, so we will
    //       send chunks in reverse order
    message->StartReverseExtract();
    while (message->CanReverseExtract())
    {
        // this gets ugly - we need to block until space is available
        while (h2fTailPlusOne == h2fHeadCache)
        {
            h2fHeadCache = pciExpressDevice->ReadCommonCSR(CSR_H2F_HEAD);
        }

        // space is available, write
        UMF_CHUNK chunk = message->ReverseExtractChunk();
        csr_data = CSR_DATA(chunk);

        pciExpressDevice->WriteCommonCSR(h2fTail, csr_data);
        h2fTail = h2fTailPlusOne;
        h2fTailPlusOne = (h2fTail == CSR_H2F_BUF_END) ? CSR_H2F_BUF_START : (h2fTail + 1);
    }

    // sync h2fTail pointer. It is OPTIONAL to do this immediately, but we will do it
    // since this is probably the response to a request the hardware might be blocked on
    pciExpressDevice->WriteSystemCSR(genIID() | (OP_UPDATE_H2FTAIL << 16) | (h2fTail << 8));

    pthread_mutex_unlock(&channelLock);

    // de-allocate message
    delete message;
}

// read one CSR's worth of unread data
void
PHYSICAL_CHANNEL_CLASS::readCSR()
{
    UMF_CHUNK chunk;
    CSR_DATA csr_data;

    // check cached pointers to see if we can actually read anything
    if (f2hHead == f2hTailCache)
    {
        return;
    }

    // read in one CSR
    csr_data = pciExpressDevice->ReadCommonCSR(f2hHead);
    chunk = UMF_CHUNK(csr_data);

    // update head pointer
    f2hHead = (f2hHead == CSR_F2H_BUF_END) ? CSR_F2H_BUF_START : (f2hHead + 1);

    // sync head pointer (OPTIONAL)
    pciExpressDevice->WriteSystemCSR(genIID() | (OP_UPDATE_F2HHEAD << 16) | (f2hHead << 8));

    // determine if we are starting a new message
    if (incomingMessage == NULL)
    {
        // new message
        incomingMessage = new UMF_MESSAGE_CLASS;
        incomingMessage->DecodeHeader(chunk);
    }
    else if (!incomingMessage->CanAppend())
    {
        // uh-oh.. we already have a full message, but it hasn't been
        // asked for yet. We will simply not read the pipe, but in
        // future, we might want to include a read buffer.
    }
    else
    {
        // read in some more bytes for the current message
        incomingMessage->AppendChunk(chunk);
    }
}

// generate a new Instruction ID
CSR_DATA
PHYSICAL_CHANNEL_CLASS::genIID()
{
    assert(sizeof(CSR_DATA) >= 4);
    iid = (iid + 1) % 256;
    return (iid << 24);
}
