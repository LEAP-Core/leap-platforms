#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <iostream>

#include "asim/provides/rrr.h"

using namespace std;

#define CHANNEL_ID    0
#define BC_CHANNEL_ID 2 // for backwards-compatibility

// instantiate global service table; this table will be
// populated by the individual services (also statically
// instantiated) before main().
RRR_SERVICE RRR_SERVER_CLASS::ServiceMap[MAX_SERVICES];
UINT64      RRR_SERVER_CLASS::ServiceValidMask = 0;


// ===========================
//   RRR service base class
// ===========================

// base-class Request() method is for backwards compatibility
// only. This method translates the call to a legacy Request()
// call. Newer server modules will overrride this method and
// handle the UMF_MESSAGE directly
UMF_MESSAGE
RRR_SERVICE_CLASS::Request(
    UMF_MESSAGE message)
{
    // basically we manually de-marshall the message into
    // individual UINT32 arguments and call the legacy
    // Request() method
    int methodID  = message->GetMethodID();

    // de-marshall args place into args array
    int argc = 4;
    UINT32 argv[MAX_ARGS];
    argv[0] = methodID;
    for (int i = 1; i < argc; i++)
    {
        argv[i] = message->ExtractUINT32();
    }

    // de-allocate message
    delete message;

    // invoke legacy Request() method to obtain result
    UINT32 result;
    bool send_result = Request(argv[0], argv[1], argv[2], argv[3], &result);

    // construct a result if required
    if (send_result)
    {
        // create a new channelio message
        message = new UMF_MESSAGE_CLASS(4); // payload = 4 bytes
        message->SetMethodID(methodID);

        // update message data
        message->AppendUINT32(result);

        // return
        return message;
    }

    // no response, return NULL
    return NULL;
}

// legacy-style method for base class should default to an error
bool
RRR_SERVICE_CLASS::Request(
    UINT32 arg0,
    UINT32 arg1,
    UINT32 arg2,
    UINT32 arg3,
    UINT32 *result)
{
    cout << "server: error: base-class legacy Request() method\n";
    exit(1);
}

// ==================================
// Server (dispatcher) static methods    
// ==================================

// register a service
void
RRR_SERVER_CLASS::RegisterService(
    int         serviceid,
    RRR_SERVICE service)
{
    if (isServiceValid(serviceid))
    {
        fprintf(stderr,
            "software server: duplicate serviceID registration: %d\n");
        exit(1);
    }

    // set link in map table
    ServiceMap[serviceid] = service;
    setServiceValid(serviceid);
}

bool
RRR_SERVER_CLASS::isServiceValid(
    int serviceid)
{
    UINT64 mask = UINT64(0x01) << serviceid;
    return ((ServiceValidMask & mask) > 0 ? true : false);
}

void
RRR_SERVER_CLASS::setServiceValid(
    int serviceid)
{
    UINT64 mask = UINT64(0x01) << serviceid;
    ServiceValidMask |= mask;
}

void
RRR_SERVER_CLASS::unsetServiceValid(
    int serviceid)
{
    UINT64 mask = UINT64(0x01) << serviceid;
    ServiceValidMask &= (~mask);
}

// ===========================
//       regular methods
// ===========================

// constructor
RRR_SERVER_CLASS::RRR_SERVER_CLASS(
    PLATFORMS_MODULE p,
    CHANNELIO    cio) :
        PLATFORMS_MODULE_CLASS(p)
{
    channelio = cio;
    Init();
}

// destructor
RRR_SERVER_CLASS::~RRR_SERVER_CLASS()
{
}

// init: all services MUST have registered when this
// method is called
void
RRR_SERVER_CLASS::Init()
{
    // initialize services
    for (int i = 0; i < MAX_SERVICES; i++)
    {
        if (isServiceValid(i))
        {
            // set myself as the PLATFORMS_MODULE parent
            // for all services so that I can chain
            // uninit()s to them
            ServiceMap[i]->Init(this);
        }
    }

    // register with channelio for message delivery
    channelio->RegisterForDelivery(CHANNEL_ID, this);

    // backwards compatibility: also register for delivery
    // on BC channel
    channelio->RegisterForDelivery(BC_CHANNEL_ID, this);
}

// uninit: override
void
RRR_SERVER_CLASS::Uninit()
{
    // reset service map
    for (int i = 0; i < MAX_SERVICES; i++)
    {
        if (isServiceValid(i))
        {
            // no need to explicitly call Uninit() on
            // services, this will happen automatically
            // when we chain the call
            ServiceMap[i] = NULL;
        }
    }
    ServiceValidMask = 0;

    // chain
    PLATFORMS_MODULE_CLASS::Uninit();
}

// accept a delivered message from channelio
void
RRR_SERVER_CLASS::DeliverMessage(
    UMF_MESSAGE message)
{
    // record channelID for backwards compatibility
    int channelID = message->GetChannelID();
    int serviceID = message->GetServiceID();

    // validate serviceID
    if (isServiceValid(serviceID) == false)
    {
        fprintf(stderr, "software server: invalid serviceID: %u\n", serviceID);
        parent->CallbackExit(1);
    }

    // call service and obtain result
    UMF_MESSAGE result = ServiceMap[serviceID]->Request(message);

    // see if we need to respond
    if (result)
    {
        // set serviceID
        result->SetServiceID(serviceID);

        // send to channelio... send on original virtual channel (BC)
        channelio->Write(channelID, result);
    }
}

// poll
void
RRR_SERVER_CLASS::Poll()
{
    // poll each service module
    for (int i = 0; i < MAX_SERVICES; i++)
    {
        if (isServiceValid(i))
        {
            ServiceMap[i]->Poll();
        }
    }
}
