#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/select.h>
#include <sys/types.h>
#include <signal.h>

#include "software-rrr-server.h"

#define SELECT_TIMEOUT      1000
#define DIALOG_PACKET_SIZE  4
#define STDIN               0
#define STDOUT              1

#define MY_STRING_ID        "FRONT_PANEL"

typedef unsigned int UINT32;

static int serviceID;

static int dialogpid;
static int child_to_parent[2], parent_to_child[2];

static UINT32 inputCache;
static UINT32 outputCache;

/* sync input cache state with dialog box */
void sync_inputs()
{
    int     data_available;
    fd_set  readfds;
    struct timeval timeout;

    int read_from_dialog = child_to_parent[0];

    /* read from pipe coming from dialog box and
     * update input cache */
    do
    {
        FD_ZERO(&readfds);
        FD_SET(read_from_dialog, &readfds);     /* from dialog box */

        timeout.tv_sec  = 0;
        timeout.tv_usec = SELECT_TIMEOUT;

        data_available = select(read_from_dialog + 1, &readfds,
                                NULL, NULL, &timeout);

        if (data_available == -1)
        {
            perror("select");
            server_callback_exit(serviceID, 1);
        }

        if (data_available != 0)
        {
            /* incoming! */
            int bytes_requested;
            int bytes_read;

            /* sanity check */
            if (data_available > 1)
            {
                fprintf(stderr, "activity detected on too many descriptors\n");
                server_callback_exit(serviceID, 1);
            }

            if (FD_ISSET(read_from_dialog, &readfds))
            {
                /* incoming data from dialog box: convert to binary */
                UINT32      mask;
                int         i;
                UINT32      data;
                char        asciibuf[DIALOG_PACKET_SIZE * 8];
                int         nbytes;

                nbytes = read(read_from_dialog, asciibuf, DIALOG_PACKET_SIZE * 8);
                if (nbytes == 0)
                {
                    /* EOF => Exit button was pressed */
                    server_callback_exit(serviceID, 0);
                }
                
                assert(nbytes == DIALOG_PACKET_SIZE * 8);

                mask = 1;
                data = 0;
                for (i = 0; i < DIALOG_PACKET_SIZE * 8; i++)
                {
                    if (asciibuf[i] == '1')
                    {
                        data += mask;
                    }
                    mask = mask << 1;
                }

                /* update cache */
                inputCache = data;
            }
            else
            {
                fprintf(stderr, "activity detected on unknown descriptor\n");
                server_callback_exit(serviceID, 1);
            }
        }
    }
    while (data_available != 0);
}

/* sync output cache state with dialog box */
void sync_outputs()
{
    UINT32      mask;
    int         i;
    char        asciibuf[DIALOG_PACKET_SIZE * 8];
    int         nbytes;

    int write_to_dialog  = parent_to_child[1];

    /* convert to ASCII */
    mask = 1;
    for (i = 0; i < DIALOG_PACKET_SIZE * 8; i++)
    {
        char bit = (mask & outputCache) ? '1' : '0';
        asciibuf[i] = bit;
        mask = mask << 1;
    }

    /* send translated data to dialog box */
    nbytes = write(write_to_dialog, asciibuf, DIALOG_PACKET_SIZE * 8);
    assert(nbytes == DIALOG_PACKET_SIZE * 8);
}

/* init */
void front_panel_init(int ID, char *stringID)
{
    /* set service ID */
    serviceID = ID;

    /* unfortunately, Perl doesn't play nice with binary
     * data, so we cannot simply instantiate a Perl front panel and
     * be done with it; we have to translate the incoming data into
     * ASCII and pipe the translated stream through to the dialog
     * box; this means we'll need to create another process for
     * the dialog box */
    if (pipe(child_to_parent) < 0 || pipe(parent_to_child) < 0)
    {
        server_callback_exit(serviceID, 1);
    }

    dialogpid = fork();
    if (dialogpid == 0)
    {
        /* child */
        close(child_to_parent[0]);
        close(parent_to_child[1]);

        dup2(parent_to_child[0], STDIN);
        dup2(child_to_parent[1], STDOUT);

        execlp("hasim-front-panel", "hasim-front-panel", NULL);
    }
    else
    {
        /* parent */
        close(child_to_parent[1]);
        close(parent_to_child[0]);

        /* initial state */
        inputCache = 0;
        outputCache = 0;
    }

    /* return-via-copy string ID */
    sprintf(stringID, "%s", MY_STRING_ID);
}

/* service method */
UINT32 front_panel_request(UINT32 arg0, UINT32 arg1, UINT32 arg2)
{
    /* sync outputs */
    if (outputCache != arg0)
    {
        outputCache = arg0;
        sync_outputs();
    }

    /* sync inputs */
    sync_inputs();

    /* return state from input cache */
    return inputCache;
}

/* uninit */
void front_panel_uninit()
{
    /* kill dialog box */
    kill(dialogpid, SIGTERM);
}
