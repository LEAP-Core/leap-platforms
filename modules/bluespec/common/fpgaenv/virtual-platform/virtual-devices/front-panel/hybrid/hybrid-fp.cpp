#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/select.h>
#include <sys/types.h>
#include <signal.h>
#include <string.h>

#include "asim/rrr/service_ids.h"
#include "asim/provides/rrr.h"

#include "asim/provides/front_panel.h"

#define SERVICE_ID FRONT_PANEL_SERVICE_ID

// service instantiation
FRONT_PANEL_SERVER_CLASS FRONT_PANEL_SERVER_CLASS::instance;

// constructor
FRONT_PANEL_SERVER_CLASS::FRONT_PANEL_SERVER_CLASS() :
    fpSwitch()
{
    // instantiate stubs
    clientStub = new FRONT_PANEL_CLIENT_STUB_CLASS(this);
    serverStub = new FRONT_PANEL_SERVER_STUB_CLASS(this);
}

// destructor
FRONT_PANEL_SERVER_CLASS::~FRONT_PANEL_SERVER_CLASS()
{
    Cleanup();
}

// init
void
FRONT_PANEL_SERVER_CLASS::Init(
    PLATFORMS_MODULE p)
{
    // set parent pointer
    parent = p;

    // set intial state
    inputCache = 0;
    inputDirty = false;
    outputCache = 0;
    outputDirty = false;

    // see if we should pop up the dialog box
    if (fpSwitch.ShowFrontPanel() == false)
    {
        return;
    }

    /* unfortunately, Perl doesn't play nice with binary
     * data, so we cannot simply instantiate a Perl front panel and
     * be done with it; we have to translate the incoming data into
     * ASCII and pipe the translated stream through to the dialog
     * box; this means we'll need to create another process for
     * the dialog box */
    if (pipe(child_to_parent) < 0 || pipe(parent_to_child) < 0)
    {
        parent->CallbackExit(1);
    }

    dialogpid = fork();
    if (dialogpid == 0)
    {
        // child
        close(child_to_parent[0]);
        close(parent_to_child[1]);

        dup2(parent_to_child[0], STDIN);
        dup2(child_to_parent[1], STDOUT);

        execlp("leap-front-panel", "leap-front-panel", NULL);
    }
    else
    {
        // parent
        close(child_to_parent[1]);
        close(parent_to_child[0]);

        // initial state
        childAlive = true;
    }

    // chain
    PLATFORMS_MODULE_CLASS::Init();
}

// uninit: override
void
FRONT_PANEL_SERVER_CLASS::Uninit()
{
    // cleanup
    Cleanup();

    // chain
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup: kill panel process
void
FRONT_PANEL_SERVER_CLASS::Cleanup()
{
    if (childAlive)
    {
        // kill dialog box
        kill(dialogpid, SIGTERM);
        childAlive = false;
    }

    // destroy stubs
    delete clientStub;
    delete serverStub;
}

// handle UpdateLEDs request
void
FRONT_PANEL_SERVER_CLASS::UpdateLEDs(
    UINT8 state)
{
    // update cache and set dirty bit
    if (outputCache != state)
    {
        outputCache = state;
        outputDirty = true;
    }
}

// poll
bool
FRONT_PANEL_SERVER_CLASS::Poll()
{
    // Is dialog disabled?
    if (fpSwitch.ShowFrontPanel() == false)
    {
        if (outputDirty && fpSwitch.ShowLEDsOnStdOut())
        {
            syncOutputsConsole();
            outputDirty = false;
        }
        return true;
    }

    // if output cache is dirty relative to dialog, update dialog
    if (outputDirty)
    {
        syncOutputs();
        outputDirty = false;
    }

    // sync input cache with dialog
    syncInputs();

    // if input cache was changed, update hardware partition
    if (inputDirty)
    {
        clientStub->UpdateSwitchesButtons(inputCache);
        inputDirty = false;
    }

    // True means call this method again.  False indicates no polling needed.
    return true;
}

// internal helper method: sync input cache state for console
void
FRONT_PANEL_SERVER_CLASS::syncInputsConsole()
{
}

// internal helper method: sync output cache state for console
void
FRONT_PANEL_SERVER_CLASS::syncOutputsConsole()
{
    printf("LEDS: %032x\n", outputCache);
}

// internal helper method: sync input cache state with dialog box
void
FRONT_PANEL_SERVER_CLASS::syncInputs()
{
    int     data_available;
    fd_set  readfds;
    struct timeval timeout;

    int read_from_dialog = child_to_parent[0];

    // read from pipe coming from dialog box and update input cache
    do
    {
        FD_ZERO(&readfds);
        FD_SET(read_from_dialog, &readfds);     // from dialog box

        timeout.tv_sec  = 0;
        timeout.tv_usec = SELECT_TIMEOUT;

        data_available = select(read_from_dialog + 1, &readfds,
                                NULL, NULL, &timeout);

        if (data_available == -1)
        {
            perror("select");
            parent->CallbackExit(1);
        }

        if (data_available != 0)
        {
            // incoming!
            int bytes_requested;
            int bytes_read;

            // sanity check
            if (data_available > 1)
            {
                fprintf(stderr, "activity detected on too many descriptors\n");
                parent->CallbackExit(1);
            }

            if (FD_ISSET(read_from_dialog, &readfds))
            {
                // incoming data from dialog box: convert to binary
                UINT32      mask;
                int         i;
                UINT32      data;
                char        asciibuf[DIALOG_PACKET_SIZE * 8];
                int         nbytes;

                nbytes = read(read_from_dialog, asciibuf, DIALOG_PACKET_SIZE * 8);
                if (nbytes == 0)
                {
                    // EOF => Exit button was pressed
                    parent->CallbackExit(0);
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

                // update cache
                if (inputCache != data)
                {
                    inputCache = data;
                    inputDirty = true;
                }
            }
            else
            {
                fprintf(stderr, "activity detected on unknown descriptor\n");
                parent->CallbackExit(1);
            }
        }
    }
    while (data_available != 0);
}

// internal helper method: sync output cache state with dialog box
void
FRONT_PANEL_SERVER_CLASS::syncOutputs()
{
    UINT32      mask;
    int         i;
    char        asciibuf[DIALOG_PACKET_SIZE * 8];
    int         nbytes;

    int write_to_dialog = parent_to_child[1];

    // convert to ASCII
    mask = 1;
    for (i = 0; i < DIALOG_PACKET_SIZE * 8; i++)
    {
        char bit = (mask & outputCache) ? '1' : '0';
        asciibuf[i] = bit;
        mask = mask << 1;
    }

    // send translated data to dialog box
    nbytes = write(write_to_dialog, asciibuf, DIALOG_PACKET_SIZE * 8);
    assert(nbytes == DIALOG_PACKET_SIZE * 8);
}

FRONT_PANEL_COMMAND_SWITCHES_CLASS::FRONT_PANEL_COMMAND_SWITCHES_CLASS() :
    showFrontPanel(false),
    showLEDsOnStdOut(true),
    COMMAND_SWITCH_OPTIONAL_STRING_CLASS("showfp")
{
}

FRONT_PANEL_COMMAND_SWITCHES_CLASS::~FRONT_PANEL_COMMAND_SWITCHES_CLASS()
{
}

void
FRONT_PANEL_COMMAND_SWITCHES_CLASS::ProcessSwitchVoid()
{
    showFrontPanel = false;
    showLEDsOnStdOut = true;
}

void
FRONT_PANEL_COMMAND_SWITCHES_CLASS::ProcessSwitchString(char *switch_arg)
{
    if (strcmp(switch_arg, "gui") == 0)
    {
        showFrontPanel = true;
        showLEDsOnStdOut = false;
    }
    else if (strcmp(switch_arg, "stdout") == 0)
    {
        showFrontPanel = false;
        showLEDsOnStdOut = true;
    }
    else if (strncmp(switch_arg, "no", 2) == 0)
    {
        showFrontPanel = false;
        showLEDsOnStdOut = false;
    }
    else
    {
        cerr << "Warning: Unknown argument to --showfp: " << switch_arg << endl;
        cerr << "         Expected: [=gui|stdout|none]" << endl;
        showFrontPanel = true;
        showLEDsOnStdOut = false;
    }
}

bool
FRONT_PANEL_COMMAND_SWITCHES_CLASS::ShowSwitch(char *buff)
{
    strcpy(buff, "[--showfp[=gui|stdout|none]]");
    return true;
}
