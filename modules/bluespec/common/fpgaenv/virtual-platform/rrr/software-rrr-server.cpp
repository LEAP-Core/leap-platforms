#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>

#include "software-rrr-server.h"

/* this is the main HAsim software server */

/* service map */
Service ServiceMap[MAX_SERVICES];
int     n_services;

/* internal methods */
static void init()
{
    int i;
    n_services = 0;

    /* initialize service table by defining a
     * macro and including the service definition
     * file */
#define ADD_SERVICE(name)                                   \
    {                                                       \
        /* first generate function prototypes */            \
        void    name##_init(char *);                        \
        UINT32  name##_request(UINT32, UINT32, UINT32);     \
                                                            \
        /* now fill in service table */                     \
        ServiceMap[n_services].ID       =   n_services;     \
        ServiceMap[n_services].params   =   3;              \
        ServiceMap[n_services].init     =   name##_init;    \
        ServiceMap[n_services].main     =   NULL;           \
        ServiceMap[n_services].request  =   name##_request; \
                                                            \
        /* update service count */                          \
        n_services++;                                       \
    }

#include "global-service-list.rrr"

#undef ADD_SERVICE

    /* initialize individual services */
    for (i = 0; i < n_services; i++)
    {
        ServiceMap[i].init(ServiceMap[i].stringID);
        fprintf(stderr, "RRR server: registered service: %s\n",
                ServiceMap[i].stringID);
    }
}

static void unpack(UINT32 src, unsigned char dst[])
{
    /* unpack UINT32 into byte sequence */
    unsigned int mask = 0xFF;
    int i;
    for (i = 0; i < CHANNELIO_PACKET_SIZE; i++)
    {
        unsigned char byte = (mask & src) >> (i * 8);
        dst[i] = (unsigned char)byte;
        mask = mask << 8;
    }
}

static UINT32 pack(unsigned char dst[])
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

/* main */
int main()
{
    unsigned char   buf[CHANNELIO_PACKET_SIZE];
    int             nbytes;
    UINT32          command;

    /* the server side is fully serialized and has no
     * notion of virtual channels. It simply picks up
     * one request from ChannelIO, ships it off to the
     * service function, waits for the service function
     * to complete, and returns the result to STDOUT.
     * The client side can perform whatever virtualization
     * it chooses to */
    init();

    /* go into an infinite loop, scanning stdin for commands */
    while ((nbytes = read(STDIN, buf, CHANNELIO_PACKET_SIZE)) != 0)
    {
        int argc;
        int i;
        UINT32 argv[MAX_ARGS];
        UINT32 result;

        /* make sure we've read the full command... for now, we'll
         * just crash, but later add a loop to complete the read TODO */
        if (nbytes != CHANNELIO_PACKET_SIZE)
        {
            fprintf(stderr, "software server: incomplete command\n");
            exit(1);
        }

        /* decode command */
        command = pack(buf);
        if (command >= MAX_SERVICES)
        {
            fprintf(stderr, "software server: invalid command: %u\n", command);
            exit(1);
        }

        /* figure out the expected number of arguments */
        // argc = ServiceMap[command].params;
        argc = 3;

        /* read args from pipe and place into args array */
        for (i = 0; i < argc; i++)
        {
            nbytes = read(STDIN, buf, CHANNELIO_PACKET_SIZE);
            if (nbytes != CHANNELIO_PACKET_SIZE)
            {
                fprintf(stderr, "software server: read too few bytes from parameter: %u", nbytes);
                fprintf(stderr, ", parameter = %u\n", pack(buf));
                exit(0);
            }
            argv[i] = pack(buf);
        }

        /* invoke local service method to obtain result */
        // result = ServiceMap[command].request(argc, argv);
        result = ServiceMap[command].request(argv[0], argv[1], argv[2]);

        /* send result to ChannelIO */
        unpack(result, buf);
        nbytes = write(STDOUT, buf, CHANNELIO_PACKET_SIZE);
        assert(nbytes == CHANNELIO_PACKET_SIZE);    /* ugh */
    }

    return 0;
}
