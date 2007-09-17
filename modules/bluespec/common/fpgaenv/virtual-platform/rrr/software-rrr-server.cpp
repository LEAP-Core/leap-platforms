#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>

#include "software-rrr-server.h"

/* this is the main HAsim software server */

/* service map */
static Service ServiceMap[MAX_SERVICES];
static int     n_services;

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

        dup2(CHILD_READ, 0);
        dup2(CHILD_WRITE, 1);

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
    }
}

static void uninit_hardware()
{
    /* kill child process */
    kill(childpid, SIGTERM);
}

/* init */
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
        void    name##_init(int, char *);                   \
        UINT32  name##_request(UINT32, UINT32, UINT32);     \
        void    name##_uninit(void);                        \
                                                            \
        /* now fill in service table */                     \
        ServiceMap[n_services].ID       =   n_services;     \
        ServiceMap[n_services].params   =   3;              \
        ServiceMap[n_services].init     =   name##_init;    \
        ServiceMap[n_services].main     =   NULL;           \
        ServiceMap[n_services].request  =   name##_request; \
        ServiceMap[n_services].uninit   =   name##_uninit;  \
                                                            \
        /* update service count */                          \
        n_services++;                                       \
    }

#include "master-service-list.rrr"

#undef ADD_SERVICE

    /* initialize individual services */
    for (i = 0; i < n_services; i++)
    {
        ServiceMap[i].init(ServiceMap[i].ID, ServiceMap[i].stringID);
#ifdef __DEBUG__
        fprintf(stderr, "RRR server: registered service: %s\n",
                ServiceMap[i].stringID);
#endif
    }

    /* launch hardware */
    init_hardware();

    /* flags */
    initialized = 1;
}

/* uninit */
static void uninit()
{
    /* call uninit function for all services */
    int i;

    for (i = 0; i < n_services; i++)
    {
        ServiceMap[i].uninit();
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

/* main */
int main()
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
    init();

    /* go into an infinite loop, scanning input pipe for requests */
    while ((nbytes = read(PARENT_READ, buf, CHANNELIO_PACKET_SIZE)) != 0)
    {
        int argc;
        int i;
        UINT32 argv[MAX_ARGS];
        UINT32 result;

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
        // argc = ServiceMap[serviceID].params;
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
        // result = ServiceMap[serviceID].request(argc, argv);
        result = ServiceMap[serviceID].request(argv[0], argv[1], argv[2]);

        /* send result to pipe */
        unpack(result, buf);
        nbytes = write(PARENT_WRITE, buf, CHANNELIO_PACKET_SIZE);
        assert(nbytes == CHANNELIO_PACKET_SIZE);    /* ugh */
    }

    /* pipe read returned 0 => process has terminated.
     * cleanup and exit */
    uninit();

    return 0;
}

/* internal function: check if child process has quit
 * this function is currently unused, since the moment
 * the child process exits, the read() call in main()
 * will return a 0, causing the program to terminate,
 * which is exactly the behavior we want right now. In
 * future, though, this function could prove useful.
 */
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
    uninit();
    exit(exitcode);
}
