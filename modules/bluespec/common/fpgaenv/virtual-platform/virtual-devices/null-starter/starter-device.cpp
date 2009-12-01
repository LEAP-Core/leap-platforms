#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <iomanip>

#include "asim/atomic.h"

#include "asim/provides/starter_device.h"

// Temporarily control the Stat Dumping.
//#include "asim/provides/stats_device.h"

#include "asim/ioformat.h"

using namespace std;

// Global lock variables
pthread_mutex_t hardwareStatusLock;
int             hardwareStarted;
int             hardwareFinished;
int             hardwareExitCode;
pthread_cond_t  hardwareFinishedSignal;


// constructor
STARTER_DEVICE_SERVER_CLASS::STARTER_DEVICE_SERVER_CLASS()
{
}


// destructor
STARTER_DEVICE_SERVER_CLASS::~STARTER_DEVICE_SERVER_CLASS()
{
}

//
// RRR service requests
//

// init
void
STARTER_DEVICE_SERVER_CLASS::Init(
    PLATFORMS_MODULE p)
{
}

// uninit: override
void
STARTER_DEVICE_SERVER_CLASS::Uninit()
{
}

// cleanup
void
STARTER_DEVICE_SERVER_CLASS::Cleanup()
{
}

// End
void
STARTER_DEVICE_SERVER_CLASS::End(
    UINT8 exit_code)
{
}

// Heartbeat
void
STARTER_DEVICE_SERVER_CLASS::Heartbeat(
    UINT64 fpga_cycles)
{
}


// client: Start
void
STARTER_DEVICE_SERVER_CLASS::Start()
{
}
