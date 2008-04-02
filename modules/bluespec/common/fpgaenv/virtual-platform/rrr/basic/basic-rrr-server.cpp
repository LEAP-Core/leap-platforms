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

#include "basic-rrr-server.h"

using namespace std;

#define CHANNEL_ID  0

// instantiate global service table; this table will be
// populated by the individual services (also statically
// instantiated) before main().
RRR_SERVICE RRR_SERVER_CLASS::ServiceMap[MAX_SERVICES];
UINT64      RRR_SERVER_CLASS::ServiceValidMask = 0;

// ===========================
//       static methods    
// ===========================

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
    HASIM_MODULE p,
    CHANNELIO    cio) :
        HASIM_MODULE_CLASS(p)
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
            // set myself as the HASIM_MODULE parent
            // for all services so that I can chain
            // uninit()s to them
            ServiceMap[i]->Init(this);
        }
    }

    // register with channelio for message delivery
    channelio->RegisterForDelivery(CHANNEL_ID, this);
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
    HASIM_MODULE_CLASS::Uninit();
}

// accept a delivered message from channelio
void
RRR_SERVER_CLASS::DeliverMessage(
    UMF_MESSAGE message)
{
    int serviceID = message->GetServiceID();
    int methodID  = message->GetMethodID();

    // validate serviceID
    if (isServiceValid(serviceID) == false)
    {
        fprintf(stderr, "software server: invalid serviceID: %u\n", serviceID);
        parent->CallbackExit(1);
    }

    // read args from channelio and place into args array
    int argc = 4;
    UINT32 argv[MAX_ARGS];
    argv[0] = methodID;
    for (int i = 1; i < argc; i++)
    {
        argv[i] = message->ExtractUINT32();
    }

    // we have extracted everything we need from the message,
    // so we can de-allocate it now. TODO: in future, services
    // will be passed the entire message, and they will
    // de-allocate it themselves.
    delete message;

    // invoke service method to obtain result
    UINT32 result;
    bool send_result = ServiceMap[serviceID]->Request(argv[0], argv[1], argv[2], argv[3], &result);

    // send result to channelio if this is a value method
    if (send_result)
    {
        // create a new channelio message
        UMF_MESSAGE message = new UMF_MESSAGE_CLASS(4); // payload = 4 bytes
        message->SetServiceID(serviceID);
        message->SetMethodID(methodID);

        // update message data
        message->AppendUINT32(result);

        // send to channelio
        channelio->Write(CHANNEL_ID, message);
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

