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

/*** this is the main HAsim software server ***/

// service map
static RRR_SERVICE  ServiceMap[MAX_SERVICES];
static int          n_services;

// extern pointers to RRR service instances
#define ADD_SERVICE(NAME) extern RRR_SERVICE_CLASS* NAME##_service;
#include "master-service-list.rrr"
#undef ADD_SERVICE

/* process/pipe state: this should go into a lower-level
 * simulation-specific module, it has nothing to
 * do per-se with the software RRR server */
static int inpipe[2], outpipe[2];
static int childpid;
static int terminated = 0;
static int initialized = 0;

#define PARENT_READ     inpipe[0]
#define CHILD_WRITE     inpipe[1]
#define CHILD_READ      outpipe[0]
#define PARENT_WRITE    outpipe[1]

/* set up hardware partition */
static void init_hardware()
{
    /* create I/O pipes */
    if (pipe(inpipe) < 0 || pipe(outpipe) < 0)
    {
        perror("pipe");
        exit(1);
    }

    /* create target process */
    childpid = fork();
    if (childpid < 0)
    {
        perror("fork");
        exit(1);
    }

    if (childpid == 0)
    {
        char hardware_exe[256];

        /* CHILD: setup pipes for hardware side */
        close(PARENT_READ);
        close(PARENT_WRITE);

        dup2(CHILD_READ, CHANNELIO_HOST_2_FPGA);
        dup2(CHILD_WRITE, CHANNELIO_FPGA_2_HOST);

        /* launch hardware executable/download bitfile */
        sprintf(hardware_exe, "./%s_hw.exe", APM_NAME);
        execlp(hardware_exe, hardware_exe, NULL);

        /* error */
        perror("execlp");
        exit(1);
    }
    else
    {
        /* PARENT: setup pipes for software side */
        close(CHILD_READ);
        close(CHILD_WRITE);

        /* flags */
        terminated = 0;

        /* make sure channel is working by exchanging
         * message with FPGA */
        char buf[32] = "NULL";
        
        if (write(PARENT_WRITE, "SYN", 4) == -1)
        {
            perror("host/init/write");
            rrr_server_uninit();
            exit(1);
        }

        if (read(PARENT_READ, buf, 4) == -1)
        {
            perror("host/init/read");
            rrr_server_uninit();
            exit(1);
        }

        if (strcmp(buf, "ACK") != 0)
        {
            fprintf(stderr, "host: incorrect ack message from FPGA: %s\n", buf);
            rrr_server_uninit();
            exit(1);
        }
    }
}

static void uninit_hardware()
{
    /* kill child process */
    kill(childpid, SIGTERM);
}

/* init */
void rrr_server_init()
{
    /* initialize servive map table */
    for (int i = 0; i < MAX_SERVICES; i++)
    {
        ServiceMap[i] = NULL;
    }
    n_services = 0;

    /* populate service map table by defining a
     * macro and including the service definition
     * file */
#define ADD_SERVICE(NAME)                                           \
    {                                                               \
        /* instantiate service */                                   \
        ServiceMap[n_services] = NAME##_service;                    \
        ServiceMap[n_services]->Init(n_services);                   \
                                                                    \
        /* update service count */                                  \
        n_services++;                                               \
    }

#include "master-service-list.rrr"

#undef ADD_SERVICE

    /* launch hardware */
    init_hardware();

    /* flags */
    initialized = 1;
}

/* uninit */
void rrr_server_uninit()
{
    /* reset service map */
    for (int i = 0; i < n_services; i++)
    {
        if (ServiceMap[i])
        {
            ServiceMap[i]->Uninit();
            ServiceMap[i] = NULL;
        }
    }

    /* terminate hardware process */
    uninit_hardware();
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

/* clock */
void rrr_server_clock()
{
    unsigned char   buf[CHANNELIO_PACKET_SIZE];
    int             nbytes;
    UINT32          serviceID;

    /* the server side is fully serialized and has no
     * notion of virtual channels. It simply picks up
     * one request from ChannelIO, ships it off to the
     * service function, waits for the service function
     * to complete, and returns the result to STDOUT.
     * The client side can perform whatever virtualization
     * it chooses to */

    /* block-read input pipe */
    if ((nbytes = read(PARENT_READ, buf, CHANNELIO_PACKET_SIZE)) != 0)
    {
        int argc;
        int i;
        UINT32 argv[MAX_ARGS];
        UINT32 result;
        bool send_result;

        /* trap errors */
        if (nbytes == -1)
        {
            perror("read");
            exit(1);
        }

        /* make sure we've read the full serviceID... for now, we'll
         * just crash, but later add a loop to complete the read TODO */
        if (nbytes != CHANNELIO_PACKET_SIZE)
        {
            fprintf(stderr, "software server: incomplete serviceID\n");
            exit(1);
        }

        /* decode serviceID */
        serviceID = pack(buf);
        if (serviceID >= n_services)
        {
            fprintf(stderr, "software server: invalid serviceID: %u\n", serviceID);
            exit(1);
        }

        /* figure out the expected number of arguments */
        argc = 3;

        /* read args from pipe and place into args array */
        for (i = 0; i < argc; i++)
        {
            nbytes = read(PARENT_READ, buf, CHANNELIO_PACKET_SIZE);
            if (nbytes != CHANNELIO_PACKET_SIZE)
            {
                fprintf(stderr, "software server: read too few bytes from parameter:\n");
                fprintf(stderr, "                 serviceID  = %u\n", serviceID);
                fprintf(stderr, "                 param no.  = %u\n", i);
                fprintf(stderr, "                 bytes read = %u\n", nbytes);
                fprintf(stderr, "                 parameter  = %u\n", pack(buf));
                exit(0);
            }
            argv[i] = pack(buf);
        }

        /* invoke local service method to obtain result */
        send_result = ServiceMap[serviceID]->Request(argv[0], argv[1], argv[2], &result);

        /* send result to pipe? */
        if (send_result)
        {
            unpack(result, buf);
            nbytes = write(PARENT_WRITE, buf, CHANNELIO_PACKET_SIZE);
            assert(nbytes == CHANNELIO_PACKET_SIZE);    /* ugh */
        }
    }
    else
    {
        /* pipe read returned 0 => process has terminated, so exit */
        rrr_server_uninit();
        exit(0);
    }

    /* clock each service module */
    for (int i = 0; i < n_services; i++)
    {
        ServiceMap[i]->Clock();
    }
}

/* internal function: check if child process has quit
 * this function is currently unused, since the moment
 * the child process exits, the read() call in main()
 * will return a 0, causing the program to terminate,
 * which is exactly the behavior we want right now. In
 * future, though, this function could prove useful. */
static int termCheck()
{
    /* sanity check */
    if (initialized == 0)
    {
        /* invalid call */
        fprintf(stderr, "termCheck called without initialization\n");
        exit(1);
    }

    /* find out if child has exited */
    if (terminated == 0)
    {
        if (waitpid(childpid, NULL, WNOHANG|WUNTRACED) == childpid)
        {
            /* child has exited */
            terminated = 1;

            /* close pipes */
            close(PARENT_READ);
            close(PARENT_WRITE);

            return 1;
        }
    }
    else
    {
        /* terminated earlier */
        return 1;
    }

    return 0;
}

/* callback method that services can use to terminate simulation,
   either due to an error, or to signal a voluntary termination
   (e.g., Exit button-press on Front Panel) */
void server_callback_exit(int serviceID, int exitcode)
{
    rrr_server_uninit();
    exit(exitcode);
}
