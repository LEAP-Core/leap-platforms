#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/select.h>
#include <sys/types.h>
#include <signal.h>
#include <string.h>
#include <iostream>

#include "asim/provides/streams.h"
#include "asim/rrr/rrr_service_ids.h"

#include "asim/dict/STREAMS.h"
#include "asim/dict/STREAMID.h"

#define SERVICE_ID       STREAMS_SERVICE_ID

using namespace std;

// ===== service instantiation =====
STREAMS_CLASS STREAMS_CLASS::instance;

// ===== methods =====

// constructor
STREAMS_CLASS::STREAMS_CLASS()
{
    // register with server's map table
    RRR_SERVER_CLASS::RegisterService(SERVICE_ID, &instance);
}

// destructor
STREAMS_CLASS::~STREAMS_CLASS()
{
}

// init
void
STREAMS_CLASS::Init(
    HASIM_MODULE     p)
{
    // set parent pointer
    parent = p;

    // initialize maps
    for (int i = 0; i < MAX_STREAMS; i++)
    {
        streamOutput[i] = stdout;
        callbackModule[i] = NULL;
    }
}

// uninit
void
STREAMS_CLASS::Uninit()
{
}

// request
bool
STREAMS_CLASS::Request(
    UINT32 arg0,
    UINT32 arg1,
    UINT32 arg2,
    UINT32 arg3,
    UINT32 *result)
{
    // extract IDs and payloads
    UINT32 streamID = arg0;
    UINT32 stringID = arg1;
    UINT32 payload0 = arg2;
    UINT32 payload1 = arg3;

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
    STREAMS_CALLBACK_MODULE module = callbackModule[streamID];
    if (module != NULL)
    {
        module->StreamsCallback(stringID, payload0, payload1);
    }

    // no RRR response
    return false;
}

// poll
void
STREAMS_CLASS::Poll()
{
}

// map a stream to an output file
void
STREAMS_CLASS::MapStream(
    int   streamID,
    FILE *out)
{
    // sanity check
    if (streamID >= MAX_STREAMS)
    {
        cerr << "streams: invalid streamID: " << streamID << endl;
        CallbackExit(1);
    }

    // map stream
    streamOutput[streamID] = out;
}

// set link to module to be called back
void
STREAMS_CLASS::RegisterCallback(
    int streamID,
    STREAMS_CALLBACK_MODULE module)
{
    callbackModule[streamID] = module;
}

// count number of payloads in a printf-style format string
int
STREAMS_CLASS::CountPayloads(
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

