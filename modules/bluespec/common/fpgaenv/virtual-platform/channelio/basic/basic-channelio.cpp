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

// ============================================
//                 Channel I/O                 
// ============================================

// constructor
CHANNELIO_CLASS::CHANNELIO_CLASS(
    HASIM_MODULE p)
{
    parent = p;

    // set up stations
    for (int i = 0; i < CIO_NUM_CHANNELS; i++)
    {
        // default station type is READ
        stations[i].type = CIO_STATION_TYPE_READ;
        stations[i].module = NULL;
    }
}

// destructor
CHANNELIO_CLASS::~CHANNELIO_CLASS()
{
    Uninit();
}

// uninit
void
CHANNELIO_CLASS::Uninit()
{
    physicalChannel.Uninit();
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

// blocking read
UMF_MESSAGE
CHANNELIO_CLASS::Read(
    int channel)
{
    // first check if a message is already enqueued in read buffer
    if (stations[channel].readBuffer.empty() == false)
    {
        UMF_MESSAGE msg = stations[channel].readBuffer.front();
        stations[channel].readBuffer.pop();
        return msg;
    }

    // loop until we get what we are looking for
    while (true)
    {
        // block-read a message from physical channel
        UMF_MESSAGE msg = physicalChannel.Read();

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
            stations[inchannel].readBuffer.push(msg);
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
    physicalChannel.Write(message);
}

// poll
void
CHANNELIO_CLASS::Poll()
{
    // check if physical channel has a new message
    UMF_MESSAGE msg = physicalChannel.TryRead();
    if (msg != NULL)
    {
        // get virtual channel ID
        int channelID = msg->GetChannelID();

        //cout << "channelio: got message via poll: channel " << msg->GetChannelID()
        //     << " service " << msg->GetServiceID() << " method "
        //     << msg->GetMethodID() << " length " << msg->GetLength() << ", ";

        // if this message is for a read-type station, then enqueue it
        if (stations[channelID].type == CIO_STATION_TYPE_READ)
        {
            //cout << "buffering" << endl;
            stations[channelID].readBuffer.push(msg);
        }
        else
        {
            //cout << "delivering" << endl;
            // deliver message to station module immediately
            stations[channelID].module->DeliverMessage(msg);
        }
    }
}

