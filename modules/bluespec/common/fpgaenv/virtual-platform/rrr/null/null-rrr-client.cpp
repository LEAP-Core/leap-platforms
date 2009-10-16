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

#include <iostream>

#include "asim/provides/rrr.h"
#include "asim/provides/model.h" // FIXME should be project

#define CHANNEL_ID  1

using namespace std;

// global link
RRR_CLIENT RRRClient;

// constructor
RRR_CLIENT_CLASS::RRR_CLIENT_CLASS(
    PLATFORMS_MODULE p,
    CHANNELIO    cio) :
        PLATFORMS_MODULE_CLASS(p),
        initialized (0)
{
    // set channelio link
    channelio = cio;

    // set up locks and CVs
    pthread_mutex_init(&bufferLock, NULL);
    pthread_cond_init(&bufferCond, NULL);
}

// destructor
RRR_CLIENT_CLASS::~RRR_CLIENT_CLASS()
{
}

// The monitor thread ID must be set before we start polling.
void
RRR_CLIENT_CLASS::SetMonitorThreadID(pthread_t mon)
{ 
    monitorThreadID = mon;
    initialized = 1;
    return;
}

// make request with response
UMF_MESSAGE
RRR_CLIENT_CLASS::MakeRequest(
    UMF_MESSAGE request)
{
    UMF_MESSAGE response;

    // get serviceID
    UINT32 serviceID = request->GetServiceID();

    // add channelID to request
    request->SetChannelID(CHANNEL_ID);

    // write request message to channel
    channelio->Write(CHANNEL_ID, request);

    //
    // read response (blocking read) from channelio
    // 
    // We need to handle the Monitor/Service thread and the
    // System thread differently.
    //

    if (pthread_self() != monitorThreadID)
    {
        //
        // System Thread: this thread is only allowed to look
        // at the system-thread-return-buffer. If the buffer is
        // empty, then the thread blocks on a condition variable.
        // The CV is global for all services since there is only
        // one System thread, which can be simultaneously blocked
        // on at most one service at any instant.
        //

        // sleep until buffer becomes non-empty
        pthread_mutex_lock(&bufferLock);
        while (systemThreadResponseBuffer.empty())
        {
            pthread_cond_wait(&bufferCond, &bufferLock);
        }
        
        // buffer is not empty, and we have the lock
        response = systemThreadResponseBuffer.front();
        systemThreadResponseBuffer.pop();

        // response is ready, unlock the buffers
        pthread_mutex_unlock(&bufferLock);

        // sanity check: the serviceID of the buffered message
        // MUST be what we are expecting
        ASSERTX(serviceID == response->GetServiceID());
    }
    else
    {
        //
        // Monitor/Service Thread: this thread directly reads
        // (blocking read) messages out of the channel, directs
        // messages for other services into their appropriate input
        // buffers, and triggers the condition variables. It is
        // guaranteed that a message expected by the Monitor/Service
        // thread will never be in an input buffer; it can only be
        // obtained by directly probing the channel.
        //

        // loop until we get a response for our request
        while (true)
        {
            // get a message from channelio
            response = channelio->Read(CHANNEL_ID);

            // check if this is a message for the service that
            // initiated the request
            if (serviceID == response->GetServiceID())
            {
                // we're all set, break out
                break;
            }

            // this message is for a different service, perhaps
            // (actually, most certainly) it is a response that
            // the System thread is blocked on. Enqueue it into
            // the response buffer of the service and release the
            // condition variable
            pthread_mutex_lock(&bufferLock);

            // sanity check: the current code structure guarantees
            // that there can be at most one outstanding message in
            // the response buffer
            ASSERTX(systemThreadResponseBuffer.empty());

            systemThreadResponseBuffer.push(response);

            pthread_cond_broadcast(&bufferCond);
            pthread_mutex_unlock(&bufferLock);
        }
    }

    return response;
}

// make request with no response
void
RRR_CLIENT_CLASS::MakeRequestNoResponse(
    UMF_MESSAGE request)
{
    // add channelID to request
    request->SetChannelID(CHANNEL_ID);

    // write request message to channelio
    channelio->Write(CHANNEL_ID, request);
}

// poll
void
RRR_CLIENT_CLASS::Poll()
{
    if (!initialized)
        return;

    // this method can only be called from the Monitor/Service thread
    ASSERTX(pthread_self() == monitorThreadID);

    // try to read a single message from channelio
    UMF_MESSAGE msg = channelio->TryRead(CHANNEL_ID);

    //
    // If channelio gives us a message, this means the message is a
    // response to a request that the System thread is currently
    // blocked on. It cannot be a response to a Monitor/Service request.
    //
    if (msg != NULL)
    {
        // lock the buffer
        pthread_mutex_lock(&bufferLock);

        // we cannot already have an outstanding response in the response
        // buffer, because the System thread is only allowed to have one
        // outstanding request
        ASSERTX(systemThreadResponseBuffer.empty());

        // put the message into the System thread's buffer
        systemThreadResponseBuffer.push(msg);

        // wake up the System thread and unlock the buffer
        pthread_cond_broadcast(&bufferCond);
        pthread_mutex_unlock(&bufferLock);
    }
}
