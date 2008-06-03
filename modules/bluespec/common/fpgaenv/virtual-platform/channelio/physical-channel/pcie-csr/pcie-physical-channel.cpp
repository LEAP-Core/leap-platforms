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

#define SLEEP for (unsigned long i = 0; i < 0; i++)

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

    // other initialization
    iid = 0;

    // bootstrap: first write indices that I control
    pciExpressDevice->WriteCommonCSR(CSR_F2H_HEAD, f2hHead);
    pciExpressDevice->WriteCommonCSR(CSR_H2F_TAIL, h2fTail);

    // give green signal to FPGA
    pciExpressDevice->WriteSystemCSR(genIID() | 0x50000);

    // wait for green signal from FPGA
    CSR_DATA data;
    do
    {
        data = pciExpressDevice->ReadSystemCSR();
        SLEEP;
    }
    while (data != SIGNAL_GREEN);
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
    while (true)
    {
        // check if message is ready
        if (incomingMessage != NULL && incomingMessage->BytesRemaining() == 0)
        {
            // message is ready!
            UMF_MESSAGE msg = incomingMessage;
            incomingMessage = NULL;
            // cout << "pchannel: reading message: channel "; message->Print(cout);
            return msg;
        }

        // if CSRs are empty, then poll pointers till some data is available
        while (f2hHead == f2hTailCache)
        {
            f2hTailCache = pciExpressDevice->ReadCommonCSR(CSR_F2H_TAIL);
            SLEEP;
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
    // if CSRs are empty, then poll pointers (OPTIONAL)
    if (f2hHead == f2hTailCache)
    {
        f2hTailCache = pciExpressDevice->ReadCommonCSR(CSR_F2H_TAIL);
        SLEEP;
    }

    // now attempt read 
    readCSR();

    // now see if we have a complete message
    if (incomingMessage && incomingMessage->BytesRemaining() == 0)
    {
        UMF_MESSAGE msg = incomingMessage;
        incomingMessage = NULL;
        // cout << "pchannel: try-reading message: channel "; message->Print(cout);
        return msg;
    }

    // message not yet ready
    return NULL;
}

// write
void
PHYSICAL_CHANNEL_CLASS::Write(
    UMF_MESSAGE message)
{
    // block until buffer has sufficient space
    CSR_INDEX h2fTailPlusOne = (h2fTail == CSR_H2F_BUF_END) ? CSR_H2F_BUF_START : (h2fTail + 1);
    while (h2fTailPlusOne == h2fHeadCache)
    {
        h2fHeadCache = pciExpressDevice->ReadCommonCSR(CSR_H2F_HEAD);
        SLEEP;
    }

    // cout << "pchannel: writing message: channel "; message->Print(cout);

    // construct header
    UMF_CHUNK header = message->ConstructHeader();
    CSR_DATA csr_data = CSR_DATA(header);

    // write header to physical channel
    pciExpressDevice->WriteCommonCSR(h2fTail, csr_data);
    h2fTail = h2fTailPlusOne;
    h2fTailPlusOne = (h2fTail == CSR_H2F_BUF_END) ? CSR_H2F_BUF_START : (h2fTail + 1);

    // write message data to physical channel
    // NOTE: hardware demarshaller expects chunk pattern to start from most
    //       significant chunk and end at least significant chunk, so we will
    //       send chunks in reverse order
    message->StartReverseRead();
    while (message->CanReverseRead())
    {
        // this gets ugly - we need to block until space is available
        while (h2fTailPlusOne == h2fHeadCache)
        {
            h2fHeadCache = pciExpressDevice->ReadCommonCSR(CSR_H2F_HEAD);
            SLEEP;
        }

        // space is available, write
        UMF_CHUNK chunk = message->ReverseReadChunk();
        csr_data = CSR_DATA(chunk);

        pciExpressDevice->WriteCommonCSR(h2fTail, csr_data);
        h2fTail = h2fTailPlusOne;
        h2fTailPlusOne = (h2fTail == CSR_H2F_BUF_END) ? CSR_H2F_BUF_START : (h2fTail + 1);
    }

    // sync h2fTail pointer (OPTIONAL)
    pciExpressDevice->WriteCommonCSR(CSR_H2F_TAIL, h2fTail);
    pciExpressDevice->WriteSystemCSR(genIID() | 0x60000);

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

    // cout << "readCSR: read new chunk at F2H head = " << f2hHead
    //      << " data = 0x" << hex << chunk << dec << endl << flush;

    // update head pointer
    f2hHead = (f2hHead == CSR_F2H_BUF_END) ? CSR_F2H_BUF_START : (f2hHead + 1);

    // sync head pointer (OPTIONAL)
    pciExpressDevice->WriteCommonCSR(CSR_F2H_HEAD, f2hHead);
    pciExpressDevice->WriteSystemCSR(genIID() | 0x70000);

    // determine if we are starting a new message
    if (incomingMessage == NULL)
    {
        // new message
        incomingMessage = new UMF_MESSAGE_CLASS();
        incomingMessage->DecodeHeaderFromChunk(chunk);

        UMF_MESSAGE m = incomingMessage;
        // cout << "readCSR: starting new message: channel "; message->Print(cout);
    }
    else if (incomingMessage->BytesRemaining() == 0)
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
    iid = (iid == 255) ? 0 : (iid + 1);
    return (iid << 24);
}
