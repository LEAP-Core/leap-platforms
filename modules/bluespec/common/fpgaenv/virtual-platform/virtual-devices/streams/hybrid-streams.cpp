#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/select.h>
#include <sys/types.h>
#include <signal.h>
#include <iostream>

#include "asim/provides/streams.h"
#include "asim/rrr/rrr_service_ids.h"

#include "asim/dict/STREAMS.h"
#include "asim/dict/MESSAGES.h"
#include "asim/dict/EVENTS.h"
#include "asim/dict/STATS.h"
#include "asim/dict/ASSERTS.h"
#include "asim/dict/MEMTEST.h"

#define SERVICE_ID  STREAMS_SERVICE_ID

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

    // open events and stats files
    eventfile = fopen("software_events.out", "w+");
    statfile = fopen("software_stats.out", "w+");
}

// uninit
void
STREAMS_CLASS::Uninit()
{
    // close stat and event files
    fclose(eventfile);
    fclose(statfile);
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
    bool retval = false;

    //cout << "streams: received request: method " << arg0 << " arg1 "
    //     << arg1 << " arg2 " << arg2 << endl;

    // decode request
    switch(arg0)
    {
        case STREAMS_MESSAGE:
            PrintMessage(arg1, arg2, arg3);
            retval = false;
            break;

        case STREAMS_EVENT:
            PrintEvent(arg1, arg2, arg3);
            retval = false;
            break;

        case STREAMS_STAT:
            PrintStat(arg1, arg2);
            retval = false;
            break;

        case STREAMS_ASSERT:
            PrintAssert(arg1, arg2);
            retval = false;
            break;

        case STREAMS_MEMTEST:
            PrintMemTestReq(arg1, arg2, arg3);
            retval = false;
            break;

        default:
            cerr << "console: invalid request" << endl;
            CallbackExit(1);
            break;
    }

    return retval;
}

// poll
void
STREAMS_CLASS::Poll()
{
}

// ===== internal print methods =====

// print message
void
STREAMS_CLASS::PrintMessage(
    UINT32 stringID,
    UINT32 payload0,
    UINT32 payload1)
{
    if (stringID > MESSAGES_last)
    {
        cerr << "streams: " << DICT_STREAMS::Str(STREAMS_MESSAGE)
             << ": invalid stringID: " << stringID << endl;
        CallbackExit(1);
    }

    const char *fmtstr = DICT_MESSAGES::Str(stringID);

    // need to special-case certain messages
    if (stringID == MESSAGES_START || stringID == MESSAGES_SUCCESS || stringID == MESSAGES_FAILURE)
    {
        printf(fmtstr, payload0);
    }
    else
    {
        printf(fmtstr, payload0, payload1);
    }
    fflush(stdout);
}

// print event
void
STREAMS_CLASS::PrintEvent(
    UINT32 stringID,
    UINT32 payload0,
    UINT32 payload1)
{
    if (stringID > EVENTS_last)
    {
        cerr << "streams: " << DICT_STREAMS::Str(STREAMS_EVENT)
             << ": invalid stringID: " << stringID << endl;
        CallbackExit(1);
    }

    const char *fmtstr = DICT_EVENTS::Str(stringID);
    fprintf(eventfile, fmtstr, payload0, payload1);
    fflush(eventfile);
}

// print stat
void
STREAMS_CLASS::PrintStat(
    UINT32 stringID,
    UINT32 value)
{
    if (stringID > STATS_last)
    {
        cerr << "streams: " << DICT_STREAMS::Str(STREAMS_STAT)
             << ": invalid stringID: " << stringID << endl;
        CallbackExit(1);
    }

    const char *fmtstr = DICT_STATS::Str(stringID);
    fprintf(statfile, fmtstr, value);
}

// print assert
void
STREAMS_CLASS::PrintAssert(
    UINT32 stringID,
    UINT32 severity)
{
    if (stringID > ASSERTS_last)
    {
        cerr << "streams: " << DICT_STREAMS::Str(STREAMS_ASSERT)
             << ": invalid stringID: " << stringID << endl;
        CallbackExit(1);
    }

    const char *fmtstr = DICT_ASSERTS::Str(stringID);
    printf(fmtstr);
    fflush(stdout);

    if (severity > 1)
    {
        CallbackExit(1);
    }
}

// print memtest message
void
STREAMS_CLASS::PrintMemTestReq(
    UINT32 stringID,
    UINT32 payload0,
    UINT32 payload1)
{
    if (stringID > MEMTEST_last)
    {
        cerr << "streams: " << DICT_STREAMS::Str(STREAMS_MEMTEST)
             << ": invalid stringID: " << stringID << endl;
        CallbackExit(1);
    }

    const char *fmtstr = DICT_MEMTEST::Str(stringID);

    switch (stringID)
    {
        case MEMTEST_DATA : printf(fmtstr, payload0, payload1); break;
        case MEMTEST_INVAL: printf(fmtstr, payload0);           break;
        case MEMTEST_DONE : printf(fmtstr);                     break;
    }

    fflush(stdout);
}
