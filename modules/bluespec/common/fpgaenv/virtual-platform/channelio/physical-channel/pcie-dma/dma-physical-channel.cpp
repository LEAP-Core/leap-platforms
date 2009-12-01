#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mman.h>
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

    // all of this module's code assumes UMF_CHUNK fits within 64 bits
    if (sizeof(UMF_CHUNK) > 8)
    {
        ASIMERROR("UMF_CHUNK must fit within 64 bits");
        CallbackExit(1);
    }

    // allocate page-aligned buffers and pin them down
    UINT32 page_size = getpagesize();

    // sanity check for page size
    if (page_size != (UINT32(0x01) << PAGE_OFFSET_BITS))
    {
        ASIMERROR("page size mismatch");
        CallbackExit(1);
    }
 
    if (posix_memalign((void **)&h2fBuffer, page_size, page_size) != 0)
    {
        perror("posix_memalign");
        CallbackExit(1);
    }

    // h2fBuffer = (UINT64*) pciExpressDevice->GetDMABuffer_H2F();

    bzero((void *)h2fBuffer, page_size);    

    // if (mlock((const void *)h2fBuffer, page_size) != 0)
    // {
    //     perror("mlock");
    //     CallbackExit(1);
    // }

    if (posix_memalign((void **)&f2hBuffer, page_size, page_size) != 0)
    {
        perror("posix_memalign");
        CallbackExit(1);
    }

    // f2hBuffer = (UINT64*) pciExpressDevice->GetDMABuffer_F2H();

    bzero((void *)f2hBuffer, page_size);

    // if (mlock((const void *)f2hBuffer, page_size) != 0)
    // {
    //     perror("mlock");
    //     CallbackExit(1);
    // }

    //
    // Address Translation
    //

    UINT64 h2fBufferPA = pciExpressDevice->TranslateV2P(UINT64(h2fBuffer));
    UINT64 f2hBufferPA = pciExpressDevice->TranslateV2P(UINT64(f2hBuffer));

    // UINT64 h2fBufferPA = pciExpressDevice->GetDMABufferPA_H2F();
    // UINT64 f2hBufferPA = pciExpressDevice->GetDMABufferPA_F2H();

    //
    // set common buffer size
    // we'll store one UMF_CHUNK within a 64-bit memory word in order
    // to avoid an additional marshalling/demarshalling step on the FPGA
    //
    bufferSize = page_size / sizeof(UINT64);
        
    // initialize indices
    f2hHead      = 0;
    f2hTailCache = 0;
    h2fHeadCache = 0;
    h2fTail      = 0;

    // try to initialize FPGA. If necessary, reset the FPGA, rinse and repeat
    CSR_DATA data;
    do
    {
        // initialize unique IID
        iid = 0;

        // first write indices that I control
        pciExpressDevice->WriteCommonCSR(CSR_F2H_HEAD, f2hHead);
        pciExpressDevice->WriteCommonCSR(CSR_H2F_TAIL, h2fTail);

        // send buffer size, physical addresses, etc. to hardware
        // FIXME: all addresses are hard-wired UINT64
        UINT64 lo_mask = 0x0FFFFFFFF;

        pciExpressDevice->WriteCommonCSR(CSR_H2F_ADDR_LO, UINT32(h2fBufferPA & lo_mask));
        pciExpressDevice->WriteCommonCSR(CSR_H2F_ADDR_HI, UINT32(h2fBufferPA >> 32));

        pciExpressDevice->WriteCommonCSR(CSR_F2H_ADDR_LO, UINT32(f2hBufferPA & lo_mask));
        pciExpressDevice->WriteCommonCSR(CSR_F2H_ADDR_HI, UINT32(f2hBufferPA >> 32));

        // give green signal to FPGA
        pciExpressDevice->WriteSystemCSR(GenIID() | (OP_START << 16));

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
    pciExpressDevice->WriteSystemCSR(GenIID() | (OP_UPDATE_F2HHEAD << 16) | (f2hHead));
    pciExpressDevice->WriteSystemCSR(GenIID() | (OP_UPDATE_H2FTAIL << 16) | (h2fTail));

    // set leaky bucket parameters
    pciExpressDevice->WriteSystemCSR(GenIID() | (OP_SET_MAX_BUCKET   << 16) | 5);
    pciExpressDevice->WriteSystemCSR(GenIID() | (OP_SET_MAX_THROTTLE << 16) | 32);

    pthread_mutex_init(&channelLock, NULL);
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
    Cleanup();
}

// uninit
void
PHYSICAL_CHANNEL_CLASS::Uninit()
{
    Cleanup();
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
PHYSICAL_CHANNEL_CLASS::Cleanup()
{
    if (f2hBuffer)
    {
        free(f2hBuffer);
    }

    if (h2fBuffer)
    {
        free(h2fBuffer);
    }
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

        // read some data from buffer
        ReadF2HBuffer();
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
        UINT32 temp = pciExpressDevice->ReadSystemCSR();
    }

    // now attempt read 
    ReadF2HBuffer();

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
    while (h2fHeadCache == ((h2fTail + 1) % bufferSize))
    {
        h2fHeadCache = pciExpressDevice->ReadCommonCSR(CSR_H2F_HEAD);
    }

    // construct header and write to H2F buffer
    UMF_CHUNK header = message->EncodeHeader();

    // zero-extend chunk to UINT64
    h2fBuffer[h2fTail] = UINT64(header);
    h2fTail = (h2fTail + 1) % bufferSize;

    // write message data to physical channel
    // NOTE: hardware demarshaller expects chunk pattern to start from most
    //       significant chunk and end at least significant chunk, so we will
    //       send chunks in reverse order
    message->StartReverseExtract();
    while (message->CanReverseExtract())
    {
        // this gets ugly - we need to block until space is available
        while (h2fHeadCache == ((h2fTail + 1) % bufferSize))
        {
            h2fHeadCache = pciExpressDevice->ReadCommonCSR(CSR_H2F_HEAD);
        }

        // space is available, write
        UMF_CHUNK chunk = message->ReverseExtractChunk();

        // zero-extend chunk to UINT64
        h2fBuffer[h2fTail] = UINT64(chunk);
        h2fTail = (h2fTail + 1) % bufferSize;
    }

    // sync h2fTail pointer. It is OPTIONAL to do this immediately, but we will do it
    // since this is probably the response to a request the hardware might be blocked on
    pciExpressDevice->WriteSystemCSR(GenIID() | (OP_UPDATE_H2FTAIL << 16) | (h2fTail));

    pthread_mutex_unlock(&channelLock);

    // de-allocate message
    delete message;
}

// read one chunk's worth of unread data from the F2H buffer
void
PHYSICAL_CHANNEL_CLASS::ReadF2HBuffer()
{
    UMF_CHUNK chunk;

    // check cached pointers to see if we can actually read anything
    if (f2hHead == f2hTailCache)
    {
        return;
    }

    // read in one chunk (truncate from UINT64)
    chunk = UMF_CHUNK(f2hBuffer[f2hHead]);
    f2hHead = (f2hHead + 1) % bufferSize;

    // sync head pointer (OPTIONAL)
    pciExpressDevice->WriteSystemCSR(GenIID() | (OP_UPDATE_F2HHEAD << 16) | (f2hHead));

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
PHYSICAL_CHANNEL_CLASS::GenIID()
{
    assert(sizeof(CSR_DATA) >= 4);
    iid = (iid + 1) % 256;
    return (iid << 24);
}
