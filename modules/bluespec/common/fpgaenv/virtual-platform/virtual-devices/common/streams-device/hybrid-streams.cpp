#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/select.h>
#include <sys/types.h>
#include <signal.h>
#include <string.h>
#include <iostream>

#include "asim/provides/streams_device.h"
#include "asim/rrr/service_ids.h"

#include "asim/dict/STREAMS.h"
#include "asim/dict/STREAMID.h"

#define SERVICE_ID       STREAMS_SERVICE_ID

using namespace std;

// ===== service instantiation =====
STREAMS_DEVICE_SERVER_CLASS STREAMS_DEVICE_SERVER_CLASS::instance;

// ===== methods =====

// constructor
STREAMS_DEVICE_SERVER_CLASS::STREAMS_DEVICE_SERVER_CLASS()
{
    // instantiate stubs
    serverStub = new STREAMS_SERVER_STUB_CLASS(this);
}

// destructor
STREAMS_DEVICE_SERVER_CLASS::~STREAMS_DEVICE_SERVER_CLASS()
{
    Cleanup();
}

// init
void
STREAMS_DEVICE_SERVER_CLASS::Init(
    PLATFORMS_MODULE p)
{
    // set parent pointer
    parent = p;

    // initialize maps
    for (int i = 0; i < MAX_STREAMS_DEVICE; i++)
    {
        streamOutput[i] = stdout;
        callbackModule[i] = NULL;
    }
    PLATFORMS_MODULE_CLASS::Init();
}

// uninit: we have to write this explicitly
void
STREAMS_DEVICE_SERVER_CLASS::Uninit()
{
    Cleanup();

    // chain
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
STREAMS_DEVICE_SERVER_CLASS::Cleanup()
{
    // destroy stubs
    delete serverStub;
}

// RRR request method
void
STREAMS_DEVICE_SERVER_CLASS::Print(
    UINT32 streamID,
    UINT32 stringID,
    UINT32 payload0,
    UINT32 payload1)
{
    // lookup format string from dictionary
    const char *fmtstr = STREAMS_DICT::Str(stringID);
    if (fmtstr == NULL)
    {
        cerr << "streams: " << STREAMID_DICT::Str(streamID)
             << ": invalid stringID: " << stringID << endl;
        CallbackExit(1);
    }

    // lookup output stream
    FILE *outstream = streamOutput[streamID];
    if (outstream == NULL)
    {
        cerr << "streams: invalid streamID: " << streamID << endl;
        CallbackExit(1);
    }

    // find number of payloads
    int payloads = CountPayloads(fmtstr);

    // print message
    switch (payloads)
    {
        case 0:
            fprintf(outstream, fmtstr);
            break;

        case 1:
            fprintf(outstream, fmtstr, payload0);
            break;

        case 2:
            fprintf(outstream, fmtstr, payload0, payload1);
            break;

        default:
            cerr << "streams: invalid number of payloads" << endl;
            break;
    }
    fflush(outstream);

    // call back module if required
    STREAMS_DEVICE_CALLBACK_MODULE module = callbackModule[streamID];
    if (module != NULL)
    {
        module->StreamsCallback(stringID, payload0, payload1);
    }

    // On special exit message exit the program
    if ( stringID == STREAMS_MESSAGE_EXIT )
    {
        CallbackExit(payload0);
    }
}

// map a stream to an output file
void
STREAMS_DEVICE_SERVER_CLASS::MapStream(
    int   streamID,
    FILE *out)
{
    // sanity check
    if (streamID >= MAX_STREAMS_DEVICE)
    {
        cerr << "streams: invalid streamID: " << streamID << endl;
        CallbackExit(1);
    }

    // map stream
    streamOutput[streamID] = out;
}

// set link to module to be called back
void
STREAMS_DEVICE_SERVER_CLASS::RegisterCallback(
    int streamID,
    STREAMS_DEVICE_CALLBACK_MODULE module)
{
    callbackModule[streamID] = module;
}

// count number of payloads in a printf-style format string
int
STREAMS_DEVICE_SERVER_CLASS::CountPayloads(
    const char *str)
{
    // simply count the number of %'s in the string. The only
    // exception is escaped characters. This heuristic can be
    // improved in future.
    int count = 0;
    for (int i = 0; i < strlen(str); i++)
    {
        // skip escape sequences
        if (str[i] == '\\')
        {
            i++;
            continue;
        }

        if (str[i] == '%')
        {
            count++;
        }
    }

    return count;
}
