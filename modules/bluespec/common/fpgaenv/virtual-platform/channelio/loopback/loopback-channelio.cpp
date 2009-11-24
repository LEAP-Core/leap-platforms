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

#include "asim/provides/channelio.h"

using namespace std;

#define LOCK   { pthread_mutex_lock(&lock);   }
#define UNLOCK { pthread_mutex_unlock(&lock); }

// ============================================
//                 Channel I/O                 
// ============================================

// constructor
CHANNELIO_CLASS::CHANNELIO_CLASS(
    PLATFORMS_MODULE p,
    PHYSICAL_DEVICES d) :
        readReq(false),
        writeReq(false),
        PLATFORMS_MODULE_CLASS(p),
        physicalChannel(this, d)
{
    // set up stations
    for (int i = 0; i < CIO_NUM_CHANNELS; i++)
    {
        // default station type is READ
        stations[i].type = CIO_STATION_TYPE_READ;
        stations[i].module = NULL;
    }

    // initialize mutexes (mutices?)
    pthread_mutex_init(&bufferLock, NULL);
    pthread_mutex_init(&channelLock, NULL);

    CHANNELIO_CLASS::setPTR(this);
}

// destructor
CHANNELIO_CLASS::~CHANNELIO_CLASS()
{
}

// register a station for message delivery
void
CHANNELIO_CLASS::RegisterForDelivery(
    int channel,
    CIO_DELIVERY_STATION module)
{
  stations[channel].type = CIO_STATION_TYPE_DELIVERY;
  stations[channel].module = module;
}

// non-blocking read
UMF_MESSAGE
CHANNELIO_CLASS::TryRead(
    int channel)
{
  UMF_MESSAGE msg = NULL;
  
  // check if a message is already enqueued in read buffer
  pthread_mutex_lock(&bufferLock);
  if (stations[channel].readBuffer.empty() == false)
    {
      msg = stations[channel].readBuffer.front();
      stations[channel].readBuffer.pop();
    }
  pthread_mutex_unlock(&bufferLock);
  
  return msg;
}

// blocking read
UMF_MESSAGE
CHANNELIO_CLASS::Read(
    int channel)
{

    //
    // We will use two locks to implement this functionality.
    // The first lock called channelLock simply guards access to
    // the physical channel layer (and can possibly be transferred
    // to the physical channel code). The second lock, called
    // bufferLock is a fine-grained lock that we use to control
    // access to our internal per-channel buffers.
    //
    // I am NOT convinced that these two locks are sufficient to
    // guarantee correct atomic behavior of channelio under all
    // circumstances. Using a global lock around the Read and Write
    // methods is much safer and easier to reason about, but
    // unfortunately leads to a deadlock situation because of
    // Delivery-type stations (the lock is still held while
    // DeliverMessage is called, which in turn might call Write
    // on us). I think we should get rid of the entire Delivery idea
    // and require all stations to poll us for messages, although
    // this would reduce performance somewhat.
    //

    UMF_MESSAGE msg = NULL;

    // first check if a message is already enqueued in read buffer
    pthread_mutex_lock(&bufferLock);
    if (stations[channel].readBuffer.empty() == false)
    {
        msg = stations[channel].readBuffer.front();
        stations[channel].readBuffer.pop();
    }
    pthread_mutex_unlock(&bufferLock);

    // return if we found a message
    if (msg)
    {
        return msg;
    }

    // loop until we get what we are looking for
    while (true)
    {
        // block-read a message from physical channel
        readReq = true;
        pthread_mutex_lock(&channelLock);
        readReq = false;
        msg = physicalChannel.Read();
        pthread_mutex_unlock(&channelLock);

        // get virtual channel ID of incoming message
        int inchannel = msg->GetChannelID();

        // if this message is for the channel we want, then return it
        if (inchannel == channel)
        {
            return msg;
        }

        // message is for another channel, check type of station
        if (stations[inchannel].type == CIO_STATION_TYPE_READ)
        {
            // enqueue in read buffer
            pthread_mutex_lock(&bufferLock);
            stations[inchannel].readBuffer.push(msg);
            pthread_mutex_unlock(&bufferLock);
        }
        else
        {
            // deliver message to station module
            stations[inchannel].module->DeliverMessage(msg);
        }
    }

    // shouldn't be here
    return NULL;
}

// write
void
CHANNELIO_CLASS::Write(
    int channel,
    UMF_MESSAGE message)
{
    // attach channelID to message
    message->SetChannelID(channel);

    // send to physical channel
    writeReq = true;
    pthread_mutex_lock(&channelLock);
    writeReq = false;
    physicalChannel.Write(message);
    pthread_mutex_unlock(&channelLock);
}

// poll
void
CHANNELIO_CLASS::Poll()
{
    // Yield if a read or write request is trying to get the lock.  On multi-core
    // machines the pool loop can effectively hold the lock and never give it
    // up without this.
    if (readReq || writeReq) return;

    // check if physical channel has a new message
    pthread_mutex_lock(&channelLock);
    UMF_MESSAGE msg = physicalChannel.TryRead();
    pthread_mutex_unlock(&channelLock);

    if (msg != NULL)
    {
        // get virtual channel ID
        int channelID = msg->GetChannelID();

        // if this message is for a read-type station, then enqueue it
        if (stations[channelID].type == CIO_STATION_TYPE_READ)
        {
            pthread_mutex_lock(&bufferLock);
            stations[channelID].readBuffer.push(msg);
            pthread_mutex_unlock(&bufferLock);
        }
        else
        {
            // deliver message to station module immediately
            stations[channelID].module->DeliverMessage(msg);
        }
    }
}


//stuff related to the ugly hack used in the loopback main

CHANNELIO CHANNELIO_CLASS::ptr = 0x0;

void
CHANNELIO_CLASS::setPTR(CHANNELIO a){ptr = a;}

CHANNELIO
CHANNELIO_CLASS::getPTR(){assert(ptr);return ptr;}

// more here in the future
void
CHANNELIO_CLASS::runTest()
{
  printf("CHANNELIO_EXT_CLASS::runTest()\n");
  for(int i = 0; i < 100; i++){
    UMF_MESSAGE message = new UMF_MESSAGE_CLASS;

    message->SetChannelID(0);
    message->SetServiceID(2);
    message->SetMethodID(0);
    message->SetLength(sizeof(UINT32));
    message->StartAppend();
    message->AppendUINT32(0xabcdabcd);

    printf("physicalChannel.Write(message);\n");
    physicalChannel.Write(message);
    UMF_MESSAGE rv = NULL;
    printf("physicalChannel.Read();\n");

    rv = physicalChannel.Read();
    rv->StartExtract();
    printf("%d\n",(rv->GetChannelID()));
    printf("%d\n",(rv->GetServiceID()));
    printf("%d\n",(rv->GetMethodID()));
    printf("%d\n",(rv->GetLength()));
    printf("%x\n",(rv->ExtractUINT32()));

    bool valid =  ((rv->GetChannelID()==0)&&
		   (rv->GetServiceID()==2)&&
		   (rv->GetMethodID()==0)&&
		   (rv->GetLength()==sizeof(UINT32))&&
		   (rv->ExtractUINT32()==0xabcdabcd));

    if(!valid){
      printf("invalid message\ntest failed\n");
      exit(0);
    }
      
  }
}
