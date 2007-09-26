#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>

#include "software-rrr-server.h"

// extern pointers to RRR service instances
#define ADD_SERVICE(NAME) extern RRR_SERVICE_CLASS* NAME##_service;
#include "master-service-list.rrr"
#undef ADD_SERVICE

// constructor
RRR_SERVER_CLASS::RRR_SERVER_CLASS(
    HASIM_SW_MODULE p,
    CHANNELIO cio)
{
    parent = p;
    channelio = cio;
    Init();
}

// destructor
RRR_SERVER_CLASS::~RRR_SERVER_CLASS()
{
    Uninit();
}

// init
void
RRR_SERVER_CLASS::Init()
{
    // initialize servive map table
    for (int i = 0; i < MAX_SERVICES; i++)
    {
        ServiceMap[i] = NULL;
    }
    n_services = 0;

    // populate service map table by defining a macro and
    // including the service definition file
#define ADD_SERVICE(NAME)                                           \
    {                                                               \
        /* instantiate service */                                   \
        ServiceMap[n_services] = NAME##_service;                    \
        ServiceMap[n_services]->Init(this, n_services);             \
                                                                    \
        /* update service count */                                  \
        n_services++;                                               \
    }

#include "master-service-list.rrr"

#undef ADD_SERVICE
}

// uninit
void
RRR_SERVER_CLASS::Uninit()
{
    // reset service map
    for (int i = 0; i < n_services; i++)
    {
        if (ServiceMap[i])
        {
            ServiceMap[i]->Uninit();
            ServiceMap[i] = NULL;
        }
    }
}

// unpack
void
RRR_SERVER_CLASS::unpack(
    UINT32 src,
    unsigned char dst[])
{
    // unpack UINT32 into byte sequence
    unsigned int mask = 0xFF;
    int i;
    for (i = 0; i < CHANNELIO_PACKET_SIZE; i++)
    {
        unsigned char byte = (mask & src) >> (i * 8);
        dst[i] = (unsigned char)byte;
        mask = mask << 8;
    }
}

// pack
UINT32
RRR_SERVER_CLASS::pack(
    unsigned char dst[])
{
    UINT32 retval = 0;
    int i;
    for (i = 0; i < CHANNELIO_PACKET_SIZE; i++)
    {
        unsigned int byte = (unsigned int)dst[i];
        retval |= (byte << (i * 8));
    }
    return retval;
}

// poll
void
RRR_SERVER_CLASS::Poll()
{
    unsigned char   buf[CHANNELIO_PACKET_SIZE];

    // currently, we only have 1 virtual channel to channelio,
    // and we can only perform blocking reads
    channelio->Read(buf);

    // decode serviceID
    int serviceID = pack(buf);
    if (serviceID >= n_services)
    {
        fprintf(stderr, "software server: invalid serviceID: %u\n", serviceID);
        parent->CallbackExit(1);
    }

    // read args from channelio and place into args array
    int argc = 3;
    UINT32 argv[MAX_ARGS];
    for (int i = 0; i < argc; i++)
    {
        channelio->Read(buf);
        argv[i] = pack(buf);
    }

    // invoke service method to obtain result
    UINT32 result;
    bool send_result = ServiceMap[serviceID]->Request(argv[0], argv[1], argv[2], &result);

    // send result to channelio if this is a value method
    if (send_result)
    {
        unpack(result, buf);
        channelio->Write(buf);
    }

    // poll each service module
    for (int i = 0; i < n_services; i++)
    {
        ServiceMap[i]->Poll();
    }
}

